//
//  ActivityLog.swift
//  StickyToDo
//
//  Activity log model for tracking all task changes and modifications.
//  Provides comprehensive change history with before/after values.
//

import Foundation

/// Represents a single change event in the activity log
///
/// ActivityLog entries track all task modifications, deletions, and creations
/// with before/after values for full audit trail and change history.
struct ActivityLog: Identifiable, Codable, Equatable {

    // MARK: - Core Properties

    /// Unique identifier for this log entry
    let id: UUID

    /// ID of the task this log entry is about
    let taskId: UUID

    /// Title of the task (denormalized for display even if task is deleted)
    let taskTitle: String

    /// Type of change that occurred
    let changeType: ChangeType

    /// When this change occurred
    let timestamp: Date

    /// Before value (if applicable)
    let beforeValue: String?

    /// After value (if applicable)
    let afterValue: String?

    /// Additional metadata about the change
    let metadata: [String: String]?

    // MARK: - Change Types

    /// Types of changes that can be logged
    enum ChangeType: String, Codable, CaseIterable {
        case created = "Created"
        case modified = "Modified"
        case deleted = "Deleted"
        case statusChanged = "Status Changed"
        case priorityChanged = "Priority Changed"
        case projectSet = "Project Set"
        case contextSet = "Context Set"
        case dueDateChanged = "Due Date Changed"
        case deferDateChanged = "Defer Date Changed"
        case flagged = "Flagged"
        case unflagged = "Unflagged"
        case tagAdded = "Tag Added"
        case tagRemoved = "Tag Removed"
        case attachmentAdded = "Attachment Added"
        case attachmentRemoved = "Attachment Removed"
        case timerStarted = "Timer Started"
        case timerStopped = "Timer Stopped"
        case completed = "Completed"
        case uncompleted = "Uncompleted"
        case titleChanged = "Title Changed"
        case notesChanged = "Notes Changed"
        case effortChanged = "Effort Changed"
        case colorChanged = "Color Changed"
        case subtaskAdded = "Subtask Added"
        case subtaskRemoved = "Subtask Removed"
        case parentSet = "Parent Set"
        case positionChanged = "Position Changed"
        case recurrenceSet = "Recurrence Set"
        case typeChanged = "Type Changed"

        /// Human-readable description
        var description: String {
            return rawValue
        }

        /// Icon for this change type
        var icon: String {
            switch self {
            case .created: return "plus.circle"
            case .modified: return "pencil.circle"
            case .deleted: return "trash.circle"
            case .statusChanged: return "arrow.triangle.2.circlepath"
            case .priorityChanged: return "exclamationmark.triangle"
            case .projectSet: return "folder"
            case .contextSet: return "location"
            case .dueDateChanged: return "calendar"
            case .deferDateChanged: return "calendar.badge.clock"
            case .flagged: return "flag.fill"
            case .unflagged: return "flag"
            case .tagAdded: return "tag.fill"
            case .tagRemoved: return "tag"
            case .attachmentAdded: return "paperclip"
            case .attachmentRemoved: return "paperclip"
            case .timerStarted: return "timer"
            case .timerStopped: return "timer"
            case .completed: return "checkmark.circle.fill"
            case .uncompleted: return "circle"
            case .titleChanged: return "textformat"
            case .notesChanged: return "doc.text"
            case .effortChanged: return "clock"
            case .colorChanged: return "paintpalette"
            case .subtaskAdded: return "list.bullet.indent"
            case .subtaskRemoved: return "list.bullet"
            case .parentSet: return "arrow.up.square"
            case .positionChanged: return "move.3d"
            case .recurrenceSet: return "repeat"
            case .typeChanged: return "square.grid.2x2"
            }
        }
    }

    // MARK: - Initialization

    /// Creates a new activity log entry
    /// - Parameters:
    ///   - id: Unique identifier (generates new UUID if not provided)
    ///   - taskId: ID of the task this log entry is about
    ///   - taskTitle: Title of the task
    ///   - changeType: Type of change that occurred
    ///   - timestamp: When this change occurred (defaults to now)
    ///   - beforeValue: Before value (if applicable)
    ///   - afterValue: After value (if applicable)
    ///   - metadata: Additional metadata about the change
    init(
        id: UUID = UUID(),
        taskId: UUID,
        taskTitle: String,
        changeType: ChangeType,
        timestamp: Date = Date(),
        beforeValue: String? = nil,
        afterValue: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.changeType = changeType
        self.timestamp = timestamp
        self.beforeValue = beforeValue
        self.afterValue = afterValue
        self.metadata = metadata
    }
}

