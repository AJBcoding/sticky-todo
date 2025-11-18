#!/bin/bash
#
# generate-icons.sh
# Generates all required macOS app icon sizes from a source image
#
# Requirements:
#   - ImageMagick (brew install imagemagick)
#   - Source icon file (SVG or high-res PNG)
#
# Usage:
#   ./scripts/generate-icons.sh [source-file]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default source file
SOURCE_FILE="${1:-assets/icon-source.png}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Sticky ToDo Icon Generator${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed${NC}"
    echo "Please install it with: brew install imagemagick"
    exit 1
fi

# Check if source file exists
if [ ! -f "$PROJECT_ROOT/$SOURCE_FILE" ]; then
    echo -e "${RED}Error: Source file not found: $SOURCE_FILE${NC}"
    echo ""
    echo "Please provide a source image file (PNG or SVG)"
    echo "Usage: $0 [source-file]"
    exit 1
fi

echo -e "${GREEN}✓${NC} Source file: $SOURCE_FILE"
echo ""

# macOS App Icon sizes (as of macOS 12+)
# Format: "size@scale"
declare -a SIZES=(
    "16@1x"
    "16@2x"
    "32@1x"
    "32@2x"
    "128@1x"
    "128@2x"
    "256@1x"
    "256@2x"
    "512@1x"
    "512@2x"
)

# Function to generate icon
generate_icon() {
    local size_spec=$1
    local output_dir=$2

    # Parse size and scale
    local size=$(echo "$size_spec" | cut -d'@' -f1)
    local scale=$(echo "$size_spec" | cut -d'@' -f2 | sed 's/x//')

    # Calculate actual pixel size
    local pixels=$((size * scale))

    # Output filename
    local filename="icon_${size}x${size}@${scale}x.png"
    local output_path="$output_dir/$filename"

    echo -e "  ${YELLOW}→${NC} Generating ${size}x${size}@${scale}x (${pixels}x${pixels}px)..."

    # Generate icon using ImageMagick
    convert "$PROJECT_ROOT/$SOURCE_FILE" \
        -resize "${pixels}x${pixels}" \
        -gravity center \
        -extent "${pixels}x${pixels}" \
        "$output_path"

    if [ $? -eq 0 ]; then
        echo -e "    ${GREEN}✓${NC} Created $filename"
    else
        echo -e "    ${RED}✗${NC} Failed to create $filename"
        return 1
    fi
}

# Generate icons for SwiftUI app
SWIFTUI_ICON_DIR="$PROJECT_ROOT/StickyToDo-SwiftUI/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$SWIFTUI_ICON_DIR"

echo -e "${BLUE}Generating icons for SwiftUI app...${NC}"
for size in "${SIZES[@]}"; do
    generate_icon "$size" "$SWIFTUI_ICON_DIR"
done

# Generate icons for AppKit app
APPKIT_ICON_DIR="$PROJECT_ROOT/StickyToDo-AppKit/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$APPKIT_ICON_DIR"

echo ""
echo -e "${BLUE}Generating icons for AppKit app...${NC}"
for size in "${SIZES[@]}"; do
    generate_icon "$size" "$APPKIT_ICON_DIR"
done

# Create Contents.json for SwiftUI
echo ""
echo -e "${BLUE}Creating Contents.json files...${NC}"

cat > "$SWIFTUI_ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16@1x.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32@1x.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128@1x.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256@1x.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512@1x.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

cp "$SWIFTUI_ICON_DIR/Contents.json" "$APPKIT_ICON_DIR/Contents.json"

echo -e "${GREEN}✓${NC} Contents.json created for both apps"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Icon generation complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo "Generated icon sets in:"
echo "  • StickyToDo-SwiftUI/Assets.xcassets/AppIcon.appiconset"
echo "  • StickyToDo-AppKit/Assets.xcassets/AppIcon.appiconset"
echo ""
