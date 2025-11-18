# StickyToDo Development Guide

Technical documentation for developers contributing to or extending StickyToDo.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Getting Started](#getting-started)
3. [Project Structure](#project-structure)
4. [Core Components](#core-components)
5. [Data Layer](#data-layer)
6. [UI Layer](#ui-layer)
7. [Testing](#testing)
8. [Building and Running](#building-and-running)
9. [Contributing](#contributing)
10. [Release Process](#release-process)

## Architecture Overview

StickyToDo follows a clean architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────┐
│          UI Layer (Views)           │
│   SwiftUI & AppKit Components       │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│       Application Layer (Stores)     │
│   TaskStore, BoardStore, DataMgr    │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│        Data Layer (I/O)             │
│   MarkdownFileIO, YAMLParser        │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│         Model Layer (Core)          │
│   Task, Board, Perspective, etc.    │
└─────────────────────────────────────┘
```

### Key Architectural Decisions

**1. Plain-Text Storage**
- All data in markdown files with YAML frontmatter
- No database, human-readable format
- Enables version control, external editing

**2. Reactive Data Flow**
- Combine framework for reactive updates
- ObservableObject stores publish changes
- Views automatically update via @Published

**3. Dual UI Approach**
- SwiftUI for modern, declarative UI
- AppKit for advanced canvas interactions
- Bridges between both frameworks

**4. GTD-First Design**
- Models follow Getting Things Done methodology
- Status-based workflow
- Context and project organization

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- macOS 14.0 (Sonoma) or later
- Swift 5.9 or later
- Command Line Tools installed

### Clone and Setup

```bash
# Clone repository
git clone https://github.com/yourusername/sticky-todo.git
cd sticky-todo

# Open in Xcode
open StickyToDo.xcodeproj

# Or use command line
xcodebuild -project StickyToDo.xcodeproj -scheme StickyToDo
```

### First Build

1. **Select target** - StickyToDo (Mac)
2. **Choose destination** - My Mac
3. **Build** - ⌘B
4. **Run** - ⌘R

### Dependencies

StickyToDo uses Swift Package Manager for dependencies:

**Yams** - YAML parsing
- Repository: https://github.com/jpsim/Yams
- Version: ~> 5.0
- Usage: Frontmatter parsing and generation

To add/update dependencies:
1. File → Add Packages...
2. Enter repository URL
3. Select version requirements
4. Add to target

## Project Structure

```
StickyToDo/
├── StickyToDoCore/           # Core models (shared)
│   └── Models/
│       ├── Task.swift
│       ├── Board.swift
│       ├── Perspective.swift
│       ├── Filter.swift
│       ├── Status.swift
│       ├── Priority.swift
│       ├── Position.swift
│       └── ...
│
├── StickyToDo/               # SwiftUI app
│   ├── StickyToDoApp.swift   # App entry point
│   ├── ContentView.swift     # Main window
│   ├── Data/                 # Data layer
│   │   ├── DataManager.swift
│   │   ├── TaskStore.swift
│   │   ├── BoardStore.swift
│   │   ├── MarkdownFileIO.swift
│   │   ├── YAMLParser.swift
│   │   └── FileWatcher.swift
│   └── Views/
│       ├── ListView/
│       ├── BoardView/
│       ├── QuickCapture/
│       └── Inspector/
│
├── StickyToDo-AppKit/        # AppKit-based board views
│   ├── CanvasViewController.swift
│   ├── PrototypeWindow.swift
│   └── BoardCanvas/
│
└── StickyToDoTests/          # Unit tests
    ├── ModelTests.swift
    ├── YAMLParserTests.swift
    ├── MarkdownFileIOTests.swift
    ├── TaskStoreTests.swift
    ├── BoardStoreTests.swift
    ├── NaturalLanguageParserTests.swift
    └── DataManagerTests.swift
```

### File Organization Principles

1. **Models in Core** - Shared between all targets
2. **Platform-specific in separate targets** - SwiftUI vs AppKit
3. **Tests mirror implementation** - Same structure
4. **Group by feature** - ListView/, BoardView/, etc.

## Core Components

### Models (StickyToDoCore/Models/)

**Task.swift** - Central task model
```swift
struct Task: Identifiable, Codable {
    let id: UUID
    var type: TaskType
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
}
```

**Key methods:**
- `matches(_ filter: Filter) -> Bool` - Filter matching
- `matchesSearch(_ query: String) -> Bool` - Text search
- `complete()`, `reopen()` - Status transitions
- `promoteToTask()`, `demoteToNote()` - Type changes
- `setPosition(_ position: Position, for boardId: String)` - Board positioning

**Board.swift** - Board configuration
```swift
struct Board: Identifiable, Codable {
    let id: String
    var type: BoardType
    var layout: Layout
    var filter: Filter
    var columns: [String]?
    var autoHide: Bool
    var title: String?
    var notes: String?
    // ...
}
```

**Key methods:**
- `metadataUpdates(forColumn:) -> [String: Any]` - Metadata changes
- `shouldAutoHide(lastActiveDate:) -> Bool` - Auto-hide logic

**Perspective.swift** - List view configuration
```swift
struct Perspective: Identifiable, Codable {
    let id: String
    var name: String
    var filter: Filter
    var groupBy: GroupBy
    var sortBy: SortBy
    var sortDirection: SortDirection
    // ...
}
```

**Key methods:**
- `apply(to tasks: [Task]) -> [Task]` - Filter and sort
- `group(_ tasks: [Task]) -> [(String, [Task])]` - Group tasks

### Data Layer

**DataManager.swift** - Central coordinator
```swift
final class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published private(set) var isInitialized = false
    @Published private(set) var isLoading = false

    private(set) var taskStore: TaskStore!
    private(set) var boardStore: BoardStore!

    func initialize(rootDirectory: URL) async throws
    func createTask(...) -> Task
    func updateTask(_ task: Task)
    func deleteTask(_ task: Task)
    // ...
}
```

**TaskStore.swift** - Task management
```swift
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [Task] = []
    @Published private(set) var projects: [String] = []
    @Published private(set) var contexts: [String] = []

    func loadAll() throws
    func add(_ task: Task)
    func update(_ task: Task)
    func delete(_ task: Task)
    func tasks(matching filter: Filter) -> [Task]
    // ...
}
```

**Debounced saves:**
- 500ms delay
- Coalesce rapid changes
- Immediate save before quit

**BoardStore.swift** - Board management
```swift
final class BoardStore: ObservableObject {
    @Published private(set) var boards: [Board] = []
    @Published private(set) var visibleBoards: [Board] = []

    func loadAll() throws
    func add(_ board: Board)
    func getOrCreateContextBoard(for context: Context) -> Board
    func getOrCreateProjectBoard(for projectName: String) -> Board
    // ...
}
```

**MarkdownFileIO.swift** - File I/O
```swift
class MarkdownFileIO {
    private let rootDirectory: URL

    func ensureDirectoryStructure() throws
    func readTask(from url: URL) throws -> Task?
    func writeTask(_ task: Task) throws
    func loadAllTasks() throws -> [Task]
    func readBoard(from url: URL) throws -> Board?
    func writeBoard(_ board: Board) throws
    func loadAllBoards() throws -> [Board]
    // ...
}
```

**YAMLParser.swift** - Frontmatter parsing
```swift
struct YAMLParser {
    static func parseFrontmatter<T: Decodable>(_ markdown: String) -> (T?, String)
    static func parseFrontmatterStrict<T: Decodable>(_ markdown: String) throws -> (T, String)
    static func generateFrontmatter<T: Encodable>(_ object: T, body: String) throws -> String
    // ...
}
```

**FileWatcher.swift** - External change detection
```swift
class FileWatcher {
    var onFileCreated: ((URL) -> Void)?
    var onFileModified: ((URL) -> Void)?
    var onFileDeleted: ((URL) -> Void)?

    func startWatching(directory: URL)
    func stopWatching()
    func checkForConflict(...) -> FileConflict?
    // ...
}
```

## UI Layer

### SwiftUI Views

**ContentView.swift** - Main window
```swift
struct ContentView: View {
    @StateObject var dataManager = DataManager.shared
    @State private var selectedView: ViewType = .list

    var body: some View {
        NavigationSplitView {
            Sidebar()
        } detail: {
            if selectedView == .list {
                TaskListView()
            } else {
                BoardCanvasView()
            }
        }
    }
}
```

**TaskListView.swift** - List view
- Displays filtered/sorted tasks
- Supports grouping
- Inline editing
- Multi-selection

**TaskRowView.swift** - Individual task row
- Status indicator
- Priority badge
- Due date display
- Flag indicator

**TaskInspectorView.swift** - Task details
- All task properties
- Markdown editor for notes
- Date pickers
- Dropdown selectors

**QuickCaptureView.swift** - Global quick capture
- Natural language parsing
- Floating window
- Keyboard-driven

**PerspectiveSidebarView.swift** - Perspective list
- Built-in perspectives
- Custom perspectives
- Drag to reorder

### AppKit Views

**BoardCanvasView.swift** - Canvas container
```swift
struct BoardCanvasView: NSViewControllerRepresentable {
    @Binding var board: Board
    @Binding var tasks: [Task]

    func makeNSViewController(context: Context) -> CanvasViewController {
        // Create AppKit view controller
    }

    func updateNSViewController(_ nsViewController: CanvasViewController, context: Context) {
        // Update with new data
    }
}
```

**CanvasViewController.swift** - AppKit canvas
- Custom drawing
- Drag and drop
- Zoom/pan
- Hit testing

## Testing

### Test Structure

All tests follow the Arrange-Act-Assert pattern:

```swift
func testExample() {
    // Arrange
    let task = Task(title: "Test", status: .inbox)

    // Act
    task.complete()

    // Assert
    XCTAssertEqual(task.status, .completed)
}
```

### Running Tests

**Xcode:**
1. ⌘U - Run all tests
2. ⌘⌥U - Run tests with coverage
3. Click diamond in gutter - Run single test

**Command Line:**
```bash
# All tests
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo

# Specific test
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo \
  -only-testing:StickyToDoTests/ModelTests/testTaskCreation

# With coverage
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo \
  -enableCodeCoverage YES
```

### Test Categories

**ModelTests.swift**
- Task creation and modification
- Board configuration
- Perspective filtering
- Filter matching
- Status transitions

**YAMLParserTests.swift**
- Parse valid frontmatter
- Handle malformed YAML
- Round-trip testing
- Unicode handling

**MarkdownFileIOTests.swift**
- Read/write tasks and boards
- Directory creation
- Error handling
- Concurrent access

**TaskStoreTests.swift**
- Add/update/delete tasks
- Filtering and searching
- Debounced saves
- Observer notifications

**BoardStoreTests.swift**
- Board management
- Auto-creation logic
- Auto-hide behavior
- Dynamic project boards

**NaturalLanguageParserTests.swift**
- Context extraction
- Project extraction
- Priority parsing
- Date parsing
- Effort parsing

**DataManagerTests.swift**
- Initialization
- First-run setup
- Conflict detection
- Save before quit

### Coverage Goals

- **Models:** 90%+ - Core business logic
- **Data Layer:** 85%+ - Critical persistence
- **Stores:** 80%+ - State management
- **Views:** 60%+ - UI components (harder to test)

### Mocking

**File I/O:**
```swift
class MockFileIO: MarkdownFileIO {
    var mockTasks: [Task] = []

    override func loadAllTasks() throws -> [Task] {
        return mockTasks
    }

    override func writeTask(_ task: Task) throws {
        mockTasks.append(task)
    }
}
```

**Use in tests:**
```swift
func testWithMock() {
    let mockIO = MockFileIO()
    mockIO.mockTasks = [Task(title: "Test")]

    let store = TaskStore(fileIO: mockIO)
    try store.loadAll()

    XCTAssertEqual(store.taskCount, 1)
}
```

## Building and Running

### Debug Build

```bash
xcodebuild -project StickyToDo.xcodeproj \
  -scheme StickyToDo \
  -configuration Debug \
  build
```

### Release Build

```bash
xcodebuild -project StickyToDo.xcodeproj \
  -scheme StickyToDo \
  -configuration Release \
  build
```

### Code Signing

For distribution:

1. **Developer ID Application** certificate
2. **Hardened Runtime** enabled
3. **Notarization** via Apple

### Build Settings

**Debug:**
- Optimization: None [-Onone]
- Debug Symbols: Yes
- Assertions: Enabled

**Release:**
- Optimization: Aggressive [-O]
- Debug Symbols: Strip
- Assertions: Disabled
- Whole Module Optimization: Yes

## Contributing

### Code Style

**Swift Style Guide:**
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for consistency
- 4 spaces for indentation
- Max line length: 120 characters

**Naming Conventions:**
```swift
// Types: PascalCase
class TaskStore { }
struct Task { }
enum Status { }

// Functions/Properties: camelCase
func loadAllTasks() { }
var taskCount: Int

// Constants: camelCase
let maxTaskCount = 1000

// Enums: lowercase
enum Status {
    case inbox
    case nextAction
}
```

**Documentation:**
```swift
/// Brief description of what this does.
///
/// Longer description with more details about
/// behavior, edge cases, etc.
///
/// - Parameter task: The task to process
/// - Returns: Processed result
/// - Throws: TaskError if processing fails
func processTask(_ task: Task) throws -> ProcessedTask {
    // Implementation
}
```

### Pull Request Process

1. **Fork** repository
2. **Create branch** - `feature/my-feature` or `fix/my-bug`
3. **Make changes** - Follow code style
4. **Add tests** - Maintain coverage
5. **Update docs** - If API changes
6. **Run tests** - All must pass
7. **Submit PR** - Descriptive title and description

**PR Template:**
```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Added unit tests
- [ ] All tests passing
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guide
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): subject

body

footer
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Formatting
- `refactor:` - Code restructuring
- `test:` - Tests
- `chore:` - Maintenance

**Examples:**
```
feat(quick-capture): add natural language parsing for dates

Implement date parsing that recognizes "tomorrow", "next week",
and specific dates like "nov 20".

Closes #123
```

```
fix(task-store): prevent duplicate task IDs in store

Tasks with duplicate UUIDs were being added to the store,
causing data corruption. Added check before insertion.

Fixes #456
```

## Release Process

### Versioning

Follows [Semantic Versioning](https://semver.org/):

`MAJOR.MINOR.PATCH`

- **MAJOR** - Breaking changes
- **MINOR** - New features, backwards compatible
- **PATCH** - Bug fixes

### Release Checklist

1. **Update version** in project settings
2. **Update CHANGELOG.md**
3. **Run all tests** - Must pass
4. **Build release** - Archive
5. **Code sign** - Developer ID
6. **Notarize** - Submit to Apple
7. **Create tag** - `v1.2.3`
8. **Push tag** - Triggers CI
9. **Create GitHub release** - Attach binary
10. **Announce** - Blog/Twitter/etc.

### Continuous Integration

**GitHub Actions:**
```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo
      - name: Upload coverage
        uses: codecov/codecov-action@v1
```

## Debugging

### Common Issues

**Tests failing:**
```bash
# Clean build folder
xcodebuild clean -project StickyToDo.xcodeproj

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

**File watcher not working:**
- Check file permissions
- Verify `FileWatcher` is initialized
- Enable debug logging

**YAML parsing errors:**
- Validate YAML syntax
- Check for special characters
- Ensure proper quoting

### Debug Logging

**Enable:**
```swift
DataManager.shared.enableLogging = true

DataManager.shared.setLogger { message in
    print(message)
}
```

**Levels:**
- INFO - Normal operations
- WARN - Recoverable issues
- ERROR - Failures

## Resources

### Documentation
- [User Guide](USER_GUIDE.md)
- [Keyboard Shortcuts](KEYBOARD_SHORTCUTS.md)
- [File Format](FILE_FORMAT.md)

### External
- [Swift Documentation](https://docs.swift.org/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Getting Things Done](https://gettingthingsdone.com/)
- [Yams Documentation](https://github.com/jpsim/Yams)

### Community
- GitHub Issues
- Discussions
- Discord Server (if applicable)

---

*Last updated: 2025-11-18*

Happy coding!
