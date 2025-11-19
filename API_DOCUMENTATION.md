# StickyToDo API Documentation

**Version**: 1.0.0
**Last Updated**: 2025-11-18

---

## Overview

This document provides comprehensive API documentation for StickyToDoCore, the shared framework containing all core models, data layer, and utilities used by both AppKit and SwiftUI implementations.

### Target Audience

- Developers extending StickyToDo
- Plugin creators (future)
- Contributors to the project
- Anyone integrating with StickyToDo's data layer

### Module Structure

```
StickyToDoCore/
├── Models/           # Core data models
├── Data/             # Data layer and persistence
├── Utilities/        # Shared utilities and helpers
├── AppIntents/       # Siri Shortcuts integration
└── ImportExport/     # Import/export functionality
```

---

## Core Models

All models are located in `StickyToDoCore/Models/` and conform to `Codable` for YAML serialization.

### Task

The central model representing a task or note in the system.

```swift
public struct Task: Identifiable, Codable, Equatable, Hashable {
    // MARK: - Core Properties

    public let id: UUID
    public var type: TaskType  // .task or .note
    public var title: String
    public var notes: String

    // MARK: - GTD Metadata

    public var status: Status
    public var project: String?
    public var context: String?
    public var priority: Priority
    public var due: Date?
    public var defer: Date?
    public var flagged: Bool
    public var effort: Int?  // Minutes

    // MARK: - Advanced Features

    public var tags: [String]
    public var parentTaskId: UUID?
    public var subtasks: [UUID]
    public var recurrence: Recurrence?
    public var timeTracking: [TimeEntry]
    public var attachments: [Attachment]

    // MARK: - Board Positioning

    public var positions: [String: Position]

    // MARK: - Timestamps

    public var created: Date
    public var modified: Date
    public var completed: Date?
}
```

#### Initialization

```swift
// Create a new task
let task = Task(
    title: "My Task",
    status: .inbox,
    project: "Work",
    context: "@office",
    priority: .high,
    due: Date().addingTimeInterval(86400)  // Tomorrow
)

// Create a lightweight note
let note = Task(
    title: "Quick Idea",
    type: .note
)
```

#### Key Methods

```swift
// Filter Matching
func matches(_ filter: Filter) -> Bool

// Search Matching
func matchesSearch(_ query: String) -> Bool

// Status Operations
mutating func complete()
mutating func reopen()
mutating func archive()

// Type Conversion
mutating func promoteToTask()
mutating func demoteToNote()

// Board Positioning
mutating func setPosition(_ position: Position, for boardId: String)
func position(for boardId: String) -> Position?

// Subtask Operations
mutating func addSubtask(_ taskId: UUID)
mutating func removeSubtask(_ taskId: UUID)
func isSubtask(of parentId: UUID) -> Bool

// Time Tracking
mutating func addTimeEntry(_ entry: TimeEntry)
func totalTimeSpent() -> TimeInterval

// Validation
func validate() throws
var isOverdue: Bool { get }
var isDeferred: Bool { get }
var isActive: Bool { get }
```

#### Usage Examples

```swift
// Create and configure a task
var task = Task(title: "Review PR #123")
task.status = .nextAction
task.project = "Development"
task.context = "@computer"
task.priority = .high
task.due = Calendar.current.date(byAdding: .day, value: 3, to: Date())
task.effort = 60  // 1 hour
task.tags = ["code-review", "urgent"]
task.flagged = true

// Complete a task
task.complete()
print(task.status)  // .completed
print(task.completed)  // Date of completion

// Add to board
task.setPosition(Position(x: 100, y: 200), for: "brainstorm-board")

// Check if overdue
if task.isOverdue {
    print("Task is overdue!")
}

// Filter matching
let filter = Filter(status: [.nextAction], project: ["Development"])
if task.matches(filter) {
    print("Task matches filter")
}
```

---

### Board

Represents a visual board with filtering and layout configuration.

