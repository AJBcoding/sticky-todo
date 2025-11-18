//
//  RecurrenceEngineTests.swift
//  StickyToDoTests
//
//  Unit tests for RecurrenceEngine functionality.
//

import XCTest
@testable import StickyToDo

class RecurrenceEngineTests: XCTestCase {

    // MARK: - Daily Recurrence Tests

    func testDailyRecurrence() {
        let recurrence = Recurrence(frequency: .daily, interval: 1)
        let baseDate = Date()

        let nextDate = RecurrenceEngine.calculateNextOccurrence(from: baseDate, recurrence: recurrence)

        XCTAssertNotNil(nextDate)

        // Next occurrence should be 1 day later
        let calendar = Calendar.current
        let dayDifference = calendar.dateComponents([.day], from: baseDate, to: nextDate!).day
        XCTAssertEqual(dayDifference, 1)
    }

    func testDailyRecurrenceWithInterval() {
        let recurrence = Recurrence(frequency: .daily, interval: 3)
        let baseDate = Date()

        let nextDate = RecurrenceEngine.calculateNextOccurrence(from: baseDate, recurrence: recurrence)

        XCTAssertNotNil(nextDate)

        // Next occurrence should be 3 days later
        let calendar = Calendar.current
        let dayDifference = calendar.dateComponents([.day], from: baseDate, to: nextDate!).day
        XCTAssertEqual(dayDifference, 3)
    }

    // MARK: - Weekly Recurrence Tests

    func testWeeklyRecurrence() {
        let recurrence = Recurrence(frequency: .weekly, interval: 1)
        let baseDate = Date()

        let nextDate = RecurrenceEngine.calculateNextOccurrence(from: baseDate, recurrence: recurrence)

        XCTAssertNotNil(nextDate)

        // Next occurrence should be 1 week later
        let calendar = Calendar.current
        let dayDifference = calendar.dateComponents([.day], from: baseDate, to: nextDate!).day
        XCTAssertEqual(dayDifference, 7)
    }

    func testWeeklyRecurrenceWithSpecificDays() {
        // Test Monday, Wednesday, Friday recurrence
        let recurrence = Recurrence(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [1, 3, 5] // Mon, Wed, Fri
        )

        // Use a known Monday
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 6 // Monday, January 6, 2025
        let monday = Calendar.current.date(from: components)!

        let nextDate = RecurrenceEngine.calculateNextOccurrence(from: monday, recurrence: recurrence)

        XCTAssertNotNil(nextDate)

        // Next should be Wednesday (2 days later)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: nextDate!)
        XCTAssertEqual(weekday, 4) // Wednesday is 4 (0-based would be 3)
    }

    // MARK: - Monthly Recurrence Tests

    func testMonthlyRecurrence() {
        let recurrence = Recurrence(frequency: .monthly, interval: 1, dayOfMonth: 15)

        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        let baseDate = Calendar.current.date(from: components)!

        let nextDate = RecurrenceEngine.calculateNextOccurrence(from: baseDate, recurrence: recurrence)

        XCTAssertNotNil(nextDate)

        // Next should be February 15
        let calendar = Calendar.current
        let nextComponents = calendar.dateComponents([.year, .month, .day], from: nextDate!)
        XCTAssertEqual(nextComponents.year, 2025)
        XCTAssertEqual(nextComponents.month, 2)
        XCTAssertEqual(nextComponents.day, 15)
    }

    func testMonthlyRecurrenceLastDay() {
        let recurrence = Recurrence(
            frequency: .monthly,
            interval: 1,
            useLastDayOfMonth: true
        )

        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 31
        let baseDate = Calendar.current.date(from: components)!

        let nextDate = RecurrenceEngine.calculateNextOccurrence(from: baseDate, recurrence: recurrence)

        XCTAssertNotNil(nextDate)

        // Next should be February 28, 2025 (not a leap year)
        let calendar = Calendar.current
        let nextComponents = calendar.dateComponents([.year, .month, .day], from: nextDate!)
        XCTAssertEqual(nextComponents.year, 2025)
        XCTAssertEqual(nextComponents.month, 2)
        XCTAssertEqual(nextComponents.day, 28)
    }

    // MARK: - Yearly Recurrence Tests

    func testYearlyRecurrence() {
        let recurrence = Recurrence(frequency: .yearly, interval: 1)

        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 15
        let baseDate = Calendar.current.date(from: components)!

        let nextDate = RecurrenceEngine.calculateNextOccurrence(from: baseDate, recurrence: recurrence)

        XCTAssertNotNil(nextDate)

        // Next should be March 15, 2026
        let calendar = Calendar.current
        let nextComponents = calendar.dateComponents([.year, .month, .day], from: nextDate!)
        XCTAssertEqual(nextComponents.year, 2026)
        XCTAssertEqual(nextComponents.month, 3)
        XCTAssertEqual(nextComponents.day, 15)
    }

    // MARK: - End Condition Tests

    func testRecurrenceWithEndDate() {
        let endDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        var recurrence = Recurrence(
            frequency: .daily,
            interval: 1,
            endDate: endDate
        )

        // Set occurrence count high to ensure end date is the limiting factor
        recurrence.occurrenceCount = 0

        XCTAssertFalse(recurrence.isComplete)

        // Move past end date
        recurrence.occurrenceCount = 0
        var pastRecurrence = recurrence
        pastRecurrence.endDate = Date().addingTimeInterval(-86400) // Yesterday

        XCTAssertTrue(pastRecurrence.isComplete)
    }

