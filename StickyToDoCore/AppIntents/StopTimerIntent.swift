//
//  StopTimerIntent.swift
//  StickyToDo
//
//  Siri intent to stop a running timer.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
public struct StopTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Timer"

    static var description = IntentDescription(
        "Stop the currently running timer.",
        categoryName: "Time Tracking",
        searchKeywords: ["stop", "timer", "pause", "end", "clock"]
    )

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task", description: "The task with running timer (optional)")
    var task: TaskEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Stop timer") {
            \.$task
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

        // Find running timer task
        var timerTask: Task?

        if let taskEntity = task {
            timerTask = await MainActor.run {
                taskStore.task(withID: taskEntity.id)
            }
        } else {
            // Find any running timer
            timerTask = await MainActor.run {
                taskStore.tasks.first { $0.isTimerRunning }
            }
        }

        guard var taskWithTimer = timerTask else {
            throw TaskError.noRunningTimer
        }

        // Check if timer is actually running
        if !taskWithTimer.isTimerRunning {
            return .result(
                dialog: "No timer is running for '\(taskWithTimer.title)'",
                view: TimerStoppedView(
                    title: taskWithTimer.title,
                    duration: "0s",
                    totalTime: taskWithTimer.timeSpentDescription ?? "0s"
                )
            )
        }

        // Get duration before stopping
        let duration = taskWithTimer.currentTimerDescription ?? "0s"

        // Stop the timer
        let timeEntry = await MainActor.run {
            timeManager.stopTimer(for: &taskWithTimer)
        }

        // Update task in store
        await MainActor.run {
            taskStore.update(taskWithTimer)
        }

        // Create dialog
        let dialog: IntentDialog = "Stopped timer for '\(taskWithTimer.title)' after \(duration)"

        // Create snippet view
        let snippetView = TimerStoppedView(
            title: taskWithTimer.title,
            duration: duration,
            totalTime: taskWithTimer.timeSpentDescription ?? "0s"
        )

        return .result(dialog: dialog, view: snippetView)
    }
}

/// Snippet view showing timer stopped summary
@available(iOS 16.0, macOS 13.0, *)
public struct TimerStoppedView: View {
    var title: String
    var duration: String
    var totalTime: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "timer.square")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("This Session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(duration)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalTime)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
    }
}
