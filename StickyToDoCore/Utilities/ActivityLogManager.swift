//
//  ActivityLogManager.swift
//  StickyToDo
//
//  Manager for activity log entries with filtering, search, and persistence.
//  Handles log retention policy and exports.
//

import Foundation
import Combine

/// Manager for activity log entries
///
/// ActivityLogManager provides:
/// - In-memory storage of activity logs
/// - Automatic persistence to disk
/// - Filtering by task, date range, and change type
/// - Search functionality
/// - Grouping by task or date
/// - Export to CSV/JSON
/// - Retention policy management (default 90 days)
final class ActivityLogManager: ObservableObject {

    // MARK: - Published Properties

    /// All activity log entries
    @Published private(set) var logs: [ActivityLog] = []

    // MARK: - Private Properties

    /// File I/O handler for reading/writing log files
    private let fileIO: MarkdownFileIO

    /// Serial queue for thread-safe access
    private let queue = DispatchQueue(label: "com.stickytodo.activitylog", qos: .userInitiated)

    /// Retention period in days (default 90 days)
    private var retentionDays: Int

    /// Logger for debugging operations
    private var logger: ((String) -> Void)?

    /// Save debounce timer
    private var saveTimer: Timer?

    /// Save debounce interval (1 second)
    private let saveDebounceInterval: TimeInterval = 1.0

    // MARK: - Initialization

    /// Creates a new ActivityLogManager
    /// - Parameters:
    ///   - fileIO: The file I/O handler for persistence
    ///   - retentionDays: Number of days to retain logs (default 90)
    public init(fileIO: MarkdownFileIO, retentionDays: Int = 90) {
        self.fileIO = fileIO
        self.retentionDays = retentionDays
    }

    /// Configure logging for activity log operations
    /// - Parameter logger: A closure that receives log messages
    func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    // MARK: - Configuration

    /// Updates the retention period
    /// - Parameter days: Number of days to retain logs
    func setRetentionPeriod(days: Int) {
        retentionDays = days
        logger?("Updated retention period to \(days) days")
    }

    /// Returns the current retention period
    var currentRetentionDays: Int {
        return retentionDays
    }

    // MARK: - Loading

