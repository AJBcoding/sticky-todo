//
//  KanbanLayoutView.swift
//  StickyToDo
//
//  SwiftUI Kanban board layout with vertical columns for workflow stages.
//  Supports drag-and-drop between columns with automatic metadata updates.
//

import SwiftUI

/// SwiftUI Kanban board view
///
/// Displays tasks organized in vertical swim lanes. Each column represents
/// a stage in the workflow. Tasks can be dragged between columns.
struct KanbanLayoutView: View {

    // MARK: - Properties

    /// The current board being displayed
    let board: Board

    /// All tasks to display on the board
    @Binding var tasks: [Task]

    /// Currently selected task IDs
    @Binding var selectedTaskIds: Set<UUID>

    /// Callback when a task is selected
    var onTaskSelected: (UUID) -> Void

    /// Callback when a task is updated
    var onTaskUpdated: (Task) -> Void

    /// Callback when a new task should be created
    var onCreateTask: (String) -> Void

    // MARK: - State

    @State private var draggedTask: Task?

    // MARK: - Computed Properties

    /// Tasks that appear on this board
    private var boardTasks: [Task] {
        tasks.filter { $0.matches(board.filter) }
    }

    /// Columns for this board
    private var columns: [String] {
        board.effectiveColumns
    }

    /// Tasks grouped by column
    private var tasksByColumn: [String: [Task]] {
        var grouped: [String: [Task]] = [:]

        for column in columns {
            grouped[column] = []
        }

        for task in boardTasks {
            if let column = LayoutEngine.assignTaskToColumn(task: task, board: board) {
                grouped[column]?.append(task)
            } else {
                grouped[columns.first ?? ""]?.append(task)
            }
        }

        return grouped
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: LayoutEngine.columnSpacing) {
                ForEach(columns, id: \.self) { column in
                    kanbanColumn(column: column)
                }
            }
            .padding(LayoutEngine.gridSpacing)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Column View

    private func kanbanColumn(column: String) -> some View {
        let columnTasks = tasksByColumn[column] ?? []

        return VStack(alignment: .leading, spacing: 0) {
            // Column header
            columnHeader(column: column, taskCount: columnTasks.count)

            // Task cards
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: LayoutEngine.cardSpacing) {
                    ForEach(columnTasks) { task in
                        kanbanTaskCard(task: task, column: column)
                    }
                }
                .padding(LayoutEngine.columnPadding)
            }
        }
        .frame(width: LayoutEngine.defaultColumnWidth)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers: providers, toColumn: column)
        }
    }

    // MARK: - Column Header

    private func columnHeader(column: String, taskCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(column)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(taskCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Button(action: {
                onCreateTask(column)
            }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                    Text("Add Task")
                        .font(.system(size: 11))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Task Card

    private func kanbanTaskCard(task: Task, column: String) -> some View {
        let isSelected = selectedTaskIds.contains(task.id)

        return VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(task.title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(3)
                .foregroundColor(.primary)

            // Metadata badges
            HStack(spacing: 4) {
                if let context = task.context {
                    metadataBadge(text: context, color: .blue)
                }

                if let project = task.project {
                    metadataBadge(text: project, color: .purple)
                }

                if task.priority == .high {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }

                if task.flagged {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }

                if let dueDesc = task.dueDescription {
                    metadataBadge(
                        text: dueDesc,
                        color: task.isOverdue ? .red : .gray
                    )
                }

                Spacer()
            }
        }
        .padding(12)
        .frame(height: LayoutEngine.defaultCardHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(colorForTask(task))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.blue : Color(NSColor.separatorColor), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .onTapGesture {
            handleTaskTap(task.id)
        }
        .onDrag {
            self.draggedTask = task
            return NSItemProvider(object: task.id.uuidString as NSString)
        }
    }

    // MARK: - Metadata Badge

    private func metadataBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundColor(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
    }

    // MARK: - Helpers

    private func colorForTask(_ task: Task) -> Color {
        if task.status == .completed {
            return Color.green.opacity(0.15)
        }

        switch task.priority {
        case .high:
            return Color.red.opacity(0.1)
        case .medium:
            return Color.yellow.opacity(0.15)
        case .low:
            return Color.blue.opacity(0.1)
        }
    }

    private func handleTaskTap(_ taskId: UUID) {
        if NSEvent.modifierFlags.contains(.command) {
            // Toggle selection
            if selectedTaskIds.contains(taskId) {
                selectedTaskIds.remove(taskId)
            } else {
                selectedTaskIds.insert(taskId)
            }
        } else {
            // Single selection
            selectedTaskIds = [taskId]
        }

        onTaskSelected(taskId)
    }

    private func handleDrop(providers: [NSItemProvider], toColumn column: String) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { (item, error) in
            guard let data = item as? Data,
                  let taskIdString = String(data: data, encoding: .utf8),
                  let taskId = UUID(uuidString: taskIdString),
                  let taskIndex = tasks.firstIndex(where: { $0.id == taskId }) else {
                return
            }

            DispatchQueue.main.async {
                // Apply metadata updates for the target column
                var updatedTask = tasks[taskIndex]
                let metadata = LayoutEngine.metadataUpdates(
                    forTask: updatedTask,
                    inColumn: column,
                    onBoard: board
                )

                // Apply metadata
                for (key, value) in metadata {
                    switch key {
                    case "status":
                        if let statusString = value as? String,
                           let status = Status(rawValue: statusString) {
                            updatedTask.status = status
                        }
                    case "context":
                        if let context = value as? String {
                            updatedTask.context = context
                        }
                    case "project":
                        if let project = value as? String {
                            updatedTask.project = project
                        }
                    case "priority":
                        if let priorityString = value as? String,
                           let priority = Priority(rawValue: priorityString) {
                            updatedTask.priority = priority
                        }
                    case "flagged":
                        if let flagged = value as? Bool {
                            updatedTask.flagged = flagged
                        }
                    default:
                        break
                    }
                }

                updatedTask.modified = Date()
                tasks[taskIndex] = updatedTask
                onTaskUpdated(updatedTask)
            }
        }

        return true
    }
}

// MARK: - Preview

#Preview("Kanban Board") {
    KanbanLayoutView(
        board: Board(
            id: "next-actions",
            type: .status,
            layout: .kanban,
            filter: Filter(status: .nextAction),
            columns: ["To Do", "In Progress", "Done"]
        ),
        tasks: .constant([
            Task(
                title: "Call John about proposal",
                status: .inbox,
                context: "@phone",
                priority: .high,
                flagged: true
            ),
            Task(
                title: "Review mockups",
                status: .nextAction,
                project: "Website",
                priority: .medium
            ),
            Task(
                title: "Write report",
                status: .nextAction,
                priority: .low
            ),
            Task(
                title: "Deploy to production",
                status: .completed,
                project: "Website"
            ),
        ]),
        selectedTaskIds: .constant([]),
        onTaskSelected: { _ in },
        onTaskUpdated: { _ in },
        onCreateTask: { _ in }
    )
    .frame(width: 900, height: 600)
}
