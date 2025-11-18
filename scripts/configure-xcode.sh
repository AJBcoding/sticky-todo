#!/bin/bash
#
# configure-xcode.sh
#
# Verification script for StickyToDo Xcode configuration
# Checks dependencies, frameworks, and build settings
#
# Usage:
#   ./scripts/configure-xcode.sh
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more checks failed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Project paths
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$PROJECT_DIR/StickyToDo.xcodeproj"

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}StickyToDo Xcode Configuration Checker${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Function to print test result
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check if we're in the right directory
echo -e "${BLUE}[1/10] Checking project structure...${NC}"
if [ ! -d "$PROJECT_FILE" ]; then
    check_fail "StickyToDo.xcodeproj not found at $PROJECT_FILE"
    echo "Please run this script from the project root directory"
    exit 1
fi
check_pass "Found StickyToDo.xcodeproj"

if [ -d "$PROJECT_DIR/StickyToDoCore" ]; then
    check_pass "Found StickyToDoCore directory"
else
    check_fail "StickyToDoCore directory not found"
fi

if [ -d "$PROJECT_DIR/StickyToDo-SwiftUI" ]; then
    check_pass "Found StickyToDo-SwiftUI directory"
else
    check_fail "StickyToDo-SwiftUI directory not found"
fi

if [ -d "$PROJECT_DIR/StickyToDo-AppKit" ]; then
    check_pass "Found StickyToDo-AppKit directory"
else
    check_fail "StickyToDo-AppKit directory not found"
fi

echo ""

# Check Xcode installation
echo -e "${BLUE}[2/10] Checking Xcode installation...${NC}"
if ! command -v xcodebuild &> /dev/null; then
    check_fail "xcodebuild not found - Xcode may not be installed"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1 | awk '{print $2}')
XCODE_MAJOR=$(echo $XCODE_VERSION | cut -d. -f1)

check_pass "Xcode version: $XCODE_VERSION"

if [ "$XCODE_MAJOR" -lt 15 ]; then
    check_warn "Xcode 15.0+ recommended (you have $XCODE_VERSION)"
else
    check_pass "Xcode version meets requirements (15.0+)"
fi

echo ""

# Check Swift version
echo -e "${BLUE}[3/10] Checking Swift version...${NC}"
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version | head -n 1 | awk '{print $4}')
    check_pass "Swift version: $SWIFT_VERSION"
else
    check_fail "Swift compiler not found"
fi

echo ""

# Check macOS version
echo -e "${BLUE}[4/10] Checking macOS version...${NC}"
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo $MACOS_VERSION | cut -d. -f1)
MACOS_MINOR=$(echo $MACOS_VERSION | cut -d. -f2)

check_pass "macOS version: $MACOS_VERSION"

if [ "$MACOS_MAJOR" -lt 13 ]; then
    check_warn "macOS 13.0+ recommended for App Intents support (you have $MACOS_VERSION)"
else
    check_pass "macOS version meets requirements (13.0+)"
fi

echo ""

# Check for Swift Package Dependencies
echo -e "${BLUE}[5/10] Checking Swift Package Dependencies...${NC}"

# Try to resolve packages
if xcodebuild -resolvePackageDependencies -project "$PROJECT_FILE" &> /dev/null; then
    check_pass "Package dependencies resolved successfully"
else
    check_warn "Package resolution failed - you may need to add Yams"
fi

