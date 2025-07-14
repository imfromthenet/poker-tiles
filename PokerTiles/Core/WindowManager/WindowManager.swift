import Foundation
import ScreenCaptureKit
import AppKit
import Observation

@Observable
class WindowManager {
    enum PermissionState {
        case notDetermined
        case granted
        case denied
        
        var hasAccess: Bool {
            self == .granted
        }
    }
    
    var windowCount: Int = 0
    var windows: [WindowInfo] = []
    var permissionState: PermissionState = .notDetermined
    var hasPermission: Bool { permissionState.hasAccess }
    var isScanning: Bool = false
    var isAutoScanEnabled: Bool = true
    var autoScanInterval: TimeInterval = 1.0 // Default 1 second
    
    let pokerTableDetector = PokerTableDetector()
    var pokerTables: [PokerTable] = []
    
    private var autoScanTask: Task<Void, Never>?
    
    struct WindowInfo: Identifiable {
        let id: String
        let title: String
        let appName: String
        let bundleIdentifier: String
        let isOnScreen: Bool
        let bounds: CGRect
        let scWindow: SCWindow
        var thumbnail: NSImage?
        
        init(scWindow: SCWindow, thumbnail: NSImage? = nil) {
            self.scWindow = scWindow
            self.id = "\(scWindow.windowID)"
            self.title = scWindow.title ?? "Untitled"
            self.appName = scWindow.owningApplication?.applicationName ?? "Unknown"
            self.bundleIdentifier = scWindow.owningApplication?.bundleIdentifier ?? "unknown"
            self.isOnScreen = scWindow.isOnScreen
            self.bounds = scWindow.frame
            self.thumbnail = thumbnail
        }
    }
    
    init() {
        checkPermissions()
        startAutoScan()
    }
    
    deinit {
        stopAutoScan()
    }
    
    func checkPermissions() {
        if CGPreflightScreenCaptureAccess() {
            permissionState = .granted
        } else {
            // Check if we can determine if it's denied or just not determined
            // If we've requested before and still no access, it's likely denied
            permissionState = .notDetermined
        }
    }
    
    func requestPermissions() async {
        // Store current state to detect if user actually made a choice
        let previousState = permissionState
        
        CGRequestScreenCaptureAccess()
        
        // Wait a bit for the system to update
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        await MainActor.run {
            self.checkPermissions()
            
            // If still not granted after request, user likely denied
            if self.permissionState != .granted && previousState == .notDetermined {
                self.permissionState = .denied
            }
        }
    }
    
