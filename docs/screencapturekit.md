# ScreenCaptureKit Documentation

## Overview
ScreenCaptureKit provides high-performance screen capture capabilities for analyzing poker table visuals and positioning overlays.

## Key Classes

### SCStreamConfiguration
Configure capture settings for optimal performance.

```swift
let config = SCStreamConfiguration()
config.width = 1920
config.height = 1080
config.minimumFrameInterval = CMTime(value: 1, timescale: 60) // 60 FPS
config.queueDepth = 3
config.showsCursor = false
config.scalesToFit = false
config.colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
config.pixelFormat = kCVPixelFormatType_32BGRA
```

### SCContentFilter
Filter content to capture specific windows or applications.

```swift
// Capture specific window
let filter = SCContentFilter(desktopIndependentWindow: window)

// Capture entire display
let filter = SCContentFilter(display: display, excludingWindows: [])

// Capture application windows
let filter = SCContentFilter(desktopIndependentWindow: window)
```

### SCStream
Main capture stream for processing frames.

```swift
class PokerTableCapture: SCStreamOutput {
    private var stream: SCStream?
    
    func startCapture(window: SCWindow) {
        let config = SCStreamConfiguration()
        let filter = SCContentFilter(desktopIndependentWindow: window)
        
        stream = SCStream(filter: filter, configuration: config, delegate: nil)
        
        do {
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
            stream?.startCapture()
        } catch {
            print("Failed to start capture: \(error)")
        }
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Process the captured frame
        processPokerTableFrame(imageBuffer)
    }
}
```

## Content Discovery

### Finding Poker Applications
```swift
func findPokerWindows() async -> [SCWindow] {
    do {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        return content.windows.filter { window in
            guard let app = window.owningApplication else { return false }
            
            // Check for browser applications
            let browserBundles = [
                "com.apple.Safari",
                "com.google.Chrome",
                "org.mozilla.firefox",
                "com.microsoft.edgemac"
            ]
            
            return browserBundles.contains(app.bundleIdentifier) && 
                   window.title?.contains("poker") == true
        }
    } catch {
        print("Failed to get shareable content: \(error)")
        return []
    }
}
```

### Window Monitoring
```swift
func setupWindowMonitoring() {
    NotificationCenter.default.addObserver(
        forName: NSWindow.didBecomeKeyNotification,
        object: nil,
        queue: .main
    ) { notification in
        if let window = notification.object as? NSWindow {
            checkIfPokerWindow(window)
        }
    }
}
```

## Frame Processing

### Converting to CGImage
```swift
func createCGImage(from imageBuffer: CVImageBuffer) -> CGImage? {
    let ciImage = CIImage(cvImageBuffer: imageBuffer)
    let context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)])
    
    return context.createCGImage(ciImage, from: ciImage.extent)
}
```

### Cropping Table Regions
```swift
func cropTableRegion(from image: CGImage, bounds: CGRect) -> CGImage? {
    return image.cropping(to: bounds)
}
```

## Performance Optimization

### Efficient Capture Settings
```swift
// Optimize for poker table detection
let config = SCStreamConfiguration()
config.width = 1280  // Reduce resolution for better performance
config.height = 720
config.minimumFrameInterval = CMTime(value: 1, timescale: 30)  // 30 FPS sufficient
config.queueDepth = 2  // Minimize latency
config.capturesAudio = false  // Disable audio capture
```

### Selective Processing
```swift
func processFrameSelectively(_ imageBuffer: CVImageBuffer) {
    // Only process frames when poker action is detected
    guard tableNeedsUpdate else { return }
    
    let image = createCGImage(from: imageBuffer)
    analyzePokerElements(image)
}
```

## Common Patterns

### Table Region Tracking
```swift
class PokerTableTracker {
    private var lastKnownBounds: CGRect?
    private var stableFrameCount = 0
    
    func updateTableBounds(_ bounds: CGRect) {
        if bounds == lastKnownBounds {
            stableFrameCount += 1
        } else {
            stableFrameCount = 0
            lastKnownBounds = bounds
        }
        
        // Consider bounds stable after 10 consistent frames
        if stableFrameCount >= 10 {
            confirmTablePosition(bounds)
        }
    }
}
```

### Multi-Window Capture
```swift
class MultiTableCapture {
    private var streams: [SCWindow: SCStream] = [:]
    
    func startCaptureForAllTables() {
        Task {
            let windows = await findPokerWindows()
            
            for window in windows {
                let stream = createStream(for: window)
                streams[window] = stream
                try? stream.startCapture()
            }
        }
    }
}
```

## Required Permissions

Add to Info.plist:
```xml
<key>NSCameraUsageDescription</key>
<string>PockerTile needs screen recording access to capture poker table content for analysis.</string>
```

Request permissions:
```swift
func requestScreenCapturePermissions() {
    guard CGPreflightScreenCaptureAccess() else {
        CGRequestScreenCaptureAccess()
        return
    }
}
```

## Error Handling

```swift
func handleCaptureError(_ error: Error) {
    if let scError = error as? SCStreamError {
        switch scError.code {
        case .userDeclined:
            // Handle permission denied
            promptForPermissions()
        case .failedToStart:
            // Handle capture failure
            retryCapture()
        default:
            print("Capture error: \(error)")
        }
    }
}
```