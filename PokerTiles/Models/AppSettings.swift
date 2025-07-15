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
        windowManager.setAutoScanInterval(autoScanInterval)
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