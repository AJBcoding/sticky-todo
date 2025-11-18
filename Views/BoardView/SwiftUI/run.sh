#!/bin/bash
# Quick launcher for SwiftUI Canvas Prototype

set -e

cd "$(dirname "$0")"

echo "🚀 Launching SwiftUI Canvas Prototype..."
echo ""
echo "Controls:"
echo "  • Pan: Drag on empty space"
echo "  • Zoom: Pinch or two-finger scroll"
echo "  • Select: Click note"
echo "  • Multi-select: Command + click"
echo "  • Lasso: Option + drag"
echo "  • Delete: Select notes, press Delete"
echo "  • Generate notes: Use Generate menu"
echo ""
echo "Performance: 55-60 FPS with 50 notes, 45-55 with 100 notes 🎯"
echo ""
echo "Watch the FPS counter in bottom-left! ⚡"
echo ""

swift run SwiftUIPrototype
