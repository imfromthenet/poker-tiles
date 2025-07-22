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
            
            if let (key, modifiers) = hotkeyManager.getHotkey(for: action) {
                HotkeyDisplay(key: key, modifiers: modifiers)
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
    let key: Key
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
        switch key {
        case .a: return "A"
        case .c: return "C"
        case .f: return "F"
        case .r: return "R"
        case .s: return "S"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .space: return "Space"
        case .tab: return "Tab"
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
    
    @State private var recordedKey: Key?
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
            if let key = recordedKey {
                HotkeyDisplay(key: key, modifiers: recordedModifiers)
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
                    if let key = recordedKey {
                        hotkeyManager.registerHotkey(action, key: key, modifiers: recordedModifiers)
                    }
                    dismiss()
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .disabled(recordedKey == nil)
            }
        }
        .padding(40)
        .frame(width: 400, height: 250)
        .background(KeyRecorderRepresentable(
            onKeyPress: { key, modifiers in
                recordedKey = key
                recordedModifiers = modifiers
            }
        ))
    }
}

// MARK: - Key Recorder NSView

struct KeyRecorderRepresentable: NSViewRepresentable {
    let onKeyPress: (Key, NSEvent.ModifierFlags) -> Void
    
    func makeNSView(context: Context) -> KeyRecorderView {
        let view = KeyRecorderView()
        view.onKeyPress = onKeyPress
        return view
    }
    
    func updateNSView(_ nsView: KeyRecorderView, context: Context) {}
}

class KeyRecorderView: NSView {
    var onKeyPress: ((Key, NSEvent.ModifierFlags) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
    
    override func keyDown(with event: NSEvent) {
        guard let key = convertToKey(event.keyCode) else {
            super.keyDown(with: event)
            return
        }
        
        onKeyPress?(key, event.modifierFlags.intersection([.command, .shift, .control, .option]))
    }
    
    private func convertToKey(_ keyCode: UInt16) -> Key? {
        // Map common key codes to our Key enum
        switch keyCode {
        case 0: return .a
        case 8: return .c
        case 3: return .f
        case 15: return .r
        case 1: return .s
        case 18: return .one
        case 19: return .two
        case 20: return .three
        case 49: return .space
        case 48: return .tab
        default: return nil
        }
    }
}

// MARK: - Preview

struct HotkeySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        HotkeySettingsView(hotkeyManager: HotkeyManager())
    }
}