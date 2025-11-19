//
//  Rule.swift
//  StickyToDoCore
//
//  Automation rule model with triggers and actions.
//

import Foundation

// MARK: - Trigger Types

/// The type of event that triggers a rule
public enum TriggerType: String, Codable, CaseIterable {
    case taskCreated = "task_created"
    case statusChanged = "status_changed"
    case dueDateApproaching = "due_date_approaching"
    case taskFlagged = "task_flagged"
    case taskUnflagged = "task_unflagged"
    case movedToBoard = "moved_to_board"
    case tagAdded = "tag_added"
    case projectSet = "project_set"
    case contextSet = "context_set"
    case priorityChanged = "priority_changed"
    case taskCompleted = "task_completed"
}

extension TriggerType {
    var displayName: String {
        switch self {
        case .taskCreated: return "Task Created"
        case .statusChanged: return "Status Changed"
        case .dueDateApproaching: return "Due Date Approaching"
        case .taskFlagged: return "Task Flagged"
        case .taskUnflagged: return "Task Unflagged"
        case .movedToBoard: return "Moved to Board"
        case .tagAdded: return "Tag Added"
        case .projectSet: return "Project Set"
        case .contextSet: return "Context Set"
        case .priorityChanged: return "Priority Changed"
        case .taskCompleted: return "Task Completed"
        }
    }

    var description: String {
        switch self {
        case .taskCreated: return "Triggers when a new task is created"
        case .statusChanged: return "Triggers when a task's status changes"
        case .dueDateApproaching: return "Triggers when a task's due date is approaching"
        case .taskFlagged: return "Triggers when a task is flagged"
        case .taskUnflagged: return "Triggers when a task is unflagged"
        case .movedToBoard: return "Triggers when a task is moved to a board"
        case .tagAdded: return "Triggers when a tag is added to a task"
        case .projectSet: return "Triggers when a project is assigned to a task"
        case .contextSet: return "Triggers when a context is assigned to a task"
        case .priorityChanged: return "Triggers when a task's priority changes"
        case .taskCompleted: return "Triggers when a task is completed"
        }
    }
}

// MARK: - Action Types

/// The type of action to perform when a rule is triggered
public enum ActionType: String, Codable, CaseIterable {
    case setStatus = "set_status"
    case setPriority = "set_priority"
    case setContext = "set_context"
    case setProject = "set_project"
    case addTag = "add_tag"
    case setDueDate = "set_due_date"
    case setDeferDate = "set_defer_date"
    case flag = "flag"
    case unflag = "unflag"
    case moveToBoard = "move_to_board"
    case sendNotification = "send_notification"
    case copyContextFromProject = "copy_context_from_project"
    case copyProjectFromParent = "copy_project_from_parent"
}

extension ActionType {
    var displayName: String {
        switch self {
        case .setStatus: return "Set Status"
        case .setPriority: return "Set Priority"
        case .setContext: return "Set Context"
        case .setProject: return "Set Project"
        case .addTag: return "Add Tag"
        case .setDueDate: return "Set Due Date"
        case .setDeferDate: return "Set Defer Date"
        case .flag: return "Flag Task"
        case .unflag: return "Unflag Task"
        case .moveToBoard: return "Move to Board"
        case .sendNotification: return "Send Notification"
        case .copyContextFromProject: return "Copy Context from Project"
        case .copyProjectFromParent: return "Copy Project from Parent"
        }
    }

    var description: String {
        switch self {
        case .setStatus: return "Changes the task's status"
        case .setPriority: return "Changes the task's priority"
        case .setContext: return "Sets the task's context"
        case .setProject: return "Sets the task's project"
        case .addTag: return "Adds a tag to the task"
        case .setDueDate: return "Sets the task's due date"
        case .setDeferDate: return "Sets the task's defer date"
        case .flag: return "Flags the task"
        case .unflag: return "Unflags the task"
        case .moveToBoard: return "Moves the task to a specific board"
        case .sendNotification: return "Sends a notification"
        case .copyContextFromProject: return "Automatically sets context based on project"
        case .copyProjectFromParent: return "Copies project from parent task"
        }
    }

    var requiresValue: Bool {
        switch self {
        case .flag, .unflag, .copyContextFromProject, .copyProjectFromParent:
            return false
        default:
            return true
        }
    }
}

// MARK: - Conditions

