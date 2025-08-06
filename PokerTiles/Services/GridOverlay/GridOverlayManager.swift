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
    
    // Manual layout override
    var manualLayoutOverride: GridLayoutManager.GridLayout?
    
    // Appearance
    @Published var gridColor: NSColor = .systemGreen {
        didSet { savePreferences() }
    }
    @Published var padding: CGFloat = SettingsConstants.GridLayout.defaultPadding
    @Published var windowSpacing: CGFloat = SettingsConstants.GridLayout.defaultWindowSpacing
    @Published var lineWidth: CGFloat = SettingsConstants.GridLayout.defaultLineWidth {
        didSet { savePreferences() }
    }
    @Published var useDashedLines: Bool = false {
        didSet { savePreferences() }
    }
    @Published var cornerRadius: CGFloat = SettingsConstants.GridLayout.defaultCornerRadius {
        didSet { savePreferences() }
    }
    
    // Hotkey tracking
    private var hotkeyPressTime: Date?
    private let quickReleaseThreshold: TimeInterval = SettingsConstants.Hotkey.quickReleaseThreshold
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
        showOverlay()
    }
    
    /// Handle hotkey release
    func handleHotkeyRelease() {
        hideOverlay()
    }
    
    // MARK: - State Updates
    
    /// Update grid state from window manager
    func updateGridState() {
        guard let windowManager = windowManager else { return }
        
        // Get current layout
        let tableCount = windowManager.pokerTables.count
        self.tableCount = tableCount
        
        // Use manual override if set, otherwise determine best layout
        if let override = manualLayoutOverride {
            currentLayout = override
        } else {
            let layoutManager = GridLayoutManager()
            if tableCount > 0 {
                currentLayout = layoutManager.getBestLayout(for: tableCount)
            } else {
                // Default to 2x2 when no tables are present
                currentLayout = .twoByTwo
            }
        }
        
        // Update grid options
        padding = windowManager.gridLayoutOptions.padding
        windowSpacing = windowManager.gridLayoutOptions.windowSpacing
        
        // Get actual occupied slots from position tracker
        occupiedSlots = windowManager.tablePositionTracker.occupiedSlots
        
        // If no positions tracked yet, fall back to simple count-based display
        if occupiedSlots.isEmpty && tableCount > 0 {
            // Show slots based on table count as fallback
            for i in 0..<min(tableCount, currentLayout.capacity) {
                occupiedSlots.insert(i)
            }
        }
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
        
        defaults.set(Float(lineWidth), forKey: "gridOverlayLineWidth")
        defaults.set(useDashedLines, forKey: "gridOverlayUseDashedLines")
        defaults.set(Float(cornerRadius), forKey: "gridOverlayCornerRadius")
    }
}