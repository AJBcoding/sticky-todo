//
//  AnalyticsTests.swift
//  StickyToDoTests
//
//  Tests for analytics calculation functionality.
//

import XCTest
@testable import StickyToDoCore

final class AnalyticsTests: XCTestCase {

    var calculator: AnalyticsCalculator!
    var testTasks: [Task]!

    override func setUpWithError() throws {
        calculator = AnalyticsCalculator()

        // Create comprehensive test dataset
        let calendar = Calendar.current
        let now = Date()

        testTasks = [
            // Completed tasks
            Task(
                title: "Completed Task 1",
                status: .completed,
                project: "Project A",
                context: "@work",
                priority: .high,
                totalTimeSpent: 3600, // 1 hour
                created: calendar.date(byAdding: .day, value: -10, to: now)!,
                modified: calendar.date(byAdding: .day, value: -5, to: now)!
            ),
            Task(
                title: "Completed Task 2",
                status: .completed,
                project: "Project A",
                context: "@home",
                priority: .medium,
                totalTimeSpent: 1800, // 30 minutes
                created: calendar.date(byAdding: .day, value: -8, to: now)!,
                modified: calendar.date(byAdding: .day, value: -3, to: now)!
            ),
            Task(
                title: "Completed Task 3",
                status: .completed,
                project: "Project B",
                context: "@work",
                priority: .low,
                totalTimeSpent: 7200, // 2 hours
                created: calendar.date(byAdding: .day, value: -6, to: now)!,
                modified: calendar.date(byAdding: .day, value: -2, to: now)!
            ),

            // Active tasks
            Task(
                title: "Next Action Task",
                status: .nextAction,
                project: "Project A",
                context: "@work",
                priority: .high,
                created: calendar.date(byAdding: .day, value: -2, to: now)!
            ),
            Task(
                title: "Inbox Task",
                status: .inbox,
                project: "Project B",
                priority: .medium,
                created: calendar.date(byAdding: .day, value: -1, to: now)!
            ),
            Task(
                title: "Waiting Task",
                status: .waiting,
                project: "Project C",
                context: "@phone",
                priority: .low,
                created: now
            ),
            Task(
                title: "Someday Task",
                status: .someday,
                project: "Project C",
                priority: .low,
                created: now
            )
        ]
    }

    override func tearDownWithError() throws {
        calculator = nil
        testTasks = nil
    }

    // MARK: - Basic Analytics Tests

    func testBasicCounts() {
        let analytics = calculator.calculate(for: testTasks)

        XCTAssertEqual(analytics.totalTasks, 7)
        XCTAssertEqual(analytics.completedTasks, 3)
        XCTAssertEqual(analytics.activeTasks, 4)
    }

    func testCompletionRate() {
        let analytics = calculator.calculate(for: testTasks)

        let expectedRate = 3.0 / 7.0
        XCTAssertEqual(analytics.completionRate, expectedRate, accuracy: 0.01)
        XCTAssertEqual(analytics.completionRateString, "42.9%")
    }

    // MARK: - Distribution Tests

    func testStatusDistribution() {
        let analytics = calculator.calculate(for: testTasks)

        XCTAssertEqual(analytics.tasksByStatus[.completed], 3)
        XCTAssertEqual(analytics.tasksByStatus[.nextAction], 1)
        XCTAssertEqual(analytics.tasksByStatus[.inbox], 1)
        XCTAssertEqual(analytics.tasksByStatus[.waiting], 1)
        XCTAssertEqual(analytics.tasksByStatus[.someday], 1)
    }

    func testPriorityDistribution() {
        let analytics = calculator.calculate(for: testTasks)

        XCTAssertEqual(analytics.tasksByPriority[.high], 2)
        XCTAssertEqual(analytics.tasksByPriority[.medium], 2)
        XCTAssertEqual(analytics.tasksByPriority[.low], 3)
    }

