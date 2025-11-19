# StickyToDo - Testing Guide

**Version**: 1.0.0
**Last Updated**: 2025-11-18
**Test Coverage**: 80%+ (Core Data Layer)

---

## Table of Contents

1. [Overview](#overview)
2. [Test Structure](#test-structure)
3. [Running Tests](#running-tests)
4. [Unit Tests](#unit-tests)
5. [Integration Tests](#integration-tests)
6. [Manual Testing](#manual-testing)
7. [Performance Testing](#performance-testing)
8. [Writing New Tests](#writing-new-tests)
9. [Test Coverage](#test-coverage)
10. [Continuous Integration](#continuous-integration)

---

## Overview

StickyToDo maintains high test coverage to ensure reliability and data safety. The test suite covers:

- **Core Models** - Business logic and validation
- **Data Layer** - File I/O, YAML parsing, stores
- **Parsers** - Natural language and YAML parsing
- **Integration** - End-to-end workflows

### Testing Philosophy

1. **Test What Matters** - Focus on business logic and data integrity
2. **Fast Tests** - Unit tests run in < 5 seconds
3. **Isolated** - Tests don't depend on each other
4. **Repeatable** - Same inputs always produce same outputs
5. **Readable** - Tests document expected behavior

### Test Pyramid

```
          ┌────────────┐
         /  Manual (5%) \
        /                \
       /   Integration    \
      /      (15%)         \
     /                      \
    /      Unit Tests        \
   /         (80%)            \
  /                            \
 └──────────────────────────────┘
```

---

## Test Structure

### Test Suite Organization

```
StickyToDoTests/
├── ModelTests.swift                    # Core model validation
├── YAMLParserTests.swift               # YAML parsing
├── MarkdownFileIOTests.swift           # File I/O
├── TaskStoreTests.swift                # Task store operations
├── BoardStoreTests.swift               # Board store operations
├── DataManagerTests.swift              # Integration tests
├── NaturalLanguageParserTests.swift    # Quick capture parsing
└── StickyToDoTests.swift               # General tests
```

### Test File Structure

Each test file follows this pattern:

```swift
import XCTest
@testable import StickyToDo

final class TaskStoreTests: XCTestCase {
    // MARK: - Properties

    var store: TaskStore!
    var testDirectory: URL!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        // Called before each test
        store = TaskStore()
        testDirectory = createTempDirectory()
    }

    override func tearDownWithError() throws {
        // Called after each test
        deleteTempDirectory(testDirectory)
        store = nil
    }

    // MARK: - Tests

    func testTaskCreation() {
        // Test implementation
    }

    // MARK: - Helpers

    private func createSampleTask() -> Task {
        // Helper method
    }
}
```

---

## Running Tests

### In Xcode

**Run All Tests**:
1. Open StickyToDo.xcodeproj in Xcode
2. Press `⌘U` or select Product → Test
3. Wait for tests to complete (5-10 seconds)
4. View results in Test Navigator (⌘6)

**Run Specific Test Suite**:
1. Open test file (e.g., `TaskStoreTests.swift`)
2. Click diamond icon next to `class TaskStoreTests`
3. Or press `⌘U` with file open

**Run Single Test**:
1. Click diamond icon next to test method
2. Or place cursor in test method and press `⌘U`

**Test with Coverage**:
1. Press `⌘⌥U` or select Product → Test with Code Coverage
2. View coverage report: View → Navigators → Reports (⌘9)
3. Select latest test run
4. Click Coverage tab

### Command Line

**Run All Tests**:
```bash
xcodebuild test \
  -project StickyToDo.xcodeproj \
  -scheme StickyToDo \
  -destination 'platform=macOS'
```

**Run Specific Test Class**:
```bash
xcodebuild test \
  -project StickyToDo.xcodeproj \
  -scheme StickyToDo \
  -only-testing:StickyToDoTests/TaskStoreTests
```

**Run Single Test**:
```bash
xcodebuild test \
  -project StickyToDo.xcodeproj \
  -scheme StickyToDo \
  -only-testing:StickyToDoTests/TaskStoreTests/testTaskCreation
```

**Test with Coverage**:
```bash
xcodebuild test \
  -project StickyToDo.xcodeproj \
  -scheme StickyToDo \
  -enableCodeCoverage YES \
  -destination 'platform=macOS'
```

**Extract Coverage Report**:
```bash
xcrun xccov view \
  --report \
  ~/Library/Developer/Xcode/DerivedData/.../Logs/Test/*.xcresult
```

---

## Unit Tests

### ModelTests.swift

Tests core model behavior and validation.

**Coverage**:
- Task creation and initialization
- Task metadata manipulation
- Status transitions
- Type conversions (note ↔ task)
- Board positioning
- Filter matching
- Validation rules

**Example Tests**:

```swift
// Test task creation with default values
func testTaskCreation() {
    let task = Task(title: "Test Task")

    XCTAssertNotNil(task.id)
    XCTAssertEqual(task.title, "Test Task")
    XCTAssertEqual(task.type, .task)
    XCTAssertEqual(task.status, .inbox)
    XCTAssertFalse(task.flagged)
    XCTAssertNil(task.due)
    XCTAssertNotNil(task.created)
}

// Test task completion
func testTaskCompletion() {
    var task = Task(title: "Complete me", status: .nextAction)

    task.complete()

    XCTAssertEqual(task.status, .completed)
    XCTAssertNotNil(task.completed)
    XCTAssertTrue(task.completed! > task.created)
}

// Test filter matching
func testFilterMatching() {
    let task = Task(
        title: "Test",
        status: .nextAction,
        project: "Website",
        priority: .high
    )

    let filter = Filter(
        status: [.nextAction],
        project: ["Website"]
    )

    XCTAssertTrue(task.matches(filter))
}

// Test board positioning
func testBoardPositioning() {
    var task = Task(title: "Positioned Task")
    let position = Position(x: 100, y: 200)

    task.setPosition(position, for: "board-1")

    XCTAssertEqual(task.position(for: "board-1")?.x, 100)
    XCTAssertEqual(task.position(for: "board-1")?.y, 200)
    XCTAssertNil(task.position(for: "board-2"))
}
```

**Run Model Tests**:
```bash
xcodebuild test \
  -project StickyToDo.xcodeproj \
  -scheme StickyToDo \
  -only-testing:StickyToDoTests/ModelTests
```

---

### YAMLParserTests.swift

Tests YAML frontmatter parsing and generation.

**Coverage**:
- Parse valid YAML frontmatter
- Handle malformed YAML gracefully
- Generate correct YAML from structs
- Round-trip testing (parse → generate → parse)
- Unicode and special character handling
- Date format parsing

**Example Tests**:

```swift
// Test parsing valid task YAML
func testParseTaskYAML() throws {
    let markdown = """
    ---
    id: 550e8400-e29b-41d4-a716-446655440000
    type: task
    title: "Test Task"
    status: next-action
    priority: high
    ---

    Task notes here.
    """

    let (task, body) = try YAMLParser.parseTask(markdown)

    XCTAssertEqual(task.title, "Test Task")
    XCTAssertEqual(task.status, .nextAction)
    XCTAssertEqual(task.priority, .high)
    XCTAssertEqual(body, "Task notes here.")
}

// Test generating task YAML
func testGenerateTaskYAML() throws {
    let task = Task(
        title: "Generate Test",
        status: .nextAction,
        priority: .high
    )
    let notes = "Test notes"

    let markdown = try YAMLParser.generateTask(task, notes: notes)

    XCTAssertTrue(markdown.contains("title: \"Generate Test\""))
    XCTAssertTrue(markdown.contains("status: next-action"))
    XCTAssertTrue(markdown.contains("priority: high"))
    XCTAssertTrue(markdown.contains("Test notes"))
}

// Test round-trip parsing
func testRoundTrip() throws {
    let original = Task(
        title: "Round Trip",
        status: .nextAction,
        project: "Test",
        context: "@computer",
        priority: .high,
        flagged: true
    )

    let markdown = try YAMLParser.generateTask(original, notes: "Notes")
    let (parsed, _) = try YAMLParser.parseTask(markdown)

    XCTAssertEqual(parsed.title, original.title)
    XCTAssertEqual(parsed.status, original.status)
    XCTAssertEqual(parsed.project, original.project)
    XCTAssertEqual(parsed.context, original.context)
}

// Test error handling
func testMalformedYAML() {
    let malformed = """
    ---
    title: Unclosed quote "
    status: invalid
    ---
    """

    XCTAssertThrowsError(try YAMLParser.parseTask(malformed)) { error in
        XCTAssertTrue(error is DataError)
    }
}
```

---

### MarkdownFileIOTests.swift

Tests file system operations.

**Coverage**:
- Read tasks from markdown files
- Write tasks to markdown files
- Directory creation and management
- Bulk loading operations
- Error handling (missing files, permission errors)
- Thread safety

**Example Tests**:

```swift
// Test write and read task
func testWriteAndReadTask() throws {
    let task = Task(title: "File Test", status: .nextAction)

    let url = try fileIO.writeTask(task)
    let loaded = try fileIO.readTask(from: url)

    XCTAssertNotNil(loaded)
    XCTAssertEqual(loaded?.id, task.id)
    XCTAssertEqual(loaded?.title, task.title)
}

// Test bulk loading
func testLoadAllTasks() throws {
    let task1 = Task(title: "Task 1")
    let task2 = Task(title: "Task 2")

    try fileIO.writeTask(task1)
    try fileIO.writeTask(task2)

    let tasks = try fileIO.loadAllTasks()

    XCTAssertEqual(tasks.count, 2)
    XCTAssertTrue(tasks.contains { $0.id == task1.id })
    XCTAssertTrue(tasks.contains { $0.id == task2.id })
}

// Test archive task
func testArchiveTask() throws {
    var task = Task(title: "Archive Me", status: .completed)
    try fileIO.writeTask(task)

    try fileIO.archiveTask(task)

    let archiveURL = fileIO.archiveURL(for: task)
    let archived = try fileIO.readTask(from: archiveURL)

    XCTAssertNotNil(archived)
    XCTAssertEqual(archived?.id, task.id)
}
```

---

### TaskStoreTests.swift

Tests in-memory task management.

**Coverage**:
- Add, update, delete operations
- Filtering by status, project, context
- Search functionality
- Project/context extraction
- Statistics calculation
- Batch operations

**Example Tests**:

```swift
// Test adding task
func testAddTask() {
    let task = Task(title: "New Task")

    store.add(task)

    XCTAssertEqual(store.taskCount, 1)
    XCTAssertNotNil(store.task(withId: task.id))
}

// Test filtering
func testFilterByStatus() {
    store.add(Task(title: "Inbox", status: .inbox))
    store.add(Task(title: "Next", status: .nextAction))
    store.add(Task(title: "Waiting", status: .waiting))

    let nextActions = store.tasks(with: .nextAction)

    XCTAssertEqual(nextActions.count, 1)
    XCTAssertEqual(nextActions.first?.title, "Next")
}

// Test search
func testSearch() {
    store.add(Task(title: "Design mockups"))
    store.add(Task(title: "Review code"))
    store.add(Task(title: "Design icons"))

    let results = store.search("design")

    XCTAssertEqual(results.count, 2)
    XCTAssertTrue(results.allSatisfy { $0.title.lowercased().contains("design") })
}

// Test statistics
func testStatistics() {
    store.add(Task(title: "Active 1", status: .nextAction))
    store.add(Task(title: "Active 2", status: .waiting))
    var completed = Task(title: "Done", status: .nextAction)
    completed.complete()
    store.add(completed)

    XCTAssertEqual(store.taskCount, 3)
    XCTAssertEqual(store.activeTaskCount, 2)
    XCTAssertEqual(store.completedTaskCount, 1)
}
```

---

### NaturalLanguageParserTests.swift

Tests quick capture natural language parsing.

**Coverage**:
- Context extraction (@phone, @office)
- Project extraction (#ProjectName)
- Priority parsing (!high, !medium, !low)
- Date parsing (tomorrow, friday, nov 20)
- Effort parsing (//30m, //2h)
- Multiple patterns in one input

**Example Tests**:

```swift
// Test context extraction
func testContextExtraction() {
    let (task, _) = parser.parse("Call John @phone")

    XCTAssertEqual(task.title, "Call John")
    XCTAssertEqual(task.context, "@phone")
}

// Test project extraction
func testProjectExtraction() {
    let (task, _) = parser.parse("Update docs #Website")

    XCTAssertEqual(task.title, "Update docs")
    XCTAssertEqual(task.project, "Website")
}

// Test priority parsing
func testPriorityParsing() {
    let (high, _) = parser.parse("Urgent task !high")
    let low, _) = parser.parse("Someday task !low")

    XCTAssertEqual(high.priority, .high)
    XCTAssertEqual(low.priority, .low)
}

// Test date parsing
func testDateParsing() {
    let (task, _) = parser.parse("Call client tomorrow")

    XCTAssertNotNil(task.due)
    // Verify tomorrow's date
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    XCTAssertEqual(
        Calendar.current.isDate(task.due!, inSameDayAs: tomorrow),
        true
    )
}

// Test complex input
func testComplexParsing() {
    let (task, _) = parser.parse("Review PR #App @computer !high tomorrow //30m")

    XCTAssertEqual(task.title, "Review PR")
    XCTAssertEqual(task.project, "App")
    XCTAssertEqual(task.context, "@computer")
    XCTAssertEqual(task.priority, .high)
    XCTAssertNotNil(task.due)
    XCTAssertEqual(task.effort, 30)
}
```

---

## Integration Tests

### DataManagerTests.swift

Tests end-to-end workflows.

**Coverage**:
- Initialization and setup
- Task CRUD through DataManager
- File watching and reload
- Conflict detection
- Save/load cycles
- First-run experience

**Example Tests**:

```swift
// Test initialization
func testInitialization() async throws {
    let manager = DataManager()
    let directory = createTempDirectory()

    try await manager.initialize(rootDirectory: directory)

    XCTAssertTrue(manager.isInitialized)
    XCTAssertNotNil(manager.taskStore)
    XCTAssertNotNil(manager.boardStore)
}

// Test create and save
func testCreateAndSave() async throws {
    let manager = DataManager()
    try await manager.initialize(rootDirectory: testDirectory)

    let task = manager.createTask(
        title: "Test Task",
        type: .task,
        status: .inbox
    )

    try await manager.save()

    // Reload
    try await manager.reload()

    let loaded = manager.taskStore.task(withId: task.id)
    XCTAssertNotNil(loaded)
    XCTAssertEqual(loaded?.title, "Test Task")
}

// Test file watching
func testFileWatching() async throws {
    let manager = DataManager()
    try await manager.initialize(rootDirectory: testDirectory)

    let task = manager.createTask(title: "Watch Me")
    try await manager.save()

    // Modify file externally
    let url = manager.fileIO.url(for: task)
    var markdown = try String(contentsOf: url)
    markdown = markdown.replacingOccurrences(of: "Watch Me", with: "Modified")
    try markdown.write(to: url, atomically: true, encoding: .utf8)

    // Wait for file watcher
    try await Task.sleep(nanoseconds: 300_000_000) // 300ms

    let reloaded = manager.taskStore.task(withId: task.id)
    XCTAssertEqual(reloaded?.title, "Modified")
}
```

---

## Manual Testing

### Manual Test Plan

**Test Case 1: Quick Capture**
1. Press ⌘⇧Space to open Quick Capture
2. Type: `Call John @phone #Website !high tomorrow //30m`
3. Press Return
4. Verify task created with all metadata
5. Verify task appears in Inbox perspective
6. Verify task has due date of tomorrow

**Test Case 2: Board Canvas**
1. Create new custom board (Freeform layout)
2. Add 50+ tasks to board
3. Drag tasks around canvas
4. Zoom in/out with ⌘+/-
5. Pan with Option+drag
6. Lasso select multiple tasks
7. Verify 60 FPS performance (no lag)

**Test Case 3: External Edit**
1. Open data directory in Finder
2. Navigate to tasks/active/YYYY/MM/
3. Open task file in VS Code
4. Edit title and save
5. Return to StickyToDo
6. Verify task updated automatically

**Test Case 4: Weekly Review**
1. Create tasks in Inbox (10+)
2. Open Weekly Review
3. Process Inbox to zero
4. Review Next Actions
5. Check Waiting For items
6. Complete review workflow

**Test Case 5: Recurring Tasks**
1. Create recurring task (daily)
2. Complete task
3. Verify next instance created
4. Check recurrence pattern preserved

### Testing Checklist

**Core Features**:
- [ ] Quick Capture with natural language
- [ ] All 7 perspectives display correctly
- [ ] Custom perspectives can be created
- [ ] Boards auto-create for projects/contexts
- [ ] Three board layouts work (Freeform, Kanban, Grid)
- [ ] Task inspector edits all metadata
- [ ] Recurring tasks generate correctly
- [ ] Subtasks display in hierarchy
- [ ] Search finds all matches
- [ ] Export works for all formats

**Performance**:
- [ ] App launches in < 2 seconds (500 tasks)
- [ ] Canvas maintains 60 FPS with 100+ tasks
- [ ] Search returns results in < 200ms
- [ ] Auto-save doesn't cause UI lag

**Data Integrity**:
- [ ] No data loss on force quit
- [ ] External edits reload correctly
- [ ] Conflicts detected and resolved
- [ ] All YAML validates correctly
- [ ] No duplicate UUIDs created

---

## Performance Testing

### Load Testing

**Create Large Dataset**:
```swift
func testPerformanceWithLargeDa taset() throws {
    measure {
        // Create 1000 tasks
        for i in 1...1000 {
            let task = Task(title: "Task \(i)")
            store.add(task)
        }

        // Search
        _ = store.search("Task")

        // Filter
        let filter = Filter(status: [.nextAction])
        _ = store.tasks(matching: filter)
    }
}
```

**Benchmarks**:
- Task creation: < 0.1ms per task
- Search 1000 tasks: < 200ms
- Filter 1000 tasks: < 50ms
- Load 1000 tasks from disk: < 1 second

### Memory Testing

**Monitor Memory Usage**:
```swift
func testMemoryUsage() {
    measure(metrics: [XCTMemoryMetric()]) {
        // Create 1000 tasks
        for i in 1...1000 {
            store.add(Task(title: "Task \(i)"))
        }
    }

    // Should be < 50 MB for 1000 tasks
}
```

---

## Writing New Tests

### Test Template

```swift
// MARK: - [Feature Name] Tests

func test[FeatureName]_[Scenario]_[ExpectedOutcome]() {
    // Arrange - Set up test data
    let task = Task(title: "Test")

    // Act - Perform the operation
    task.complete()

    // Assert - Verify expectations
    XCTAssertEqual(task.status, .completed)
    XCTAssertNotNil(task.completed)
}
```

### Best Practices

**Naming**:
- Use descriptive names: `testTaskCompletion_UpdatesStatusAndTimestamp`
- Include scenario: `testFilterMatching_WithMultipleCriteria_ReturnsCorrectTasks`

**Arrange-Act-Assert**:
```swift
// Good
func testTaskFlagging() {
    // Arrange
    var task = Task(title: "Test")

    // Act
    task.flagged = true

    // Assert
    XCTAssertTrue(task.flagged)
}

// Avoid - unclear structure
func testTaskFlagging() {
    var task = Task(title: "Test")
    task.flagged = true
    XCTAssertTrue(task.flagged)
}
```

**Isolation**:
```swift
// Good - each test is independent
func testAdd() {
    store.add(Task(title: "1"))
    XCTAssertEqual(store.taskCount, 1)
}

func testDelete() {
    let task = Task(title: "1")
    store.add(task)
    store.delete(task)
    XCTAssertEqual(store.taskCount, 0)
}

// Avoid - tests depend on execution order
func testAdd() {
    store.add(Task(title: "1"))
}

func testCount() {
    XCTAssertEqual(store.taskCount, 1) // Depends on previous test!
}
```

---

## Test Coverage

### Current Coverage (v1.0)

| Module | Coverage | Target |
|--------|----------|--------|
| **Models** | 92% | 90%+ |
| **Data Layer** | 85% | 85%+ |
| **Stores** | 88% | 80%+ |
| **Parsers** | 90% | 85%+ |
| **Views** | 45% | 60%+ |
| **Overall** | 80% | 80%+ |

### Viewing Coverage

**In Xcode**:
1. Run tests with coverage (⌘⌥U)
2. Open Reports Navigator (⌘9)
3. Select latest test run
4. Click Coverage tab
5. Expand modules to see file-level coverage

**Command Line**:
```bash
# Generate coverage report
xcodebuild test \
  -project StickyToDo.xcodeproj \
  -scheme StickyToDo \
  -enableCodeCoverage YES

# View coverage
xcrun xccov view --report \
  ~/Library/Developer/Xcode/DerivedData/.../coverage.xccovarchive
```

---

## Continuous Integration

### GitHub Actions (Example)

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.0.app

      - name: Run Tests
        run: |
          xcodebuild test \
            -project StickyToDo.xcodeproj \
            -scheme StickyToDo \
            -destination 'platform=macOS' \
            -enableCodeCoverage YES

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
```

---

## Troubleshooting

### Common Issues

**Tests Fail After Clean**:
```bash
# Solution: Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

**File I/O Tests Fail**:
```swift
// Check permissions on temp directory
XCTAssertTrue(FileManager.default.isWritableFile(atPath: tempDir.path))
```

**Async Tests Timeout**:
```swift
// Increase timeout for async tests
func testAsyncOperation() async throws {
    let expectation = XCTestExpectation(description: "Async op")
    // ...
    wait(for: [expectation], timeout: 10.0) // Increase from 5.0
}
```

---

## Additional Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [WWDC Testing Videos](https://developer.apple.com/videos/frameworks/testing)
- [Test-Driven Development by Example](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)

---

**Version**: 1.0.0
**Last Updated**: 2025-11-18
**Test Count**: 150+ unit tests, 25+ integration tests
