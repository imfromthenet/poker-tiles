//
//  GridLayoutView.swift
//  PokerTiles
//
//  UI for managing window grid layouts
//

import SwiftUI
import OSLog

struct GridLayoutView: View {
    let windowManager: WindowManager
    @State private var selectedLayout: GridLayoutManager.GridLayout = .twoByTwo
    @State private var isArranging = false
    @State private var tempPadding: CGFloat = SettingsConstants.GridLayout.defaultPadding
    @State private var tempWindowSpacing: CGFloat = SettingsConstants.GridLayout.defaultWindowSpacing
    @State private var tempLineWidth: CGFloat = SettingsConstants.GridLayout.defaultLineWidth
    @State private var tempGridColor: Color = .green
    @State private var tempUseDashedLines: Bool = false
    @State private var tempCornerRadius: CGFloat = SettingsConstants.GridLayout.defaultCornerRadius
    @State private var isOverlayVisible = false
    
    var body: some View {
        VStack(spacing: UIConstants.Spacing.huge) {
            // Header
            VStack(alignment: .leading, spacing: UIConstants.Spacing.standard) {
                Text("Arrange poker tables in predefined grid layouts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Layout Options
            VStack(alignment: .leading, spacing: UIConstants.Spacing.large) {
                Text("Select Layout")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: UIConstants.FrameDimensions.layoutButtonSize))], spacing: UIConstants.Spacing.medium) {
                    ForEach(GridLayoutManager.GridLayout.allCases, id: \.self) { layout in
                        LayoutOptionButton(
                            layout: layout,
                            isSelected: selectedLayout == layout,
                            tableCount: windowManager.pokerTables.count
                        ) {
                            selectedLayout = layout
                            // Update overlay if it's visible
                            if isOverlayVisible {
                                windowManager.gridOverlayManager?.manualLayoutOverride = layout
                                windowManager.gridOverlayManager?.updateGridState()
                            }
                        }
                    }
                }
            }
            
