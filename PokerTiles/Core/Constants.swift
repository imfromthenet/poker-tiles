//
//  Constants.swift
//  PokerTiles
//
//  Central location for all magic numbers and constants used throughout the app
//

import SwiftUI

// MARK: - UI Constants
struct UIConstants {
    // MARK: Spacing
    struct Spacing {
        static let extraSmall: CGFloat = 2
        static let tiny: CGFloat = 4
        static let small: CGFloat = 5
        static let compact: CGFloat = 6
        static let standard: CGFloat = 8
        static let medium: CGFloat = 10
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
        static let huge: CGFloat = 20
        static let massive: CGFloat = 24
        static let giant: CGFloat = 32
        static let gigantic: CGFloat = 40
        static let colossal: CGFloat = 52
    }
    
    // MARK: Corner Radius
    struct CornerRadius {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 6
        static let standard: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    // MARK: Line Width
    struct LineWidth {
        static let thin: CGFloat = 1
        static let standard: CGFloat = 2
        static let thick: CGFloat = 3
    }
    
    // MARK: Frame Dimensions
    struct FrameDimensions {
        static let iconSmall: CGFloat = 24
        static let buttonHeight: CGFloat = 40
        static let textFieldWidth: CGFloat = 45
        static let gridCellSize: CGFloat = 60
        static let labelWidth: CGFloat = 100
        static let layoutButtonSize: CGFloat = 120
        static let thumbnailSmall: CGFloat = 50
        static let thumbnailMedium: CGFloat = 150
        static let thumbnailLarge: CGFloat = 200
        static let sidebarWidth: CGFloat = 200
        static let formWidth: CGFloat = 400
        static let sheetWidthSmall: CGFloat = 500
        static let sheetWidthMedium: CGFloat = 600
        static let defaultWindowWidth: CGFloat = 1920
        static let defaultWindowHeight: CGFloat = 1080
    }
    
    // MARK: Opacity
    struct Opacity {
        static let veryLight: Double = 0.1
        static let light: Double = 0.2
        static let semiLight: Double = 0.3
        static let medium: Double = 0.5
        static let visible: Double = 0.7
        static let semiOpaque: Double = 0.8
        static let nearlyOpaque: Double = 0.9
        static let opaque: Double = 1.0
    }
    
    // MARK: Scale
    struct Scale {
        static let half: CGFloat = 0.5
        static let pressed: CGFloat = 0.95
        static let enlarged: CGFloat = 1.5
    }
    
    // MARK: Aspect Ratio
    struct AspectRatio {
        static let pokerTable: CGFloat = 1.6
    }
}

// MARK: - Animation Constants
struct AnimationConstants {
    // MARK: Duration
    struct Duration {
        static let instant: TimeInterval = 0.1
        static let veryShort: TimeInterval = 0.15
        static let short: TimeInterval = 0.2
        static let standard: TimeInterval = 0.3
        static let medium: TimeInterval = 0.5
        static let long: TimeInterval = 1.0
        static let veryLong: TimeInterval = 1.5
        static let extraLong: TimeInterval = 2.0
    }
    
    // MARK: Sleep Intervals (nanoseconds)
    struct SleepInterval {
        static let brief: UInt64 = 100_000_000        // 0.1 seconds
        static let short: UInt64 = 500_000_000        // 0.5 seconds
        static let standard: UInt64 = 1_000_000_000   // 1.0 second
        static let medium: UInt64 = 1_500_000_000     // 1.5 seconds
        static let long: UInt64 = 5_000_000_000       // 5.0 seconds
    }
}

// MARK: - Settings Constants
struct SettingsConstants {
    // MARK: Auto Scan
    struct AutoScan {
        static let minInterval: TimeInterval = 0.01
        static let defaultInterval: TimeInterval = 1.0
        static let maxInterval: TimeInterval = 5.0
        static let veryShortInterval: TimeInterval = 0.02
        static let mediumInterval: TimeInterval = 2.0
    }
    
    // MARK: Grid Layout
    struct GridLayout {
        static let minSpacing: CGFloat = 0.0
        static let defaultPadding: CGFloat = 10.0
        static let defaultWindowSpacing: CGFloat = 5.0
        static let maxSpacing: CGFloat = 50.0
        static let minLineWidth: CGFloat = 1.0
        static let maxLineWidth: CGFloat = 10.0
        static let defaultLineWidth: CGFloat = 2.0
        static let defaultCornerRadius: CGFloat = 8.0
        static let maxCornerRadius: CGFloat = 16.0
    }
    
    // MARK: Hotkey
    struct Hotkey {
        static let quickReleaseThreshold: TimeInterval = 0.2
        static let recordingMinWidth: CGFloat = 150.0
        static let recordingIdealWidth: CGFloat = 200.0
        static let recordingMaxWidth: CGFloat = 300.0
        static let comboDelayThreshold: TimeInterval = 0.15
    }
}

// MARK: - Layout Constants
struct LayoutConstants {
    // MARK: Window Arrangement
    struct WindowArrangement {
        static let cascadeOffset: CGFloat = 30.0
        static let cascadeInitialX: CGFloat = 100.0
        static let cascadeInitialY: CGFloat = 100.0
        static let minTableWidth: CGFloat = 400.0
        static let minTableHeight: CGFloat = 300.0
    }
    
    // MARK: Grid Cell
    struct GridCell {
        static let minCellSize: CGFloat = 100.0
        static let dotSize: CGFloat = 4.0
        static let dotSpacing: CGFloat = 16.0
    }
}

// MARK: - Debug Constants
struct DebugConstants {
    static let logWindowWidth: CGFloat = 800.0
    static let logWindowHeight: CGFloat = 600.0
    static let maxLogLines: Int = 1000
}