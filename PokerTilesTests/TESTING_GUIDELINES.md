# Testing Guidelines for PokerTiles

## Swift Testing Framework

As of January 2025, we are using **Swift Testing** for all new tests, not XCTest.

### Key Differences:

1. **Import Statement**
   ```swift
   import Testing  // NOT import XCTest
   ```

2. **Test Structure**
   ```swift
   @Suite struct MyTests {  // NOT class MyTests: XCTestCase
       @Test func myTest() {
           // test code
       }
   }
   ```

3. **Assertions**
   ```swift
   #expect(value == expected)  // NOT XCTAssertEqual(value, expected)
   #require(optional != nil)   // NOT XCTUnwrap(optional)
   ```

4. **Setup/Teardown**
   ```swift
   init() throws {
       // setup code - NOT override func setUp()
   }
   
   deinit {
       // teardown code - NOT override func tearDown()
   }
   ```

### Migration Status

Currently, all existing tests use XCTest. These will be migrated incrementally as we modify them. All new tests should use Swift Testing.

### Documentation

See `.claude/docs/swift-testing-playbook.md` for comprehensive Swift Testing documentation.