# Overlay System Documentation

This guide covers the implementation of PokerTiles' overlay system, which provides HUD-style information displays over poker tables.

## Overview

The overlay system creates transparent, click-through windows that float above poker tables to display statistics, notes, and action buttons without interfering with gameplay.

## Architecture

```
┌─────────────────────────────────────────────┐
│           Overlay Manager                    │
│  • Window lifecycle management              │
│  • Position synchronization                 │
│  • Update coordination                      │
└─────────────┬───────────────────────────────┘
              │
    ┌─────────┴─────────┬─────────────────┐
    │                   │                   │
┌───▼────────┐  ┌──────▼──────┐  ┌────────▼───────┐
│   HUD      │  │  Statistics │  │    Action      │
│  Window    │  │   Window    │  │   Buttons      │
│            │  │             │  │                │
│ • Player   │  │ • VPIP/PFR  │  │ • Bet sizing   │
│   notes    │  │ • 3-bet %   │  │ • Quick fold   │
│ • Pot odds │  │ • AF/WSD    │  │ • Auto-action  │
└────────────┘  └─────────────┘  └────────────────┘
```

## NSWindow Configuration

### Creating Overlay Windows

```swift
class OverlayWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Essential overlay properties
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.ignoresMouseEvents = true
        self.hasShadow = false
    }
}
```

### Key Window Properties

1. **Style Mask**
   - `.borderless` - No title bar or window controls
   - `.nonactivatingPanel` - Doesn't steal focus

2. **Window Level**
   - `.floating` - Above normal windows
   - Alternative: `.statusBar` for always-on-top

3. **Collection Behavior**
   - `.canJoinAllSpaces` - Visible on all desktops
   - `.stationary` - Doesn't move with spaces
   - `.ignoresCycle` - Not in cmd+tab

4. **Mouse Interaction**
   - `ignoresMouseEvents = true` for click-through
   - Can be toggled for interactive elements

## HUD Components

### Base HUD View

```swift
struct HUDView: View {
    @ObservedObject var tableState: PokerTableState
    @State private var opacity: Double = 0.8
    
    var body: some View {
        VStack(spacing: 0) {
            // Statistics bar
            HStack {
                StatLabel("VPIP", value: tableState.stats.vpip)
                StatLabel("PFR", value: tableState.stats.pfr)
                StatLabel("3Bet", value: tableState.stats.threeBet)
            }
            .padding(4)
            .background(Color.black.opacity(0.7))
            
            // Player notes
            if let notes = tableState.playerNotes {
                Text(notes)
                    .font(.caption)
                    .padding(2)
                    .background(Color.blue.opacity(0.6))
            }
            
            // Pot odds calculator
            if tableState.showPotOdds {
                PotOddsView(pot: tableState.potSize, bet: tableState.currentBet)
            }
        }
        .cornerRadius(4)
        .opacity(opacity)
    }
}
```

### Statistics Display

```swift
struct StatLabel: View {
    let label: String
    let value: Double
    
    var color: Color {
        // Color-code based on value ranges
        switch value {
        case 0..<20: return .blue
        case 20..<30: return .green
        case 30..<40: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            Text(String(format: "%.0f", value))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(width: 35)
    }
}
```

## Position Synchronization

### Tracking Parent Windows

```swift
class OverlayPositionManager {
    private var windowObservers: [NSObjectProtocol] = []
    
    func attachOverlay(to parentWindow: WindowInfo, overlay: OverlayWindow) {
        // Initial positioning
        positionOverlay(overlay, relativeTo: parentWindow)
        
        // Monitor parent window moves
        let observer = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.positionOverlay(overlay, relativeTo: parentWindow)
        }
        
        windowObservers.append(observer)
    }
    
    private func positionOverlay(_ overlay: OverlayWindow, relativeTo parent: WindowInfo) {
        // Calculate position relative to poker table
        let parentFrame = parent.frame
        let overlayFrame = overlay.frame
        
        // Position at top-right of table
        let x = parentFrame.maxX - overlayFrame.width - 10
        let y = parentFrame.maxY - overlayFrame.height - 10
        
        overlay.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
```

### Handling Window Events

```swift
extension OverlayManager {
    func handleTableResize(_ notification: Notification) {
        guard let tableWindow = notification.object as? NSWindow else { return }
        
        // Find associated overlay
        if let overlay = overlays[tableWindow.windowNumber] {
            // Recalculate overlay size/position
            updateOverlayLayout(overlay, for: tableWindow)
        }
    }
    
    func handleTableClose(_ notification: Notification) {
        guard let tableWindow = notification.object as? NSWindow else { return }
        
        // Remove associated overlay
        if let overlay = overlays[tableWindow.windowNumber] {
            overlay.close()
            overlays.removeValue(forKey: tableWindow.windowNumber)
        }
    }
}
```

## Real-time Updates

### Update Pipeline

