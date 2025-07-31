# PokerTiles Refactoring TODO

This document tracks cleanup and refactoring opportunities identified in the codebase.
Generated on: 2025-07-31

## Priority Cleanup Tasks

### 1. Debug Print Statements (High Priority)
**Issue**: 50+ print statements scattered throughout the codebase
**Files affected**:
- WindowManager classes: 30+ prints
- AccessibilityWindowManager: 15+ prints  
- DirectWindowMover: 20+ prints
- HotkeyManager: Multiple prints
- Various UI components

**Recommended Actions**:
- [ ] Implement a proper logging system (e.g., OSLog, SwiftyBeaver)
- [ ] Create log levels (debug, info, warning, error)
- [ ] Wrap existing prints in `#if DEBUG` blocks as interim solution
- [ ] Add build configuration to control logging verbosity

### 2. Code Duplication (Medium Priority)
**Issue**: Permission checking pattern repeated 6+ times
**Pattern**:
```swift
if !PermissionManager.hasAccessibilityPermission() {
    print("❌ No Accessibility permission - requesting...")
    PermissionManager.requestAccessibilityPermission()
    return
}
```

**Files affected**:
- GridLayoutView.swift (4 occurrences)
- QuickActionsView.swift (2 occurrences)

**Recommended Actions**:
- [ ] Create a `withAccessibilityPermission` wrapper function
- [ ] Or create a `@RequiresAccessibility` property wrapper
- [ ] Standardize permission handling across the app

### 3. TODO Implementation (High Priority)
**Location**: `HotkeyManager.swift:256`
**Task**: Implement poker action automation
```swift
// TODO: Implement poker action automation
```

**Recommended Actions**:
- [ ] Design poker action API
- [ ] Implement action execution methods
- [ ] Add safety checks and confirmations
- [ ] Test with different poker platforms

### 4. Magic Numbers and Constants (Low Priority)
**Issue**: Hardcoded values throughout codebase

**Examples**:
- Retry counts (always 3)
- Timing delays (various milliseconds)
- Window positioning offsets
- Grid layout calculations

**Recommended Actions**:
- [ ] Create `Constants.swift` file
- [ ] Define semantic constants (e.g., `maxRetryAttempts`, `windowAnimationDelay`)
- [ ] Group constants by feature area
- [ ] Document units for time-based constants

### 5. Error Handling Standardization (Medium Priority)
**Issue**: Inconsistent error handling patterns

**Current approaches**:
- Silent failures with print statements
- Boolean returns without error details
- Missing error propagation in async methods

**Recommended Actions**:
- [ ] Define custom error types for each subsystem
- [ ] Standardize on Swift's Result type or throw pattern
- [ ] Add error recovery strategies
- [ ] Implement user-facing error messages

### 6. Architecture Improvements

#### Logging System
- [ ] Choose logging framework (OSLog recommended for macOS)
- [ ] Create LogManager singleton
- [ ] Define log categories (UI, WindowManagement, Permissions, etc.)
- [ ] Add performance logging for slow operations

#### Dependency Injection
- [ ] Refactor singletons for better testability
- [ ] Consider using a DI container or factory pattern
- [ ] Make dependencies explicit in initializers

#### Code Organization
- [ ] Split large files with multiple responsibilities
- [ ] Group related functionality into modules
- [ ] Consider extracting reusable components into a framework

### 7. Build Configuration (Medium Priority)
**Issue**: Debug code not consistently wrapped

**Recommended Actions**:
- [ ] Audit all debug-only code
- [ ] Wrap in `#if DEBUG` blocks
- [ ] Create separate debug menu/interface
- [ ] Remove debug UI from release builds

### 8. Testing Infrastructure
**Current state**: Test files exist but coverage unknown

**Recommended Actions**:
- [ ] Audit existing test coverage
- [ ] Add unit tests for core functionality
- [ ] Create UI tests for critical workflows
- [ ] Set up continuous integration

### 9. Documentation
**Recommended Actions**:
- [ ] Add inline documentation for public APIs
- [ ] Create architecture decision records (ADRs)
- [ ] Document poker platform specifics
- [ ] Add setup/troubleshooting guides

### 10. Performance Optimization
**Potential areas**:
- [ ] Profile window detection performance
- [ ] Optimize screenshot/capture operations
- [ ] Review memory usage during multi-table sessions
- [ ] Optimize hotkey response time

## Implementation Priority

1. **Immediate** (affects production quality):
   - Remove/wrap print statements
   - Implement poker action automation TODO

2. **Short-term** (improves maintainability):
   - Extract duplicated permission code
   - Standardize error handling
   - Add constants file

3. **Long-term** (architectural improvements):
   - Implement proper logging system
   - Improve dependency injection
   - Enhance test coverage
   - Complete documentation

## Notes
- The codebase is generally well-structured
- These improvements focus on maintainability and production readiness
- Consider addressing high-priority items before major feature additions