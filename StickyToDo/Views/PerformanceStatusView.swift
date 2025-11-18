//
//  PerformanceStatusView.swift
//  StickyToDo
//
//  Performance monitoring indicator for task count
//  Shows visual warning when approaching or exceeding thresholds
//

import SwiftUI

/// Visual indicator showing task count performance status
///
/// Displays a color-coded indicator with task count:
/// - Green: Normal (< 500 tasks)
/// - Yellow: Warning (500-999 tasks)
/// - Orange: Alert (1000-1499 tasks)
/// - Red: Critical (>= 1500 tasks)
struct PerformanceStatusView: View {

    /// Task store to monitor
    @ObservedObject var taskStore: TaskStore

    /// Show detailed popover
    @State private var showingDetails = false

    var body: some View {
        Button(action: { showingDetails.toggle() }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text("\(taskStore.taskCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .help(statusHelpText)
        .popover(isPresented: $showingDetails) {
            performanceDetailsView
                .padding()
                .frame(width: 300)
        }
    }

    // MARK: - Details View

    private var performanceDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)

                Text("Performance Status")
                    .font(.headline)

                Spacer()
            }

            Divider()

            // Task counts
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Tasks:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(taskStore.taskCount)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Active:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(taskStore.activeTaskCount)")
                }

                HStack {
                    Text("Completed:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(taskStore.completedTaskCount)")
                }
            }

            Divider()

            // Thresholds
            VStack(alignment: .leading, spacing: 6) {
                Text("Thresholds")
                    .font(.caption)
                    .foregroundColor(.secondary)

                thresholdBar(
                    current: taskStore.taskCount,
                    threshold: 500,
                    label: "Warning",
                    color: .yellow
                )

                thresholdBar(
                    current: taskStore.taskCount,
                    threshold: 1000,
                    label: "Alert",
                    color: .orange
                )

                thresholdBar(
                    current: taskStore.taskCount,
                    threshold: 1500,
                    label: "Critical",
                    color: .red
                )
            }

            // Suggestions
            if let suggestion = taskStore.getPerformanceSuggestion() {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendation")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
            }

            // Archivable tasks count
            let archivableCount = taskStore.archivableTasksCount()
            if archivableCount > 0 {
                Divider()

                HStack {
                    Image(systemName: "archivebox")
                        .foregroundColor(.blue)

                    Text("\(archivableCount) tasks ready to archive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Threshold Bar

    private func thresholdBar(current: Int, threshold: Int, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption2)
                .frame(width: 50, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.6))
                        .frame(
                            width: min(CGFloat(current) / CGFloat(threshold) * geometry.size.width, geometry.size.width),
                            height: 4
                        )
                }
            }
            .frame(height: 4)

            Text("\(threshold)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        let count = taskStore.taskCount

        if count >= 1500 {
            return .red
        } else if count >= 1000 {
            return .orange
        } else if count >= 500 {
            return .yellow
        } else {
            return .green
        }
    }

    private var statusHelpText: String {
        let count = taskStore.taskCount

        if count >= 1500 {
            return "Critical: \(count) tasks - Performance severely impacted"
        } else if count >= 1000 {
            return "Alert: \(count) tasks - Consider archiving completed tasks"
        } else if count >= 500 {
            return "Warning: \(count) tasks - Approaching performance threshold"
        } else {
            return "Normal: \(count) tasks"
        }
    }
}

// MARK: - Preview

#Preview {
    // Mock task store for preview
    let fileIO = MarkdownFileIO(dataDirectory: URL(fileURLWithPath: "/tmp"))
    let taskStore = TaskStore(fileIO: fileIO)

    return PerformanceStatusView(taskStore: taskStore)
        .padding()
}
