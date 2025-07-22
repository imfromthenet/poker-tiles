# Window Management Guide for PokerTiles

This guide covers the comprehensive window management system in PokerTiles, including how to handle resistant windows and implement grid layouts.

## Overview

PokerTiles uses a multi-layered approach to window management that combines:
1. **Accessibility API (AXUIElement)** - Primary method for window manipulation
2. **AppleScript** - Fallback for resistant windows
3. **Grid Layout Manager** - Intelligent window arrangement
4. **Resistance Detection** - Identifies and handles problematic windows

## Core Components

### 1. AccessibilityWindowManager

The primary interface for window manipulation using macOS Accessibility API.

```swift
// Basic usage
let accessibilityManager = AccessibilityWindowManager()

// Check permissions
if accessibilityManager.hasPermission {
    // Move window
    accessibilityManager.moveWindow(windowInfo, to: CGPoint(x: 100, y: 100))
    
    // Resize window
    accessibilityManager.resizeWindow(windowInfo, to: CGSize(width: 800, height: 600))
    
    // Move gradually (for resistant windows)
    accessibilityManager.moveWindow(windowInfo, to: position, gradual: true)
}
```

### 2. AppleScriptWindowManager

Fallback method for windows that resist Accessibility API manipulation.

```swift
let appleScriptManager = AppleScriptWindowManager()

// Move window using AppleScript
appleScriptManager.moveWindow(windowInfo, to: position)

// Special handling for poker applications
appleScriptManager.movePokerStarsWindow(windowInfo, to: position)
appleScriptManager.moveBrowserPokerWindow(windowInfo, to: position)
```

### 3. WindowManipulator

Unified interface that intelligently chooses the best manipulation method.

```swift
let manipulator = WindowManipulator()

// Automatically tries multiple methods
manipulator.moveWindow(windowInfo, to: position)

// Batch operations
let windows = [(window1, pos1), (window2, pos2)]
manipulator.moveWindows(windows)

// Grid arrangement
manipulator.arrangeWindowsInGrid(windows, on: screen, rows: 2, cols: 2)
```

### 4. GridLayoutManager

Handles grid-based window layouts with multi-monitor support.

```swift
let gridManager = GridLayoutManager()

// Calculate grid layout
let grid = gridManager.calculateGridLayout(for: screen, rows: 3, cols: 3)

// Get optimal grid for window count
let (rows, cols) = gridManager.calculateOptimalGrid(for: 6) // Returns (2, 3)

// Predefined layouts
let layout = GridLayoutManager.GridLayout.threeByThree
gridManager.arrangePokerTables(tables, preferredScreen: screen)

// Special layouts
let cascadeFrames = gridManager.createCascadeLayout(for: windows, on: screen)
let stackFrames = gridManager.createStackLayout(for: windows, on: screen)

// Multi-monitor distribution
let distribution = gridManager.distributeAcrossScreens(windows, screens: NSScreen.screens)
```

### 5. WindowResistanceDetector

Identifies why windows resist manipulation and suggests workarounds.

```swift
let detector = WindowResistanceDetector()

// Analyze single window
let profile = detector.analyzeWindow(windowInfo)
print("Resistance type: \(profile.resistanceType)")
print("Suggested method: \(profile.suggestedMethod)")

// Find all resistant windows
let resistantWindows = detector.getResistantWindows(from: allWindows)

// Apply workaround
if profile.resistanceType != .none {
    detector.applyWorkaround(for: profile, targetFrame: desiredFrame)
}
```

## Window Resistance Patterns

### Common Resistance Types

1. **Permission Denied**
   - Missing Accessibility or Screen Recording permissions
   - Solution: Request permissions through PermissionManager

2. **Application Locked**
   - App prevents external window manipulation
   - Solution: Use AppleScript as fallback

3. **Display Boundary Lock**
   - Window validates position against screen bounds
   - Solution: Use gradual movement or adjust to valid bounds

4. **Full Screen Mode**
   - Window is in fullscreen and cannot be moved
   - Solution: Exit fullscreen first

5. **Minimized**
   - Window is in dock
   - Solution: Restore window before manipulation

### Known Resistant Applications

```swift
// PokerStars - validates against display bounds
// Workaround: Use AppleScript first

// 888poker - locks during active play
// Workaround: Use gradual movement

// GGPoker - requires multiple attempts
// Workaround: Use retry logic
```

## Grid Layout Strategies

### Dynamic Grid Calculation

The system automatically calculates optimal grid sizes:
- 1 window: 1×1 (fullscreen)
- 2 windows: 2×1 (side by side)
- 3-4 windows: 2×2
- 5-6 windows: 3×2
- 7-9 windows: 3×3
- 10+ windows: Calculated based on square root

### Multi-Monitor Support

```swift
// Distribute windows across all screens
windowManager.distributeTablesAcrossScreens()

// Arrange on specific screen
let targetScreen = NSScreen.screens[1]
windowManager.arrangePokerTablesInGrid(.threeByThree, on: targetScreen)
```

