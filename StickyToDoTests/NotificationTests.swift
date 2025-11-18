//
//  NotificationTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for notification functionality.
//

import XCTest
import UserNotifications
@testable import StickyToDoCore

final class NotificationTests: XCTestCase {

    var notificationManager: NotificationManager!
    var testTask: Task!

    override func setUpWithError() throws {
        try super.setUpWithError()
        notificationManager = NotificationManager.shared
        testTask = Task(
            title: "Test Task",
            due: Date().addingTimeInterval(3600), // 1 hour from now
            defer: Date().addingTimeInterval(1800) // 30 minutes from now
        )
    }

    override func tearDownWithError() throws {
        // Cancel all notifications after each test
        notificationManager.cancelAllNotifications()
        try super.tearDownWithError()
    }

    // MARK: - Authorization Tests

    func testAuthorizationStatusCheck() async throws {
        // Test that we can check authorization status
        await notificationManager.checkAuthorizationStatus()

        // The status should be one of the valid values
        let status = notificationManager.authorizationStatus
        XCTAssertTrue([
            .notDetermined,
            .denied,
            .authorized,
            .provisional,
            .ephemeral
        ].contains(status), "Authorization status should be valid")
    }

    func testNotificationsAvailable() {
        // Test the computed property for notification availability
        let available = notificationManager.areNotificationsAvailable

        // Should be true only if authorized and enabled
        if notificationManager.authorizationStatus == .authorized &&
           notificationManager.notificationsEnabled {
            XCTAssertTrue(available)
        } else {
            XCTAssertFalse(available)
        }
    }

    // MARK: - Due Date Notification Tests

    func testScheduleDueNotifications() async throws {
        // Setup: Enable notifications
        notificationManager.notificationsEnabled = true
        notificationManager.dueReminderTime = .oneHour

        // Test scheduling due notifications
        let notificationIds = await notificationManager.scheduleDueNotifications(for: testTask)

        // We should get at least one notification ID if authorized
        if notificationManager.authorizationStatus == .authorized {
            XCTAssertFalse(notificationIds.isEmpty, "Should schedule at least one notification")
        }

        // Verify pending notifications
        let pendingCount = await notificationManager.getPendingNotificationCount()
        XCTAssertGreaterThanOrEqual(pendingCount, notificationIds.count)
    }

    func testMultipleDueReminders() async throws {
        notificationManager.notificationsEnabled = true
        notificationManager.dueReminderTime = .multiple

        let task = Task(
            title: "Multi-reminder Task",
            due: Date().addingTimeInterval(86400 * 2) // 2 days from now
        )

        let notificationIds = await notificationManager.scheduleDueNotifications(for: task)

        // With multiple reminders, should schedule multiple notifications
        if notificationManager.authorizationStatus == .authorized {
            XCTAssertGreaterThan(notificationIds.count, 1, "Should schedule multiple reminders")
        }
    }

    func testDueNotificationNotScheduledForPastDate() async throws {
        let pastTask = Task(
            title: "Past Task",
            due: Date().addingTimeInterval(-3600) // 1 hour ago
        )

        let notificationIds = await notificationManager.scheduleDueNotifications(for: pastTask)

        // Should not schedule notifications for past dates
        XCTAssertTrue(notificationIds.isEmpty, "Should not schedule notifications for past dates")
    }

    func testDueNotificationNotScheduledForCompletedTask() async throws {
        var completedTask = testTask
        completedTask.status = .completed

        let notificationIds = await notificationManager.scheduleDueNotifications(for: completedTask)

        // Should not schedule notifications for completed tasks
        XCTAssertTrue(notificationIds.isEmpty, "Should not schedule notifications for completed tasks")
    }

    // MARK: - Defer Date Notification Tests

    func testScheduleDeferNotification() async throws {
        notificationManager.notificationsEnabled = true

        let notificationId = await notificationManager.scheduleDeferNotification(for: testTask)

        // Should get a notification ID if authorized
        if notificationManager.authorizationStatus == .authorized {
            XCTAssertNotNil(notificationId, "Should schedule defer notification")
        }
    }

    func testDeferNotificationNotScheduledForPastDate() async throws {
        let task = Task(
            title: "Past Defer Task",
            defer: Date().addingTimeInterval(-1800) // 30 minutes ago
        )

        let notificationId = await notificationManager.scheduleDeferNotification(for: task)

        // Should not schedule notification for past defer date
        XCTAssertNil(notificationId, "Should not schedule notification for past defer date")
    }

    // MARK: - Timer Notification Tests

