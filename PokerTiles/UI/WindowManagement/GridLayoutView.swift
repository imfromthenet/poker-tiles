//
//  GridLayoutView.swift
//  PokerTiles
//
//  UI for managing window grid layouts
//

import SwiftUI

struct GridLayoutView: View {
    let windowManager: WindowManager
    @State private var selectedLayout: GridLayoutManager.GridLayout = .twoByTwo
    @State private var isArranging = false
    @State private var showResistanceAnalysis = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Window Layout")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Arrange poker tables in predefined grid layouts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Layout Options
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Layout")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                    ForEach(GridLayoutManager.GridLayout.allCases, id: \.self) { layout in
                        LayoutOptionButton(
                            layout: layout,
                            isSelected: selectedLayout == layout,
                            tableCount: windowManager.pokerTables.count
                        ) {
                            selectedLayout = layout
                        }
                    }
                }
            }
            
            // Quick Actions
            VStack(spacing: 10) {
                Button(action: arrangeInSelectedLayout) {
                    Label("Arrange Tables", systemImage: "rectangle.grid.2x2")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(windowManager.pokerTables.isEmpty || isArranging)
                
                HStack(spacing: 10) {
                    Button(action: cascadeTables) {
                        Label("Cascade", systemImage: "square.stack.3d.down.forward")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: stackTables) {
                        Label("Stack", systemImage: "square.stack")
                    }
                    .buttonStyle(.bordered)
                    
                    if NSScreen.screens.count > 1 {
                        Button(action: distributeAcrossScreens) {
                            Label("Multi-Screen", systemImage: "macwindow.on.rectangle")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .disabled(windowManager.pokerTables.isEmpty || isArranging)
            }
            
            // Status
            if windowManager.pokerTables.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("No poker tables detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(windowManager.pokerTables.count) poker table\(windowManager.pokerTables.count == 1 ? "" : "s") ready to arrange")
                        .font(.caption)
                }
                .padding(.vertical, 10)
            }
            
            Divider()
            
            // Advanced Options
            DisclosureGroup("Advanced") {
                VStack(alignment: .leading, spacing: 10) {
                    Button(action: analyzeResistance) {
                        Label("Analyze Window Resistance", systemImage: "exclamationmark.triangle")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: showStatistics) {
                        Label("Show Manipulation Stats", systemImage: "chart.bar")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .frame(width: 400)
        .sheet(isPresented: $showResistanceAnalysis) {
            ResistanceAnalysisView(windowManager: windowManager)
        }
    }
    
    // MARK: - Actions
    
    private func arrangeInSelectedLayout() {
        isArranging = true
        
        print("🎯 Arranging \(windowManager.pokerTables.count) tables in \(selectedLayout.displayName)")
        
        // Check permissions first
        if !PermissionManager.hasAccessibilityPermission() {
            print("❌ No Accessibility permission - requesting...")
            PermissionManager.requestAccessibilityPermission()
            isArranging = false
            return
        }
        
        Task {
            await MainActor.run {
                windowManager.arrangePokerTablesInGrid(selectedLayout)
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
            await MainActor.run {
                isArranging = false
            }
        }
    }
    
    private func cascadeTables() {
        print("🎯 Cascading \(windowManager.pokerTables.count) tables")
        if !PermissionManager.hasAccessibilityPermission() {
            print("❌ No Accessibility permission - requesting...")
            PermissionManager.requestAccessibilityPermission()
            return
        }
        windowManager.cascadePokerTables()
    }
    
    private func stackTables() {
        print("🎯 Stacking \(windowManager.pokerTables.count) tables")
        if !PermissionManager.hasAccessibilityPermission() {
            print("❌ No Accessibility permission - requesting...")
            PermissionManager.requestAccessibilityPermission()
            return
        }
        windowManager.stackPokerTables()
    }
    
    private func distributeAcrossScreens() {
        print("🎯 Distributing \(windowManager.pokerTables.count) tables across screens")
        if !PermissionManager.hasAccessibilityPermission() {
            print("❌ No Accessibility permission - requesting...")
            PermissionManager.requestAccessibilityPermission()
            return
        }
        windowManager.distributeTablesAcrossScreens()
    }
    
    private func analyzeResistance() {
        showResistanceAnalysis = true
        windowManager.analyzeWindowResistance()
    }
    
    private func showStatistics() {
        let stats = windowManager.getManipulationStatistics()
        print(stats)
        
        // Show alert with stats
        let alert = NSAlert()
        alert.messageText = "Window Manipulation Statistics"
        alert.informativeText = stats
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Layout Option Button

struct LayoutOptionButton: View {
    let layout: GridLayoutManager.GridLayout
    let isSelected: Bool
    let tableCount: Int
    let action: () -> Void
    
    var isDisabled: Bool {
        tableCount > layout.capacity
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Grid visualization
                GridVisualization(rows: layout.rows, columns: layout.columns)
                    .frame(width: 60, height: 60)
                
                // Layout name
                Text(layout.displayName)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                
                // Capacity indicator
                Text("\(layout.capacity) tables")
                    .font(.caption2)
                    .foregroundColor(isDisabled ? .red : .secondary)
            }
            .frame(width: 100, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

// MARK: - Grid Visualization

struct GridVisualization: View {
    let rows: Int
    let columns: Int
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<columns, id: \.self) { col in
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.3))
                            .aspectRatio(1.6, contentMode: .fit)
                    }
                }
            }
        }
    }
}

// MARK: - Resistance Analysis View

struct ResistanceAnalysisView: View {
    let windowManager: WindowManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Window Resistance Analysis")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Identifies windows that may be difficult to manipulate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            // Analysis results would go here
            ScrollView {
                Text("Analysis results will appear here after running window resistance detection.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
        .padding()
        .frame(width: 600, height: 400)
    }
}

// MARK: - Preview

struct GridLayoutView_Previews: PreviewProvider {
    static var previews: some View {
        GridLayoutView(windowManager: WindowManager())
    }
}