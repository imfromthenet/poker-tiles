# Grid Overlay System Redesign - Implementation Plan

## Overview
This document outlines the comprehensive redesign of the PokerTiles grid overlay system to provide accurate position tracking, multi-layer overlays, and intelligent auto-arrangement of poker tables.

## Problem Statement
The current grid overlay system has fundamental limitations:
- Only tracks the NUMBER of tables, not their ACTUAL positions
- When a new table opens, the overlay incorrectly marks slots as occupied
- No visual feedback for table states (new, moved, correctly positioned)
- Single monolithic overlay instead of composable layers

## Solution Architecture

### Core Components

#### 1. TablePositionTracker (✅ Implemented)
- Tracks actual window positions and their relationship to grid slots
- Maintains state for each table: positioned, moved, new, floating
- Maps windows to grid positions based on proximity
- Detects when tables are moved from their assigned positions

#### 2. Multi-Layer Overlay System (🔄 In Progress)
- **GridLinesOverlay**: Shows grid cell boundaries
- **TableNumberOverlay**: Shows numbers on actual tables
- **CellNumberOverlay**: Shows cell position numbers in grid
- **TableStatusOverlay**: Shows position status with color coding

#### 3. Auto-Arrangement Engine (📋 Planned)
- Automatically places new tables in empty slots
- Expands grid when full
- Supports different placement strategies (fill gaps vs append)

## Implementation Phases

### Phase 1: Core Position Tracking ✅
**Status: Completed**

#### 1.1 TablePositionTracker Creation ✅
- Created `TablePositionTracker.swift` with comprehensive position tracking
- Tracks table positions, assigned slots, and status
- Implements position-to-grid mapping logic

#### 1.2 Integration with WindowManager ✅
- WindowManager now syncs table positions on every scan
- Grid arrangement updates tracker with slot assignments
- Position tracker maintains accurate state

#### 1.3 GridOverlay Integration ✅
- Overlay now uses actual occupied slots from tracker
- Falls back to count-based display if no positions tracked

### Phase 2: Visual Feedback System 🔄
**Status: In Progress**

#### 2.1 Status Detection
- Detect when tables are:
  - ✅ Correctly positioned (green)
  - ✅ Moved from position (yellow)
  - ✅ Newly opened (red)
  - ✅ Floating/unassigned (gray)

#### 2.2 Color-Coded Rendering
- Update GridDrawingLayer to show different colors per status
- Add visual indicators for each table state
- Implement smooth transitions between states

### Phase 3: Overlay Separation 📋
**Status: Planned**

#### 3.1 Create Independent Overlay Components
```swift
// Planned structure
OverlaySystem/
├── GridLinesOverlay.swift      // Grid boundaries only
├── TableNumberOverlay.swift    // Numbers on tables
├── CellNumberOverlay.swift     // Numbers in grid cells
└── TableStatusOverlay.swift    // Status indicators
```

#### 3.2 Separate Hotkeys
- Cmd+Shift+G: Grid lines
- Cmd+Shift+N: Table/cell numbers
- Cmd+Shift+S: Status indicators

#### 3.3 Configuration System
```json
{
  "overlay": {
    "gridLines": { "enabled": true, "color": "#00FF00" },
    "tableNumbers": { "enabled": true, "showOnTables": true },
    "cellNumbers": { "enabled": false },
    "statusIndicators": { "enabled": true }
  }
}
```

### Phase 4: Auto-Arrangement 📋
**Status: Planned**

#### 4.1 New Table Detection
- Monitor for new tables in real-time
- Queue new tables for placement

#### 4.2 Placement Strategies
```swift
enum PlacementStrategy {
    case fillGaps      // Fill first empty slot
    case append        // Add after last occupied
    case smart         // Based on table importance
}
```

#### 4.3 Grid Auto-Scaling
- Detect when grid is full
- Calculate optimal new grid size
- Smoothly transition all tables to new layout

## Technical Details

### Data Structures

#### TablePosition
```swift
struct TablePosition {
    let id: String
    let tableInfo: PokerTable
    let windowInfo: WindowInfo
    var assignedSlot: Int?
    var actualPosition: CGRect
    var expectedPosition: CGRect?
    var status: PositionStatus
    let detectedAt: Date
    var lastPositionedAt: Date?
}
```

