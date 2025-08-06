//
//  TablePositionTracker.swift
//  PokerTiles
//
//  Tracks actual positions of poker tables and their relationship to grid slots
//

import Foundation
import AppKit
import Combine
import OSLog

/// Tracks the position and status of poker tables in relation to the grid
class TablePositionTracker {
    
    // MARK: - Types
    
    /// Represents a table's position information
    struct TablePosition: Identifiable {
        let id: String
        let tableInfo: PokerTable
        let windowInfo: WindowInfo
        var assignedSlot: Int?              // Grid slot this table is assigned to
        var actualPosition: CGRect          // Current window position
        var expectedPosition: CGRect?       // Where it should be based on grid slot
        var status: PositionStatus
        let detectedAt: Date                // When this table was first detected
        var lastPositionedAt: Date?         // When it was last arranged in grid
        
        /// Calculate distance from actual position to expected position
        var positionOffset: CGFloat {
            guard let expected = expectedPosition else { return .infinity }
            let dx = actualPosition.midX - expected.midX
            let dy = actualPosition.midY - expected.midY
            return sqrt(dx * dx + dy * dy)
        }
        
        /// Check if table is within tolerance of its expected position
        func isInPosition(tolerance: CGFloat = 20) -> Bool {
            return positionOffset <= tolerance
        }
    }
    
    /// Status of a table's position
    enum PositionStatus: String, CaseIterable {
        case positioned     // In correct grid position (green)
        case moved         // Was positioned but user moved it (yellow)
        case new           // Never positioned, just opened (red)
        case floating      // Not assigned to any grid slot (gray)
        case arranging     // Currently being arranged (blue)
        
        var color: NSColor {
            switch self {
            case .positioned: return .systemGreen
            case .moved: return .systemYellow
            case .new: return .systemRed
            case .floating: return .systemGray
            case .arranging: return .systemBlue
            }
        }
        
        var description: String {
            switch self {
            case .positioned: return "Positioned"
            case .moved: return "Moved"
            case .new: return "New"
            case .floating: return "Floating"
            case .arranging: return "Arranging"
            }
        }
    }
    
    // MARK: - Properties
    
    /// All tracked table positions
    private(set) var tablePositions: [String: TablePosition] = [:]
    
    /// Grid slot assignments (slot index -> table ID)
    private(set) var slotAssignments: [Int: String] = [:]
    
    /// Current grid layout being used
    var currentGridLayout: GridLayoutManager.GridLayout = .twoByTwo
    
    /// Grid positions for current layout
    private var gridPositions: [[CGRect]] = []
    
    /// Position tolerance for considering a table "in position"
    var positionTolerance: CGFloat = 20
    
    /// Track tables that have been manually moved by user
    private var userMovedTables: Set<String> = []
    
    // MARK: - Computed Properties
    
    /// Tables that are correctly positioned
    var positionedTables: [TablePosition] {
        tablePositions.values.filter { $0.status == .positioned }
    }
    
    /// Tables that have been moved from their grid position
    var movedTables: [TablePosition] {
        tablePositions.values.filter { $0.status == .moved }
    }
    
    /// Newly opened tables not yet positioned
    var newTables: [TablePosition] {
        tablePositions.values.filter { $0.status == .new }
    }
    
    /// Tables not assigned to any grid slot
    var floatingTables: [TablePosition] {
        tablePositions.values.filter { $0.status == .floating }
    }
    
    /// Next available grid slot
    var nextAvailableSlot: Int? {
        let maxSlots = currentGridLayout.capacity
        for slot in 0..<maxSlots {
            if slotAssignments[slot] == nil {
                return slot
            }
        }
        return nil
    }
    
    /// Get occupied slots for overlay display
    var occupiedSlots: Set<Int> {
        Set(slotAssignments.keys)
    }
    
    // MARK: - Initialization
    
    init() {
        Logger.tableTracking.info("TablePositionTracker initialized")
    }
    
    // MARK: - Grid Management
    
    /// Update grid positions for current layout and screen
    func updateGridPositions(layout: GridLayoutManager.GridLayout, screen: NSScreen) {
        currentGridLayout = layout
        let layoutManager = GridLayoutManager()
        gridPositions = layoutManager.calculateGridLayout(
            for: screen,
            rows: layout.rows,
            cols: layout.columns
        )
        
        // Update expected positions for all assigned tables
        updateExpectedPositions()
    }
    
    /// Update expected positions based on current grid
    private func updateExpectedPositions() {
        for (slot, tableId) in slotAssignments {
            guard var position = tablePositions[tableId] else { continue }
            
            if let gridPos = getGridPosition(for: slot) {
                position.expectedPosition = gridPos
                
                // Update status based on actual vs expected position
                if position.isInPosition(tolerance: positionTolerance) {
                    position.status = .positioned
                } else if userMovedTables.contains(tableId) {
                    position.status = .moved
                }
                
                tablePositions[tableId] = position
            }
        }
    }
    
    /// Get grid position for a slot index
    private func getGridPosition(for slot: Int) -> CGRect? {
        guard slot >= 0 && slot < currentGridLayout.capacity else { return nil }
        
        // Grid positions are stored in reverse row order (top visual row first)
        // So we need to map slot index correctly
        let cols = currentGridLayout.columns
        let row = slot / cols
        let col = slot % cols
        
        // Since we iterate rows in reverse for top-first filling
        let gridRow = gridPositions.count - 1 - row
        
        guard gridRow >= 0 && gridRow < gridPositions.count,
              col >= 0 && col < gridPositions[gridRow].count else { return nil }
        
        return gridPositions[gridRow][col]
    }
    
    // MARK: - Table Tracking
    
