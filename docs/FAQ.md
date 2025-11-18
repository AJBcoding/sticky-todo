# StickyToDo - Frequently Asked Questions

Common questions, troubleshooting tips, and best practices for using StickyToDo effectively.

## Table of Contents

- [Getting Started](#getting-started)
- [Task Management](#task-management)
- [Boards and Views](#boards-and-views)
- [Sync and Data](#sync-and-data)
- [Search and Filtering](#search-and-filtering)
- [Automation and Advanced Features](#automation-and-advanced-features)
- [Troubleshooting](#troubleshooting)
- [Tips for Power Users](#tips-for-power-users)
- [Known Limitations](#known-limitations)

---

## Getting Started

### Q: What is StickyToDo?

**A**: StickyToDo is a macOS task management app that combines OmniFocus-style GTD (Getting Things Done) methodology with Miro-style visual boards. It stores all data in plain-text markdown files, giving you full ownership and portability of your tasks.

---

### Q: What makes StickyToDo different from other task managers?

**A**: Three key differences:

1. **Plain Text Storage** - All tasks stored as readable markdown files. Edit in any text editor, version control with git, sync with any service.

2. **Dual Mode Design** - Equal support for traditional list views and visual board views. Switch seamlessly based on your task.

3. **Boards as Filters** - Boards don't contain tasks; they filter and display them. Single source of truth, no duplication.

---

### Q: Do I need to know markdown to use StickyToDo?

**A**: No. StickyToDo handles all the markdown for you. However, knowing markdown is helpful if you want to:
- Edit files in external editors
- Add rich formatting to task notes
- Use git for version control
- Script task creation

---

### Q: What is GTD (Getting Things Done)?

**A**: GTD is a productivity methodology by David Allen. Key concepts:

- **Capture** everything that has your attention
- **Clarify** what each item means and what to do
- **Organize** into appropriate categories
- **Reflect** regularly (weekly review)
- **Engage** with confidence

StickyToDo implements this with Inbox → Next Actions → Complete workflow.

---

### Q: Where should I store my StickyToDo data?

**A**: Three recommended options:

**Option 1: Local Directory (Simplest)**
```
~/Documents/StickyToDo
```
- Easy to find and backup
- Full control
- Fast access

**Option 2: iCloud (Best for sync)**
```
~/Library/Mobile Documents/com~apple~CloudDocs/StickyToDo
```
- Syncs across Macs
- Automatic backup
- Apple ecosystem integration

**Option 3: Dropbox/Other**
```
~/Dropbox/StickyToDo
```
- Third-party sync service
- Version history
- Team collaboration potential

---

### Q: Can I move my data directory later?

**A**: Yes!

1. Quit StickyToDo
2. Move entire directory to new location
3. Launch StickyToDo
4. When prompted, select new location
5. All tasks and settings preserved

**Important**: Don't move files while StickyToDo is running.

---

## Task Management

### Q: What's the difference between a note and a task?

**A**:
- **Note** - Lightweight item for quick capture, minimal metadata
- **Task** - Full GTD item with all metadata (project, context, priority, etc.)

**Tip**: Start with notes during brainstorming, promote to tasks when you're ready to act.

---

### Q: How do I promote a note to a task?

**A**:
1. Right-click the note
2. Select "Promote to Task"
3. Or simply add metadata (@context, #project, etc.)
4. Note automatically becomes a task

---

### Q: Should I use tags or projects?

**A**: Use both! They serve different purposes:

**Projects** - Group tasks toward a single outcome
- Example: "Website Redesign"
- All tasks must be complete for project to be done
- Projects have a finish line

**Tags** - Cross-cutting categories
- Example: #urgent, #waiting-response, #5-minutes
- Tags categorize by theme, not outcome
- Tags are persistent across projects

---

### Q: How do I handle tasks that belong to multiple projects?

**A**: StickyToDo supports one project per task, but you can:

1. **Use Tags** - Add tags for secondary categorization
2. **Use Parent Tasks** - Create a parent task that links related items
3. **Use Boards** - Create a board that filters both projects
4. **Duplicate** - Create separate task instances (for different aspects)

---

### Q: What does "defer date" mean?

**A**: Defer date (also called "start date") hides the task until that date arrives.

**Use when**:
- Task can't be done until a specific date
- Waiting for something before you can start
- Want to reduce noise in your lists
- Scheduling recurring tasks

**Example**:
```
Task: Review Q4 report
Defer: Dec 1 (when report is available)
Due: Dec 5 (when review must be done)

Result: Task hidden until Dec 1, then appears in Next Actions
```

---

### Q: How do I handle really big tasks?

**A**: Break them down using subtasks:

1. Create main task: "Launch Website"
2. Add subtasks (⌘N, then ⌘] to indent):
   - Design mockups
   - Write content
   - Build site
   - Deploy to production
3. Work on one subtask at a time
4. Parent completes when all children are done

**Or use a project board** to visualize all related tasks.

---

### Q: Can I have recurring tasks?

**A**: Yes! StickyToDo has full recurring task support:

1. Create task
2. Open inspector (⌘I)
3. Click "Add Recurrence"
4. Choose pattern:
   - Daily (every N days)
   - Weekly (every N weeks, specific days)
   - Monthly (every N months)
   - Yearly (every N years)
5. Set end condition (never, after N times, on date)

**When you complete a recurring task**, the next occurrence is automatically created.

---

## Boards and Views

### Q: What's the difference between perspectives and boards?

**A**:

**Perspectives** (List View)
- Filter tasks into lists
- Grouped by context, project, etc.
- Keyboard shortcuts (⌘1-7)
- Best for processing and reviewing

**Boards** (Visual View)
- Filter tasks into visual layouts
- Three layouts: Freeform, Kanban, Grid
- Best for planning and organizing
- Spatial/visual thinking

**Use both!** They're complementary, not competing.

---

### Q: When should I use Freeform vs Kanban vs Grid?

**A**:

**Freeform** (infinite canvas)
- Brainstorming
- Mind mapping
- Project planning
- Spatial organization
- Non-linear thinking

**Kanban** (columns)
- Workflow tracking
- Process management
- Status visualization
- Sequential steps
- Agile/Scrum

**Grid** (sections)
- Organized lists
- Category views
- Compact display
- Grouped tasks
- Quick overview

---

### Q: If I move a task on a board, does it move the actual task?

**A**: The task doesn't "move" because boards are filters, but:

**Freeform**: Position is saved per board
- Task stays in same location when you return
- Positions saved in task metadata

**Kanban**: Moving between columns updates task status
- Left to right typically means progress
- Column rules auto-apply metadata

**Grid**: Tasks auto-arrange by grouping
- Position not manually controllable
- Groups expand/collapse

---

### Q: Can a task appear on multiple boards?

**A**: Yes! This is a core feature.

**How it works**:
- Boards filter tasks, they don't contain them
- Single source of truth (the task file)
- Task appears on any board where it matches the filter
- Edit once, updates everywhere

**Example**:
```
Task: "Call John @phone #Sales !high"

Appears on:
- @phone context board (matches @phone)
- Sales project board (matches #Sales)
- High Priority board (matches !high)
- Next Actions board (matches status)
```

---

### Q: Why did my project board disappear?

**A**: Boards can auto-hide when inactive.

**Reason**: No active tasks matching the filter for 7+ days

**To find it**:
1. Settings → Boards
2. Show "Hidden Boards"
3. Find your board
4. Click "Show" to unhide

**To prevent auto-hide**:
1. Edit board
2. Uncheck "Auto-hide when inactive"

---

## Sync and Data

### Q: How do I sync between multiple Macs?

**A**: Use a sync service:

**Option 1: iCloud (Easiest)**
1. Set data directory to iCloud location on first Mac
2. On second Mac, select same iCloud location
3. Both Macs now share data

**Option 2: Dropbox**
1. Same process as iCloud
2. Install Dropbox on both Macs
3. Point both to Dropbox folder

**Important**:
- Don't run StickyToDo on multiple Macs simultaneously
- Let sync complete before switching machines
- Use file watcher to detect external changes

---

### Q: Can I edit task files in a text editor while StickyToDo is running?

**A**: Yes! StickyToDo watches for external changes.

**How to do it safely**:
1. Open task file in VS Code, Obsidian, etc.
2. Make your edits
3. Save file
4. StickyToDo automatically reloads
5. Changes appear immediately

**Conflict handling**:
- If StickyToDo has unsaved changes, you'll see a conflict dialog
- Choose: Keep file version or keep app version
- Or manually merge

---

### Q: Can I use git for version control?

**A**: Absolutely! This is a designed use case.

**Setup**:
```bash
cd ~/Documents/StickyToDo
git init
git add .
git commit -m "Initial commit"
```

**Benefits**:
- Track all changes
- Revert mistakes
- See history
- Branch for experiments
- Collaborate with team

**Tip**: Add `.gitignore`:
```
.DS_Store
*.swp
```

---

### Q: What happens if I delete a task file manually?

**A**:
1. StickyToDo detects file deletion
2. Task removed from app immediately
3. Can restore from backup/git if needed

**Safer option**: Use StickyToDo's delete function (⌘Delete) which:
- Moves to archive (not permanent delete)
- Maintains metadata
- Recoverable

---

### Q: How do I backup my tasks?

**A**: Multiple options:

**Option 1: File System Backup**
- Time Machine automatically backs up data directory
- Or manually copy entire folder

**Option 2: Export**
- File → Export → All Tasks
- Choose format (Markdown, JSON, etc.)
- Save to backup location

**Option 3: Git**
```bash
cd ~/Documents/StickyToDo
git commit -am "Backup $(date)"
git push  # if you have remote
```

**Option 4: Cloud Sync**
- iCloud/Dropbox automatically backs up
- Version history available

---

## Search and Filtering

### Q: How do I find a task when I have hundreds?

**A**: Several methods:

**1. Quick Search (⌘F)**
- Type any part of title, notes, project, or context
- Instant results
- Highlighted matches

**2. Advanced Search**
- Use operators: AND, OR, NOT
- Field-specific: `project:Website`
- Exact phrases: `"code review"`

**3. Smart Perspectives**
- Filter by any combination of criteria
- Save for reuse

**4. Spotlight**
- ⌘Space (system-wide)
- Search across all tasks
- Open directly in StickyToDo

---

### Q: What are search operators and how do I use them?

**A**: Operators let you build complex queries:

**AND** - Both terms must match
```
urgent AND @office
→ Tasks with "urgent" in @office context
```

**OR** - Either term matches
```
project:Website OR project:App
→ Tasks in either project
```

**NOT** - Exclude term
```
!high NOT completed
→ High priority tasks not done
```

**Exact phrase** - Quote it
```
"code review"
→ Exact phrase match only
```

**Field-specific** - Use field: prefix
```
notes:important
→ Search only in notes field
```

**Combine operators**:
```
(project:Website OR project:App) AND !high NOT completed
→ High priority incomplete tasks in either project
```

---

### Q: Can I save my searches?

**A**: Yes, as custom perspectives:

1. Perform search
2. Click "Save as Perspective"
3. Name it
4. Assign keyboard shortcut (optional)
5. Access anytime from sidebar

---

## Automation and Advanced Features

### Q: What can I automate with rules?

**A**: Almost anything! Rules have triggers and actions.

**Example Rules**:

**Auto-context based on project**:
```
Trigger: Project set to "Website"
Action: Set context to @computer
```

**Auto-flag overdue tasks**:
```
Trigger: Task becomes overdue
Action: Set flagged = true
Action: Set priority = high
```

**Auto-tag by keywords**:
```
Trigger: Title contains "meeting"
Action: Add tag #meeting
Action: Set context @office
```

**Send notification on completion**:
```
Trigger: Task marked completed
Condition: Priority = high
Action: Send notification "High priority task completed!"
```

---

### Q: How accurate is time tracking?

**A**: As accurate as you make it.

**For best results**:
- Start timer when you begin work
- Stop timer when you take breaks
- Review time logs weekly
- Adjust estimates based on actuals
- Use for learning, not punishment

**Tip**: StickyToDo shows effort estimate vs. actual time, helping you improve estimation over time.

---

### Q: Can I use Siri to add tasks?

**A**: Yes! StickyToDo has Siri Shortcuts integration.

**Try these commands**:
```
"Hey Siri, add task to StickyToDo"
"Hey Siri, show my inbox in StickyToDo"
"Hey Siri, what should I work on?"
"Hey Siri, complete task in StickyToDo"
```

**Custom Shortcuts**:
- Build in Shortcuts app
- Create complex workflows
- Combine with other apps

---

### Q: What are task templates and when should I use them?

**A**: Templates are reusable task blueprints.

**Use for**:
- Recurring workflows (meeting notes, code reviews)
- Checklists (onboarding, project kickoff)
- Standardized processes (client intake)

**Example: Meeting Notes Template**:
```
Title: [Meeting Name] - [Date]
Project: Meetings
Context: @office
Subtasks:
  - Review agenda
  - Take notes
  - Send summary
  - Schedule follow-up
```

**Create**:
1. Make task with all details
2. Right-click → Save as Template
3. Use ⌘⌥N to instantiate

---

## Troubleshooting

### Q: StickyToDo won't launch. What do I do?

**A**: Try these steps in order:

1. **Check macOS version**
   - Requires macOS 14.0 (Sonoma) or later
   - System Settings → General → About

2. **Check permissions**
   - System Settings → Privacy & Security
   - Allow StickyToDo if blocked

3. **Reset preferences** (safe, doesn't delete tasks)
   ```bash
   defaults delete com.yourcompany.StickyToDo
   ```

4. **Check crash logs**
   - Console.app → Search "StickyToDo"
   - Look for crash reports

5. **Reinstall app**
   - Delete StickyToDo.app
   - Download fresh copy
   - Tasks in data directory are preserved

---

### Q: My tasks are missing! Where did they go?

**A**: Don't panic. Check these:

**1. Check current perspective**
- Tasks might be filtered out
- Press ⌘7 (All Active) to see everything

**2. Check defer dates**
- Deferred tasks are hidden until date arrives
- Remove defer date to unhide

**3. Check search**
- Clear any active search (⌘F, then Escape)

**4. Check status**
- If marked completed, tasks move to archive
- Look in Archive perspective

**5. Check file system**
- Open data directory
- Look in tasks/active/YYYY/MM/
- Files still there?

**6. Check sync**
- If using iCloud/Dropbox, sync may be delayed
- Wait a few minutes and check again

**7. Restore from backup**
- Time Machine
- Git history
- Cloud service version history

---

### Q: Quick capture hotkey isn't working.

**A**: Troubleshooting steps:

**1. Check if enabled**
- Settings → Quick Capture
- "Enable Global Hotkey" checked?

**2. Check for conflicts**
- System Settings → Keyboard → Keyboard Shortcuts
- Look for conflicts with ⌘⇧Space
- If Spotlight uses it, change one or the other

**3. Check accessibility permissions**
- System Settings → Privacy & Security → Accessibility
- StickyToDo should be in the list with checkbox

**4. Try different hotkey**
- Settings → Quick Capture
- Change to ⌘⌥Space or another combo

**5. Restart StickyToDo**
- Quit completely (⌘Q)
- Relaunch
- Test hotkey

---

### Q: Tasks aren't syncing between my Macs.

**A**: Sync checklist:

**1. Verify same location**
- Both Macs pointing to same folder?
- Settings → General → Data Directory

**2. Check sync service**
- iCloud Drive enabled? (System Settings → iCloud)
- Dropbox running and synced?

**3. Let sync complete**
- Don't use both Macs simultaneously
- Wait for sync before switching
- Check sync service status

**4. File watcher enabled**
- Settings → Advanced → File Watcher
- Should be ON

**5. Force refresh**
- File → Reload All Tasks
- Or restart app

**6. Check for conflicts**
- Look for "conflicted copy" files
- Resolve manually if needed

---

### Q: App is running slowly with many tasks.

**A**: Performance optimization:

**1. Archive completed tasks**
- Old completed tasks can slow things down
- File → Archive Completed Tasks
- Move to archive folder

**2. Close unused boards**
- Too many open boards affects performance
- Hide boards you don't use regularly

**3. Reduce file watcher scope**
- Settings → Advanced → File Watcher
- Exclude archive folder

**4. Check number of tasks**
- Phase 1 targets 500-1000 tasks
- More than 2000? Performance may degrade
- Consider archiving old projects

**5. Check macOS resources**
- Activity Monitor → Look for memory pressure
- Close other apps
- Restart Mac

**Future**: SQLite backend (Phase 2) will handle 10,000+ tasks easily.

---

### Q: I got a "conflict detected" message. What do I do?

**A**: This means the file changed externally while app had unsaved changes.

**Options presented**:

**1. Keep File Version**
- Use changes from disk
- Lose app's unsaved changes
- Choose this if you edited externally

**2. Keep App Version**
- Use app's changes
- Overwrite file on disk
- Choose this if file change was accidental

**3. View Diff**
- See what changed
- Manually merge if needed
- Save merged version

**Prevention**:
- Let app auto-save before editing externally
- Wait for sync before opening on second Mac
- Use git for safety net

---

## Tips for Power Users

### Q: What are the most useful keyboard shortcuts to memorize?

**A**: The "Golden 10":

1. **⌘⇧Space** - Quick capture (anywhere on Mac)
2. **⌘N** - New task
3. **⌘I** - Toggle inspector
4. **⌘F** - Search
5. **⌘1-7** - Switch perspectives
6. **⌘⌥2** - Move to Next Actions
7. **Space** - Mark complete
8. **⌘Delete** - Delete task
9. **Return** - Edit selected task
10. **Tab** - Next field (in inspector)

**Master these** and you can work entirely from keyboard.

---

### Q: How do experienced GTD users set up StickyToDo?

**A**: Common setup from GTD veterans:

**1. Contexts by tool/location**:
- @computer
- @phone
- @office
- @home
- @errands
- @anywhere

**2. Weekly review scheduled**:
- Friday afternoon or Sunday evening
- Recurring task with checklist
- Block 30-60 minutes

**3. Inbox processed daily**:
- Morning routine (before work)
- Evening routine (before shutting down)
- Goal: Inbox zero daily

**4. Custom perspectives**:
- "Quick Wins" (≤15 min, high priority)
- "Waiting For Review" (waiting tasks over 7 days old)
- "Today" (due today + flagged)
- "This Week" (due in 7 days)

**5. Projects with single next action**:
- Every active project has at least one next action
- Review in weekly review
- Archive finished projects

---

### Q: What's the fastest way to process inbox to zero?

**A**: Use keyboard-only workflow:

```
1. Press ⌘1 (Inbox)
2. Select first task (↓)
3. Press ⌘I (Inspector)
4. Tab to Context → type @context
5. Tab to Project → type #project
6. Tab to Priority → select
7. Press ⌘⌥2 (Move to Next Actions)
8. Press ↓ (Next task)
9. Repeat from step 3

Average: 10-15 seconds per task
```

**Pro tip**: Use natural language for quick capture to reduce processing time:
```
Instead of:
  Title: "Call John"
  [then add all metadata in inspector]

Use:
  "Call John @phone #Sales !high tomorrow //30m"
  [metadata already set]
```

---

### Q: How do I use StickyToDo with other productivity systems?

**A**: StickyToDo is flexible:

**Time Blocking**:
- Calendar integration
- Defer dates for scheduled times
- Effort estimates for time blocks

**Pomodoro**:
- Use time tracker
- Create @pomodoro context
- Filter tasks by //25m effort

**Eisenhower Matrix**:
- Priority = Importance
- Due date = Urgency
- Create perspectives:
  - "Do First" (high priority, due soon)
  - "Schedule" (high priority, not urgent)
  - "Delegate" (low priority, due soon)
  - "Eliminate" (low priority, not urgent)

**Bullet Journal**:
- Daily perspective (due today + flagged)
- Monthly log (calendar view)
- Migration via status changes

---

### Q: Can I script task creation?

**A**: Yes! Tasks are just markdown files.

**Bash script example**:
```bash
#!/bin/bash
# quick-task.sh

UUID=$(uuidgen)
TITLE="$1"
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
YEAR=$(date +"%Y")
MONTH=$(date +"%m")

cat > ~/Documents/StickyToDo/tasks/active/$YEAR/$MONTH/$UUID-$SLUG.md <<EOF
---
id: $UUID
type: task
title: "$TITLE"
status: inbox
created: $DATE
modified: $DATE
---

EOF
```

**Usage**:
```bash
./quick-task.sh "Buy groceries"
```

**Python, Ruby, Node.js**: All work the same way. Just create valid markdown + YAML.

---

### Q: What advanced workflows are possible?

**A**: Some creative uses:

**1. Morning Dashboard**:
- Custom perspective: "Today's Focus"
- Filter: Flagged OR (Due today) OR (Defer today)
- Sort by priority
- Shows exactly what to work on

**2. Energy-Based Contexts**:
- @high-energy (deep work)
- @medium-energy (meetings, email)
- @low-energy (admin, filing)
- Match context to current energy level

**3. Time-Based Filtering**:
- @5-minutes (waiting in line)
- @15-minutes (between meetings)
- @30-minutes (focused blocks)
- @2-hours (deep work)

**4. Automated Project Setup**:
- Template for new project
- Automation rule adds standard tasks
- Board auto-created
- Checklist populated

**5. Meeting Workflow**:
- Template: "Meeting - [Topic]"
- Auto-creates pre/during/post tasks
- Links to calendar event
- Recurring for regular meetings

---

## Known Limitations

### Q: What are the current limitations of StickyToDo?

**A**: Phase 1 MVP limitations:

**Performance**:
- Target: 500-1000 tasks
- More tasks work but may slow down
- SQLite backend coming in Phase 2

**Platform**:
- macOS only (14.0+)
- iOS/iPadOS planned for Phase 2

**Collaboration**:
- No real-time collaboration
- Manual sync via Dropbox/iCloud
- Multi-user editing not recommended
- Collaboration features in Phase 3

**Attachments**:
- Stored as markdown links
- Files copied to data directory
- No cloud storage integration yet
- Large files increase backup size

**Advanced GTD**:
- No project templates (use task templates)
- No sequential vs parallel projects distinction
- No project hierarchies (flat list)

**See [NEXT_STEPS.md](../NEXT_STEPS.md) for planned enhancements.**

---

### Q: Can multiple people edit the same StickyToDo database?

**A**: Not recommended in Phase 1.

**Current state**:
- File-based storage isn't designed for concurrent editing
- Sync conflicts possible
- No conflict resolution beyond file-level

**Workarounds**:
- Take turns editing
- Use git for change tracking
- Communicate before making changes

**Future** (Phase 3):
- Collaboration features
- Proper multi-user support
- Real-time sync

---

### Q: Is there a mobile app?

**A**: Not yet, but planned for Phase 2.

**Meanwhile**:
- Edit files on iPhone/iPad using:
  - Obsidian (supports markdown + YAML)
  - iA Writer
  - Working Copy (with git)
- Changes sync via iCloud
- macOS app detects and reloads

---

### Q: Can I import from other task managers?

**A**: Yes, for several formats:

**Currently Supported**:
- CSV import
- Markdown import
- Things export format
- OmniFocus export format
- TaskPaper format
- Plain text (with parsing)

**Process**:
1. Export from other app
2. File → Import in StickyToDo
3. Select format
4. Map fields
5. Import

**Manual conversion** also possible since tasks are just markdown files.

---

## Still Have Questions?

**Resources**:
- [User Guide](USER_GUIDE.md) - Complete documentation
- [Quick Start](QUICK_START.md) - Get started fast
- [Features](FEATURES.md) - All features explained
- [Keyboard Shortcuts](KEYBOARD_SHORTCUTS.md) - Complete reference

**Get Help**:
- [GitHub Issues](https://github.com/yourusername/sticky-todo/issues) - Report bugs
- [Discussions](https://github.com/yourusername/sticky-todo/discussions) - Ask questions
- [Email Support](mailto:support@stickytodo.app) - Direct help

**Contribute**:
- [Contributing Guide](../CONTRIBUTING.md)
- [Development Guide](DEVELOPMENT.md)

---

*Last updated: 2025-11-18*

**Your tasks. Your format. Your control.**
