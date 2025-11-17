# StickyToDo Project Handoff

**Date:** 2025-11-17
**Status:** Design Complete, Ready for Implementation
**Project Location:** `/Users/anthonybyrnes/PycharmProjects/Sticky To Do/`

## Project Overview

StickyToDo is a macOS task management application that combines OmniFocus-style GTD methodology with Miro-style visual boards. Users work in two equal modes: traditional list views for processing tasks, and visual board views for planning and prioritization.

**Core Innovation:** All data stores in plain text markdown files. Users own their data in a format they can read, edit, and version control. Tasks appear on boards automatically based on metadata filters—moving tasks between boards updates their metadata.

## What Was Completed

### Design Phase (2025-11-17)

We conducted a comprehensive brainstorming session that refined the initial concept into a complete technical design:

**Deliverables:**
- Complete design document: `docs/plans/2025-11-17-sticky-todo-design.md`
- Git repository initialized with first commit
- File structure established (`docs/plans/` directory created)

**Design Artifacts:**
- Data architecture and file structure
- Task metadata schema (YAML frontmatter)
- Board system with three layouts (freeform, kanban, grid)
- List view perspectives
- Quick capture workflows
- Import/export specifications
- UI/UX wireframes and keyboard shortcuts
- Technical architecture (Phase 1 in-memory, Phase 2 SQLite)
- Phased roadmap (3 phases defined)

### Key Design Decisions

**1. Plain Text Foundation**
- Tasks store as markdown files with YAML frontmatter
- File structure: `tasks/active/YYYY/MM/uuid-title.md`
- Completed tasks move to `tasks/archive/YYYY/MM/`
- Boards define as `boards/*.md` files with frontmatter config
- Decision rationale: Data durability, user ownership, version control friendly

**2. Two-Tier Task System**
- Notes: Lightweight items for brainstorming (type: note)
- Tasks: Full GTD items with complete metadata (type: task)
- Users promote notes to tasks by applying metadata (project, context, etc.)
- Decision rationale: Reduces friction during brainstorming while maintaining GTD rigor for execution

**3. Boards as Filters**
- Boards don't contain tasks; they filter and display them
- Tasks appear on boards when they match filter criteria
- Moving task to board updates its metadata based on board type
- Tasks can appear on multiple boards simultaneously
- Decision rationale: Single source of truth, no data duplication, automatic organization

**4. Phase 1 In-Memory Approach**
- Parse all markdown files on launch into Swift structs
- Keep everything in memory while app runs
- Write to files on every change (debounced 500ms)
- FSEvents watches for external file changes
- Decision rationale: Simpler implementation for MVP, adequate for 500-1000 tasks, migrate to SQLite in Phase 2 when needed

**5. UI Framework: To Be Determined**
- Must prototype freeform canvas in both SwiftUI and AppKit
- Test: drag/drop, pan/zoom, lasso select, multi-select
- Choose framework based on which handles complex canvas interactions better
- Decision deferred until prototyping complete

**6. Contexts vs Projects**
- Contexts: Predefined list in `config/contexts.md` (stable, managed in Settings)
- Projects: Dynamic, auto-created on first use, auto-hide after 7 days inactive
- Decision rationale: Contexts are tools/locations (finite set), projects come and go (infinite)

## Current Repository State

```
Sticky To Do/
├── .git/                     # Git repository initialized
├── docs/
│   └── plans/
│       └── 2025-11-17-sticky-todo-design.md  # Complete design doc
└── HANDOFF.md               # This file
```

**Git Status:**
- Branch: main
- Commits: 1 (31a6b27)
- Working tree: clean

**No code written yet.** Project is in design phase.

## Next Steps (Priority Order)

### Immediate (Required for MVP)

**1. Framework Decision (1-2 days)**
- Create new Xcode project
- Prototype freeform canvas in SwiftUI
  - Test drag/drop for sticky notes
  - Test pan/zoom on infinite canvas
  - Test lasso select with multi-select
  - Test performance with 50-100 items
- Prototype same canvas in AppKit
  - Same tests as SwiftUI
- Document findings, choose framework
- Commit decision to repository

**2. Core Data Layer (1 week)**
- Implement Task struct with Codable
- Implement Board struct with Codable
- Build YAML frontmatter parser (use Yams library)
- Build markdown file reader/writer
- Create TaskStore and BoardStore (in-memory)
- Write unit tests for parsing and persistence
- Test with sample markdown files

