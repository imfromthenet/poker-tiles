# PokerTiles Tests

This directory contains automated tests for the PokerTiles application.

## Test Structure

### Unit Tests
- `PokerAppTests.swift` - Tests for poker app detection and pattern matching
- `PokerTableTests.swift` - Tests for poker table type detection
- `PokerTableDetectorTests.swift` - Tests for the poker table detection service

### Integration Tests
- `WindowManagerIntegrationTests.swift` - Tests for WindowManager integration

### UI Tests
- `PokerTilesUITests.swift` - UI automation tests
- `PokerTilesUITestsLaunchTests.swift` - Launch performance tests

## Running Tests

### In Xcode
1. Open `PokerTiles.xcodeproj`
2. Create test targets:
   - File → New → Target → Unit Testing Bundle (name: PokerTilesTests)
   - File → New → Target → UI Testing Bundle (name: PokerTilesUITests)
3. Add test files to respective targets
4. Press `Cmd+U` to run all tests

### Command Line
```bash
# Run all tests
xcodebuild test -project PokerTiles.xcodeproj -scheme PokerTiles -destination 'platform=macOS'

# Run specific test suite
xcodebuild test -project PokerTiles.xcodeproj -scheme PokerTiles -only-testing:PokerTilesTests/PokerAppTests

# Run with code coverage
xcodebuild test -project PokerTiles.xcodeproj -scheme PokerTiles -enableCodeCoverage YES

# Generate test report
xcodebuild test -project PokerTiles.xcodeproj -scheme PokerTiles -resultBundlePath TestResults.xcresult
```

### CI/CD Pipeline
```yaml
# Example GitHub Actions workflow
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          xcodebuild test \
            -project PokerTiles.xcodeproj \
            -scheme PokerTiles \
            -destination 'platform=macOS' \
            -resultBundlePath TestResults.xcresult
      - name: Upload test results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: TestResults.xcresult
```

## Test Coverage

Current test coverage includes:
- ✅ Poker app detection from bundle identifiers
- ✅ Window title pattern matching
- ✅ Table type categorization (cash, tournament, sit & go, fast-fold)
- ✅ Non-table window filtering
- ✅ Regex pattern validation
- ✅ WindowManager integration
- ✅ UI element verification
- ✅ User flow testing

## Notes

- Some integration tests require screen recording permissions
- UI tests may need accessibility permissions
- Mock objects are needed for `SCWindow` testing
- Performance tests included for critical paths