//
//  Logger.swift
//  PokerTiles
//
//  Centralized logging system using Apple's modern Logger API
//

import OSLog

extension Logger {
    /// The subsystem for all PokerTiles logging
    private static let subsystem = "com.olsevskas.PokerTiles"
    
    // MARK: - Categorized Loggers
    
    /// Logger for window management operations
    static let windowManager = Logger(subsystem: subsystem, category: "WindowManager")
    
    /// Logger for permission-related operations
    static let permissions = Logger(subsystem: subsystem, category: "Permissions")
    
    /// Logger for hotkey management
    static let hotkeys = Logger(subsystem: subsystem, category: "Hotkeys")
    
    /// Logger for poker table detection
    static let pokerDetection = Logger(subsystem: subsystem, category: "PokerDetection")
    
    /// Logger for UI-related operations
    static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// Logger for grid overlay functionality
    static let gridOverlay = Logger(subsystem: subsystem, category: "GridOverlay")
    
    /// Logger for window movement operations
    static let windowMovement = Logger(subsystem: subsystem, category: "WindowMovement")
    
    /// Logger for accessibility API operations
    static let accessibility = Logger(subsystem: subsystem, category: "Accessibility")
    
    /// Logger for thumbnail capture operations
    static let thumbnails = Logger(subsystem: subsystem, category: "Thumbnails")
    
    /// General logger for miscellaneous operations
    static let general = Logger(subsystem: subsystem, category: "General")
}

