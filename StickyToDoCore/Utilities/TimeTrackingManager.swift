//
//  TimeTrackingManager.swift
//  StickyToDo
//
//  Manages time tracking operations for tasks, including starting/stopping timers
//  and maintaining time entry records.
//

import Foundation
import Combine

/// Manages time tracking for tasks
///
/// This class handles:
/// - Starting and stopping timers for tasks
/// - Creating and managing time entries
/// - Calculating time statistics
/// - Persisting time entries to disk
public class TimeTrackingManager: ObservableObject {

    // MARK: - Published Properties

    /// All time entries loaded from the file system
    @Published private(set) var timeEntries: [TimeEntry] = []

    /// Currently running timers (task ID -> timer start time)
    @Published private(set) var runningTimers: [UUID: Date] = [:]

    // MARK: - Private Properties

    /// Timer that fires every second to update running timers
    private var updateTimer: Timer?

    /// Callbacks for when timers change
    private var timerCallbacks: [(UUID, TimeInterval) -> Void] = []

    // MARK: - Initialization

    public init() {
        // Start the update timer to refresh running timer displays
        startUpdateTimer()
    }

    deinit {
        stopUpdateTimer()
    }

    // MARK: - Timer Management

    /// Starts a timer for a task
    /// - Parameters:
    ///   - task: The task to start timing
    ///   - startTime: When the timer started (defaults to now)
    /// - Returns: Updated task with timer running
    func startTimer(for task: Task, startTime: Date = Date()) -> Task {
        var updatedTask = task

        // Stop any existing timer for this task
        if updatedTask.isTimerRunning {
            updatedTask = stopTimer(for: updatedTask)
        }

        // Start the new timer
        updatedTask.isTimerRunning = true
        updatedTask.currentTimerStart = startTime
        updatedTask.touch()

        // Track in running timers
        runningTimers[task.id] = startTime

        return updatedTask
    }

    /// Stops the timer for a task and creates a time entry
    /// - Parameter task: The task to stop timing
    /// - Returns: Tuple of (updated task, new time entry)
    func stopTimer(for task: Task) -> (task: Task, entry: TimeEntry?) {
        var updatedTask = task
        var newEntry: TimeEntry? = nil

        guard updatedTask.isTimerRunning,
              let startTime = updatedTask.currentTimerStart else {
            return (updatedTask, nil)
        }

        let endTime = Date()

        // Create a time entry
        let entry = TimeEntry(
            taskId: task.id,
            startTime: startTime,
            endTime: endTime
        )

        // Update the task's total time
        updatedTask.totalTimeSpent += entry.duration
        updatedTask.isTimerRunning = false
        updatedTask.currentTimerStart = nil
        updatedTask.touch()

        // Add to time entries
        timeEntries.append(entry)
        newEntry = entry

        // Remove from running timers
        runningTimers.removeValue(forKey: task.id)

        return (updatedTask, newEntry)
    }

    /// Stops the timer for a task without returning the entry (convenience method)
    /// - Parameter task: The task to stop timing
    /// - Returns: Updated task with timer stopped
    func stopTimer(for task: Task) -> Task {
        let (updatedTask, _) = stopTimer(for: task) as (task: Task, entry: TimeEntry?)
        return updatedTask
    }

    /// Toggles the timer for a task (start if stopped, stop if running)
    /// - Parameter task: The task to toggle timing for
    /// - Returns: Tuple of (updated task, optional time entry if stopped)
    func toggleTimer(for task: Task) -> (task: Task, entry: TimeEntry?) {
        if task.isTimerRunning {
            return stopTimer(for: task)
        } else {
            let updatedTask = startTimer(for: task)
            return (updatedTask, nil)
        }
    }

    /// Returns the current duration for a running timer
    /// - Parameter taskId: The ID of the task
    /// - Returns: Duration in seconds, or nil if no timer is running
    func currentDuration(for taskId: UUID) -> TimeInterval? {
        guard let startTime = runningTimers[taskId] else { return nil }
        return Date().timeIntervalSince(startTime)
    }

    // MARK: - Time Entry Management

