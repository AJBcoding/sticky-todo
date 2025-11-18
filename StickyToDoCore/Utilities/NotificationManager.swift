//
//  NotificationManager.swift
//  StickyToDoCore
//
//  Comprehensive notification manager for StickyToDo.
//  Handles all notification operations including scheduling, canceling, and badge updates.
//

import Foundation
import UserNotifications

/// Manages all notification operations for StickyToDo
///
/// NotificationManager provides:
/// - Permission requesting and status checking
/// - Notification scheduling for due dates, deferrals, timers, and reviews
/// - Interactive notifications with actions (Complete, Snooze, Open)
/// - Badge count updates based on overdue tasks
/// - Notification cancellation when tasks are completed/deleted
@MainActor
public class NotificationManager: NSObject, ObservableObject {

    // MARK: - Singleton

    /// Shared instance for app-wide access
    public static let shared = NotificationManager()

    // MARK: - Published Properties

    /// Current authorization status for notifications
    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Whether notifications are enabled in settings
    @Published public var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    /// Whether to show badge count for overdue tasks
    @Published public var badgeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(badgeEnabled, forKey: "badgeEnabled")
        }
    }

    /// Reminder time for due date notifications (in hours before due)
    @Published public var dueReminderTime: DueReminderTime {
        didSet {
            if let encoded = try? JSONEncoder().encode(dueReminderTime) {
                UserDefaults.standard.set(encoded, forKey: "dueReminderTime")
            }
        }
    }

    /// Notification sound preference
    @Published public var notificationSound: NotificationSound {
        didSet {
            UserDefaults.standard.set(notificationSound.rawValue, forKey: "notificationSound")
        }
    }

    /// Weekly review schedule
    @Published public var weeklyReviewSchedule: WeeklyReviewSchedule {
        didSet {
            UserDefaults.standard.set(weeklyReviewSchedule.rawValue, forKey: "weeklyReviewSchedule")
            scheduleWeeklyReviewNotification()
        }
    }

    // MARK: - Private Properties

    /// UserNotifications center
    private let notificationCenter = UNUserNotificationCenter.current()

    /// Logger for debugging
    private var logger: ((String) -> Void)?

    // MARK: - Initialization

    private override init() {
        // Load settings from UserDefaults
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.badgeEnabled = UserDefaults.standard.bool(forKey: "badgeEnabled")

        // Load reminder time (with Codable support for custom values)
        if let data = UserDefaults.standard.data(forKey: "dueReminderTime"),
           let decoded = try? JSONDecoder().decode(DueReminderTime.self, from: data) {
            self.dueReminderTime = decoded
        } else {
            self.dueReminderTime = .oneHour
        }

        let soundValue = UserDefaults.standard.string(forKey: "notificationSound") ?? NotificationSound.default.rawValue
        self.notificationSound = NotificationSound(rawValue: soundValue) ?? .default

        let scheduleValue = UserDefaults.standard.string(forKey: "weeklyReviewSchedule") ?? WeeklyReviewSchedule.sundayEvening.rawValue
        self.weeklyReviewSchedule = WeeklyReviewSchedule(rawValue: scheduleValue) ?? .sundayEvening

        super.init()

        // Set delegate
        notificationCenter.delegate = self

        // Check authorization status
        Task {
            await checkAuthorizationStatus()
        }
    }

    /// Configure logging
    public func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    // MARK: - Authorization

    /// Requests notification permissions from the user
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await checkAuthorizationStatus()
            logger?("Notification authorization: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger?("Failed to request notification authorization: \(error)")
            return false
        }
    }

    /// Checks current authorization status
    public func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        logger?("Notification authorization status: \(settings.authorizationStatus.rawValue)")
    }

    /// Returns true if notifications are authorized and enabled
    public var areNotificationsAvailable: Bool {
        return authorizationStatus == .authorized && notificationsEnabled
    }

    // MARK: - Due Date Notifications

    /// Schedules notifications for a task's due date
    /// - Parameter task: The task to schedule notifications for
    /// - Returns: Array of notification identifiers that were scheduled
    @discardableResult
    public func scheduleDueNotifications(for task: Task) async -> [String] {
        guard areNotificationsAvailable,
              let dueDate = task.due,
              task.status != .completed,
              dueDate > Date() else {
            return []
        }

        var notificationIds: [String] = []

        // Schedule notifications based on user preference
        switch dueReminderTime {
        case .oneDayBefore:
            if let id = await scheduleNotification(for: task, at: dueDate, offset: -86400, title: "Task due tomorrow", body: task.title) {
                notificationIds.append(id)
            }
        case .oneHour:
            if let id = await scheduleNotification(for: task, at: dueDate, offset: -3600, title: "Task due in 1 hour", body: task.title) {
                notificationIds.append(id)
            }
        case .fifteenMinutes:
            if let id = await scheduleNotification(for: task, at: dueDate, offset: -900, title: "Task due in 15 minutes", body: task.title) {
                notificationIds.append(id)
            }
        case .custom(let minutes):
            if let id = await scheduleNotification(for: task, at: dueDate, offset: -Double(minutes * 60), title: "Task due soon", body: task.title) {
                notificationIds.append(id)
            }
        case .multiple:
            // Schedule multiple reminders
            if let id1 = await scheduleNotification(for: task, at: dueDate, offset: -86400, title: "Task due tomorrow", body: task.title) {
                notificationIds.append(id1)
            }
            if let id2 = await scheduleNotification(for: task, at: dueDate, offset: -3600, title: "Task due in 1 hour", body: task.title) {
                notificationIds.append(id2)
            }
        }

        // Also schedule notification at due time
        if let id = await scheduleNotification(for: task, at: dueDate, offset: 0, title: "Task is due now", body: task.title) {
            notificationIds.append(id)
        }

        logger?("Scheduled \(notificationIds.count) due date notifications for task: \(task.title)")
        return notificationIds
    }

    // MARK: - Defer Date Notifications

    /// Schedules notification for when a deferred task becomes available
    /// - Parameter task: The task with a defer date
    /// - Returns: Notification identifier if scheduled
    @discardableResult
    public func scheduleDeferNotification(for task: Task) async -> String? {
        guard areNotificationsAvailable,
              let deferDate = task.defer,
              task.status != .completed,
              deferDate > Date() else {
            return nil
        }

        let id = await scheduleNotification(
            for: task,
            at: deferDate,
            offset: 0,
            title: "Task is now available",
            body: task.title
        )

        if let id = id {
            logger?("Scheduled defer notification for task: \(task.title)")
        }

        return id
    }

    // MARK: - Timer Notifications

    /// Schedules notification for when a timer completes
    /// - Parameters:
    ///   - task: The task with a running timer
    ///   - duration: Timer duration in seconds
    /// - Returns: Notification identifier if scheduled
    @discardableResult
    public func scheduleTimerNotification(for task: Task, duration: TimeInterval) async -> String? {
        guard areNotificationsAvailable else { return nil }

        let fireDate = Date().addingTimeInterval(duration)
        let id = await scheduleNotification(
            for: task,
            at: fireDate,
            offset: 0,
            title: "Timer completed",
            body: "Timer for '\(task.title)' has finished"
        )

        if let id = id {
            logger?("Scheduled timer notification for task: \(task.title)")
        }

        return id
    }

    // MARK: - Recurring Task Notifications

    /// Schedules notification for a newly created recurring task instance
    /// - Parameter task: The recurring task instance
    /// - Returns: Array of notification identifiers
    @discardableResult
    public func scheduleRecurringTaskNotification(for task: Task) async -> [String] {
        guard areNotificationsAvailable,
              task.isRecurringInstance else {
            return []
        }

        // Schedule same as regular due date notifications
        return await scheduleDueNotifications(for: task)
    }

    // MARK: - Weekly Review Notification

    /// Schedules weekly review notification based on user preference
    public func scheduleWeeklyReviewNotification() {
        guard areNotificationsAvailable else { return }

        Task {
            // Cancel existing weekly review notification
            cancelNotifications(withIdentifiers: ["weekly-review"])

            guard let fireDate = weeklyReviewSchedule.nextFireDate else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Weekly Review"
            content.body = "Time to review your tasks and plan for the week ahead"
            content.sound = notificationSound.sound
            content.categoryIdentifier = NotificationCategory.weeklyReview.rawValue
            content.userInfo = ["type": "weeklyReview"]

            // Create date components for weekly trigger
            let calendar = Calendar.current
            let components = calendar.dateComponents([.weekday, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let request = UNNotificationRequest(
                identifier: "weekly-review",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
                logger?("Scheduled weekly review notification")
            } catch {
                logger?("Failed to schedule weekly review notification: \(error)")
            }
        }
    }

    // MARK: - Helper Methods

    /// Schedules a notification at a specific date with optional offset
    private func scheduleNotification(
        for task: Task,
        at date: Date,
        offset: TimeInterval,
        title: String,
        body: String
    ) async -> String? {
        let fireDate = date.addingTimeInterval(offset)

        // Don't schedule if fire date is in the past
        guard fireDate > Date() else { return nil }

        let identifier = "\(task.id.uuidString)-\(Int(offset))"

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = notificationSound.sound
        content.categoryIdentifier = NotificationCategory.task.rawValue
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "task"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: fireDate.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            return identifier
        } catch {
            logger?("Failed to schedule notification: \(error)")
            return nil
        }
    }

    // MARK: - Cancellation

    /// Cancels all notifications for a specific task
    /// - Parameter task: The task whose notifications should be cancelled
    public func cancelNotifications(for task: Task) {
        guard !task.notificationIds.isEmpty else { return }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: task.notificationIds)
        logger?("Cancelled \(task.notificationIds.count) notifications for task: \(task.title)")
    }

    /// Cancels notifications with specific identifiers
    /// - Parameter identifiers: Array of notification identifiers to cancel
    public func cancelNotifications(withIdentifiers identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        logger?("Cancelled notifications: \(identifiers.joined(separator: ", "))")
    }

    /// Cancels all pending notifications
    public func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        logger?("Cancelled all pending notifications")
    }

    // MARK: - Badge Management

    /// Updates the app badge count with the number of overdue tasks
    /// - Parameter overdueCount: Number of overdue tasks
    public func updateBadgeCount(_ overdueCount: Int) {
        guard badgeEnabled else {
            clearBadge()
            return
        }

        UNUserNotificationCenter.current().setBadgeCount(overdueCount) { error in
            if let error = error {
                self.logger?("Failed to update badge count: \(error)")
            } else {
                self.logger?("Updated badge count to: \(overdueCount)")
            }
        }
    }

    /// Clears the app badge
    public func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                self.logger?("Failed to clear badge: \(error)")
            }
        }
    }

    // MARK: - Testing

    /// Sends a test notification to verify notifications are working
    public func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from StickyToDo"
        content.sound = notificationSound.sound

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            logger?("Sent test notification")
        } catch {
            logger?("Failed to send test notification: \(error)")
        }
    }

    // MARK: - Pending Notifications

    /// Returns all pending notification requests
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    /// Returns count of pending notifications
    public func getPendingNotificationCount() async -> Int {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.count
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Called when a notification is about to be presented while the app is in the foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when the user interacts with a notification
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle notification actions
        switch response.actionIdentifier {
        case NotificationAction.complete.rawValue:
            handleCompleteAction(userInfo: userInfo)

        case NotificationAction.snooze.rawValue:
            handleSnoozeAction(userInfo: userInfo)

        case UNNotificationDefaultActionIdentifier:
            handleOpenAction(userInfo: userInfo)

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            logger?("Notification dismissed")

        default:
            break
        }

        completionHandler()
    }

    /// Handles the complete action
    private func handleCompleteAction(userInfo: [AnyHashable: Any]) {
        guard let taskIdString = userInfo["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString) else {
            return
        }

        logger?("Complete action triggered for task: \(taskId)")

        // Post notification for TaskStore to handle
        NotificationCenter.default.post(
            name: .taskCompleteRequested,
            object: nil,
            userInfo: ["taskId": taskId]
        )
    }

    /// Handles the snooze action
    private func handleSnoozeAction(userInfo: [AnyHashable: Any]) {
        guard let taskIdString = userInfo["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString) else {
            return
        }

        logger?("Snooze action triggered for task: \(taskId)")

        // Post notification for TaskStore to handle (snooze for 1 hour)
        NotificationCenter.default.post(
            name: .taskSnoozeRequested,
            object: nil,
            userInfo: ["taskId": taskId, "duration": 3600.0]
        )
    }

    /// Handles opening the app to a specific task
    private func handleOpenAction(userInfo: [AnyHashable: Any]) {
        guard let taskIdString = userInfo["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString) else {
            return
        }

        logger?("Open action triggered for task: \(taskId)")

        // Post notification for app to handle
        NotificationCenter.default.post(
            name: .taskOpenRequested,
            object: nil,
            userInfo: ["taskId": taskId]
        )
    }
}

