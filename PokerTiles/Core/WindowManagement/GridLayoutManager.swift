//
//  GridLayoutManager.swift
//  PokerTiles
//
//  Manages grid-based window layouts with multi-monitor support
//

import Foundation
import AppKit

/// Manages grid-based window layouts
class GridLayoutManager {
    
    // MARK: - Types
    
    /// Predefined grid layouts
    enum GridLayout: CaseIterable {
        case single      // 1x1
        case oneByTwo    // 1x2 (side by side)
        case twoByOne    // 2x1 (stacked)
        case twoByTwo    // 2x2
        case twoByThree  // 2x3
        case threeByThree // 3x3
        case threeByFour // 3x4
        case fourByFour  // 4x4
        
        var rows: Int {
            switch self {
            case .single: return 1
            case .oneByTwo: return 1
            case .twoByOne: return 2
            case .twoByTwo: return 2
            case .twoByThree: return 2
            case .threeByThree: return 3
            case .threeByFour: return 3
            case .fourByFour: return 4
            }
        }
        
        var columns: Int {
            switch self {
            case .single: return 1
            case .oneByTwo: return 2
            case .twoByOne: return 1
            case .twoByTwo: return 2
            case .twoByThree: return 3
            case .threeByThree: return 3
            case .threeByFour: return 4
            case .fourByFour: return 4
            }
        }
        
        var displayName: String {
            switch self {
            case .single: return "Single"
            case .oneByTwo: return "1x2 Side by Side"
            case .twoByOne: return "2x1 Stacked"
            case .twoByTwo: return "2x2 Grid"
            case .twoByThree: return "2x3 Grid"
            case .threeByThree: return "3x3 Grid"
            case .threeByFour: return "3x4 Grid"
            case .fourByFour: return "4x4 Grid"
            }
        }
        
        var capacity: Int {
            return rows * columns
        }
    }
    
    /// Layout options
    struct LayoutOptions {
        var padding: CGFloat = 10
        var windowSpacing: CGFloat = 5
        var respectMenuBar: Bool = true
        var respectDock: Bool = true
        var snapToPixels: Bool = true
    }
    
    // MARK: - Properties
    
    private let options: LayoutOptions
    
    // MARK: - Initialization
    
    init(options: LayoutOptions = LayoutOptions()) {
        self.options = options
    }
    
    // MARK: - Grid Calculation
    
    /// Calculate grid layout for a screen
    func calculateGridLayout(for screen: NSScreen, rows: Int, cols: Int) -> [[CGRect]] {
        let frame = getUsableFrame(for: screen)
        
        let totalHorizontalSpacing = options.padding * 2 + options.windowSpacing * CGFloat(cols - 1)
        let totalVerticalSpacing = options.padding * 2 + options.windowSpacing * CGFloat(rows - 1)
        
        let cellWidth = (frame.width - totalHorizontalSpacing) / CGFloat(cols)
        let cellHeight = (frame.height - totalVerticalSpacing) / CGFloat(rows)
        
        var grid: [[CGRect]] = []
        
        for row in 0..<rows {
            var rowRects: [CGRect] = []
            
            for col in 0..<cols {
                let x = frame.origin.x + options.padding + CGFloat(col) * (cellWidth + options.windowSpacing)
                // Flip Y coordinate for macOS coordinate system (origin at bottom-left)
                let y = frame.origin.y + frame.height - options.padding - CGFloat(row + 1) * cellHeight - CGFloat(row) * options.windowSpacing
                
                var rect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
                
                if options.snapToPixels {
                    rect = snapToPixels(rect)
                }
                
                rowRects.append(rect)
            }
            
            grid.append(rowRects)
        }
        
        return grid
    }
    
    /// Calculate optimal grid size for number of windows
    func calculateOptimalGrid(for windowCount: Int) -> (rows: Int, cols: Int) {
        switch windowCount {
        case 1:
            return (1, 1)
        case 2:
            return (1, 2)
        case 3...4:
            return (2, 2)
        case 5...6:
            return (2, 3)
        case 7...9:
            return (3, 3)
        case 10...12:
            return (3, 4)
        case 13...16:
            return (4, 4)
        default:
            // For larger numbers, calculate based on square root
            let sqrt = Int(ceil(sqrt(Double(windowCount))))
            return (sqrt, sqrt)
        }
    }
    
    /// Get the best grid layout for a number of windows
    func getBestLayout(for windowCount: Int) -> GridLayout {
        return GridLayout.allCases
            .filter { $0.capacity >= windowCount }
            .min { $0.capacity < $1.capacity } ?? .fourByFour
    }
    
    // MARK: - Multi-Monitor Support
    
    /// Distribute windows across multiple screens
    func distributeAcrossScreens(_ windows: [WindowInfo], screens: [NSScreen]) -> [(WindowInfo, NSScreen, CGRect)] {
        guard !windows.isEmpty && !screens.isEmpty else { return [] }
        
        var result: [(WindowInfo, NSScreen, CGRect)] = []
        
        // Calculate windows per screen
        let windowsPerScreen = Int(ceil(Double(windows.count) / Double(screens.count)))
        
        var windowIndex = 0
        for screen in screens {
            let startIdx = windowIndex
            let endIdx = min(windowIndex + windowsPerScreen, windows.count)
            
            guard startIdx < endIdx else { break }
            
            let screenWindows = Array(windows[startIdx..<endIdx])
            let (rows, cols) = calculateOptimalGrid(for: screenWindows.count)
            let grid = calculateGridLayout(for: screen, rows: rows, cols: cols)
            
            var gridIndex = 0
            for window in screenWindows {
                let row = gridIndex / cols
                let col = gridIndex % cols
                
                if row < grid.count && col < grid[row].count {
                    result.append((window, screen, grid[row][col]))
                }
                
                gridIndex += 1
            }
            
            windowIndex = endIdx
        }
        
        return result
    }
    
