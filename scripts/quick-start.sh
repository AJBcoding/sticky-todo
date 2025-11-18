#!/bin/bash

#
# quick-start.sh
# StickyToDo Quick Start Script
#
# Automated setup and launch script for StickyToDo project
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Symbols
ROCKET="🚀"
CHECK_MARK="✓"
CROSS_MARK="✗"
INFO="ℹ"
WRENCH="🔧"
FOLDER="📁"

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
XCODE_PROJECT="StickyToDo.xcodeproj"
DEFAULT_SCHEME="StickyToDo-SwiftUI"

# Helper functions
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  $1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_banner() {
    clear
    echo -e "${MAGENTA}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ███████╗████████╗██╗ ██████╗██╗  ██╗██╗   ██╗          ║
║   ██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝╚██╗ ██╔╝          ║
║   ███████╗   ██║   ██║██║     █████╔╝  ╚████╔╝           ║
║   ╚════██║   ██║   ██║██║     ██╔═██╗   ╚██╔╝            ║
║   ███████║   ██║   ██║╚██████╗██║  ██╗   ██║             ║
║   ╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝             ║
║                                                           ║
║              T O D O   -   Quick Start                   ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}        Modern macOS Task Management (SwiftUI + AppKit)${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}${CHECK_MARK}${NC} $1"
}

print_error() {
    echo -e "${RED}${CROSS_MARK}${NC} $1"
}

print_info() {
    echo -e "${BLUE}${INFO}${NC}  $1"
}

