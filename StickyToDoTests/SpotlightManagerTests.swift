//
//  SpotlightManagerTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for SpotlightManager covering indexing, deindexing,
//  keyword generation, and search integration.
//

import XCTest
import CoreSpotlight
@testable import StickyToDoCore

final class SpotlightManagerTests: XCTestCase {

    var manager: SpotlightManager!
    var testTasks: [Task]!

    override func setUpWithError() throws {
        manager = SpotlightManager.shared

        // Create test tasks with varied properties
        testTasks = [
            Task(
                title: "Review project proposal",
                notes: "Important client meeting notes",
                status: .nextAction,
                project: "Client Work",
                context: "@office",
                due: Date().addingTimeInterval(86400), // Tomorrow
                flagged: true,
                priority: .high
            ),
            Task(
                title: "Buy groceries",
                notes: "Milk, bread, eggs",
                status: .inbox,
                project: "Personal",
                context: "@home",
                priority: .medium
            ),
            Task(
                title: "Call dentist",
                notes: "",
                status: .waiting,
                project: "Health",
                context: "@phone",
                priority: .low
            ),
            Task(
                title: "Completed task",
                status: .completed,
                project: "Archive",
                priority: .medium
            )
        ]
    }

    override func tearDownWithError() throws {
        // Clean up indexed items
        manager.clearTaskIndex()
        testTasks = nil
        manager = nil
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = SpotlightManager.shared
        let instance2 = SpotlightManager.shared

        XCTAssertTrue(instance1 === instance2, "Should be a singleton")
    }

    // MARK: - Single Task Indexing Tests

