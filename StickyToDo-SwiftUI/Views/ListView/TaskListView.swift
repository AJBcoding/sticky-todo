//
//  TaskListView.swift
//  StickyToDo-SwiftUI
//
//  Traditional list view for tasks with drag-drop support and batch editing.
//

import SwiftUI

/// Traditional list view for displaying and managing tasks
struct TaskListView: View {

    // MARK: - Properties

    /// Task data store
    @ObservedObject var taskStore: TaskStore

    /// Filter for tasks to display
    let filter: Filter

    /// Title for the list
    let title: String

    // MARK: - State

    @State private var selectedTaskIds: Set<UUID> = []
    @State private var searchText = ""
    @State private var isBatchEditMode = false
    @State private var showingBatchActionMenu = false
    @State private var showingDeleteConfirmation = false
    @State private var showingProjectPicker = false
    @State private var showingContextPicker = false
    @State private var showingStatusPicker = false
    @State private var showingPriorityPicker = false
    @State private var showingDueDatePicker = false
    @State private var selectedBatchProject: String?
    @State private var selectedBatchContext: String?
    @State private var selectedBatchStatus: Status = .nextAction
    @State private var selectedBatchPriority: Priority = .medium
    @State private var selectedBatchDueDate: Date = Date()

    // MARK: - Batch Edit Manager

    private let batchEditManager = BatchEditManager()

    // MARK: - Computed Properties

