//
//  TaskStoreTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for TaskStore operations.
//

import XCTest
import Combine
@testable import StickyToDo

final class TaskStoreTests: XCTestCase {

    var tempDirectory: URL!
    var fileIO: MarkdownFileIO!
    var taskStore: TaskStore!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TaskStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        fileIO = MarkdownFileIO(rootDirectory: tempDirectory)
        try fileIO.ensureDirectoryStructure()

        taskStore = TaskStore(fileIO: fileIO)
        cancellables = []
    }

    override func tearDown() async throws {
        taskStore.cancelAllPendingSaves()
        cancellables = nil
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - Initialization and Loading Tests

    func testInitialState() {
        XCTAssertEqual(taskStore.tasks.count, 0)
        XCTAssertEqual(taskStore.projects.count, 0)
        XCTAssertEqual(taskStore.contexts.count, 0)
        XCTAssertEqual(taskStore.taskCount, 0)
    }

    func testLoadAllTasks() throws {
        // Create test tasks
        let tasks = [
            Task(title: "Task 1", status: .inbox),
            Task(title: "Task 2", status: .nextAction, project: "Project A"),
            Task(title: "Task 3", status: .waiting, context: "@office")
        ]

        for task in tasks {
            try fileIO.writeTask(task)
        }

        // Load tasks
        try taskStore.loadAll()

        // Wait for async loading
        let expectation = XCTestExpectation(description: "Tasks loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(taskStore.taskCount, tasks.count)
        XCTAssertEqual(taskStore.projects.count, 1)
        XCTAssertTrue(taskStore.projects.contains("Project A"))
        XCTAssertEqual(taskStore.contexts.count, 1)
        XCTAssertTrue(taskStore.contexts.contains("@office"))
    }

    // MARK: - CRUD Operation Tests

    func testAddTask() {
        let expectation = XCTestExpectation(description: "Task added")
        var observedTasks: [Task] = []

        taskStore.$tasks.sink { tasks in
            observedTasks = tasks
            if tasks.count > 0 {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        let task = Task(title: "New Task", status: .inbox)
        taskStore.add(task)

        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(observedTasks.count, 1)
        XCTAssertEqual(observedTasks[0].id, task.id)
        XCTAssertEqual(taskStore.taskCount, 1)
    }

    func testAddDuplicateTask() {
        let task = Task(title: "Duplicate Test", status: .inbox)

        taskStore.add(task)
        taskStore.add(task) // Try to add same task again

        // Wait for tasks to be added
        let expectation = XCTestExpectation(description: "Tasks processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(taskStore.taskCount, 1) // Should only be added once
    }

    func testUpdateTask() {
        var task = Task(title: "Original Title", status: .inbox)
        taskStore.add(task)

        task.title = "Updated Title"
        task.status = .nextAction
        taskStore.update(task)

        let expectation = XCTestExpectation(description: "Task updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let updated = taskStore.task(withID: task.id)
        XCTAssertNotNil(updated)
        XCTAssertEqual(updated?.title, "Updated Title")
        XCTAssertEqual(updated?.status, .nextAction)
    }

    func testDeleteTask() {
        let task = Task(title: "Delete Me", status: .inbox)
        taskStore.add(task)

        let expectation1 = XCTestExpectation(description: "Task added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)

        XCTAssertEqual(taskStore.taskCount, 1)

        taskStore.delete(task)

        let expectation2 = XCTestExpectation(description: "Task deleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)

        XCTAssertEqual(taskStore.taskCount, 0)
        XCTAssertNil(taskStore.task(withID: task.id))
    }

    // MARK: - Filtering Tests

    func testTasksMatchingFilter() {
        let tasks = [
            Task(title: "Inbox Task", status: .inbox),
            Task(title: "Next Action", status: .nextAction),
            Task(title: "Waiting", status: .waiting),
            Task(title: "Project Task", status: .nextAction, project: "TestProject")
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let inboxTasks = taskStore.tasks(matching: Filter(status: .inbox))
        XCTAssertEqual(inboxTasks.count, 1)

        let nextActionTasks = taskStore.tasks(matching: Filter(status: .nextAction))
        XCTAssertEqual(nextActionTasks.count, 2)

        let projectTasks = taskStore.tasks(matching: Filter(project: "TestProject"))
        XCTAssertEqual(projectTasks.count, 1)
    }

    func testTasksMatchingSearch() {
        let tasks = [
            Task(title: "Buy groceries", notes: "Get milk and bread"),
            Task(title: "Call plumber", notes: "Fix the leak"),
            Task(title: "Write report", notes: "Annual report for Q4")
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let groceryTasks = taskStore.tasks(matchingSearch: "groceries")
        XCTAssertEqual(groceryTasks.count, 1)

        let milkTasks = taskStore.tasks(matchingSearch: "milk")
        XCTAssertEqual(milkTasks.count, 1)

        let reportTasks = taskStore.tasks(matchingSearch: "report")
        XCTAssertEqual(reportTasks.count, 1)

        let noMatch = taskStore.tasks(matchingSearch: "nonexistent")
        XCTAssertEqual(noMatch.count, 0)
    }

    func testTasksByProject() {
        let tasks = [
            Task(title: "Task 1", project: "Project A"),
            Task(title: "Task 2", project: "Project A"),
            Task(title: "Task 3", project: "Project B"),
            Task(title: "Task 4")
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let projectATasks = taskStore.tasks(forProject: "Project A")
        XCTAssertEqual(projectATasks.count, 2)

        let projectBTasks = taskStore.tasks(forProject: "Project B")
        XCTAssertEqual(projectBTasks.count, 1)
    }

    func testTasksByContext() {
        let tasks = [
            Task(title: "Task 1", context: "@office"),
            Task(title: "Task 2", context: "@office"),
            Task(title: "Task 3", context: "@home"),
            Task(title: "Task 4")
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let officeTasks = taskStore.tasks(forContext: "@office")
        XCTAssertEqual(officeTasks.count, 2)

        let homeTasks = taskStore.tasks(forContext: "@home")
        XCTAssertEqual(homeTasks.count, 1)
    }

    func testTasksByStatus() {
        let tasks = [
            Task(title: "Task 1", status: .inbox),
            Task(title: "Task 2", status: .nextAction),
            Task(title: "Task 3", status: .nextAction),
            Task(title: "Task 4", status: .completed)
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let inboxTasks = taskStore.tasks(withStatus: .inbox)
        XCTAssertEqual(inboxTasks.count, 1)

        let nextActionTasks = taskStore.tasks(withStatus: .nextAction)
        XCTAssertEqual(nextActionTasks.count, 2)
    }

    // MARK: - Specialized Filtering Tests

    func testOverdueTasks() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let tasks = [
            Task(title: "Overdue Task", status: .nextAction, due: yesterday),
            Task(title: "Future Task", status: .nextAction, due: tomorrow),
            Task(title: "Completed Overdue", status: .completed, due: yesterday)
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let overdue = taskStore.overdueTasks()
        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue[0].title, "Overdue Task")
    }

    func testDueTodayTasks() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let tasks = [
            Task(title: "Due Today", status: .nextAction, due: today),
            Task(title: "Due Tomorrow", status: .nextAction, due: tomorrow)
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let dueToday = taskStore.dueTodayTasks()
        XCTAssertEqual(dueToday.count, 1)
        XCTAssertEqual(dueToday[0].title, "Due Today")
    }

    func testFlaggedTasks() {
        let tasks = [
            Task(title: "Flagged 1", flagged: true),
            Task(title: "Not Flagged", flagged: false),
            Task(title: "Flagged 2", flagged: true)
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let flagged = taskStore.flaggedTasks()
        XCTAssertEqual(flagged.count, 2)
    }

    // MARK: - Batch Operations Tests

    func testUpdateBatch() {
        var tasks = [
            Task(title: "Batch 1", status: .inbox),
            Task(title: "Batch 2", status: .inbox),
            Task(title: "Batch 3", status: .inbox)
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation1 = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)

        // Update all to next action
        for i in 0..<tasks.count {
            tasks[i].status = .nextAction
        }

        taskStore.updateBatch(tasks)

        let expectation2 = XCTestExpectation(description: "Tasks updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)

        let nextActionTasks = taskStore.tasks(withStatus: .nextAction)
        XCTAssertEqual(nextActionTasks.count, 3)
    }

    func testDeleteBatch() {
        let tasks = [
            Task(title: "Delete 1", status: .inbox),
            Task(title: "Delete 2", status: .inbox),
            Task(title: "Keep", status: .inbox)
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation1 = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)

        XCTAssertEqual(taskStore.taskCount, 3)

        taskStore.deleteBatch(Array(tasks[0..<2]))

        let expectation2 = XCTestExpectation(description: "Tasks deleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)

        XCTAssertEqual(taskStore.taskCount, 1)
    }

    // MARK: - Statistics Tests

    func testTaskCounts() {
        let tasks = [
            Task(title: "Inbox 1", status: .inbox),
            Task(title: "Inbox 2", status: .inbox),
            Task(title: "Next 1", status: .nextAction),
            Task(title: "Completed 1", status: .completed)
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(taskStore.taskCount, 4)
        XCTAssertEqual(taskStore.activeTaskCount, 3)
        XCTAssertEqual(taskStore.completedTaskCount, 1)
        XCTAssertEqual(taskStore.inboxTaskCount, 2)
        XCTAssertEqual(taskStore.actionableTaskCount, 1)
    }

    // MARK: - Sorting Tests

    func testSortedTasksByTitle() {
        let tasks = [
            Task(title: "Zebra"),
            Task(title: "Apple"),
            Task(title: "Mango")
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let sorted = taskStore.sortedTasks(by: .title)
        XCTAssertEqual(sorted[0].title, "Apple")
        XCTAssertEqual(sorted[1].title, "Mango")
        XCTAssertEqual(sorted[2].title, "Zebra")
    }

    func testSortedTasksByPriority() {
        let tasks = [
            Task(title: "Low", priority: .low),
            Task(title: "High", priority: .high),
            Task(title: "Medium", priority: .medium)
        ]

        for task in tasks {
            taskStore.add(task)
        }

        let expectation = XCTestExpectation(description: "Tasks added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let sorted = taskStore.sortedTasks(by: .priority)
        XCTAssertEqual(sorted[0].priority, .high)
        XCTAssertEqual(sorted[1].priority, .medium)
        XCTAssertEqual(sorted[2].priority, .low)
    }

    // MARK: - Debounced Save Tests

    func testDebouncedSave() throws {
        let task = Task(title: "Debounce Test", status: .inbox)
        taskStore.add(task)

        // Wait for debounce interval plus buffer
        let expectation = XCTestExpectation(description: "Task saved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Verify file was written
        let url = fileIO.taskURL(for: task)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testImmediateSave() throws {
        let task = Task(title: "Immediate Save", status: .inbox)
        taskStore.add(task)

        // Immediate save should write instantly
        try taskStore.saveImmediately(task)

        let url = fileIO.taskURL(for: task)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: - Observation Tests

    func testTasksPublisher() {
        let expectation = XCTestExpectation(description: "Publisher fired")
        var receivedCount = 0

        taskStore.$tasks.sink { tasks in
            receivedCount = tasks.count
            if receivedCount > 0 {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        let task = Task(title: "Publisher Test", status: .inbox)
        taskStore.add(task)

        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(receivedCount, 1)
    }

    func testDerivedDataUpdates() {
        let task1 = Task(title: "Task 1", project: "Project A", context: "@office")
        let task2 = Task(title: "Task 2", project: "Project B", context: "@home")

        taskStore.add(task1)
        taskStore.add(task2)

        let expectation = XCTestExpectation(description: "Derived data updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(taskStore.projects.count, 2)
        XCTAssertTrue(taskStore.projects.contains("Project A"))
        XCTAssertTrue(taskStore.projects.contains("Project B"))

        XCTAssertEqual(taskStore.contexts.count, 2)
        XCTAssertTrue(taskStore.contexts.contains("@office"))
        XCTAssertTrue(taskStore.contexts.contains("@home"))
    }
}
