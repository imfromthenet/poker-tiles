# Hotkey Engine Documentation

This guide covers the implementation and usage of PokerTiles' global hotkey system for poker actions and table management.

## Overview

The hotkey engine provides configurable keyboard shortcuts for common poker actions (fold, call, raise) and table management operations (switch tables, arrange windows) using macOS's CGEventTap API.

## Architecture

```
┌────────────────────────────────────────────┐
│            Hotkey Manager                   │
│  • Registration & validation               │
│  • Conflict resolution                     │
│  • Context management                      │
└──────────────┬─────────────────────────────┘
               │
     ┌─────────▼──────────┐
     │  CGEventTap Hook   │
     │  • Low-level capture│
     │  • Event filtering  │
     └─────────┬──────────┘
               │
  ┌────────────┴────────────┬─────────────────┐
  │                         │                  │
┌─▼──────────────┐  ┌──────▼───────┐  ┌──────▼──────┐
│ Poker Actions  │  │Table Control │  │   Window    │
│                │  │              │  │ Management  │
│ • Fold         │  │ • Next table │  │ • Grid 2x2  │
│ • Check/Call   │  │ • Prev table │  │ • Grid 3x3  │
│ • Raise        │  │ • Close table│  │ • Cascade   │
│ • All-in       │  │ • Focus table│  │ • Stack     │
└────────────────┘  └──────────────┘  └─────────────┘
```

## Current Implementation

### HotkeyManager Class

```swift
class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var registeredHotkeys: [Hotkey] = []
    
    // Start monitoring
    func startMonitoring() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: handleKeyEvent,
            userInfo: nil
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        self.runLoopSource = runLoopSource
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
}
```

### Event Callback

```swift
private let handleKeyEvent: CGEventTapCallBack = { proxy, type, event, refcon in
    guard type == .keyDown else { return Unmanaged.passUnretained(event) }
    
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags
    
    // Check if this matches any registered hotkey
    if let hotkey = HotkeyManager.shared.findHotkey(keyCode: keyCode, flags: flags) {
        // Execute associated action
        HotkeyManager.shared.executeAction(for: hotkey)
        
        // Consume event to prevent propagation
        return nil
    }
    
    return Unmanaged.passUnretained(event)
}
```

## Hotkey Registration

### Hotkey Model

```swift
struct Hotkey: Codable, Equatable {
    let id: UUID
    let keyCode: CGKeyCode
    let modifiers: CGEventFlags
    let action: HotkeyAction
    var isEnabled: Bool = true
    
    var displayString: String {
        var parts: [String] = []
        
        if modifiers.contains(.maskCommand) { parts.append("⌘") }
        if modifiers.contains(.maskControl) { parts.append("⌃") }
        if modifiers.contains(.maskAlternate) { parts.append("⌥") }
        if modifiers.contains(.maskShift) { parts.append("⇧") }
        
        parts.append(KeyCodeTranslator.keyString(for: keyCode))
        
        return parts.joined()
    }
}

enum HotkeyAction: String, Codable {
    // Poker actions
    case fold
    case checkCall
    case raise
    case allIn
    case checkFold
    
    // Table navigation
    case nextTable
    case previousTable
    case closeTable
    
    // Window management
    case arrangeGrid2x2
    case arrangeGrid3x3
    case cascadeWindows
    case stackWindows
    
    // Utility
    case toggleHUD
    case takeScreenshot
    case markHand
}
```

### Registration API

```swift
extension HotkeyManager {
    func register(_ hotkey: Hotkey) throws {
        // Check for conflicts
        if let conflict = findConflict(for: hotkey) {
            throw HotkeyError.conflict(existing: conflict)
        }
        
        // Validate key combination
        guard isValidCombination(keyCode: hotkey.keyCode, modifiers: hotkey.modifiers) else {
            throw HotkeyError.invalidCombination
        }
        
        registeredHotkeys.append(hotkey)
        saveHotkeys()
    }
    
    func unregister(_ hotkey: Hotkey) {
        registeredHotkeys.removeAll { $0.id == hotkey.id }
        saveHotkeys()
    }
    
    private func findConflict(for hotkey: Hotkey) -> Hotkey? {
        registeredHotkeys.first { existing in
            existing.keyCode == hotkey.keyCode &&
            existing.modifiers == hotkey.modifiers &&
            existing.isEnabled
        }
    }
}
```

## Context-Aware Actions

### Active Table Detection

