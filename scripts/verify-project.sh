#!/bin/bash

#
# verify-project.sh
# StickyToDo Project Verification Script
#
# Verifies that the Xcode project is correctly configured and ready to build
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Symbols
CHECK_MARK="✓"
CROSS_MARK="✗"
WARNING="⚠"

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}${CHECK_MARK}${NC} $1"
    ((PASSED++))
}

print_error() {
    echo -e "${RED}${CROSS_MARK}${NC} $1"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}${WARNING}${NC} $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "  $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Main verification

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     StickyToDo Project Verification Tool      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# 1. System Requirements
print_header "1. Checking System Requirements"

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
MACOS_MINOR=$(echo "$MACOS_VERSION" | cut -d. -f2)

if [ "$MACOS_MAJOR" -ge 13 ]; then
    print_success "macOS version: $MACOS_VERSION (meets requirement: 13.0+)"
elif [ "$MACOS_MAJOR" -eq 13 ] && [ "$MACOS_MINOR" -ge 0 ]; then
    print_success "macOS version: $MACOS_VERSION (meets requirement: 13.0+)"
else
    print_error "macOS version: $MACOS_VERSION (requires 13.0 or later)"
fi

# Check Xcode
if check_command xcodebuild; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    print_success "Xcode found: $XCODE_VERSION"

    # Check Xcode version number
    XCODE_VER_NUM=$(xcodebuild -version | grep "Xcode" | awk '{print $2}' | cut -d. -f1)
    if [ "$XCODE_VER_NUM" -ge 15 ]; then
        print_success "Xcode version meets requirement (15.0+)"
    else
        print_warning "Xcode version may be too old (recommended: 15.0+)"
    fi
else
    print_error "Xcode not found (xcodebuild command not available)"
fi

# Check Swift
if check_command swift; then
    SWIFT_VERSION=$(swift --version | head -n 1)
    print_success "Swift found: $SWIFT_VERSION"
else
    print_error "Swift compiler not found"
fi

# 2. Project Structure
print_header "2. Verifying Project Structure"

cd "$PROJECT_DIR"

# Check for Xcode project
if [ -d "StickyToDo.xcodeproj" ]; then
    print_success "Xcode project found: StickyToDo.xcodeproj"
else
    print_error "Xcode project not found: StickyToDo.xcodeproj"
fi

# Check for target directories
TARGETS=(
    "StickyToDoCore"
    "StickyToDo-SwiftUI"
    "StickyToDo-AppKit"
    "StickyToDoTests"
)

for target in "${TARGETS[@]}"; do
    if [ -d "$target" ]; then
        print_success "Target directory found: $target"
    else
        print_error "Target directory missing: $target"
    fi
done

# Check for essential files
ESSENTIAL_FILES=(
    "StickyToDoCore/Models/Task.swift"
    "StickyToDoCore/Models/Board.swift"
    "StickyToDoCore/Models/Perspective.swift"
    "StickyToDo-SwiftUI/StickyToDoApp.swift"
    "StickyToDo-AppKit/AppDelegate.swift"
)

for file in "${ESSENTIAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Found: $file"
    else
        print_warning "Missing: $file (may need to be created)"
    fi
done

# 3. Asset Catalogs
print_header "3. Checking Asset Catalogs"

if [ -d "StickyToDo-SwiftUI/Assets.xcassets" ]; then
    print_success "SwiftUI Assets.xcassets found"
else
    print_warning "SwiftUI Assets.xcassets missing (app icon required)"
fi

if [ -d "StickyToDo-AppKit/Assets.xcassets" ]; then
    print_success "AppKit Assets.xcassets found"
else
    print_warning "AppKit Assets.xcassets missing (app icon required)"
fi

# 4. Entitlements
print_header "4. Checking Entitlements"

ENTITLEMENTS=(
    "StickyToDo-SwiftUI/StickyToDo.entitlements"
    "StickyToDo-AppKit/StickyToDo-AppKit.entitlements"
)

for entitlement in "${ENTITLEMENTS[@]}"; do
    if [ -f "$entitlement" ]; then
        print_success "Found: $entitlement"
    else
        print_warning "Missing: $entitlement"
    fi
done

# 5. Build Schemes
print_header "5. Verifying Build Schemes"

SCHEMES=(
    "StickyToDoCore"
    "StickyToDo-SwiftUI"
    "StickyToDo-AppKit"
)

for scheme in "${SCHEMES[@]}"; do
    if xcodebuild -list -project StickyToDo.xcodeproj | grep -q "$scheme"; then
        print_success "Build scheme found: $scheme"
    else
        print_error "Build scheme missing: $scheme"
    fi
done

# 6. Swift Package Dependencies
print_header "6. Checking Swift Package Dependencies"

print_info "Resolving package dependencies..."

# Try to resolve packages (this may take a moment)
if xcodebuild -resolvePackageDependencies -project StickyToDo.xcodeproj &> /dev/null; then
    print_success "Swift Package dependencies resolved successfully"
else
    print_warning "Could not resolve Swift Package dependencies automatically"
    print_info "You may need to resolve them manually in Xcode"
    print_info "Recommended packages:"
    print_info "  - Yams: https://github.com/jpsim/Yams.git (v5.0+)"
