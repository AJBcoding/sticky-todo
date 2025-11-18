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

    /// Callback when task is tapped
    var onTap: () -> Void

    /// Callback when task completion state changes
    var onToggleComplete: () -> Void

    /// Callback when task should be deleted
    var onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
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
        onTap: {},
        onToggleComplete: {},
        onDelete: {}
    )
    .padding()
}

#Preview("Task Row - Completed") {
    TaskRowView(
        task: .constant(Task(
            title: "Completed task with long title that wraps",
            status: .completed,
            project: "Q4 Planning"
        )),
        isSelected: false,
        onTap: {},
        onToggleComplete: {},
        onDelete: {}
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
        onTap: {},
        onToggleComplete: {},
        onDelete: {}
    )
    .padding()
}
