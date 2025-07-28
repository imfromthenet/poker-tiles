# Multi-Table Coordination Documentation

This guide covers the implementation of multi-table management in PokerTiles, including table prioritization, action queuing, and performance optimization for handling numerous poker tables simultaneously.

## Overview

Multi-table coordination ensures smooth gameplay across multiple poker tables by intelligently managing focus, prioritizing tables requiring action, and optimizing system resources.

## Architecture

```
┌─────────────────────────────────────────────────┐
│          Multi-Table Coordinator                 │
│  • Table registry & lifecycle                   │
│  • Priority calculation                         │
│  • Resource allocation                          │
└────────────────┬────────────────────────────────┘
                 │
    ┌────────────┴───────────┬──────────────────┐
    │                        │                   │
┌───▼──────────┐  ┌─────────▼────────┐  ┌──────▼──────┐
│Table Priority│  │  Action Queue    │  │   Focus     │
│  Manager     │  │   Manager        │  │  Manager    │
│              │  │                  │  │             │
│ • Urgency    │  │ • FIFO/Priority  │  │ • Smart     │
│ • Time left  │  │ • Batch actions  │  │   cycling   │
│ • Pot size   │  │ • Deduplication  │  │ • History   │
└──────────────┘  └──────────────────┘  └─────────────┘
```

## Table Registry

### Table Model

```swift
class PokerTableInstance {
    let id: UUID
    let windowInfo: WindowInfo
    var gameState: GameState
    var priority: TablePriority
    var lastAction: Date?
    var statistics: TableStatistics
    
    // Timing
    var timeBank: TimeInterval?
    var actionDeadline: Date?
    
    // State
    var isAwaitingAction: Bool = false
    var isFocused: Bool = false
    var isMinimized: Bool = false
    
    // Metadata
    let siteName: PokerSite
    let tableType: TableType // Cash, Tournament, SitNGo
    let stakes: Stakes?
    let seats: Int
}

struct TablePriority: Comparable {
    let urgency: Double      // 0.0 - 1.0
    let potSize: Double      // In BB
    let timeRemaining: TimeInterval?
    let isAllIn: Bool
    
    static func < (lhs: TablePriority, rhs: TablePriority) -> Bool {
        // All-in decisions take precedence
        if lhs.isAllIn != rhs.isAllIn {
            return rhs.isAllIn
        }
        
        // Then time pressure
        if let lhsTime = lhs.timeRemaining,
           let rhsTime = rhs.timeRemaining {
            if lhsTime < 5 || rhsTime < 5 {
                return lhsTime < rhsTime
            }
        }
        
        // Then pot size
        if abs(lhs.potSize - rhs.potSize) > 10 {
            return lhs.potSize > rhs.potSize
        }
        
        // Finally general urgency
        return lhs.urgency > rhs.urgency
    }
}
```

### Table Coordinator

```swift
class MultiTableCoordinator {
    static let shared = MultiTableCoordinator()
    
    private var activeTables: [UUID: PokerTableInstance] = [:]
    private let tableQueue = DispatchQueue(label: "pokertiles.tables", attributes: .concurrent)
    private var updateTimer: Timer?
    
    func register(_ table: PokerTableInstance) {
        tableQueue.async(flags: .barrier) {
            self.activeTables[table.id] = table
        }
        
        // Start monitoring if first table
        if activeTables.count == 1 {
            startMonitoring()
        }
    }
    
    func unregister(_ tableId: UUID) {
        tableQueue.async(flags: .barrier) {
            self.activeTables.removeValue(forKey: tableId)
        }
        
        // Stop monitoring if no tables
        if activeTables.isEmpty {
            stopMonitoring()
        }
    }
    
    private func startMonitoring() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateAllTables()
        }
    }
}
```

## Priority Management

### Priority Calculator

