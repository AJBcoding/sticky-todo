#!/bin/bash
# Script to add public modifiers to Swift types in StickyToDoCore

# Models that still need fixing
FILES=(
    "/home/user/sticky-todo/StickyToDoCore/Models/Board.swift"
    "/home/user/sticky-todo/StickyToDoCore/Models/BoardType.swift"
    "/home/user/sticky-todo/StickyToDoCore/Models/Layout.swift"
    "/home/user/sticky-todo/StickyToDoCore/Models/Perspective.swift"
    "/home/user/sticky-todo/StickyToDoCore/Models/SmartPerspective.swift"
    "/home/user/sticky-todo/StickyToDoCore/Models/ProjectNote.swift"
    "/home/user/sticky-todo/StickyToDoCore/Models/TaskTemplate.swift"
    "/home/user/sticky-todo/StickyToDoCore/Models/TimeEntry.swift"
    "/home/user/sticky-todo/StickyToDoCore/Models/ActivityLog.swift"
    "/home/user/sticky-todo/StickyToDoCore/Models/WeeklyReview.swift"
    "/home/user/sticky-todo/StickyToDoCore/Models/Rule.swift"
)

echo "Fixing public modifiers in Model files..."

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        # Add public to struct/enum/class/protocol declarations
        sed -i 's/^struct /public struct /g' "$file"
        sed -i 's/^enum /public enum /g' "$file"
        sed -i 's/^class /public class /g' "$file"
        sed -i 's/^protocol /public protocol /g' "$file"
        # Add public to init methods (need to be more careful with indentation)
        sed -i 's/^    init(/    public init(/g' "$file"
    else
        echo "File not found: $file"
    fi
done

echo "Done fixing Model files!"