    func testProjectDistribution() {
        let analytics = calculator.calculate(for: testTasks)

        XCTAssertEqual(analytics.tasksByProject["Project A"], 3)
        XCTAssertEqual(analytics.tasksByProject["Project B"], 2)
        XCTAssertEqual(analytics.tasksByProject["Project C"], 2)
    }

    func testContextDistribution() {
        let analytics = calculator.calculate(for: testTasks)

        XCTAssertEqual(analytics.tasksByContext["@work"], 3)
        XCTAssertEqual(analytics.tasksByContext["@home"], 1)
        XCTAssertEqual(analytics.tasksByContext["@phone"], 1)
    }

    // MARK: - Time Metrics Tests

    func testTotalTimeSpent() {
        let analytics = calculator.calculate(for: testTasks)

        // 3600 + 1800 + 7200 = 12600 seconds
        XCTAssertEqual(analytics.totalTimeSpent, 12600, accuracy: 0.1)
    }

    func testAverageTimePerTask() {
        let analytics = calculator.calculate(for: testTasks)

        // 12600 / 3 (only tasks with time) = 4200 seconds
        XCTAssertEqual(analytics.averageTimePerTask, 4200, accuracy: 0.1)
    }

    func testAverageCompletionTime() {
        let analytics = calculator.calculate(for: testTasks)

        // Task 1: 5 days, Task 2: 5 days, Task 3: 4 days
        // Average: (5 + 5 + 4) / 3 = 4.67 days = 403200 seconds
        XCTAssertNotNil(analytics.averageCompletionTime)
        XCTAssertGreaterThan(analytics.averageCompletionTime!, 0)
    }

    // MARK: - Productivity Trends Tests

    func testCompletionsByDay() {
        let analytics = calculator.calculate(for: testTasks)

        // Should have completions grouped by day of week
        XCTAssertGreaterThan(analytics.completionsByDay.count, 0)

        let totalCompletions = analytics.completionsByDay.values.reduce(0, +)
        XCTAssertEqual(totalCompletions, 3) // 3 completed tasks
    }

    func testCompletionsByHour() {
        let analytics = calculator.calculate(for: testTasks)

        let totalCompletions = analytics.completionsByHour.values.reduce(0, +)
        XCTAssertEqual(totalCompletions, 3)
    }

    func testMostProductiveProjects() {
        let analytics = calculator.calculate(for: testTasks)

        // Project A has 2 completed tasks, Project B has 1
        XCTAssertGreaterThan(analytics.mostProductiveProjects.count, 0)

        let topProject = analytics.mostProductiveProjects.first!
        XCTAssertEqual(topProject.project, "Project A")
        XCTAssertEqual(topProject.completed, 2)
    }

    func testMostProductiveDays() {
        let analytics = calculator.calculate(for: testTasks)

        XCTAssertGreaterThan(analytics.mostProductiveDays.count, 0)
    }

    // MARK: - Date Range Filter Tests

    func testDateRangeFilter() {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        let endDate = now

        let dateRange = DateInterval(start: startDate, end: endDate)
        let analytics = calculator.calculate(for: testTasks, dateRange: dateRange)

        // Should only include tasks created in the last 7 days
        XCTAssertLessThanOrEqual(analytics.totalTasks, testTasks.count)
    }

    // MARK: - Weekly Completion Rate Tests

    func testWeeklyCompletionRate() {
        let weeklyData = calculator.weeklyCompletionRate(for: testTasks, weeks: 4)

        XCTAssertEqual(weeklyData.count, 4)

        // Total completions should equal completed tasks
        let totalCompletions = weeklyData.reduce(0) { $0 + $1.1 }
        XCTAssertEqual(totalCompletions, 3)
    }

    // MARK: - Productivity Score Tests

    func testProductivityScore() {
        let score = calculator.productivityScore(for: testTasks)

        // Score should be between 0 and 1
        XCTAssertGreaterThanOrEqual(score, 0.0)
        XCTAssertLessThanOrEqual(score, 1.0)
    }

