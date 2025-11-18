//
//  SmartPerspective.swift
//  StickyToDo
//
//  Smart perspectives with dynamic filtering and advanced logic.
//

import Foundation

/// Logic operator for combining filter rules
enum FilterLogic: String, Codable, CaseIterable {
    case and
    case or
}

/// Filter rule for advanced search
struct FilterRule: Codable, Equatable, Identifiable {
    // MARK: - Core Properties

    /// Unique identifier for the rule
    let id: UUID

    /// Property to filter on
    var property: FilterProperty

    /// Operator to apply
    var operatorType: FilterOperator

    /// Value to compare against (type depends on property)
    var value: FilterValue

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        property: FilterProperty,
        operatorType: FilterOperator,
        value: FilterValue
    ) {
        self.id = id
        self.property = property
        self.operatorType = operatorType
        self.value = value
    }
}

/// Property that can be filtered
enum FilterProperty: String, Codable, CaseIterable {
    case title
    case notes
    case status
    case priority
    case context
    case project
    case dueDate
    case deferDate
    case createdDate
    case modifiedDate
    case effort
    case flagged
    case hasSubtasks
    case isSubtask
    case hasAttachments
    case tags
}

/// Filter operator
enum FilterOperator: String, Codable {
    // String operators
    case contains
    case notContains
    case equals
    case notEquals
    case startsWith
    case endsWith

    // Numeric/Date operators
    case lessThan
    case lessThanOrEqual
    case greaterThan
    case greaterThanOrEqual

    // Boolean operators
    case isTrue
    case isFalse

    // Special operators
    case isEmpty
    case isNotEmpty
    case isWithin  // For date ranges
}

/// Filter value (can be string, number, date, or boolean)
enum FilterValue: Codable, Equatable {
    case string(String)
    case number(Int)
    case date(Date)
    case boolean(Bool)
    case dateRange(DateRange)
    case stringArray([String])  // For tags
}

/// Date range for filtering
enum DateRange: String, Codable, CaseIterable {
    case today
    case tomorrow
    case thisWeek
    case nextWeek
    case thisMonth
    case nextMonth
    case past
    case future
    case last7Days
    case last30Days
    case next7Days
    case next30Days
}

/// Smart perspective with advanced filtering capabilities
struct SmartPerspective: Identifiable, Codable, Equatable {
    // MARK: - Core Properties

    /// Unique identifier
    let id: UUID

    /// Display name
    var name: String

    /// Description of what this perspective shows
    var description: String?

    /// Filter rules to apply
    var rules: [FilterRule]

    /// Logic for combining rules (AND or OR)
    var logic: FilterLogic

    /// Grouping option
    var groupBy: GroupBy

    /// Sorting option
    var sortBy: SortBy

    /// Sort direction
    var sortDirection: SortDirection

    /// Whether to show completed tasks
    var showCompleted: Bool

    /// Whether to show deferred tasks
    var showDeferred: Bool

    /// Icon for the perspective
    var icon: String?

    /// Color for the perspective
    var color: String?

    /// Whether this is a built-in perspective
    var isBuiltIn: Bool

    /// When this perspective was created
    var created: Date

    /// When this perspective was last modified
    var modified: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        rules: [FilterRule] = [],
        logic: FilterLogic = .and,
        groupBy: GroupBy = .none,
        sortBy: SortBy = .created,
        sortDirection: SortDirection = .ascending,
        showCompleted: Bool = false,
        showDeferred: Bool = false,
        icon: String? = nil,
        color: String? = nil,
        isBuiltIn: Bool = false,
        created: Date = Date(),
        modified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.rules = rules
        self.logic = logic
        self.groupBy = groupBy
        self.sortBy = sortBy
        self.sortDirection = sortDirection
        self.showCompleted = showCompleted
        self.showDeferred = showDeferred
        self.icon = icon
        self.color = color
        self.isBuiltIn = isBuiltIn
        self.created = created
        self.modified = modified
    }
}

// MARK: - Task Filtering

extension SmartPerspective {
    /// Applies this perspective's filter rules to a task
    /// - Parameter task: Task to test
    /// - Returns: True if the task matches this perspective's criteria
    func matches(_ task: Task) -> Bool {
        // Check visibility settings
        if !showCompleted && task.status == .completed {
            return false
        }

        if !showDeferred && task.isDeferred {
            return false
        }

        // If no rules, match all visible tasks
        if rules.isEmpty {
            return true
        }

        // Apply rules with the specified logic
        if logic == .and {
            return rules.allSatisfy { $0.matches(task) }
        } else {
            return rules.contains { $0.matches(task) }
        }
    }