**3. File System Integration (3-4 days)**
- Implement file structure creation (tasks/, boards/, config/)
- Build file watcher using FSEvents
- Handle external file changes
- Implement auto-save with debouncing
- Test concurrent access scenarios
- Add error handling for corrupted files

**4. List View Implementation (1 week)**
- Build task list UI with grouping and sorting
- Implement Inbox perspective
- Implement Next Actions perspective
- Add inline editing for task title
- Create task detail inspector panel
- Add keyboard navigation (j/k, enter, ⌘↩)

**5. Quick Capture (3-4 days)**
- Implement global hotkey listener
- Build floating quick capture window
- Create in-app quick add panel
- Implement natural language parser for metadata
  - @context, #project, !priority, dates, effort
  - Use NSDataDetector for dates or custom parser
- Test capture from various macOS contexts

**6. Board View - Freeform Layout (1 week)**
- Implement infinite canvas with pan/zoom
- Build sticky note UI component
- Add drag-to-reposition functionality
- Implement lasso select
- Add batch metadata application to selected notes
- Build note → task promotion workflow
- Test with 100+ items for performance

### Short Term (Complete Phase 1)

**7. Board View - Kanban Layout (4-5 days)**
- Build column-based layout
- Implement drag between columns
- Add metadata update rules per column
- Create board configuration UI

**8. Board View - Grid Layout (3-4 days)**
- Build section-based layout
- Implement snap-to-grid or auto-arrange
- Add section configuration

**9. Remaining Perspectives (3-4 days)**
- Implement all built-in smart perspectives
- Add custom board creation UI
- Build board sidebar navigation

**10. Search & Filtering (3-4 days)**
- Implement quick search (⌘F)
- Build search syntax parser
- Add live filtering

**11. Import/Export (1 week)**
- Build native markdown export (zip)
- Implement TaskPaper import/export
- Add CSV export
- Add JSON export
- Create import wizard UI

**12. Polish & Settings (1 week)**
- Build Settings/Preferences UI
- Implement first-run experience
- Add all keyboard shortcuts
- Create app icon and branding
- Write user documentation

### Medium Term (Phase 2 Planning)

**13. Performance Analysis**
- Monitor with 500+ tasks
- Profile launch time and memory usage
- Identify bottlenecks
- Plan SQLite migration if needed

**14. iOS/iPadOS Planning**
- Evaluate cross-platform code sharing
- Design touch interactions for boards
- Plan iCloud sync architecture

## Critical Context & Considerations

### Technical Decisions to Finalize During Implementation

1. **Frontmatter format:** YAML chosen for readability, but TOML or JSON possible alternatives
2. **Natural language parser:** Evaluate existing libraries vs custom implementation
3. **Task UUID format:** Full UUID vs shorter hash for filename readability
4. **Board column actions:** Need syntax for complex metadata updates (e.g., "set priority=high AND status=in-progress")

### Potential Challenges

**Canvas Performance:**
- Rendering 100+ sticky notes with smooth pan/zoom
- Mitigation: Use viewport culling, render only visible items

**File Watching Conflicts:**
- User edits file externally while app has uncommitted changes
- Mitigation: Timestamp comparison, diff UI, backup before overwrite

**Natural Language Parsing Ambiguity:**
- "Call John tomorrow about the #design project @home"
- Is "#design" a hashtag or markdown heading?
- Mitigation: Graceful degradation, manual override always available

**Board Filter Complexity:**
- Advanced filters with AND/OR logic
- Mitigation: Start with simple filters (single field match), add complexity in Phase 2

### Design Philosophy