```swift
public struct Board: Identifiable, Codable, Equatable, Hashable {
    // MARK: - Core Properties

    public let id: String
    public var type: BoardType
    public var displayTitle: String
    public var layout: Layout

    // MARK: - Filtering

    public var filter: Filter

    // MARK: - Kanban Configuration

    public var columns: [String]?  // For kanban layout

    // MARK: - Visibility

    public var autoHide: Bool
    public var hideAfterDays: Int
    public var isBuiltIn: Bool
    public var isVisible: Bool
    public var order: Int

    // MARK: - Content

    public var notes: String?

    // MARK: - Timestamps

    public var created: Date
    public var modified: Date
    public var lastAccessed: Date?
}
```

#### Initialization

```swift
// Create a custom board
let board = Board(
    id: "my-board",
    type: .custom,
    displayTitle: "This Week",
    layout: .freeform,
    filter: Filter(flagged: true)
)

// Create a project board
let projectBoard = Board.projectBoard(
    for: "Website Redesign",
    layout: .kanban,
    columns: ["To Do", "In Progress", "Review", "Done"]
)

// Create a context board
let contextBoard = Board.contextBoard(for: "@phone")
```

#### Key Methods

```swift
// Metadata Updates
func metadataUpdates(forColumn column: String) -> [String: Any]

// Auto-Hide Logic
func shouldAutoHide(lastAccessDate: Date?) -> Bool

// Visibility
mutating func show()
mutating func hide()
mutating func markAccessed()

// Board Creation Helpers
static func projectBoard(for project: String, layout: Layout, columns: [String]?) -> Board
static func contextBoard(for context: String) -> Board
static func inboxBoard() -> Board
static func nextActionsBoard() -> Board
```

#### Usage Examples

```swift
// Create a custom freeform board for brainstorming
var board = Board(
    id: "brainstorm-2025",
    type: .custom,
    displayTitle: "2025 Planning",
    layout: .freeform,
    filter: Filter(project: ["Strategic Planning"])
)
board.autoHide = true
board.hideAfterDays = 14

// Create a kanban workflow board
var kanban = Board(
    id: "dev-workflow",
    type: .custom,
    displayTitle: "Development Pipeline",
    layout: .kanban,
    filter: Filter(project: ["App Development"])
)
kanban.columns = ["Backlog", "In Progress", "Code Review", "Testing", "Done"]

// Get metadata updates for moving a task to a column
let updates = kanban.metadataUpdates(forColumn: "In Progress")
// Returns: ["status": Status.nextAction]

// Check if board should auto-hide
if board.shouldAutoHide(lastAccessDate: board.lastAccessed) {
    board.hide()
}
```

---

### Perspective

Represents a filtered view of tasks (list mode).

```swift
public struct Perspective: Identifiable, Codable, Equatable, Hashable {
    // MARK: - Core Properties

    public let id: String
    public var name: String
    public var icon: String?  // SF Symbol name

    // MARK: - Filtering & Sorting

    public var filter: Filter
    public var groupBy: GroupBy
    public var sortBy: SortBy
    public var sortDirection: SortDirection

    // MARK: - Configuration

    public var isBuiltIn: Bool
    public var isVisible: Bool
    public var order: Int

    // MARK: - Timestamps

    public var created: Date
    public var modified: Date
}
```

#### Built-In Perspectives

```swift
// Seven built-in perspectives
public static let inbox: Perspective
public static let nextActions: Perspective
public static let flagged: Perspective
public static let dueSoon: Perspective
public static let waitingFor: Perspective
public static let somedayMaybe: Perspective
public static let allActive: Perspective

// Access all built-ins
public static var builtInPerspectives: [Perspective]
```

#### Key Methods

```swift
// Apply Perspective to Tasks
func apply(to tasks: [Task]) -> [Task]

// Group Tasks
func group(_ tasks: [Task]) -> [(String, [Task])]

// Create Custom Perspective
static func custom(
    id: String,
    name: String,
    filter: Filter,
    groupBy: GroupBy,
    sortBy: SortBy
) -> Perspective
```

#### Usage Examples