print_step() {
    echo -e "${YELLOW}${WRENCH}${NC}  $1..."
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

pause_for_input() {
    echo ""
    read -p "Press Enter to continue..."
    echo ""
}

# Main script starts here

print_banner

print_header "Welcome to StickyToDo Quick Start"

echo "This script will help you:"
echo "  • Verify your development environment"
echo "  • Check project structure"
echo "  • Open the project in Xcode"
echo "  • Guide you through initial setup"
echo "  • Optionally generate sample data"
echo ""

read -p "Ready to begin? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Step 1: Environment Check
print_header "Step 1: Checking Development Environment"

cd "$PROJECT_DIR"

# Check macOS version
print_step "Checking macOS version"
MACOS_VERSION=$(sw_vers -productVersion)
print_success "macOS $MACOS_VERSION detected"

# Check Xcode
print_step "Checking Xcode installation"
if check_command xcodebuild; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    print_success "$XCODE_VERSION found"
else
    print_error "Xcode not found!"
    echo ""
    echo "Please install Xcode from the Mac App Store:"
    echo "  https://apps.apple.com/app/xcode/id497799835"
    exit 1
fi

# Check Swift
print_step "Checking Swift compiler"
if check_command swift; then
    SWIFT_VERSION=$(swift --version | head -n 1 | awk '{print $4}')
    print_success "Swift $SWIFT_VERSION found"
else
    print_error "Swift not found!"
    exit 1
fi

# Check for Xcode Command Line Tools
print_step "Checking Xcode Command Line Tools"
if xcode-select -p &> /dev/null; then
    print_success "Command Line Tools installed"
else
    print_error "Command Line Tools not found"
    echo ""
    echo "Installing Command Line Tools..."
    xcode-select --install
    echo "Please complete the installation and run this script again."
    exit 1
fi

echo ""
print_success "Environment check passed!"
pause_for_input

# Step 2: Project Structure Verification
print_header "Step 2: Verifying Project Structure"

print_step "Checking project file"
if [ -d "$XCODE_PROJECT" ]; then
    print_success "Xcode project found"
else
    print_error "Xcode project not found!"
    exit 1
fi

print_step "Checking target directories"
TARGETS=(
    "StickyToDoCore"
    "StickyToDo-SwiftUI"
    "StickyToDo-AppKit"
)

MISSING_TARGETS=()
for target in "${TARGETS[@]}"; do
    if [ -d "$target" ]; then
        print_success "$target directory found"
    else
        print_error "$target directory missing"
        MISSING_TARGETS+=("$target")
    fi
done

if [ ${#MISSING_TARGETS[@]} -gt 0 ]; then
    echo ""
    print_error "Some target directories are missing!"
    echo "Please check your project structure."
    exit 1
fi

echo ""
print_success "Project structure verified!"
pause_for_input

# Step 3: Dependencies Check
print_header "Step 3: Checking Dependencies"

print_step "Resolving Swift Package dependencies"
echo "This may take a moment..."

if xcodebuild -resolvePackageDependencies -project "$XCODE_PROJECT" &> /tmp/stickytodo_deps.log; then
    print_success "Dependencies resolved successfully"
else
    print_error "Could not resolve dependencies automatically"
    echo ""
    echo "You'll need to add dependencies manually in Xcode:"
    echo ""
    echo "  Required packages:"
    echo "    • Yams - https://github.com/jpsim/Yams.git (v5.0+)"
    echo ""
    echo "  To add in Xcode:"
    echo "    1. Open project in Xcode"
    echo "    2. Select the project in navigator"
    echo "    3. Go to Package Dependencies tab"
    echo "    4. Click + to add package"
    echo "    5. Enter package URL and version"
    echo ""
fi

pause_for_input

# Step 4: Optional Setup Tasks
print_header "Step 4: Optional Setup Tasks"

echo "Would you like to:"
echo ""

# Option: Create sample data
read -p "  1. Generate sample data for testing? (y/n) " -n 1 -r
echo ""
GENERATE_SAMPLE_DATA=$REPLY

# Option: Run verification script
read -p "  2. Run full project verification? (y/n) " -n 1 -r
echo ""
RUN_VERIFICATION=$REPLY

# Option: Open documentation
read -p "  3. Open BUILD_SETUP.md documentation? (y/n) " -n 1 -r
echo ""
OPEN_DOCS=$REPLY

echo ""

# Execute optional tasks
if [[ $RUN_VERIFICATION =~ ^[Yy]$ ]]; then
    print_step "Running project verification"
    if [ -f "$SCRIPT_DIR/verify-project.sh" ]; then
        bash "$SCRIPT_DIR/verify-project.sh"
        pause_for_input
    else
        print_error "verify-project.sh not found"
    fi
fi

if [[ $GENERATE_SAMPLE_DATA =~ ^[Yy]$ ]]; then
    print_step "Generating sample data"
    # Create sample data directory
    mkdir -p "$HOME/Library/Application Support/StickyToDo"

    # Create sample tasks file
    cat > "$HOME/Library/Application Support/StickyToDo/sample-tasks.yaml" << 'EOF'
tasks:
  - id: "task-001"
    title: "Welcome to StickyToDo!"
    notes: "This is a sample task to get you started."
    created: 2025-11-18T10:00:00Z
    status: active
    priority: high
    type: task

  - id: "task-002"
    title: "Check out the board view"
    notes: "Try organizing tasks on a visual board."
    created: 2025-11-18T10:05:00Z
    status: active
    priority: medium
    type: task

  - id: "task-003"
    title: "Use quick capture"
    notes: "Press ⌘N to quickly add new tasks."
    created: 2025-11-18T10:10:00Z
    status: active
    priority: low
    type: task

  - id: "task-004"
    title: "Completed sample task"
    notes: "This task is already done."
    created: 2025-11-17T15:00:00Z
    completed: 2025-11-18T09:00:00Z
    status: completed
    priority: medium
    type: task

boards:
  - id: "board-001"
    name: "Getting Started"
    type: kanban
    created: 2025-11-18T10:00:00Z
EOF

    print_success "Sample data created at ~/Library/Application Support/StickyToDo/"
    echo ""
fi

if [[ $OPEN_DOCS =~ ^[Yy]$ ]]; then
    if [ -f "$PROJECT_DIR/BUILD_SETUP.md" ]; then
        open "$PROJECT_DIR/BUILD_SETUP.md"
        print_success "Opened BUILD_SETUP.md"
    else
        print_error "BUILD_SETUP.md not found"
    fi
fi

# Step 5: Choose which app to run
print_header "Step 5: Choose Application to Launch"

echo "Which version would you like to run?"
echo ""
echo "  1) StickyToDo-SwiftUI (Modern, SwiftUI-based)"
echo "  2) StickyToDo-AppKit (Traditional, AppKit-based)"
echo "  3) Both (in separate instances)"
echo "  4) Just open in Xcode (don't run)"
echo ""

read -p "Enter choice (1-4): " -n 1 -r
echo ""

SCHEME=""
case $REPLY in
    1)
        SCHEME="StickyToDo-SwiftUI"
        ;;
    2)
        SCHEME="StickyToDo-AppKit"
        ;;
    3)
        SCHEME="both"
        ;;
    4)
        SCHEME="none"
        ;;
    *)
        echo "Invalid choice, defaulting to SwiftUI"
        SCHEME="StickyToDo-SwiftUI"
        ;;