#### PositionStatus
```swift
enum PositionStatus {
    case positioned  // Correctly placed (green)
    case moved      // User moved it (yellow)
    case new        // Just opened (red)
    case floating   // No slot assigned (gray)
    case arranging  // Being positioned (blue)
}
```

### Key Algorithms

#### Position-to-Slot Mapping
```swift
func findClosestSlot(for position: CGRect) -> Int? {
    // Calculate distance to each grid position
    // Return slot with minimum distance
}
```

#### Grid Expansion
```swift
func expandGridForNewTable() {
    // Calculate new optimal grid size
    // Rearrange existing tables
    // Place new table in appropriate slot
}
```

## Testing Checklist

### Phase 1 Testing ✅
- [x] Basic position tracking works
- [x] Slot assignments persist through scans
- [x] Overlay shows actual occupied slots
- [x] Re-arrangement updates tracker

### Phase 2 Testing 🔄
- [ ] Tables show correct color based on status
- [ ] Moved tables detected and marked yellow
- [ ] New tables marked red
- [ ] Status updates when tables return to position

### Phase 3 Testing 📋
- [ ] Each overlay layer toggles independently
- [ ] Separate hotkeys work correctly
- [ ] Settings persist between sessions
- [ ] Performance acceptable with all layers

### Phase 4 Testing 📋
- [ ] New tables auto-arrange when opened
- [ ] Grid expands appropriately when full
- [ ] Different placement strategies work
- [ ] Smooth animations during transitions

## Migration Path

1. **Current State**: Simple occupancy counter
2. **Phase 1**: Add position tracking (backward compatible)
3. **Phase 2**: Enhanced visuals (opt-in via settings)
4. **Phase 3**: Modular overlays (gradual rollout)
5. **Phase 4**: Auto-arrangement (feature flag)

## Configuration

### User Preferences
```swift
struct OverlayPreferences {
    // Visual
    var showGridLines = true
    var showTableNumbers = true
    var showCellNumbers = false
    var showStatusColors = true
    
    // Behavior
    var autoArrangeNewTables = true
    var placementStrategy = PlacementStrategy.fillGaps
    var autoExpandGrid = true
    
    // Appearance
    var gridColor = NSColor.systemGreen
    var lineWidth: CGFloat = 2.0
    var opacity: CGFloat = 0.3
}
```

## Performance Considerations

- Use CALayer for overlays (hardware accelerated)
- Cache grid calculations
- Batch position updates
- Debounce rapid table movements
- Lazy load overlay components

## Future Enhancements

1. **Smart Positioning**
   - Learn user's preferred layouts
   - Position based on table importance/activity
   
2. **Animation System**
   - Smooth transitions when arranging
   - Visual feedback during movements
   
3. **Multi-Monitor Support**
   - Track positions across screens
   - Maintain separate grids per monitor
   
4. **Preset Layouts**
   - Save/load custom arrangements
   - Quick switch between layouts

## Implementation Status

| Component | Status | Files | Notes |
|-----------|--------|-------|-------|
| TablePositionTracker | ✅ Complete | `Core/TablePositionTracker.swift` | Fully functional |
| WindowManager Integration | ✅ Complete | `Core/WindowManager/WindowManager.swift` | Syncs on scan |
| GridOverlay Update | ✅ Complete | `Services/GridOverlay/GridOverlayManager.swift` | Uses tracker data |
| Status Colors | 🔄 In Progress | - | Next priority |
| Overlay Separation | 📋 Planned | - | Phase 3 |
| Auto-Arrangement | 📋 Planned | - | Phase 4 |

## Development Log

### 2025-08-06
- Created TablePositionTracker class
- Integrated with WindowManager
- Updated GridOverlayManager to use actual positions
- Fixed compilation issues (imports, property mutability)
- Successfully built and ready for testing

## Next Steps

1. **Immediate**: Test current implementation
2. **Next**: Add color-coded status indicators
3. **Then**: Separate overlay layers
4. **Finally**: Implement auto-arrangement

## References

- Original issue discussion: Grid overlay position tracking problem
- Related files:
  - `/Core/TablePositionTracker.swift`
  - `/Core/WindowManager/WindowManager.swift`
  - `/Services/GridOverlay/GridOverlayManager.swift`
  - `/Core/WindowManagement/GridLayoutManager.swift`