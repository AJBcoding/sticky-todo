//
//  MarkdownFileIOTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for markdown file I/O operations.
//

import XCTest
@testable import StickyToDo

final class MarkdownFileIOTests: XCTestCase {

    var tempDirectory: URL!
    var fileIO: MarkdownFileIO!

    override func setUp() async throws {
        // Create a temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StickyToDoTests-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        fileIO = MarkdownFileIO(rootDirectory: tempDirectory)
    }

    override func tearDown() async throws {
        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }

    // MARK: - Directory Structure Tests

    func testEnsureDirectoryStructure() throws {
        try fileIO.ensureDirectoryStructure()

        // Verify all required directories exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("tasks/active").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("tasks/archive").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("boards").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("config").path))
    }

    func testDirectoryHelpers() throws {
        try fileIO.ensureDirectoryStructure()

        XCTAssertEqual(fileIO.tasksDirectory.path, tempDirectory.appendingPathComponent("tasks").path)
        XCTAssertEqual(fileIO.activeTasksDirectory.path, tempDirectory.appendingPathComponent("tasks/active").path)
        XCTAssertEqual(fileIO.archivedTasksDirectory.path, tempDirectory.appendingPathComponent("tasks/archive").path)
        XCTAssertEqual(fileIO.boardsDirectory.path, tempDirectory.appendingPathComponent("boards").path)
        XCTAssertEqual(fileIO.configDirectory.path, tempDirectory.appendingPathComponent("config").path)
    }

    // MARK: - Task I/O Tests

    func testWriteAndReadTask() throws {
        try fileIO.ensureDirectoryStructure()

        let task = Task(
            title: "Test Task",
            notes: "This is a test task.",
            status: .nextAction,
            project: "TestProject",
            context: "@office",
            priority: .high
        )

        // Write task
        try fileIO.writeTask(task)

        // Read task back
        let url = fileIO.taskURL(for: task)
        let readTask = try fileIO.readTask(from: url)

        XCTAssertNotNil(readTask)
        XCTAssertEqual(readTask?.id, task.id)
        XCTAssertEqual(readTask?.title, task.title)
        XCTAssertEqual(readTask?.notes, task.notes)
        XCTAssertEqual(readTask?.status, task.status)
        XCTAssertEqual(readTask?.project, task.project)
        XCTAssertEqual(readTask?.context, task.context)
        XCTAssertEqual(readTask?.priority, task.priority)
    }

    func testWriteTaskCreatesDirectories() throws {
        // Don't create directory structure first
        let task = Task(title: "Auto-create directories", status: .nextAction)

        // Write should create directories automatically
        try fileIO.writeTask(task)

        let url = fileIO.taskURL(for: task)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testTaskURL() throws {
        let calendar = Calendar.current
        let created = Date()
        let year = calendar.component(.year, from: created)
        let month = calendar.component(.month, from: created)
        let monthString = String(format: "%02d", month)

        let activeTask = Task(title: "Active Task", status: .nextAction, created: created)
        let activeURL = fileIO.taskURL(for: activeTask)

        XCTAssertTrue(activeURL.path.contains("tasks/active/\(year)/\(monthString)"))
        XCTAssertTrue(activeURL.path.hasSuffix(".md"))

        let completedTask = Task(title: "Completed Task", status: .completed, created: created)
        let archiveURL = fileIO.taskURL(for: completedTask)

        XCTAssertTrue(archiveURL.path.contains("tasks/archive/\(year)/\(monthString)"))
    }

    func testReadNonexistentTask() throws {
        let url = tempDirectory.appendingPathComponent("tasks/nonexistent.md")

        XCTAssertThrowsError(try fileIO.readTask(from: url)) { error in
            XCTAssertTrue(error is MarkdownFileError)
        }
    }

    func testDeleteTask() throws {
        try fileIO.ensureDirectoryStructure()

        let task = Task(title: "Delete Me", status: .nextAction)
        try fileIO.writeTask(task)

        let url = fileIO.taskURL(for: task)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        try fileIO.deleteTask(task)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testMoveTaskFile() throws {
        try fileIO.ensureDirectoryStructure()

        var task = Task(title: "Move Me", status: .nextAction)
        try fileIO.writeTask(task)

        let fromURL = fileIO.taskURL(for: task)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fromURL.path))

        // Complete the task (changes its path to archive)
        task.status = .completed
        let toURL = fileIO.taskURL(for: task)

        try fileIO.moveTaskFile(for: task, from: fromURL, to: toURL)

        XCTAssertFalse(FileManager.default.fileExists(atPath: fromURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: toURL.path))
    }

    // MARK: - Board I/O Tests

