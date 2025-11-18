//
//  CalendarManager.swift
//  StickyToDoCore
//
//  Manages EventKit calendar integration for syncing tasks with system calendars.
//

import Foundation
import EventKit

/// Manages calendar integration using EventKit
///
/// This manager handles:
/// - Calendar access permissions
/// - Creating calendar events from tasks
/// - Two-way sync between tasks and calendar events
/// - Monitoring calendar changes
/// - User preferences for calendar sync
@available(macOS 10.15, *)
public class CalendarManager: ObservableObject {

    // MARK: - Properties

    /// The EventKit event store
    private let eventStore = EKEventStore()

    /// Published authorization status
    @Published public private(set) var authorizationStatus: EKAuthorizationStatus

    /// Published list of available calendars
    @Published public private(set) var availableCalendars: [EKCalendar] = []

    /// Published sync errors
    @Published public private(set) var lastError: CalendarError?

    /// User preferences for calendar sync
    @Published public var preferences = CalendarPreferences()

    /// Shared singleton instance
    public static let shared = CalendarManager()

    // MARK: - Initialization

    private init() {
        if #available(macOS 14.0, *) {
            self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
        loadPreferences()
        refreshCalendars()
    }

    // MARK: - Authorization

    /// Request calendar access authorization
    /// - Parameter completion: Callback with result
    public func requestAuthorization(completion: @escaping (Result<Bool, CalendarError>) -> Void) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        let calendarError = CalendarError.authorizationFailed(error.localizedDescription)
                        self?.lastError = calendarError
                        completion(.failure(calendarError))
                        return
                    }

                    self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    self?.refreshCalendars()
                    completion(.success(granted))
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        let calendarError = CalendarError.authorizationFailed(error.localizedDescription)
                        self?.lastError = calendarError
                        completion(.failure(calendarError))
                        return
                    }

                    self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    self?.refreshCalendars()
                    completion(.success(granted))
                }
            }
        }
    }

    /// Check if we have calendar access
    public var hasAuthorization: Bool {
        if #available(macOS 14.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return authorizationStatus == .authorized
        }
    }

    // MARK: - Calendar Management

    /// Refresh the list of available calendars
    public func refreshCalendars() {
        guard hasAuthorization else {
            availableCalendars = []
            return
        }

        availableCalendars = eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .sorted { $0.title < $1.title }
    }

    /// Get the default calendar for new events
    public var defaultCalendar: EKCalendar? {
        guard hasAuthorization else { return nil }

        // Try to get user's preferred calendar
        if let calendarId = preferences.defaultCalendarId,
           let calendar = eventStore.calendar(withIdentifier: calendarId),
           calendar.allowsContentModifications {
            return calendar
        }

        // Fall back to default calendar
        return eventStore.defaultCalendarForNewEvents
    }

    // MARK: - Event Sync

    /// Create a calendar event from a task
    /// - Parameters:
    ///   - task: The task to create an event for
    ///   - calendar: Optional specific calendar (uses default if nil)
    /// - Returns: The created event identifier
    public func createEvent(from task: Task, in calendar: EKCalendar? = nil) -> Result<String, CalendarError> {
        guard hasAuthorization else {
            return .failure(.notAuthorized)
        }

        guard let dueDate = task.due else {
            return .failure(.invalidTaskData("Task has no due date"))
        }

        let targetCalendar = calendar ?? defaultCalendar
        guard let targetCalendar = targetCalendar else {
            return .failure(.noCalendarSelected)
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = targetCalendar
        event.title = task.title

        // Set notes with task metadata
        var notesContent = task.notes
        if !task.notes.isEmpty {
            notesContent += "\n\n"
        }
        notesContent += "---\n"
        notesContent += "Task ID: \(task.id.uuidString)\n"
        if let project = task.project {
            notesContent += "Project: \(project)\n"
        }
        if let context = task.context {
            notesContent += "Context: \(context)\n"
        }
        event.notes = notesContent

        // Set date and time
        event.startDate = dueDate

        // If task has a specific time, use 1 hour duration, otherwise all-day
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: dueDate)
        if components.hour == 0 && components.minute == 0 {
            event.isAllDay = true
            event.endDate = dueDate
        } else {
            event.isAllDay = false
            event.endDate = dueDate.addingTimeInterval(3600) // 1 hour
        }

        // Add alarm if task is flagged
        if task.flagged {
            let alarm = EKAlarm(relativeOffset: -3600) // 1 hour before
            event.addAlarm(alarm)
        }

        // Save the event
        do {
            try eventStore.save(event, span: .thisEvent)
            return .success(event.eventIdentifier)
        } catch {
            let calendarError = CalendarError.saveFailed(error.localizedDescription)
            lastError = calendarError
            return .failure(calendarError)
        }
    }

    /// Update an existing calendar event from task
    /// - Parameters:
    ///   - eventId: The event identifier
    ///   - task: The updated task
    public func updateEvent(_ eventId: String, from task: Task) -> Result<Void, CalendarError> {
        guard hasAuthorization else {
            return .failure(.notAuthorized)
        }

        guard let event = eventStore.event(withIdentifier: eventId) else {
            return .failure(.eventNotFound)
        }

        guard event.calendar.allowsContentModifications else {
            return .failure(.calendarReadOnly)
        }

        // Update event properties
        event.title = task.title

        var notesContent = task.notes
        if !task.notes.isEmpty {
            notesContent += "\n\n"
        }
        notesContent += "---\n"
        notesContent += "Task ID: \(task.id.uuidString)\n"
        if let project = task.project {
            notesContent += "Project: \(project)\n"
        }
        if let context = task.context {
            notesContent += "Context: \(context)\n"
        }
        event.notes = notesContent

        // Update date if changed
        if let dueDate = task.due {
            event.startDate = dueDate

            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: dueDate)
            if components.hour == 0 && components.minute == 0 {
                event.isAllDay = true
                event.endDate = dueDate
            } else {
                event.isAllDay = false
                event.endDate = dueDate.addingTimeInterval(3600)
            }
        }

        // Update alarm based on flagged status
        event.alarms?.removeAll()
        if task.flagged {
            let alarm = EKAlarm(relativeOffset: -3600)
            event.addAlarm(alarm)
        }

        // Save changes
        do {
            try eventStore.save(event, span: .thisEvent)
            return .success(())
        } catch {
            let calendarError = CalendarError.saveFailed(error.localizedDescription)
            lastError = calendarError
            return .failure(calendarError)
        }
    }

    /// Delete a calendar event
    /// - Parameter eventId: The event identifier
    public func deleteEvent(_ eventId: String) -> Result<Void, CalendarError> {
        guard hasAuthorization else {
            return .failure(.notAuthorized)
        }

        guard let event = eventStore.event(withIdentifier: eventId) else {
            return .failure(.eventNotFound)
        }

        guard event.calendar.allowsContentModifications else {
            return .failure(.calendarReadOnly)
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
            return .success(())
        } catch {
            let calendarError = CalendarError.deleteFailed(error.localizedDescription)
            lastError = calendarError
            return .failure(calendarError)
        }
    }

    /// Fetch a calendar event by ID
    /// - Parameter eventId: The event identifier
    /// - Returns: The calendar event if found
    public func fetchEvent(_ eventId: String) -> EKEvent? {
        guard hasAuthorization else { return nil }
        return eventStore.event(withIdentifier: eventId)
    }

    /// Sync a task with its calendar event
    /// - Parameter task: The task to sync
    public func syncTask(_ task: Task) -> Result<String?, CalendarError> {
        guard preferences.autoSyncEnabled else {
            return .success(nil)
        }

        // Check if task should be synced
        guard shouldSyncTask(task) else {
            // If task has an event but shouldn't be synced, remove it
            if let eventId = task.calendarEventId {
                _ = deleteEvent(eventId)
                return .success(nil)
            }
            return .success(nil)
        }

        // Create or update event
        if let eventId = task.calendarEventId {
            // Update existing event
            switch updateEvent(eventId, from: task) {
            case .success:
                return .success(eventId)
            case .failure(let error):
                return .failure(error)
            }
        } else {
            // Create new event
            switch createEvent(from: task) {
            case .success(let eventId):
                return .success(eventId)
            case .failure(let error):
                return .failure(error)
            }
        }
    }

    /// Check if a task should be synced based on preferences
    /// - Parameter task: The task to check
    /// - Returns: True if task should be synced
    public func shouldSyncTask(_ task: Task) -> Bool {
        // Don't sync completed tasks
        guard task.status != .completed else { return false }

        // Must have a due date
        guard task.due != nil else { return false }

        // Check sync filter
        switch preferences.syncFilter {
        case .all:
            return true
        case .flaggedOnly:
            return task.flagged
        case .withDueDate:
            return task.due != nil
        case .flaggedWithDueDate:
            return task.flagged && task.due != nil
        }
    }

    /// Sync all tasks from a task store
    /// - Parameter tasks: Array of tasks to sync
    /// - Returns: Dictionary mapping task IDs to event IDs
    public func syncAllTasks(_ tasks: [Task]) -> [UUID: String?] {
        var results: [UUID: String?] = [:]

        for task in tasks {
            switch syncTask(task) {
            case .success(let eventId):
                results[task.id] = eventId
            case .failure(let error):
                print("Failed to sync task \(task.id): \(error)")
                results[task.id] = nil
            }
        }

        return results
    }

    // MARK: - Preferences

    /// Load calendar preferences from UserDefaults
    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "CalendarPreferences"),
           let prefs = try? JSONDecoder().decode(CalendarPreferences.self, from: data) {
            preferences = prefs
        }
    }

    /// Save calendar preferences to UserDefaults
    public func savePreferences() {
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: "CalendarPreferences")
        }
    }

    // MARK: - Event Fetching

    /// Fetch events for a date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    ///   - calendars: Optional specific calendars (uses all if nil)
    /// - Returns: Array of events
    public func fetchEvents(from startDate: Date, to endDate: Date, in calendars: [EKCalendar]? = nil) -> [EKEvent] {
        guard hasAuthorization else { return [] }

        let targetCalendars = calendars ?? availableCalendars
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: targetCalendars)

        return eventStore.events(matching: predicate)
    }
}

