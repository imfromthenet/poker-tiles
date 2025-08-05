//
//  HotkeysTabView.swift
//  PokerTiles
//
//  Tab view for hotkey configuration and testing
//

import SwiftUI

struct HotkeysTabView: View {
    @Binding var permissionTriggerId: UUID?
    let windowManager: WindowManager
    
    var body: some View {
        Form {
            // Hotkey Configuration
            Section("Hotkeys") {
                HotkeySettingsView(hotkeyManager: windowManager.hotkeyManager)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    HotkeysTabView(
        permissionTriggerId: .constant(nil),
        windowManager: WindowManager()
    )
}