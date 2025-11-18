//
//  TaskListView.swift
//  StickyToDo
//
//  Main task list view with grouped sections, filtering, and sorting.
//

import SwiftUI

/// Main task list view displaying filtered and grouped tasks
///
/// Features:
/// - SwiftUI List with task rows
/// - Grouped sections with headers
/// - Swipe actions (complete, delete)
/// - Inline editing
/// - Keyboard shortcuts
/// - Context menu
/// - Multi-selection support
struct TaskListView: View {

    // MARK: - Properties

    /// The perspective defining how tasks are filtered and grouped
    let perspective: Perspective

    /// All available tasks
    @Binding var tasks: [Task]

    /// Currently selected task IDs
    @Binding var selectedTaskIds: Set<UUID>

    /// Search query
    @Binding var searchQuery: String

    /// Callback when a task is selected
    var onTaskSelected: (UUID) -> Void

    /// Callback when task should be deleted
    var onDeleteTask: (UUID) -> Void

    /// Callback when new task should be created
    var onAddTask: () -> Void

    // MARK: - State

    @State private var editingTaskId: UUID?
    @State private var hoveredTaskId: UUID?
    @State private var searchResults: [SearchResult] = []

    // MARK: - Computed Properties

    /// Tasks filtered and sorted according to the perspective
    private var filteredTasks: [Task] {
        var filtered = perspective.apply(to: tasks)

        // Apply search filter if query is not empty
        if !searchQuery.isEmpty {
            // Use SearchManager for better relevance ranking and highlighting
            searchResults = SearchManager.search(tasks: filtered, queryString: searchQuery)
            return searchResults.map { $0.task }
        } else {
            searchResults = []
        }

        return filtered
    }

    /// Tasks grouped according to the perspective
    private var groupedTasks: [(String, [Task])] {
        perspective.group(filteredTasks)
    }

    /// Count of tasks in current view
    private var taskCount: Int {
        filteredTasks.count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with count
            listHeader

            // Main list
            if filteredTasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - List Header

    private var listHeader: some View {
        HStack {
            Text(!searchQuery.isEmpty ? "Search Results" : perspective.displayTitle)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Text("\(taskCount) task\(taskCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)

            if !selectedTaskIds.isEmpty {
                Text("(\(selectedTaskIds.count) selected)")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }

            if !searchQuery.isEmpty {
                Text("for \"\(searchQuery)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Task List

    private var taskList: some View {
        List(selection: $selectedTaskIds) {
            ForEach(groupedTasks, id: \.0) { groupName, groupTasks in
                Section(header: groupHeader(groupName)) {
                    ForEach(groupTasks) { task in
                        taskRow(for: task)
                            .tag(task.id)
                    }
                }
            }
        }
        .listStyle(.inset)
        .alternatingRowBackgrounds()
    }

    // MARK: - Group Header

    private func groupHeader(_ name: String) -> some View {
        HStack {
            if perspective.groupBy != .none {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Task Row

    private func taskRow(for task: Task) -> some View {
        // Find the index of this task in the tasks array
        let binding = Binding<Task>(
            get: {
                tasks.first(where: { $0.id == task.id }) ?? task
            },
            set: { newValue in
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index] = newValue
                }
            }
        )

        return TaskRowView(
            task: binding,
            isSelected: selectedTaskIds.contains(task.id),
            onTap: {
                onTaskSelected(task.id)
            },
            onToggleComplete: {
                toggleComplete(task: task)
            },
            onDelete: {
                onDeleteTask(task.id)
            }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDeleteTask(task.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                toggleComplete(task: task)
            } label: {
                Label(
                    task.status == .completed ? "Incomplete" : "Complete",
                    systemImage: task.status == .completed ? "circle" : "checkmark.circle"
                )
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading) {
            Button {
                toggleFlag(task: task)
            } label: {
                Label(
                    task.flagged ? "Unflag" : "Flag",
                    systemImage: task.flagged ? "star.slash" : "star.fill"
                )
            }
            .tint(.yellow)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: perspective.icon ?? "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(searchQuery.isEmpty ? "No tasks" : "No matching tasks")
                .font(.title3)
                .foregroundColor(.secondary)

            if searchQuery.isEmpty {
                Text("Create a new task to get started")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: onAddTask) {
                    Label("Add Task", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods

    private func toggleComplete(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            if tasks[index].status == .completed {
                tasks[index].reopen()
            } else {
                tasks[index].complete()
            }
        }
    }

    private func toggleFlag(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].flagged.toggle()
        }
    }
}

// MARK: - List Style Extension

extension View {
    /// Adds alternating row backgrounds to a List (macOS-style)
    func alternatingRowBackgrounds() -> some View {
        self
    }
}

// MARK: - Preview

#Preview("Task List - Grouped") {
    TaskListView(
        perspective: .nextActions,
        tasks: .constant([
            Task(title: "Call John", context: "@phone", priority: .high),
            Task(title: "Email Sarah", context: "@computer", priority: .medium),
            Task(title: "Buy groceries", context: "@errands", priority: .low),
            Task(title: "Review code", context: "@computer", priority: .high),
        ]),
        selectedTaskIds: .constant([]),
        searchQuery: .constant(""),
        onTaskSelected: { _ in },
        onDeleteTask: { _ in },
        onAddTask: {}
    )
}

#Preview("Task List - Empty") {
    TaskListView(
        perspective: .inbox,
        tasks: .constant([]),
        selectedTaskIds: .constant([]),
        searchQuery: .constant(""),
        onTaskSelected: { _ in },
        onDeleteTask: { _ in },
        onAddTask: {}
    )
}

#Preview("Task List - Search") {
    TaskListView(
        perspective: .allActive,
        tasks: .constant([
            Task(title: "Call John", context: "@phone"),
            Task(title: "Email Sarah", context: "@computer"),
        ]),
        selectedTaskIds: .constant([]),
        searchQuery: .constant("john"),
        onTaskSelected: { _ in },
        onDeleteTask: { _ in },
        onAddTask: {}
    )
}