    func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func startAutoScan() {
        stopAutoScan() // Cancel any existing task
        
        guard isAutoScanEnabled else { return }
        
        autoScanTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                if self.hasPermission && !self.isScanning {
                    await self.scanWindows()
                }
                
                try? await Task.sleep(nanoseconds: UInt64(self.autoScanInterval * 1_000_000_000))
            }
        }
    }
    
    func stopAutoScan() {
        autoScanTask?.cancel()
        autoScanTask = nil
    }
    
    func setAutoScanEnabled(_ enabled: Bool) {
        isAutoScanEnabled = enabled
        if enabled {
            startAutoScan()
        } else {
            stopAutoScan()
        }
    }
    
    func setAutoScanInterval(_ interval: TimeInterval) {
        autoScanInterval = max(0.01, interval) // Minimum 0.01 seconds
        if isAutoScanEnabled {
            startAutoScan() // Restart with new interval
        }
    }
    
    func scanWindows() async {
        guard hasPermission else {
            print("Screen capture permission not granted")
            return
        }
        
        await MainActor.run {
            self.isScanning = true
        }
        
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            
            // Create window infos and capture thumbnails
            var windowInfos: [WindowInfo] = []
            
            for window in content.windows {
                // Only capture thumbnails for actual app windows
                let shouldCapture = isAppWindow(window)
                let thumbnail = shouldCapture ? await captureWindowThumbnail(window) : nil
                let windowInfo = WindowInfo(scWindow: window, thumbnail: thumbnail)
                windowInfos.append(windowInfo)
                
                if shouldCapture {
                    if thumbnail != nil {
                        print("✅ Captured thumbnail for: \(window.title ?? "Unknown")")
                    } else {
                        print("❌ Failed to capture thumbnail for: \(window.title ?? "Unknown")")
                    }
                }
            }
            
            await MainActor.run {
                self.windows = windowInfos
                self.windowCount = windowInfos.count
                self.pokerTables = self.pokerTableDetector.detectPokerTables(from: windowInfos)
                self.isScanning = false
            }
            
            print("Found \(windowInfos.count) windows, \(self.pokerTables.count) poker tables")
            
        } catch {
            print("Failed to get window content: \(error)")
            await MainActor.run {
                self.isScanning = false
            }
        }
    }
    
    func getPokerAppWindows() -> [WindowInfo] {
        let pokerAppBundles = [
            "com.pokerstars",
            "com.pokerstars.eu",
            "com.pokerstars.net",
            "com.888poker",
            "com.ggpoker",
            "com.partypoker",
            "com.winamax",
            "com.ignitioncasino",
            "com.americascardroom"
        ]
        
        return windows.filter { window in
            pokerAppBundles.contains { bundlePrefix in
                window.bundleIdentifier.lowercased().contains(bundlePrefix.lowercased())
            }
        }
    }
    
    func getPokerTableWindows() -> [WindowInfo] {
        return pokerTables.map { $0.windowInfo }
    }
    
    func getVisibleWindows() -> [WindowInfo] {
        return windows.filter { $0.isOnScreen }
    }
    
    func getAppWindows() -> [WindowInfo] {
        let systemBundles = [
            "com.apple.controlcenter",
            "com.apple.NotificationCenter",
            "com.apple.dock",
            "com.apple.WindowManager",
            "com.apple.systemuiserver",
            "com.apple.spotlight",
            "com.apple.loginwindow",
            "com.apple.MenuMeters",
            "com.apple.preferences",
            "com.apple.finder"
        ]
        
        return windows.filter { window in
            // Filter out system windows and windows without proper titles
            !systemBundles.contains(window.bundleIdentifier) &&
            !window.title.isEmpty &&
            window.title != "Window" &&
            window.title != "Desktop" &&
            window.bounds.width > 100 &&
            window.bounds.height > 100
        }
    }
    
    func printWindowSummary() {
        print("\n=== Window Summary ===")
        print("Total windows: \(windowCount)")
        print("App windows: \(getAppWindows().count)")
        print("Visible windows: \(getVisibleWindows().count)")
        print("Poker app windows: \(getPokerAppWindows().count)")
        print("Poker tables detected: \(pokerTables.count)")
        
        print("\n=== Applications ===")
        let appWindows = getAppWindows()
        let apps = Dictionary(grouping: appWindows) { $0.appName }
        for (app, windows) in apps.sorted(by: { $0.key < $1.key }) {
            print("\(app): \(windows.count) windows")
        }
        
        print("\n=== Poker Tables ===")
        if pokerTables.isEmpty {
            print("No poker tables detected")
        } else {
            let tablesByApp = pokerTableDetector.groupTablesByApp(pokerTables)
            for (app, tables) in tablesByApp.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                print("\n\(app.rawValue):")
                for table in tables {
                    print("  - \(table.windowInfo.title) [\(table.tableType.displayName)]")
                }
            }
        }
        
        print("\n=== Non-Table Poker Windows ===")
        let allPokerWindows = getPokerAppWindows()
        let tableWindows = getPokerTableWindows()
        let nonTableWindows = allPokerWindows.filter { window in
            !tableWindows.contains(where: { $0.id == window.id })
        }
        
        if nonTableWindows.isEmpty {
            print("None (all poker windows are tables)")
        } else {
            for window in nonTableWindows {
                print("- \(window.appName): \(window.title)")
            }
        }
    }
    
    func bringWindowToFront(_ windowInfo: WindowInfo) {
        guard let app = windowInfo.scWindow.owningApplication else {
            print("No owning application found for window")
            return
        }
        
        let pid = app.processID
        let runningApp = NSRunningApplication(processIdentifier: pid)
        
        // Activate the application
        if #available(macOS 14.0, *) {
            runningApp?.activate()
        } else {
            runningApp?.activate(options: [.activateIgnoringOtherApps])
        }
        
        print("Brought window '\(windowInfo.title)' from app '\(windowInfo.appName)' to front")
    }
    
    private func isAppWindow(_ window: SCWindow) -> Bool {
        guard let app = window.owningApplication else { return false }
        
        let systemBundles = [
            "com.apple.controlcenter",
            "com.apple.NotificationCenter", 
            "com.apple.dock",
            "com.apple.WindowManager",
            "com.apple.systemuiserver",
            "com.apple.spotlight",
            "com.apple.loginwindow",
            "com.apple.MenuMeters",
            "com.apple.menuextra",
            "com.apple.wallpaper"
        ]
        
        let title = window.title ?? ""
        let bundleId = app.bundleIdentifier
        
        // Skip system bundles
        if systemBundles.contains(where: { bundleId.contains($0) }) {
            return false
        }
        
        // Skip system UI elements
        if title.isEmpty || 
           title.contains("Menubar") ||
           title.contains("Dock") ||
           title.contains("Item-") ||
           title.contains("BentoBox") ||
           title.contains("Backstop") ||
           title.contains("Wallpaper") ||
           title == "Desktop" ||
           title == "Window" {
            return false
        }
        
        // Must be on screen and reasonable size
        return window.isOnScreen && 
               window.frame.width > 100 && 
               window.frame.height > 100
    }
    
    private func captureWindowThumbnail(_ window: SCWindow) async -> NSImage? {
        guard window.isOnScreen,
              window.frame.width > 50,
              window.frame.height > 50 else {
            print("⏩ Skipping thumbnail for '\(window.title ?? "Unknown")' - not on screen or too small")
            return nil
        }
        
        print("📸 Attempting to capture thumbnail for: \(window.title ?? "Unknown") (\(Int(window.frame.width))x\(Int(window.frame.height)))")
        
        return await captureWithScreenCaptureKit(window)
    }
    
    private func captureWithScreenCaptureKit(_ window: SCWindow) async -> NSImage? {
        do { 
            // Try using SCScreenshotManager for a simpler one-shot capture
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let configuration = SCStreamConfiguration()
            
            // Set reasonable thumbnail size
            configuration.width = min(200, Int(window.frame.width))
            configuration.height = min(150, Int(window.frame.height))
            configuration.showsCursor = false
            configuration.scalesToFit = true
            
            if #available(macOS 14.0, *) {
                let screenshot = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: configuration
                )
                
                let nsImage = NSImage(cgImage: screenshot, size: CGSize(width: screenshot.width, height: screenshot.height))
                print("✅ Successfully captured screenshot: \(nsImage.size)")
                return nsImage
            } else {
                // Fallback for older macOS versions
                return await captureWithStreamForOlderOS(window, filter: filter, config: configuration)
            }
        } catch {
            print("❌ Screenshot capture failed: \(error)")
            return nil
        }
    }
    
    private func captureWithStreamForOlderOS(_ window: SCWindow, filter: SCContentFilter, config: SCStreamConfiguration) async -> NSImage? {
        do {
            let stream = SCStream(filter: filter, configuration: config, delegate: nil)
            
            return try await withCheckedThrowingContinuation { continuation in
                var isResumed = false
                let resumeLock = NSLock()
                
                func safeResume(with result: Result<NSImage?, Error>) {
                    resumeLock.lock()
                    defer { resumeLock.unlock() }
                    
                    guard !isResumed else { return }
                    isResumed = true
                    
                    switch result {
                    case .success(let image):
                        continuation.resume(returning: image)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                let captureOutput = ThumbnailCaptureOutput { image in
                    safeResume(with: .success(image))
                }
                
                do {
                    try stream.addStreamOutput(captureOutput, type: .screen, sampleHandlerQueue: .main)
                    stream.startCapture { error in
                        if let error = error {
                            safeResume(with: .failure(error))
                        }
                    }
                    
                    // Set up timeout to ensure continuation is always resumed
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second timeout
                        
                        await MainActor.run {
                            stream.stopCapture { _ in }
                        }
                        
                        // Resume with nil if not already resumed
                        safeResume(with: .success(nil))
                    }
                } catch {
                    safeResume(with: .failure(error))
                }
            }
        } catch {
            print("Failed to capture thumbnail with stream: \(error)")
            return nil
        }
    }
}

