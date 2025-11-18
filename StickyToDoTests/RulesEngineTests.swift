//
//  RulesEngineTests.swift
//  StickyToDoTests
//
//  Tests for the automation rules engine.
//

import XCTest
@testable import StickyToDo

class RulesEngineTests: XCTestCase {

    var engine: RulesEngine!

    override func setUp() {
        super.setUp()
        engine = RulesEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Rule Management Tests

    func testAddRule() {
        let rule = createTestRule(name: "Test Rule")
        engine.addRule(rule)

        XCTAssertEqual(engine.rules.count, 1)
        XCTAssertEqual(engine.rules.first?.name, "Test Rule")
    }

    func testUpdateRule() {
        var rule = createTestRule(name: "Original")
        engine.addRule(rule)

        rule.name = "Updated"
        engine.updateRule(rule)

        XCTAssertEqual(engine.rules.first?.name, "Updated")
    }

    func testRemoveRule() {
        let rule = createTestRule(name: "Test Rule")
        engine.addRule(rule)
        XCTAssertEqual(engine.rules.count, 1)

        engine.removeRule(rule)
        XCTAssertEqual(engine.rules.count, 0)
    }

    func testToggleRule() {
        let rule = createTestRule(name: "Test Rule", isEnabled: true)
        engine.addRule(rule)

        engine.toggleRule(rule)
        XCTAssertFalse(engine.rules.first?.isEnabled ?? true)

        engine.toggleRule(rule)
        XCTAssertTrue(engine.rules.first?.isEnabled ?? false)
    }

    // MARK: - Rule Evaluation Tests

    func testTaskCreatedTrigger() {
        // Create a rule that flags all new tasks
        let rule = Rule(
            name: "Flag new tasks",
            triggerType: .taskCreated,
            actions: [RuleAction(type: .flag)]
        )
        engine.addRule(rule)

        let task = Task(title: "New Task", flagged: false)
        let context = TaskChangeContext.taskCreated(task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertTrue(result.flagged, "Task should be flagged after rule evaluation")
    }

    func testStatusChangedTrigger() {
        // Create a rule that flags tasks when they become next-action
        let rule = Rule(
            name: "Flag next actions",
            triggerType: .statusChanged,
            triggerValue: "next-action",
            actions: [RuleAction(type: .flag)]
        )
        engine.addRule(rule)

        var task = Task(title: "Test Task", status: .inbox)
        task.status = .nextAction

        let context = TaskChangeContext.statusChanged(from: .inbox, to: .nextAction, task: task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertTrue(result.flagged)
    }

    func testPriorityChangedTrigger() {
        // Create a rule that flags high priority tasks
        let rule = Rule(
            name: "Flag high priority",
            triggerType: .priorityChanged,
            triggerValue: "high",
            conditions: [
                RuleCondition(property: .priority, operator: .equals, value: "high")
            ],
            actions: [RuleAction(type: .flag)]
        )
        engine.addRule(rule)

        var task = Task(title: "Test Task", priority: .medium)
        task.priority = .high

        let context = TaskChangeContext.priorityChanged(from: .medium, to: .high, task: task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertTrue(result.flagged)
    }

    // MARK: - Condition Tests

    func testConditionMatching_Equals() {
        let rule = Rule(
            name: "Flag inbox tasks",
            triggerType: .taskCreated,
            conditions: [
                RuleCondition(property: .status, operator: .equals, value: "inbox")
            ],
            actions: [RuleAction(type: .flag)]
        )
        engine.addRule(rule)

        let inboxTask = Task(title: "Inbox Task", status: .inbox)
        let nextTask = Task(title: "Next Task", status: .nextAction)

        XCTAssertTrue(rule.matches(task: inboxTask))
        XCTAssertFalse(rule.matches(task: nextTask))
    }

    func testConditionMatching_Contains() {
        let rule = Rule(
            name: "Tag work tasks",
            triggerType: .taskCreated,
            conditions: [
                RuleCondition(property: .title, operator: .contains, value: "work")
            ],
            actions: [RuleAction(type: .addTag, value: "work")]
        )
        engine.addRule(rule)

        let workTask = Task(title: "Work on project")
        let personalTask = Task(title: "Buy groceries")

        XCTAssertTrue(rule.matches(task: workTask))
        XCTAssertFalse(rule.matches(task: personalTask))
    }

    func testConditionMatching_Boolean() {
        let rule = Rule(
            name: "Unflag completed",
            triggerType: .taskCompleted,
            conditions: [
                RuleCondition(property: .flagged, operator: .isTrue, value: "true")
            ],
            actions: [RuleAction(type: .unflag)]
        )
        engine.addRule(rule)

        let flaggedTask = Task(title: "Flagged Task", flagged: true)
        let unflaggedTask = Task(title: "Unflagged Task", flagged: false)

        XCTAssertTrue(rule.matches(task: flaggedTask))
        XCTAssertFalse(rule.matches(task: unflaggedTask))
    }

    func testConditionLogic_All() {
        let rule = Rule(
            name: "High priority inbox",
            triggerType: .taskCreated,
            conditions: [
                RuleCondition(property: .status, operator: .equals, value: "inbox"),
                RuleCondition(property: .priority, operator: .equals, value: "high")
            ],
            conditionLogic: .all,
            actions: [RuleAction(type: .flag)]
        )
        engine.addRule(rule)

        let matchingTask = Task(title: "Matching", status: .inbox, priority: .high)
        let partialTask1 = Task(title: "Partial 1", status: .inbox, priority: .medium)
        let partialTask2 = Task(title: "Partial 2", status: .nextAction, priority: .high)

        XCTAssertTrue(rule.matches(task: matchingTask))
        XCTAssertFalse(rule.matches(task: partialTask1))
        XCTAssertFalse(rule.matches(task: partialTask2))
    }

    func testConditionLogic_Any() {
        let rule = Rule(
            name: "Important tasks",
            triggerType: .taskCreated,
            conditions: [
                RuleCondition(property: .flagged, operator: .isTrue, value: "true"),
                RuleCondition(property: .priority, operator: .equals, value: "high")
            ],
            conditionLogic: .any,
            actions: [RuleAction(type: .addTag, value: "important")]
        )
        engine.addRule(rule)

        let flaggedTask = Task(title: "Flagged", flagged: true, priority: .low)
        let highPriorityTask = Task(title: "High Priority", flagged: false, priority: .high)
        let bothTask = Task(title: "Both", flagged: true, priority: .high)
        let neitherTask = Task(title: "Neither", flagged: false, priority: .low)

        XCTAssertTrue(rule.matches(task: flaggedTask))
        XCTAssertTrue(rule.matches(task: highPriorityTask))
        XCTAssertTrue(rule.matches(task: bothTask))
        XCTAssertFalse(rule.matches(task: neitherTask))
    }

    // MARK: - Action Tests

    func testAction_SetStatus() {
        let rule = Rule(
            name: "Auto next-action",
            triggerType: .taskCreated,
            actions: [RuleAction(type: .setStatus, value: "next-action")]
        )
        engine.addRule(rule)

        let task = Task(title: "New Task", status: .inbox)
        let context = TaskChangeContext.taskCreated(task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertEqual(result.status, .nextAction)
    }

    func testAction_SetPriority() {
        let rule = Rule(
            name: "High priority urgent",
            triggerType: .tagAdded,
            triggerValue: "urgent",
            actions: [RuleAction(type: .setPriority, value: "high")]
        )
        engine.addRule(rule)

        let task = Task(title: "Urgent Task", priority: .medium)
        let context = TaskChangeContext.tagAdded("urgent", to: task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertEqual(result.priority, .high)
    }

    func testAction_AddTag() {
        let rule = Rule(
            name: "Tag high priority",
            triggerType: .priorityChanged,
            triggerValue: "high",
            actions: [RuleAction(type: .addTag, value: "urgent")]
        )
        engine.addRule(rule)

        var task = Task(title: "Test Task", priority: .medium)
        task.priority = .high

        let context = TaskChangeContext.priorityChanged(from: .medium, to: .high, task: task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertTrue(result.tags.contains(where: { $0.name == "urgent" }))
    }

    func testAction_Flag() {
        let rule = Rule(
            name: "Flag important",
            triggerType: .taskCreated,
            actions: [RuleAction(type: .flag)]
        )
        engine.addRule(rule)

        let task = Task(title: "Test Task", flagged: false)
        let context = TaskChangeContext.taskCreated(task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertTrue(result.flagged)
    }

    func testAction_Unflag() {
        let rule = Rule(
            name: "Unflag completed",
            triggerType: .taskCompleted,
            actions: [RuleAction(type: .unflag)]
        )
        engine.addRule(rule)

        let task = Task(title: "Test Task", status: .completed, flagged: true)
        let context = TaskChangeContext.taskCompleted(task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertFalse(result.flagged)
    }

    func testAction_SetContext() {
        let rule = Rule(
            name: "Set work context",
            triggerType: .projectSet,
            triggerValue: "Work Project",
            actions: [RuleAction(type: .setContext, value: "office")]
        )
        engine.addRule(rule)

        var task = Task(title: "Test Task")
        task.project = "Work Project"

        let context = TaskChangeContext.projectSet("Work Project", to: task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertEqual(result.context, "office")
    }

    func testAction_SetProject() {
        let rule = Rule(
            name: "Set default project",
            triggerType: .taskCreated,
            conditions: [
                RuleCondition(property: .hasProject, operator: .isFalse, value: "false")
            ],
            actions: [RuleAction(type: .setProject, value: "Inbox")]
        )
        engine.addRule(rule)

        let task = Task(title: "Test Task")
        let context = TaskChangeContext.taskCreated(task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertEqual(result.project, "Inbox")
    }

    func testAction_SetRelativeDueDate() {
        let rule = Rule(
            name: "Due in 3 days",
            triggerType: .taskCreated,
            actions: [
                RuleAction(
                    type: .setDueDate,
                    relativeDate: RelativeDateValue(amount: 3, unit: .days)
                )
            ]
        )
        engine.addRule(rule)

        let task = Task(title: "Test Task")
        let context = TaskChangeContext.taskCreated(task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertNotNil(result.due)

        // Check that due date is approximately 3 days from now
        let expectedDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let diff = abs(result.due!.timeIntervalSince(expectedDate))
        XCTAssertLessThan(diff, 10) // Within 10 seconds
    }

    func testAction_SetRelativeDeferDate() {
        let rule = Rule(
            name: "Defer 1 week",
            triggerType: .taskCreated,
            actions: [
                RuleAction(
                    type: .setDeferDate,
                    relativeDate: RelativeDateValue(amount: 1, unit: .weeks)
                )
            ]
        )
        engine.addRule(rule)

        let task = Task(title: "Test Task")
        let context = TaskChangeContext.taskCreated(task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertNotNil(result.defer)

        // Check that defer date is approximately 1 week from now
        let expectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        let diff = abs(result.defer!.timeIntervalSince(expectedDate))
        XCTAssertLessThan(diff, 10)
    }

    // MARK: - Multiple Actions Tests

    func testMultipleActions() {
        let rule = Rule(
            name: "Urgent task setup",
            triggerType: .taskCreated,
            actions: [
                RuleAction(type: .setPriority, value: "high"),
                RuleAction(type: .flag),
                RuleAction(type: .addTag, value: "urgent"),
                RuleAction(type: .setStatus, value: "next-action")
            ]
        )
        engine.addRule(rule)

        let task = Task(title: "Test Task", status: .inbox, flagged: false, priority: .medium)
        let context = TaskChangeContext.taskCreated(task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertEqual(result.priority, .high)
        XCTAssertTrue(result.flagged)
        XCTAssertTrue(result.tags.contains(where: { $0.name == "urgent" }))
        XCTAssertEqual(result.status, .nextAction)
    }

    // MARK: - Due Date Checking Tests

    func testCheckDueDateRules() {
        let rule = Rule(
            name: "Flag approaching deadlines",
            triggerType: .dueDateApproaching,
            actions: [RuleAction(type: .flag)]
        )
        engine.addRule(rule)

        // Create tasks with different due dates
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        let task1 = Task(title: "Due tomorrow", due: tomorrow)
        let task2 = Task(title: "Due next week", due: nextWeek)

        let tasks = [task1, task2]
        let results = engine.checkDueDateRules(for: tasks)

        // Task due tomorrow should be flagged
        let result1 = results.first { $0.id == task1.id }
        XCTAssertTrue(result1?.flagged ?? false)

        // Task due next week should not be flagged (outside 3-day window)
        let result2 = results.first { $0.id == task2.id }
        XCTAssertFalse(result2?.flagged ?? true)
    }

    // MARK: - Built-in Templates Tests

    func testBuiltInTemplates() {
        engine.loadBuiltInTemplates()

        XCTAssertEqual(engine.rules.count, Rule.builtInTemplates.count)
        XCTAssertTrue(engine.rules.allSatisfy { $0.isBuiltIn })
    }

    func testAutoFlagHighPriorityTemplate() {
        let template = Rule.autoFlagHighPriority
        engine.addRule(template)

        var task = Task(title: "Test Task", priority: .medium)
        task.priority = .high

        let context = TaskChangeContext.priorityChanged(from: .medium, to: .high, task: task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertTrue(result.flagged)
    }

    // MARK: - Rule Validation Tests

    func testValidateRule_EmptyName() {
        let rule = Rule(
            name: "",
            triggerType: .taskCreated,
            actions: [RuleAction(type: .flag)]
        )

        let errors = engine.validateRule(rule)
        XCTAssertTrue(errors.contains { $0.contains("name") })
    }

    func testValidateRule_NoActions() {
        let rule = Rule(
            name: "Invalid Rule",
            triggerType: .taskCreated,
            actions: []
        )

        let errors = engine.validateRule(rule)
        XCTAssertTrue(errors.contains { $0.contains("action") })
    }

    func testValidateRule_ActionMissingValue() {
        let rule = Rule(
            name: "Invalid Rule",
            triggerType: .taskCreated,
            actions: [RuleAction(type: .setStatus, value: nil)]
        )

        let errors = engine.validateRule(rule)
        XCTAssertTrue(errors.contains { $0.contains("value") })
    }

    func testValidateRule_Valid() {
        let rule = Rule(
            name: "Valid Rule",
            triggerType: .taskCreated,
            actions: [RuleAction(type: .flag)]
        )

        let errors = engine.validateRule(rule)
        XCTAssertTrue(errors.isEmpty)
    }

    // MARK: - Statistics Tests

    func testRuleStatistics() {
        let rule1 = createTestRule(name: "Rule 1", isEnabled: true)
        let rule2 = createTestRule(name: "Rule 2", isEnabled: false)

        engine.addRule(rule1)
        engine.addRule(rule2)

        let stats = engine.getRuleStatistics()

        XCTAssertEqual(stats.totalRules, 2)
        XCTAssertEqual(stats.enabledRules, 1)
        XCTAssertEqual(stats.disabledRules, 1)
    }

    func testRuleStatistics_TriggerCount() {
        var rule = createTestRule(name: "Test Rule")
        engine.addRule(rule)

        // Simulate triggering the rule
        rule.recordTrigger()
        rule.recordTrigger()
        rule.recordTrigger()
        engine.updateRule(rule)

        let stats = engine.getRuleStatistics()
        XCTAssertEqual(stats.totalTriggers, 3)
        XCTAssertEqual(stats.mostTriggeredRule?.name, "Test Rule")
    }

    // MARK: - Project Context Mapping Tests

    func testProjectContextMapping() {
        let tasks = [
            Task(title: "Task 1", project: "Work", context: "office"),
            Task(title: "Task 2", project: "Work", context: "office"),
            Task(title: "Task 3", project: "Work", context: "computer"),
            Task(title: "Task 4", project: "Personal", context: "home")
        ]

        engine.buildProjectContextMappings(from: tasks)

        let rule = Rule(
            name: "Auto context",
            triggerType: .projectSet,
            actions: [RuleAction(type: .copyContextFromProject)]
        )
        engine.addRule(rule)

        var task = Task(title: "New Work Task")
        task.project = "Work"

        let context = TaskChangeContext.projectSet("Work", to: task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertEqual(result.context, "office") // Most common context for "Work" project
    }

    // MARK: - Disabled Rule Tests

    func testDisabledRuleNotTriggered() {
        let rule = Rule(
            name: "Disabled Rule",
            isEnabled: false,
            triggerType: .taskCreated,
            actions: [RuleAction(type: .flag)]
        )
        engine.addRule(rule)

        let task = Task(title: "Test Task", flagged: false)
        let context = TaskChangeContext.taskCreated(task)
        let result = engine.evaluateRules(for: context, task: task)

        XCTAssertFalse(result.flagged)
    }

    // MARK: - Helper Methods

    private func createTestRule(
        name: String,
        isEnabled: Bool = true,
        triggerType: TriggerType = .taskCreated
    ) -> Rule {
        return Rule(
            name: name,
            isEnabled: isEnabled,
            triggerType: triggerType,
            actions: [RuleAction(type: .flag)]
        )
    }
}
