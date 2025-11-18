//
//  Perspective.swift
//  StickyToDo
//
//  List view perspective for filtering, grouping, and sorting tasks.
//

import Foundation

/// Grouping option for list views
public enum GroupBy: String, Codable, CaseIterable {
    case none
    case context
    case project
    case status
    case priority
    case dueDate
}

/// Sorting option for list views
public enum SortBy: String, Codable, CaseIterable {
    case title
    case created
    case modified
    case due
    case defer
    case priority
    case status
    case effort
}

/// Sort direction
public enum SortDirection: String, Codable {
    case ascending
    case descending
}

/// Represents a saved list view perspective with filter, grouping, and sorting
///
/// Perspectives define how tasks are displayed in list view, similar to saved searches
/// or smart folders in other applications.
public struct Perspective: Identifiable, Codable, Equatable {
    // MARK: - Core Properties

    /// Unique identifier for the perspective
    let id: String

    /// Display name for the perspective
    var name: String

    /// Filter criteria for which tasks to show
    var filter: Filter

    /// How to group tasks in the list
    var groupBy: GroupBy

    /// How to sort tasks within each group
    var sortBy: SortBy

    /// Sort direction
    var sortDirection: SortDirection

    /// Whether to show completed tasks
    var showCompleted: Bool

    /// Whether to show deferred tasks (defer date in future)
    var showDeferred: Bool

    /// Custom icon for the perspective
    var icon: String?

    /// Color for the perspective in the UI
    var color: String?

    /// Whether this is a built-in system perspective
    var isBuiltIn: Bool

    /// Whether this perspective is visible in the sidebar
    var isVisible: Bool

    /// Sort order for the perspective in the sidebar
    var order: Int?

    // MARK: - Initialization

    /// Creates a new perspective
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - name: Display name
    ///   - filter: Filter criteria
    ///   - groupBy: Grouping option
    ///   - sortBy: Sorting option
    ///   - sortDirection: Sort direction
    ///   - showCompleted: Whether to show completed tasks
    ///   - showDeferred: Whether to show deferred tasks
    ///   - icon: Custom icon
    ///   - color: Perspective color
    ///   - isBuiltIn: Whether this is a system perspective
    ///   - isVisible: Whether visible in sidebar
    ///   - order: Sort order
    public init(
        id: String,
        name: String,
        filter: Filter = Filter(),
        groupBy: GroupBy = .none,
        sortBy: SortBy = .created,
        sortDirection: SortDirection = .ascending,
        showCompleted: Bool = false,
        showDeferred: Bool = false,
        icon: String? = nil,
        color: String? = nil,
        isBuiltIn: Bool = false,
        isVisible: Bool = true,
        order: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.filter = filter
        self.groupBy = groupBy
        self.sortBy = sortBy
        self.sortDirection = sortDirection
        self.showCompleted = showCompleted
        self.showDeferred = showDeferred
        self.icon = icon
        self.color = color
        self.isBuiltIn = isBuiltIn
        self.isVisible = isVisible
        self.order = order
    }
}

// MARK: - Computed Properties

extension Perspective {
    /// Returns the display title for this perspective
    var displayTitle: String {
        return name
    }
}

// MARK: - Task Filtering and Sorting

extension Perspective {
    /// Filters and sorts tasks according to this perspective's configuration
    /// - Parameter tasks: Tasks to filter and sort
    /// - Returns: Filtered and sorted tasks
    func apply(to tasks: [Task]) -> [Task] {
        var filtered = tasks

        // Apply filter
        filtered = filtered.filter { task in
            // Check base filter
            guard task.matches(filter) else { return false }

            // Check completed visibility
            if !showCompleted && task.status == .completed {
                return false
            }

            // Check deferred visibility
            if !showDeferred && task.isDeferred {
                return false
            }

            return true
        }

        // Apply sorting
        filtered.sort { lhs, rhs in
            let ascending = sortDirection == .ascending

            switch sortBy {
            case .title:
                return ascending ? lhs.title < rhs.title : lhs.title > rhs.title

            case .created:
                return ascending ? lhs.created < rhs.created : lhs.created > rhs.created

            case .modified:
                return ascending ? lhs.modified < rhs.modified : lhs.modified > rhs.modified

            case .due:
                // nil dates go to end
                switch (lhs.due, rhs.due) {
                case (.none, .none):
                    return false
                case (.some, .none):
                    return ascending
                case (.none, .some):
                    return !ascending
                case (.some(let lDate), .some(let rDate)):
                    return ascending ? lDate < rDate : lDate > rDate
                }

            case .defer:
                // nil dates go to end
                switch (lhs.defer, rhs.defer) {
                case (.none, .none):
                    return false
                case (.some, .none):
                    return ascending
                case (.none, .some):
                    return !ascending
                case (.some(let lDate), .some(let rDate)):
                    return ascending ? lDate < rDate : lDate > rDate
                }

            case .priority:
                return ascending ?
                    lhs.priority.sortOrder < rhs.priority.sortOrder :
                    lhs.priority.sortOrder > rhs.priority.sortOrder

            case .status:
                return ascending ?
                    lhs.status.rawValue < rhs.status.rawValue :
                    lhs.status.rawValue > rhs.status.rawValue

            case .effort:
                // nil efforts go to end
                switch (lhs.effort, rhs.effort) {
                case (.none, .none):
                    return false
                case (.some, .none):
                    return ascending
                case (.none, .some):
                    return !ascending
                case (.some(let lEffort), .some(let rEffort)):
                    return ascending ? lEffort < rEffort : lEffort > rEffort
                }
            }
        }

        return filtered
    }