```swift
class HotkeyActionHandler {
    func executePokerAction(_ action: HotkeyAction) {
        // Find active poker table
        guard let activeTable = findActivePokerTable() else {
            showNotification("No active poker table found")
            return
        }
        
        switch action {
        case .fold:
            clickButton(labeled: "Fold", on: activeTable)
        case .checkCall:
            clickButton(labeled: ["Check", "Call"], on: activeTable)
        case .raise:
            clickButton(labeled: "Raise", on: activeTable)
        case .allIn:
            clickButton(labeled: "All-in", on: activeTable)
        default:
            break
        }
    }
    
    private func findActivePokerTable() -> PokerTable? {
        // Priority order:
        // 1. Table with mouse cursor
        // 2. Frontmost poker window
        // 3. Table awaiting action
        
        let mouseLocation = NSEvent.mouseLocation
        
        // Check if mouse is over a poker table
        if let table = pokerTables.first(where: { $0.frame.contains(mouseLocation) }) {
            return table
        }
        
        // Check frontmost window
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           let table = pokerTables.first(where: { $0.owningApp == frontmost }) {
            return table
        }
        
        // Check for tables awaiting action
        return pokerTables.first { $0.isAwaitingAction }
    }
}
```

### Multi-Table Support

```swift
extension HotkeyActionHandler {
    func handleMultiTableAction(_ action: HotkeyAction, tables: [PokerTable]) {
        switch action {
        case .nextTable:
            cycleToNextTable(from: tables)
        case .previousTable:
            cycleToPreviousTable(from: tables)
        default:
            // Apply to all tables with pending actions
            let pendingTables = tables.filter { $0.isAwaitingAction }
            for table in pendingTables {
                executePokerAction(action, on: table)
            }
        }
    }
    
    private func cycleToNextTable(from tables: [PokerTable]) {
        guard let current = tables.first(where: { $0.isFocused }),
              let currentIndex = tables.firstIndex(of: current) else {
            // Focus first table
            tables.first?.focus()
            return
        }
        
        let nextIndex = (currentIndex + 1) % tables.count
        tables[nextIndex].focus()
    }
}
```

## Key Code Translation

```swift
struct KeyCodeTranslator {
    static let keyMap: [CGKeyCode: String] = [
        0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F",
        0x04: "H", 0x05: "G", 0x06: "Z", 0x07: "X",
        0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
        0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y",
        0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
        0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
        0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8",
        0x1D: "0", 0x1E: "]", 0x1F: "O", 0x20: "U",
        0x21: "[", 0x22: "I", 0x23: "P", 0x25: "L",
        0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";",
        0x2A: "\\", 0x2B: ",", 0x2C: "/", 0x2D: "N",
        0x2E: "M", 0x2F: ".", 0x32: "`",
        0x24: "↩︎", 0x30: "⇥", 0x31: "Space", 0x33: "⌫",
        0x35: "⎋", 0x7A: "F1", 0x78: "F2", 0x63: "F3",
        // ... more key codes
    ]
    
    static func keyString(for keyCode: CGKeyCode) -> String {
        keyMap[keyCode] ?? "Key\(keyCode)"
    }
    
    static func keyCode(for character: String) -> CGKeyCode? {
        keyMap.first { $0.value == character }?.key
    }
}
```

## Preferences UI

```swift
struct HotkeySettingsView: View {
    @ObservedObject var hotkeyManager = HotkeyManager.shared
    @State private var recordingHotkey: HotkeyAction?
    
    var body: some View {
        Form {
            Section("Poker Actions") {
                HotkeyRow(action: .fold, hotkey: binding(for: .fold))
                HotkeyRow(action: .checkCall, hotkey: binding(for: .checkCall))
                HotkeyRow(action: .raise, hotkey: binding(for: .raise))
                HotkeyRow(action: .allIn, hotkey: binding(for: .allIn))
            }
            
            Section("Table Management") {
                HotkeyRow(action: .nextTable, hotkey: binding(for: .nextTable))
                HotkeyRow(action: .previousTable, hotkey: binding(for: .previousTable))
                HotkeyRow(action: .arrangeGrid2x2, hotkey: binding(for: .arrangeGrid2x2))
            }
        }
    }
    
    private func binding(for action: HotkeyAction) -> Binding<Hotkey?> {
        Binding(
            get: { hotkeyManager.hotkey(for: action) },
            set: { newHotkey in
                if let hotkey = newHotkey {
                    try? hotkeyManager.register(hotkey)
                }
            }
        )
    }
}

struct HotkeyRow: View {
    let action: HotkeyAction
    @Binding var hotkey: Hotkey?
    @State private var isRecording = false
    
