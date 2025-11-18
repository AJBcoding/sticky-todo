//
//  Task.swift
//  StickyToDo
//
//  Core task model with full GTD metadata.
//

import Foundation

/// Represents a task or note in the StickyToDo system
///
/// Tasks are stored as markdown files with YAML frontmatter in the tasks/ directory.
/// The file system organization is: tasks/active/YYYY/MM/uuid-slug.md or tasks/archive/YYYY/MM/uuid-slug.md
struct Task: Identifiable, Codable, Equatable {
    // MARK: - Core Properties

    /// Unique identifier for the task
    let id: UUID

    /// Task type (note or task)
    var type: TaskType

    /// Task title/summary
    var title: String

    /// Detailed notes in markdown format
    var notes: String

    // MARK: - GTD Metadata

    /// Current status in the GTD workflow
    var status: Status

    /// Project this task belongs to
    var project: String?

    /// Context in which this task can be completed
    var context: String?

    /// Due date for the task
    var due: Date?

    /// Defer/start date - task is hidden until this date
    var defer: Date?

    /// Whether this task is flagged/starred for attention
    var flagged: Bool

    /// Priority level
    var priority: Priority

    /// Estimated effort in minutes
    var effort: Int?

    // MARK: - Organization

    /// Custom tags applied to this task
    var tags: [Tag]

    /// Attachments associated with this task
    var attachments: [Attachment]

    // MARK: - Board Positioning

    /// Position of this task on different boards, keyed by board ID
    var positions: [String: Position]

    // MARK: - Task Hierarchy

    /// Reference to parent task (nil if this is a top-level task)
    var parentId: UUID?

    /// Array of child task IDs (subtasks)
    var subtaskIds: [UUID]

    // MARK: - Recurrence

    /// Recurrence pattern for this task (nil if not recurring)
    var recurrence: Recurrence?

    /// For recurring task instances: the ID of the original template task
    var originalTaskId: UUID?

    /// For recurring task instances: the occurrence date this instance represents
    var occurrenceDate: Date?

    // MARK: - Timestamps

    /// When this task was created
    var created: Date

    /// When this task was last modified
    var modified: Date

    // MARK: - Initialization

    /// Creates a new task with the given title
    /// - Parameters:
    ///   - id: Unique identifier (generates new UUID if not provided)
    ///   - type: Task type (defaults to .task)
    ///   - title: Task title
    ///   - notes: Detailed notes (defaults to empty)
    ///   - status: Initial status (defaults to .inbox)
    ///   - project: Project name
    ///   - context: Context
    ///   - due: Due date
    ///   - defer: Defer date
    ///   - flagged: Flagged state (defaults to false)
    ///   - priority: Priority level (defaults to .medium)
    ///   - effort: Estimated effort in minutes
    ///   - tags: Custom tags (defaults to empty)
    ///   - attachments: Task attachments (defaults to empty)
    ///   - positions: Initial board positions (defaults to empty)
    ///   - parentId: Reference to parent task (defaults to nil)
    ///   - subtaskIds: Array of child task IDs (defaults to empty)
    ///   - recurrence: Recurrence pattern for recurring tasks
    ///   - originalTaskId: ID of the template task (for recurring instances)
    ///   - occurrenceDate: Date this occurrence represents
    ///   - created: Creation timestamp (defaults to now)
    ///   - modified: Modification timestamp (defaults to now)
    init(
        id: UUID = UUID(),
        type: TaskType = .task,
        title: String,
        notes: String = "",
        status: Status = .inbox,
        project: String? = nil,
        context: String? = nil,
        due: Date? = nil,
        defer: Date? = nil,
        flagged: Bool = false,
        priority: Priority = .medium,
        effort: Int? = nil,
        tags: [Tag] = [],
        attachments: [Attachment] = [],
        positions: [String: Position] = [:],
        parentId: UUID? = nil,
        subtaskIds: [UUID] = [],
        recurrence: Recurrence? = nil,
        originalTaskId: UUID? = nil,
        occurrenceDate: Date? = nil,
        created: Date = Date(),
        modified: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.notes = notes
        self.status = status
        self.project = project
        self.context = context
        self.due = due
        self.defer = defer
        self.flagged = flagged
        self.priority = priority
        self.effort = effort
        self.tags = tags
        self.attachments = attachments
        self.positions = positions
        self.parentId = parentId
        self.subtaskIds = subtaskIds
        self.recurrence = recurrence
        self.originalTaskId = originalTaskId
        self.occurrenceDate = occurrenceDate
        self.created = created
        self.modified = modified
    }
}

// MARK: - Computed Properties

