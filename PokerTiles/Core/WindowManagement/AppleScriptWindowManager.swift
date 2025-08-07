//
//  AppleScriptWindowManager.swift
//  PokerTiles
//
//  Fallback window management using AppleScript for resistant windows
//

import Foundation
import AppKit
import OSLog

/// Manages window positioning using AppleScript as a fallback method
class AppleScriptWindowManager {
    
    // MARK: - Properties
    
    /// Cache of compiled scripts for performance
    private var scriptCache: [String: NSAppleScript] = [:]
    
    /// Check if we can use AppleScript
    var isAvailable: Bool {
        // Check if we have automation permission by attempting a simple script
        let testScript = "tell application \"System Events\" to return name of first process"
        if let script = NSAppleScript(source: testScript) {
            var error: NSDictionary?
            let _ = script.executeAndReturnError(&error)
            return error == nil
        }
        return false
    }
    
    // MARK: - Window Movement
    
    /// Move a window using AppleScript
    /// - Parameters:
    ///   - windowInfo: The window to move
    ///   - position: Target position
    /// - Returns: Success status
    @discardableResult
    func moveWindow(_ windowInfo: WindowInfo, to position: CGPoint) -> Bool {
        let script = """
            tell application "System Events"
                tell process "\(windowInfo.appName)"
                    try
                        set position of window "\(escapeString(windowInfo.title))" to {\(Int(position.x)), \(Int(position.y))}
                        return true
                    on error
                        -- Try by index if name fails
                        try
                            set position of window 1 to {\(Int(position.x)), \(Int(position.y))}
                            return true
                        on error
                            return false
                        end try
                    end try
                end tell
            end tell
        """
        
        return executeScript(script)
    }
    
    /// Resize a window using AppleScript
    /// - Parameters:
    ///   - windowInfo: The window to resize
    ///   - size: Target size
    /// - Returns: Success status
    @discardableResult
    func resizeWindow(_ windowInfo: WindowInfo, to size: CGSize) -> Bool {
        let script = """
            tell application "System Events"
                tell process "\(windowInfo.appName)"
                    try
                        set size of window "\(escapeString(windowInfo.title))" to {\(Int(size.width)), \(Int(size.height))}
                        return true
                    on error
                        -- Try by index if name fails
                        try
                            set size of window 1 to {\(Int(size.width)), \(Int(size.height))}
                            return true
                        on error
                            return false
                        end try
                    end try
                end tell
            end tell
        """
        
        return executeScript(script)
    }
    
    /// Set window frame (position and size)
    /// - Parameters:
    ///   - windowInfo: The window to manipulate
    ///   - frame: Target frame
    /// - Returns: Success status
    @discardableResult
    func setWindowFrame(_ windowInfo: WindowInfo, frame: CGRect) -> Bool {
        let script = """
            tell application "System Events"
                tell process "\(windowInfo.appName)"
                    try
                        tell window "\(escapeString(windowInfo.title))"
                            set position to {\(Int(frame.origin.x)), \(Int(frame.origin.y))}
                            set size to {\(Int(frame.size.width)), \(Int(frame.size.height))}
                        end tell
                        return true
                    on error
                        -- Try by index if name fails
                        try
                            tell window 1
                                set position to {\(Int(frame.origin.x)), \(Int(frame.origin.y))}
                                set size to {\(Int(frame.size.width)), \(Int(frame.size.height))}
                            end tell
                            return true
                        on error
                            return false
                        end try
                    end try
                end tell
            end tell
        """
        
        return executeScript(script)
    }
    
    // MARK: - Advanced Operations
    
    /// Bring window to front
    func bringWindowToFront(_ windowInfo: WindowInfo) -> Bool {
        // Try multiple approaches to bring the window to front
        // First try by exact title match
        let script = """
            tell application "System Events"
                tell process "\(windowInfo.appName)"
                    try
                        -- Make the process frontmost (required for window operations)
                        set frontmost to true
                        
                        -- Try to find and raise the specific window
                        set targetWindow to missing value
                        repeat with w in windows
                            if name of w contains "\(escapeString(windowInfo.title))" then
                                set targetWindow to w
                                exit repeat
                            end if
                        end repeat
                        
                        if targetWindow is not missing value then
                            perform action "AXRaise" of targetWindow
                            return true
                        else
                            return false
                        end if
                    on error
                        return false
                    end try
                end tell
            end tell
        """
        
        return executeScript(script)
    }
    