esac

# Step 6: Open and Run
print_header "Step 6: Launching Xcode"

print_step "Opening Xcode project"
open "$XCODE_PROJECT"
print_success "Xcode opened"

sleep 2  # Give Xcode time to open

if [ "$SCHEME" == "none" ]; then
    echo ""
    print_info "Project opened in Xcode"
    print_info "Select a scheme and press ⌘R to build and run"
elif [ "$SCHEME" == "both" ]; then
    print_info "Building both applications..."
    echo ""
    echo "To run both apps simultaneously:"
    echo "  1. Build SwiftUI app first (select scheme, press ⌘R)"
    echo "  2. Stop the app (⌘.)"
    echo "  3. Find the built app in Finder and launch it"
    echo "  4. Switch to AppKit scheme in Xcode"
    echo "  5. Press ⌘R to build and run AppKit version"
    echo ""
    echo "Both apps will now be running side-by-side!"
else
    echo ""
    print_info "To build and run $SCHEME:"
    echo ""
    echo "  1. Wait for Xcode to finish indexing"
    echo "  2. Select '$SCHEME' scheme from toolbar"
    echo "  3. Press ⌘R to build and run"
    echo ""
fi

# Step 7: Next Steps
print_header "Setup Complete!"

echo -e "${GREEN}${ROCKET}${NC}  Your StickyToDo project is ready!"
echo ""
echo "Next steps:"
echo ""
echo "  ${CHECK_MARK} Read the documentation:"
echo "     • BUILD_SETUP.md - Build configuration guide"
echo "     • docs/DEVELOPMENT.md - Development guidelines"
echo "     • docs/ASSETS.md - App icon creation guide"
echo ""
echo "  ${CHECK_MARK} Explore the code:"
echo "     • StickyToDoCore/ - Shared business logic"
echo "     • StickyToDo-SwiftUI/ - Modern UI implementation"
echo "     • StickyToDo-AppKit/ - Classic UI implementation"
echo ""
echo "  ${CHECK_MARK} Try building:"
echo "     • Select a scheme in Xcode"
echo "     • Press ⌘R to build and run"
echo "     • Test both SwiftUI and AppKit versions"
echo ""
echo "  ${CHECK_MARK} Add features:"
echo "     • Core models in StickyToDoCore/Models/"
echo "     • SwiftUI views in StickyToDo-SwiftUI/Views/"
echo "     • AppKit views in StickyToDo-AppKit/Views/"
echo ""

# Manual steps reminder
print_header "Manual Steps Required"

echo "Some steps need to be completed manually in Xcode:"
echo ""
echo "  1. ${WRENCH} Add Swift Package Dependencies:"
echo "     • File > Add Packages..."
echo "     • Add Yams: https://github.com/jpsim/Yams.git"
echo "     • Version: 5.0.0 or later"
echo ""
echo "  2. ${FOLDER} Create App Icons:"
echo "     • See docs/ASSETS.md for detailed instructions"
echo "     • Design 1024x1024 icon"
echo "     • Export required sizes"
echo "     • Add to both Assets.xcassets"
echo ""
echo "  3. ${CHECK_MARK} Build and Test:"
echo "     • Build each scheme (⌘B)"
echo "     • Run tests (⌘U)"
echo "     • Verify both apps launch correctly"
echo ""

# Helpful commands
print_header "Helpful Commands"

echo "Run these commands from the project directory:"
echo ""
echo "  # Verify project configuration"
echo "  bash scripts/verify-project.sh"
echo ""
echo "  # Build from command line"
echo "  xcodebuild -scheme StickyToDo-SwiftUI build"
echo ""
echo "  # Run tests"
echo "  xcodebuild test -scheme StickyToDo-SwiftUI"
echo ""
echo "  # Clean build"
echo "  xcodebuild clean -scheme StickyToDo-SwiftUI"
echo ""

# Final message
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Happy coding! 🚀${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Open relevant files in default editor (optional)
read -p "Would you like to open key files for review? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Open README
    if [ -f "$PROJECT_DIR/README.md" ]; then
        open "$PROJECT_DIR/README.md"
    fi

    # Open HANDOFF
    if [ -f "$PROJECT_DIR/HANDOFF.md" ]; then
        open "$PROJECT_DIR/HANDOFF.md"
    fi

    print_success "Documentation opened"
fi

echo ""
echo "Setup script complete!"
echo ""

exit 0
