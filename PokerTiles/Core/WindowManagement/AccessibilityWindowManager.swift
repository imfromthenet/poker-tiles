//
//  AccessibilityWindowManager.swift
//  PokerTiles
//
//  Window management using macOS Accessibility API (AXUIElement)
//

import Foundation
import AppKit
import ApplicationServices
import ScreenCaptureKit

/// Manages window positioning and sizing using the Accessibility API
class AccessibilityWindowManager {
    
    // MARK: - Properties
    
    /// Cache of process references to avoid repeated lookups
    private var processCache: [pid_t: AXUIElement] = [:]
    
    /// Check if we have accessibility permissions
    var hasPermission: Bool {
        return AXIsProcessTrusted()
    }
    
    // MARK: - Initialization
    
    init() {
        if !hasPermission {
            print("⚠️ Accessibility permission not granted. Window management will be limited.")
        }
    }
    
    // MARK: - Window Movement
    
    /// Move a window to a specific position
    /// - Parameters:
    ///   - windowInfo: The window to move
    ///   - position: Target position
    ///   - gradual: Whether to move gradually (helps with resistant windows)
    /// - Returns: Success status
    @discardableResult
    func moveWindow(_ windowInfo: WindowInfo, to position: CGPoint, gradual: Bool = false) -> Bool {
        guard hasPermission else {
            print("❌ No accessibility permission")
            return false
        }
        
        guard let window = getAXWindow(for: windowInfo) else {
            print("❌ Could not get AX reference for window")
            return false
        }
        
        // Check if window is moveable
        guard isWindowMoveable(window) else {
            print("❌ Window position is not settable")
            return false
        }
        
        if gradual {
            return moveWindowGradually(window, to: position)
        } else {
            return setWindowPosition(window, position)
        }
    }
    
    /// Resize a window
    /// - Parameters:
    ///   - windowInfo: The window to resize
    ///   - size: Target size
    /// - Returns: Success status
    @discardableResult
    func resizeWindow(_ windowInfo: WindowInfo, to size: CGSize) -> Bool {
        guard hasPermission else {
            print("❌ No accessibility permission")
            return false
        }
        
        guard let window = getAXWindow(for: windowInfo) else {
            print("❌ Could not get AX reference for window")
            return false
        }
        
        // Check if window is resizable
        guard isWindowResizable(window) else {
            print("❌ Window size is not settable")
            return false
        }
        
        return setWindowSize(window, size)
    }
    
    /// Move and resize a window in one operation
    /// - Parameters:
    ///   - windowInfo: The window to manipulate
    ///   - frame: Target frame (position and size)
    ///   - gradual: Whether to move gradually
    /// - Returns: Success status
    @discardableResult
    func setWindowFrame(_ windowInfo: WindowInfo, frame: CGRect, gradual: Bool = false) -> Bool {
        let moveSuccess = moveWindow(windowInfo, to: frame.origin, gradual: gradual)
        let resizeSuccess = resizeWindow(windowInfo, to: frame.size)
        return moveSuccess && resizeSuccess
    }
    
    // MARK: - Resistant Window Handling
    
    /// Move a window gradually to avoid rejection by resistant applications
    private func moveWindowGradually(_ window: AXUIElement, to targetPosition: CGPoint) -> Bool {
        guard let currentPos = getCurrentPosition(window) else {
            return false
        }
        
        let steps = 10
        var lastSuccessfulPosition = currentPos
        
        for i in 1...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let newX = currentPos.x + (targetPosition.x - currentPos.x) * progress
            let newY = currentPos.y + (targetPosition.y - currentPos.y) * progress
            let intermediatePosition = CGPoint(x: newX, y: newY)
            
            if setWindowPosition(window, intermediatePosition) {
                lastSuccessfulPosition = intermediatePosition
                Thread.sleep(forTimeInterval: 0.05) // Small delay between moves
            } else {
                // If a step fails, try to at least get to the last successful position
                print("⚠️ Gradual move failed at step \(i), reverting to last successful position")
                _ = setWindowPosition(window, lastSuccessfulPosition)
                return false
            }
        }
        
        // Verify final position
        if let finalPos = getCurrentPosition(window) {
            let tolerance: CGFloat = 5.0
            return abs(finalPos.x - targetPosition.x) < tolerance && 
                   abs(finalPos.y - targetPosition.y) < tolerance
        }
        
