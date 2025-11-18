# StickyToDo Integration Guide

This guide explains how the UI components are wired to the data layer in both AppKit and SwiftUI versions.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  ┌──────────────────┐              ┌────────────────────┐   │
│  │  AppKit Views    │              │   SwiftUI Views    │   │
│  │  - NSTableView   │              │   - List           │   │
│  │  - NSOutlineView │              │   - NavigationView │   │
│  └──────────────────┘              └────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                        │                        │
                        ▼                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   Coordination Layer                         │
│  ┌──────────────────┐              ┌────────────────────┐   │
│  │ AppKitCoordinator│              │SwiftUICoordinator  │   │
│  │ - KVO Observers  │              │ - @Published props │   │
│  │ - NotificationCtr│              │ - Combine pipeline │   │
│  └──────────────────┘              └────────────────────┘   │
│           │                                   │              │
│           └───────────────┬───────────────────┘              │
│                          ▼                                   │
│              ┌──────────────────────┐                        │
│              │  BaseAppCoordinator  │                        │
│              │  - Shared logic      │                        │
│              │  - Task operations   │                        │
│              └──────────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ DataManager  │──│  TaskStore   │  │   BoardStore     │   │
│  │ - Init       │  │  - @Published│  │   - @Published   │   │
│  │ - FileWatcher│  │  - Debounce  │  │   - Auto-hide    │   │
│  │ - Conflicts  │  │  - Filter    │  │   - Filter       │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
│                            │                                 │
│                            ▼                                 │
│                  ┌──────────────────┐                        │
│                  │ MarkdownFileIO   │                        │
│                  │ - Read/Write     │                        │
│                  │ - YAML parsing   │                        │
│                  └──────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │  File System │
                    │  - tasks/    │
                    │  - boards/   │
                    └──────────────┘
```

## Key Components

### 1. AppCoordinator Protocol (StickyToDoCore/Utilities/AppCoordinator.swift)

Defines the contract for both AppKit and SwiftUI coordinators:

```swift
protocol AppCoordinatorProtocol: AnyObject {
    var dataManager: DataManager { get }
    var taskStore: TaskStore { get }
    var boardStore: BoardStore { get }
    var configManager: ConfigurationManager { get }

    func navigateToPerspective(_ perspective: Perspective)
    func navigateToBoard(_ board: Board)
    func createTask(title: String, status: Status, perspective: Perspective?) -> Task
    func updateTask(_ task: Task)
    // ... more methods
}
```

### 2. ConfigurationManager (StickyToDoCore/Utilities/ConfigurationManager.swift)

Manages all app preferences and settings:

```swift
class ConfigurationManager: ObservableObject {
    @Published var dataDirectory: URL
    @Published var lastPerspectiveID: String?
    @Published var viewMode: ViewMode
    // ... more settings
}
```

### 3. AppKit Integration

#### AppKitCoordinator (StickyToDo-AppKit/AppKitCoordinator.swift)

Coordinates AppKit views with data stores using Combine:

```swift
class AppKitCoordinator: BaseAppCoordinator, AppCoordinatorProtocol {
    private var mainWindowController: MainWindowController?

    private func setupDataObservers() {
        taskStore.$tasks
            .sink { [weak self] tasks in
                self?.handleTasksChanged(tasks)
            }
            .store(in: &cancellables)
    }
}
```

#### DataSourceAdapters (StickyToDo-AppKit/Integration/DataSourceAdapters.swift)

Connects NSTableView and NSOutlineView to data stores:

```swift
class TaskListDataSource: NSObject, NSTableViewDataSource {
    private let taskStore: TaskStore

    func numberOfRows(in tableView: NSTableView) -> Int {
        return displayedTasks.count
    }
}
```

#### AppStateInitializer (StickyToDo-AppKit/Integration/AppStateInitializer.swift)

Initializes the app state on launch:

```swift
// In AppDelegate.swift
func applicationDidFinishLaunching(_ notification: Notification) {
    AppStateInitializer.shared.initialize { result in
        switch result {
        case .success:
            self.mainWindowController?.setCoordinator(
                AppStateInitializer.shared.coordinator
            )
        case .failure(let error):
            self.showError(error)
        }
    }
}
```

### 4. SwiftUI Integration

#### SwiftUICoordinator (StickyToDo-SwiftUI/Utilities/SwiftUICoordinator.swift)

Coordinates SwiftUI views with data stores using @Published properties:

```swift
class SwiftUICoordinator: BaseAppCoordinator, AppCoordinatorProtocol {
    @Published var navigationPath = NavigationPath()
    @Published var selectedTask: Task?
    @Published var isQuickCaptureVisible = false

