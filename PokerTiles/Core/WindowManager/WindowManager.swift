import Foundation
import ScreenCaptureKit
import AppKit
import Observation

@Observable
class WindowManager {
    var windowCount: Int = 0
    var windows: [WindowInfo] = []
    var hasPermission: Bool = false
    var isScanning: Bool = false
    
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
    }
    
    func checkPermissions() {
        hasPermission = CGPreflightScreenCaptureAccess()
    }
    
    func requestPermissions() async {
        CGRequestScreenCaptureAccess()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            self.checkPermissions()
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
                self.isScanning = false
            }
            
            print("Found \(windowInfos.count) windows")
            
        } catch {
            print("Failed to get window content: \(error)")
            await MainActor.run {
                self.isScanning = false
            }
        }
    }
    
    func getBrowserWindows() -> [WindowInfo] {
        let browserBundles = [
            "com.apple.Safari",
            "com.google.Chrome",
            "org.mozilla.firefox",
            "com.microsoft.edgemac",
            "com.brave.Browser",
            "com.operasoftware.Opera",
            "company.thebrowser.Browser"
        ]
        
        return windows.filter { window in
            browserBundles.contains(window.bundleIdentifier)
        }
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
        print("Browser windows: \(getBrowserWindows().count)")
        
        print("\n=== Applications ===")
        let appWindows = getAppWindows()
        let apps = Dictionary(grouping: appWindows) { $0.appName }
        for (app, windows) in apps.sorted(by: { $0.key < $1.key }) {
            print("\(app): \(windows.count) windows")
        }
        
        print("\n=== Browser Windows ===")
        let browserWindows = getBrowserWindows()
        for window in browserWindows {
            print("- \(window.appName): \(window.title)")
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
