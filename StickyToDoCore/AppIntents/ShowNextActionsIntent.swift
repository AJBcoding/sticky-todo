//
//  ShowNextActionsIntent.swift
//  StickyToDo
//
//  Siri intent to open the next actions view.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
struct ShowNextActionsIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Next Actions"

    static var description = IntentDescription(
        "Open your next actions list to see actionable tasks.",
        categoryName: "Navigation",
        searchKeywords: ["show", "open", "next", "actions", "actionable", "tasks"]
    )

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Context Filter", description: "Filter by context")
    var contextFilter: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Show Next Actions") {
            \.$contextFilter
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            throw TaskError.storeUnavailable
        }

        // Get next action tasks
        var nextActions = await MainActor.run {
            taskStore.tasks(withStatus: .nextAction)
        }

        // Filter by context if specified
        if let context = contextFilter {
            nextActions = nextActions.filter { $0.context == context }
        }

        // Post notification to navigate to next actions
        await MainActor.run {
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToNextActions"),
                object: contextFilter
            )
        }

        // Create dialog
        let count = nextActions.count
        let dialog: IntentDialog
        if let context = contextFilter {
            if count == 0 {
                dialog = "No next actions for \(context)"
            } else if count == 1 {
                dialog = "You have 1 next action for \(context)"
            } else {
                dialog = "You have \(count) next actions for \(context)"
            }
        } else {
            if count == 0 {
                dialog = "No next actions. Time to process your inbox!"
            } else if count == 1 {
                dialog = "You have 1 next action"
            } else {
                dialog = "You have \(count) next actions"
            }
        }

        // Create snippet view
        let snippetView = NextActionsSummaryView(
            taskCount: count,
            tasks: Array(nextActions.prefix(5)),
            context: contextFilter
        )

        return .result(dialog: dialog, view: snippetView)
    }
}

/// Snippet view showing next actions summary
@available(iOS 16.0, macOS 13.0, *)
struct NextActionsSummaryView: View {
    var taskCount: Int
    var tasks: [Task]
    var context: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.circle")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text(context ?? "Next Actions")
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
                            if let proj = task.project {
                                Text(proj)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