fi

# 7. Code Compilation Test
print_header "7. Testing Code Compilation"

print_info "Building StickyToDoCore framework..."
if xcodebuild -scheme StickyToDoCore -configuration Debug build CODE_SIGNING_ALLOWED=NO &> /tmp/stickytodo_build.log; then
    print_success "StickyToDoCore builds successfully"
else
    print_error "StickyToDoCore failed to build"
    print_info "Check /tmp/stickytodo_build.log for details"
fi

print_info "Building StickyToDo-SwiftUI app..."
if xcodebuild -scheme StickyToDo-SwiftUI -configuration Debug build CODE_SIGNING_ALLOWED=NO &> /tmp/stickytodo_swiftui_build.log; then
    print_success "StickyToDo-SwiftUI builds successfully"
else
    print_warning "StickyToDo-SwiftUI failed to build (may need additional setup)"
    print_info "Check /tmp/stickytodo_swiftui_build.log for details"
fi

print_info "Building StickyToDo-AppKit app..."
if xcodebuild -scheme StickyToDo-AppKit -configuration Debug build CODE_SIGNING_ALLOWED=NO &> /tmp/stickytodo_appkit_build.log; then
    print_success "StickyToDo-AppKit builds successfully"
else
    print_warning "StickyToDo-AppKit failed to build (may need additional setup)"
    print_info "Check /tmp/stickytodo_appkit_build.log for details"
fi

# 8. Swift File Analysis
print_header "8. Analyzing Swift Files"

SWIFT_FILES=$(find . -name "*.swift" -not -path "*/DerivedData/*" -not -path "*/.build/*" | wc -l | tr -d ' ')
print_success "Found $SWIFT_FILES Swift source files"

# Check for basic syntax errors (simple check)
SWIFT_ERRORS=0
while IFS= read -r -d '' file; do
    if ! swift -frontend -parse "$file" &> /dev/null; then
        ((SWIFT_ERRORS++))
    fi
done < <(find . -name "*.swift" -not -path "*/DerivedData/*" -not -path "*/.build/*" -print0)

if [ "$SWIFT_ERRORS" -eq 0 ]; then
    print_success "No syntax errors detected in Swift files"
else
    print_warning "Detected potential syntax errors in $SWIFT_ERRORS Swift files"
fi

# 9. Target Configuration
print_header "9. Verifying Target Configurations"

# Check if targets have correct deployment target
for scheme in "${SCHEMES[@]}"; do
    if xcodebuild -scheme "$scheme" -showBuildSettings 2>/dev/null | grep -q "MACOSX_DEPLOYMENT_TARGET = 13.0"; then
        print_success "$scheme: Deployment target correctly set to macOS 13.0"
    else
        print_warning "$scheme: Deployment target may not be set correctly"
    fi
done

# 10. File Organization
print_header "10. Checking File Organization"

# Check for utility directories
if [ -d "StickyToDo-SwiftUI/Utilities" ]; then
    print_success "SwiftUI Utilities directory found"
else
    print_warning "SwiftUI Utilities directory missing"
fi

if [ -d "StickyToDo-AppKit/Utilities" ]; then
    print_success "AppKit Utilities directory found"
else
    print_warning "AppKit Utilities directory missing"
fi

# Check for animation files
if [ -f "StickyToDo-SwiftUI/Utilities/AnimationPresets.swift" ]; then
    print_success "SwiftUI AnimationPresets.swift found"
else
    print_warning "SwiftUI AnimationPresets.swift missing"
fi

if [ -f "StickyToDo-AppKit/Utilities/AnimationHelpers.swift" ]; then
    print_success "AppKit AnimationHelpers.swift found"
else
    print_warning "AppKit AnimationHelpers.swift missing"
fi

# Summary
print_header "Verification Summary"

TOTAL=$((PASSED + FAILED + WARNINGS))

echo ""
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${RED}Failed:${NC}   $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "Total:    $TOTAL"
echo ""

if [ "$FAILED" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✓ Project verification PASSED${NC}"
    echo -e "${GREEN}  All checks completed successfully!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Open StickyToDo.xcodeproj in Xcode"
    echo "  2. Select a scheme (SwiftUI or AppKit)"
    echo "  3. Press ⌘R to build and run"
    echo ""
    exit 0
elif [ "$FAILED" -eq 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  ⚠ Project verification completed with warnings${NC}"
    echo -e "${YELLOW}  Project should build, but review warnings above${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Recommended actions:"
    echo "  - Review warnings above"
    echo "  - Add missing files or directories"
    echo "  - See BUILD_SETUP.md for detailed instructions"
    echo ""
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ✗ Project verification FAILED${NC}"
    echo -e "${RED}  Please fix the errors above before building${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Recommended actions:"
    echo "  1. Review errors and warnings above"
    echo "  2. Consult BUILD_SETUP.md for setup instructions"
    echo "  3. Run scripts/quick-start.sh for automated setup"
    echo "  4. Re-run this script after fixing issues"
    echo ""
    exit 1
fi