```swift
class TablePriorityCalculator {
    struct PriorityWeights {
        let timeWeight: Double = 0.4
        let potSizeWeight: Double = 0.3
        let tournamentWeight: Double = 0.2
        let historyWeight: Double = 0.1
    }
    
    private let weights = PriorityWeights()
    
    func calculatePriority(for table: PokerTableInstance) -> TablePriority {
        var urgency = 0.0
        
        // Time component
        if let deadline = table.actionDeadline {
            let timeRemaining = deadline.timeIntervalSinceNow
            if timeRemaining < 5 {
                urgency += weights.timeWeight * 1.0
            } else if timeRemaining < 10 {
                urgency += weights.timeWeight * 0.7
            } else if timeRemaining < 20 {
                urgency += weights.timeWeight * 0.4
            }
        }
        
        // Pot size component (normalized to big blinds)
        let potInBB = table.gameState.potSize / table.gameState.bigBlind
        if potInBB > 100 {
            urgency += weights.potSizeWeight * 1.0
        } else if potInBB > 50 {
            urgency += weights.potSizeWeight * 0.7
        } else if potInBB > 20 {
            urgency += weights.potSizeWeight * 0.4
        }
        
        // Tournament considerations
        if table.tableType == .tournament {
            let icmPressure = calculateICMPressure(table)
            urgency += weights.tournamentWeight * icmPressure
        }
        
        // Recent action history
        if let lastAction = table.lastAction {
            let timeSinceAction = Date().timeIntervalSince(lastAction)
            if timeSinceAction < 60 {
                // Penalize recently acted tables
                urgency -= weights.historyWeight * 0.5
            }
        }
        
        return TablePriority(
            urgency: min(1.0, max(0.0, urgency)),
            potSize: potInBB,
            timeRemaining: table.actionDeadline?.timeIntervalSinceNow,
            isAllIn: table.gameState.isAllInDecision
        )
    }
    
    private func calculateICMPressure(_ table: PokerTableInstance) -> Double {
        // Simplified ICM pressure calculation
        guard table.tableType == .tournament else { return 0 }
        
        let stackInBB = table.gameState.heroStack / table.gameState.bigBlind
        let avgStack = table.gameState.averageStack / table.gameState.bigBlind
        
        // More pressure when short stacked
        if stackInBB < 10 {
            return 1.0
        } else if stackInBB < 20 {
            return 0.7
        } else if stackInBB < avgStack {
            return 0.4
        }
        
        return 0.2
    }
}
```

### Priority Queue

```swift
class TablePriorityQueue {
    private var tables: [PokerTableInstance] = []
    private let queue = DispatchQueue(label: "priority.queue", attributes: .concurrent)
    
    func enqueue(_ table: PokerTableInstance) {
        queue.async(flags: .barrier) {
            self.tables.append(table)
            self.sort()
        }
    }
    
    func dequeue() -> PokerTableInstance? {
        queue.sync {
            tables.isEmpty ? nil : tables.removeFirst()
        }
    }
    
    func peek() -> PokerTableInstance? {
        queue.sync {
            tables.first
        }
    }
    
    private func sort() {
        tables.sort { $0.priority > $1.priority }
    }
    
    func updatePriorities() {
        queue.async(flags: .barrier) {
            let calculator = TablePriorityCalculator()
            for table in self.tables {
                table.priority = calculator.calculatePriority(for: table)
            }
            self.sort()
        }
    }
}
```

## Action Queue Management

### Action Types

```swift
enum TableAction {
    case focus
    case performPokerAction(PokerAction)
    case minimize
    case restore
    case close
    case snapshot
    case updateHUD
}

struct QueuedAction {
    let id: UUID = UUID()
    let tableId: UUID
    let action: TableAction
    let priority: ActionPriority
    let timestamp: Date = Date()
    
    enum ActionPriority: Int, Comparable {
        case critical = 3    // Time-critical actions
        case high = 2        // User-initiated actions
        case normal = 1      // Regular updates
        case low = 0         // Background tasks
        
        static func < (lhs: ActionPriority, rhs: ActionPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
```

### Action Queue

```swift
class MultiTableActionQueue {
    private var queue: [QueuedAction] = []
    private let queueLock = NSLock()
    private let processor = ActionProcessor()
    private var isProcessing = false
    
    func enqueue(_ action: QueuedAction) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        // Check for duplicate actions
        let isDuplicate = queue.contains { existing in
            existing.tableId == action.tableId &&
            existing.action.isDuplicate(of: action.action)
        }
        
        if !isDuplicate {
            queue.append(action)
            queue.sort { $0.priority > $1.priority }
        }
        
        processNextIfNeeded()
    }
    
    private func processNextIfNeeded() {
        guard !isProcessing, !queue.isEmpty else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.processNext()
        }
    }
    
    private func processNext() {
        queueLock.lock()
        guard let action = queue.first else {
            isProcessing = false
            queueLock.unlock()
            return
        }
        queue.removeFirst()
        queueLock.unlock()
        
        // Process action
        processor.process(action) { [weak self] in
            self?.isProcessing = false
            self?.processNextIfNeeded()
        }
    }
}
```

## Focus Management

### Smart Focus System

