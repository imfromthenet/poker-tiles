# Poker Detection Implementation Guide

## Overview
This guide covers the implementation of poker table detection, combining Accessibility API and Vision framework for robust table recognition.

## Detection Strategy

### Multi-Modal Approach
1. **Accessibility API**: Structure and text content
2. **Vision Framework**: Visual elements and layout
3. **ScreenCaptureKit**: Real-time visual updates
4. **Heuristic Analysis**: Game state inference

## Table Detection Pipeline

### 1. Browser Window Discovery
```swift
class PokerTableDiscovery {
    func findPokerTables() async -> [PokerTable] {
        var tables: [PokerTable] = []
        
        // Get all browser windows
        let windows = await findBrowserWindows()
        
        for window in windows {
            if let table = await analyzeWindow(window) {
                tables.append(table)
            }
        }
        
        return tables
    }
    
    private func findBrowserWindows() async -> [BrowserWindow] {
        let content = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        return content?.windows.compactMap { window in
            guard let app = window.owningApplication,
                  isBrowserApp(app.bundleIdentifier) else { return nil }
            
            return BrowserWindow(scWindow: window, browserType: getBrowserType(app.bundleIdentifier))
        } ?? []
    }
}
```

### 2. Accessibility Analysis
```swift
class PokerAccessibilityAnalyzer {
    func analyzePokerContent(_ window: BrowserWindow) -> PokerContentAnalysis? {
        let axApp = AXUIElementCreateApplication(window.processID)
        
        // Navigate to web content
        guard let webArea = findWebArea(axApp) else { return nil }
        
        var analysis = PokerContentAnalysis()
        
        // Detect poker-specific elements
        analysis.gameElements = findGameElements(webArea)
        analysis.actionButtons = findActionButtons(webArea)
        analysis.playerElements = findPlayerElements(webArea)
        analysis.potElement = findPotElement(webArea)
        
        return analysis
    }
    
    private func findGameElements(_ webArea: AXUIElement) -> [GameElement] {
        var elements: [GameElement] = []
        
        // Look for poker-specific text patterns
        let textElements = getAllTextElements(webArea)
        
        for element in textElements {
            if let text = getElementText(element) {
                if let gameElement = parsePokerElement(text, element: element) {
                    elements.append(gameElement)
                }
            }
        }
        
        return elements
    }
}
```

### 3. Visual Analysis
```swift
class PokerVisualAnalyzer {
    func analyzeTableVisuals(_ image: CGImage) -> PokerVisualAnalysis {
        var analysis = PokerVisualAnalysis()
        
        // Detect table layout
        analysis.tableLayout = detectTableLayout(image)
        
        // Find cards
        analysis.cards = detectCards(image)
        
        // Detect chips and betting areas
        analysis.chips = detectChips(image)
        
        // Analyze action buttons
        analysis.actionButtons = detectActionButtons(image)
        
        return analysis
    }
    
    private func detectTableLayout(_ image: CGImage) -> TableLayout? {
        // Look for circular or oval table shapes
        let request = VNDetectRectanglesRequest { request, error in
            // Process detected rectangles
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([request])
        
        return analyzeTableGeometry(image)
    }
}
```

## Site-Specific Detection

### PokerStars Detection
```swift
class PokerStarsDetector: SiteSpecificDetector {
    override func detectTable(in window: BrowserWindow) -> PokerTable? {
        // PokerStars specific patterns
        let indicators = [
            "PokerStars",
            "Lobby",
            "Tournament",
            "Cash Game"
        ]
        
        guard containsPokerStarsIndicators(window, indicators) else { return nil }
        
        return PokerTable(
            site: .pokerStars,
            window: window,
            gameType: detectGameType(window),
            stakes: detectStakes(window)
        )
    }
    
    private func detectGameType(_ window: BrowserWindow) -> GameType {
        // Analyze title and content for game type
        if window.title.contains("Tournament") {
            return .tournament
        } else if window.title.contains("Cash") {
            return .cash
        }
        return .unknown
    }
}
```

### 888poker Detection
```swift
class Poker888Detector: SiteSpecificDetector {
    override func detectTable(in window: BrowserWindow) -> PokerTable? {
        let patterns = [
            "888poker",
            "Poker Table",
            "Blinds:"
        ]
        
        return analyzeWith888Patterns(window, patterns)
    }
}
```

## Game State Detection