// MARK: - Computed Properties

extension ActivityLog {
    /// Returns a human-readable description of this change
    var description: String {
        var desc = "\(changeType.description)"

        if let before = beforeValue, let after = afterValue {
            desc += ": \(before) → \(after)"
        } else if let after = afterValue {
            desc += ": \(after)"
        } else if let before = beforeValue {
            desc += ": was \(before)"
        }

        return desc
    }

    /// Returns a detailed description including task title
    var fullDescription: String {
        return "\(taskTitle): \(description)"
    }

    /// Returns a formatted timestamp
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }

    /// Returns a relative timestamp (e.g., "2 hours ago")
    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Helper Methods

extension ActivityLog {
    /// Creates a log entry for task creation
    static func taskCreated(task: Task) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .created,
            metadata: [
                "type": task.type.rawValue,
                "status": task.status.rawValue
            ]
        )
    }

    /// Creates a log entry for task deletion
    static func taskDeleted(task: Task) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .deleted,
            metadata: [
                "type": task.type.rawValue,
                "status": task.status.rawValue
            ]
        )
    }

    /// Creates a log entry for status change
    static func statusChanged(task: Task, from oldStatus: Status, to newStatus: Status) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .statusChanged,
            beforeValue: oldStatus.rawValue,
            afterValue: newStatus.rawValue
        )
    }

    /// Creates a log entry for priority change
    static func priorityChanged(task: Task, from oldPriority: Priority, to newPriority: Priority) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .priorityChanged,
            beforeValue: oldPriority.rawValue,
            afterValue: newPriority.rawValue
        )
    }

    /// Creates a log entry for project change
    static func projectSet(task: Task, from oldProject: String?, to newProject: String?) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .projectSet,
            beforeValue: oldProject ?? "(none)",
            afterValue: newProject ?? "(none)"
        )
    }

    /// Creates a log entry for context change
    static func contextSet(task: Task, from oldContext: String?, to newContext: String?) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .contextSet,
            beforeValue: oldContext ?? "(none)",
            afterValue: newContext ?? "(none)"
        )
    }

    /// Creates a log entry for due date change
    static func dueDateChanged(task: Task, from oldDue: Date?, to newDue: Date?) -> ActivityLog {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .dueDateChanged,
            beforeValue: oldDue.map { dateFormatter.string(from: $0) } ?? "(none)",
            afterValue: newDue.map { dateFormatter.string(from: $0) } ?? "(none)"
        )
    }

    /// Creates a log entry for defer date change
    static func deferDateChanged(task: Task, from oldDefer: Date?, to newDefer: Date?) -> ActivityLog {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .deferDateChanged,
            beforeValue: oldDefer.map { dateFormatter.string(from: $0) } ?? "(none)",
            afterValue: newDefer.map { dateFormatter.string(from: $0) } ?? "(none)"
        )
    }

    /// Creates a log entry for flagging
    static func flagged(task: Task) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .flagged,
            afterValue: "Flagged"
        )
    }

    /// Creates a log entry for unflagging
    static func unflagged(task: Task) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .unflagged,
            afterValue: "Unflagged"
        )
    }

    /// Creates a log entry for tag addition
    static func tagAdded(task: Task, tag: Tag) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .tagAdded,
            afterValue: tag.name
        )
    }

    /// Creates a log entry for tag removal
    static func tagRemoved(task: Task, tag: Tag) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .tagRemoved,
            beforeValue: tag.name
        )
    }

    /// Creates a log entry for attachment addition
    static func attachmentAdded(task: Task, attachment: Attachment) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .attachmentAdded,
            afterValue: attachment.name
        )
    }

    /// Creates a log entry for attachment removal
    static func attachmentRemoved(task: Task, attachment: Attachment) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .attachmentRemoved,
            beforeValue: attachment.name
        )
    }

    /// Creates a log entry for timer start
    static func timerStarted(task: Task) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .timerStarted,
            metadata: [
                "startTime": ISO8601DateFormatter().string(from: task.currentTimerStart ?? Date())
            ]
        )
    }

    /// Creates a log entry for timer stop
    static func timerStopped(task: Task, duration: TimeInterval) -> ActivityLog {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        var durationStr = ""
        if hours > 0 {
            durationStr = String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            durationStr = String(format: "%dm %ds", minutes, seconds)
        } else {
            durationStr = String(format: "%ds", seconds)
        }

        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .timerStopped,
            afterValue: durationStr,
            metadata: [
                "duration": String(duration)
            ]
        )
    }

    /// Creates a log entry for task completion
    static func completed(task: Task) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .completed
        )
    }

    /// Creates a log entry for task uncompletion
    static func uncompleted(task: Task) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .uncompleted
        )
    }

    /// Creates a log entry for title change
    static func titleChanged(task: Task, from oldTitle: String, to newTitle: String) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: newTitle,
            changeType: .titleChanged,
            beforeValue: oldTitle,
            afterValue: newTitle
        )
    }

    /// Creates a log entry for notes change
    static func notesChanged(task: Task) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .notesChanged,
            afterValue: "Notes updated"
        )
    }

    /// Creates a log entry for effort change
    static func effortChanged(task: Task, from oldEffort: Int?, to newEffort: Int?) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .effortChanged,
            beforeValue: oldEffort.map { "\($0) min" } ?? "(none)",
            afterValue: newEffort.map { "\($0) min" } ?? "(none)"
        )
    }

    /// Creates a log entry for task type change
    static func typeChanged(task: Task, from oldType: TaskType, to newType: TaskType) -> ActivityLog {
        return ActivityLog(
            taskId: task.id,
            taskTitle: task.title,
            changeType: .typeChanged,
            beforeValue: oldType.rawValue,
            afterValue: newType.rawValue
        )
    }
}

