//
//  ShowFlaggedTasksIntent.swift
//  StickyToDo
//
//  Siri intent to show all flagged tasks.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
public struct ShowFlaggedTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Flagged Tasks"

    static var description = IntentDescription(
        "View all tasks marked as flagged for attention.",
        categoryName: "Navigation",
        searchKeywords: ["show", "flagged", "starred", "important", "priority"]
    )

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Project Filter", description: "Filter by project")
    var projectFilter: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Show Flagged Tasks") {
            \.$projectFilter
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            throw TaskError.storeUnavailable
        }

        // Get flagged tasks
        var flaggedTasks = await MainActor.run {
            taskStore.flaggedTasks()
        }

        // Filter by project if specified
        if let project = projectFilter {
            flaggedTasks = flaggedTasks.filter { $0.project == project }
        }

        // Post notification to navigate to flagged view
        await MainActor.run {
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToFlagged"),
                object: projectFilter
            )
        }

        // Create dialog
        let count = flaggedTasks.count
        let dialog: IntentDialog

        if let project = projectFilter {
            if count == 0 {
                dialog = "No flagged tasks in \(project)"
            } else if count == 1 {
                dialog = "You have 1 flagged task in \(project)"
            } else {
                dialog = "You have \(count) flagged tasks in \(project)"
            }
        } else {
            if count == 0 {
                dialog = "No flagged tasks. Flag important tasks to see them here!"
            } else if count == 1 {
                dialog = "You have 1 flagged task"
            } else {
                dialog = "You have \(count) flagged tasks"
            }
        }

        // Create snippet view
        let snippetView = FlaggedTasksSummaryView(
            taskCount: count,
            tasks: Array(flaggedTasks.prefix(5)),
            project: projectFilter
        )

        return .result(dialog: dialog, view: snippetView)
    }
}

/// Snippet view showing flagged tasks summary
@available(iOS 16.0, macOS 13.0, *)
public struct FlaggedTasksSummaryView: View {
    var taskCount: Int
    var tasks: [Task]
    var project: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text(project ?? "Flagged")
                    .font(.headline)
                Spacer()
                Text("\(taskCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }

            if taskCount > 0 {
                Divider()

                ForEach(tasks) { task in
                    HStack {
                        Circle()
                            .fill(priorityColor(task.priority))
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            if let proj = task.project, project == nil {
                                Text(proj)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let ctx = task.context {
                                Text(ctx)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if task.isDueToday {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if task.isOverdue {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                if taskCount > 5 {
                    Text("and \(taskCount - 5) more...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}
