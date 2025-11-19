//
//  ShowInboxIntent.swift
//  StickyToDo
//
//  Siri intent to open the inbox view and show unprocessed tasks.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
public struct ShowInboxIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Inbox"

    static var description = IntentDescription(
        "Open your inbox to see unprocessed tasks.",
        categoryName: "Navigation",
        searchKeywords: ["show", "open", "inbox", "unprocessed", "new"]
    )

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            throw TaskError.storeUnavailable
        }

        // Get inbox tasks
        let inboxTasks = await MainActor.run {
            taskStore.tasks(withStatus: .inbox)
        }

        // Post notification to navigate to inbox
        await MainActor.run {
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToInbox"),
                object: nil
            )
        }

        // Create dialog
        let count = inboxTasks.count
        let dialog: IntentDialog
        if count == 0 {
            dialog = "Your inbox is empty. Great job!"
        } else if count == 1 {
            dialog = "You have 1 task in your inbox"
        } else {
            dialog = "You have \(count) tasks in your inbox"
        }

        // Create snippet view
        let snippetView = InboxSummaryView(
            taskCount: count,
            tasks: Array(inboxTasks.prefix(5))
        )

        return .result(dialog: dialog, view: snippetView)
    }
}

/// Snippet view showing inbox summary
@available(iOS 16.0, macOS 13.0, *)
public struct InboxSummaryView: View {
    var taskCount: Int
    var tasks: [Task]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Inbox")
                    .font(.headline)
                Spacer()
                Text("\(taskCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            if taskCount > 0 {
                Divider()

                ForEach(tasks) { task in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Text(task.title)
                            .font(.subheadline)
                            .lineLimit(1)
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
}
