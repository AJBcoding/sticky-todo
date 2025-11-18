#!/bin/bash

################################################################################
# StickyToDo Build and Run Script
#
# Comprehensive build verification and execution script for StickyToDo project.
# Features:
# - Xcode installation verification
# - Package dependency checks (Yams)
# - Build verification for both schemes
# - Test execution
# - Error reporting with fixes
# - Multiple operation modes
# - Color-coded output
# - Build log saving
#
# Usage:
#   ./build-and-run.sh [options]
#
# Options:
#   --check-only      Only check dependencies and configuration
#   --fix-issues      Attempt to automatically fix common issues
#   --test-only       Run tests only (skip build)
#   --clean           Clean build before compiling
#   --verbose         Show detailed build output
#   --scheme <name>   Build specific scheme (StickyToDo-SwiftUI or StickyToDo-AppKit)
#   --run             Run the app after successful build
#   --help            Show this help message
#
# Examples:
#   ./build-and-run.sh --check-only
#   ./build-and-run.sh --fix-issues --clean
#   ./build-and-run.sh --scheme StickyToDo-SwiftUI --run
#   ./build-and-run.sh --test-only
#
################################################################################

set -e  # Exit on error (we'll handle this ourselves)
set -o pipefail

# Script directory and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_FILE="$PROJECT_ROOT/StickyToDo.xcodeproj"
LOGS_DIR="$PROJECT_ROOT/build-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOGS_DIR/build_${TIMESTAMP}.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
CHECK_ONLY=false
FIX_ISSUES=false
TEST_ONLY=false
CLEAN_BUILD=false
VERBOSE=false
RUN_APP=false
SPECIFIC_SCHEME=""
BUILD_SCHEMES=("StickyToDo-SwiftUI" "StickyToDo-AppKit")

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_step() {
    echo -e "\n${BOLD}${MAGENTA}▸${NC} $1"
}

log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

show_help() {
    cat << EOF
${BOLD}StickyToDo Build and Run Script${NC}

${BOLD}USAGE:${NC}
    $0 [options]

${BOLD}OPTIONS:${NC}
    --check-only      Only check dependencies and configuration
    --fix-issues      Attempt to automatically fix common issues
    --test-only       Run tests only (skip build)
    --clean           Clean build before compiling
    --verbose         Show detailed build output
    --scheme <name>   Build specific scheme (StickyToDo-SwiftUI or StickyToDo-AppKit)
    --run             Run the app after successful build
    --help            Show this help message

${BOLD}EXAMPLES:${NC}
    $0 --check-only
    $0 --fix-issues --clean
    $0 --scheme StickyToDo-SwiftUI --run
    $0 --test-only

EOF
}

################################################################################
# Verification Functions
################################################################################

check_xcode() {
    print_step "Checking Xcode installation..."

    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools not found"
        print_info "Install with: xcode-select --install"
        return 1
    fi

    local xcode_version=$(xcodebuild -version | head -n 1)
    print_success "Found: $xcode_version"
    log_message "Xcode version: $xcode_version"

    return 0
}

check_project_file() {
    print_step "Checking project file..."

    if [ ! -d "$PROJECT_FILE" ]; then
        print_error "Project file not found: $PROJECT_FILE"
        return 1
    fi

    print_success "Project file exists"
    log_message "Project file: $PROJECT_FILE"

    return 0
}

check_yams_dependency() {
    print_step "Checking Yams package dependency..."

    # Check if Package.swift exists
    if [ -f "$PROJECT_ROOT/Package.swift" ]; then
        if grep -q "jpsim/Yams" "$PROJECT_ROOT/Package.swift"; then
            print_success "Yams dependency found in Package.swift"
            return 0
        fi
    fi

    # Check project.pbxproj for package reference
    if grep -q "Yams" "$PROJECT_FILE/project.pbxproj"; then
        print_success "Yams package reference found in project"
        return 0
    fi

    print_warning "Yams package dependency not found"
    print_info "To add Yams:"
    echo ""
    echo "  1. Open StickyToDo.xcodeproj in Xcode"
    echo "  2. Select the project in the navigator"
    echo "  3. Go to 'Package Dependencies' tab"
    echo "  4. Click '+' and add: https://github.com/jpsim/Yams"
    echo "  5. Use 'Up to Next Major Version' with minimum 5.0.0"
    echo ""

    if [ "$FIX_ISSUES" = true ]; then
        print_info "Auto-fix not available for package dependencies - must be done in Xcode"
    fi

    return 1
}

