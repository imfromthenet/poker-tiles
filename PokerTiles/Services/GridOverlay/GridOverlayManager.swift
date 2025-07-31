//
//  GridOverlayManager.swift
//  PokerTiles
//
//  Manages the grid overlay lifecycle and state
//

import Foundation
import AppKit
import SwiftUI
import Combine

/// Manages the grid overlay window and its state
class GridOverlayManager: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    // Overlay window
    private var overlayWindow: GridOverlayWindow?
    private var windowDelegate: GridOverlayWindowDelegate?
    
    // State
    @Published var isVisible = false
    @Published var currentLayout: GridLayoutManager.GridLayout = .twoByTwo
    @Published var occupiedSlots: Set<Int> = []
    @Published var tableCount: Int = 0
    
    // Appearance
    @Published var gridColor: NSColor = .systemGreen {
        didSet { savePreferences() }
    }
    @Published var padding: CGFloat = 10
    @Published var windowSpacing: CGFloat = 5
    @Published var lineWidth: CGFloat = 2 {
        didSet { savePreferences() }
    }
    @Published var useDashedLines: Bool = false {
        didSet { savePreferences() }
    }
    @Published var cornerRadius: CGFloat = 8 {
        didSet { savePreferences() }
    }
    
    // Hotkey tracking
    private var hotkeyPressTime: Date?
    private let quickReleaseThreshold: TimeInterval = 0.2
    private var isToggleMode = false
    
    // Window manager reference (will be set during integration)
    weak var windowManager: WindowManager?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupOverlayWindow()
        observeScreenChanges()
        loadPreferences()
    }
    
    // MARK: - Setup
    
    private func setupOverlayWindow() {
        overlayWindow = GridOverlayWindow()
        windowDelegate = GridOverlayWindowDelegate()
        overlayWindow?.delegate = windowDelegate
        
        // Set content
        let overlayView = GridOverlayView(overlayManager: self)
        overlayWindow?.setContent(overlayView)
    }
    
    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func screenConfigurationChanged() {
        overlayWindow?.updateForScreenChange()
    }
    
    // MARK: - Public Interface
    
    /// Show the grid overlay
    func showOverlay() {
        guard !isVisible else { return }
        
        updateGridState()
        overlayWindow?.showOverlay(animated: true)
        isVisible = true
        
        // Track press time for quick release detection
        hotkeyPressTime = Date()
    }
    
    /// Hide the grid overlay
    func hideOverlay() {
        guard isVisible else { return }
        
        // Check for quick release (potential toggle intent)
        if let pressTime = hotkeyPressTime,
           Date().timeIntervalSince(pressTime) < quickReleaseThreshold {
            // Quick tap detected - enter toggle mode
            isToggleMode = true
            return
        }
        
        overlayWindow?.hideOverlay(animated: true)
        isVisible = false
        isToggleMode = false
        hotkeyPressTime = nil
    }
    
    /// Toggle overlay visibility
    func toggleOverlay() {
        if isVisible && !isToggleMode {
            hideOverlay()
        } else {
            showOverlay()
            isToggleMode = true
        }
    }
    
    /// Handle hotkey press
    func handleHotkeyPress() {
        if isToggleMode {
            // In toggle mode, toggle visibility
            if isVisible {
                overlayWindow?.hideOverlay(animated: true)
                isVisible = false
                isToggleMode = false
            } else {
                showOverlay()
            }
        } else {
            // Normal mode - show on press
            showOverlay()
        }
    }
    
    /// Handle hotkey release
    func handleHotkeyRelease() {
        if !isToggleMode {
            hideOverlay()
        }
    }
    
    // MARK: - State Updates
    
    /// Update grid state from window manager
    func updateGridState() {
        guard let windowManager = windowManager else { return }
        
        // Get current layout
        let tableCount = windowManager.pokerTables.count
        self.tableCount = tableCount
        
        // Determine best layout - if no tables, still show 2x2 grid
        let layoutManager = GridLayoutManager()
        if tableCount > 0 {
            currentLayout = layoutManager.getBestLayout(for: tableCount)
        } else {
            // Default to 2x2 when no tables are present
            currentLayout = .twoByTwo
        }
        
        // Update grid options
        padding = windowManager.gridLayoutOptions.padding
        windowSpacing = windowManager.gridLayoutOptions.windowSpacing
        
        // Determine occupied slots
        occupiedSlots.removeAll()
        for i in 0..<min(tableCount, currentLayout.capacity) {
            occupiedSlots.insert(i)
        }
        
        print("[GridOverlayManager] Updated grid state:")
        print("  Table count: \(tableCount)")
        print("  Current layout: \(currentLayout.displayName) (\(currentLayout.rows)x\(currentLayout.columns))")
        print("  Occupied slots: \(occupiedSlots)")
    }
    
    /// Update grid appearance
    func updateAppearance(color: NSColor? = nil) {
        if let color = color {
            gridColor = color
        }
        
        // Force redraw
        if isVisible {
            updateGridState()
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        overlayWindow?.close()
    }
}

// MARK: - Settings

extension GridOverlayManager {
    
    /// Load saved preferences
    func loadPreferences() {
        let defaults = UserDefaults.standard
        
        if let colorData = defaults.data(forKey: "gridOverlayColor"),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            gridColor = color
        }
        
        isToggleMode = defaults.bool(forKey: "gridOverlayToggleMode")
        
        let savedLineWidth = defaults.float(forKey: "gridOverlayLineWidth")
        if savedLineWidth > 0 {
            lineWidth = CGFloat(savedLineWidth)
        }
        
        useDashedLines = defaults.bool(forKey: "gridOverlayUseDashedLines")
        
        let savedCornerRadius = defaults.float(forKey: "gridOverlayCornerRadius")
        if savedCornerRadius > 0 {
            cornerRadius = CGFloat(savedCornerRadius)
        }
    }
    
    /// Save preferences
    func savePreferences() {
        let defaults = UserDefaults.standard
        
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: gridColor, requiringSecureCoding: true) {
            defaults.set(colorData, forKey: "gridOverlayColor")
        }
        
        defaults.set(isToggleMode, forKey: "gridOverlayToggleMode")
        defaults.set(Float(lineWidth), forKey: "gridOverlayLineWidth")
        defaults.set(useDashedLines, forKey: "gridOverlayUseDashedLines")
        defaults.set(Float(cornerRadius), forKey: "gridOverlayCornerRadius")
    }
}