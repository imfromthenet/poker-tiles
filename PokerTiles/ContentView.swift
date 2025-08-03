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
    @State private var hasAllPermissions = false
    @State private var selectedTab = "permissions"
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Permissions tab - shown only when permissions are missing
            if !hasAllPermissions {
                PermissionsTabView()
                    .tabItem {
                        Label("Permissions", systemImage: "shield.checkerboard")
                    }
                    .tag("permissions")
            }
            
            // Layouts tab - for window arrangements
            LayoutsTabView(
                permissionTriggerId: $permissionTriggerId,
                windowManager: windowManager
            )
            .tabItem {
                Label("Layouts", systemImage: "rectangle.grid.2x2")
            }
            .tag("layouts")
            
            // Hotkeys tab - for hotkey configuration
            HotkeysTabView(
                permissionTriggerId: $permissionTriggerId,
                windowManager: windowManager
            )
            .tabItem {
                Label("Hotkeys", systemImage: "keyboard")
            }
            .tag("hotkeys")
            
            // Settings tab - for app settings
            SettingsTabView(
                permissionTriggerId: $permissionTriggerId,
                windowManager: windowManager
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag("settings")
            
            #if DEBUG
            // Debug tab - for debugging purposes
            DebugTabView(
                permissionTriggerId: $permissionTriggerId,
                windowManager: windowManager
            )
            .tabItem {
                Label("Debug", systemImage: "ladybug.fill")
            }
            .tag("debug")
            #endif
        }
        .task(id: "initial_setup") {
            checkAllPermissions()
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
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Check every 2 seconds
                windowManager.checkPermissions()
                checkAllPermissions()
                
                // Auto-switch to layouts tab when permissions are granted
                if hasAllPermissions && selectedTab == "permissions" {
                    selectedTab = "layouts"
                }
            }
        }
    }
    
    private func checkAllPermissions() {
        let hasScreenRecording = PermissionManager.hasScreenRecordingPermission()
        let hasAccessibility = PermissionManager.hasAccessibilityPermission()
        hasAllPermissions = hasScreenRecording && hasAccessibility
        
        // Set initial tab based on permission status
        if !hasAllPermissions && selectedTab.isEmpty {
            selectedTab = "permissions"
        } else if hasAllPermissions && selectedTab == "permissions" {
            selectedTab = "layouts"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ColorSchemeManager())
}