        return false
    }
    
    /// Move window with retry logic
    func moveWindowWithRetry(_ windowInfo: WindowInfo, to position: CGPoint, maxRetries: Int = 3) -> Bool {
        for attempt in 0..<maxRetries {
            if attempt > 0 {
                print("🔄 Retry attempt \(attempt + 1) for window movement")
                Thread.sleep(forTimeInterval: 0.1 * Double(attempt))
            }
            
            if moveWindow(windowInfo, to: position, gradual: attempt > 0) {
                return true
            }
        }
        
        print("❌ Failed to move window after \(maxRetries) attempts")
        return false
    }
    
    // MARK: - Private Helpers
    
    /// Get AXUIElement for a window
    private func getAXWindow(for windowInfo: WindowInfo) -> AXUIElement? {
        // Try to get the AXUIElement for the window
        let pid = windowInfo.owningApplication?.processIdentifier ?? 0
        guard pid > 0 else {
            print("❌ No valid PID for window")
            return nil
        }
        
        let app = AXUIElementCreateApplication(pid)
        
        // Get all windows for the app
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)
        
        if result != .success {
            print("❌ Failed to get windows: error \(result.rawValue)")
            return nil
        }
        
        guard let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
            print("❌ No windows found for app")
            return nil
        }
        
        // Match window by title
        for window in windows {
            var titleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
               let title = titleRef as? String,
               title == windowInfo.title {
                return window
            }
        }
        
        // If no match by title, try by position
        for window in windows {
            var posRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success {
                var currentPos = CGPoint.zero
                if let posValue = posRef {
                    AXValueGetValue(posValue as! AXValue, .cgPoint, &currentPos)
                    if abs(currentPos.x - windowInfo.bounds.origin.x) < 10 &&
                       abs(currentPos.y - windowInfo.bounds.origin.y) < 10 {
                        return window
                    }
                }
            }
        }
        
        // Fallback: return first window if only one exists
        if windows.count == 1 {
            return windows.first
        }
        
        return nil
    }
    
    /// Get window title
    private func getWindowTitle(_ window: AXUIElement) -> String? {
        var title: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title)
        guard result == .success else { return nil }
        return title as? String
    }
    
    /// Get current window position
    private func getCurrentPosition(_ window: AXUIElement) -> CGPoint? {
        var position: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &position)
        guard result == .success else { return nil }
        
        var point = CGPoint.zero
        if let positionValue = position {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &point)
            return point
        }
        return nil
    }
    
    /// Get current window size
    private func getCurrentSize(_ window: AXUIElement) -> CGSize? {
        var size: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &size)
        guard result == .success else { return nil }
        
        var cgSize = CGSize.zero
        if let sizeValue = size {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &cgSize)
            return cgSize
        }
        return nil
    }
    
    /// Set window position
    private func setWindowPosition(_ window: AXUIElement, _ position: CGPoint) -> Bool {
        var pos = position
        let positionValue = AXValueCreate(.cgPoint, &pos)!
        let result = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        
        if result != .success {
            print("❌ Failed to set position: \(result.rawValue)")
            return false
        }
        
        return true
    }
    
    /// Set window size
    private func setWindowSize(_ window: AXUIElement, _ size: CGSize) -> Bool {
        var sz = size
        let sizeValue = AXValueCreate(.cgSize, &sz)!
        let result = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        
        if result != .success {
            print("❌ Failed to set size: \(result.rawValue)")
            return false
        }
        
        return true
    }
    
    /// Check if window position is settable
    private func isWindowMoveable(_ window: AXUIElement) -> Bool {
        var settable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &settable)
        return settable.boolValue
    }
    
    /// Check if window size is settable
    private func isWindowResizable(_ window: AXUIElement) -> Bool {
        var settable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(window, kAXSizeAttribute as CFString, &settable)
        return settable.boolValue
    }
    
    // MARK: - Batch Operations
    
    /// Move multiple windows efficiently
    func moveWindows(_ windows: [(WindowInfo, CGPoint)]) {
        for (window, position) in windows {
            moveWindow(window, to: position)
        }
    }
    
    /// Request accessibility permission
    static func requestPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
}

// MARK: - Window State Detection

extension AccessibilityWindowManager {
    
    /// Detect if a window is in a resistant state
    func isWindowResistant(_ windowInfo: WindowInfo) -> Bool {
        guard let window = getAXWindow(for: windowInfo) else {
            return true // Can't get reference = resistant
        }
        
        // Test with a small movement
        guard let currentPos = getCurrentPosition(window) else {
            return true
        }
        
        let testPos = CGPoint(x: currentPos.x + 1, y: currentPos.y + 1)
        let success = setWindowPosition(window, testPos)
        
        if success {
            // Restore original position
            _ = setWindowPosition(window, currentPos)
            return false
        }
        
        return true
    }
    
    /// Get detailed window state
    func getWindowState(_ windowInfo: WindowInfo) -> WindowState {
        guard let window = getAXWindow(for: windowInfo) else {
            return WindowState(isAccessible: false, isMoveable: false, isResizable: false, currentPosition: nil, currentSize: nil)
        }
        
        return WindowState(
            isAccessible: true,
            isMoveable: isWindowMoveable(window),
            isResizable: isWindowResizable(window),
            currentPosition: getCurrentPosition(window),
            currentSize: getCurrentSize(window)
        )
    }
}

/// Window state information
struct WindowState {
    let isAccessible: Bool
    let isMoveable: Bool
    let isResizable: Bool
    let currentPosition: CGPoint?
    let currentSize: CGSize?
}

// MARK: - WindowInfo Extension

private extension WindowInfo {
    var owningApplication: NSRunningApplication? {
        guard let scWindow = scWindow,
              let app = scWindow.owningApplication else {
            return nil
        }
        return NSRunningApplication(processIdentifier: app.processID)
    }
}