/// Condition for filtering which tasks a rule applies to
public struct RuleCondition: Codable, Equatable {
    var property: ConditionProperty
    var operator: ConditionOperator
    var value: String
}

public enum ConditionProperty: String, Codable, CaseIterable {
    case status
    case priority
    case project
    case context
    case hasTag = "has_tag"
    case flagged
    case hasProject = "has_project"
    case hasContext = "has_context"
    case hasDueDate = "has_due_date"
    case isSubtask = "is_subtask"
    case title
}

extension ConditionProperty {
    var displayName: String {
        switch self {
        case .status: return "Status"
        case .priority: return "Priority"
        case .project: return "Project"
        case .context: return "Context"
        case .hasTag: return "Has Tag"
        case .flagged: return "Flagged"
        case .hasProject: return "Has Project"
        case .hasContext: return "Has Context"
        case .hasDueDate: return "Has Due Date"
        case .isSubtask: return "Is Subtask"
        case .title: return "Title"
        }
    }
}

public enum ConditionOperator: String, Codable, CaseIterable {
    case equals
    case notEquals = "not_equals"
    case contains
    case notContains = "not_contains"
    case isTrue = "is_true"
    case isFalse = "is_false"
}

extension ConditionOperator {
    var displayName: String {
        switch self {
        case .equals: return "equals"
        case .notEquals: return "does not equal"
        case .contains: return "contains"
        case .notContains: return "does not contain"
        case .isTrue: return "is true"
        case .isFalse: return "is false"
        }
    }
}

// MARK: - Rule Action

/// An action to be performed when a rule is triggered
public struct RuleAction: Codable, Equatable, Identifiable {
    let id: UUID
    var type: ActionType
    var value: String?
    var relativeDate: RelativeDateValue?

    public init(id: UUID = UUID(), type: ActionType, value: String? = nil, relativeDate: RelativeDateValue? = nil) {
        self.id = id
        self.type = type
        self.value = value
        self.relativeDate = relativeDate
    }
}

/// Represents a relative date offset (e.g., +3 days, -1 week)
public struct RelativeDateValue: Codable, Equatable {
    var amount: Int
    var unit: DateUnit

    enum DateUnit: String, Codable, CaseIterable {
        case days
        case weeks
        case months
    }
}

extension RelativeDateValue {
    var displayString: String {
        let sign = amount >= 0 ? "+" : ""
        let unitString = unit.rawValue
        return "\(sign)\(amount) \(unitString)"
    }

    func apply(to date: Date) -> Date {
        let calendar = Calendar.current
        let component: Calendar.Component = {
            switch unit {
            case .days: return .day
            case .weeks: return .weekOfYear
            case .months: return .month
            }
        }()
        return calendar.date(byAdding: component, value: amount, to: date) ?? date
    }
}

// MARK: - Rule Model

/// An automation rule that triggers actions based on task changes
public struct Rule: Codable, Equatable, Identifiable {
    // MARK: - Core Properties

    let id: UUID
    var name: String
    var description: String?
    var isEnabled: Bool
    var isBuiltIn: Bool

    // MARK: - Trigger Configuration

    var triggerType: TriggerType
    var triggerValue: String? // Optional value for trigger (e.g., specific status, board ID, etc.)

    // MARK: - Conditions

    var conditions: [RuleCondition]
    var conditionLogic: ConditionLogic // AND or OR

    // MARK: - Actions

    var actions: [RuleAction]

    // MARK: - Metadata

    var created: Date
    var modified: Date
    var lastTriggered: Date?
    var triggerCount: Int

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        isEnabled: Bool = true,
        isBuiltIn: Bool = false,
        triggerType: TriggerType,
        triggerValue: String? = nil,
        conditions: [RuleCondition] = [],
        conditionLogic: ConditionLogic = .all,
        actions: [RuleAction],
        created: Date = Date(),
        modified: Date = Date(),
        lastTriggered: Date? = nil,
        triggerCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isEnabled = isEnabled
        self.isBuiltIn = isBuiltIn
        self.triggerType = triggerType
        self.triggerValue = triggerValue
        self.conditions = conditions
        self.conditionLogic = conditionLogic
        self.actions = actions
        self.created = created
        self.modified = modified
        self.lastTriggered = lastTriggered
        self.triggerCount = triggerCount
    }
}

public enum ConditionLogic: String, Codable, CaseIterable {
    case all // AND - all conditions must match
    case any // OR - any condition must match
}

