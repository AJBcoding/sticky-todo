# Recurring Tasks - Quick Start Guide

## Overview

StickyToDo now supports recurring tasks with flexible patterns for daily, weekly, monthly, and yearly recurrence. This guide shows you how to use this feature.

## Creating a Recurring Task

### Via UI (SwiftUI or AppKit)

1. Create or select a task
2. Open the Inspector panel (right sidebar)
3. Find the "Recurrence" section
4. Toggle "Repeat Task" to ON
5. Configure your recurrence pattern:
   - **Frequency**: Daily, Weekly, Monthly, or Yearly
   - **Interval**: Every N days/weeks/months/years
   - **Days** (Weekly only): Select which days of the week
   - **Day of Month** (Monthly only): Specific day or last day
   - **Ends**: Never, On a date, or After N occurrences
6. Save the task

### Programmatically

```swift
import StickyToDoCore

// Daily task
let dailyTask = Task(
    title: "Morning meditation",
    due: Date(),
    recurrence: .daily
)

// Weekly task (Mon/Wed/Fri)
let gymTask = Task(
    title: "Gym workout",
    due: Date(),
    recurrence: Recurrence(
        frequency: .weekly,
        interval: 1,
        daysOfWeek: [1, 3, 5]
    )
)

// Monthly task (last day)
let rentTask = Task(
    title: "Pay rent",
    due: Date(),
    recurrence: Recurrence(
        frequency: .monthly,
        interval: 1,
        useLastDayOfMonth: true
    )
)

// Limited recurrence (10 times)
let trainingTask = Task(
    title: "Training session",
    due: Date(),
    recurrence: Recurrence(
        frequency: .daily,
        interval: 1,
        count: 10
    )
)

// Add to task store
taskStore.add(dailyTask)
```

## Common Patterns

### Weekday Task (Mon-Fri)

```swift
let task = Task(
    title: "Check email",
    due: Date(),
    recurrence: .weekdays
)
```

### Bi-weekly Task

```swift
let task = Task(
    title: "Team retrospective",
    due: Date(),
    recurrence: .biweekly
)
```

### Monthly on 15th

```swift
let task = Task(
    title: "Submit timesheet",
    due: Date(),
    recurrence: Recurrence(
        frequency: .monthly,
        interval: 1,
        dayOfMonth: 15
    )
)
```

### Quarterly Task

```swift
let task = Task(
    title: "Quarterly review",
    due: Date(),
    recurrence: Recurrence(
        frequency: .monthly,
        interval: 3  // Every 3 months
    )
)
```

## How It Works

### Templates and Instances

When you create a recurring task, you're creating a **template**:
- The template defines the recurrence pattern
- The template is never completed
- Instances are created from the template

When an occurrence is due, an **instance** is created:
- Instance has the same title, notes, project, context
- Instance can be completed normally
- Completing an instance creates the next one

### Automatic Creation

Instances are created automatically when:
- The app launches (creates all due instances)
- A daily check runs (background timer)
- You complete a recurring instance

### Viewing Instances

In the Inspector panel:
- **Template tasks** show the recurrence pattern and next occurrence date
- **Instance tasks** show which template they came from and their occurrence date

## Managing Recurring Tasks

### Editing the Recurrence Pattern

1. Select the template task (not an instance)
2. Modify the recurrence settings in the Inspector
3. Save changes
4. New instances will use the updated pattern

### Stopping a Recurrence

1. Select the template task
2. Toggle "Repeat Task" to OFF
3. Existing instances remain, but no new ones are created

### Deleting a Recurring Task

When you delete a template task, you'll be asked whether to:
- **Delete template only**: Keeps existing instances
- **Delete template and all instances**: Removes everything

### Completing a Series

(Coming soon) Complete all future instances at once.

## Examples

### Daily Standup

```swift
Task(
    title: "Daily standup",
    notes: "Review progress and blockers",
    project: "Team",
    due: Date(),
    recurrence: .daily
)
```

### Weekly Review (Fridays)

```swift
Task(
    title: "Weekly review",
    notes: "Review accomplishments and plan next week",
    due: Date(),
    recurrence: Recurrence(
        frequency: .weekly,
        interval: 1,
        daysOfWeek: [5]  // Friday
    )
)
```

### Monthly Budget Review

```swift
Task(
    title: "Review budget",
    project: "Finance",
    due: Date(),
    recurrence: Recurrence(
        frequency: .monthly,
        interval: 1,
        dayOfMonth: 1  // First of each month
    )
)
```

### Yearly Tax Filing

```swift
let taxDate = Calendar.current.date(from: DateComponents(
    year: 2025,
    month: 4,
    day: 15
))!

Task(
    title: "File taxes",
    project: "Finance",
    due: taxDate,
    recurrence: .yearly
)
```

### 30-Day Challenge

```swift
Task(
    title: "Daily exercise",
    project: "Health",
    due: Date(),
    recurrence: Recurrence(
        frequency: .daily,
        interval: 1,
        count: 30  // Stops after 30 days
    )
)
```

### Weekend Chores

```swift
Task(
    title: "Clean house",
    context: "@home",
    due: Date(),
    recurrence: .weekends
)
```

## Tips

1. **Set Due Dates**: Recurring tasks work best with a due date
2. **Use Projects**: Group related recurring tasks in projects
3. **Check Inspector**: The Inspector shows next occurrence and pattern details
4. **Review Templates**: Periodically review your recurring templates
5. **Adjust Patterns**: Don't hesitate to modify patterns as your needs change

## Keyboard Shortcuts

(Future enhancement)
- `⌘R` - Toggle recurrence
- `⌘⇧R` - Edit recurrence pattern

## Troubleshooting

### No instances are being created

- Check that the recurrence pattern is enabled
- Verify the due date is in the past
- Check the end condition (count or end date)
- Restart the app to trigger a check

### Too many instances created

- Adjust the interval (make it less frequent)
- Set an end date or count limit
- Stop the recurrence if no longer needed

### Instances have wrong dates

- Review the recurrence pattern
- Check for month overflow (e.g., Feb 30 -> Feb 28)
- Verify the selected days of week

## API Reference

See `RecurringTasksImplementation.md` for full API documentation.

## Support

For issues or questions about recurring tasks, see:
- `/docs/RecurringTasksImplementation.md` - Full technical documentation
- `/StickyToDoTests/RecurrenceEngineTests.swift` - Usage examples and tests
