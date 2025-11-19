#!/bin/bash
# Quick launcher for AppKit Canvas Prototype

set -e

cd "$(dirname "$0")"

echo "🚀 Launching AppKit Canvas Prototype..."
echo ""
echo "Controls:"
echo "  • Pan: Option + drag"
echo "  • Zoom: Command + scroll"
echo "  • Select: Click note"
echo "  • Multi-select: Command + click"
echo "  • Lasso: Click + drag on empty space"
echo "  • Delete: Select notes, press Delete"
echo "  • Add note: Click '+' button"
echo ""
echo "Performance: 60 FPS with 100+ notes 🎯"
echo ""

swift run AppKitPrototype