check_swift_version() {
    print_step "Checking Swift version..."

    if ! command -v swift &> /dev/null; then
        print_error "Swift not found"
        return 1
    fi

    local swift_version=$(swift --version | head -n 1)
    print_success "$swift_version"
    log_message "Swift version: $swift_version"

    return 0
}

check_schemes() {
    print_step "Checking build schemes..."

    local schemes=$(xcodebuild -list -project "$PROJECT_FILE" 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | awk '{print $1}')

    if [ -z "$schemes" ]; then
        print_error "No schemes found in project"
        return 1
    fi

    print_success "Available schemes:"
    echo "$schemes" | while read -r scheme; do
        echo "    - $scheme"
    done
    log_message "Available schemes: $schemes"

    return 0
}

################################################################################
# Build Functions
################################################################################

clean_build_folder() {
    print_step "Cleaning build folder..."

    if xcodebuild clean -project "$PROJECT_FILE" &>> "$LOG_FILE"; then
        print_success "Build folder cleaned"
        return 0
    else
        print_error "Failed to clean build folder"
        return 1
    fi
}

build_scheme() {
    local scheme=$1
    print_step "Building scheme: $scheme..."

    local build_cmd="xcodebuild -project \"$PROJECT_FILE\" -scheme \"$scheme\" -configuration Debug"

    if [ "$VERBOSE" = true ]; then
        build_cmd="$build_cmd | tee -a \"$LOG_FILE\""
    else
        build_cmd="$build_cmd &>> \"$LOG_FILE\""
    fi

    if eval $build_cmd; then
        print_success "Build succeeded: $scheme"
        log_message "Build succeeded: $scheme"
        return 0
    else
        print_error "Build failed: $scheme"
        print_info "Check log file: $LOG_FILE"
        analyze_build_errors "$scheme"
        return 1
    fi
}

run_tests() {
    print_step "Running tests..."

    local test_cmd="xcodebuild test -project \"$PROJECT_FILE\" -scheme StickyToDoTests"

    if [ "$VERBOSE" = true ]; then
        test_cmd="$test_cmd | tee -a \"$LOG_FILE\""
    else
        test_cmd="$test_cmd &>> \"$LOG_FILE\""
    fi

    if eval $test_cmd; then
        print_success "All tests passed"
        log_message "Tests passed"

        # Extract test summary
        local test_summary=$(grep -A 5 "Test Suite 'All tests'" "$LOG_FILE" | tail -n 3)
        echo ""
        echo "$test_summary"
        return 0
    else
        print_error "Tests failed"
        print_info "Check log file: $LOG_FILE"
        return 1
    fi
}

run_app() {
    local scheme=$1
    print_step "Running application: $scheme..."

    # Find the built app
    local app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "$scheme.app" -type d 2>/dev/null | head -n 1)

    if [ -z "$app_path" ]; then
        print_error "Could not find built application"
        print_info "Try building first: $0 --scheme $scheme"
        return 1
    fi

    print_success "Launching: $app_path"
    open "$app_path"

    return 0
}

################################################################################
# Error Analysis Functions
################################################################################

analyze_build_errors() {
    local scheme=$1
    print_step "Analyzing build errors..."

    # Common error patterns and solutions
    if grep -q "Cannot find 'Yams' in scope" "$LOG_FILE" || \
       grep -q "No such module 'Yams'" "$LOG_FILE"; then
        print_error "Missing Yams dependency"
        print_info "Fix: Add Yams package to the project"
        echo "  1. Open Xcode"
        echo "  2. File → Add Packages..."
        echo "  3. Enter: https://github.com/jpsim/Yams"
        echo "  4. Add to all targets that import Yams"
        return
    fi

    if grep -q "No such module" "$LOG_FILE"; then
        local missing_module=$(grep "No such module" "$LOG_FILE" | head -n 1 | sed "s/.*'\(.*\)'.*/\1/")
        print_error "Missing module: $missing_module"
        print_info "Check import statements and framework dependencies"
        return
    fi

    if grep -q "Use of unresolved identifier" "$LOG_FILE"; then
        print_error "Unresolved identifiers found"
        print_info "Check for missing imports or typos in code"
        grep "Use of unresolved identifier" "$LOG_FILE" | head -n 5
        return
    fi

    if grep -q "Type .* does not conform to protocol" "$LOG_FILE"; then
        print_error "Protocol conformance issues found"
        print_info "Check protocol implementations"
        grep "does not conform to protocol" "$LOG_FILE" | head -n 3
        return
    fi

    if grep -q "Cannot find type .* in scope" "$LOG_FILE"; then
        print_error "Type resolution issues found"
        print_info "Check for missing files in target or import statements"
        grep "Cannot find type" "$LOG_FILE" | head -n 5
        return
    fi

    # Show last 20 error lines if no specific pattern matched
    print_warning "Generic build errors detected"
    print_info "Last 20 error lines:"
    grep -i "error:" "$LOG_FILE" | tail -n 20
}

