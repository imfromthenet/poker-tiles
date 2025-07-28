# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PokerTiles is a comprehensive poker table management application for macOS, designed to enhance multi-tabling experiences with advanced overlays, hotkeys, and table organization features. The app combines Accessibility API and ScreenCaptureKit to read, monitor, and control poker tables across various poker clients.

## Core Features

- **Poker Table Detection**: Automatically detect and track poker tables across browsers
- **Custom Overlays**: HUD-style information displays with statistics and notes
- **Hotkey System**: Configurable shortcuts for poker actions (fold, call, raise, etc.)
- **Table Organization**: Grid layouts, stacking, and positioning for optimal multi-tabling
- **Multi-Platform Support**: Works with browser-based poker sites and desktop applications

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PokerTiles Main App                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   SwiftUI   │  │   AppKit     │  │  Permissions    │  │
│  │   Tables    │  │  Overlays    │  │   Manager       │  │
│  └──────┬──────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                 │                    │            │
│  ┌──────▼─────────────────▼────────────────────▼────────┐  │
│  │              Poker Table Manager                      │  │
│  │  • Table Discovery    • Table State Tracking        │  │
│  │  • Site Detection     • Multi-Table Coordination    │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
│  ┌─────────────┐       │       ┌─────────────────────┐   │
│  │   Poker     │       │       │   Computer Vision   │   │
│  │ Element     │◄──────┼──────►│   Poker Detector    │   │
│  │ Detector    │       │       │   (Cards/Chips)     │   │
│  └─────────────┘       │       └─────────────────────┘   │
│                         │                                   │
│  ┌─────────────────────▼─────────────────────────────────┐  │
│  │                Poker Overlay System                    │  │
│  │  • HUD Widgets     • Statistics Display              │  │
│  │  • Action Buttons  • Timer Overlays                  │  │
│  └─────────────────────┬─────────────────────────────────┘  │
│                         │                                   │
│  ┌─────────────────────▼─────────────────────────────────┐  │
│  │                 Hotkey Engine                          │  │
│  │  • Action Mapping  • Global Shortcuts                │  │
│  │  • Context Aware   • Multi-Table Support             │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Key Technologies

### Core Frameworks
- **Accessibility API (AXUIElement)**: Direct access to browser DOM elements for precise poker table detection
- **ScreenCaptureKit**: High-performance window capture for visual analysis
- **Vision Framework**: OCR and computer vision for card/chip detection
- **Core ML**: Custom models for poker-specific element recognition
- **SwiftUI + AppKit**: Modern UI with custom overlay windows

### Multi-platform Support
- Platform-specific optimizations for major poker platforms

## Project Structure

```
PokerTiles/
├── App/
│   ├── PokerTilesApp.swift          # Main app entry point
│   └── AppDelegate.swift            # App lifecycle management
├── Core/
│   ├── WindowManager/               # Browser window discovery and tracking
│   ├── Accessibility/               # AX API integration for content access
│   ├── ScreenCapture/               # Screen capture and frame processing
│   └── Permissions/                 # Permission management and onboarding
├── Models/
│   ├── PokerTable.swift             # Poker table data model
│   ├── PokerElements.swift          # Detected poker UI elements
│   ├── GameState.swift              # Poker game state tracking
│   └── BrowserType.swift            # Browser-specific configurations
├── Services/
│   ├── PokerDetection/              # Poker table detection and analysis
│   ├── OverlaySystem/               # HUD overlay management
│   ├── HotkeyEngine/                # Global hotkey handling
│   └── TableManager/                # Multi-table coordination
└── UI/
    ├── MainWindow/                  # Primary application interface
    ├── TableList/                   # Active tables list view
    ├── OverlayViews/                # Poker HUD components
    └── Settings/                    # Configuration interface
```

## Development Commands

### Build and Run
```bash
# Build the app in Xcode
open PokerTiles.xcodeproj
# Use Xcode's build (⌘+B) and run (⌘+R) commands

# Build from command line
xcodebuild -project PokerTiles.xcodeproj -scheme PokerTiles -configuration Debug build
```

### Testing
```bash
# Run tests from command line
xcodebuild -project PokerTiles.xcodeproj -scheme PokerTiles -configuration Debug test

# Run specific test suites
xcodebuild test -project PokerTiles.xcodeproj -scheme PokerTiles -only-testing:PokerTilesTests/PokerDetectionTests
```

## Required Permissions

- **Accessibility Access**: Required for content access and table detection
- **Screen Recording**: Required for visual analysis and overlay positioning
- **Input Monitoring**: Required for global hotkey capture

## Poker-Specific Features

### Table Detection
- Automatic recognition of poker tables across major platforms
- Real-time game state tracking (preflop, flop, turn, river)
- Player position and action detection
- Pot size and betting analysis

### Overlay System
- Customizable HUD with statistics and notes
- Pot odds calculator
- Timer displays and action indicators
- Player tracking and history

### Hotkey Actions
- Betting actions: fold, call, raise, all-in, check
- Table navigation: next/previous table
- HUD controls: show/hide overlays
- Table management: resize, reposition, close

### Multi-Table Support
- Simultaneous table monitoring
- Priority-based processing for active tables
- Coordinated action handling across tables
- Automatic table arrangement and organization

## Performance Considerations

- **Selective Processing**: Only analyze active tables requiring attention
- **Smart Update Intervals**: Variable refresh rates based on game state
- **Memory Management**: Efficient capture and processing of table regions
- **Background Processing**: Non-blocking analysis using Swift Concurrency

## Development Tools

### Debug Window Move View
- Comprehensive testing interface for window manipulation
- Features:
  - Test window movement with verification
  - Grid arrangement testing (2x2, 3x3)
  - Window resize testing
  - Poker window detection
  - Real-time logging with copy functionality
- Located at: `PokerTiles/UI/DebugWindowMoveView.swift`

## Project Configuration

- Bundle ID: `com.olsevskas.PokerTiles`
- Development Team: Paulius Olsevskas
- macOS 15+ deployment target
- **App Sandbox: DISABLED** (required for Accessibility API to function properly)
  - This allows full window manipulation capabilities
  - See `docs/archive/WINDOW_MOVEMENT_FIX.md` for details
- Required entitlements:
  - `com.apple.security.accessibility` - For window manipulation
  - `com.apple.security.screen-capture` - For window detection
- SwiftUI Previews enabled for development

## Summary instructions

When you are using compact, please focus on test output and code changes
