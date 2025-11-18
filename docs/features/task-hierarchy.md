# Task Hierarchy and Subtasks

## Overview

StickyToDo supports hierarchical task organization through parent-child relationships. Tasks can have subtasks, creating a structured breakdown of work. This feature is available in all views: List View, Board View (Freeform, Kanban, and Grid layouts).

## Data Model

### Task Properties

Each task includes the following hierarchy-related properties:

- **`parentId: UUID?`** - Reference to the parent task (nil for top-level tasks)
- **`subtaskIds: [UUID]`** - Array of child task IDs
- **`hasSubtasks: Bool`** - Computed property returning true if task has children
- **`isSubtask: Bool`** - Computed property returning true if task has a parent
- **`indentationLevel: Int`** - Computed property for basic indentation (0 or 1)

### YAML Serialization

Tasks with hierarchy are serialized to markdown files with YAML frontmatter:

**Parent Task Example:**
```yaml
---
id: 123e4567-e89b-12d3-a456-426614174000
title: Complete website redesign
status: next-action
subtaskIds:
  - 123e4567-e89b-12d3-a456-426614174001
  - 123e4567-e89b-12d3-a456-426614174002
  - 123e4567-e89b-12d3-a456-426614174003
---
```

**Subtask Example:**
```yaml
---
id: 123e4567-e89b-12d3-a456-426614174001
title: Design homepage mockup
status: completed
parentId: 123e4567-e89b-12d3-a456-426614174000
---
```

## TaskStore Methods

### Querying Hierarchy

```swift
// Get all subtasks of a parent task
let subtasks = taskStore.subtasks(for: parentTask)

// Get the parent of a subtask
let parent = taskStore.parentTask(for: subtask)

// Get all top-level tasks (tasks without parents)
let topLevelTasks = taskStore.topLevelTasks()

// Get indentation level (handles deep hierarchies)
let level = taskStore.indentationLevel(for: task)
```

### Progress Tracking

```swift
// Check if all subtasks are completed
let allComplete = taskStore.areAllSubtasksCompleted(for: task)

// Get completion progress
let (completed, total) = taskStore.subtaskProgress(for: task)
// Returns: (2, 5) meaning 2 out of 5 subtasks are complete
```

### Creating and Managing Subtasks

```swift
// Create a new subtask under a parent
let subtask = taskStore.createSubtask(title: "Design mockup", under: parentTask)

// Convert an existing task to a subtask
taskStore.convertToSubtask(existingTask, of: parentTask)

// Promote a subtask to top-level task
taskStore.promoteToTopLevel(subtask)
```

### Smart Completion

```swift
// Complete a task and all its subtasks recursively
taskStore.completeWithSubtasks(parentTask)

// Uncomplete a task and its parent chain
// When a subtask is marked incomplete, the parent also becomes incomplete
taskStore.uncompleteWithParent(subtask)
```

## Task Methods

### Managing Subtask Relationships

```swift
var task = Task(title: "Parent Task")

// Add a subtask reference
task.addSubtask(subtaskId)

// Remove a subtask reference
task.removeSubtask(subtaskId)

// Clear all subtasks
task.clearSubtasks()

// Set or clear parent
task.setParent(parentId)  // Set parent
task.setParent(nil)       // Clear parent
```

## UI Integration

### SwiftUI: TaskRowView

TaskRowView displays hierarchical tasks with indentation and visual indicators:

```swift
TaskRowView(
    task: $task,
    isSelected: false,
    indentationLevel: 1,           // 0 = top-level, 1+ = subtask
    hasSubtasks: true,              // Show disclosure triangle
    subtaskProgress: (2, 5),        // Shows "2/5" badge
    isExpanded: $isExpanded,        // Controls disclosure state
    onTap: { },
    onToggleComplete: { },
    onDelete: { },
    onToggleExpansion: { },         // Handle disclosure toggle
    onAddSubtask: { }               // Handle "Add Subtask" action
)
```

**Visual Elements:**
- **Indentation**: 20px per level (configurable)
- **Disclosure Triangle**: Chevron (right/down) for tasks with subtasks
- **Progress Badge**: Shows "completed/total" with color coding:
  - Green: All subtasks completed
  - Orange: Partial completion
- **Context Menu**: Includes "Add Subtask" option

### AppKit: TaskTableCellView

TaskTableCellView provides similar hierarchy support for macOS:

```swift
let cell = TaskTableCellView()
cell.configure(
    with: task,
    indentationLevel: 1,
    hasSubtasks: true,
    isExpanded: true,
    subtaskProgress: (2, 5)
)
cell.onDisclosureToggled = {
    // Handle disclosure triangle toggle
}
```

