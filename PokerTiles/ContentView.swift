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
            // Tables tab - for monitoring poker tables
            TablesTabView(
                permissionTriggerId: $permissionTriggerId,
                windowManager: windowManager
            )
            .tabItem {
                Label("Tables", systemImage: "tablecells")
            }
            #endif
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

#Preview {
    ContentView()
        .environmentObject(ColorSchemeManager())
}