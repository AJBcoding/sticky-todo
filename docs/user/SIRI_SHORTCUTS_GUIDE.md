# StickyToDo Siri Shortcuts Guide

Comprehensive guide to using Siri Shortcuts and App Intents with StickyToDo for hands-free productivity.

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Available Shortcuts](#available-shortcuts)
4. [Sample Phrases](#sample-phrases)
5. [Advanced Usage](#advanced-usage)
6. [Spotlight Integration](#spotlight-integration)
7. [Troubleshooting](#troubleshooting)
8. [Developer Reference](#developer-reference)

## Overview

StickyToDo integrates deeply with iOS and macOS through App Intents, enabling:

- **Voice Control**: Use Siri to manage tasks hands-free
- **Shortcuts App**: Create custom automation workflows
- **Spotlight Search**: Find tasks instantly across your system
- **Suggestions**: Proactive Siri suggestions based on your usage patterns
- **Widget Integration**: Quick actions from home screen widgets

### Requirements

- iOS 16.0+ / macOS 13.0+
- Siri enabled in System Settings
- StickyToDo app installed and configured

## Getting Started

### 1. Enable Siri Access

**iOS:**
1. Open Settings > Siri & Search
2. Enable "Listen for 'Hey Siri'"
3. Find StickyToDo in the app list
4. Enable "Learn from this App"
5. Enable "Show App in Search"
6. Enable "Show Siri Suggestions"

**macOS:**
1. Open System Settings > Siri & Spotlight
2. Enable "Ask Siri"
3. Ensure StickyToDo has necessary permissions

### 2. Configure Shortcuts

Within StickyToDo:
1. Open Settings/Preferences
2. Navigate to "Siri & Shortcuts"
3. Browse available shortcuts
4. Tap "Add to Siri" for shortcuts you want to use
5. Record custom phrases (optional)

### 3. First Use

Try your first command:
```
"Hey Siri, add a task in StickyToDo"
```

Siri will prompt you for the task title and optionally other details.

## Available Shortcuts

### 1. Add Task

**Description**: Quickly capture a new task via voice or the Shortcuts app.

**Parameters**:
- `Title` (required): Task title
- `Notes` (optional): Additional task details
- `Project` (optional): Project to assign the task
- `Context` (optional): Context for completing the task (@office, @home, etc.)
- `Priority` (optional): high, medium, or low
- `Due Date` (optional): When the task is due
- `Flagged` (optional): Mark as flagged for attention

**Sample Phrases**:
```
"Hey Siri, add a task in StickyToDo"
"Hey Siri, create 'Call the dentist' in StickyToDo"
"Hey Siri, new task in StickyToDo"
"Hey Siri, quick capture in StickyToDo"
```

**Returns**: Confirmation dialog with task details

### 2. Show Inbox

**Description**: View all unprocessed tasks in your inbox.

**Parameters**: None

**Sample Phrases**:
```
"Hey Siri, show my inbox in StickyToDo"
"Hey Siri, what's in my inbox?"
"Hey Siri, open inbox in StickyToDo"
```

**Returns**: Count of inbox tasks and snippet view showing first 5 tasks

### 3. Show Next Actions

**Description**: View your actionable tasks.

**Parameters**:
- `Context Filter` (optional): Filter by specific context

**Sample Phrases**:
```
"Hey Siri, show my next actions in StickyToDo"
"Hey Siri, what should I do next?"
"Hey Siri, show actionable tasks in StickyToDo"
"Hey Siri, show next actions for @office in StickyToDo"
```

**Returns**: List of next actions, optionally filtered by context

### 4. Complete Task

**Description**: Mark a task as completed.

**Parameters**:
- `Task` (optional): Specific task entity
- `Task Title` (optional): Find task by title

**Sample Phrases**:
```
"Hey Siri, complete a task in StickyToDo"
"Hey Siri, mark 'Write report' as done in StickyToDo"
"Hey Siri, finish task in StickyToDo"
```

**Returns**: Confirmation that task was completed

### 5. Show Today's Tasks

**Description**: View all tasks due today.

**Parameters**:
- `Include Overdue` (optional, default: true): Also show overdue tasks

**Sample Phrases**:
```
"Hey Siri, show today's tasks in StickyToDo"
"Hey Siri, what's due today?"
"Hey Siri, what do I need to do today?"
```

**Returns**: Count and list of tasks due today, plus overdue tasks if requested

### 6. Start Timer

**Description**: Start tracking time for a task.

**Parameters**:
- `Task` (optional): Specific task to time
- `Task Title` (optional): Find task by title

**Sample Phrases**:
```
"Hey Siri, start timer in StickyToDo"
"Hey Siri, track time for 'Design mockups' in StickyToDo"
"Hey Siri, start tracking time in StickyToDo"
```

**Returns**: Confirmation with task title and timer status

**Note**: Starting a timer automatically stops any other running timer.

### 7. Stop Timer

**Description**: Stop the currently running timer.

**Parameters**:
- `Task` (optional): Specific task (defaults to any running timer)

**Sample Phrases**:
```
"Hey Siri, stop timer in StickyToDo"
"Hey Siri, stop tracking time in StickyToDo"
"Hey Siri, end timer in StickyToDo"
```

**Returns**: Time tracked in this session and total time for the task

## Sample Phrases

### Quick Capture Workflow
```
1. "Hey Siri, add a task in StickyToDo"
   Siri: "What's the task?"
   You: "Buy groceries"
   Siri: "Added 'Buy groceries' to your inbox"

2. "Hey Siri, create 'Call dentist tomorrow at 2pm' in StickyToDo"
   (Natural language parsing will extract due date)
```

### Daily Review Workflow
```
1. "Hey Siri, show today's tasks in StickyToDo"
2. "Hey Siri, show my next actions in StickyToDo"
3. "Hey Siri, what's in my inbox?"
```

### Time Tracking Workflow
```
1. "Hey Siri, start timer for 'Write documentation' in StickyToDo"
   (Work on task...)
2. "Hey Siri, stop timer in StickyToDo"
   Siri: "Stopped timer for 'Write documentation' after 1h 23m"
```

### Task Completion Workflow
```
1. "Hey Siri, complete 'Buy groceries' in StickyToDo"
2. "Hey Siri, mark task as done in StickyToDo"
   (Siri will show matching tasks if multiple exist)
```

## Advanced Usage

### Using the Shortcuts App

You can create custom automation with StickyToDo shortcuts:

#### Example: Morning Review
```
1. Open Shortcuts app
2. Create new shortcut
3. Add "Show Today's Tasks" (StickyToDo)
4. Add "Show Next Actions" (StickyToDo)
5. Set to run automatically at 8:00 AM
```

#### Example: Quick Errands Entry
```
1. Create shortcut
2. Add "Ask for Input" (prompt: "Errand")
3. Add "Add Task" (StickyToDo)
   - Title: Input
   - Project: "Errands"
   - Context: "@errands"
4. Add to home screen as icon
```

#### Example: End of Day Wrap-Up
```
1. Create shortcut
2. Add "Show Today's Tasks" (StickyToDo)
3. Add "If" (if completed tasks > 0)
4. Add "Show notification" with congratulations
5. Set to run automatically at 6:00 PM
```

### Parameters in Shortcuts

When using shortcuts in the Shortcuts app, you can:

- **Set static values**: Hardcode project, context, or priority
- **Use variables**: Pass data from other shortcuts actions
- **Prompt for input**: Ask user for specific parameters
- **Use magic variables**: Reference outputs from previous actions

### Automation Triggers

Combine StickyToDo shortcuts with triggers:

- **Time of Day**: "Show inbox at 9 AM"
- **Location**: "Show @errands tasks when arriving at shopping district"
- **App Launch**: "Show today's tasks when opening Calendar"
- **NFC Tag**: Tap tag on desk to start work timer

## Spotlight Integration

### Searching Tasks

StickyToDo indexes all active tasks in Spotlight:

**Search Examples**:
```
- "meeting" - finds tasks with "meeting" in title
- "project:Work" - finds tasks in Work project
- "@office" - finds tasks with @office context
- "high priority" - finds high-priority tasks
- "overdue" - finds overdue tasks
- "flagged" - finds flagged tasks
```

### Spotlight Keywords

Tasks are indexed with intelligent keywords:

- Title words
- Project name
- Context (with and without @ prefix)
- Tags
- Status-related terms (inbox, next action, etc.)
- Time-based terms (today, overdue)

### Opening Tasks from Spotlight

1. Search for a task in Spotlight
2. Press Return/Enter or tap the result
3. StickyToDo opens with the task selected

### Privacy

- Only **active** (non-completed) tasks are indexed
- Completed tasks are removed from index after 30 days
- You can disable Spotlight indexing in Settings

## Troubleshooting

### Siri Doesn't Recognize Commands

**Problem**: Siri says "I couldn't find that in StickyToDo"

**Solutions**:
1. Ensure app is installed and opened at least once
2. Check Settings > Siri & Search > StickyToDo
3. Enable "Learn from this App"
4. Try more specific phrasing: "Hey Siri, add a task in StickyToDo"
5. Record custom phrase in Shortcuts app

### Shortcuts Not Appearing

**Problem**: StickyToDo shortcuts don't show in Shortcuts app

**Solutions**:
1. Ensure iOS 16+ / macOS 13+
2. Restart the app
3. Check App Intents are properly configured
4. Re-install the app if necessary

### Task Not Found Errors

**Problem**: "Task not found" when trying to complete or start timer

**Solutions**:
1. Speak task title clearly and exactly as written
2. Use unique task titles
3. Try searching by partial title
4. Siri will offer disambiguation if multiple matches

### Timer Issues

**Problem**: Timer doesn't start or stop

**Solutions**:
1. Ensure no other timer is running (only one timer at a time)
2. Verify task exists and is not completed
3. Check permissions in Settings
4. Try stopping timer manually first, then starting

### Spotlight Not Showing Tasks

**Problem**: Tasks don't appear in Spotlight search

**Solutions**:
1. Check Settings > Siri & Search > StickyToDo
2. Enable "Show App in Search"
3. Wait a few minutes for initial indexing
4. Trigger re-index: Settings > StickyToDo > Advanced > Reindex Spotlight

### Permission Denied

**Problem**: Siri says "I don't have permission"

**Solutions**:
1. Check Settings > Privacy & Security > StickyToDo
2. Grant necessary permissions
3. Check Siri & Search permissions
4. Restart device if permissions were just granted

## Developer Reference

### Architecture

```
StickyToDoAppShortcuts (AppShortcutsProvider)
├── AddTaskIntent
├── CompleteTaskIntent
├── ShowInboxIntent
├── ShowNextActionsIntent
├── ShowTodayTasksIntent
├── StartTimerIntent
└── StopTimerIntent

Supporting Components:
├── TaskEntity (AppEntity)
├── TaskQuery (EntityQuery)
├── PriorityOption (AppEnum)
├── SpotlightManager
└── ShortcutsConfigView
```

### File Structure

```
StickyToDoCore/AppIntents/
├── StickyToDoAppShortcuts.swift    # AppShortcutsProvider
├── TaskEntity.swift                # App Intents entity
├── AddTaskIntent.swift
├── CompleteTaskIntent.swift
├── ShowInboxIntent.swift
├── ShowNextActionsIntent.swift
├── ShowTodayTasksIntent.swift
├── StartTimerIntent.swift
└── StopTimerIntent.swift

StickyToDoCore/Utilities/
└── SpotlightManager.swift          # Spotlight integration

StickyToDo-SwiftUI/Views/Shortcuts/
├── ShortcutsConfigView.swift       # Settings UI
└── AddToSiriButton.swift           # Siri button components
```

### Key Classes

#### AppShortcutsProvider
Defines all available shortcuts with phrases, titles, and icons.

#### TaskEntity
App Intents representation of a Task for Siri integration.

#### Intent Classes
Each intent implements `AppIntent` protocol with:
- Parameters
- Perform method (async)
- Result with dialog and optional snippet view

#### SpotlightManager
Manages Core Spotlight indexing:
- `indexTask(_:)` - Index a single task
- `indexTasks(_:)` - Batch index tasks
- `deindexTask(_:)` - Remove from index
- `reindexAllTasks(from:)` - Complete reindex

### Adding New Shortcuts

To add a new shortcut:

1. Create intent file in `AppIntents/`
2. Implement `AppIntent` protocol
3. Define parameters with `@Parameter`
4. Implement `perform()` method
5. Add to `StickyToDoAppShortcuts.appShortcuts`
6. Add sample phrases
7. Create tests in `AppShortcutsTests.swift`
8. Update this documentation

### Testing

Run tests:
```bash
xcodebuild test -scheme StickyToDo -destination 'platform=iOS Simulator,name=iPhone 14'
```

Test coverage includes:
- Intent parameter handling
- TaskEntity conversion
- Search and filtering
- Timer operations
- Error handling
- Performance benchmarks

## Best Practices

### For Users

1. **Start Simple**: Begin with basic commands, then explore advanced features
2. **Use Consistent Naming**: Keep task titles clear and unique for voice commands
3. **Record Custom Phrases**: Personalize shortcuts with phrases that feel natural to you
4. **Leverage Automation**: Use Shortcuts app for routine workflows
5. **Regular Reviews**: Set up automated reminders to review inbox and next actions

### For Developers

1. **Clear Error Messages**: Provide helpful feedback when operations fail
2. **Graceful Degradation**: Handle missing parameters gracefully
3. **Performance**: Keep intent operations fast (<200ms when possible)
4. **Spotlight Hygiene**: Clean up old/completed tasks from index
5. **Testing**: Maintain comprehensive test coverage for all intents

## Future Enhancements

Planned improvements for Siri integration:

- [ ] Natural language date parsing in voice commands
- [ ] Multi-task operations (complete multiple tasks at once)
- [ ] Weekly review shortcuts
- [ ] Focus mode integration
- [ ] Apple Watch complications
- [ ] Lock screen widgets
- [ ] Live Activities for running timers

## Resources

- [Apple App Intents Documentation](https://developer.apple.com/documentation/appintents)
- [Shortcuts User Guide](https://support.apple.com/guide/shortcuts/)
- [Core Spotlight Framework](https://developer.apple.com/documentation/corespotlight)
- [StickyToDo Documentation](../README.md)

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review [GitHub Issues](https://github.com/yourusername/stickytodo/issues)
- Contact support: support@stickytodo.com

---

**Version**: 1.0.0
**Last Updated**: 2025-01-18
**Platform**: iOS 16+, macOS 13+
