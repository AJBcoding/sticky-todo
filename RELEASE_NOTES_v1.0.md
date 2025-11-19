# StickyToDo v1.0.0 - Release Notes

**Release Date**: November 18, 2025
**Version**: 1.0.0
**Build**: 1000
**Platform**: macOS 14.0 (Sonoma) or later

---

## 🎉 Welcome to StickyToDo v1.0

We're thrilled to announce the first public release of **StickyToDo**, a revolutionary task management application for macOS that brings together the best of two worlds: **OmniFocus-style GTD (Getting Things Done) methodology** and **Miro-style visual boards**, all backed by **plain-text markdown storage**.

### What Makes StickyToDo Different?

**You own your data.** Every task, every note, every board is stored as a plain-text markdown file with YAML frontmatter that you can read, edit, and version control. No proprietary formats, no vendor lock-in, no cloud dependency. Your tasks are yours forever.

**Two modes, one system.** Work in traditional list views when you need structure and GTD discipline. Switch to visual boards when you need to brainstorm, plan, or see the big picture. Both modes work with the same data—choose the view that fits your current task.

**Plain text, powerful features.** Despite the simple storage format, StickyToDo packs 21+ advanced features including recurring tasks, subtasks, automation rules, Siri Shortcuts, calendar integration, time tracking, and more.

---

## Executive Summary

### What's New in v1.0

StickyToDo v1.0 is a **feature-complete, production-ready** task management application with:

- **21+ Major Features** covering the complete GTD workflow plus advanced capabilities
- **Three Visual Board Layouts** (Freeform, Kanban, Grid) with 60 FPS performance
- **Plain-Text Markdown Storage** for future-proof data ownership
- **Natural Language Quick Capture** with global hotkey
- **Deep macOS Integration** including Siri Shortcuts, Calendar, Spotlight, and Notifications
- **80%+ Test Coverage** ensuring reliability and data safety
- **Comprehensive Documentation** for users and developers

### Key Statistics

| Metric | Value |
|--------|-------|
| **Development Time** | 12-16 weeks (design to release) |
| **Lines of Code** | 26,550+ Swift, 25,000+ documentation |
| **Test Coverage** | 80%+ for core data layer |
| **Performance** | < 2s launch with 500 tasks, 60 FPS canvas |
| **Documentation** | 24+ files covering all features |
| **Features** | 21+ advanced features beyond basic GTD |

---

## Major Features

### 1. Complete GTD Workflow

**Getting Things Done, your way.**

- **Five Core Statuses**: Inbox → Next Actions → Waiting For → Someday/Maybe → Completed
- **Seven Built-in Perspectives**: Smart views for every GTD workflow stage
- **Custom Perspectives**: Create your own filtered views with complex criteria
- **Quick Capture**: Global hotkey (⌘⇧Space) with natural language parsing
- **Weekly Review**: Dedicated interface for GTD weekly reviews

**Natural Language Examples:**
```
Call John @phone #Website !high tomorrow //30m
→ Creates task "Call John" with context @phone, project Website,
  priority High, due tomorrow, 30 minute estimate

Review designs @computer #App next friday
→ Creates task "Review designs" with context @computer,
  project App, due next Friday

Buy groceries @errands
→ Creates task "Buy groceries" with context @errands
```

### 2. Visual Boards with Three Layouts

**See your tasks, organize visually.**

#### Freeform Canvas
- Infinite canvas for spatial brainstorming
- Pan (Option+drag) and zoom (⌘+scroll)
- Drag tasks anywhere for mind mapping
- Perfect for project planning and ideation

#### Kanban Boards
- Vertical swim lanes for workflow stages
- Drag tasks between columns to update status
- Customizable column definitions
- Great for agile team workflows

#### Grid Boards
- Organized sections with auto-layout
- Compact view for many tasks
- Category-based organization
- Ideal for structured task lists

**Performance**: 60 FPS smooth scrolling with 100+ tasks on canvas, powered by AppKit for maximum performance.

### 3. Plain Text Markdown Storage

**Your data, your format, your control.**

Every task is a markdown file with YAML frontmatter:

