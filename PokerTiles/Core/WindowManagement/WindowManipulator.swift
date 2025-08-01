//
//  WindowManipulator.swift
//  PokerTiles
//
//  Unified window manipulation interface that tries multiple methods
//

import Foundation
import AppKit

/// Protocol for window manipulation strategies
protocol WindowManipulationStrategy {
    func moveWindow(_ windowInfo: WindowInfo, to position: CGPoint) -> Bool
    func resizeWindow(_ windowInfo: WindowInfo, to size: CGSize) -> Bool
    func setWindowFrame(_ windowInfo: WindowInfo, frame: CGRect) -> Bool
}

/// Unified window manipulator that combines multiple strategies
class WindowManipulator {
    
    // MARK: - Properties
    
    private let accessibilityManager = AccessibilityWindowManager()
    private let appleScriptManager = AppleScriptWindowManager()
    
    /// Statistics for tracking success rates
    private var stats = ManipulationStats()
    
    /// Known resistant applications and their preferred methods
    private let resistantApps: [String: WindowManipulationMethod] = [
        "PokerStars": .appleScriptFirst,
        "888poker": .accessibilityWithRetry,
        "GGPoker": .gradualMovement
    ]
    
    enum WindowManipulationMethod {
        case accessibilityFirst
        case appleScriptFirst
        case accessibilityWithRetry
        case gradualMovement
    }
    
    // MARK: - Public Interface
    
    /// Move a window using the best available method
    @discardableResult
    func moveWindow(_ windowInfo: WindowInfo, to position: CGPoint) -> Bool {
        print("🎯 Attempting to move window '\(windowInfo.title)' to position \(position)")
        
        let method = getPreferredMethod(for: windowInfo)
        print("📋 Using method: \(method)")
        
        var success = false
        
        switch method {
        case .accessibilityFirst:
            print("🔧 Trying Accessibility API first...")
            success = tryAccessibilityMove(windowInfo, to: position)
            if !success {
                print("🔄 Accessibility failed, trying AppleScript...")
                success = tryAppleScriptMove(windowInfo, to: position)
            }
            
        case .appleScriptFirst:
            print("🔧 Trying AppleScript first...")
            success = tryAppleScriptMove(windowInfo, to: position)
            if !success {
                print("🔄 AppleScript failed, trying Accessibility...")
                success = tryAccessibilityMove(windowInfo, to: position)
            }
            
        case .accessibilityWithRetry:
            print("🔧 Using Accessibility with retry...")
            success = accessibilityManager.moveWindowWithRetry(windowInfo, to: position)
            
        case .gradualMovement:
            print("🔧 Using gradual movement...")
            success = accessibilityManager.moveWindow(windowInfo, to: position, gradual: true)
        }
        
        // Update statistics
        stats.recordAttempt(app: windowInfo.appName, success: success)
        
        if success {
            print("✅ Successfully moved window '\(windowInfo.title)'")
        } else {
            print("❌ Failed to move window '\(windowInfo.title)' for app '\(windowInfo.appName)'")
        }
        
        return success
    }
    
    /// Resize a window using the best available method
    @discardableResult
    func resizeWindow(_ windowInfo: WindowInfo, to size: CGSize) -> Bool {
        var success = accessibilityManager.resizeWindow(windowInfo, to: size)
        
        if !success {
            success = appleScriptManager.resizeWindow(windowInfo, to: size)
        }
        
        stats.recordAttempt(app: windowInfo.appName, success: success)
        return success
    }
    
    /// Set window frame (position and size)
    @discardableResult
    func setWindowFrame(_ windowInfo: WindowInfo, frame: CGRect) -> Bool {
        let method = getPreferredMethod(for: windowInfo)
        var success = false
        
        switch method {
        case .accessibilityFirst, .accessibilityWithRetry:
            success = accessibilityManager.setWindowFrame(windowInfo, frame: frame, gradual: false)
            if !success {
                success = appleScriptManager.setWindowFrame(windowInfo, frame: frame)
            }
            
        case .appleScriptFirst:
            success = appleScriptManager.setWindowFrame(windowInfo, frame: frame)
            if !success {
                success = accessibilityManager.setWindowFrame(windowInfo, frame: frame, gradual: false)
            }
            
        case .gradualMovement:
            success = accessibilityManager.setWindowFrame(windowInfo, frame: frame, gradual: true)
        }
        
        stats.recordAttempt(app: windowInfo.appName, success: success)
        return success
    }
    
    /// Bring window to front
    func bringWindowToFront(_ windowInfo: WindowInfo) -> Bool {
        // Try AppleScript first as it's more reliable for activation
        return appleScriptManager.bringWindowToFront(windowInfo)
    }
    
    /// Check if window is resistant to manipulation
    func isWindowResistant(_ windowInfo: WindowInfo) -> Bool {
        // Check known resistant apps
        if resistantApps[windowInfo.appName] != nil {
            return true
        }
        
        // Test with accessibility API
        return accessibilityManager.isWindowResistant(windowInfo)
    }
    
