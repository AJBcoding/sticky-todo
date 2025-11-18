//
//  TaskListView.swift
//  StickyToDo-SwiftUI
//
//  Traditional list view for tasks with drag-drop support.
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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

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

                                    Divider()
                                        .padding(.leading, 52)
                                }
                            } header: {
                                sectionHeader("Active", count: activeTasks.count)
                            }
                        }

                        // Completed tasks
                        if !completedTasks.isEmpty {
                            Section {
                                ForEach(completedTasks) { task in
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

                                    Divider()
                                        .padding(.leading, 52)
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

    // MARK: - Event Handlers

    private func handleTaskTap(_ task: Task) {
        if NSEvent.modifierFlags.contains(.command) {
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