    /// Update tracking for a table
    func updateTable(_ table: PokerTable, at position: CGRect) {
        let tableId = table.id
        
        if var existingPosition = tablePositions[tableId] {
            // Update existing table position
            let previousPosition = existingPosition.actualPosition
            existingPosition.actualPosition = position
            
            // Check if user moved the table
            if existingPosition.status == .positioned {
                let moved = !existingPosition.isInPosition(tolerance: positionTolerance)
                if moved {
                    existingPosition.status = .moved
                    userMovedTables.insert(tableId)
                    Logger.tableTracking.info("Table \(tableId) was moved by user")
                }
            }
            
            tablePositions[tableId] = existingPosition
        } else {
            // New table detected
            let newPosition = TablePosition(
                id: tableId,
                tableInfo: table,
                windowInfo: table.windowInfo,
                assignedSlot: nil,
                actualPosition: position,
                expectedPosition: nil,
                status: .new,
                detectedAt: Date(),
                lastPositionedAt: nil
            )
            
            tablePositions[tableId] = newPosition
            Logger.tableTracking.info("New table detected: \(tableId)")
        }
    }
    
    /// Remove a table from tracking
    func removeTable(_ tableId: String) {
        if let position = tablePositions[tableId] {
            // Clear slot assignment
            if let slot = position.assignedSlot {
                slotAssignments[slot] = nil
            }
            
            tablePositions.removeValue(forKey: tableId)
            userMovedTables.remove(tableId)
            
            Logger.tableTracking.info("Table removed from tracking: \(tableId)")
        }
    }
    
    // MARK: - Slot Assignment
    
    /// Assign a table to a grid slot
    func assignTableToSlot(_ tableId: String, slot: Int) {
        guard var position = tablePositions[tableId] else { return }
        
        // Clear previous slot assignment
        if let oldSlot = position.assignedSlot {
            slotAssignments[oldSlot] = nil
        }
        
        // Clear any existing table in target slot
        if let existingTableId = slotAssignments[slot] {
            if var existingPosition = tablePositions[existingTableId] {
                existingPosition.assignedSlot = nil
                existingPosition.status = .floating
                tablePositions[existingTableId] = existingPosition
            }
        }
        
        // Assign new slot
        position.assignedSlot = slot
        position.expectedPosition = getGridPosition(for: slot)
        position.lastPositionedAt = Date()
        
        // Update status
        if position.isInPosition(tolerance: positionTolerance) {
            position.status = .positioned
        } else {
            position.status = .arranging
        }
        
        slotAssignments[slot] = tableId
        tablePositions[tableId] = position
        
        Logger.tableTracking.info("Table \(tableId) assigned to slot \(slot)")
    }
    
    /// Clear all slot assignments
    func clearAllAssignments() {
        slotAssignments.removeAll()
        
        for (id, var position) in tablePositions {
            position.assignedSlot = nil
            position.expectedPosition = nil
            position.status = .floating
            tablePositions[id] = position
        }
        
        userMovedTables.removeAll()
    }
    
    // MARK: - Position Mapping
    
    /// Find the closest grid slot for a table position
    func findClosestSlot(for position: CGRect) -> Int? {
        var closestSlot: Int?
        var minDistance: CGFloat = .infinity
        
        for slot in 0..<currentGridLayout.capacity {
            guard let gridPos = getGridPosition(for: slot) else { continue }
            
            let dx = position.midX - gridPos.midX
            let dy = position.midY - gridPos.midY
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < minDistance {
                minDistance = distance
                closestSlot = slot
            }
        }
        
        return closestSlot
    }
    
    /// Check if a position is within any grid slot
    func isPositionInGrid(_ position: CGRect, tolerance: CGFloat? = nil) -> Bool {
        let tol = tolerance ?? positionTolerance
        
        for slot in 0..<currentGridLayout.capacity {
            guard let gridPos = getGridPosition(for: slot) else { continue }
            
            let dx = position.midX - gridPos.midX
            let dy = position.midY - gridPos.midY
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance <= tol {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Batch Updates
    
    /// Update all table positions after arrangement
    func markTablesAsPositioned(_ tableIds: [String]) {
        for tableId in tableIds {
            guard var position = tablePositions[tableId] else { continue }
            
            position.status = .positioned
            position.lastPositionedAt = Date()
            tablePositions[tableId] = position
            userMovedTables.remove(tableId)
        }
    }
    
    /// Reset moved status for tables that are back in position
    func checkAndResetMovedTables() {
        for tableId in userMovedTables {
            guard var position = tablePositions[tableId] else { continue }
            
            if position.isInPosition(tolerance: positionTolerance) {
                position.status = .positioned
                tablePositions[tableId] = position
                userMovedTables.remove(tableId)
                
                Logger.tableTracking.info("Table \(tableId) returned to position")
            }
        }
    }
    
    // MARK: - Sync with Window Manager
    
    /// Sync with current poker tables from WindowManager
    func syncWithTables(_ tables: [PokerTable], screen: NSScreen) {
        // Update grid positions for current screen
        updateGridPositions(layout: currentGridLayout, screen: screen)
        
        // Track current table IDs
        let currentTableIds = Set(tables.map { $0.id })
        
        // Remove tables that no longer exist
        let trackedIds = Set(tablePositions.keys)
        for removedId in trackedIds.subtracting(currentTableIds) {
            removeTable(removedId)
        }
        
        // Update or add current tables
        for table in tables {
            updateTable(table, at: table.windowInfo.bounds)
        }
        
        // Check if any moved tables are back in position
        checkAndResetMovedTables()
    }
}

// MARK: - Logging

extension Logger {
    static let tableTracking = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.pokertiles",
        category: "TableTracking"
    )
}