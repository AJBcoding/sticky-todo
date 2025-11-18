# StickyToDo Data Layer

Complete shared data layer implementation for StickyToDo, compatible with both AppKit and SwiftUI.

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  DataManager                        │
│  (Coordinator & Single Point of Access)            │
└────────┬─────────────────────────────┬──────────────┘
         │                             │
    ┌────▼────────┐              ┌─────▼──────────┐
    │  TaskStore  │              │  BoardStore    │
    │  (In-memory)│              │  (In-memory)   │
    └────┬────────┘              └─────┬──────────┘
         │                             │
         └──────────┬──────────────────┘
                    │
            ┌───────▼────────┐
            │ MarkdownFileIO │
            │  (Persistence) │
            └───────┬────────┘
                    │
            ┌───────▼────────┐
            │  YAMLParser    │
            │  (Yams lib)    │
            └────────────────┘

         ┌──────────────────┐
         │   FileWatcher    │
         │  (FSEvents)      │
         └──────────────────┘
```

## Components

### 1. YAMLParser.swift
**Purpose:** Parse and generate YAML frontmatter in markdown files.

**Key Features:**
- Uses Yams library for YAML parsing
- Graceful error handling for malformed YAML
- Strict and lenient parsing modes
- Type-safe Codable support

**Methods:**
```swift
// Parse frontmatter from markdown
parseFrontmatter<T: Decodable>(_ markdown: String) -> (frontmatter: T?, body: String)

// Generate markdown with frontmatter
generateFrontmatter<T: Encodable>(_ object: T, body: String) throws -> String
```

**Usage:**
```swift
let markdown = try YAMLParser.generateTask(task, body: task.notes)
let (task, body) = YAMLParser.parseTask(markdown)
```

### 2. MarkdownFileIO.swift
**Purpose:** Read and write markdown files to the file system.

**Key Features:**
- Automatic directory structure creation
- Thread-safe file operations
- Bulk loading operations
- Error recovery for corrupted files

**Methods:**
```swift
// Read/write tasks
readTask(from: URL) throws -> Task?
writeTask(_ task: Task, to: URL?) throws

// Read/write boards
readBoard(from: URL) throws -> Board?
writeBoard(_ board: Board, to: URL?) throws

// Bulk operations
loadAllTasks() throws -> [Task]
loadAllBoards() throws -> [Board]
```

**File Structure Created:**
```
project-root/
  tasks/
    active/
      YYYY/
        MM/
          uuid-slug.md
    archive/
      YYYY/
        MM/
          uuid-slug.md
  boards/
    board-id.md
  config/
    contexts.md
    settings.md
```

### 3. TaskStore.swift
**Purpose:** In-memory store for all tasks with reactive updates.

**Key Features:**
- `@Published` properties for SwiftUI/Combine
- Debounced auto-save (500ms)
- Thread-safe operations via serial queue
- Filtering and searching
- Batch operations
- Statistics

**Properties:**
```swift
@Published private(set) var tasks: [Task]
@Published private(set) var projects: [String]
@Published private(set) var contexts: [String]
```

**Methods:**
```swift
// CRUD
add(_ task: Task)
update(_ task: Task)
delete(_ task: Task)
save(_ task: Task)  // Debounced
saveImmediately(_ task: Task) throws

// Filtering
tasks(matching filter: Filter) -> [Task]
tasks(for board: Board) -> [Task]
tasks(matchingSearch query: String) -> [Task]

// Statistics
var taskCount: Int
var activeTaskCount: Int
var inboxTaskCount: Int
```

**Usage with SwiftUI:**
```swift
@ObservedObject var taskStore: TaskStore

var body: some View {
    List(taskStore.tasks) { task in
        Text(task.title)
    }
}
```

### 4. BoardStore.swift
**Purpose:** In-memory store for all boards.

**Key Features:**
- Built-in board management
- Dynamic board creation for contexts/projects
- Auto-hide inactive project boards
- Visibility management
- Board ordering

**Methods:**
```swift
// CRUD
add(_ board: Board)
update(_ board: Board)
delete(_ board: Board)

// Dynamic creation
getOrCreateContextBoard(for context: Context) -> Board
getOrCreateProjectBoard(for projectName: String) -> Board

// Visibility
hide(_ board: Board)
show(_ board: Board)
updateAutoHideStatus(taskStore: TaskStore)

