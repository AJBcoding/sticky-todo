# StickyToDo - System Architecture

**Version**: 1.0.0
**Last Updated**: 2025-11-18
**Status**: Production Ready

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Overview](#system-overview)
3. [Architecture Layers](#architecture-layers)
4. [Data Flow](#data-flow)
5. [Module Structure](#module-structure)
6. [Technology Stack](#technology-stack)
7. [Design Patterns](#design-patterns)
8. [Storage Architecture](#storage-architecture)
9. [Performance Architecture](#performance-architecture)
10. [Security Architecture](#security-architecture)

---

## Executive Summary

StickyToDo employs a **layered architecture** with clear separation of concerns, combining the best of **SwiftUI's declarative UI** with **AppKit's high-performance rendering** for board canvas operations. The system is built around **plain-text markdown storage** with a reactive, in-memory data layer that provides instant responsiveness while ensuring data durability through debounced writes.

### Key Architectural Decisions

1. **Hybrid UI Framework**: SwiftUI for app shell, AppKit for canvas performance
2. **Plain-Text Storage**: Markdown + YAML for future-proof data ownership
3. **In-Memory First**: All data loaded at startup for instant access
4. **Reactive Data Flow**: Combine framework with @Published properties
5. **Debounced Persistence**: 500ms delay to reduce disk I/O
6. **File Watching**: FSEvents for external change detection

---

## System Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                       │
│  ┌────────────────────────┐      ┌──────────────────────────┐  │
│  │   SwiftUI Components   │      │   AppKit Components      │  │
│  │  - Windows & Navigation│      │  - High-Perf Canvas      │  │
│  │  - List Views          │      │  - Gestures & Rendering  │  │
│  │  - Inspector Panels    │      │  - Zoom & Pan            │  │
│  │  - Settings & Prefs    │      │  - Lasso Selection       │  │
│  └──────────┬─────────────┘      └──────────┬───────────────┘  │
└─────────────┼────────────────────────────────┼──────────────────┘
              │                                │
              └────────────┬───────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                   Application/Coordination Layer                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              AppCoordinator Protocol                      │  │
│  │  - Navigation routing                                     │  │
│  │  - Action handling (create, update, delete)              │  │
│  │  - State coordination                                     │  │
│  └─────────────────────┬────────────────────────────────────┘  │
│           ┌────────────┴─────────────┐                          │
│    ┌──────▼──────┐          ┌────────▼─────────┐               │
│    │   SwiftUI   │          │     AppKit       │               │
│    │ Coordinator │          │   Coordinator    │               │
│    └─────────────┘          └──────────────────┘               │
└─────────────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                        Business Logic Layer                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              DataManager (Singleton)                      │  │
│  │  - Lifecycle management (init, shutdown)                 │  │
│  │  - Coordination between stores                           │  │
│  │  - File watching integration                             │  │
│  │  - Conflict resolution                                    │  │
│  └────────┬────────────────────────────┬─────────────────────┘  │
│      ┌────▼──────┐              ┌──────▼────────┐               │
│      │ TaskStore │              │  BoardStore   │               │
│      │@Published │              │  @Published   │               │
│      │- Filtering│              │  - Auto-hide  │               │
│      │- Searching│              │  - Visibility │               │
│      │- CRUD ops │              │  - Dynamic    │               │
│      └────┬──────┘              └──────┬────────┘               │
└───────────┼────────────────────────────┼─────────────────────────┘
            │                            │
            └──────────┬─────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────────┐
│                      Data Access Layer                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            MarkdownFileIO                                 │  │
│  │  - Read/Write Task and Board objects                     │  │
│  │  - Directory structure management                        │  │
│  │  - Bulk loading operations                               │  │
│  │  - Thread-safe file operations                           │  │
│  └────────────────────┬─────────────────────────────────────┘  │
│  ┌────────────────────▼─────────────────────────────────────┐  │
│  │            YAMLParser (Yams)                              │  │
│  │  - Parse YAML frontmatter → Swift structs                │  │
│  │  - Generate YAML frontmatter from Swift structs          │  │
│  │  - Error recovery and validation                         │  │
│  └────────────────────┬─────────────────────────────────────┘  │
│  ┌────────────────────▼─────────────────────────────────────┐  │
│  │            FileWatcher (FSEvents)                         │  │
│  │  - Monitor directory for external changes                │  │
│  │  - Debounce rapid events (200ms)                         │  │
│  │  - Trigger reload on file modifications                  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                           │
                   ┌───────▼────────┐
                   │  File System   │
                   │  - tasks/      │
                   │  - boards/     │
                   │  - config/     │
                   └────────────────┘
```

### Component Interactions

```
┌──────────────┐
│     User     │
└──────┬───────┘
       │ Interaction (keyboard, mouse, voice)
       ▼
┌──────────────────────────────────────────┐
│        UI Layer (SwiftUI/AppKit)         │
│  - Captures events                        │
│  - Displays data via bindings            │
└──────┬───────────────────────────────────┘
       │ Actions (create, update, delete)
       ▼
┌──────────────────────────────────────────┐
│      Coordinator (AppCoordinator)        │
│  - Routes navigation                      │
│  - Validates actions                     │
│  - Calls DataManager                     │
└──────┬───────────────────────────────────┘
       │ Business operations
       ▼
┌──────────────────────────────────────────┐
│         DataManager (Singleton)          │
│  - Coordinates TaskStore & BoardStore    │
│  - Triggers debounced saves              │
│  - Handles conflicts                     │
└──────┬───────────────────────────────────┘
       │ State updates
       ▼
┌──────────────────────────────────────────┐
│      TaskStore / BoardStore              │
│  - Updates @Published properties         │
│  - Filters and searches                  │
│  - Maintains in-memory state             │
└──────┬───────────────────────────────────┘
       │ @Published changes
       ▼
┌──────────────────────────────────────────┐
│           UI Layer (Observes)            │
│  - SwiftUI auto-updates via bindings    │
│  - Re-renders affected views             │
└──────────────────────────────────────────┘

       ┌─── Async (debounced 500ms) ───┐
       │                                │
       ▼                                │
┌──────────────────────────────────────────┐
│         MarkdownFileIO                   │
│  - Writes task to .md file              │
│  - Generates YAML frontmatter           │
│  - Saves to disk                        │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│          File System                     │
│  tasks/active/YYYY/MM/uuid-slug.md      │
└──────────────────────────────────────────┘
```

---

## Architecture Layers

### 1. Presentation Layer

**Responsibility**: User interface and interaction handling

**Technologies**:
- SwiftUI for declarative UI (70% of app)
- AppKit for high-performance canvas (30% of app)
- NSViewControllerRepresentable for SwiftUI/AppKit bridging

**Components**:

**SwiftUI Components**:
- `ContentView` - Main window with split view
- `PerspectiveSidebarView` - Navigation sidebar
- `TaskListView` - Traditional list view
- `TaskRowView` - Individual task row
- `TaskInspectorView` - Detailed task editor
- `QuickCaptureView` - Global quick capture window
- `SettingsView` - App preferences
- `OnboardingView` - First-run experience

**AppKit Components**:
- `BoardCanvasViewController` - High-performance canvas
- `CanvasView` - Infinite scroll view with pan/zoom
- `StickyNoteView` - Individual task card on canvas
- `LassoSelectionOverlay` - Selection rectangle

**Design Principles**:
- **Declarative** - SwiftUI describes UI state, not mutations
- **Reactive** - UI automatically updates when @Published properties change
- **Performance-First** - AppKit for canvas ensures 60 FPS

---

### 2. Coordination Layer

**Responsibility**: Navigation routing and action orchestration

**Protocol-Based Design**:

```swift
protocol AppCoordinator {
    // Navigation
    func navigate(to perspective: Perspective)
    func navigate(to board: Board)

    // Actions
    func showQuickCapture()
    func showTaskInspector(for task: Task)

    // Task operations
    func createTask(from input: String)
    func updateTask(_ task: Task)
    func deleteTask(_ task: Task)

    // Board operations
    func createBoard(_ board: Board)
    func updateBoard(_ board: Board)
}
```

**Implementations**:
- `SwiftUICoordinator` - Coordinates SwiftUI navigation
- `AppKitCoordinator` - Coordinates AppKit window management

**Benefits**:
- **Testable** - Mock coordinators for unit tests
- **Flexible** - Swap implementations without changing business logic
- **Decoupled** - UI doesn't directly call DataManager

---

### 3. Business Logic Layer

**Responsibility**: Core application logic and state management

**Key Components**:

**DataManager** (Singleton):
- Lifecycle management (initialization, shutdown)
- Coordination between TaskStore and BoardStore
- Save/reload operations with debouncing
- File watching integration
- First-run setup and sample data generation

**TaskStore** (ObservableObject):
- In-memory task storage
- Filtering and searching
- CRUD operations
- Automatic project/context extraction
- Statistics calculation

**BoardStore** (ObservableObject):
- In-memory board storage
- Auto-creation for projects and contexts
- Visibility management
- Auto-hide inactive boards

**Design Patterns**:
- **Repository Pattern** - Stores abstract data access
- **Observer Pattern** - @Published properties for reactive updates
- **Singleton Pattern** - DataManager as single source of truth

---

### 4. Data Access Layer

**Responsibility**: File system I/O and data persistence

**MarkdownFileIO**:
- Reads/writes Task and Board objects
- Manages directory structure
- Thread-safe operations with serial queue
- Bulk loading for startup
- Error recovery

**YAMLParser**:
- Parses YAML frontmatter into Swift structs
- Generates YAML frontmatter from Swift structs
- Uses Yams library for YAML processing
- Graceful error handling

**FileWatcher**:
- FSEvents wrapper for file monitoring
- Debouncing (200ms) for rapid changes
- Callbacks for create/modify/delete
- Conflict detection

---

## Data Flow

### Write Path: User Creates a Task

```
1. User Input
   └─> QuickCaptureView (⌘⇧Space)
       └─> NaturalLanguageParser.parse("Call John @phone tomorrow")
           └─> Returns: Task(title: "Call John", context: "@phone", due: tomorrow)

2. Coordinator
   └─> SwiftUICoordinator.createTask(from: parsedInput)
       └─> Validates task
       └─> Calls DataManager

3. DataManager
   └─> DataManager.shared.createTask(...)
       └─> Creates Task object with UUID
       └─> Calls TaskStore.add(task)
       └─> Schedules debounced save (500ms)

4. TaskStore
   └─> TaskStore.add(task)
       └─> Appends to tasks array
       └─> Updates @Published tasks property
       └─> Extracts project/context
       └─> Updates @Published projects/contexts arrays

5. UI Update (Automatic)
   └─> SwiftUI observes TaskStore.tasks change
       └─> Re-renders TaskListView
       └─> New task appears in list

6. Persistence (After 500ms)
   └─> DataManager debounced save timer fires
       └─> Calls MarkdownFileIO.writeTask(task)
           └─> YAMLParser.generateTask(task)
           └─> Writes to tasks/active/YYYY/MM/uuid-slug.md
           └─> Creates parent directories if needed

7. File System
   └─> File written to disk
       └─> Available for external editing
       └─> FileWatcher detects new file (ignored, we created it)
```

### Read Path: External Edit

```
1. External Change
   └─> User edits task.md in VS Code
       └─> Saves file

2. File System
   └─> tasks/active/2025/11/uuid-slug.md modified
       └─> FSEvents notification triggered

3. FileWatcher
   └─> Detects modification
       └─> Debounces (200ms wait for more changes)
       └─> Calls onFileModified callback

4. DataManager
   └─> Receives file modified notification
       └─> Checks for conflict with unsaved changes
       └─> If no conflict: reloads task
       └─> If conflict: shows conflict resolution UI

5. MarkdownFileIO
   └─> Reads file from disk
       └─> YAMLParser.parseTask(markdown)
       └─> Returns updated Task object

6. TaskStore
   └─> TaskStore.update(task)
       └─> Replaces task in tasks array
       └─> Updates @Published property

7. UI Update (Automatic)
   └─> SwiftUI observes change
       └─> Re-renders affected views
       └─> User sees updated task
```

### Filter/Search Path

```
1. User Action
   └─> Types in search field: "design @computer"

2. SearchManager
   └─> Debounces input (300ms)
       └─> Parses query: "design" AND context:"@computer"
       └─> Calls TaskStore.search(query)

3. TaskStore
   └─> Filters tasks array
       └─> Checks each task:
           └─> task.matchesSearch("design") AND
           └─> task.context == "@computer"
       └─> Returns matching tasks

4. UI
   └─> Displays filtered results
       └─> Highlights "design" in yellow
       └─> Shows context badge
```

---

## Module Structure

### StickyToDoCore (Shared Framework)

**Purpose**: Shared models, data layer, and utilities

**Structure**:
```
StickyToDoCore/
├── Models/
│   ├── Task.swift
│   ├── Board.swift
│   ├── Perspective.swift
│   ├── Context.swift
│   ├── Filter.swift
│   ├── Priority.swift
│   ├── Status.swift
│   ├── Position.swift
│   ├── Layout.swift
│   ├── BoardType.swift
│   └── TaskType.swift
│
├── Data/
│   ├── DataManager.swift
│   ├── TaskStore.swift
│   ├── BoardStore.swift
│   ├── MarkdownFileIO.swift
│   ├── YAMLParser.swift
│   └── FileWatcher.swift
│
├── Utilities/
│   ├── AppCoordinator.swift
│   ├── ConfigurationManager.swift
│   ├── NaturalLanguageParser.swift
│   └── SearchManager.swift
│
├── AppIntents/
│   ├── SiriShortcuts.swift
│   └── IntentHandlers.swift
│
└── ImportExport/
    ├── ExportManager.swift
    ├── CSVExporter.swift
    ├── JSONExporter.swift
    └── MarkdownExporter.swift
```

**Targets That Use It**:
- StickyToDo (main app)
- StickyToDo-SwiftUI
- StickyToDo-AppKit
- StickyToDoTests

---

### StickyToDo-SwiftUI (Main App)

**Purpose**: SwiftUI-based application implementation

**Structure**:
```
StickyToDo-SwiftUI/
├── StickyToDoApp.swift          # App entry point
├── ContentView.swift             # Main window
│
├── Views/
│   ├── ListView/
│   │   ├── TaskListView.swift
│   │   ├── TaskRowView.swift
│   │   └── PerspectiveSidebarView.swift
│   │
│   ├── BoardView/
│   │   ├── BoardCanvasViewControllerWrapper.swift
│   │   └── BoardCanvasIntegratedView.swift
│   │
│   ├── Inspector/
│   │   ├── TaskInspectorView.swift
│   │   ├── MetadataEditorView.swift
│   │   └── NotesEditorView.swift
│   │
│   ├── QuickCapture/
│   │   ├── QuickCaptureView.swift
│   │   └── QuickCaptureWindow.swift
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── GeneralSettings.swift
│   │   ├── NotificationSettings.swift
│   │   └── KeyboardShortcuts.swift
│   │
│   └── Onboarding/
│       ├── WelcomeView.swift
│       ├── DataDirectoryPicker.swift
│       └── OnboardingTourView.swift
│
├── Utilities/
│   ├── SwiftUICoordinator.swift
│   ├── AppStateInitializer.swift
│   └── KeyboardShortcutManager.swift
│
└── Resources/
    └── Assets.xcassets/
```

---

### StickyToDo-AppKit (Canvas Implementation)

**Purpose**: High-performance AppKit components

**Structure**:
```
StickyToDo-AppKit/
├── BoardCanvas/
│   ├── BoardCanvasViewController.swift
│   ├── CanvasView.swift
│   ├── StickyNoteView.swift
│   └── LassoSelectionOverlay.swift
│
├── Integration/
│   ├── AppKitCoordinator.swift
│   └── DataSourceAdapters.swift
│
└── Resources/
    └── Assets.xcassets/
```

---

## Technology Stack

### Languages & Frameworks

| Technology | Version | Purpose |
|------------|---------|---------|
| **Swift** | 5.9+ | Primary language |
| **SwiftUI** | iOS 17+ | Declarative UI framework |
| **AppKit** | macOS 14+ | High-performance views |
| **Combine** | Built-in | Reactive programming |
| **Foundation** | Built-in | Core utilities |
| **CoreServices** | Built-in | FSEvents file watching |
| **EventKit** | Built-in | Calendar integration |
| **UserNotifications** | Built-in | Local notifications |
| **Intents** | Built-in | Siri Shortcuts |

### Dependencies

| Library | Version | License | Purpose |
|---------|---------|---------|---------|
| **Yams** | 5.0+ | MIT | YAML parsing |

### Build Tools

- **Xcode** 15.0+
- **Swift Package Manager** - Dependency management
- **xcodebuild** - Command-line building and testing

---

## Design Patterns

### 1. Model-View-ViewModel (MVVM)

**Used In**: SwiftUI views

**Example**:
```swift
// Model
struct Task: Identifiable { ... }

// ViewModel
class TaskStore: ObservableObject {
    @Published var tasks: [Task]
}

// View
struct TaskListView: View {
    @ObservedObject var store: TaskStore

    var body: some View {
        List(store.tasks) { task in
            TaskRowView(task: task)
        }
    }
}
```

---

### 2. Repository Pattern

**Used In**: TaskStore, BoardStore

**Purpose**: Abstract data access

```swift
protocol TaskRepository {
    func add(_ task: Task)
    func update(_ task: Task)
    func delete(_ task: Task)
    func task(withId id: UUID) -> Task?
    func tasks(matching filter: Filter) -> [Task]
}

// Implementation
class TaskStore: TaskRepository {
    // Implements all repository methods
}
```

---

### 3. Coordinator Pattern

**Used In**: Navigation and action routing

**Purpose**: Decouple UI from business logic

```swift
protocol AppCoordinator {
    func navigate(to perspective: Perspective)
    func createTask(from input: String)
}

// SwiftUI implementation
class SwiftUICoordinator: AppCoordinator {
    func navigate(to perspective: Perspective) {
        // Update navigation state
    }
}
```

---

### 4. Observer Pattern

**Used In**: Reactive data flow

**Purpose**: Automatic UI updates

```swift
class TaskStore: ObservableObject {
    @Published var tasks: [Task] = []

    func add(_ task: Task) {
        tasks.append(task)
        // SwiftUI views automatically update
    }
}
```

---

### 5. Singleton Pattern

**Used In**: DataManager

**Purpose**: Single source of truth

```swift
class DataManager: ObservableObject {
    static let shared = DataManager()

    private init() { }

    // All app code uses DataManager.shared
}
```

---

### 6. Strategy Pattern

**Used In**: Export functionality

**Purpose**: Pluggable export formats

```swift
protocol ExportStrategy {
    func export(tasks: [Task]) -> Data
}

class JSONExportStrategy: ExportStrategy {
    func export(tasks: [Task]) -> Data { ... }
}

class CSVExportStrategy: ExportStrategy {
    func export(tasks: [Task]) -> Data { ... }
}
```

---

## Storage Architecture

### Directory Structure

```
~/Documents/StickyToDo/              # Root data directory
│
├── tasks/                            # Task storage
│   ├── active/                       # Active tasks
│   │   └── YYYY/                     # Year
│   │       └── MM/                   # Month
│   │           ├── uuid-task-slug.md
│   │           ├── uuid-another-task.md
│   │           └── ...
│   │
│   └── archive/                      # Completed/archived tasks
│       └── YYYY/
│           └── MM/
│               └── uuid-archived-task.md
│
├── boards/                           # Board definitions
│   ├── inbox.md                      # Built-in boards
│   ├── next-actions.md
│   ├── project-website.md            # Auto-created project board
│   ├── context-phone.md              # Auto-created context board
│   └── custom-board.md               # User-created boards
│
├── config/                           # Configuration files
│   ├── contexts.yaml                 # Context definitions
│   ├── perspectives.yaml             # Custom perspectives
│   ├── templates.yaml                # Task templates
│   ├── automation-rules.yaml         # Automation rules
│   └── settings.yaml                 # App settings
│
└── attachments/                      # File attachments
    └── task-uuid/
        ├── attachment1.pdf
        ├── screenshot.png
        └── ...
```

### File Format

**Task File** (`uuid-task-slug.md`):
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
tags: ["urgent", "client"]
positions:
  brainstorm-board: {x: 150.0, y: 200.0}
created: 2025-11-17T10:30:00Z
modified: 2025-11-18T09:15:00Z
---

Discuss Q4 proposal and timeline.

## Key Points
- Budget requirements
- Timeline expectations
- Resource allocation
```

**Board File** (`project-website.md`):
```markdown
---
id: "project-website"
type: project
displayTitle: "Website Redesign"
layout: kanban
filter:
  project: ["Website Redesign"]
columns: ["To Do", "In Progress", "Review", "Done"]
autoHide: false
isBuiltIn: false
isVisible: true
order: 10
created: 2025-11-17T10:00:00Z
modified: 2025-11-17T10:00:00Z
---

# Website Redesign

Project board for tracking all website redesign tasks.
```

---

## Performance Architecture

### Startup Performance

**Target**: < 2 seconds with 500 tasks

**Strategy**:
1. **Parallel Loading**: Load tasks and boards concurrently
2. **Lazy Initialization**: Only load what's needed for first screen
3. **Background Indexing**: Index projects/contexts/tags in background
4. **Incremental Rendering**: SwiftUI lists render on-demand

**Implementation**:
```swift
func initialize(rootDirectory: URL) async throws {
    // Load in parallel
    async let tasks = loadAllTasks()
    async let boards = loadAllBoards()

    let (loadedTasks, loadedBoards) = try await (tasks, boards)

    // Update stores
    taskStore.tasks = loadedTasks
    boardStore.boards = loadedBoards

    // Background indexing
    Task {
        await indexProjects()
        await indexContexts()
        await indexTags()
    }
}
```

---

### Runtime Performance

**Canvas Rendering**: 60 FPS with 100+ tasks

**Strategy**:
- **AppKit Core Animation**: Hardware-accelerated rendering
- **Viewport Culling**: Only render visible tasks
- **Cached Layers**: Reuse CALayers for unchanged tasks
- **Batch Updates**: Coalesce multiple changes

**Memory Management**:
- Weak references to avoid retain cycles
- Lazy loading of attachments
- Automatic image downsampling
- Periodic memory cleanup

---

### Persistence Performance

**Debounced Writes**: 500ms delay

**Strategy**:
```swift
class DataManager {
    private var saveTimer: Timer?

    func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task {
                await self.save()
            }
        }
    }

    func save() async throws {
        // Batch writes
        try await markdownFileIO.writeAllTasks(taskStore.tasks)
        try await markdownFileIO.writeAllBoards(boardStore.boards)
    }
}
```

**Benefits**:
- Reduces disk I/O by 95% for rapid edits
- Prevents file system thrashing
- Improves responsiveness
- Still safe (force flush before quit)

---

## Security Architecture

### Data Privacy

**All Local**: No cloud services, all data stays on device

**Permissions**:
- **Files and Folders**: Read/write access to data directory (required)
- **Notifications**: Local notifications (optional)
- **Calendar**: EventKit for calendar sync (optional)
- **Contacts**: Not used
- **Location**: Not used
- **Camera**: Not used

### Code Signing & Notarization

**Developer ID**: Signed with Apple Developer ID
**Hardened Runtime**: Enabled for security
**Notarization**: Submitted to Apple for malware scan
**Gatekeeper**: Passes macOS security checks

### Data Integrity

**Validation**:
- UUID uniqueness checks
- YAML schema validation
- File corruption detection
- Graceful error recovery

**Backups**:
- User controls backup strategy (Time Machine, etc.)
- Export functionality for manual backups
- Version control support (git)

---

## Scalability Considerations

### Current Limits (v1.0)

- **Recommended**: 500-1,000 active tasks
- **Canvas**: 200 visible tasks per board
- **Search**: 500 results maximum

### Future Scalability (v2.0)

**SQLite Migration** (for 10,000+ tasks):
```
Phase 1: Dual Mode
- Keep markdown files
- Add SQLite for indexing/search
- Sync between formats

Phase 2: SQLite Primary
- SQLite as source of truth
- Export to markdown on demand
- Maintain compatibility
```

---

## Conclusion

StickyToDo's architecture balances **simplicity** with **power**, using proven patterns and technologies to deliver a fast, reliable, and maintainable application. The hybrid SwiftUI/AppKit approach provides the best of both worlds: modern declarative UI with high-performance rendering where it matters.

The plain-text storage ensures user data ownership and future-proofing, while the reactive data layer provides instant responsiveness. This architecture is designed to scale from dozens to thousands of tasks while maintaining sub-second performance.

---

**Version**: 1.0.0
**Last Updated**: 2025-11-18
**Author**: StickyToDo Development Team