```swift
// Use built-in perspective
let inbox = Perspective.inbox
let inboxTasks = inbox.apply(to: allTasks)

// Create custom perspective for urgent items
let urgent = Perspective.custom(
    id: "urgent-items",
    name: "Urgent",
    filter: Filter(
        priority: [.high],
        status: [.nextAction],
        flagged: true
    ),
    groupBy: .project,
    sortBy: .dueDate
)

// Apply and group
let urgentTasks = urgent.apply(to: allTasks)
let grouped = urgent.group(urgentTasks)
for (groupName, tasks) in grouped {
    print("\(groupName): \(tasks.count) tasks")
}
```

---

### Filter

Powerful filtering system with AND/OR logic.

```swift
public struct Filter: Codable, Equatable {
    // MARK: - Basic Filters

    public var status: [Status]?
    public var project: [String]?
    public var context: [String]?
    public var priority: [Priority]?
    public var flagged: Bool?
    public var tags: [String]?

    // MARK: - Date Filters

    public var dueBefore: Date?
    public var dueAfter: Date?
    public var dueToday: Bool?
    public var dueThisWeek: Bool?
    public var overdue: Bool?

    public var deferBefore: Date?
    public var deferAfter: Date?

    public var completedAfter: Date?
    public var completedBefore: Date?

    // MARK: - Type Filters

    public var type: TaskType?
    public var hasSubtasks: Bool?
    public var isSubtask: Bool?
    public var hasRecurrence: Bool?

    // MARK: - Logic

    public var matchAll: Bool  // true = AND, false = OR
    public var subFilters: [Filter]?
}
```

#### Initialization

```swift
// Simple filter
let filter = Filter(
    status: [.nextAction],
    project: ["Website"]
)

// Complex filter with multiple criteria
let complexFilter = Filter(
    status: [.nextAction, .waiting],
    priority: [.high, .medium],
    flagged: true,
    dueThisWeek: true,
    matchAll: true  // AND logic
)

// Nested filters (OR of ANDs)
let nestedFilter = Filter(
    subFilters: [
        Filter(status: [.nextAction], priority: [.high], matchAll: true),
        Filter(flagged: true, dueToday: true, matchAll: true)
    ],
    matchAll: false  // OR between subfilters
)
```

#### Key Methods

```swift
// Evaluate a task against filter
func matches(_ task: Task) -> Bool

// Combine filters
func and(_ other: Filter) -> Filter
func or(_ other: Filter) -> Filter

// Check if filter is empty
var isEmpty: Bool { get }
```

#### Usage Examples

```swift
// Filter for high-priority next actions
let filter = Filter(
    status: [.nextAction],
    priority: [.high]
)

let tasks = allTasks.filter { filter.matches($0) }

// Complex query: (High priority OR flagged) AND due this week
let complexQuery = Filter(
    subFilters: [
        Filter(priority: [.high]),
        Filter(flagged: true)
    ],
    matchAll: false  // OR
).and(Filter(dueThisWeek: true))

// Filter for overdue phone calls
let overduePhoneCalls = Filter(
    context: ["@phone"],
    overdue: true,
    status: [.nextAction]
)
```

---

### Enumerations

#### Status

```swift
public enum Status: String, Codable, CaseIterable {
    case inbox
    case nextAction
    case waiting
    case someday
    case completed

    var displayName: String { get }
    var color: NSColor { get }
    var icon: String { get }  // SF Symbol
}
```

#### Priority

```swift
public enum Priority: String, Codable, CaseIterable {
    case high
    case medium
    case low

    var displayName: String { get }
    var color: NSColor { get }
    var sortOrder: Int { get }
}
```

#### TaskType

```swift
public enum TaskType: String, Codable {
    case task
    case note

    var displayName: String { get }
}
```

#### Layout

```swift
public enum Layout: String, Codable, CaseIterable {
    case freeform
    case kanban
    case grid

    var displayName: String { get }
    var icon: String { get }  // SF Symbol
}
```

#### BoardType

```swift
public enum BoardType: String, Codable {
    case inbox
    case nextAction
    case project
    case context
    case custom

    var displayName: String { get }
}
```

