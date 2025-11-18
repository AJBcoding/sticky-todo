//
//  TaskListItemView.swift
//  StickyToDo-SwiftUI
//
//  Reusable task list item view with drag support.
//

import SwiftUI

/// A list item view for displaying a task with drag-drop support
struct TaskListItemView: View {

    // MARK: - Properties

    let task: Task
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    // MARK: - State

    @State private var isHovering = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button(action: onToggleComplete) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == .completed ? .green : .secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)

            // Task content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)

                // Metadata
                if hasMetadata {
                    HStack(spacing: 8) {
                        if let project = task.project {
                            Label(project, systemImage: "folder")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        if let context = task.context {
                            Label(context, systemImage: "mappin.circle")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        if task.flagged {
                            Image(systemName: "flag.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }

                        if let due = task.due {
                            Label(formatDate(due), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(task.isOverdue ? .red : .secondary)
                        }

                        if task.priority == .high {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            Spacer()

            // Drag handle (visible on hover)
            if isHovering {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .taskDraggable(task)
    }

    // MARK: - Computed Properties

    private var hasMetadata: Bool {
        task.project != nil || task.context != nil || task.flagged || task.due != nil || task.priority == .high
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Task List Item") {
    VStack(spacing: 0) {
        TaskListItemView(
            task: Task(
                title: "Complete project proposal",
                status: .nextAction,
                project: "Big Project",
                context: "@office",
                due: Date(),
                flagged: true,
                priority: .high
            ),
            isSelected: false,
            onTap: { print("Tapped") },
            onToggleComplete: { print("Toggle") }
        )

        TaskListItemView(
            task: Task(
                title: "Call John about meeting",
                status: .nextAction,
                context: "@phone"
            ),
            isSelected: true,
            onTap: { print("Tapped") },
            onToggleComplete: { print("Toggle") }
        )

        TaskListItemView(
            task: Task(
                title: "Completed task",
                status: .completed
            ),
            isSelected: false,
            onTap: { print("Tapped") },
            onToggleComplete: { print("Toggle") }
        )
    }
    .padding()
    .frame(width: 400)
}
