//
//  RulesEngine.swift
//  StickyToDoCore
//
//  Engine for evaluating and executing automation rules.
//

import Foundation

/// Engine that evaluates rules and executes actions on tasks
class RulesEngine {

    // MARK: - Properties

    /// All active rules
    private(set) var rules: [Rule]

    /// Logger for debugging rule execution
    private var logger: ((String) -> Void)?

    /// Mapping of projects to their default contexts
    private var projectContextMappings: [String: String] = [:]

    // MARK: - Initialization

    init(rules: [Rule] = []) {
        self.rules = rules
    }

    /// Configure logging for rule engine operations
    /// - Parameter logger: A closure that receives log messages
    func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    /// Sets the project-to-context mapping
    /// - Parameter mappings: Dictionary mapping project names to context names
    func setProjectContextMappings(_ mappings: [String: String]) {
        self.projectContextMappings = mappings
    }

    // MARK: - Rule Management

    /// Adds a rule to the engine
    func addRule(_ rule: Rule) {
        rules.append(rule)
        logger?("Added rule: \(rule.name)")
    }

    /// Updates an existing rule
    func updateRule(_ rule: Rule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            var updatedRule = rule
            updatedRule.touch()
            rules[index] = updatedRule
            logger?("Updated rule: \(rule.name)")
        }
    }

    /// Removes a rule
    func removeRule(_ rule: Rule) {
        rules.removeAll { $0.id == rule.id }
        logger?("Removed rule: \(rule.name)")
    }

    /// Removes a rule by ID
    func removeRule(withID id: UUID) {
        rules.removeAll { $0.id == id }
        logger?("Removed rule with ID: \(id)")
    }

    /// Toggles a rule's enabled state
    func toggleRule(_ rule: Rule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].isEnabled.toggle()
            logger?("Toggled rule: \(rule.name) - enabled: \(rules[index].isEnabled)")
        }
    }

    /// Returns all enabled rules
    var enabledRules: [Rule] {
        return rules.filter { $0.isEnabled }
    }

    // MARK: - Rule Evaluation

    /// Evaluates rules for a task change and returns the modified task
    /// - Parameters:
    ///   - context: The change context describing what changed
    ///   - task: The task to evaluate
    /// - Returns: The modified task after applying all matching rules
    func evaluateRules(for context: TaskChangeContext, task: Task) -> Task {
        var modifiedTask = task

        // Find all rules that match this trigger type
        let matchingRules = enabledRules.filter { rule in
            // Check if trigger type matches
            guard rule.triggerType == context.changeType else { return false }

            // If rule has a trigger value, check if it matches
            if let triggerValue = rule.triggerValue,
               let newValue = context.newValue {
                return triggerValue.lowercased() == newValue.lowercased()
            }

            return true
        }

        logger?("Found \(matchingRules.count) rules matching trigger: \(context.changeType.displayName)")

        // Execute each matching rule
        for var rule in matchingRules {
            // Check if rule conditions match the task
            if rule.matches(task: modifiedTask) {
                logger?("Executing rule: \(rule.name)")

                // Apply all actions
                modifiedTask = executeActions(rule.actions, on: modifiedTask)

                // Record that the rule was triggered
                rule.recordTrigger()
                updateRule(rule)
            }
        }

        return modifiedTask
    }

    /// Executes a list of actions on a task
    /// - Parameters:
    ///   - actions: The actions to execute
    ///   - task: The task to modify
    /// - Returns: The modified task
    private func executeActions(_ actions: [RuleAction], on task: Task) -> Task {
        var modifiedTask = task

        for action in actions {
            modifiedTask = executeAction(action, on: modifiedTask)
        }

        return modifiedTask
    }

    /// Executes a single action on a task
    /// - Parameters:
    ///   - action: The action to execute
    ///   - task: The task to modify
    /// - Returns: The modified task
    private func executeAction(_ action: RuleAction, on task: Task) -> Task {
        var modifiedTask = task

        switch action.type {
        case .setStatus:
            if let statusString = action.value,
               let status = Status(rawValue: statusString) {
                modifiedTask.status = status
                logger?("Set status to: \(status.displayName)")
            }

        case .setPriority:
            if let priorityString = action.value,
               let priority = Priority(rawValue: priorityString) {
                modifiedTask.priority = priority
                logger?("Set priority to: \(priority.displayName)")
            }

        case .setContext:
            modifiedTask.context = action.value
            logger?("Set context to: \(action.value ?? "nil")")

        case .setProject:
            modifiedTask.project = action.value
            logger?("Set project to: \(action.value ?? "nil")")

        case .addTag:
            if let tagName = action.value {
                let tag = Tag(name: tagName, color: nil)
                if !modifiedTask.tags.contains(where: { $0.name == tagName }) {
                    modifiedTask.addTag(tag)
                    logger?("Added tag: \(tagName)")
                }
            }

        case .setDueDate:
            if let relativeDate = action.relativeDate {
                let baseDate = modifiedTask.due ?? Date()
                modifiedTask.due = relativeDate.apply(to: baseDate)
                logger?("Set due date to: \(relativeDate.displayString)")
            } else if let dateString = action.value {
                // Parse date string if provided
                if let date = parseDateString(dateString) {
                    modifiedTask.due = date
                    logger?("Set due date to: \(dateString)")
                }
            }

        case .setDeferDate:
            if let relativeDate = action.relativeDate {
                let baseDate = Date()
                modifiedTask.defer = relativeDate.apply(to: baseDate)
                logger?("Set defer date to: \(relativeDate.displayString)")
            } else if let dateString = action.value {
                // Parse date string if provided
                if let date = parseDateString(dateString) {
                    modifiedTask.defer = date
                    logger?("Set defer date to: \(dateString)")
                }
            }

        case .flag:
            modifiedTask.flagged = true
            logger?("Flagged task")

        case .unflag:
            modifiedTask.flagged = false
            logger?("Unflagged task")

        case .moveToBoard:
            if let boardId = action.value {
                // Set a position on the board (default position)
                let position = Position(x: 0, y: 0, width: 200, height: 150)
                modifiedTask.setPosition(position, for: boardId)
                logger?("Moved task to board: \(boardId)")
            }

        case .sendNotification:
            // This would trigger a notification
            logger?("Notification: \(action.value ?? "")")

        case .copyContextFromProject:
            // Copy context from project mapping
            if let project = modifiedTask.project,
               let context = projectContextMappings[project] {
                modifiedTask.context = context
                logger?("Copied context '\(context)' from project '\(project)'")
            }

        case .copyProjectFromParent:
            // This would need to be handled by the caller who has access to parent task
            logger?("Copy project from parent requested")
        }

        return modifiedTask
    }

    /// Parses a date string in various formats
    private func parseDateString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Try standard ISO format first
        if let date = formatter.date(from: dateString) {
            return date
        }

        // Try other common formats
        formatter.dateFormat = "MM/dd/yyyy"
        if let date = formatter.date(from: dateString) {
            return date
        }

        return nil
    }

    // MARK: - Scheduled Rule Checking

    /// Checks for tasks with approaching due dates and triggers rules
    /// This should be called daily or on app launch
    /// - Parameter tasks: All active tasks to check
    /// - Returns: Modified tasks with rules applied
    func checkDueDateRules(for tasks: [Task]) -> [Task] {
        var modifiedTasks: [Task] = []

        for task in tasks {
            var modifiedTask = task

            // Check if task is due within the next 3 days
            if let dueDate = task.due, !task.isOverdue {
                let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0

                if daysUntilDue >= 0 && daysUntilDue <= 3 {
                    let context = TaskChangeContext(
                        changeType: .dueDateApproaching,
                        newValue: "\(daysUntilDue)",
                        task: task
                    )

                    modifiedTask = evaluateRules(for: context, task: task)
                }
            }

            modifiedTasks.append(modifiedTask)
        }

        return modifiedTasks
    }

    // MARK: - Rule Validation

    /// Validates that a rule is properly configured
    /// - Parameter rule: The rule to validate
    /// - Returns: An array of validation error messages (empty if valid)
    func validateRule(_ rule: Rule) -> [String] {
        var errors: [String] = []

        // Check for empty name
        if rule.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Rule name cannot be empty")
        }

        // Check that actions are properly configured
        for action in rule.actions {
            if action.type.requiresValue {
                if action.value == nil && action.relativeDate == nil {
                    errors.append("Action '\(action.type.displayName)' requires a value")
                }
            }
        }

        // Check for at least one action
        if rule.actions.isEmpty {
            errors.append("Rule must have at least one action")
        }

        // Validate conditions
        for condition in rule.conditions {
            if condition.operator.requiresValue && condition.value.isEmpty {
                errors.append("Condition on '\(condition.property.displayName)' requires a value")
            }
        }

        return errors
    }

    // MARK: - Statistics

    /// Returns statistics about rule usage
    func getRuleStatistics() -> RuleStatistics {
        let totalRules = rules.count
        let enabledCount = rules.filter { $0.isEnabled }.count
        let disabledCount = totalRules - enabledCount
        let totalTriggers = rules.reduce(0) { $0 + $1.triggerCount }

        let mostTriggeredRule = rules.max { $0.triggerCount < $1.triggerCount }

        return RuleStatistics(
            totalRules: totalRules,
            enabledRules: enabledCount,
            disabledRules: disabledCount,
            totalTriggers: totalTriggers,
            mostTriggeredRule: mostTriggeredRule
        )
    }
}

