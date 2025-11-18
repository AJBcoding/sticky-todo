//
//  RulesEditorView.swift
//  StickyToDo-SwiftUI
//
//  View for managing automation rules.
//

import SwiftUI

/// Main view for managing automation rules
struct RulesEditorView: View {
    @ObservedObject var taskStore: TaskStore
    @State private var rules: [Rule] = []
    @State private var selectedRule: Rule?
    @State private var showingRuleBuilder = false
    @State private var ruleToEdit: Rule?
    @State private var showingDeleteAlert = false
    @State private var ruleToDelete: Rule?
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            // Sidebar - List of rules
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search rules...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .padding()

                // Rules list
                List(selection: $selectedRule) {
                    Section(header: Text("Built-in Templates")) {
                        ForEach(builtInRules) { rule in
                            RuleRowView(rule: rule, taskStore: taskStore)
                                .tag(rule as Rule?)
                        }
                    }

                    if !customRules.isEmpty {
                        Section(header: Text("Custom Rules")) {
                            ForEach(customRules) { rule in
                                RuleRowView(rule: rule, taskStore: taskStore)
                                    .tag(rule as Rule?)
                                    .contextMenu {
                                        Button("Edit") {
                                            editRule(rule)
                                        }
                                        Button("Duplicate") {
                                            duplicateRule(rule)
                                        }
                                        Divider()
                                        Button("Delete", role: .destructive) {
                                            ruleToDelete = rule
                                            showingDeleteAlert = true
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)

                // Bottom toolbar
                HStack {
                    Button(action: createNewRule) {
                        Label("New Rule", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    Button(action: loadBuiltInTemplates) {
                        Label("Add Templates", systemImage: "square.stack.3d.up")
                    }
                    .buttonStyle(.borderless)
                    .help("Load built-in rule templates")
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
            .frame(minWidth: 300, idealWidth: 350)

            // Detail view
            if let rule = selectedRule {
                RuleDetailView(rule: rule, taskStore: taskStore, onEdit: {
                    editRule(rule)
                }, onDelete: {
                    ruleToDelete = rule
                    showingDeleteAlert = true
                })
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "gear.badge.questionmark")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a rule to view details")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Automation rules help you automatically organize and manage your tasks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Automation Rules")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: createNewRule) {
                    Label("New Rule", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingRuleBuilder) {
            RuleBuilderView(taskStore: taskStore, rule: ruleToEdit)
        }
        .alert("Delete Rule", isPresented: $showingDeleteAlert, presenting: ruleToDelete) { rule in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRule(rule)
            }
        } message: { rule in
            Text("Are you sure you want to delete '\(rule.name)'? This action cannot be undone.")
        }
        .onAppear {
            loadRules()
        }
    }

    // MARK: - Computed Properties

    private var filteredRules: [Rule] {
        if searchText.isEmpty {
            return rules
        }
        return rules.filter { rule in
            rule.name.localizedCaseInsensitiveContains(searchText) ||
            (rule.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var builtInRules: [Rule] {
        filteredRules.filter { $0.isBuiltIn }
    }

    private var customRules: [Rule] {
        filteredRules.filter { !$0.isBuiltIn }
    }

    // MARK: - Actions

    private func loadRules() {
        rules = taskStore.automationRules
    }

    private func createNewRule() {
        ruleToEdit = nil
        showingRuleBuilder = true
    }

    private func editRule(_ rule: Rule) {
        ruleToEdit = rule
        showingRuleBuilder = true
    }

    private func duplicateRule(_ rule: Rule) {
        let duplicate = rule.duplicate()
        taskStore.addRule(duplicate)
        loadRules()
    }

    private func deleteRule(_ rule: Rule) {
        taskStore.removeRule(rule)
        if selectedRule?.id == rule.id {
            selectedRule = nil
        }
        loadRules()
    }

    private func loadBuiltInTemplates() {
        taskStore.loadBuiltInRuleTemplates()
        loadRules()
    }
}

// MARK: - Rule Row View

struct RuleRowView: View {
    let rule: Rule
    @ObservedObject var taskStore: TaskStore

    var body: some View {
        HStack(spacing: 12) {
            // Enabled indicator
            Circle()
                .fill(rule.isEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.body)

                HStack(spacing: 4) {
                    Text(rule.triggerType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if rule.actions.count > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(rule.actions.count) action\(rule.actions.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Built-in badge
            if rule.isBuiltIn {
                Text("Built-in")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }

            // Toggle
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in taskStore.toggleRule(rule) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Rule Detail View

struct RuleDetailView: View {
    let rule: Rule
    @ObservedObject var taskStore: TaskStore
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(rule.name)
                            .font(.title)

                        Spacer()

                        if rule.isBuiltIn {
                            Text("Built-in Template")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }

                    if let description = rule.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        Label(rule.isEnabled ? "Enabled" : "Disabled", systemImage: rule.isEnabled ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(rule.isEnabled ? .green : .gray)
                            .font(.caption)

                        Text("•")
                            .foregroundColor(.secondary)

                        if let lastTriggered = rule.lastTriggered {
                            Text("Last triggered: \(lastTriggered, style: .relative) ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never triggered")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("•")
                            .foregroundColor(.secondary)

                        Text("\(rule.triggerCount) times")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Trigger
                VStack(alignment: .leading, spacing: 8) {
                    Label("Trigger", systemImage: "bolt.fill")
                        .font(.headline)

                    HStack {
                        Text("When:")
                            .foregroundColor(.secondary)
                        Text(rule.triggerType.displayName)
                            .fontWeight(.medium)

                        if let triggerValue = rule.triggerValue {
                            Text("=")
                                .foregroundColor(.secondary)
                            Text(triggerValue)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Conditions
                if !rule.conditions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Conditions", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.headline)

                        Text("Match \(rule.conditionLogic.displayName.lowercased()) of the following:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            ForEach(Array(rule.conditions.enumerated()), id: \.offset) { index, condition in
                                HStack {
                                    Text("\(index + 1).")
                                        .foregroundColor(.secondary)
                                    Text(condition.property.displayName)
                                    Text(condition.operator.displayName)
                                        .foregroundColor(.secondary)
                                    Text(condition.value)
                                        .fontWeight(.medium)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                // Actions
                VStack(alignment: .leading, spacing: 8) {
                    Label("Actions", systemImage: "play.fill")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(Array(rule.actions.enumerated()), id: \.element.id) { index, action in
                            HStack {
                                Text("\(index + 1).")
                                    .foregroundColor(.secondary)
                                Text(action.type.displayName)
                                    .fontWeight(.medium)

                                if let value = action.value {
                                    Text("→")
                                        .foregroundColor(.secondary)
                                    Text(value)
                                } else if let relativeDate = action.relativeDate {
                                    Text("→")
                                        .foregroundColor(.secondary)
                                    Text(relativeDate.displayString)
                                }

                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }

                Spacer()

                // Action buttons
                HStack {
                    if !rule.isBuiltIn {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(action: {
                        let duplicate = rule.duplicate()
                        taskStore.addRule(duplicate)
                    }) {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    if !rule.isBuiltIn {
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 400, idealWidth: 600)
    }
}

// MARK: - Preview

#if DEBUG
struct RulesEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let fileIO = MarkdownFileIO(rootDirectory: URL(fileURLWithPath: "/tmp/sticky-todo"))
        let taskStore = TaskStore(fileIO: fileIO)

        RulesEditorView(taskStore: taskStore)
            .frame(width: 900, height: 600)
    }
}
#endif
