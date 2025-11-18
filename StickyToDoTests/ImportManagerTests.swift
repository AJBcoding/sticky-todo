//
//  ImportManagerTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for ImportManager covering all import formats,
//  error handling, edge cases, and data validation.
//

import XCTest
@testable import StickyToDoCore

final class ImportManagerTests: XCTestCase {

    var importManager: ImportManager!
    var tempDirectory: URL!

    override func setUpWithError() throws {
        importManager = ImportManager()

        // Create temp directory for test files
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        importManager = nil
    }

    // MARK: - JSON Import Tests

    func testJSONImport() async throws {
        // Create test JSON file
        let tasks = [
            Task(title: "Test Task 1", status: .inbox, project: "Project A", priority: .high),
            Task(title: "Test Task 2", status: .nextAction, project: "Project B", priority: .medium),
            Task(title: "Test Task 3", status: .completed, project: "Project A", priority: .low)
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(tasks)

        let jsonURL = tempDirectory.appendingPathComponent("test.json")
        try data.write(to: jsonURL)

        // Import
        let options = ImportOptions(format: .json, autoDetect: false)
        let result = try await importManager.importTasks(from: jsonURL, options: options)

        XCTAssertEqual(result.importedCount, 3)
        XCTAssertEqual(result.tasks.count, 3)
        XCTAssertEqual(result.tasks[0].title, "Test Task 1")
        XCTAssertEqual(result.tasks[1].project, "Project B")
        XCTAssertEqual(result.tasks[2].priority, .low)
    }

    func testJSONImportWithInvalidData() async throws {
        let invalidJSON = "{invalid json content}"
        let jsonURL = tempDirectory.appendingPathComponent("invalid.json")
        try invalidJSON.write(to: jsonURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .json, autoDetect: false)

        do {
            _ = try await importManager.importTasks(from: jsonURL, options: options)
            XCTFail("Should have thrown an error for invalid JSON")
        } catch {
            // Expected error
            XCTAssertTrue(error is ImportError)
        }
    }

    func testJSONImportWithMaxTasksLimit() async throws {
        let tasks = (0..<100).map { Task(title: "Task \($0)") }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(tasks)

        let jsonURL = tempDirectory.appendingPathComponent("many.json")
        try data.write(to: jsonURL)

        var options = ImportOptions(format: .json, autoDetect: false)
        options.maxTasks = 10

        let result = try await importManager.importTasks(from: jsonURL, options: options)

        XCTAssertEqual(result.importedCount, 10)
        XCTAssertEqual(result.tasks.count, 10)
    }

    // MARK: - CSV Import Tests

    func testCSVImport() async throws {
        let csvContent = """
        ID,Type,Title,Status,Project,Context,Priority,Due,Flagged,Notes
        \(UUID().uuidString),task,"Buy groceries",inbox,"Personal","@home",high,2025-11-20,false,"Milk and bread"
        \(UUID().uuidString),task,"Call client",next-action,"Work","@phone",medium,2025-11-21,true,"Discuss project timeline"
        \(UUID().uuidString),task,"Review code",completed,"Work","@computer",low,,false,""
        """

        let csvURL = tempDirectory.appendingPathComponent("test.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        var options = ImportOptions(format: .csv, autoDetect: false)
        options.dateFormat = "yyyy-MM-dd"

        let result = try await importManager.importTasks(from: csvURL, options: options)

        XCTAssertEqual(result.importedCount, 3)
        XCTAssertEqual(result.tasks[0].title, "Buy groceries")
        XCTAssertEqual(result.tasks[0].status, .inbox)
        XCTAssertEqual(result.tasks[0].priority, .high)
        XCTAssertEqual(result.tasks[0].project, "Personal")
        XCTAssertEqual(result.tasks[0].context, "@home")
        XCTAssertTrue(result.tasks[1].flagged)
    }

    func testCSVImportWithQuotedFields() async throws {
        let csvContent = """
        Title,Status,Notes
        "Task with, comma",inbox,"Note with ""quotes"""
        Simple task,next-action,Simple note
        """

        let csvURL = tempDirectory.appendingPathComponent("quoted.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .csv, autoDetect: false)
        let result = try await importManager.importTasks(from: csvURL, options: options)

        XCTAssertEqual(result.tasks[0].title, "Task with, comma")
        XCTAssertTrue(result.tasks[0].notes.contains("quotes"))
    }

    func testCSVImportWithMissingRequiredField() async throws {
        let csvContent = """
        Status,Project
        inbox,Test
        """

        let csvURL = tempDirectory.appendingPathComponent("missing.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .csv, autoDetect: false, skipErrors: false)

        do {
            _ = try await importManager.importTasks(from: csvURL, options: options)
            XCTFail("Should have thrown an error for missing title field")
        } catch {
            XCTAssertTrue(error is ImportError)
        }
    }

    func testCSVImportWithSkipErrors() async throws {
        let csvContent = """
        Title,Status
        Valid Task,inbox
        ,inbox
        Another Valid,next-action
        """

        let csvURL = tempDirectory.appendingPathComponent("partial.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        var options = ImportOptions(format: .csv, autoDetect: false)
        options.skipErrors = true

        let result = try await importManager.importTasks(from: csvURL, options: options)

        XCTAssertEqual(result.importedCount, 2) // Only valid tasks
        XCTAssertTrue(result.errors.count > 0)
    }

    // MARK: - TSV Import Tests

    func testTSVImport() async throws {
        let tsvContent = """
        Title\tStatus\tProject\tPriority
        Task 1\tinbox\tProject A\thigh
        Task 2\tnext-action\tProject B\tmedium
        Task 3\tcompleted\tProject C\tlow
        """

        let tsvURL = tempDirectory.appendingPathComponent("test.tsv")
        try tsvContent.write(to: tsvURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .tsv, autoDetect: false)
        let result = try await importManager.importTasks(from: tsvURL, options: options)

        XCTAssertEqual(result.importedCount, 3)
        XCTAssertEqual(result.tasks[0].title, "Task 1")
        XCTAssertEqual(result.tasks[1].status, .nextAction)
    }

    // MARK: - TaskPaper Import Tests

    func testTaskPaperImport() async throws {
        let taskPaperContent = """
        Work:
        \t- Call John @phone @priority(high) @due(2025-11-20)
        \t- Review document @computer @priority(medium)
        \t- Team meeting @done

        Personal:
        \t- Buy groceries @home @priority(low)
        """

        let taskPaperURL = tempDirectory.appendingPathComponent("test.taskpaper")
        try taskPaperContent.write(to: taskPaperURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .taskpaper, autoDetect: false)
        let result = try await importManager.importTasks(from: taskPaperURL, options: options)

        XCTAssertEqual(result.importedCount, 4)
        XCTAssertEqual(result.tasks[0].title, "Call John")
        XCTAssertEqual(result.tasks[0].context, "@phone")
        XCTAssertEqual(result.tasks[0].priority, .high)
        XCTAssertNotNil(result.tasks[0].due)
        XCTAssertEqual(result.tasks[2].status, .completed)
    }

    func testTaskPaperImportWithNestedNotes() async throws {
        let taskPaperContent = """
        Project:
        \t- Main task @priority(high)
        \t\tThis is a note
        \t\tThis is another note
        """

        let taskPaperURL = tempDirectory.appendingPathComponent("notes.taskpaper")
        try taskPaperContent.write(to: taskPaperURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .taskpaper, autoDetect: false)
        let result = try await importManager.importTasks(from: taskPaperURL, options: options)

        XCTAssertEqual(result.tasks.count, 1)
        // Notes would be parsed if implementation supports nested content
    }

    // MARK: - Plain Text Checklist Import Tests

    func testPlainTextChecklistImport() async throws {
        let checklistContent = """
        - [ ] Buy milk @home #Shopping !high
        - [x] Complete report @work #Project
        - [ ] Call dentist @phone
        * [ ] Clean garage !low
        * [X] Read book
        """

        let checklistURL = tempDirectory.appendingPathComponent("checklist.txt")
        try checklistContent.write(to: checklistURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .plainTextChecklist, autoDetect: false)
        let result = try await importManager.importTasks(from: checklistURL, options: options)

        XCTAssertEqual(result.importedCount, 5)
        XCTAssertEqual(result.tasks[0].title, "Buy milk")
        XCTAssertEqual(result.tasks[0].context, "@home")
        XCTAssertEqual(result.tasks[0].project, "Shopping")
        XCTAssertEqual(result.tasks[0].priority, .high)
        XCTAssertEqual(result.tasks[1].status, .completed)
    }

    func testPlainTextChecklistWithNoMetadata() async throws {
        let checklistContent = """
        - [ ] Simple task
        - [x] Completed task
        """

        let checklistURL = tempDirectory.appendingPathComponent("simple.txt")
        try checklistContent.write(to: checklistURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .plainTextChecklist, autoDetect: false)
        let result = try await importManager.importTasks(from: checklistURL, options: options)

        XCTAssertEqual(result.tasks[0].title, "Simple task")
        XCTAssertEqual(result.tasks[0].priority, .medium) // Default priority
    }

    // MARK: - Native Markdown Import Tests

    func testNativeMarkdownImport() async throws {
        let markdownContent = """
        ---
        type: task
        title: "Test Task"
        status: next-action
        project: "Test Project"
        context: "@home"
        priority: high
        flagged: true
        effort: 60
        due: 2025-11-20T10:00:00Z
        created: 2025-11-01T10:00:00Z
        modified: 2025-11-15T10:00:00Z
        ---

        This is the task notes section.
        It can have multiple lines.
        """

        let markdownURL = tempDirectory.appendingPathComponent("test.md")
        try markdownContent.write(to: markdownURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .nativeMarkdown, autoDetect: false)
        let result = try await importManager.importTasks(from: markdownURL, options: options)

        XCTAssertEqual(result.importedCount, 1)
        XCTAssertEqual(result.tasks[0].title, "Test Task")
        XCTAssertEqual(result.tasks[0].status, .nextAction)
        XCTAssertEqual(result.tasks[0].project, "Test Project")
        XCTAssertEqual(result.tasks[0].context, "@home")
        XCTAssertEqual(result.tasks[0].priority, .high)
        XCTAssertTrue(result.tasks[0].flagged)
        XCTAssertEqual(result.tasks[0].effort, 60)
        XCTAssertNotNil(result.tasks[0].due)
        XCTAssertTrue(result.tasks[0].notes.contains("task notes"))
    }

    func testNativeMarkdownImportWithMissingFrontmatter() async throws {
        let markdownContent = """
        # This is just markdown

        No frontmatter here.
        """

        let markdownURL = tempDirectory.appendingPathComponent("invalid.md")
        try markdownContent.write(to: markdownURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .nativeMarkdown, autoDetect: false)

        do {
            _ = try await importManager.importTasks(from: markdownURL, options: options)
            XCTFail("Should have thrown an error for missing frontmatter")
        } catch {
            XCTAssertTrue(error is ImportError)
        }
    }

    // MARK: - Format Auto-Detection Tests

    func testFormatAutoDetectionJSON() async throws {
        let tasks = [Task(title: "Test Task")]
        let encoder = JSONEncoder()
        let data = try encoder.encode(tasks)

        let jsonURL = tempDirectory.appendingPathComponent("auto.json")
        try data.write(to: jsonURL)

        let options = ImportOptions(format: .json, autoDetect: true)
        let result = try await importManager.importTasks(from: jsonURL, options: options)

        XCTAssertEqual(result.tasks.count, 1)
    }

    func testFormatAutoDetectionCSV() async throws {
        let csvContent = "Title,Status\nTest Task,inbox\n"
        let csvURL = tempDirectory.appendingPathComponent("auto.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .csv, autoDetect: true)
        let result = try await importManager.importTasks(from: csvURL, options: options)

        XCTAssertEqual(result.tasks.count, 1)
    }

    // MARK: - Import Preview Tests

    func testImportPreview() async throws {
        let tasks = (0..<20).map { Task(title: "Task \($0)", project: "Project \($0 % 3)") }

        let encoder = JSONEncoder()
        let data = try encoder.encode(tasks)

        let jsonURL = tempDirectory.appendingPathComponent("preview.json")
        try data.write(to: jsonURL)

        let options = ImportOptions(format: .json, autoDetect: false)
        let preview = try await importManager.preview(from: jsonURL, options: options)

        XCTAssertEqual(preview.taskCount, 10) // Preview limit
        XCTAssertTrue(preview.projects.count > 0)
    }

    // MARK: - Import Options Tests

    func testImportWithDefaultStatus() async throws {
        let csvContent = """
        Title,Project
        Task 1,Project A
        Task 2,Project B
        """

        let csvURL = tempDirectory.appendingPathComponent("defaults.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        var options = ImportOptions(format: .csv, autoDetect: false)
        options.defaultStatus = .nextAction

        let result = try await importManager.importTasks(from: csvURL, options: options)

        XCTAssertEqual(result.tasks[0].status, .nextAction)
        XCTAssertEqual(result.tasks[1].status, .nextAction)
    }

    func testImportWithDefaultProject() async throws {
        let csvContent = """
        Title,Status
        Task 1,inbox
        Task 2,next-action
        """

        let csvURL = tempDirectory.appendingPathComponent("default-project.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)

        var options = ImportOptions(format: .csv, autoDetect: false)
        options.defaultProject = "Default Project"

        let result = try await importManager.importTasks(from: csvURL, options: options)

        XCTAssertEqual(result.tasks[0].project, "Default Project")
        XCTAssertEqual(result.tasks[1].project, "Default Project")
    }

    func testImportWithPreserveIds() async throws {
        let id1 = UUID()
        let id2 = UUID()
        let tasks = [
            Task(id: id1, title: "Task 1"),
            Task(id: id2, title: "Task 2")
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(tasks)

        let jsonURL = tempDirectory.appendingPathComponent("ids.json")
        try data.write(to: jsonURL)

        var options = ImportOptions(format: .json, autoDetect: false)
        options.preserveIds = true

        let result = try await importManager.importTasks(from: jsonURL, options: options)

        XCTAssertEqual(result.tasks[0].id, id1)
        XCTAssertEqual(result.tasks[1].id, id2)
    }

    func testImportWithoutPreserveIds() async throws {
        let id1 = UUID()
        let id2 = UUID()
        let tasks = [
            Task(id: id1, title: "Task 1"),
            Task(id: id2, title: "Task 2")
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(tasks)

        let jsonURL = tempDirectory.appendingPathComponent("new-ids.json")
        try data.write(to: jsonURL)

        var options = ImportOptions(format: .json, autoDetect: false)
        options.preserveIds = false

        let result = try await importManager.importTasks(from: jsonURL, options: options)

        XCTAssertNotEqual(result.tasks[0].id, id1)
        XCTAssertNotEqual(result.tasks[1].id, id2)
    }

    // MARK: - Progress Callback Tests

    func testProgressCallback() async throws {
        var progressUpdates: [(Double, String)] = []

        importManager.progressHandler = { progress, message in
            progressUpdates.append((progress, message))
        }

        let tasks = (0..<5).map { Task(title: "Task \($0)") }
        let encoder = JSONEncoder()
        let data = try encoder.encode(tasks)

        let jsonURL = tempDirectory.appendingPathComponent("progress.json")
        try data.write(to: jsonURL)

        let options = ImportOptions(format: .json, autoDetect: false)
        _ = try await importManager.importTasks(from: jsonURL, options: options)

        XCTAssertTrue(progressUpdates.count > 0)
        XCTAssertTrue(progressUpdates.contains { $0.0 == 1.0 }) // Should complete at 100%
    }

    // MARK: - Error Handling Tests

    func testImportFromNonexistentFile() async throws {
        let nonexistentURL = tempDirectory.appendingPathComponent("nonexistent.json")
        let options = ImportOptions(format: .json, autoDetect: false)

        do {
            _ = try await importManager.importTasks(from: nonexistentURL, options: options)
            XCTFail("Should have thrown an error for nonexistent file")
        } catch {
            // Expected error
        }
    }

    func testImportWithEmptyFile() async throws {
        let emptyURL = tempDirectory.appendingPathComponent("empty.json")
        try "".write(to: emptyURL, atomically: true, encoding: .utf8)

        let options = ImportOptions(format: .json, autoDetect: false)

        do {
            _ = try await importManager.importTasks(from: emptyURL, options: options)
            XCTFail("Should have thrown an error for empty file")
        } catch {
            // Expected error
        }
    }

    // MARK: - Performance Tests

    func testLargeFileImportPerformance() throws {
        let tasks = (0..<1000).map { Task(title: "Task \($0)", project: "Project \($0 % 10)") }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(tasks)

        let jsonURL = tempDirectory.appendingPathComponent("large.json")
        try data.write(to: jsonURL)

        let options = ImportOptions(format: .json, autoDetect: false)

        measure {
            let expectation = XCTestExpectation(description: "Import completes")

            Task {
                _ = try await importManager.importTasks(from: jsonURL, options: options)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 10.0)
        }
    }
}