show_common_fixes() {
    print_header "Common Issues and Fixes"

    cat << EOF
${BOLD}1. Missing Yams Package${NC}
   Error: "No such module 'Yams'"
   Fix:   Add Yams via Xcode → File → Add Packages
          URL: https://github.com/jpsim/Yams
          Version: 5.0.0 or higher

${BOLD}2. Missing Files in Target${NC}
   Error: "Cannot find type X in scope"
   Fix:   Select file → File Inspector → Target Membership
          Ensure files are added to correct target

${BOLD}3. Missing Framework Import${NC}
   Error: "Use of unresolved identifier"
   Fix:   Add required import statement at top of file
          Common: import SwiftUI, import AppKit

${BOLD}4. Build Directory Issues${NC}
   Error: Various compilation errors
   Fix:   Clean build folder with --clean flag
          Or manually: Xcode → Product → Clean Build Folder

${BOLD}5. Derived Data Corruption${NC}
   Error: Persistent build failures
   Fix:   Delete derived data:
          rm -rf ~/Library/Developer/Xcode/DerivedData

${BOLD}6. Signing Issues${NC}
   Error: Code signing errors
   Fix:   Xcode → Signing & Capabilities
          Set Team and Bundle Identifier

For more help, check: $LOG_FILE

EOF
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header "StickyToDo Build and Run Script"

    # Create logs directory
    mkdir -p "$LOGS_DIR"

    # Initialize log file
    log_message "Build script started"
    log_message "Project root: $PROJECT_ROOT"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check-only)
                CHECK_ONLY=true
                shift
                ;;
            --fix-issues)
                FIX_ISSUES=true
                shift
                ;;
            --test-only)
                TEST_ONLY=true
                shift
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --run)
                RUN_APP=true
                shift
                ;;
            --scheme)
                SPECIFIC_SCHEME="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Verification phase
    print_header "System Verification"

    local verification_failed=false

    check_xcode || verification_failed=true
    check_swift_version || verification_failed=true
    check_project_file || verification_failed=true
    check_schemes || verification_failed=true
    check_yams_dependency || verification_failed=true

    if [ "$verification_failed" = true ]; then
        print_error "Verification failed"
        if [ "$FIX_ISSUES" = true ]; then
            show_common_fixes
        fi
        exit 1
    fi

    print_success "All verifications passed"

    # Exit if check-only mode
    if [ "$CHECK_ONLY" = true ]; then
        print_header "Check Complete"
        print_success "Project is ready to build"
        exit 0
    fi

    # Clean build if requested
    if [ "$CLEAN_BUILD" = true ]; then
        clean_build_folder
    fi

    # Test-only mode
    if [ "$TEST_ONLY" = true ]; then
        print_header "Running Tests"
        if run_tests; then
            print_header "Test Complete"
            print_success "All tests passed"
            exit 0
        else
            print_header "Test Failed"
            exit 1
        fi
    fi

    # Build phase
    print_header "Building Project"

    local build_failed=false
    local built_scheme=""

    if [ -n "$SPECIFIC_SCHEME" ]; then
        # Build specific scheme
        if build_scheme "$SPECIFIC_SCHEME"; then
            built_scheme="$SPECIFIC_SCHEME"
        else
            build_failed=true
        fi
    else
        # Build all schemes
        for scheme in "${BUILD_SCHEMES[@]}"; do
            if build_scheme "$scheme"; then
                built_scheme="$scheme"
            else
                build_failed=true
                break
            fi
        done
    fi

    # Run tests after successful build
    if [ "$build_failed" = false ]; then
        print_header "Running Tests"
        run_tests || true  # Don't fail on test errors
    fi

    # Final status
    print_header "Build Summary"

    if [ "$build_failed" = true ]; then
        print_error "Build failed"
        print_info "Log file: $LOG_FILE"
        show_common_fixes
        exit 1
    else
        print_success "Build completed successfully"
        print_info "Log file: $LOG_FILE"

        # Run app if requested
        if [ "$RUN_APP" = true ] && [ -n "$built_scheme" ]; then
            run_app "$built_scheme"
        fi

        exit 0
    fi
}

# Run main function
main "$@"
