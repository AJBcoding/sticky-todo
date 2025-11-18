//
//  ActivityLogTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for the activity log system.
//  Tests ActivityLog model, ActivityLogManager, and integration with TaskStore.
//

import XCTest
@testable import StickyToDo

class ActivityLogTests: XCTestCase {

    var tempDirectory: URL!
    var fileIO: MarkdownFileIO!
    var activityLogManager: ActivityLogManager!
    var taskStore: TaskStore!

    override func setUpWithError() throws {
        // Create temporary directory
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Initialize components
        fileIO = MarkdownFileIO(rootDirectory: tempDirectory)
        try fileIO.ensureDirectoryStructure()

        activityLogManager = ActivityLogManager(fileIO: fileIO, retentionDays: 90)
        taskStore = TaskStore(fileIO: fileIO)
        taskStore.setActivityLogManager(activityLogManager)
    }

    override func tearDownWithError() throws {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - ActivityLog Model Tests

    func testActivityLogCreation() {
        let task = Task(title: "Test Task")
        let log = ActivityLog.taskCreated(task: task)

        XCTAssertEqual(log.taskId, task.id)
        XCTAssertEqual(log.taskTitle, task.title)
        XCTAssertEqual(log.changeType, .created)
        XCTAssertNotNil(log.metadata)
    }

    func testActivityLogStatusChange() {
        let task = Task(title: "Test Task", status: .nextAction)
        let log = ActivityLog.statusChanged(task: task, from: .inbox, to: .nextAction)

        XCTAssertEqual(log.changeType, .statusChanged)
        XCTAssertEqual(log.beforeValue, "inbox")
        XCTAssertEqual(log.afterValue, "next-action")
    }

    func testActivityLogPriorityChange() {
        let task = Task(title: "Test Task", priority: .high)
        let log = ActivityLog.priorityChanged(task: task, from: .medium, to: .high)

        XCTAssertEqual(log.changeType, .priorityChanged)
        XCTAssertEqual(log.beforeValue, "medium")
        XCTAssertEqual(log.afterValue, "high")
    }

    func testActivityLogProjectChange() {
        let task = Task(title: "Test Task", project: "New Project")
        let log = ActivityLog.projectSet(task: task, from: "Old Project", to: "New Project")

        XCTAssertEqual(log.changeType, .projectSet)
        XCTAssertEqual(log.beforeValue, "Old Project")
        XCTAssertEqual(log.afterValue, "New Project")
    }

    func testActivityLogFiltering() {
        let task = Task(title: "Test Task")
        let log = ActivityLog.taskCreated(task: task)

        XCTAssertTrue(log.isForTask(task.id))
        XCTAssertFalse(log.isForTask(UUID()))

        XCTAssertTrue(log.hasChangeType(.created))
        XCTAssertFalse(log.hasChangeType(.deleted))

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        XCTAssertTrue(log.isInDateRange(from: yesterday, to: tomorrow))
        XCTAssertFalse(log.isInDateRange(from: tomorrow, to: nil))
    }

    func testActivityLogSearch() {
        let task = Task(title: "Important Task")
        let log = ActivityLog.taskCreated(task: task)

        XCTAssertTrue(log.matchesSearch("Important"))
        XCTAssertTrue(log.matchesSearch("task"))
        XCTAssertTrue(log.matchesSearch("Created"))
        XCTAssertFalse(log.matchesSearch("Nonexistent"))
    }

    func testActivityLogExportToCSV() {
        let task = Task(title: "Test Task")
        let log = ActivityLog.taskCreated(task: task)

        let csvRow = log.toCSVRow()

        XCTAssertEqual(csvRow.count, 8) // 8 columns
        XCTAssertEqual(csvRow[0], log.id.uuidString)
        XCTAssertEqual(csvRow[1], task.id.uuidString)
        XCTAssertEqual(csvRow[2], task.title)
        XCTAssertEqual(csvRow[3], "Created")
    }

    func testActivityLogExportToJSON() {
        let task = Task(title: "Test Task")
        let log = ActivityLog.taskCreated(task: task)

        let jsonDict = log.toJSONDictionary()

        XCTAssertEqual(jsonDict["taskTitle"] as? String, task.title)
        XCTAssertEqual(jsonDict["changeType"] as? String, "Created")
        XCTAssertNotNil(jsonDict["metadata"])
    }

    // MARK: - ActivityLogManager Tests

    func testActivityLogManagerAddLog() throws {
        let task = Task(title: "Test Task")
        let log = ActivityLog.taskCreated(task: task)

        activityLogManager.addLog(log)

        XCTAssertEqual(activityLogManager.logCount, 1)
        XCTAssertEqual(activityLogManager.logs.first?.id, log.id)
    }

    func testActivityLogManagerAddMultipleLogs() throws {
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")

        let log1 = ActivityLog.taskCreated(task: task1)
        let log2 = ActivityLog.taskCreated(task: task2)

        activityLogManager.addLogs([log1, log2])

        XCTAssertEqual(activityLogManager.logCount, 2)
    }

    func testActivityLogManagerFilterByTask() throws {
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")

        activityLogManager.addLog(ActivityLog.taskCreated(task: task1))
        activityLogManager.addLog(ActivityLog.taskCreated(task: task2))
        activityLogManager.addLog(ActivityLog.taskDeleted(task: task1))

        let task1Logs = activityLogManager.logs(forTask: task1.id)

        XCTAssertEqual(task1Logs.count, 2)
        XCTAssertTrue(task1Logs.allSatisfy { $0.taskId == task1.id })
    }

    func testActivityLogManagerFilterByChangeType() throws {
        let task = Task(title: "Test Task")

        activityLogManager.addLog(ActivityLog.taskCreated(task: task))
        activityLogManager.addLog(ActivityLog.flagged(task: task))
        activityLogManager.addLog(ActivityLog.taskDeleted(task: task))

        let createdLogs = activityLogManager.logs(ofType: .created)
        XCTAssertEqual(createdLogs.count, 1)
        XCTAssertEqual(createdLogs.first?.changeType, .created)

        let flaggedLogs = activityLogManager.logs(ofType: .flagged)
        XCTAssertEqual(flaggedLogs.count, 1)
        XCTAssertEqual(flaggedLogs.first?.changeType, .flagged)
    }

    func testActivityLogManagerFilterByDateRange() throws {
        let task = Task(title: "Test Task")
        let now = Date()

        // Create logs with different timestamps
        var oldLog = ActivityLog.taskCreated(task: task)
        oldLog = ActivityLog(
            id: oldLog.id,
            taskId: oldLog.taskId,
            taskTitle: oldLog.taskTitle,
            changeType: oldLog.changeType,
            timestamp: Calendar.current.date(byAdding: .day, value: -10, to: now)!,
            beforeValue: oldLog.beforeValue,
            afterValue: oldLog.afterValue,
            metadata: oldLog.metadata
        )

        var recentLog = ActivityLog.flagged(task: task)
        recentLog = ActivityLog(
            id: recentLog.id,
            taskId: recentLog.taskId,
            taskTitle: recentLog.taskTitle,
            changeType: recentLog.changeType,
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
            beforeValue: recentLog.beforeValue,
            afterValue: recentLog.afterValue,
            metadata: recentLog.metadata
        )

        activityLogManager.addLogs([oldLog, recentLog])

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let recentLogs = activityLogManager.logs(from: sevenDaysAgo, to: now)

        XCTAssertEqual(recentLogs.count, 1)
        XCTAssertEqual(recentLogs.first?.id, recentLog.id)
    }

    func testActivityLogManagerSearch() throws {
        let task1 = Task(title: "Important Meeting")
        let task2 = Task(title: "Review Code")

        activityLogManager.addLog(ActivityLog.taskCreated(task: task1))
        activityLogManager.addLog(ActivityLog.taskCreated(task: task2))

        let results = activityLogManager.logs(matchingSearch: "Meeting")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.taskTitle, "Important Meeting")
    }

