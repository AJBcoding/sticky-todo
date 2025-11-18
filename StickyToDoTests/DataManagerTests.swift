//
//  DataManagerTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for DataManager integration.
//

import XCTest
@testable import StickyToDo

final class DataManagerTests: XCTestCase {

    var tempDirectory: URL!
    var dataManager: DataManager!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DataManagerTests-\(UUID().uuidString)")

        // Create a new instance for testing (not using singleton)
        dataManager = DataManager()
    }

    override func tearDown() async throws {
        dataManager?.cleanup()
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - Initialization Tests

    func testInitialization() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        XCTAssertTrue(dataManager.isInitialized)
        XCTAssertFalse(dataManager.isLoading)
        XCTAssertNil(dataManager.error)
        XCTAssertNotNil(dataManager.taskStore)
        XCTAssertNotNil(dataManager.boardStore)
    }

    func testInitializationCreatesDirectoryStructure() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("tasks/active").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("tasks/archive").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("boards").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("config").path))
    }

    func testInitializationLoadsExistingData() async throws {
        // Create some test data first
        let fileIO = MarkdownFileIO(rootDirectory: tempDirectory)
        try fileIO.ensureDirectoryStructure()

        let task = Task(title: "Existing Task", status: .inbox)
        try fileIO.writeTask(task)

        let board = Board(id: "existing-board", type: .custom)
        try fileIO.writeBoard(board)

        // Now initialize DataManager
        try await dataManager.initialize(rootDirectory: tempDirectory)

        // Should have loaded existing data
        XCTAssertGreaterThan(dataManager.taskStore.taskCount, 0)
        XCTAssertGreaterThan(dataManager.boardStore.boardCount, 0)

        let loadedTask = dataManager.taskStore.task(withID: task.id)
        XCTAssertNotNil(loadedTask)
        XCTAssertEqual(loadedTask?.title, "Existing Task")
    }

    func testDoubleInitialization() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)
        XCTAssertTrue(dataManager.isInitialized)

        // Second initialization should be ignored
        try await dataManager.initialize(rootDirectory: tempDirectory)
        XCTAssertTrue(dataManager.isInitialized)
    }

    // MARK: - Convenience Method Tests

    func testCreateTask() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        let task = dataManager.createTask(title: "New Task", notes: "Task notes", status: .inbox)

        XCTAssertEqual(task.title, "New Task")
        XCTAssertEqual(task.notes, "Task notes")
        XCTAssertEqual(task.status, .inbox)

        // Should be added to store
        let expectation = XCTestExpectation(description: "Task added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertNotNil(dataManager.taskStore.task(withID: task.id))
    }

    func testUpdateTask() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        var task = dataManager.createTask(title: "Update Test", status: .inbox)

        let expectation1 = XCTestExpectation(description: "Task created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 2.0)

        task.status = .nextAction
        task.title = "Updated Title"
        dataManager.updateTask(task)

        let expectation2 = XCTestExpectation(description: "Task updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        await fulfillment(of: [expectation2], timeout: 2.0)

        let updated = dataManager.taskStore.task(withID: task.id)
        XCTAssertEqual(updated?.title, "Updated Title")
        XCTAssertEqual(updated?.status, .nextAction)
    }

    func testDeleteTask() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        let task = dataManager.createTask(title: "Delete Test", status: .inbox)

        let expectation1 = XCTestExpectation(description: "Task created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 2.0)

        XCTAssertNotNil(dataManager.taskStore.task(withID: task.id))

        dataManager.deleteTask(task)

        let expectation2 = XCTestExpectation(description: "Task deleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        await fulfillment(of: [expectation2], timeout: 2.0)

        XCTAssertNil(dataManager.taskStore.task(withID: task.id))
    }

    func testCreateBoard() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        let board = dataManager.createBoard(id: "test-board", type: .custom, layout: .freeform)

        XCTAssertEqual(board.id, "test-board")
        XCTAssertEqual(board.type, .custom)
        XCTAssertEqual(board.layout, .freeform)

        let expectation = XCTestExpectation(description: "Board created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertNotNil(dataManager.boardStore.board(withID: "test-board"))
    }

    // MARK: - Save Before Quit Tests

    func testSaveBeforeQuit() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        let task = dataManager.createTask(title: "Save Test", status: .inbox)

        // Save immediately without debounce
        try dataManager.saveBeforeQuit()

        // Verify file exists
        let fileIO = MarkdownFileIO(rootDirectory: tempDirectory)
        let url = fileIO.taskURL(for: task)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: - Statistics Tests

    func testStatistics() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        // Create test data
        _ = dataManager.createTask(title: "Inbox Task", status: .inbox)
        _ = dataManager.createTask(title: "Next Action", status: .nextAction)
        _ = dataManager.createTask(title: "Completed", status: .completed)
        _ = dataManager.createTask(title: "Project Task", status: .nextAction, project: "TestProject")

        let expectation = XCTestExpectation(description: "Tasks created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)

        let stats = dataManager.statistics

        XCTAssertEqual(stats.totalTasks, 4)
        XCTAssertEqual(stats.activeTasks, 3)
        XCTAssertEqual(stats.completedTasks, 1)
        XCTAssertEqual(stats.inboxTasks, 1)
        XCTAssertGreaterThan(stats.totalBoards, 0) // Should have built-in boards
    }

    // MARK: - First Run Setup Tests

    func testFirstRunSetupWithNoSampleData() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        let initialTaskCount = dataManager.taskStore.taskCount

        dataManager.performFirstRunSetup(createSampleData: false)

        let expectation = XCTestExpectation(description: "Setup complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)

        // Should not have created sample tasks
        XCTAssertEqual(dataManager.taskStore.taskCount, initialTaskCount)
    }

    func testFirstRunSetupWithSampleData() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        XCTAssertEqual(dataManager.taskStore.taskCount, 0)

        dataManager.performFirstRunSetup(createSampleData: true)

        let expectation = XCTestExpectation(description: "Sample data created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)

        // Should have created sample tasks
        XCTAssertGreaterThan(dataManager.taskStore.taskCount, 0)
    }

    func testFirstRunSetupSkipsIfDataExists() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        // Create a task first
        _ = dataManager.createTask(title: "Existing Task", status: .inbox)

        let expectation1 = XCTestExpectation(description: "Task created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 2.0)

        let existingCount = dataManager.taskStore.taskCount

        // First run setup should be skipped
        dataManager.performFirstRunSetup(createSampleData: true)

        let expectation2 = XCTestExpectation(description: "Setup attempted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        await fulfillment(of: [expectation2], timeout: 2.0)

        // Task count should be unchanged
        XCTAssertEqual(dataManager.taskStore.taskCount, existingCount)
    }

    // MARK: - Cleanup Tests

    func testCleanup() async throws {
        try await dataManager.initialize(rootDirectory: tempDirectory)

        let task = dataManager.createTask(title: "Cleanup Test", status: .inbox)

        // Cleanup should save pending changes
        dataManager.cleanup()

        // Wait a bit for cleanup to complete
        let expectation = XCTestExpectation(description: "Cleanup complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)

        // Verify file was saved
        let fileIO = MarkdownFileIO(rootDirectory: tempDirectory)
        let url = fileIO.taskURL(for: task)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: - Error Handling Tests

    func testInitializationWithInvalidDirectory() async throws {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/that/should/not/exist")

        do {
            try await dataManager.initialize(rootDirectory: invalidURL)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is DataManagerError)
        }
    }

    // MARK: - Logging Tests

    func testLogging() async throws {
        var logMessages: [String] = []

        dataManager.setLogger { message in
            logMessages.append(message)
        }

        try await dataManager.initialize(rootDirectory: tempDirectory)

        // Should have logged initialization
        XCTAssertTrue(logMessages.contains { $0.contains("Initializing") })
        XCTAssertTrue(logMessages.contains { $0.contains("initialized successfully") })
    }

    // MARK: - Configuration Tests

    func testLoggingConfiguration() async throws {
        dataManager.enableLogging = false

        var logMessages: [String] = []
        dataManager.setLogger { message in
            logMessages.append(message)
        }

        try await dataManager.initialize(rootDirectory: tempDirectory)

        // Should not have logged when logging is disabled
        XCTAssertTrue(logMessages.isEmpty)
    }
}