    func navigateToBoard(_ board: Board) {
        navigationPath.append(NavigationDestination.board(board))
    }
}
```

#### AppStateInitializer (StickyToDo-SwiftUI/Utilities/AppStateInitializer.swift)

Handles async initialization and provides SwiftUI views:

```swift
@MainActor
class AppStateInitializer: ObservableObject {
    @Published var isInitialized = false

    func initialize() async {
        try await dataManager.initialize(rootDirectory: dataDirectory)
        try await coordinator.initialize()
    }
}
```

#### Usage in SwiftUI App:

```swift
@main
struct StickyToDoApp: App {
    var body: some Scene {
        WindowGroup {
            AppContentView()  // Handles initialization automatically
        }
    }
}
```

## Data Flow Examples

### Example 1: Creating a Task (AppKit)

```swift
// User clicks "New Task" button in UI
// ↓
// MainWindowController
func addTask(_ sender: Any?) {
    coordinator.createTask(title: "New Task", status: .inbox, perspective: nil)
}

// ↓
// AppKitCoordinator
override func createTask(title: String, status: Status, perspective: Perspective?) -> Task {
    let task = super.createTask(title: title, status: status)
    mainWindowController?.refreshAfterTaskCreated(task)
    NotificationCenter.default.post(name: .taskCreated, object: task)
    return task
}

// ↓
// BaseAppCoordinator
func createTask(...) -> Task {
    let task = dataManager.createTask(title: title, status: status)
    return task
}

// ↓
// DataManager
func createTask(title: String, status: Status) -> Task {
    let task = Task(title: title, status: status)
    taskStore.add(task)
    return task
}

// ↓
// TaskStore
func add(_ task: Task) {
    tasks.append(task)  // @Published property triggers UI update
    scheduleSave(for: task)  // Debounced save to disk
}
```

### Example 2: Navigating to a Board (SwiftUI)

```swift
// User taps a board in sidebar
// ↓
// PerspectiveSidebarView (SwiftUI)
Button(action: {
    coordinator.navigateToBoard(board)
}) {
    Text(board.displayTitle)
}

// ↓
// SwiftUICoordinator
func navigateToBoard(_ board: Board) {
    super.navigateToBoard(board)
    navigationPath.append(NavigationDestination.board(board))  // @Published
    configManager.lastBoardID = board.id
}

// ↓
// BaseAppCoordinator
func navigateToBoard(_ board: Board) {
    activeBoard = board  // @Published
    activePerspective = nil
    viewMode = .board
}

// ↓
// SwiftUI automatically updates ContentView due to @Published properties
```

### Example 3: Observer Pattern (AppKit)

```swift
// TaskStore publishes changes
taskStore.$tasks.sink { [weak self] tasks in
    self?.handleTasksChanged(tasks)
}

// ↓
// AppKitCoordinator handles changes
private func handleTasksChanged(_ tasks: [Task]) {
    mainWindowController?.refreshTaskList()
    updateBadgeCounts()
}

// ↓
// MainWindowController updates NSTableView
func refreshTaskList() {
    taskListViewController.setTasks(filteredTasks)
}

// ↓
// TaskListViewController reloads table
func setTasks(_ tasks: [Task]) {
    allTasks = tasks
    refreshData()
}

func refreshData() {
    tableView.reloadData()  // NSTableView reloads
}
```

## Initialization Flow

### AppKit Initialization

```
1. AppDelegate.applicationDidFinishLaunching
   ↓
2. AppStateInitializer.shared.initialize()
   ↓
3. ConfigurationManager.load()
   ↓
4. DataManager.initialize(rootDirectory:)
   ├─ TaskStore.loadAll()
   └─ BoardStore.loadAll()
   ↓
5. AppKitCoordinator.initialize()
   ↓
6. Wire MainWindowController to coordinator
   ↓
7. Restore last state (perspective, view mode, etc.)
   ↓
8. Show main window
```

### SwiftUI Initialization

```
1. App.init
   ↓
2. WindowGroup { AppContentView() }
   ↓
3. AppContentView displays loading view
   ↓
4. .task { await AppStateInitializer.shared.initialize() }
   ↓