private class ThumbnailCaptureOutput: NSObject, SCStreamOutput {
    private let completion: (NSImage?) -> Void
    private let lock = NSLock()
    private var _hasCompleted = false
    
    var hasCompleted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _hasCompleted
    }
    
    init(completion: @escaping (NSImage?) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        lock.lock()
        guard !_hasCompleted else { 
            lock.unlock()
            return 
        }
        _hasCompleted = true
        lock.unlock()
        
        print("🎬 Received sample buffer for thumbnail capture")
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("❌ Failed to get image buffer from sample")
            completion(nil)
            return
        }
        
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("❌ Failed to create CGImage from CIImage")
            completion(nil)
            return
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        print("✅ Successfully created NSImage: \(nsImage.size)")
        completion(nsImage)
    }
}

// MARK: - Poker Detection Models and Services

enum PokerApp: String, CaseIterable {
    case pokerStars = "PokerStars"
    case poker888 = "888poker"
    case ggPoker = "GGPoker"
    case partyPoker = "partypoker"
    case winamax = "Winamax"
    case ignition = "Ignition"
    case acr = "Americas Cardroom"
    case unknown = "Unknown"
    
    var bundleIdentifiers: [String] {
        switch self {
        case .pokerStars:
            return ["com.pokerstars", "com.pokerstars.eu", "com.pokerstars.net", "com.pokerstarsuk.poker"]
        case .poker888:
            return ["com.888poker", "com.888holdingsplc.888poker"]
        case .ggPoker:
            return ["com.ggpoker", "com.goodgame.poker", "com.nsus1.ggpoker"]
        case .partyPoker:
            return ["com.partypoker", "com.partygaming.partypoker"]
        case .winamax:
            return ["com.winamax", "fr.winamax.poker"]
        case .ignition:
            return ["com.ignitioncasino", "com.ignition.poker"]
        case .acr:
            return ["com.americascardroom", "com.acr.poker", "com.winningpokernetwork"]
        case .unknown:
            return []
        }
    }
    