    private var filteredTasks: [Task] {
        let filtered = taskStore.tasks.filter { $0.matches(filter) }

        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { $0.matchesSearch(searchText) }
        }
    }

    private var activeTasks: [Task] {
        filteredTasks.filter { $0.status != .completed }
    }

    private var completedTasks: [Task] {
        filteredTasks.filter { $0.status == .completed }
    }

    private var selectedTasks: [Task] {
        filteredTasks.filter { selectedTaskIds.contains($0.id) }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Batch edit toolbar
            if isBatchEditMode && !selectedTaskIds.isEmpty {
                batchEditToolbar
                Divider()
            }

            // Content
            if filteredTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        // Active tasks
                        if !activeTasks.isEmpty {
                            Section {
                                ForEach(activeTasks) { task in
                                    taskRow(task)
                                }
                            } header: {
                                sectionHeader("Active", count: activeTasks.count)
                            }
                        }

                        // Completed tasks
                        if !completedTasks.isEmpty {
                            Section {
                                ForEach(completedTasks) { task in
                                    taskRow(task)
                                }
                            } header: {
                                sectionHeader("Completed", count: completedTasks.count)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .alert("Delete Tasks", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                performBatchDelete()
            }
        } message: {
            Text(batchEditManager.confirmationMessage(for: .delete, taskCount: selectedTaskIds.count))
        }
        .sheet(isPresented: $showingProjectPicker) {
            projectPickerSheet
        }
        .sheet(isPresented: $showingContextPicker) {
            contextPickerSheet
        }
        .sheet(isPresented: $showingStatusPicker) {
            statusPickerSheet
        }
        .sheet(isPresented: $showingPriorityPicker) {
            priorityPickerSheet
        }
        .sheet(isPresented: $showingDueDatePicker) {
            dueDatePickerSheet
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            // Search field
            TextField("Search tasks...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .accessibilityLabel("Search tasks")
                .accessibilityHint("Type to filter tasks by title or content")

            // Batch edit mode toggle
            Button(action: toggleBatchEditMode) {
                Label(isBatchEditMode ? "Done" : "Select", systemImage: isBatchEditMode ? "checkmark.circle.fill" : "checkmark.circle")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(isBatchEditMode ? "Exit batch edit mode" : "Enter batch edit mode")
            .accessibilityHint(isBatchEditMode ? "Double-tap to exit selection mode" : "Double-tap to select multiple tasks")
            .keyboardShortcut("e", modifiers: [.command, .shift])

            // Add task button
            Button(action: addNewTask) {
                Label("Add Task", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Add new task")
            .accessibilityHint("Double-tap to create a new task in this list")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Batch Edit Toolbar

    private var batchEditToolbar: some View {
        HStack(spacing: 8) {
            Text("\(selectedTaskIds.count) selected")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityLabel("\(selectedTaskIds.count) tasks selected")

            Spacer()

            // Select All / Deselect All
            Button(action: selectAllOrNone) {
                Text(selectedTaskIds.count == filteredTasks.count ? "Deselect All" : "Select All")
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("a", modifiers: [.command])
            .accessibilityLabel(selectedTaskIds.count == filteredTasks.count ? "Deselect all tasks" : "Select all tasks")

            Divider()
                .frame(height: 20)

            // Batch actions menu
            Menu {
                // Status actions
                Menu("Change Status") {
                    Button("Next Action") {
                        performBatchOperation(.setStatus(.nextAction))
                    }
                    Button("Waiting") {
                        performBatchOperation(.setStatus(.waiting))
                    }
                    Button("Someday/Maybe") {
                        performBatchOperation(.setStatus(.someday))
                    }
                    Button("Inbox") {
                        performBatchOperation(.setStatus(.inbox))
                    }
                }

                // Priority actions
                Menu("Set Priority") {
                    Button("High Priority") {
                        performBatchOperation(.setPriority(.high))
                    }
                    Button("Medium Priority") {
                        performBatchOperation(.setPriority(.medium))
                    }
                    Button("Low Priority") {
                        performBatchOperation(.setPriority(.low))
                    }
                }

                Divider()

                // Project/Context
                Button("Set Project...") {
                    showingProjectPicker = true
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button("Set Context...") {
                    showingContextPicker = true
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Divider()

                // Dates
                Button("Set Due Date...") {
                    showingDueDatePicker = true
                }

                Button("Clear Due Date") {
                    performBatchOperation(.setDueDate(nil))
                }

                Divider()

                // Flag
                Button("Flag Tasks") {
                    performBatchOperation(.flag)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Button("Unflag Tasks") {
                    performBatchOperation(.unflag)
                }

                Divider()

                // Complete/Uncomplete
                Button("Complete Tasks") {
                    performBatchOperation(.complete)
                }
                .keyboardShortcut(.return, modifiers: [.command])

                Button("Mark as Incomplete") {
                    performBatchOperation(.uncomplete)
                }

                Divider()

                // Archive
                Button("Archive Tasks") {
                    performBatchOperation(.archive)
                }

                Divider()

                // Delete
                Button("Delete Tasks...", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .keyboardShortcut(.delete, modifiers: [.command])
            } label: {
                Label("Batch Actions", systemImage: "ellipsis.circle")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Batch actions menu")
            .accessibilityHint("Double-tap to see available actions for selected tasks")

            // Quick action buttons
            Button(action: { performBatchOperation(.complete) }) {
                Label("Complete", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .help("Complete selected tasks")
            .accessibilityLabel("Complete selected tasks")

            Button(action: { showingDeleteConfirmation = true }) {
                Label("Delete", systemImage: "trash")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .help("Delete selected tasks")
            .accessibilityLabel("Delete selected tasks")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Task Row

    private func taskRow(_ task: Task) -> some View {
        HStack(spacing: 0) {
            // Checkbox for batch edit mode
            if isBatchEditMode {
                Button(action: { toggleTaskSelection(task) }) {
                    Image(systemName: selectedTaskIds.contains(task.id) ? "checkmark.square.fill" : "square")
                        .foregroundColor(selectedTaskIds.contains(task.id) ? .accentColor : .secondary)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .accessibilityLabel(selectedTaskIds.contains(task.id) ? "Deselect task" : "Select task")
                .accessibilityAddTraits(.isButton)
            }

            // Task item view
            TaskListItemView(
                task: task,
                isSelected: selectedTaskIds.contains(task.id),
                onTap: {
                    handleTaskTap(task)
                },
                onToggleComplete: {
                    toggleTaskCompletion(task)
                }
            )
            .id(task.id)
        }
        .background(
            Rectangle()
                .fill(selectedTaskIds.contains(task.id) ? Color.accentColor.opacity(0.05) : Color.clear)
        )
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, isBatchEditMode ? 52 : 0)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text("(\(count))")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) section, \(count) task\(count == 1 ? "" : "s")")
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No tasks found")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Add a task to get started")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Add Task") {
                addNewTask()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Add first task")
            .accessibilityHint("Double-tap to create your first task")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Picker Sheets

    private var projectPickerSheet: some View {
        NavigationView {
            VStack {
                List {
                    Section("Projects") {
                        Button("None (Remove Project)") {
                            performBatchOperation(.setProject(nil))
                            showingProjectPicker = false
                        }

                        ForEach(taskStore.projects, id: \.self) { project in
                            Button(project) {
                                performBatchOperation(.setProject(project))
                                showingProjectPicker = false
                            }
                        }
                    }

                    Section {
                        TextField("New project name", text: Binding(
                            get: { selectedBatchProject ?? "" },
                            set: { selectedBatchProject = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)

                        Button("Set Custom Project") {
                            if let project = selectedBatchProject, !project.isEmpty {
                                performBatchOperation(.setProject(project))
                                showingProjectPicker = false
                                selectedBatchProject = nil
                            }
                        }
                        .disabled(selectedBatchProject?.isEmpty ?? true)
                    }
                }
            }
            .navigationTitle("Select Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingProjectPicker = false
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }

    private var contextPickerSheet: some View {
        NavigationView {
            VStack {
                List {
                    Section("Contexts") {
                        Button("None (Remove Context)") {
                            performBatchOperation(.setContext(nil))
                            showingContextPicker = false
                        }

                        ForEach(taskStore.contexts, id: \.self) { context in
                            Button(context) {
                                performBatchOperation(.setContext(context))
                                showingContextPicker = false
                            }
                        }
                    }

                    Section {
                        TextField("New context name", text: Binding(
                            get: { selectedBatchContext ?? "" },
                            set: { selectedBatchContext = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)

                        Button("Set Custom Context") {
                            if let context = selectedBatchContext, !context.isEmpty {
                                performBatchOperation(.setContext(context))
                                showingContextPicker = false
                                selectedBatchContext = nil
                            }
                        }
                        .disabled(selectedBatchContext?.isEmpty ?? true)
                    }
                }
            }
            .navigationTitle("Select Context")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingContextPicker = false
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }

    private var statusPickerSheet: some View {
        NavigationView {
            List {
                ForEach([Status.inbox, .nextAction, .waiting, .someday], id: \.self) { status in
                    Button(status.displayName) {
                        performBatchOperation(.setStatus(status))
                        showingStatusPicker = false
                    }
                }
            }
            .navigationTitle("Select Status")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingStatusPicker = false
                    }
                }
            }
        }
        .frame(width: 300, height: 300)
    }

    private var priorityPickerSheet: some View {
        NavigationView {
            List {
                ForEach([Priority.high, .medium, .low], id: \.self) { priority in
                    Button(priority.displayName) {
                        performBatchOperation(.setPriority(priority))
                        showingPriorityPicker = false
                    }
                }
            }
            .navigationTitle("Select Priority")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingPriorityPicker = false
                    }
                }
            }
        }
        .frame(width: 300, height: 250)
    }

    private var dueDatePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker("Due Date", selection: $selectedBatchDueDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .padding()

                HStack {
                    Button("Cancel") {
                        showingDueDatePicker = false
                    }
                    .buttonStyle(.bordered)

                    Button("Set Due Date") {
                        performBatchOperation(.setDueDate(selectedBatchDueDate))
                        showingDueDatePicker = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Set Due Date")
        }
        .frame(width: 400, height: 450)
    }

    // MARK: - Event Handlers

    private func toggleBatchEditMode() {
        isBatchEditMode.toggle()
        if !isBatchEditMode {
            selectedTaskIds.removeAll()
        }
    }

    private func toggleTaskSelection(_ task: Task) {
        if selectedTaskIds.contains(task.id) {
            selectedTaskIds.remove(task.id)
        } else {
            selectedTaskIds.insert(task.id)
        }
    }

    private func selectAllOrNone() {
        if selectedTaskIds.count == filteredTasks.count {
            selectedTaskIds.removeAll()
        } else {
            selectedTaskIds = Set(filteredTasks.map { $0.id })
        }
    }

    private func handleTaskTap(_ task: Task) {
        if isBatchEditMode {
            toggleTaskSelection(task)
        } else if NSEvent.modifierFlags.contains(.command) {
            // Toggle selection
            if selectedTaskIds.contains(task.id) {
                selectedTaskIds.remove(task.id)
            } else {
                selectedTaskIds.insert(task.id)
            }
        } else {
            // Single selection
            selectedTaskIds = [task.id]
        }
    }

    private func toggleTaskCompletion(_ task: Task) {
        var updatedTask = task

        if task.status == .completed {
            updatedTask.status = .nextAction
        } else {
            updatedTask.status = .completed
        }

        taskStore.update(updatedTask)
    }

    private func addNewTask() {
        let task = Task(
            title: "New Task",
            status: .inbox,
            project: filter.project,
            context: filter.context
        )
        taskStore.add(task)
    }

    // MARK: - Batch Operations

    private func performBatchOperation(_ operation: BatchEditManager.BatchOperation) {
        // Handle special operations
        if case .delete = operation {
            performBatchDelete()
            return
        }

        if case .archive = operation {
            taskStore.archiveBatch(selectedTasks)
            selectedTaskIds.removeAll()
            isBatchEditMode = false
            return
        }

        let result = batchEditManager.applyOperation(operation, to: selectedTasks)

        // Update all modified tasks in the store
        taskStore.updateBatch(result.modifiedTasks)

        // Clear selection after operation
        selectedTaskIds.removeAll()
        isBatchEditMode = false

        // Log errors if any
        if !result.errors.isEmpty {
            print("Batch operation completed with \(result.errors.count) errors")
        }
    }

    private func performBatchDelete() {
        let tasksToDelete = selectedTasks
        taskStore.deleteBatch(tasksToDelete)
        selectedTaskIds.removeAll()
        isBatchEditMode = false
    }

    // MARK: - Keyboard Shortcuts

    private func setupKeyboardShortcuts() {
        let shortcutManager = KeyboardShortcutManager.shared

        // Batch edit mode toggle
        shortcutManager.registerAction(for: "batchEditMode") {
            self.toggleBatchEditMode()
        }

        // Select all
        shortcutManager.registerAction(for: "selectAllTasks") {
            if self.isBatchEditMode {
                self.selectAllOrNone()
            }
        }

        // Batch complete
        shortcutManager.registerAction(for: "batchComplete") {
            if self.isBatchEditMode && !self.selectedTaskIds.isEmpty {
                self.performBatchOperation(.complete)
            }
        }

        // Batch delete
        shortcutManager.registerAction(for: "batchDelete") {
            if self.isBatchEditMode && !self.selectedTaskIds.isEmpty {
                self.showingDeleteConfirmation = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Task List View") {
    let fileIO = MarkdownFileIO(rootPath: FileManager.default.temporaryDirectory.path)
    let taskStore = TaskStore(fileIO: fileIO)

    // Add test tasks
    taskStore.add(Task(
        title: "Complete project proposal",
        status: .nextAction,
        project: "Work",
        due: Date(),
        flagged: true,
        priority: .high
    ))
    taskStore.add(Task(
        title: "Call client",
        status: .nextAction,
        context: "@phone"
    ))
    taskStore.add(Task(
        title: "Review code",
        status: .completed
    ))

    return TaskListView(
        taskStore: taskStore,
        filter: Filter(),
        title: "All Tasks"
    )
    .frame(width: 500, height: 600)
}
