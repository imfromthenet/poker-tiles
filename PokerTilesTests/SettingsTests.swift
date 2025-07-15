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
    
    func testAutoScanIntervalClamping() {
        // Test values below minimum
        windowManager.setAutoScanInterval(0.001)
        XCTAssertEqual(windowManager.autoScanInterval, 0.01)
        
        // Test values above maximum
        windowManager.setAutoScanInterval(10.0)
        XCTAssertEqual(windowManager.autoScanInterval, 5.0)
        
        // Test valid values
        windowManager.setAutoScanInterval(2.5)
        XCTAssertEqual(windowManager.autoScanInterval, 2.5)
    }
    
    func testImportWithInvalidValues() throws {
        // Create settings with out-of-range values
        let settings = AppSettings(
            exportDate: Date(),
            isAutoScanEnabled: true,
            autoScanInterval: 10.0  // Above max
        )
        
        // Apply to window manager
        settings.apply(to: windowManager)
        
        // Verify value was clamped
        XCTAssertEqual(windowManager.autoScanInterval, 5.0)
    }
    
    func testImportJSONWithInvalidValues() throws {
        // Create JSON with invalid values
        let json = """
        {
            "version": 1,
            "exportDate": "2024-01-01T00:00:00Z",
            "isAutoScanEnabled": true,
            "autoScanInterval": 0.001
        }
        """
        
        let data = json.data(using: .utf8)!
        
        // Import should succeed and clamp values
        try SettingsManager.importSettings(data, to: windowManager)
        
        // Verify value was clamped to minimum
        XCTAssertEqual(windowManager.autoScanInterval, 0.01)
    }
    
    func testSettingsValidation() throws {
        // Test valid settings
        let validSettings = AppSettings(
            exportDate: Date(),
            isAutoScanEnabled: true,
            autoScanInterval: 2.0
        )
        XCTAssertNoThrow(try validSettings.validate())
        
        // Test invalid settings - below minimum
        let belowMinSettings = AppSettings(
            exportDate: Date(),
            isAutoScanEnabled: true,
            autoScanInterval: 0.001
        )
        XCTAssertThrowsError(try belowMinSettings.validate()) { error in
            XCTAssertTrue(error is SettingsError)
        }
        
        // Test invalid settings - above maximum
        let aboveMaxSettings = AppSettings(
            exportDate: Date(),
            isAutoScanEnabled: true,
            autoScanInterval: 10.0
        )
        XCTAssertThrowsError(try aboveMaxSettings.validate()) { error in
            XCTAssertTrue(error is SettingsError)
        }
    }
}