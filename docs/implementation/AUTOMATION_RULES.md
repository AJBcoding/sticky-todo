# Automation Rules Engine

StickyToDo includes a powerful automation rules engine that allows you to automatically organize and manage your tasks based on triggers, conditions, and actions.

## Table of Contents

- [Overview](#overview)
- [Accessing Automation Rules](#accessing-automation-rules)
- [Rule Components](#rule-components)
- [Built-in Templates](#built-in-templates)
- [Creating Custom Rules](#creating-custom-rules)
- [Rule Examples](#rule-examples)
- [Best Practices](#best-practices)
- [Technical Details](#technical-details)

## Overview

The automation rules engine evaluates rules in real-time as tasks are created and modified, automatically applying actions based on your configured triggers and conditions. This helps you maintain consistent task organization without manual intervention.

### Key Features

- **11 Trigger Types**: Respond to task creation, status changes, flagging, and more
- **13 Action Types**: Automatically set properties, add tags, schedule dates, and send notifications
- **Flexible Conditions**: Match tasks using AND/OR logic with multiple criteria
- **Built-in Templates**: Start with 5 pre-configured rule templates
- **Relative Dates**: Set due/defer dates relative to trigger time (e.g., +3 days)
- **Project-Context Mapping**: Automatically derive contexts from projects

## Accessing Automation Rules

**Menu**: Tools → Automation Rules...
**Keyboard Shortcut**: `⌘⌥R`

The Automation Rules editor displays all your rules, both built-in templates and custom rules. You can:

- View rule details and statistics
- Enable/disable rules
- Create new rules
- Edit existing custom rules
- Duplicate rules
- Delete custom rules

## Rule Components

Every automation rule consists of three main components:

### 1. Trigger

The trigger determines **when** a rule should evaluate. Available triggers:

| Trigger | Description | Example Use Case |
|---------|-------------|------------------|
| **Task Created** | Fires when a new task is created | Auto-assign default project |
| **Status Changed** | Fires when task status changes | Flag next-action tasks |
| **Priority Changed** | Fires when priority is modified | Auto-tag high priority items |
| **Task Flagged** | Fires when a task is flagged | Set high priority |
| **Task Unflagged** | Fires when a task is unflagged | Remove urgent tag |
| **Moved to Board** | Fires when task is placed on a board | Set context based on board |
| **Tag Added** | Fires when a tag is added | Trigger related actions |
| **Project Set** | Fires when project is assigned | Auto-set context |
| **Context Set** | Fires when context is assigned | Related organization |
| **Due Date Approaching** | Fires 3 days before due date | Flag urgent items |
| **Task Completed** | Fires when task is marked complete | Auto-archive or cleanup |

### 2. Conditions (Optional)

Conditions filter which tasks a rule applies to. Multiple conditions can be combined with AND/OR logic.

**Condition Properties:**

- **Status**: inbox, next-action, waiting, someday, completed
- **Priority**: high, medium, low
- **Project**: Specific project name
- **Context**: Specific context name
- **Has Tag**: Check for specific tag
- **Flagged**: Is flagged or not
- **Has Project**: Has any project assigned
- **Has Context**: Has any context assigned
- **Has Due Date**: Has a due date set
- **Is Subtask**: Is a subtask of another task
- **Title**: Text in task title

**Condition Operators:**

- **equals** / **does not equal**: Exact match
- **contains** / **does not contain**: Partial match
- **is true** / **is false**: Boolean properties

**Example Condition:**
```
Match ALL of the following:
- Status equals "inbox"
- Priority equals "high"
- Has Project is true
```

### 3. Actions

Actions define **what** happens when a rule matches. Multiple actions can be executed in sequence.

| Action | Description | Value Type |
|--------|-------------|------------|
| **Set Status** | Changes task status | inbox, next-action, waiting, someday, completed |
| **Set Priority** | Changes task priority | high, medium, low |
| **Set Context** | Sets the task context | Text value |
| **Set Project** | Sets the task project | Text value |
| **Add Tag** | Adds a tag to the task | Tag name |
| **Set Due Date** | Sets the due date | Relative date (+3 days, +1 week) |
| **Set Defer Date** | Sets the defer/start date | Relative date (+1 week, +2 months) |
| **Flag** | Flags the task | No value needed |
| **Unflag** | Unflags the task | No value needed |
| **Move to Board** | Places task on a board | Board ID |
| **Send Notification** | Shows a notification | Message text |
| **Copy Context from Project** | Auto-sets context based on learned project mappings | No value needed |
| **Copy Project from Parent** | Inherits project from parent task | No value needed |

## Built-in Templates

StickyToDo includes 5 built-in rule templates that you can enable and customize:

### 1. Auto-Flag High Priority

**Purpose**: Automatically flag tasks when priority is set to high

**Configuration:**
- **Trigger**: Priority Changed (value: high)
- **Conditions**: Priority equals "high"
- **Actions**: Flag

**Use Case**: Ensures all high-priority tasks are visually highlighted for quick identification.

### 2. Auto-Defer Weekend Tasks

**Purpose**: Defer tasks created on weekends to next Monday

**Configuration:**
- **Trigger**: Task Created
- **Conditions**: None (applies to all tasks)
- **Actions**: Set Defer Date (+1 day)

**Use Case**: Prevents weekend-created tasks from cluttering your Monday inbox by deferring them slightly.

### 3. Auto-Context from Project

**Purpose**: Automatically set context when project is assigned

**Configuration:**
- **Trigger**: Project Set
- **Conditions**: Has Project is true
- **Actions**: Copy Context from Project

**Use Case**: Learns which contexts you commonly use for each project and automatically applies them.

### 4. Auto-Tag Urgent Tasks

**Purpose**: Tag tasks as 'urgent' when they are high priority and due soon

**Configuration:**
- **Trigger**: Due Date Approaching
- **Conditions**: Priority equals "high"
- **Actions**: Add Tag "urgent", Flag

**Use Case**: Automatically identifies and highlights truly urgent tasks that need immediate attention.

### 5. Auto-Archive Old Completed

**Purpose**: Archive completed tasks after 30 days

**Configuration:**
- **Trigger**: Task Completed
- **Conditions**: Status equals "completed"
- **Actions**: Send Notification "Task completed and will be archived"

**Use Case**: Helps maintain a clean task list by archiving old completed items.

## Creating Custom Rules

### Step-by-Step Guide

1. **Open Automation Rules**
   - Menu: Tools → Automation Rules...
   - Or press `⌘⌥R`

2. **Click "New Rule" or press `+`**

3. **Configure Basic Information**
   - Enter a descriptive name
   - Add an optional description
   - Set the rule as enabled (default)

4. **Select a Trigger**
   - Choose when the rule should evaluate
   - Enter a trigger value if required (e.g., specific status)

5. **Add Conditions (Optional)**
   - Click "Add" in the Conditions section
   - Select property, operator, and value
   - Choose AND or OR logic for multiple conditions

6. **Add Actions**
   - Click "Add" in the Actions section
   - Select action type
   - Enter value or configure relative date
   - Add multiple actions to execute in sequence

7. **Save the Rule**
   - Click "Save" to create the rule
   - The rule will immediately start evaluating new changes

## Rule Examples

### Example 1: Work Project Organization

**Goal**: Automatically organize work-related tasks

```yaml
Name: Work Project Setup
Trigger: Project Set (value: "Work")
Conditions:
  - Project equals "Work"
Actions:
  - Set Context: "office"
  - Add Tag: "work"
  - Set Priority: "medium"
```

### Example 2: Quick Inbox Processing

**Goal**: Auto-promote inbox tasks with specific keywords to next-action

```yaml
Name: Quick Capture Processing
Trigger: Task Created
Conditions:
  Match ANY:
    - Title contains "call"
    - Title contains "email"
    - Title contains "meeting"
Actions:
  - Set Status: "next-action"
  - Set Priority: "high"
```

### Example 3: Deadline Management

**Goal**: Flag tasks due in the next 3 days and set high priority

```yaml
Name: Approaching Deadlines
Trigger: Due Date Approaching
Conditions:
  - Status equals "next-action"
Actions:
  - Flag
  - Set Priority: "high"
  - Add Tag: "deadline"
```

### Example 4: Subtask Inheritance

**Goal**: New subtasks inherit project from parent

```yaml
Name: Subtask Project Inheritance
Trigger: Task Created
Conditions:
  - Is Subtask is true
  - Has Project is false
Actions:
  - Copy Project from Parent
  - Copy Context from Project
```

### Example 5: Weekend Deferral

**Goal**: Defer personal tasks created on weekends to Monday

```yaml
Name: Weekend Deferral
Trigger: Task Created
Conditions:
  - Project equals "Personal"
Actions:
  - Set Defer Date: +2 days
```

### Example 6: Auto-Schedule with Relative Dates

**Goal**: Tasks tagged "next-week" automatically get due date

```yaml
Name: Next Week Scheduler
Trigger: Tag Added (value: "next-week")
Conditions: None
Actions:
  - Set Due Date: +7 days
  - Set Status: "next-action"
```

### Example 7: Waiting Task Management

**Goal**: Unflag tasks moved to waiting status

```yaml
Name: Unflag Waiting Tasks
Trigger: Status Changed (value: "waiting")
Conditions:
  - Flagged is true
Actions:
  - Unflag
  - Add Tag: "waiting-for"
```

### Example 8: High Priority Alert

**Goal**: Multiple actions for urgent high-priority tasks

```yaml
Name: High Priority Alert
Trigger: Priority Changed (value: "high")
Conditions:
  Match ALL:
    - Priority equals "high"
    - Has Due Date is true
Actions:
  - Flag
  - Add Tag: "urgent"
  - Send Notification: "High priority task requires attention"
  - Set Status: "next-action"
```

## Best Practices

### 1. Start Simple

Begin with one or two rules that address your most common workflows. Add complexity gradually as you become comfortable with the system.

### 2. Use Built-in Templates

Enable and test the built-in templates first. They cover common GTD workflows and can be duplicated and customized.

### 3. Descriptive Names

Use clear, descriptive names that explain what the rule does:
- ✅ "Auto-flag urgent work tasks"
- ❌ "Rule 1"

### 4. Test Before Enabling

Create a rule in disabled state, test it on a few tasks, then enable it once you're confident it works as expected.

### 5. Leverage Conditions

Use conditions to make rules specific and avoid unintended matches:
- Too broad: Trigger=Task Created, Action=Flag (flags everything!)
- Better: Trigger=Task Created, Condition=Priority is high, Action=Flag

### 6. Combine Actions Wisely

Multiple actions execute in sequence, so order matters:
```
Good order:
1. Set Status
2. Set Priority
3. Flag
4. Add Tag

The logical flow ensures properties are set before tags are added.
```

### 7. Relative Dates for Flexibility

Use relative dates instead of absolute dates:
- ✅ Set Due Date: +3 days (flexible, works anytime)
- ❌ Set Due Date: "2025-12-01" (static, becomes outdated)

### 8. Monitor Rule Statistics

Check the rule statistics to see:
- How often rules trigger
- Which rules are most useful
- Rules that never trigger (candidates for removal)

### 9. Avoid Rule Conflicts

Be careful not to create rules that fight each other:
```
Conflict Example:
Rule A: Trigger=Task Created → Set Priority: high
Rule B: Trigger=Task Created → Set Priority: low

Both will run, last one wins (confusing!)
```

### 10. Document Complex Rules

Add detailed descriptions to complex rules explaining:
- Why the rule exists
- What problem it solves
- Any special considerations

## Technical Details

### Rule Evaluation

Rules are evaluated in the following scenarios:

1. **Task Creation**: When `TaskStore.add()` is called
2. **Task Updates**: When `TaskStore.updateWithRules()` is called with a change context
3. **Daily Check**: Via `TaskStore.checkDueDateAutomation()` for approaching due dates
4. **Manual Trigger**: Through the UI or API

### Rule Execution Order

1. Rules are evaluated in the order they appear in the rules list
2. For each rule:
   - Check if trigger type matches the event
   - Check if trigger value matches (if specified)
   - Evaluate all conditions (AND/OR logic)
   - Execute all actions in sequence if conditions pass
3. Modified task is returned

### Performance Considerations

- Rules are evaluated in-memory with minimal overhead
- Disabled rules are skipped entirely
- Condition evaluation short-circuits (stops at first failure in AND mode)
- Action execution is synchronous but fast

### Storage Format

Rules are stored in `config/rules.yaml`:

```yaml
- id: 12345678-1234-1234-1234-123456789012
  name: Auto-Flag High Priority
  description: Automatically flag tasks when priority is set to high
  isEnabled: true
  isBuiltIn: true
  triggerType: priority_changed
  triggerValue: high
  conditions:
    - property: priority
      operator: equals
      value: high
  conditionLogic: all
  actions:
    - id: 87654321-4321-4321-4321-210987654321
      type: flag
  created: 2025-11-18T00:00:00Z
  modified: 2025-11-18T00:00:00Z
  triggerCount: 0
```

### API Integration

For programmatic access:

```swift
// Add a rule
let rule = Rule(
    name: "My Rule",
    triggerType: .taskCreated,
    actions: [RuleAction(type: .flag)]
)
taskStore.addRule(rule)

// Evaluate rules for a change
let context = TaskChangeContext.taskCreated(task)
let modifiedTask = taskStore.evaluateAutomationRules(for: context, task: task)

// Get statistics
let stats = taskStore.getRuleStatistics()
print("Total triggers: \(stats.totalTriggers)")
```

### Extending the Rules Engine

The rules engine is designed to be extensible. To add new triggers or actions:

1. Add new case to `TriggerType` or `ActionType` enum
2. Implement evaluation logic in `RulesEngine.evaluateRules()`
3. Add UI support in `RuleBuilderView`
4. Update tests in `RulesEngineTests`

## Troubleshooting

### Rule Not Triggering

**Symptoms**: Rule exists but doesn't seem to execute

**Checklist**:
- [ ] Is the rule enabled?
- [ ] Does the trigger type match the event?
- [ ] Do the conditions match the task?
- [ ] Check condition logic (ALL vs ANY)
- [ ] Review rule statistics - has it triggered before?

### Unexpected Behavior

**Symptoms**: Rule triggers but produces wrong results

**Checklist**:
- [ ] Check action values (correct status/priority strings?)
- [ ] Review action order (do they conflict?)
- [ ] Check for multiple matching rules
- [ ] Verify condition operators (equals vs contains)

### Performance Issues

**Symptoms**: App slows down with many rules

**Solutions**:
- Disable unused rules
- Combine similar rules where possible
- Use specific conditions to reduce matches
- Avoid circular rule dependencies

## Support

For questions, issues, or feature requests related to automation rules:

1. Check the [Built-in Templates](#built-in-templates) for examples
2. Review the [Rule Examples](#rule-examples) section
3. Enable debug logging to see rule evaluation details
4. File an issue on GitHub with rule configuration details

## Future Enhancements

Planned improvements to the automation rules engine:

- [ ] **Scheduled Rules**: Trigger rules at specific times/dates
- [ ] **Batch Actions**: Process multiple tasks at once
- [ ] **Custom Scripts**: Execute custom JavaScript/AppleScript
- [ ] **Rule Chaining**: One rule triggers another
- [ ] **Undo Support**: Undo automatic changes
- [ ] **Import/Export**: Share rule configurations
- [ ] **Rule Groups**: Organize rules into categories
- [ ] **Testing Mode**: Preview rule effects before applying

---

**Version**: 1.0
**Last Updated**: November 18, 2025
**Related Documentation**: [GTD Methodology](GTD.md), [Quick Capture](QUICK_CAPTURE.md)