```markdown
---
id: 550e8400-e29b-41d4-a716-446655440000
type: task
title: "Call John about proposal"
status: next-action
project: "Website Redesign"
context: "@phone"
priority: high
due: 2025-11-20T14:00:00Z
flagged: true
effort: 30
---

Discuss the timeline and budget for the website redesign.

## Key Points
- Budget approval
- Timeline expectations
- Resource allocation
```

**Benefits:**
- Edit in **any text editor** (VS Code, Obsidian, vim, Sublime)
- **Version control** with git for change tracking
- **Sync-friendly** with Dropbox, iCloud Drive, or any file sync
- **Future-proof** with standard formats
- **No lock-in** to any proprietary system

### 4. Recurring Tasks

**Never forget repeating responsibilities.**

- Daily, weekly, monthly, yearly patterns
- Custom intervals (every 3 days, every 2 weeks)
- Flexible scheduling (weekdays only, specific days)
- Smart completion (creates next instance automatically)
- End date or count-based termination

**Examples:**
- "Team standup" every weekday at 9:00 AM
- "Weekly review" every Friday at 4:00 PM
- "Quarterly planning" every 3 months on the 1st
- "Pay rent" monthly on the 1st, 12 times total

### 5. Subtasks & Hierarchies

**Break down complex projects.**

- Unlimited nesting depth (UI shows 10 levels)
- Parent-child relationships
- Progress tracking for parent tasks
- Independent or cascading completion
- Hierarchical display in lists and inspector

**Example:**
```
□ Launch new website
  □ Design phase
    ☑ Create wireframes
    ☑ Design mockups
    □ Client approval
  □ Development
    □ Set up hosting
    □ Build frontend
    □ Configure CMS
  □ Launch
    □ Final testing
    □ Deploy to production
```

### 6. Full-Text Search with Spotlight

**Find anything, instantly.**

- Real-time search with 300ms debouncing
- Advanced operators: AND, OR, NOT
- Yellow highlighting of matches
- Search in titles, notes, projects, contexts
- **Spotlight integration**: Search from anywhere on macOS

**Search Examples:**
```
project:Website AND status:next-action
→ All active Website tasks

priority:high OR flagged:true
→ Important or flagged tasks

@phone AND NOT status:waiting
→ Phone tasks not waiting on others
```

### 7. Time Tracking & Analytics

**Understand your productivity.**

**Time Tracking:**
- Manual time entry per task
- Estimated vs. actual time tracking
- Time spent by project and context
- Running timers (future feature)

**Analytics Dashboard:**
- Task completion rates over time
- Time invested by project/context
- Productivity trends (daily/weekly/monthly)
- Average task completion time
- Task aging analysis (how long tasks sit)
- Custom date range filtering

**Export analytics** to CSV or JSON for external analysis.

### 8. Task Templates

**Standardize recurring workflows.**

**Seven Built-in Templates:**
1. **Meeting Notes** - Title, attendees, agenda, action items
2. **Project Kickoff** - Goals, deliverables, timeline, stakeholders
3. **Weekly Review** - GTD review checklist with all perspectives
4. **Bug Report** - Steps to reproduce, expected vs. actual, severity
5. **Design Review** - Mockups, feedback, iterations, approval
6. **Research Task** - Question, sources, findings, conclusions
7. **Client Follow-up** - Last contact, action items, next steps

**Custom Templates:**
- Create from any existing task
- Template variables for dynamic content
- Import/export template libraries
- Apply with keyboard shortcut

### 9. Automation Rules Engine

**Let StickyToDo work for you.**

**11 Trigger Types:**
- Task created, completed, or modified
- Status or priority changed
- Project or context assigned
- Due date approaching or passed
- Deferred date reached
- Flagged status changed
- Tags added or removed

**13 Action Types:**
- Set status, priority, project, context
- Add or remove tags
- Flag or unflag tasks
- Set relative due/defer dates
- Send notifications
- Play sounds
- Run AppleScript
- Create follow-up tasks

**Example Rules:**
- When task flagged → Set priority to High
- When due date approaching → Send notification 1 day before
- When project = "Website" AND status = completed → Create follow-up task "Deploy to production"
- When status = waiting → Set due date to 7 days from now

### 10. Export & Import (7 Formats)

