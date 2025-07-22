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
    
    enum HotkeyAction: String, CaseIterable {
        // Window Layout Actions
        case grid2x1 = "2x1 Grid Layout"
        case grid2x2 = "2x2 Grid Layout"
        case grid3x3 = "3x3 Grid Layout"
        case cascade = "Cascade Windows"
        case stack = "Stack Windows"
        case autoArrange = "Auto Arrange"
        
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
            case .grid2x1, .grid2x2, .grid3x3, .cascade, .stack, .autoArrange:
                return "Window Layout"
            case .fold, .check, .call, .raise, .allIn, .nextTable, .previousTable:
                return "Poker Actions"
            }
        }
        
        var defaultKey: Key? {
            switch self {
            // Layout hotkeys (Cmd+Shift+Number)
            case .grid2x1: return .one
            case .grid2x2: return .two
            case .grid3x3: return .three
            case .cascade: return .c
            case .stack: return .s
            case .autoArrange: return .a
                
            // Poker action hotkeys
            case .fold: return .f
            case .check: return .space
            case .call: return .c
            case .raise: return .r
            case .allIn: return .a
            case .nextTable: return .tab
            case .previousTable: return .tab
            }
        }
        
        var defaultModifiers: NSEvent.ModifierFlags? {
            switch self {
            // Layout hotkeys use Cmd+Shift
            case .grid2x1, .grid2x2, .grid3x3, .cascade, .stack, .autoArrange:
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
        let keyCode: Int
        let modifiers: Int
        
        init(action: HotkeyAction, key: Key, modifiers: NSEvent.ModifierFlags) {
            self.action = action.rawValue
            self.keyCode = Int(key.carbonKeyCode)
            self.modifiers = Int(modifiers.rawValue)
        }
    }
    
    // MARK: - Properties
    
    @Published var isEnabled = false
    private var hotkeys: [HotkeyAction: HotKey] = [:]
    private weak var windowManager: WindowManager?
    
    // MARK: - Initialization
    
    init(windowManager: WindowManager? = nil) {
        self.windowManager = windowManager
        loadHotkeys()
    }
    
    // MARK: - Public Methods
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        
        if enabled {
            registerAllHotkeys()
        } else {
            unregisterAllHotkeys()
        }
    }
    
    func registerHotkey(_ action: HotkeyAction, key: Key, modifiers: NSEvent.ModifierFlags) {
        // Unregister existing hotkey if any
        unregisterHotkey(action)
        
        // Create and register new hotkey
        let hotkey = HotKey(key: key, modifiers: modifiers)
        hotkey.keyDownHandler = { [weak self] in
            self?.handleHotkeyAction(action)
        }
        
        hotkeys[action] = hotkey
        
        // Save to preferences
        saveHotkey(action: action, key: key, modifiers: modifiers)
    }
    
    func unregisterHotkey(_ action: HotkeyAction) {
        hotkeys[action] = nil
    }
    
    func getHotkey(for action: HotkeyAction) -> (key: Key, modifiers: NSEvent.ModifierFlags)? {
        guard let hotkey = hotkeys[action] else { return nil }
        
        return (hotkey.key, hotkey.modifiers)
    }
    
    func resetToDefaults() {
        unregisterAllHotkeys()
        
        for action in HotkeyAction.allCases {
            if let key = action.defaultKey,
               let modifiers = action.defaultModifiers {
                registerHotkey(action, key: key, modifiers: modifiers)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func registerAllHotkeys() {
        guard isEnabled else { return }
        
        // Register default hotkeys if none exist
        if hotkeys.isEmpty {
            for action in HotkeyAction.allCases {
                if let key = action.defaultKey,
                   let modifiers = action.defaultModifiers {
                    registerHotkey(action, key: key, modifiers: modifiers)
                }
            }
        }
    }
    
    private func unregisterAllHotkeys() {
        hotkeys.removeAll()
    }
    
    private func handleHotkeyAction(_ action: HotkeyAction) {
        guard let windowManager = windowManager else { return }
        
        DispatchQueue.main.async {
            switch action {
            // Window Layout Actions
            case .grid2x1:
                windowManager.arrangePokerTablesInGrid(.twoByOne)
                
            case .grid2x2:
                windowManager.arrangePokerTablesInGrid(.twoByTwo)
                
            case .grid3x3:
                windowManager.arrangePokerTablesInGrid(.threeByThree)
                
            case .cascade:
                windowManager.cascadePokerTables()
                
            case .stack:
                windowManager.stackPokerTables()
                
            case .autoArrange:
                windowManager.autoArrangePokerTables()
                
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
        guard let windowManager = windowManager else { return }
        
        let tables = windowManager.pokerTables
        guard !tables.isEmpty else { return }
        
        // Find current active table
        if let currentIndex = tables.firstIndex(where: { $0.isActive }) {
            let nextIndex = (currentIndex + 1) % tables.count
            windowManager.bringWindowToFront(tables[nextIndex].windowInfo)
        } else {
            // No active table, activate the first one
            windowManager.bringWindowToFront(tables[0].windowInfo)
        }
    }
    
    private func switchToPreviousTable() {
        guard let windowManager = windowManager else { return }
        
        let tables = windowManager.pokerTables
        guard !tables.isEmpty else { return }
        
        // Find current active table
        if let currentIndex = tables.firstIndex(where: { $0.isActive }) {
            let previousIndex = currentIndex > 0 ? currentIndex - 1 : tables.count - 1
            windowManager.bringWindowToFront(tables[previousIndex].windowInfo)
        } else {
            // No active table, activate the last one
            windowManager.bringWindowToFront(tables[tables.count - 1].windowInfo)
        }
    }
    
    // MARK: - Persistence
    
    private func saveHotkey(action: HotkeyAction, key: Key, modifiers: NSEvent.ModifierFlags) {
        let binding = HotkeyBinding(action: action, key: key, modifiers: modifiers)
        
        var bindings = loadSavedBindings()
        bindings[action.rawValue] = binding
        
        if let data = try? JSONEncoder().encode(Array(bindings.values)) {
            UserDefaults.standard.set(data, forKey: "PokerTilesHotkeys")
        }
    }
    
    private func loadHotkeys() {
        let bindings = loadSavedBindings()
        
        for (actionName, binding) in bindings {
            guard let action = HotkeyAction(rawValue: actionName),
                  let key = Key(carbonKeyCode: UInt32(binding.keyCode)) else {
                continue
            }
            
            let modifiers = NSEvent.ModifierFlags(rawValue: UInt(binding.modifiers))
            registerHotkey(action, key: key, modifiers: modifiers)
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

// Mock HotKey implementation
// In production, you would use the HotKey package from:
// https://github.com/soffes/HotKey
class HotKey {
    let key: Key
    let modifiers: NSEvent.ModifierFlags
    var keyDownHandler: (() -> Void)?
    
    init(key: Key, modifiers: NSEvent.ModifierFlags) {
        self.key = key
        self.modifiers = modifiers
    }
}

// Mock Key enum
enum Key {
    case a, c, f, r, s
    case one, two, three
    case space, tab
    
    var carbonKeyCode: UInt32 {
        switch self {
        case .a: return 0
        case .c: return 8
        case .f: return 3
        case .r: return 15
        case .s: return 1
        case .one: return 18
        case .two: return 19
        case .three: return 20
        case .space: return 49
        case .tab: return 48
        }
    }
    
    init?(carbonKeyCode: UInt32) {
        switch carbonKeyCode {
        case 0: self = .a
        case 8: self = .c
        case 3: self = .f
        case 15: self = .r
        case 1: self = .s
        case 18: self = .one
        case 19: self = .two
        case 20: self = .three
        case 49: self = .space
        case 48: self = .tab
        default: return nil
        }
    }
}