// MARK: - Supporting Types

/// Calendar sync preferences
public struct CalendarPreferences: Codable {
    /// Whether auto-sync is enabled
    public var autoSyncEnabled: Bool = false

    /// Default calendar identifier for new events
    public var defaultCalendarId: String?

    /// Filter for which tasks to sync
    public var syncFilter: SyncFilter = .flaggedWithDueDate

    /// Whether to create reminders in addition to events
    public var createReminders: Bool = false
}

/// Sync filter options
public enum SyncFilter: String, Codable, CaseIterable {
    case all = "All Tasks with Due Dates"
    case flaggedOnly = "Flagged Tasks Only"
    case withDueDate = "All with Due Dates"
    case flaggedWithDueDate = "Flagged with Due Dates"
}

/// Calendar-related errors
public enum CalendarError: LocalizedError, Equatable {
    case notAuthorized
    case authorizationFailed(String)
    case noCalendarSelected
    case invalidTaskData(String)
    case eventNotFound
    case calendarReadOnly
    case saveFailed(String)
    case deleteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized. Please grant permission in System Preferences."
        case .authorizationFailed(let message):
            return "Authorization failed: \(message)"
        case .noCalendarSelected:
            return "No calendar selected. Please choose a default calendar in settings."
        case .invalidTaskData(let message):
            return "Invalid task data: \(message)"
        case .eventNotFound:
            return "Calendar event not found. It may have been deleted."
        case .calendarReadOnly:
            return "Cannot modify this calendar. Please select a different calendar."
        case .saveFailed(let message):
            return "Failed to save event: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete event: \(message)"
        }
    }
}
