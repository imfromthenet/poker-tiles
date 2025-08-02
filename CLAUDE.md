# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PokerTiles is a comprehensive poker table management application for macOS, designed to enhance multi-tabling experiences with advanced overlays, hotkeys, and table organization features. The app combines Accessibility API and ScreenCaptureKit to read, monitor, and control poker tables from desktop poker applications.

## Additional Guidelines

Claude Code should also reference the project-specific rules and documentation in the `.claude/` directory:

### Core Development Rules
- `.claude/rules/modern-swift.md` - Swift/SwiftUI best practices
- `.claude/rules/implement-task.md` - Structured approach to implementing features
- `.claude/rules/check.md` - Code verification procedures

### Workflow Rules
- `.claude/rules/bug-fix.md` - Standardized bug fixing workflow from issue to PR
- `.claude/rules/commit.md` - Commit message conventions with descriptive emojis
- `.claude/rules/commit-fast.md` - Quick commit workflow for simple changes
- `.claude/rules/analyze-issue.md` - Issue analysis and technical specification template
- `.claude/rules/context-prime.md` - Project context loading and understanding procedure
- `.claude/rules/code-analysis.md` - Code analysis and review procedures
- `.claude/rules/update-docs.md` - Documentation update guidelines
- `.claude/rules/pr-review.md` - Pull request review process and checklist
- `.claude/rules/add-to-changelog.md` - Changelog update procedures

### Available Commands
- `.claude/commands/reflection.md` - Analyze and improve Claude instructions and configuration

Apply these rules when working on this codebase.

## Core Features

### ✅ Implemented
- **Poker Table Detection**: Automatically detect and track poker tables from desktop applications
- **Table Organization**: Grid layouts, stacking, and positioning for optimal multi-tabling

### 🟡 Partially Implemented
- **Hotkey System**: Configurable shortcuts framework (actions not yet connected)

### 🔴 Planned
- **Custom Overlays**: HUD-style information displays with statistics and notes
- **Game State Tracking**: Real-time detection of cards, betting rounds, and pot sizes

## Implementation Status

### ✅ Implemented Features
- **Window Detection**: Desktop application window discovery via Accessibility API
- **Poker Table Detection**: Basic title-based identification of poker tables
- **Window Management**: Move, resize, and arrange windows in grid layouts
- **Grid Overlay**: Visual grid overlay for window arrangement
- **Permission Management**: Accessibility and Screen Recording permission handling
- **Auto-scan**: Automatic window scanning with configurable intervals
- **Basic Hotkey System**: Framework for global hotkeys (actions not yet implemented)
- **Dark Mode Support**: Full color scheme management

### 🚧 In Development
- **Enhanced Table Detection**: More sophisticated pattern matching
- **Debug UI Improvements**: Visual distinction for debug components

