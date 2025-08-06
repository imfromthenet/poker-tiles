//
//  ColorSchemeManager.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/30.
//

import SwiftUI
import Combine

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var displayName: String {
        self.rawValue
    }
}

class ColorSchemeManager: ObservableObject {
    @Published var appearanceMode: AppearanceMode = .system {
        didSet {
            saveAppearance()
            // Force a view update
            objectWillChange.send()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let appearanceModeKey = "appearanceMode"
    private var effectiveAppearanceObserver: NSKeyValueObservation?
    
    init() {
        loadSavedAppearance()
        
        // Monitor system appearance changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemAppearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
        
        // Observe NSApp.effectiveAppearance changes to ensure proper synchronization
        effectiveAppearanceObserver = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            // Force SwiftUI to re-evaluate views when effective appearance changes
            self?.objectWillChange.send()
        }
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
        effectiveAppearanceObserver?.invalidate()
    }
    
    func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
    }
    
    private func loadSavedAppearance() {
        if let savedMode = userDefaults.string(forKey: appearanceModeKey),
           let mode = AppearanceMode(rawValue: savedMode) {
            appearanceMode = mode
        }
    }
    
    private func saveAppearance() {
        userDefaults.set(appearanceMode.rawValue, forKey: appearanceModeKey)
    }
    
    @objc private func systemAppearanceChanged() {
        if appearanceMode == .system {
            // Force a view update when system appearance changes
            objectWillChange.send()
        }
    }
}

// MARK: - Codable Support for Settings Export/Import
extension ColorSchemeManager {
    struct Settings: Codable {
        let appearanceMode: AppearanceMode
    }
    
    var exportableSettings: Settings {
        Settings(appearanceMode: appearanceMode)
    }
    
    func importSettings(_ settings: Settings) {
        setAppearanceMode(settings.appearanceMode)
    }
}