    func testProductivityScoreWithAllCompleted() {
        let allCompleted = testTasks.map { task -> Task in
            var modified = task
            modified.status = .completed
            return modified
        }

        let score = calculator.productivityScore(for: allCompleted)

        // Should have high score with all completed
        XCTAssertGreaterThan(score, 0.5)
    }

    func testProductivityScoreWithAllInbox() {
        let allInbox = testTasks.map { task -> Task in
            var modified = task
            modified.status = .inbox
            return modified
        }

        let score = calculator.productivityScore(for: allInbox)

        // Should have lower score with all in inbox
        XCTAssertLessThan(score, 0.5)
    }

    func testProductivityScoreWithOverdue() {
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .day, value: -7, to: Date())!

        let overdueTasks = testTasks.map { task -> Task in
            var modified = task
            modified.due = pastDate
            return modified
        }

        let score = calculator.productivityScore(for: overdueTasks)

        // Should have lower score with overdue tasks
        XCTAssertLessThan(score, 0.7)
    }

    // MARK: - Edge Cases Tests

    func testEmptyTaskList() {
        let analytics = calculator.calculate(for: [])

        XCTAssertEqual(analytics.totalTasks, 0)
        XCTAssertEqual(analytics.completedTasks, 0)
        XCTAssertEqual(analytics.completionRate, 0.0)
        XCTAssertEqual(analytics.totalTimeSpent, 0.0)
    }

    func testSingleTask() {
        let singleTask = [testTasks[0]]
        let analytics = calculator.calculate(for: singleTask)

        XCTAssertEqual(analytics.totalTasks, 1)
        XCTAssertEqual(analytics.completedTasks, 1)
        XCTAssertEqual(analytics.completionRate, 1.0)
    }

    func testTasksWithNoProjects() {
        let noProjectTasks = testTasks.map { task -> Task in
            var modified = task
            modified.project = nil
            return modified
        }

        let analytics = calculator.calculate(for: noProjectTasks)

        XCTAssertEqual(analytics.tasksByProject["No Project"], 7)
    }

    func testTasksWithNoTime() {
        let noTimeTasks = testTasks.map { task -> Task in
            var modified = task
            modified.totalTimeSpent = 0
            return modified
        }

        let analytics = calculator.calculate(for: noTimeTasks)

        XCTAssertEqual(analytics.totalTimeSpent, 0.0)
        XCTAssertEqual(analytics.averageTimePerTask, 0.0)
    }

    // MARK: - Formatting Tests

    func testTimeSpentFormatting() {
        let analytics = calculator.calculate(for: testTasks)

        // 12600 seconds = 3h 30m
        XCTAssertTrue(analytics.totalTimeSpentString.contains("h"))
    }

    func testCompletionRateFormatting() {
        let analytics = calculator.calculate(for: testTasks)

        XCTAssertTrue(analytics.completionRateString.hasSuffix("%"))
    }

    // MARK: - Performance Tests

    func testAnalyticsPerformance() {
        // Create large dataset
        var largeTasks: [Task] = []
        for i in 0..<10000 {
            largeTasks.append(Task(
                title: "Task \(i)",
                status: i % 3 == 0 ? .completed : .nextAction,
                project: "Project \(i % 100)",
                priority: i % 2 == 0 ? .high : .low,
                totalTimeSpent: Double(i % 3600)
            ))
        }

        measure {
            _ = calculator.calculate(for: largeTasks)
        }
    }

    func testWeeklyCompletionPerformance() {
        // Create dataset with many completions
        var weeklyTasks: [Task] = []
        let calendar = Calendar.current
        let now = Date()

        for i in 0..<1000 {
            let daysAgo = i % 84 // 12 weeks
            let created = calendar.date(byAdding: .day, value: -daysAgo, to: now)!

            weeklyTasks.append(Task(
                title: "Task \(i)",
                status: .completed,
                created: created,
                modified: created
            ))
        }

        measure {
            _ = calculator.weeklyCompletionRate(for: weeklyTasks, weeks: 12)
        }
    }
}