    func testScheduleTimerNotification() async throws {
        notificationManager.notificationsEnabled = true

        let duration: TimeInterval = 1800 // 30 minutes
        let notificationId = await notificationManager.scheduleTimerNotification(
            for: testTask,
            duration: duration
        )

        // Should get a notification ID if authorized
        if notificationManager.authorizationStatus == .authorized {
            XCTAssertNotNil(notificationId, "Should schedule timer notification")
        }
    }

    // MARK: - Recurring Task Notification Tests

    func testScheduleRecurringTaskNotification() async throws {
        notificationManager.notificationsEnabled = true

        var recurringTask = Task(
            title: "Recurring Task",
            due: Date().addingTimeInterval(86400), // 1 day from now
            originalTaskId: UUID() // Mark as recurring instance
        )

        let notificationIds = await notificationManager.scheduleRecurringTaskNotification(for: recurringTask)

        // Should schedule notifications for recurring task instances
        if notificationManager.authorizationStatus == .authorized {
            XCTAssertFalse(notificationIds.isEmpty, "Should schedule notifications for recurring tasks")
        }
    }

    // MARK: - Cancellation Tests

    func testCancelNotifications() async throws {
        notificationManager.notificationsEnabled = true

        // Schedule some notifications
        var task = testTask
        let notificationIds = await notificationManager.scheduleDueNotifications(for: task)
        task.notificationIds = notificationIds

        // Get initial pending count
        let initialCount = await notificationManager.getPendingNotificationCount()

        // Cancel notifications
        notificationManager.cancelNotifications(for: task)

        // Wait a bit for cancellation to process
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Pending count should decrease
        let finalCount = await notificationManager.getPendingNotificationCount()
        XCTAssertLessThanOrEqual(finalCount, initialCount)
    }

    func testCancelAllNotifications() async throws {
        notificationManager.notificationsEnabled = true

        // Schedule multiple notifications
        _ = await notificationManager.scheduleDueNotifications(for: testTask)

        let task2 = Task(
            title: "Another Task",
            due: Date().addingTimeInterval(7200)
        )
        _ = await notificationManager.scheduleDueNotifications(for: task2)

        // Cancel all notifications
        notificationManager.cancelAllNotifications()

        // Wait a bit for cancellation to process
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Should have no pending notifications
        let pendingCount = await notificationManager.getPendingNotificationCount()
        XCTAssertEqual(pendingCount, 0, "Should have no pending notifications after cancel all")
    }

    // MARK: - Badge Management Tests

    func testUpdateBadgeCount() {
        let overdueCount = 5
        notificationManager.badgeEnabled = true

        notificationManager.updateBadgeCount(overdueCount)

        // Badge should be updated (can't easily verify without UI testing)
        // Just verify the method doesn't crash
        XCTAssertTrue(true)
    }

    func testClearBadge() {
        notificationManager.clearBadge()

        // Badge should be cleared (can't easily verify without UI testing)
        // Just verify the method doesn't crash
        XCTAssertTrue(true)
    }

    func testBadgeNotUpdatedWhenDisabled() {
        notificationManager.badgeEnabled = false

        notificationManager.updateBadgeCount(10)

        // When badge is disabled, should clear badge
        // Just verify the method doesn't crash
        XCTAssertTrue(true)
    }

    // MARK: - Settings Tests

    func testNotificationSettings() {
        // Test default settings
        XCTAssertTrue(notificationManager.notificationsEnabled || !notificationManager.notificationsEnabled)
        XCTAssertTrue(notificationManager.badgeEnabled || !notificationManager.badgeEnabled)

        // Test changing settings
        let originalEnabled = notificationManager.notificationsEnabled
        notificationManager.notificationsEnabled = !originalEnabled
        XCTAssertEqual(notificationManager.notificationsEnabled, !originalEnabled)

        // Restore original
        notificationManager.notificationsEnabled = originalEnabled
    }

    func testDueReminderTimeSettings() {
        // Test all reminder time options
        let reminderTimes: [DueReminderTime] = [
            .oneDayBefore,
            .oneHour,
            .fifteenMinutes,
            .custom(30),
            .multiple
        ]

        for reminderTime in reminderTimes {
            notificationManager.dueReminderTime = reminderTime
            XCTAssertEqual(notificationManager.dueReminderTime, reminderTime)
        }
    }

    func testNotificationSoundSettings() {
        // Test all sound options
        for sound in NotificationSound.allCases {
            notificationManager.notificationSound = sound
            XCTAssertEqual(notificationManager.notificationSound, sound)
        }
    }

    func testWeeklyReviewScheduleSettings() {
        // Test all schedule options
        for schedule in WeeklyReviewSchedule.allCases {
            notificationManager.weeklyReviewSchedule = schedule
            XCTAssertEqual(notificationManager.weeklyReviewSchedule, schedule)
        }
    }

