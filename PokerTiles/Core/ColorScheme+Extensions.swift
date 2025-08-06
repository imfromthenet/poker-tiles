//
//  ColorScheme+Extensions.swift
//  PokerTiles
//
//  Extensions for ColorScheme handling
//

import SwiftUI
import AppKit

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
    
    var nsAppearance: NSAppearance? {
        switch appearanceMode {
        case .system:
            return nil // Use system default
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}

// ViewModifier to sync NSApp appearance with ColorSchemeManager
struct AppAppearanceModifier: ViewModifier {
    @ObservedObject var colorSchemeManager: ColorSchemeManager
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                updateAppAppearance()
            }
            .onChange(of: colorSchemeManager.appearanceMode) {
                updateAppAppearance()
            }
    }
    
    private func updateAppAppearance() {
        NSApp.appearance = colorSchemeManager.nsAppearance
    }
}

extension View {
    func syncAppAppearance(_ colorSchemeManager: ColorSchemeManager) -> some View {
        self.modifier(AppAppearanceModifier(colorSchemeManager: colorSchemeManager))
    }
}

