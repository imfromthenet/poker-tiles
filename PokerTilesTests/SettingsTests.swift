//
//  SettingsTests.swift
//  PokerTilesTests
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import XCTest
@testable import PokerTiles

final class SettingsTests: XCTestCase {
    
    var windowManager: WindowManager!
    
    override func setUp() {
        super.setUp()
        windowManager = WindowManager()
    }
    
    override func tearDown() {
        windowManager = nil
        super.tearDown()
    }
    
    func testAppSettingsInitialization() {
        // Set some custom values
        windowManager.setAutoScanEnabled(false)
        windowManager.setAutoScanInterval(2.5)
        
        // Create settings
        let settings = AppSettings(from: windowManager)
        
        // Verify settings captured the values
        XCTAssertEqual(settings.version, 1)
        XCTAssertFalse(settings.isAutoScanEnabled)
        XCTAssertEqual(settings.autoScanInterval, 2.5)
        XCTAssertNotNil(settings.exportDate)
    }
    
    func testAppSettingsApply() {
        // Create settings with specific values
        let originalSettings = AppSettings(
            exportDate: Date(),
            isAutoScanEnabled: false,
            autoScanInterval: 4.5
        )
        
        // Apply to window manager
        originalSettings.apply(to: windowManager)
        
        // Verify values were applied
        XCTAssertFalse(windowManager.isAutoScanEnabled)
        XCTAssertEqual(windowManager.autoScanInterval, 4.5)
    }
    
    func testSettingsExportImport() throws {
        // Set specific values
        windowManager.setAutoScanEnabled(false)
        windowManager.setAutoScanInterval(3.33)
        
        // Export to JSON
        let exportedData = try SettingsManager.exportSettings(from: windowManager)
        
        // Create a new window manager with different values
        let newWindowManager = WindowManager()
        newWindowManager.setAutoScanEnabled(true)
        newWindowManager.setAutoScanInterval(1.0)
        
        // Import the settings
        try SettingsManager.importSettings(exportedData, to: newWindowManager)
        
        // Verify imported values match original
        XCTAssertFalse(newWindowManager.isAutoScanEnabled)
        XCTAssertEqual(newWindowManager.autoScanInterval, 3.33)
    }
    
    func testSettingsJSONFormat() throws {
        // Set known values
        windowManager.setAutoScanEnabled(true)
        windowManager.setAutoScanInterval(2.0)
        
        // Export to JSON
        let jsonData = try SettingsManager.exportSettings(from: windowManager)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Verify JSON contains expected fields
        XCTAssertTrue(jsonString.contains("\"version\""))
        XCTAssertTrue(jsonString.contains("\"exportDate\""))
        XCTAssertTrue(jsonString.contains("\"isAutoScanEnabled\""))
        XCTAssertTrue(jsonString.contains("\"autoScanInterval\""))
        XCTAssertTrue(jsonString.contains("true")) // isAutoScanEnabled
        XCTAssertTrue(jsonString.contains("2")) // autoScanInterval
    }
    
    func testSettingsFileOperations() throws {
        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test-settings.json")
        
        defer {
            // Clean up
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // Set values and save to file
        windowManager.setAutoScanEnabled(false)
        windowManager.setAutoScanInterval(1.23)
        try SettingsManager.saveSettingsToFile(from: windowManager, to: fileURL)
        
        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        
        // Load from file to new window manager
        let newWindowManager = WindowManager()
        try SettingsManager.loadSettingsFromFile(from: fileURL, to: newWindowManager)
        
        // Verify loaded values
        XCTAssertFalse(newWindowManager.isAutoScanEnabled)
        XCTAssertEqual(newWindowManager.autoScanInterval, 1.23)
    }
}