    var tableWindowPatterns: [String] {
        switch self {
        case .pokerStars:
            return ["Tournament", "Cash", "Zoom", "Spin & Go", "Table", "6-Max", "9-Max", "Heads-Up"]
        case .poker888:
            return ["Table", "Tournament", "SNAP", "BLAST", "Cash Game"]
        case .ggPoker:
            return ["Table", "Rush & Cash", "All-In or Fold", "Battle Royale", "Flip & Go"]
        case .partyPoker:
            return ["Table", "fastforward", "SPINS", "Cash Game", "Sit & Go"]
        case .winamax:
            return ["Table", "Expresso", "Cash Game", "Go Fast"]
        case .ignition:
            return ["Table", "Zone Poker", "Jackpot Sit & Go", "Cash"]
        case .acr:
            return ["Table", "Blitz", "Jackpot Poker", "Cash Game", "Beast"]
        case .unknown:
            return []
        }
    }
    
    var lobbyWindowPatterns: [String] {
        switch self {
        case .pokerStars:
            return ["Lobby", "Home", "Cashier", "Settings", "Tournament Lobby", "My Stars"]
        case .poker888:
            return ["Lobby", "My Account", "Cashier", "Settings", "Promotions"]
        case .ggPoker:
            return ["Lobby", "Smart HUD", "Cashier", "Profile", "Shop"]
        case .partyPoker:
            return ["Lobby", "My Account", "Cashier", "Rewards"]
        case .winamax:
            return ["Lobby", "Mon Compte", "Caisse", "Accueil"]
        case .ignition:
            return ["Lobby", "Cashier", "Rewards", "Account"]
        case .acr:
            return ["Lobby", "Cashier", "Missions", "The Beast"]
        case .unknown:
            return []
        }
    }
    
    static func from(bundleIdentifier: String) -> PokerApp {
        for app in PokerApp.allCases {
            if app.bundleIdentifiers.contains(where: { bundleIdentifier.lowercased().contains($0.lowercased()) }) {
                return app
            }
        }
        return .unknown
    }
    
    func isTableWindow(title: String) -> Bool {
        let lowercasedTitle = title.lowercased()
        
        // Check if it's a lobby window
        if lobbyWindowPatterns.contains(where: { lowercasedTitle.contains($0.lowercased()) }) {
            return false
        }
        
        // Check if it matches table patterns
        return tableWindowPatterns.contains(where: { lowercasedTitle.contains($0.lowercased()) })
    }
}

struct PokerTable: Identifiable {
    let id: String
    let windowInfo: WindowManager.WindowInfo
    let pokerApp: PokerApp
    let tableType: TableType
    let isActive: Bool
    
