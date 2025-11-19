//
//  ShowWeeklyReviewIntent.swift
//  StickyToDo
//
//  Siri intent to show the weekly review perspective.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
public struct ShowWeeklyReviewIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Weekly Review"

    static var description = IntentDescription(
        "Open your weekly review to process tasks and plan ahead.",
        categoryName: "Navigation",
        searchKeywords: ["show", "weekly", "review", "planning", "gtd"]
    )

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            throw TaskError.storeUnavailable
        }

        // Gather weekly review statistics
        let stats = await MainActor.run {
            WeeklyReviewStats(from: taskStore)
        }

        // Post notification to navigate to weekly review
        await MainActor.run {
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToWeeklyReview"),
                object: nil
            )
        }

        // Create dialog
        let dialog: IntentDialog = "Opening your weekly review with \(stats.inboxCount) inbox items, \(stats.nextActionsCount) next actions, and \(stats.completedThisWeek) tasks completed this week"

        // Create snippet view
        let snippetView = WeeklyReviewSummaryView(stats: stats)

        return .result(dialog: dialog, view: snippetView)
    }
}

/// Statistics for weekly review
@available(iOS 16.0, macOS 13.0, *)
public struct WeeklyReviewStats {
    let inboxCount: Int
    let nextActionsCount: Int
    let completedThisWeek: Int
    let overdueCount: Int
    let dueThisWeek: Int
    let projectCount: Int

    init(from taskStore: TaskStore) {
        self.inboxCount = taskStore.tasks(withStatus: .inbox).count
        self.nextActionsCount = taskStore.tasks(withStatus: .nextAction).count
        self.overdueCount = taskStore.overdueTasks().count
        self.dueThisWeek = taskStore.dueThisWeekTasks().count

        // Count tasks completed this week
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        self.completedThisWeek = taskStore.tasks.filter { task in
            task.status == .completed && task.modified >= oneWeekAgo
        }.count

        // Count unique projects
        self.projectCount = Set(taskStore.tasks.compactMap { $0.project }).count
    }
}

/// Snippet view showing weekly review summary
@available(iOS 16.0, macOS 13.0, *)
public struct WeeklyReviewSummaryView: View {
    var stats: WeeklyReviewStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("Weekly Review")
                    .font(.headline)
            }

            Divider()

            // Process Section
            VStack(alignment: .leading, spacing: 8) {
                Text("To Process")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack {
                    StatBadge(
                        label: "Inbox",
                        value: stats.inboxCount,
                        color: .blue
                    )
                    StatBadge(
                        label: "Overdue",
                        value: stats.overdueCount,
                        color: .red
                    )
                }
            }

            // Work Section
            VStack(alignment: .leading, spacing: 8) {
                Text("This Week")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack {
                    StatBadge(
                        label: "Due",
                        value: stats.dueThisWeek,
                        color: .orange
                    )
                    StatBadge(
                        label: "Completed",
                        value: stats.completedThisWeek,
                        color: .green
                    )
                }
            }

            // Overview
            HStack(spacing: 16) {
                VStack {
                    Text("\(stats.nextActionsCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Next Actions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack {
                    Text("\(stats.projectCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Projects")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

/// Small stat badge
@available(iOS 16.0, macOS 13.0, *)
public struct StatBadge: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text("\(value)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}
