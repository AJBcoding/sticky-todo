#!/bin/bash

# Build script for AppKit Canvas Prototype
# Usage: ./build.sh [run|clean]

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
EXECUTABLE="$BUILD_DIR/CanvasPrototype"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_step() {
    echo -e "${GREEN}==>${NC} $1"
}

function print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

function print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# Create build directory
function setup_build_dir() {
    print_step "Setting up build directory..."
    mkdir -p "$BUILD_DIR"
}

# Clean build artifacts
function clean() {
    print_step "Cleaning build artifacts..."
    rm -rf "$BUILD_DIR"
    echo "✓ Clean complete"
}

# Build the prototype
function build() {
    print_step "Building AppKit Canvas Prototype..."

    setup_build_dir

    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This prototype requires macOS to build and run"
        exit 1
    fi

    # Check for Swift compiler
    if ! command -v swiftc &> /dev/null; then
        print_error "Swift compiler not found. Please install Xcode or Command Line Tools."
        exit 1
    fi

    # Compile all Swift files
    print_step "Compiling Swift files..."
    swiftc -framework Cocoa \
        -O \
        -o "$EXECUTABLE" \
        "$PROJECT_DIR/StickyNoteView.swift" \
        "$PROJECT_DIR/LassoSelectionOverlay.swift" \
        "$PROJECT_DIR/CanvasView.swift" \
        "$PROJECT_DIR/CanvasController.swift" \
        "$PROJECT_DIR/PrototypeWindow.swift"

    echo "✓ Build complete: $EXECUTABLE"
}

# Run the prototype
function run() {
    if [[ ! -f "$EXECUTABLE" ]]; then
        print_warning "Executable not found. Building first..."
        build
    fi

    print_step "Running prototype..."
    "$EXECUTABLE"
}

# Show help
function show_help() {
    cat << EOF
AppKit Canvas Prototype Build Script

Usage: ./build.sh [COMMAND]

Commands:
    build       Compile the prototype (default)
    run         Build and run the prototype
    clean       Remove build artifacts
    help        Show this help message

Examples:
    ./build.sh              # Just build
    ./build.sh run          # Build and run
    ./build.sh clean        # Clean build directory

Requirements:
    - macOS
    - Swift compiler (Xcode or Command Line Tools)

For more information, see README.md
EOF
}

# Main script logic
case "${1:-build}" in
    build)
        build
        ;;
    run)
        run
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run './build.sh help' for usage information"
        exit 1
        ;;
esac
