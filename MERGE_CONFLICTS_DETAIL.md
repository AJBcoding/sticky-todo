# Merge Conflicts: v1.0 Polish Phase Branch

Branch: `claude/parallel-agents-work-assessment-01MCdtb5bfzLd2GJ4Sd2vhLw` → `main`

## Overview

There are **3 files with merge conflicts** that need to be resolved before this branch can be merged into main.

---

## Conflict 1: README.md

**Location:** Documentation section

**Issue:** Both branches reorganized the documentation structure in different ways.

### Main Branch (HEAD):
- Simple, flat documentation structure with direct links
- Three categories: Getting Started, Reference, Advanced
- Links directly to files in `docs/` directory
- Examples:
  - `docs/QUICK_START.md`
  - `docs/USER_GUIDE.md`
  - `docs/FAQ.md`

### Polish Phase Branch:
- Hierarchical documentation structure with subdirectories
- Five main categories: Users, Developers, Technical & Planning, Features, Project Status
- Links to organized subdirectories
- Examples:
  - `docs/user/USER_GUIDE.md`
  - `docs/developer/DEVELOPMENT.md`
  - `docs/technical/FILE_FORMAT.md`

**Resolution Strategy:**
Choose the polish phase branch's hierarchical structure (it's more scalable and professional) OR merge both approaches by keeping main's simple links but updating paths to match the new directory structure.

**Recommendation:** Use the polish phase structure - it's part of the documentation consolidation effort (Agent 8) that organized 68 files into 11 categorized directories.

---

## Conflict 2: StickyToDo-SwiftUI/Views/ListView/TaskListView.swift

**Location:** Task row rendering in LazyVStack (appears twice - once for active tasks, once for completed tasks)

**Issue:** Different implementations for rendering task rows

### Main Branch (HEAD):
```swift
TaskListItemView(
    task: task,
    isSelected: selectedTaskIds.contains(task.id),
    onTap: {
        handleTaskTap(task)
    },
    onToggleComplete: {
        toggleTaskCompletion(task)
    }
)
.id(task.id)

Divider()
    .padding(.leading, DesignSystem.Spacing.xxl + DesignSystem.Spacing.sm)
```
- Explicit `TaskListItemView` with inline callbacks
- Includes selection state (`isSelected`)
- Manual divider with specific padding using `DesignSystem.Spacing`

### Polish Phase Branch:
```swift
taskRow(task)
```
- Refactored into a helper function `taskRow(task)`
- Cleaner, more maintainable code
- Likely consolidates the task row logic in one place

**Resolution Strategy:**
1. Check if `taskRow(task)` helper function exists in the polish phase branch
2. Verify it includes all functionality from main (selection, callbacks, divider)
3. If yes, use the polish phase version (cleaner)
4. If no, keep main's explicit version OR enhance the helper to include missing features

**Recommendation:** Use the polish phase `taskRow(task)` helper IF it contains all the selection and DesignSystem features. This is likely part of the context menu enhancements (Agent 6).

---

## Conflict 3: StickyToDo/Views/ListView/PerspectiveSidebarView.swift

**Location:** Context menu for smart perspectives

**Issue:** Different context menu implementations

### Main Branch (HEAD):
```swift
.contextMenu {
    Button("Edit") {
        perspectiveToEdit = smartPerspective
        showingPerspectiveEditor = true
    }
    Button("Duplicate") {
        var duplicated = smartPerspective
        duplicated.name = "\(smartPerspective.name) Copy"
        perspectiveStore.create(duplicated)
    }
    Divider()
    Button("Delete", role: .destructive) {
        perspectiveStore.delete(smartPerspective)
    }
}
```
- Inline context menu with 3 actions
- Edit, Duplicate, Delete functionality

### Polish Phase Branch:
```swift
.contextMenu {
    perspectiveContextMenu(for: smartPerspective)
}
```
- Refactored into a helper function `perspectiveContextMenu(for:)`
- Part of the context menu enhancements (80+ menu items across 6 views)

**Resolution Strategy:**
1. Check the `perspectiveContextMenu(for:)` helper function in the polish phase branch
2. Verify it includes Edit, Duplicate, and Delete actions from main
3. Check if it adds additional menu items (likely, given Agent 6's work)
4. Use the polish phase version if it's a superset of main's functionality

**Recommendation:** Use the polish phase `perspectiveContextMenu(for:)` helper - this is part of Agent 6's comprehensive context menu enhancement work that added 80+ context menu items and 20+ keyboard shortcuts across 6 views.

---

## Resolution Approach

### Option 1: Accept All Polish Phase Changes (Recommended)
The polish phase branch represents a comprehensive refactoring and enhancement effort. If the helper functions contain all the functionality from main plus enhancements, accept all polish phase changes.

**Pros:**
- Cleaner, more maintainable code
- Part of coordinated v1.0 polish effort
- Includes enhancements (80+ context menus, better organization)

**Cons:**
- Need to verify helper functions contain all features
- May need to review and test extensively

### Option 2: Selective Merge
Keep main's explicit implementations but incorporate polish phase's documentation structure.

**Pros:**
- More conservative approach
- Keep proven code from main

**Cons:**
- Miss out on polish enhancements
- More work to merge manually

### Option 3: Hybrid Approach
1. **README.md**: Use polish phase's hierarchical structure
2. **TaskListView.swift**: Verify `taskRow()` contains selection + DesignSystem features, then use polish phase version
3. **PerspectiveSidebarView.swift**: Verify `perspectiveContextMenu()` contains all actions, then use polish phase version

---

## Testing After Resolution

After resolving conflicts, test these areas:
1. **Documentation links** - Verify all README links work
2. **Task list selection** - Multi-select should work in task lists
3. **Context menus** - All perspective context menu items should appear
4. **Keyboard shortcuts** - Verify shortcuts still work
5. **Visual consistency** - Check dividers and spacing in task lists

---

## Commands to Resolve

```bash
# Checkout the polish phase branch
git checkout claude/parallel-agents-work-assessment-01MCdtb5bfzLd2GJ4Sd2vhLw

# Create a merge branch
git checkout -b merge-v1.0-polish

# Merge main into this branch
git merge main

# Resolve conflicts in each file
# For README.md: Accept polish phase structure (theirs)
git checkout --theirs README.md

# For the Swift files: Manually review and merge
# Open in editor and choose appropriate sections
code StickyToDo-SwiftUI/Views/ListView/TaskListView.swift
code StickyToDo/Views/ListView/PerspectiveSidebarView.swift

# After resolving all conflicts
git add .
git commit -m "Merge main into v1.0 polish phase branch"

# Push the merge commit
git push origin merge-v1.0-polish

# Create PR from merge-v1.0-polish to main
```

---

## File-by-File Resolution Guide

### README.md
```bash
# Accept polish phase version (better structure)
git checkout --theirs README.md
```

### TaskListView.swift
Check if `taskRow(task)` function exists and contains:
- Selection handling (`isSelected` parameter)
- Task tap callback
- Toggle completion callback
- Divider with DesignSystem spacing

If yes, accept polish phase version:
```bash
git checkout --theirs StickyToDo-SwiftUI/Views/ListView/TaskListView.swift
```

If no, manually merge or keep main version.

### PerspectiveSidebarView.swift
Check if `perspectiveContextMenu(for:)` function contains:
- Edit action
- Duplicate action
- Delete action with destructive role

If yes, accept polish phase version:
```bash
git checkout --theirs StickyToDo/Views/ListView/PerspectiveSidebarView.swift
```

If enhanced with additional items, definitely use polish phase version.