5. ConfigurationManager.load()
   ↓
6. DataManager.initialize(rootDirectory:)
   ├─ TaskStore.loadAllAsync()
   └─ BoardStore.loadAllAsync()
   ↓
7. SwiftUICoordinator.initialize()
   ↓
8. Restore last state
   ↓
9. AppContentView switches to ContentView
   ↓
10. ContentView receives coordinator via .environmentObject
```

## Best Practices

### 1. Use Coordinators for All Actions

✅ **Good:**
```swift
coordinator.createTask(title: "New task")
coordinator.navigateToBoard(board)
```

❌ **Bad:**
```swift
dataManager.taskStore.add(task)  // Bypasses coordinator
```

### 2. Observe Data Changes via Combine

✅ **Good:**
```swift
taskStore.$tasks
    .sink { tasks in
        updateUI(with: tasks)
    }
    .store(in: &cancellables)
```

❌ **Bad:**
```swift
Timer.scheduledTimer(withTimeInterval: 1.0) { _ in
    checkForTaskChanges()
}
```

### 3. Use Configuration Manager for Preferences

✅ **Good:**
```swift
let dataDir = configManager.dataDirectory
configManager.lastViewMode = .board
```

❌ **Bad:**
```swift
UserDefaults.standard.set("/path", forKey: "dataDirectory")
```

### 4. Handle Errors Gracefully

✅ **Good:**
```swift
do {
    try await coordinator.initialize()
} catch {
    showError(error)
}
```

❌ **Bad:**
```swift
try! coordinator.initialize()  // Will crash on error
```

## Threading Considerations

- **TaskStore/BoardStore:** Thread-safe via internal serial queues
- **DataManager:** Thread-safe, performs I/O on background queues
- **Coordinators:** Always update UI on main thread
- **SwiftUI:** @Published properties automatically update on MainActor
- **AppKit:** Use DispatchQueue.main.async for UI updates

## File Watcher Integration

The file watcher automatically detects external changes:

```swift
// DataManager sets up file watcher
fileWatcher.onFileModified = { [weak self] url in
    self?.handleFileModified(url)
}

// ↓
// Reloads task from disk
private func reloadTaskFromFile(_ url: URL) {
    if let updatedTask = try? fileIO.readTask(from: url) {
        taskStore.update(updatedTask)  // @Published triggers UI update
    }
}
```

## Memory Management

All coordinators and data sources use weak references to avoid retain cycles:

```swift
taskStore.$tasks
    .sink { [weak self] tasks in  // ✅ Weak reference
        self?.handleTasksChanged(tasks)
    }
    .store(in: &cancellables)
```

Cancellables are stored and cleaned up:

```swift
deinit {
    cancellables.removeAll()
}
```

## Testing

The architecture supports testing at multiple levels:

```swift
// Unit test TaskStore
let fileIO = MockMarkdownFileIO()
let taskStore = TaskStore(fileIO: fileIO)

// Integration test Coordinator
let mockDataManager = MockDataManager()
let coordinator = AppKitCoordinator(dataManager: mockDataManager)

// UI test
// Use XCUITest for AppKit, or SwiftUI previews for SwiftUI
```

## Common Integration Points

### Adding a New Task Action

1. Add method to `AppCoordinatorProtocol`
2. Implement in `BaseAppCoordinator` (shared logic)
3. Override in `AppKitCoordinator` or `SwiftUICoordinator` (UI-specific)
4. Wire UI to coordinator method
5. Update UI after action completes

### Adding a New View

1. Create view controller/view
2. Add navigation method to coordinator
3. Wire view to data via data source adapters (AppKit) or @Published properties (SwiftUI)
4. Handle user actions via coordinator

### Adding a New Preference

1. Add @Published property to `ConfigurationManager`
2. Add UserDefaults key
3. Load in `init()`, save on change
4. Access via `configManager.propertyName`

## Troubleshooting

### UI Not Updating

- Ensure using @Published properties
- Check Combine subscriptions are stored in cancellables
- Verify updates happen on main thread

### Data Not Persisting

- Check file permissions in data directory
- Verify debounced save timers aren't cancelled prematurely
- Call `saveBeforeQuit()` on app termination

### Memory Leaks

- Use weak references in closures
- Store cancellables and clean up in deinit
- Check for retain cycles with Instruments

---

For more details, see the inline documentation in each file.
