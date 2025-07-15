//
//  PokerTable.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import Foundation

struct PokerTable: Identifiable {
    let id: String
    let windowInfo: WindowInfo
    let pokerApp: PokerApp
    let tableType: TableType
    let isActive: Bool
    
    init(windowInfo: WindowInfo) {
        self.id = windowInfo.id
        self.windowInfo = windowInfo
        self.pokerApp = PokerApp.from(bundleIdentifier: windowInfo.bundleIdentifier)
        self.tableType = TableType.from(title: windowInfo.title, app: self.pokerApp)
        self.isActive = windowInfo.isOnScreen && !windowInfo.title.isEmpty
    }
    
    enum TableType {
        case cash
        case tournament
        case sitAndGo
        case fastFold // Zoom, SNAP, Blitz, etc.
        case unknown
        
        static func from(title: String, app: PokerApp) -> TableType {
            let lowercasedTitle = title.lowercased()
            
            // Fast-fold variants
            if lowercasedTitle.contains("zoom") || 
               lowercasedTitle.contains("snap") || 
               lowercasedTitle.contains("blitz") ||
               lowercasedTitle.contains("zone") ||
               lowercasedTitle.contains("fast") ||
               lowercasedTitle.contains("rush") {
                return .fastFold
            }
            
            // Tournament indicators
            if lowercasedTitle.contains("tournament") ||
               lowercasedTitle.contains("mtt") ||
               lowercasedTitle.contains("turbo") ||
               lowercasedTitle.contains("bounty") {
                return .tournament
            }
            
            // Sit & Go indicators
            if lowercasedTitle.contains("sit & go") ||
               lowercasedTitle.contains("sit&go") ||
               lowercasedTitle.contains("sng") ||
               lowercasedTitle.contains("spin") ||
               lowercasedTitle.contains("jackpot") ||
               lowercasedTitle.contains("expresso") {
                return .sitAndGo
            }
            
            // Cash game indicators
            if lowercasedTitle.contains("cash") ||
               lowercasedTitle.contains("nl") ||
               lowercasedTitle.contains("pl") ||
               lowercasedTitle.contains("6-max") ||
               lowercasedTitle.contains("9-max") ||
               lowercasedTitle.contains("heads-up") {
                return .cash
            }
            
            // Default to cash if it's a table window but type is unclear
            if app.isTableWindow(title: title) {
                return .cash
            }
            
            return .unknown
        }
        
        var displayName: String {
            switch self {
            case .cash: return "Cash Game"
            case .tournament: return "Tournament"
            case .sitAndGo: return "Sit & Go"
            case .fastFold: return "Fast Fold"
            case .unknown: return "Unknown"
            }
        }
    }
}