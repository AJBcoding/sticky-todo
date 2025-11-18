# Performance Monitoring for Task Count

## Overview

The Sticky ToDo app now includes comprehensive performance monitoring that tracks task count and warns users when approaching or exceeding recommended thresholds. This prevents performance degradation at scale and helps users maintain optimal app performance.

## Implementation Location

**File:** `/home/user/sticky-todo/StickyToDo/Data/TaskStore.swift`

**Lines:** 83-307 (Performance Monitoring section)

## Performance Thresholds

The monitoring system defines three escalating threshold levels:

| Level | Task Count | Color | Description |
|-------|-----------|-------|-------------|
| **Warning** | 500 | Yellow | Approaching performance threshold |
| **Alert** | 1000 | Orange | Exceeds recommended limit |
| **Critical** | 1500 | Red | Severe performance risk |

## Features

### 1. Automatic Monitoring

Performance checks are automatically triggered after:
- Loading tasks (`loadAll()`, `loadAllAsync()` at lines 368-400)
- Adding a task (`add()` at line 459)
- Deleting a task (`delete()` at line 566)
- Batch deleting tasks (`deleteBatch()` at line 743)

### 2. Intelligent Logging

The system only logs when:
- The performance level changes (avoids log spam)
- The level is above normal (no logs for normal operation)

**Example Warning Log (500+ tasks):**
```
⚠️ WARNING: Task count approaching performance threshold
Current: 523 tasks (Warning threshold: 500)

Recommendation: Consider archiving completed tasks to maintain optimal performance.
Active tasks: 341 | Completed tasks: 182
```

**Example Alert Log (1000+ tasks):**
```
🚨 ALERT: Task count exceeds recommended limit
Current: 1042 tasks (Alert threshold: 1000)

URGENT: Archive or delete old completed tasks to prevent performance degradation.
- You have 387 completed tasks that could be archived
- Active tasks: 655

Performance may be impacted with this many tasks.
```

**Example Critical Log (1500+ tasks):**
```
❌ CRITICAL: Task count at critical level
Current: 1567 tasks (Critical threshold: 1500)

IMMEDIATE ACTION REQUIRED:
1. Archive completed tasks (892 available)
2. Delete unnecessary tasks
3. Consider splitting tasks into separate data files

Severe performance degradation likely at this task count!
```

### 3. Public API Methods

#### `getPerformanceMetrics() -> [String: Any]`

Returns current performance information:
```swift
let metrics = taskStore.getPerformanceMetrics()
// Returns:
// {
//   "taskCount": 623,
//   "activeTaskCount": 412,
//   "completedTaskCount": 211,
//   "level": "warning",
//   "warningThreshold": 500,
//   "alertThreshold": 1000,
//   "criticalThreshold": 1500,
//   "percentOfWarning": 124.6,
//   "percentOfAlert": 62.3
// }
```

#### Threshold Check Properties

```swift
taskStore.isAtWarningThreshold   // Bool: >= 500 tasks
taskStore.isAtAlertThreshold     // Bool: >= 1000 tasks
taskStore.isAtCriticalThreshold  // Bool: >= 1500 tasks
```

#### `archivableTasksCount() -> Int`

Returns count of tasks eligible for archiving (completed and older than 30 days):
```swift
let archivable = taskStore.archivableTasksCount()
// Returns: 127
```

#### `getPerformanceSuggestion() -> String?`

Returns a user-friendly suggestion message, or `nil` if no action needed:
```swift
if let suggestion = taskStore.getPerformanceSuggestion() {
    print(suggestion)
    // "Alert: 1042 tasks. Consider archiving 387 completed tasks."
}
```

## UI Integration

### Performance Status View

**File:** `/home/user/sticky-todo/StickyToDo/Views/PerformanceStatusView.swift`

A SwiftUI component that displays a color-coded indicator in the toolbar:
- **Green dot**: Normal (< 500 tasks)
- **Yellow dot**: Warning (500-999 tasks)
- **Orange dot**: Alert (1000-1499 tasks)
- **Red dot**: Critical (≥ 1500 tasks)

The indicator shows the current task count and can be clicked to display a detailed popover with:
- Total, active, and completed task counts
- Visual progress bars for each threshold
- Actionable recommendations
- Count of archivable tasks

### Integration in ContentView

**File:** `/home/user/sticky-todo/StickyToDo/ContentView.swift`

**Line:** 214-216

Added to toolbar as a status item:
```swift
ToolbarItem(placement: .status) {
    PerformanceStatusView(taskStore: taskStore)
}
```

## Performance Impact

### Design Considerations

