//
//  GlobalHotkeyMonitor.swift
//  PokerTiles
//
//  Native implementation of global hotkey monitoring using CGEventTap
//

import Foundation
import AppKit
import Carbon

/// Native implementation of global hotkey monitoring
class GlobalHotkeyMonitor {
    
    // MARK: - Types
    
    typealias HotkeyHandler = () -> Void
    typealias HotkeyUpDownHandler = (Bool) -> Void
    
    struct Hotkey: Hashable {
        let keyCode: UInt16
        let modifiers: CGEventFlags
        
        // Mask for relevant modifier flags only
        static let modifierMask: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
        
        static func == (lhs: Hotkey, rhs: Hotkey) -> Bool {
            // Compare only relevant modifier flags
            let lhsRelevantFlags = lhs.modifiers.intersection(modifierMask)
            let rhsRelevantFlags = rhs.modifiers.intersection(modifierMask)
            return lhs.keyCode == rhs.keyCode && lhsRelevantFlags == rhsRelevantFlags
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(keyCode)
            // Hash only relevant modifiers
            hasher.combine(modifiers.intersection(Hotkey.modifierMask).rawValue)
        }
    }
    
    // MARK: - Properties
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hotkeys: [Hotkey: HotkeyHandler] = [:]
    private var upDownHotkeys: [Hotkey: HotkeyUpDownHandler] = [:]
    private var isMonitoring = false
    
    // MARK: - Singleton
    
    static let shared = GlobalHotkeyMonitor()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start monitoring for global hotkeys
    func startMonitoring() -> Bool {
        guard !isMonitoring else { 
            print("⚠️ GlobalHotkeyMonitor: Already monitoring")
            return true 
        }
        
        // Check for accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        print("🔍 GlobalHotkeyMonitor: Checking permissions...")
        print("   - Accessibility permission: \(trusted ? "✅ Granted" : "❌ Not granted")")
        
        if !trusted {
            print("⚠️ Accessibility permission required for global hotkeys")
            return false
        }
        
        // Create event tap for both keyDown and keyUp events
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        print("🔧 GlobalHotkeyMonitor: Creating event tap...")
        print("   - Event mask: \(String(format: "0x%X", eventMask))")
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Get the monitor instance from refcon
                let monitor = Unmanaged<GlobalHotkeyMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ Failed to create event tap")
            print("   - This can happen if:")
            print("     1. Accessibility permission was just granted (restart app)")
            print("     2. Another app is using exclusive event tap")
            print("     3. System security settings are blocking event taps")
            return false
        }
        
