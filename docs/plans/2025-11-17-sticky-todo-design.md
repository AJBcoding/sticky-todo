# StickyToDo: Visual GTD Task Manager

**Design Document**
**Date:** 2025-11-17
**Platform:** macOS (Phase 1), iOS/iPadOS (Phase 2)

## Vision

StickyToDo combines OmniFocus-style GTD methodology with Miro's spatial organization. Users switch freely between traditional list views and visual board views. Both views show the same data through different lenses.

The application stores all data in plain text markdown files. Users own their data in a format they can read, edit, and version control.

## Core Principles

**Plain text foundation:** All tasks and boards live in human-readable markdown files with YAML frontmatter.

**Dual-mode interface:** List view and board view have equal status. Users choose the view that fits their current workflow.

**Two-tier task system:** Lightweight notes support brainstorming. Tasks carry full GTD metadata. Users promote notes to tasks when ideas become actionable.

**Boards as filters:** Tasks appear on boards when they match the board's filter criteria. Moving a task between boards updates its metadata.

## Data Architecture

### File Structure

```
project-root/
  tasks/
    active/
      2025/
        11/
          uuid-call-john.md
          uuid-design-mockups.md
    archive/
      2025/
        11/
          uuid-completed-task.md
  boards/
    inbox.md
    next-actions.md
    this-week.md
    computer-context.md
    website-project.md
  config/
    contexts.md
    settings.md
```

Tasks organize by status (active/archive) and creation date. This structure keeps active tasks accessible while archiving completed work.

### Task Metadata

Phase 1 metadata:

```yaml
---
type: task  # or "note"
title: "Call John about proposal"
status: next-action  # inbox, next-action, waiting, someday, completed
project: "Website Redesign"
context: "@phone"
due: 2025-11-20
defer: 2025-11-18
flagged: true
priority: high  # high, medium, low
effort: 30  # minutes
positions:
  brainstorming: {x: 150, y: 200}
  this-week: {x: 50, y: 100}
created: 2025-11-17T10:30:00Z
modified: 2025-11-17T11:45:00Z
---

Notes and detailed description go here.
Can include multiple paragraphs, links, etc.
```

Future phases add: color coding, custom tags, custom fields, attachments, subtasks.

### Board Configuration

Each board is a markdown file with frontmatter:

```yaml
---
type: context  # context, project, status, custom
layout: kanban  # freeform, kanban, grid
filter:
  context: "@computer"
columns: [To Do, In Progress, Done]  # for kanban
autoHide: true
hideAfterDays: 7
---

# @Computer Context

Tasks requiring a computer.
```

Board types determine metadata effects:

| Board Type | Moving task to board sets | Example |
|------------|---------------------------|---------|
| Context | `context: @value` | @Computer, @Home, @Errands |
| Project | `project: ProjectName` | Website Redesign, Q4 Planning |
| Status | `status: value` | Next Actions, Waiting For |
| Custom | User-defined rules | This Week sets `flagged: true` |

## Board System

### Three Layout Modes

**Freeform Canvas**
Users drag sticky notes anywhere on an infinite canvas. The system stores positions as x,y coordinates. This mode suits brainstorming and spatial planning.

Workflow:
1. Create notes on freeform board
2. Lasso select related notes
3. Apply metadata (project, context) to selection
4. Notes become tasks (type changes from note to task)
5. Tasks appear on relevant project and context boards

**Kanban Columns**
Vertical swim lanes move tasks through workflow stages. Board configuration defines columns and their metadata effects. Users drag tasks between columns or let them auto-arrange within columns.

**Grid/Sections**
Named sections organize tasks by priority, energy level, or other criteria. Tasks snap to grid or auto-arrange within sections.

Each board chooses its layout. Workflow boards use kanban. Brainstorming boards use freeform. Context boards use grid.

### Built-in Smart Boards

**GTD Core:**
- Inbox (status: inbox)
- Next Actions (status: next-action)
- Flagged (flagged: true)
- Waiting For (status: waiting)
- Someday/Maybe (status: someday)

**Time-based:**
- Due Today (due: today)
- Due This Week (due within 7 days)
- Overdue (due < today, status != completed)
- Scheduled (defer date in future)