---

## Data Layer

All data layer classes are located in `StickyToDoCore/Data/`.

### DataManager

Central coordinator for all data operations.

```swift
public final class DataManager: ObservableObject {
    // MARK: - Singleton

    public static let shared = DataManager()

    // MARK: - Published State

    @Published public private(set) var isInitialized: Bool
    @Published public private(set) var isLoading: Bool
    @Published public private(set) var error: Error?

    // MARK: - Stores

    public private(set) var taskStore: TaskStore!
    public private(set) var boardStore: BoardStore!

    // MARK: - Configuration

    public var rootDirectory: URL?
    public var autoSaveInterval: TimeInterval  // Default: 0.5 seconds

    // MARK: - Initialization

    public func initialize(rootDirectory: URL) async throws
    public func shutdown() async

    // MARK: - Task Operations

    public func createTask(
        title: String,
        type: TaskType,
        status: Status,
        project: String?,
        context: String?,
        priority: Priority,
        due: Date?,
        defer: Date?
    ) -> Task

    public func updateTask(_ task: Task)
    public func deleteTask(_ task: Task)
    public func archiveTask(_ task: Task)
    public func restoreTask(_ task: Task)

    // MARK: - Board Operations

    public func createBoard(
        id: String,
        type: BoardType,
        title: String,
        layout: Layout,
        filter: Filter
    ) -> Board

    public func updateBoard(_ board: Board)
    public func deleteBoard(_ board: Board)

    // MARK: - Batch Operations

    public func batchUpdate(tasks: [Task])
    public func batchDelete(tasks: [Task])

    // MARK: - Save & Reload

    public func save() async throws
    public func reload() async throws
}
```

#### Usage Examples

```swift
// Initialize DataManager
let manager = DataManager.shared
try await manager.initialize(rootDirectory: URL(fileURLWithPath: "/path/to/data"))

// Create a task
let task = manager.createTask(
    title: "Review designs",
    type: .task,
    status: .nextAction,
    project: "Website",
    context: "@computer",
    priority: .high,
    due: Date().addingTimeInterval(86400),
    defer: nil
)

// Update a task
var updatedTask = task
updatedTask.title = "Review and approve designs"
manager.updateTask(updatedTask)

// Delete a task
manager.deleteTask(task)

// Create a board
let board = manager.createBoard(
    id: "dev-board",
    type: .custom,
    title: "Development",
    layout: .kanban,
    filter: Filter(project: ["App"])
)

// Save manually (auto-save happens automatically)
try await manager.save()
```

---

### TaskStore

In-memory task storage with reactive updates.

```swift
public final class TaskStore: ObservableObject {
    // MARK: - Published State

    @Published public private(set) var tasks: [Task]
    @Published public private(set) var projects: [String]
    @Published public private(set) var contexts: [String]
    @Published public private(set) var tags: [String]

    // MARK: - Statistics

    public var taskCount: Int { get }
    public var activeTaskCount: Int { get }
    public var completedTaskCount: Int { get }
    public var overdueTaskCount: Int { get }

    // MARK: - CRUD Operations

    public func add(_ task: Task)
    public func update(_ task: Task)
    public func delete(_ task: Task)
    public func task(withId id: UUID) -> Task?

    // MARK: - Filtering

    public func tasks(matching filter: Filter) -> [Task]
    public func tasks(in project: String) -> [Task]
    public func tasks(with context: String) -> [Task]
    public func tasks(with status: Status) -> [Task]

    // MARK: - Searching

    public func search(_ query: String) -> [Task]

    // MARK: - Batch Operations

    public func batchUpdate(_ tasks: [Task])
    public func batchDelete(_ tasks: [Task])

    // MARK: - Loading

    public func loadAll(from directory: URL) throws
    public func reload() throws
}
```

#### Usage Examples

