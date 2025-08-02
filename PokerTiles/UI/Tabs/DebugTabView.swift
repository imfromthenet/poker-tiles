//
//  DebugTabView.swift
//  PokerTiles
//
//  Debug tab for debugging purposes
//

import SwiftUI

struct DebugTabView: View {
    @Binding var permissionTriggerId: UUID?
    let windowManager: WindowManager
    
    var body: some View {
        Form {
            if !windowManager.hasPermission {
                PermissionSection(
                    permissionTriggerId: $permissionTriggerId,
                    windowManager: windowManager
                )
            } else {
                // Debug Window Move
                Section("Debug Window Move") {
                    DebugWindowMoveView()
                }
                
                // Window Statistics
                WindowStatisticsSection(windowManager: windowManager)
                
                // Active tables
                if !windowManager.pokerTables.isEmpty {
                    PokerTableSection(windowManager: windowManager)
                } else if !windowManager.getPokerAppWindows().isEmpty {
                    Section {
                        Text("No poker tables detected. Open a poker table to see it here.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                } else {
                    Section {
                        VStack(spacing: 10) {
                            Image(systemName: "tablecells")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No poker apps detected")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Open a poker application to start monitoring tables")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    DebugTabView(
        permissionTriggerId: .constant(nil),
        windowManager: WindowManager()
    )
}