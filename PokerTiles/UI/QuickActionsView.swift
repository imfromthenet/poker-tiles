//
//  QuickActionsView.swift
//  PokerTiles
//
//  Quick access to window management actions
//

import SwiftUI

struct QuickActionsView: View {
    let windowManager: WindowManager
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            // Permission Check
            HStack {
                Image(systemName: hasAllPermissions ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(hasAllPermissions ? Color.green : Color.orange)
                
                Text(hasAllPermissions ? "All permissions granted" : "Missing permissions")
                    .font(.subheadline)
                
                Spacer()
                
                if !hasAllPermissions {
                    Button("Fix") {
                        if !PermissionManager.hasAccessibilityPermission() {
                            PermissionManager.requestAccessibilityPermission()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            Divider()
            
            // Table Count
            HStack {
                Label("\(windowManager.pokerTables.count) poker table(s) detected", systemImage: "square.grid.2x2")
                    .font(.subheadline)
                
                Spacer()
                
                Button("Refresh") {
                    Task {
                        await windowManager.scanWindows()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Quick Layout Buttons
            if !windowManager.pokerTables.isEmpty {
                Divider()
                
                Text("Quick Layouts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Button("2x2") {
                        arrangeInGrid(.twoByTwo)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("3x3") {
                        arrangeInGrid(.threeByThree)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Cascade") {
                        cascade()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Stack") {
                        stack()
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.small)
            }
            
            // Debug Info
            if windowManager.pokerTables.isEmpty && !windowManager.getPokerAppWindows().isEmpty {
                Divider()
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Found poker app windows but no tables. Open a poker table to enable layouts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                PermissionManager.openPermissionSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Accessibility permission is required to move windows. Grant permission in System Preferences.")
        }
    }
    
    private var hasAllPermissions: Bool {
        PermissionManager.hasScreenRecordingPermission() && PermissionManager.hasAccessibilityPermission()
    }
    
    private func arrangeInGrid(_ layout: GridLayoutManager.GridLayout) {
        if !checkPermissions() { return }
        
        print("🎯 Quick action: Arranging in \(layout.displayName)")
        windowManager.arrangePokerTablesInGrid(layout)
    }
    
    private func cascade() {
        if !checkPermissions() { return }
        
        print("🎯 Quick action: Cascading windows")
        windowManager.cascadePokerTables()
    }
    
    private func stack() {
        if !checkPermissions() { return }
        
        print("🎯 Quick action: Stacking windows")
        windowManager.stackPokerTables()
    }
    
    private func checkPermissions() -> Bool {
        if !PermissionManager.hasAccessibilityPermission() {
            showingPermissionAlert = true
            return false
        }
        return true
    }
}

struct QuickActionsView_Previews: PreviewProvider {
    static var previews: some View {
        QuickActionsView(windowManager: WindowManager())
            .frame(width: 400)
    }
}