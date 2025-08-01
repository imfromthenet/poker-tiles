//
//  HotkeyTestView.swift
//  PokerTiles
//
//  Test interface for hotkey functionality
//

import SwiftUI
import AppKit


struct HotkeyTestView: View {
    let windowManager: WindowManager
    @State private var testResult: String = ""
    @State private var debugLogs: [String] = []
    @State private var lastSwitchedIndex: Int? = nil
    @State private var isCapturingKeys: Bool = false
    @State private var keyCaptureLogs: [String] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test hotkey functionality without using actual hotkeys")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Button("Test Next Table") {
                    testNextTable()
                }
                .buttonStyle(.bordered)
                
                Button("Test Previous Table") {
                    testPreviousTable()
                }
                .buttonStyle(.bordered)
                
                Button("Check Permissions") {
                    checkPermissions()
                }
                .buttonStyle(.bordered)
                
                Button("Show Hotkeys") {
                    showRegisteredHotkeys()
                }
                .buttonStyle(.bordered)
            }
            
            HStack {
                Button("Test Key Capture") {
                    testKeyCapture()
                }
                .buttonStyle(.bordered)
                
                if isCapturingKeys {
                    Text("Press any key combination...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button("Stop") {
                        stopKeyCapture()
                    }
                    .buttonStyle(.link)
                }
            }
            
            if !testResult.isEmpty {
                Text(testResult)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            
            // Reset button for when user manually switches
            Button("Reset Navigation") {
                lastSwitchedIndex = nil
                testResult = "Navigation reset - will detect current table from frontmost app"
                debugLogs.append("🔄 Navigation reset")
            }
            .font(.caption)
            .buttonStyle(.link)
            
            // Debug log viewer
            if !debugLogs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Debug Logs")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                        Button("Copy") {
                            let logText = debugLogs.joined(separator: "\n")
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(logText, forType: .string)
                        }
                        .font(.caption)
                        Button("Clear") {
                            debugLogs.removeAll()
                        }
                        .font(.caption)
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(debugLogs.indices, id: \.self) { index in
                                Text(debugLogs[index])
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .padding(4)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func testNextTable() {
        testResult = "Testing Next Table..."
        debugLogs.removeAll() // Clear previous logs
        
        let tables = windowManager.pokerTables
        debugLogs.append("🧪 Next Table - Found \(tables.count) poker tables")
        
        guard !tables.isEmpty else {
            testResult = "❌ No poker tables found"
            return
        }
        
        // Log all tables
        for (index, table) in tables.enumerated() {
            debugLogs.append("   Table \(index): \(table.windowInfo.appName) - \(table.windowInfo.title)")
            debugLogs.append("      ID: \(table.windowInfo.id), Bundle: \(table.windowInfo.bundleIdentifier)")
        }
        
        // Get the frontmost app to determine current table
        let workspace = NSWorkspace.shared
        let frontmostApp = workspace.frontmostApplication
        debugLogs.append("   Frontmost app: \(frontmostApp?.localizedName ?? "Unknown") (\(frontmostApp?.bundleIdentifier ?? "Unknown"))")
        
        var currentIndex: Int?
        
        // First check if we have a last switched index (for rapid switching)
        if let lastIndex = lastSwitchedIndex, lastIndex < tables.count {
            debugLogs.append("   Using last switched index: \(lastIndex)")
            currentIndex = lastIndex
        } else if let frontmostBundleId = frontmostApp?.bundleIdentifier {
            // Otherwise, check if any poker table's app is frontmost
            currentIndex = tables.firstIndex { table in
                table.windowInfo.bundleIdentifier == frontmostBundleId
            }
            if let index = currentIndex {
                debugLogs.append("   Detected current table from frontmost app: \(index)")
            }
        }
        
        // Determine next index
        let nextIndex: Int
        if let index = currentIndex {
            nextIndex = (index + 1) % tables.count
            debugLogs.append("✅ Current table at index \(index), switching to \(nextIndex)")
            testResult = "Switching from table \(index) to \(nextIndex)"
        } else {
            nextIndex = 0
            debugLogs.append("⚠️ No current table detected, activating first table")
            testResult = "No current table detected, activating first table"
        }
        
        let targetWindow = tables[nextIndex].windowInfo
        debugLogs.append("   Target: \(targetWindow.appName) - \(targetWindow.title)")
        
        windowManager.bringWindowToFront(targetWindow)
        lastSwitchedIndex = nextIndex  // Remember what we switched to
    }
    
    private func testPreviousTable() {
        testResult = "Testing Previous Table..."
        debugLogs.removeAll() // Clear previous logs
        
        let tables = windowManager.pokerTables
        debugLogs.append("🧪 Previous Table - Found \(tables.count) poker tables")
        
        guard !tables.isEmpty else {
            testResult = "❌ No poker tables found"
            return
        }
        
        // Log all tables
        for (index, table) in tables.enumerated() {
            debugLogs.append("   Table \(index): \(table.windowInfo.appName) - \(table.windowInfo.title)")
            debugLogs.append("      ID: \(table.windowInfo.id), Bundle: \(table.windowInfo.bundleIdentifier)")
        }
        
        // Get the frontmost app to determine current table
        let workspace = NSWorkspace.shared
        let frontmostApp = workspace.frontmostApplication
        debugLogs.append("   Frontmost app: \(frontmostApp?.localizedName ?? "Unknown") (\(frontmostApp?.bundleIdentifier ?? "Unknown"))")
        
        var currentIndex: Int?
        
        // First check if we have a last switched index (for rapid switching)
        if let lastIndex = lastSwitchedIndex, lastIndex < tables.count {
            debugLogs.append("   Using last switched index: \(lastIndex)")
            currentIndex = lastIndex
        } else if let frontmostBundleId = frontmostApp?.bundleIdentifier {
            // Otherwise, check if any poker table's app is frontmost
            currentIndex = tables.firstIndex { table in
                table.windowInfo.bundleIdentifier == frontmostBundleId
            }
            if let index = currentIndex {
                debugLogs.append("   Detected current table from frontmost app: \(index)")
            }
        }
        
        // Determine previous index
        let previousIndex: Int
        if let index = currentIndex {
            previousIndex = index > 0 ? index - 1 : tables.count - 1
            debugLogs.append("✅ Current table at index \(index), switching to \(previousIndex)")
            testResult = "Switching from table \(index) to \(previousIndex)"
        } else {
            previousIndex = tables.count - 1
            debugLogs.append("⚠️ No current table detected, activating last table")
            testResult = "No current table detected, activating last table"
        }
        
        let targetWindow = tables[previousIndex].windowInfo
        debugLogs.append("   Target: \(targetWindow.appName) - \(targetWindow.title)")
        
        windowManager.bringWindowToFront(targetWindow)
        lastSwitchedIndex = previousIndex  // Remember what we switched to
    }
    
    private func checkPermissions() {
        let hotkeyManager = windowManager.hotkeyManager
        
        // Check accessibility permission
        let hasAccessibility = PermissionManager.hasAccessibilityPermission()
        
        // Check if Input Monitoring is granted (this is what event taps need)
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        testResult = """
        Accessibility: \(hasAccessibility ? "✅" : "❌")
        AX Trusted: \(trusted ? "✅" : "❌")
        Hotkeys enabled: \(hotkeyManager?.isEnabled ?? false ? "✅" : "❌")
        """
        
        debugLogs.append("🧪 Permission check:")
        debugLogs.append("   - Accessibility: \(hasAccessibility)")
        debugLogs.append("   - AX Trusted: \(trusted)")
        debugLogs.append("   - Hotkeys enabled: \(hotkeyManager?.isEnabled ?? false)")
    }
    
    private func showRegisteredHotkeys() {
        guard let hotkeyManager = windowManager.hotkeyManager else {
            testResult = "❌ No hotkey manager available"
            return
        }
        
        debugLogs.append("📋 Registered Hotkeys:")
        debugLogs.append("   Enabled: \(hotkeyManager.isEnabled ? "✅" : "❌")")
        
        // Check specific hotkeys we care about
        let actionsToCheck: [HotkeyManager.HotkeyAction] = [.nextTable, .previousTable, .fold, .call, .raise]
        
        for action in actionsToCheck {
            if let (keyCode, modifiers) = hotkeyManager.getHotkey(for: action) {
                let modifierStr = describeModifiers(modifiers)
                let keyStr = describeKeyCode(keyCode)
                let modRaw = String(format: "0x%X", modifiers.rawValue)
                debugLogs.append("   \(action.rawValue):")
                debugLogs.append("      Key: \(modifierStr)\(keyStr) (code: \(keyCode))")
                debugLogs.append("      Modifiers: \(modRaw)")
                
                // Show expected vs actual
                if let defaultKey = action.defaultKeyCode,
                   let defaultMods = action.defaultModifiers {
                    let defaultModStr = describeModifiers(defaultMods)
                    let defaultKeyStr = describeKeyCode(defaultKey)
                    debugLogs.append("      Default: \(defaultModStr)\(defaultKeyStr)")
                }
            } else {
                debugLogs.append("   \(action.rawValue): Not registered")
            }
        }
        
        testResult = "Check debug logs below"
    }
    
    private func describeModifiers(_ flags: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if flags.contains(.command) { parts.append("⌘") }
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        return parts.joined()
    }
    
    private func describeKeyCode(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0x30: return "Tab"
        case 0x31: return "Space"
        case 0x00: return "A"
        case 0x08: return "C"
        case 0x03: return "F"
        case 0x2D: return "N"
        case 0x23: return "P"
        case 0x0F: return "R"
        default: return "Key\(keyCode)"
        }
    }
    
    private func testKeyCapture() {
        debugLogs.removeAll()
        debugLogs.append("🎮 Key Capture Test Mode Started")
        debugLogs.append("Press any key combination to see raw values")
        debugLogs.append("This will show what the system sees when you press keys")
        
        isCapturingKeys = true
        testResult = "Key capture mode active - check debug logs"
        
        // Start a temporary event monitor
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if self.isCapturingKeys {
                let keyCode = event.keyCode
                let modifiers = event.modifierFlags
                let keyStr = self.describeKeyCode(UInt16(keyCode))
                let modStr = self.describeModifiers(modifiers)
                
                self.debugLogs.append("")
                self.debugLogs.append("🎹 Key Pressed:")
                self.debugLogs.append("   Key: \(modStr)\(keyStr)")
                self.debugLogs.append("   KeyCode: \(keyCode) (0x\(String(format: "%02X", keyCode)))")
                self.debugLogs.append("   Modifiers: \(String(format: "0x%X", modifiers.rawValue))")
                self.debugLogs.append("   Control: \(modifiers.contains(.control) ? "✅" : "❌")")
                self.debugLogs.append("   Option: \(modifiers.contains(.option) ? "✅" : "❌")")
                self.debugLogs.append("   Command: \(modifiers.contains(.command) ? "✅" : "❌")")
                self.debugLogs.append("   Shift: \(modifiers.contains(.shift) ? "✅" : "❌")")
                
                // Don't consume the event
                return event
            }
            return event
        }
    }
    
    private func stopKeyCapture() {
        isCapturingKeys = false
        debugLogs.append("")
        debugLogs.append("🛑 Key Capture Test Mode Stopped")
        testResult = "Key capture stopped"
    }
}


#Preview {
    HotkeyTestView(windowManager: WindowManager())
}