extension Task {
    /// Returns the file path for this task based on its status and creation date
    /// Format: tasks/active/YYYY/MM/uuid-slug.md or tasks/archive/YYYY/MM/uuid-slug.md
    var filePath: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: created)
        let month = calendar.component(.month, from: created)

        let statusFolder = status == .completed ? "archive" : "active"
        let slug = title.slugified()
        let monthString = String(format: "%02d", month)

        return "tasks/\(statusFolder)/\(year)/\(monthString)/\(id.uuidString)-\(slug).md"
    }

    /// Returns the relative path from the project root
    var relativePath: String {
        return filePath
    }

    /// Returns just the filename component
    var fileName: String {
        let slug = title.slugified()
        return "\(id.uuidString)-\(slug).md"
    }

    /// Returns true if this task is overdue
    var isOverdue: Bool {
        guard let dueDate = due else { return false }
        return dueDate < Date() && status != .completed
    }

    /// Returns true if this task is due today
    var isDueToday: Bool {
        guard let dueDate = due else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    /// Returns true if this task is due within the next 7 days
    var isDueThisWeek: Bool {
        guard let dueDate = due else { return false }
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return dueDate <= weekFromNow && dueDate >= Date()
    }

    /// Returns true if this task is currently deferred (defer date is in the future)
    var isDeferred: Bool {
        guard let deferDate = defer else { return false }
        return deferDate > Date()
    }

    /// Returns true if this task should be visible (not completed and not deferred)
    var isVisible: Bool {
        return status != .completed && !isDeferred
    }

    /// Returns true if this task is actionable (next-action status and not deferred)
    var isActionable: Bool {
        return status == .nextAction && !isDeferred
    }

    /// Returns a human-readable description of the task's due status
    var dueDescription: String? {
        guard let dueDate = due else { return nil }

        if isOverdue {
            return "Overdue"
        } else if isDueToday {
            return "Due today"
        } else if isDueThisWeek {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            return "Due in \(days) days"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return "Due \(formatter.string(from: dueDate))"
        }
    }

    /// Returns the effort in a human-readable format
    var effortDescription: String? {
        guard let minutes = effort else { return nil }

        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }

    /// Returns true if this task has subtasks
    var hasSubtasks: Bool {
        return !subtaskIds.isEmpty
    }

    /// Returns true if this task is a subtask (has a parent)
    var isSubtask: Bool {
        return parentId != nil
    }

    /// Returns the indentation level for this task (0 = top-level, 1 = first-level subtask, etc.)
    /// Note: This is a simple implementation. For deeper hierarchies, use TaskStore.indentationLevel(for:)
    var indentationLevel: Int {
        return isSubtask ? 1 : 0
    }

    /// Returns true if this task is recurring
    var isRecurring: Bool {
        return recurrence != nil && originalTaskId == nil
    }

    /// Returns true if this is a recurring task instance (created from a template)
    var isRecurringInstance: Bool {
        return originalTaskId != nil
    }

    /// Returns the next occurrence date for a recurring task
    var nextOccurrence: Date? {
        guard let recurrence = recurrence,
              !recurrence.isComplete else { return nil }

        let baseDate = occurrenceDate ?? due ?? Date()
        return RecurrenceEngine.calculateNextOccurrence(from: baseDate, recurrence: recurrence)
    }
}

// MARK: - Helper Methods

extension Task {
    /// Returns the position for a given board
    /// - Parameter boardId: The board identifier
    /// - Returns: The position, or nil if not positioned on this board
    func position(for boardId: String) -> Position? {
        return positions[boardId]
    }

    /// Sets the position for a given board
    /// - Parameters:
    ///   - position: The new position
    ///   - boardId: The board identifier
    mutating func setPosition(_ position: Position, for boardId: String) {
        positions[boardId] = position
        modified = Date()
    }

    /// Removes the position for a given board
    /// - Parameter boardId: The board identifier
    mutating func removePosition(for boardId: String) {
        positions.removeValue(forKey: boardId)
        modified = Date()
    }

    /// Returns true if this task has a position on the given board
    /// - Parameter boardId: The board identifier
    /// - Returns: True if positioned on this board
    func isPositioned(on boardId: String) -> Bool {
        return positions[boardId] != nil
    }

    /// Promotes this task from a note to a full task
    mutating func promoteToTask() {
        guard type == .note else { return }
        type = .task
        if status == .inbox {
            // Keep inbox status when promoting
        }
        modified = Date()
    }

    /// Demotes this task from a task to a note
    mutating func demoteToNote() {
        guard type == .task else { return }
        type = .note
        modified = Date()
    }

    /// Marks this task as completed
    mutating func complete() {
        status = .completed
        modified = Date()
    }

    /// Reopens a completed task
    mutating func reopen() {
        guard status == .completed else { return }
        status = .nextAction
        modified = Date()
    }

    /// Creates a copy of this task with a new ID
    /// - Returns: A duplicate task
    func duplicate() -> Task {
        var copy = self
        copy.id = UUID()
        copy.created = Date()
        copy.modified = Date()
        copy.title = "\(title) (copy)"
        copy.positions = [:]
        return copy
    }

    /// Updates the modified timestamp
    mutating func touch() {
        modified = Date()
    }

    /// Adds a subtask to this task
    /// - Parameter taskId: The ID of the subtask to add
    mutating func addSubtask(_ taskId: UUID) {
        guard !subtaskIds.contains(taskId) else { return }
        subtaskIds.append(taskId)
        modified = Date()
    }

