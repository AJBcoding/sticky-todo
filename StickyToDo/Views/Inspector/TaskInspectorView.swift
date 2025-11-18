//
//  TaskInspectorView.swift
//  StickyToDo
//
//  Inspector panel for editing task metadata and details.
//

import SwiftUI

/// Inspector panel showing detailed task information and metadata
///
/// Features:
/// - Form-based editing interface
/// - All metadata fields (status, priority, context, dates, effort)
/// - Notes editor with TextEditor
/// - Projects and tags management
/// - "Appears on Boards" section
/// - Delete and duplicate buttons
/// - Auto-save with .onChange modifiers
struct TaskInspectorView: View {

    // MARK: - Properties

    /// The task being inspected (nil if no selection)
    @Binding var task: Task?

    /// All available contexts
    let contexts: [Context]

    /// All available boards
    let boards: [Board]

    /// Callback when task should be deleted
    var onDelete: () -> Void

    /// Callback when task should be duplicated
    var onDuplicate: () -> Void

    /// Callback when task is modified
    var onTaskModified: () -> Void

    // MARK: - State

    @State private var editedTitle: String = ""
    @State private var editedNotes: String = ""
    @State private var showingDeleteAlert = false

    // MARK: - Body

    var body: some View {
        Group {
            if let task = task {
                inspectorContent(for: task)
            } else {
                emptyState
            }
        }
        .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Inspector Content

    @ViewBuilder
    private func inspectorContent(for task: Task) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title field
                titleSection(task: task)

                // Status and Priority
                statusPrioritySection(task: task)

                // Dates
                datesSection(task: task)

                // Context and Project
                contextProjectSection(task: task)

                // Effort estimate
                effortSection(task: task)

                // Color picker
                colorSection(task: task)

                // Recurrence
                recurrenceSection(task: task)

                // Notes
                notesSection(task: task)

                // Appears on boards
                boardsSection(task: task)

                Divider()

                // Actions
                actionsSection
            }
            .padding()
        }
    }

    // MARK: - Title Section

    private func titleSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("Task title", text: binding(for: \.title))
                .textFieldStyle(.roundedBorder)
                .onChange(of: task.title) { _ in
                    onTaskModified()
                }
        }
    }

    // MARK: - Status and Priority Section

    private func statusPrioritySection(task: Task) -> some View {
        VStack(spacing: 12) {
            // Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Status", selection: binding(for: \.status)) {
                    Text("Inbox").tag(Status.inbox)
                    Text("Next Action").tag(Status.nextAction)
                    Text("Waiting").tag(Status.waiting)
                    Text("Someday").tag(Status.someday)
                    Text("Completed").tag(Status.completed)
                }
                .pickerStyle(.segmented)
                .onChange(of: task.status) { _ in
                    onTaskModified()
                }
            }

            // Priority
            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Priority", selection: binding(for: \.priority)) {
                    Text("Low").tag(Priority.low)
                    Text("Medium").tag(Priority.medium)
                    Text("High").tag(Priority.high)
                }
                .pickerStyle(.segmented)
                .onChange(of: task.priority) { _ in
                    onTaskModified()
                }
            }

            // Flagged toggle
            Toggle("Flagged", isOn: binding(for: \.flagged))
                .onChange(of: task.flagged) { _ in
                    onTaskModified()
                }
        }
    }

    // MARK: - Dates Section

    private func datesSection(task: Task) -> some View {
        VStack(spacing: 12) {
            // Due date
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Due Date")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if task.due != nil {
                        Button("Clear") {
                            clearDueDate()
                        }
                        .font(.caption2)
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }

                if let _ = task.due {
                    DatePicker(
                        "Due",
                        selection: Binding(
                            get: { task.due ?? Date() },
                            set: { newValue in
                                updateDueDate(newValue)
                            }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                } else {
                    Button("Set Due Date") {
                        updateDueDate(Date())
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Defer date
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Defer Until")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if task.defer != nil {
                        Button("Clear") {
                            clearDeferDate()
                        }
                        .font(.caption2)
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }

                if let _ = task.defer {
                    DatePicker(
                        "Defer",
                        selection: Binding(
                            get: { task.defer ?? Date() },
                            set: { newValue in
                                updateDeferDate(newValue)
                            }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                } else {
                    Button("Set Defer Date") {
                        updateDeferDate(Date())
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Context and Project Section

    private func contextProjectSection(task: Task) -> some View {
        VStack(spacing: 12) {
            // Context
            VStack(alignment: .leading, spacing: 8) {
                Text("Context")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Context", selection: binding(for: \.context)) {
                    Text("None").tag(nil as String?)
                    ForEach(contexts, id: \.name) { context in
                        HStack {
                            Text(context.icon)
                            Text(context.displayName)
                        }
                        .tag(context.name as String?)
                    }
                }
                .onChange(of: task.context) { _ in
                    onTaskModified()
                }
            }

            // Project
            VStack(alignment: .leading, spacing: 8) {
                Text("Project")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Project name", text: binding(for: \.project, default: ""))
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: task.project) { _ in
                        onTaskModified()
                    }
            }
        }
    }

    // MARK: - Effort Section

    private func effortSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Effort Estimate")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField(
                    "Minutes",
                    value: Binding(
                        get: { task.effort ?? 0 },
                        set: { newValue in
                            updateEffort(newValue > 0 ? newValue : nil)
                        }
                    ),
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)

                Text("minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let effortDesc = task.effortDescription {
                    Text("(\(effortDesc))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Color Section

    private func colorSection(task: Task) -> some View {
        ColorPickerView(
            selectedColor: binding(for: \.color),
            allowNoColor: true,
            onColorSelected: { _ in
                onTaskModified()
            }
        )
    }

    // MARK: - Recurrence Section

    private func recurrenceSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show recurrence info for instances
            if task.isRecurringInstance {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recurring Task Instance")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let occurrenceDate = task.occurrenceDate {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        Text("Occurrence: \(formatter.string(from: occurrenceDate))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if let templateId = task.originalTaskId {
                        Text("Template ID: \(templateId.uuidString.prefix(8))...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.1))
                )
            } else {
                // Recurrence picker for template tasks
                RecurrencePicker(
                    recurrence: binding(for: \.recurrence),
                    onChange: onTaskModified
                )

                // Show next occurrence if recurring
                if let nextOccurrence = task.nextOccurrence {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short

                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.blue)

                        Text("Next: \(formatter.string(from: nextOccurrence))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.caption)
                .foregroundColor(.secondary)

            TextEditor(text: binding(for: \.notes))
                .font(.body)
                .frame(minHeight: 120)
                .border(Color.secondary.opacity(0.2), width: 1)
                .onChange(of: task.notes) { _ in
                    onTaskModified()
                }
        }
    }

    // MARK: - Boards Section

    private func boardsSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Appears on Boards")
                .font(.caption)
                .foregroundColor(.secondary)

            let matchingBoards = boards.filter { task.matches($0.filter) }

            if matchingBoards.isEmpty {
                Text("This task doesn't match any board filters")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(matchingBoards, id: \.id) { board in
                        HStack {
                            if let icon = board.icon {
                                Text(icon)
                                    .font(.caption)
                            }
                            Text(board.displayTitle)
                                .font(.caption)

                            Spacer()

                            if task.isPositioned(on: board.id) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: onDuplicate) {
                Label("Duplicate Task", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            // Complete series button for recurring instances
            if let task = task, task.isRecurringInstance {
                Button(action: {
                    // TODO: Implement complete series functionality
                }) {
                    Label("Complete Series", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.green)
            }

            Button(role: .destructive, action: {
                showingDeleteAlert = true
            }) {
                Label("Delete Task", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .alert("Delete Task?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                if let task = task, task.isRecurring {
                    Text("This is a recurring task. Deleting it will remove all future occurrences. This action cannot be undone.")
                } else {
                    Text("This action cannot be undone.")
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Selection")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Select a task to view details")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods

    private func binding<T>(for keyPath: WritableKeyPath<Task, T>) -> Binding<T> {
        Binding(
            get: { task?[keyPath: keyPath] ?? Task(title: "")[keyPath: keyPath] },
            set: { newValue in
                task?[keyPath: keyPath] = newValue
            }
        )
    }

    private func binding<T>(for keyPath: WritableKeyPath<Task, T?>, default defaultValue: T) -> Binding<T> {
        Binding(
            get: { task?[keyPath: keyPath] ?? defaultValue },
            set: { newValue in
                task?[keyPath: keyPath] = newValue
            }
        )
    }

    private func clearDueDate() {
        task?.due = nil
        onTaskModified()
    }

    private func updateDueDate(_ date: Date) {
        task?.due = date
        onTaskModified()
    }

    private func clearDeferDate() {
        task?.defer = nil
        onTaskModified()
    }

    private func updateDeferDate(_ date: Date) {
        task?.defer = date
        onTaskModified()
    }

    private func updateEffort(_ minutes: Int?) {
        task?.effort = minutes
        onTaskModified()
    }
}

// MARK: - Preview

#Preview("Inspector - With Task") {
    TaskInspectorView(
        task: .constant(Task(
            title: "Call John about proposal",
            notes: "Discuss the new website design and get feedback on mockups.",
            status: .nextAction,
            project: "Website Redesign",
            context: "@phone",
            due: Date().addingTimeInterval(86400),
            flagged: true,
            priority: .high,
            effort: 30
        )),
        contexts: Context.defaults,
        boards: Board.builtInBoards,
        onDelete: {},
        onDuplicate: {},
        onTaskModified: {}
    )
}

#Preview("Inspector - No Selection") {
    TaskInspectorView(
        task: .constant(nil),
        contexts: Context.defaults,
        boards: Board.builtInBoards,
        onDelete: {},
        onDuplicate: {},
        onTaskModified: {}
    )
}
