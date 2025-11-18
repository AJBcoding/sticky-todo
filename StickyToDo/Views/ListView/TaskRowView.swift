//
//  TaskRowView.swift
//  StickyToDo
//
//  Individual task row component for list view.
//

import SwiftUI

/// Individual task row component displaying task information and metadata
///
/// Features:
/// - Toggle for completion status
/// - Inline title editing
/// - Metadata badges (context, project, priority)
/// - Due date with color coding
/// - Effort estimate display
/// - Hover actions and context menu
struct TaskRowView: View {

    // MARK: - Properties

    /// The task to display
    @Binding var task: Task

    /// Whether this row is currently selected
    let isSelected: Bool

    /// Whether to show the editing state
    @State private var isEditing: Bool = false

    /// Edited title when in editing mode
    @State private var editedTitle: String = ""

    /// Whether the row is being hovered
    @State private var isHovered: Bool = false

    /// Indentation level for hierarchical display (0 = top-level)
    let indentationLevel: Int

    /// Whether this task has subtasks
    let hasSubtasks: Bool

    /// Subtask progress (completed, total) - nil if no subtasks
    let subtaskProgress: (completed: Int, total: Int)?

    /// Whether subtasks are expanded (for disclosure triangle)
    @Binding var isExpanded: Bool

    /// Callback when task is tapped
    var onTap: () -> Void

    /// Callback when task completion state changes
    var onToggleComplete: () -> Void

    /// Callback when task should be deleted
    var onDelete: () -> Void

    /// Callback when disclosure triangle is tapped
    var onToggleExpansion: (() -> Void)?

    /// Callback when "Add Subtask" is tapped
    var onAddSubtask: (() -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Indentation spacer
            if indentationLevel > 0 {
                Spacer()
                    .frame(width: CGFloat(indentationLevel) * 20)
            }

            // Disclosure triangle (if task has subtasks)
            if hasSubtasks {
                Button(action: {
                    onToggleExpansion?()
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
            } else if indentationLevel > 0 {
                // Placeholder for alignment
                Spacer()
                    .frame(width: 12, height: 12)
            }

            // Completion checkbox
            Button(action: {
                onToggleComplete()
            }) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(task.status == .completed ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                // Title (with inline editing)
                if isEditing {
                    TextField("Task title", text: $editedTitle, onCommit: {
                        saveEdit()
                    })
                    .textFieldStyle(.plain)
                    .font(.body)
                    .onAppear {
                        editedTitle = task.title
                    }
                } else {
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.status == .completed)
                        .foregroundColor(task.status == .completed ? .secondary : .primary)
                        .lineLimit(2)
                        .onTapGesture {
                            if !isEditing {
                                onTap()
                            }
                        }
                }

                // Metadata badges
                HStack(spacing: 6) {
                    // Subtask progress badge (only if has subtasks)
                    if let progress = subtaskProgress, progress.total > 0 {
                        MetadataBadge(
                            text: "\(progress.completed)/\(progress.total)",
                            color: progress.completed == progress.total ? .green : .orange,
                            icon: "checklist"
                        )
                    }

                    // Context badge
                    if let context = task.context {
                        MetadataBadge(
                            text: context,
                            color: .blue,
                            icon: "mappin.circle.fill"
                        )
                    }

                    // Project badge
                    if let project = task.project {
                        MetadataBadge(
                            text: project,
                            color: .purple,
                            icon: "folder.fill"
                        )
                    }

                    // Priority badge (only for high priority)
                    if task.priority == .high {
                        MetadataBadge(
                            text: "High",
                            color: .red,
                            icon: "exclamationmark.circle.fill"
                        )
                    }

                    // Due date badge
                    if let dueDescription = task.dueDescription {
                        MetadataBadge(
                            text: dueDescription,
                            color: task.isOverdue ? .red : (task.isDueToday ? .orange : .gray),
                            icon: "calendar"
                        )
                    }

                    // Effort estimate
                    if let effortDesc = task.effortDescription {
                        MetadataBadge(
                            text: effortDesc,
                            color: .green,
                            icon: "clock.fill"
                        )
                    }

                    // Flagged indicator
                    if task.flagged {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }

            Spacer()

            // Hover actions
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: { startEditing() }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            contextMenuContent
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuContent: some View {
        Button("Edit") {
            startEditing()
        }

        Button(task.status == .completed ? "Mark Incomplete" : "Mark Complete") {
            onToggleComplete()
        }

        Divider()

        // Subtask menu
        if let addSubtask = onAddSubtask {
            Button("Add Subtask", systemImage: "plus.circle") {
                addSubtask()
            }

            Divider()
        }

        Button("Flag", systemImage: task.flagged ? "star.slash" : "star") {
            task.flagged.toggle()
        }

        Menu("Change Status") {
            Button("Inbox") { task.status = .inbox }
            Button("Next Action") { task.status = .nextAction }
            Button("Waiting") { task.status = .waiting }
            Button("Someday") { task.status = .someday }
        }

        Menu("Change Priority") {
            Button("High") { task.priority = .high }
            Button("Medium") { task.priority = .medium }
            Button("Low") { task.priority = .low }
        }

        Divider()

        Button("Duplicate") {
            // This would need to be handled by the parent view
        }

        Button("Delete", systemImage: "trash", role: .destructive) {
            onDelete()
        }
    }

    // MARK: - Helper Methods

    private func startEditing() {
        editedTitle = task.title
        isEditing = true
    }

    private func saveEdit() {
        task.title = editedTitle
        isEditing = false
    }
}

// MARK: - Metadata Badge

/// Small capsule badge for displaying task metadata
struct MetadataBadge: View {
    let text: String
    let color: Color
    let icon: String?

    init(text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 3) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9))
            }
            Text(text)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
        )
        .foregroundColor(color)
    }
}