// MARK: - Filtering

extension ActivityLog {
    /// Returns true if this log entry matches the given task ID
    func isForTask(_ taskId: UUID) -> Bool {
        return self.taskId == taskId
    }

    /// Returns true if this log entry is within the given date range
    func isInDateRange(from startDate: Date?, to endDate: Date?) -> Bool {
        if let start = startDate, timestamp < start {
            return false
        }

        if let end = endDate, timestamp > end {
            return false
        }

        return true
    }

    /// Returns true if this log entry matches the given change type
    func hasChangeType(_ type: ChangeType) -> Bool {
        return changeType == type
    }

    /// Returns true if this log entry matches the search query
    func matchesSearch(_ query: String) -> Bool {
        let lowercaseQuery = query.lowercased()

        if taskTitle.lowercased().contains(lowercaseQuery) {
            return true
        }

        if changeType.rawValue.lowercased().contains(lowercaseQuery) {
            return true
        }

        if let before = beforeValue, before.lowercased().contains(lowercaseQuery) {
            return true
        }

        if let after = afterValue, after.lowercased().contains(lowercaseQuery) {
            return true
        }

        return false
    }
}

// MARK: - Grouping

extension ActivityLog {
    /// Returns the date component for grouping by date
    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: timestamp)
    }

    /// Returns the task key for grouping by task
    var taskKey: String {
        return taskId.uuidString
    }
}

// MARK: - Export

extension ActivityLog {
    /// Converts this log entry to a CSV row
    func toCSVRow() -> [String] {
        return [
            id.uuidString,
            taskId.uuidString,
            taskTitle,
            changeType.rawValue,
            ISO8601DateFormatter().string(from: timestamp),
            beforeValue ?? "",
            afterValue ?? "",
            metadata?.map { "\($0.key)=\($0.value)" }.joined(separator: "; ") ?? ""
        ]
    }

    /// CSV header row
    static var csvHeader: [String] {
        return ["ID", "Task ID", "Task Title", "Change Type", "Timestamp", "Before Value", "After Value", "Metadata"]
    }

    /// Converts this log entry to a JSON-compatible dictionary
    func toJSONDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "taskId": taskId.uuidString,
            "taskTitle": taskTitle,
            "changeType": changeType.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: timestamp)
        ]

        if let before = beforeValue {
            dict["beforeValue"] = before
        }

        if let after = afterValue {
            dict["afterValue"] = after
        }

        if let meta = metadata {
            dict["metadata"] = meta
        }

        return dict
    }
}
