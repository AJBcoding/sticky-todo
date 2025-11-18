//
//  PerformanceMonitoringTests.swift
//  StickyToDo
//
//  Tests for performance monitoring functionality
//

import XCTest
@testable import StickyToDo

@available(macOS 10.15, *)
final class PerformanceMonitoringTests: XCTestCase {

    var taskStore: TaskStore!
    var fileIO: MarkdownFileIO!
    var logMessages: [String] = []

    override func setUp() {
        super.setUp()

        // Create temporary directory for tests
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        fileIO = MarkdownFileIO(dataDirectory: tempDir)
        taskStore = TaskStore(fileIO: fileIO)

        // Setup logger to capture messages
        logMessages = []
        taskStore.setLogger { [weak self] message in
            self?.logMessages.append(message)
        }
    }

    override func tearDown() {
        // Clean up temporary directory
        if let dataDir = fileIO?.dataDirectory {
            try? FileManager.default.removeItem(at: dataDir)
        }

        taskStore = nil
        fileIO = nil
        logMessages = []

        super.tearDown()
    }

    // MARK: - Normal Level Tests

    func testNormalLevel() {
        // Add 100 tasks (below warning threshold)
        for i in 1...100 {
            let task = Task(title: "Task \(i)", status: .inbox)
            taskStore.add(task)
        }

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Verify task count
        XCTAssertEqual(taskStore.taskCount, 100)

        // Verify normal status
        XCTAssertFalse(taskStore.isAtWarningThreshold)
        XCTAssertFalse(taskStore.isAtAlertThreshold)
        XCTAssertFalse(taskStore.isAtCriticalThreshold)

        // Verify no performance warnings
        XCTAssertNil(taskStore.getPerformanceSuggestion())
    }

    // MARK: - Warning Level Tests