// MARK: - Supporting Types

/// Due date reminder time options
public enum DueReminderTime: Codable, Equatable {
    case oneDayBefore
    case oneHour
    case fifteenMinutes
    case custom(Int) // minutes before due date
    case multiple

    var description: String {
        switch self {
        case .oneDayBefore:
            return "1 Day Before"
        case .oneHour:
            return "1 Hour Before"
        case .fifteenMinutes:
            return "15 Minutes Before"
        case .custom(let minutes):
            return "Custom (\(minutes) minutes)"
        case .multiple:
            return "Multiple Reminders"
        }
    }

    var rawValue: String {
        return description
    }

    public static var allCases: [DueReminderTime] {
        return [.oneDayBefore, .oneHour, .fifteenMinutes, .custom(30), .multiple]
    }
}

/// Notification sound options
public enum NotificationSound: String, CaseIterable, Codable {
    case `default` = "Default"
    case glass = "Glass"
    case pop = "Pop"
    case tink = "Tink"
    case none = "None"

    var sound: UNNotificationSound? {
        switch self {
        case .default:
            return .default
        case .glass:
            return UNNotificationSound(named: UNNotificationSoundName("glass.caf"))
        case .pop:
            return UNNotificationSound(named: UNNotificationSoundName("pop.caf"))
        case .tink:
            return UNNotificationSound(named: UNNotificationSoundName("tink.caf"))
        case .none:
            return nil
        }
    }
}

