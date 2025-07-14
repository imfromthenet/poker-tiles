//
//  AutoScanTests.swift
//  PokerTilesTests
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import XCTest
@testable import PokerTiles

final class AutoScanTests: XCTestCase {
    
    var windowManager: WindowManager!
    
    override func setUp() {
        super.setUp()
        windowManager = WindowManager()
    }
    
    override func tearDown() {
        windowManager.stopAutoScan()
        windowManager = nil
        super.tearDown()
    }
    
    func testAutoScanEnabledByDefault() {
        XCTAssertTrue(windowManager.isAutoScanEnabled)
        XCTAssertEqual(windowManager.autoScanInterval, 1.0)
    }
    
    func testSetAutoScanEnabled() {
        // Disable auto scan
        windowManager.setAutoScanEnabled(false)
        XCTAssertFalse(windowManager.isAutoScanEnabled)
        
        // Re-enable auto scan
        windowManager.setAutoScanEnabled(true)
        XCTAssertTrue(windowManager.isAutoScanEnabled)
    }
    
    func testSetAutoScanInterval() {
        // Test setting valid interval
        windowManager.setAutoScanInterval(2.5)
        XCTAssertEqual(windowManager.autoScanInterval, 2.5)
        
        // Test minimum interval enforcement
        windowManager.setAutoScanInterval(0.005)
        XCTAssertEqual(windowManager.autoScanInterval, 0.01)
        
        // Test negative interval gets clamped to minimum
        windowManager.setAutoScanInterval(-5.0)
        XCTAssertEqual(windowManager.autoScanInterval, 0.01)
        
        // Test very small positive value
        windowManager.setAutoScanInterval(0.02)
        XCTAssertEqual(windowManager.autoScanInterval, 0.02)
    }
    
    func testAutoScanStartsOnInit() async {
        // Give auto-scan a moment to potentially start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // We can't directly test if scanning happened without permission,
        // but we can verify the auto-scan configuration is set up
        XCTAssertTrue(windowManager.isAutoScanEnabled)
    }
}