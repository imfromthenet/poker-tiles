//
//  WindowResistanceDetector.swift
//  PokerTiles
//
//  Detects and handles windows that resist manipulation
//

import Foundation
import AppKit
import OSLog

/// Detects and categorizes window resistance patterns
class WindowResistanceDetector {
    
    // MARK: - Types
    
    /// Types of window resistance
    enum ResistanceType {
        case none                    // Window moves freely
        case permissionDenied       // Lack of accessibility/automation permissions
        case applicationLocked      // App prevents external manipulation
        case fullScreenMode         // Window is in fullscreen
        case displayBoundaryLock    // Window validates against display bounds
        case minimized             // Window is minimized
        case systemWindow          // System-level window
        case unknown              // Resistance detected but cause unknown
    }
    
    /// Window resistance profile
    struct ResistanceProfile {
        let windowInfo: WindowInfo
        let resistanceType: ResistanceType
        let isMoveable: Bool
        let isResizable: Bool
        let suggestedMethod: WindowManipulator.WindowManipulationMethod?
        let details: String
    }
    
    // MARK: - Properties
    
    private let accessibilityManager = AccessibilityWindowManager()
    private let appleScriptManager = AppleScriptWindowManager()
    
    /// Known resistant applications and their patterns
    private let knownResistantApps: [String: ResistancePattern] = [
        "PokerStars": ResistancePattern(
            type: .displayBoundaryLock,
            workaround: .appleScriptFirst,
            details: "PokerStars validates window positions against display bounds"
        ),
        "888poker": ResistancePattern(
            type: .applicationLocked,
            workaround: .gradualMovement,
            details: "888poker may lock window positions during active play"
        ),
        "GGPoker": ResistancePattern(
            type: .applicationLocked,
            workaround: .accessibilityWithRetry,
            details: "GGPoker requires multiple attempts for window movement"
        )
    ]
    
    private struct ResistancePattern {
        let type: ResistanceType
        let workaround: WindowManipulator.WindowManipulationMethod
        let details: String
    }
    
    // MARK: - Detection Methods
    
    /// Analyze a window for resistance patterns
    func analyzeWindow(_ windowInfo: WindowInfo) -> ResistanceProfile {
        // Check known resistant apps first
        if let pattern = knownResistantApps[windowInfo.appName] {
            let state = accessibilityManager.getWindowState(windowInfo)
            
            return ResistanceProfile(
                windowInfo: windowInfo,
                resistanceType: pattern.type,
                isMoveable: state.isMoveable,
                isResizable: state.isResizable,
                suggestedMethod: pattern.workaround,
                details: pattern.details
            )
        }
        
        // Check permissions
        if !accessibilityManager.hasPermission {
            return ResistanceProfile(
                windowInfo: windowInfo,
                resistanceType: .permissionDenied,
                isMoveable: false,
                isResizable: false,
                suggestedMethod: nil,
                details: "Accessibility permission not granted"
            )
        }
        
        // Get window state
        let state = accessibilityManager.getWindowState(windowInfo)
        
        // Check if window is accessible at all
        if !state.isAccessible {
            // Try AppleScript as fallback test
            if appleScriptManager.isWindowAccessible(windowInfo) {
                return ResistanceProfile(
                    windowInfo: windowInfo,
                    resistanceType: .applicationLocked,
                    isMoveable: false,
                    isResizable: false,
                    suggestedMethod: .appleScriptFirst,
                    details: "Window not accessible via Accessibility API but responds to AppleScript"
                )
            } else {
                return ResistanceProfile(
                    windowInfo: windowInfo,
                    resistanceType: .unknown,
                    isMoveable: false,
                    isResizable: false,
                    suggestedMethod: nil,
                    details: "Window not accessible via any method"
                )
            }
        }
        
        // Check specific resistance patterns
        if isSystemWindow(windowInfo) {
            return ResistanceProfile(
                windowInfo: windowInfo,
                resistanceType: .systemWindow,
                isMoveable: false,
                isResizable: false,
                suggestedMethod: nil,
                details: "System windows cannot be manipulated"
            )
        }
        
        if isFullScreen(windowInfo) {
            return ResistanceProfile(
                windowInfo: windowInfo,
                resistanceType: .fullScreenMode,
                isMoveable: false,
                isResizable: false,
                suggestedMethod: nil,
                details: "Fullscreen windows cannot be moved or resized"
            )
        }
        
        if isMinimized(windowInfo) {
            return ResistanceProfile(
                windowInfo: windowInfo,
                resistanceType: .minimized,
                isMoveable: false,
                isResizable: false,
                suggestedMethod: nil,
                details: "Minimized windows must be restored first"
            )
        }
        
        // Test actual manipulation
        let resistanceType = testManipulationResistance(windowInfo, state: state)
        
        return ResistanceProfile(
            windowInfo: windowInfo,
            resistanceType: resistanceType,
            isMoveable: state.isMoveable,
            isResizable: state.isResizable,
            suggestedMethod: getSuggestedMethod(for: resistanceType),
            details: getResistanceDetails(resistanceType, windowInfo: windowInfo)
        )
    }
    