# Check for Package.resolved
if [ -f "$PROJECT_FILE/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    check_pass "Found Package.resolved"

    # Check if Yams is in resolved packages
    if grep -q "Yams" "$PROJECT_FILE/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" 2>/dev/null; then
        check_pass "Yams package is resolved"
    else
        check_fail "Yams package not found in resolved dependencies"
        echo "  → Add Yams via: File > Add Package Dependencies"
        echo "  → URL: https://github.com/jpsim/Yams.git"
    fi
else
    check_warn "Package.resolved not found - packages may not be resolved yet"
    echo "  → Run: xcodebuild -resolvePackageDependencies"
fi

echo ""

# Check for AppIntents implementation
echo -e "${BLUE}[6/10] Checking App Intents implementation...${NC}"

if [ -d "$PROJECT_DIR/StickyToDoCore/AppIntents" ]; then
    check_pass "Found AppIntents directory"

    INTENT_COUNT=$(find "$PROJECT_DIR/StickyToDoCore/AppIntents" -name "*Intent.swift" -type f | wc -l)
    check_pass "Found $INTENT_COUNT intent implementations"

    if [ -f "$PROJECT_DIR/StickyToDoCore/AppIntents/StickyToDoAppShortcuts.swift" ]; then
        check_pass "Found StickyToDoAppShortcuts.swift"
    else
        check_fail "StickyToDoAppShortcuts.swift not found"
    fi
else
    check_fail "AppIntents directory not found in StickyToDoCore"
fi

echo ""

# Check entitlements files
echo -e "${BLUE}[7/10] Checking entitlements files...${NC}"

SWIFTUI_ENTITLEMENTS="$PROJECT_DIR/StickyToDo-SwiftUI/StickyToDo.entitlements"
APPKIT_ENTITLEMENTS="$PROJECT_DIR/StickyToDo-AppKit/StickyToDo-AppKit.entitlements"

if [ -f "$SWIFTUI_ENTITLEMENTS" ]; then
    check_pass "Found StickyToDo-SwiftUI entitlements"

    if grep -q "com.apple.security.app-sandbox" "$SWIFTUI_ENTITLEMENTS"; then
        check_pass "SwiftUI: App Sandbox enabled"
    else
        check_warn "SwiftUI: App Sandbox not configured"
    fi

    if grep -q "com.apple.security.files.user-selected.read-write" "$SWIFTUI_ENTITLEMENTS"; then
        check_pass "SwiftUI: File access enabled"
    else
        check_warn "SwiftUI: File access not configured"
    fi
else
    check_fail "StickyToDo-SwiftUI entitlements file not found"
fi

if [ -f "$APPKIT_ENTITLEMENTS" ]; then
    check_pass "Found StickyToDo-AppKit entitlements"

    if grep -q "com.apple.security.app-sandbox" "$APPKIT_ENTITLEMENTS"; then
        check_pass "AppKit: App Sandbox enabled"
    else
        check_warn "AppKit: App Sandbox not configured"
    fi
else
    check_fail "StickyToDo-AppKit entitlements file not found"
fi

echo ""

# Check for framework imports
echo -e "${BLUE}[8/10] Checking framework imports...${NC}"

# Check for AppIntents imports
if grep -r "import AppIntents" "$PROJECT_DIR/StickyToDoCore/AppIntents" &> /dev/null; then
    check_pass "AppIntents framework imported"
else
    check_fail "AppIntents framework not imported in AppIntents directory"
fi

# Check for CoreSpotlight
if [ -f "$PROJECT_DIR/StickyToDoCore/Utilities/SpotlightManager.swift" ]; then
    check_pass "Found SpotlightManager.swift"

    if grep -q "import CoreSpotlight" "$PROJECT_DIR/StickyToDoCore/Utilities/SpotlightManager.swift"; then
        check_pass "CoreSpotlight framework imported"
    else
        check_warn "CoreSpotlight not imported in SpotlightManager"
    fi
else
    check_warn "SpotlightManager.swift not found"
fi

echo ""

# Check build schemes
echo -e "${BLUE}[9/10] Checking build schemes...${NC}"

SCHEMES_DIR="$PROJECT_FILE/xcshareddata/xcschemes"

if [ -d "$SCHEMES_DIR" ]; then
    SCHEME_COUNT=$(find "$SCHEMES_DIR" -name "*.xcscheme" -type f | wc -l)
    check_pass "Found $SCHEME_COUNT build schemes"

    if [ -f "$SCHEMES_DIR/StickyToDo-SwiftUI.xcscheme" ] || [ -f "$PROJECT_FILE/xcuserdata/*/xcschemes/StickyToDo-SwiftUI.xcscheme" ]; then
        check_pass "StickyToDo-SwiftUI scheme exists"
    else
        check_warn "StickyToDo-SwiftUI scheme not found"
    fi

    if [ -f "$SCHEMES_DIR/StickyToDo-AppKit.xcscheme" ] || [ -f "$PROJECT_FILE/xcuserdata/*/xcschemes/StickyToDo-AppKit.xcscheme" ]; then
        check_pass "StickyToDo-AppKit scheme exists"
    else
        check_warn "StickyToDo-AppKit scheme not found"
    fi
else
    check_warn "Shared schemes directory not found (schemes may be user-specific)"
fi

echo ""

# Try a test build
echo -e "${BLUE}[10/10] Testing build configuration...${NC}"

echo "Attempting to build StickyToDoCore framework..."
if xcodebuild -scheme StickyToDoCore -configuration Debug -quiet clean build 2>&1 | grep -q "BUILD SUCCEEDED"; then
    check_pass "StickyToDoCore builds successfully"
else
    BUILD_OUTPUT=$(xcodebuild -scheme StickyToDoCore -configuration Debug clean build 2>&1 || true)

    if echo "$BUILD_OUTPUT" | grep -q "Cannot find 'Yams'"; then
        check_fail "Build failed: Yams package not found"
        echo "  → Add Yams: File > Add Package Dependencies"
        echo "  → URL: https://github.com/jpsim/Yams.git"
    elif echo "$BUILD_OUTPUT" | grep -q "No such module 'AppIntents'"; then
        check_fail "Build failed: AppIntents framework not available"
        echo "  → Ensure deployment target is macOS 13.0+"
        echo "  → Link AppIntents framework to StickyToDoCore target"
    else
        check_warn "Build failed - check Xcode for details"
        echo "  → Run: xcodebuild -scheme StickyToDoCore -configuration Debug"
    fi
fi

echo ""
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}=================================${NC}"
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Failed:${NC}   $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open StickyToDo.xcodeproj in Xcode"
    echo "2. Add Yams package if not already added"
    echo "3. Configure Info.plist keys (see XCODE_SETUP.md)"
    echo "4. Build and run the apps"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Please address the failed checks above."
    echo "Refer to XCODE_SETUP.md for detailed instructions."
    echo ""
    exit 1
fi
