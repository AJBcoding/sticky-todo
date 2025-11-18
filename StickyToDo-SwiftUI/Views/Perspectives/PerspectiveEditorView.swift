//
//  PerspectiveEditorView.swift
//  StickyToDo-SwiftUI
//
//  Comprehensive editor for creating and modifying smart perspectives.
//

import SwiftUI

/// Full-featured editor for smart perspectives
///
/// Features:
/// - Create new or edit existing perspectives
/// - Add/remove/modify filter rules
/// - Configure grouping and sorting
/// - Set visibility options
/// - Icon and color customization
/// - Export/Import perspectives
struct PerspectiveEditorView: View {

    // MARK: - Properties

    /// Perspective being edited (nil for new)
    let perspective: SmartPerspective?

    /// Callback when save is requested
    let onSave: (SmartPerspective) -> Void

    /// Callback when cancelled
    let onCancel: () -> Void

    /// Callback for exporting perspective
    let onExport: ((SmartPerspective) -> Void)?

    // MARK: - State

    @State private var name: String
    @State private var description: String
    @State private var icon: String
    @State private var color: String
    @State private var rules: [FilterRule]
    @State private var logic: FilterLogic
    @State private var groupBy: GroupBy
    @State private var sortBy: SortBy
    @State private var sortDirection: SortDirection
    @State private var showCompleted: Bool
    @State private var showDeferred: Bool

    @State private var showIconPicker = false
    @State private var showRuleEditor = false
    @State private var editingRule: FilterRule?
    @State private var editingRuleIndex: Int?

    // MARK: - Initialization

