//
//  PermissionManager.swift
//  PokerTiles
//
//  Manages all permissions required for window manipulation
//

import Foundation
import AppKit
import ApplicationServices

/// Manages all permissions required by PokerTiles
class PermissionManager {
    
    // MARK: - Types
    
    enum Permission: String, CaseIterable {
        case screenRecording = "Screen Recording"
        case accessibility = "Accessibility"
        
        var description: String {
            switch self {
            case .screenRecording:
                return "Required to capture poker table content and detect game states"
            case .accessibility:
                return "Required to move and resize poker table windows"
            }
        }
        
        var systemPreferencesURL: String {
            switch self {
            case .screenRecording:
                return "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            case .accessibility:
                return "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            }
        }
    }
    
    struct PermissionStatus {
        let permission: Permission
        let isGranted: Bool
        let canRequest: Bool
    }
    
    // MARK: - Screen Recording Permission
    
    static func hasScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    static func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }
    
    // MARK: - Accessibility Permission
    
    static func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    static func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    // MARK: - Combined Permission Check
    
    static func checkAllPermissions() -> [PermissionStatus] {
        return [
            PermissionStatus(
                permission: .screenRecording,
                isGranted: hasScreenRecordingPermission(),
                canRequest: true
            ),
            PermissionStatus(
                permission: .accessibility,
                isGranted: hasAccessibilityPermission(),
                canRequest: true
            )
        ]
    }
    
    static func getMissingPermissions() -> [Permission] {
        var missing: [Permission] = []
        
        if !hasScreenRecordingPermission() {
            missing.append(.screenRecording)
        }
        
        if !hasAccessibilityPermission() {
            missing.append(.accessibility)
        }
        
        return missing
    }
    
    static func hasAllPermissions() -> Bool {
        return hasScreenRecordingPermission() && hasAccessibilityPermission()
    }
    
    static func hasScreenRecordingOnly() -> Bool {
        return hasScreenRecordingPermission() && !hasAccessibilityPermission()
    }
    
    static func hasAccessibilityOnly() -> Bool {
        return !hasScreenRecordingPermission() && hasAccessibilityPermission()
    }
    
    static func hasAnyPermission() -> Bool {
        return hasScreenRecordingPermission() || hasAccessibilityPermission()
    }
    
    // MARK: - System Preferences
    
    static func openSystemPreferences(for permission: Permission) {
        if let url = URL(string: permission.systemPreferencesURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    static func openPermissionSettings() {
        // Open general privacy settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Permission Request Flow
    
    static func requestPermission(_ permission: Permission) {
        switch permission {
        case .screenRecording:
            requestScreenRecordingPermission()
        case .accessibility:
            requestAccessibilityPermission()
        }
    }
    
    static func requestAllPermissions() {
        if !hasScreenRecordingPermission() {
            requestScreenRecordingPermission()
        }
        
        if !hasAccessibilityPermission() {
            // Small delay to avoid overwhelming the user
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                requestAccessibilityPermission()
            }
        }
    }
    
    // MARK: - Permission Monitoring
    
    static func startMonitoringPermissions(callback: @escaping ([PermissionStatus]) -> Void) -> Timer {
        // Check permissions every 2 seconds
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let status = checkAllPermissions()
            callback(status)
        }
        
        // Initial check
        callback(checkAllPermissions())
        
        return timer
    }
    
    // MARK: - User Guidance
    
    static func getPermissionInstructions(_ permission: Permission) -> String {
        switch permission {
        case .screenRecording:
            return """
            To grant Screen Recording permission:
            1. Click "Open System Preferences" below
            2. Find PokerTiles in the list
            3. Toggle the switch to enable Screen Recording
            4. You may need to restart PokerTiles
            """
        case .accessibility:
            return """
            To grant Accessibility permission:
            1. Click "Open System Preferences" below
            2. Click the lock icon to make changes
            3. Find PokerTiles in the list
            4. Check the box next to PokerTiles
            """
        }
    }
    
    // MARK: - Automation Permission (for AppleScript)
    
    static func hasAutomationPermission(for bundleIdentifier: String = "com.apple.systemevents") -> Bool {
        // Try to execute a simple AppleScript to check automation permission
        let script = "tell application \"System Events\" to return name of first process"
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let _ = appleScript.executeAndReturnError(&error)
            return error == nil
        }
        
        return false
    }
    
    static func requestAutomationPermission() {
        // Execute a simple AppleScript that will trigger the automation permission dialog
        let script = "tell application \"System Events\" to return name of first process"
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}