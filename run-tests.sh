#!/bin/bash

# PokerTiles Test Runner Script

set -e

echo "🧪 Running PokerTiles Tests..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results directory
RESULTS_DIR="TestResults"
mkdir -p "$RESULTS_DIR"

# Function to run tests
run_tests() {
    local test_type=$1
    local test_filter=$2
    
    echo -e "\n${YELLOW}Running $test_type...${NC}"
    
    if [ -z "$test_filter" ]; then
        xcodebuild test \
            -project PokerTiles.xcodeproj \
            -scheme PokerTiles \
            -destination 'platform=macOS' \
            -resultBundlePath "$RESULTS_DIR/${test_type}.xcresult" \
            2>&1 | xcpretty
    else
        xcodebuild test \
            -project PokerTiles.xcodeproj \
            -scheme PokerTiles \
            -destination 'platform=macOS' \
            -only-testing:"$test_filter" \
            -resultBundlePath "$RESULTS_DIR/${test_type}.xcresult" \
            2>&1 | xcpretty
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $test_type passed${NC}"
    else
        echo -e "${RED}❌ $test_type failed${NC}"
        exit 1
    fi
}

# Check if xcpretty is installed
if ! command -v xcpretty &> /dev/null; then
    echo "Installing xcpretty for better output formatting..."
    gem install xcpretty
fi

# Parse command line arguments
case "$1" in
    unit)
        run_tests "Unit Tests" "PokerTilesTests"
        ;;
    ui)
        run_tests "UI Tests" "PokerTilesUITests"
        ;;
    integration)
        run_tests "Integration Tests" "PokerTilesTests/WindowManagerIntegrationTests"
        ;;
    coverage)
        echo -e "\n${YELLOW}Running tests with code coverage...${NC}"
        xcodebuild test \
            -project PokerTiles.xcodeproj \
            -scheme PokerTiles \
            -destination 'platform=macOS' \
            -enableCodeCoverage YES \
            -resultBundlePath "$RESULTS_DIR/Coverage.xcresult" \
            2>&1 | xcpretty
        
        # Generate coverage report
        xcrun xccov view --report "$RESULTS_DIR/Coverage.xcresult" > "$RESULTS_DIR/coverage.txt"
        echo -e "${GREEN}✅ Coverage report generated at $RESULTS_DIR/coverage.txt${NC}"
        ;;
    all|"")
        run_tests "All Tests" ""
        ;;
    *)
        echo "Usage: $0 [unit|ui|integration|coverage|all]"
        echo "  unit        - Run unit tests only"
        echo "  ui          - Run UI tests only"
        echo "  integration - Run integration tests only"
        echo "  coverage    - Run all tests with code coverage"
        echo "  all         - Run all tests (default)"
        exit 1
        ;;
esac

echo -e "\n${GREEN}🎉 All tests completed successfully!${NC}"
echo "Test results saved in: $RESULTS_DIR/"

# Generate summary
echo -e "\n📊 Test Summary:"
find "$RESULTS_DIR" -name "*.xcresult" -exec echo "  - {}" \;