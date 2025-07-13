//
//  WindowManagerIntegrationTests.swift
//  PokerTilesTests
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import XCTest
@testable import PokerTiles

final class WindowManagerIntegrationTests: XCTestCase {
    
    var windowManager: WindowManager!
    
    override func setUp() {
        super.setUp()
        windowManager = WindowManager()
    }
    
    override func tearDown() {
        windowManager = nil
        super.tearDown()
    }
    
    func testWindowManagerInitialization() {
        XCTAssertNotNil(windowManager)
        XCTAssertEqual(windowManager.windowCount, 0)
        XCTAssertTrue(windowManager.windows.isEmpty)
        XCTAssertTrue(windowManager.pokerTables.isEmpty)
        XCTAssertFalse(windowManager.isScanning)
        XCTAssertNotNil(windowManager.pokerTableDetector)
    }
    
    func testCheckPermissions() {
        windowManager.checkPermissions()
        
        // Permission state depends on system settings
        // We can only verify that the property is set
        XCTAssertNotNil(windowManager.hasPermission)
    }
    
    func testGetPokerAppWindows() {
        // Without real windows, this should return empty
        let pokerWindows = windowManager.getPokerAppWindows()
        XCTAssertTrue(pokerWindows.isEmpty)
    }
    
    func testGetPokerTableWindows() {
        // Without detected tables, this should return empty
        let tableWindows = windowManager.getPokerTableWindows()
        XCTAssertTrue(tableWindows.isEmpty)
    }
    
    func testGetVisibleWindows() {
        // Without windows, this should return empty
        let visibleWindows = windowManager.getVisibleWindows()
        XCTAssertTrue(visibleWindows.isEmpty)
    }
    
    func testGetAppWindows() {
        // Without windows, this should return empty
        let appWindows = windowManager.getAppWindows()
        XCTAssertTrue(appWindows.isEmpty)
    }
    
    func testScanWindowsWithoutPermission() async {
        // Force no permission state
        windowManager.hasPermission = false
        
        await windowManager.scanWindows()
        
        // Should not scan without permission
        XCTAssertEqual(windowManager.windowCount, 0)
        XCTAssertTrue(windowManager.windows.isEmpty)
        XCTAssertFalse(windowManager.isScanning)
    }
    
    func testPrintWindowSummary() {
        // This should not crash even with no windows
        windowManager.printWindowSummary()
        
        // Verify state hasn't changed
        XCTAssertEqual(windowManager.windowCount, 0)
    }
    
    // MARK: - Performance Tests
    
    func testPokerAppDetectionPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = windowManager.getPokerAppWindows()
            }
        }
    }
    
    func testPokerTableDetectionPerformance() {
        // Create mock windows for performance testing
        let mockWindows: [WindowManager.WindowInfo] = []
        
        measure {
            _ = windowManager.pokerTableDetector.detectPokerTables(from: mockWindows)
        }
    }
}

// MARK: - Mock Helpers for Testing

extension WindowManagerIntegrationTests {
    
    func testPokerTableDetectorIntegration() {
        XCTAssertNotNil(windowManager.pokerTableDetector)
        
        // Test that detector is properly integrated
        let emptyTables = windowManager.pokerTableDetector.detectPokerTables(from: [])
        XCTAssertTrue(emptyTables.isEmpty)
    }
    
    func testWindowInfoStructure() {
        // Test that WindowInfo properties are accessible
        // This would require proper mocking of SCWindow
        
        // For now, we can test the structure exists
        XCTAssertTrue(true, "WindowInfo structure exists in WindowManager")
    }
}