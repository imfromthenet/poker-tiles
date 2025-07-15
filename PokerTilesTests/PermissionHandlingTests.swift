//
//  PermissionHandlingTests.swift
//  PokerTilesTests
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import XCTest
@testable import PokerTiles

final class PermissionHandlingTests: XCTestCase {
    
    func testPermissionStateEnum() {
        // Test hasAccess computed property
        XCTAssertTrue(PermissionState.granted.hasAccess)
        XCTAssertFalse(PermissionState.denied.hasAccess)
        XCTAssertFalse(PermissionState.notDetermined.hasAccess)
    }
    
    func testWindowManagerInitialPermissionState() {
        let windowManager = WindowManager()
        
        // Initial state should be one of the valid states
        let validStates: [PermissionState] = [.notDetermined, .granted, .denied]
        XCTAssertTrue(validStates.contains(windowManager.permissionState))
        
        // hasPermission should match the state
        XCTAssertEqual(windowManager.hasPermission, windowManager.permissionState.hasAccess)
    }
    
    func testOpenSystemPreferences() {
        let windowManager = WindowManager()
        
        // This test just verifies the method exists and doesn't crash
        // We can't actually test if System Preferences opens in unit tests
        windowManager.openSystemPreferences()
        
        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }
}