    func testRecurrenceWithCount() {
        var recurrence = Recurrence(
            frequency: .daily,
            interval: 1,
            count: 10
        )

        recurrence.occurrenceCount = 5
        XCTAssertFalse(recurrence.isComplete)

        recurrence.occurrenceCount = 10
        XCTAssertTrue(recurrence.isComplete)

        recurrence.occurrenceCount = 11
        XCTAssertTrue(recurrence.isComplete)
    }

    // MARK: - Instance Creation Tests

    func testCreateNextOccurrence() {
        let template = Task(
            title: "Daily standup",
            project: "Work",
            due: Date(),
            recurrence: Recurrence(frequency: .daily, interval: 1)
        )

        let instance = RecurrenceEngine.createNextOccurrence(from: template)

        XCTAssertNotNil(instance)
        XCTAssertEqual(instance?.title, template.title)
        XCTAssertEqual(instance?.project, template.project)
        XCTAssertEqual(instance?.originalTaskId, template.id)
        XCTAssertNotNil(instance?.occurrenceDate)
        XCTAssertNil(instance?.recurrence) // Instances don't have recurrence
        XCTAssertTrue(instance?.positions.isEmpty ?? false) // No positions
    }

    func testCreateOccurrenceFromCompletedRecurrence() {
        var recurrence = Recurrence(frequency: .daily, interval: 1, count: 5)
        recurrence.occurrenceCount = 5 // Already at limit

        let template = Task(
            title: "Limited task",
            due: Date(),
            recurrence: recurrence
        )

        let instance = RecurrenceEngine.createNextOccurrence(from: template)

        // Should not create instance for completed recurrence
        XCTAssertNil(instance)
    }

    // MARK: - Batch Creation Tests

    func testCreateDueOccurrences() {
        // Create a daily task that started 5 days ago
        let startDate = Date().addingTimeInterval(-86400 * 5)
        let template = Task(
            title: "Daily task",
            due: startDate,
            recurrence: Recurrence(frequency: .daily, interval: 1)
        )

        let instances = RecurrenceEngine.createDueOccurrences(
            from: template,
            existingInstances: []
        )

        // Should create 5 instances (one for each past day)
        XCTAssertEqual(instances.count, 5)

        // All should be instances
        XCTAssertTrue(instances.allSatisfy { $0.isRecurringInstance })

        // All should link to template
        XCTAssertTrue(instances.allSatisfy { $0.originalTaskId == template.id })
    }

    func testCreateDueOccurrencesDoesNotCreateFutureInstances() {
        // Create a daily task starting tomorrow
        let futureDate = Date().addingTimeInterval(86400)
        let template = Task(
            title: "Future task",
            due: futureDate,
            recurrence: Recurrence(frequency: .daily, interval: 1)
        )

        let instances = RecurrenceEngine.createDueOccurrences(
            from: template,
            existingInstances: []
        )

        // Should not create future instances
        XCTAssertEqual(instances.count, 0)
    }

    // MARK: - Preset Pattern Tests

    func testPresetPatterns() {
        XCTAssertEqual(Recurrence.daily.frequency, .daily)
        XCTAssertEqual(Recurrence.daily.interval, 1)

        XCTAssertEqual(Recurrence.weekly.frequency, .weekly)
        XCTAssertEqual(Recurrence.weekly.interval, 1)

        XCTAssertEqual(Recurrence.biweekly.frequency, .weekly)
        XCTAssertEqual(Recurrence.biweekly.interval, 2)

        XCTAssertEqual(Recurrence.monthly.frequency, .monthly)
        XCTAssertEqual(Recurrence.monthly.interval, 1)

        XCTAssertEqual(Recurrence.yearly.frequency, .yearly)
        XCTAssertEqual(Recurrence.yearly.interval, 1)

        // Weekdays: Mon-Fri (1-5)
        XCTAssertEqual(Recurrence.weekdays.daysOfWeek, [1, 2, 3, 4, 5])

        // Weekends: Sat-Sun (0, 6)
        XCTAssertEqual(Recurrence.weekends.daysOfWeek, [0, 6])
    }

    // MARK: - Description Tests

    func testRecurrenceDescription() {
        var recurrence = Recurrence(frequency: .daily, interval: 1)
        XCTAssertEqual(recurrence.shortDescription, "Daily")

        recurrence = Recurrence(frequency: .daily, interval: 3)
        XCTAssertEqual(recurrence.shortDescription, "Every 3 days")

        recurrence = Recurrence(frequency: .weekly, interval: 1)
        XCTAssertEqual(recurrence.shortDescription, "Weekly")

        recurrence = Recurrence(frequency: .weekly, interval: 2)
        XCTAssertEqual(recurrence.shortDescription, "Every 2 weeks")

        recurrence = Recurrence(frequency: .monthly, interval: 1)
        XCTAssertEqual(recurrence.shortDescription, "Monthly")

        recurrence = Recurrence(frequency: .yearly, interval: 1)
        XCTAssertEqual(recurrence.shortDescription, "Yearly")
    }
}