```swift
class OverlayUpdateCoordinator {
    private let updateQueue = DispatchQueue(label: "overlay.updates", qos: .userInteractive)
    private var updateTimer: Timer?
    
    func startUpdating(overlay: HUDOverlay, interval: TimeInterval = 0.1) {
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.updateQueue.async {
                // Fetch latest table state
                let tableState = self.getTableState(for: overlay.tableId)
                
                // Update on main thread
                DispatchQueue.main.async {
                    overlay.update(with: tableState)
                }
            }
        }
    }
    
    func updateOverlay(_ overlay: HUDOverlay, with state: PokerTableState) {
        // Smooth animations for value changes
        withAnimation(.easeInOut(duration: 0.2)) {
            overlay.stats = state.statistics
            overlay.potSize = state.potSize
            overlay.playerPositions = state.playerPositions
        }
    }
}
```

## Performance Considerations

### Efficient Rendering

1. **Minimize Redraws**
   ```swift
   struct OptimizedHUDView: View {
       let stats: PlayerStats
       
       var body: some View {
           // Only redraw when stats actually change
           StatisticsView(stats: stats)
               .equatable()
               .drawingGroup() // Flatten view hierarchy
       }
   }
   ```

2. **Layer Backing**
   ```swift
   overlay.contentView?.wantsLayer = true
   overlay.contentView?.layerContentsRedrawPolicy = .onSetNeedsDisplay
   ```

3. **Update Throttling**
   ```swift
   class ThrottledUpdater {
       private var pendingUpdate: (() -> Void)?
       private var lastUpdate = Date()
       private let minInterval: TimeInterval = 0.1
       
       func scheduleUpdate(_ update: @escaping () -> Void) {
           let now = Date()
           if now.timeIntervalSince(lastUpdate) >= minInterval {
               update()
               lastUpdate = now
           } else {
               pendingUpdate = update
               // Schedule for later
           }
       }
   }
   ```

## Interactive Elements

### Making Overlays Interactive

```swift
class InteractiveOverlay: OverlayWindow {
    private var isInteractive = false
    
    func enableInteraction() {
        ignoresMouseEvents = false
        isInteractive = true
        
        // Visual feedback
        contentView?.layer?.borderWidth = 1
        contentView?.layer?.borderColor = NSColor.systemBlue.cgColor
    }
    
    func disableInteraction() {
        ignoresMouseEvents = true
        isInteractive = false
        
        contentView?.layer?.borderWidth = 0
    }
    
    // Toggle with hotkey
    @objc func toggleInteraction() {
        isInteractive ? disableInteraction() : enableInteraction()
    }
}
```

### Action Buttons

```swift
struct ActionButtonsOverlay: View {
    @ObservedObject var tableController: TableController
    
    var body: some View {
        HStack(spacing: 4) {
            ActionButton("Fold", color: .red) {
                tableController.performAction(.fold)
            }
            
            ActionButton("Call", color: .green) {
                tableController.performAction(.call)
            }
            
            ActionButton("Raise", color: .blue) {
                tableController.performAction(.raise)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.8))
        .cornerRadius(6)
    }
}
```

## Multi-Monitor Support

```swift
extension OverlayManager {
    func handleScreenChange() {
        for (tableId, overlay) in overlays {
            guard let table = findTable(tableId) else { continue }
            
            // Check if table moved to different screen
            let tableScreen = NSScreen.screens.first { screen in
                screen.frame.contains(table.frame)
            }
            
            let overlayScreen = overlay.screen
            
            if tableScreen != overlayScreen {
                // Reposition overlay to correct screen
                positionOverlay(overlay, on: tableScreen, for: table)
            }
        }
    }
}
```

## Best Practices

1. **Memory Management**
   - Remove observers when overlay closes
   - Clear references to prevent retain cycles
   - Use weak references where appropriate

2. **Visual Design**
   - Keep overlays minimal and unobtrusive
   - Use consistent transparency (70-80%)
   - Ensure text remains readable

3. **User Preferences**
   - Allow opacity adjustment
   - Configurable overlay positions
   - Toggle individual components

4. **Error Handling**
   - Gracefully handle parent window disappearance
   - Recover from display configuration changes
   - Log issues for debugging

## Testing Overlays

```swift
class OverlayTestView: View {
    func testOverlayCreation() {
        let overlay = OverlayWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100))
        
        // Verify properties
        assert(overlay.ignoresMouseEvents == true)
        assert(overlay.isOpaque == false)
        assert(overlay.level == .floating)
        
        // Test positioning
        let testFrame = NSRect(x: 100, y: 100, width: 800, height: 600)
        positionOverlay(overlay, relativeTo: testFrame)
        
        // Verify position
        assert(overlay.frame.origin.x == 690) // 100 + 800 - 200 - 10
    }
}
```

## Next Steps

1. Implement base OverlayWindow class
2. Create HUD component library
3. Build position synchronization system
4. Add preference management
5. Implement performance monitoring
6. Create visual overlay editor