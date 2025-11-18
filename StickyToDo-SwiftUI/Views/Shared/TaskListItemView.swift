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
            .accessibilityLabel(task.status == .completed ? "Mark task as incomplete" : "Mark task as complete")
            .accessibilityHint(task.status == .completed ? "Double-tap to reopen this task" : "Double-tap to mark this task as completed")
            .accessibilityAddTraits(.isButton)

            // Task content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)
                    .accessibilityLabel("Task: \(task.title)")
                    .accessibilityAddTraits(task.status == .completed ? .isStaticText : .isHeader)

                // Metadata
                if hasMetadata {
                    HStack(spacing: 8) {
                        if let project = task.project {
                            Label(project, systemImage: "folder")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .accessibilityLabel("Project: \(project)")
                        }

                        if let context = task.context {
                            Label(context, systemImage: "mappin.circle")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .accessibilityLabel("Context: \(context)")
                        }

                        if task.flagged {
                            Image(systemName: "flag.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .accessibilityLabel("Flagged task")
                        }

                        if let due = task.due {
                            Label(formatDate(due), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(task.isOverdue ? .red : .secondary)
                                .accessibilityLabel(task.isOverdue ? "Overdue: \(formatDate(due))" : "Due date: \(formatDate(due))")
                        }

                        if task.priority == .high {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .accessibilityLabel("High priority")
                        }
                    }
                    .accessibilityElement(children: .contain)
                }
            }

            Spacer()

            // Drag handle (visible on hover)
            if isHovering {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .accessibilityLabel("Drag handle")
                    .accessibilityHint("Use to reorder this task")
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(buildAccessibilityLabel())
        .accessibilityValue(task.status == .completed ? "Completed" : "Active")
    }

    // MARK: - Accessibility Helper

    private func buildAccessibilityLabel() -> String {
        var components: [String] = [task.title]

        if let project = task.project {
            components.append("in project \(project)")
        }

        if let context = task.context {
            components.append("in context \(context)")
        }

        if task.flagged {
            components.append("flagged")
        }

        if let due = task.due {
            if task.isOverdue {
                components.append("overdue \(formatDate(due))")
            } else {
                components.append("due \(formatDate(due))")
            }
        }

        if task.priority == .high {
            components.append("high priority")
        }

        return components.joined(separator: ", ")
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