**Dynamic:**
- One board per context (auto-created from contexts.md)
- One board per active project (auto-created, auto-hides after 7 days)

**Custom:**
- This Week (flagged OR due within 7 days)
- High Priority (priority: high AND status: next-action)
- Quick Wins (effort < 30 AND priority: high)

Project boards hide automatically after 7 days without active tasks. Users can show hidden boards manually or adjust the hide duration.

## List View & Perspectives

List view filters, groups, and sorts tasks. Each perspective defines these parameters:

```yaml
# Next Actions perspective
filter:
  status: next-action
  type: task
groupBy: context
sortBy: priority
showCompleted: false
```

Built-in perspectives:
- **Inbox:** Process new items
- **Next Actions:** Grouped by context, sorted by priority
- **Flagged:** Important items sorted by due date
- **Due Soon:** Items due within 7 days, color-coded (overdue=red, today=orange)
- **Waiting For:** Blocked items grouped by project
- **Someday/Maybe:** Future ideas grouped by project
- **All Active:** Complete overview grouped by project

List view features:
- Batch operations (multi-select to change metadata)
- Inline editing of title and common fields
- Keyboard navigation (j/k, enter to edit, ⌘↩ to complete)
- Context menu ("Show on Board X")

## Quick Capture

### Global Quick Capture

Users press a hotkey (default: ⌘⇧Space) anywhere in macOS. A floating window appears with a single text field. Type title, press Enter. Task creates with `status: inbox`. Window dismisses.

Ultra-low friction for capturing thoughts immediately.

### In-App Quick Add

Press N or + button. Larger panel appears with:
- Title field with natural language parsing
- Recent projects and contexts as one-click pills
- Optional expansion to full metadata fields

Parser recognizes:
- `@context` → sets context
- `#project` → sets project
- `!high`, `!medium`, `!low` → sets priority
- `tomorrow`, `friday`, `nov 20` → sets due date
- `^defer:tomorrow` → sets defer date
- `//30m` → sets effort estimate

Example: `"Call John @phone #Website !high tomorrow"`
- Title: "Call John"
- Context: @phone
- Project: Website
- Priority: high
- Due: 2025-11-18

### Template-based Capture

Quick-add panel shows recent and pinned templates. Click template to pre-fill common fields.

### Drag & Drop

Drop email, file, or URL onto app icon. Creates task with title from subject/filename. Attaches link or reference in notes.

All capture modes create tasks in Inbox.

## Technical Architecture (Phase 1)

### Technology Stack

**UI Framework:** Prototype board canvas in both SwiftUI and AppKit. Test freeform canvas with drag/drop, pan/zoom, and multi-select. Choose framework based on which handles complex interactions better.

Goal: macOS v1, then iOS/iPadOS using same framework.

### Data Layer

```
┌─────────────────┐
│   UI Layer      │  SwiftUI/AppKit Views
└────────┬────────┘
         │
┌────────▼────────┐
│  Data Manager   │  In-memory stores
│                 │  TaskStore, BoardStore
└────────┬────────┘
         │
┌────────▼────────┐
│ Markdown I/O    │  Parse/write files
│                 │  YAML frontmatter
└────────┬────────┘
         │
┌────────▼────────┐
│  File System    │  *.md files
└─────────────────┘
```

**In-memory approach (Phase 1):**
- Parse all markdown files on launch
- Keep everything in memory while app runs
- Write to markdown files on every change (debounced 500ms)
- Use FSEvents to watch for external changes

**SQLite migration (Phase 2):**
- When 500+ tasks make launch slow
- When search needs better performance
- Before implementing external file watching with conflict resolution

### Core Swift Models

```swift
struct Task: Identifiable, Codable {
    let id: UUID
    var type: TaskType  // note or task
    var title: String
    var notes: String
    var status: Status
    var project: String?
    var context: String?
    var due: Date?
    var defer: Date?
    var flagged: Bool
    var priority: Priority
    var effort: Int?
    var positions: [String: Position]
    var created: Date
    var modified: Date

    var filePath: String {
        // tasks/active/2025/11/uuid.md
    }
}

struct Board: Identifiable, Codable {
    let id: String
    var type: BoardType
    var layout: Layout
    var filter: Filter
    var columns: [String]?
    var autoHide: Bool
    var hideAfterDays: Int
}
```

