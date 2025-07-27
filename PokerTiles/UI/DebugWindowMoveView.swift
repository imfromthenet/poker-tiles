//
//  DebugWindowMoveView.swift
//  PokerTiles
//
//  Debug view to test window movement directly
//

import SwiftUI
import AppKit
import ApplicationServices

struct DebugWindowMoveView: View {
    @State private var logText = ""
    @State private var hasPermission = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Window Movement Debug")
                .font(.headline)
            
            HStack {
                Text("Accessibility Permission:")
                Text(hasPermission ? "✅ Granted" : "❌ Not Granted")
                    .foregroundColor(hasPermission ? .green : .red)
                    .fontWeight(.bold)
            }
            
            HStack(spacing: 10) {
                Button("Check Permission") {
                    checkPermission()
                }
                
                Button("Request Permission") {
                    requestPermission()
                }
                
                Button("Test Move Window") {
                    testMoveWindow()
                }
                .disabled(!hasPermission)
                
                Button("Test Direct Move") {
                    testDirectMove()
                }
                .disabled(!hasPermission)
                
                Button("Test Poker Window") {
                    testPokerWindow()
                }
                .disabled(!hasPermission)
                
                Button("Test Browser Move") {
                    testBrowserMove()
                }
                .disabled(!hasPermission)
            }
            .buttonStyle(.bordered)
            
            HStack(spacing: 10) {
                Button("Test 2x2 Grid") {
                    testGridArrangement(rows: 2, cols: 2)
                }
                .disabled(!hasPermission)
                
                Button("Test 3x3 Grid") {
                    testGridArrangement(rows: 3, cols: 3)
                }
                .disabled(!hasPermission)
            }
            .buttonStyle(.bordered)
            
            Divider()
            