    /// Minimize window
    func minimizeWindow(_ windowInfo: WindowInfo) -> Bool {
        let script = """
            tell application "System Events"
                tell process "\(windowInfo.appName)"
                    try
                        set value of attribute "AXMinimized" of window "\(escapeString(windowInfo.title))" to true
                        return true
                    on error
                        return false
                    end try
                end tell
            end tell
        """
        
        return executeScript(script)
    }
    
    /// Check if window exists and is accessible
    func isWindowAccessible(_ windowInfo: WindowInfo) -> Bool {
        let script = """
            tell application "System Events"
                tell process "\(windowInfo.appName)"
                    try
                        get window "\(escapeString(windowInfo.title))"
                        return true
                    on error
                        return false
                    end try
                end tell
            end tell
        """
        
        return executeScript(script)
    }
    
    // MARK: - Poker-Specific Handlers
    
    /// Special handling for PokerStars windows
    func movePokerStarsWindow(_ windowInfo: WindowInfo, to position: CGPoint) -> Bool {
        // PokerStars sometimes needs the app to be frontmost
        let script = """
            tell application "PokerStars"
                activate
                delay 0.1
            end tell
            tell application "System Events"
                tell process "PokerStars"
                    try
                        set position of window "\(escapeString(windowInfo.title))" to {\(Int(position.x)), \(Int(position.y))}
                        return true
                    on error
                        return false
                    end try
                end tell
            end tell
        """
        
        return executeScript(script)
    }
    
    /// Handle browser-based poker windows
    func moveBrowserPokerWindow(_ windowInfo: WindowInfo, to position: CGPoint) -> Bool {
        // For browser windows, we need to handle tabs
        let browserName = windowInfo.appName
        let isKnownBrowser = ["Safari", "Google Chrome", "Firefox"].contains(browserName)
        
        if isKnownBrowser {
            let script = """
                tell application "\(browserName)"
                    activate
                    delay 0.1
                end tell
                tell application "System Events"
                    tell process "\(browserName)"
                        try
                            -- Find window containing the poker tab
                            set targetWindow to missing value
                            repeat with w in windows
                                if (name of w) contains "\(escapeString(windowInfo.title))" then
                                    set targetWindow to w
                                    exit repeat
                                end if
                            end repeat
                            
                            if targetWindow is not missing value then
                                set position of targetWindow to {\(Int(position.x)), \(Int(position.y))}
                                return true
                            else
                                return false
                            end if
                        on error
                            return false
                        end try
                    end tell
                end tell
            """
            
            return executeScript(script)
        }
        
        // Fallback to standard method
        return moveWindow(windowInfo, to: position)
    }
    
    // MARK: - Private Helpers
    
    /// Execute an AppleScript
    private func executeScript(_ source: String) -> Bool {
        // Check cache first
        if let cachedScript = scriptCache[source] {
            var error: NSDictionary?
            let result = cachedScript.executeAndReturnError(&error)
            
            if let error = error {
                Logger.windowMovement.error("AppleScript error: \(error)")
                return false
            }
            
            // Check if result indicates success
            if let boolResult = result.booleanValue {
                return boolResult
            }
            
            return true // NSAppleEventDescriptor is non-optional, so this is always true
        }
        
        // Compile and cache new script
        guard let script = NSAppleScript(source: source) else {
            Logger.windowMovement.error("Failed to compile AppleScript")
            return false
        }
        
        // Cache for future use (limit cache size)
        if scriptCache.count < 50 {
            scriptCache[source] = script
        }
        
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        
        if let error = error {
            Logger.windowMovement.error("AppleScript error: \(error)")
            return false
        }
        
        // Check if result indicates success
        if let boolResult = result.booleanValue {
            return boolResult
        }
        
        return true // NSAppleEventDescriptor is non-optional, so this is always true
    }
    
    /// Escape special characters in strings for AppleScript
    private func escapeString(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    /// Clear script cache
    func clearCache() {
        scriptCache.removeAll()
    }
}

// MARK: - NSAppleEventDescriptor Extension

extension NSAppleEventDescriptor {
    var booleanValue: Bool? {
        switch self.descriptorType {
        case typeTrue:
            return true
        case typeFalse:
            return false
        case typeBoolean:
            return self.booleanValue
        default:
            // Try to parse as string
            if let stringValue = self.stringValue?.lowercased() {
                return stringValue == "true" || stringValue == "yes" || stringValue == "1"
            }
            return nil
        }
    }
}