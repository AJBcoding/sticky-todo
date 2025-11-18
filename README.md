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

### Two-Tier Task System

- **Notes**: Lightweight items for brainstorming with minimal friction
- **Tasks**: Full GTD items with complete metadata (project, context, priority, due dates, effort, etc.)
- Seamlessly promote notes to tasks by applying metadata

### Plain Text Foundation

- **Markdown Storage**: Tasks stored as markdown files with YAML frontmatter
- **Human-Readable**: Edit in VS Code, Obsidian, or any text editor
- **Version Control**: Use git to track changes, collaborate, and maintain history
- **Future-Proof**: Standard formats ensure long-term accessibility
- **Sync-Friendly**: Works with Dropbox, iCloud Drive, or any file sync service

### Visual Board Layouts

**Freeform Canvas**
- Infinite canvas for brainstorming
- Drag tasks anywhere
- Zoom and pan
- Spatial organization
- Perfect for mind mapping and planning

**Kanban Boards**
- Vertical swim lanes for workflows
- Drag tasks between columns
- Auto-update task metadata
- Customizable columns
- Great for process management

**Grid Boards**
- Organized sections
- Auto-arrange layout
- Compact task view
- Category-based organization
- Ideal for structured lists

### GTD Workflow

**Five Core Statuses**
- **Inbox**: Unprocessed items awaiting clarification
- **Next Actions**: Ready-to-work tasks
- **Waiting For**: Blocked or delegated items
- **Someday/Maybe**: Future possibilities
- **Completed**: Finished tasks (auto-archived)

**Smart Perspectives**
- Inbox - Process new items
- Next Actions - Grouped by context
- Flagged - Starred for attention
- Due Soon - Upcoming deadlines
- Waiting For - Blocked items
- Someday/Maybe - Future ideas
- All Active - Complete overview
- Create custom perspectives

### Quick Capture

Global hotkey (⌘⇧Space) for instant task capture from anywhere on macOS.

**Natural Language Parsing:**
```
Call John @phone #Website !high tomorrow //30m
```

Automatically extracts:
- Title: "Call John"
- Context: @phone
- Project: Website
- Priority: High
- Due: Tomorrow
- Effort: 30 minutes

**Supported Patterns:**
- `@context` - Work context (@phone, @computer, @office, etc.)
- `#project` - Project assignment
- `!priority` - Priority level (!high, !medium, !low)
- `tomorrow`, `friday`, `nov 20` - Due dates
- `^defer:date` - Defer/start dates
- `//30m`, `//2h` - Effort estimates

### Boards as Filters

- Boards don't contain tasks; they filter and display them
- Tasks appear when they match filter criteria
- Moving tasks to boards updates their metadata
- Tasks can appear on multiple boards simultaneously
- Dynamic board creation for contexts and projects

### File Watching

- Detects external file changes
- Auto-reloads modified tasks
- Conflict detection and resolution
- Edit files in your favorite editor
- Changes sync immediately

### Rich Metadata

- **Projects**: Group related tasks
- **Contexts**: Where/how tasks are done
- **Priority**: High, Medium, Low
- **Due Dates**: Hard deadlines
- **Defer Dates**: Hide until start date
- **Effort Estimates**: Time in minutes/hours
- **Flags**: Star important items
- **Notes**: Full markdown support
- **Positions**: Task placement on boards

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

### For Users
- **[User Documentation](docs/user/)** - Complete user guides and references
  - [User Guide](docs/user/USER_GUIDE.md) - Complete usage documentation
  - [Quick Reference](docs/user/QUICK_REFERENCE.md) - Quick reference guide
  - [Keyboard Shortcuts](docs/user/KEYBOARD_SHORTCUTS.md) - All shortcuts reference
  - [Feature Guides](docs/user/) - Siri Shortcuts, Search, Recurring Tasks

### For Developers
- **[Developer Documentation](docs/developer/)** - Development setup and guidelines
  - [Development Guide](docs/developer/DEVELOPMENT.md) - Contributing and architecture
  - [Build Setup](docs/developer/BUILD_SETUP.md) - Building the project
  - [Xcode Setup](docs/developer/XCODE_SETUP.md) - Xcode configuration

### Technical & Planning
- **[Technical Documentation](docs/technical/)** - Specifications and architecture
  - [File Format](docs/technical/FILE_FORMAT.md) - Task file format specification
  - [Search Architecture](docs/technical/SEARCH_ARCHITECTURE.txt) - Search system design
  - [Integration Guides](docs/technical/) - Integration and testing documentation
- **[Plans & Design](docs/plans/)** - Design documents and planning
- **[Features](docs/features/)** - Feature-specific documentation
- **[Examples](docs/examples/)** - Example files and demonstrations

### Project Status & Reports
- **[Implementation Reports](docs/implementation/)** - Detailed feature implementation reports
- **[Status Reports](docs/status/)** - Project status and progress tracking
- **[Assessment Reports](docs/assessments/)** - Code reviews and quality assessments
- **[Pull Requests](docs/pull-requests/)** - Pull request documentation
- **[Handoff Documentation](docs/handoff/)** - Project handoff and knowledge transfer

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

Contributions are welcome! See [DEVELOPMENT.md](docs/developer/DEVELOPMENT.md) for:

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
- [Project Handoff](docs/handoff/HANDOFF.md)
- [Development Guide](docs/developer/DEVELOPMENT.md)

---

Made with ❤️ for GTD enthusiasts and plain-text lovers

**Your tasks. Your format. Your control.**
