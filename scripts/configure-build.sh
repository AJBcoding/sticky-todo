#!/bin/bash
#
# configure-build.sh
# Configures build settings for Sticky ToDo project
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Sticky ToDo Build Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Version information
VERSION="1.0.0"
BUILD="1"

echo -e "${GREEN}Version:${NC} $VERSION"
echo -e "${GREEN}Build:${NC} $BUILD"
echo ""

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode command line tools not installed${NC}"
    exit 1
fi

echo -e "${BLUE}Configuring Info.plist files...${NC}"

# Configure SwiftUI Info.plist
SWIFTUI_PLIST="$PROJECT_ROOT/StickyToDo-SwiftUI/Info.plist"
if [ ! -f "$SWIFTUI_PLIST" ]; then
    echo "Creating SwiftUI Info.plist..."
    cat > "$SWIFTUI_PLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Sticky ToDo</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 Sticky ToDo. All rights reserved.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Markdown Document</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>net.daringfireball.markdown</string>
            </array>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
        </dict>
    </array>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.stickytodo.url</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>stickytodo</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF
    echo -e "${GREEN}✓${NC} Created $SWIFTUI_PLIST"
else
    echo -e "${YELLOW}Info.plist already exists${NC}"
fi

# Configure AppKit Info.plist
APPKIT_PLIST="$PROJECT_ROOT/StickyToDo-AppKit/Info.plist"
if [ ! -f "$APPKIT_PLIST" ]; then
    echo "Creating AppKit Info.plist..."
    cp "$SWIFTUI_PLIST" "$APPKIT_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'Sticky ToDo (AppKit)'" "$APPKIT_PLIST" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Created $APPKIT_PLIST"
fi

# Configure Core framework Info.plist
CORE_PLIST="$PROJECT_ROOT/StickyToDoCore/Info.plist"
if [ -f "$CORE_PLIST" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CORE_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$CORE_PLIST"

    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$CORE_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD" "$CORE_PLIST"

    echo -e "${GREEN}✓${NC} Updated $CORE_PLIST"
fi

echo ""
echo -e "${BLUE}Verifying project structure...${NC}"

# Check for required directories
REQUIRED_DIRS=(
    "StickyToDo-SwiftUI"
    "StickyToDo-AppKit"
    "StickyToDoCore"
    "StickyToDoTests"
    "docs"
    "scripts"
    "assets"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        echo -e "${GREEN}✓${NC} $dir"
    else
        echo -e "${RED}✗${NC} $dir (missing)"
    fi
done

echo ""
echo -e "${BLUE}Checking build dependencies...${NC}"

# Check for SwiftLint
if command -v swiftlint &> /dev/null; then
    echo -e "${GREEN}✓${NC} SwiftLint installed"
else
    echo -e "${YELLOW}○${NC} SwiftLint not installed (optional)"
    echo "  Install with: brew install swiftlint"
fi

# Check for ImageMagick (for icons)
if command -v convert &> /dev/null; then
    echo -e "${GREEN}✓${NC} ImageMagick installed"
else
    echo -e "${YELLOW}○${NC} ImageMagick not installed (for icon generation)"
    echo "  Install with: brew install imagemagick"
fi

echo ""
echo -e "${BLUE}Build configuration summary:${NC}"
echo ""
echo "Project: Sticky ToDo"
echo "Version: $VERSION (Build $BUILD)"
echo "Min macOS: 12.0"
echo "Architectures: arm64, x86_64"
echo ""

# Create xcconfig files if they don't exist
XCCONFIG_DIR="$PROJECT_ROOT/Configuration"
mkdir -p "$XCCONFIG_DIR"

# Debug configuration
cat > "$XCCONFIG_DIR/Debug.xcconfig" << 'EOF'
// Debug Configuration

// Optimization
SWIFT_OPTIMIZATION_LEVEL = -Onone
GCC_OPTIMIZATION_LEVEL = 0

// Debugging
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
ENABLE_TESTABILITY = YES
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG
GCC_PREPROCESSOR_DEFINITIONS = DEBUG=1

// Warnings
SWIFT_TREAT_WARNINGS_AS_ERRORS = NO
GCC_TREAT_WARNINGS_AS_ERRORS = NO

// Code Signing
CODE_SIGN_IDENTITY = Apple Development
EOF

# Release configuration
cat > "$XCCONFIG_DIR/Release.xcconfig" << 'EOF'
// Release Configuration

// Optimization
SWIFT_OPTIMIZATION_LEVEL = -O
GCC_OPTIMIZATION_LEVEL = s
SWIFT_COMPILATION_MODE = wholemodule

// Debugging
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
ENABLE_TESTABILITY = NO

// Stripping
STRIP_INSTALLED_PRODUCT = YES
COPY_PHASE_STRIP = NO
STRIP_SWIFT_SYMBOLS = YES
DEAD_CODE_STRIPPING = YES

// Warnings
SWIFT_TREAT_WARNINGS_AS_ERRORS = YES
GCC_TREAT_WARNINGS_AS_ERRORS = YES

// Code Signing
CODE_SIGN_IDENTITY = Developer ID Application
ENABLE_HARDENED_RUNTIME = YES
EOF

echo -e "${GREEN}✓${NC} Created xcconfig files in Configuration/"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Configuration complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "  1. Generate app icons: ./scripts/create-placeholder-icon.sh"
echo "  2. Build project: xcodebuild -scheme StickyToDo-SwiftUI"
echo "  3. Run tests: xcodebuild test -scheme StickyToDoTests"
echo ""