extension ConditionLogic {
    var displayName: String {
        switch self {
        case .all: return "All"
        case .any: return "Any"
        }
    }
}

// MARK: - Rule Extensions

extension Rule {
    /// Returns true if this rule's conditions match the given task
    func matches(task: Task) -> Bool {
        guard isEnabled else { return false }

        // If no conditions, rule applies to all tasks
        guard !conditions.isEmpty else { return true }

        switch conditionLogic {
        case .all:
            return conditions.allSatisfy { condition in
                evaluateCondition(condition, for: task)
            }
        case .any:
            return conditions.contains { condition in
                evaluateCondition(condition, for: task)
            }
        }
    }

    /// Evaluates a single condition against a task
    private func evaluateCondition(_ condition: RuleCondition, for task: Task) -> Bool {
        switch condition.property {
        case .status:
            let taskStatus = task.status.rawValue
            return evaluateStringCondition(taskStatus, condition.operator, condition.value)

        case .priority:
            let taskPriority = task.priority.rawValue
            return evaluateStringCondition(taskPriority, condition.operator, condition.value)

        case .project:
            let taskProject = task.project ?? ""
            return evaluateStringCondition(taskProject, condition.operator, condition.value)

        case .context:
            let taskContext = task.context ?? ""
            return evaluateStringCondition(taskContext, condition.operator, condition.value)

        case .hasTag:
            let hasTag = task.tags.contains { $0.name == condition.value }
            return condition.operator == .isTrue ? hasTag : !hasTag

        case .flagged:
            return condition.operator == .isTrue ? task.flagged : !task.flagged

        case .hasProject:
            let hasProject = task.project != nil
            return condition.operator == .isTrue ? hasProject : !hasProject

        case .hasContext:
            let hasContext = task.context != nil
            return condition.operator == .isTrue ? hasContext : !hasContext

        case .hasDueDate:
            let hasDueDate = task.due != nil
            return condition.operator == .isTrue ? hasDueDate : !hasDueDate

        case .isSubtask:
            return condition.operator == .isTrue ? task.isSubtask : !task.isSubtask

        case .title:
            return evaluateStringCondition(task.title, condition.operator, condition.value)
        }
    }

    /// Evaluates a string-based condition
    private func evaluateStringCondition(_ taskValue: String, _ op: ConditionOperator, _ conditionValue: String) -> Bool {
        let taskValueLower = taskValue.lowercased()
        let conditionValueLower = conditionValue.lowercased()

        switch op {
        case .equals:
            return taskValueLower == conditionValueLower
        case .notEquals:
            return taskValueLower != conditionValueLower
        case .contains:
            return taskValueLower.contains(conditionValueLower)
        case .notContains:
            return !taskValueLower.contains(conditionValueLower)
        default:
            return false
        }
    }

    /// Returns a duplicate of this rule with a new ID
    func duplicate() -> Rule {
        var copy = self
        copy.id = UUID()
        copy.name = "\(name) (copy)"
        copy.isBuiltIn = false
        copy.created = Date()
        copy.modified = Date()
        copy.lastTriggered = nil
        copy.triggerCount = 0
        return copy
    }

    /// Updates the modified timestamp
    mutating func touch() {
        modified = Date()
    }

    /// Records that this rule was triggered
    mutating func recordTrigger() {
        lastTriggered = Date()
        triggerCount += 1
    }
}

// MARK: - Built-in Rule Templates

extension Rule {
    /// Returns a collection of built-in rule templates
    static var builtInTemplates: [Rule] {
        return [
            autoFlagHighPriority,
            autoDeferWeekendTasks,
            autoContextFromProject,
            autoTagUrgentTasks,
            autoArchiveOldCompleted
        ]
    }

    /// Auto-flag high priority tasks
    static var autoFlagHighPriority: Rule {
        Rule(
            name: "Auto-Flag High Priority",
            description: "Automatically flag tasks when priority is set to high",
            isBuiltIn: true,
            triggerType: .priorityChanged,
            triggerValue: "high",
            conditions: [
                RuleCondition(property: .priority, operator: .equals, value: "high")
            ],
            actions: [
                RuleAction(type: .flag)
            ]
        )
    }