    init(windowInfo: WindowManager.WindowInfo) {
        self.id = windowInfo.id
        self.windowInfo = windowInfo
        self.pokerApp = PokerApp.from(bundleIdentifier: windowInfo.bundleIdentifier)
        self.tableType = TableType.from(title: windowInfo.title, app: self.pokerApp)
        self.isActive = windowInfo.isOnScreen && !windowInfo.title.isEmpty
    }
    
    enum TableType {
        case cash
        case tournament
        case sitAndGo
        case fastFold // Zoom, SNAP, Blitz, etc.
        case unknown
        
        static func from(title: String, app: PokerApp) -> TableType {
            let lowercasedTitle = title.lowercased()
            
            // Fast-fold variants
            if lowercasedTitle.contains("zoom") || 
               lowercasedTitle.contains("snap") || 
               lowercasedTitle.contains("blitz") ||
               lowercasedTitle.contains("zone") ||
               lowercasedTitle.contains("fast") ||
               lowercasedTitle.contains("rush") {
                return .fastFold
            }
            
            // Tournament indicators
            if lowercasedTitle.contains("tournament") ||
               lowercasedTitle.contains("mtt") ||
               lowercasedTitle.contains("turbo") ||
               lowercasedTitle.contains("bounty") {
                return .tournament
            }
            
            // Sit & Go indicators
            if lowercasedTitle.contains("sit & go") ||
               lowercasedTitle.contains("sit&go") ||
               lowercasedTitle.contains("sng") ||
               lowercasedTitle.contains("spin") ||
               lowercasedTitle.contains("jackpot") ||
               lowercasedTitle.contains("expresso") {
                return .sitAndGo
            }
            
            // Cash game indicators
            if lowercasedTitle.contains("cash") ||
               lowercasedTitle.contains("nl") ||
               lowercasedTitle.contains("pl") ||
               lowercasedTitle.contains("6-max") ||
               lowercasedTitle.contains("9-max") ||
               lowercasedTitle.contains("heads-up") {
                return .cash
            }
            
            // Default to cash if it's a table window but type is unclear
            if app.isTableWindow(title: title) {
                return .cash
            }
            
            return .unknown
        }
        
        var displayName: String {
            switch self {
            case .cash: return "Cash Game"
            case .tournament: return "Tournament"
            case .sitAndGo: return "Sit & Go"
            case .fastFold: return "Fast Fold"
            case .unknown: return "Unknown"
            }
        }
    }
}

class PokerTableDetector {
    
    func detectPokerTables(from windows: [WindowManager.WindowInfo]) -> [PokerTable] {
        var pokerTables: [PokerTable] = []
        
        for window in windows {
            if let pokerTable = analyzeWindow(window) {
                pokerTables.append(pokerTable)
            }
        }
        
        return pokerTables.sorted { $0.windowInfo.title < $1.windowInfo.title }
    }
    
    private func analyzeWindow(_ window: WindowManager.WindowInfo) -> PokerTable? {
        // First check if it's a poker app
        let pokerApp = PokerApp.from(bundleIdentifier: window.bundleIdentifier)
        guard pokerApp != .unknown else { return nil }
        
        // Create a potential poker table
        let potentialTable = PokerTable(windowInfo: window)
        
        // Filter out non-table windows
        guard isPokerTableWindow(potentialTable) else { return nil }
        
        return potentialTable
    }
    