        self.eventTap = eventTap
        
        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        isMonitoring = true
        print("✅ Global hotkey monitoring started successfully")
        print("   - Event tap created and enabled")
        print("   - Registered hotkeys: \(hotkeys.count) regular, \(upDownHotkeys.count) up/down")
        return true
    }
    
    /// Stop monitoring for global hotkeys
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
        
        print("✅ Global hotkey monitoring stopped")
    }
    
    /// Register a hotkey
    func register(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, handler: @escaping HotkeyHandler) {
        let hotkey = Hotkey(
            keyCode: keyCode,
            modifiers: convertModifiers(modifiers)
        )
        hotkeys[hotkey] = handler
        
        let modifierStr = describeModifiers(hotkey.modifiers)
        let keyStr = describeKeyCode(keyCode)
        print("📌 Registered hotkey: \(modifierStr)\(keyStr)")
    }
    
    /// Register a hotkey with up/down handling
    func registerUpDown(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, handler: @escaping HotkeyUpDownHandler) {
        let hotkey = Hotkey(
            keyCode: keyCode,
            modifiers: convertModifiers(modifiers)
        )
        upDownHotkeys[hotkey] = handler
    }
    
    /// Unregister a hotkey
    func unregister(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        let hotkey = Hotkey(
            keyCode: keyCode,
            modifiers: convertModifiers(modifiers)
        )
        hotkeys.removeValue(forKey: hotkey)
        upDownHotkeys.removeValue(forKey: hotkey)
    }
    
    /// Clear all registered hotkeys
    func clearAll() {
        hotkeys.removeAll()
        upDownHotkeys.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Only handle key down and key up events
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        
        // Create hotkey with only relevant modifier flags
        let relevantFlags = flags.intersection(Hotkey.modifierMask)
        let hotkey = Hotkey(keyCode: keyCode, modifiers: relevantFlags)
        
        // Check for up/down handler first
        if let upDownHandler = upDownHotkeys[hotkey] {
            let isKeyDown = (type == .keyDown)
            // Execute handler on main thread
            DispatchQueue.main.async {
                upDownHandler(isKeyDown)
            }
            
            // Consume the event (prevent it from being passed to other apps)
            return nil
        }
        
        // Check for regular handler (only on keyDown)
        if type == .keyDown, let handler = hotkeys[hotkey] {
            // Execute handler on main thread
            DispatchQueue.main.async {
                handler()
            }
            
            // Consume the event (prevent it from being passed to other apps)
            return nil
        }
        
        // Pass through unhandled events
        return Unmanaged.passUnretained(event)
    }
    
    private func describeModifiers(_ flags: CGEventFlags) -> String {
        var parts: [String] = []
        if flags.contains(.maskCommand) { parts.append("⌘") }
        if flags.contains(.maskControl) { parts.append("⌃") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskShift) { parts.append("⇧") }
        return parts.joined()
    }
    
    private func describeKeyCode(_ keyCode: UInt16) -> String {
        // Map common key codes to readable names
        switch keyCode {
        case KeyCode.tab: return "Tab"
        case KeyCode.space: return "Space"
        case KeyCode.return: return "Return"
        case KeyCode.escape: return "Escape"
        case KeyCode.delete: return "Delete"
        case KeyCode.f: return "F"
        case KeyCode.c: return "C"
        case KeyCode.r: return "R"
        case KeyCode.a: return "A"
        case KeyCode.n: return "N"
        case KeyCode.p: return "P"
        case KeyCode.one: return "1"
        case KeyCode.two: return "2"
        case KeyCode.three: return "3"
        case KeyCode.four: return "4"
        case KeyCode.five: return "5"
        case KeyCode.six: return "6"
        default: return "Key\(keyCode)"
        }
    }
    
    private func convertModifiers(_ modifiers: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: CGEventFlags = []
        
        if modifiers.contains(.command) {
            flags.insert(.maskCommand)
        }
        if modifiers.contains(.control) {
            flags.insert(.maskControl)
        }
        if modifiers.contains(.option) {
            flags.insert(.maskAlternate)
        }
        if modifiers.contains(.shift) {
            flags.insert(.maskShift)
        }
        
        return flags
    }
}

// MARK: - Carbon Key Codes