            // Spacing Controls
            VStack(alignment: .leading, spacing: UIConstants.Spacing.large) {
                Text("Spacing")
                    .font(.headline)
                
                VStack(spacing: UIConstants.Spacing.extraLarge) {
                    // Padding control
                    HStack {
                        Text("Padding:")
                            .frame(width: UIConstants.FrameDimensions.labelWidth, alignment: .leading)
                        
                        Slider(
                            value: $tempPadding,
                            in: SettingsConstants.GridLayout.minSpacing...SettingsConstants.GridLayout.maxSpacing,
                            step: UIConstants.LineWidth.thin,
                            onEditingChanged: { editing in
                                if !editing {
                                    windowManager.setGridPadding(tempPadding)
                                }
                            }
                        )
                        
                        Text("\(Int(tempPadding))px")
                            .frame(width: UIConstants.FrameDimensions.textFieldWidth)
                            .monospacedDigit()
                    }
                    
                    // Window spacing control
                    HStack {
                        Text("Gap:")
                            .frame(width: UIConstants.FrameDimensions.labelWidth, alignment: .leading)
                        
                        Slider(
                            value: $tempWindowSpacing,
                            in: SettingsConstants.GridLayout.minSpacing...SettingsConstants.GridLayout.maxSpacing,
                            step: UIConstants.LineWidth.thin,
                            onEditingChanged: { editing in
                                if !editing {
                                    windowManager.setGridWindowSpacing(tempWindowSpacing)
                                }
                            }
                        )
                        
                        Text("\(Int(tempWindowSpacing))px")
                            .frame(width: UIConstants.FrameDimensions.textFieldWidth)
                            .monospacedDigit()
                    }
                    
                    // Border thickness control
                    HStack {
                        Text("Border:")
                            .frame(width: UIConstants.FrameDimensions.labelWidth, alignment: .leading)
                        
                        Slider(
                            value: $tempLineWidth,
                            in: SettingsConstants.GridLayout.minLineWidth...SettingsConstants.GridLayout.maxLineWidth,
                            step: UIConstants.LineWidth.thin,
                            onEditingChanged: { editing in
                                if !editing {
                                    windowManager.gridOverlayManager?.lineWidth = tempLineWidth
                                }
                            }
                        )
                        
                        Text("\(Int(tempLineWidth))px")
                            .frame(width: UIConstants.FrameDimensions.textFieldWidth)
                            .monospacedDigit()
                    }
                    
                    // Grid color picker
                    HStack {
                        Text("Color:")
                            .frame(width: UIConstants.FrameDimensions.labelWidth, alignment: .leading)
                        
                        ColorPicker("", selection: $tempGridColor)
                            .onChange(of: tempGridColor) { _, newColor in
                                windowManager.gridOverlayManager?.gridColor = NSColor(newColor)
                            }
                            .labelsHidden()
                            .frame(width: UIConstants.FrameDimensions.buttonHeight)
                        
                        Spacer()
                        
                        // Preset colors
                        HStack(spacing: UIConstants.Spacing.standard) {
                            ForEach([
                                Color.green,
                                Color.blue,
                                Color.red,
                                Color.yellow,
                                Color.orange,
                                Color.purple,
                                Color.pink
                            ], id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: UIConstants.Spacing.huge, height: UIConstants.Spacing.huge)
                                    .overlay(
                                        Circle()
                                            .stroke(tempGridColor == color ? Color.primary : Color.clear, lineWidth: UIConstants.LineWidth.standard)
                                    )
                                    .onTapGesture {
                                        tempGridColor = color
                                        windowManager.gridOverlayManager?.gridColor = NSColor(color)
                                    }
                            }
                        }
                    }
                    
                    // Style options
                    HStack {
                        Text("Style:")
                            .frame(width: UIConstants.FrameDimensions.labelWidth, alignment: .leading)
                        
                        Toggle("Dashed Lines", isOn: $tempUseDashedLines)
                            .onChange(of: tempUseDashedLines) { _, newValue in
                                windowManager.gridOverlayManager?.useDashedLines = newValue
                            }
                        
                        Spacer()
                        
                        Text("Corners:")
                        Slider(
                            value: $tempCornerRadius,
                            in: 0...SettingsConstants.GridLayout.maxCornerRadius,
                            step: UIConstants.LineWidth.standard,
                            onEditingChanged: { editing in
                                if !editing {
                                    windowManager.gridOverlayManager?.cornerRadius = tempCornerRadius
                                }
                            }
                        )
                        .frame(width: UIConstants.FrameDimensions.labelWidth)
                        
                        Text("\(Int(tempCornerRadius))px")
                            .frame(width: UIConstants.FrameDimensions.textFieldWidth)
                            .monospacedDigit()
                    }
                    
                    // Wall-to-wall preset button
                    HStack {
                        Button("Wall-to-Wall") {
                            tempPadding = SettingsConstants.GridLayout.minSpacing
                            tempWindowSpacing = SettingsConstants.GridLayout.minSpacing
                            windowManager.setWallToWallLayout()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Default") {
                            tempPadding = SettingsConstants.GridLayout.defaultPadding
                            tempWindowSpacing = SettingsConstants.GridLayout.defaultWindowSpacing
                            tempLineWidth = SettingsConstants.GridLayout.defaultLineWidth
                            tempGridColor = .green
                            tempUseDashedLines = false
                            tempCornerRadius = SettingsConstants.GridLayout.defaultCornerRadius
                            windowManager.setGridPadding(SettingsConstants.GridLayout.defaultPadding)
                            windowManager.setGridWindowSpacing(SettingsConstants.GridLayout.defaultWindowSpacing)
                            windowManager.gridOverlayManager?.lineWidth = SettingsConstants.GridLayout.defaultLineWidth
                            windowManager.gridOverlayManager?.gridColor = .systemGreen
                            windowManager.gridOverlayManager?.useDashedLines = false
                            windowManager.gridOverlayManager?.cornerRadius = SettingsConstants.GridLayout.defaultCornerRadius
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                }
                .padding(.vertical, UIConstants.Spacing.standard)
                .padding(.horizontal, UIConstants.Spacing.large)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(UIConstants.CornerRadius.standard)
            }
            
            // Quick Actions
            VStack(spacing: UIConstants.Spacing.medium) {
                Button(action: arrangeInSelectedLayout) {
                    Label("Arrange Tables", systemImage: "rectangle.grid.2x2")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(windowManager.pokerTables.isEmpty || isArranging)
                
                // Custom hold-to-show button
                Label("Show Grid Overlay", systemImage: "square.grid.3x3.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, UIConstants.Spacing.compact)
                    .padding(.horizontal, UIConstants.Spacing.large)
                    .background(Color.green.opacity(isOverlayVisible ? UIConstants.Opacity.semiOpaque : UIConstants.Opacity.light))
                    .foregroundColor(isOverlayVisible ? .white : .green)
                    .cornerRadius(UIConstants.CornerRadius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                            .stroke(Color.green, lineWidth: UIConstants.LineWidth.thin)
                    )
                    .scaleEffect(isOverlayVisible ? UIConstants.Scale.pressed : 1.0)
                    .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) {
                        // Never called
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            showGridOverlay()
                        } else {
                            hideGridOverlay()
                        }
                    }
                
                HStack(spacing: UIConstants.Spacing.medium) {
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
                .padding(.vertical, UIConstants.Spacing.medium)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("\(windowManager.pokerTables.count) poker table\(windowManager.pokerTables.count == 1 ? "" : "s") ready to arrange")
                        .font(.caption)
                }
                .padding(.vertical, UIConstants.Spacing.medium)
            }
        }
        .padding()
        .frame(width: UIConstants.FrameDimensions.formWidth)
        .onAppear {
            tempPadding = windowManager.gridLayoutOptions.padding
            tempWindowSpacing = windowManager.gridLayoutOptions.windowSpacing
            tempLineWidth = windowManager.gridOverlayManager?.lineWidth ?? SettingsConstants.GridLayout.defaultLineWidth
            if let nsColor = windowManager.gridOverlayManager?.gridColor {
                tempGridColor = Color(nsColor)
            }
            tempUseDashedLines = windowManager.gridOverlayManager?.useDashedLines ?? false
            tempCornerRadius = windowManager.gridOverlayManager?.cornerRadius ?? SettingsConstants.GridLayout.defaultCornerRadius
        }
    }
    
    // MARK: - Actions
    
    private func arrangeInSelectedLayout() {
        isArranging = true
        
        Logger.ui.info("Arranging \(windowManager.pokerTables.count) tables in \(selectedLayout.displayName)")
        
        // Check permissions first
        guard PermissionManager.requireAccessibilityPermission() else {
            isArranging = false
            return
        }
        
        Task {
            await MainActor.run {
                windowManager.arrangePokerTablesInGrid(selectedLayout)
            }
            
            try? await Task.sleep(nanoseconds: AnimationConstants.SleepInterval.short) // 0.5 second
            
            await MainActor.run {
                isArranging = false
            }
        }
    }
    
    private func cascadeTables() {
        Logger.ui.info("Cascading \(windowManager.pokerTables.count) tables")
        PermissionManager.withAccessibilityPermission {
            windowManager.cascadePokerTables()
        }
    }
    
    private func stackTables() {
        Logger.ui.info("Stacking \(windowManager.pokerTables.count) tables")
        PermissionManager.withAccessibilityPermission {
            windowManager.stackPokerTables()
        }
    }
    
    private func distributeAcrossScreens() {
        Logger.ui.info("Distributing \(windowManager.pokerTables.count) tables across screens")
        PermissionManager.withAccessibilityPermission {
            windowManager.distributeTablesAcrossScreens()
        }
    }
    
    private func showGridOverlay() {
        windowManager.gridOverlayManager?.manualLayoutOverride = selectedLayout
        windowManager.gridOverlayManager?.showOverlay()
        isOverlayVisible = true
    }
    
    private func hideGridOverlay() {
        windowManager.gridOverlayManager?.hideOverlay()
        windowManager.gridOverlayManager?.manualLayoutOverride = nil
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
                    .frame(width: UIConstants.FrameDimensions.gridCellSize, height: UIConstants.FrameDimensions.gridCellSize)
                
                // Layout name
                Text(layout.displayName)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                
                // Capacity indicator
                Text("Up to \(layout.capacity) \(layout.capacity == 1 ? "table" : "tables")")
                    .font(.caption2)
                    .foregroundStyle(isDisabled ? .red : .secondary)
            }
            .frame(width: UIConstants.FrameDimensions.labelWidth, height: UIConstants.FrameDimensions.layoutButtonSize)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.standard)
                    .fill(isSelected ? Color.accentColor.opacity(UIConstants.Opacity.light) : Color(.systemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.standard)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: UIConstants.LineWidth.standard)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? UIConstants.Opacity.medium : UIConstants.Opacity.opaque)
    }
}

// MARK: - Grid Visualization

struct GridVisualization: View {
    let rows: Int
    let columns: Int
    
    var body: some View {
        VStack(spacing: UIConstants.Spacing.extraSmall) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: UIConstants.Spacing.extraSmall) {
                    ForEach(0..<columns, id: \.self) { col in
                        Rectangle()
                            .fill(Color.accentColor.opacity(UIConstants.Opacity.semiLight))
                            .aspectRatio(UIConstants.AspectRatio.pokerTable, contentMode: .fit)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct GridLayoutView_Previews: PreviewProvider {
    static var previews: some View {
        GridLayoutView(windowManager: WindowManager())
    }
}