    /// Groups tasks according to this perspective's grouping configuration
    /// - Parameter tasks: Tasks to group (should already be filtered and sorted)
    /// - Returns: Dictionary of group names to tasks in that group
    func group(_ tasks: [Task]) -> [(String, [Task])] {
        guard groupBy != .none else {
            return [("All", tasks)]
        }

        var groups: [String: [Task]] = [:]

        for task in tasks {
            let groupKey: String

            switch groupBy {
            case .none:
                groupKey = "All"

            case .context:
                groupKey = task.context ?? "No Context"

            case .project:
                groupKey = task.project ?? "No Project"

            case .status:
                groupKey = task.status.displayName

            case .priority:
                groupKey = task.priority.displayName

            case .dueDate:
                if let due = task.due {
                    if Calendar.current.isDateInToday(due) {
                        groupKey = "Today"
                    } else if Calendar.current.isDateInTomorrow(due) {
                        groupKey = "Tomorrow"
                    } else if task.isDueThisWeek {
                        groupKey = "This Week"
                    } else if task.isOverdue {
                        groupKey = "Overdue"
                    } else {
                        groupKey = "Later"
                    }
                } else {
                    groupKey = "No Due Date"
                }
            }

            groups[groupKey, default: []].append(task)
        }

        // Sort groups by key
        return groups.sorted { $0.key < $1.key }
    }
}

// MARK: - Built-in Perspectives

extension Perspective {
    /// Inbox perspective - process new items
    static var inbox: Perspective {
        Perspective(
            id: "inbox",
            name: "Inbox",
            filter: .inbox,
            groupBy: .none,
            sortBy: .created,
            sortDirection: .descending,
            icon: "📥",
            color: "blue",
            isBuiltIn: true,
            order: 0
        )
    }

    /// Next Actions perspective - actionable tasks grouped by context
    static var nextActions: Perspective {
        Perspective(
            id: "next-actions",
            name: "Next Actions",
            filter: .nextActions,
            groupBy: .context,
            sortBy: .priority,
            sortDirection: .descending,
            icon: "▶️",
            color: "green",
            isBuiltIn: true,
            order: 1
        )
    }

    /// Flagged perspective - important items sorted by due date
    static var flagged: Perspective {
        Perspective(
            id: "flagged",
            name: "Flagged",
            filter: .flagged,
            groupBy: .none,
            sortBy: .due,
            sortDirection: .ascending,
            icon: "⭐",
            color: "yellow",
            isBuiltIn: true,
            order: 2
        )
    }

    /// Due Soon perspective - items due within 7 days
    static var dueSoon: Perspective {
        Perspective(
            id: "due-soon",
            name: "Due Soon",
            filter: .dueThisWeek,
            groupBy: .dueDate,
            sortBy: .due,
            sortDirection: .ascending,
            icon: "📅",
            color: "orange",
            isBuiltIn: true,
            order: 3
        )
    }

    /// Waiting For perspective - blocked items grouped by project
    static var waitingFor: Perspective {
        Perspective(
            id: "waiting-for",
            name: "Waiting For",
            filter: .waiting,
            groupBy: .project,
            sortBy: .created,
            sortDirection: .descending,
            icon: "⏳",
            color: "orange",
            isBuiltIn: true,
            order: 4
        )
    }

    /// Someday/Maybe perspective - future ideas grouped by project
    static var someday: Perspective {
        Perspective(
            id: "someday-maybe",
            name: "Someday/Maybe",
            filter: .someday,
            groupBy: .project,
            sortBy: .created,
            sortDirection: .descending,
            icon: "💭",
            color: "purple",
            isBuiltIn: true,
            order: 5
        )
    }

    /// All Active perspective - complete overview grouped by project
    static var allActive: Perspective {
        Perspective(
            id: "all-active",
            name: "All Active",
            filter: Filter(type: .task),
            groupBy: .project,
            sortBy: .priority,
            sortDirection: .descending,
            showCompleted: false,
            icon: "📋",
            color: "blue",
            isBuiltIn: true,
            order: 6
        )
    }

    /// Returns all built-in perspectives
    static var builtInPerspectives: [Perspective] {
        return [
            .inbox,
            .nextActions,
            .flagged,
            .dueSoon,
            .waitingFor,
            .someday,
            .allActive
        ]
    }
}

// MARK: - GroupBy Extension

extension GroupBy {
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .context:
            return "Context"
        case .project:
            return "Project"
        case .status:
            return "Status"
        case .priority:
            return "Priority"
        case .dueDate:
            return "Due Date"
        }
    }
}

// MARK: - SortBy Extension

extension SortBy {
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .title:
            return "Title"
        case .created:
            return "Created"
        case .modified:
            return "Modified"
        case .due:
            return "Due Date"
        case .defer:
            return "Defer Date"
        case .priority:
            return "Priority"
        case .status:
            return "Status"
        case .effort:
            return "Effort"
        }
    }
}