### Persistence Strategy

- **On launch:** Parse all markdown files into memory
- **On change:** Write updated task immediately (debounced 500ms)
- **Crash recovery:** Write on every significant change
- **File watching:** Detect external edits, reload affected tasks, show conflict UI

## Import/Export

### Export Formats

**Native markdown archive:** Zip of entire tasks/ and boards/ directories. Perfect backup with full fidelity.

**Simplified markdown:** One file per project/board. Tasks as checklist items with inline metadata. Works in any markdown editor.

**TaskPaper format:** Compatible with TaskPaper app using tag syntax.

**CSV/TSV:** Spreadsheet format with metadata as columns. Import into Excel or databases.

**JSON:** Structured export for programmatic access and API integrations.

### Import Sources

**Native markdown:** Import zip or folder, auto-detect format.

**TaskPaper:** Parse tags, convert to metadata.

**OmniFocus:** Via TaskPaper export (user exports OmniFocus first). Direct database parsing in Phase 2.

**CSV/JSON:** Column/field mapping UI.

**Plain text checklists:** Parse markdown `- [ ]` syntax. Best-effort metadata extraction. Everything to Inbox.

### URL Scheme

```
stickytodo://add?title=Call%20John&context=@phone&project=Website
```

## Context & Project Management

### Contexts (Predefined)

Stored in `config/contexts.md`:

```yaml
---
contexts:
  - name: "@computer"
    icon: "💻"
    color: blue
  - name: "@phone"
    icon: "📱"
    color: green
  - name: "@home"
    icon: "🏠"
    color: orange
  - name: "@errands"
    icon: "🚗"
    color: purple
  - name: "@office"
    icon: "🏢"
    color: gray
---
```

Users add, edit, remove, and reorder contexts in Settings. Deleting a context warns if tasks use it and offers to reassign. Each context auto-creates a board.

### Projects (Dynamic)

Projects auto-create when first used. No separate config file required.

When users create a task with `project: Website Redesign`, that project exists. System auto-creates `boards/website-redesign.md`. Board appears in sidebar.

After all tasks complete or move, board auto-hides after 7 days (configurable). Project stays in archived task metadata. Users can show hidden boards manually.

**Phase 2:** Optional project files in `projects/*.md` for notes, goals, deadlines, and reference materials.

### Auto-complete

Typing project name suggests existing projects. Typing context shows dropdown of defined contexts. This prevents typos while allowing flexibility for projects.

## User Experience

### First Run

1. Choose storage location (default: ~/Documents/StickyToDo/)
2. Optional import from OmniFocus/TaskPaper
3. System creates default boards and sample contexts
4. Optional tutorial (skippable)

### Main Window

```
┌─────────────────────────────────────────────────────┐
│  [≡] StickyToDo      [List|Board]  [+] [Search] [⚙] │
├──────────┬──────────────────────────────────────────┤
│ SMART    │                                          │
│  Inbox   │         Main Content Area                │
│  Next    │      (List View or Board View)           │
│  Flagged │                                          │
│          │                                          │
│ CONTEXTS │                                          │
│  @Comp.. │                                          │
│  @Phone  │                                          │
│          │                                          │
│ PROJECTS │                                          │
│  Website │                                          │
│  Q4 Plan │                                          │
│          │                                          │
│ CUSTOM   │                                          │
│  This Wk │                                          │
└──────────┴──────────────────────────────────────────┘
```

### Keyboard Shortcuts

- ⌘N: New task (in-app)
- ⌘⇧Space: Global quick capture
- ⌘L: Switch to list view
- ⌘B: Switch to board view
- ⌘F: Focus search
- Space: Quick look at task
- Enter: Edit task
- ⌘↩: Toggle completion
- ⌘⌫: Delete task
- 1-9: Jump to sidebar item

### Settings

**General:**
- Storage location
- Default board on launch
- Auto-hide inactive projects after N days
- Auto-save interval

**Quick Capture:**
- Global hotkey
- Enable natural language parsing

**Contexts:**
- Manage contexts (add/edit/remove/reorder)
- Set icons and colors

**Boards:**
- Show/hide built-in boards
- Default layout for new boards
- Sidebar organization

**Advanced:**
- File watching
- Conflict resolution strategy
- Debug mode
- Export diagnostic logs