### 📋 Planned Features (Not Yet Implemented)
- **Computer Vision Integration**: OCR for card/chip detection
- **Core ML Models**: Custom models for poker element recognition
- **Game State Tracking**: Real-time tracking of betting rounds
- **HUD System**: Statistics display and player notes
- **Advanced Overlays**: Pot odds calculator, timers, action indicators
- **Poker Action Automation**: Hotkey-triggered poker actions

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PokerTiles Main App                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   SwiftUI   │  │   AppKit     │  │  Permissions    │  │
│  │  Tables 🟢  │  │ Overlays 🔴  │  │  Manager 🟢     │  │
│  └──────┬──────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                 │                    │            │
│  ┌──────▼─────────────────▼────────────────────▼────────┐  │
│  │              Poker Table Manager 🟢                   │  │
│  │  • Table Discovery    • Table State Tracking 🔴      │  │
│  │  • App Detection      • Multi-Table Coordination     │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
│  ┌─────────────┐       │       ┌─────────────────────┐   │
│  │   Poker     │       │       │   Computer Vision   │   │
│  │ Element     │◄──────┼──────►│   Poker Detector    │   │
│  │ Detector 🔴 │       │       │   (Cards/Chips) 🔴  │   │
│  └─────────────┘       │       └─────────────────────┘   │
│                         │                                   │
│  ┌─────────────────────▼─────────────────────────────────┐  │
│  │                Poker Overlay System 🔴                 │  │
│  │  • HUD Widgets     • Statistics Display              │  │
│  │  • Action Buttons  • Timer Overlays                  │  │
│  └─────────────────────┬─────────────────────────────────┘  │
│                         │                                   │
│  ┌─────────────────────▼─────────────────────────────────┐  │
│  │                 Hotkey Engine 🟡                       │  │
│  │  • Action Mapping  • Global Shortcuts                │  │
│  │  • Context Aware   • Multi-Table Support             │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```
🟢 Implemented | 🟡 Partial | 🔴 Planned

## Key Technologies

### Core Frameworks
- **Accessibility API (AXUIElement)**: Direct access to application UI elements for precise poker table detection
- **ScreenCaptureKit**: High-performance window capture for visual analysis
- **Vision Framework**: OCR and computer vision for card/chip detection (Planned)
- **Core ML**: Custom models for poker-specific element recognition (Planned)
- **SwiftUI + AppKit**: Modern UI with custom overlay windows

## Project Structure

```
PokerTiles/
├── PokerTiles/
│   ├── PokerTilesApp.swift          # Main app entry point
│   ├── ContentView.swift            # Main tab view container
│   ├── Core/
│   │   ├── WindowManager/           # Window discovery and management
│   │   ├── WindowManagement/        # Window manipulation implementations
│   │   ├── HotkeyManager/           # Global hotkey handling
│   │   ├── Permissions/             # Permission management
│   │   ├── PokerTableDetector.swift # Table detection logic
│   │   ├── ColorSchemeManager.swift # Theme management
│   │   └── Constants.swift          # Centralized constants for UI values
│   ├── Models/
│   │   ├── PokerTable.swift         # Poker table data model
│   │   ├── PokerApp.swift           # Poker app definitions
│   │   ├── WindowInfo.swift         # Window information model
│   │   ├── AppSettings.swift        # Application settings
│   │   └── PermissionState.swift    # Permission status model
│   ├── Services/
│   │   └── GridOverlay/             # Grid overlay system (only service)
│   └── UI/
│       ├── Tabs/                    # Main tab views
│       ├── Sections/                # Reusable UI sections
│       ├── Components/              # UI components
│       └── WindowManagement/        # Window management UI
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

## Build Verification with XcodeBuildMCP

Claude Code has access to XcodeBuildMCP tools. Use these for all build operations:
- `mcp__XcodeBuildMCP__discover_projs` - Find Xcode projects
- `mcp__XcodeBuildMCP__build_mac_proj` - Build the macOS app
- `mcp__XcodeBuildMCP__build_run_mac_proj` - Build and run for testing
- `mcp__XcodeBuildMCP__show_build_set_proj` - Show build settings

**Important**: Always verify code changes compile successfully using these MCP tools before considering a task complete.

## Swift Development Resources

The `.claude/docs/` directory contains extensive Swift-specific documentation:
- `.claude/docs/swift-testing-playbook.md` - Comprehensive Swift Testing migration guide from XCTest
- `.claude/docs/swift-testing-api.md` - Complete Swift Testing API reference (large file, search for specific APIs)
- `.claude/docs/swift-observation.md` - Swift Observation framework patterns for reactive programming
- `.claude/docs/swift-observable.md` - Observable patterns for state management in SwiftUI
- `.claude/docs/swiftui.md` - Extensive SwiftUI best practices and patterns (comprehensive guide)
- `.claude/docs/swift6-migration.md` - Swift 6 migration guidance and concurrency updates
- `.claude/docs/swiftdata.md` - SwiftData framework usage for persistence

Reference these resources when implementing Swift-specific features or migrating code.

## Required Permissions

- **Accessibility Access**: Required for content access and table detection
- **Screen Recording**: Required for visual analysis and overlay positioning
- **Input Monitoring**: Required for global hotkey capture

## Poker-Specific Features

### Table Detection
- Automatic recognition of poker tables from desktop applications ✅
- Real-time game state tracking (preflop, flop, turn, river) 🔴 Planned
- Player position and action detection 🔴 Planned
- Pot size and betting analysis 🔴 Planned

### Overlay System 🔴 Planned
- Customizable HUD with statistics and notes
- Pot odds calculator
- Timer displays and action indicators
- Player tracking and history

