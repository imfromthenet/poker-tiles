//
//  HotkeySettingsView.swift
//  PokerTiles
//
//  UI for configuring global hotkeys
//

import SwiftUI
import AppKit

struct HotkeySettingsView: View {
    @ObservedObject var hotkeyManager: HotkeyManager
    @State private var editingAction: HotkeyManager.HotkeyAction?
    @State private var isRecording = false
    @State private var showAccessibilityAlert = false
    
    var body: some View {
        VStack(spacing: UIConstants.Spacing.huge) {
            // Invalid bindings notification
            if hotkeyManager.hasInvalidBindings() {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    
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
                .background(Color.yellow.opacity(UIConstants.Opacity.veryLight))
                .cornerRadius(UIConstants.CornerRadius.standard)
            }
            
            // Header
            VStack(alignment: .leading, spacing: UIConstants.Spacing.standard) {
                Text("Hotkey Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Configure global keyboard shortcuts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Enable/Disable Toggle
            HStack {
                Text("Global Hotkeys")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { hotkeyManager.isEnabled },
                    set: { newValue in
                        if newValue != hotkeyManager.isEnabled {
                            if newValue && !PermissionManager.hasAccessibilityPermission() {
                                showAccessibilityAlert = true
                            } else {
                                hotkeyManager.setEnabled(newValue)
                            }
                        }
                    }
                ))
                .toggleStyle(.switch)
            }
            
            // Status indicator
            if !hotkeyManager.isEnabled {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Hotkeys are disabled. Enable the toggle above to use them.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, UIConstants.Spacing.standard)
            }
            
            // Hotkey List
            ScrollView {
                VStack(spacing: UIConstants.Spacing.extraLarge) {
                    ForEach(groupedActions(), id: \.0) { category, actions in
                        VStack(alignment: .leading, spacing: UIConstants.Spacing.standard) {
                            Text(category)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: UIConstants.Spacing.tiny) {
                                ForEach(actions, id: \.self) { action in
                                    HotkeyRow(
                                        action: action,
                                        hotkeyManager: hotkeyManager,
                                        isEditing: editingAction == action,
                                        onEdit: {
                                            if hotkeyManager.isEnabled {
                                                editingAction = action
                                                isRecording = true
                                            }
                                        },
                                        onClear: {
                                            if hotkeyManager.isEnabled {
                                                hotkeyManager.unregisterHotkey(action)
                                            }
                                        }
                                    )
                                    .disabled(!hotkeyManager.isEnabled)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: UIConstants.FrameDimensions.sheetWidthSmall - UIConstants.FrameDimensions.thumbnailLarge)
            .opacity(hotkeyManager.isEnabled ? UIConstants.Opacity.opaque : UIConstants.Opacity.medium)
            
            Divider()
            
            // Reset Button
            Button("Reset to Defaults") {
                hotkeyManager.resetToDefaults()
            }
            .buttonStyle(.bordered)
            .disabled(!hotkeyManager.isEnabled)
        }
        .padding()
        .frame(width: UIConstants.FrameDimensions.sheetWidthSmall)
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
        .alert("Accessibility Permission Required", isPresented: $showAccessibilityAlert) {
            Button("Open System Settings") {
                PermissionManager.requestAccessibilityPermission()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("PokerTiles needs accessibility permission to use global hotkeys.\n\nPlease grant permission in System Settings, then return here to enable hotkeys.")
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
                        .foregroundStyle(.secondary)
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
        .padding(.horizontal, UIConstants.Spacing.large)
        .padding(.vertical, UIConstants.Spacing.standard)
        .background(isEditing ? Color.accentColor.opacity(UIConstants.Opacity.veryLight) : Color(.tertiarySystemFill))
        .cornerRadius(UIConstants.CornerRadius.small)
    }
}

// MARK: - Hotkey Display

struct HotkeyDisplay: View {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags
    
    var body: some View {
        HStack(spacing: UIConstants.Spacing.tiny) {
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
        case GlobalHotkeyMonitor.KeyCode.g: return "G"
        case GlobalHotkeyMonitor.KeyCode.r: return "R"
        case GlobalHotkeyMonitor.KeyCode.s: return "S"
        case GlobalHotkeyMonitor.KeyCode.one: return "1"
        case GlobalHotkeyMonitor.KeyCode.two: return "2"
        case GlobalHotkeyMonitor.KeyCode.three: return "3"
        case GlobalHotkeyMonitor.KeyCode.four: return "4"
        case GlobalHotkeyMonitor.KeyCode.five: return "5"
        case GlobalHotkeyMonitor.KeyCode.six: return "6"
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
            .font(.system(size: UIConstants.Spacing.large, weight: .medium, design: .monospaced))
            .foregroundStyle(.primary)
            .frame(minWidth: UIConstants.FrameDimensions.iconSmall, minHeight: UIConstants.FrameDimensions.iconSmall)
            .background(Color(.tertiarySystemFill))
            .cornerRadius(UIConstants.CornerRadius.tiny)
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.tiny)
                    .stroke(Color(.separatorColor), lineWidth: UIConstants.LineWidth.thin)
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
        VStack(spacing: UIConstants.Spacing.huge) {
            Text("Press New Hotkey")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Recording hotkey for: \(action.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Show current combination
            if let keyCode = recordedKeyCode {
                HotkeyDisplay(keyCode: keyCode, modifiers: recordedModifiers)
                    .scaleEffect(UIConstants.Scale.enlarged)
                    .padding()
            } else {
                Text("Press any key combination...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding()
            }
            
            HStack(spacing: UIConstants.Spacing.medium) {
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
        .padding(UIConstants.Spacing.gigantic)
        .frame(width: UIConstants.FrameDimensions.formWidth, height: UIConstants.FrameDimensions.thumbnailLarge + UIConstants.FrameDimensions.thumbnailSmall)
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