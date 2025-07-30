//
//  HotkeySettingsView.swift
//  PokerTiles
//
//  UI for configuring global hotkeys
//

import SwiftUI
import AppKit

struct HotkeySettingsView: View {
    let hotkeyManager: HotkeyManager
    @State private var editingAction: HotkeyManager.HotkeyAction?
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Invalid bindings notification
            if hotkeyManager.hasInvalidBindings() {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    
                    Text("\(hotkeyManager.invalidBindings.count) hotkey settings couldn't be loaded and were reset to defaults")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Button("Dismiss") {
                        hotkeyManager.clearInvalidBindings()
                    }
                    .buttonStyle(.link)
                    .controlSize(.small)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Hotkey Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Configure global keyboard shortcuts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Enable/Disable Toggle
            HStack {
                Text("Global Hotkeys")
                Spacer()
                Button(hotkeyManager.isEnabled ? "Enabled" : "Disabled") {
                    hotkeyManager.setEnabled(!hotkeyManager.isEnabled)
                }
                .buttonStyle(.bordered)
                .foregroundColor(hotkeyManager.isEnabled ? .green : .secondary)
            }
            
            if hotkeyManager.isEnabled {
                // Hotkey List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(groupedActions(), id: \.0) { category, actions in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                VStack(spacing: 4) {
                                    ForEach(actions, id: \.self) { action in
                                        HotkeyRow(
                                            action: action,
                                            hotkeyManager: hotkeyManager,
                                            isEditing: editingAction == action,
                                            onEdit: {
                                                editingAction = action
                                                isRecording = true
                                            },
                                            onClear: {
                                                hotkeyManager.unregisterHotkey(action)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                
                Divider()
                
                // Reset Button
                Button("Reset to Defaults") {
                    hotkeyManager.resetToDefaults()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 500)
        .sheet(isPresented: $isRecording) {
            if let action = editingAction {
                HotkeyRecorderView(
                    action: action,
                    hotkeyManager: hotkeyManager,
                    onComplete: {
                        isRecording = false
                        editingAction = nil
                    }
                )
            }
        }
    }
    
    private func groupedActions() -> [(String, [HotkeyManager.HotkeyAction])] {
        let grouped = Dictionary(grouping: HotkeyManager.HotkeyAction.allCases) { $0.category }
        return grouped.sorted { $0.key < $1.key }
    }
}

// MARK: - Hotkey Row

struct HotkeyRow: View {
    let action: HotkeyManager.HotkeyAction
    let hotkeyManager: HotkeyManager
    let isEditing: Bool
    let onEdit: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            Text(action.rawValue)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            if let (keyCode, modifiers) = hotkeyManager.getHotkey(for: action) {
                HotkeyDisplay(keyCode: keyCode, modifiers: modifiers)
                    .onTapGesture {
                        onEdit()
                    }
                
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button("Set") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isEditing ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

// MARK: - Hotkey Display

struct HotkeyDisplay: View {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags
    
    var body: some View {
        HStack(spacing: 4) {
            if modifiers.contains(.control) {
                KeyCapView(symbol: "⌃")
            }
            if modifiers.contains(.option) {
                KeyCapView(symbol: "⌥")
            }
            if modifiers.contains(.shift) {
                KeyCapView(symbol: "⇧")
            }
            if modifiers.contains(.command) {
                KeyCapView(symbol: "⌘")
            }
            
            KeyCapView(symbol: keySymbol)
        }
    }
    
    private var keySymbol: String {
        // Map key codes to symbols
        switch keyCode {
        case GlobalHotkeyMonitor.KeyCode.a: return "A"
        case GlobalHotkeyMonitor.KeyCode.c: return "C"
        case GlobalHotkeyMonitor.KeyCode.f: return "F"
        case GlobalHotkeyMonitor.KeyCode.r: return "R"
        case GlobalHotkeyMonitor.KeyCode.s: return "S"
        case GlobalHotkeyMonitor.KeyCode.one: return "1"
        case GlobalHotkeyMonitor.KeyCode.two: return "2"
        case GlobalHotkeyMonitor.KeyCode.three: return "3"
        case GlobalHotkeyMonitor.KeyCode.space: return "Space"
        case GlobalHotkeyMonitor.KeyCode.tab: return "Tab"
        default:
            // Try to get a string representation for other keys
            if let source = CGEventSource(stateID: .hidSystemState) {
                let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true)
                if let event = event {
                    let nsEvent = NSEvent(cgEvent: event)
                    return nsEvent?.charactersIgnoringModifiers?.uppercased() ?? "?"
                }
            }
            return "Key \(keyCode)"
        }
    }
}

// MARK: - Key Cap View

struct KeyCapView: View {
    let symbol: String
    
    var body: some View {
        Text(symbol)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.primary)
            .frame(minWidth: 24, minHeight: 24)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Hotkey Recorder View

struct HotkeyRecorderView: View {
    let action: HotkeyManager.HotkeyAction
    let hotkeyManager: HotkeyManager
    let onComplete: () -> Void
    
    @State private var recordedKeyCode: UInt16?
    @State private var recordedModifiers: NSEvent.ModifierFlags = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Press New Hotkey")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Recording hotkey for: \(action.rawValue)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Show current combination
            if let keyCode = recordedKeyCode {
                HotkeyDisplay(keyCode: keyCode, modifiers: recordedModifiers)
                    .scaleEffect(1.5)
                    .padding()
            } else {
                Text("Press any key combination...")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            HStack(spacing: 10) {
                Button("Cancel") {
                    dismiss()
                    onComplete()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    if let keyCode = recordedKeyCode {
                        hotkeyManager.registerHotkey(action, keyCode: keyCode, modifiers: recordedModifiers)
                    }
                    dismiss()
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .disabled(recordedKeyCode == nil)
            }
        }
        .padding(40)
        .frame(width: 400, height: 250)
        .background(KeyRecorderRepresentable(
            onKeyPress: { keyCode, modifiers in
                recordedKeyCode = keyCode
                recordedModifiers = modifiers
            }
        ))
    }
}

// MARK: - Key Recorder NSView

struct KeyRecorderRepresentable: NSViewRepresentable {
    let onKeyPress: (UInt16, NSEvent.ModifierFlags) -> Void
    
    func makeNSView(context: Context) -> KeyRecorderView {
        let view = KeyRecorderView()
        view.onKeyPress = onKeyPress
        return view
    }
    
    func updateNSView(_ nsView: KeyRecorderView, context: Context) {}
}

class KeyRecorderView: NSView {
    var onKeyPress: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
    
    override func keyDown(with event: NSEvent) {
        // Pass the raw key code and modifiers
        onKeyPress?(event.keyCode, event.modifierFlags.intersection([.command, .shift, .control, .option]))
    }
}

// MARK: - Preview

struct HotkeySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        HotkeySettingsView(hotkeyManager: HotkeyManager())
    }
}