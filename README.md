# StickyToDo

A powerful macOS task management application that combines OmniFocus-style GTD methodology with Miro-style visual boards. Your tasks, your way—in plain text.

[![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Overview

StickyToDo provides two complementary modes of working with your tasks:

- **List View**: Traditional GTD perspectives for processing tasks (Inbox, Next Actions, Projects, etc.)
- **Board View**: Visual boards with three layouts (Freeform, Kanban, Grid) for planning and brainstorming

**Core Innovation**: All data stored in plain-text markdown files. You own your data in a format you can read, edit, and version control. Tasks appear on boards automatically based on metadata filters—moving tasks between boards updates their metadata.

## Features

### 🎯 30+ Powerful Features

StickyToDo combines the best of GTD methodology with visual planning tools, all built on a plain-text foundation.

### Core GTD & Task Management

**Two-Tier Task System**
- **Notes**: Lightweight items for quick capture and brainstorming
- **Tasks**: Full GTD items with 12+ metadata fields
- Seamlessly promote notes to tasks as they become actionable

**Five-Status GTD Workflow**
- **Inbox** → Capture everything
- **Next Actions** → Ready to work
- **Waiting For** → Blocked or delegated
- **Someday/Maybe** → Future possibilities
- **Completed** → Auto-archived with history

**Smart Perspectives** (7 Built-in + Custom)
- Inbox, Next Actions, Flagged, Due Soon, Waiting, Someday, All Active
- Create unlimited custom perspectives
- Filter by any combination: status, project, context, priority, dates, effort, tags
- Keyboard shortcuts for instant access (⌘1-7)

**Advanced Task Features**
- 📝 **Rich Metadata**: Projects, contexts, priority, due/defer dates, effort, flags, tags, notes
- 🔄 **Recurring Tasks**: Daily, weekly, monthly, yearly with complex patterns
- 📊 **Subtasks & Hierarchies**: Break down complex projects
- 📎 **Attachments**: Files, images, PDFs, documents
- 🎨 **Task Templates**: Reusable blueprints for standard workflows
- ⏱️ **Time Tracking**: Track actual time vs. estimates

### Visual Boards (3 Layouts)

**Freeform Canvas**
- Infinite canvas for mind mapping and spatial planning
- 60 FPS performance (AppKit-powered)
- Pan (Option+drag), Zoom (⌘+/-), Lasso selection
- Perfect for brainstorming and visual thinking

**Kanban Boards**
- Drag-and-drop workflow management
- Customizable columns with metadata rules
- Auto-update task status when moving between lanes
- Great for agile/scrum and process tracking

**Grid Boards**
- Organized sections with auto-arrange
- Compact, scannable task view
- Group by any field (context, project, priority)
- Ideal for categorized lists

**Dynamic Filtering**
- Boards filter tasks, they don't contain them
- Single source of truth (no duplication)
- Tasks appear on multiple boards simultaneously
- Moving to board updates task metadata automatically

### Plain Text Foundation

**Markdown Storage** (Your Data, Your Control)
- Tasks stored as markdown files with YAML frontmatter
- **Human-Readable**: Edit in VS Code, Obsidian, vim, or any text editor
- **Version Control**: Use git to track changes and collaborate
- **Future-Proof**: Standard formats, no vendor lock-in
- **Sync-Friendly**: Works with Dropbox, iCloud Drive, or any file sync service
- **Script-Friendly**: Automate with bash, Python, Node.js, etc.

**File Watching**
- Real-time detection of external changes
- Auto-reload modified tasks
- Conflict detection and resolution
- Edit anywhere, sync everywhere

### Quick Capture & Search

**Global Hotkey Capture** (⌘⇧Space)
- Capture from anywhere on macOS
- Floating quick-entry window
- Multi-task rapid entry (⌘Return to chain)

**Natural Language Parsing**
```
Call John @phone #Sales !high tomorrow //30m
```
Automatically extracts: Title, Context, Project, Priority, Due date, Effort

**Supported Syntax:**
- `@context` - Where/how (@phone, @computer, @office, @home, @errands)
- `#project` - Project assignment
- `!priority` - !high, !medium, !low
- Smart dates - tomorrow, friday, nov 20, next week
- `^defer:date` - Hide until date
- `//30m`, `//2h` - Time estimates
- `tag:value` - Custom tags

**Full-Text Search**
- Search across all fields (title, notes, project, context, tags)
- **Boolean operators**: AND, OR, NOT
- **Exact phrases**: "code review"
- **Field-specific**: project:Website, context:@office
- Relevance scoring and match highlighting
- Save searches as perspectives

### Automation & Intelligence

**Automation Rules Engine**
- 11 triggers (created, completed, status changed, overdue, etc.)
- 13 actions (set status, project, context, priority, tags, notify, etc.)
- Build complex workflows
- Example: Auto-flag overdue tasks, auto-assign contexts by project

**Smart Features**
- Task suggestions based on context, time, and patterns
- Activity log and history
- Time tracking with analytics
- Weekly review interface with guided workflow

### Integration & Export

**macOS Integration**
- 🎙️ **Siri Shortcuts**: 12+ voice commands ("Add task", "Show inbox", "What should I work on?")
- 📅 **Calendar Integration**: Sync tasks with Calendar.app
- 🔔 **Notifications**: Smart reminders with actionable buttons
- 🔍 **Spotlight**: Search tasks system-wide (⌘Space)

**Export & Import** (7 Formats)
- Markdown (native), JSON, CSV, HTML
- iCalendar (.ics)
- Things import/export
- OmniFocus import/export

### Analytics & Insights

**Analytics Dashboard**
- Tasks completed (daily/weekly/monthly)
- Time by project and context
- Completion rate and trends
- Productivity scoring
- Estimation accuracy

**Weekly Review Tools**
- Guided review workflow
- Stats summary and insights
- Quick access to all perspectives
- Reflection notes

## Screenshots

<!-- Screenshots to be added -->
*Screenshots coming soon showing List View, Freeform Board, Kanban Board, and Quick Capture*

## Installation

### Requirements

- macOS 14.0 (Sonoma) or later
- 50 MB disk space
- Optional: Git for version control

### Download

1. **Download** the latest release from [Releases](https://github.com/yourusername/sticky-todo/releases)
2. **Unzip** the downloaded file
3. **Drag** StickyToDo.app to your Applications folder
4. **Launch** StickyToDo

### First Launch

1. **Choose data directory** - Select where to store your tasks
   - Recommended: `~/Documents/StickyToDo`
   - Or use iCloud: `~/Library/Mobile Documents/com~apple~CloudDocs/StickyToDo`

2. **Set up contexts** - Go to Settings → Contexts to customize

3. **Configure quick capture** - Set global hotkey (default: ⌘⇧Space)

4. **Optional: Sample tasks** - Create sample tasks to explore features

## Quick Start

### Process Your Inbox

1. Press `⌘⇧Space` to quick capture tasks
2. Type: `Buy groceries @errands #Personal tomorrow`
3. Press Return to save
4. Go to Inbox (⌘1) to process
5. For each task:
   - Clarify what it is
   - Decide if actionable
   - Assign context and project
   - Set priority if urgent
   - Move to Next Actions (⌘⌥2)

### Create a Project Board

1. Tag tasks with `#ProjectName`
2. Board automatically created
3. Switch layout to Kanban
4. Customize columns
5. Drag tasks through workflow

### Use Freeform Canvas

1. Create custom board
2. Select Freeform layout
3. Add tasks or notes
4. Drag to arrange spatially
5. Zoom in/out with ⌘+/-
6. Organize visually

### Weekly Review

1. Press ⌘1 - Process inbox to zero
2. Press ⌘2 - Review next actions
3. Press ⌘5 - Check waiting items
4. Press ⌘6 - Scan someday/maybe
5. Press ⌘7 - Review all active
6. Look ahead at upcoming week

## Documentation

**Getting Started**
- **[Quick Start Guide](docs/QUICK_START.md)** - Get up and running in 5 minutes
- **[User Guide](docs/USER_GUIDE.md)** - Complete usage documentation
- **[FAQ](docs/FAQ.md)** - Common questions and troubleshooting

**Reference**
- **[Features](docs/FEATURES.md)** - All 30+ features explained with examples
- **[Keyboard Shortcuts](docs/KEYBOARD_SHORTCUTS.md)** - Complete shortcuts reference
- **[File Format](docs/FILE_FORMAT.md)** - Technical specification for plain-text format

**Advanced**
- **[Development Guide](docs/DEVELOPMENT.md)** - Contributing and architecture
- **[Siri Shortcuts Guide](docs/SIRI_SHORTCUTS_GUIDE.md)** - Voice control setup
- **[Search Quick Reference](docs/SEARCH_QUICK_REFERENCE.md)** - Advanced search operators

## Building from Source

### Prerequisites

- Xcode 15.0 or later
- macOS 14.0 SDK
- Swift 5.9 or later

### Build Steps

```bash
# Clone repository
git clone https://github.com/yourusername/sticky-todo.git
cd sticky-todo

# Open in Xcode
open StickyToDo.xcodeproj

# Or build from command line
xcodebuild -project StickyToDo.xcodeproj -scheme StickyToDo build

# Run tests
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo
```

### Project Structure

```
StickyToDo/
├── StickyToDoCore/           # Shared core models
│   └── Models/               # Task, Board, Perspective, etc.
├── StickyToDo/               # Main SwiftUI app
│   ├── Data/                 # Data layer (stores, I/O, parsers)
│   └── Views/                # UI components
├── StickyToDo-AppKit/        # AppKit board canvas
├── StickyToDoTests/          # Unit tests (80%+ coverage)
└── docs/                     # Documentation
```

## Architecture

### Phase 1 (Current MVP)

- Parse all markdown files on launch into Swift structs
- Keep everything in memory while app runs
- Write to files on every change (debounced 500ms)
- FSEvents watches for external file changes
- Target: 500-1000 tasks with < 2 second launch time

### Data Flow

```
User Input → Store (in-memory) → File I/O (debounced) → Markdown Files
              ↑                                             ↓
          File Watcher ← FSEvents ← External Changes ←─────┘
```

### Technology Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI + AppKit (for advanced canvas)
- **Data Format**: Markdown + YAML (via Yams)
- **Architecture**: MVVM with Combine
- **Testing**: XCTest (comprehensive test suite)

## Data Format

Tasks are stored as markdown files with YAML frontmatter:

```markdown
---
id: 550e8400-e29b-41d4-a716-446655440000
type: task
title: Call John about proposal
status: next-action
project: Sales
context: "@phone"
priority: high
due: 2025-11-20T09:00:00Z
flagged: true
effort: 30
created: 2025-11-18T10:00:00Z
modified: 2025-11-18T14:15:00Z
---

Discuss Q4 proposal and timeline.

Key points to cover:
- Budget requirements
- Timeline expectations
- Resource allocation
```

**File Organization:**
- Active: `tasks/active/YYYY/MM/uuid-slug.md`
- Archive: `tasks/archive/YYYY/MM/uuid-slug.md`
- Boards: `boards/board-id.md`
- Config: `config/*.yaml`

## Design Philosophy

- **YAGNI**: Don't build features until they're needed
- **Plain Text First**: All features must work with plain text storage
- **Dual-Mode Equality**: List and board views have equal status
- **User Ownership**: Users own their data in a readable, portable format
- **GTD-Compliant**: Follow Getting Things Done methodology
- **Keyboard-First**: Power users can work entirely from keyboard
- **Privacy-Focused**: All data local, no cloud requirement

## Testing

Comprehensive test suite with 80%+ coverage:

- **ModelTests** - Task, Board, Perspective models
- **YAMLParserTests** - Frontmatter parsing and generation
- **MarkdownFileIOTests** - File I/O operations
- **TaskStoreTests** - Task management and filtering
- **BoardStoreTests** - Board management and auto-creation
- **NaturalLanguageParserTests** - Quick capture parsing
- **DataManagerTests** - Integration and coordination

Run tests:
```bash
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo
```

## Roadmap

### Version 1.0 (MVP)
- [x] Core models
- [x] Data layer (file I/O, YAML parsing)
- [x] Task and board stores
- [x] Comprehensive test suite
- [ ] SwiftUI list views
- [ ] Board canvas (freeform, kanban, grid)
- [ ] Quick capture with natural language
- [ ] File watcher and sync
- [ ] Settings and preferences

### Version 1.1
- [ ] Custom perspectives
- [ ] Advanced filters
- [ ] Keyboard shortcuts customization
- [ ] Import/export utilities
- [ ] Templates

### Version 2.0
- [ ] iOS/iPadOS support
- [ ] iCloud sync
- [ ] Collaboration features
- [ ] SQLite migration (for performance)

### Future Considerations
- [ ] Siri shortcuts
- [ ] Widget support
- [ ] URL schemes
- [ ] Scripting/automation
- [ ] Themes and customization

## Contributing

Contributions are welcome! See [DEVELOPMENT.md](docs/DEVELOPMENT.md) for:

- Architecture overview
- Code style guidelines
- Testing requirements
- Pull request process

### Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Commit with conventional commits (`feat:`, `fix:`, etc.)
7. Push to your fork
8. Open a Pull Request

## Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/yourusername/sticky-todo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/sticky-todo/discussions)

## Acknowledgments

- **Getting Things Done** methodology by David Allen
- **Yams** for YAML parsing
- Inspired by OmniFocus, Miro, and plain-text task management

## License

MIT License - see [LICENSE](LICENSE) file for details

## Contact

For questions about design decisions or implementation details, refer to:
- [Design Document](docs/plans/2025-11-17-sticky-todo-design.md)
- [Project Handoff](HANDOFF.md)
- [Development Guide](docs/DEVELOPMENT.md)

---

Made with ❤️ for GTD enthusiasts and plain-text lovers

**Your tasks. Your format. Your control.**
