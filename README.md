# StickyToDo

A macOS task management application that combines OmniFocus-style GTD methodology with Miro-style visual boards.

## Overview

StickyToDo provides two equal modes of working with your tasks:

- **List View**: Traditional GTD perspectives for processing tasks (Inbox, Next Actions, Projects, etc.)
- **Board View**: Visual boards with three layouts (Freeform, Kanban, Grid) for planning and brainstorming

**Core Innovation**: All data stores in plain text markdown files. You own your data in a format you can read, edit, and version control. Tasks appear on boards automatically based on metadata filters—moving tasks between boards updates their metadata.

## Features

### Two-Tier Task System

- **Notes**: Lightweight items for brainstorming (minimal friction)
- **Tasks**: Full GTD items with complete metadata (project, context, priority, etc.)
- Seamlessly promote notes to tasks by applying metadata

### Plain Text Foundation

- Tasks stored as markdown files with YAML frontmatter
- File structure: `tasks/active/YYYY/MM/uuid-title.md`
- Completed tasks archived to: `tasks/archive/YYYY/MM/`
- Boards defined as: `boards/*.md` files with frontmatter config

### Boards as Filters

- Boards don't contain tasks; they filter and display them
- Tasks appear when they match filter criteria
- Moving tasks to boards updates their metadata
- Tasks can appear on multiple boards simultaneously

### Quick Capture

- Global hotkey for instant task capture
- Natural language parsing: `@context`, `#project`, `!priority`, dates, effort
- Minimal friction from thought to task

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for development)

## Project Structure

```
StickyToDo/
├── StickyToDo.xcodeproj/        # Xcode project
├── StickyToDo/                  # Main app target
│   ├── Models/                  # Data models (Task, Board, Context, etc.)
│   ├── Data/                    # Data layer (parsers, stores, file watcher)
│   ├── Views/                   # SwiftUI views
│   │   ├── ListView/            # List view components
│   │   ├── BoardView/           # Board view components
│   │   ├── QuickCapture/        # Quick capture UI
│   │   └── Inspector/           # Task detail inspector
│   ├── Controllers/             # View controllers and coordinators
│   ├── Utilities/               # Helper functions and extensions
│   ├── StickyToDoApp.swift      # App entry point
│   ├── ContentView.swift        # Main app view
│   ├── Assets.xcassets/         # Images and icons
│   └── StickyToDo.entitlements  # App capabilities
├── StickyToDoTests/             # Unit tests
├── docs/                        # Documentation
│   └── plans/                   # Design documents
├── .gitignore                   # Git ignore rules
├── HANDOFF.md                   # Project handoff document
└── README.md                    # This file
```

## Development Status

**Current Phase**: Initial Setup Complete

The Xcode project structure has been created with:
- SwiftUI lifecycle
- macOS 13.0 minimum deployment target
- Organized folder structure for Models, Data, Views, Controllers, and Utilities
- Basic app scaffold with navigation
- Unit test target

**Next Steps**: See `HANDOFF.md` for detailed implementation roadmap

### Priority 1: Framework Decision

Before full implementation, we need to prototype the freeform canvas in both SwiftUI and AppKit to determine which framework handles complex canvas interactions better (drag/drop, pan/zoom, lasso select).

## Building the Project

1. Clone the repository
2. Open `StickyToDo.xcodeproj` in Xcode
3. Select the StickyToDo scheme
4. Build and run (⌘R)

## Architecture

### Phase 1 (Current MVP Target)

- Parse all markdown files on launch into Swift structs
- Keep everything in memory while app runs
- Write to files on every change (debounced 500ms)
- FSEvents watches for external file changes
- Target: 500-1000 tasks with < 2 second launch time

### Phase 2 (Future)

- Migrate to SQLite for better performance
- iOS/iPadOS support
- iCloud sync

## Data Format

Tasks are stored as markdown files with YAML frontmatter:

```markdown
---
id: 550e8400-e29b-41d4-a716-446655440000
type: task
title: Implement quick capture
project: StickyToDo Development
context: coding
priority: high
status: in-progress
created: 2025-11-17T10:00:00Z
modified: 2025-11-17T14:30:00Z
---

# Implement quick capture

Build the global hotkey listener and floating quick capture window.

## Notes
- Use NSEvent for global hotkey
- Window should be always on top
- Parse natural language for metadata
```

## Design Philosophy

- **YAGNI**: Don't build features until they're needed
- **Plain Text First**: All features must work with plain text storage
- **Dual-Mode Equality**: List and board views have equal status
- **User Ownership**: Users own their data in a readable, portable format

## Documentation

- `docs/plans/2025-11-17-sticky-todo-design.md` - Complete design document
- `HANDOFF.md` - Project handoff and implementation roadmap

## License

TBD

## Contact

For questions about design decisions or implementation details, refer to the design documentation in the `docs/` directory.
