//
//  PERFORMANCE_MONITORING_USAGE_EXAMPLES.swift
//  StickyToDo
//
//  Code examples for using the performance monitoring API
//

import Foundation

// MARK: - Example 1: Basic Status Check

func example1_checkStatus() {
    let taskStore = TaskStore(fileIO: fileIO)

    // Check if at various thresholds
    if taskStore.isAtCriticalThreshold {
        print("🔴 CRITICAL: \(taskStore.taskCount) tasks!")
    } else if taskStore.isAtAlertThreshold {
        print("🟠 ALERT: \(taskStore.taskCount) tasks")
    } else if taskStore.isAtWarningThreshold {
        print("🟡 WARNING: \(taskStore.taskCount) tasks")
    } else {
        print("🟢 Normal: \(taskStore.taskCount) tasks")
    }
}

// MARK: - Example 2: Get Detailed Metrics

func example2_getMetrics() {
    let taskStore = TaskStore(fileIO: fileIO)
    let metrics = taskStore.getPerformanceMetrics()

    print("Total Tasks: \(metrics["taskCount"] ?? 0)")
    print("Active Tasks: \(metrics["activeTaskCount"] ?? 0)")
    print("Completed Tasks: \(metrics["completedTaskCount"] ?? 0)")
    print("Level: \(metrics["level"] ?? "unknown")")
    print("Progress to Warning: \(metrics["percentOfWarning"] ?? 0)%")
    print("Progress to Alert: \(metrics["percentOfAlert"] ?? 0)%")
}

// MARK: - Example 3: Show User Suggestion

func example3_showSuggestion() {
    let taskStore = TaskStore(fileIO: fileIO)

    if let suggestion = taskStore.getPerformanceSuggestion() {
        // Display in UI
        showAlert(title: "Performance Suggestion", message: suggestion)
    }
}

// MARK: - Example 4: Archive Old Tasks

func example4_archiveOldTasks() {
    let taskStore = TaskStore(fileIO: fileIO)

    // Check how many tasks can be archived
    let archivableCount = taskStore.archivableTasksCount()

    if archivableCount > 0 {
        print("Found \(archivableCount) tasks eligible for archiving")

        // Get archivable tasks (completed and >30 days old)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let tasksToArchive = taskStore.tasks.filter { task in
            task.status == .completed && task.modified < thirtyDaysAgo
        }

        // Archive them (your archiving logic here)
        archiveTasks(tasksToArchive)

        // Or delete them if no archiving system
        taskStore.deleteBatch(tasksToArchive)

        print("Archived \(archivableCount) old completed tasks")
    }
}

// MARK: - Example 5: Monitor During Bulk Operations

func example5_bulkOperationMonitoring() {
    let taskStore = TaskStore(fileIO: fileIO)

    // Setup logger to see performance warnings
    taskStore.setLogger { message in
        print("[TaskStore] \(message)")
    }

    // Perform bulk add
    for i in 1...600 {
        let task = Task(title: "Task \(i)", status: .inbox)
        taskStore.add(task)
    }

    // Monitor will automatically log warning when crossing 500 threshold
    // You'll see: "⚠️ WARNING: Task count approaching performance threshold..."
}

// MARK: - Example 6: Display in UI (SwiftUI)

import SwiftUI

struct Example6_DisplayInUI: View {
    @ObservedObject var taskStore: TaskStore

    var body: some View {
        VStack(spacing: 16) {
            // Performance badge
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)

                Text("Tasks: \(taskStore.taskCount)")
                    .fontWeight(.semibold)
            }

            // Progress bar to next threshold
            if !taskStore.isAtAlertThreshold {
                VStack(alignment: .leading) {
                    Text("Progress to Alert Threshold")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))

                            Rectangle()
                                .fill(statusColor)
                                .frame(width: progressWidth(geometry.size.width))
                        }
                    }
                    .frame(height: 8)
                    .cornerRadius(4)

                    Text("\(taskStore.taskCount) / 1000")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Show suggestion if available
            if let suggestion = taskStore.getPerformanceSuggestion() {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(statusColor)

                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(statusColor.opacity(0.1))
                .cornerRadius(8)
            }

            // Archive button if tasks available
            if taskStore.archivableTasksCount() > 0 {
                Button {
                    archiveOldCompletedTasks()
                } label: {
                    Label("Archive \(taskStore.archivableTasksCount()) Old Tasks",
                          systemImage: "archivebox")
                }
            }
        }
        .padding()
    }

    private var statusColor: Color {
        if taskStore.isAtCriticalThreshold {
            return .red
        } else if taskStore.isAtAlertThreshold {
            return .orange
        } else if taskStore.isAtWarningThreshold {
            return .yellow
        } else {
            return .green
        }
    }

    private func progressWidth(_ maxWidth: CGFloat) -> CGFloat {
        let progress = Double(taskStore.taskCount) / 1000.0
        return CGFloat(min(progress, 1.0)) * maxWidth
    }

    private func archiveOldCompletedTasks() {
        // Your archiving logic
    }
}

// MARK: - Example 7: Conditional Features Based on Performance