```swift
let store = DataManager.shared.taskStore

// Filter tasks
let nextActions = store.tasks(with: .nextAction)
let phoneTasks = store.tasks(with: "@phone")
let websiteTasks = store.tasks(in: "Website")

// Complex filtering
let filter = Filter(status: [.nextAction], priority: [.high])
let highPriorityTasks = store.tasks(matching: filter)

// Search
let results = store.search("design review")

// Get statistics
print("Total tasks: \(store.taskCount)")
print("Active: \(store.activeTaskCount)")
print("Overdue: \(store.overdueTaskCount)")

// Batch operations
let tasksToComplete = store.tasks(in: "Completed Project")
var completed = tasksToComplete.map { task in
    var t = task
    t.complete()
    return t
}
store.batchUpdate(completed)
```

---

### BoardStore

In-memory board storage with auto-creation logic.

```swift
public final class BoardStore: ObservableObject {
    // MARK: - Published State

    @Published public private(set) var boards: [Board]
    @Published public private(set) var visibleBoards: [Board]

    // MARK: - CRUD Operations

    public func add(_ board: Board)
    public func update(_ board: Board)
    public func delete(_ board: Board)
    public func board(withId id: String) -> Board?

    // MARK: - Auto-Creation

    public func getOrCreateProjectBoard(for project: String) -> Board
    public func getOrCreateContextBoard(for context: String) -> Board

    // MARK: - Visibility

    public func show(_ board: Board)
    public func hide(_ board: Board)
    public func updateAutoHide()

    // MARK: - Ordering

    public func reorder(_ boards: [Board])

    // MARK: - Loading

    public func loadAll(from directory: URL) throws
}
```

#### Usage Examples

```swift
let store = DataManager.shared.boardStore

// Get or create project board
let projectBoard = store.getOrCreateProjectBoard(for: "Website Redesign")

// Get or create context board
let phoneBoard = store.getOrCreateContextBoard(for: "@phone")

// Update visibility
store.show(projectBoard)
store.hide(phoneBoard)

// Reorder boards
let reordered = store.visibleBoards.sorted { $0.displayTitle < $1.displayTitle }
store.reorder(reordered)

// Update auto-hide (hides inactive boards)
store.updateAutoHide()
```

---

### MarkdownFileIO

File system I/O operations for tasks and boards.

```swift
public final class MarkdownFileIO {
    // MARK: - Initialization

    public init(rootDirectory: URL)

    // MARK: - Directory Structure

    public func ensureDirectoryStructure() throws

    // MARK: - Task I/O

    public func readTask(from url: URL) throws -> Task?
    public func writeTask(_ task: Task) throws -> URL
    public func loadAllTasks() throws -> [Task]
    public func deleteTask(_ task: Task) throws
    public func archiveTask(_ task: Task) throws
    public func restoreTask(_ task: Task) throws

    // MARK: - Board I/O

    public func readBoard(from url: URL) throws -> Board?
    public func writeBoard(_ board: Board) throws -> URL
    public func loadAllBoards() throws -> [Board]
    public func deleteBoard(_ board: Board) throws

    // MARK: - URL Generation

    public func url(for task: Task) -> URL
    public func url(for board: Board) -> URL
    public func archiveURL(for task: Task) -> URL
}
```

---

### YAMLParser

YAML frontmatter parsing and generation.

```swift
public struct YAMLParser {
    // MARK: - Parsing

    public static func parseFrontmatter<T: Decodable>(_ markdown: String) -> (metadata: T?, body: String)

    public static func parseFrontmatterStrict<T: Decodable>(_ markdown: String) throws -> (metadata: T, body: String)

    // MARK: - Generation

    public static func generateFrontmatter<T: Encodable>(_ object: T, body: String) throws -> String

    // MARK: - Convenience Methods

    public static func parseTask(_ markdown: String) throws -> (task: Task, body: String)
    public static func generateTask(_ task: Task, notes: String) throws -> String

    public static func parseBoard(_ markdown: String) throws -> (board: Board, body: String)
    public static func generateBoard(_ board: Board, notes: String) throws -> String
}
```

---

### FileWatcher

FSEvents-based file system monitoring.

