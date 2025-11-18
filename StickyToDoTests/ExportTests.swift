//
//  ExportTests.swift
//  StickyToDoTests
//
//  Tests for export functionality across all formats.
//

import XCTest
@testable import StickyToDoCore

final class ExportTests: XCTestCase {

    var exportManager: ExportManager!
    var testTasks: [Task]!
    var testBoards: [Board]!
    var tempDirectory: URL!

    override func setUpWithError() throws {
        exportManager = ExportManager()

        // Create test tasks
        testTasks = [
            Task(
                title: "Test Task 1",
                status: .nextAction,
                project: "Test Project",
                context: "@home",
                due: Date(),
                priority: .high
            ),
            Task(
                title: "Test Task 2",
                status: .completed,
                project: "Test Project",
                context: "@work",
                priority: .medium
            ),
            Task(
                title: "Test Task 3",
                status: .inbox,
                project: "Another Project",
                priority: .low
            )
        ]

        // Create test boards
        testBoards = [
            Board(
                id: UUID(),
                name: "Test Board",
                type: .gtd,
                layout: .kanban,
                filter: Filter()
            )
        ]

        // Create temp directory
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        exportManager = nil
        testTasks = nil
        testBoards = nil
    }

    // MARK: - JSON Export Tests

    func testJSONExport() async throws {
        let url = tempDirectory.appendingPathComponent("test.json")
        let options = ExportOptions(format: .json, filename: "test")

        let result = try await exportManager.export(tasks: testTasks, to: url, options: options)

        XCTAssertEqual(result.format, .json)
        XCTAssertEqual(result.taskCount, 3)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.fileURL.path))

        // Verify JSON content
        let data = try Data(contentsOf: result.fileURL)
        let decoded = try JSONDecoder().decode([Task].self, from: data)
        XCTAssertEqual(decoded.count, 3)
    }

    // MARK: - CSV Export Tests

    func testCSVExport() async throws {
        let url = tempDirectory.appendingPathComponent("test.csv")
        let options = ExportOptions(format: .csv, filename: "test")

        let result = try await exportManager.export(tasks: testTasks, to: url, options: options)

        XCTAssertEqual(result.format, .csv)
        XCTAssertEqual(result.taskCount, 3)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.fileURL.path))

        // Verify CSV content
        let content = try String(contentsOf: result.fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("ID,Type,Title,Status"))
        XCTAssertTrue(content.contains("Test Task 1"))
        XCTAssertTrue(content.contains("Test Task 2"))
        XCTAssertTrue(content.contains("Test Task 3"))
    }

    // MARK: - TSV Export Tests

    func testTSVExport() async throws {
        let url = tempDirectory.appendingPathComponent("test.tsv")
        let options = ExportOptions(format: .tsv, filename: "test")

        let result = try await exportManager.export(tasks: testTasks, to: url, options: options)

        XCTAssertEqual(result.format, .tsv)
        XCTAssertEqual(result.taskCount, 3)

        let content = try String(contentsOf: result.fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("\t")) // Tab-separated
    }

    // MARK: - HTML Export Tests

    func testHTMLExport() async throws {
        let url = tempDirectory.appendingPathComponent("test.html")
        let options = ExportOptions(format: .html, filename: "test")

        let result = try await exportManager.export(tasks: testTasks, to: url, options: options)

        XCTAssertEqual(result.format, .html)
        XCTAssertEqual(result.taskCount, 3)

        let content = try String(contentsOf: result.fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("<!DOCTYPE html>"))
        XCTAssertTrue(content.contains("StickyToDo Export"))
        XCTAssertTrue(content.contains("Test Task 1"))
    }

    // MARK: - iCal Export Tests

    func testiCalExport() async throws {
        // Only tasks with due dates should be exported
        let url = tempDirectory.appendingPathComponent("test.ics")
        let options = ExportOptions(format: .ical, filename: "test")

        let result = try await exportManager.export(tasks: testTasks, to: url, options: options)

        XCTAssertEqual(result.format, .ical)
        XCTAssertEqual(result.taskCount, 1) // Only 1 task has due date

        let content = try String(contentsOf: result.fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(content.contains("BEGIN:VTODO"))
        XCTAssertTrue(content.contains("END:VCALENDAR"))
    }

    // MARK: - Simplified Markdown Export Tests

    func testSimplifiedMarkdownExport() async throws {
        let url = tempDirectory.appendingPathComponent("test.md")
        let options = ExportOptions(format: .simplifiedMarkdown, filename: "test")

        let result = try await exportManager.export(tasks: testTasks, to: url, options: options)

        XCTAssertEqual(result.format, .simplifiedMarkdown)
        XCTAssertEqual(result.taskCount, 3)

        // For multiple projects, it should create a directory
        // Verify at least one file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.fileURL.path))
    }

    // MARK: - TaskPaper Export Tests

    func testTaskPaperExport() async throws {
        let url = tempDirectory.appendingPathComponent("test.taskpaper")
        let options = ExportOptions(format: .taskpaper, filename: "test")

        let result = try await exportManager.export(tasks: testTasks, to: url, options: options)

        XCTAssertEqual(result.format, .taskpaper)
        XCTAssertEqual(result.taskCount, 3)

        let content = try String(contentsOf: result.fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("@priority"))
        XCTAssertTrue(content.contains("@project"))
    }

    // MARK: - Filter Tests

    func testExportWithCompletedFilter() async throws {
        let url = tempDirectory.appendingPathComponent("test.json")
        var options = ExportOptions(format: .json, filename: "test")
        options.includeCompleted = false

        let result = try await exportManager.export(tasks: testTasks, to: url, options: options)

        // Should exclude 1 completed task
        XCTAssertEqual(result.taskCount, 2)
    }

    func testExportWithDateRangeFilter() async throws {
        let url = tempDirectory.appendingPathComponent("test.json")
        var options = ExportOptions(format: .json, filename: "test")

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        options.dateRange = DateInterval(start: yesterday, end: tomorrow)

        let result = try await exportManager.export(tasks: testTasks, to: url, options: options)

        // All test tasks were created "now", so they should all be included
        XCTAssertEqual(result.taskCount, 3)
    }

    func testExportWithProjectFilter() async throws {
        let url = tempDirectory.appendingPathComponent("test.json")
        var options = ExportOptions(format: .json, filename: "test")
        options.projects = ["Test Project"]

        let result = try await exportManager.export(tasks: testTasks, to: url, options: options)

        // Should only include 2 tasks from "Test Project"
        XCTAssertEqual(result.taskCount, 2)
    }

    // MARK: - Export Preview Tests

    func testExportPreview() {
        let options = ExportOptions(format: .json, filename: "test")
        let preview = exportManager.preview(tasks: testTasks, options: options)

        XCTAssertEqual(preview.taskCount, 3)
        XCTAssertEqual(preview.projects.count, 2)
        XCTAssertEqual(preview.contexts.count, 2)
    }

    func testExportPreviewWithFilters() {
        var options = ExportOptions(format: .json, filename: "test")
        options.includeCompleted = false

        let preview = exportManager.preview(tasks: testTasks, options: options)

        // Should exclude completed task
        XCTAssertEqual(preview.taskCount, 2)
    }

    // MARK: - Format Properties Tests

    func testFormatProperties() {
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.html.fileExtension, "html")
        XCTAssertEqual(ExportFormat.pdf.fileExtension, "pdf")
        XCTAssertEqual(ExportFormat.ical.fileExtension, "ics")

        XCTAssertTrue(ExportFormat.nativeMarkdownArchive.isLossless)
        XCTAssertFalse(ExportFormat.json.isLossless)
        XCTAssertFalse(ExportFormat.html.isLossless)
    }

    // MARK: - Performance Tests

    func testExportPerformance() throws {
        // Create large dataset
        var largeTasks: [Task] = []
        for i in 0..<1000 {
            largeTasks.append(Task(
                title: "Task \(i)",
                project: "Project \(i % 10)",
                priority: i % 2 == 0 ? .high : .low
            ))
        }

        let url = tempDirectory.appendingPathComponent("large.json")
        let options = ExportOptions(format: .json, filename: "large")

        measure {
            let expectation = XCTestExpectation(description: "Export completes")

            Task {
                _ = try await exportManager.export(tasks: largeTasks, to: url, options: options)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 10.0)
        }
    }
}