### Hotkey Actions
- Betting actions: fold, call, raise, all-in, check 🔴 Planned
- Table navigation: next/previous table 🔴 Planned
- HUD controls: show/hide overlays 🔴 Planned
- Table management: resize, reposition, close 🟡 Partial (resize/reposition work)

### Multi-Table Support
- Simultaneous table monitoring ✅
- Priority-based processing for active tables 🔴 Planned
- Coordinated action handling across tables 🔴 Planned
- Automatic table arrangement and organization ✅ (Grid layouts)

## Current Limitations

- **Poker Action Automation**: Hotkeys are detected but don't execute poker actions yet
- **Visual Detection**: No OCR or computer vision - relies on window titles only
- **No Game State Tracking**: Cannot detect cards, chips, or betting rounds
- **Basic Table Detection**: May miss tables with non-standard titles
- **Debug UI**: Debug views not visually distinguished from production UI

## Development Priorities

### Immediate Tasks (Production Quality)
1. **Convert Debug Output to Logging**: Convert 50+ print statements to proper logging system with debug mode support
2. **Implement Logging System**: Add structured logging with OSLog
3. **Permission Code Refactoring**: Extract duplicated permission checking

### Short-term Improvements
1. **Error Handling**: Standardize error patterns across the app
2. **Debug UI Styling**: Mark debug views with different colors/styling
3. **Test Coverage**: Add unit tests for core functionality

### Long-term Goals
1. **Poker Action Automation**: Implement hotkey-triggered poker actions
2. **Computer Vision Integration**: Add OCR for game state detection
3. **HUD System**: Implement statistics and overlay features
4. **CI/CD Pipeline**: Implement automated testing and deployment
   - See detailed research: `docs/development/CICD_AND_TICKETING_RESEARCH.md`
   - Recommended: GitHub Actions with self-hosted runner + local AI for $0/month

## Known Issues

- Multiple debug print statements throughout codebase
- Permission checking code duplication (6+ occurrences)
- Hotkey actions not connected to poker operations
- No standardized error handling pattern
- Debug views not visually distinguished from production UI

## Performance Considerations

- **Selective Processing**: Only analyze active tables requiring attention
- **Smart Update Intervals**: Variable refresh rates based on game state
- **Memory Management**: Efficient capture and processing of table regions
- **Background Processing**: Non-blocking analysis using Swift Concurrency

## macOS Development Constraints

### Testing Limitations
- Cannot test Accessibility API features without proper permissions
- Cannot test Screen Recording features without user approval
- Window manipulation requires app sandbox to be disabled (already configured)

### When Testing Is Limited
- Verify code compiles using XcodeBuildMCP tools
- Check for common Swift/macOS API usage errors
- Suggest using DebugWindowMoveView for manual testing
- Warn user when features require runtime permissions

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

## Development Principles

- **Always build before attempting to commit** - Use XcodeBuildMCP tools to verify
- **Use centralized constants**: All UI magic numbers should use constants from `Core/Constants.swift`
- **Follow .claude/rules/check.md**: Run appropriate checks for code quality
- **Apply .claude/rules/modern-swift.md**: Write idiomatic Swift/SwiftUI code
- **Use .claude/rules/implement-task.md**: For structured feature implementation

## Development Tool Rules

Additional development tools and automation rules in `.claude/rules/`:
- `.claude/rules/clean.md` - Swift code formatting and quality checks (SwiftLint, SwiftFormat)
- `.claude/rules/mermaid.md` - Diagram generation for documentation and architecture
- `.claude/rules/screenshot-automation.md` - Automated screenshot capture for UI testing

## Recent Updates

### Magic Number Extraction (Completed)
- Created comprehensive `Constants.swift` file with organized categories:
  - UIConstants: spacing, corner radius, line width, frame dimensions, opacity, scale
  - AnimationConstants: durations and sleep intervals
  - SettingsConstants: auto scan, grid layout, and hotkey settings
  - LayoutConstants: window arrangement and grid cell settings
  - DebugConstants: debug-specific values
- Updated all major UI files to use centralized constants
- Removed hardcoded values throughout the codebase

### UI Cleanup (Completed)
- Removed Advanced section from Layouts tab containing unimplemented features:
  - Window resistance analysis
  - Window manipulation statistics
- Cleaned up unused code and methods from WindowManager
- Simplified the UI to focus on working features

## Summary instructions

When you are using compact, please focus on test output and code changes