**Visual Elements:**
- **Indentation**: 20px per level
- **Disclosure Button**: Native macOS disclosure triangle
- **Progress Badge**: Colored badge showing completion status

### Board View: Task Cards

On board canvases (Freeform, Kanban, Grid), task cards display subtask progress:

```swift
TaskNoteView(
    task: task,
    isSelected: false,
    subtaskProgress: (2, 5),  // Shows checklist icon + "2/5"
    onTap: { },
    onDragStart: { },
    onDragChange: { _ in },
    onDragEnd: { }
)
```

**Progress Badge:**
- Icon: Checklist symbol
- Text: "completed/total"
- Color: Green (all done) or Orange (in progress)

## User Workflows

### Creating a Task Breakdown

1. Create parent task: "Complete website redesign"
2. Right-click parent task → "Add Subtask"
3. Create subtasks:
   - "Design homepage mockup"
   - "Implement responsive layout"
   - "Test on multiple devices"
4. Each subtask inherits project/context from parent

### Tracking Progress

- Parent task shows progress badge: "2/3" (2 of 3 subtasks completed)
- Completing all subtasks automatically completes parent (optional behavior)
- Progress visible in all views: List, Kanban, Freeform, Grid

### Reorganizing Hierarchy

- **Promote subtask**: Right-click → "Promote to Top Level"
- **Convert to subtask**: Drag task onto another task (with modifier key)
- **Reorder subtasks**: Drag within parent's subtask list

## Indentation Levels

The system supports deep hierarchies:

```
Level 0: Parent Task
  Level 1: Subtask 1
    Level 2: Sub-subtask 1.1
      Level 3: Sub-sub-subtask 1.1.1
  Level 1: Subtask 2
```

- **Simple cases**: Use `task.indentationLevel` (returns 0 or 1)
- **Deep hierarchies**: Use `taskStore.indentationLevel(for: task)` (traverses parent chain)
- **Safety limit**: Maximum 10 levels to prevent infinite loops

## Automatic Completion Logic

### Parent Completes All Children

When you complete a parent task:

```swift
taskStore.completeWithSubtasks(parentTask)
```

All subtasks are recursively completed. This ensures the entire task tree is marked done.

### Child Uncompletes Parent

When you uncomplete a subtask:

```swift
taskStore.uncompleteWithParent(subtask)
```

The parent task (and its parent, recursively) is marked incomplete. This maintains data integrity - a parent cannot be "done" if children are still pending.

## Filtering and Display Options

### Show/Hide Subtasks

List views can optionally collapse subtasks:

```swift
// Show only top-level tasks
let displayTasks = taskStore.topLevelTasks()

// Show all tasks (including subtasks)
let displayTasks = taskStore.tasks
```

### Board View Options

On boards, you can configure subtask visibility:

- **Show All**: Display both parents and subtasks as separate cards
- **Hide Subtasks**: Only show top-level tasks (with progress badges)
- **Compact Mode**: Show parent with inline subtask checklist

## Best Practices

1. **Keep hierarchies shallow**: 2-3 levels is usually sufficient
2. **Use subtasks for related work**: Break down complex tasks into manageable pieces
3. **Inherit metadata**: Subtasks typically share project/context with parent
4. **Track progress visually**: Use progress badges to see completion status at a glance
5. **Complete in order**: Mark subtasks done before completing parent (or use auto-complete)

## Example: Website Redesign Project

```
📋 Complete website redesign (0/3 complete) #high
  ✅ Design homepage mockup (done)
  🔲 Implement responsive layout (in progress)
    ✅ Mobile breakpoint (done)
    🔲 Tablet breakpoint (pending)
    🔲 Desktop breakpoint (pending)
  🔲 Test on multiple devices (pending)
```

This structure provides clear organization, progress tracking, and helps break down large projects into actionable steps.

## Implementation Details

### Data Integrity

- Orphaned subtasks: If parent is deleted, subtasks can optionally be:
  - Promoted to top-level tasks (preserve work)
  - Deleted along with parent (cleanup)

- Circular references: Prevented by validation logic
  - Cannot set task's own ID as parent
  - Cannot create circular parent chains

### Performance

- Subtask queries use array filtering (O(n))
- Indentation calculation traverses parent chain (O(d) where d = depth)
- For large task lists, consider caching hierarchy information

### File System Organization

Tasks remain in flat directory structure:
```
tasks/
  active/
    2025/
      11/
        uuid1-complete-website-redesign.md     (parent)
        uuid2-design-homepage-mockup.md        (subtask 1)
        uuid3-implement-responsive-layout.md   (subtask 2)
```

Hierarchy is maintained through `parentId` and `subtaskIds` in YAML frontmatter, not directory structure.
