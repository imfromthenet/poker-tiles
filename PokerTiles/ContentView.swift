//
//  ContentView.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/3.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var windowManager = WindowManager()
    @State private var permissionTriggerId: UUID?
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        TabView {
            // Tables tab - for monitoring poker tables
            TablesTabView(
                permissionTriggerId: $permissionTriggerId,
                windowManager: windowManager
            )
            .tabItem {
                Label("Tables", systemImage: "tablecells")
            }
            
            // Layouts tab - for window arrangements
            Form {
                if !windowManager.hasPermission {
                    PermissionSection(
                        permissionTriggerId: $permissionTriggerId,
                        windowManager: windowManager
                    )
                } else {
                    // Window Management
                    Section("Window Management") {
                        QuickActionsView(windowManager: windowManager)
                    }
                    
                    // Window Layout
                    Section("Window Layout") {
                        GridLayoutView(windowManager: windowManager)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Layouts", systemImage: "rectangle.grid.2x2")
            }
            
            // Hotkeys tab - for hotkey configuration
            Form {
                if !windowManager.hasPermission {
                    PermissionSection(
                        permissionTriggerId: $permissionTriggerId,
                        windowManager: windowManager
                    )
                } else {
                    // Hotkey Configuration
                    Section("Hotkeys") {
                        HotkeySettingsView(hotkeyManager: windowManager.hotkeyManager)
                    }
                    
                    // Hotkey Test Section
                    if !windowManager.pokerTables.isEmpty {
                        Section("Hotkey Test") {
                            HotkeyTestView(windowManager: windowManager)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Hotkeys", systemImage: "keyboard")
            }
            
            // Settings tab - for app settings
            Form {
                if !windowManager.hasPermission {
                    PermissionSection(
                        permissionTriggerId: $permissionTriggerId,
                        windowManager: windowManager
                    )
                } else {
                    // Auto Scan
                    AutoScanSection(windowManager: windowManager)
                    
                    // General Settings
                    SettingsSection(windowManager: windowManager)
                    
                    // Permissions
                    Section("Permissions") {
                        PermissionStatusView()
                    }
                    
                    #if DEBUG
                    Section("Debug") {
                        DebugWindowMoveView()
                    }
                    #endif
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .task(id: "initial_setup") {
            windowManager.checkPermissions()
            // Do an immediate scan to initialize
            if windowManager.hasPermission {
                await windowManager.scanWindows()
            }
            // Start auto-scan with a delay to ensure app is fully initialized
            windowManager.startAutoScanWithDelay(delay: 2.0)
        }
        .task {
            // Periodically check permissions in case they're revoked
            while true {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // Check every 5 seconds
                windowManager.checkPermissions()
            }
        }
    }
}

// MARK: - Permission Section
struct PermissionSection: View {
    @Binding var permissionTriggerId: UUID?
    let windowManager: WindowManager
    
    var body: some View {
        Section("Permissions Required") {
            VStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(iconColor)
                
                Text(titleText)
                    .font(.headline)
                
                Text(messageText)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 10) {
                    if windowManager.permissionState == .denied {
                        Button("Open System Preferences") {
                            windowManager.openSystemPreferences()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button(buttonText) {
                        permissionTriggerId = UUID()
                    }
                    .buttonStyle(.bordered)
                    .disabled(windowManager.permissionState == .denied && !canRetry)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .task(id: permissionTriggerId) {
            if permissionTriggerId != nil {
                await windowManager.requestPermissions()
            }
        }
    }
    
    private var iconName: String {
        switch windowManager.permissionState {
        case .granted:
            return "checkmark.circle"
        case .denied:
            return "xmark.circle"
        case .notDetermined:
            return "exclamationmark.triangle"
        }
    }
    
    private var iconColor: Color {
        switch windowManager.permissionState {
        case .granted:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        }
    }
    
    private var titleText: String {
        switch windowManager.permissionState {
        case .granted:
            return "Permission Granted"
        case .denied:
            return "Permission Denied"
        case .notDetermined:
            return "Screen Recording Permission Required"
        }
    }
    
    private var messageText: String {
        switch windowManager.permissionState {
        case .granted:
            return "PokerTiles has access to detect windows"
        case .denied:
            return "Please grant screen recording permission in System Preferences > Privacy & Security > Screen Recording"
        case .notDetermined:
            return "PokerTiles needs screen recording access to detect poker windows"
        }
    }
    
    private var buttonText: String {
        switch windowManager.permissionState {
        case .granted:
            return "Check Again"
        case .denied:
            return "Check Again"
        case .notDetermined:
            return "Grant Permission"
        }
    }
    
    private var canRetry: Bool {
        // On macOS, we can always retry checking permissions
        true
    }
}

// MARK: - Window Statistics Section
struct WindowStatisticsSection: View {
    let windowManager: WindowManager
    
    var body: some View {
        Section("Window Statistics") {
            VStack(spacing: 15) {
                if !windowManager.isInitialized {
                    // Skeleton loading state
                    SkeletonStatisticRow()
                    SkeletonStatisticRow()
                    SkeletonStatisticRow()
                    SkeletonStatisticRow()
                } else {
                    // Actual statistics with fade-in
                    StatisticRow(
                        label: "Total Windows:",
                        value: "\(windowManager.windowCount)"
                    )
                    .transition(.opacity)
                    
                    StatisticRow(
                        label: "App Windows:",
                        value: "\(windowManager.getAppWindows().count)"
                    )
                    .transition(.opacity)
                    
                    StatisticRow(
                        label: "Poker App Windows:",
                        value: "\(windowManager.getPokerAppWindows().count)"
                    )
                    .transition(.opacity)
                    
                    StatisticRow(
                        label: "Poker Tables:",
                        value: "\(windowManager.pokerTables.count)"
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: windowManager.isInitialized)
        }
    }
}

// MARK: - Statistic Row
struct StatisticRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}


// MARK: - Auto Scan Section
struct AutoScanSection: View {
    let windowManager: WindowManager
    @State private var tempInterval: Double = 1.0
    
    var body: some View {
        Section("Auto Scan") {
            Toggle("Enable Automatic Scanning", isOn: Binding(
                get: { windowManager.isAutoScanEnabled },
                set: { windowManager.setAutoScanEnabled($0) }
            ))
            
            if windowManager.isAutoScanEnabled {
                HStack {
                    Text("Scan Interval:")
                    Slider(
                        value: $tempInterval,
                        in: 0.01...5,
                        step: 0.01,
                        onEditingChanged: { editing in
                            if !editing {
                                windowManager.setAutoScanInterval(tempInterval)
                            }
                        }
                    )
                    HStack(spacing: 8) {
                        Text("\(tempInterval, specifier: "%.2f")s")
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 8, height: 8)
                            .opacity(windowManager.isScanning ? 1.0 : 0.0)
                    }
                    .frame(width: 65)
                }
            }
        }
        .onAppear {
            tempInterval = windowManager.autoScanInterval
        }
        .onChange(of: windowManager.autoScanInterval) { oldValue, newValue in
            tempInterval = newValue
        }
    }
}


// MARK: - Settings Section
struct SettingsSection: View {
    let windowManager: WindowManager
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    @State private var showingExportAlert = false
    @State private var showingImportAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        
        Section("Settings") {
            // Appearance Settings
            HStack {
                Text("Appearance")
                Spacer()
                Picker("", selection: $colorSchemeManager.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            HStack {
                Button("Export Settings") {
                    exportSettings()
                }
                
                Button("Import Settings") {
                    importSettings()
                }
            }
        }
        .alert("Settings", isPresented: Binding(
            get: { showingExportAlert || showingImportAlert },
            set: { _ in
                showingExportAlert = false
                showingImportAlert = false
            }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportSettings() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Settings"
        savePanel.nameFieldStringValue = "PokerTiles-Settings-\(Date().formatted(date: .abbreviated, time: .omitted)).json"
        savePanel.allowedContentTypes = [.json]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try SettingsManager.saveSettingsToFile(from: windowManager, colorSchemeManager: colorSchemeManager, to: url)
                    alertMessage = "Settings exported successfully!"
                    showingExportAlert = true
                } catch {
                    alertMessage = "Failed to export settings: \(error.localizedDescription)"
                    showingExportAlert = true
                }
            }
        }
    }
    
    private func importSettings() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import Settings"
        openPanel.message = "Select a PokerTiles settings file"
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    try SettingsManager.loadSettingsFromFile(from: url, to: windowManager, colorSchemeManager: colorSchemeManager)
                    alertMessage = "Settings imported successfully!"
                    showingImportAlert = true
                } catch {
                    alertMessage = "Failed to import settings: \(error.localizedDescription)"
                    showingImportAlert = true
                }
            }
        }
    }
}

// MARK: - Poker Table Section
struct PokerTableSection: View {
    let windowManager: WindowManager
    
    var body: some View {
        Section("Active Poker Tables") {
            VStack(spacing: 12) {
                ForEach(windowManager.pokerTables) { table in
                    PokerTableRow(
                        table: table,
                        onTap: {
                            windowManager.bringWindowToFront(table.windowInfo)
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Poker Table Row
struct PokerTableRow: View {
    let table: PokerTable
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // App Icon
                VStack {
                    Image(systemName: "suit.spade.fill")
                        .font(.title2)
                        .foregroundStyle(appColor(for: table.pokerApp))
                    Text(table.pokerApp.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 60)
                
                // Table Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(table.windowInfo.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Label(table.tableType.displayName, systemImage: tableTypeIcon(for: table.tableType))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if table.isActive {
                            Spacer()
                            Label("Active", systemImage: "eye.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Spacer()
                
                // Thumbnail
                if let thumbnail = table.windowInfo.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 60)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.separatorColor), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemFill))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private func appColor(for app: PokerApp) -> Color {
        switch app {
        case .pokerStars: return .red
        case .poker888: return .green
        case .ggPoker: return .orange
        case .partyPoker: return .blue
        case .winamax: return .purple
        case .ignition: return .yellow
        case .acr: return .cyan
        case .unknown: return .gray
        }
    }
    
    private func tableTypeIcon(for type: PokerTable.TableType) -> String {
        switch type {
        case .cash: return "dollarsign.circle"
        case .tournament: return "trophy"
        case .sitAndGo: return "clock"
        case .fastFold: return "bolt"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Hotkey Test View
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
    ContentView()
        .environmentObject(ColorSchemeManager())
}