    /// Batch analyze multiple windows
    func analyzeWindows(_ windows: [WindowInfo]) -> [ResistanceProfile] {
        return windows.map { analyzeWindow($0) }
    }
    
    /// Get resistant windows from a list
    func getResistantWindows(from windows: [WindowInfo]) -> [WindowInfo] {
        return windows.filter { window in
            let profile = analyzeWindow(window)
            return profile.resistanceType != .none
        }
    }
    
    // MARK: - Private Detection Methods
    
    /// Test manipulation resistance by attempting small movements
    private func testManipulationResistance(_ windowInfo: WindowInfo, state: WindowState) -> ResistanceType {
        // If not moveable according to state, determine why
        if !state.isMoveable && !state.isResizable {
            return .applicationLocked
        }
        
        // Test with actual movement
        if accessibilityManager.isWindowResistant(windowInfo) {
            // Check if it's a display boundary issue
            if isNearDisplayBoundary(windowInfo) {
                return .displayBoundaryLock
            }
            return .unknown
        }
        
        return .none
    }
    
    /// Check if window is a system window
    private func isSystemWindow(_ windowInfo: WindowInfo) -> Bool {
        let systemBundles = [
            "com.apple.dock",
            "com.apple.controlcenter",
            "com.apple.notificationcenterui",
            "com.apple.systemuiserver",
            "com.apple.finder" // Finder windows are special
        ]
        
        return systemBundles.contains { windowInfo.bundleIdentifier.hasPrefix($0) }
    }
    
    /// Check if window is in fullscreen mode
    private func isFullScreen(_ windowInfo: WindowInfo) -> Bool {
        // Check if window bounds match screen bounds
        for screen in NSScreen.screens {
            if windowInfo.bounds.equalTo(screen.frame) {
                return true
            }
        }
        return false
    }
    
    /// Check if window is minimized
    private func isMinimized(_ windowInfo: WindowInfo) -> Bool {
        // Windows with negative Y coordinates are often minimized
        return windowInfo.bounds.origin.y < -1000
    }
    
    /// Check if window is near display boundary
    private func isNearDisplayBoundary(_ windowInfo: WindowInfo) -> Bool {
        guard let screen = NSScreen.screenContaining(window: windowInfo) else {
            return false
        }
        
        let threshold: CGFloat = 50
        let bounds = windowInfo.bounds
        let screenFrame = screen.frame
        
        return bounds.minX <= screenFrame.minX + threshold ||
               bounds.maxX >= screenFrame.maxX - threshold ||
               bounds.minY <= screenFrame.minY + threshold ||
               bounds.maxY >= screenFrame.maxY - threshold
    }
    