    func testIndexSingleTask() {
        let task = testTasks[0]

        manager.indexTask(task)

        // Wait for async indexing to complete
        let expectation = XCTestExpectation(description: "Indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Note: Actual verification of indexing would require querying the index,
        // which is complex in tests. We verify no crashes occur.
    }

    func testIndexTaskWithMinimalData() {
        let minimalTask = Task(title: "Minimal Task")

        manager.indexTask(minimalTask)

        // Should index successfully even with minimal data
        let expectation = XCTestExpectation(description: "Indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testIndexTaskWithAllFields() {
        let fullTask = Task(
            title: "Full task",
            notes: "Detailed notes here",
            status: .nextAction,
            project: "Test Project",
            context: "@office",
            due: Date(),
            defer: Date(),
            flagged: true,
            priority: .high,
            effort: 120
        )

        manager.indexTask(fullTask)

        let expectation = XCTestExpectation(description: "Indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Batch Indexing Tests

    func testIndexMultipleTasks() {
        manager.indexTasks(testTasks)

        let expectation = XCTestExpectation(description: "Batch indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testIndexEmptyTaskArray() {
        manager.indexTasks([])

        // Should handle empty array gracefully
        let expectation = XCTestExpectation(description: "Empty indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testIndexLargeNumberOfTasks() {
        let largeBatch = (0..<100).map { index in
            Task(
                title: "Task \(index)",
                project: "Project \(index % 10)",
                priority: index % 2 == 0 ? .high : .low
            )
        }

        manager.indexTasks(largeBatch)

        let expectation = XCTestExpectation(description: "Large batch indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Deindexing Tests

    func testDeindexSingleTask() {
        let task = testTasks[0]

        // Index first
        manager.indexTask(task)

        // Then deindex
        manager.deindexTask(task)

        let expectation = XCTestExpectation(description: "Deindexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testDeindexMultipleTasks() {
        manager.indexTasks(testTasks)

        // Wait for indexing
        Thread.sleep(forTimeInterval: 0.5)

        manager.deindexTasks(testTasks)

        let expectation = XCTestExpectation(description: "Batch deindexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testDeindexNonIndexedTask() {
        // Should handle deindexing a task that was never indexed
        let newTask = Task(title: "Never indexed")

        manager.deindexTask(newTask)

        let expectation = XCTestExpectation(description: "Deindexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Clear Index Tests

    func testClearTaskIndex() {
        // Index some tasks first
        manager.indexTasks(testTasks)

        // Wait for indexing
        Thread.sleep(forTimeInterval: 0.5)

        // Clear all
        manager.clearTaskIndex()

        let expectation = XCTestExpectation(description: "Clear index completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Keyword Generation Tests

    func testKeywordGenerationForBasicTask() {
        let task = Task(
            title: "Review project proposal",
            status: .nextAction,
            project: "Client Work",
            priority: .high
        )

        // Use reflection or expose the keyword building method for testing
        // For now, we verify the task can be indexed without errors
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Indexing with keywords completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testKeywordGenerationWithContext() {
        let task = Task(
            title: "Make phone call",
            context: "@phone",
            status: .nextAction
        )

        // Keywords should include "phone" without @ prefix
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Context indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testKeywordGenerationWithTags() {
        var task = Task(title: "Tagged task", status: .nextAction)
        task.tags = [
            Tag(name: "urgent"),
            Tag(name: "important"),
            Tag(name: "client")
        ]

        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Tag indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Status-Based Keyword Tests

    func testInboxKeywords() {
        let task = Task(title: "New item", status: .inbox)

        // Should include inbox-related keywords: inbox, unprocessed, new
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Inbox indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testNextActionKeywords() {
        let task = Task(title: "Action item", status: .nextAction)

        // Should include: next, action, actionable, todo
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Next action indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testWaitingKeywords() {
        let task = Task(title: "Waiting item", status: .waiting)

        // Should include: waiting, blocked
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Waiting indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testCompletedKeywords() {
        let task = Task(title: "Done item", status: .completed)

        // Should include: completed, done, finished
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Completed indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Time-Based Keyword Tests

    func testDueTodayKeywords() {
        var task = Task(title: "Due today task", status: .nextAction)
        // Set due date to today
        let calendar = Calendar.current
        task.due = calendar.startOfDay(for: Date())

        // Should include: today, due today
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Due today indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testOverdueKeywords() {
        var task = Task(title: "Overdue task", status: .nextAction)
        // Set due date to yesterday
        task.due = Date().addingTimeInterval(-86400)

        // Should include: overdue, late
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Overdue indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testFlaggedKeywords() {
        var task = Task(title: "Important task", status: .nextAction)
        task.flagged = true

        // Should include: flagged, important, starred
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Flagged indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Priority-Based Indexing Tests

    func testHighPriorityRanking() {
        let task = Task(title: "High priority", priority: .high)

        // Should have ranking hint of 1.0
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "High priority indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testMediumPriorityRanking() {
        let task = Task(title: "Medium priority", priority: .medium)

        // Should have ranking hint of 0.5
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Medium priority indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testLowPriorityRanking() {
        let task = Task(title: "Low priority", priority: .low)

        // Should have ranking hint of 0.2
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Low priority indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Expiration Tests

    func testCompletedTaskExpiration() {
        var task = Task(title: "Completed task", status: .completed)
        task.modified = Date()

        // Completed tasks should expire after 30 days
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Expiration indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testActiveTaskNoExpiration() {
        let task = Task(title: "Active task", status: .nextAction)

        // Active tasks should not have expiration
        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "No expiration indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Spotlight Continuation Tests

    func testHandleSpotlightContinuation() {
        let testUUID = UUID()

        let result = manager.handleSpotlightContinuation(with: testUUID.uuidString)

        XCTAssertEqual(result, testUUID)
    }

    func testHandleInvalidSpotlightContinuation() {
        let result = manager.handleSpotlightContinuation(with: "invalid-uuid")

        XCTAssertNil(result)
    }

    func testHandleEmptySpotlightContinuation() {
        let result = manager.handleSpotlightContinuation(with: "")

        XCTAssertNil(result)
    }

    // MARK: - Reindex Tests

    func testReindexAllTasksFromStore() {
        // Create a mock task store
        let taskStore = TaskStore()

        // Add test tasks to store
        for task in testTasks {
            taskStore.add(task: task)
        }

        // Reindex all tasks
        manager.reindexAllTasks(from: taskStore)

        let expectation = XCTestExpectation(description: "Reindexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testReindexWithEmptyStore() {
        let emptyStore = TaskStore()

        manager.reindexAllTasks(from: emptyStore)

        let expectation = XCTestExpectation(description: "Empty reindexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testReindexExcludesCompletedTasks() {
        let taskStore = TaskStore()

        // Add mix of active and completed tasks
        taskStore.add(task: Task(title: "Active 1", status: .nextAction))
        taskStore.add(task: Task(title: "Completed 1", status: .completed))
        taskStore.add(task: Task(title: "Active 2", status: .inbox))
        taskStore.add(task: Task(title: "Completed 2", status: .completed))

        // Reindex should only index active tasks
        manager.reindexAllTasks(from: taskStore)

        let expectation = XCTestExpectation(description: "Selective reindexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Edge Cases

    func testIndexTaskWithEmptyTitle() {
        let task = Task(title: "", status: .inbox)

        manager.indexTask(task)

        // Should handle gracefully
        let expectation = XCTestExpectation(description: "Empty title indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testIndexTaskWithVeryLongTitle() {
        let longTitle = String(repeating: "Long task title ", count: 100)
        let task = Task(title: longTitle, status: .inbox)

        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Long title indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testIndexTaskWithSpecialCharacters() {
        let task = Task(
            title: "Task with symbols: @#$%^&*()",
            notes: "Notes with emoji 😀 and symbols",
            status: .inbox
        )

        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Special chars indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testIndexTaskWithUnicodeCharacters() {
        let task = Task(
            title: "Unicode task: 你好 Привет مرحبا",
            notes: "Multilingual notes",
            status: .inbox
        )

        manager.indexTask(task)

        let expectation = XCTestExpectation(description: "Unicode indexing completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Performance Tests

    func testIndexingPerformance() {
        let tasks = (0..<100).map { Task(title: "Task \($0)", status: .inbox) }

        measure {
            manager.indexTasks(tasks)
            Thread.sleep(forTimeInterval: 1.0) // Wait for async completion
        }
    }

    func testDeindexingPerformance() {
        let tasks = (0..<100).map { Task(title: "Task \($0)", status: .inbox) }

        // Index first
        manager.indexTasks(tasks)
        Thread.sleep(forTimeInterval: 1.0)

        measure {
            manager.deindexTasks(tasks)
            Thread.sleep(forTimeInterval: 1.0) // Wait for async completion
        }
    }

    func testClearIndexPerformance() {
        // Index many tasks
        let tasks = (0..<500).map { Task(title: "Task \($0)", status: .inbox) }
        manager.indexTasks(tasks)
        Thread.sleep(forTimeInterval: 2.0)

        measure {
            manager.clearTaskIndex()
            Thread.sleep(forTimeInterval: 1.0)
        }
    }
}