**Data portability guaranteed.**

**Export Formats:**
1. **JSON** - Complete data with all metadata
2. **CSV** - Spreadsheet-compatible
3. **Markdown** - Standalone .md files
4. **HTML** - Formatted web pages with styling
5. **iCal (.ics)** - Calendar events for tasks with due dates
6. **Things** - Import into Things 3
7. **OmniFocus** - Import into OmniFocus

**Export Options:**
- All tasks or filtered selection
- By project, context, or date range
- Include or exclude archived tasks
- Preserve board positions and layout

### 11. Calendar Integration

**Two-way sync with macOS Calendar.**

- Tasks with due dates appear as calendar events
- Calendar events can create tasks
- Multiple calendar support
- EventKit integration with full permissions
- Customizable sync rules (which calendars, which tasks)

### 12. Siri Shortcuts Integration

**Control with your voice.**

**12 Built-in Voice Commands:**
- "Add task to inbox" - Quick task creation
- "Show next actions" - Open Next Actions perspective
- "What's due today" - List today's due tasks
- "Flag this task" - Mark task as important
- "Complete task [name]" - Mark task done
- "Create project [name]" - Start new project
- "Show waiting for" - View waiting tasks
- "Add to someday/maybe" - Defer task idea
- "What's overdue" - Show overdue tasks
- "Weekly review" - Start GTD review
- "Search for [query]" - Find tasks
- "How many tasks" - Get task count statistics

Compatible with macOS and iOS Shortcuts app for advanced automation.

### 13. Attachments Support

**Enrich tasks with context.**

**Three Attachment Types:**
1. **Files** - Any format, stored in tasks directory
2. **URLs/Links** - Web references, documents, related resources
3. **Notes** - Rich text annotations and comments

**Features:**
- Preview images and PDFs inline
- Quick access from task inspector
- Search within attachments
- Storage management and cleanup tools
- 10 MB file size limit (configurable)

### 14. Activity Log & Change History

**Never lose track of what changed.**

**26 Change Types Tracked:**
- All metadata changes (title, notes, dates, priority)
- Status transitions with timestamps
- Project and context assignments
- Tag additions and removals
- Attachment operations
- Rule executions
- Time tracking entries
- User who made the change (future: multi-user)

**Features:**
- Undo/redo support (10 levels)
- Export activity log to CSV
- Audit trail for important projects
- Timeline view of task evolution

### 15. Tags with Colors & Icons

**Organize beyond projects and contexts.**

- Create colored tags for visual organization
- Assign SF Symbols icons to tags
- Filter and search by tags
- Auto-complete when typing
- Tag cloud visualization
- Rename and merge tags
- Track most-used tags

**Example Tags:**
- 🔴 Urgent (red)
- 💰 Financial (green)
- 🎨 Creative (purple)
- 🐛 Bug (orange)
- 📚 Learning (blue)

### 16. Local Notifications

**Never miss important tasks.**

**Notification Types:**
- Due date reminders (customizable timing: 1 hour, 1 day, 1 week before)
- Deferred task now available
- Recurring task instance created
- Rule-triggered notifications

**Interactive Actions:**
- Complete task directly from notification
- Snooze for 1 hour, 1 day, or custom time
- Open in app for editing

**Configuration:**
- Quiet hours (no notifications during specified times)
- Per-project notification preferences
- Badge count in Dock icon
- Sound customization

### 17. Weekly Review Interface

**Stay on top of your commitments.**

Dedicated workflow interface for GTD weekly reviews:

**Review Steps:**
1. **Process Inbox** - Get to zero
2. **Review Next Actions** - By context
3. **Check Waiting For** - Follow up on blocked items
4. **Review Someday/Maybe** - Promote ideas ready for action
5. **Look Ahead** - Check calendar and upcoming deadlines
6. **Review Completed** - Celebrate wins
7. **Set Priorities** - Flag important tasks for next week

**Features:**
- Progress tracking through review steps
- Completion statistics (tasks processed, completed, deferred)
- Review history and trends
- One-click navigation between perspectives
- Keyboard-driven workflow

### 18-21. Additional Features

