//
//  RuleBuilderView.swift
//  StickyToDo-SwiftUI
//
//  View for creating and editing automation rules.
//

import SwiftUI

/// View for building/editing automation rules
struct RuleBuilderView: View {
    @ObservedObject var taskStore: TaskStore
    @Environment(\.dismiss) var dismiss

    // Rule being edited (nil for new rule)
    let rule: Rule?

    // Form fields
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isEnabled: Bool = true
    @State private var triggerType: TriggerType = .taskCreated
    @State private var triggerValue: String = ""
    @State private var conditionLogic: ConditionLogic = .all
    @State private var conditions: [RuleCondition] = []
    @State private var actions: [RuleAction] = []

    // UI state
    @State private var showingAddCondition = false
    @State private var showingAddAction = false
    @State private var validationErrors: [String] = []

    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section(header: Text("Basic Information")) {
                    TextField("Rule Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    TextField("Description (optional)", text: $description)
                        .textFieldStyle(.roundedBorder)

                    Toggle("Enabled", isOn: $isEnabled)
                }

                // Trigger
                Section(header: Text("Trigger")) {
                    Picker("When", selection: $triggerType) {
                        ForEach(TriggerType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    if triggerRequiresValue(triggerType) {
                        TextField("Value", text: $triggerValue)
                            .textFieldStyle(.roundedBorder)
                    }

                    Text(triggerType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Conditions
                Section(header: HStack {
                    Text("Conditions (Optional)")
                    Spacer()
                    Button(action: { showingAddCondition = true }) {
                        Label("Add", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderless)
                }) {
                    if conditions.isEmpty {
                        Text("No conditions - rule will apply to all tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Match", selection: $conditionLogic) {
                            Text("All").tag(ConditionLogic.all)
                            Text("Any").tag(ConditionLogic.any)
                        }
                        .pickerStyle(.segmented)

                        ForEach(Array(conditions.enumerated()), id: \.offset) { index, condition in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(condition.property.displayName)
                                        .fontWeight(.medium)
                                    Text("\(condition.operator.displayName) '\(condition.value)'")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(role: .destructive, action: {
                                    conditions.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Actions
                Section(header: HStack {
                    Text("Actions")
                    Spacer()
                    Button(action: { showingAddAction = true }) {
                        Label("Add", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderless)
                }) {
                    if actions.isEmpty {
                        Text("Add at least one action")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(action.type.displayName)
                                        .fontWeight(.medium)

                                    if let value = action.value {
                                        Text("Value: \(value)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else if let relativeDate = action.relativeDate {
                                        Text(relativeDate.displayString)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Button(role: .destructive, action: {
                                    actions.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Validation Errors
                if !validationErrors.isEmpty {
                    Section(header: Text("Errors")) {
                        ForEach(validationErrors, id: \.self) { error in
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(rule == nil ? "New Rule" : "Edit Rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRule()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingAddCondition) {
                AddConditionView(conditions: $conditions)
            }
            .sheet(isPresented: $showingAddAction) {
                AddActionView(actions: $actions)
            }
            .onAppear {
                loadRule()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        !name.isEmpty && !actions.isEmpty
    }

    // MARK: - Helper Methods

    private func triggerRequiresValue(_ trigger: TriggerType) -> Bool {
        switch trigger {
        case .statusChanged, .priorityChanged, .movedToBoard, .tagAdded, .projectSet, .contextSet:
            return true
        default:
            return false
        }
    }

    private func loadRule() {
        guard let rule = rule else { return }

        name = rule.name
        description = rule.description ?? ""
        isEnabled = rule.isEnabled
        triggerType = rule.triggerType
        triggerValue = rule.triggerValue ?? ""
        conditionLogic = rule.conditionLogic
        conditions = rule.conditions
        actions = rule.actions
    }

    private func saveRule() {
        // Validate
        validationErrors = []

        if name.isEmpty {
            validationErrors.append("Rule name is required")
        }

        if actions.isEmpty {
            validationErrors.append("At least one action is required")
        }

        if !validationErrors.isEmpty {
            return
        }

        // Create or update rule
        let savedRule = Rule(
            id: rule?.id ?? UUID(),
            name: name,
            description: description.isEmpty ? nil : description,
            isEnabled: isEnabled,
            isBuiltIn: false,
            triggerType: triggerType,
            triggerValue: triggerValue.isEmpty ? nil : triggerValue,
            conditions: conditions,
            conditionLogic: conditionLogic,
            actions: actions,
            created: rule?.created ?? Date(),
            modified: Date(),
            lastTriggered: rule?.lastTriggered,
            triggerCount: rule?.triggerCount ?? 0
        )

        if rule != nil {
            taskStore.updateRule(savedRule)
        } else {
            taskStore.addRule(savedRule)
        }

        dismiss()
    }
}

// MARK: - Add Condition View

struct AddConditionView: View {
    @Binding var conditions: [RuleCondition]
    @Environment(\.dismiss) var dismiss

    @State private var property: ConditionProperty = .status
    @State private var conditionOperator: ConditionOperator = .equals
    @State private var value: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Condition")) {
                    Picker("Property", selection: $property) {
                        ForEach(ConditionProperty.allCases, id: \.self) { prop in
                            Text(prop.displayName).tag(prop)
                        }
                    }

                    Picker("Operator", selection: $conditionOperator) {
                        ForEach(availableOperators, id: \.self) { op in
                            Text(op.displayName).tag(op)
                        }
                    }

                    if operatorRequiresValue(conditionOperator) {
                        TextField("Value", text: $value)
                            .textFieldStyle(.roundedBorder)

                        // Helper text for property
                        Text(propertyHelperText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Condition")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCondition()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 450, height: 300)
    }

    private var availableOperators: [ConditionOperator] {
        switch property {
        case .flagged, .hasProject, .hasContext, .hasDueDate, .isSubtask:
            return [.isTrue, .isFalse]
        case .title, .hasTag:
            return [.contains, .notContains, .equals, .notEquals]
        default:
            return [.equals, .notEquals]
        }
    }

    private var propertyHelperText: String {
        switch property {
        case .status:
            return "Values: inbox, next-action, waiting, someday, completed"
        case .priority:
            return "Values: high, medium, low"
        case .project, .context, .title, .hasTag:
            return "Enter the text to match"
        default:
            return ""
        }
    }

    private var isValid: Bool {
        if operatorRequiresValue(conditionOperator) {
            return !value.isEmpty
        }
        return true
    }

    private func operatorRequiresValue(_ op: ConditionOperator) -> Bool {
        switch op {
        case .isTrue, .isFalse:
            return false
        default:
            return true
        }
    }

    private func addCondition() {
        let condition = RuleCondition(
            property: property,
            operator: conditionOperator,
            value: value
        )
        conditions.append(condition)
        dismiss()
    }
}

// MARK: - Add Action View

struct AddActionView: View {
    @Binding var actions: [RuleAction]
    @Environment(\.dismiss) var dismiss

    @State private var actionType: ActionType = .setStatus
    @State private var value: String = ""
    @State private var relativeDateAmount: Int = 1
    @State private var relativeDateUnit: RelativeDateValue.DateUnit = .days

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Action")) {
                    Picker("Action Type", selection: $actionType) {
                        ForEach(ActionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Text(actionType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if usesRelativeDate {
                        Stepper("Amount: \(relativeDateAmount)", value: $relativeDateAmount, in: -365...365)

                        Picker("Unit", selection: $relativeDateUnit) {
                            ForEach(RelativeDateValue.DateUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue.capitalized).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    } else if actionType.requiresValue {
                        TextField("Value", text: $value)
                            .textFieldStyle(.roundedBorder)

                        // Helper text
                        Text(actionHelperText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Action")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addAction()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 450, height: 350)
    }

    private var usesRelativeDate: Bool {
        actionType == .setDueDate || actionType == .setDeferDate
    }

    private var isValid: Bool {
        if actionType.requiresValue && !usesRelativeDate {
            return !value.isEmpty
        }
        return true
    }

    private var actionHelperText: String {
        switch actionType {
        case .setStatus:
            return "Values: inbox, next-action, waiting, someday, completed"
        case .setPriority:
            return "Values: high, medium, low"
        case .setContext, .setProject, .addTag:
            return "Enter the text value"
        case .moveToBoard:
            return "Enter the board ID"
        case .sendNotification:
            return "Enter the notification message"
        default:
            return ""
        }
    }

    private func addAction() {
        let action: RuleAction
        if usesRelativeDate {
            action = RuleAction(
                type: actionType,
                relativeDate: RelativeDateValue(amount: relativeDateAmount, unit: relativeDateUnit)
            )
        } else {
            action = RuleAction(
                type: actionType,
                value: value.isEmpty ? nil : value
            )
        }
        actions.append(action)
        dismiss()
    }
}

// MARK: - Preview

#if DEBUG
struct RuleBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        let fileIO = MarkdownFileIO(rootDirectory: URL(fileURLWithPath: "/tmp/sticky-todo"))
        let taskStore = TaskStore(fileIO: fileIO)

        RuleBuilderView(taskStore: taskStore, rule: nil)
    }
}
#endif