    /// Filters and sorts tasks according to this perspective
    /// - Parameter tasks: Tasks to filter
    /// - Returns: Filtered and sorted tasks
    func apply(to tasks: [Task]) -> [Task] {
        let filtered = tasks.filter { matches($0) }

        return filtered.sorted { lhs, rhs in
            let ascending = sortDirection == .ascending

            switch sortBy {
            case .title:
                return ascending ? lhs.title < rhs.title : lhs.title > rhs.title
            case .created:
                return ascending ? lhs.created < rhs.created : lhs.created > rhs.created
            case .modified:
                return ascending ? lhs.modified < rhs.modified : lhs.modified > rhs.modified
            case .due:
                switch (lhs.due, rhs.due) {
                case (.none, .none): return false
                case (.some, .none): return ascending
                case (.none, .some): return !ascending
                case (.some(let lDate), .some(let rDate)):
                    return ascending ? lDate < rDate : lDate > rDate
                }
            case .defer:
                switch (lhs.defer, rhs.defer) {
                case (.none, .none): return false
                case (.some, .none): return ascending
                case (.none, .some): return !ascending
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
                switch (lhs.effort, rhs.effort) {
                case (.none, .none): return false
                case (.some, .none): return ascending
                case (.none, .some): return !ascending
                case (.some(let lEffort), .some(let rEffort)):
                    return ascending ? lEffort < rEffort : lEffort > rEffort
                }
            }
        }
    }
}

// MARK: - FilterRule Matching

extension FilterRule {
    /// Tests if a task matches this filter rule
    /// - Parameter task: Task to test
    /// - Returns: True if the task matches this rule
    func matches(_ task: Task) -> Bool {
        // This would need to be implemented based on the property, operator, and value
        // For now, providing a basic structure
        switch property {
        case .title:
            return matchesString(task.title)
        case .notes:
            return matchesString(task.notes)
        case .status:
            guard case .string(let statusStr) = value else { return false }
            return operatorType == .equals ? task.status.rawValue == statusStr : task.status.rawValue != statusStr
        case .priority:
            guard case .string(let priorityStr) = value else { return false }
            return operatorType == .equals ? task.priority.rawValue == priorityStr : task.priority.rawValue != priorityStr
        case .context:
            return matchesOptionalString(task.context)
        case .project:
            return matchesOptionalString(task.project)
        case .dueDate:
            return matchesDate(task.due)
        case .deferDate:
            return matchesDate(task.defer)
        case .createdDate:
            return matchesDate(task.created)
        case .modifiedDate:
            return matchesDate(task.modified)
        case .effort:
            return matchesNumber(task.effort)
        case .flagged:
            return matchesBoolean(task.flagged)
        case .hasSubtasks:
            return matchesBoolean(false)  // Would need subtask support
        case .isSubtask:
            return matchesBoolean(false)  // Would need subtask support
        case .hasAttachments:
            return matchesBoolean(false)  // Would need to check task.attachments
        case .tags:
            return matchesTags([])  // Would need to check task.tags
        }
    }

    private func matchesString(_ string: String) -> Bool {
        guard case .string(let filterString) = value else { return false }

        let lowercaseString = string.lowercased()
        let lowercaseFilter = filterString.lowercased()

        switch operatorType {
        case .contains:
            return lowercaseString.contains(lowercaseFilter)
        case .notContains:
            return !lowercaseString.contains(lowercaseFilter)
        case .equals:
            return lowercaseString == lowercaseFilter
        case .notEquals:
            return lowercaseString != lowercaseFilter
        case .startsWith:
            return lowercaseString.hasPrefix(lowercaseFilter)
        case .endsWith:
            return lowercaseString.hasSuffix(lowercaseFilter)
        case .isEmpty:
            return string.isEmpty
        case .isNotEmpty:
            return !string.isEmpty
        default:
            return false
        }
    }

    private func matchesOptionalString(_ string: String?) -> Bool {
        guard let string = string else {
            return operatorType == .isEmpty || operatorType == .isFalse
        }
        return matchesString(string)
    }

    private func matchesDate(_ date: Date?) -> Bool {
        switch operatorType {
        case .isEmpty:
            return date == nil
        case .isNotEmpty:
            return date != nil
        case .isWithin:
            guard let taskDate = date,
                  case .dateRange(let range) = value else { return false }
            return taskDate.isWithin(range)
        case .lessThan, .lessThanOrEqual, .greaterThan, .greaterThanOrEqual:
            guard let taskDate = date,
                  case .date(let filterDate) = value else { return false }

            switch operatorType {
            case .lessThan:
                return taskDate < filterDate
            case .lessThanOrEqual:
                return taskDate <= filterDate
            case .greaterThan:
                return taskDate > filterDate
            case .greaterThanOrEqual:
                return taskDate >= filterDate
            default:
                return false
            }
        default:
            return false
        }
    }