    /// Loads all activity logs from the file system
    /// - Throws: Error if loading fails
    func loadAll() throws {
        logger?("Loading all activity logs from file system")

        let loadedLogs = try fileIO.loadAllActivityLogs()

        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.logs = loadedLogs.sorted { $0.timestamp > $1.timestamp }
                self.logger?("Loaded \(loadedLogs.count) activity log entries")

                // Apply retention policy after loading
                self.applyRetentionPolicy()
            }
        }
    }

    /// Loads all activity logs asynchronously
    func loadAllAsync() async throws {
        logger?("Loading all activity logs asynchronously")
        let loadedLogs = try fileIO.loadAllActivityLogs()

        await MainActor.run {
            self.logs = loadedLogs.sorted { $0.timestamp > $1.timestamp }
            self.logger?("Loaded \(loadedLogs.count) activity log entries")

            // Apply retention policy after loading
            self.applyRetentionPolicy()
        }
    }

    // MARK: - Adding Log Entries

    /// Adds a new activity log entry
    /// - Parameter log: The log entry to add
    func addLog(_ log: ActivityLog) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.logs.insert(log, at: 0) // Insert at beginning for chronological order
                self.logger?("Added activity log: \(log.description)")

                // Schedule debounced save
                self.scheduleSave()
            }
        }
    }

    /// Adds multiple log entries at once
    /// - Parameter logs: The log entries to add
    func addLogs(_ logs: [ActivityLog]) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.logs.insert(contentsOf: logs, at: 0)
                self.logs.sort { $0.timestamp > $1.timestamp }
                self.logger?("Added \(logs.count) activity log entries")

                // Schedule debounced save
                self.scheduleSave()
            }
        }
    }

    // MARK: - Saving

    /// Saves all activity logs to disk with debouncing
    private func scheduleSave() {
        // Cancel any existing timer
        saveTimer?.invalidate()

        // Create new timer
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.queue.async {
                do {
                    try self.fileIO.writeAllActivityLogs(self.logs)
                    self.logger?("Saved \(self.logs.count) activity log entries")
                } catch {
                    self.logger?("Failed to save activity logs: \(error)")
                }
            }
        }
    }

    /// Immediately saves all logs to disk without debouncing
    /// - Throws: Error if saving fails
    func saveImmediately() throws {
        saveTimer?.invalidate()
        saveTimer = nil

        try fileIO.writeAllActivityLogs(logs)
        logger?("Immediately saved \(logs.count) activity log entries")
    }

    // MARK: - Filtering

    /// Returns logs for a specific task
    /// - Parameter taskId: The task ID to filter by
    /// - Returns: Array of logs for that task
    func logs(forTask taskId: UUID) -> [ActivityLog] {
        return logs.filter { $0.isForTask(taskId) }
    }

    /// Returns logs within a date range
    /// - Parameters:
    ///   - startDate: Start date (inclusive, nil for no start limit)
    ///   - endDate: End date (inclusive, nil for no end limit)
    /// - Returns: Array of logs within the date range
    func logs(from startDate: Date?, to endDate: Date?) -> [ActivityLog] {
        return logs.filter { $0.isInDateRange(from: startDate, to: endDate) }
    }

    /// Returns logs of a specific change type
    /// - Parameter changeType: The change type to filter by
    /// - Returns: Array of logs with that change type
    func logs(ofType changeType: ActivityLog.ChangeType) -> [ActivityLog] {
        return logs.filter { $0.hasChangeType(changeType) }
    }

    /// Returns logs matching a search query
    /// - Parameter query: The search string
    /// - Returns: Array of logs matching the query
    func logs(matchingSearch query: String) -> [ActivityLog] {
        guard !query.isEmpty else { return logs }
        return logs.filter { $0.matchesSearch(query) }
    }

    /// Returns logs with combined filters
    /// - Parameters:
    ///   - taskId: Task ID to filter by (nil for all tasks)
    ///   - changeType: Change type to filter by (nil for all types)
    ///   - startDate: Start date (nil for no start limit)
    ///   - endDate: End date (nil for no end limit)
    ///   - searchQuery: Search query (nil for no search)
    /// - Returns: Array of logs matching all criteria
    func filteredLogs(
        taskId: UUID? = nil,
        changeType: ActivityLog.ChangeType? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        searchQuery: String? = nil
    ) -> [ActivityLog] {
        var filtered = logs

        if let taskId = taskId {
            filtered = filtered.filter { $0.isForTask(taskId) }
        }

        if let changeType = changeType {
            filtered = filtered.filter { $0.hasChangeType(changeType) }
        }

        filtered = filtered.filter { $0.isInDateRange(from: startDate, to: endDate) }

        if let query = searchQuery, !query.isEmpty {
            filtered = filtered.filter { $0.matchesSearch(query) }
        }

        return filtered
    }

    // MARK: - Grouping

    /// Groups logs by date
    /// - Returns: Dictionary keyed by date string
    func groupedByDate() -> [String: [ActivityLog]] {
        return Dictionary(grouping: logs) { $0.dateKey }
    }

    /// Groups logs by task
    /// - Returns: Dictionary keyed by task ID
    func groupedByTask() -> [UUID: [ActivityLog]] {
        return Dictionary(grouping: logs) { $0.taskId }
    }

    /// Groups filtered logs by date
    /// - Parameters:
    ///   - taskId: Task ID to filter by (nil for all tasks)
    ///   - changeType: Change type to filter by (nil for all types)
    ///   - startDate: Start date (nil for no start limit)
    ///   - endDate: End date (nil for no end limit)
    ///   - searchQuery: Search query (nil for no search)
    /// - Returns: Dictionary keyed by date string
    func groupedByDate(
        taskId: UUID? = nil,
        changeType: ActivityLog.ChangeType? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        searchQuery: String? = nil
    ) -> [String: [ActivityLog]] {
        let filtered = filteredLogs(
            taskId: taskId,
            changeType: changeType,
            startDate: startDate,
            endDate: endDate,
            searchQuery: searchQuery
        )
        return Dictionary(grouping: filtered) { $0.dateKey }
    }

    // MARK: - Statistics

    /// Returns the total number of log entries
    var logCount: Int {
        return logs.count
    }

    /// Returns the number of logs for a specific task
    /// - Parameter taskId: The task ID
    /// - Returns: Number of log entries for that task
    func logCount(forTask taskId: UUID) -> Int {
        return logs(forTask: taskId).count
    }

    /// Returns the number of logs for each change type
    /// - Returns: Dictionary mapping change types to counts
    func logCountsByChangeType() -> [ActivityLog.ChangeType: Int] {
        return Dictionary(grouping: logs) { $0.changeType }
            .mapValues { $0.count }
    }

    /// Returns the most active day (day with most changes)
    /// - Returns: Tuple of date string and count, or nil if no logs
    func mostActiveDay() -> (date: String, count: Int)? {
        let grouped = groupedByDate()
        return grouped.max { $0.value.count < $1.value.count }
            .map { (date: $0.key, count: $0.value.count) }
    }

    /// Returns the most changed task (task with most log entries)
    /// - Returns: Tuple of task ID, title, and count, or nil if no logs
    func mostChangedTask() -> (taskId: UUID, taskTitle: String, count: Int)? {
        let grouped = groupedByTask()
        return grouped.max { $0.value.count < $1.value.count }
            .flatMap { key, value in
                value.first.map { (taskId: key, taskTitle: $0.taskTitle, count: value.count) }
            }
    }

    // MARK: - Retention Policy

    /// Applies the retention policy, removing old log entries
    /// - Returns: Number of logs removed
    @discardableResult
    func applyRetentionPolicy() -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date())!

        let beforeCount = logs.count
        logs.removeAll { $0.timestamp < cutoffDate }
        let removedCount = beforeCount - logs.count

        if removedCount > 0 {
            logger?("Removed \(removedCount) old activity log entries (retention policy: \(retentionDays) days)")
            scheduleSave()
        }

        return removedCount
    }

    /// Manually clears all logs
    func clearAll() {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                let count = self.logs.count
                self.logs.removeAll()
                self.logger?("Cleared all \(count) activity log entries")
                self.scheduleSave()
            }
        }
    }

    /// Clears logs for a specific task
    /// - Parameter taskId: The task ID
    func clearLogs(forTask taskId: UUID) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                let beforeCount = self.logs.count
                self.logs.removeAll { $0.isForTask(taskId) }
                let removedCount = beforeCount - self.logs.count

                if removedCount > 0 {
                    self.logger?("Cleared \(removedCount) activity log entries for task")
                    self.scheduleSave()
                }
            }
        }
    }

    // MARK: - Export

    /// Exports logs to CSV format
    /// - Parameters:
    ///   - logs: The logs to export (defaults to all logs)
    ///   - includedHeader: Whether to include CSV header row
    /// - Returns: CSV string
    func exportToCSV(logs: [ActivityLog]? = nil, includeHeader: Bool = true) -> String {
        let logsToExport = logs ?? self.logs
        var csv = ""

        if includeHeader {
            csv += ActivityLog.csvHeader.joined(separator: ",") + "\n"
        }

        for log in logsToExport {
            let row = log.toCSVRow().map { field in
                // Escape fields containing commas or quotes
                if field.contains(",") || field.contains("\"") {
                    return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
                } else {
                    return field
                }
            }
            csv += row.joined(separator: ",") + "\n"
        }

        return csv
    }

    /// Exports logs to JSON format
    /// - Parameter logs: The logs to export (defaults to all logs)
    /// - Returns: JSON data
    /// - Throws: Error if JSON encoding fails
    func exportToJSON(logs: [ActivityLog]? = nil) throws -> Data {
        let logsToExport = logs ?? self.logs
        let dictionaries = logsToExport.map { $0.toJSONDictionary() }

        return try JSONSerialization.data(
            withJSONObject: dictionaries,
            options: [.prettyPrinted, .sortedKeys]
        )
    }

    /// Exports logs to a CSV file
    /// - Parameters:
    ///   - url: The file URL to write to
    ///   - logs: The logs to export (defaults to all logs)
    /// - Throws: Error if writing fails
    func exportToCSVFile(url: URL, logs: [ActivityLog]? = nil) throws {
        let csv = exportToCSV(logs: logs, includeHeader: true)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        logger?("Exported \(logs?.count ?? self.logs.count) logs to CSV: \(url.path)")
    }

    /// Exports logs to a JSON file
    /// - Parameters:
    ///   - url: The file URL to write to
    ///   - logs: The logs to export (defaults to all logs)
    /// - Throws: Error if writing fails
    func exportToJSONFile(url: URL, logs: [ActivityLog]? = nil) throws {
        let jsonData = try exportToJSON(logs: logs)
        try jsonData.write(to: url)
        logger?("Exported \(logs?.count ?? self.logs.count) logs to JSON: \(url.path)")
    }

    // MARK: - Cleanup

    deinit {
        saveTimer?.invalidate()
    }
}

// MARK: - Helper Extensions

extension ActivityLogManager {
    /// Returns recent logs (last 100)
    var recentLogs: [ActivityLog] {
        return Array(logs.prefix(100))
    }

    /// Returns today's logs
    var todayLogs: [ActivityLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return logs(from: today, to: tomorrow)
    }

    /// Returns this week's logs
    var thisWeekLogs: [ActivityLog] {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return logs(from: weekStart, to: Date())
    }

    /// Returns this month's logs
    var thisMonthLogs: [ActivityLog] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        return logs(from: monthStart, to: Date())
    }
}
