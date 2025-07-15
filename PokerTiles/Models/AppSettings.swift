//
//  AppSettings.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import Foundation

struct AppSettings: Codable {
    let version: Int = 1 // For future compatibility
    let exportDate: Date
    
    // Auto-scan settings
    let isAutoScanEnabled: Bool
    let autoScanInterval: TimeInterval
    
    // Valid ranges
    static let minAutoScanInterval: TimeInterval = 0.01
    static let maxAutoScanInterval: TimeInterval = 5.0
    
    // Future settings can be added here
    // let theme: String?
    // let hotkeys: [String: String]?
    
    init(from windowManager: WindowManager) {
        self.exportDate = Date()
        self.isAutoScanEnabled = windowManager.isAutoScanEnabled
        self.autoScanInterval = windowManager.autoScanInterval
    }
    
    // For testing
    init(exportDate: Date, isAutoScanEnabled: Bool, autoScanInterval: TimeInterval) {
        self.exportDate = exportDate
        self.isAutoScanEnabled = isAutoScanEnabled
        self.autoScanInterval = autoScanInterval
    }
    
    func apply(to windowManager: WindowManager) {
        windowManager.setAutoScanEnabled(isAutoScanEnabled)
        // setAutoScanInterval will clamp the value automatically
        windowManager.setAutoScanInterval(autoScanInterval)
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
    }
}

// MARK: - Settings Error
enum SettingsError: LocalizedError {
    case invalidAutoScanInterval(value: TimeInterval, min: TimeInterval, max: TimeInterval)
    
    var errorDescription: String? {
        switch self {
        case .invalidAutoScanInterval(let value, let min, let max):
            return "Invalid auto-scan interval: \(String(format: "%.2f", value))s. Must be between \(String(format: "%.2f", min))s and \(String(format: "%.2f", max))s."
        }
    }
}

// MARK: - Settings Manager
class SettingsManager {
    static func exportSettings(from windowManager: WindowManager) throws -> Data {
        let settings = AppSettings(from: windowManager)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(settings)
    }
    
    static func importSettings(_ data: Data, to windowManager: WindowManager) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let settings = try decoder.decode(AppSettings.self, from: data)
        
        // Apply settings - WindowManager will automatically clamp values
        settings.apply(to: windowManager)
    }
    
    static func saveSettingsToFile(from windowManager: WindowManager, to url: URL) throws {
        let data = try exportSettings(from: windowManager)
        try data.write(to: url)
    }
    
    static func loadSettingsFromFile(from url: URL, to windowManager: WindowManager) throws {
        let data = try Data(contentsOf: url)
        try importSettings(data, to: windowManager)
    }
}
