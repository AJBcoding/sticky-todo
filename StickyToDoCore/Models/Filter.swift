//
//  Filter.swift
//  StickyToDo
//
//  Filtering criteria for boards and perspectives.
//

import Foundation

/// Defines filtering criteria for which tasks appear on a board or in a perspective
///
/// All filter properties are optional. A nil value means no filtering on that criterion.
/// Multiple criteria are combined with AND logic (all must match).
public struct Filter: Codable, Equatable {
    /// Filter by task type (note or task)
    var type: TaskType?

    /// Filter by task status
    var status: Status?

    /// Filter by project name
    var project: String?

    /// Filter by context
    var context: String?

    /// Filter by flagged state
    var flagged: Bool?

    /// Filter by priority level
    var priority: Priority?

    /// Filter by due date (matches if task is due on or before this date)
    var dueBefore: Date?

    /// Filter by due date (matches if task is due on or after this date)
    var dueAfter: Date?

    /// Filter by defer date (matches if task is deferred to on or after this date)
    var deferAfter: Date?

    /// Filter by effort (matches if effort is less than or equal to this value)
    var effortMax: Int?

    /// Filter by effort (matches if effort is greater than or equal to this value)
    var effortMin: Int?

    /// Custom filter expression for advanced queries
    /// Format: "project:Website AND context:@computer AND priority:high"
    var expression: String?

    /// Creates an empty filter (matches all tasks)
    public init() {}

    /// Creates a filter with the specified criteria
    public init(
        type: TaskType? = nil,
        status: Status? = nil,
        project: String? = nil,
        context: String? = nil,
        flagged: Bool? = nil,
        priority: Priority? = nil,
        dueBefore: Date? = nil,
        dueAfter: Date? = nil,
        deferAfter: Date? = nil,
        effortMax: Int? = nil,
        effortMin: Int? = nil,
        expression: String? = nil
    ) {
        self.type = type
        self.status = status
        self.project = project
        self.context = context
        self.flagged = flagged
        self.priority = priority
        self.dueBefore = dueBefore
        self.dueAfter = dueAfter
        self.deferAfter = deferAfter
        self.effortMax = effortMax
        self.effortMin = effortMin
        self.expression = expression
    }
}

extension Filter {
    /// Returns true if this filter matches all tasks (no criteria set)
    var matchesAll: Bool {
        return type == nil &&
               status == nil &&
               project == nil &&
               context == nil &&
               flagged == nil &&
               priority == nil &&
               dueBefore == nil &&
               dueAfter == nil &&
               deferAfter == nil &&
               effortMax == nil &&
               effortMin == nil &&
               expression == nil
    }

    /// Returns the number of active filter criteria
    var criteriaCount: Int {
        var count = 0
        if type != nil { count += 1 }
        if status != nil { count += 1 }
        if project != nil { count += 1 }
        if context != nil { count += 1 }
        if flagged != nil { count += 1 }
        if priority != nil { count += 1 }
        if dueBefore != nil { count += 1 }
        if dueAfter != nil { count += 1 }
        if deferAfter != nil { count += 1 }
        if effortMax != nil { count += 1 }
        if effortMin != nil { count += 1 }
        if expression != nil { count += 1 }
        return count
    }
}

// MARK: - Predefined Filters

extension Filter {
    /// Filter for inbox tasks
    static var inbox: Filter {
        Filter(status: .inbox)
    }

    /// Filter for next action tasks
    static var nextActions: Filter {
        Filter(status: .nextAction, type: .task)
    }

    /// Filter for flagged tasks
    static var flagged: Filter {
        Filter(flagged: true)
    }

    /// Filter for waiting tasks
    static var waiting: Filter {
        Filter(status: .waiting)
    }

    /// Filter for someday/maybe tasks
    static var someday: Filter {
        Filter(status: .someday)
    }

    /// Filter for completed tasks
    static var completed: Filter {
        Filter(status: .completed)
    }

    /// Filter for tasks due today
    static var dueToday: Filter {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return Filter(dueAfter: today, dueBefore: tomorrow)
    }

    /// Filter for tasks due within the next 7 days
    static var dueThisWeek: Filter {
        let today = Date()
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        return Filter(dueBefore: weekFromNow)
    }

    /// Filter for overdue tasks (due before today and not completed)
    static func overdue(referenceDate: Date = Date()) -> Filter {
        return Filter(status: .nextAction, dueBefore: referenceDate)
    }

    /// Filter for high priority next actions
    static var highPriorityActions: Filter {
        Filter(status: .nextAction, priority: .high)
    }

    /// Filter for quick wins (short tasks with high priority)
    static var quickWins: Filter {
        Filter(status: .nextAction, priority: .high, effortMax: 30)
    }
}
