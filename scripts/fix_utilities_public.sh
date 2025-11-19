#!/bin/bash
# Script to add public modifiers to Swift types in StickyToDoCore/Utilities, Data, ImportExport, AppIntents

echo "Fixing public modifiers in Utilities..."

# Utilities - Classes and structs that need to be public
UTIL_FILES=(
    "/home/user/sticky-todo/StickyToDoCore/Utilities/RulesEngine.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/TimeTrackingManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/AppCoordinator.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/RecurrenceEngine.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/ColorPalette.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/ConfigurationManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/SampleDataGenerator.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/SpotlightManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/NotificationManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/CalendarManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/SearchManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/ActivityLogManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/WeeklyReviewManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/LayoutEngine.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/KeyboardShortcutManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/PerformanceMonitor.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/WindowStateManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/AccessibilityHelper.swift"
    "/home/user/sticky-todo/StickyToDoCore/Utilities/AnalyticsCalculator.swift"
)

for file in "${UTIL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        sed -i 's/^struct /public struct /g' "$file"
        sed -i 's/^enum /public enum /g' "$file"
        sed -i 's/^class /public class /g' "$file"
        sed -i 's/^protocol /public protocol /g' "$file"
        sed -i 's/^    init(/    public init(/g' "$file"
    fi
done

echo "Fixing public modifiers in Data..."

# Data - YAMLParser
DATA_FILES=(
    "/home/user/sticky-todo/StickyToDoCore/Data/YAMLParser.swift"
)

for file in "${DATA_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        sed -i 's/^struct /public struct /g' "$file"
        sed -i 's/^enum /public enum /g' "$file"
        sed -i 's/^class /public class /g' "$file"
    fi
done

echo "Fixing public modifiers in ImportExport..."

# ImportExport
IMPORT_FILES=(
    "/home/user/sticky-todo/StickyToDoCore/ImportExport/ImportFormat.swift"
    "/home/user/sticky-todo/StickyToDoCore/ImportExport/ExportFormat.swift"
    "/home/user/sticky-todo/StickyToDoCore/ImportExport/ImportManager.swift"
    "/home/user/sticky-todo/StickyToDoCore/ImportExport/ExportManager.swift"
)

for file in "${IMPORT_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        sed -i 's/^struct /public struct /g' "$file"
        sed -i 's/^enum /public enum /g' "$file"
        sed -i 's/^class /public class /g' "$file"
        sed -i 's/^    init(/    public init(/g' "$file"
    fi
done

echo "Fixing public modifiers in AppIntents..."

# AppIntents
APPINTENT_FILES=(
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/AddTaskIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/AddTaskToProjectIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/CompleteTaskIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/FlagTaskIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/ShowFlaggedTasksIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/ShowInboxIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/ShowNextActionsIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/ShowTodayTasksIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/ShowWeeklyReviewIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/StartTimerIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/StopTimerIntent.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/StickyToDoAppShortcuts.swift"
    "/home/user/sticky-todo/StickyToDoCore/AppIntents/TaskEntity.swift"
)

for file in "${APPINTENT_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        sed -i 's/^struct /public struct /g' "$file"
        sed -i 's/^enum /public enum /g' "$file"
        sed -i 's/^class /public class /g' "$file"
    fi
done

echo "Done fixing all directories!"
