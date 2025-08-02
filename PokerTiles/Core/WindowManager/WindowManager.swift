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
    var isInitialized: Bool = false
    var isAutoScanEnabled: Bool = true
    var autoScanInterval: TimeInterval = SettingsConstants.AutoScan.defaultInterval // Default 1 second
    
    let pokerTableDetector = PokerTableDetector()
    var pokerTables: [PokerTable] = []
    
    private var autoScanTask: Task<Void, Never>?
    
    // Window manipulation components
    private let windowManipulator = WindowManipulator()
    private let gridLayoutManager: GridLayoutManager
    private let resistanceDetector = WindowResistanceDetector()
    
    // Grid layout options (public for settings access)
    var gridLayoutOptions = GridLayoutManager.LayoutOptions() {
        didSet {
            // Update the layout manager with new options
            updateGridLayoutManager()
        }
    }
    
    // Hotkey management
    private(set) var hotkeyManager: HotkeyManager!
    
    // Grid overlay
    var gridOverlayManager: GridOverlayManager? {
        return hotkeyManager?.gridOverlayManager
    }
    
    init() {
        // Initialize grid layout manager with default options first
        gridLayoutManager = GridLayoutManager()
        
        checkPermissions()
        hotkeyManager = HotkeyManager(windowManager: self)
        // Don't start auto-scan immediately to prevent early screenshot capture
        // startAutoScan()
        
        // Load saved grid layout preferences
        loadGridLayoutPreferences()
        
        // Update grid layout manager with loaded preferences
        gridLayoutManager.updateOptions(gridLayoutOptions)
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
        try? await Task.sleep(nanoseconds: AnimationConstants.SleepInterval.medium) // 1.5 seconds
        
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
    
    func startAutoScanWithDelay(delay: TimeInterval = AnimationConstants.Duration.extraLong) {
        Task { @MainActor in
            // Wait for the specified delay before starting auto-scan
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Only start if still enabled and has permission
            if isAutoScanEnabled && hasPermission {
                startAutoScan()
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
        // Clamp interval between min and max allowed values
        autoScanInterval = min(max(SettingsConstants.AutoScan.minInterval, interval), SettingsConstants.AutoScan.maxInterval)
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
                
                // Only log failures
                if shouldCapture && thumbnail == nil {
                    print("❌ Failed to capture thumbnail for: \(window.title ?? "Unknown")")
                }
            }
            
            let capturedWindowInfos = windowInfos
            let detectedTables = self.pokerTableDetector.detectPokerTables(from: capturedWindowInfos)
            
            await MainActor.run {
                self.windows = capturedWindowInfos
                self.windowCount = capturedWindowInfos.count
                self.pokerTables = detectedTables
                self.isScanning = false
                self.isInitialized = true
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
            window.bounds.width > UIConstants.FrameDimensions.labelWidth &&
            window.bounds.height > UIConstants.FrameDimensions.labelWidth
        }
    }
    
    func bringWindowToFront(_ windowInfo: WindowInfo) {
        // First try to find if we're dealing with multiple windows from the same app
        let sameAppTables = pokerTables.filter { $0.windowInfo.bundleIdentifier == windowInfo.bundleIdentifier }
        
        if sameAppTables.count > 1 {
            // Multiple windows from same app - we need to be more specific
            // Try using accessibility API to raise specific window
            if let pid = windowInfo.scWindow?.owningApplication?.processID {
                focusSpecificWindow(windowInfo: windowInfo, pid: pid)
            }
        } else {
            // Single window from this app - safe to just activate the app
            
            // Use the new window manipulator for better reliability
            if windowManipulator.bringWindowToFront(windowInfo) {
                print("✅ Brought window '\(windowInfo.title)' from app '\(windowInfo.appName)' to front")
            } else {
                // Fallback to original method
                guard let scWindow = windowInfo.scWindow,
                      let app = scWindow.owningApplication else {
                    print("No owning application found for window")
                    return
                }
                
                let pid = app.processID
                let runningApp = NSRunningApplication(processIdentifier: pid)
                
                // Activate the application
                if #available(macOS 14.0, *) {
                    runningApp?.activate()
                } else {
                    runningApp?.activate(options: .activateIgnoringOtherApps)
                }
                
                print("Brought window '\(windowInfo.title)' from app '\(windowInfo.appName)' to front")
            }
        }
    }
    
    private func focusSpecificWindow(windowInfo: WindowInfo, pid: pid_t) {
        // Get the app element
        let appElement = AXUIElementCreateApplication(pid)
        
        // Get all windows
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success,
              let windows = windowsRef as? [AXUIElement] else {
            return
        }
        
        // Find the specific window by title
        for window in windows {
            var titleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
               let title = titleRef as? String {
                if title == windowInfo.title {
                    // Found our window - raise it
                    AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                    
                    // Also set it as main window
                    let mainRef: CFTypeRef = kCFBooleanTrue
                    AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, mainRef)
                    
                    // Activate the app
                    if let runningApp = NSRunningApplication(processIdentifier: pid) {
                        if #available(macOS 14.0, *) {
                            runningApp.activate()
                        } else {
                            runningApp.activate(options: .activateIgnoringOtherApps)
                        }
                    }
                    
                    return
                }
            }
        }
    }
    
    private func isAppWindow(_ window: SCWindow) -> Bool {
        guard let app = window.owningApplication else { return false }
        
        // Skip our own app - we don't need thumbnails of ourselves
        if app.bundleIdentifier == Bundle.main.bundleIdentifier {
            return false
        }
        
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
               window.frame.width > UIConstants.FrameDimensions.labelWidth &&
               window.frame.height > UIConstants.FrameDimensions.labelWidth
    }
    
    private func captureWindowThumbnail(_ window: SCWindow) async -> NSImage? {
        guard window.isOnScreen,
              window.frame.width > UIConstants.FrameDimensions.thumbnailSmall,
              window.frame.height > UIConstants.FrameDimensions.thumbnailSmall else {
            print("⏩ Skipping thumbnail for '\(window.title ?? "Unknown")' - not on screen or too small")
            return nil
        }
        
        return await captureWithScreenCaptureKit(window)
    }
    
    private func captureWithScreenCaptureKit(_ window: SCWindow) async -> NSImage? {
        do {
            // Try using SCScreenshotManager for a simpler one-shot capture
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let configuration = SCStreamConfiguration()
            
            // Set reasonable thumbnail size
            configuration.width = min(Int(UIConstants.FrameDimensions.thumbnailLarge), Int(window.frame.width))
            configuration.height = min(Int(UIConstants.FrameDimensions.thumbnailMedium), Int(window.frame.height))
            configuration.showsCursor = false
            configuration.scalesToFit = true
            
            if #available(macOS 14.0, *) {
                let screenshot = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: configuration
                )
                
                let nsImage = NSImage(cgImage: screenshot, size: CGSize(width: screenshot.width, height: screenshot.height))
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
                        try? await Task.sleep(nanoseconds: AnimationConstants.SleepInterval.standard) // 1 second timeout
                        
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

// MARK: - Window Manipulation
extension WindowManager {
    
    /// Move a window to a specific position
    func moveWindow(_ windowInfo: WindowInfo, to position: CGPoint) -> Bool {
        return windowManipulator.moveWindow(windowInfo, to: position)
    }
    
    /// Resize a window
    func resizeWindow(_ windowInfo: WindowInfo, to size: CGSize) -> Bool {
        return windowManipulator.resizeWindow(windowInfo, to: size)
    }
    
    /// Set window frame (position and size)
    func setWindowFrame(_ windowInfo: WindowInfo, frame: CGRect) -> Bool {
        return windowManipulator.setWindowFrame(windowInfo, frame: frame)
    }
    
    /// Arrange poker tables in a grid layout
    func arrangePokerTablesInGrid(_ layout: GridLayoutManager.GridLayout, on screen: NSScreen? = nil) {
        let tables = pokerTables.map { $0.windowInfo }
        let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first!
        
        // Calculate grid positions using our configured layout manager
        let grid = gridLayoutManager.calculateGridLayout(for: targetScreen, rows: layout.rows, cols: layout.columns)
        
        // Arrange windows using calculated positions
        var windowIndex = 0
        for row in 0..<layout.rows {
            for col in 0..<layout.columns {
                guard windowIndex < tables.count else { return }
                
                let window = tables[windowIndex]
                let frame = grid[row][col]
                
                _ = windowManipulator.setWindowFrame(window, frame: frame)
                windowIndex += 1
            }
        }
    }
    
    /// Auto-arrange all poker tables
    func autoArrangePokerTables() {
        guard !pokerTables.isEmpty else {
            print("No poker tables to arrange")
            return
        }
        
        // Use the preferred screen or main screen
        let screen = NSScreen.main ?? NSScreen.screens.first!
        
        // Get optimal layout
        let layout = gridLayoutManager.getBestLayout(for: pokerTables.count)
        print("Auto-arranging \(pokerTables.count) tables in \(layout.displayName) layout")
        
        arrangePokerTablesInGrid(layout, on: screen)
    }
    
    /// Cascade poker tables
    func cascadePokerTables() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let windows = pokerTables.map { $0.windowInfo }
        let frames = gridLayoutManager.createCascadeLayout(for: windows, on: screen)
        
        for (index, table) in pokerTables.enumerated() {
            if index < frames.count {
                _ = setWindowFrame(table.windowInfo, frame: frames[index])
            }
        }
    }
    
    /// Stack poker tables (all in same position)
    func stackPokerTables() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let windows = pokerTables.map { $0.windowInfo }
        let frames = gridLayoutManager.createStackLayout(for: windows, on: screen)
        
        for (index, table) in pokerTables.enumerated() {
            if index < frames.count {
                _ = setWindowFrame(table.windowInfo, frame: frames[index])
            }
        }
    }
    
    /// Distribute tables across multiple screens
    func distributeTablesAcrossScreens() {
        let screens = NSScreen.screens
        guard screens.count > 1 else {
            print("Only one screen available, using grid layout instead")
            autoArrangePokerTables()
            return
        }
        
        let windows = pokerTables.map { $0.windowInfo }
        let distribution = gridLayoutManager.distributeAcrossScreens(windows, screens: screens)
        
        for (window, _, frame) in distribution {
            _ = setWindowFrame(window, frame: frame)
        }
    }
    
    // MARK: - Grid Layout Preferences
    
    private func updateGridLayoutManager() {
        // Update the layout manager with new options
        gridLayoutManager.updateOptions(gridLayoutOptions)
    }
    
    private func loadGridLayoutPreferences() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: "gridPadding") != nil {
            gridLayoutOptions.padding = CGFloat(defaults.float(forKey: "gridPadding"))
        }
        
        if defaults.object(forKey: "gridWindowSpacing") != nil {
            gridLayoutOptions.windowSpacing = CGFloat(defaults.float(forKey: "gridWindowSpacing"))
        }
    }
    
    private func saveGridLayoutPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(Float(gridLayoutOptions.padding), forKey: "gridPadding")
        defaults.set(Float(gridLayoutOptions.windowSpacing), forKey: "gridWindowSpacing")
    }
    
    func setGridPadding(_ padding: CGFloat) {
        gridLayoutOptions.padding = max(AppSettings.minGridSpacing, min(AppSettings.maxGridSpacing, padding))
        saveGridLayoutPreferences()
    }
    
    func setGridWindowSpacing(_ spacing: CGFloat) {
        gridLayoutOptions.windowSpacing = max(AppSettings.minGridSpacing, min(AppSettings.maxGridSpacing, spacing))
        saveGridLayoutPreferences()
    }
    
    func setWallToWallLayout() {
        gridLayoutOptions.padding = SettingsConstants.GridLayout.minSpacing
        gridLayoutOptions.windowSpacing = SettingsConstants.GridLayout.minSpacing
        saveGridLayoutPreferences()
    }
}