    /// Adds a time entry manually
    /// - Parameter entry: The time entry to add
    func addEntry(_ entry: TimeEntry) {
        timeEntries.append(entry)
    }

    /// Updates an existing time entry
    /// - Parameter entry: The updated time entry
    func updateEntry(_ entry: TimeEntry) {
        if let index = timeEntries.firstIndex(where: { $0.id == entry.id }) {
            timeEntries[index] = entry
        }
    }

    /// Deletes a time entry
    /// - Parameter entry: The time entry to delete
    func deleteEntry(_ entry: TimeEntry) {
        timeEntries.removeAll { $0.id == entry.id }
    }

    /// Loads all time entries from an array (used when loading from disk)
    /// - Parameter entries: The time entries to load
    func loadEntries(_ entries: [TimeEntry]) {
        self.timeEntries = entries
    }

    // MARK: - Statistics

    /// Returns all time entries for a specific task
    /// - Parameter taskId: The task ID
    /// - Returns: Array of time entries for the task
    func entries(for taskId: UUID) -> [TimeEntry] {
        return timeEntries.filter { $0.taskId == taskId }
    }

    /// Returns the total time spent on a task (from time entries)
    /// - Parameter taskId: The task ID
    /// - Returns: Total duration in seconds
    func totalTime(for taskId: UUID) -> TimeInterval {
        return entries(for: taskId).totalDuration
    }

    /// Returns time entries for a specific date
    /// - Parameter date: The date to filter by
    /// - Returns: Array of time entries that occurred on the date
    func entries(on date: Date) -> [TimeEntry] {
        return timeEntries.filter { $0.occurred(on: date) }
    }

    /// Returns time entries for a specific week
    /// - Parameter date: A date in the week to filter by
    /// - Returns: Array of time entries that occurred in the week
    func entries(inWeekOf date: Date) -> [TimeEntry] {
        return timeEntries.filter { $0.occurred(inWeekOf: date) }
    }

    /// Returns time entries for a specific month
    /// - Parameter date: A date in the month to filter by
    /// - Returns: Array of time entries that occurred in the month
    func entries(inMonthOf date: Date) -> [TimeEntry] {
        return timeEntries.filter { $0.occurred(inMonthOf: date) }
    }

    /// Returns time entries grouped by date
    /// - Returns: Dictionary of date to time entries
    func entriesGroupedByDate() -> [Date: [TimeEntry]] {
        return timeEntries.grouped(byDate: true)
    }

    /// Returns time entries grouped by task
    /// - Returns: Dictionary of task ID to time entries
    func entriesGroupedByTask() -> [UUID: [TimeEntry]] {
        return timeEntries.grouped(byTask: true)
    }

    // MARK: - Analytics

    /// Analytics data for time tracking
    struct Analytics {
        /// Total time tracked across all tasks
        let totalTime: TimeInterval

        /// Time grouped by project
        let timeByProject: [String: TimeInterval]

        /// Time grouped by context
        let timeByContext: [String: TimeInterval]

        /// Time grouped by date
        let timeByDate: [Date: TimeInterval]

        /// Time grouped by task
        let timeByTask: [UUID: TimeInterval]

        /// Average time per task
        let averageTimePerTask: TimeInterval

        /// Number of time entries
        let entryCount: Int
    }