    private func isPokerTableWindow(_ table: PokerTable) -> Bool {
        let title = table.windowInfo.title
        
        // Skip empty titles
        guard !title.isEmpty else { return false }
        
        // Skip if it's clearly a lobby window
        if table.pokerApp.lobbyWindowPatterns.contains(where: { title.lowercased().contains($0.lowercased()) }) {
            return false
        }
        
        // Skip common non-table windows
        let nonTablePatterns = [
            "cashier", "settings", "preferences", "options",
            "history", "statistics", "notes", "chat",
            "help", "about", "update", "install",
            "login", "register", "password", "account"
        ]
        
        let lowercasedTitle = title.lowercased()
        if nonTablePatterns.contains(where: { lowercasedTitle.contains($0) }) {
            return false
        }
        
        // Check if window is reasonable size for a poker table
        let bounds = table.windowInfo.bounds
        guard bounds.width >= 400 && bounds.height >= 300 else { return false }
        
        // If it matches table patterns, it's likely a table
        if table.pokerApp.isTableWindow(title: title) {
            return true
        }
        
        // Additional heuristics for tables that might not match patterns
        // Look for table number patterns (e.g., "Table 123456")
        let tableNumberPattern = try? NSRegularExpression(pattern: "table\\s*\\d+", options: .caseInsensitive)
        if tableNumberPattern?.firstMatch(in: title, options: [], range: NSRange(title.startIndex..., in: title)) != nil {
            return true
        }
        
        // Look for stakes patterns (e.g., "$0.50/$1.00", "€5/€10")
        let stakesPattern = try? NSRegularExpression(pattern: "[$€£]?\\d+([.,]\\d+)?/[$€£]?\\d+([.,]\\d+)?", options: [])
        if stakesPattern?.firstMatch(in: title, options: [], range: NSRange(title.startIndex..., in: title)) != nil {
            return true
        }
        
        // Look for player count patterns (e.g., "6-max", "9-handed")
        let playerCountPattern = try? NSRegularExpression(pattern: "\\d+[-\\s]?(max|handed|players)", options: .caseInsensitive)
        if playerCountPattern?.firstMatch(in: title, options: [], range: NSRange(title.startIndex..., in: title)) != nil {
            return true
        }
        
        return false
    }
    
    
    func groupTablesByApp(_ tables: [PokerTable]) -> [PokerApp: [PokerTable]] {
        return Dictionary(grouping: tables) { $0.pokerApp }
    }
    
    func groupTablesByType(_ tables: [PokerTable]) -> [PokerTable.TableType: [PokerTable]] {
        return Dictionary(grouping: tables) { $0.tableType }
    }
}

// MARK: - Test Utilities
extension WindowManager {
    func testPokerDetection() async {
        print("\n=== Testing Poker Table Detection ===")
        
        print("1. Checking permissions...")
        checkPermissions()
        print("   Screen recording permission: \(hasPermission ? "✅ Granted" : "❌ Not granted")")
        
        if !hasPermission {
            print("   ⚠️ Please grant screen recording permission in System Preferences > Privacy & Security > Screen Recording")
            return
        }
        
        print("\n2. Scanning for windows...")
        await scanWindows()
        
        print("\n3. Window Detection Results:")
        print("   Total windows found: \(windowCount)")
        print("   Poker app windows: \(getPokerAppWindows().count)")
        print("   Poker tables detected: \(pokerTables.count)")
        
        // Test poker app detection
        print("\n4. Poker App Detection:")
        let pokerWindows = getPokerAppWindows()
        if pokerWindows.isEmpty {
            print("   ❌ No poker applications detected")
            print("   Tip: Open a poker client (PokerStars, 888poker, etc.) to test detection")
        } else {
            print("   ✅ Found \(pokerWindows.count) poker app window(s):")
            for window in pokerWindows {
                let app = PokerApp.from(bundleIdentifier: window.bundleIdentifier)
                print("      - \(app.rawValue): \(window.title)")
                print("        Bundle: \(window.bundleIdentifier)")
            }
        }
        
        // Test poker table detection
        print("\n5. Poker Table Analysis:")
        if pokerTables.isEmpty {
            print("   ❌ No poker tables detected")
            print("   Tip: Open a poker table (not just the lobby) to test detection")
        } else {
            print("   ✅ Detected \(pokerTables.count) poker table(s):")
            
            // Group by app
            let tablesByApp = pokerTableDetector.groupTablesByApp(pokerTables)
            for (app, tables) in tablesByApp.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                print("\n   \(app.rawValue) (\(tables.count) tables):")
                for table in tables {
                    print("      - \(table.windowInfo.title)")
                    print("        Type: \(table.tableType.displayName)")
                    print("        Active: \(table.isActive ? "Yes" : "No")")
                    print("        Size: \(Int(table.windowInfo.bounds.width))×\(Int(table.windowInfo.bounds.height))")
                }
            }
            
            // Group by type
            let tablesByType = pokerTableDetector.groupTablesByType(pokerTables)
            print("\n   Tables by Type:")
            for (type, tables) in tablesByType {
                print("      - \(type.displayName): \(tables.count)")
            }
        }
        
        print("\n=== Test Complete ===\n")
    }
}