    func testWriteAndReadBoard() throws {
        try fileIO.ensureDirectoryStructure()

        let board = Board(
            id: "test-board",
            type: .project,
            layout: .kanban,
            filter: Filter(project: "TestProject"),
            columns: ["Todo", "In Progress", "Done"],
            title: "Test Board",
            notes: "Board notes here."
        )

        // Write board
        try fileIO.writeBoard(board)

        // Read board back
        let url = fileIO.boardURL(for: board)
        let readBoard = try fileIO.readBoard(from: url)

        XCTAssertNotNil(readBoard)
        XCTAssertEqual(readBoard?.id, board.id)
        XCTAssertEqual(readBoard?.type, board.type)
        XCTAssertEqual(readBoard?.layout, board.layout)
        XCTAssertEqual(readBoard?.columns, board.columns)
        XCTAssertEqual(readBoard?.title, board.title)
        XCTAssertEqual(readBoard?.notes, board.notes)
    }

    func testBoardURL() {
        let board = Board(id: "my-board", type: .custom)
        let url = fileIO.boardURL(for: board)

        XCTAssertEqual(url.lastPathComponent, "my-board.md")
        XCTAssertTrue(url.path.contains("boards"))
    }

    func testDeleteBoard() throws {
        try fileIO.ensureDirectoryStructure()

        let board = Board(id: "delete-me", type: .custom)
        try fileIO.writeBoard(board)

        let url = fileIO.boardURL(for: board)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        try fileIO.deleteBoard(board)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: - Bulk Operations Tests

    func testLoadAllTasks() throws {
        try fileIO.ensureDirectoryStructure()

        // Create several tasks
        let tasks = [
            Task(title: "Task 1", status: .nextAction),
            Task(title: "Task 2", status: .inbox),
            Task(title: "Task 3", status: .waiting),
            Task(title: "Task 4", status: .completed),
            Task(title: "Task 5", status: .someday)
        ]

        for task in tasks {
            try fileIO.writeTask(task)
        }

        // Load all tasks
        let loadedTasks = try fileIO.loadAllTasks()

        XCTAssertEqual(loadedTasks.count, tasks.count)

        // Verify all tasks were loaded
        let loadedIDs = Set(loadedTasks.map { $0.id })
        for task in tasks {
            XCTAssertTrue(loadedIDs.contains(task.id))
        }
    }

    func testLoadAllTasksFromActiveAndArchive() throws {
        try fileIO.ensureDirectoryStructure()

        // Create active tasks
        let activeTasks = [
            Task(title: "Active 1", status: .nextAction),
            Task(title: "Active 2", status: .inbox)
        ]

        for task in activeTasks {
            try fileIO.writeTask(task)
        }

        // Create archived tasks
        let archivedTasks = [
            Task(title: "Archived 1", status: .completed),
            Task(title: "Archived 2", status: .completed)
        ]

        for task in archivedTasks {
            try fileIO.writeTask(task)
        }

        // Load all
        let loadedTasks = try fileIO.loadAllTasks()

        XCTAssertEqual(loadedTasks.count, activeTasks.count + archivedTasks.count)
    }

    func testLoadAllBoards() throws {
        try fileIO.ensureDirectoryStructure()

        // Create several boards
        let boards = [
            Board(id: "board-1", type: .custom),
            Board(id: "board-2", type: .project),
            Board(id: "board-3", type: .context)
        ]

        for board in boards {
            try fileIO.writeBoard(board)
        }

        // Load all boards
        let loadedBoards = try fileIO.loadAllBoards()

        XCTAssertEqual(loadedBoards.count, boards.count)

        // Verify all boards were loaded
        let loadedIDs = Set(loadedBoards.map { $0.id })
        for board in boards {
            XCTAssertTrue(loadedIDs.contains(board.id))
        }
    }

    func testLoadAllWithNoFiles() throws {
        try fileIO.ensureDirectoryStructure()

        let tasks = try fileIO.loadAllTasks()
        XCTAssertEqual(tasks.count, 0)

        let boards = try fileIO.loadAllBoards()
        XCTAssertEqual(boards.count, 0)
    }

    func testLoadAllSkipsCorruptedFiles() throws {
        try fileIO.ensureDirectoryStructure()

        // Create a valid task
        let validTask = Task(title: "Valid Task", status: .inbox)
        try fileIO.writeTask(validTask)

        // Create a corrupted file
        let corruptedURL = tempDirectory
            .appendingPathComponent("tasks/active/2025/01/corrupted.md")

        try FileManager.default.createDirectory(
            at: corruptedURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "This is not valid task markdown".write(to: corruptedURL, atomically: true, encoding: .utf8)

        // Load all tasks - should load valid one and skip corrupted
        let loadedTasks = try fileIO.loadAllTasks()

        // Should have loaded the valid task
        XCTAssertGreaterThanOrEqual(loadedTasks.count, 1)
        XCTAssertTrue(loadedTasks.contains { $0.id == validTask.id })
    }

    // MARK: - Error Handling Tests

    func testFileNotFoundError() {
        let url = tempDirectory.appendingPathComponent("nonexistent.md")

        XCTAssertThrowsError(try fileIO.readTask(from: url)) { error in
            if case let MarkdownFileError.fileNotFound(foundURL) = error {
                XCTAssertEqual(foundURL.path, url.path)
            } else {
                XCTFail("Expected fileNotFound error")
            }
        }
    }

    func testInvalidPathHandling() {
        let invalidURL = URL(fileURLWithPath: "/")

        XCTAssertThrowsError(try fileIO.readTask(from: invalidURL)) { error in
            XCTAssertTrue(error is MarkdownFileError)
        }
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentWrites() throws {
        try fileIO.ensureDirectoryStructure()

        let expectation = XCTestExpectation(description: "Concurrent writes complete")
        let queue = DispatchQueue(label: "test-concurrent", attributes: .concurrent)
        var errors: [Error] = []
        let errorLock = NSLock()

        let tasks = (0..<10).map { Task(title: "Concurrent Task \($0)", status: .inbox) }

        for task in tasks {
            queue.async {
                do {
                    try self.fileIO.writeTask(task)
                } catch {
                    errorLock.lock()
                    errors.append(error)
                    errorLock.unlock()
                }

                if task.title == "Concurrent Task 9" {
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)

        // Should not have any errors
        XCTAssertTrue(errors.isEmpty, "Concurrent writes should not produce errors")

        // Verify all tasks were written
        let loadedTasks = try fileIO.loadAllTasks()
        XCTAssertEqual(loadedTasks.count, tasks.count)
    }

    // MARK: - Special Characters Tests

    func testTaskWithSpecialCharactersInTitle() throws {
        try fileIO.ensureDirectoryStructure()

        let task = Task(
            title: "Task with special ch@racters! & symbols #123",
            notes: "Notes with émojis 🚀 and unicode",
            status: .nextAction
        )

        try fileIO.writeTask(task)

        let url = fileIO.taskURL(for: task)
        let readTask = try fileIO.readTask(from: url)

        XCTAssertNotNil(readTask)
        XCTAssertEqual(readTask?.title, task.title)
        XCTAssertEqual(readTask?.notes, task.notes)
    }

    func testTaskWithUnicodeContent() throws {
        try fileIO.ensureDirectoryStructure()

        let task = Task(
            title: "日本語タイトル",
            notes: "中文內容 with العربية and עברית",
            status: .inbox
        )

        try fileIO.writeTask(task)

        let url = fileIO.taskURL(for: task)
        let readTask = try fileIO.readTask(from: url)

        XCTAssertNotNil(readTask)
        XCTAssertEqual(readTask?.title, task.title)
        XCTAssertEqual(readTask?.notes, task.notes)
    }

    // MARK: - Edge Cases

    func testTaskWithVeryLongTitle() throws {
        try fileIO.ensureDirectoryStructure()

        let longTitle = String(repeating: "A", count: 500)
        let task = Task(title: longTitle, status: .inbox)

        try fileIO.writeTask(task)

        let url = fileIO.taskURL(for: task)
        let readTask = try fileIO.readTask(from: url)

        XCTAssertNotNil(readTask)
        XCTAssertEqual(readTask?.title, longTitle)
    }

    func testTaskWithEmptyNotes() throws {
        try fileIO.ensureDirectoryStructure()

        let task = Task(title: "No Notes", notes: "", status: .inbox)

        try fileIO.writeTask(task)

        let url = fileIO.taskURL(for: task)
        let readTask = try fileIO.readTask(from: url)

        XCTAssertNotNil(readTask)
        XCTAssertEqual(readTask?.notes, "")
    }

    func testTaskWithMultilineNotes() throws {
        try fileIO.ensureDirectoryStructure()

        let notes = """
        Line 1
        Line 2
        Line 3

        Line 5 with blank line above
        """

        let task = Task(title: "Multiline Notes", notes: notes, status: .inbox)

        try fileIO.writeTask(task)

        let url = fileIO.taskURL(for: task)
        let readTask = try fileIO.readTask(from: url)

        XCTAssertNotNil(readTask)
        XCTAssertEqual(readTask?.notes, notes)
    }

    // MARK: - Permission Tests

    func testReadOnlyFileHandling() throws {
        try fileIO.ensureDirectoryStructure()

        let task = Task(title: "Read Only Test", status: .inbox)
        try fileIO.writeTask(task)

        let url = fileIO.taskURL(for: task)

        // Make file read-only
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o444],
            ofItemAtPath: url.path
        )

        // Should still be able to read
        let readTask = try fileIO.readTask(from: url)
        XCTAssertNotNil(readTask)

        // Writing should fail
        XCTAssertThrowsError(try fileIO.writeTask(task)) { error in
            XCTAssertTrue(error is MarkdownFileError)
        }

        // Restore permissions for cleanup
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o644],
            ofItemAtPath: url.path
        )
    }
}
