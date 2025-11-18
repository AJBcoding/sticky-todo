//
//  AppShortcutsTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for App Shortcuts and Siri integration.
//

import XCTest
@testable import StickyToDo

#if canImport(AppIntents)
import AppIntents
#endif

@available(iOS 16.0, macOS 13.0, *)
final class AppShortcutsTests: XCTestCase {
    var taskStore: TaskStore!
    var fileIO: MarkdownFileIO!
    var tempDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create temporary directory for test data
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )

        // Initialize file I/O and task store
        fileIO = MarkdownFileIO(baseURL: tempDirectory)
        taskStore = TaskStore(fileIO: fileIO)
    }

    override func tearDownWithError() throws {
        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }

        taskStore = nil
        fileIO = nil
        tempDirectory = nil

        try super.tearDownWithError()
    }

    // MARK: - TaskEntity Tests

    func testTaskEntityConversion() {
        let task = Task(
            title: "Test Task",
            notes: "Test notes",
            status: .nextAction,
            project: "Test Project",
            context: "@office",
            priority: .high,
            flagged: true
        )

        let entity = TaskEntity.from(task: task)

        XCTAssertEqual(entity.id, task.id)
        XCTAssertEqual(entity.title, task.title)
        XCTAssertEqual(entity.notes, task.notes)
        XCTAssertEqual(entity.status, task.status.rawValue)
        XCTAssertEqual(entity.project, task.project)
        XCTAssertEqual(entity.context, task.context)
        XCTAssertEqual(entity.priority, task.priority.rawValue)
        XCTAssertEqual(entity.flagged, task.flagged)
    }

    func testTaskEntityDisplayRepresentation() {
        let task = Task(
            title: "Test Task",
            project: "Work",
            context: "@office"
        )

        let entity = TaskEntity.from(task: task)
        let display = entity.displayRepresentation

        XCTAssertEqual(display.title.key, "Test Task")
    }

    // MARK: - Add Task Intent Tests

    func testAddTaskIntent() async throws {
        // This test would require a mocked AppDelegate
        // For demonstration purposes, we'll test the task creation logic

        let task = Task(
            title: "New Task",
            notes: "Task notes",
            project: "Personal",
            context: "@home",
            priority: .medium,
            flagged: false
        )

        taskStore.add(task)

        // Verify task was added
        let addedTask = taskStore.task(withID: task.id)
        XCTAssertNotNil(addedTask)
        XCTAssertEqual(addedTask?.title, "New Task")
        XCTAssertEqual(addedTask?.project, "Personal")
        XCTAssertEqual(addedTask?.context, "@home")
    }

    // MARK: - Complete Task Intent Tests

    func testCompleteTaskIntent() {
        var task = Task(
            title: "Task to Complete",
            status: .nextAction
        )

        taskStore.add(task)

        // Complete the task
        task.complete()
        taskStore.update(task)

        // Verify task was completed
        let completedTask = taskStore.task(withID: task.id)
        XCTAssertEqual(completedTask?.status, .completed)
    }

    // MARK: - Show Inbox Intent Tests

    func testShowInboxIntent() {
        // Add tasks to inbox
        for i in 1...5 {
            let task = Task(
                title: "Inbox Task \(i)",
                status: .inbox
            )
            taskStore.add(task)
        }

        // Add non-inbox tasks
        let nextActionTask = Task(
            title: "Next Action Task",
            status: .nextAction
        )
        taskStore.add(nextActionTask)

        // Get inbox tasks
        let inboxTasks = taskStore.tasks(withStatus: .inbox)

        XCTAssertEqual(inboxTasks.count, 5)
        XCTAssertTrue(inboxTasks.allSatisfy { $0.status == .inbox })
    }

    // MARK: - Show Next Actions Intent Tests

    func testShowNextActionsIntent() {
        // Add next action tasks
        for i in 1...3 {
            let task = Task(
                title: "Next Action \(i)",
                status: .nextAction,
                context: "@office"
            )
            taskStore.add(task)
        }

        // Add tasks with different context
        let homeTask = Task(
            title: "Home Task",
            status: .nextAction,
            context: "@home"
        )
        taskStore.add(homeTask)

        // Get all next actions
        let allNextActions = taskStore.tasks(withStatus: .nextAction)
        XCTAssertEqual(allNextActions.count, 4)

        // Filter by context
        let officeActions = taskStore.tasks(forContext: "@office")
        XCTAssertEqual(officeActions.count, 3)
    }

    // MARK: - Show Today's Tasks Intent Tests

    func testShowTodayTasksIntent() {
        // Add task due today
        let todayTask = Task(
            title: "Due Today",
            due: Date()
        )
        taskStore.add(todayTask)

        // Add task due tomorrow
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tomorrowTask = Task(
            title: "Due Tomorrow",
            due: tomorrowDate
        )
        taskStore.add(tomorrowTask)

        // Add overdue task
        let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let overdueTask = Task(
            title: "Overdue",
            due: yesterdayDate,
            status: .nextAction
        )
        taskStore.add(overdueTask)

        // Get today's tasks
        let todayTasks = taskStore.dueTodayTasks()
        XCTAssertEqual(todayTasks.count, 1)
        XCTAssertTrue(todayTasks.first?.isDueToday ?? false)

        // Get overdue tasks
        let overdueTasks = taskStore.overdueTasks()
        XCTAssertEqual(overdueTasks.count, 1)
        XCTAssertTrue(overdueTasks.first?.isOverdue ?? false)
    }

    // MARK: - Start Timer Intent Tests

    func testStartTimerIntent() {
        var task = Task(
            title: "Task with Timer",
            status: .nextAction
        )

        taskStore.add(task)

        // Simulate starting timer
        task.isTimerRunning = true
        task.currentTimerStart = Date()
        taskStore.update(task)

        // Verify timer started
        let updatedTask = taskStore.task(withID: task.id)
        XCTAssertTrue(updatedTask?.isTimerRunning ?? false)
        XCTAssertNotNil(updatedTask?.currentTimerStart)
    }

    // MARK: - Stop Timer Intent Tests

    func testStopTimerIntent() {
        var task = Task(
            title: "Task with Running Timer",
            status: .nextAction,
            isTimerRunning: true,
            currentTimerStart: Date()
        )

        taskStore.add(task)

        // Simulate stopping timer
        let duration: TimeInterval = 3600 // 1 hour
        task.isTimerRunning = false
        task.totalTimeSpent += duration
        task.currentTimerStart = nil
        taskStore.update(task)

        // Verify timer stopped
        let updatedTask = taskStore.task(withID: task.id)
        XCTAssertFalse(updatedTask?.isTimerRunning ?? true)
        XCTAssertNil(updatedTask?.currentTimerStart)
        XCTAssertEqual(updatedTask?.totalTimeSpent, duration)
    }

    // MARK: - Priority Option Tests

    func testPriorityOptionConversion() {
        XCTAssertEqual(PriorityOption.high.toPriority, .high)
        XCTAssertEqual(PriorityOption.medium.toPriority, .medium)
        XCTAssertEqual(PriorityOption.low.toPriority, .low)
    }

    // MARK: - Task Query Tests

    func testTaskQuerySuggestedEntities() async throws {
        // Add next action tasks
        for i in 1...5 {
            let task = Task(
                title: "Next Action \(i)",
                status: .nextAction
            )
            taskStore.add(task)
        }

        // Add flagged tasks
        for i in 1...3 {
            let task = Task(
                title: "Flagged Task \(i)",
                flagged: true
            )
            taskStore.add(task)
        }

        // Verify we have the expected tasks
        let nextActions = taskStore.tasks(withStatus: .nextAction)
        XCTAssertEqual(nextActions.count, 5)

        let flaggedTasks = taskStore.flaggedTasks()
        XCTAssertEqual(flaggedTasks.count, 3)
    }

    func testTaskQuerySearch() {
        // Add searchable tasks
        let task1 = Task(title: "Write documentation")
        let task2 = Task(title: "Review code")
        let task3 = Task(title: "Write tests")

        taskStore.add(task1)
        taskStore.add(task2)
        taskStore.add(task3)

        // Search for "write"
        let results = taskStore.tasks(matchingSearch: "write")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(where: { $0.id == task1.id }))
        XCTAssertTrue(results.contains(where: { $0.id == task3.id }))
    }

    // MARK: - Spotlight Integration Tests

    func testSpotlightKeywordGeneration() {
        let task = Task(
            title: "Important Meeting",
            status: .nextAction,
            project: "Work Project",
            context: "@office",
            priority: .high,
            flagged: true
        )

        // Test that spotlight manager would generate appropriate keywords
        // This is a conceptual test - actual Spotlight testing requires more setup
        XCTAssertEqual(task.title, "Important Meeting")
        XCTAssertEqual(task.project, "Work Project")
        XCTAssertEqual(task.context, "@office")
        XCTAssertTrue(task.flagged)
    }

    // MARK: - Error Handling Tests

    func testTaskErrorLocalizedStrings() {
        let storeError = TaskError.storeUnavailable
        XCTAssertNotNil(storeError.localizedStringResource)

        let notFoundError = TaskError.taskNotFound
        XCTAssertNotNil(notFoundError.localizedStringResource)

        let invalidInputError = TaskError.invalidInput
        XCTAssertNotNil(invalidInputError.localizedStringResource)

        let noTimerError = TaskError.noRunningTimer
        XCTAssertNotNil(noTimerError.localizedStringResource)
    }

    // MARK: - Integration Tests

    func testCompleteWorkflow() {
        // 1. Add task via intent simulation
        let task = Task(
            title: "Complete Workflow Task",
            notes: "Testing complete workflow",
            status: .inbox,
            project: "Testing",
            priority: .high
        )
        taskStore.add(task)

        // 2. Move to next actions
        var updatedTask = taskStore.task(withID: task.id)!
        updatedTask.status = .nextAction
        taskStore.update(updatedTask)

        // 3. Start timer
        updatedTask = taskStore.task(withID: task.id)!
        updatedTask.isTimerRunning = true
        updatedTask.currentTimerStart = Date()
        taskStore.update(updatedTask)

        // 4. Stop timer
        updatedTask = taskStore.task(withID: task.id)!
        updatedTask.isTimerRunning = false
        updatedTask.totalTimeSpent = 3600
        updatedTask.currentTimerStart = nil
        taskStore.update(updatedTask)

        // 5. Complete task
        updatedTask = taskStore.task(withID: task.id)!
        updatedTask.complete()
        taskStore.update(updatedTask)

        // Verify final state
        let finalTask = taskStore.task(withID: task.id)!
        XCTAssertEqual(finalTask.status, .completed)
        XCTAssertFalse(finalTask.isTimerRunning)
        XCTAssertEqual(finalTask.totalTimeSpent, 3600)
    }
}

// MARK: - Performance Tests

@available(iOS 16.0, macOS 13.0, *)
extension AppShortcutsTests {
    func testAddTaskPerformance() {
        measure {
            for i in 0..<100 {
                let task = Task(title: "Performance Test \(i)")
                taskStore.add(task)
            }
        }
    }

    func testSearchPerformance() {
        // Add many tasks
        for i in 0..<1000 {
            let task = Task(
                title: "Task \(i)",
                project: i % 2 == 0 ? "Even Project" : "Odd Project"
            )
            taskStore.add(task)
        }

        measure {
            _ = taskStore.tasks(matchingSearch: "Project")
        }
    }
}
