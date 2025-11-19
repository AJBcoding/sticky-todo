#!/bin/bash
# Master test script for both Canvas Prototypes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    StickyToDo Canvas Prototype Test Suite     ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo ""

echo -e "${BLUE}Available options:${NC}"
echo ""
echo "  1. Run AppKit Prototype"
echo "  2. Run SwiftUI Prototype"
echo "  3. Run Both (side-by-side comparison)"
echo "  4. Open AppKit in Xcode"
echo "  5. Open SwiftUI in Xcode"
echo "  6. View Testing Guide"
echo "  7. Exit"
echo ""

read -p "Enter your choice (1-7): " choice

case $choice in
    1)
        echo -e "\n${GREEN}→ Launching AppKit Prototype...${NC}\n"
        cd "$SCRIPT_DIR/AppKit"
        ./run.sh
        ;;
    2)
        echo -e "\n${GREEN}→ Launching SwiftUI Prototype...${NC}\n"
        cd "$SCRIPT_DIR/SwiftUI"
        ./run.sh
        ;;
    3)
        echo -e "\n${GREEN}→ Launching BOTH prototypes for side-by-side comparison...${NC}\n"
        echo -e "${YELLOW}Both apps will open. Arrange windows side-by-side to compare!${NC}\n"

        # Launch AppKit in background
        cd "$SCRIPT_DIR/AppKit"
        swift run AppKitPrototype &
        APPKIT_PID=$!

        # Wait a moment
        sleep 2

        # Launch SwiftUI
        cd "$SCRIPT_DIR/SwiftUI"
        swift run SwiftUIPrototype &
        SWIFTUI_PID=$!

        echo ""
        echo -e "${GREEN}✓ Both prototypes launched!${NC}"
        echo ""
        echo "AppKit PID: $APPKIT_PID"
        echo "SwiftUI PID: $SWIFTUI_PID"
        echo ""
        echo "Press Ctrl+C to quit both apps"

        # Wait for both processes
        wait $APPKIT_PID $SWIFTUI_PID
        ;;
    4)
        echo -e "\n${GREEN}→ Opening AppKit prototype in Xcode...${NC}\n"
        cd "$SCRIPT_DIR/AppKit"
        open Package.swift
        ;;
    5)
        echo -e "\n${GREEN}→ Opening SwiftUI prototype in Xcode...${NC}\n"
        cd "$SCRIPT_DIR/SwiftUI"
        open Package.swift
        ;;
    6)
        echo -e "\n${GREEN}→ Opening Testing Guide...${NC}\n"
        open "$SCRIPT_DIR/TESTING_GUIDE.md"
        ;;
    7)
        echo -e "\n${GREEN}Goodbye!${NC}\n"
        exit 0
        ;;
    *)
        echo -e "\n${YELLOW}Invalid choice. Please run again and choose 1-7.${NC}\n"
        exit 1
        ;;
esac
