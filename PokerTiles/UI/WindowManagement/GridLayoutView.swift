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
    @State private var tempPadding: CGFloat = 10
    @State private var tempWindowSpacing: CGFloat = 5
    @State private var isOverlayVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Window Layout")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Arrange poker tables in predefined grid layouts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
            
            // Spacing Controls
            VStack(alignment: .leading, spacing: 12) {
                Text("Spacing")
                    .font(.headline)
                
                VStack(spacing: 16) {
                    // Padding control
                    HStack {
                        Text("Padding:")
                            .frame(width: 100, alignment: .leading)
                        
                        Slider(
                            value: $tempPadding,
                            in: AppSettings.minGridSpacing...AppSettings.maxGridSpacing,
                            step: 1,
                            onEditingChanged: { editing in
                                if !editing {
                                    windowManager.setGridPadding(tempPadding)
                                }
                            }
                        )
                        
                        Text("\(Int(tempPadding))px")
                            .frame(width: 45)
                            .monospacedDigit()
                    }
                    
                    // Window spacing control
                    HStack {
                        Text("Gap:")
                            .frame(width: 100, alignment: .leading)
                        
                        Slider(
                            value: $tempWindowSpacing,
                            in: AppSettings.minGridSpacing...AppSettings.maxGridSpacing,
                            step: 1,
                            onEditingChanged: { editing in
                                if !editing {
                                    windowManager.setGridWindowSpacing(tempWindowSpacing)
                                }
                            }
                        )
                        
                        Text("\(Int(tempWindowSpacing))px")
                            .frame(width: 45)
                            .monospacedDigit()
                    }
                    
                    // Wall-to-wall preset button
                    HStack {
                        Button("Wall-to-Wall") {
                            tempPadding = 0
                            tempWindowSpacing = 0
                            windowManager.setWallToWallLayout()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Default") {
                            tempPadding = 10
                            tempWindowSpacing = 5
                            windowManager.setGridPadding(10)
                            windowManager.setGridWindowSpacing(5)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Quick Actions
            VStack(spacing: 10) {
                Button(action: arrangeInSelectedLayout) {
                    Label("Arrange Tables", systemImage: "rectangle.grid.2x2")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(windowManager.pokerTables.isEmpty || isArranging)
                
                // Custom hold-to-show button
                Label("Show Grid Overlay", systemImage: "square.grid.3x3.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.green.opacity(isOverlayVisible ? 0.8 : 0.2))
                    .foregroundColor(isOverlayVisible ? .white : .green)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.green, lineWidth: 1)
                    )
                    .scaleEffect(isOverlayVisible ? 0.95 : 1.0)
                    .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) {
                        // Never called
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            showGridOverlay()
                        } else {
                            hideGridOverlay()
                        }
                    }
                
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
                        .foregroundStyle(.secondary)
                    Text("No poker tables detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
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
        .onAppear {
            tempPadding = windowManager.gridLayoutOptions.padding
            tempWindowSpacing = windowManager.gridLayoutOptions.windowSpacing
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
    
    private func showGridOverlay() {
        windowManager.gridOverlayManager?.showOverlay()
        isOverlayVisible = true
    }
    
    private func hideGridOverlay() {
        windowManager.gridOverlayManager?.hideOverlay()
        isOverlayVisible = false
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
                    .foregroundStyle(isDisabled ? .red : .secondary)
            }
            .frame(width: 100, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemFill))
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
                        .foregroundStyle(.secondary)
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
                    .foregroundStyle(.secondary)
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