// Organization
reorder(_ boardIDs: [String])
```

**Properties:**
```swift
@Published private(set) var boards: [Board]
@Published private(set) var visibleBoards: [Board]
```

### 5. FileWatcher.swift
**Purpose:** Monitor file system for external changes using FSEvents.

**Key Features:**
- Monitors directory tree recursively
- Debounces rapid changes (200ms)
- File type filtering (.md only)
- Conflict detection
- Thread-safe callbacks

**Setup:**
```swift
let watcher = FileWatcher()
watcher.onFileCreated = { url in
    // Handle new file
}
watcher.onFileModified = { url in
    // Handle modified file
}
watcher.onFileDeleted = { url in
    // Handle deleted file
}
watcher.startWatching(directory: dataDirectory)
```

**Conflict Detection:**
```swift
if let conflict = watcher.checkForConflict(
    url: fileURL,
    ourModificationDate: task.modified
) {
    if conflict.hasConflict {
        // Show conflict resolution UI
    }
}
```

### 6. DataManager.swift
**Purpose:** Central coordinator for all data operations.

**Key Features:**
- Single point of access
- Manages TaskStore, BoardStore, FileIO, and FileWatcher
- Handles app lifecycle (init, save on quit)
- Conflict resolution
- First-run setup
- Statistics

**Initialization:**
```swift
// Async initialization
let dataManager = DataManager.shared
try await dataManager.initialize(rootDirectory: dataDirectory)

// Sync initialization
try dataManager.initialize(rootDirectory: dataDirectory)
```

**Access Stores:**
```swift
let tasks = dataManager.taskStore.tasks
let boards = dataManager.boardStore.boards
```

**Convenience Methods:**
```swift
// Create/update/delete
dataManager.createTask(title: "New task")
dataManager.updateTask(task)
dataManager.deleteTask(task)

// App lifecycle
try dataManager.saveBeforeQuit()
dataManager.cleanup()

// Statistics
let stats = dataManager.statistics
print(stats.description)
```

**Conflict Handling:**
```swift
dataManager.onConflictDetected = { conflict in
    // Show conflict resolution UI
    showConflictAlert(conflict)
}

// User chooses disk version
dataManager.resolveConflictWithDiskVersion(conflict)

// User chooses our version
dataManager.resolveConflictWithOurVersion(conflict)
```

## Setup Instructions

### 1. Add Yams Package Dependency

**In Xcode:**
1. Open the project in Xcode
2. Select the project in the navigator
3. Go to the "Package Dependencies" tab
4. Click the "+" button
5. Enter the repository URL: `https://github.com/jpsim/Yams.git`
6. Select version: Up to Next Major (6.0.0 or later)
7. Click "Add Package"
8. Select the "Yams" product for your target

**Or add to Package.swift (if using SPM):**
```swift
dependencies: [
    .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
],
targets: [
    .target(
        name: "StickyToDo",
        dependencies: ["Yams"]
    )
]
```

### 2. Import in Files

The data layer files already have `import Yams` at the top of YAMLParser.swift. Ensure Yams is properly linked to your target.

### 3. Add Files to Xcode Project

Add all the Data layer files to your Xcode project:
- YAMLParser.swift
- MarkdownFileIO.swift
- TaskStore.swift
- BoardStore.swift
- FileWatcher.swift
- DataManager.swift

Make sure they're added to your app target.

## Usage Examples

### Basic Setup (SwiftUI App)

```swift
import SwiftUI

@main
struct StickyToDoApp: App {
    @StateObject private var dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager.taskStore)
                .environmentObject(dataManager.boardStore)
                .task {
                    do {
                        let documentsURL = FileManager.default.urls(
                            for: .documentDirectory,
                            in: .userDomainMask
                        ).first!
                        let dataURL = documentsURL.appendingPathComponent("StickyToDo")

                        try await dataManager.initialize(rootDirectory: dataURL)
                        dataManager.performFirstRunSetup(createSampleData: true)
                    } catch {
                        print("Failed to initialize: \(error)")
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Save All") {
                    try? dataManager.saveBeforeQuit()
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
        }
    }
}
```

### Basic Setup (AppKit App)

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    let dataManager = DataManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let dataURL = documentsURL.appendingPathComponent("StickyToDo")

        do {
            try dataManager.initialize(rootDirectory: dataURL)
            dataManager.performFirstRunSetup(createSampleData: true)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        do {
            try dataManager.saveBeforeQuit()
            dataManager.cleanup()
            return .terminateNow
        } catch {
            NSAlert(error: error).runModal()
            return .terminateCancel
        }
    }
}
```

### Working with Tasks

```swift
// Create a task
let task = dataManager.createTask(
    title: "Call John",
    notes: "Discuss project timeline",
    status: .inbox
)

// Update task metadata
var updatedTask = task
updatedTask.context = "@phone"
updatedTask.priority = .high
updatedTask.due = Date().addingTimeInterval(86400) // Tomorrow
dataManager.updateTask(updatedTask)

// Filter tasks
let inboxTasks = dataManager.taskStore.tasks(withStatus: .inbox)
let phoneTasks = dataManager.taskStore.tasks(forContext: "@phone")
let overdueTasks = dataManager.taskStore.overdueTasks()

