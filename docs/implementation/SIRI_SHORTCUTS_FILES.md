# Siri Shortcuts - File Manifest

Quick reference for all files created for Siri Shortcuts integration.

## App Intents (9 files)

### Core Intent Implementations

1. **`/StickyToDoCore/AppIntents/TaskEntity.swift`**
   - TaskEntity (AppEntity)
   - TaskQuery (EntityQuery)
   - PriorityOption (AppEnum)
   - ~150 lines

2. **`/StickyToDoCore/AppIntents/AddTaskIntent.swift`**
   - Quick task capture via Siri
   - Parameters: title, notes, project, context, priority, due date, flagged
   - Returns: Confirmation dialog + snippet view
   - ~210 lines

3. **`/StickyToDoCore/AppIntents/CompleteTaskIntent.swift`**
   - Mark task as completed
   - Parameters: task entity or task title
   - Returns: Confirmation dialog
   - ~90 lines

4. **`/StickyToDoCore/AppIntents/ShowInboxIntent.swift`**
   - Open inbox view
   - Shows count and first 5 tasks
   - Returns: Dialog + snippet view
   - ~100 lines

5. **`/StickyToDoCore/AppIntents/ShowNextActionsIntent.swift`**
   - Show next actions
   - Optional context filter
   - Returns: Dialog + snippet view with priorities
   - ~140 lines

6. **`/StickyToDoCore/AppIntents/ShowTodayTasksIntent.swift`**
   - Show tasks due today
   - Optional overdue tasks
   - Returns: Dialog + snippet view
   - ~150 lines

7. **`/StickyToDoCore/AppIntents/StartTimerIntent.swift`**
   - Start task timer
   - Stops other running timers
   - Returns: Confirmation + timer status
   - ~150 lines

8. **`/StickyToDoCore/AppIntents/StopTimerIntent.swift`**
   - Stop running timer
   - Shows session and total time
   - Returns: Confirmation + duration summary
   - ~140 lines

9. **`/StickyToDoCore/AppIntents/StickyToDoAppShortcuts.swift`**
   - AppShortcutsProvider implementation
   - 7 AppShortcut definitions
   - Sample phrases for all shortcuts
   - ~140 lines

## UI Components (2 files)

10. **`/StickyToDo-SwiftUI/Views/Shortcuts/ShortcutsConfigView.swift`**
    - Settings UI for managing shortcuts
    - Category filtering (All, Tasks, Navigation, Time Tracking)
    - Card-based layout
    - Help section
    - ~250 lines

11. **`/StickyToDo-SwiftUI/Views/Shortcuts/AddToSiriButton.swift`**
    - AddToSiriButton component
    - SiriShortcutCard
    - SiriSuggestionBanner
    - Compact and full styles
    - ~140 lines

## Utilities (1 file)

12. **`/StickyToDoCore/Utilities/SpotlightManager.swift`**
    - Spotlight integration
    - Task indexing/deindexing
    - Keyword generation
    - Search handling
    - ~290 lines

## Tests (1 file)

13. **`/StickyToDoTests/AppShortcutsTests.swift`**
    - 20+ test cases
    - Entity conversion tests
    - Intent functionality tests
    - Integration tests
    - Performance tests
    - ~350 lines

## Documentation (2 files)

14. **`/docs/SIRI_SHORTCUTS_GUIDE.md`**
    - User guide
    - Getting started
    - All 7 shortcuts documented
    - 50+ sample phrases
    - Advanced usage examples
    - Troubleshooting
    - ~850 lines

15. **`/SIRI_SHORTCUTS_IMPLEMENTATION.md`**
    - Implementation report
    - Architecture overview
    - Technical details
    - Integration requirements
    - Performance metrics
    - ~650 lines

---

## File Statistics

**Total Files**: 15
**Total Lines**: ~3,500
**Core Intents**: 9 files (~1,270 lines)
**UI Components**: 2 files (~390 lines)
**Utilities**: 1 file (~290 lines)
**Tests**: 1 file (~350 lines)
**Documentation**: 2 files (~1,500 lines)

## Directory Structure

```
sticky-todo/
├── StickyToDoCore/
│   ├── AppIntents/
│   │   ├── AddTaskIntent.swift
│   │   ├── CompleteTaskIntent.swift
│   │   ├── ShowInboxIntent.swift
│   │   ├── ShowNextActionsIntent.swift
│   │   ├── ShowTodayTasksIntent.swift
│   │   ├── StartTimerIntent.swift
│   │   ├── StopTimerIntent.swift
│   │   ├── StickyToDoAppShortcuts.swift
│   │   └── TaskEntity.swift
│   └── Utilities/
│       └── SpotlightManager.swift
├── StickyToDo-SwiftUI/
│   └── Views/
│       └── Shortcuts/
│           ├── AddToSiriButton.swift
│           └── ShortcutsConfigView.swift
├── StickyToDoTests/
│   └── AppShortcutsTests.swift
├── docs/
│   └── SIRI_SHORTCUTS_GUIDE.md
├── SIRI_SHORTCUTS_IMPLEMENTATION.md
└── SIRI_SHORTCUTS_FILES.md (this file)
```

## Quick Reference

### Shortcuts Implemented

1. ✅ Add Task - Quick capture
2. ✅ Complete Task - Mark as done
3. ✅ Show Inbox - View unprocessed
4. ✅ Show Next Actions - View actionable tasks
5. ✅ Show Today's Tasks - Tasks due today
6. ✅ Start Timer - Begin time tracking
7. ✅ Stop Timer - End time tracking

### Key Classes

- `TaskEntity` - App Intents entity
- `TaskQuery` - Search and suggestions
- `StickyToDoAppShortcuts` - Provider
- `SpotlightManager` - Search integration
- `ShortcutsConfigView` - Settings UI

### Integration Points

- AppDelegate.shared.taskStore
- AppDelegate.shared.timeTrackingManager
- NotificationCenter (navigation)
- CSSearchableIndex (Spotlight)

## Next Steps

1. Add to Xcode project
2. Configure Info.plist
3. Enable capabilities (Siri, App Intents)
4. Add frameworks (AppIntents, Intents, IntentsUI, CoreSpotlight)
5. Implement AppDelegate integration
6. Add navigation handlers
7. Build and test
8. Submit to App Store

## Related Documentation

- [User Guide](../user/SIRI_SHORTCUTS_GUIDE.md)
- [Implementation Report](SIRI_SHORTCUTS_IMPLEMENTATION.md)
- [Main README](README.md)