**YAGNI (You Aren't Gonna Need It):**
- Phase 1 intentionally excludes features that add complexity without clear value
- Deferred to Phase 2: subtasks, attachments, recurring tasks, custom fields
- Don't build these until users request them

**Plain Text Constraints:**
- All features must work with plain text storage
- Complex relationships (subtasks) harder to represent in flat files
- Consider this when designing Phase 2 features

**Dual-Mode Equality:**
- List view and board view must have equal status
- Don't treat one as "advanced" or secondary
- Users should never feel forced to use one over the other

## Resources & References

### Design Document Sections (Quick Reference)

| Section | Page/Topic | Key Info |
|---------|-----------|----------|
| Data Architecture | File structure, metadata schema | YAML frontmatter format |
| Board System | Three layouts, filters | How boards work |
| List View | Perspectives | Built-in smart views |
| Quick Capture | Four capture modes | Natural language syntax |
| Technical Architecture | Phase 1 approach | In-memory + file I/O |
| Phased Roadmap | MVP scope | What's in/out of Phase 1 |

### External References

**GTD Methodology:**
- David Allen's "Getting Things Done"
- Core concepts: Inbox, Next Actions, Contexts, Projects, Weekly Review

**Similar Apps (Research):**
- OmniFocus: Perspectives, review mode, keyboard-first design
- Things: Natural language parsing, clean UI
- Asana: Board view with list view toggle
- Miro: Freeform canvas, infinite zoom, sticky notes
- TaskPaper: Plain text task format with tags

**macOS Development:**
- [SwiftUI Canvas Documentation](https://developer.apple.com/documentation/swiftui/)
- [AppKit NSView Custom Drawing](https://developer.apple.com/documentation/appkit/nsview)
- [FSEvents Programming Guide](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/)
- [YAML Parser for Swift (Yams)](https://github.com/jpsim/Yams)

### Files to Create for Phase 1

**Configuration:**
- `.gitignore` (Xcode, macOS, build artifacts)
- `README.md` (project overview, setup instructions)
- `LICENSE` (choose appropriate license)

**Documentation:**
- `docs/architecture.md` (technical deep-dive)
- `docs/file-format.md` (markdown format specification)
- `docs/keyboard-shortcuts.md` (complete shortcut reference)

**Code Structure (suggested):**
```
StickyToDo/
├── StickyToDo.xcodeproj
├── StickyToDo/
│   ├── Models/
│   │   ├── Task.swift
│   │   ├── Board.swift
│   │   ├── Context.swift
│   │   └── Perspective.swift
│   ├── Data/
│   │   ├── MarkdownParser.swift
│   │   ├── TaskStore.swift
│   │   ├── BoardStore.swift
│   │   └── FileWatcher.swift
│   ├── Views/
│   │   ├── ListView/
│   │   ├── BoardView/
│   │   ├── QuickCapture/
│   │   └── Inspector/
│   ├── Controllers/
│   └── Utilities/
└── StickyToDoTests/
```

## Questions for Product Owner

Before starting implementation, clarify:

1. **Target macOS version?** (macOS 13+ for SwiftUI, or support older versions?)
2. **App distribution?** (Mac App Store, direct download, or both?)
3. **License model?** (Open source, commercial, freemium?)
4. **Phase 1 timeline?** (How many weeks/months for MVP?)
5. **Analytics/telemetry?** (None for privacy, or basic usage stats?)
6. **Crash reporting?** (Use service like Sentry, or none?)

## Success Metrics for Phase 1

**MVP is successful when:**

1. User can capture 100 tasks via global hotkey in < 30 seconds total
2. User can process Inbox to zero using list view with keyboard only
3. User can create freeform brainstorm board, add 20 notes, promote 10 to tasks, all in < 5 minutes
4. All data exports to zip, imports back without loss
5. App handles 500 tasks with < 2 second launch time
6. External markdown edits reflect in app without restart
7. No data loss on crash (auto-save working)
8. User can perform GTD weekly review using built-in perspectives

## Getting Started Checklist

When you pick up this project:

- [ ] Read complete design document (`docs/plans/2025-11-17-sticky-todo-design.md`)
- [ ] Review this handoff document
- [ ] Install Xcode and latest macOS SDK
- [ ] Create new Xcode project (macOS app)
- [ ] Set up `.gitignore` for Xcode
- [ ] Create prototype branch: `git checkout -b prototype/canvas-framework`
- [ ] Build SwiftUI canvas prototype
- [ ] Build AppKit canvas prototype
- [ ] Document framework decision
- [ ] Merge decision to main
- [ ] Create feature branch: `git checkout -b feature/data-layer`
- [ ] Begin implementation following Next Steps priority order

## Contact & Context

**Brainstorming Session:** 2025-11-17
**Design Collaborator:** Claude (Anthropic)
**Design Methodology:** Socratic dialogue, iterative refinement, YAGNI principle
**Total Design Time:** ~2 hours
**Key Insight:** Plain text foundation enables data durability while boards-as-filters eliminate duplication

---

**Ready to build.** All major design decisions made. Clear path to MVP. Begin with framework prototyping.