    func testActivityLogManagerGrouping() throws {
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")

        activityLogManager.addLog(ActivityLog.taskCreated(task: task1))
        activityLogManager.addLog(ActivityLog.flagged(task: task1))
        activityLogManager.addLog(ActivityLog.taskCreated(task: task2))

        let groupedByTask = activityLogManager.groupedByTask()

        XCTAssertEqual(groupedByTask.count, 2)
        XCTAssertEqual(groupedByTask[task1.id]?.count, 2)
        XCTAssertEqual(groupedByTask[task2.id]?.count, 1)
    }

    func testActivityLogManagerRetentionPolicy() throws {
        let task = Task(title: "Test Task")
        let now = Date()

        // Create an old log (100 days ago)
        var oldLog = ActivityLog.taskCreated(task: task)
        oldLog = ActivityLog(
            id: oldLog.id,
            taskId: oldLog.taskId,
            taskTitle: oldLog.taskTitle,
            changeType: oldLog.changeType,
            timestamp: Calendar.current.date(byAdding: .day, value: -100, to: now)!,
            beforeValue: oldLog.beforeValue,
            afterValue: oldLog.afterValue,
            metadata: oldLog.metadata
        )

        // Create a recent log
        let recentLog = ActivityLog.flagged(task: task)

        activityLogManager.addLogs([oldLog, recentLog])
        XCTAssertEqual(activityLogManager.logCount, 2)

        // Apply retention policy (90 days)
        let removedCount = activityLogManager.applyRetentionPolicy()

        XCTAssertEqual(removedCount, 1)
        XCTAssertEqual(activityLogManager.logCount, 1)
        XCTAssertEqual(activityLogManager.logs.first?.id, recentLog.id)
    }

    func testActivityLogManagerStatistics() throws {
        let task = Task(title: "Test Task")

        activityLogManager.addLog(ActivityLog.taskCreated(task: task))
        activityLogManager.addLog(ActivityLog.flagged(task: task))
        activityLogManager.addLog(ActivityLog.statusChanged(task: task, from: .inbox, to: .nextAction))

        let countsByType = activityLogManager.logCountsByChangeType()

        XCTAssertEqual(countsByType[.created], 1)
        XCTAssertEqual(countsByType[.flagged], 1)
        XCTAssertEqual(countsByType[.statusChanged], 1)
    }

