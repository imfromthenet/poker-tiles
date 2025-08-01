//
//  HotkeyManager.swift
//  PokerTiles
//
//  Manages global hotkeys for poker actions and window layouts
//

import Foundation
import AppKit
import Combine

/// Manages global hotkeys for poker actions and window management
class HotkeyManager: ObservableObject {
    
    // MARK: - Types
    
    // Track last switched table index for continuous navigation
    private static var lastSwitchedTableIndex: Int?
    
    enum HotkeyAction: String, CaseIterable {
        // Window Layout Actions
        case grid1x2 = "1x2 Grid Layout"
        case grid2x2 = "2x2 Grid Layout"
        case grid2x3 = "2x3 Grid Layout"
        case grid3x3 = "3x3 Grid Layout"
        case grid3x4 = "3x4 Grid Layout"
        case grid4x4 = "4x4 Grid Layout"
        case cascade = "Cascade Windows"
        case stack = "Stack Windows"
        case autoArrange = "Auto Arrange"
        case showGridOverlay = "Show Grid Overlay"
        
        // Poker Actions
        case fold = "Fold"
        case check = "Check"
        case call = "Call"
        case raise = "Raise"
        case allIn = "All In"
        case nextTable = "Next Table"
        case previousTable = "Previous Table"
        
        var category: String {
            switch self {
            case .grid1x2, .grid2x2, .grid2x3, .grid3x3, .grid3x4, .grid4x4, .cascade, .stack, .autoArrange, .showGridOverlay:
                return "Window Layout"
            case .fold, .check, .call, .raise, .allIn, .nextTable, .previousTable:
                return "Poker Actions"
            }
        }
        
        var defaultKeyCode: UInt16? {
            switch self {
            // Layout hotkeys (Cmd+Shift+Number)
            case .grid1x2: return GlobalHotkeyMonitor.KeyCode.one
            case .grid2x2: return GlobalHotkeyMonitor.KeyCode.two
            case .grid2x3: return GlobalHotkeyMonitor.KeyCode.three
            case .grid3x3: return GlobalHotkeyMonitor.KeyCode.four
            case .grid3x4: return GlobalHotkeyMonitor.KeyCode.five
            case .grid4x4: return GlobalHotkeyMonitor.KeyCode.six
            case .cascade: return GlobalHotkeyMonitor.KeyCode.c
            case .stack: return GlobalHotkeyMonitor.KeyCode.s
            case .autoArrange: return GlobalHotkeyMonitor.KeyCode.a
            case .showGridOverlay: return GlobalHotkeyMonitor.KeyCode.g
                
            // Poker action hotkeys
            case .fold: return GlobalHotkeyMonitor.KeyCode.f
            case .check: return GlobalHotkeyMonitor.KeyCode.space
            case .call: return GlobalHotkeyMonitor.KeyCode.c
            case .raise: return GlobalHotkeyMonitor.KeyCode.r
            case .allIn: return GlobalHotkeyMonitor.KeyCode.a
            case .nextTable: return GlobalHotkeyMonitor.KeyCode.n
            case .previousTable: return GlobalHotkeyMonitor.KeyCode.p
            }
        }
        
        var defaultModifiers: NSEvent.ModifierFlags? {
            switch self {
            // Layout hotkeys use Cmd+Shift
            case .grid1x2, .grid2x2, .grid2x3, .grid3x3, .grid3x4, .grid4x4, .cascade, .stack, .autoArrange, .showGridOverlay:
                return [.command, .shift]
                
            // Poker actions use Ctrl
            case .fold, .check, .call, .raise, .allIn:
                return [.control]
                
            // Table navigation
            case .nextTable:
                return [.control]
            case .previousTable:
                return [.control, .shift]
            }
        }
    }
    
    struct HotkeyBinding: Codable {
        let action: String
        let keyCode: UInt16
        let modifiers: UInt
        
        init(action: HotkeyAction, keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
            self.action = action.rawValue
            self.keyCode = keyCode
            self.modifiers = modifiers.rawValue
        }
    }
    
    // MARK: - Properties
    