1. **Minimal Overhead**: Monitoring uses simple integer comparisons
2. **Smart Logging**: Only logs on level changes, not on every operation
3. **No Blocking**: All checks run synchronously but are O(1) for threshold checks
4. **Efficient Counting**: Uses existing `taskCount` property (already computed)

### Measured Impact

Based on test results (see `PerformanceMonitoringTests.swift`):
- Adding 1,000 tasks with monitoring: < 2 seconds
- Performance check execution: < 1ms per check
- No measurable impact on normal operations

## Testing

**File:** `/home/user/sticky-todo/StickyToDo/Tests/PerformanceMonitoringTests.swift`

Comprehensive test suite covering:
- Normal level (< 500 tasks)
- Warning level (500-999 tasks)
- Alert level (1000-1499 tasks)
- Critical level (≥ 1500 tasks)
- Performance metrics accuracy
- Archivable task detection
- Load monitoring
- Delete improvement detection
- Performance impact measurement

Run tests with:
```bash
swift test --filter PerformanceMonitoringTests
```

## Usage Examples

### Example 1: Check Performance Status

```swift
let taskStore = TaskStore(fileIO: fileIO)

// Check current status
if taskStore.isAtWarningThreshold {
    print("Warning: \(taskStore.taskCount) tasks")
    print("Suggestion: \(taskStore.getPerformanceSuggestion() ?? "None")")
}
```

### Example 2: Display Metrics in UI

```swift
let metrics = taskStore.getPerformanceMetrics()
let taskCount = metrics["taskCount"] as? Int ?? 0
let level = metrics["level"] as? String ?? "normal"
let percentOfAlert = metrics["percentOfAlert"] as? Double ?? 0.0

Text("Tasks: \(taskCount) (\(Int(percentOfAlert))% of alert threshold)")
    .foregroundColor(level == "alert" ? .orange : .primary)
```

### Example 3: Archive Old Tasks

```swift
// Find archivable tasks
let archivableCount = taskStore.archivableTasksCount()

if archivableCount > 0 {
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    let tasksToArchive = taskStore.tasks.filter { task in
        task.status == .completed && task.modified < thirtyDaysAgo
    }

    // Move to archive (implementation depends on your archiving strategy)
    taskStore.deleteBatch(tasksToArchive)
}
```

## Future Enhancements

Potential improvements for consideration:

1. **Configurable Thresholds**: Allow users to customize warning/alert levels
2. **Performance History**: Track task count over time
3. **Automatic Archiving**: Offer to automatically archive old completed tasks
4. **Database Migration**: Suggest moving to a database at high task counts
5. **Export Options**: Easy export of old tasks before deletion
6. **Performance Profiles**: Different thresholds based on device capabilities

## Architecture Decisions

### Why These Thresholds?

- **500 (Warning)**: Based on app target of "500-1000 tasks"
- **1000 (Alert)**: Upper bound of target range
- **1500 (Critical)**: Safety margin before severe degradation

### Why 30 Days for Archiving?

- Balances recent history access with cleanup needs
- Matches common task completion cycles
- Aligns with typical "monthly review" workflows

### Why Check on Every Add/Delete?

- Provides immediate feedback to users
- Catches threshold crossings as they happen
- Minimal performance overhead (O(1) checks)

## Related Files

- **Core Implementation**: `/home/user/sticky-todo/StickyToDo/Data/TaskStore.swift` (lines 83-307)
- **UI Component**: `/home/user/sticky-todo/StickyToDo/Views/PerformanceStatusView.swift`
- **UI Integration**: `/home/user/sticky-todo/StickyToDo/ContentView.swift` (line 214-216)
- **Tests**: `/home/user/sticky-todo/StickyToDo/Tests/PerformanceMonitoringTests.swift`
- **Documentation**: `/home/user/sticky-todo/docs/performance-monitoring.md` (this file)

## Troubleshooting

### Not Seeing Warnings

1. Check if logger is configured:
   ```swift
   taskStore.setLogger { message in
       print(message)
   }
   ```

2. Verify task count:
   ```swift
   print("Task count: \(taskStore.taskCount)")
   print("Is at warning: \(taskStore.isAtWarningThreshold)")
   ```

### Performance Status View Not Showing

1. Ensure TaskStore is passed as ObservedObject:
   ```swift
   @ObservedObject var taskStore: TaskStore
   ```

2. Verify toolbar placement is correct (`.status` placement)

### False Positives for Archivable Count

The `archivableTasksCount()` method counts completed tasks older than 30 days. If you're seeing unexpected counts:
1. Check task `modified` dates
2. Verify task `status` is `.completed`
3. Confirm your calendar/date settings

## Contact

For questions or issues related to performance monitoring, please refer to:
- GitHub Issues: [sticky-todo/issues](https://github.com/your-repo/sticky-todo/issues)
- Internal Documentation: `/docs/`