    /// Get detailed window state
    func getWindowState(_ windowInfo: WindowInfo) -> WindowState {
        return accessibilityManager.getWindowState(windowInfo)
    }
    
    // MARK: - Batch Operations
    
    /// Move multiple windows efficiently
    func moveWindows(_ windows: [(WindowInfo, CGPoint)]) {
        // Group by app for optimization
        let groupedWindows = Dictionary(grouping: windows) { $0.0.appName }
        
        for (appName, windowGroup) in groupedWindows {
            print("📦 Moving \(windowGroup.count) windows for \(appName)")
            
            for (window, position) in windowGroup {
                moveWindow(window, to: position)
                
                // Small delay between windows of same app to avoid overwhelming it
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
    }
    
    /// Arrange windows in a grid
    func arrangeWindowsInGrid(_ windows: [WindowInfo], on screen: NSScreen, rows: Int, cols: Int) {
        print("📐 Arranging \(windows.count) windows in \(rows)x\(cols) grid on screen \(screen.localizedName)")
        
        let gridManager = GridLayoutManager()
        let grid = gridManager.calculateGridLayout(for: screen, rows: rows, cols: cols)
        
        var windowIndex = 0
        for row in 0..<rows {
            for col in 0..<cols {
                guard windowIndex < windows.count else { return }
                
                let window = windows[windowIndex]
                let frame = grid[row][col]
                
                print("📍 Placing window '\(window.title)' at row \(row), col \(col) - frame: \(frame)")
                setWindowFrame(window, frame: frame)
                windowIndex += 1
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Determine the preferred manipulation method for an app
    private func getPreferredMethod(for windowInfo: WindowInfo) -> WindowManipulationMethod {
        // Check known resistant apps
        if let method = resistantApps[windowInfo.appName] {
            return method
        }
        
        // Check statistics for best method
        if let bestMethod = stats.getBestMethod(for: windowInfo.appName) {
            return bestMethod
        }
        
        // Default to accessibility first
        return .accessibilityFirst
    }
    
    /// Try to move window using accessibility API
    private func tryAccessibilityMove(_ windowInfo: WindowInfo, to position: CGPoint) -> Bool {
        return accessibilityManager.moveWindow(windowInfo, to: position)
    }
    
    /// Try to move window using AppleScript
    private func tryAppleScriptMove(_ windowInfo: WindowInfo, to position: CGPoint) -> Bool {
        // Special handling for known poker apps
        if windowInfo.appName == "PokerStars" {
            return appleScriptManager.movePokerStarsWindow(windowInfo, to: position)
        } else if ["Safari", "Google Chrome", "Firefox"].contains(windowInfo.appName) {
            return appleScriptManager.moveBrowserPokerWindow(windowInfo, to: position)
        }
        
        return appleScriptManager.moveWindow(windowInfo, to: position)
    }
    
    // MARK: - Statistics
    
    /// Get manipulation statistics
    func getStatistics() -> ManipulationStats {
        return stats
    }
    
    /// Reset statistics
    func resetStatistics() {
        stats = ManipulationStats()
    }
}

// MARK: - Manipulation Statistics

/// Track success rates for different manipulation methods
struct ManipulationStats {
    private var attempts: [String: (total: Int, successful: Int)] = [:]
    private var methodSuccess: [String: [WindowManipulator.WindowManipulationMethod: Int]] = [:]
    
    mutating func recordAttempt(app: String, success: Bool) {
        let current = attempts[app] ?? (total: 0, successful: 0)
        attempts[app] = (
            total: current.total + 1,
            successful: current.successful + (success ? 1 : 0)
        )
    }
    
    mutating func recordMethodSuccess(app: String, method: WindowManipulator.WindowManipulationMethod) {
        var appMethods = methodSuccess[app] ?? [:]
        appMethods[method] = (appMethods[method] ?? 0) + 1
        methodSuccess[app] = appMethods
    }
    
    func getSuccessRate(for app: String) -> Double {
        guard let stats = attempts[app], stats.total > 0 else { return 0 }
        return Double(stats.successful) / Double(stats.total)
    }
    
    func getBestMethod(for app: String) -> WindowManipulator.WindowManipulationMethod? {
        guard let methods = methodSuccess[app] else { return nil }
        
        let sorted = methods.sorted { $0.value > $1.value }
        return sorted.first?.key
    }
    
    var summary: String {
        var result = "Window Manipulation Statistics:\n"
        
        for (app, stats) in attempts.sorted(by: { $0.key < $1.key }) {
            let rate = Double(stats.successful) / Double(stats.total) * 100
            result += "  \(app): \(stats.successful)/\(stats.total) (\(String(format: "%.1f", rate))%)\n"
        }
        
        return result
    }
}