    // MARK: - Persistence Tests

    func testActivityLogPersistence() throws {
        let task = Task(title: "Test Task")
        let log = ActivityLog.taskCreated(task: task)

        activityLogManager.addLog(log)
        try activityLogManager.saveImmediately()

        // Create new manager and load
        let newManager = ActivityLogManager(fileIO: fileIO)
        try newManager.loadAll()

        XCTAssertEqual(newManager.logCount, 1)
        XCTAssertEqual(newManager.logs.first?.id, log.id)
        XCTAssertEqual(newManager.logs.first?.taskTitle, task.title)
    }

    func testActivityLogExport() throws {
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")

        activityLogManager.addLog(ActivityLog.taskCreated(task: task1))
        activityLogManager.addLog(ActivityLog.taskCreated(task: task2))

        // Test CSV export
        let csvString = activityLogManager.exportToCSV(includeHeader: true)
        XCTAssertTrue(csvString.contains("Task 1"))
        XCTAssertTrue(csvString.contains("Task 2"))
        XCTAssertTrue(csvString.contains("Created"))

        // Test JSON export
        let jsonData = try activityLogManager.exportToJSON()
        let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
        XCTAssertEqual(jsonArray?.count, 2)
    }

    // MARK: - TaskStore Integration Tests

    func testTaskStoreLogsTaskCreation() throws {
        let task = Task(title: "New Task")

        taskStore.add(task)

        // Wait a bit for async operations
        let expectation = XCTestExpectation(description: "Wait for log")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let logs = activityLogManager.logs(forTask: task.id)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.changeType, .created)
    }

    func testTaskStoreLogsTaskDeletion() throws {
        var task = Task(title: "Task to Delete")
        taskStore.add(task)

        // Wait a bit
        Thread.sleep(forTimeInterval: 0.1)

        taskStore.delete(task)

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Wait for log")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let logs = activityLogManager.logs(forTask: task.id)
        XCTAssertTrue(logs.contains { $0.changeType == .deleted })
    }

    func testTaskStoreLogsStatusChange() throws {
        var task = Task(title: "Task", status: .inbox)
        taskStore.add(task)
        Thread.sleep(forTimeInterval: 0.1)

        // Change status
        task.status = .nextAction
        taskStore.update(task)

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Wait for log")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let logs = activityLogManager.logs(forTask: task.id)
        XCTAssertTrue(logs.contains { $0.changeType == .statusChanged })
    }

    func testTaskStoreLogsPriorityChange() throws {
        var task = Task(title: "Task", priority: .medium)
        taskStore.add(task)
        Thread.sleep(forTimeInterval: 0.1)

        // Change priority
        task.priority = .high
        taskStore.update(task)

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Wait for log")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let logs = activityLogManager.logs(forTask: task.id)
        XCTAssertTrue(logs.contains { $0.changeType == .priorityChanged })
    }

    func testTaskStoreLogsFlagChange() throws {
        var task = Task(title: "Task", flagged: false)
        taskStore.add(task)
        Thread.sleep(forTimeInterval: 0.1)

        // Flag the task
        task.flagged = true
        taskStore.update(task)

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Wait for log")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let logs = activityLogManager.logs(forTask: task.id)
        XCTAssertTrue(logs.contains { $0.changeType == .flagged })
    }

    func testTaskStoreLogsTagChanges() throws {
        var task = Task(title: "Task")
        taskStore.add(task)
        Thread.sleep(forTimeInterval: 0.1)

        // Add a tag
        let tag = Tag(name: "Important")
        task.addTag(tag)
        taskStore.update(task)

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Wait for log")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let logs = activityLogManager.logs(forTask: task.id)
        XCTAssertTrue(logs.contains { $0.changeType == .tagAdded })
    }

    func testMultipleChangesGenerateMultipleLogs() throws {
        var task = Task(title: "Task", status: .inbox, priority: .low, flagged: false)
        taskStore.add(task)
        Thread.sleep(forTimeInterval: 0.1)

        // Make multiple changes
        task.status = .nextAction
        task.priority = .high
        task.flagged = true
        task.project = "New Project"
        taskStore.update(task)

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Wait for log")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let logs = activityLogManager.logs(forTask: task.id)

        // Should have logs for: created, statusChanged, priorityChanged, flagged, projectSet
        XCTAssertTrue(logs.count >= 5)
        XCTAssertTrue(logs.contains { $0.changeType == .created })
        XCTAssertTrue(logs.contains { $0.changeType == .statusChanged })
        XCTAssertTrue(logs.contains { $0.changeType == .priorityChanged })
        XCTAssertTrue(logs.contains { $0.changeType == .flagged })
        XCTAssertTrue(logs.contains { $0.changeType == .projectSet })
    }
}
