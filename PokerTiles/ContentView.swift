//
//  ContentView.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/3.
//

import SwiftUI

struct ContentView: View {
    @State private var windowManager = WindowManager()
    @State private var scanTriggerId: UUID?
    @State private var testTriggerId: UUID?
    @State private var permissionTriggerId: UUID?
    
    var body: some View {
        Form {
            HeaderSection()
            
            if !windowManager.hasPermission {
                PermissionSection(
                    permissionTriggerId: $permissionTriggerId,
                    windowManager: windowManager
                )
            } else {
                WindowStatisticsSection(windowManager: windowManager)
                
                ActionsSection(
                    scanTriggerId: $scanTriggerId,
                    testTriggerId: $testTriggerId,
                    windowManager: windowManager
                )
                
                if !windowManager.pokerTables.isEmpty {
                    PokerTableSection(windowManager: windowManager)
                } else if !windowManager.getPokerAppWindows().isEmpty {
                    Text("No poker tables detected. Open a poker table to see it here.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
        .formStyle(.grouped)
        .task(id: "initial_setup") {
            windowManager.checkPermissions()
            if windowManager.hasPermission {
                await windowManager.scanWindows()
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
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Screen Recording Permission Required")
                    .font(.headline)
                
                Text("PokerTiles needs screen recording access to detect windows")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Grant Permission") {
                    permissionTriggerId = UUID()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
        }
        .task(id: permissionTriggerId) {
            if permissionTriggerId != nil {
                await windowManager.requestPermissions()
            }
        }
    }
}

// MARK: - Window Statistics Section
struct WindowStatisticsSection: View {
    let windowManager: WindowManager
    
    var body: some View {
        Section("Window Statistics") {
            VStack(spacing: 15) {
                StatisticRow(
                    label: "Total Windows:",
                    value: "\(windowManager.windowCount)"
                )
                
                StatisticRow(
                    label: "App Windows:",
                    value: "\(windowManager.getAppWindows().count)"
                )
                
                StatisticRow(
                    label: "Poker App Windows:",
                    value: "\(windowManager.getPokerAppWindows().count)"
                )
                
                StatisticRow(
                    label: "Poker Tables:",
                    value: "\(windowManager.pokerTables.count)"
                )
            }
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

// MARK: - Actions Section
struct ActionsSection: View {
    @Binding var scanTriggerId: UUID?
    @Binding var testTriggerId: UUID?
    let windowManager: WindowManager
    
    var body: some View {
        Section("Actions") {
            HStack(spacing: 10) {
                Button("Scan Windows") {
                    scanTriggerId = UUID()
                }
                .buttonStyle(.borderedProminent)
                .disabled(windowManager.isScanning)
                
                Button("Test Detection") {
                    testTriggerId = UUID()
                }
                .buttonStyle(.bordered)
                .disabled(windowManager.isScanning)
            }
        }
        .task(id: scanTriggerId) {
            if scanTriggerId != nil {
                await windowManager.scanWindows()
                windowManager.printWindowSummary()
            }
        }
        .task(id: testTriggerId) {
            if testTriggerId != nil {
                await windowManager.testPokerDetection()
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
                        .foregroundColor(appColor(for: table.pokerApp))
                    Text(table.pokerApp.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
                            .foregroundColor(.secondary)
                        
                        if table.isActive {
                            Spacer()
                            Label("Active", systemImage: "eye.fill")
                                .font(.caption)
                                .foregroundColor(.green)
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
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
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
}