// MARK: - Preview

#Preview("Task Row - Normal") {
    TaskRowView(
        task: .constant(Task(
            title: "Call John about proposal",
            status: .nextAction,
            project: "Website Redesign",
            context: "@phone",
            due: Date().addingTimeInterval(86400),
            priority: .high,
            effort: 30
        )),
        isSelected: false,
        indentationLevel: 0,
        hasSubtasks: false,
        subtaskProgress: nil,
        isExpanded: .constant(false),
        onTap: {},
        onToggleComplete: {},
        onDelete: {},
        onToggleExpansion: nil,
        onAddSubtask: {}
    )
    .padding()
}

#Preview("Task Row - With Subtasks") {
    TaskRowView(
        task: .constant(Task(
            title: "Complete website redesign",
            status: .nextAction,
            project: "Website Redesign"
        )),
        isSelected: false,
        indentationLevel: 0,
        hasSubtasks: true,
        subtaskProgress: (completed: 2, total: 5),
        isExpanded: .constant(true),
        onTap: {},
        onToggleComplete: {},
        onDelete: {},
        onToggleExpansion: {},
        onAddSubtask: {}
    )
    .padding()
}

#Preview("Task Row - Subtask") {
    TaskRowView(
        task: .constant(Task(
            title: "Design homepage mockup",
            status: .completed,
            project: "Website Redesign"
        )),
        isSelected: false,
        indentationLevel: 1,
        hasSubtasks: false,
        subtaskProgress: nil,
        isExpanded: .constant(false),
        onTap: {},
        onToggleComplete: {},
        onDelete: {},
        onToggleExpansion: nil,
        onAddSubtask: {}
    )
    .padding()
}

#Preview("Task Row - Selected") {
    TaskRowView(
        task: .constant(Task(
            title: "Selected task",
            flagged: true
        )),
        isSelected: true,
        indentationLevel: 0,
        hasSubtasks: false,
        subtaskProgress: nil,
        isExpanded: .constant(false),
        onTap: {},
        onToggleComplete: {},
        onDelete: {},
        onToggleExpansion: nil,
        onAddSubtask: {}
    )
    .padding()
}