    init(
        perspective: SmartPerspective? = nil,
        onSave: @escaping (SmartPerspective) -> Void,
        onCancel: @escaping () -> Void,
        onExport: ((SmartPerspective) -> Void)? = nil
    ) {
        self.perspective = perspective
        self.onSave = onSave
        self.onCancel = onCancel
        self.onExport = onExport

        // Initialize state from perspective or defaults
        _name = State(initialValue: perspective?.name ?? "")
        _description = State(initialValue: perspective?.description ?? "")
        _icon = State(initialValue: perspective?.icon ?? "⭐")
        _color = State(initialValue: perspective?.color ?? "#007AFF")
        _rules = State(initialValue: perspective?.rules ?? [])
        _logic = State(initialValue: perspective?.logic ?? .and)
        _groupBy = State(initialValue: perspective?.groupBy ?? .none)
        _sortBy = State(initialValue: perspective?.sortBy ?? .created)
        _sortDirection = State(initialValue: perspective?.sortDirection ?? .ascending)
        _showCompleted = State(initialValue: perspective?.showCompleted ?? false)
        _showDeferred = State(initialValue: perspective?.showDeferred ?? false)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Editor Form
            editorForm

            Divider()

            // Footer
            footerView
        }
        .frame(minWidth: 700, minHeight: 600)
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(selectedIcon: $icon, icons: commonIcons)
        }
        .sheet(isPresented: $showRuleEditor) {
            if let editingRule = editingRule, let index = editingRuleIndex {
                FilterRuleEditorView(
                    rule: editingRule,
                    onSave: { updatedRule in
                        rules[index] = updatedRule
                        showRuleEditor = false
                    },
                    onCancel: {
                        showRuleEditor = false
                    }
                )
            } else {
                FilterRuleEditorView(
                    rule: nil,
                    onSave: { newRule in
                        rules.append(newRule)
                        showRuleEditor = false
                    },
                    onCancel: {
                        showRuleEditor = false
                    }
                )
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Text(perspective == nil ? "New Perspective" : "Edit Perspective")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if let onExport = onExport, perspective != nil {
                Button {
                    exportPerspective()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }

            Button("Cancel") {
                onCancel()
            }
            .keyboardShortcut(.cancelAction)

            Button("Save") {
                savePerspective()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(name.isEmpty)
        }
        .padding()
    }

    private var editorForm: some View {
        Form {
            // Basic Information
            Section("Basic Information") {
                TextField("Perspective Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                TextField("Description (optional)", text: $description)
                    .textFieldStyle(.roundedBorder)

                // Icon and Color
                HStack(spacing: 20) {
                    // Icon
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Icon")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button {
                            showIconPicker = true
                        } label: {
                            Text(icon)
                                .font(.largeTitle)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }

                    // Color
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Color")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ColorPicker("", selection: Binding(
                            get: { Color(hex: color) },
                            set: { color = $0.toHex() }
                        ))
                        .labelsHidden()
                        .frame(width: 60, height: 60)
                    }
                }
            }

            // Filter Rules
            Section {
                // Logic
                Picker("Match", selection: $logic) {
                    Text("ALL rules (AND)").tag(FilterLogic.and)
                    Text("ANY rule (OR)").tag(FilterLogic.or)
                }
                .pickerStyle(.segmented)

                // Rules list
                if rules.isEmpty {
                    HStack {
                        Text("No filter rules")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ruleDescription(rule))
                                    .font(.body)
                                Text(rule.property.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                editRule(at: index)
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.plain)

                            Button {
                                rules.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button {
                    addRule()
                } label: {
                    Label("Add Rule", systemImage: "plus.circle")
                }
            } header: {
                Text("Filter Rules")
            }

            // Display Options
            Section("Display Options") {
                // Grouping
                Picker("Group by", selection: $groupBy) {
                    ForEach(GroupBy.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }

                // Sorting
                HStack {
                    Picker("Sort by", selection: $sortBy) {
                        ForEach(SortBy.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }

                    Picker("", selection: $sortDirection) {
                        Text("Ascending").tag(SortDirection.ascending)
                        Text("Descending").tag(SortDirection.descending)
                    }
                    .labelsHidden()
                    .frame(width: 130)
                }

                // Visibility toggles
                Toggle("Show completed tasks", isOn: $showCompleted)
                Toggle("Show deferred tasks", isOn: $showDeferred)
            }
        }
        .formStyle(.grouped)
    }

    private var footerView: some View {
        HStack {
            if !rules.isEmpty {
                Text("\(rules.count) rule\(rules.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private func ruleDescription(_ rule: FilterRule) -> String {
        let op = rule.operatorType.displayName
        let value = valueDescription(rule.value)
        return "\(op) \(value)"
    }

    private func valueDescription(_ value: FilterValue) -> String {
        switch value {
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return "\(num)"
        case .date(let date):
            return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
        case .boolean(let bool):
            return bool ? "true" : "false"
        case .dateRange(let range):
            return range.displayName
        case .stringArray(let arr):
            return arr.joined(separator: ", ")
        }
    }

    private func addRule() {
        editingRule = nil
        editingRuleIndex = nil
        showRuleEditor = true
    }

    private func editRule(at index: Int) {
        editingRule = rules[index]
        editingRuleIndex = index
        showRuleEditor = true
    }

    private func savePerspective() {
        let updatedPerspective = SmartPerspective(
            id: perspective?.id ?? UUID(),
            name: name,
            description: description.isEmpty ? nil : description,
            rules: rules,
            logic: logic,
            groupBy: groupBy,
            sortBy: sortBy,
            sortDirection: sortDirection,
            showCompleted: showCompleted,
            showDeferred: showDeferred,
            icon: icon,
            color: color,
            isBuiltIn: false,
            created: perspective?.created ?? Date(),
            modified: Date()
        )

        onSave(updatedPerspective)
    }

    private func exportPerspective() {
        guard let onExport = onExport, let perspective = perspective else { return }

        let updatedPerspective = SmartPerspective(
            id: perspective.id,
            name: name,
            description: description.isEmpty ? nil : description,
            rules: rules,
            logic: logic,
            groupBy: groupBy,
            sortBy: sortBy,
            sortDirection: sortDirection,
            showCompleted: showCompleted,
            showDeferred: showDeferred,
            icon: icon,
            color: color,
            isBuiltIn: false,
            created: perspective.created,
            modified: Date()
        )

        onExport(updatedPerspective)
    }

    private let commonIcons = [
        "⭐", "🎯", "🔥", "💡", "✅", "📌", "🚀",
        "⚡", "💪", "🎨", "📊", "🔍", "📝", "⏰",
        "🌟", "🎓", "🏆", "💼", "📱", "💻", "🏠",
        "☀️", "🌙", "💎", "🎪", "🎭", "🎬", "📷"
    ]
}

// MARK: - Filter Rule Editor View

struct FilterRuleEditorView: View {
    let rule: FilterRule?
    let onSave: (FilterRule) -> Void
    let onCancel: () -> Void

    @State private var property: FilterProperty
    @State private var operatorType: FilterOperator
    @State private var stringValue: String
    @State private var numberValue: Int
    @State private var boolValue: Bool
    @State private var dateValue: Date
    @State private var dateRangeValue: DateRange

    init(rule: FilterRule?, onSave: @escaping (FilterRule) -> Void, onCancel: @escaping () -> Void) {
        self.rule = rule
        self.onSave = onSave
        self.onCancel = onCancel

        _property = State(initialValue: rule?.property ?? .status)
        _operatorType = State(initialValue: rule?.operatorType ?? .equals)
        _stringValue = State(initialValue: {
            if case .string(let str) = rule?.value {
                return str
            }
            return ""
        }())
        _numberValue = State(initialValue: {
            if case .number(let num) = rule?.value {
                return num
            }
            return 30
        }())
        _boolValue = State(initialValue: {
            if case .boolean(let bool) = rule?.value {
                return bool
            }
            return true
        }())
        _dateValue = State(initialValue: {
            if case .date(let date) = rule?.value {
                return date
            }
            return Date()
        }())
        _dateRangeValue = State(initialValue: {
            if case .dateRange(let range) = rule?.value {
                return range
            }
            return .today
        }())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(rule == nil ? "New Rule" : "Edit Rule")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveRule()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            // Editor
            Form {
                Picker("Property", selection: $property) {
                    ForEach(FilterProperty.allCases, id: \.self) { prop in
                        Text(prop.displayName).tag(prop)
                    }
                }

                Picker("Operator", selection: $operatorType) {
                    ForEach(availableOperators, id: \.self) { op in
                        Text(op.displayName).tag(op)
                    }
                }

                // Value input (type depends on property and operator)
                if needsValueInput {
                    valueInputView
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 450, height: 400)
    }

    @ViewBuilder
    private var valueInputView: some View {
        switch propertyValueType {
        case .string:
            TextField("Value", text: $stringValue)
                .textFieldStyle(.roundedBorder)

        case .number:
            Stepper("Value: \(numberValue)", value: $numberValue, in: 0...9999)

        case .boolean:
            Toggle("Value", isOn: $boolValue)

        case .date:
            DatePicker("Value", selection: $dateValue, displayedComponents: .date)

        case .dateRange:
            Picker("Date Range", selection: $dateRangeValue) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
        }
    }

    private var needsValueInput: Bool {
        ![.isEmpty, .isNotEmpty, .isTrue, .isFalse].contains(operatorType)
    }

    private var propertyValueType: PropertyValueType {
        switch property {
        case .title, .notes, .context, .project, .status, .priority, .tags:
            return .string
        case .effort:
            return .number
        case .flagged, .hasSubtasks, .isSubtask, .hasAttachments:
            return .boolean
        case .dueDate, .deferDate, .createdDate, .modifiedDate:
            return operatorType == .isWithin ? .dateRange : .date
        }
    }

    private var availableOperators: [FilterOperator] {
        switch property {
        case .title, .notes, .context, .project, .tags:
            return [.contains, .notContains, .equals, .notEquals, .startsWith, .endsWith, .isEmpty, .isNotEmpty]
        case .status, .priority:
            return [.equals, .notEquals]
        case .effort:
            return [.equals, .notEquals, .lessThan, .lessThanOrEqual, .greaterThan, .greaterThanOrEqual, .isEmpty, .isNotEmpty]
        case .dueDate, .deferDate, .createdDate, .modifiedDate:
            return [.isEmpty, .isNotEmpty, .isWithin, .lessThan, .lessThanOrEqual, .greaterThan, .greaterThanOrEqual]
        case .flagged, .hasSubtasks, .isSubtask, .hasAttachments:
            return [.isTrue, .isFalse]
        }
    }

    private func saveRule() {
        let value: FilterValue
        switch propertyValueType {
        case .string:
            value = .string(stringValue)
        case .number:
            value = .number(numberValue)
        case .boolean:
            value = .boolean(boolValue)
        case .date:
            value = .date(dateValue)
        case .dateRange:
            value = .dateRange(dateRangeValue)
        }

        let newRule = FilterRule(
            id: rule?.id ?? UUID(),
            property: property,
            operatorType: operatorType,
            value: value
        )

        onSave(newRule)
    }

    private enum PropertyValueType {
        case string
        case number
        case boolean
        case date
        case dateRange
    }
}

// MARK: - Color Extensions

extension Color {
    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Preview

#Preview("Editor") {
    PerspectiveEditorView(
        perspective: SmartPerspective.todaysFocus,
        onSave: { _ in },
        onCancel: { }
    )
}
