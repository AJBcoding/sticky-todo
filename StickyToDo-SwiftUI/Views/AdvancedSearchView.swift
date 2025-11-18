//
//  AdvancedSearchView.swift
//  StickyToDo
//
//  Advanced search with visual filter builder.
//

import SwiftUI

/// Advanced search view with visual filter builder
struct AdvancedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var filterRules: [FilterRule] = []
    @State private var filterLogic: FilterLogic = .and
    @State private var showingSaveDialog = false
    @State private var perspectiveName = ""
    @State private var selectedProperty: FilterProperty = .title
    @State private var selectedOperator: FilterOperator = .contains
    @State private var filterValue = ""

    // Mock data for preview - in real app this would come from TaskStore
    @State private var tasks: [Task] = []
    @State private var recentSearches: [SmartPerspective] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick search bar
                searchBar

                Divider()

                // Filter builder
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Logic toggle
                        if filterRules.count > 1 {
                            logicToggle
                        }

                        // Filter rules
                        ForEach(Array(filterRules.enumerated()), id: \.element.id) { index, rule in
                            FilterRuleRow(
                                rule: rule,
                                onDelete: {
                                    filterRules.remove(at: index)
                                },
                                onChange: { newRule in
                                    filterRules[index] = newRule
                                }
                            )
                        }

                        // Add filter button
                        Button(action: addFilter) {
                            Label("Add Filter", systemImage: "plus.circle.fill")
                                .font(.body)
                        }
                        .buttonStyle(.borderless)
                        .padding(.horizontal)

                        // Results preview
                        resultsPreview

                        // Recent searches
                        if !recentSearches.isEmpty {
                            recentSearchesSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Advanced Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save as Perspective") {
                        showingSaveDialog = true
                    }
                    .disabled(filterRules.isEmpty)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Clear All") {
                        filterRules.removeAll()
                        searchText = ""
                    }
                    .disabled(filterRules.isEmpty && searchText.isEmpty)
                }
            }
            .sheet(isPresented: $showingSaveDialog) {
                savePerspectiveDialog
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search tasks...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.textBackgroundColor))
    }

    private var logicToggle: some View {
        HStack {
            Text("Match")
                .foregroundColor(.secondary)

            Picker("Logic", selection: $filterLogic) {
                Text("All").tag(FilterLogic.and)
                Text("Any").tag(FilterLogic.or)
            }
            .pickerStyle(.segmented)
            .frame(width: 150)

            Text("of the following conditions:")
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal)
    }

    private var resultsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.secondary)
                Text("Results Preview")
                    .font(.headline)
                Spacer()
                Text("\(filteredTasks.count) tasks")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            if filteredTasks.isEmpty {
                Text("No tasks match these criteria")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(filteredTasks.prefix(5)) { task in
                        TaskPreviewRow(task: task)
                    }

                    if filteredTasks.count > 5 {
                        Text("+ \(filteredTasks.count - 5) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Recent Searches")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            ForEach(recentSearches.prefix(3)) { perspective in
                Button(action: {
                    loadPerspective(perspective)
                }) {
                    HStack {
                        if let icon = perspective.icon {
                            Text(icon)
                        }
                        Text(perspective.name)
                        Spacer()
                        Text("\(perspective.rules.count) filters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var savePerspectiveDialog: some View {
        VStack(spacing: 20) {
            Text("Save as Smart Perspective")
                .font(.title2)
                .fontWeight(.bold)

            TextField("Perspective Name", text: $perspectiveName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showingSaveDialog = false
                    perspectiveName = ""
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Save") {
                    savePerspective()
                }
                .keyboardShortcut(.return)
                .disabled(perspectiveName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private var filteredTasks: [Task] {
        let perspective = SmartPerspective(
            name: "Search",
            rules: filterRules,
            logic: filterLogic
        )

        var results = perspective.apply(to: tasks)

        // Apply text search if present using SearchManager for better results
        if !searchText.isEmpty {
            let searchResults = SearchManager.search(tasks: results, queryString: searchText)
            results = searchResults.map { $0.task }
        }

        return results
    }

    private func addFilter() {
        let newRule = FilterRule(
            property: .title,
            operatorType: .contains,
            value: .string("")
        )
        filterRules.append(newRule)
    }

    private func loadPerspective(_ perspective: SmartPerspective) {
        filterRules = perspective.rules
        filterLogic = perspective.logic
    }

    private func savePerspective() {
        let perspective = SmartPerspective(
            name: perspectiveName,
            rules: filterRules,
            logic: filterLogic
        )

        // In real app, save to TaskStore
        // taskStore.addSmartPerspective(perspective)

        recentSearches.insert(perspective, at: 0)
        showingSaveDialog = false
        perspectiveName = ""
    }
}

/// Row for displaying and editing a filter rule
struct FilterRuleRow: View {
    let rule: FilterRule
    let onDelete: () -> Void
    let onChange: (FilterRule) -> Void

    @State private var selectedProperty: FilterProperty
    @State private var selectedOperator: FilterOperator
    @State private var stringValue: String
    @State private var numberValue: Int
    @State private var dateValue: Date
    @State private var booleanValue: Bool
    @State private var dateRangeValue: DateRange

    init(rule: FilterRule, onDelete: @escaping () -> Void, onChange: @escaping (FilterRule) -> Void) {
        self.rule = rule
        self.onDelete = onDelete
        self.onChange = onChange

        _selectedProperty = State(initialValue: rule.property)
        _selectedOperator = State(initialValue: rule.operatorType)

        // Initialize values based on the rule's value
        switch rule.value {
        case .string(let str):
            _stringValue = State(initialValue: str)
            _numberValue = State(initialValue: 0)
            _dateValue = State(initialValue: Date())
            _booleanValue = State(initialValue: false)
            _dateRangeValue = State(initialValue: .today)
        case .number(let num):
            _stringValue = State(initialValue: "")
            _numberValue = State(initialValue: num)
            _dateValue = State(initialValue: Date())
            _booleanValue = State(initialValue: false)
            _dateRangeValue = State(initialValue: .today)
        case .date(let date):
            _stringValue = State(initialValue: "")
            _numberValue = State(initialValue: 0)
            _dateValue = State(initialValue: date)
            _booleanValue = State(initialValue: false)
            _dateRangeValue = State(initialValue: .today)
        case .boolean(let bool):
            _stringValue = State(initialValue: "")
            _numberValue = State(initialValue: 0)
            _dateValue = State(initialValue: Date())
            _booleanValue = State(initialValue: bool)
            _dateRangeValue = State(initialValue: .today)
        case .dateRange(let range):
            _stringValue = State(initialValue: "")
            _numberValue = State(initialValue: 0)
            _dateValue = State(initialValue: Date())
            _booleanValue = State(initialValue: false)
            _dateRangeValue = State(initialValue: range)
        case .stringArray:
            _stringValue = State(initialValue: "")
            _numberValue = State(initialValue: 0)
            _dateValue = State(initialValue: Date())
            _booleanValue = State(initialValue: false)
            _dateRangeValue = State(initialValue: .today)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Property picker
            Picker("Property", selection: $selectedProperty) {
                ForEach(FilterProperty.allCases, id: \.self) { property in
                    Text(property.displayName).tag(property)
                }
            }
            .frame(width: 150)
            .onChange(of: selectedProperty) { _ in updateRule() }

            // Operator picker
            Picker("Operator", selection: $selectedOperator) {
                ForEach(availableOperators, id: \.self) { op in
                    Text(op.displayName).tag(op)
                }
            }
            .frame(width: 150)
            .onChange(of: selectedOperator) { _ in updateRule() }

            // Value input
            valueInput
                .frame(minWidth: 150)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var valueInput: some View {
        switch selectedProperty {
        case .title, .notes, .project, .context:
            TextField("Value", text: $stringValue)
                .textFieldStyle(.roundedBorder)
                .onChange(of: stringValue) { _ in updateRule() }

        case .effort:
            TextField("Minutes", value: $numberValue, format: .number)
                .textFieldStyle(.roundedBorder)
                .onChange(of: numberValue) { _ in updateRule() }

        case .dueDate, .deferDate, .createdDate, .modifiedDate:
            if selectedOperator == .isWithin {
                Picker("Range", selection: $dateRangeValue) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .onChange(of: dateRangeValue) { _ in updateRule() }
            } else if selectedOperator == .isEmpty || selectedOperator == .isNotEmpty {
                Text("(no value needed)")
                    .foregroundColor(.secondary)
            } else {
                DatePicker("Date", selection: $dateValue, displayedComponents: .date)
                    .labelsHidden()
                    .onChange(of: dateValue) { _ in updateRule() }
            }

        case .status:
            Picker("Status", selection: $stringValue) {
                ForEach(["inbox", "nextAction", "waiting", "someday", "completed"], id: \.self) { status in
                    Text(status).tag(status)
                }
            }
            .onChange(of: stringValue) { _ in updateRule() }

        case .priority:
            Picker("Priority", selection: $stringValue) {
                Text("High").tag("high")
                Text("Medium").tag("medium")
                Text("Low").tag("low")
            }
            .onChange(of: stringValue) { _ in updateRule() }

        case .flagged, .hasSubtasks, .isSubtask, .hasAttachments:
            Toggle("", isOn: $booleanValue)
                .labelsHidden()
                .onChange(of: booleanValue) { _ in updateRule() }

        case .tags:
            TextField("Tag names (comma separated)", text: $stringValue)
                .textFieldStyle(.roundedBorder)
                .onChange(of: stringValue) { _ in updateRule() }
        }
    }

    private var availableOperators: [FilterOperator] {
        switch selectedProperty {
        case .title, .notes, .project, .context:
            return [.contains, .notContains, .equals, .notEquals, .startsWith, .endsWith, .isEmpty, .isNotEmpty]
        case .effort:
            return [.lessThan, .lessThanOrEqual, .greaterThan, .greaterThanOrEqual, .equals, .notEquals, .isEmpty, .isNotEmpty]
        case .dueDate, .deferDate, .createdDate, .modifiedDate:
            return [.isWithin, .lessThan, .lessThanOrEqual, .greaterThan, .greaterThanOrEqual, .isEmpty, .isNotEmpty]
        case .status, .priority:
            return [.equals, .notEquals]
        case .flagged, .hasSubtasks, .isSubtask, .hasAttachments:
            return [.isTrue, .isFalse]
        case .tags:
            return [.contains, .notContains, .isEmpty, .isNotEmpty]
        }
    }

    private func updateRule() {
        let newValue: FilterValue

        switch selectedProperty {
        case .title, .notes, .project, .context, .status, .priority:
            newValue = .string(stringValue)
        case .effort:
            newValue = .number(numberValue)
        case .dueDate, .deferDate, .createdDate, .modifiedDate:
            if selectedOperator == .isWithin {
                newValue = .dateRange(dateRangeValue)
            } else {
                newValue = .date(dateValue)
            }
        case .flagged, .hasSubtasks, .isSubtask, .hasAttachments:
            newValue = .boolean(booleanValue)
        case .tags:
            let tagArray = stringValue.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            newValue = .stringArray(tagArray)
        }

        let updatedRule = FilterRule(
            id: rule.id,
            property: selectedProperty,
            operatorType: selectedOperator,
            value: newValue
        )

        onChange(updatedRule)
    }
}

/// Simple task preview row
struct TaskPreviewRow: View {
    let task: Task

    var body: some View {
        HStack {
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.status == .completed ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)

                HStack(spacing: 8) {
                    if let project = task.project {
                        Text(project)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let context = task.context {
                        Text(context)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if task.flagged {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct AdvancedSearchView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSearchView()
    }
}
