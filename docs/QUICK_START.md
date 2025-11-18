# StickyToDo Quick Start Guide

Get up and running with StickyToDo in 5 minutes. This guide covers the essentials to start managing your tasks effectively.

## Table of Contents

- [Installation](#installation)
- [First Launch](#first-launch)
- [Create Your First Task](#create-your-first-task)
- [Use Perspectives](#use-perspectives)
- [Try the Board Canvas](#try-the-board-canvas)
- [Quick Capture Anywhere](#quick-capture-anywhere)
- [Next Steps](#next-steps)

---

## Installation

### Download and Install

1. Download StickyToDo from the [Releases page](https://github.com/yourusername/sticky-todo/releases)
2. Unzip the downloaded file
3. Drag **StickyToDo.app** to your Applications folder
4. Double-click to launch

### System Requirements

- macOS 14.0 (Sonoma) or later
- 50 MB free disk space
- Recommended: 100+ MB for task data storage

---

## First Launch

When you first open StickyToDo, you'll be prompted to set up your data directory.

### Choose Your Data Location

Pick where to store your tasks:

**Option 1: Local (Recommended for beginners)**
```
~/Documents/StickyToDo
```
- Easy to find
- Simple to backup
- Good for local-only use

**Option 2: iCloud (Recommended for sync)**
```
~/Library/Mobile Documents/com~apple~CloudDocs/StickyToDo
```
- Syncs across devices
- Automatic cloud backup
- Accessible from multiple Macs

**Option 3: Dropbox/Other**
```
~/Dropbox/StickyToDo
```
- Works with any sync service
- Share with team members
- Version history through Dropbox

### Initial Setup

After choosing your location:

1. **Sample Data** (Optional)
   - Click "Create Sample Tasks" to explore features
   - Or click "Skip" to start fresh

2. **Configure Quick Capture**
   - Press the suggested hotkey (⌘⇧Space)
   - Or customize in Settings → Quick Capture

3. **Set Up Contexts**
   - Review default contexts (@office, @home, @phone, etc.)
   - Customize in Settings → Contexts

4. **You're Ready!**
   - The main window opens to your Inbox

---

## Create Your First Task

Let's create a task using the GTD methodology.

### Method 1: In-App Creation

1. **Press ⌘N** or click the **+ button**
2. **Type your task**: `Call dentist to schedule appointment`
3. **Press Return** to save
4. **Open the inspector** (⌘I) to add details:
   - **Context**: @phone
   - **Project**: Personal Health
   - **Priority**: Medium
   - **Due Date**: Friday
   - **Effort**: 15 minutes
5. **Press ⌘Return** to save and close

**Result**: Your task appears in the Inbox, ready to be processed.

### Method 2: Natural Language (Faster!)

1. **Type in the quick add field**:
   ```
   Call dentist @phone #Health friday //15m
   ```

2. **Press Return**

**StickyToDo automatically extracts**:
- Title: "Call dentist"
- Context: @phone
- Project: Health
- Due: This Friday
- Effort: 15 minutes

**Supported Syntax**:
- `@context` - Where/how to do it
- `#project` - Which project
- `!priority` - !high, !medium, !low
- `tomorrow`, `friday`, `nov 20` - Due dates
- `^defer:monday` - Don't show until Monday
- `//30m` or `//2h` - Time estimate

---

## Use Perspectives

Perspectives are smart views that filter your tasks. They're the heart of GTD workflow.

### Essential Perspectives

**Press ⌘1 - Inbox**
- All unprocessed tasks
- Process daily to zero
- Decide: Is it actionable?

**Press ⌘2 - Next Actions**
- Ready-to-work tasks
- Grouped by context
- Your main work list

**Press ⌘3 - Flagged**
- Starred for attention
- Today's priorities
- Use sparingly for impact

**Press ⌘4 - Due Soon**
- Tasks due in next 7 days
- Grouped by date
- Check daily

**Press ⌘5 - Waiting For**
- Blocked or delegated items
- Review weekly
- Follow up proactively

**Press ⌘6 - Someday/Maybe**
- Future possibilities
- No immediate action
- Review monthly

**Press ⌘7 - All Active**
- Everything not completed
- Complete overview
- Use for weekly review

### Your First Workflow

**Morning Routine (5 minutes)**:
1. Press ⌘4 - Check what's due soon
2. Press ⌘3 - Review flagged items
3. Press ⌘2 - See next actions by context
4. Start working from your current context

**Daily Processing (10 minutes)**:
1. Press ⌘1 - Go to Inbox
2. For each item:
   - What is it?
   - Is it actionable?
   - Where can I do it? (add @context)
   - When is it due? (add due date if needed)
   - Move to Next Actions (⌘⌥2)
3. Get to Inbox Zero

---

## Try the Board Canvas

Boards provide a visual way to organize and plan tasks.

### Create Your First Board

1. **Click "+" next to Boards** in the sidebar
2. **Choose "Custom Board"**
3. **Name it**: "This Week"
4. **Select Layout**: Freeform
5. **Set Filter**: Flagged: Yes
6. **Click Create**

**Result**: A visual canvas with all your flagged tasks.

### Freeform Canvas Basics

**Navigate the Canvas**:
- **Pan**: Hold Option and drag
- **Zoom In**: ⌘+
- **Zoom Out**: ⌘-
- **Reset**: ⌘0
- **Fit All**: ⌘⇧0

**Work with Tasks**:
- **Move**: Drag task to new position
- **Select**: Click task
- **Multi-select**: ⌘-click multiple tasks
- **Lasso**: Click and drag in empty space
- **Edit**: Double-click task

**Add Tasks to Board**:
1. Press ⌘N while viewing board
2. Type task title
3. Task appears on canvas
4. Drag to organize spatially

### Try Kanban Layout

1. **Create another board**: "Website Project"
2. **Select Layout**: Kanban
3. **Set Filter**: Project: Website
4. **Configure Columns**:
   - To Do
   - In Progress
   - Done
5. **Drag tasks** between columns to update status

**Tip**: Moving tasks between Kanban columns automatically updates their status!

### Grid Layout for Lists

1. **Create a board**: "Quick Wins"
2. **Select Layout**: Grid
3. **Set Filter**:
   - Status: Next Action
   - Effort: ≤ 30 minutes
4. **View**: Organized, compact task list

---

## Quick Capture Anywhere

The global hotkey lets you capture tasks from anywhere on your Mac.

### Set Up Quick Capture

1. **Go to Settings** (⌘,)
2. **Click "Quick Capture"**
3. **Set your hotkey** (default: ⌘⇧Space)
4. **Click "Enable Global Hotkey"**

### Use Quick Capture

**From anywhere on your Mac**:

1. **Press ⌘⇧Space**
2. **Type your task**:
   ```
   Buy groceries @errands #Personal tomorrow
   ```
3. **Press Return** to save
4. **Or ⌘Return** to save and add another

**The task is captured** and you're back to what you were doing!

### Quick Capture Examples

**Simple task**:
```
Call John
```

**Task with context**:
```
Email proposal @computer
```

**Complete task with all metadata**:
```
Review contract @office #Legal !high friday //1h
```

**Multiple tasks** (press ⌘Return after each):
```
Buy milk @errands
Call dentist @phone tomorrow
Review code @computer #Dev !high
```

**Tip**: Add notes later. Quick capture is about speed!

---

## Next Steps

### Learn More Features

**Explore the User Guide**:
- Read the complete [User Guide](USER_GUIDE.md)
- Review [Keyboard Shortcuts](KEYBOARD_SHORTCUTS.md)
- Understand [File Format](FILE_FORMAT.md)

**Try Advanced Features**:
- Recurring tasks (daily standup, weekly review)
- Subtasks (break down projects)
- Task templates (meeting notes, project kickoff)
- Automation rules (auto-assign contexts)
- Time tracking (see where time goes)
- Search with operators (find tasks fast)

### Set Up Your GTD System

**Week 1: Basic Capture**
- Use quick capture exclusively
- Process inbox daily
- Don't worry about perfection

**Week 2: Add Contexts**
- Customize your contexts
- Assign contexts to all tasks
- Work from Next Actions view

**Week 3: Add Projects**
- Group related tasks
- Create project boards
- Review projects weekly

**Week 4: Weekly Review**
- Schedule weekly review time
- Process to inbox zero
- Review all perspectives
- Plan next week

### Customize Your Workflow

**Settings to Explore** (⌘,):
- **General**: Data directory, theme, language
- **Contexts**: Customize where you work
- **Quick Capture**: Hotkey and defaults
- **Perspectives**: Create custom views
- **Boards**: Default layouts and filters
- **Keyboard**: Customize shortcuts
- **Notifications**: Due date reminders
- **Advanced**: Auto-save, file watching

### Get Help

**Resources**:
- [User Guide](USER_GUIDE.md) - Complete documentation
- [FAQ](FAQ.md) - Common questions
- [Features](FEATURES.md) - All 25+ features explained
- [GitHub Issues](https://github.com/yourusername/sticky-todo/issues) - Report bugs
- [Discussions](https://github.com/yourusername/sticky-todo/discussions) - Ask questions

**Community**:
- Share your workflows
- Learn from power users
- Suggest features
- Contribute improvements

---

## Quick Reference Card

### Essential Shortcuts
- `⌘⇧Space` - Quick capture (global)
- `⌘N` - New task
- `⌘I` - Toggle inspector
- `⌘F` - Search
- `⌘1-7` - Switch perspectives
- `Space` - Mark complete
- `⌘Delete` - Delete task

### GTD Workflow
1. **Capture** → Inbox (⌘⇧Space anywhere)
2. **Clarify** → Process inbox (⌘1)
3. **Organize** → Assign context + project
4. **Reflect** → Weekly review (⌘7)
5. **Engage** → Work from Next Actions (⌘2)

### Quick Capture Syntax
```
Task title @context #project !priority date //effort
```

**Examples**:
- `@phone` - Context
- `#Website` - Project
- `!high` - Priority
- `tomorrow` - Due date
- `//30m` - 30 minutes effort

### Board Layouts
- **Freeform** - Infinite canvas, spatial planning
- **Kanban** - Workflow columns, status tracking
- **Grid** - Organized sections, compact view

---

**Congratulations!** You're ready to Get Things Done with StickyToDo.

**Remember**: Start simple, build habits, then add complexity. The power of GTD comes from consistent use, not from having every feature configured perfectly on day one.

**Your tasks. Your format. Your control.**

---

*For detailed information, see the [complete User Guide](USER_GUIDE.md)*
