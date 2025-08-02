//
//  AppSettings.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import Foundation

struct AppSettings: Codable {
    var version: Int = 1 // For future compatibility
    let exportDate: Date
    
    // Auto-scan settings
    let isAutoScanEnabled: Bool
    let autoScanInterval: TimeInterval
    
    // Appearance settings
    let appearanceMode: AppearanceMode?
    
    // Grid layout settings
    let gridPadding: CGFloat?
    let gridWindowSpacing: CGFloat?
    
    // Valid ranges
    static let minAutoScanInterval: TimeInterval = SettingsConstants.AutoScan.minInterval
    static let maxAutoScanInterval: TimeInterval = SettingsConstants.AutoScan.maxInterval
    static let minGridSpacing: CGFloat = SettingsConstants.GridLayout.minSpacing
    static let maxGridSpacing: CGFloat = SettingsConstants.GridLayout.maxSpacing
    
    // Future settings can be added here
    // let hotkeys: [String: String]?
    
    init(from windowManager: WindowManager, colorSchemeManager: ColorSchemeManager) {
        self.exportDate = Date()
        self.isAutoScanEnabled = windowManager.isAutoScanEnabled
        self.autoScanInterval = windowManager.autoScanInterval
        self.appearanceMode = colorSchemeManager.appearanceMode
        self.gridPadding = windowManager.gridLayoutOptions.padding
        self.gridWindowSpacing = windowManager.gridLayoutOptions.windowSpacing
    }
    
    // For testing
    init(exportDate: Date, isAutoScanEnabled: Bool, autoScanInterval: TimeInterval, appearanceMode: AppearanceMode? = nil, gridPadding: CGFloat? = nil, gridWindowSpacing: CGFloat? = nil) {
        self.exportDate = exportDate
        self.isAutoScanEnabled = isAutoScanEnabled
        self.autoScanInterval = autoScanInterval
        self.appearanceMode = appearanceMode
        self.gridPadding = gridPadding
        self.gridWindowSpacing = gridWindowSpacing
    }
    
    func apply(to windowManager: WindowManager, colorSchemeManager: ColorSchemeManager) {
        windowManager.setAutoScanEnabled(isAutoScanEnabled)
        // setAutoScanInterval will clamp the value automatically
        windowManager.setAutoScanInterval(autoScanInterval)
        
        if let appearanceMode = appearanceMode {
            colorSchemeManager.setAppearanceMode(appearanceMode)
        }
        
        if let padding = gridPadding {
            windowManager.setGridPadding(padding)
        }
        
        if let spacing = gridWindowSpacing {
            windowManager.setGridWindowSpacing(spacing)
        }
    }
    
    func validate() throws {
        if autoScanInterval < AppSettings.minAutoScanInterval || 
           autoScanInterval > AppSettings.maxAutoScanInterval {
            throw SettingsError.invalidAutoScanInterval(
                value: autoScanInterval,
                min: AppSettings.minAutoScanInterval,
                max: AppSettings.maxAutoScanInterval
            )
        }
        
        if let padding = gridPadding, 
           (padding < AppSettings.minGridSpacing || padding > AppSettings.maxGridSpacing) {
            throw SettingsError.invalidGridSpacing(
                type: "padding",
                value: padding,
                min: AppSettings.minGridSpacing,
                max: AppSettings.maxGridSpacing
            )
        }
        
        if let spacing = gridWindowSpacing,
           (spacing < AppSettings.minGridSpacing || spacing > AppSettings.maxGridSpacing) {
            throw SettingsError.invalidGridSpacing(
                type: "window spacing",
                value: spacing,
                min: AppSettings.minGridSpacing,
                max: AppSettings.maxGridSpacing
            )
        }
    }
}

// MARK: - Settings Error
enum SettingsError: LocalizedError {
    case invalidAutoScanInterval(value: TimeInterval, min: TimeInterval, max: TimeInterval)
    case invalidGridSpacing(type: String, value: CGFloat, min: CGFloat, max: CGFloat)
    
    var errorDescription: String? {
        switch self {
        case .invalidAutoScanInterval(let value, let min, let max):
            return "Invalid auto-scan interval: \(String(format: "%.2f", value))s. Must be between \(String(format: "%.2f", min))s and \(String(format: "%.2f", max))s."
        case .invalidGridSpacing(let type, let value, let min, let max):
            return "Invalid grid \(type): \(String(format: "%.0f", value))px. Must be between \(String(format: "%.0f", min))px and \(String(format: "%.0f", max))px."
        }
    }
}

// MARK: - Settings Manager
class SettingsManager {
    static func exportSettings(from windowManager: WindowManager, colorSchemeManager: ColorSchemeManager) throws -> Data {
        let settings = AppSettings(from: windowManager, colorSchemeManager: colorSchemeManager)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(settings)
    }
    
    static func importSettings(_ data: Data, to windowManager: WindowManager, colorSchemeManager: ColorSchemeManager) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let settings = try decoder.decode(AppSettings.self, from: data)
        
        // Apply settings - WindowManager will automatically clamp values
        settings.apply(to: windowManager, colorSchemeManager: colorSchemeManager)
    }
    
    static func saveSettingsToFile(from windowManager: WindowManager, colorSchemeManager: ColorSchemeManager, to url: URL) throws {
        let data = try exportSettings(from: windowManager, colorSchemeManager: colorSchemeManager)
        try data.write(to: url)
    }
    
    static func loadSettingsFromFile(from url: URL, to windowManager: WindowManager, colorSchemeManager: ColorSchemeManager) throws {
        let data = try Data(contentsOf: url)
        try importSettings(data, to: windowManager, colorSchemeManager: colorSchemeManager)
    }
}
