//
//  CompleteTaskIntent.swift
//  StickyToDo
//
//  Siri intent to mark a task as completed.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
public struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"

    static var description = IntentDescription(
        "Mark a task as completed.",
        categoryName: "Tasks",
        searchKeywords: ["complete", "finish", "done", "task", "check"]
    )

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task", description: "The task to complete")
    var task: TaskEntity?

    @Parameter(title: "Task Title", description: "Find task by title")
    var taskTitle: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Complete \(\.$task)") {
            \.$taskTitle
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            throw TaskError.storeUnavailable
        }

        // Find the task to complete
        var taskToComplete: Task?

        if let taskEntity = task {
            taskToComplete = await MainActor.run {
                taskStore.task(withID: taskEntity.id)
            }
        } else if let title = taskTitle {
            let matches = await MainActor.run {
                taskStore.tasks(withTitle: title)
            }
            taskToComplete = matches.first
        }

        guard var targetTask = taskToComplete else {
            throw TaskError.taskNotFound
        }

        // Check if task is already completed
        if targetTask.status == .completed {
            return .result(dialog: "'\(targetTask.title)' is already completed")
        }

        // Mark task as completed
        await MainActor.run {
            targetTask.complete()
            taskStore.update(targetTask)
        }

        // Create confirmation dialog
        let dialog: IntentDialog = "Completed '\(targetTask.title)'"

        return .result(dialog: dialog)
    }
}

/// Intent to disambiguate when multiple tasks match
@available(iOS 16.0, macOS 13.0, *)
public struct CompleteTaskDisambiguationIntent: AppIntent {
    static var title: LocalizedStringResource = "Choose Task to Complete"

    @Parameter(title: "Task")
    var task: TaskEntity

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