    /// Removes a subtask from this task
    /// - Parameter taskId: The ID of the subtask to remove
    mutating func removeSubtask(_ taskId: UUID) {
        subtaskIds.removeAll { $0 == taskId }
        modified = Date()
    }

    /// Removes all subtasks from this task
    mutating func clearSubtasks() {
        subtaskIds.removeAll()
        modified = Date()
    }

    /// Sets the parent task for this task
    /// - Parameter parentId: The ID of the parent task (or nil to clear)
    mutating func setParent(_ parentId: UUID?) {
        self.parentId = parentId
        modified = Date()
    }

    /// Adds a tag to this task
    /// - Parameter tag: The tag to add
    mutating func addTag(_ tag: Tag) {
        guard !tags.contains(tag) else { return }
        tags.append(tag)
        modified = Date()
    }

    /// Removes a tag from this task
    /// - Parameter tag: The tag to remove
    mutating func removeTag(_ tag: Tag) {
        tags.removeAll { $0.id == tag.id }
        modified = Date()
    }

    /// Removes all tags from this task
    mutating func clearTags() {
        tags.removeAll()
        modified = Date()
    }

    /// Returns true if this task has the given tag
    /// - Parameter tag: The tag to check
    /// - Returns: True if the task has this tag
    func hasTag(_ tag: Tag) -> Bool {
        return tags.contains { $0.id == tag.id }
    }

    /// Returns true if this task has any tags
    var hasTags: Bool {
        return !tags.isEmpty
    }

    /// Adds an attachment to this task
    /// - Parameter attachment: The attachment to add
    mutating func addAttachment(_ attachment: Attachment) {
        guard !attachments.contains(where: { $0.id == attachment.id }) else { return }
        attachments.append(attachment)
        modified = Date()
    }

    /// Removes an attachment from this task
    /// - Parameter attachment: The attachment to remove
    mutating func removeAttachment(_ attachment: Attachment) {
        attachments.removeAll { $0.id == attachment.id }
        modified = Date()
    }

    /// Removes all attachments from this task
    mutating func clearAttachments() {
        attachments.removeAll()
        modified = Date()
    }

    /// Returns true if this task has attachments
    var hasAttachments: Bool {
        return !attachments.isEmpty
    }
}

// MARK: - Filtering and Matching

extension Task {
    /// Returns true if this task matches the given filter
    /// - Parameter filter: The filter to test against
    /// - Returns: True if this task matches all filter criteria
    func matches(_ filter: Filter) -> Bool {
        if let filterType = filter.type, type != filterType {
            return false
        }

        if let filterStatus = filter.status, status != filterStatus {
            return false
        }

        if let filterProject = filter.project, project != filterProject {
            return false
        }

        if let filterContext = filter.context, context != filterContext {
            return false
        }

        if let filterFlagged = filter.flagged, flagged != filterFlagged {
            return false
        }

        if let filterPriority = filter.priority, priority != filterPriority {
            return false
        }

        if let filterDueBefore = filter.dueBefore {
            guard let taskDue = due, taskDue <= filterDueBefore else {
                return false
            }
        }

        if let filterDueAfter = filter.dueAfter {
            guard let taskDue = due, taskDue >= filterDueAfter else {
                return false
            }
        }

        if let filterDeferAfter = filter.deferAfter {
            guard let taskDefer = defer, taskDefer >= filterDeferAfter else {
                return false
            }
        }

        if let filterEffortMax = filter.effortMax {
            guard let taskEffort = effort, taskEffort <= filterEffortMax else {
                return false
            }
        }

        if let filterEffortMin = filter.effortMin {
            guard let taskEffort = effort, taskEffort >= filterEffortMin else {
                return false
            }
        }

        return true
    }

    /// Returns true if this task matches the search query
    /// - Parameter query: The search string
    /// - Returns: True if the query matches title, notes, project, context, tags, or attachments
    func matchesSearch(_ query: String) -> Bool {
        let lowercaseQuery = query.lowercased()

        if title.lowercased().contains(lowercaseQuery) {
            return true
        }

        if notes.lowercased().contains(lowercaseQuery) {
            return true
        }

        if let proj = project, proj.lowercased().contains(lowercaseQuery) {
            return true
        }

        if let ctx = context, ctx.lowercased().contains(lowercaseQuery) {
            return true
        }

        // Search in tags
        if tags.contains(where: { $0.name.lowercased().contains(lowercaseQuery) }) {
            return true
        }

        // Search in attachments
        if attachments.contains(where: { attachment in
            attachment.name.lowercased().contains(lowercaseQuery) ||
            attachment.description?.lowercased().contains(lowercaseQuery) == true
        }) {
            return true
        }

        return false
    }
}

// MARK: - String Extensions

fileprivate extension String {
    /// Converts a string to a URL-safe slug
    func slugified() -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let slug = self
            .lowercased()
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        // Truncate to reasonable length
        let maxLength = 50
        if slug.count > maxLength {
            return String(slug.prefix(maxLength))
        }

        return slug.isEmpty ? "untitled" : slug
    }
}
