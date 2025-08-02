//
//  SettingsTabView.swift
//  PokerTiles
//
//  Tab view for app settings and configuration
//

import SwiftUI

struct SettingsTabView: View {
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
                // Auto Scan
                AutoScanSection(windowManager: windowManager)
                
                // General Settings
                SettingsSection(windowManager: windowManager)
                
                // Permissions
                Section("Permissions") {
                    PermissionStatusView()
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsTabView(
        permissionTriggerId: .constant(nil),
        windowManager: WindowManager()
    )
    .environmentObject(ColorSchemeManager())
}