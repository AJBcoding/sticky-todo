//
//  AddTaskIntent.swift
//  StickyToDo
//
//  Siri intent for quickly adding a new task via voice or Shortcuts.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"

    static var description = IntentDescription(
        "Quickly add a new task to your inbox.",
        categoryName: "Tasks",
        searchKeywords: ["add", "create", "new", "task", "todo", "capture"]
    )

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Title", description: "The task title")
    var title: String

    @Parameter(title: "Notes", description: "Additional notes for the task", default: "")
    var notes: String?

    @Parameter(title: "Project", description: "Project to assign the task to")
    var project: String?

    @Parameter(title: "Context", description: "Context for completing the task")
    var context: String?

    @Parameter(title: "Priority", description: "Task priority level", default: .medium)
    var priority: PriorityOption

    @Parameter(title: "Due Date", description: "When the task is due")
    var dueDate: Date?

    @Parameter(title: "Flag Task", description: "Mark task as flagged for attention", default: false)
    var flagged: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title)") {
            \.$notes
            \.$project
            \.$context
            \.$priority
            \.$dueDate
            \.$flagged
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            throw TaskError.storeUnavailable
        }

        // Create new task
        let task = Task(
            title: title,
            notes: notes ?? "",
            status: .inbox,
            project: project,
            context: context,
            due: dueDate,
            flagged: flagged,
            priority: priority.toPriority
        )

        // Add to store
        await MainActor.run {
            taskStore.add(task)
        }

        // Create confirmation dialog
        let dialog: IntentDialog
        if let proj = project {
            dialog = "Added '\(title)' to \(proj)"
        } else {
            dialog = "Added '\(title)' to your inbox"
        }

        // Create snippet view
        let snippetView = AddTaskResultView(
            title: title,
            project: project,
            context: context,
            priority: priority.rawValue,
            dueDate: dueDate
        )

        return .result(dialog: dialog, view: snippetView)
    }
}

/// Result view shown after adding a task
@available(iOS 16.0, macOS 13.0, *)
struct AddTaskResultView: View {
    var title: String
    var project: String?
    var context: String?
    var priority: String
    var dueDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            HStack {
                Label(priority.capitalized, systemImage: priorityIcon)
                    .font(.caption)
                    .foregroundColor(priorityColor)

                if let proj = project {
                    Label(proj, systemImage: "folder")
                        .font(.caption)
                }

                if let ctx = context {
                    Label(ctx, systemImage: "tag")
                        .font(.caption)
                }
            }

            if let due = dueDate {
                Label(due.formatted(date: .abbreviated, time: .omitted),
                      systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var priorityIcon: String {
        switch priority.lowercased() {
        case "high": return "exclamationmark.3"
        case "low": return "minus.circle"
        default: return "circle"
        }
    }

    private var priorityColor: Color {
        switch priority.lowercased() {
        case "high": return .red
        case "low": return .blue
        default: return .orange
        }
    }
}

/// Errors that can occur when working with tasks
@available(iOS 16.0, macOS 13.0, *)
enum TaskError: Error, CustomLocalizedStringResourceConvertible {
    case storeUnavailable
    case taskNotFound
    case invalidInput
    case noRunningTimer

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .storeUnavailable:
            return "Task store is not available"
        case .taskNotFound:
            return "Task not found"
        case .invalidInput:
            return "Invalid input provided"
        case .noRunningTimer:
            return "No timer is currently running"
        }
    }
}
