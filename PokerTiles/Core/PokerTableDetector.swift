//
//  PokerTableDetector.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import Foundation
import CoreGraphics

class PokerTableDetector {
    
    func detectPokerTables(from windows: [WindowInfo]) -> [PokerTable] {
        var pokerTables: [PokerTable] = []
        
        for window in windows {
            if let pokerTable = analyzeWindow(window) {
                pokerTables.append(pokerTable)
            }
        }
        
        return pokerTables.sorted { $0.windowInfo.title < $1.windowInfo.title }
    }
    
    private func analyzeWindow(_ window: WindowInfo) -> PokerTable? {
        // First check if it's a poker app
        let pokerApp = PokerApp.from(bundleIdentifier: window.bundleIdentifier)
        guard pokerApp != .unknown else { return nil }
        
        // Create a potential poker table
        let potentialTable = PokerTable(windowInfo: window)
        
        // Filter out non-table windows
        guard isPokerTableWindow(potentialTable) else { return nil }
        
        return potentialTable
    }
    
    private func isPokerTableWindow(_ table: PokerTable) -> Bool {
        let title = table.windowInfo.title
        
        // Skip empty titles
        guard !title.isEmpty else { return false }
        
        // Skip if it's clearly a lobby window
        if table.pokerApp.lobbyWindowPatterns.contains(where: { title.lowercased().contains($0.lowercased()) }) {
            return false
        }
        
        // Skip common non-table windows
        let nonTablePatterns = [
            "cashier", "settings", "preferences", "options",
            "history", "statistics", "notes", "chat",
            "help", "about", "update", "install",
            "login", "register", "password", "account"
        ]
        
        let lowercasedTitle = title.lowercased()
        if nonTablePatterns.contains(where: { lowercasedTitle.contains($0) }) {
            return false
        }
        
        // Check if window is reasonable size for a poker table
        let bounds = table.windowInfo.bounds
        guard bounds.width >= 400 && bounds.height >= 300 else { return false }
        
        // If it matches table patterns, it's likely a table
        if table.pokerApp.isTableWindow(title: title) {
            return true
        }
        
        // Additional heuristics for tables that might not match patterns
        // Look for table number patterns (e.g., "Table 123456")
        let tableNumberPattern = try? NSRegularExpression(pattern: "table\\s*\\d+", options: .caseInsensitive)
        if tableNumberPattern?.firstMatch(in: title, options: [], range: NSRange(title.startIndex..., in: title)) != nil {
            return true
        }
        
        // Look for stakes patterns (e.g., "$0.50/$1.00", "€5/€10")
        let stakesPattern = try? NSRegularExpression(pattern: "[$€£]?\\d+([.,]\\d+)?/[$€£]?\\d+([.,]\\d+)?", options: [])
        if stakesPattern?.firstMatch(in: title, options: [], range: NSRange(title.startIndex..., in: title)) != nil {
            return true
        }
        
        // Look for player count patterns (e.g., "6-max", "9-handed")
        let playerCountPattern = try? NSRegularExpression(pattern: "\\d+[-\\s]?(max|handed|players)", options: .caseInsensitive)
        if playerCountPattern?.firstMatch(in: title, options: [], range: NSRange(title.startIndex..., in: title)) != nil {
            return true
        }
        
        return false
    }
    
    func groupTablesByApp(_ tables: [PokerTable]) -> [PokerApp: [PokerTable]] {
        return Dictionary(grouping: tables) { $0.pokerApp }
    }
    
    func groupTablesByType(_ tables: [PokerTable]) -> [PokerTable.TableType: [PokerTable]] {
        return Dictionary(grouping: tables) { $0.tableType }
    }
}