    var body: some View {
        HStack {
            Text(action.displayName)
            Spacer()
            
            if isRecording {
                Text("Press keys...")
                    .foregroundColor(.secondary)
            } else if let hotkey = hotkey {
                Text(hotkey.displayString)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            } else {
                Text("Not set")
                    .foregroundColor(.secondary)
            }
            
            Button(isRecording ? "Cancel" : "Set") {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}
```

## Performance Optimization

### Event Filtering

```swift
extension HotkeyManager {
    private func shouldProcessEvent(_ event: CGEvent) -> Bool {
        // Quick checks to avoid unnecessary processing
        
        // 1. Check if any hotkeys use this key
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let hasRegisteredKey = registeredHotkeys.contains { $0.keyCode == CGKeyCode(keyCode) }
        
        if !hasRegisteredKey {
            return false
        }
        
        // 2. Check if modifiers might match
        let flags = event.flags
        let hasModifiers = flags.contains(.maskCommand) || 
                          flags.contains(.maskControl) || 
                          flags.contains(.maskAlternate)
        
        // Most hotkeys have modifiers
        if registeredHotkeys.allSatisfy({ $0.modifiers != .init(rawValue: 0) }) && !hasModifiers {
            return false
        }
        
        return true
    }
}
```

### Caching

```swift
class HotkeyLookupCache {
    private var cache: [Int: Hotkey?] = [:]
    
    func lookup(keyCode: CGKeyCode, flags: CGEventFlags) -> Hotkey? {
        let cacheKey = makeCacheKey(keyCode: keyCode, flags: flags)
        
        if let cached = cache[cacheKey] {
            return cached
        }
        
        let hotkey = HotkeyManager.shared.registeredHotkeys.first { h in
            h.keyCode == keyCode && h.modifiers == flags && h.isEnabled
        }
        
        cache[cacheKey] = hotkey
        return hotkey
    }
    
    func invalidate() {
        cache.removeAll()
    }
    
    private func makeCacheKey(keyCode: CGKeyCode, flags: CGEventFlags) -> Int {
        Int(keyCode) | (Int(flags.rawValue) << 16)
    }
}
```

## Error Handling

```swift
enum HotkeyError: LocalizedError {
    case eventTapCreationFailed
    case permissionDenied
    case conflict(existing: Hotkey)
    case invalidCombination
    case systemReserved
    
    var errorDescription: String? {
        switch self {
        case .eventTapCreationFailed:
            return "Failed to create keyboard event monitor"
        case .permissionDenied:
            return "Accessibility permission required for global hotkeys"
        case .conflict(let existing):
            return "Hotkey conflicts with \(existing.action.displayName)"
        case .invalidCombination:
            return "Invalid key combination"
        case .systemReserved:
            return "This key combination is reserved by the system"
        }
    }
}
```

## Best Practices

1. **Permission Handling**
   - Check for accessibility permission before starting
   - Provide clear instructions for granting permission
   - Handle permission revocation gracefully

2. **Conflict Resolution**
   - Check against system shortcuts
   - Warn about application conflicts
   - Allow users to override with confirmation

3. **User Experience**
   - Provide visual feedback when hotkey is triggered
   - Show current hotkey state in HUD
   - Allow temporary disable during typing

4. **Performance**
   - Filter events early to minimize processing
   - Use caching for frequent lookups
   - Avoid blocking the event tap callback

## Testing

```swift
class HotkeyTests {
    func testHotkeyRegistration() {
        let manager = HotkeyManager()
        let hotkey = Hotkey(
            id: UUID(),
            keyCode: 0x00, // A
            modifiers: .maskCommand,
            action: .fold
        )
        
        XCTAssertNoThrow(try manager.register(hotkey))
        XCTAssertEqual(manager.registeredHotkeys.count, 1)
        
        // Test conflict detection
        let duplicate = Hotkey(
            id: UUID(),
            keyCode: 0x00,
            modifiers: .maskCommand,
            action: .raise
        )
        
        XCTAssertThrowsError(try manager.register(duplicate))
    }
    
    func testKeyCodeTranslation() {
        XCTAssertEqual(KeyCodeTranslator.keyString(for: 0x00), "A")
        XCTAssertEqual(KeyCodeTranslator.keyCode(for: "A"), 0x00)
    }
}
```

## Future Enhancements

1. **Action Sequences**
   - Support multi-key sequences (e.g., "gg" for all-in)
   - Customizable delays between actions

2. **Context Profiles**
   - Different hotkey sets for cash vs tournament
   - Site-specific configurations

3. **Advanced Actions**
   - Bet sizing presets
   - Auto-timebank activation
   - Note-taking shortcuts

4. **Integration**
   - Import/export hotkey configurations
   - Sync across devices
   - Share configurations with other players