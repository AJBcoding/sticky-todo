//
//  TaskInspectorView.swift
//  StickyToDo
//
//  Inspector panel for editing task metadata and details.
//

import SwiftUI
import AppKit

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

    /// Callback when "Save as Template" is requested
    var onSaveAsTemplate: ((Task) -> Void)?

    /// Callback when a subtask should be created
    var onCreateSubtask: ((Task, String) -> Void)?

    /// Callback when complete series is requested for recurring tasks
    var onCompleteSeries: ((Task) -> Void)?

    /// All available tags in the system
    var availableTags: [Tag]

    /// Task store for fetching related tasks (subtasks, etc.)
    /// Optional for backward compatibility
    var taskStore: TaskStore?

    // MARK: - State

    @State private var editedTitle: String = ""
    @State private var editedNotes: String = ""
    @State private var showingDeleteAlert = false
    @State private var showingSaveTemplateDialog = false

    // Subtask state
    @State private var showingAddSubtask = false
    @State private var newSubtaskTitle = ""

    // Complete series state
    @State private var showingCompleteSeriesConfirmation = false

    // Attachment state
    @State private var showingAddLinkAttachment = false
    @State private var newLinkURL = ""
    @State private var newLinkName = ""
    @State private var showingAddNoteAttachment = false
    @State private var newNoteName = ""
    @State private var newNoteText = ""

    // Tag state
    @State private var showingTagPicker = false
    @State private var showingCreateNewTag = false
    @State private var newTagName = ""
    @State private var newTagColor = "#007AFF"
    @State private var newTagIcon = ""

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

                // Subtasks
                subtasksSection(task: task)

                // Attachments
                attachmentsSection(task: task)

                // Tags
                tagsSection(task: task)

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
                .accessibilityHidden(true)

            TextField("Task title", text: binding(for: \.title))
                .textFieldStyle(.roundedBorder)
                .onChange(of: task.title) { _ in
                    onTaskModified()
                }
                .accessibilityLabel("Task title")
                .accessibilityHint("Enter or edit the task title")
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
                    .accessibilityHidden(true)

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
                .accessibilityLabel("Task status")
                .accessibilityValue(task.status.displayName)
                .accessibilityHint("Select the task status")
            }

            // Priority
            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                Picker("Priority", selection: binding(for: \.priority)) {
                    Text("Low").tag(Priority.low)
                    Text("Medium").tag(Priority.medium)
                    Text("High").tag(Priority.high)
                }
                .pickerStyle(.segmented)
                .onChange(of: task.priority) { _ in
                    onTaskModified()
                }
                .accessibilityLabel("Task priority")
                .accessibilityValue(task.priority.displayName)
                .accessibilityHint("Select the task priority level")
            }

            // Flagged toggle
            Toggle("Flagged", isOn: binding(for: \.flagged))
                .onChange(of: task.flagged) { _ in
                    onTaskModified()
                }
                .accessibilityLabel("Flagged")
                .accessibilityValue(task.flagged ? "On" : "Off")
                .accessibilityHint("Toggle whether this task is flagged for attention")
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
                        .accessibilityHidden(true)

                    Spacer()

                    if task.due != nil {
                        Button("Clear") {
                            clearDueDate()
                        }
                        .font(.caption2)
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .accessibilityLabel("Clear due date")
                        .accessibilityHint("Double tap to remove the due date")
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
                    .accessibilityLabel("Due date")
                    .accessibilityHint("Select when this task is due")
                } else {
                    Button("Set Due Date") {
                        updateDueDate(Date())
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Set due date")
                    .accessibilityHint("Double tap to add a due date to this task")
                }
            }

            // Defer date
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Defer Until")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)

                    Spacer()

                    if task.defer != nil {
                        Button("Clear") {
                            clearDeferDate()
                        }
                        .font(.caption2)
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .accessibilityLabel("Clear defer date")
                        .accessibilityHint("Double tap to remove the defer date")
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
                    .accessibilityLabel("Defer until date")
                    .accessibilityHint("Select when this task should become visible")
                } else {
                    Button("Set Defer Date") {
                        updateDeferDate(Date())
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Set defer date")
                    .accessibilityHint("Double tap to add a defer date to hide this task until later")
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
                    .accessibilityHidden(true)

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
                .accessibilityLabel("Task context")
                .accessibilityValue(task.context ?? "None")
                .accessibilityHint("Select where or how this task can be done")
            }

            // Project
            VStack(alignment: .leading, spacing: 8) {
                Text("Project")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                TextField("Project name", text: binding(for: \.project, default: ""))
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: task.project) { _ in
                        onTaskModified()
                    }
                    .accessibilityLabel("Project name")
                    .accessibilityHint("Enter the project this task belongs to")
            }
        }
    }

    // MARK: - Effort Section

    private func effortSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Effort Estimate")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

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
                .accessibilityLabel("Effort estimate in minutes")
                .accessibilityHint("Enter the estimated time needed for this task")

                Text("minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                if let effortDesc = task.effortDescription {
                    Text("(\(effortDesc))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel(effortDesc)
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

                // Complete Series button for recurring templates
                if task.isRecurring {
                    Button(action: {
                        showingCompleteSeriesConfirmation = true
                    }) {
                        Label("Complete Series", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                    .accessibilityLabel("Complete entire recurring series")
                    .confirmationDialog(
                        "Complete Entire Series?",
                        isPresented: $showingCompleteSeriesConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Complete Series", role: .destructive) {
                            completeSeries()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will mark the template as completed and delete all future uncompleted instances. This action cannot be undone.")
                    }
                }
            }
        }
    }

    // MARK: - Subtasks Section

    private func subtasksSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Subtasks")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !task.subtaskIds.isEmpty {
                    Text("\(task.subtaskIds.count) subtasks")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if task.isSubtask {
                // Show parent task info for subtasks
                HStack {
                    Image(systemName: "arrow.up.backward")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text("This is a subtask")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.1))
                )
            } else {
                // Show subtasks list for parent tasks
                if task.subtaskIds.isEmpty {
                    Text("No subtasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(subtasks) { subtask in
                            HStack(spacing: 6) {
                                // Status indicator
                                Image(systemName: subtask.status == .completed ? "checkmark.circle.fill" : "circle")
                                    .font(.caption)
                                    .foregroundColor(subtask.status == .completed ? .green : .secondary)

                                // Subtask title
                                Text(subtask.title)
                                    .font(.caption)
                                    .foregroundColor(subtask.status == .completed ? .secondary : .primary)
                                    .strikethrough(subtask.status == .completed)
                                    .lineLimit(1)

                                Spacer()

                                // Priority indicator
                                if subtask.priority == .high {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }

                                // Flagged indicator
                                if subtask.flagged {
                                    Image(systemName: "flag.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(4)
                        }
                    }
                }

                // Add subtask button
                Button(action: {
                    newSubtaskTitle = ""
                    showingAddSubtask = true
                }) {
                    Label("Add Subtask", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add Subtask")
                .sheet(isPresented: $showingAddSubtask) {
                    addSubtaskDialog
                }
            }
        }
    }

    // MARK: - Attachments Section

    private func attachmentsSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Attachments")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !task.attachments.isEmpty {
                    Text("\(task.attachments.count) items")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if task.attachments.isEmpty {
                Text("No attachments")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(task.attachments) { attachment in
                        HStack(spacing: 8) {
                            Image(systemName: attachment.iconName)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .frame(width: 16)

                            Text(attachment.name)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            Text(attachment.typeDescription)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(4)
                    }
                }
            }

            // Add attachment button
            Menu {
                Button(action: {
                    openFilePicker()
                }) {
                    Label("Add File", systemImage: "doc")
                }

                Button(action: {
                    newLinkURL = ""
                    newLinkName = ""
                    showingAddLinkAttachment = true
                }) {
                    Label("Add Link", systemImage: "link")
                }

                Button(action: {
                    newNoteName = ""
                    newNoteText = ""
                    showingAddNoteAttachment = true
                }) {
                    Label("Add Note", systemImage: "note.text")
                }
            } label: {
                Label("Add Attachment", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Add Attachment")
            .sheet(isPresented: $showingAddLinkAttachment) {
                addLinkAttachmentDialog
            }
            .sheet(isPresented: $showingAddNoteAttachment) {
                addNoteAttachmentDialog
            }
        }
    }

    // MARK: - Tags Section

    private func tagsSection(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !task.tags.isEmpty {
                    Text("\(task.tags.count) tags")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if task.tags.isEmpty {
                Text("No tags")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                // Display tags as colored pills
                FlowLayout(spacing: 6) {
                    ForEach(task.tags) { tag in
                        HStack(spacing: 4) {
                            if let icon = tag.icon {
                                Image(systemName: icon)
                                    .font(.caption2)
                            }

                            Text(tag.name)
                                .font(.caption)
                                .fontWeight(.medium)

                            Button(action: {
                                removeTag(tag)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: tag.color))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }

            // Add tag button
            Button(action: {
                showingTagPicker = true
            }) {
                Label("Add Tag", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Add Tag")
            .sheet(isPresented: $showingTagPicker) {
                tagPickerDialog
            }
            .sheet(isPresented: $showingCreateNewTag) {
                createNewTagDialog
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

            Button(action: {
                showingSaveTemplateDialog = true
            }) {
                Label("Save as Template", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .sheet(isPresented: $showingSaveTemplateDialog) {
                if let task = task {
                    SaveAsTemplateView(
                        task: task,
                        onSave: { template in
                            onSaveAsTemplate?(task)
                            showingSaveTemplateDialog = false
                        },
                        onCancel: {
                            showingSaveTemplateDialog = false
                        }
                    )
                }
            }

            // Complete series button for recurring instances
            if let task = task, task.isRecurringInstance {
                Button(action: {
                    onCompleteSeries?(task)
                }) {
                    Label("Complete Series", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.green)
                .accessibilityLabel("Complete entire recurring series")
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

    // MARK: - Computed Properties

    /// Returns the actual subtask objects for the current task
    private var subtasks: [Task] {
        guard let task = task, let store = taskStore else { return [] }
        return task.subtaskIds.compactMap { store.task(withID: $0) }
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

    private func completeSeries() {
        guard let currentTask = task else { return }
        onCompleteSeries?(currentTask)
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
        onTaskModified: {},
        onSaveAsTemplate: nil,
        onCreateSubtask: nil,
        onCompleteSeries: nil,
        availableTags: Tag.defaultTags
    )
}

#Preview("Inspector - No Selection") {
    TaskInspectorView(
        task: .constant(nil),
        contexts: Context.defaults,
        boards: Board.builtInBoards,
        onDelete: {},
        onDuplicate: {},
        onTaskModified: {},
        onSaveAsTemplate: nil,
        onCreateSubtask: nil,
        onCompleteSeries: nil,
        availableTags: Tag.defaultTags
    )
}

// MARK: - Helper Views and Extensions

extension TaskInspectorView {
    private func removeTag(_ tag: Tag) {
        task?.tags.removeAll { $0.id == tag.id }
        onTaskModified()
    }

    // MARK: - Add Subtask Dialog

    private var addSubtaskDialog: some View {
        VStack(spacing: 20) {
            Text("Add Subtask")
                .font(.headline)

            TextField("Subtask title", text: $newSubtaskTitle)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showingAddSubtask = false
                    newSubtaskTitle = ""
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    guard !newSubtaskTitle.isEmpty, let task = task else { return }
                    onCreateSubtask?(task, newSubtaskTitle)
                    showingAddSubtask = false
                    newSubtaskTitle = ""
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newSubtaskTitle.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    // MARK: - Add Link Attachment Dialog

    private var addLinkAttachmentDialog: some View {
        VStack(spacing: 20) {
            Text("Add Link Attachment")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Link name", text: $newLinkName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("https://example.com", text: $newLinkURL)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") {
                    showingAddLinkAttachment = false
                    newLinkURL = ""
                    newLinkName = ""
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    guard !newLinkURL.isEmpty, !newLinkName.isEmpty,
                          let url = URL(string: newLinkURL) else { return }

                    let attachment = Attachment.linkAttachment(
                        url: url,
                        name: newLinkName
                    )
                    task?.addAttachment(attachment)
                    onTaskModified()
                    showingAddLinkAttachment = false
                    newLinkURL = ""
                    newLinkName = ""
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newLinkURL.isEmpty || newLinkName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    // MARK: - Add Note Attachment Dialog

    private var addNoteAttachmentDialog: some View {
        VStack(spacing: 20) {
            Text("Add Note Attachment")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Note name", text: $newNoteName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $newNoteText)
                    .font(.body)
                    .frame(minHeight: 120)
                    .border(Color.secondary.opacity(0.2), width: 1)
            }

            HStack {
                Button("Cancel") {
                    showingAddNoteAttachment = false
                    newNoteName = ""
                    newNoteText = ""
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    guard !newNoteName.isEmpty, !newNoteText.isEmpty else { return }

                    let attachment = Attachment.noteAttachment(
                        text: newNoteText,
                        name: newNoteName
                    )
                    task?.addAttachment(attachment)
                    onTaskModified()
                    showingAddNoteAttachment = false
                    newNoteName = ""
                    newNoteText = ""
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newNoteName.isEmpty || newNoteText.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    // MARK: - Tag Picker Dialog

    private var tagPickerDialog: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Add Tag")
                    .font(.headline)

                Spacer()

                Button(action: {
                    showingTagPicker = false
                    showingCreateNewTag = true
                }) {
                    Label("New Tag", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // Show predefined tags
                    Text("Available Tags")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(availableTags.filter { tag in
                        !(task?.tags.contains(where: { $0.id == tag.id }) ?? false)
                    }) { tag in
                        Button(action: {
                            task?.addTag(tag)
                            onTaskModified()
                            showingTagPicker = false
                        }) {
                            HStack(spacing: 8) {
                                if let icon = tag.icon {
                                    Image(systemName: icon)
                                        .font(.caption)
                                }

                                Text(tag.name)
                                    .font(.body)

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: tag.color))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 300)

            Button("Cancel") {
                showingTagPicker = false
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .frame(width: 400)
    }

    // MARK: - Create New Tag Dialog

    private var createNewTagDialog: some View {
        VStack(spacing: 20) {
            Text("Create New Tag")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Tag name", text: $newTagName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(predefinedColors, id: \.self) { colorHex in
                        Button(action: {
                            newTagColor = colorHex
                        }) {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: newTagColor == colorHex ? 3 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Icon (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("SF Symbol name (e.g., star.fill)", text: $newTagIcon)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") {
                    showingCreateNewTag = false
                    newTagName = ""
                    newTagColor = "#007AFF"
                    newTagIcon = ""
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    guard !newTagName.isEmpty else { return }

                    let newTag = Tag(
                        name: newTagName,
                        color: newTagColor,
                        icon: newTagIcon.isEmpty ? nil : newTagIcon
                    )
                    task?.addTag(newTag)
                    onTaskModified()
                    showingCreateNewTag = false
                    newTagName = ""
                    newTagColor = "#007AFF"
                    newTagIcon = ""
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newTagName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    // MARK: - File Picker

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            let attachment = Attachment.fileAttachment(url: url)
            task?.addAttachment(attachment)
            onTaskModified()
        }
    }

    // MARK: - Helper Properties

    private var predefinedColors: [String] {
        return [
            "#FF3B30", // Red
            "#FF9500", // Orange
            "#FFCC00", // Yellow
            "#34C759", // Green
            "#5856D6", // Purple
            "#007AFF", // Blue
            "#5AC8FA", // Light Blue
            "#FF2D55"  // Pink
        ]
    }
}

/// Flow layout for tags that wraps to multiple lines
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
