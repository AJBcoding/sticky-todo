//
//  IntegrationTests.swift
//  StickyToDoTests
//
//  Created on 2025-11-18.
//  Copyright © 2025 Sticky ToDo. All rights reserved.
//

import XCTest
@testable import StickyToDoCore

/// Integration tests for end-to-end functionality
class IntegrationTests: XCTestCase {

    var tempDirectory: URL!
    var taskStore: TaskStore!
    var boardStore: BoardStore!
    var fileIO: MarkdownFileIO!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create temporary directory for tests
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Initialize stores
        taskStore = TaskStore()
        boardStore = BoardStore()
        fileIO = MarkdownFileIO()

        // Set storage location
        fileIO.setStorageDirectory(tempDirectory)
    }

    override func tearDownWithError() throws {
        // Clean up temp directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }

        taskStore = nil
        boardStore = nil
        fileIO = nil
        tempDirectory = nil

        try super.tearDownWithError()
    }

    // MARK: - End-to-End Task Management

    func testCreateEditCompleteDeleteTask() throws {
        let performanceMonitor = PerformanceMonitor.shared

        // Create task
        performanceMonitor.startOperation("createTask")
        let task = Task(
            title: "Integration Test Task",
            notes: "This is a test task",
            status: .todo,
            priority: .high
        )
        taskStore.add(task)
        performanceMonitor.endOperation("createTask")

        XCTAssertEqual(taskStore.tasks.count, 1)
        XCTAssertEqual(taskStore.tasks.first?.title, "Integration Test Task")

        // Edit task
        performanceMonitor.startOperation("editTask")
        var editedTask = task
        editedTask.title = "Updated Task Title"
        editedTask.notes = "Updated notes"
        taskStore.update(editedTask)
        performanceMonitor.endOperation("editTask")

        XCTAssertEqual(taskStore.tasks.first?.title, "Updated Task Title")

        // Complete task
        performanceMonitor.startOperation("completeTask")
        var completedTask = editedTask
        completedTask.status = .done
        taskStore.update(completedTask)
        performanceMonitor.endOperation("completeTask")

        XCTAssertEqual(taskStore.tasks.first?.status, .done)

        // Delete task
        performanceMonitor.startOperation("deleteTask")
        taskStore.delete(completedTask.id)
        performanceMonitor.endOperation("deleteTask")

        XCTAssertEqual(taskStore.tasks.count, 0)
    }

    // MARK: - Large Dataset Performance

    func testPerformanceWithLargDataset() throws {
        let taskCount = 1000
        let performanceMonitor = PerformanceMonitor.shared

        // Create 1000 tasks
        performanceMonitor.startOperation("create1000Tasks")
        for i in 1...taskCount {
            let task = Task(
                title: "Task \(i)",
                notes: "Test task number \(i)",
                status: i % 3 == 0 ? .done : .todo,
                priority: Priority.allCases.randomElement() ?? .medium
            )
            taskStore.add(task)
        }
        performanceMonitor.endOperation("create1000Tasks")

        XCTAssertEqual(taskStore.tasks.count, taskCount)

        // Filter tasks
        performanceMonitor.startOperation("filterTasks")
        let completedTasks = taskStore.tasks.filter { $0.status == .done }
        performanceMonitor.endOperation("filterTasks")

        XCTAssertGreaterThan(completedTasks.count, 0)

        // Search tasks
        performanceMonitor.startOperation("searchTasks")
        let searchResults = taskStore.tasks.filter { $0.title.contains("100") }
        performanceMonitor.endOperation("searchTasks")

        XCTAssertGreaterThan(searchResults.count, 0)

        // Sort tasks
        performanceMonitor.startOperation("sortTasks")
        let sortedTasks = taskStore.tasks.sorted { $0.title < $1.title }
        performanceMonitor.endOperation("sortTasks")

        XCTAssertEqual(sortedTasks.count, taskCount)

        // Print performance stats
        if let stats = performanceMonitor.getOperationStats("create1000Tasks") {
            print("Created \(taskCount) tasks in \(String(format: "%.3f", stats.average))s")
        }
    }

    // MARK: - File I/O Integration

    func testFileReadWriteCycle() throws {
        // Create tasks
        let task1 = Task(title: "Task 1", status: .todo, priority: .high)
        let task2 = Task(title: "Task 2", status: .done, priority: .low)

        taskStore.add(task1)
        taskStore.add(task2)

        // Write to files
        let writeExpectation = expectation(description: "Write tasks")
        fileIO.writeTasksToFiles(taskStore.tasks) { result in
            switch result {
            case .success:
                writeExpectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to write tasks: \(error)")
            }
        }

        wait(for: [writeExpectation], timeout: 5.0)

        // Clear task store
        taskStore.tasks.removeAll()
        XCTAssertEqual(taskStore.tasks.count, 0)

        // Read from files
        let readExpectation = expectation(description: "Read tasks")
        fileIO.loadTasksFromDirectory(tempDirectory) { result in
            switch result {
            case .success(let tasks):
                for task in tasks {
                    self.taskStore.add(task)
                }
                readExpectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to read tasks: \(error)")
            }
        }

        wait(for: [readExpectation], timeout: 5.0)

        // Verify tasks were restored
        XCTAssertEqual(taskStore.tasks.count, 2)
        XCTAssertTrue(taskStore.tasks.contains { $0.title == "Task 1" })
        XCTAssertTrue(taskStore.tasks.contains { $0.title == "Task 2" })
    }

    // MARK: - Board Integration

    func testBoardOperations() throws {
        // Create a board
        let board = Board(
            id: UUID().uuidString,
            title: "Test Board",
            type: .canvas
        )
        boardStore.add(board)

        XCTAssertEqual(boardStore.boards.count, 1)

        // Create tasks on the board
        for i in 1...10 {
            let task = Task(
                title: "Board Task \(i)",
                status: .todo,
                priority: .medium,
                boardID: board.id,
                position: Position(x: Double(i * 50), y: Double(i * 50))
            )
            taskStore.add(task)
        }

        // Get tasks for this board
        let boardTasks = taskStore.tasks.filter { $0.boardID == board.id }
        XCTAssertEqual(boardTasks.count, 10)

        // Update task position
        if var task = boardTasks.first {
            task.position = Position(x: 200, y: 200)
            taskStore.update(task)

            let updatedTask = taskStore.tasks.first { $0.id == task.id }
            XCTAssertEqual(updatedTask?.position?.x, 200)
            XCTAssertEqual(updatedTask?.position?.y, 200)
        }

        // Delete board
        boardStore.delete(board.id)
        XCTAssertEqual(boardStore.boards.count, 0)
    }

    // MARK: - Import/Export Integration

    func testImportExportRoundTrip() throws {
        // Create diverse task set
        let tasks = [
            Task(title: "High Priority Task", status: .todo, priority: .high, dueDate: Date()),
            Task(title: "Completed Task", status: .done, priority: .medium),
            Task(title: "Task with Context", status: .inProgress, priority: .low, context: "@work"),
            Task(title: "Someday Task", status: .todo, priority: .low, type: .someday)
        ]

        tasks.forEach { taskStore.add($0) }

        // Export to JSON
        let exportManager = ExportManager()
        let exportExpectation = expectation(description: "Export tasks")
        var exportedURL: URL?

        exportManager.export(tasks: taskStore.tasks, format: .json) { result in
            switch result {
            case .success(let url):
                exportedURL = url
                exportExpectation.fulfill()
            case .failure(let error):
                XCTFail("Export failed: \(error)")
            }
        }

        wait(for: [exportExpectation], timeout: 5.0)

        guard let exportURL = exportedURL else {
            XCTFail("No export URL")
            return
        }

        // Clear tasks
        taskStore.tasks.removeAll()

        // Import from JSON
        let importManager = ImportManager()
        let importExpectation = expectation(description: "Import tasks")

        importManager.import(from: exportURL, format: .json) { result in
            switch result {
            case .success(let importedTasks):
                importedTasks.forEach { self.taskStore.add($0) }
                importExpectation.fulfill()
            case .failure(let error):
                XCTFail("Import failed: \(error)")
            }
        }

        wait(for: [importExpectation], timeout: 5.0)

        // Verify
        XCTAssertEqual(taskStore.tasks.count, 4)
        XCTAssertTrue(taskStore.tasks.contains { $0.title == "High Priority Task" })
        XCTAssertTrue(taskStore.tasks.contains { $0.title == "Task with Context" })
    }

    // MARK: - Perspective Filtering

    func testPerspectiveFiltering() throws {
        // Create tasks for different perspectives
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!

        let tasks = [
            Task(title: "Inbox Task", status: .todo, priority: .medium),
            Task(title: "Today Task", status: .todo, priority: .high, dueDate: today),
            Task(title: "Tomorrow Task", status: .todo, priority: .medium, dueDate: tomorrow),
            Task(title: "Next Week Task", status: .todo, priority: .low, dueDate: nextWeek),
            Task(title: "Completed Task", status: .done, priority: .medium),
            Task(title: "Someday Task", status: .todo, priority: .low, type: .someday)
        ]

        tasks.forEach { taskStore.add($0) }

        // Test Inbox filter
        let inboxFilter = Filter.perspective(.inbox)
        let inboxTasks = taskStore.tasks.filter { inboxFilter.matches(task: $0) }
        XCTAssertGreaterThan(inboxTasks.count, 0)

        // Test Today filter
        let todayFilter = Filter.perspective(.today)
        let todayTasks = taskStore.tasks.filter { todayFilter.matches(task: $0) }
        XCTAssertGreaterThan(todayTasks.count, 0)

        // Test Completed filter
        let completedFilter = Filter.perspective(.completed)
        let completedTasks = taskStore.tasks.filter { completedFilter.matches(task: $0) }
        XCTAssertEqual(completedTasks.count, 1)

        // Test Someday filter
        let somedayFilter = Filter.perspective(.someday)
        let somedayTasks = taskStore.tasks.filter { somedayFilter.matches(task: $0) }
        XCTAssertEqual(somedayTasks.count, 1)
    }

    // MARK: - Concurrency Tests

    func testConcurrentOperations() throws {
        let operationCount = 100
        let expectation = self.expectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = operationCount

        DispatchQueue.concurrentPerform(iterations: operationCount) { index in
            let task = Task(
                title: "Concurrent Task \(index)",
                status: .todo,
                priority: .medium
            )

            DispatchQueue.main.async {
                self.taskStore.add(task)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)

        // Verify all tasks were added
        XCTAssertEqual(taskStore.tasks.count, operationCount)
    }

    // MARK: - State Persistence

    func testWindowStatePersistence() throws {
        let stateManager = WindowStateManager.shared

        // Set various state properties
        stateManager.inspectorIsOpen = true
        stateManager.sidebarWidth = 250
        stateManager.viewMode = .board
        stateManager.selectedPerspective = "today"
        stateManager.zoomLevel = 1.5

        // Save state
        stateManager.saveState()

        // Reset to defaults
        stateManager.inspectorIsOpen = false
        stateManager.sidebarWidth = 200
        stateManager.viewMode = .list
        stateManager.selectedPerspective = "inbox"
        stateManager.zoomLevel = 1.0

        // Reload state from UserDefaults
        let newStateManager = WindowStateManager.shared

        // Verify state was restored
        XCTAssertTrue(newStateManager.inspectorIsOpen)
        XCTAssertEqual(newStateManager.sidebarWidth, 250, accuracy: 0.1)
        XCTAssertEqual(newStateManager.viewMode, .board)
        XCTAssertEqual(newStateManager.selectedPerspective, "today")
        XCTAssertEqual(newStateManager.zoomLevel, 1.5, accuracy: 0.01)

        // Clean up
        stateManager.resetToDefaults()
    }

    // MARK: - Error Handling

    func testErrorHandling() throws {
        // Test invalid file path
        let invalidURL = URL(fileURLWithPath: "/invalid/path/that/does/not/exist")

        let expectation = self.expectation(description: "Error handling")

        fileIO.loadTasksFromDirectory(invalidURL) { result in
            switch result {
            case .success:
                XCTFail("Should have failed with invalid path")
            case .failure:
                // Expected failure
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Performance Benchmarks

    func testPerformanceBenchmarks() throws {
        // This test measures various operations for performance monitoring
        let performanceMonitor = PerformanceMonitor.shared
        performanceMonitor.reset()

        measure {
            // Create tasks
            for i in 1...100 {
                let task = Task(
                    title: "Benchmark Task \(i)",
                    status: .todo,
                    priority: .medium
                )
                taskStore.add(task)
            }

            // Filter tasks
            _ = taskStore.tasks.filter { $0.status == .todo }

            // Update tasks
            for task in taskStore.tasks {
                var updated = task
                updated.title = "Updated \(task.title)"
                taskStore.update(updated)
            }

            // Delete tasks
            for task in taskStore.tasks {
                taskStore.delete(task.id)
            }
        }
    }
}

// MARK: - Helper Extensions

extension Filter {
    func matches(task: Task) -> Bool {
        // Simplified filter matching for tests
        switch self {
        case .perspective(let perspective):
            switch perspective {
            case .inbox:
                return task.status != .done && task.type != .someday
            case .today:
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            case .completed:
                return task.status == .done
            case .someday:
                return task.type == .someday
            default:
                return true
            }
        default:
            return true
        }
    }
}
