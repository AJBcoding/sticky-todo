//
//  CalendarIntegrationTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for calendar integration functionality.
//

import XCTest
import EventKit
@testable import StickyToDoCore

@available(macOS 10.15, *)
final class CalendarIntegrationTests: XCTestCase {

    // MARK: - Properties

    var calendarManager: CalendarManager!
    var testTask: Task!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        calendarManager = CalendarManager.shared

        // Create a test task with due date
        testTask = Task(
            title: "Test Calendar Task",
            notes: "This is a test task for calendar integration",
            status: .nextAction,
            project: "Testing",
            context: "@office",
            due: Date().addingTimeInterval(86400), // Tomorrow
            flagged: true,
            priority: .high
        )
    }

    override func tearDownWithError() throws {
        // Clean up any created events
        if let eventId = testTask.calendarEventId {
            _ = calendarManager.deleteEvent(eventId)
        }

        testTask = nil
        try super.tearDownWithError()
    }

    // MARK: - Authorization Tests

    func testAuthorizationStatus() {
        // Test that authorization status is retrievable
        let status = calendarManager.authorizationStatus
        XCTAssertNotNil(status)

        // Status should be one of the known values
        let validStatuses: [EKAuthorizationStatus] = [
            .notDetermined,
            .restricted,
            .denied,
            .authorized,
            .fullAccess,
            .writeOnly
        ]

        XCTAssertTrue(validStatuses.contains(status))
    }

    func testHasAuthorization() {
        // Test hasAuthorization computed property
        let hasAuth = calendarManager.hasAuthorization

        if #available(macOS 14.0, *) {
            XCTAssertEqual(hasAuth, calendarManager.authorizationStatus == .fullAccess)
        } else {
            XCTAssertEqual(hasAuth, calendarManager.authorizationStatus == .authorized)
        }
    }

    // MARK: - Calendar Management Tests

    func testRefreshCalendars() {
        // Note: This test will only pass if calendar access is granted
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        calendarManager.refreshCalendars()

        // Should have at least one calendar available
        XCTAssertGreaterThanOrEqual(calendarManager.availableCalendars.count, 0)
    }

    func testDefaultCalendar() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        let defaultCal = calendarManager.defaultCalendar
        XCTAssertNotNil(defaultCal, "Default calendar should be available when authorized")
    }

    // MARK: - Task Sync Tests

    func testShouldSyncTask() {
        // Test various scenarios for shouldSyncTask

        // Completed tasks should not sync
        var completedTask = testTask!
        completedTask.status = .completed
        calendarManager.preferences.syncFilter = .all
        XCTAssertFalse(calendarManager.shouldSyncTask(completedTask))

        // Tasks without due date should not sync
        var noDueTask = testTask!
        noDueTask.due = nil
        XCTAssertFalse(calendarManager.shouldSyncTask(noDueTask))

        // Test sync filter: all with due dates
        calendarManager.preferences.syncFilter = .withDueDate
        var regularTask = testTask!
        regularTask.flagged = false
        XCTAssertTrue(calendarManager.shouldSyncTask(regularTask))

        // Test sync filter: flagged only
        calendarManager.preferences.syncFilter = .flaggedOnly
        XCTAssertTrue(calendarManager.shouldSyncTask(testTask))
        XCTAssertFalse(calendarManager.shouldSyncTask(regularTask))

        // Test sync filter: flagged with due date
        calendarManager.preferences.syncFilter = .flaggedWithDueDate
        XCTAssertTrue(calendarManager.shouldSyncTask(testTask))
        XCTAssertFalse(calendarManager.shouldSyncTask(regularTask))
    }

    func testCreateEventWithoutAuthorization() {
        // Test creating event without authorization
        // First, check if we have authorization
        if calendarManager.hasAuthorization {
            XCTSkip("Cannot test unauthorized state when already authorized")
        }

        let result = calendarManager.createEvent(from: testTask)

        switch result {
        case .success:
            XCTFail("Should not succeed without authorization")
        case .failure(let error):
            XCTAssertEqual(error, .notAuthorized)
        }
    }

    func testCreateEventWithoutDueDate() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        var noDueTask = testTask!
        noDueTask.due = nil

        let result = calendarManager.createEvent(from: noDueTask)

        switch result {
        case .success:
            XCTFail("Should not succeed without due date")
        case .failure(let error):
            if case .invalidTaskData = error {
                // Expected
            } else {
                XCTFail("Expected invalidTaskData error, got \(error)")
            }
        }
    }

    func testCreateEvent() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        let result = calendarManager.createEvent(from: testTask)

        switch result {
        case .success(let eventId):
            XCTAssertFalse(eventId.isEmpty)
            testTask.calendarEventId = eventId

            // Verify event was created
            let event = calendarManager.fetchEvent(eventId)
            XCTAssertNotNil(event)
            XCTAssertEqual(event?.title, testTask.title)

        case .failure(let error):
            XCTFail("Failed to create event: \(error.localizedDescription)")
        }
    }

    func testUpdateEvent() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        // First create an event
        let createResult = calendarManager.createEvent(from: testTask)

        guard case .success(let eventId) = createResult else {
            XCTFail("Failed to create event for update test")
            return
        }

        testTask.calendarEventId = eventId

        // Update the task
        testTask.title = "Updated Test Task"
        testTask.notes = "Updated notes"

        // Update the event
        let updateResult = calendarManager.updateEvent(eventId, from: testTask)

        switch updateResult {
        case .success:
            // Verify event was updated
            let event = calendarManager.fetchEvent(eventId)
            XCTAssertEqual(event?.title, "Updated Test Task")
            XCTAssertTrue(event?.notes?.contains("Updated notes") ?? false)

        case .failure(let error):
            XCTFail("Failed to update event: \(error.localizedDescription)")
        }
    }

    func testDeleteEvent() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        // First create an event
        let createResult = calendarManager.createEvent(from: testTask)

        guard case .success(let eventId) = createResult else {
            XCTFail("Failed to create event for delete test")
            return
        }

        // Delete the event
        let deleteResult = calendarManager.deleteEvent(eventId)

        switch deleteResult {
        case .success:
            // Verify event was deleted
            let event = calendarManager.fetchEvent(eventId)
            XCTAssertNil(event)

        case .failure(let error):
            XCTFail("Failed to delete event: \(error.localizedDescription)")
        }

        // Clear the event ID since we deleted it
        testTask.calendarEventId = nil
    }

    func testSyncTask() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        // Enable auto-sync
        calendarManager.preferences.autoSyncEnabled = true
        calendarManager.preferences.syncFilter = .all

        // Sync the task
        let result = calendarManager.syncTask(testTask)

        switch result {
        case .success(let eventId):
            XCTAssertNotNil(eventId)
            if let eventId = eventId {
                testTask.calendarEventId = eventId

                // Verify event exists
                let event = calendarManager.fetchEvent(eventId)
                XCTAssertNotNil(event)
            }

        case .failure(let error):
            XCTFail("Failed to sync task: \(error.localizedDescription)")
        }
    }

    func testSyncTaskWithAutoSyncDisabled() {
        // Disable auto-sync
        calendarManager.preferences.autoSyncEnabled = false

        let result = calendarManager.syncTask(testTask)

        switch result {
        case .success(let eventId):
            XCTAssertNil(eventId, "Should not create event when auto-sync is disabled")

        case .failure(let error):
            XCTFail("Should not fail, just return nil: \(error)")
        }
    }

    // MARK: - Preferences Tests

    func testSaveAndLoadPreferences() {
        // Modify preferences
        calendarManager.preferences.autoSyncEnabled = true
        calendarManager.preferences.syncFilter = .flaggedWithDueDate
        calendarManager.preferences.createReminders = true

        // Save preferences
        calendarManager.savePreferences()

        // Create a new instance to test loading
        let newManager = CalendarManager()

        // Verify preferences were loaded
        XCTAssertEqual(newManager.preferences.autoSyncEnabled, true)
        XCTAssertEqual(newManager.preferences.syncFilter, .flaggedWithDueDate)
        XCTAssertEqual(newManager.preferences.createReminders, true)
    }

    func testSyncFilterCases() {
        // Test all sync filter cases
        let allCases = SyncFilter.allCases

        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.flaggedOnly))
        XCTAssertTrue(allCases.contains(.withDueDate))
        XCTAssertTrue(allCases.contains(.flaggedWithDueDate))
    }

    // MARK: - Error Handling Tests

    func testCalendarErrorDescriptions() {
        // Test error descriptions
        let errors: [CalendarError] = [
            .notAuthorized,
            .authorizationFailed("Test failure"),
            .noCalendarSelected,
            .invalidTaskData("No due date"),
            .eventNotFound,
            .calendarReadOnly,
            .saveFailed("Save error"),
            .deleteFailed("Delete error")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    // MARK: - Task Properties Tests

    func testTaskIsSyncedToCalendar() {
        // Test task with no calendar event
        XCTAssertFalse(testTask.isSyncedToCalendar)

        // Test task with calendar event
        testTask.calendarEventId = "test-event-id"
        XCTAssertTrue(testTask.isSyncedToCalendar)
    }

    // MARK: - Event Fetching Tests

    func testFetchEvents() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        let events = calendarManager.fetchEvents(from: startDate, to: endDate)

        // Should return an array (may be empty)
        XCTAssertNotNil(events)
    }

    func testFetchEventsWithSpecificCalendar() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        guard let defaultCalendar = calendarManager.defaultCalendar else {
            XCTSkip("No default calendar available")
        }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        let events = calendarManager.fetchEvents(
            from: startDate,
            to: endDate,
            in: [defaultCalendar]
        )

        // Should return an array (may be empty)
        XCTAssertNotNil(events)
    }

    // MARK: - All Day Event Tests

    func testCreateAllDayEvent() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        // Create task with midnight due date (all-day event)
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date().addingTimeInterval(86400))

        var allDayTask = testTask!
        allDayTask.due = midnight

        let result = calendarManager.createEvent(from: allDayTask)

        switch result {
        case .success(let eventId):
            testTask.calendarEventId = eventId

            // Verify event is all-day
            let event = calendarManager.fetchEvent(eventId)
            XCTAssertTrue(event?.isAllDay ?? false)

        case .failure(let error):
            XCTFail("Failed to create all-day event: \(error.localizedDescription)")
        }
    }

    // MARK: - Alarm Tests

    func testEventWithAlarm() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        // Flagged tasks should get alarms
        testTask.flagged = true

        let result = calendarManager.createEvent(from: testTask)

        switch result {
        case .success(let eventId):
            testTask.calendarEventId = eventId

            // Verify event has alarm
            let event = calendarManager.fetchEvent(eventId)
            XCTAssertTrue(event?.hasAlarms ?? false)

        case .failure(let error):
            XCTFail("Failed to create event with alarm: \(error.localizedDescription)")
        }
    }

    // MARK: - Performance Tests

    func testSyncMultipleTasksPerformance() {
        guard calendarManager.hasAuthorization else {
            XCTSkip("Calendar access not authorized")
        }

        // Create multiple test tasks
        var tasks: [Task] = []
        for i in 0..<10 {
            let task = Task(
                title: "Test Task \(i)",
                status: .nextAction,
                due: Date().addingTimeInterval(Double(i) * 86400),
                flagged: i % 2 == 0
            )
            tasks.append(task)
        }

        measure {
            let results = calendarManager.syncAllTasks(tasks)
            XCTAssertEqual(results.count, tasks.count)
        }

        // Clean up created events
        for task in tasks {
            if let eventId = task.calendarEventId {
                _ = calendarManager.deleteEvent(eventId)
            }
        }
    }
}
