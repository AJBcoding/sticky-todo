//
//  TimeEntry.swift
//  StickyToDo
//
//  Time tracking entry model for recording work sessions on tasks.
//

import Foundation

/// Represents a single time tracking session for a task
///
/// Time entries are stored as markdown files with YAML frontmatter in the time-entries/ directory.
/// The file system organization is: time-entries/YYYY/MM/uuid.md
public struct TimeEntry: Identifiable, Codable, Equatable {
    // MARK: - Core Properties

    /// Unique identifier for the time entry
    let id: UUID

    /// ID of the task this time entry belongs to
    var taskId: UUID

    /// When the timer started
    var startTime: Date

    /// When the timer ended (nil if timer is still running)
    var endTime: Date?

    /// Duration in seconds (computed if endTime is set, otherwise calculated from startTime)
    var duration: TimeInterval {
        if let end = endTime {
            return end.timeIntervalSince(startTime)
        } else {
            // Timer is still running
            return Date().timeIntervalSince(startTime)
        }
    }

    /// Optional notes about what was accomplished during this session
    var notes: String

    // MARK: - Metadata

    /// When this entry was created (usually same as startTime)
    var created: Date

    /// When this entry was last modified
    var modified: Date

    // MARK: - Initialization

    /// Creates a new time entry
    /// - Parameters:
    ///   - id: Unique identifier (generates new UUID if not provided)
    ///   - taskId: ID of the task being tracked
    ///   - startTime: When the timer started (defaults to now)
    ///   - endTime: When the timer ended (nil if still running)
    ///   - notes: Optional notes about the session
    ///   - created: Creation timestamp (defaults to now)
    ///   - modified: Modification timestamp (defaults to now)
    public init(
        id: UUID = UUID(),
        taskId: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        notes: String = "",
        created: Date = Date(),
        modified: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.created = created
        self.modified = modified
    }
}

// MARK: - Computed Properties

extension TimeEntry {
    /// Returns the file path for this time entry based on its creation date
    /// Format: time-entries/YYYY/MM/uuid.md
    var filePath: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: created)
        let month = calendar.component(.month, from: created)

        let monthString = String(format: "%02d", month)

        return "time-entries/\(year)/\(monthString)/\(id.uuidString).md"
    }

    /// Returns the relative path from the project root
    var relativePath: String {
        return filePath
    }

    /// Returns just the filename component
    var fileName: String {
        return "\(id.uuidString).md"
    }

    /// Returns true if this time entry is currently running
    var isRunning: Bool {
        return endTime == nil
    }

    /// Returns a human-readable description of the duration
    var durationDescription: String {
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

    /// Returns a compact duration description (suitable for badges)
    var compactDurationDescription: String {
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

    /// Returns the date range as a formatted string
    var dateRangeDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let startString = formatter.string(from: startTime)

        if let end = endTime {
            formatter.timeStyle = .short
            let endString = formatter.string(from: end)
            return "\(startString) - \(endString)"
        } else {
            return "\(startString) - Now"
        }
    }
}

// MARK: - Helper Methods

extension TimeEntry {
    /// Stops the timer by setting the end time
    mutating func stop() {
        guard endTime == nil else { return }
        endTime = Date()
        modified = Date()
    }

    /// Updates the modified timestamp
    mutating func touch() {
        modified = Date()
    }

    /// Returns true if this entry overlaps with another entry
    /// - Parameter other: The other time entry to check against
    /// - Returns: True if the entries overlap in time
    func overlaps(with other: TimeEntry) -> Bool {
        let thisStart = startTime
        let thisEnd = endTime ?? Date()
        let otherStart = other.startTime
        let otherEnd = other.endTime ?? Date()

        return thisStart < otherEnd && otherStart < thisEnd
    }

    /// Returns true if this entry occurred on the given date
    /// - Parameter date: The date to check
    /// - Returns: True if the entry started on the given date
    func occurred(on date: Date) -> Bool {
        return Calendar.current.isDate(startTime, inSameDayAs: date)
    }

    /// Returns true if this entry occurred in the given month
    /// - Parameter date: A date in the month to check
    /// - Returns: True if the entry started in the same month
    func occurred(inMonthOf date: Date) -> Bool {
        let calendar = Calendar.current
        let entryComponents = calendar.dateComponents([.year, .month], from: startTime)
        let dateComponents = calendar.dateComponents([.year, .month], from: date)

        return entryComponents.year == dateComponents.year &&
               entryComponents.month == dateComponents.month
    }

    /// Returns true if this entry occurred in the given week
    /// - Parameter date: A date in the week to check
    /// - Returns: True if the entry started in the same week
    func occurred(inWeekOf date: Date) -> Bool {
        let calendar = Calendar.current
        let entryComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startTime)
        let dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)

        return entryComponents.yearForWeekOfYear == dateComponents.yearForWeekOfYear &&
               entryComponents.weekOfYear == dateComponents.weekOfYear
    }
}

// MARK: - Aggregation Helpers

extension Array where Element == TimeEntry {
    /// Calculates the total duration of all entries in the array
    var totalDuration: TimeInterval {
        return reduce(0) { $0 + $1.duration }
    }

    /// Returns a human-readable description of the total duration
    var totalDurationDescription: String {
        let seconds = Int(totalDuration)
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

    /// Groups entries by date
    func grouped(byDate: Bool) -> [Date: [TimeEntry]] {
        let calendar = Calendar.current
        var groups: [Date: [TimeEntry]] = [:]

        for entry in self {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: entry.startTime)
            if let date = calendar.date(from: dateComponents) {
                groups[date, default: []].append(entry)
            }
        }

        return groups
    }

    /// Groups entries by task ID
    func grouped(byTask: Bool) -> [UUID: [TimeEntry]] {
        return Dictionary(grouping: self, by: { $0.taskId })
    }
}