    /// Calculates analytics for time entries with associated tasks
    /// - Parameter tasks: Array of tasks to include in analytics
    /// - Returns: Analytics data structure
    func calculateAnalytics(for tasks: [Task]) -> Analytics {
        let taskMap = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })

        var timeByProject: [String: TimeInterval] = [:]
        var timeByContext: [String: TimeInterval] = [:]
        var timeByDate: [Date: TimeInterval] = [:]
        var timeByTask: [UUID: TimeInterval] = [:]

        let calendar = Calendar.current

        for entry in timeEntries {
            let duration = entry.duration

            // Group by task
            timeByTask[entry.taskId, default: 0] += duration

            // Group by project and context (if we have the task)
            if let task = taskMap[entry.taskId] {
                if let project = task.project {
                    timeByProject[project, default: 0] += duration
                }

                if let context = task.context {
                    timeByContext[context, default: 0] += duration
                }
            }

            // Group by date
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: entry.startTime)
            if let date = calendar.date(from: dateComponents) {
                timeByDate[date, default: 0] += duration
            }
        }

        let totalTime = timeEntries.totalDuration
        let averageTime = timeByTask.isEmpty ? 0 : totalTime / TimeInterval(timeByTask.count)

        return Analytics(
            totalTime: totalTime,
            timeByProject: timeByProject,
            timeByContext: timeByContext,
            timeByDate: timeByDate,
            timeByTask: timeByTask,
            averageTimePerTask: averageTime,
            entryCount: timeEntries.count
        )
    }

    /// Returns the top N tasks by time spent
    /// - Parameters:
    ///   - count: Number of tasks to return
    ///   - tasks: Array of tasks to consider
    /// - Returns: Array of (task, duration) tuples sorted by duration
    func topTasks(count: Int, from tasks: [Task]) -> [(task: Task, duration: TimeInterval)] {
        let taskMap = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        let timeByTask = entriesGroupedByTask().mapValues { $0.totalDuration }

        return timeByTask
            .compactMap { taskId, duration -> (Task, TimeInterval)? in
                guard let task = taskMap[taskId] else { return nil }
                return (task, duration)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(count)
            .map { $0 }
    }

    // MARK: - CSV Export

    /// Exports time entries to CSV format
    /// - Parameters:
    ///   - tasks: Array of tasks to include task names
    ///   - dateRange: Optional date range to filter entries
    /// - Returns: CSV string
    func exportToCSV(tasks: [Task], dateRange: ClosedRange<Date>? = nil) -> String {
        let taskMap = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })

        var entries = timeEntries

        // Filter by date range if provided
        if let range = dateRange {
            entries = entries.filter { entry in
                entry.startTime >= range.lowerBound && entry.startTime <= range.upperBound
            }
        }

        // Build CSV
        var csv = "Date,Start Time,End Time,Duration (minutes),Task,Project,Context,Notes\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        for entry in entries.sorted(by: { $0.startTime < $1.startTime }) {
            let task = taskMap[entry.taskId]

            let date = dateFormatter.string(from: entry.startTime)
            let startTime = timeFormatter.string(from: entry.startTime)
            let endTime = entry.endTime.map { timeFormatter.string(from: $0) } ?? "Running"
            let durationMinutes = Int(entry.duration / 60)
            let taskName = task?.title ?? "Unknown Task"
            let project = task?.project ?? ""
            let context = task?.context ?? ""
            let notes = entry.notes.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: ",", with: ";")

            csv += "\(date),\(startTime),\(endTime),\(durationMinutes),\(taskName),\(project),\(context),\"\(notes)\"\n"
        }

        return csv
    }

    // MARK: - Private Helpers

    /// Starts the timer that updates running timer displays
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateRunningTimers()
        }
    }

    /// Stops the update timer
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    /// Called every second to trigger UI updates for running timers
    private func updateRunningTimers() {
        // This triggers published property updates
        objectWillChange.send()

        // Call any registered callbacks
        for (taskId, startTime) in runningTimers {
            let duration = Date().timeIntervalSince(startTime)
            for callback in timerCallbacks {
                callback(taskId, duration)
            }
        }
    }

    /// Registers a callback to be called when timer durations update
    /// - Parameter callback: Closure to call with (taskId, duration)
    func onTimerUpdate(_ callback: @escaping (UUID, TimeInterval) -> Void) {
        timerCallbacks.append(callback)
    }
}

// MARK: - Utility Extensions

extension TimeTrackingManager {
    /// Formats a duration as a human-readable string
    /// - Parameter duration: Duration in seconds
    /// - Returns: Formatted string (e.g., "1h 23m")
    static func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    /// Formats a duration with seconds for precise display
    /// - Parameter duration: Duration in seconds
    /// - Returns: Formatted string (e.g., "1h 23m 45s")
    static func formatDurationPrecise(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, secs)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, secs)
        } else {
            return String(format: "%ds", secs)
        }
    }
}
