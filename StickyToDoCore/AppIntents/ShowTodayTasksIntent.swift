//
//  ShowTodayTasksIntent.swift
//  StickyToDo
//
//  Siri intent to show tasks due today.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
public struct ShowTodayTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Today's Tasks"

    static var description = IntentDescription(
        "View all tasks due today.",
        categoryName: "Navigation",
        searchKeywords: ["show", "today", "due", "tasks", "daily"]
    )

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Include Overdue", description: "Also show overdue tasks", default: true)
    var includeOverdue: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Show Today's Tasks") {
            \.$includeOverdue
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            throw TaskError.storeUnavailable
        }

        // Get today's tasks
        var todayTasks = await MainActor.run {
            taskStore.dueTodayTasks()
        }

        // Get overdue tasks if requested
        var overdueTasks: [Task] = []
        if includeOverdue {
            overdueTasks = await MainActor.run {
                taskStore.overdueTasks()
            }
        }

        // Post notification to navigate to today view
        await MainActor.run {
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToToday"),
                object: nil
            )
        }

        // Create dialog
        let todayCount = todayTasks.count
        let overdueCount = overdueTasks.count
        let totalCount = todayCount + overdueCount

        let dialog: IntentDialog
        if totalCount == 0 {
            dialog = "You have no tasks due today. Enjoy your day!"
        } else if includeOverdue && overdueCount > 0 {
            if todayCount == 0 {
                dialog = "You have \(overdueCount) overdue tasks"
            } else {
                dialog = "You have \(todayCount) tasks due today and \(overdueCount) overdue"
            }
        } else {
            dialog = "You have \(todayCount) tasks due today"
        }

        // Combine tasks for snippet
        let allTasks = overdueTasks + todayTasks

        // Create snippet view
        let snippetView = TodayTasksView(
            todayCount: todayCount,
            overdueCount: overdueCount,
            tasks: Array(allTasks.prefix(5))
        )

        return .result(dialog: dialog, view: snippetView)
    }
}

/// Snippet view showing today's tasks
@available(iOS 16.0, macOS 13.0, *)
public struct TodayTasksView: View {
    var todayCount: Int
    var overdueCount: Int
    var tasks: [Task]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Today")
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing) {
                    if overdueCount > 0 {
                        Text("\(overdueCount) overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Text("\(todayCount) due")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }

            if !tasks.isEmpty {
                Divider()

                ForEach(tasks) { task in
                    HStack {
                        Circle()
                            .fill(task.isOverdue ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            if let proj = task.project, let ctx = task.context {
                                Text("\(proj) • \(ctx)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if let proj = task.project {
                                Text(proj)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if task.flagged {
                            Image(systemName: "flag.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                if tasks.count > 5 {
                    Text("and \(tasks.count - 5) more...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}
