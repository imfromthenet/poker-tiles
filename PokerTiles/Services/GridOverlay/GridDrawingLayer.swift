//
//  GridDrawingLayer.swift
//  PokerTiles
//
//  CALayer-based grid drawing for performance
//

import AppKit
import CoreGraphics

/// High-performance grid drawing using CALayer
class GridDrawingLayer: CALayer {
    
    // MARK: - Properties
    
    var gridLayout: GridLayoutManager.GridLayout = .twoByTwo {
        didSet { setNeedsDisplay() }
    }
    
    var occupiedSlots: Set<Int> = [] {
        didSet { setNeedsDisplay() }
    }
    
    var padding: CGFloat = 10 {
        didSet { setNeedsDisplay() }
    }
    
    var windowSpacing: CGFloat = 5 {
        didSet { setNeedsDisplay() }
    }
    
    var gridColor: NSColor = .systemGreen {
        didSet { setNeedsDisplay() }
    }
    
    var lineWidth: CGFloat = 2.0 {
        didSet { 
            // Clamp between 1 and 10
            lineWidth = max(1, min(10, lineWidth))
            setNeedsDisplay() 
        }
    }
    
    var dashPattern: [CGFloat] = [6, 4] // For dashed lines
    var useDashedLines: Bool = false {
        didSet { setNeedsDisplay() }
    }
    var gridCornerRadius: CGFloat = 8 {
        didSet { setNeedsDisplay() }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        if let gridLayer = layer as? GridDrawingLayer {
            self.gridLayout = gridLayer.gridLayout
            self.occupiedSlots = gridLayer.occupiedSlots
            self.padding = gridLayer.padding
            self.windowSpacing = gridLayer.windowSpacing
            self.gridColor = gridLayer.gridColor
            self.lineWidth = gridLayer.lineWidth
            self.dashPattern = gridLayer.dashPattern
            self.useDashedLines = gridLayer.useDashedLines
            self.gridCornerRadius = gridLayer.gridCornerRadius
        }
    }
    
    private func setup() {
        contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        needsDisplayOnBoundsChange = true
    }
    
    // MARK: - Drawing
    
    override func draw(in ctx: CGContext) {
        guard let screen = NSScreen.main else { return }
        
        // Clear background
        ctx.clear(bounds)
        
        // Calculate grid
        let gridManager = GridLayoutManager()
        gridManager.updateOptions(GridLayoutManager.LayoutOptions(
            padding: padding,
            windowSpacing: windowSpacing,
            respectMenuBar: true,
            respectDock: true,
            snapToPixels: true
        ))
        
        let grid = gridManager.calculateGridLayout(
            for: screen,
            rows: gridLayout.rows,
            cols: gridLayout.columns
        )
        
        // Set up drawing parameters
        ctx.setStrokeColor(gridColor.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        
        // Draw grid cells
        var slotIndex = 0
        for row in 0..<gridLayout.rows {
            for col in 0..<gridLayout.columns {
                guard row < grid.count && col < grid[row].count else { continue }
                
                let cellRect = grid[row][col]
                let isOccupied = occupiedSlots.contains(slotIndex)
                
                // Draw cell border
                if useDashedLines {
                    ctx.setLineDash(phase: 0, lengths: dashPattern)
                } else {
                    ctx.setLineDash(phase: 0, lengths: [])
                }
                drawRoundedRect(in: ctx, rect: cellRect, cornerRadius: gridCornerRadius)
                
                // Draw slot indicator
                if isOccupied {
                    drawOccupiedIndicator(in: ctx, rect: cellRect, slotNumber: slotIndex + 1)
                } else {
                    drawEmptyIndicator(in: ctx, rect: cellRect)
                }
                
                slotIndex += 1
            }
        }
    }
    
    private func drawRoundedRect(in ctx: CGContext, rect: CGRect, cornerRadius: CGFloat) {
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        ctx.addPath(path)
        ctx.strokePath()
    }
    
    private func drawOccupiedIndicator(in ctx: CGContext, rect: CGRect, slotNumber: Int) {
        // Just draw the table number
        drawTableNumber(in: ctx, rect: rect, number: slotNumber)
    }
    
    private func drawEmptyIndicator(in ctx: CGContext, rect: CGRect) {
        // Draw dots pattern in center
        let dotSize: CGFloat = 4
        let dotSpacing: CGFloat = 16
        let dotsColor = gridColor.withAlphaComponent(0.3)
        
        ctx.saveGState()
        ctx.setFillColor(dotsColor.cgColor)
        
        for row in -1...1 {
            for col in -1...1 {
                let x = rect.midX + CGFloat(col) * dotSpacing - dotSize / 2
                let y = rect.midY + CGFloat(row) * dotSpacing - dotSize / 2
                ctx.fillEllipse(in: CGRect(x: x, y: y, width: dotSize, height: dotSize))
            }
        }
        
        ctx.restoreGState()
    }
    
    private func drawTableNumber(in ctx: CGContext, rect: CGRect, number: Int) {
        // Draw table number in top-left corner
        let numberStr = "\(number)" as NSString
        let fontSize: CGFloat = 24
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        
        // Calculate size
        let textSize = numberStr.size(withAttributes: attrs)
        
        // Position in top-left with padding (remember macOS has origin at bottom-left)
        let x = rect.minX + 16
        let y = rect.maxY - textSize.height - 16
        
        // Background for better visibility
        ctx.saveGState()
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.8).cgColor)
        let bgRect = CGRect(
            x: x - 8,
            y: y - 4,
            width: textSize.width + 16,
            height: textSize.height + 8
        )
        let bgPath = CGPath(
            roundedRect: bgRect,
            cornerWidth: 6,
            cornerHeight: 6,
            transform: nil
        )
        ctx.addPath(bgPath)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Save current graphics state
        ctx.saveGState()
        
        // Create NSGraphicsContext from CGContext
        let nsGraphicsContext = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsGraphicsContext
        
        // Draw the text
        let textRect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)
        numberStr.draw(in: textRect, withAttributes: attrs)
        
        // Restore graphics state
        NSGraphicsContext.restoreGraphicsState()
        ctx.restoreGState()
    }
}

// MARK: - NSView Wrapper

/// NSView wrapper for the grid drawing layer
class GridDrawingView: NSView {
    
    // MARK: - Properties
    
    var gridLayer: GridDrawingLayer {
        return layer as! GridDrawingLayer
    }
    
    var gridLayout: GridLayoutManager.GridLayout {
        get { gridLayer.gridLayout }
        set { gridLayer.gridLayout = newValue }
    }
    
    var occupiedSlots: Set<Int> {
        get { gridLayer.occupiedSlots }
        set { gridLayer.occupiedSlots = newValue }
    }
    
    var gridColor: NSColor {
        get { gridLayer.gridColor }
        set { gridLayer.gridColor = newValue }
    }
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }
    
    override func makeBackingLayer() -> CALayer {
        return GridDrawingLayer()
    }
    
    // MARK: - Updates
    
    func updateGridOptions(padding: CGFloat, windowSpacing: CGFloat) {
        gridLayer.padding = padding
        gridLayer.windowSpacing = windowSpacing
    }
}