// Search tasks
let results = dataManager.taskStore.tasks(matchingSearch: "project")

// Batch update
let selectedTasks = [task1, task2, task3]
let updatedTasks = selectedTasks.map { task in
    var updated = task
    updated.project = "Website Redesign"
    return updated
}
dataManager.taskStore.updateBatch(updatedTasks)
```

### Working with Boards

```swift
// Get built-in boards
let inboxBoard = dataManager.boardStore.board(withID: "inbox")

// Create a custom board
let customBoard = dataManager.createBoard(
    id: "this-week",
    type: .custom,
    layout: .grid,
    filter: Filter(flagged: true)
)

// Get or create dynamic boards
let computerBoard = dataManager.boardStore.getOrCreateContextBoard(
    for: Context(name: "@computer", icon: "💻", color: "blue")
)

let projectBoard = dataManager.boardStore.getOrCreateProjectBoard(
    for: "Website Redesign"
)

// Get tasks for a board
let boardTasks = dataManager.taskStore.tasks(for: inboxBoard)

// Update board visibility
dataManager.boardStore.hide(customBoard)
dataManager.boardStore.show(customBoard)

// Auto-hide inactive project boards
dataManager.boardStore.updateAutoHideStatus(taskStore: dataManager.taskStore)
```

## Thread Safety

All stores use serial dispatch queues for thread-safe access:
- TaskStore: `com.stickytodo.taskstore`
- BoardStore: `com.stickytodo.boardstore`
- FileWatcher: `com.stickytodo.filewatcher`

All published properties update on the main thread, making them safe for UI binding.

## Performance Characteristics

**Phase 1 (In-Memory):**
- Launch: < 2 seconds with 500 tasks
- Task creation: Instant (async write)
- Search: < 200ms with 500 tasks
- Auto-save debounce: 500ms

**File Watcher:**
- Event debounce: 200ms
- Only monitors .md files
- Minimal CPU impact

## Error Handling

All components use comprehensive error handling:

```swift
do {
    try dataManager.saveBeforeQuit()
} catch DataManagerError.notInitialized {
    // Handle not initialized
} catch DataManagerError.savingFailed(let error) {
    // Handle save failure
} catch {
    // Handle other errors
}
```

## Logging

Enable logging for debugging:

```swift
dataManager.enableLogging = true
dataManager.setLogger { message in
    print(message)
    // Or write to a log file
}
```

## Testing

The data layer is designed to be testable:

```swift
// Create a test data manager with a temporary directory
let tempURL = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString)
let testDataManager = DataManager()
try testDataManager.initialize(rootDirectory: tempURL)

// Disable file watching for faster tests
testDataManager.enableFileWatching = false

// Run tests
let task = testDataManager.createTask(title: "Test task")
XCTAssertEqual(testDataManager.taskStore.taskCount, 1)

// Cleanup
try FileManager.default.removeItem(at: tempURL)
```

## Migration Path

The in-memory approach is designed for Phase 1 (up to ~1000 tasks).

**Phase 2 Migration to SQLite:**
1. Keep the same public API (DataManager, TaskStore, BoardStore)
2. Replace MarkdownFileIO with SQLite storage
3. Markdown files become the export/import format
4. File watching for sync rather than primary storage

The abstraction layers allow this migration without changing app code.

## File Format Examples

### Task File (tasks/active/2025/11/uuid-call-john.md)

```markdown
---
id: "123e4567-e89b-12d3-a456-426614174000"
type: task
title: "Call John about proposal"
status: next-action
project: "Website Redesign"
context: "@phone"
due: 2025-11-20T14:00:00Z
flagged: true
priority: high
effort: 30
positions:
  this-week: {x: 150, y: 200}
created: 2025-11-17T10:30:00Z
modified: 2025-11-18T09:15:00Z
---

Discuss the timeline for the website redesign project.

Key points to cover:
- Budget approval
- Team resources
- Launch date
```

### Board File (boards/this-week.md)

```markdown
---
id: "this-week"
type: custom
layout: grid
filter:
  flagged: true
autoHide: false
hideAfterDays: 7
title: "This Week"
icon: "⭐"
color: "yellow"
isBuiltIn: false
isVisible: true
order: 10
---

# This Week

Tasks flagged for completion this week.
High-priority and time-sensitive items.
```

## Next Steps

1. Add Yams package dependency in Xcode
2. Add all Data layer files to your target
3. Initialize DataManager in your app delegate
4. Create your first task and board
5. Test file watching by editing markdown files externally
6. Implement conflict resolution UI

## Support

For issues or questions about the data layer:
1. Check error logs (enable logging)
2. Verify Yams is properly linked
3. Ensure directory structure was created
4. Check file permissions

---

**Implementation Complete:** All six data layer components are ready for use with both AppKit and SwiftUI.