    func testWarningLevel() {
        // Add 500 tasks (at warning threshold)
        for i in 1...500 {
            let task = Task(title: "Task \(i)", status: .inbox)
            taskStore.add(task)
        }

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Verify task count
        XCTAssertEqual(taskStore.taskCount, 500)

        // Verify warning status
        XCTAssertTrue(taskStore.isAtWarningThreshold)
        XCTAssertFalse(taskStore.isAtAlertThreshold)
        XCTAssertFalse(taskStore.isAtCriticalThreshold)

        // Verify warning message logged
        let hasWarning = logMessages.contains { $0.contains("WARNING") }
        XCTAssertTrue(hasWarning, "Should log warning at 500 tasks")

        // Verify suggestion provided
        let suggestion = taskStore.getPerformanceSuggestion()
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion?.contains("Warning") ?? false)
    }

    // MARK: - Alert Level Tests

    func testAlertLevel() {
        // Add 1000 tasks (at alert threshold)
        for i in 1...1000 {
            let task = Task(title: "Task \(i)", status: .inbox)
            taskStore.add(task)
        }

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Verify task count
        XCTAssertEqual(taskStore.taskCount, 1000)

        // Verify alert status
        XCTAssertTrue(taskStore.isAtWarningThreshold)
        XCTAssertTrue(taskStore.isAtAlertThreshold)
        XCTAssertFalse(taskStore.isAtCriticalThreshold)

        // Verify alert message logged
        let hasAlert = logMessages.contains { $0.contains("ALERT") }
        XCTAssertTrue(hasAlert, "Should log alert at 1000 tasks")

        // Verify suggestion provided
        let suggestion = taskStore.getPerformanceSuggestion()
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion?.contains("Alert") ?? false)
    }

    // MARK: - Critical Level Tests

    func testCriticalLevel() {
        // Add 1500 tasks (at critical threshold)
        for i in 1...1500 {
            let task = Task(title: "Task \(i)", status: .inbox)
            taskStore.add(task)
        }

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Verify task count
        XCTAssertEqual(taskStore.taskCount, 1500)

        // Verify critical status
        XCTAssertTrue(taskStore.isAtWarningThreshold)
        XCTAssertTrue(taskStore.isAtAlertThreshold)
        XCTAssertTrue(taskStore.isAtCriticalThreshold)

        // Verify critical message logged
        let hasCritical = logMessages.contains { $0.contains("CRITICAL") }
        XCTAssertTrue(hasCritical, "Should log critical at 1500 tasks")

        // Verify suggestion provided
        let suggestion = taskStore.getPerformanceSuggestion()
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion?.contains("Critical") ?? false)
    }

    // MARK: - Performance Metrics Tests

    func testPerformanceMetrics() {
        // Add mix of active and completed tasks
        for i in 1...600 {
            var task = Task(title: "Task \(i)", status: .inbox)
            if i <= 200 {
                task.complete()
            }
            taskStore.add(task)
        }

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Get performance metrics
        let metrics = taskStore.getPerformanceMetrics()

        // Verify metrics
        XCTAssertEqual(metrics["taskCount"] as? Int, 600)
        XCTAssertEqual(metrics["completedTaskCount"] as? Int, 200)
        XCTAssertEqual(metrics["activeTaskCount"] as? Int, 400)
        XCTAssertEqual(metrics["level"] as? String, "warning")

        // Verify thresholds in metrics
        XCTAssertEqual(metrics["warningThreshold"] as? Int, 500)
        XCTAssertEqual(metrics["alertThreshold"] as? Int, 1000)
        XCTAssertEqual(metrics["criticalThreshold"] as? Int, 1500)

        // Verify percentages
        let percentOfWarning = metrics["percentOfWarning"] as? Double
        XCTAssertNotNil(percentOfWarning)
        XCTAssertEqual(percentOfWarning ?? 0, 120.0, accuracy: 0.1)
    }

    // MARK: - Archivable Tasks Tests

    func testArchivableTasksCount() {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -31, to: Date())!
        let today = Date()

        // Add completed tasks from 31 days ago (archivable)
        for i in 1...50 {
            var task = Task(title: "Old Task \(i)", status: .completed)
            task.modified = thirtyDaysAgo
            taskStore.add(task)
        }

        // Add recently completed tasks (not archivable)
        for i in 1...50 {
            var task = Task(title: "Recent Task \(i)", status: .completed)
            task.modified = today
            taskStore.add(task)
        }

        // Add active tasks
        for i in 1...100 {
            let task = Task(title: "Active Task \(i)", status: .inbox)
            taskStore.add(task)
        }

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Verify archivable count
        let archivableCount = taskStore.archivableTasksCount()
        XCTAssertEqual(archivableCount, 50, "Should identify 50 old completed tasks as archivable")
    }

    // MARK: - Load Performance Monitoring Tests

    func testLoadPerformanceMonitoring() async throws {
        // Create tasks in file system
        for i in 1...550 {
            let task = Task(title: "Task \(i)", status: .inbox)
            try fileIO.writeTask(task)
        }

        // Load all tasks
        try await taskStore.loadAllAsync()

        // Wait a bit for monitoring to run
        try await Task.sleep(nanoseconds: 500_000_000)

        // Verify warning was logged
        let hasWarning = logMessages.contains { $0.contains("WARNING") }
        XCTAssertTrue(hasWarning, "Should log warning when loading 550 tasks")
    }

    // MARK: - Delete Performance Monitoring Tests

    func testDeleteImprovement() {
        // Add 550 tasks to trigger warning
        for i in 1...550 {
            let task = Task(title: "Task \(i)", status: .inbox)
            taskStore.add(task)
        }

        // Wait for async operations
        var expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Clear log messages
        logMessages.removeAll()

        // Delete tasks to bring count below warning threshold
        let tasksToDelete = Array(taskStore.tasks.prefix(100))
        taskStore.deleteBatch(tasksToDelete)

        // Wait for async operations
        expectation = XCTestExpectation(description: "Tasks deleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Verify count is below warning threshold
        XCTAssertEqual(taskStore.taskCount, 450)
        XCTAssertFalse(taskStore.isAtWarningThreshold)

        // Verify improvement message was logged
        let hasImprovement = logMessages.contains { $0.contains("back to normal") }
        XCTAssertTrue(hasImprovement, "Should log improvement when count drops below threshold")
    }

    // MARK: - Performance Impact Tests

    func testMonitoringPerformanceImpact() {
        let startTime = Date()

        // Add many tasks and measure time
        for i in 1...1000 {
            let task = Task(title: "Task \(i)", status: .inbox)
            taskStore.add(task)
        }

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Verify monitoring doesn't significantly impact performance
        // Adding 1000 tasks should complete within 2 seconds even with monitoring
        XCTAssertLessThan(duration, 2.0, "Performance monitoring should not significantly impact task operations")

        // Verify all tasks were added
        XCTAssertEqual(taskStore.taskCount, 1000)
    }
}