    private func matchesNumber(_ number: Int?) -> Bool {
        switch operatorType {
        case .isEmpty:
            return number == nil
        case .isNotEmpty:
            return number != nil
        case .lessThan, .lessThanOrEqual, .greaterThan, .greaterThanOrEqual, .equals, .notEquals:
            guard let taskNumber = number,
                  case .number(let filterNumber) = value else { return false }

            switch operatorType {
            case .lessThan:
                return taskNumber < filterNumber
            case .lessThanOrEqual:
                return taskNumber <= filterNumber
            case .greaterThan:
                return taskNumber > filterNumber
            case .greaterThanOrEqual:
                return taskNumber >= filterNumber
            case .equals:
                return taskNumber == filterNumber
            case .notEquals:
                return taskNumber != filterNumber
            default:
                return false
            }
        default:
            return false
        }
    }

    private func matchesBoolean(_ bool: Bool) -> Bool {
        guard case .boolean(let filterBool) = value else {
            return operatorType == .isTrue && bool || operatorType == .isFalse && !bool
        }
        return bool == filterBool
    }

    private func matchesTags(_ tags: [Tag]) -> Bool {
        guard case .stringArray(let filterTags) = value else { return false }

        let taskTagNames = tags.map { $0.name.lowercased() }
        let filterTagNames = filterTags.map { $0.lowercased() }

        switch operatorType {
        case .contains:
            return filterTagNames.allSatisfy { taskTagNames.contains($0) }
        case .notContains:
            return !filterTagNames.contains(where: { taskTagNames.contains($0) })
        case .isEmpty:
            return tags.isEmpty
        case .isNotEmpty:
            return !tags.isEmpty
        default:
            return false
        }
    }
}

// MARK: - Date Extensions

extension Date {
    /// Checks if this date is within the specified range
    func isWithin(_ range: DateRange) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch range {
        case .today:
            return calendar.isDateInToday(self)
        case .tomorrow:
            return calendar.isDateInTomorrow(self)
        case .thisWeek:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { return false }
            return self >= weekStart && self < weekEnd
        case .nextWeek:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
                  let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: weekStart),
                  let nextWeekEnd = calendar.date(byAdding: .day, value: 7, to: nextWeekStart) else { return false }
            return self >= nextWeekStart && self < nextWeekEnd
        case .thisMonth:
            return calendar.isDate(self, equalTo: now, toGranularity: .month)
        case .nextMonth:
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) else { return false }
            return calendar.isDate(self, equalTo: nextMonth, toGranularity: .month)
        case .past:
            return self < now
        case .future:
            return self > now
        case .last7Days:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
            return self >= weekAgo && self <= now
        case .last30Days:
            guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return false }
            return self >= monthAgo && self <= now
        case .next7Days:
            guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) else { return false }
            return self >= now && self <= weekFromNow
        case .next30Days:
            guard let monthFromNow = calendar.date(byAdding: .day, value: 30, to: now) else { return false }
            return self >= now && self <= monthFromNow
        }
    }
}

// MARK: - Predefined Smart Perspectives

extension SmartPerspective {
    /// Today's Focus - Due today OR flagged AND next-action
    static var todaysFocus: SmartPerspective {
        SmartPerspective(
            name: "Today's Focus",
            description: "Tasks due today or flagged next actions",
            rules: [
                FilterRule(
                    property: .dueDate,
                    operatorType: .isWithin,
                    value: .dateRange(.today)
                ),
                FilterRule(
                    property: .flagged,
                    operatorType: .isTrue,
                    value: .boolean(true)
                ),
                FilterRule(
                    property: .status,
                    operatorType: .equals,
                    value: .string("nextAction")
                )
            ],
            logic: .or,
            groupBy: .priority,
            sortBy: .priority,
            sortDirection: .descending,
            icon: "sun.max.fill",
            color: "#FF9500",
            isBuiltIn: true
        )
    }