    @Published var isEnabled = false
    @Published var invalidBindings: [(action: String, keyCode: UInt16)] = []
    private var registeredHotkeys: [HotkeyAction: (keyCode: UInt16, modifiers: NSEvent.ModifierFlags)] = [:]
    private weak var windowManager: WindowManager?
    private let monitor = GlobalHotkeyMonitor.shared
    private(set) var gridOverlayManager: GridOverlayManager?
    
    // MARK: - Initialization
    
    init(windowManager: WindowManager? = nil) {
        self.windowManager = windowManager
        
        // Initialize grid overlay manager
        self.gridOverlayManager = GridOverlayManager()
        self.gridOverlayManager?.windowManager = windowManager
        
        loadHotkeys()
    }
    
    // MARK: - Public Methods
    
    func hasInvalidBindings() -> Bool {
        return !invalidBindings.isEmpty
    }
    
    func clearInvalidBindings() {
        // Clear invalid bindings from UserDefaults
        if !invalidBindings.isEmpty {
            let count = invalidBindings.count
            let validBindings = loadSavedBindings().filter { (actionName, _) in
                HotkeyAction(rawValue: actionName) != nil
            }
            
            if let data = try? JSONEncoder().encode(Array(validBindings.values)) {
                UserDefaults.standard.set(data, forKey: "PokerTilesHotkeys")
                invalidBindings.removeAll()
                print("✅ Cleared \(count) invalid hotkey bindings")
            }
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        if enabled {
            // Check for accessibility permission first
            if !PermissionManager.hasAccessibilityPermission() {
                print("❌ Accessibility permission required for hotkeys")
                PermissionManager.requestAccessibilityPermission()
                isEnabled = false
                return
            }
            
            if monitor.startMonitoring() {
                isEnabled = true
                registerAllHotkeys()
                print("✅ Hotkeys enabled")
            } else {
                isEnabled = false
                print("❌ Failed to start hotkey monitoring")
            }
        } else {
            isEnabled = false
            unregisterAllHotkeys()
            monitor.stopMonitoring()
            print("✅ Hotkeys disabled")
        }
    }
    
    func registerHotkey(_ action: HotkeyAction, keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        // Unregister existing hotkey if any
        unregisterHotkey(action)
        
        // Special handling for grid overlay (needs up/down events)
        if action == .showGridOverlay {
            print("📐 Registering grid overlay hotkey with up/down handling")
            monitor.registerUpDown(keyCode: keyCode, modifiers: modifiers) { [weak self] isKeyDown in
                print("📐 Grid overlay hotkey \(isKeyDown ? "pressed" : "released")")
                if isKeyDown {
                    self?.gridOverlayManager?.handleHotkeyPress()
                } else {
                    self?.gridOverlayManager?.handleHotkeyRelease()
                }
            }
        } else {
            // Regular hotkey registration
            monitor.register(keyCode: keyCode, modifiers: modifiers) { [weak self] in
                self?.handleHotkeyAction(action)
            }
        }
        
        // Store registration
        registeredHotkeys[action] = (keyCode: keyCode, modifiers: modifiers)
        
        // Save to preferences
        saveHotkey(action: action, keyCode: keyCode, modifiers: modifiers)
    }
    
    func unregisterHotkey(_ action: HotkeyAction) {
        if let (keyCode, modifiers) = registeredHotkeys[action] {
            monitor.unregister(keyCode: keyCode, modifiers: modifiers)
            registeredHotkeys.removeValue(forKey: action)
        }
    }
    
    func getHotkey(for action: HotkeyAction) -> (keyCode: UInt16, modifiers: NSEvent.ModifierFlags)? {
        return registeredHotkeys[action]
    }
    
    func resetToDefaults() {
        unregisterAllHotkeys()
        
        for action in HotkeyAction.allCases {
            if let keyCode = action.defaultKeyCode,
               let modifiers = action.defaultModifiers {
                registerHotkey(action, keyCode: keyCode, modifiers: modifiers)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func registerAllHotkeys() {
        guard isEnabled else { return }
        
        // Register default hotkeys if none exist
        if registeredHotkeys.isEmpty {
            for action in HotkeyAction.allCases {
                if let keyCode = action.defaultKeyCode,
                   let modifiers = action.defaultModifiers {
                    registerHotkey(action, keyCode: keyCode, modifiers: modifiers)
                }
            }
        } else {
            // Re-register existing hotkeys
            print("📋 Re-registering \(registeredHotkeys.count) existing hotkeys")
            for (action, (keyCode, modifiers)) in registeredHotkeys {
                if action == .showGridOverlay {
                    print("📐 Re-registering grid overlay hotkey")
                    monitor.registerUpDown(keyCode: keyCode, modifiers: modifiers) { [weak self] isKeyDown in
                        print("📐 Grid overlay hotkey \(isKeyDown ? "pressed" : "released")")
                        if isKeyDown {
                            self?.gridOverlayManager?.handleHotkeyPress()
                        } else {
                            self?.gridOverlayManager?.handleHotkeyRelease()
                        }
                    }
                } else {
                    print("🔑 Re-registering hotkey: \(action.rawValue)")
                    monitor.register(keyCode: keyCode, modifiers: modifiers) { [weak self] in
                        self?.handleHotkeyAction(action)
                    }
                }
            }
        }
    }
    
    private func unregisterAllHotkeys() {
        for (_, (keyCode, modifiers)) in registeredHotkeys {
            monitor.unregister(keyCode: keyCode, modifiers: modifiers)
        }
        registeredHotkeys.removeAll()
    }
    
    private func handleHotkeyAction(_ action: HotkeyAction) {
        guard let windowManager = windowManager else { 
            print("❌ No window manager available for hotkey action")
            return 
        }
        
        print("🎯 Hotkey triggered: \(action.rawValue)")
        
        DispatchQueue.main.async {
            switch action {
            // Window Layout Actions
            case .grid1x2:
                print("Arranging tables in 1x2 grid")
                windowManager.arrangePokerTablesInGrid(.oneByTwo)
                
            case .grid2x2:
                windowManager.arrangePokerTablesInGrid(.twoByTwo)
                
            case .grid2x3:
                windowManager.arrangePokerTablesInGrid(.twoByThree)
                
            case .grid3x3:
                windowManager.arrangePokerTablesInGrid(.threeByThree)
                
            case .grid3x4:
                windowManager.arrangePokerTablesInGrid(.threeByFour)
                
            case .grid4x4:
                windowManager.arrangePokerTablesInGrid(.fourByFour)
                
            case .cascade:
                windowManager.cascadePokerTables()
                
            case .stack:
                windowManager.stackPokerTables()
                
            case .autoArrange:
                windowManager.autoArrangePokerTables()
                
            case .showGridOverlay:
                // Handled by up/down handler, but toggle if called directly
                self.gridOverlayManager?.toggleOverlay()
                
            // Poker Actions (to be implemented)
            case .fold, .check, .call, .raise, .allIn:
                self.performPokerAction(action)
                
            // Table Navigation
            case .nextTable:
                self.switchToNextTable()
                
            case .previousTable:
                self.switchToPreviousTable()
            }
        }
    }
    
    private func performPokerAction(_ action: HotkeyAction) {
        // TODO: Implement poker action automation
        // This would involve:
        // 1. Finding the active poker table
        // 2. Locating the appropriate button
        // 3. Simulating a click on that button
        
        print("Poker action '\(action.rawValue)' triggered - implementation pending")
    }
    
    private func switchToNextTable() {
        guard let windowManager = windowManager else { 
            print("❌ switchToNextTable: No window manager")
            return 
        }
        
        let tables = windowManager.pokerTables
        guard !tables.isEmpty else { return }
        
        // Get the frontmost app to determine current table
        let workspace = NSWorkspace.shared
        let frontmostApp = workspace.frontmostApplication
        
        // Try to find the current table
        var currentIndex: Int?
        
        // First check if we have a last switched index (for rapid switching)
        if let lastIndex = HotkeyManager.lastSwitchedTableIndex, lastIndex < tables.count {
            currentIndex = lastIndex
        } else if let frontmostBundleId = frontmostApp?.bundleIdentifier {
            // Otherwise, check if any poker table's app is frontmost
            currentIndex = tables.firstIndex { table in
                table.windowInfo.bundleIdentifier == frontmostBundleId
            }
        }
        
        // Determine next index
        let nextIndex: Int
        if let index = currentIndex {
            nextIndex = (index + 1) % tables.count
        } else {
            nextIndex = 0
        }
        
        windowManager.bringWindowToFront(tables[nextIndex].windowInfo)
        HotkeyManager.lastSwitchedTableIndex = nextIndex  // Remember what we switched to
    }
    
    private func switchToPreviousTable() {
        guard let windowManager = windowManager else { return }
        
        let tables = windowManager.pokerTables
        guard !tables.isEmpty else { return }
        
        // Get the frontmost app to determine current table
        let workspace = NSWorkspace.shared
        let frontmostApp = workspace.frontmostApplication
        
        // Try to find the current table
        var currentIndex: Int?
        
        // First check if we have a last switched index (for rapid switching)
        if let lastIndex = HotkeyManager.lastSwitchedTableIndex, lastIndex < tables.count {
            currentIndex = lastIndex
        } else if let frontmostBundleId = frontmostApp?.bundleIdentifier {
            // Otherwise, check if any poker table's app is frontmost
            currentIndex = tables.firstIndex { table in
                table.windowInfo.bundleIdentifier == frontmostBundleId
            }
        }
        
        // Determine previous index
        let previousIndex: Int
        if let index = currentIndex {
            previousIndex = index > 0 ? index - 1 : tables.count - 1
        } else {
            previousIndex = tables.count - 1
        }
        
        windowManager.bringWindowToFront(tables[previousIndex].windowInfo)
        HotkeyManager.lastSwitchedTableIndex = previousIndex  // Remember what we switched to
    }
    
    // MARK: - Persistence
    
    private func saveHotkey(action: HotkeyAction, keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        let binding = HotkeyBinding(action: action, keyCode: keyCode, modifiers: modifiers)
        
        var bindings = loadSavedBindings()
        bindings[action.rawValue] = binding
        
        if let data = try? JSONEncoder().encode(Array(bindings.values)) {
            UserDefaults.standard.set(data, forKey: "PokerTilesHotkeys")
        }
    }
    
    private func loadHotkeys() {
        invalidBindings.removeAll()
        let bindings = loadSavedBindings()
        
        print("📖 Loading saved hotkeys: \(bindings.count) bindings found")
        
        // If no saved bindings exist, register defaults immediately
        if bindings.isEmpty {
            print("📖 No saved hotkeys found, registering defaults")
            for action in HotkeyAction.allCases {
                if let keyCode = action.defaultKeyCode,
                   let modifiers = action.defaultModifiers {
                    print("   Registering default: \(action.rawValue)")
                    registeredHotkeys[action] = (keyCode: keyCode, modifiers: modifiers)
                    saveHotkey(action: action, keyCode: keyCode, modifiers: modifiers)
                }
            }
        } else {
            // Load saved bindings
            for (actionName, binding) in bindings {
                guard let action = HotkeyAction(rawValue: actionName) else {
                    // Track invalid binding for user feedback
                    invalidBindings.append((action: actionName, keyCode: binding.keyCode))
                    print("⚠️ Invalid hotkey binding found: '\(actionName)' with keyCode: \(binding.keyCode)")
                    continue
                }
                
                let modifiers = NSEvent.ModifierFlags(rawValue: binding.modifiers)
                print("📖 Loading hotkey: \(action.rawValue) -> keyCode: \(binding.keyCode), modifiers: \(binding.modifiers)")
                registeredHotkeys[action] = (keyCode: binding.keyCode, modifiers: modifiers)
            }
        }
        
        if !invalidBindings.isEmpty {
            print("❌ Found \(invalidBindings.count) invalid hotkey bindings that were skipped")
        }
    }
    
    private func loadSavedBindings() -> [String: HotkeyBinding] {
        guard let data = UserDefaults.standard.data(forKey: "PokerTilesHotkeys"),
              let bindings = try? JSONDecoder().decode([HotkeyBinding].self, from: data) else {
            return [:]
        }
        
        var bindingsDict: [String: HotkeyBinding] = [:]
        for binding in bindings {
            bindingsDict[binding.action] = binding
        }
        
        return bindingsDict
    }
}

// MARK: - HotKey Package Compatibility