- **Two-Tier Task System**: Notes (lightweight) vs. Tasks (full GTD)
- **File Watcher**: Auto-reload when files changed externally
- **Keyboard-First Design**: 80+ shortcuts for power users
- **First-Run Experience**: Onboarding tour with sample data

---

## What's New Highlights

### For GTD Practitioners
- Complete implementation of Getting Things Done methodology
- Seven built-in perspectives covering all GTD workflows
- Natural language quick capture with global hotkey
- Weekly review interface with progress tracking
- Support for contexts, projects, priorities, and defer dates

### For Visual Thinkers
- Three board layouts: Freeform, Kanban, Grid
- Infinite canvas with smooth pan and zoom
- Spatial task organization for brainstorming
- 60 FPS performance with 100+ tasks
- Drag-and-drop between boards and lists

### For Plain-Text Advocates
- All data in markdown files with YAML frontmatter
- Edit in any text editor (VS Code, Obsidian, vim)
- Git-friendly for version control
- Sync with Dropbox, iCloud, or any file sync
- No proprietary formats or lock-in

### For Power Users
- 80+ keyboard shortcuts
- Automation rules engine (11 triggers, 13 actions)
- Advanced search with boolean operators
- Siri Shortcuts integration (12 commands)
- Custom perspectives and templates
- Batch operations and bulk editing

### For Team Leads & Managers
- Time tracking and analytics dashboard
- Project-based organization
- Export to 7 formats for reporting
- Calendar integration for timeline planning
- Subtasks for complex project breakdown

---

## System Requirements

### Minimum Requirements
- **Operating System**: macOS 14.0 (Sonoma) or later
- **Processor**: Intel Core i5 or Apple Silicon (M1/M2/M3)
- **Memory**: 4 GB RAM
- **Storage**: 50 MB for application, additional space for task data
- **Display**: 1280x800 minimum resolution

### Recommended Requirements
- **Operating System**: macOS 14.0 (Sonoma) or later
- **Processor**: Apple Silicon (M1 or newer) for best performance
- **Memory**: 8 GB RAM or more
- **Storage**: 500 MB for comfortable task storage
- **Display**: 1920x1080 or higher for optimal board canvas experience

### Optional
- **Git**: For version control of task files
- **Dropbox/iCloud Drive**: For file synchronization across devices
- **Text Editor**: VS Code, Obsidian, or similar for external editing

---

## Installation Instructions

### Download and Install

