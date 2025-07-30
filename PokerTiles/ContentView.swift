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
        Form {
            HeaderSection()
            
            if !windowManager.hasPermission {
                PermissionSection(
                    permissionTriggerId: $permissionTriggerId,
                    windowManager: windowManager
                )
            } else {
                // Core functionality
                WindowStatisticsSection(windowManager: windowManager)
                
                AutoScanSection(windowManager: windowManager)
                
                // Window Management
                Section("Window Management") {
                    QuickActionsView(windowManager: windowManager)
                }
                
                // Active tables (when available)
                if !windowManager.pokerTables.isEmpty {
                    PokerTableSection(windowManager: windowManager)
                    
                    Section("Window Layout") {
                        GridLayoutView(windowManager: windowManager)
                    }
                } else if !windowManager.getPokerAppWindows().isEmpty {
                    Text("No poker tables detected. Open a poker table to see it here.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                
                // Configuration
                Section("Hotkeys") {
                    HotkeySettingsView(hotkeyManager: windowManager.hotkeyManager)
                }
                
                SettingsSection(windowManager: windowManager)
                
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

// MARK: - Header Section
struct HeaderSection: View {
    var body: some View {
        Section {
            Text("PokerTiles Window Manager")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
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


#Preview {
    ContentView()
        .environmentObject(ColorSchemeManager())
}