    /// Quick Wins - Effort < 30min AND priority:high
    static var quickWins: SmartPerspective {
        SmartPerspective(
            name: "Quick Wins",
            description: "High priority tasks that take less than 30 minutes",
            rules: [
                FilterRule(
                    property: .effort,
                    operatorType: .lessThanOrEqual,
                    value: .number(30)
                ),
                FilterRule(
                    property: .priority,
                    operatorType: .equals,
                    value: .string("high")
                ),
                FilterRule(
                    property: .status,
                    operatorType: .equals,
                    value: .string("nextAction")
                )
            ],
            logic: .and,
            groupBy: .context,
            sortBy: .effort,
            sortDirection: .ascending,
            icon: "bolt.fill",
            color: "#FFCC00",
            isBuiltIn: true
        )
    }

    /// Waiting This Week - Waiting AND defer < 7 days
    static var waitingThisWeek: SmartPerspective {
        SmartPerspective(
            name: "Waiting This Week",
            description: "Waiting tasks becoming available within 7 days",
            rules: [
                FilterRule(
                    property: .status,
                    operatorType: .equals,
                    value: .string("waiting")
                ),
                FilterRule(
                    property: .deferDate,
                    operatorType: .isWithin,
                    value: .dateRange(.next7Days)
                )
            ],
            logic: .and,
            groupBy: .project,
            sortBy: .defer,
            sortDirection: .ascending,
            showDeferred: true,
            icon: "clock.fill",
            color: "#FF9500",
            isBuiltIn: true
        )
    }

    /// Stale Tasks - Modified > 30 days ago AND active
    static var staleTasks: SmartPerspective {
        SmartPerspective(
            name: "Stale Tasks",
            description: "Active tasks not touched in over 30 days",
            rules: [
                FilterRule(
                    property: .modifiedDate,
                    operatorType: .isWithin,
                    value: .dateRange(.last30Days)
                ),
                FilterRule(
                    property: .status,
                    operatorType: .notEquals,
                    value: .string("completed")
                )
            ],
            logic: .and,
            groupBy: .project,
            sortBy: .modified,
            sortDirection: .ascending,
            icon: "exclamationmark.triangle.fill",
            color: "#FF3B30",
            isBuiltIn: true
        )
    }

    /// No Context - Next-action AND context is nil
    static var noContext: SmartPerspective {
        SmartPerspective(
            name: "No Context",
            description: "Next actions missing a context",
            rules: [
                FilterRule(
                    property: .status,
                    operatorType: .equals,
                    value: .string("nextAction")
                ),
                FilterRule(
                    property: .context,
                    operatorType: .isEmpty,
                    value: .boolean(false)
                )
            ],
            logic: .and,
            groupBy: .project,
            sortBy: .priority,
            sortDirection: .descending,
            icon: "questionmark.circle.fill",
            color: "#5856D6",
            isBuiltIn: true
        )
    }

    /// Returns all built-in smart perspectives
    static var builtInSmartPerspectives: [SmartPerspective] {
        return [
            .todaysFocus,
            .quickWins,
            .waitingThisWeek,
            .staleTasks,
            .noContext
        ]
    }
}

// MARK: - Display Extensions

extension FilterProperty {
    var displayName: String {
        switch self {
        case .title: return "Title"
        case .notes: return "Notes"
        case .status: return "Status"
        case .priority: return "Priority"
        case .context: return "Context"
        case .project: return "Project"
        case .dueDate: return "Due Date"
        case .deferDate: return "Defer Date"
        case .createdDate: return "Created Date"
        case .modifiedDate: return "Modified Date"
        case .effort: return "Effort"
        case .flagged: return "Flagged"
        case .hasSubtasks: return "Has Subtasks"
        case .isSubtask: return "Is Subtask"
        case .hasAttachments: return "Has Attachments"
        case .tags: return "Tags"
        }
    }
}

extension FilterOperator {
    var displayName: String {
        switch self {
        case .contains: return "contains"
        case .notContains: return "does not contain"
        case .equals: return "is"
        case .notEquals: return "is not"
        case .startsWith: return "starts with"
        case .endsWith: return "ends with"
        case .lessThan: return "is before"
        case .lessThanOrEqual: return "is on or before"
        case .greaterThan: return "is after"
        case .greaterThanOrEqual: return "is on or after"
        case .isTrue: return "is true"
        case .isFalse: return "is false"
        case .isEmpty: return "is empty"
        case .isNotEmpty: return "is not empty"
        case .isWithin: return "is within"
        }
    }
}

extension DateRange {
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .thisWeek: return "This Week"
        case .nextWeek: return "Next Week"
        case .thisMonth: return "This Month"
        case .nextMonth: return "Next Month"
        case .past: return "Past"
        case .future: return "Future"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .next7Days: return "Next 7 Days"
        case .next30Days: return "Next 30 Days"
        }
    }
}