// MARK: - Supporting Types

extension ConditionOperator {
    var requiresValue: Bool {
        switch self {
        case .isTrue, .isFalse:
            return false
        default:
            return true
        }
    }
}

struct RuleStatistics {
    let totalRules: Int
    let enabledRules: Int
    let disabledRules: Int
    let totalTriggers: Int
    let mostTriggeredRule: Rule?
}

// MARK: - Convenience Methods

extension RulesEngine {
    /// Creates a simple rule with one trigger and one action
    /// - Parameters:
    ///   - name: The rule name
    ///   - trigger: The trigger type
    ///   - action: The action type
    ///   - actionValue: The value for the action
    /// - Returns: A new rule
    static func createSimpleRule(
        name: String,
        trigger: TriggerType,
        action: ActionType,
        actionValue: String? = nil
    ) -> Rule {
        return Rule(
            name: name,
            triggerType: trigger,
            actions: [RuleAction(type: action, value: actionValue)]
        )
    }

    /// Loads built-in rule templates
    func loadBuiltInTemplates() {
        for template in Rule.builtInTemplates {
            addRule(template)
        }
        logger?("Loaded \(Rule.builtInTemplates.count) built-in rule templates")
    }
}

// MARK: - Project Context Mapping Helper

extension RulesEngine {
    /// Automatically builds project-to-context mappings from existing tasks
    /// - Parameter tasks: All tasks to analyze
    func buildProjectContextMappings(from tasks: [Task]) {
        var mappings: [String: [String: Int]] = [:] // project -> [context: count]

        // Count context usage per project
        for task in tasks {
            guard let project = task.project, let context = task.context else { continue }

            if mappings[project] == nil {
                mappings[project] = [:]
            }

            mappings[project]?[context, default: 0] += 1
        }

        // Select the most common context for each project
        var finalMappings: [String: String] = [:]
        for (project, contextCounts) in mappings {
            if let mostCommonContext = contextCounts.max(by: { $0.value < $1.value }) {
                finalMappings[project] = mostCommonContext.key
            }
        }

        self.projectContextMappings = finalMappings
        logger?("Built project-context mappings for \(finalMappings.count) projects")
    }
}
