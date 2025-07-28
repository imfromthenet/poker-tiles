# Accessibility API Documentation

## Overview
The Accessibility API provides programmatic access to UI elements in other applications, essential for detecting and interacting with poker tables in web browsers.

## Key Classes

### AXUIElement
The fundamental type for accessing UI elements.

```swift
// Create reference to application
let app = AXUIElementCreateApplication(processID)

// Get UI element attributes
var value: CFTypeRef?
let error = AXUIElementCopyAttributeValue(element, kAXTitleAttribute, &value)

// Set attribute values
AXUIElementSetAttributeValue(element, kAXValueAttribute, newValue)
```

### AXObserver
Monitor changes to UI elements.

```swift
// Create observer
var observer: AXObserver?
let error = AXObserverCreate(processID, callback, &observer)

// Add notification
AXObserverAddNotification(observer, element, kAXValueChangedNotification, contextData)

// Run observer
CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
```

## Common Attributes

### Element Properties
- `kAXRoleAttribute` - Element type (button, text field, etc.)
- `kAXTitleAttribute` - Element title or label
- `kAXValueAttribute` - Element value or content
- `kAXPositionAttribute` - Element position (CGPoint)
- `kAXSizeAttribute` - Element size (CGSize)
- `kAXChildrenAttribute` - Child elements array

### Poker-Specific Usage
- `kAXTextAttribute` - Text content for bet amounts, pot sizes
- `kAXImageAttribute` - Card images and chip graphics
- `kAXEnabledAttribute` - Button state (fold, call, raise)

## Browser Navigation

### Chrome/Safari Structure
```swift
// Navigate to web content
app -> window -> toolbar -> address bar -> web area -> poker table elements
```

### Firefox Structure
```swift
// Firefox uses different hierarchy
app -> window -> document -> poker interface elements
```

## Error Handling

```swift
func getElementValue(_ element: AXUIElement, attribute: String) -> Any? {
    var value: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
    
    guard error == .success else {
        print("Accessibility error: \(error)")
        return nil
    }
    
    return value
}
```

## Performance Considerations

- Cache AXUIElement references when possible
- Use observers for real-time updates instead of polling
- Limit attribute queries to necessary elements only
- Handle accessibility permissions gracefully

## Common Patterns

### Finding Poker Tables
```swift
func findPokerTables(in app: AXUIElement) -> [AXUIElement] {
    var tables: [AXUIElement] = []
    
    // Search for elements with poker-specific attributes
    if let webAreas = getChildrenWithRole(app, role: kAXWebAreaRole) {
        for webArea in webAreas {
            if let pokerElements = findPokerTableElements(in: webArea) {
                tables.append(contentsOf: pokerElements)
            }
        }
    }
    
    return tables
}
```

### Monitoring Changes
```swift
func setupTableMonitoring(element: AXUIElement) {
    let observer = AXObserver(processID: pid) { (observer, element, notification, userData) in
        switch notification {
        case kAXValueChangedNotification:
            handleTableUpdate(element)
        case kAXUIElementDestroyedNotification:
            handleTableClosed(element)
        default:
            break
        }
    }
    
    observer.addNotification(element, notification: kAXValueChangedNotification)
}
```

## Required Permissions

Add to Info.plist:
```xml
<key>NSAccessibilityUsageDescription</key>
<string>PokerTiles needs accessibility access to detect and interact with poker tables in web browsers.</string>
```

Check permissions:
```swift
func checkAccessibilityPermissions() -> Bool {
    return AXIsProcessTrusted()
}
```