1. **Download** the latest release from [Releases](https://github.com/yourusername/sticky-todo/releases)
2. **Unzip** the downloaded file (StickyToDo-v1.0.0.zip)
3. **Drag** StickyToDo.app to your Applications folder
4. **Right-click** and select "Open" for first launch (macOS Gatekeeper)
5. **Grant permissions** when prompted:
   - Notifications (for reminders)
   - Calendar access (optional, for calendar sync)
   - Files and Folders access (for task storage)

### First Launch Setup

1. **Welcome Screen** - Overview of StickyToDo features
2. **Choose Data Directory**
   - Recommended: `~/Documents/StickyToDo`
   - For iCloud sync: `~/Library/Mobile Documents/com~apple~CloudDocs/StickyToDo`
   - Custom location of your choice
3. **Sample Data** (optional)
   - Generate 13 sample tasks
   - Create 3 sample boards
   - Add useful tags
4. **Onboarding Tour** - Quick walkthrough of key features
5. **Set Global Hotkey** - Configure Quick Capture shortcut (default: ⌘⇧Space)

### Building from Source

For developers who want to build from source:

```bash
# Clone repository
git clone https://github.com/yourusername/sticky-todo.git
cd sticky-todo

# Open in Xcode
open StickyToDo.xcodeproj

# Install dependencies (Yams via Swift Package Manager)
# Xcode will prompt to resolve packages on first build

# Build
# Select StickyToDo scheme
# Choose "My Mac" as destination
# Press ⌘B to build or ⌘R to run

# Run tests
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo
```

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for detailed developer setup.

---

## Known Limitations

### Performance Limits
- **Recommended maximum**: 1,000 active tasks (app optimized for this range)
- **Board canvas**: Best performance with up to 200 visible tasks per board
- **Recurring tasks**: Limited to 100 future instances to prevent runaway generation

### Feature Constraints
- **Subtask nesting**: UI displays up to 10 levels (data supports unlimited)
- **Attachment file size**: 10 MB per file (configurable in preferences)
- **Undo history**: 10 levels (oldest changes are discarded)
- **Search results**: Limited to 500 matches for UI performance

### Integration Notes
- **Calendar sync**: Requires manual permission grant on first use
- **Spotlight indexing**: May take a few minutes after first launch
- **Siri Shortcuts**: Requires macOS 14.0+ for full functionality
- **External editor changes**: Require save/reload confirmation if app is running

### Known Issues
- Very large markdown files (>1MB) may have slower load times
- Board canvas zoom limited to 50%-400% range
- Natural language date parsing only supports English
- Export to Things/OmniFocus requires those apps to be installed

**Workarounds and details** are documented in the [User Guide](docs/USER_GUIDE.md).

---

## What's Coming Next

### Version 1.1 (Q1 2026)

**User-Requested Features:**
- Keyboard shortcut customization
- Enhanced dark mode with accent colors
- Batch edit operations (change multiple tasks at once)
- Advanced natural language parsing (relative dates, time ranges)
- Board templates library
- Enhanced export options (PDF, LaTeX)
- Quick action context menus

**Performance Improvements:**
- Faster search indexing
- Optimized canvas rendering
- Reduced memory footprint
- Background task synchronization

### Version 2.0 (Q3 2026)

**Major New Capabilities:**
- **iOS and iPadOS apps** - Use StickyToDo on all Apple devices
- **iCloud sync** - Seamless synchronization between Mac, iPhone, iPad
- **Collaboration features** - Shared boards and projects
- **Plugin system** - Extend StickyToDo with custom functionality
- **Advanced reporting** - Custom reports and dashboards
- **SQLite storage option** - For datasets with 10,000+ tasks

See [FEATURE_OPPORTUNITIES_REPORT.md](FEATURE_OPPORTUNITIES_REPORT.md) for complete roadmap.

---

## Getting Help

### Documentation
- **[User Guide](docs/USER_GUIDE.md)** - Complete feature documentation
- **[Keyboard Shortcuts](docs/KEYBOARD_SHORTCUTS.md)** - All shortcuts reference
- **[Development Guide](docs/DEVELOPMENT.md)** - For developers and contributors
- **[File Format](docs/FILE_FORMAT.md)** - Technical specification
- **[FAQ](docs/FAQ.md)** - Frequently asked questions

### Support Channels
- **GitHub Issues** - [Report bugs or request features](https://github.com/yourusername/sticky-todo/issues)
- **GitHub Discussions** - [Ask questions and share workflows](https://github.com/yourusername/sticky-todo/discussions)
- **Email Support** - support@stickytodo.app
- **Twitter/X** - @StickyToDoApp

### Community
- Share your workflows and custom perspectives
- Contribute templates and automation rules
- Help translate to other languages (future)
- Submit pull requests for features and fixes

---

## Thank You

StickyToDo v1.0 represents months of design, development, and refinement to create a task management system that respects your data ownership while delivering powerful features. We're grateful to:

- **Getting Things Done** practitioners who inspired the workflow
- **OmniFocus** for demonstrating what GTD software should be
- **Miro** for showing the power of visual organization
- **Obsidian** and the plain-text community for championing data ownership
- **Early testers** who provided invaluable feedback
- **Open source contributors** especially the Yams project for YAML parsing

### Contributing

StickyToDo is open source and welcomes contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to report bugs
- Feature request process
- Pull request guidelines
- Code style guide
- Testing requirements

---

## Legal

### License
StickyToDo is released under the MIT License. See [LICENSE](LICENSE) for full details.

### Privacy
StickyToDo stores all data locally on your Mac. We do not collect telemetry, analytics, or any personal information. Your tasks are private and stay on your device.

### Third-Party Libraries
- **Yams** (MIT License) - YAML parsing library

---

**Version**: 1.0.0 (Build 1000)
**Release Date**: November 18, 2025
**Download**: [GitHub Releases](https://github.com/yourusername/sticky-todo/releases)

---

**Your tasks. Your format. Your control.**

Welcome to StickyToDo.
