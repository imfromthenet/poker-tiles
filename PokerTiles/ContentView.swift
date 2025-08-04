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
    @State private var showingPermissionModal = false
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        TabView {
            // Layouts tab - for window arrangements
            LayoutsTabView(
                permissionTriggerId: $permissionTriggerId,
                windowManager: windowManager
            )
            .tabItem {
                Label("Layouts", systemImage: "rectangle.grid.2x2")
            }
            
            // Hotkeys tab - for hotkey configuration
            HotkeysTabView(
                permissionTriggerId: $permissionTriggerId,
                windowManager: windowManager
            )
            .tabItem {
                Label("Hotkeys", systemImage: "keyboard")
            }
            
            // Settings tab - for app settings
            SettingsTabView(
                permissionTriggerId: $permissionTriggerId,
                windowManager: windowManager
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            
            #if DEBUG
            // Debug tab - for debugging purposes
            DebugTabView(
                permissionTriggerId: $permissionTriggerId,
                windowManager: windowManager
            )
            .tabItem {
                Label("Debug", systemImage: "ladybug.fill")
            }
            #endif
        }
        .sheet(isPresented: $showingPermissionModal) {
            PermissionOnboardingModal()
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
                
                // Show modal if permissions are missing
                if !hasAllPermissions && !showingPermissionModal {
                    showingPermissionModal = true
                }
            }
        }
    }
    
    private func checkAllPermissions() {
        let hasScreenRecording = PermissionManager.hasScreenRecordingPermission()
        let hasAccessibility = PermissionManager.hasAccessibilityPermission()
        hasAllPermissions = hasScreenRecording && hasAccessibility
        
        // Show modal on first launch if permissions are missing
        if !hasAllPermissions && !showingPermissionModal {
            showingPermissionModal = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ColorSchemeManager())
}