```swift
class TableFocusManager {
    private var focusHistory: [UUID] = []
    private var currentFocus: UUID?
    private let maxHistory = 10
    
    func focusTable(_ tableId: UUID) {
        // Update history
        if let current = currentFocus {
            focusHistory.append(current)
            if focusHistory.count > maxHistory {
                focusHistory.removeFirst()
            }
        }
        
        currentFocus = tableId
        
        // Perform focus
        if let table = MultiTableCoordinator.shared.table(for: tableId) {
            performFocus(on: table)
        }
    }
    
    func focusNextPriorityTable() {
        let tables = MultiTableCoordinator.shared.getActionRequiredTables()
            .sorted { $0.priority > $1.priority }
        
        if let nextTable = tables.first {
            focusTable(nextTable.id)
        }
    }
    
    func cycleFocus(forward: Bool = true) {
        let tables = MultiTableCoordinator.shared.getAllTables()
        guard !tables.isEmpty else { return }
        
        guard let current = currentFocus,
              let currentIndex = tables.firstIndex(where: { $0.id == current }) else {
            // No current focus, focus first table
            if let first = tables.first {
                focusTable(first.id)
            }
            return
        }
        
        let nextIndex = forward 
            ? (currentIndex + 1) % tables.count
            : (currentIndex - 1 + tables.count) % tables.count
        
        focusTable(tables[nextIndex].id)
    }
    
    private func performFocus(on table: PokerTableInstance) {
        // Bring window to front
        table.windowInfo.window?.makeKeyAndOrderFront(nil)
        
        // Update focused state
        MultiTableCoordinator.shared.getAllTables().forEach { t in
            t.isFocused = (t.id == table.id)
        }
        
        // Update HUD
        NotificationCenter.default.post(
            name: .tableFocusChanged,
            object: nil,
            userInfo: ["tableId": table.id]
        )
    }
}
```

## Performance Optimization

### Update Throttling

```swift
class TableUpdateThrottler {
    private var updateTimers: [UUID: Timer] = [:]
    private let minimumInterval: TimeInterval = 0.1
    private let backgroundInterval: TimeInterval = 1.0
    
    func scheduleUpdate(for table: PokerTableInstance) {
        let interval = table.isAwaitingAction ? minimumInterval : backgroundInterval
        
        // Cancel existing timer
        updateTimers[table.id]?.invalidate()
        
        // Schedule new update
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.performUpdate(for: table)
        }
        
        updateTimers[table.id] = timer
    }
    
    private func performUpdate(for table: PokerTableInstance) {
        // Update table state
        TableStateUpdater.update(table)
        
        // Reschedule if still active
        if table.isActive {
            scheduleUpdate(for: table)
        } else {
            updateTimers[table.id] = nil
        }
    }
}
```

### Resource Management

```swift
class MultiTableResourceManager {
    private let maxConcurrentCaptures = 4
    private let captureQueue = OperationQueue()
    
    init() {
        captureQueue.maxConcurrentOperationCount = maxConcurrentCaptures
        captureQueue.qualityOfService = .userInteractive
    }
    
    func optimizeForTableCount(_ count: Int) {
        switch count {
        case 0...4:
            // High quality mode
            captureQueue.maxConcurrentOperationCount = 4
            ScreenCaptureManager.shared.captureQuality = .high
            
        case 5...8:
            // Balanced mode
            captureQueue.maxConcurrentOperationCount = 3
            ScreenCaptureManager.shared.captureQuality = .medium
            
        case 9...12:
            // Performance mode
            captureQueue.maxConcurrentOperationCount = 2
            ScreenCaptureManager.shared.captureQuality = .low
            
        default:
            // Maximum performance
            captureQueue.maxConcurrentOperationCount = 1
            ScreenCaptureManager.shared.captureQuality = .minimum
        }
    }
    
    func scheduleCapture(for table: PokerTableInstance) {
        let operation = CaptureOperation(table: table)
        
        // Higher priority for tables awaiting action
        operation.queuePriority = table.isAwaitingAction ? .high : .normal
        
        captureQueue.addOperation(operation)
    }
}
```

## Table Grouping

### Group Management

