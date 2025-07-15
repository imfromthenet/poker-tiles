//
//  PokerApp.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import Foundation

enum PokerApp: String, CaseIterable {
    case pokerStars = "PokerStars"
    case poker888 = "888poker"
    case ggPoker = "GGPoker"
    case partyPoker = "partypoker"
    case winamax = "Winamax"
    case ignition = "Ignition"
    case acr = "Americas Cardroom"
    case unknown = "Unknown"
    
    var bundleIdentifiers: [String] {
        switch self {
        case .pokerStars:
            return ["com.pokerstars", "com.pokerstars.eu", "com.pokerstars.net", "com.pokerstarsuk.poker"]
        case .poker888:
            return ["com.888poker", "com.888holdingsplc.888poker"]
        case .ggPoker:
            return ["com.ggpoker", "com.goodgame.poker", "com.nsus1.ggpoker"]
        case .partyPoker:
            return ["com.partypoker", "com.partygaming.partypoker"]
        case .winamax:
            return ["com.winamax", "fr.winamax.poker"]
        case .ignition:
            return ["com.ignitioncasino", "com.ignition.poker"]
        case .acr:
            return ["com.americascardroom", "com.acr.poker", "com.winningpokernetwork"]
        case .unknown:
            return []
        }
    }
    
    var tableWindowPatterns: [String] {
        switch self {
        case .pokerStars:
            return ["Tournament", "Cash", "Zoom", "Spin & Go", "Table", "6-Max", "9-Max", "Heads-Up"]
        case .poker888:
            return ["Table", "Tournament", "SNAP", "BLAST", "Cash Game"]
        case .ggPoker:
            return ["Table", "Rush & Cash", "All-In or Fold", "Battle Royale", "Flip & Go"]
        case .partyPoker:
            return ["Table", "fastforward", "SPINS", "Cash Game", "Sit & Go"]
        case .winamax:
            return ["Table", "Expresso", "Cash Game", "Go Fast"]
        case .ignition:
            return ["Table", "Zone Poker", "Jackpot Sit & Go", "Cash"]
        case .acr:
            return ["Table", "Blitz", "Jackpot Poker", "Cash Game", "Beast"]
        case .unknown:
            return []
        }
    }
    
    var lobbyWindowPatterns: [String] {
        switch self {
        case .pokerStars:
            return ["Lobby", "Home", "Cashier", "Settings", "Tournament Lobby", "My Stars"]
        case .poker888:
            return ["Lobby", "My Account", "Cashier", "Settings", "Promotions"]
        case .ggPoker:
            return ["Lobby", "Smart HUD", "Cashier", "Profile", "Shop"]
        case .partyPoker:
            return ["Lobby", "My Account", "Cashier", "Rewards"]
        case .winamax:
            return ["Lobby", "Mon Compte", "Caisse", "Accueil"]
        case .ignition:
            return ["Lobby", "Cashier", "Rewards", "Account"]
        case .acr:
            return ["Lobby", "Cashier", "Missions", "The Beast"]
        case .unknown:
            return []
        }
    }
    
    static func from(bundleIdentifier: String) -> PokerApp {
        for app in PokerApp.allCases {
            if app.bundleIdentifiers.contains(where: { bundleIdentifier.lowercased().contains($0.lowercased()) }) {
                return app
            }
        }
        return .unknown
    }
    
    func isTableWindow(title: String) -> Bool {
        let lowercasedTitle = title.lowercased()
        
        // Check if it's a lobby window
        if lobbyWindowPatterns.contains(where: { lowercasedTitle.contains($0.lowercased()) }) {
            return false
        }
        
        // Check if it matches table patterns
        return tableWindowPatterns.contains(where: { lowercasedTitle.contains($0.lowercased()) })
    }
}