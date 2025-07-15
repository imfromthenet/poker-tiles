import Foundation
import ScreenCaptureKit
import AppKit
import Observation

@Observable
class WindowManager {
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
