//
//  PokerTilesApp.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/3.
//

import SwiftUI

@main
struct PokerTilesApp: App {
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(colorSchemeManager)
        }
    }
}

struct AppRootView: View {
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        ContentView()
            .applyColorScheme(colorSchemeManager)
            .syncAppAppearance(colorSchemeManager)
    }
}
