//
//  LayoutsTabView.swift
//  PokerTiles
//
//  Tab view for window arrangements and grid layouts
//

import SwiftUI

struct LayoutsTabView: View {
    @Binding var permissionTriggerId: UUID?
    let windowManager: WindowManager
    
    var body: some View {
        Form {
            // Window Layout
            Section("Window Layout") {
                GridLayoutView(windowManager: windowManager)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    LayoutsTabView(
        permissionTriggerId: .constant(nil),
        windowManager: WindowManager()
    )
}