//
//  DirectWindowMover.swift
//  PokerTiles
//
//  Direct window movement implementation for debugging
//

import Foundation
import AppKit
import ApplicationServices

/// Direct window mover that bypasses caching and complex logic
class DirectWindowMover {
    
    /// Attempt to move any visible window as a test
    static func testMoveFirstWindow() -> Bool {
        guard AXIsProcessTrusted() else {
            print("❌ Not trusted")
            return false
        }
        
        // Get all running apps
        let apps = NSWorkspace.shared.runningApplications.filter { app in
            app.activationPolicy == .regular && !app.isHidden
        }
        
        for app in apps {
            if app.localizedName == "Finder" || app.localizedName == "Dock" {
                continue
            }
            
            print("Testing app: \(app.localizedName ?? "Unknown")")
            
            // Activate the app
            app.activate(options: .activateIgnoringOtherApps)
            Thread.sleep(forTimeInterval: 0.5)
            
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            
            var windowsRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
            
            if result == .success,
               let windows = windowsRef as? [AXUIElement],
               !windows.isEmpty {
                
                let window = windows[0]
                
                // Try to move it
                var newPos = CGPoint(x: 100, y: 100)
                let posValue = AXValueCreate(.cgPoint, &newPos)!
                let moveResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
                
                if moveResult == .success {
                    print("✅ Successfully moved window!")
                    return true
                } else {
                    print("❌ Failed to move: \(moveResult.rawValue)")
                }
            }
        }
        
        return false
    }
    
    /// Direct move for a specific app by name with verification
    static func moveAppWindow(appName: String, to position: CGPoint) -> Bool {
        guard AXIsProcessTrusted() else {
            print("❌ Not AXTrusted")
            return false
        }
        
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == appName }) else {
            print("App not found: \(appName)")
            return false
        }
        
        print("Found app: \(appName) with PID: \(app.processIdentifier)")
        
        // Ensure app is active
        if !app.isActive {
            app.activate(options: .activateIgnoringOtherApps)
            Thread.sleep(forTimeInterval: 0.3)
        }
        
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        
        var windowsRef: CFTypeRef?
        var attempts = 0
        var result: AXError = .cannotComplete
        
        // Retry a few times
        while attempts < 3 && result != .success {
            result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
            if result != .success {
                print("Attempt \(attempts + 1) failed, retrying...")
                Thread.sleep(forTimeInterval: 0.2)
                attempts += 1
            }
        }
        
        guard result == .success,
              let windows = windowsRef as? [AXUIElement],
              !windows.isEmpty else {
            print("Could not get windows after \(attempts) attempts")
            return false
        }
        
        let window = windows[0]
        
        // Get current position first
        var currentPosRef: CFTypeRef?
        var currentPos = CGPoint.zero
        if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &currentPosRef) == .success,
           let posValue = currentPosRef {
            AXValueGetValue(posValue as! AXValue, .cgPoint, &currentPos)
            print("Current position: \(currentPos)")
        }
        
        // Check if position is settable
        var settable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &settable)
        
        if !settable.boolValue {
            print("Window position is not settable")
            return false
        }
        
        // Move the window
        var pos = position
        let posValue = AXValueCreate(.cgPoint, &pos)!
        let moveResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        
        if moveResult == .success {
            print("Move command succeeded")
            
            // Verify the move
            Thread.sleep(forTimeInterval: 0.2)
            var newPosRef: CFTypeRef?
            var newPos = CGPoint.zero
            if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &newPosRef) == .success,
               let posValue = newPosRef {
                AXValueGetValue(posValue as! AXValue, .cgPoint, &newPos)
                print("New position: \(newPos)")
                
                // Check if position actually changed
                let moved = abs(newPos.x - position.x) < 5 && abs(newPos.y - position.y) < 5
                if moved {
                    print("✅ Window successfully moved to target position")
                } else if abs(newPos.x - currentPos.x) > 5 || abs(newPos.y - currentPos.y) > 5 {
                    print("⚠️ Window moved but not to exact target")
                } else {
                    print("❌ Window position did not change")
                    return false
                }
            }
        }
        
        return moveResult == .success
    }
    
    /// Test window resize functionality
    static func testResizeWindow(appName: String, to size: CGSize) -> Bool {
        guard AXIsProcessTrusted() else {
            return false
        }
        
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == appName }) else {
            print("App not found: \(appName)")
            return false
        }
        
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        
        var windowsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) != .success {
            return false
        }
        
        guard let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
            return false
        }
        
        let window = windows[0]
        
        // Get current size
        var currentSizeRef: CFTypeRef?
        var currentSize = CGSize.zero
        if AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &currentSizeRef) == .success,
           let sizeValue = currentSizeRef {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &currentSize)
            print("Current size: \(currentSize)")
        }
        
        // Check if size is settable
        var settable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(window, kAXSizeAttribute as CFString, &settable)
        
        if !settable.boolValue {
            print("Window size is not settable")
            return false
        }
        
        // Resize the window
        var newSize = size
        let sizeValue = AXValueCreate(.cgSize, &newSize)!
        let resizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        
        if resizeResult == .success {
            print("Resize command succeeded")
            
            // Verify
            Thread.sleep(forTimeInterval: 0.2)
            var verifiedSizeRef: CFTypeRef?
            var verifiedSize = CGSize.zero
            if AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &verifiedSizeRef) == .success,
               let sizeValue = verifiedSizeRef {
                AXValueGetValue(sizeValue as! AXValue, .cgSize, &verifiedSize)
                print("New size: \(verifiedSize)")
                
                if abs(verifiedSize.width - size.width) < 5 && abs(verifiedSize.height - size.height) < 5 {
                    print("✅ Window successfully resized")
                } else {
                    print("⚠️ Window resized but not to exact dimensions")
                }
            }
        }
        
        return resizeResult == .success
    }
}