### Overlap Prevention

The system automatically prevents window overlap:
```swift
var frames = calculateInitialFrames()
gridManager.preventOverlap(&frames, minSpacing: 5)
```

## Integration with WindowManager

The WindowManager class provides high-level methods:

```swift
let windowManager = WindowManager()

// Auto-arrange all poker tables
windowManager.autoArrangePokerTables()

// Use specific layout
windowManager.arrangePokerTablesInGrid(.twoByTwo)

// Cascade windows
windowManager.cascadePokerTables()

// Stack windows (same position)
windowManager.stackPokerTables()

// Analyze resistance
windowManager.analyzeWindowResistance()

// Get statistics
let stats = windowManager.getManipulationStatistics()
```

## Permission Requirements

### Required Permissions

1. **Screen Recording**
   - Required for window detection and thumbnails
   - Check: `CGPreflightScreenCaptureAccess()`

2. **Accessibility**
   - Required for window manipulation
   - Check: `AXIsProcessTrusted()`

3. **Automation** (optional)
   - Required for AppleScript fallback
   - Triggered on first use

### Permission Management

```swift
// Check all permissions
let status = PermissionManager.checkAllPermissions()

// Request specific permission
PermissionManager.requestPermission(.accessibility)

// Open System Preferences
PermissionManager.openSystemPreferences(for: .accessibility)

// Monitor permission changes
let timer = PermissionManager.startMonitoringPermissions { status in
    // Update UI based on permission status
}
```

## Best Practices

1. **Always Check Permissions First**
   ```swift
   guard PermissionManager.hasAccessibilityPermission() else {
       PermissionManager.requestAccessibilityPermission()
       return
   }
   ```

2. **Use WindowManipulator for Reliability**
   - Automatically tries multiple methods
   - Tracks success rates per application
   - Applies known workarounds

3. **Handle Resistance Gracefully**
   ```swift
   let profile = resistanceDetector.analyzeWindow(window)
   if profile.resistanceType != .none {
       // Show user-friendly message
       print("Window resistance detected: \(profile.details)")
       
       // Try workaround
       resistanceDetector.applyWorkaround(for: profile, targetFrame: frame)
   }
   ```

4. **Batch Operations for Performance**
   ```swift
   // Group by application
   let windowsByApp = Dictionary(grouping: windows) { $0.appName }
   
   // Process each app's windows together
   for (app, appWindows) in windowsByApp {
       manipulator.moveWindows(appWindows.map { ($0, calculatePosition($0)) })
   }
   ```

5. **Respect System Constraints**
   - Don't try to manipulate system windows
   - Check display bounds before moving
   - Handle fullscreen mode appropriately

## Troubleshooting

### Window Won't Move

1. Check permissions: `PermissionManager.checkAllPermissions()`
2. Analyze resistance: `resistanceDetector.analyzeWindow(window)`
3. Try gradual movement: `moveWindow(window, to: position, gradual: true)`
4. Use AppleScript fallback: `appleScriptManager.moveWindow(window, to: position)`

### Performance Issues

1. Disable auto-scan during batch operations
2. Use batch move methods instead of individual calls
3. Cache window references when possible

### Multi-Monitor Issues

1. Ensure window position is within target screen bounds
2. Use `distributeAcrossScreens()` for automatic distribution
3. Check screen arrangement in System Preferences

## Example: Complete Window Management Flow

```swift
class PokerTableOrganizer {
    let windowManager = WindowManager()
    let manipulator = WindowManipulator()
    let resistanceDetector = WindowResistanceDetector()
    
    func organizePokerTables() async {
        // 1. Check permissions
        guard PermissionManager.hasAllPermissions() else {
            PermissionManager.requestAllPermissions()
            return
        }
        
        // 2. Scan for windows
        await windowManager.scanWindows()
        
        // 3. Analyze poker tables
        let tables = windowManager.pokerTables
        guard !tables.isEmpty else {
            print("No poker tables found")
            return
        }
        
        // 4. Check for resistant windows
        let resistantTables = tables.filter { table in
            let profile = resistanceDetector.analyzeWindow(table.windowInfo)
            return profile.resistanceType != .none
        }
        
        if !resistantTables.isEmpty {
            print("Found \(resistantTables.count) resistant windows")
            // Handle resistant windows specially
        }
        
        // 5. Arrange tables
        if NSScreen.screens.count > 1 {
            // Multi-monitor setup
            windowManager.distributeTablesAcrossScreens()
        } else {
            // Single monitor - use optimal grid
            windowManager.autoArrangePokerTables()
        }
        
        // 6. Verify arrangement
        await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        await windowManager.scanWindows()
        
        // 7. Show statistics
        let stats = windowManager.getManipulationStatistics()
        print(stats)
    }
}
```

This comprehensive window management system provides reliable control over poker table windows, even when dealing with applications that resist external manipulation.