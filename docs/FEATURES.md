# StickyToDo Features

Complete reference of all 30+ features in StickyToDo, organized by category with descriptions, use cases, and examples.

## Table of Contents

- [Core GTD Features](#core-gtd-features)
- [Task Management](#task-management)
- [Visual Boards](#visual-boards)
- [Smart Organization](#smart-organization)
- [Quick Capture](#quick-capture)
- [Search and Filtering](#search-and-filtering)
- [Automation and Intelligence](#automation-and-intelligence)
- [Integration Features](#integration-features)
- [Data and Export](#data-and-export)
- [Analytics and Insights](#analytics-and-insights)
- [Customization](#customization)

---

## Core GTD Features

### 1. Five-Status GTD Workflow

**Description**: Classic Getting Things Done methodology with five core task statuses.

**Statuses**:
- **Inbox** - Capture everything, process later
- **Next Actions** - Ready to work on
- **Waiting For** - Blocked or delegated
- **Someday/Maybe** - Future possibilities
- **Completed** - Done and archived

**Use Cases**:
- Follow David Allen's GTD methodology
- Process inbox to zero daily
- Separate actionable from non-actionable items
- Track delegated tasks

**How to Use**:
1. Capture everything to Inbox (⌘⇧Space)
2. Process daily: Is it actionable?
3. Move to Next Actions if yes
4. Move to Someday if maybe later
5. Move to Waiting if blocked
6. Complete when done

**Keyboard Shortcuts**:
- ⌘1 - Inbox
- ⌘2 - Next Actions
- ⌘5 - Waiting For
- ⌘6 - Someday/Maybe

---

### 2. Smart Perspectives

**Description**: Pre-configured and custom smart views that filter tasks based on criteria.

**Built-in Perspectives** (7):
- **Inbox** - Unprocessed items
- **Next Actions** - Grouped by context
- **Flagged** - Starred for attention
- **Due Soon** - Next 7 days
- **Waiting For** - Blocked items
- **Someday/Maybe** - Future ideas
- **All Active** - Everything not completed

**Custom Perspectives**:
- Create unlimited custom views
- Filter by any combination of criteria
- Save for reuse
- Keyboard accessible

**Use Cases**:
- "Quick Wins" (effort ≤ 30min, priority high)
- "Computer Work" (context @computer)
- "This Week" (due in next 7 days)
- "High Priority" (priority high, status next-action)

**How to Create**:
1. Click + next to Perspectives
2. Set filters (status, context, project, etc.)
3. Choose grouping (by context, project, etc.)
4. Select sorting (priority, due date, etc.)
5. Save with name and icon

**Example**:
```
Quick Wins Perspective:
- Filter: Status = Next Action, Effort ≤ 30 min
- Group By: Context
- Sort By: Priority (descending)
```

---

### 3. Weekly Review Interface

**Description**: Dedicated interface for GTD weekly review process.

**Features**:
- Guided review workflow
- Checkbox for each review step
- Stats summary (tasks completed, created, etc.)
- Quick access to all perspectives
- Notes section for reflection

**Review Steps**:
1. Clear inbox to zero
2. Review next actions
3. Check waiting items
4. Scan someday/maybe
5. Review all projects
6. Plan next week
7. Update contexts

**Use Cases**:
- Weekly GTD review (recommended Friday or Sunday)
- Monthly project review
- Quarterly planning
- Annual goal review

**How to Access**:
- Menu → View → Weekly Review
- Or create keyboard shortcut

---

## Task Management

### 4. Rich Task Metadata

**Description**: Comprehensive task properties for complete task management.

**Available Fields**:
- **Title** - Task name (required)
- **Notes** - Full markdown description
- **Status** - Current GTD status
- **Project** - Project assignment
- **Context** - Where/how to do it
- **Priority** - High, Medium, Low
- **Due Date** - Hard deadline
- **Defer Date** - Hide until date
- **Flagged** - Star for attention
- **Effort** - Time estimate (minutes)
- **Tags** - Multiple custom tags
- **Created** - Auto-timestamp
- **Modified** - Auto-updated

**Use Cases**:
- Detailed task planning
- Context-based filtering
- Priority management
- Time estimation
- Multi-dimensional organization

**How to Edit**:
1. Select task
2. Press ⌘I for inspector
3. Edit any field
4. Press ⌘Return to save

---

### 5. Recurring Tasks

**Description**: Create tasks that repeat automatically on a schedule.

**Recurrence Patterns**:
- **Daily** - Every N days
- **Weekly** - Every N weeks
- **Specific Days** - Mon/Wed/Fri, etc.
- **Monthly** - Every N months
- **Yearly** - Every N years
- **Custom** - Advanced patterns

**Options**:
- End after N occurrences
- End on specific date
- Never end (ongoing)
- Skip weekends
- Adjust for month overflow

**Use Cases**:
- Daily standup
- Weekly team meeting
- Monthly invoice processing
- Quarterly reviews
- Annual tax filing
- Workout routine
- Medication reminders

**How to Create**:
1. Create task
2. Open inspector (⌘I)
3. Click "Add Recurrence"
4. Choose pattern and frequency
5. Set end condition
6. Save

**Example**:
```
Weekly Team Meeting:
- Frequency: Weekly
- Days: Every Monday
- Time: 10:00 AM
- Never ends
- Creates instance 7 days in advance
```

---

### 6. Subtasks and Hierarchies

**Description**: Break down complex tasks into manageable subtasks.

**Features**:
- Unlimited nesting depth
- Indent/outdent with ⌘] and ⌘[
- Collapse/expand parent tasks
- Progress indicators (3/5 completed)
- Auto-complete parent when all children done

**Use Cases**:
- Project planning
- Multi-step processes
- Breaking down large tasks
- Task dependencies
- Checklists within tasks

**How to Use**:
1. Create main task
2. Press ⌘N to add subtask
3. Press ⌘] to indent (make it a child)
4. Press ⌘[ to outdent (promote to sibling)
5. Complete subtasks individually

**Example**:
```
Launch Website (0/4 completed)
  ├─ Design mockups (completed)
  ├─ Write content (in progress)
  │   ├─ Homepage copy
  │   ├─ About page
  │   └─ Contact info
  ├─ Build site
  └─ Deploy to production
```

---

### 7. Task Templates

**Description**: Reusable task blueprints for recurring workflows.

**Features**:
- Save any task as template
- Include all metadata
- Include subtasks
- Include notes and attachments
- Quick instantiation

**Built-in Templates**:
- Meeting Notes
- Project Kickoff
- Code Review
- Blog Post
- Weekly Review
- Client Onboarding

**Use Cases**:
- Standardize workflows
- Ensure nothing is forgotten
- Speed up task creation
- Maintain consistency
- Onboard team members

**How to Create**:
1. Create task with all details
2. Right-click → Save as Template
3. Name the template
4. Choose category (optional)

**How to Use**:
1. Press ⌘⌥N (New from Template)
2. Select template
3. Customize as needed
4. Save

---

### 8. Attachments Support

**Description**: Attach files, images, and links to tasks.

**Supported Types**:
- Images (PNG, JPG, GIF)
- PDFs
- Documents (Word, Excel, Pages, etc.)
- Archives (ZIP, TAR)
- Any file type
- Web links

**Features**:
- Drag and drop files
- Quick Look preview (Space bar)
- Open in default app
- Export with task
- Stored as markdown links

**Use Cases**:
- Reference documents
- Meeting agendas
- Design mockups
- Screenshots
- Contracts and invoices
- Research materials

**How to Attach**:
1. Open task inspector
2. Drag file to Notes section
3. Or click "Attach" button
4. File is copied to task folder
5. Markdown link inserted

---

## Visual Boards

### 9. Freeform Canvas

**Description**: Infinite canvas for spatial task organization and brainstorming.

**Features**:
- Infinite space (pan anywhere)
- Smooth zoom (⌘+ / ⌘-)
- Drag tasks to position
- Lasso selection (drag in empty space)
- Multi-select (⌘-click)
- 60 FPS performance
- AppKit-powered rendering

**Controls**:
- **Pan**: Option + drag
- **Zoom**: ⌘+ / ⌘-
- **Reset**: ⌘0
- **Fit All**: ⌘⇧0
- **Move Task**: Drag
- **Lasso**: Click + drag

**Use Cases**:
- Mind mapping
- Project planning
- Brainstorming sessions
- Spatial organization
- Visual thinking
- Idea clustering

**Tips**:
- Group related tasks spatially
- Use color coding (priority)
- Create zones (Now/Next/Later)
- Add notes as sticky notes
- Export as image for sharing

---

### 10. Kanban Boards

**Description**: Column-based workflow boards with drag-and-drop status updates.

**Features**:
- Customizable columns
- Drag between lanes
- Auto-update task metadata
- WIP limits (optional)
- Column collapse
- Vertical swim lanes

**Default Columns**:
- Status boards: Inbox | Next | Waiting | Someday
- Project boards: To Do | In Progress | Done
- Custom boards: Define your own

**Use Cases**:
- Development workflow
- Content pipeline
- Sales process
- Support tickets
- Agile sprints
- Marketing campaigns

**Column Actions**:
- Moving task updates status
- Column-specific metadata rules
- Batch operations
- Archive completed column

**How to Use**:
1. Create board (⌘B)
2. Choose Kanban layout
3. Define columns
4. Set rules per column
5. Drag tasks to move

**Example**:
```
Website Project Kanban:
Backlog → Design → Development → Review → Deployed

Rules:
- Design column sets context to @design
- Development sets context to @computer
- Deployed sets status to completed
```

---

### 11. Grid Boards

**Description**: Organized section-based layout for compact task viewing.

**Features**:
- Named sections
- Auto-arrange layout
- Compact task cards
- Group by any field
- Expand/collapse sections
- Drag to reorder

**Use Cases**:
- Grouped task lists
- Category organization
- Team workload view
- Priority matrix
- Context-based lists

**How to Use**:
1. Create board
2. Choose Grid layout
3. Set grouping (context, project, priority)
4. Tasks auto-arrange
5. Collapse unused sections

---

### 12. Dynamic Board Filters

**Description**: Boards automatically show tasks matching filter criteria.

**Key Concept**: Boards don't contain tasks; they filter and display them from a single source of truth.

**Benefits**:
- No data duplication
- Tasks can appear on multiple boards
- Moving to board updates metadata
- Always in sync
- Single edit updates everywhere

**Filter Criteria**:
- Status
- Project
- Context
- Priority
- Flagged
- Due date range
- Defer date range
- Effort range
- Tags
- Custom expressions

**Use Cases**:
- Context boards (@office, @home)
- Project boards (automatically created)
- Custom filters (high priority + due soon)
- Smart collections

**Example**:
```
High Priority Board:
Filter:
  - Priority: High
  - Status: Next Action OR Flagged
  - Due Before: 7 days from now

Result: All high-priority actionable tasks due soon
```

---

## Smart Organization

### 13. Context-Based Organization

**Description**: Organize tasks by where/how they can be done.

**Default Contexts**:
- @office - At the office
- @home - At home
- @computer - Requires computer
- @phone - Phone calls
- @errands - Out and about
- @anywhere - No specific location

**Features**:
- Custom contexts
- Context icons and colors
- Auto-create context boards
- Context-based perspectives
- Quick context switching

**Use Cases**:
- Location-based task lists
- Tool-based organization
- Energy-level matching
- Time-based filtering

**Power User Tip**:
Create contexts for:
- Tools (@email, @phone, @computer)
- Locations (@office, @home, @cafe)
- People (@boss, @team, @client)
- Energy (@high-energy, @low-energy)
- Time (@5-minutes, @30-minutes)

---

### 14. Project-Based Organization

**Description**: Group related tasks into projects.

**Features**:
- Auto-create project boards
- Hierarchical project structure
- Project completion tracking
- Auto-hide inactive projects
- Project notes and documentation

**Use Cases**:
- Multi-task outcomes
- Client work
- Personal projects
- Goal tracking
- Campaign management

**Project Workflow**:
1. Add #ProjectName to task
2. Project board auto-created
3. All project tasks appear on board
4. Complete all tasks
5. Board auto-hides after 7 days

---

### 15. Tags System

**Description**: Multi-dimensional categorization with custom tags.

**Features**:
- Multiple tags per task
- Tag autocomplete
- Tag-based filtering
- Tag cloud view
- Rename/merge tags
- Tag statistics

**Use Cases**:
- Cross-cutting categories
- Skills required
- Resources needed
- Themes
- Campaigns
- Client names

**Example**:
```
Task: Write blog post
Tags: #writing, #marketing, #content, #SEO, #blog

Benefits:
- Find all #writing tasks
- Find all #marketing tasks
- Find tasks needing #SEO skill
- Track #blog content pipeline
```

---

## Quick Capture

### 16. Global Hotkey Quick Capture

**Description**: Capture tasks from anywhere on macOS with a global keyboard shortcut.

**Features**:
- System-wide hotkey (⌘⇧Space)
- Floating quick capture window
- Natural language parsing
- Multi-task entry
- Keyboard-only operation

**Capture Modes**:
- **Quick**: Just title, process later
- **Smart**: Natural language syntax
- **Full**: All fields in capture window
- **Multi**: Chain captures with ⌘Return

**How to Use**:
1. Press ⌘⇧Space (anywhere on Mac)
2. Type task with optional metadata
3. Press Return to save
4. Or ⌘Return to save and add another

---

### 17. Natural Language Parsing

**Description**: Automatically extract metadata from plain text task entry.

**Supported Syntax**:
- `@context` - Set context
- `#project` - Set project
- `!priority` - Set priority (!high, !medium, !low)
- `tomorrow`, `friday`, `nov 20` - Due dates
- `^defer:monday` - Defer until date
- `//30m`, `//2h` - Effort estimates
- `tag:value` - Add tags

**Smart Date Parsing**:
- tomorrow
- friday
- next week
- nov 20
- 2025-11-20
- in 3 days
- end of month

**Examples**:
```
Call John @phone #Sales !high tomorrow //30m
→ Title: "Call John"
   Context: @phone
   Project: Sales
   Priority: High
   Due: Tomorrow
   Effort: 30 minutes

Review mockups @computer #Website friday
→ Title: "Review mockups"
   Context: @computer
   Project: Website
   Due: This Friday

Buy groceries @errands tag:personal
→ Title: "Buy groceries"
   Context: @errands
   Tags: personal
```

---

## Search and Filtering

### 18. Full-Text Search

**Description**: Fast, intelligent search across all task fields with relevance ranking.

**Search Scope**:
- Task titles
- Notes content
- Projects
- Contexts
- Tags
- All metadata fields

**Features**:
- Real-time results
- Relevance scoring
- Match highlighting
- Search within results
- Save searches
- Recent searches history

**Keyboard Shortcut**: ⌘F

---

### 19. Advanced Search Operators

**Description**: Boolean logic and advanced operators for precise search queries.

**Operators**:
- `AND` - Both terms must match
- `OR` - Either term matches
- `NOT` - Exclude term
- `"exact phrase"` - Exact match
- `field:value` - Search specific field

**Field-Specific Search**:
- `title:meeting` - Search titles only
- `project:Website` - Tasks in Website project
- `context:@office` - Tasks with @office context
- `notes:urgent` - Search task notes
- `tag:client` - Tasks tagged with client

**Examples**:
```
urgent AND @office
→ Tasks with "urgent" in @office context

project:Website OR project:App
→ Tasks in either Website or App projects

!high NOT completed
→ High priority tasks not yet done

"code review" AND @computer
→ Exact phrase "code review" at computer

meeting notes:agenda
→ Meeting tasks with "agenda" in notes
```

**Use Cases**:
- Find specific tasks quickly
- Build complex queries
- Research projects
- Track specific topics
- Audit task lists

---

### 20. Saved Searches

**Description**: Save frequently used search queries for instant access.

**Features**:
- Save any search query
- Name and categorize
- Keyboard accessible
- Export/import searches
- Search library

**Use Cases**:
- Recurring searches
- Complex query templates
- Research workflows
- Audit procedures

---

## Automation and Intelligence

### 21. Automation Rules Engine

**Description**: Automatically apply actions when triggers fire.

**Available Triggers** (11):
- Task created
- Task completed
- Status changed
- Due date approaches
- Task overdue
- Project assigned
- Context changed
- Priority changed
- Tag added
- Flagged/unflagged
- Recurring instance created

**Available Actions** (13):
- Set status
- Set project
- Set context
- Set priority
- Add tag
- Remove tag
- Set flag
- Set due date
- Set defer date
- Set effort
- Add to board
- Send notification
- Run script (advanced)

**Use Cases**:
- Auto-assign contexts based on project
- Auto-prioritize overdue tasks
- Auto-flag tasks due tomorrow
- Auto-add tags based on keywords
- Auto-notify on high-priority completion

**Example Rules**:
```
Rule: Auto-Context for Meetings
Trigger: Project changed to "Meetings"
Action: Set context to @office

Rule: Flag Overdue Tasks
Trigger: Task becomes overdue
Action: Set flagged to true
Action: Set priority to high

Rule: Auto-Tag by Project
Trigger: Project contains "Website"
Action: Add tag "web-dev"
Action: Set context @computer
```

**How to Create**:
1. Settings → Automation
2. Click "+ New Rule"
3. Select trigger
4. Add condition (optional)
5. Select action(s)
6. Enable rule

---

### 22. Smart Task Suggestions

**Description**: AI-powered task recommendations based on context and patterns.

**Suggestion Types**:
- Next task to work on
- Similar past tasks
- Related tasks
- Template recommendations
- Context suggestions

**Factors Considered**:
- Current time of day
- Current location (if available)
- Available time
- Energy level
- Task priority
- Due dates
- Past patterns
- Context history

**How to Use**:
- Click "Suggest Task" in toolbar
- Or press ⌘⇧S
- Review 3-5 suggestions
- Click to select or dismiss

---

### 23. Time Tracking

**Description**: Track actual time spent on tasks and compare to estimates.

**Features**:
- Start/stop timer
- Manual time entry
- Time logs per task
- Effort vs. actual comparison
- Time analytics
- Export time data

**Use Cases**:
- Improve estimation
- Bill clients
- Analyze productivity
- Track project time
- Identify time sinks

**How to Use**:
1. Select task
2. Click timer icon
3. Work on task
4. Stop timer when done
5. Time logged automatically

---

### 24. Activity Log

**Description**: Complete history of all task changes and actions.

**Logged Events**:
- Task created
- Task completed
- Field changes
- Status changes
- Board moves
- Time tracked
- Comments added
- File attached

**Features**:
- Filterable log
- Search history
- Export logs
- Undo from history
- Audit trail

**Use Cases**:
- Track changes
- Find lost data
- Review progress
- Audit work
- Team accountability

---

## Integration Features

### 25. Siri Shortcuts (Voice Control)

**Description**: Control StickyToDo with Siri voice commands.

**Available Shortcuts** (12):
- "Add task to StickyToDo"
- "Show my inbox"
- "Show next actions"
- "Complete task"
- "What should I work on?"
- "Show today's tasks"
- "Show flagged tasks"
- "Create meeting note"
- "Start weekly review"
- "Show project tasks"
- "How many tasks do I have?"
- "Mark task as waiting"

**Examples**:
```
"Hey Siri, add 'Buy milk' to StickyToDo"
→ Creates task in inbox

"Hey Siri, show my next actions in StickyToDo"
→ Opens app to Next Actions view

"Hey Siri, what should I work on in StickyToDo?"
→ Shows smart task suggestions
```

**Custom Shortcuts**:
- Build multi-step workflows
- Combine with other apps
- Schedule automatic actions
- Create morning/evening routines

---

### 26. Calendar Integration

**Description**: Sync tasks with Calendar.app for time blocking and scheduling.

**Features**:
- Two-way sync
- Tasks with due dates appear as events
- Complete in either app
- Time blocking support
- Calendar view of tasks

**Use Cases**:
- Time blocking
- Schedule tasks
- See tasks in calendar
- Plan your day visually
- Share availability

---

### 27. Notification System

**Description**: Smart notifications with actionable buttons.

**Notification Types**:
- Due date reminders
- Overdue alerts
- Recurring task ready
- Waiting task follow-up
- Weekly review reminder
- Daily inbox reminder

**Actions in Notifications**:
- Complete
- Snooze
- Defer
- Open task
- Mark waiting
- Dismiss

**Scheduling**:
- At due time
- 1 hour before due
- 1 day before due
- Custom times
- Recurring notifications

---

### 28. Spotlight Integration

**Description**: Search tasks directly from macOS Spotlight.

**Features**:
- ⌘Space to search tasks
- System-wide search
- Quick task creation
- Open in StickyToDo
- Indexed metadata

**How to Use**:
1. Press ⌘Space
2. Type task title
3. StickyToDo tasks appear in results
4. Press Return to open in app

---

## Data and Export

### 29. Plain-Text Markdown Storage

**Description**: All data stored as human-readable markdown files with YAML frontmatter.

**Benefits**:
- Human-readable
- Edit in any text editor
- Version control friendly (git)
- Future-proof format
- No vendor lock-in
- Easy backup
- Sync-friendly

**File Structure**:
```
StickyToDo/
  tasks/
    active/
      2025/
        11/
          uuid-task-title.md
    archive/
      2025/
        11/
          uuid-completed.md
  boards/
    board-name.md
  config/
    contexts.yaml
    settings.yaml
```

**Use Cases**:
- Edit files externally
- Use with Obsidian, VS Code
- Git version control
- Grep search
- Script automation
- Data portability

---

### 30. Multi-Format Export

**Description**: Export tasks to 7+ different formats.

**Export Formats**:
- **Markdown** - Native format
- **JSON** - Structured data
- **CSV** - Spreadsheet import
- **HTML** - Web viewing
- **iCalendar** - Calendar import
- **Things** - Things.app import
- **OmniFocus** - OmniFocus import

**Export Options**:
- Single task
- Multiple tasks
- Entire perspective
- All active tasks
- Date range
- Search results

**Use Cases**:
- Backup tasks
- Migrate to other apps
- Share with team
- Archive completed
- Report generation

**How to Export**:
1. Select tasks
2. File → Export
3. Choose format
4. Select location
5. Export

---

### 31. File Watcher

**Description**: Automatically detect and reload external file changes.

**Features**:
- Real-time monitoring
- Conflict detection
- Auto-reload changed files
- Merge conflict UI
- Timestamp comparison

**Use Cases**:
- Edit in text editor
- Team collaboration
- Dropbox sync
- iCloud sync
- Git integration

**How It Works**:
1. Edit task file externally
2. Save file
3. StickyToDo detects change
4. Automatically reloads
5. Shows in app immediately

**Conflict Resolution**:
- Choose file version
- Choose app version
- Manual merge
- Show diff view

---

## Analytics and Insights

### 32. Analytics Dashboard

**Description**: Visual dashboard showing productivity metrics and insights.

**Metrics**:
- Tasks completed (daily/weekly/monthly)
- Completion rate
- Average completion time
- Time by project
- Time by context
- Priority distribution
- Overdue tasks trend
- Productivity score

**Charts**:
- Completion timeline
- Project time allocation
- Context usage
- Priority breakdown
- Weekly trends
- Monthly comparison

**Use Cases**:
- Track productivity
- Identify patterns
- Optimize workflow
- Report to managers
- Personal insights

---

### 33. Time Analytics

**Description**: Detailed analysis of how time is spent.

**Reports**:
- Time by project
- Time by context
- Time by priority
- Estimated vs. actual
- Time per task type
- Weekly time breakdown

**Insights**:
- Where time goes
- Estimation accuracy
- Context efficiency
- Priority alignment

---

### 34. Weekly Review Stats

**Description**: Summary statistics for weekly review process.

**Stats Shown**:
- Tasks completed this week
- Tasks created this week
- Net change (created - completed)
- Inbox items
- Overdue tasks
- Next week's due tasks
- Waiting items count
- Projects with no next action

---

## Customization

### 35. Keyboard Shortcut Customization

**Description**: Customize all keyboard shortcuts to match your workflow.

**Customizable Shortcuts**:
- All perspective switches
- All board actions
- Task operations
- Quick capture
- Search
- Navigation
- Inspector
- Custom commands

**Features**:
- Conflict detection
- Visual cheat sheet
- Export/import sets
- Restore defaults
- Per-command customization

---

### 36. Themes and Appearance

**Description**: Customize the visual appearance of StickyToDo.

**Theme Options**:
- Light mode
- Dark mode
- Auto (follows system)
- True black (OLED)

**Accent Colors**:
- Orange
- Blue
- Purple
- Green
- Red
- Pink
- Teal

**Board Styling**:
- Background colors
- Background images
- Grid styles
- Note appearance
- Font customization

---

### 37. Custom Contexts

**Description**: Define your own contexts beyond defaults.

**Customization**:
- Context name
- Icon/emoji
- Color
- Description
- Active/inactive
- Sort order

**Examples**:
- @high-energy
- @low-energy
- @5-minutes
- @30-minutes
- @client-site
- @gym
- @car

---

---

## Feature Summary

### Total Features: 37+

**By Category**:
- Core GTD: 3 features
- Task Management: 5 features
- Visual Boards: 4 features
- Smart Organization: 3 features
- Quick Capture: 2 features
- Search and Filtering: 3 features
- Automation: 4 features
- Integration: 4 features
- Data and Export: 3 features
- Analytics: 3 features
- Customization: 3 features

### Feature Complexity

**Beginner Features** (Start here):
- Five-status workflow
- Quick capture
- Basic perspectives
- Freeform boards
- Simple search

**Intermediate Features** (After 1-2 weeks):
- Recurring tasks
- Subtasks
- Custom perspectives
- Kanban boards
- Tags

**Advanced Features** (Power users):
- Automation rules
- Advanced search operators
- Time tracking
- Custom shortcuts
- Analytics dashboard

---

## What Makes StickyToDo Unique?

1. **Dual Mode** - Equal support for list and visual board workflows
2. **Plain Text** - All data in readable markdown files
3. **Boards as Filters** - No data duplication, dynamic views
4. **GTD Compliant** - Full Getting Things Done methodology
5. **Hybrid UI** - AppKit performance + SwiftUI productivity
6. **Extensible** - Automation, scripting, plain-text editing
7. **Privacy First** - All data local, no cloud requirement

---

## Coming Soon

**Planned Features** (Phase 4+):
- iOS/iPadOS apps
- iCloud sync
- Widget support
- URL schemes
- AppleScript support
- Plugin system
- Collaboration features
- SQLite backend (for performance)

---

**See Also**:
- [User Guide](USER_GUIDE.md) - Complete usage documentation
- [Quick Start](QUICK_START.md) - Get started in 5 minutes
- [Keyboard Shortcuts](KEYBOARD_SHORTCUTS.md) - All shortcuts
- [FAQ](FAQ.md) - Common questions

---

*Last updated: 2025-11-18*