### Hand Phase Recognition
```swift
class HandPhaseDetector {
    func detectCurrentPhase(_ table: PokerTable) -> HandPhase {
        let visual = table.visualAnalysis
        let accessibility = table.accessibilityAnalysis
        
        // Analyze board cards
        let boardCards = visual.cards.filter { $0.location == .board }
        
        switch boardCards.count {
        case 0:
            return .preflop
        case 3:
            return .flop
        case 4:
            return .turn
        case 5:
            return .river
        default:
            return .unknown
        }
    }
}
```

### Action Detection
```swift
class ActionDetector {
    func detectAvailableActions(_ table: PokerTable) -> [PokerAction] {
        var actions: [PokerAction] = []
        
        // Check accessibility elements
        for button in table.accessibilityAnalysis.actionButtons {
            if let action = parseActionButton(button) {
                actions.append(action)
            }
        }
        
        // Verify with visual analysis
        let visualActions = table.visualAnalysis.actionButtons
        return correlateActions(actions, visualActions)
    }
    
    private func parseActionButton(_ button: AXUIElement) -> PokerAction? {
        guard let title = getElementText(button),
              let enabled = getElementEnabled(button) else { return nil }
        
        let actionType = PokerActionType.from(title)
        let bounds = getElementBounds(button)
        
        return PokerAction(
            type: actionType,
            enabled: enabled,
            bounds: bounds,
            element: button
        )
    }
}
```

## Performance Optimization

### Selective Processing
```swift
class PerformanceOptimizer {
    private var lastProcessedFrame: CFTimeInterval = 0
    private let minFrameInterval: CFTimeInterval = 1.0 / 30.0  // 30 FPS max
    
    func shouldProcessFrame() -> Bool {
        let currentTime = CACurrentMediaTime()
        
        guard currentTime - lastProcessedFrame >= minFrameInterval else {
            return false
        }
        
        lastProcessedFrame = currentTime
        return true
    }
    
    func optimizeForGameState(_ gameState: GameState) {
        switch gameState {
        case .waitingForAction:
            // High frequency processing
            setProcessingInterval(1.0 / 60.0)
        case .betweenHands:
            // Low frequency processing
            setProcessingInterval(1.0 / 10.0)
        case .inactive:
            // Minimal processing
            setProcessingInterval(1.0 / 2.0)
        }
    }
}
```

### Caching Strategy
```swift
class DetectionCache {
    private var tableCache: [WindowID: PokerTable] = [:]
    private var elementCache: [ElementID: AXUIElement] = [:]
    
    func getCachedTable(_ windowID: WindowID) -> PokerTable? {
        return tableCache[windowID]
    }
    
    func cacheTable(_ table: PokerTable, windowID: WindowID) {
        tableCache[windowID] = table
    }
    
    func invalidateTable(_ windowID: WindowID) {
        tableCache.removeValue(forKey: windowID)
    }
}
```

## Error Handling

### Graceful Degradation
```swift
class RobustDetector {
    func detectTable(_ window: BrowserWindow) -> PokerTable? {
        var table = PokerTable(window: window)
        
        // Try accessibility first
        if let axAnalysis = tryAccessibilityAnalysis(window) {
            table.accessibilityAnalysis = axAnalysis
        }
        
        // Fall back to visual analysis
        if table.accessibilityAnalysis == nil {
            table.visualAnalysis = tryVisualAnalysis(window)
        }
        
        // Combine both if available
        if table.accessibilityAnalysis != nil && table.visualAnalysis == nil {
            table.visualAnalysis = tryVisualAnalysis(window)
        }
        
        return table.isValid ? table : nil
    }
}
```

## Testing and Validation

### Detection Accuracy Testing
```swift
class DetectionTester {
    func testDetectionAccuracy() {
        let testCases = loadTestCases()
        var correct = 0
        
        for testCase in testCases {
            let detected = detectTable(testCase.window)
            if validateDetection(detected, expected: testCase.expected) {
                correct += 1
            }
        }
        
        let accuracy = Double(correct) / Double(testCases.count)
        print("Detection accuracy: \(accuracy * 100)%")
    }
}
```

### Performance Benchmarking
```swift
class PerformanceBenchmark {
    func benchmarkDetectionSpeed() {
        let iterations = 100
        let startTime = CACurrentMediaTime()
        
        for _ in 0..<iterations {
            _ = detectAllTables()
        }
        
        let endTime = CACurrentMediaTime()
        let avgTime = (endTime - startTime) / Double(iterations)
        
        print("Average detection time: \(avgTime * 1000)ms")
    }
}
```