    /// Get suggested manipulation method for resistance type
    private func getSuggestedMethod(for type: ResistanceType) -> WindowManipulator.WindowManipulationMethod? {
        switch type {
        case .none:
            return .accessibilityFirst
        case .displayBoundaryLock:
            return .gradualMovement
        case .applicationLocked:
            return .appleScriptFirst
        case .permissionDenied, .fullScreenMode, .minimized, .systemWindow:
            return nil
        case .unknown:
            return .accessibilityWithRetry
        }
    }
    
    /// Get human-readable details for resistance type
    private func getResistanceDetails(_ type: ResistanceType, windowInfo: WindowInfo) -> String {
        switch type {
        case .none:
            return "Window can be manipulated normally"
        case .permissionDenied:
            return "Grant accessibility permissions in System Preferences"
        case .applicationLocked:
            return "\(windowInfo.appName) is preventing window manipulation"
        case .fullScreenMode:
            return "Exit fullscreen mode to move or resize window"
        case .displayBoundaryLock:
            return "Window position is locked to display boundaries"
        case .minimized:
            return "Restore window from dock to manipulate"
        case .systemWindow:
            return "System windows cannot be manipulated"
        case .unknown:
            return "Window resists manipulation for unknown reasons"
        }
    }
    
    // MARK: - Workaround Strategies
    
    /// Apply workaround for resistant window
    func applyWorkaround(for profile: ResistanceProfile, targetFrame: CGRect) -> Bool {
        guard profile.suggestedMethod != nil else {
            Logger.windowMovement.error("No workaround available for \(String(describing: profile.resistanceType))")
            return false
        }
        
        let manipulator = WindowManipulator()
        
        switch profile.resistanceType {
        case .minimized:
            // First restore the window
            if restoreMinimizedWindow(profile.windowInfo) {
                // Wait for restoration
                Thread.sleep(forTimeInterval: 0.5)
                // Then try to move it
                return manipulator.setWindowFrame(profile.windowInfo, frame: targetFrame)
            }
            return false
            
        case .displayBoundaryLock:
            // Move in smaller steps to avoid boundary validation
            return moveWithinBoundaries(profile.windowInfo, to: targetFrame)
            
        default:
            // Use suggested method directly
            return manipulator.setWindowFrame(profile.windowInfo, frame: targetFrame)
        }
    }
    
    /// Restore minimized window
    private func restoreMinimizedWindow(_ windowInfo: WindowInfo) -> Bool {
        let script = """
            tell application "System Events"
                tell process "\(windowInfo.appName)"
                    try
                        set value of attribute "AXMinimized" of window "\(windowInfo.title)" to false
                        return true
                    on error
                        return false
                    end try
                end tell
            end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            _ = appleScript.executeAndReturnError(&error)
            return error == nil // result is non-optional NSAppleEventDescriptor
        }
        
        return false
    }
    
    /// Move window while respecting display boundaries
    private func moveWithinBoundaries(_ windowInfo: WindowInfo, to frame: CGRect) -> Bool {
        guard let screen = NSScreen.screenContaining(window: windowInfo) else {
            return false
        }
        
        // Ensure frame is within screen bounds
        var adjustedFrame = frame
        let screenFrame = screen.visibleFrame
        
        // Adjust position to keep window on screen
        adjustedFrame.origin.x = max(screenFrame.minX, min(adjustedFrame.origin.x, screenFrame.maxX - adjustedFrame.width))
        adjustedFrame.origin.y = max(screenFrame.minY, min(adjustedFrame.origin.y, screenFrame.maxY - adjustedFrame.height))
        
        // Adjust size if necessary
        adjustedFrame.size.width = min(adjustedFrame.width, screenFrame.width)
        adjustedFrame.size.height = min(adjustedFrame.height, screenFrame.height)
        
        let manipulator = WindowManipulator()
        return manipulator.setWindowFrame(windowInfo, frame: adjustedFrame)
    }
}