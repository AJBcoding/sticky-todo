#!/bin/bash
#
# create-placeholder-icon.sh
# Creates a simple placeholder icon for development
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="$PROJECT_ROOT/assets/icon-source.png"

echo "Creating placeholder icon..."

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Warning: ImageMagick is not installed. Cannot create icon."
    echo "Install it with: brew install imagemagick"
    echo ""
    echo "Alternatively, manually create an icon at: $OUTPUT_FILE"
    exit 1
fi

# Create a simple sticky note icon with checkmark
convert -size 1024x1024 xc:none \
    \( -size 900x900 xc:"#FFD54F" \
       -fill "#FFA726" \
       -draw "polygon 850,0 900,50 900,0" \
       -fill none \
       -stroke "#424242" \
       -strokewidth 2 \
       -draw "roundrectangle 0,0 900,900 40,40" \
    \) -gravity center -composite \
    \( -size 1024x1024 xc:none \
       -fill none \
       -stroke "#2E7D32" \
       -strokewidth 80 \
       -strokelinecap round \
       -strokelinejoin round \
       -draw "path 'M 300,500 L 420,650 L 700,350'" \
    \) -composite \
    "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Created placeholder icon at: $OUTPUT_FILE"
    echo ""
    echo "To generate all icon sizes, run:"
    echo "  ./scripts/generate-icons.sh"
else
    echo "✗ Failed to create icon"
    exit 1
fi
