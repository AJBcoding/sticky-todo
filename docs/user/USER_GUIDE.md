# StickyToDo User Guide

Welcome to StickyToDo, a flexible GTD (Getting Things Done) task manager that combines the power of plain-text markdown files with visual board interfaces.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Understanding GTD in StickyToDo](#understanding-gtd-in-stickytodo)
3. [Working with Tasks](#working-with-tasks)
4. [List Views and Perspectives](#list-views-and-perspectives)
5. [Board Views](#board-views)
6. [Quick Capture](#quick-capture)
7. [Organization Strategies](#organization-strategies)
8. [Advanced Features](#advanced-features)
9. [Tips and Tricks](#tips-and-tricks)
10. [Troubleshooting](#troubleshooting)

## Getting Started

### First Launch

When you first launch StickyToDo, you'll be prompted to select or create a data directory. This directory will contain all your tasks and boards as plain markdown files.

**Recommended location:**
- `~/Documents/StickyToDo` - For easy access and backup
- `~/Library/Mobile Documents/com~apple~CloudDocs/StickyToDo` - For iCloud sync

### Initial Setup

1. **Choose your data directory** - Select a location that's backed up (iCloud, Dropbox, etc.)
2. **Create sample tasks (optional)** - Try the sample tasks to learn the interface
3. **Set up contexts** - Go to Settings → Contexts to customize your work contexts
4. **Configure quick capture** - Set up the global hotkey (default: ⌘⇧Space)

## Understanding GTD in StickyToDo

StickyToDo implements the Getting Things Done (GTD) methodology with five core task statuses:

### Task Statuses

**Inbox** - New, unprocessed items
- All new tasks start here
- Process regularly (daily recommended)
- Decision point: Is it actionable?

**Next Actions** - Tasks ready to be worked on
- Clear, actionable items
- Can be done in one sitting
- Assigned to appropriate context

**Waiting For** - Blocked items
- Waiting for someone else
- Blocked by external factors
- Review weekly

**Someday/Maybe** - Future possibilities
- Ideas you might do later
- Review monthly
- No immediate action needed

**Completed** - Finished tasks
- Automatically archived
- Kept for record-keeping
- Can be searched later

### The GTD Workflow

```
1. CAPTURE → Everything goes to Inbox
2. CLARIFY → Process each inbox item
   - Is it actionable?
     - Yes → Next Action or Project
     - No → Trash, Someday, or Reference
3. ORGANIZE → Assign context, project, priority
4. REFLECT → Weekly review of all lists
5. ENGAGE → Work from Next Actions
```

## Working with Tasks

### Creating Tasks

**From Inbox View:**
1. Click the "+" button or press ⌘N
2. Enter task title
3. Add details in inspector

**From Quick Capture (⌘⇧Space):**
```
Call John @phone #Website !high tomorrow //30m
```

### Task Properties

**Title** - Brief description of the task

**Notes** - Detailed information in markdown
- Supports bullet lists
- Code blocks
- Links
- Images (as markdown links)

**Status** - Current GTD status
- Inbox → Next Action → Completed
- Inbox → Someday (for later)
- Inbox → Waiting (if blocked)

**Project** - Group related tasks
- Example: "Website Redesign"
- Auto-creates project boards
- View all tasks in project

**Context** - Where/how task is done
- @computer - Requires computer
- @phone - Phone calls
- @office - At the office
- @home - At home
- @errands - Out and about
- @anywhere - No specific context

**Priority** - Importance level
- High (!) - Urgent/important
- Medium - Normal
- Low - Can defer

**Due Date** - When task must be done
- Hard deadlines
- Separate from defer dates
- Triggers overdue warnings

**Defer Date** - When task becomes available
- Hide until start date
- Good for scheduled tasks
- Reduces noise in lists

**Effort** - Estimated time
- In minutes (30m) or hours (2h)
- Helps with planning
- Filter by available time

**Flagged** - Star for attention
- Quick visual marker
- Dedicated flagged view
- Use sparingly for impact

### Editing Tasks

**In List View:**
- Click task to select
- Press Return to edit title
- Press ⌘I for inspector
- Drag to reorder

**In Inspector:**
- Full access to all properties
- Rich markdown editor for notes
- Quick status changes
- Add/remove tags

**Keyboard Shortcuts:**
- ⌘N - New task
- ⌘I - Toggle inspector
- ⌘Delete - Delete task
- ⌘D - Duplicate task
- Space - Quick look

### Task Types

**Tasks** - Full GTD items
- Complete metadata
- All fields available
- Actionable items

**Notes** - Lightweight entries
- Simple brainstorming
- Minimal metadata
- Can promote to task later

**Promoting Notes:**
1. Select note
2. Right-click → Promote to Task
3. Add metadata in inspector

## List Views and Perspectives

### Built-in Perspectives

**Inbox** - Unprocessed items
- Review daily
- Process each item
- Empty regularly

**Next Actions** - Ready to work
- Grouped by context
- Sorted by priority
- Your main work list

**Flagged** - Starred items
- High importance
- Quick access
- Sorted by due date

**Due Soon** - Upcoming deadlines
- Next 7 days
- Grouped by date
- Daily review

**Waiting For** - Blocked items
- Grouped by project
- Review weekly
- Follow up reminders

**Someday/Maybe** - Future ideas
- Grouped by project
- Monthly review
- Incubate ideas

**All Active** - Everything
- Grouped by project
- Complete overview
- Weekly review

### Custom Perspectives

Create your own views:

1. Click "+" in sidebar
2. Choose "New Perspective"
3. Configure filters:
   - Status
   - Project
   - Context
   - Priority
   - Due date range
   - Effort
   - Flagged status
4. Set grouping:
   - None
   - Context
   - Project
   - Status
   - Priority
   - Due date
5. Choose sorting:
   - Title
   - Created
   - Modified
   - Due date
   - Priority
   - Effort

**Example Perspectives:**

*Quick Wins*
- Status: Next Action
- Effort: ≤ 30 minutes
- Priority: High
- Sort: Due date

*Computer Work*
- Context: @computer
- Status: Next Action
- Group by: Project
- Sort: Priority

*This Week*
- Due: Next 7 days
- Status: Next Action
- Group by: Due date
- Sort: Priority

### List View Features

**Search** (⌘F)
- Searches titles, notes, projects, contexts
- Real-time filtering
- Case-insensitive
- Supports partial matches

**Filtering**
- Quick filters in toolbar
- Combine multiple criteria
- Save as perspective
- Temporary filters

**Sorting**
- Click column headers
- Multiple sort keys
- Ascending/descending
- Persists per perspective

**Grouping**
- Collapsible sections
- Group headers show count
- Reorder groups by dragging
- Hide/show groups

## Board Views

StickyToDo offers three visual board layouts for different workflows.

### Freeform Boards

**Best for:** Brainstorming, mind mapping, spatial planning

**Features:**
- Infinite canvas
- Drag tasks anywhere
- Zoom in/out
- Pan around
- Sticky note appearance
- Color coding

**Use Cases:**
- Project planning
- Mind mapping
- Whiteboard sessions
- Visual thinking

**Tips:**
- Use spatial grouping
- Color by priority
- Arrange in flows
- Add notes as context

### Kanban Boards

**Best for:** Workflow management, process tracking

**Features:**
- Vertical swim lanes
- Drag between columns
- Auto-update metadata
- Column customization
- Work-in-progress limits (optional)

**Default Columns:**
- Status boards: Inbox | Next Actions | Waiting | Someday
- Project boards: To Do | In Progress | Done
- Custom boards: Define your own

**Moving Tasks:**
- Drag task to new column
- Status updates automatically
- Metadata preserved
- Position saved

**Use Cases:**
- Development workflow
- Content pipeline
- Sales process
- Project stages

### Grid Boards

**Best for:** Organized lists, category views

**Features:**
- Named sections
- Auto-arrange layout
- Compact view
- Quick filtering
- Batch operations

**Use Cases:**
- Grouped task lists
- Category organization
- Team workload
- Priority matrix

### Board Management

**Creating Boards:**
1. Click "+" in boards section
2. Choose board type:
   - Status - Organize by GTD status
   - Project - Group project tasks
   - Context - Filter by context
   - Custom - Define your own rules
3. Select layout (Freeform/Kanban/Grid)
4. Configure filters
5. Customize appearance

**Auto-Created Boards:**
- Context boards (@phone, @computer, etc.)
- Project boards (when you add #Project)
- Automatically hidden when inactive
- Re-appear when tasks added

**Board Settings:**
- Auto-hide - Hide after N days inactive
- Columns - Customize kanban lanes
- Filter - What tasks appear
- Layout - Switch between views
- Icon & Color - Personalize appearance

## Quick Capture

The fastest way to add tasks anywhere on your Mac.

### Activation

Press `⌘⇧Space` (customizable in Settings)

### Natural Language Syntax

**Basic Task:**
```
Buy groceries
```

**With Context:**
```
Call doctor @phone
```

**With Project:**
```
Review mockups #Website
```

**With Priority:**
```
Fix bug !high
OR
Fix bug !h
```

**With Due Date:**
```
Submit report tomorrow
Submit report friday
Submit report nov 20
Submit report next week
```

**With Defer Date:**
```
Start project ^defer:monday
```

**With Effort:**
```
Write email //15m
Code feature //2h
```

**Complete Example:**
```
Call John about proposal @phone #SalesProject !high tomorrow //30m
```

**Result:**
- Title: "Call John about proposal"
- Context: @phone
- Project: SalesProject
- Priority: High
- Due: Tomorrow
- Effort: 30 minutes
- Status: Inbox (default)

### Quick Capture Tips

1. **Keep it simple** - Start with just title, add details later
2. **Use abbreviations** - !h for high, //15 for 15 minutes
3. **Natural dates** - "tomorrow", "friday", "next week" all work
4. **Multi-word projects** - Use underscores: #Website_Redesign
5. **Review inbox** - Process quick-captured items regularly

## Organization Strategies

### Processing Inbox

**Daily Routine (5-10 minutes):**

For each inbox item, ask:

1. **What is it?**
   - Clarify unclear items
   - Add notes if needed

2. **Is it actionable?**
   - YES: Continue to #3
   - NO: Delete, Someday, or Reference

3. **What's the next action?**
   - Make it specific and concrete
   - "Email John re: meeting" not "Deal with John"

4. **Where/when can I do it?**
   - Assign context
   - Set defer date if applicable

5. **How important?**
   - Set priority
   - Flag if urgent

6. **How long?**
   - Estimate effort
   - Helps with planning

7. **Move to Next Actions**
   - Ready to work on
   - Properly categorized

### Weekly Review

**Recommended: Friday afternoon or Sunday evening**

1. **Clear inbox** (Process all items)
2. **Review next actions** (Still relevant?)
3. **Check waiting for** (Follow up needed?)
4. **Scan someday/maybe** (Move to active?)
5. **Review projects** (All projects have next action?)
6. **Look ahead** (Prepare for next week)
7. **Update contexts** (Life changes?)

### Project Management

**Projects vs. Single Tasks:**
- Project = Outcome requiring multiple steps
- Single Task = Done in one sitting

**Project Setup:**
1. Create project board (automatic with #ProjectName)
2. Add all known next actions
3. Review weekly
4. Always have at least one next action per active project

**Project Completion:**
1. Mark all tasks complete
2. Board auto-hides after 7 days
3. Still searchable in archive
4. Review what worked/didn't work

### Context Usage

**Setting Up Contexts:**

Think about:
- **Tools needed** (@computer, @phone)
- **Location** (@office, @home, @errands)
- **People** (@boss, @team)
- **Energy** (@high-energy, @low-energy)
- **Time available** (@10-minutes, @30-minutes)

**Working from Contexts:**
1. Choose context (where you are/what you have)
2. Sort by priority
3. Pick highest-priority task you can do
4. Work until done or blocked
5. Repeat

## Advanced Features

### File-Based Storage

All data stored as plain markdown files:

**Benefits:**
- Version control with git
- Edit in any text editor
- Sync with Dropbox/iCloud/etc.
- Future-proof format
- Easy backup

**File Structure:**
```
StickyToDo/
  tasks/
    active/
      2025/
        01/
          uuid-task-title.md
    archive/
      2025/
        01/
          uuid-completed-task.md
  boards/
    inbox.md
    next-actions.md
    custom-board.md
  config/
    contexts.yaml
    settings.yaml
```

**Direct Editing:**
- Edit files in VS Code, Obsidian, etc.
- StickyToDo watches for changes
- Auto-reloads modified files
- Conflict detection

### Custom Workflows

**Pomodoro Integration:**
1. Create "@pomodoro" context
2. Filter tasks by //25m effort
3. Work through list
4. Track completions

**Email Processing:**
1. Forward emails to processing folder
2. Create tasks from emails
3. Link back to email
4. Archive or delete email

**Code Reviews:**
1. Create "Code Review" project
2. Add @computer context
3. Set //30m effort default
4. Process in batches

## Tips and Tricks

### Productivity Tips

1. **Start with Next Actions** - Don't check inbox first
2. **Process inbox to zero daily** - Decide and move on
3. **One next action per project** - At minimum
4. **Weekly review is sacred** - Schedule it
5. **Defer dates reduce noise** - Use liberally
6. **Flag sparingly** - Loses meaning if overused
7. **Batch similar tasks** - Group by context
8. **Review waiting weekly** - Follow up proactively
9. **Someday needs attention** - Monthly review minimum
10. **Effort estimates improve** - Track actual vs. estimated

### Interface Tips

1. **Learn keyboard shortcuts** - Much faster
2. **Customize sidebar** - Show what you use
3. **Create custom perspectives** - Your workflow
4. **Use quick capture everywhere** - Capture immediately
5. **Multiple windows** - Work on multiple projects
6. **Split view** - List + Board simultaneously
7. **Search is powerful** - Use it often
8. **Drag files to notes** - Attach references
9. **Use templates** - Recurring task patterns
10. **Theme matters** - Choose comfortable colors

### File Management Tips

1. **Regular backups** - Even with sync
2. **Git repository** - Track changes
3. **Archive old projects** - Keep it clean
4. **Search archive** - Don't delete
5. **Export completed** - Annual review
6. **Sync carefully** - Avoid conflicts
7. **Offline works** - Syncs later
8. **Text editor backup** - Always available
9. **Markdown export** - Portable format
10. **Regular cleanup** - Purge old somedays

## Troubleshooting

### Tasks Not Syncing

**Check:**
1. File permissions in data directory
2. Sync service status (iCloud, Dropbox)
3. Disk space available
4. File watcher enabled in settings
5. No conflicted copies

**Fix:**
1. Quit StickyToDo
2. Ensure sync is complete
3. Relaunch StickyToDo
4. Check for duplicate tasks
5. Resolve any conflicts

### Missing Tasks

**Possible Causes:**
1. Filtered out by current perspective
2. Deferred to future date
3. Archived (completed)
4. Deleted by accident
5. File sync issue

**Solutions:**
1. Check "All Active" perspective
2. Check due/defer dates
3. Search in archive
4. Check trash/recents
5. Restore from backup

### Performance Issues

**If slow:**
1. Archive old completed tasks
2. Reduce number of boards
3. Limit file watcher scope
4. Increase debounce interval
5. Close unused windows

**If crashes:**
1. Check crash logs
2. Reset preferences
3. Rebuild database
4. Reinstall app
5. Contact support

### File Conflicts

**When editing externally:**
1. StickyToDo detects conflicts
2. Choose version to keep:
   - Disk version (external edit)
   - App version (StickyToDo's)
3. Merge manually if needed
4. Save resolved version

**Prevention:**
1. Pause sync when editing externally
2. Edit one file at a time
3. Use StickyToDo's inspector
4. Commit changes in git
5. Sync before/after editing

### Getting Help

**Resources:**
- [Keyboard Shortcuts](KEYBOARD_SHORTCUTS.md)
- [File Format Specification](FILE_FORMAT.md)
- [Development Guide](DEVELOPMENT.md)
- GitHub Issues
- Community Forum
- Email Support

**When Reporting Issues:**
1. Include macOS version
2. StickyToDo version
3. Steps to reproduce
4. Expected vs. actual behavior
5. Sample files (if relevant)
6. Crash logs (if applicable)

---

## Quick Reference Card

### Essential Shortcuts
- `⌘N` - New task
- `⌘⇧Space` - Quick capture
- `⌘I` - Toggle inspector
- `⌘F` - Search
- `⌘1-7` - Switch perspectives

### GTD Workflow
1. Capture → Inbox
2. Clarify → Process
3. Organize → Context + Project
4. Reflect → Weekly review
5. Engage → Next Actions

### Quick Capture Format
```
Title @context #project !priority due_date //effort
```

### When in Doubt
- Inbox for capture
- Next Actions for work
- Weekly review for maintenance
- Search for finding
- Archive for history

Happy Getting Things Done!