    /// Auto-defer weekend tasks to Monday
    static var autoDeferWeekendTasks: Rule {
        Rule(
            name: "Auto-Defer Weekend Tasks",
            description: "Defer tasks created on weekends to next Monday",
            isBuiltIn: true,
            triggerType: .taskCreated,
            conditions: [],
            actions: [
                RuleAction(
                    type: .setDeferDate,
                    relativeDate: RelativeDateValue(amount: 1, unit: .days)
                )
            ]
        )
    }

    /// Auto-set context based on project
    static var autoContextFromProject: Rule {
        Rule(
            name: "Auto-Context from Project",
            description: "Automatically set context when project is assigned",
            isBuiltIn: true,
            triggerType: .projectSet,
            conditions: [
                RuleCondition(property: .hasProject, operator: .isTrue, value: "true")
            ],
            actions: [
                RuleAction(type: .copyContextFromProject)
            ]
        )
    }

    /// Auto-tag urgent tasks (high priority + due today)
    static var autoTagUrgentTasks: Rule {
        Rule(
            name: "Auto-Tag Urgent Tasks",
            description: "Tag tasks as 'urgent' when they are high priority and due soon",
            isBuiltIn: true,
            triggerType: .dueDateApproaching,
            conditions: [
                RuleCondition(property: .priority, operator: .equals, value: "high")
            ],
            conditionLogic: .all,
            actions: [
                RuleAction(type: .addTag, value: "urgent"),
                RuleAction(type: .flag)
            ]
        )
    }

    /// Auto-archive old completed tasks
    static var autoArchiveOldCompleted: Rule {
        Rule(
            name: "Auto-Archive Old Completed",
            description: "Archive completed tasks after 30 days",
            isBuiltIn: true,
            triggerType: .taskCompleted,
            conditions: [
                RuleCondition(property: .status, operator: .equals, value: "completed")
            ],
            actions: [
                // This would need a custom action type for archiving
                RuleAction(type: .sendNotification, value: "Task completed and will be archived")
            ]
        )
    }
}

// MARK: - Task Change Context

/// Context information about what changed in a task
public struct TaskChangeContext {
    var changeType: TriggerType
    var oldValue: String?
    var newValue: String?
    var task: Task
}

extension TaskChangeContext {
    /// Creates a change context for a task creation event
    static func taskCreated(_ task: Task) -> TaskChangeContext {
        TaskChangeContext(changeType: .taskCreated, task: task)
    }

    /// Creates a change context for a status change event
    static func statusChanged(from oldStatus: Status, to newStatus: Status, task: Task) -> TaskChangeContext {
        TaskChangeContext(
            changeType: .statusChanged,
            oldValue: oldStatus.rawValue,
            newValue: newStatus.rawValue,
            task: task
        )
    }

    /// Creates a change context for a priority change event
    static func priorityChanged(from oldPriority: Priority, to newPriority: Priority, task: Task) -> TaskChangeContext {
        TaskChangeContext(
            changeType: .priorityChanged,
            oldValue: oldPriority.rawValue,
            newValue: newPriority.rawValue,
            task: task
        )
    }

    /// Creates a change context for a flag event
    static func taskFlagged(_ task: Task) -> TaskChangeContext {
        TaskChangeContext(changeType: .taskFlagged, task: task)
    }

    /// Creates a change context for an unflag event
    static func taskUnflagged(_ task: Task) -> TaskChangeContext {
        TaskChangeContext(changeType: .taskUnflagged, task: task)
    }

    /// Creates a change context for a tag added event
    static func tagAdded(_ tagName: String, to task: Task) -> TaskChangeContext {
        TaskChangeContext(
            changeType: .tagAdded,
            newValue: tagName,
            task: task
        )
    }

    /// Creates a change context for a project set event
    static func projectSet(_ project: String, to task: Task) -> TaskChangeContext {
        TaskChangeContext(
            changeType: .projectSet,
            newValue: project,
            task: task
        )
    }

    /// Creates a change context for a context set event
    static func contextSet(_ context: String, to task: Task) -> TaskChangeContext {
        TaskChangeContext(
            changeType: .contextSet,
            newValue: context,
            task: task
        )
    }

    /// Creates a change context for a board move event
    static func movedToBoard(_ boardId: String, task: Task) -> TaskChangeContext {
        TaskChangeContext(
            changeType: .movedToBoard,
            newValue: boardId,
            task: task
        )
    }

    /// Creates a change context for a task completion event
    static func taskCompleted(_ task: Task) -> TaskChangeContext {
        TaskChangeContext(changeType: .taskCompleted, task: task)
    }
}