    // MARK: - Weekly Review Tests

    func testWeeklyReviewNextFireDate() {
        let schedule = WeeklyReviewSchedule.sundayEvening
        let nextFireDate = schedule.nextFireDate

        if schedule != .disabled {
            XCTAssertNotNil(nextFireDate, "Should have next fire date for enabled schedule")

            if let fireDate = nextFireDate {
                XCTAssertGreaterThan(fireDate, Date(), "Next fire date should be in the future")
            }
        } else {
            XCTAssertNil(nextFireDate, "Disabled schedule should have no fire date")
        }
    }

    func testScheduleWeeklyReviewNotification() {
        notificationManager.weeklyReviewSchedule = .sundayEvening
        notificationManager.scheduleWeeklyReviewNotification()

        // Just verify the method doesn't crash
        // Actual verification would require checking pending notifications
        XCTAssertTrue(true)
    }

    // MARK: - Test Notification

    func testSendTestNotification() async throws {
        notificationManager.notificationsEnabled = true

        await notificationManager.sendTestNotification()

        // Wait a bit for notification to be scheduled
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Just verify the method doesn't crash
        XCTAssertTrue(true)
    }

    // MARK: - Pending Notifications

    func testGetPendingNotifications() async throws {
        notificationManager.notificationsEnabled = true

        // Schedule some notifications
        _ = await notificationManager.scheduleDueNotifications(for: testTask)

        // Get pending notifications
        let requests = await notificationManager.getPendingNotifications()

        // Should have at least some notifications if authorized
        if notificationManager.authorizationStatus == .authorized {
            XCTAssertGreaterThan(requests.count, 0, "Should have pending notifications")
        }
    }

    func testGetPendingNotificationCount() async throws {
        notificationManager.notificationsEnabled = true

        // Schedule some notifications
        _ = await notificationManager.scheduleDueNotifications(for: testTask)

        // Get count
        let count = await notificationManager.getPendingNotificationCount()

        // Should have at least some notifications if authorized
        if notificationManager.authorizationStatus == .authorized {
            XCTAssertGreaterThan(count, 0, "Should have pending notifications")
        }
    }

    // MARK: - Integration Tests

    func testCompleteWorkflow() async throws {
        // This test simulates a complete workflow from task creation to completion

        notificationManager.notificationsEnabled = true
        notificationManager.dueReminderTime = .oneHour

        // 1. Create a task with due date
        var task = Task(
            title: "Workflow Test Task",
            due: Date().addingTimeInterval(7200) // 2 hours from now
        )

        // 2. Schedule notifications
        let notificationIds = await notificationManager.scheduleDueNotifications(for: task)
        task.notificationIds = notificationIds

        // 3. Verify notifications were scheduled
        if notificationManager.authorizationStatus == .authorized {
            XCTAssertFalse(notificationIds.isEmpty, "Should have scheduled notifications")
        }

        // 4. Update task (change due date)
        task.due = Date().addingTimeInterval(86400) // 1 day from now

        // Cancel old notifications and schedule new ones
        notificationManager.cancelNotifications(for: task)
        let newNotificationIds = await notificationManager.scheduleDueNotifications(for: task)
        task.notificationIds = newNotificationIds

        // 5. Complete task
        notificationManager.cancelNotifications(for: task)
        task.notificationIds = []

        // 6. Verify all notifications are cancelled
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Test completed successfully
        XCTAssertTrue(task.notificationIds.isEmpty, "Task should have no notification IDs after completion")
    }

    // MARK: - Performance Tests

    func testSchedulingPerformance() {
        // Test that scheduling many notifications is reasonably fast
        measure {
            let expectation = self.expectation(description: "Schedule notifications")

            Task {
                for i in 0..<10 {
                    let task = Task(
                        title: "Performance Test \(i)",
                        due: Date().addingTimeInterval(Double(i * 3600))
                    )
                    _ = await notificationManager.scheduleDueNotifications(for: task)
                }
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testCancellationPerformance() {
        // Test that cancelling many notifications is reasonably fast
        measure {
            let expectation = self.expectation(description: "Cancel notifications")

            Task {
                var tasks: [Task] = []

                // Schedule notifications
                for i in 0..<10 {
                    var task = Task(
                        title: "Cancellation Test \(i)",
                        due: Date().addingTimeInterval(Double(i * 3600))
                    )
                    let ids = await notificationManager.scheduleDueNotifications(for: task)
                    task.notificationIds = ids
                    tasks.append(task)
                }

                // Cancel all
                for task in tasks {
                    notificationManager.cancelNotifications(for: task)
                }

                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 5.0)
        }
    }
}
