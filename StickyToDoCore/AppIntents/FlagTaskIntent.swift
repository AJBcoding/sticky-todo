//
//  FlagTaskIntent.swift
//  StickyToDo
//
//  Siri intent to flag or unflag a task for attention.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
public struct FlagTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Flag Task"

    static var description = IntentDescription(
        "Flag a task for attention or unflag it.",
        categoryName: "Tasks",
        searchKeywords: ["flag", "star", "mark", "important", "priority"]
    )

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task", description: "The task to flag")
    var task: TaskEntity?

    @Parameter(title: "Task Title", description: "Find task by title")
    var taskTitle: String?

    @Parameter(title: "Flagged", description: "Set task as flagged or unflagged", default: true)
    var flagged: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Flag \(\.$task)") {
            \.$taskTitle
            \.$flagged
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            throw TaskError.storeUnavailable
        }

        // Find the task to flag
        var taskToFlag: Task?

        if let taskEntity = task {
            taskToFlag = await MainActor.run {
                taskStore.task(withID: taskEntity.id)
            }
        } else if let title = taskTitle {
            let matches = await MainActor.run {
                taskStore.tasks(withTitle: title)
            }
            taskToFlag = matches.first
        }

        guard var targetTask = taskToFlag else {
            throw TaskError.taskNotFound
        }

        // Check if task is already in desired state
        if targetTask.flagged == flagged {
            let state = flagged ? "already flagged" : "not flagged"
            return .result(
                dialog: "'\(targetTask.title)' is \(state)",
                view: FlagTaskResultView(
                    title: targetTask.title,
                    flagged: targetTask.flagged,
                    project: targetTask.project
                )
            )
        }

        // Update flag state
        await MainActor.run {
            targetTask.flagged = flagged
            taskStore.update(targetTask)

            // Donate intent for Siri suggestions
            donateIntent(for: targetTask)
        }

        // Create confirmation dialog
        let dialog: IntentDialog = flagged
            ? "Flagged '\(targetTask.title)'"
            : "Unflagged '\(targetTask.title)'"

        // Create snippet view
        let snippetView = FlagTaskResultView(
            title: targetTask.title,
            flagged: flagged,
            project: targetTask.project
        )

        return .result(dialog: dialog, view: snippetView)
    }

    private func donateIntent(for task: Task) {
        // Donate this intent for Siri suggestions
        let intent = FlagTaskIntent()
        intent.task = TaskEntity.from(task: task)
        intent.flagged = task.flagged
        // Intent donation happens automatically when perform() is called
    }
}

/// Result view shown after flagging a task
@available(iOS 16.0, macOS 13.0, *)
public struct FlagTaskResultView: View {
    var title: String
    var flagged: Bool
    var project: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: flagged ? "flag.fill" : "flag")
                    .font(.title2)
                    .foregroundColor(flagged ? .orange : .gray)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)

                    if let proj = project {
                        Text(proj)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack {
                Text(flagged ? "Flagged" : "Not Flagged")
                    .font(.subheadline)
                    .foregroundColor(flagged ? .orange : .secondary)
                Spacer()
                if flagged {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
    }
}
