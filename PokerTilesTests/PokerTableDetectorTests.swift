//
//  PokerTableDetectorTests.swift
//  PokerTilesTests
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import XCTest
@testable import PokerTiles

final class PokerTableDetectorTests: XCTestCase {
    
    var detector: PokerTableDetector!
    
    override func setUp() {
        super.setUp()
        detector = PokerTableDetector()
    }
    
    override func tearDown() {
        detector = nil
        super.tearDown()
    }
    
    func testDetectPokerTablesWithEmptyWindows() {
        let tables = detector.detectPokerTables(from: [])
        XCTAssertTrue(tables.isEmpty, "Should return empty array for empty windows")
    }
    
    func testGroupTablesByApp() throws {
        throw XCTSkip("This test requires creating mock WindowInfo objects which contain SCWindow instances that cannot be instantiated in tests. The grouping logic is tested indirectly through integration tests.")
    }
    
    func testGroupTablesByType() throws {
        throw XCTSkip("This test requires creating mock WindowInfo objects which contain SCWindow instances that cannot be instantiated in tests. The grouping logic is tested indirectly through integration tests.")
    }
    
    func testTableSorting() throws {
        throw XCTSkip("This test requires creating mock WindowInfo objects which contain SCWindow instances that cannot be instantiated in tests. The sorting logic is simple string comparison and is tested indirectly through integration tests.")
    }
    
    // MARK: - Note on Mocking
    
    // The following helper methods cannot be implemented because WindowManager.WindowInfo
    // contains an SCWindow instance that cannot be created in tests. To make this code
    // fully testable, the architecture would need to be refactored to use protocols
    // or dependency injection. For now, tests that require these mocks are skipped.
}

// MARK: - Regex Pattern Tests

extension PokerTableDetectorTests {
    
    func testTableNumberPatternMatching() {
        let pattern = try! NSRegularExpression(pattern: "table\\s*#?\\d+", options: .caseInsensitive)
        
        let testCases = [
            ("Table 123456", true),
            ("table #98765", true),
            ("Tournament 555 Table 42", true),
            ("Random text without table", false),
            ("Lobby", false),
            ("TABLE 999", true),
            ("My Table", false)
        ]
        
        for (text, shouldMatch) in testCases {
            let range = NSRange(text.startIndex..., in: text)
            let matches = pattern.firstMatch(in: text, options: [], range: range) != nil
            XCTAssertEqual(matches, shouldMatch, 
                          "Pattern should \(shouldMatch ? "" : "not ")match '\(text)'")
        }
    }
    
    func testStakesPatternMatching() {
        let pattern = try! NSRegularExpression(pattern: "[$€£]?\\d+([.,]\\d+)?/[$€£]?\\d+([.,]\\d+)?", options: [])
        
        let testCases = [
            ("$0.50/$1.00", true),
            ("€5/€10", true),
            ("£2.50/£5", true),
            ("$1/$2 USD", true),
            ("0.25/0.50", true),
            ("$100/$200", true),
            ("Random text", false),
            ("NL200", false),
            ("5/10 game", true)
        ]
        
        for (text, shouldMatch) in testCases {
            let range = NSRange(text.startIndex..., in: text)
            let matches = pattern.firstMatch(in: text, options: [], range: range) != nil
            XCTAssertEqual(matches, shouldMatch,
                          "Stakes pattern should \(shouldMatch ? "" : "not ")match '\(text)'")
        }
    }
    
    func testPlayerCountPatternMatching() {
        let pattern = try! NSRegularExpression(pattern: "\\d+[-\\s]?(max|handed|players)", options: .caseInsensitive)
        
        let testCases = [
            ("6-max", true),
            ("9-handed", true),
            ("6 max", true),
            ("2 players", true),
            ("Full ring", false),
            ("Heads up", false),
            ("10-MAX", true),
            ("4-Handed", true)
        ]
        
        for (text, shouldMatch) in testCases {
            let range = NSRange(text.startIndex..., in: text)
            let matches = pattern.firstMatch(in: text, options: [], range: range) != nil
            XCTAssertEqual(matches, shouldMatch,
                          "Player count pattern should \(shouldMatch ? "" : "not ")match '\(text)'")
        }
    }
}