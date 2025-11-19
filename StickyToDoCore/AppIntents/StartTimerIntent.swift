//
//  StartTimerIntent.swift
//  StickyToDo
//
//  Siri intent to start a timer for a task.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
public struct StartTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Timer"

    static var description = IntentDescription(
        "Start a timer for a task to track time spent.",
        categoryName: "Time Tracking",
        searchKeywords: ["start", "timer", "track", "time", "clock"]
    )

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task", description: "The task to time")
    var task: TaskEntity?

    @Parameter(title: "Task Title", description: "Find task by title")
    var taskTitle: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Start timer for \(\.$task)") {
            \.$taskTitle
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            throw TaskError.storeUnavailable
        }

        // Access time tracking manager
        guard let timeManager = AppDelegate.shared?.timeTrackingManager else {
            throw TaskError.storeUnavailable
        }

        // Find the task
        var targetTask: Task?

        if let taskEntity = task {
            targetTask = await MainActor.run {
                taskStore.task(withID: taskEntity.id)
            }
        } else if let title = taskTitle {
            let matches = await MainActor.run {
                taskStore.tasks(withTitle: title)
            }
            targetTask = matches.first
        }

        guard var taskToTime = targetTask else {
            throw TaskError.taskNotFound
        }

        // Check if timer is already running for this task
        if taskToTime.isTimerRunning {
            let duration = taskToTime.currentTimerDescription ?? "0s"
            return .result(
                dialog: "Timer is already running for '\(taskToTime.title)' (\(duration))",
                view: TimerStatusView(
                    title: taskToTime.title,
                    isRunning: true,
                    duration: duration
                )
            )
        }

        // Stop any other running timer first
        await MainActor.run {
            let runningTasks = taskStore.tasks.filter { $0.isTimerRunning }
            for var runningTask in runningTasks {
                _ = timeManager.stopTimer(for: &runningTask)
                taskStore.update(runningTask)
            }
        }

        // Start timer for this task
        await MainActor.run {
            timeManager.startTimer(for: &taskToTime)
            taskStore.update(taskToTime)
        }

        // Create dialog
        let dialog: IntentDialog = "Started timer for '\(taskToTime.title)'"

        // Create snippet view
        let snippetView = TimerStatusView(
            title: taskToTime.title,
            isRunning: true,
            duration: "Just started"
        )

        return .result(dialog: dialog, view: snippetView)
    }
}

/// Snippet view showing timer status
@available(iOS 16.0, macOS 13.0, *)
public struct TimerStatusView: View {
    var title: String
    var isRunning: Bool
    var duration: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isRunning ? "timer" : "timer.square")
                    .font(.title2)
                    .foregroundColor(isRunning ? .green : .gray)
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }

            HStack {
                Text(isRunning ? "Running" : "Stopped")
                    .font(.subheadline)
                    .foregroundColor(isRunning ? .green : .gray)
                Spacer()
                Text(duration)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isRunning ? .green : .gray)
            }
        }
        .padding()
    }
}