```swift
class TableGroupManager {
    enum GroupingStrategy {
        case bySite
        case byStakes
        case byTableType
        case byCustomTag
    }
    
    func groupTables(_ tables: [PokerTableInstance], by strategy: GroupingStrategy) -> [TableGroup] {
        switch strategy {
        case .bySite:
            return groupBySite(tables)
        case .byStakes:
            return groupByStakes(tables)
        case .byTableType:
            return groupByTableType(tables)
        case .byCustomTag:
            return groupByCustomTag(tables)
        }
    }
    
    private func groupBySite(_ tables: [PokerTableInstance]) -> [TableGroup] {
        let grouped = Dictionary(grouping: tables) { $0.siteName }
        return grouped.map { site, tables in
            TableGroup(
                name: site.rawValue,
                tables: tables,
                color: site.themeColor
            )
        }
    }
    
    func applyActionToGroup(_ action: GroupAction, group: TableGroup) {
        switch action {
        case .tileWindows:
            WindowArranger.tile(windows: group.tables.map { $0.windowInfo })
        case .cascade:
            WindowArranger.cascade(windows: group.tables.map { $0.windowInfo })
        case .minimize:
            group.tables.forEach { $0.minimize() }
        case .close:
            group.tables.forEach { $0.close() }
        }
    }
}
```

## Hotkey Integration

```swift
extension MultiTableCoordinator {
    func setupHotkeys() {
        HotkeyManager.shared.register(
            Hotkey(keyCode: .tab, modifiers: .control, action: .custom { [weak self] in
                self?.focusManager.focusNextPriorityTable()
            })
        )
        
        HotkeyManager.shared.register(
            Hotkey(keyCode: .tab, modifiers: [.control, .shift], action: .custom { [weak self] in
                self?.focusManager.cycleFocus(forward: false)
            })
        )
        
        // Fold all tables
        HotkeyManager.shared.register(
            Hotkey(keyCode: .f, modifiers: [.command, .shift], action: .custom { [weak self] in
                self?.performActionOnAllTables(.fold)
            })
        )
    }
    
    private func performActionOnAllTables(_ action: PokerAction) {
        let actionTables = getActionRequiredTables()
        
        for table in actionTables {
            actionQueue.enqueue(QueuedAction(
                tableId: table.id,
                action: .performPokerAction(action),
                priority: .high
            ))
        }
    }
}
```

## Monitoring & Analytics

```swift
class MultiTableAnalytics {
    struct SessionStats {
        var tablesPlayed: Int = 0
        var peakConcurrentTables: Int = 0
        var totalHands: Int = 0
        var actionTime: TimeInterval = 0
        var timeouts: Int = 0
    }
    
    private var sessionStats = SessionStats()
    private var tableStats: [UUID: TableStatistics] = [:]
    
    func recordTableAdded() {
        sessionStats.tablesPlayed += 1
        
        let current = MultiTableCoordinator.shared.getAllTables().count
        sessionStats.peakConcurrentTables = max(sessionStats.peakConcurrentTables, current)
    }
    
    func recordAction(tableId: UUID, duration: TimeInterval) {
        sessionStats.actionTime += duration
        sessionStats.totalHands += 1
        
        tableStats[tableId, default: TableStatistics()].recordAction(duration: duration)
    }
    
    func generateReport() -> SessionReport {
        SessionReport(
            stats: sessionStats,
            averageActionTime: sessionStats.actionTime / Double(sessionStats.totalHands),
            tablesPerHour: Double(sessionStats.tablesPlayed) / sessionDuration.hours,
            efficiency: calculateEfficiency()
        )
    }
}
```

## Best Practices

1. **Priority Tuning**
   - Adjust weights based on player preferences
   - Consider game type (cash vs tournament)
   - Account for player skill level

2. **Performance Scaling**
   - Dynamically adjust quality based on table count
   - Prioritize active tables for resources
   - Use lazy loading for inactive tables

3. **User Experience**
   - Provide visual indicators for priority
   - Show queue status in HUD
   - Allow manual priority override

4. **Error Recovery**
   - Handle table disconnections gracefully
   - Maintain state across reconnections
   - Log issues for debugging

## Testing

```swift
class MultiTableTests {
    func testPriorityCalculation() {
        let table1 = createMockTable(timeRemaining: 3, potSize: 100)
        let table2 = createMockTable(timeRemaining: 30, potSize: 10)
        
        let calc = TablePriorityCalculator()
        let priority1 = calc.calculatePriority(for: table1)
        let priority2 = calc.calculatePriority(for: table2)
        
        XCTAssertGreaterThan(priority1.urgency, priority2.urgency)
    }
    
    func testFocusCycling() {
        let tables = (0..<5).map { _ in createMockTable() }
        let manager = TableFocusManager()
        
        // Test forward cycling
        manager.focusTable(tables[0].id)
        manager.cycleFocus(forward: true)
        XCTAssertEqual(manager.currentFocus, tables[1].id)
        
        // Test wrap around
        manager.focusTable(tables[4].id)
        manager.cycleFocus(forward: true)
        XCTAssertEqual(manager.currentFocus, tables[0].id)
    }
}
```