```swift
public final class FileWatcher {
    // MARK: - Callbacks

    public var onFileCreated: ((URL) -> Void)?
    public var onFileModified: ((URL) -> Void)?
    public var onFileDeleted: ((URL) -> Void)?

    // MARK: - Control

    public func startWatching(directory: URL)
    public func stopWatching()

    // MARK: - Conflict Detection

    public func checkForConflict(task: Task, fileURL: URL) -> FileConflict?
}
```

---

## Extension Points

### Creating Custom Coordinators

```swift
protocol AppCoordinator {
    func navigate(to perspective: Perspective)
    func navigate(to board: Board)
    func showQuickCapture()
    func showTaskInspector(for task: Task)
    func createTask(from input: String)
    func updateTask(_ task: Task)
    func deleteTask(_ task: Task)
}
```

### Adding Custom Perspectives

```swift
let myPerspective = Perspective.custom(
    id: "my-custom-view",
    name: "My Custom View",
    filter: Filter(
        project: ["Important"],
        priority: [.high],
        status: [.nextAction]
    ),
    groupBy: .context,
    sortBy: .priority
)
```

### Creating Board Templates

```swift
func createSprintBoard(sprintNumber: Int) -> Board {
    Board(
        id: "sprint-\(sprintNumber)",
        type: .custom,
        displayTitle: "Sprint \(sprintNumber)",
        layout: .kanban,
        filter: Filter(tags: ["sprint-\(sprintNumber)"]),
        columns: ["Backlog", "In Progress", "Review", "Done"]
    )
}
```

---

## Error Handling

All data layer operations that can fail throw typed errors:

```swift
public enum DataError: LocalizedError {
    case directoryNotFound
    case fileNotFound(URL)
    case invalidYAML(String)
    case invalidTask(String)
    case invalidBoard(String)
    case writeError(Error)
    case readError(Error)
    case permissionDenied

    public var errorDescription: String? { get }
    public var recoverySuggestion: String? { get }
}
```

### Error Handling Example

```swift
do {
    try await manager.initialize(rootDirectory: dataURL)
} catch DataError.directoryNotFound {
    // Handle missing directory
    print("Data directory not found. Creating...")
} catch DataError.permissionDenied {
    // Handle permission error
    print("Cannot access directory. Check permissions.")
} catch {
    // Handle other errors
    print("Initialization failed: \(error.localizedDescription)")
}
```

---

## Performance Considerations

### Recommended Limits
- **Maximum tasks**: 1,000 active tasks for optimal performance
- **Board canvas**: Up to 200 visible tasks per board
- **Search results**: Limited to 500 matches
- **Undo history**: 10 levels

### Optimization Tips

```swift
// Use batch operations for multiple changes
let updatedTasks = tasks.map { task in
    var t = task
    t.priority = .high
    return t
}
taskStore.batchUpdate(updatedTasks)

// Filter before processing
let filtered = taskStore.tasks(matching: filter)
// Process only filtered tasks

// Debounce searches
// Built-in 300ms debouncing in SearchManager
```

---

## Thread Safety

All stores use serial queues for thread-safe operations:

```swift
// Safe to call from any thread
DispatchQueue.global().async {
    let task = Task(title: "Background Task")
    DataManager.shared.taskStore.add(task)
}

// Updates published on main thread automatically
taskStore.tasks  // Always safe to access from main thread in SwiftUI
```

---

## Migration Guide

### Version 1.0.0 (Initial Release)

No migration required. This is the first version.

### Future Migrations

Migration tools will be provided if the data format changes in future versions. The YAML frontmatter format is designed to be forward-compatible.

---

## Additional Resources

- **[User Guide](docs/USER_GUIDE.md)** - Feature documentation for end users
- **[Development Guide](docs/DEVELOPMENT.md)** - Architecture and contributing
- **[File Format Specification](docs/FILE_FORMAT.md)** - Markdown format details
- **[Testing Guide](TESTING_GUIDE.md)** - Testing strategies and examples

---

**Version**: 1.0.0
**Last Updated**: 2025-11-18
**Maintainers**: StickyToDo Development Team