func example7_adaptiveFeatures() {
    let taskStore = TaskStore(fileIO: fileIO)

    // Disable expensive features when at high task count
    if taskStore.isAtAlertThreshold {
        // Reduce refresh rate
        setAutoRefreshInterval(60) // 60 seconds instead of 5

        // Disable real-time search
        setSearchDebounce(1.0) // 1 second debounce

        // Show performance mode indicator
        showPerformanceModeIndicator()

        print("Performance mode enabled due to high task count")
    }
}

// MARK: - Example 8: Automatic Cleanup Workflow

func example8_automaticCleanup() async {
    let taskStore = TaskStore(fileIO: fileIO)

    // Check if cleanup is recommended
    guard taskStore.isAtAlertThreshold else {
        print("No cleanup needed")
        return
    }

    let archivableCount = taskStore.archivableTasksCount()

    // Ask user for permission
    let shouldArchive = await askUserPermission(
        message: "Archive \(archivableCount) old completed tasks?",
        detail: "This will improve performance"
    )

    if shouldArchive {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let tasksToArchive = taskStore.tasks.filter { task in
            task.status == .completed && task.modified < thirtyDaysAgo
        }

        // Archive to separate file
        try? await archiveToFile(tasksToArchive)

        // Remove from active store
        taskStore.deleteBatch(tasksToArchive)

        print("Archived \(archivableCount) tasks - performance improved!")
    }
}

// MARK: - Example 9: Export Performance Report

func example9_exportPerformanceReport() {
    let taskStore = TaskStore(fileIO: fileIO)
    let metrics = taskStore.getPerformanceMetrics()

    let report = """
    STICKY TODO PERFORMANCE REPORT
    Generated: \(Date())

    Task Statistics:
    - Total Tasks: \(metrics["taskCount"] ?? 0)
    - Active Tasks: \(metrics["activeTaskCount"] ?? 0)
    - Completed Tasks: \(metrics["completedTaskCount"] ?? 0)
    - Archivable Tasks: \(taskStore.archivableTasksCount())

    Performance Status:
    - Current Level: \(metrics["level"] ?? "unknown")
    - Warning Threshold (500): \(taskStore.isAtWarningThreshold ? "EXCEEDED" : "OK")
    - Alert Threshold (1000): \(taskStore.isAtAlertThreshold ? "EXCEEDED" : "OK")
    - Critical Threshold (1500): \(taskStore.isAtCriticalThreshold ? "EXCEEDED" : "OK")

    Progress:
    - % of Warning Threshold: \(String(format: "%.1f", metrics["percentOfWarning"] as? Double ?? 0))%
    - % of Alert Threshold: \(String(format: "%.1f", metrics["percentOfAlert"] as? Double ?? 0))%

    Recommendation:
    \(taskStore.getPerformanceSuggestion() ?? "No action needed")
    """

    // Save to file
    try? report.write(to: getReportFileURL(), atomically: true, encoding: .utf8)

    print(report)
}

// MARK: - Example 10: Performance Dashboard Widget

class PerformanceDashboardWidget: ObservableObject {
    @Published var taskStore: TaskStore
    @Published var history: [(Date, Int)] = []

    init(taskStore: TaskStore) {
        self.taskStore = taskStore
    }

    func recordSnapshot() {
        history.append((Date(), taskStore.taskCount))

        // Keep last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        history = history.filter { $0.0 > thirtyDaysAgo }
    }

    func getGrowthRate() -> Double {
        guard history.count >= 2 else { return 0 }

        let oldest = history.first!
        let newest = history.last!

        let daysDiff = Calendar.current.dateComponents([.day], from: oldest.0, to: newest.0).day ?? 1
        let taskDiff = newest.1 - oldest.1

        return Double(taskDiff) / Double(daysDiff)
    }

    func predictAlertDate() -> Date? {
        let currentCount = taskStore.taskCount
        guard currentCount < 1000 else { return nil }

        let growthRate = getGrowthRate()
        guard growthRate > 0 else { return nil }

        let tasksUntilAlert = 1000 - currentCount
        let daysUntilAlert = Int(Double(tasksUntilAlert) / growthRate)

        return Calendar.current.date(byAdding: .day, value: daysUntilAlert, to: Date())
    }
}

// MARK: - Helper Functions (Mock)

private func showAlert(title: String, message: String) {
    print("\(title): \(message)")
}

private func archiveTasks(_ tasks: [Task]) {
    print("Archiving \(tasks.count) tasks...")
}

private func setAutoRefreshInterval(_ seconds: Int) {
    print("Set refresh interval to \(seconds)s")
}

private func setSearchDebounce(_ seconds: Double) {
    print("Set search debounce to \(seconds)s")
}

private func showPerformanceModeIndicator() {
    print("Showing performance mode indicator")
}

private func askUserPermission(message: String, detail: String) async -> Bool {
    print("\(message) - \(detail)")
    return true
}

private func archiveToFile(_ tasks: [Task]) async throws {
    print("Archiving \(tasks.count) tasks to file...")
}

private func getReportFileURL() -> URL {
    return URL(fileURLWithPath: "/tmp/performance-report.txt")
}

private var fileIO: MarkdownFileIO {
    return MarkdownFileIO(dataDirectory: URL(fileURLWithPath: "/tmp"))
}
