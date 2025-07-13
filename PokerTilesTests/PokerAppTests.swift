//
//  PokerAppTests.swift
//  PokerTilesTests
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import XCTest
@testable import PokerTiles

final class PokerAppTests: XCTestCase {
    
    func testPokerAppDetectionFromBundleIdentifier() {
        let testCases: [(bundleId: String, expected: PokerApp)] = [
            ("com.pokerstars.PokerStarsMac", .pokerStars),
            ("com.pokerstars.eu", .pokerStars),
            ("com.pokerstars.net.client", .pokerStars),
            ("com.pokerstarsuk.poker", .pokerStars),
            ("com.888poker.mac", .poker888),
            ("com.888holdingsplc.888poker", .poker888),
            ("com.ggpoker.desktop", .ggPoker),
            ("com.goodgame.poker", .ggPoker),
            ("com.partypoker.client", .partyPoker),
            ("fr.winamax.poker", .winamax),
            ("com.ignitioncasino.client", .ignition),
            ("com.americascardroom.desktop", .acr),
            ("com.randomapp.notpoker", .unknown),
            ("", .unknown)
        ]
        
        for testCase in testCases {
            let detected = PokerApp.from(bundleIdentifier: testCase.bundleId)
            XCTAssertEqual(detected, testCase.expected, 
                          "Bundle ID '\(testCase.bundleId)' should detect as \(testCase.expected.rawValue), but got \(detected.rawValue)")
        }
    }
    
    func testTableWindowPatternDetection() {
        let testCases: [(title: String, app: PokerApp, isTable: Bool)] = [
            // PokerStars patterns
            ("Tournament 123456 Table 1 - No Limit Hold'em", .pokerStars, true),
            ("$0.50/$1.00 USD - Table 'Andromeda' 6-max", .pokerStars, true),
            ("Zoom NL100 - 6-max", .pokerStars, true),
            ("Spin & Go $5 - Table #1", .pokerStars, true),
            ("PokerStars Lobby", .pokerStars, false),
            ("Tournament Lobby", .pokerStars, false),
            ("Cashier", .pokerStars, false),
            
            // 888poker patterns
            ("Table Miami - $0.10/$0.20 - No Limit Hold'em", .poker888, true),
            ("SNAP $10 NL Hold'em", .poker888, true),
            ("Tournament #12345 Table 8", .poker888, true),
            ("888poker Lobby", .poker888, false),
            ("Settings", .poker888, false),
            
            // GGPoker patterns
            ("Rush & Cash $0.25/$0.50 - Table #123", .ggPoker, true),
            ("All-In or Fold #12345", .ggPoker, true),
            ("Battle Royale Table 5", .ggPoker, true),
            ("GGPoker Lobby", .ggPoker, false),
            ("Smart HUD", .ggPoker, false),
            
            // Generic non-table windows
            ("My Account", .pokerStars, false),
            ("Hand History", .poker888, false),
            ("Statistics", .ggPoker, false)
        ]
        
        for testCase in testCases {
            let isTable = testCase.app.isTableWindow(title: testCase.title)
            XCTAssertEqual(isTable, testCase.isTable,
                          "\(testCase.app.rawValue): '\(testCase.title)' should be table=\(testCase.isTable), but got \(isTable)")
        }
    }
    
    func testLobbyWindowPatternDetection() {
        let lobbyTitles = [
            "Lobby",
            "Home",
            "Cashier",
            "Settings",
            "Tournament Lobby",
            "My Stars",
            "My Account",
            "Promotions"
        ]
        
        for app in PokerApp.allCases where app != .unknown {
            for title in lobbyTitles {
                let isTable = app.isTableWindow(title: title)
                XCTAssertFalse(isTable, "\(app.rawValue) should not detect '\(title)' as a table")
            }
        }
    }
    
    func testAllPokerAppsHavePatterns() {
        for app in PokerApp.allCases {
            if app != .unknown {
                XCTAssertFalse(app.bundleIdentifiers.isEmpty, 
                              "\(app.rawValue) should have bundle identifiers")
                XCTAssertFalse(app.tableWindowPatterns.isEmpty, 
                              "\(app.rawValue) should have table patterns")
                XCTAssertFalse(app.lobbyWindowPatterns.isEmpty, 
                              "\(app.rawValue) should have lobby patterns")
            }
        }
    }
}