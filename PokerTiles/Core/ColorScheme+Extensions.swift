//
//  ColorScheme+Extensions.swift
//  PokerTiles
//
//  Extensions for ColorScheme handling
//

import SwiftUI

extension View {
    func applyColorScheme(_ colorSchemeManager: ColorSchemeManager) -> some View {
        self.environment(\.colorScheme, colorSchemeManager.effectiveColorScheme)
    }
}

extension ColorSchemeManager {
    var effectiveColorScheme: ColorScheme {
        switch appearanceMode {
        case .system:
            // Get the system appearance
            let systemAppearance = NSApp.effectiveAppearance.name
            return systemAppearance == .darkAqua ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}