## Search

**Quick search (⌘F):** Search title, notes, project, context. Live filtering. Shows results in current view.

**Advanced filtering:** Build complex queries with UI. Combine filters: `project:Website AND context:@computer AND priority:high`. Date ranges: `due:next-7-days`. Save as custom board/perspective.

**Search syntax:** `project:Website @computer !high due:<7d`

## Task Editing

**Inspector panel:** Shows when task selected. Dropdown fields for all metadata. Notes area. Shows which boards display this task. Delete and duplicate buttons.

**Full editor (⌘O):** Large text area for notes. Markdown preview. All metadata fields. "Open in Finder" to edit raw .md file.

**Inline editing:** Click title in list view to edit in place. Tab through fields. Enter saves, Esc cancels.

**Batch editing:** Multi-select tasks. Right-click → "Edit Selected." Change common fields for all selected tasks.

## Error Handling

**Concurrent access:** FSEvents detects external changes. On conflict, show diff view. User chooses version. Auto-backup before overwriting.

**Corrupted files:** Parser recovers partial data. Quarantine corrupted files. Log error, notify user, continue loading other tasks.

**Missing directories:** Check for required directories on launch. Auto-create if missing. Warn if files disappeared.

**Large file sets:** Phase 1 targets 500-1000 tasks. Suggest archiving old completed tasks if launch slows. Provide "Archive completed older than X" tool.

**Metadata validation:** Show warning icon for unknown context. Suggest correction. Attempt parsing invalid dates, fall back to nil. Use sensible defaults for missing fields.

**Natural language parsing:** If parser fails, use input as plain title. No error message. Graceful degradation. User edits metadata manually.

**Performance targets:**
- Launch: < 2 seconds (500 tasks)
- Board switch: < 100ms
- Task creation: Instant (async write)
- Search: < 200ms (500 tasks)

## Phased Roadmap

### Phase 1: MVP (macOS)

Core features:
- Plain text markdown storage
- Two-tier system (notes → tasks)
- Full task metadata (title, notes, project, context, status, dates, priority, effort)
- In-memory data layer with file watching
- List view with built-in perspectives
- Board view (freeform, kanban, grid layouts)
- Boards as filters
- Drag between boards to update metadata
- Lasso select on freeform boards → batch metadata → promote to tasks
- Quick capture (global hotkey + in-app with natural language)
- Predefined contexts, dynamic projects
- Auto-hide inactive project boards
- Basic search
- Inspector panel
- Import/export (markdown, CSV, JSON, TaskPaper)
- Keyboard shortcuts

Success criteria:
- Manage 500+ tasks smoothly
- Quick capture from any app
- Fluid switching between list and board
- Natural brainstorming → execution workflow
- All data in readable markdown

### Phase 2: Power Features (iOS/iPadOS)

- Task hierarchy (unlimited nesting)
- SQLite index for performance
- Advanced search with filter builder
- Saved custom perspectives
- Color coding
- Custom tags
- Smart board type inference
- Attachments
- Task templates
- Project notes files
- Recurring tasks
- iOS and iPadOS apps
- iCloud sync (CloudKit or iCloud Drive)
- Conflict resolution UI
- GTD weekly review mode
- Freeform reorganization of existing tasks

### Phase 3: Collaboration

- Shared boards/projects
- Real-time sync for teams
- Comments and activity log
- Custom fields
- Automation/rules engine
- Time tracking integration
- Calendar integration
- Plugins/extensions API
- Themes and appearance
- AI-powered suggestions

## Open Decisions

Finalize during implementation:

1. Frontmatter format: YAML vs TOML vs JSON
2. Natural language parser: Custom vs existing library
3. Canvas framework: SwiftUI vs AppKit (after prototyping)
4. Task ID format: Full UUID vs shorter hash
5. Board column actions: Syntax for complex metadata updates

---

**Next Steps:**

1. Prototype canvas interactions in SwiftUI and AppKit
2. Choose UI framework based on prototype results
3. Implement markdown parser and file I/O
4. Build in-memory data layer
5. Create list view with basic perspectives
6. Implement quick capture
7. Build board view with freeform layout
8. Add kanban and grid layouts
9. Implement search
10. Polish UX and add keyboard shortcuts