    /// Find the best screen arrangement for poker tables
    func arrangePokerTables(_ tables: [PokerTable], preferredScreen: NSScreen? = nil) -> [(PokerTable, CGRect)] {
        let screens = NSScreen.screens
        let screen = preferredScreen ?? screens.first ?? NSScreen.main!
        
        // Group tables by priority (active tables first)
        let activeTables = tables.filter { $0.isActive }
        let inactiveTables = tables.filter { !$0.isActive }
        let sortedTables = activeTables + inactiveTables
        
        // Calculate optimal grid
        let (rows, cols) = calculateOptimalGrid(for: sortedTables.count)
        let grid = calculateGridLayout(for: screen, rows: rows, cols: cols)
        
        var result: [(PokerTable, CGRect)] = []
        
        for (index, table) in sortedTables.enumerated() {
            let row = index / cols
            let col = index % cols
            
            if row < grid.count && col < grid[row].count {
                result.append((table, grid[row][col]))
            }
        }
        
        return result
    }
    
    // MARK: - Specialized Layouts
    
    /// Create a cascading window layout
    func createCascadeLayout(for windows: [WindowInfo], on screen: NSScreen, windowSize: CGSize? = nil) -> [CGRect] {
        let frame = getUsableFrame(for: screen)
        let size = windowSize ?? CGSize(width: 800, height: 600)
        let offset: CGFloat = 30
        
        var frames: [CGRect] = []
        var currentOrigin = CGPoint(x: frame.origin.x + options.padding, 
                                   y: frame.origin.y + frame.height - options.padding - size.height)
        
        for (index, _) in windows.enumerated() {
            var rect = CGRect(origin: currentOrigin, size: size)
            
            // Ensure window stays within screen bounds
            if rect.maxX > frame.maxX {
                currentOrigin.x = frame.origin.x + options.padding
            }
            if rect.minY < frame.minY {
                currentOrigin.y = frame.origin.y + frame.height - options.padding - size.height
            }
            
            rect.origin = currentOrigin
            
            if options.snapToPixels {
                rect = snapToPixels(rect)
            }
            
            frames.append(rect)
            
            // Update position for next window
            currentOrigin.x += offset
            currentOrigin.y -= offset
        }
        
        return frames
    }
    
    /// Create a stack layout (all windows in same position, for easy cycling)
    func createStackLayout(for windows: [WindowInfo], on screen: NSScreen) -> [CGRect] {
        let frame = getUsableFrame(for: screen)
        
        // Use 80% of screen space for stacked windows
        let width = frame.width * 0.8
        let height = frame.height * 0.8
        let x = frame.origin.x + (frame.width - width) / 2
        let y = frame.origin.y + (frame.height - height) / 2
        
        var rect = CGRect(x: x, y: y, width: width, height: height)
        
        if options.snapToPixels {
            rect = snapToPixels(rect)
        }
        
        return Array(repeating: rect, count: windows.count)
    }
    
    // MARK: - Helper Methods
    
    /// Get usable frame accounting for menu bar and dock
    private func getUsableFrame(for screen: NSScreen) -> CGRect {
        var frame = screen.frame
        
        if options.respectMenuBar || options.respectDock {
            // visibleFrame accounts for menu bar and dock
            frame = screen.visibleFrame
        }
        
        return frame
    }
    
    /// Snap rectangle to pixel boundaries
    private func snapToPixels(_ rect: CGRect) -> CGRect {
        return CGRect(
            x: round(rect.origin.x),
            y: round(rect.origin.y),
            width: round(rect.size.width),
            height: round(rect.size.height)
        )
    }
    
    /// Check if rectangles overlap
    func checkOverlap(_ rects: [CGRect]) -> [(Int, Int)] {
        var overlaps: [(Int, Int)] = []
        
        for i in 0..<rects.count {
            for j in (i+1)..<rects.count {
                if rects[i].intersects(rects[j]) {
                    overlaps.append((i, j))
                }
            }
        }
        
        return overlaps
    }
    
    /// Adjust positions to prevent overlap
    func preventOverlap(_ frames: inout [CGRect], minSpacing: CGFloat = 5) {
        let overlaps = checkOverlap(frames)
        
        for (i, j) in overlaps {
            // Move the second window to avoid overlap
            var adjustedFrame = frames[j]
            
            // Try moving right first
            adjustedFrame.origin.x = frames[i].maxX + minSpacing
            
            // Check if it goes off screen
            if let screen = NSScreen.main, adjustedFrame.maxX > screen.frame.maxX {
                // Try moving down instead
                adjustedFrame.origin.x = frames[j].origin.x
                adjustedFrame.origin.y = frames[i].minY - adjustedFrame.height - minSpacing
            }
            
            frames[j] = adjustedFrame
        }
    }
}

// MARK: - Screen Extension

extension NSScreen {
    /// Get the screen containing a point
    static func screenContaining(point: CGPoint) -> NSScreen? {
        return screens.first { $0.frame.contains(point) }
    }
    
    /// Get the screen containing a window
    static func screenContaining(window: WindowInfo) -> NSScreen? {
        let windowCenter = CGPoint(
            x: window.bounds.midX,
            y: window.bounds.midY
        )
        return screenContaining(point: windowCenter)
    }
}