extension GlobalHotkeyMonitor {
    /// Common key codes for convenience
    enum KeyCode {
        static let a: UInt16 = 0x00
        static let s: UInt16 = 0x01
        static let d: UInt16 = 0x02
        static let f: UInt16 = 0x03
        static let h: UInt16 = 0x04
        static let g: UInt16 = 0x05
        static let z: UInt16 = 0x06
        static let x: UInt16 = 0x07
        static let c: UInt16 = 0x08
        static let v: UInt16 = 0x09
        static let b: UInt16 = 0x0B
        static let q: UInt16 = 0x0C
        static let w: UInt16 = 0x0D
        static let e: UInt16 = 0x0E
        static let r: UInt16 = 0x0F
        static let y: UInt16 = 0x10
        static let t: UInt16 = 0x11
        static let one: UInt16 = 0x12
        static let two: UInt16 = 0x13
        static let three: UInt16 = 0x14
        static let four: UInt16 = 0x15
        static let six: UInt16 = 0x16
        static let five: UInt16 = 0x17
        static let equal: UInt16 = 0x18
        static let nine: UInt16 = 0x19
        static let seven: UInt16 = 0x1A
        static let minus: UInt16 = 0x1B
        static let eight: UInt16 = 0x1C
        static let zero: UInt16 = 0x1D
        static let rightBracket: UInt16 = 0x1E
        static let o: UInt16 = 0x1F
        static let u: UInt16 = 0x20
        static let leftBracket: UInt16 = 0x21
        static let i: UInt16 = 0x22
        static let p: UInt16 = 0x23
        static let l: UInt16 = 0x25
        static let j: UInt16 = 0x26
        static let quote: UInt16 = 0x27
        static let k: UInt16 = 0x28
        static let semicolon: UInt16 = 0x29
        static let backslash: UInt16 = 0x2A
        static let comma: UInt16 = 0x2B
        static let slash: UInt16 = 0x2C
        static let n: UInt16 = 0x2D
        static let m: UInt16 = 0x2E
        static let period: UInt16 = 0x2F
        static let grave: UInt16 = 0x32
        static let keypadDecimal: UInt16 = 0x41
        static let keypadMultiply: UInt16 = 0x43
        static let keypadPlus: UInt16 = 0x45
        static let keypadClear: UInt16 = 0x47
        static let keypadDivide: UInt16 = 0x4B
        static let keypadEnter: UInt16 = 0x4C
        static let keypadMinus: UInt16 = 0x4E
        static let keypadEquals: UInt16 = 0x51
        static let keypad0: UInt16 = 0x52
        static let keypad1: UInt16 = 0x53
        static let keypad2: UInt16 = 0x54
        static let keypad3: UInt16 = 0x55
        static let keypad4: UInt16 = 0x56
        static let keypad5: UInt16 = 0x57
        static let keypad6: UInt16 = 0x58
        static let keypad7: UInt16 = 0x59
        static let keypad8: UInt16 = 0x5B
        static let keypad9: UInt16 = 0x5C
        static let `return`: UInt16 = 0x24
        static let tab: UInt16 = 0x30
        static let space: UInt16 = 0x31
        static let delete: UInt16 = 0x33
        static let escape: UInt16 = 0x35
        static let command: UInt16 = 0x37
        static let shift: UInt16 = 0x38
        static let capsLock: UInt16 = 0x39
        static let option: UInt16 = 0x3A
        static let control: UInt16 = 0x3B
        static let rightCommand: UInt16 = 0x36
        static let rightShift: UInt16 = 0x3C
        static let rightOption: UInt16 = 0x3D
        static let rightControl: UInt16 = 0x3E
        static let function: UInt16 = 0x3F
        static let f17: UInt16 = 0x40
        static let volumeUp: UInt16 = 0x48
        static let volumeDown: UInt16 = 0x49
        static let mute: UInt16 = 0x4A
        static let f18: UInt16 = 0x4F
        static let f19: UInt16 = 0x50
        static let f20: UInt16 = 0x5A
        static let f5: UInt16 = 0x60
        static let f6: UInt16 = 0x61
        static let f7: UInt16 = 0x62
        static let f3: UInt16 = 0x63
        static let f8: UInt16 = 0x64
        static let f9: UInt16 = 0x65
        static let f11: UInt16 = 0x67
        static let f13: UInt16 = 0x69
        static let f16: UInt16 = 0x6A
        static let f14: UInt16 = 0x6B
        static let f10: UInt16 = 0x6D
        static let f12: UInt16 = 0x6F
        static let f15: UInt16 = 0x71
        static let help: UInt16 = 0x72
        static let home: UInt16 = 0x73
        static let pageUp: UInt16 = 0x74
        static let forwardDelete: UInt16 = 0x75
        static let f4: UInt16 = 0x76
        static let end: UInt16 = 0x77
        static let f2: UInt16 = 0x78
        static let pageDown: UInt16 = 0x79
        static let f1: UInt16 = 0x7A
        static let leftArrow: UInt16 = 0x7B
        static let rightArrow: UInt16 = 0x7C
        static let downArrow: UInt16 = 0x7D
        static let upArrow: UInt16 = 0x7E
    }
}