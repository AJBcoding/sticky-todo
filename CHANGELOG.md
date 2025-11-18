# Changelog

All notable changes to StickyToDo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-18

### 🎉 Initial Release - StickyToDo v1.0

First public release of StickyToDo, a powerful macOS task management application that combines OmniFocus-style GTD methodology with Miro-style visual boards, all backed by plain-text markdown storage.

### Core Features

#### GTD Workflow
- **Five Core Statuses**: Inbox, Next Actions, Waiting For, Someday/Maybe, Completed
- **Seven Built-in Perspectives**: Smart filtered views for different GTD contexts
  - Inbox - Process new items
  - Next Actions - Grouped by context
  - Flagged - Starred for attention
  - Due Soon - Upcoming deadlines
  - Waiting For - Blocked items
  - Someday/Maybe - Future ideas
  - All Active - Complete overview
- **Custom Perspectives**: Create your own filtered views with complex criteria
- **Natural Language Quick Capture**: Global hotkey (⌘⇧Space) with intelligent parsing
  - Context extraction (@phone, @computer, @office)
  - Project assignment (#ProjectName)
  - Priority detection (!high, !medium, !low)
  - Date parsing (tomorrow, friday, nov 20)
  - Effort estimates (//30m, //2h)

#### Visual Boards
- **Three Layout Types**:
  - **Freeform Canvas**: Infinite canvas for spatial brainstorming with pan/zoom
  - **Kanban Boards**: Vertical swim lanes for workflow management
  - **Grid Boards**: Organized sections for structured lists
- **Dynamic Board Creation**: Auto-create boards for projects and contexts
- **Boards as Filters**: Tasks appear based on metadata matching, not manual placement
- **High Performance**: 60 FPS canvas with 100+ tasks (AppKit-powered)

#### Two-Tier Task System
- **Notes**: Lightweight items for quick brainstorming with minimal metadata
- **Tasks**: Full GTD items with complete metadata support
- **Seamless Promotion**: Convert notes to tasks by adding metadata

#### Plain Text Foundation
- **Markdown Storage**: All tasks stored as .md files with YAML frontmatter
- **Human-Readable**: Edit in any text editor (VS Code, Obsidian, vim)
- **Version Control Ready**: Use git to track changes and maintain history
- **Sync-Friendly**: Works with Dropbox, iCloud Drive, or any file sync service
- **Future-Proof**: Standard formats ensure long-term data accessibility

#### Rich Task Metadata
- UUID-based unique identifiers
- Title and full markdown notes
- Projects and contexts
- Priority levels (High, Medium, Low)
- Due dates with time support
- Defer/start dates
- Flagged status
- Effort estimates in minutes
- Per-board position tracking
- Created and modified timestamps
- Tags with colors and icons

#### Advanced Features

##### Recurring Tasks
- Flexible recurrence patterns (daily, weekly, monthly, yearly)
- Custom intervals (every 3 days, every 2 weeks)
- Day-of-week selection for weekly tasks
- Monthly date or day-of-week options
- Skip weekends option
- End date or count-based termination
- Automatic next instance creation

##### Subtasks & Hierarchy
- Unlimited nesting depth
- Parent-child relationships
- Completion cascading options
- Hierarchical display in lists and inspector
- Progress tracking for parent tasks
- Independent or dependent subtask workflows

##### Search & Filtering
- **Full-Text Search** with 300ms debouncing
- **Advanced Operators**: AND, OR, NOT for complex queries
- **Yellow Highlighting** of matched text in results
- **Spotlight Integration**: Search tasks from system-wide Spotlight
- **Filter by Any Metadata**: Status, project, context, priority, dates, flags, tags

##### Time Tracking & Analytics
- Manual time entry for tasks
- Time estimates vs. actual tracking
- **Analytics Dashboard** with:
  - Task completion rates
  - Time spent by project/context
  - Productivity trends over time
  - Average completion time
  - Task aging analysis
  - Weekly/monthly summaries
- Export analytics data for external analysis

##### Templates
- **Seven Built-in Templates**:
  - Meeting Notes
  - Project Kickoff
  - Weekly Review
  - Bug Report
  - Design Review
  - Research Task
  - Client Follow-up
- Create custom templates from any task
- Template variables for dynamic content
- Import/export template libraries
- "Save as Template" quick action

##### Automation Rules Engine
- **11 Trigger Types**:
  - Task created
  - Task completed
  - Status changed
  - Project assigned
  - Due date approaching
  - Due date passed
  - Flagged status changed
  - Task modified
  - Tag added/removed
  - Priority changed
  - Deferred date reached
- **13 Action Types**:
  - Set status
  - Set priority
  - Add tag
  - Remove tag
  - Flag/unflag
  - Set project
  - Set context
  - Set due date (relative)
  - Set defer date (relative)
  - Send notification
  - Play sound
  - Run AppleScript
  - Create follow-up task
- Conditional logic with AND/OR operators
- Enable/disable rules individually
- Rule execution history in activity log

##### Export & Import
- **Seven Export Formats**:
  - JSON - Full data export with all metadata
  - CSV - Spreadsheet-compatible format
  - Markdown - Standalone .md files
  - HTML - Formatted web pages
  - iCal (.ics) - Calendar events for tasks with due dates
  - Things - Import into Things 3
  - OmniFocus - Import into OmniFocus
- Batch export by project, context, or date range
- Import from other task managers
- Backup and restore functionality

##### Calendar Integration
- Two-way sync with macOS Calendar
- Tasks with due dates appear as calendar events
- Calendar events can create tasks
- EventKit integration with permissions
- Multiple calendar support
- Customizable sync rules

##### Notifications
- **Local Notifications** for:
  - Due date reminders (customizable timing)
  - Deferred task availability
  - Recurring task instances
  - Rule-based notifications
- **Interactive Actions**: Complete or snooze from notification
- **Badge Count**: Unread notification count in Dock
- Quiet hours configuration
- Per-project notification preferences

##### Siri Shortcuts Integration
- **12 Voice Commands**:
  - "Add task to inbox"
  - "Show next actions"
  - "What's due today"
  - "Flag this task"
  - "Complete task [name]"
  - "Create project [name]"
  - "Show waiting for"
  - "Add to someday/maybe"
  - "What's overdue"
  - "Weekly review"
  - "Search for [query]"
  - "How many tasks"
- Custom Siri phrase configuration
- iOS/macOS Shortcuts integration
- Automation workflow support

##### Attachments
- **Three Attachment Types**:
  - Files (any format, stored in tasks directory)
  - URLs/Links (web references, documents)
  - Notes (rich text annotations)
- Preview support for images and PDFs
- Quick access from task inspector
- Attachment search capability
- Storage management and cleanup

##### Activity Log & History
- **26 Change Types Tracked**:
  - All metadata changes
  - Status transitions
  - Project/context assignments
  - Priority updates
  - Date modifications
  - Note edits
  - Tag operations
  - Attachment additions
  - Rule executions
  - Time tracking entries
- Who/what/when for all changes
- Undo/redo support (10 levels)
- Export activity log
- Audit trail for important tasks

##### Weekly Review
- Dedicated weekly review interface
- **GTD Review Workflow**:
  - Process inbox to zero
  - Review next actions by context
  - Check waiting for items
  - Review someday/maybe projects
  - Look ahead at calendar
  - Review completed tasks
  - Set priorities for next week
- Progress tracking through review steps
- Completion statistics
- Review history and trends

##### Tags System
- Colored tags for visual organization
- Icon support (SF Symbols)
- Tag filtering and searching
- Auto-complete when typing
- Tag cloud visualization
- Most-used tags tracking
- Rename and merge tags

#### Data Layer & Architecture

##### File System Organization
```
YourDataDirectory/
├── tasks/
│   ├── active/
│   │   └── YYYY/MM/uuid-task-slug.md
│   └── archive/
│       └── YYYY/MM/uuid-task-slug.md
├── boards/
│   └── board-id.md
└── config/
    ├── contexts.yaml
    ├── perspectives.yaml
    └── settings.yaml
```

##### Data Management
- **In-Memory Architecture**: All tasks loaded at startup for instant access
- **Debounced Writes**: Changes saved after 500ms of inactivity
- **File Watching**: FSEvents monitors external changes and auto-reloads
- **Conflict Detection**: Warns when external changes conflict with unsaved edits
- **Thread-Safe Operations**: Serial queues prevent data corruption
- **Performance**: < 2 second launch time with 500-1000 tasks

##### Integration Points
- Combine framework for reactive data flow
- @Published properties for SwiftUI binding
- NSViewControllerRepresentable for AppKit canvas integration
- EventKit for calendar sync
- UserNotifications for local notifications
- Spotlight API for system search
- Siri Intents for voice commands

#### User Interface

##### Main Window
- **Split View Layout**: Sidebar, content area, inspector panel
- **Perspective Sidebar**: Quick access to all perspectives and boards
- **List View**: Traditional task list with grouping and sorting
- **Board Canvas**: Visual workspace with drag-and-drop
- **Inspector Panel**: Detailed task editing with all metadata
- **Toolbar**: Quick actions and view switching
- **Global Quick Capture**: ⌘⇧Space from anywhere

##### Design & Polish
- Native macOS design language
- Dark mode support
- SF Symbols icons throughout
- Smooth animations and transitions
- Keyboard-first navigation (80+ shortcuts)
- Accessibility support
- Retina-optimized graphics

##### First-Run Experience
- Welcome screen with feature overview
- Data directory selection
- Sample data generation (optional)
- Onboarding tour highlighting key features
- Permission requests (Notifications, Calendar, Spotlight)
- Keyboard shortcuts cheat sheet
- Quick start guide

#### Developer Features

##### Testing
- **80%+ Test Coverage** for core data layer
- **8 Test Suites**:
  - ModelTests - Core models validation
  - YAMLParserTests - Frontmatter parsing
  - MarkdownFileIOTests - File operations
  - TaskStoreTests - Task management
  - BoardStoreTests - Board management
  - DataManagerTests - Integration tests
  - NaturalLanguageParserTests - Quick capture
  - StickyToDoTests - General application tests
- Comprehensive error handling
- Edge case validation
- Performance benchmarking

##### Documentation
- Complete README with quick start guide
- Developer guide with architecture details
- User guide with feature documentation
- API reference for public interfaces
- File format specification
- Keyboard shortcuts reference
- Contributing guidelines
- Code of conduct

##### Build & Distribution
- Xcode 15.0+ project configuration
- Swift Package Manager for dependencies
- Code signing and notarization support
- Build scripts and automation
- Release checklist
- Version management

### Technology Stack

#### Frameworks & Languages
- **Swift 5.9+** - Primary language
- **SwiftUI** - Modern declarative UI
- **AppKit** - High-performance canvas
- **Combine** - Reactive programming

#### System Frameworks
- Foundation - Core utilities
- CoreServices - FSEvents file watching
- CoreGraphics - Drawing and rendering
- EventKit - Calendar integration
- UserNotifications - Local notifications
- Intents - Siri Shortcuts

#### Dependencies
- **Yams 5.0+** - YAML parsing (MIT License)

### System Requirements
- macOS 14.0 (Sonoma) or later
- 50 MB disk space
- Intel or Apple Silicon Mac
- Optional: Git for version control

### Known Issues

#### Minor Issues
- Calendar sync requires manual permission grant on first use
- Spotlight indexing may take a few minutes after first launch
- Very large markdown files (>1MB) may have slower load times
- External editor changes while app is running require save/reload confirmation

#### Limitations
- Maximum recommended task count: 1000 active tasks (performance optimized for this range)
- Recurring tasks limited to 100 future instances to prevent runaway generation
- Attachment file size limit: 10 MB per file (configurable in preferences)
- Subtask nesting depth limited to 10 levels (UI constraint)
- Board canvas optimized for up to 200 visible tasks per board

### Performance Benchmarks
- App launch: < 2 seconds with 500 tasks
- Task creation: Instant (async write to disk)
- Task search: < 200ms with 500 tasks
- Canvas rendering: 60 FPS with 100+ tasks
- File auto-save: 500ms debounce
- External change detection: 200ms debounce

### Migration Notes

This is the first release, so no migration is required. Future versions will include migration tools if the data format changes.

### Acknowledgments

StickyToDo is inspired by:
- **Getting Things Done** methodology by David Allen
- **OmniFocus** for GTD task management patterns
- **Miro** for visual board interactions
- **Obsidian** for plain-text philosophy
- **Yams** library for YAML parsing

### Contributors

See [CREDITS.md](CREDITS.md) for full list of contributors.

### License

StickyToDo is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## Future Roadmap

### Version 1.1 (Planned)
- Enhanced keyboard shortcut customization
- Custom color themes and dark mode refinements
- Batch edit operations
- Advanced natural language parsing (relative dates, time ranges)
- Board templates library
- Enhanced export options (PDF, LaTeX)

### Version 2.0 (Future)
- iOS and iPadOS support
- iCloud sync between devices
- Collaboration features (shared boards)
- Plugin system for extensibility
- Advanced reporting and analytics
- SQLite option for large datasets (10,000+ tasks)

---

**Your tasks. Your format. Your control.**