            ScrollView {
                Text(logText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)
            
            HStack {
                Button("Clear Log") {
                    logText = ""
                }
                .buttonStyle(.link)
                
                Spacer()
                
                Button("Copy Log") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(logText, forType: .string)
                }
                .buttonStyle(.link)
            }
        }
        .padding()
        .onAppear {
            checkPermission()
        }
    }
    
    private func log(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        logText += "[\(timestamp)] \(message)\n"
    }
    
    private func checkPermission() {
        hasPermission = AXIsProcessTrusted()
        log("Permission check: \(hasPermission ? "Granted" : "Not Granted")")
        
        // Additional diagnostics
        log("Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        log("Executable: \(Bundle.main.executablePath ?? "Unknown")")
    }
    
    private func requestPermission() {
        log("Requesting permission...")
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let result = AXIsProcessTrustedWithOptions(options)
        log("Request result: \(result)")
        
        // Check again after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            checkPermission()
        }
    }
    
    private func testMoveWindow() {
        log("\n=== Starting Window Move Test ===")
        
        // Find a simple window to test with
        let apps = NSWorkspace.shared.runningApplications
        var testApp: NSRunningApplication?
        
        // Try to find a suitable app - avoid Finder as it can be problematic
        let preferredApps = ["TextEdit", "Safari", "Google Chrome", "Notes", "Calculator"]
        
        for preferredName in preferredApps {
            if let found = apps.first(where: { $0.localizedName == preferredName }) {
                testApp = found
                log("Found test app: \(preferredName) (PID: \(found.processIdentifier))")
                break
            }
        }
        
        // If no preferred app, try any regular app
        if testApp == nil {
            testApp = apps.first { app in
                app.activationPolicy == .regular && 
                !app.isHidden && 
                app.localizedName != "Finder" &&
                app.localizedName != "Dock"
            }
            if let app = testApp {
                log("Using app: \(app.localizedName ?? "Unknown") (PID: \(app.processIdentifier))")
            }
        }
        
        guard let app = testApp else {
            log("❌ No suitable test app found")
            return
        }
        
        // Get AX reference
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        
        // Get windows
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
        
        if result != .success {
            log("❌ Failed to get windows: \(errorDescription(for: result))")
            
            // Try alternative approach
            log("Trying alternative window detection...")
            
            // Try to activate the app first
            if !app.isActive {
                app.activate(options: .activateIgnoringOtherApps)
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            // Try again
            let result2 = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
            if result2 != .success {
                log("❌ Second attempt also failed: \(errorDescription(for: result2))")
                return
            }
        }
        
        guard let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
            log("❌ No windows found for app")
            return
        }
        
        let window = windows[0]
        log("Got window reference")
        
        // Get current position
        var posRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef)
        
        var currentPos = CGPoint.zero
        if let posValue = posRef {
            AXValueGetValue(posValue as! AXValue, .cgPoint, &currentPos)
            log("Current position: \(currentPos)")
        }
        
        // Check if settable
        var isSettable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &isSettable)
        log("Position settable: \(isSettable.boolValue)")
        
        if !isSettable.boolValue {
            log("❌ Window position is not settable!")
            return
        }
        
        // Try to move
        let newPos = CGPoint(x: currentPos.x + 50, y: currentPos.y + 50)
        var newPosPoint = newPos
        let newPosValue = AXValueCreate(.cgPoint, &newPosPoint)!
        
        let moveResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, newPosValue)
        
        if moveResult == .success {
            log("✅ Move command succeeded!")
            
            // Verify
            Thread.sleep(forTimeInterval: 0.5)
            var verifyRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &verifyRef)
            
            var verifiedPos = CGPoint.zero
            if let verifyValue = verifyRef {
                AXValueGetValue(verifyValue as! AXValue, .cgPoint, &verifiedPos)
                log("New position: \(verifiedPos)")
                
                if abs(verifiedPos.x - newPos.x) < 5 && abs(verifiedPos.y - newPos.y) < 5 {
                    log("✅ Window moved successfully!")
                } else {
                    log("⚠️ Window moved but not to expected position")
                }
            }
        } else {
            log("❌ Move failed: error \(moveResult.rawValue)")
        }
        
        log("=== Test Complete ===\n")
    }
    
    private func testPokerWindow() {
        log("\n=== Testing Poker Window Movement ===")
        
        // Use CGWindowListCopyWindowInfo to find poker windows
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            log("❌ Failed to get window list")
            return
        }
        
        log("Scanning \(windowList.count) windows for poker apps...")
        
        // Expanded keywords to catch browser tabs with poker sites
        let pokerKeywords = ["poker", "holdem", "888", "stars", "gg", "party", "winamax", 
                           "pokerstars", "888poker", "ggpoker", "partypoker", 
                           "table", "nlh", "plo", "cash game", "tournament"]
        var foundPokerWindow = false
        
        for windowInfo in windowList {
            guard let windowTitle = windowInfo[kCGWindowName as String] as? String,
                  let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
                  let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t else {
                continue
            }
            
            let lowerTitle = windowTitle.lowercased()
            let lowerOwner = ownerName.lowercased()
            
            // Check if this is a poker window
            let isPoker = pokerKeywords.contains { keyword in
                lowerTitle.contains(keyword) || lowerOwner.contains(keyword)
            }
            
            if isPoker {
                foundPokerWindow = true
                log("\n🎰 Found poker window:")
                log("   Title: \(windowTitle)")
                log("   App: \(ownerName)")
                log("   PID: \(pid)")
                
                // Try to move this window
                testMoveSpecificApp(pid: pid, appName: ownerName)
                break
            }
        }
        
        if !foundPokerWindow {
            log("❌ No poker windows found. Please open a poker app/website.")
            log("\nTip: Make sure the poker site is visible in a browser tab title.")
            
            // Show all windows for debugging
            log("\n📋 All visible windows:")
            for (index, windowInfo) in windowList.enumerated() {
                if let title = windowInfo[kCGWindowName as String] as? String,
                   let owner = windowInfo[kCGWindowOwnerName as String] as? String,
                   !title.isEmpty {
                    log("\(index + 1). \(owner): \(title)")
                    if index >= 10 { 
                        log("... and \(windowList.count - 10) more")
                        break 
                    }
                }
            }
        }
        
        log("=== Poker Test Complete ===\n")
    }
    
    private func testMoveSpecificApp(pid: pid_t, appName: String) {
        log("\nAttempting to move window for \(appName) (PID: \(pid))...")
        
        let axApp = AXUIElementCreateApplication(pid)
        
        // Get windows
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
        
        if result != .success {
            log("❌ Failed to get AX windows: \(errorDescription(for: result))")
            
            // Try focusing the app first
            if let app = NSRunningApplication(processIdentifier: pid) {
                log("Activating app...")
                app.activate(options: .activateIgnoringOtherApps)
                Thread.sleep(forTimeInterval: 1.0)
                
                // Try again
                let result2 = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
                if result2 != .success {
                    log("❌ Still failed after activation: \(errorDescription(for: result2))")
                    return
                }
            }
        }
        
        guard let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
            log("❌ No accessible windows found")
            return
        }
        
        log("✅ Found \(windows.count) window(s)")
        
        // Try to move the first window
        let window = windows[0]
        
        // Get window title for confirmation
        var titleRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
           let title = titleRef as? String {
            log("   Window title: \(title)")
        }
        
        // Get current position
        var posRef: CFTypeRef?
        let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef)
        
        if posResult != .success {
            log("❌ Failed to get position: \(errorDescription(for: posResult))")
            return
        }
        
        var currentPos = CGPoint.zero
        if let posValue = posRef {
            AXValueGetValue(posValue as! AXValue, .cgPoint, &currentPos)
            log("   Current position: \(currentPos)")
        }
        
        // Check if settable
        var isSettable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &isSettable)
        log("   Position settable: \(isSettable.boolValue)")
        
        if !isSettable.boolValue {
            log("❌ Window position is not settable!")
            return
        }
        
        // Try to move
        let newPos = CGPoint(x: 100, y: 100)  // Fixed position for testing
        var newPosPoint = newPos
        let newPosValue = AXValueCreate(.cgPoint, &newPosPoint)!
        
        log("   Attempting to move to: \(newPos)")
        let moveResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, newPosValue)
        
        if moveResult == .success {
            log("✅ Move command succeeded!")
            
            // Verify
            Thread.sleep(forTimeInterval: 0.5)
            var verifyRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &verifyRef)
            
            var verifiedPos = CGPoint.zero
            if let verifyValue = verifyRef {
                AXValueGetValue(verifyValue as! AXValue, .cgPoint, &verifiedPos)
                log("   Verified position: \(verifiedPos)")
                
                if abs(verifiedPos.x - newPos.x) < 5 && abs(verifiedPos.y - newPos.y) < 5 {
                    log("✅ Window moved successfully to target position!")
                } else if abs(verifiedPos.x - currentPos.x) > 5 || abs(verifiedPos.y - currentPos.y) > 5 {
                    log("⚠️ Window moved but not to exact target (possibly constrained)")
                } else {
                    log("❌ Window didn't move at all")
                }
            }
        } else {
            log("❌ Move failed: \(errorDescription(for: moveResult))")
        }
    }
    
    private func testDirectMove() {
        log("\n=== Testing Direct Window Move & Resize ===")
        log("This will move and resize a window to verify full control...")
        
        // Find a test app
        let testApps = ["TextEdit", "Notes", "Calculator", "Safari", "Finder"]
        var testedApp: String?
        
        for appName in testApps {
            if NSWorkspace.shared.runningApplications.contains(where: { $0.localizedName == appName }) {
                log("\n🎯 Testing with \(appName)...")
                
                // Test 1: Move to position
                log("Test 1: Moving window to (300, 200)...")
                if DirectWindowMover.moveAppWindow(appName: appName, to: CGPoint(x: 300, y: 200)) {
                    log("✅ Move test passed!")
                    
                    // Test 2: Move to different position
                    Thread.sleep(forTimeInterval: 0.5)
                    log("\nTest 2: Moving window to (500, 300)...")
                    if DirectWindowMover.moveAppWindow(appName: appName, to: CGPoint(x: 500, y: 300)) {
                        log("✅ Second move test passed!")
                    } else {
                        log("❌ Second move failed")
                    }
                    
                    // Test 3: Resize
                    Thread.sleep(forTimeInterval: 0.5)
                    log("\nTest 3: Resizing window to 800x600...")
                    if DirectWindowMover.testResizeWindow(appName: appName, to: CGSize(width: 800, height: 600)) {
                        log("✅ Resize test passed!")
                    } else {
                        log("❌ Resize failed")
                    }
                    
                    testedApp = appName
                    break
                } else {
                    log("❌ Move failed for \(appName)")
                }
            }
        }
        
        if testedApp == nil {
            log("\n❌ No suitable test app found. Please open TextEdit, Notes, or Calculator.")
        }
        
        log("\n=== Direct Test Complete ===\n")
    }
    
    private func testBrowserMove() {
        log("\n=== Testing Browser Window Move ===")
        
        let browsers = ["Safari", "Google Chrome", "Brave Browser", "Firefox", "Microsoft Edge", "Arc"]
        
        for browserName in browsers {
            if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == browserName }) {
                log("\nFound \(browserName) running...")
                
                // Try with DirectWindowMover first
                if DirectWindowMover.moveAppWindow(appName: browserName, to: CGPoint(x: 150, y: 150)) {
                    log("✅ Successfully moved \(browserName) window!")
                    
                    // List windows for this browser
                    if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] {
                        log("Browser windows:")
                        for window in windowList {
                            if let owner = window[kCGWindowOwnerName as String] as? String,
                               let title = window[kCGWindowName as String] as? String,
                               owner == browserName && !title.isEmpty {
                                log("  - \(title)")
                            }
                        }
                    }
                    
                    break
                } else {
                    log("❌ Failed to move \(browserName)")
                }
            }
        }
        
        log("=== Browser Test Complete ===\n")
    }
    
    private func testGridArrangement(rows: Int, cols: Int) {
        log("\n=== Testing \(rows)x\(cols) Grid Arrangement ===")
        
        // Get all visible app windows
        let apps = NSWorkspace.shared.runningApplications.filter { app in
            app.activationPolicy == .regular && 
            !app.isHidden &&
            app.localizedName != "PokerTiles"
        }
        
        var windowsToArrange: [(String, pid_t)] = []
        
        // Collect up to rows*cols windows
        for app in apps {
            if windowsToArrange.count >= rows * cols {
                break
            }
            if let name = app.localizedName {
                windowsToArrange.append((name, app.processIdentifier))
            }
        }
        
        if windowsToArrange.isEmpty {
            log("❌ No windows found to arrange")
            return
        }
        
        log("Found \(windowsToArrange.count) windows to arrange")
        
        // Calculate grid positions
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let frame = screen.visibleFrame
        let cellWidth = frame.width / CGFloat(cols)
        let cellHeight = frame.height / CGFloat(rows)
        
        // Arrange windows
        for (index, (appName, _)) in windowsToArrange.enumerated() {
            let row = index / cols
            let col = index % cols
            
            let x = frame.origin.x + CGFloat(col) * cellWidth
            let y = frame.origin.y + frame.height - CGFloat(row + 1) * cellHeight
            
            log("\nArranging \(appName) to position (\(Int(x)), \(Int(y)))")
            log("Size: \(Int(cellWidth)) x \(Int(cellHeight))")
            
            // Move window
            if DirectWindowMover.moveAppWindow(appName: appName, to: CGPoint(x: x, y: y)) {
                log("✅ Moved \(appName)")
                
                // Try to resize
                Thread.sleep(forTimeInterval: 0.1)
                if DirectWindowMover.testResizeWindow(appName: appName, to: CGSize(width: cellWidth - 10, height: cellHeight - 10)) {
                    log("✅ Resized \(appName)")
                } else {
                    log("⚠️ Could not resize \(appName)")
                }
            } else {
                log("❌ Failed to move \(appName)")
            }
        }
        
        log("\n=== Grid Test Complete ===\n")
    }
    
    private func errorDescription(for error: AXError) -> String {
        switch error {
        case .success: return "Success"
        case .failure: return "General failure"
        case .illegalArgument: return "Illegal argument"
        case .invalidUIElement: return "Invalid UI element"
        case .invalidUIElementObserver: return "Invalid observer"
        case .cannotComplete: return "Cannot complete (-25204)"
        case .attributeUnsupported: return "Attribute unsupported"
        case .actionUnsupported: return "Action unsupported"
        case .notificationUnsupported: return "Notification unsupported"
        case .notImplemented: return "Not implemented"
        case .notificationAlreadyRegistered: return "Notification already registered"
        case .notificationNotRegistered: return "Notification not registered"
        case .apiDisabled: return "API disabled"
        case .noValue: return "No value"
        case .parameterizedAttributeUnsupported: return "Parameterized attribute unsupported"
        case .notEnoughPrecision: return "Not enough precision"
        @unknown default: return "Unknown error: \(error.rawValue)"
        }
    }
}

struct DebugWindowMoveView_Previews: PreviewProvider {
    static var previews: some View {
        DebugWindowMoveView()
            .frame(width: 500, height: 400)
    }
}