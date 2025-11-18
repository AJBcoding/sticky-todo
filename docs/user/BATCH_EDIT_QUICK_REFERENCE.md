# Batch Edit Quick Reference Guide

Efficiently manage multiple tasks at once with StickyToDo's powerful batch edit features.

## Quick Start

### Entering Batch Edit Mode

**SwiftUI:**
1. Click the **"Select"** button in the toolbar, OR
2. Press **Cmd+Shift+E**

**AppKit:**
1. Select multiple tasks using **Cmd+Click** or **Shift+Click**, OR
2. Press **Cmd+A** to select all tasks

### Selecting Tasks

**SwiftUI (Batch Edit Mode):**
- Click checkboxes to select individual tasks
- Click **"Select All"** to select all visible tasks
- Click **"Deselect All"** to clear selection

**AppKit (Native Selection):**
- **Cmd+Click** - Add/remove individual tasks from selection
- **Shift+Click** - Select range of tasks
- **Cmd+A** - Select all tasks in list

### Applying Batch Operations

**SwiftUI:**
- Click **"Batch Actions"** dropdown for full menu
- Use quick action buttons: ✓ (Complete) or 🗑️ (Delete)
- Use keyboard shortcuts (see below)

**AppKit:**
- Click **"Batch Actions"** button in batch toolbar
- Use quick action buttons when tasks are selected
- Use keyboard shortcuts

## Supported Operations

### Status Management
- Complete, Uncomplete
- Set to Inbox, Next Action, Waiting, Someday/Maybe

### Priority Management
- High, Medium, Low

### Organization
- Set/Clear Project, Set/Clear Context

### Dates & Timing
- Set/Clear Due Date, Set/Clear Defer Date

### Flags & Actions
- Flag, Unflag, Archive, Delete

## Keyboard Shortcuts

### SwiftUI

| Shortcut | Action |
|----------|--------|
| **Cmd+Shift+E** | Toggle batch edit mode |
| **Cmd+A** | Select all / Deselect all |
| **Cmd+Shift+P** | Set project |
| **Cmd+Shift+C** | Set context |
| **Cmd+Shift+F** | Flag tasks |
| **Cmd+Return** | Complete tasks |
| **Cmd+Delete** | Delete tasks |

### AppKit

| Shortcut | Action |
|----------|--------|
| **Cmd+Shift+E** | Toggle batch edit mode |
| **Cmd+A** | Select all tasks |
| **Cmd+Click** | Add to selection |
| **Shift+Click** | Select range |

## Tips & Best Practices

- Start with small batches (10-50 tasks)
- Use filters to narrow down selection
- Review selection count before applying
- Delete operations require confirmation
- Operations cannot be undone

---

**Last Updated:** 2025-11-18
**For full documentation, see:** `docs/implementation/BATCH_EDIT_IMPLEMENTATION_REPORT.md`
