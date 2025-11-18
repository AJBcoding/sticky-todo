//
//  TimeTrackingTests.swift
//  StickyToDoTests
//
//  Unit tests for time tracking functionality including TimeEntry model,
//  TimeTrackingManager, and time analytics.
//

import XCTest
@testable import StickyToDoCore

final class TimeTrackingTests: XCTestCase {

    // MARK: - TimeEntry Tests

    func testTimeEntryCreation() {
        let taskId = UUID()
        let startTime = Date()
        let entry = TimeEntry(taskId: taskId, startTime: startTime)

        XCTAssertEqual(entry.taskId, taskId)
        XCTAssertEqual(entry.startTime, startTime)
        XCTAssertNil(entry.endTime)
        XCTAssertTrue(entry.isRunning)
    }

    func testTimeEntryDuration() {
        let taskId = UUID()
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600) // 1 hour
        let entry = TimeEntry(
            taskId: taskId,
            startTime: startTime,
            endTime: endTime
        )

        XCTAssertEqual(entry.duration, 3600, accuracy: 0.1)
        XCTAssertFalse(entry.isRunning)
    }

    func testTimeEntryStop() {
        let taskId = UUID()
        var entry = TimeEntry(taskId: taskId)

        XCTAssertTrue(entry.isRunning)
        XCTAssertNil(entry.endTime)

        entry.stop()

        XCTAssertFalse(entry.isRunning)
        XCTAssertNotNil(entry.endTime)
    }

    func testTimeEntryFilePath() {
        let entry = TimeEntry(
            taskId: UUID(),
            created: Date(timeIntervalSince1970: 1700000000) // Nov 2023
        )

        let path = entry.filePath
        XCTAssertTrue(path.hasPrefix("time-entries/"))
        XCTAssertTrue(path.hasSuffix(".md"))
        XCTAssertTrue(path.contains("/2023/"))
    }

    func testTimeEntryDurationDescription() {
        let taskId = UUID()

        // Test with hours
        let entry1 = TimeEntry(
            taskId: taskId,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3665) // 1h 1m 5s
        )
        XCTAssertEqual(entry1.durationDescription, "1h 1m 5s")

        // Test with minutes only
        let entry2 = TimeEntry(
            taskId: taskId,
            startTime: Date(),
            endTime: Date().addingTimeInterval(125) // 2m 5s
        )
        XCTAssertEqual(entry2.durationDescription, "2m 5s")

        // Test with seconds only
        let entry3 = TimeEntry(
            taskId: taskId,
            startTime: Date(),
            endTime: Date().addingTimeInterval(45) // 45s
        )
        XCTAssertEqual(entry3.durationDescription, "45s")
    }

    func testTimeEntryOccurredOn() {
        let calendar = Calendar.current
        let taskId = UUID()
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let entry = TimeEntry(taskId: taskId, startTime: today)

        XCTAssertTrue(entry.occurred(on: today))
        XCTAssertFalse(entry.occurred(on: yesterday))
    }

    func testTimeEntryOccurredInMonth() {
        let calendar = Calendar.current
        let taskId = UUID()
        let today = Date()
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today)!

        let entry = TimeEntry(taskId: taskId, startTime: today)

        XCTAssertTrue(entry.occurred(inMonthOf: today))
        XCTAssertFalse(entry.occurred(inMonthOf: nextMonth))
    }

    func testTimeEntryOverlaps() {
        let taskId = UUID()
        let start1 = Date()
        let end1 = start1.addingTimeInterval(3600) // 1 hour
        let entry1 = TimeEntry(taskId: taskId, startTime: start1, endTime: end1)

        // Overlapping entry
        let start2 = start1.addingTimeInterval(1800) // 30 minutes after start1
        let end2 = start2.addingTimeInterval(3600)
        let entry2 = TimeEntry(taskId: taskId, startTime: start2, endTime: end2)

        // Non-overlapping entry
        let start3 = end1.addingTimeInterval(100)
        let end3 = start3.addingTimeInterval(3600)
        let entry3 = TimeEntry(taskId: taskId, startTime: start3, endTime: end3)

        XCTAssertTrue(entry1.overlaps(with: entry2))
        XCTAssertFalse(entry1.overlaps(with: entry3))
    }

    // MARK: - TimeEntry Array Tests

    func testTimeEntryArrayTotalDuration() {
        let taskId = UUID()
        let entries = [
            TimeEntry(taskId: taskId, startTime: Date(), endTime: Date().addingTimeInterval(1800)),
            TimeEntry(taskId: taskId, startTime: Date(), endTime: Date().addingTimeInterval(3600)),
            TimeEntry(taskId: taskId, startTime: Date(), endTime: Date().addingTimeInterval(900))
        ]

        let total = entries.totalDuration
        XCTAssertEqual(total, 6300, accuracy: 0.1) // 30 + 60 + 15 minutes = 105 minutes = 6300 seconds
    }

    func testTimeEntryArrayGroupedByDate() {
        let calendar = Calendar.current
        let taskId = UUID()
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let entries = [
            TimeEntry(taskId: taskId, startTime: today),
            TimeEntry(taskId: taskId, startTime: today),
            TimeEntry(taskId: taskId, startTime: yesterday)
        ]

        let grouped = entries.grouped(byDate: true)
        XCTAssertEqual(grouped.count, 2) // Two different dates
    }

    func testTimeEntryArrayGroupedByTask() {
        let task1 = UUID()
        let task2 = UUID()

        let entries = [
            TimeEntry(taskId: task1),
            TimeEntry(taskId: task1),
            TimeEntry(taskId: task2)
        ]

        let grouped = entries.grouped(byTask: true)
        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped[task1]?.count, 2)
        XCTAssertEqual(grouped[task2]?.count, 1)
    }

    // MARK: - TimeTrackingManager Tests

    func testStartTimer() {
        let manager = TimeTrackingManager()
        let task = Task(title: "Test Task")

        let updatedTask = manager.startTimer(for: task)

        XCTAssertTrue(updatedTask.isTimerRunning)
        XCTAssertNotNil(updatedTask.currentTimerStart)
        XCTAssertTrue(manager.runningTimers.keys.contains(task.id))
    }

    func testStopTimer() {
        let manager = TimeTrackingManager()
        var task = Task(title: "Test Task")

        task = manager.startTimer(for: task)
        Thread.sleep(forTimeInterval: 0.1) // Wait a bit

        let (updatedTask, entry) = manager.stopTimer(for: task)

        XCTAssertFalse(updatedTask.isTimerRunning)
        XCTAssertNil(updatedTask.currentTimerStart)
        XCTAssertNotNil(entry)
        XCTAssertGreaterThan(updatedTask.totalTimeSpent, 0)
        XCTAssertEqual(manager.runningTimers.count, 0)
    }

    func testToggleTimer() {
        let manager = TimeTrackingManager()
        var task = Task(title: "Test Task")

        // Start
        let (updatedTask1, entry1) = manager.toggleTimer(for: task)
        XCTAssertTrue(updatedTask1.isTimerRunning)
        XCTAssertNil(entry1)

        task = updatedTask1
        Thread.sleep(forTimeInterval: 0.1)

        // Stop
        let (updatedTask2, entry2) = manager.toggleTimer(for: task)
        XCTAssertFalse(updatedTask2.isTimerRunning)
        XCTAssertNotNil(entry2)
    }

    func testCurrentDuration() {
        let manager = TimeTrackingManager()
        var task = Task(title: "Test Task")

        task = manager.startTimer(for: task)
        Thread.sleep(forTimeInterval: 0.1)

        let duration = manager.currentDuration(for: task.id)
        XCTAssertNotNil(duration)
        XCTAssertGreaterThan(duration!, 0)
    }

    func testEntriesForTask() {
        let manager = TimeTrackingManager()
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")

        let entry1 = TimeEntry(taskId: task1.id)
        let entry2 = TimeEntry(taskId: task1.id)
        let entry3 = TimeEntry(taskId: task2.id)

        manager.addEntry(entry1)
        manager.addEntry(entry2)
        manager.addEntry(entry3)

        let task1Entries = manager.entries(for: task1.id)
        XCTAssertEqual(task1Entries.count, 2)

        let task2Entries = manager.entries(for: task2.id)
        XCTAssertEqual(task2Entries.count, 1)
    }

    func testTotalTimeForTask() {
        let manager = TimeTrackingManager()
        let taskId = UUID()

        let entry1 = TimeEntry(
            taskId: taskId,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800)
        )
        let entry2 = TimeEntry(
            taskId: taskId,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )

        manager.addEntry(entry1)
        manager.addEntry(entry2)

        let total = manager.totalTime(for: taskId)
        XCTAssertEqual(total, 5400, accuracy: 0.1) // 30 + 60 minutes
    }

    func testEntriesOnDate() {
        let calendar = Calendar.current
        let manager = TimeTrackingManager()
        let taskId = UUID()
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        manager.addEntry(TimeEntry(taskId: taskId, startTime: today))
        manager.addEntry(TimeEntry(taskId: taskId, startTime: today))
        manager.addEntry(TimeEntry(taskId: taskId, startTime: yesterday))

        let todayEntries = manager.entries(on: today)
        XCTAssertEqual(todayEntries.count, 2)
    }

    func testAnalytics() {
        let manager = TimeTrackingManager()

        let task1 = Task(title: "Task 1", project: "Project A", context: "@office")
        let task2 = Task(title: "Task 2", project: "Project B", context: "@office")
        let task3 = Task(title: "Task 3", project: "Project A", context: "@home")

        manager.addEntry(TimeEntry(
            taskId: task1.id,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        ))
        manager.addEntry(TimeEntry(
            taskId: task2.id,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800)
        ))
        manager.addEntry(TimeEntry(
            taskId: task3.id,
            startTime: Date(),
            endTime: Date().addingTimeInterval(7200)
        ))

        let analytics = manager.calculateAnalytics(for: [task1, task2, task3])

        XCTAssertEqual(analytics.totalTime, 12600, accuracy: 0.1)
        XCTAssertEqual(analytics.entryCount, 3)
        XCTAssertEqual(analytics.timeByProject.count, 2)
        XCTAssertEqual(analytics.timeByProject["Project A"], 10800, accuracy: 0.1)
        XCTAssertEqual(analytics.timeByProject["Project B"], 1800, accuracy: 0.1)
        XCTAssertEqual(analytics.timeByContext.count, 2)
    }

    func testTopTasks() {
        let manager = TimeTrackingManager()

        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")
        let task3 = Task(title: "Task 3")

        manager.addEntry(TimeEntry(
            taskId: task1.id,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        ))
        manager.addEntry(TimeEntry(
            taskId: task2.id,
            startTime: Date(),
            endTime: Date().addingTimeInterval(7200)
        ))
        manager.addEntry(TimeEntry(
            taskId: task3.id,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800)
        ))

        let topTasks = manager.topTasks(count: 2, from: [task1, task2, task3])

        XCTAssertEqual(topTasks.count, 2)
        XCTAssertEqual(topTasks[0].task.id, task2.id) // Highest duration first
        XCTAssertEqual(topTasks[1].task.id, task1.id)
    }

    func testCSVExport() {
        let manager = TimeTrackingManager()
        let task = Task(title: "Test Task", project: "Test Project", context: "@office")

        manager.addEntry(TimeEntry(
            taskId: task.id,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        ))

        let csv = manager.exportToCSV(tasks: [task])

        XCTAssertTrue(csv.contains("Date,Start Time,End Time,Duration (minutes)"))
        XCTAssertTrue(csv.contains("Test Task"))
        XCTAssertTrue(csv.contains("Test Project"))
        XCTAssertTrue(csv.contains("@office"))
    }

    // MARK: - Task Timer Properties Tests

    func testTaskTimerProperties() {
        var task = Task(title: "Test Task")

        XCTAssertFalse(task.isTimerRunning)
        XCTAssertNil(task.currentTimerStart)
        XCTAssertEqual(task.totalTimeSpent, 0)

        task.isTimerRunning = true
        task.currentTimerStart = Date()
        task.totalTimeSpent = 3600

        XCTAssertTrue(task.isTimerRunning)
        XCTAssertNotNil(task.currentTimerStart)
        XCTAssertEqual(task.totalTimeSpent, 3600)
    }

    func testTaskTimeSpentDescription() {
        var task = Task(title: "Test Task")

        XCTAssertNil(task.timeSpentDescription)

        task.totalTimeSpent = 3665 // 1h 1m 5s
        XCTAssertEqual(task.timeSpentDescription, "1h 1m")

        task.totalTimeSpent = 125 // 2m 5s
        XCTAssertEqual(task.timeSpentDescription, "2m")

        task.totalTimeSpent = 45
        XCTAssertEqual(task.timeSpentDescription, "45s")
    }

    func testTaskCurrentTimerDuration() {
        var task = Task(title: "Test Task")

        XCTAssertNil(task.currentTimerDuration)

        task.isTimerRunning = true
        task.currentTimerStart = Date().addingTimeInterval(-100)

        let duration = task.currentTimerDuration
        XCTAssertNotNil(duration)
        XCTAssertGreaterThan(duration!, 90)
    }

    // MARK: - Helper Methods

    func testFormatDuration() {
        XCTAssertEqual(TimeTrackingManager.formatDuration(3665), "1h 1m")
        XCTAssertEqual(TimeTrackingManager.formatDuration(125), "2m")
        XCTAssertEqual(TimeTrackingManager.formatDuration(45), "45s")
    }

    func testFormatDurationPrecise() {
        XCTAssertEqual(TimeTrackingManager.formatDurationPrecise(3665), "1h 1m 5s")
        XCTAssertEqual(TimeTrackingManager.formatDurationPrecise(125), "2m 5s")
        XCTAssertEqual(TimeTrackingManager.formatDurationPrecise(45), "45s")
    }
}