/// Weekly review schedule options
public enum WeeklyReviewSchedule: String, CaseIterable, Codable {
    case sundayEvening = "Sunday Evening (6 PM)"
    case sundayMorning = "Sunday Morning (9 AM)"
    case fridayEvening = "Friday Evening (5 PM)"
    case mondayMorning = "Monday Morning (9 AM)"
    case disabled = "Disabled"

    var nextFireDate: Date? {
        guard self != .disabled else { return nil }

        let calendar = Calendar.current
        let now = Date()

        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = 0

        // Find next occurrence
        guard let nextDate = calendar.nextDate(
            after: now,
            matching: components,
            matchingPolicy: .nextTime
        ) else {
            return nil
        }

        return nextDate
    }

    private var weekday: Int {
        switch self {
        case .sundayEvening, .sundayMorning:
            return 1 // Sunday
        case .fridayEvening:
            return 6 // Friday
        case .mondayMorning:
            return 2 // Monday
        case .disabled:
            return 0
        }
    }

    private var hour: Int {
        switch self {
        case .sundayEvening:
            return 18 // 6 PM
        case .sundayMorning:
            return 9 // 9 AM
        case .fridayEvening:
            return 17 // 5 PM
        case .mondayMorning:
            return 9 // 9 AM
        case .disabled:
            return 0
        }
    }
}

/// Notification categories for different types of notifications
public enum NotificationCategory: String {
    case task = "TASK_NOTIFICATION"
    case weeklyReview = "WEEKLY_REVIEW"
    case timer = "TIMER_NOTIFICATION"
}

/// Notification actions
public enum NotificationAction: String {
    case complete = "COMPLETE_ACTION"
    case snooze = "SNOOZE_ACTION"
    case open = "OPEN_ACTION"
}

// MARK: - Notification Names

public extension Notification.Name {
    static let taskCompleteRequested = Notification.Name("taskCompleteRequested")
    static let taskSnoozeRequested = Notification.Name("taskSnoozeRequested")
    static let taskOpenRequested = Notification.Name("taskOpenRequested")
}
