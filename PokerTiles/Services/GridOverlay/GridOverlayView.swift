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
    @State private var infoOpacity = 1.0
    
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
                lineWidth: overlayManager.lineWidth
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
                .padding(32)
            }
        }
        .onAppear {
            // Fade out info panel after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    infoOpacity = 0.3
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
        VStack(alignment: .leading, spacing: 8) {
            // Layout name
            Text(layout.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Table count
            HStack(spacing: 4) {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(.green)
                Text("\(occupiedCount) of \(layout.capacity) slots occupied")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Instructions
            Text("Hold ⌘⇧G to show grid")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
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
    
    func makeNSView(context: Context) -> GridDrawingView {
        let view = GridDrawingView()
        view.gridLayout = layout
        view.occupiedSlots = occupiedSlots
        view.updateGridOptions(padding: padding, windowSpacing: windowSpacing)
        view.gridColor = gridColor
        view.gridLayer.lineWidth = lineWidth
        return view
    }
    
    func updateNSView(_ nsView: GridDrawingView, context: Context) {
        nsView.gridLayout = layout
        nsView.occupiedSlots = occupiedSlots
        nsView.updateGridOptions(padding: padding, windowSpacing: windowSpacing)
        nsView.gridColor = gridColor
        nsView.gridLayer.lineWidth = lineWidth
    }
}

// MARK: - Preview

struct GridOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        GridOverlayView(overlayManager: GridOverlayManager())
            .frame(width: 1920, height: 1080)
            .background(Color.black.opacity(0.1))
    }
}