//
//  GridOverlayView.swift
//  PokerTiles
//
//  SwiftUI view for the grid overlay content
//

import SwiftUI
import AppKit

/// SwiftUI view for the grid overlay
struct GridOverlayView: View {
    
    // MARK: - Properties
    
    @ObservedObject var overlayManager: GridOverlayManager
    @State private var showInfo = true
    @State private var infoOpacity = UIConstants.Opacity.opaque
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Grid drawing layer
            GridDrawingViewWrapper(
                layout: overlayManager.currentLayout,
                occupiedSlots: overlayManager.occupiedSlots,
                padding: overlayManager.padding,
                windowSpacing: overlayManager.windowSpacing,
                gridColor: overlayManager.gridColor,
                lineWidth: overlayManager.lineWidth,
                useDashedLines: overlayManager.useDashedLines,
                cornerRadius: overlayManager.cornerRadius
            )
            .allowsHitTesting(false)
            
            // Info overlay
            if showInfo {
                VStack {
                    HStack {
                        InfoPanel(
                            layout: overlayManager.currentLayout,
                            tableCount: overlayManager.tableCount,
                            occupiedCount: overlayManager.occupiedSlots.count
                        )
                        .opacity(infoOpacity)
                        
                        Spacer()
                    }
                    Spacer()
                }
                .padding(UIConstants.Spacing.giant)
            }
        }
        .onAppear {
            // Fade out info panel after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.Duration.extraLong) {
                withAnimation(.easeOut(duration: AnimationConstants.Duration.medium)) {
                    infoOpacity = UIConstants.Opacity.semiLight
                }
            }
        }
    }
}

// MARK: - Info Panel

struct InfoPanel: View {
    let layout: GridLayoutManager.GridLayout
    let tableCount: Int
    let occupiedCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.standard) {
            // Layout name
            Text(layout.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Table count
            HStack(spacing: UIConstants.Spacing.tiny) {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(.green)
                Text("\(occupiedCount) of \(layout.capacity) slots occupied")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(UIConstants.Opacity.nearlyOpaque))
            }
            
            // Instructions
            Text("Hold ⌘⇧G to show grid")
                .font(.caption)
                .foregroundColor(.white.opacity(UIConstants.Opacity.visible))
        }
        .padding(UIConstants.Spacing.extraLarge)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .fill(Color.black.opacity(UIConstants.Opacity.semiOpaque))
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                        .stroke(Color.green.opacity(UIConstants.Opacity.medium), lineWidth: UIConstants.LineWidth.thin)
                )
        )
        .shadow(color: .black.opacity(UIConstants.Opacity.medium), radius: UIConstants.Spacing.medium, x: 0, y: UIConstants.Spacing.small)
    }
}

// MARK: - Grid Drawing View Wrapper

struct GridDrawingViewWrapper: NSViewRepresentable {
    let layout: GridLayoutManager.GridLayout
    let occupiedSlots: Set<Int>
    let padding: CGFloat
    let windowSpacing: CGFloat
    let gridColor: NSColor
    let lineWidth: CGFloat
    let useDashedLines: Bool
    let cornerRadius: CGFloat
    
    func makeNSView(context: Context) -> GridDrawingView {
        let view = GridDrawingView()
        view.gridLayout = layout
        view.occupiedSlots = occupiedSlots
        view.updateGridOptions(padding: padding, windowSpacing: windowSpacing)
        view.gridColor = gridColor
        view.gridLayer.lineWidth = lineWidth
        view.gridLayer.useDashedLines = useDashedLines
        view.gridLayer.gridCornerRadius = cornerRadius
        return view
    }
    
    func updateNSView(_ nsView: GridDrawingView, context: Context) {
        nsView.gridLayout = layout
        nsView.occupiedSlots = occupiedSlots
        nsView.updateGridOptions(padding: padding, windowSpacing: windowSpacing)
        nsView.gridColor = gridColor
        nsView.gridLayer.lineWidth = lineWidth
        nsView.gridLayer.useDashedLines = useDashedLines
        nsView.gridLayer.gridCornerRadius = cornerRadius
    }
}

// MARK: - Preview

struct GridOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        GridOverlayView(overlayManager: GridOverlayManager())
            .frame(width: UIConstants.FrameDimensions.defaultWindowWidth, height: UIConstants.FrameDimensions.defaultWindowHeight)
            .background(Color.black.opacity(UIConstants.Opacity.veryLight))
    }
}