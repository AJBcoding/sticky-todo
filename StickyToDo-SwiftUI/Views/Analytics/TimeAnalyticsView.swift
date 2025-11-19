//
//  TimeAnalyticsView.swift
//  StickyToDo-SwiftUI
//
//  Time tracking analytics dashboard showing time spent per project, context, day, and task.
//

import SwiftUI
import StickyToDoCore

/// Analytics dashboard for time tracking data
///
/// Displays:
/// - Time spent per project
/// - Time spent per context
/// - Time spent per day/week
/// - Most time-consuming tasks
/// - Average task completion time
struct TimeAnalyticsView: View {

    // MARK: - Environment

    @ObservedObject var timeTracker: TimeTrackingManager
    let tasks: [Task]

    // MARK: - State

    @State private var selectedPeriod: TimePeriod = .week
    @State private var analytics: TimeTrackingManager.Analytics?
    @State private var showExportSheet: Bool = false
    @State private var exportedCSV: String = ""

    // MARK: - Time Period

    enum TimePeriod: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"

        var dateRange: ClosedRange<Date>? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .today:
                let start = calendar.startOfDay(for: now)
                let end = calendar.date(byAdding: .day, value: 1, to: start)!
                return start...end
            case .week:
                let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
                return start...end
            case .month:
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                let end = calendar.date(byAdding: .month, value: 1, to: start)!
                return start...end
            case .all:
                return nil
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                header

                // Period selector
                periodSelector

                // Summary cards
                summaryCards

                // Charts section
                chartsSection

                // Top tasks section
                topTasksSection

                // Export button
                exportSection
            }
            .padding()
        }
        .navigationTitle("Time Analytics")
        .onAppear {
            calculateAnalytics()
        }
        .onChange(of: selectedPeriod) { _ in
            calculateAnalytics()
        }
        .sheet(isPresented: $showExportSheet) {
            exportSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Tracking Analytics")
                .font(.largeTitle)
                .bold()
                .accessibilityAddTraits(.isHeader)

            Text("Insights into your productivity and time allocation")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker("Time Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Time period filter")
        .accessibilityHint("Select time range for time tracking analytics")
        .accessibilityValue(selectedPeriod.rawValue)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "Total Time",
                value: TimeTrackingManager.formatDuration(analytics?.totalTime ?? 0),
                icon: "clock.fill",
                color: .blue
            )

            SummaryCard(
                title: "Entries",
                value: "\(analytics?.entryCount ?? 0)",
                icon: "list.bullet",
                color: .green
            )

            SummaryCard(
                title: "Avg/Task",
                value: TimeTrackingManager.formatDuration(analytics?.averageTimePerTask ?? 0),
                icon: "chart.bar.fill",
                color: .orange
            )
        }
    }

    // MARK: - Charts Section

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time by Project
            if let analytics = analytics, !analytics.timeByProject.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time by Project")
                        .font(.headline)

                    ForEach(sortedProjects, id: \.key) { project, duration in
                        BarChartRow(
                            label: project,
                            value: duration,
                            maxValue: analytics.timeByProject.values.max() ?? 1,
                            color: .purple
                        )
                    }
                }
                .padding()
                .background(Color(.textBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            }

            // Time by Context
            if let analytics = analytics, !analytics.timeByContext.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time by Context")
                        .font(.headline)

                    ForEach(sortedContexts, id: \.key) { context, duration in
                        BarChartRow(
                            label: context,
                            value: duration,
                            maxValue: analytics.timeByContext.values.max() ?? 1,
                            color: .blue
                        )
                    }
                }
                .padding()
                .background(Color(.textBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            }

            // Time by Date
            if let analytics = analytics, !analytics.timeByDate.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time by Date")
                        .font(.headline)

                    ForEach(sortedDates, id: \.key) { date, duration in
                        BarChartRow(
                            label: formatDate(date),
                            value: duration,
                            maxValue: analytics.timeByDate.values.max() ?? 1,
                            color: .green
                        )
                    }
                }
                .padding()
                .background(Color(.textBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Top Tasks Section

    private var topTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Time-Consuming Tasks")
                .font(.headline)

            let topTasks = timeTracker.topTasks(count: 10, from: tasks)

            if topTasks.isEmpty {
                Text("No time entries yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(topTasks, id: \.task.id) { taskData in
                    TaskTimeRow(
                        task: taskData.task,
                        duration: taskData.duration
                    )
                }
            }
        }
        .padding()
        .background(Color(.textBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                exportToCSV()
            }) {
                Label("Export to CSV", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Export time entries to CSV")
            .accessibilityHint("Export time tracking data for the selected period as a CSV file")

            Text("Export time entries for the selected period")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Export Sheet

    private var exportSheet: some View {
        VStack(spacing: 16) {
            Text("Exported Time Entries")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            TextEditor(text: .constant(exportedCSV))
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 300)
                .border(Color.gray.opacity(0.3))
                .accessibilityLabel("Exported CSV data")
                .accessibilityHint("Time entries in CSV format")

            HStack {
                Button("Copy to Clipboard") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(exportedCSV, forType: .string)
                }
                .accessibilityLabel("Copy to clipboard")
                .accessibilityHint("Copy CSV data to clipboard")

                Button("Save to File") {
                    saveCSVToFile()
                }
                .accessibilityLabel("Save to file")
                .accessibilityHint("Save CSV data to a file")

                Spacer()

                Button("Done") {
                    showExportSheet = false
                }
                .accessibilityLabel("Done")
                .accessibilityHint("Close export dialog")
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }

    // MARK: - Helper Methods

    private func calculateAnalytics() {
        // Filter tasks and entries by selected period
        let entries: [TimeEntry]
        if let range = selectedPeriod.dateRange {
            entries = timeTracker.timeEntries.filter { entry in
                entry.startTime >= range.lowerBound && entry.startTime <= range.upperBound
            }
        } else {
            entries = timeTracker.timeEntries
        }

        // Create a temporary tracker with filtered entries
        let tempTracker = TimeTrackingManager()
        tempTracker.loadEntries(entries)

        analytics = tempTracker.calculateAnalytics(for: tasks)
    }

    private var sortedProjects: [(key: String, value: TimeInterval)] {
        guard let analytics = analytics else { return [] }
        return analytics.timeByProject.sorted { $0.value > $1.value }
    }

    private var sortedContexts: [(key: String, value: TimeInterval)] {
        guard let analytics = analytics else { return [] }
        return analytics.timeByContext.sorted { $0.value > $1.value }
    }

    private var sortedDates: [(key: Date, value: TimeInterval)] {
        guard let analytics = analytics else { return [] }
        return analytics.timeByDate.sorted { $0.key > $1.key }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func exportToCSV() {
        exportedCSV = timeTracker.exportToCSV(tasks: tasks, dateRange: selectedPeriod.dateRange)
        showExportSheet = true
    }

    private func saveCSVToFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "time-entries-\(selectedPeriod.rawValue.lowercased().replacingOccurrences(of: " ", with: "-")).csv"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? exportedCSV.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.textBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Bar Chart Row

struct BarChartRow: View {
    let label: String
    let value: TimeInterval
    let maxValue: TimeInterval
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(TimeTrackingManager.formatDuration(value))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(height: 20)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value / maxValue), height: 20)
                }
            }
            .frame(height: 20)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(TimeTrackingManager.formatDuration(value))")
    }
}

// MARK: - Task Time Row

struct TaskTimeRow: View {
    let task: Task
    let duration: TimeInterval

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)

                HStack(spacing: 8) {
                    if let project = task.project {
                        Label(project, systemImage: "folder.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .accessibilityLabel("Project: \(project)")
                    }

                    if let context = task.context {
                        Label(context, systemImage: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .accessibilityLabel("Context: \(context)")
                    }
                }
            }

            Spacer()

            Text(TimeTrackingManager.formatDuration(duration))
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var label = "Task: \(task.title), time spent: \(TimeTrackingManager.formatDuration(duration))"
        if let project = task.project {
            label += ", project: \(project)"
        }
        if let context = task.context {
            label += ", context: \(context)"
        }
        return label
    }
}

// MARK: - Preview

#Preview {
    TimeAnalyticsView(
        timeTracker: {
            let tracker = TimeTrackingManager()
            // Add sample entries
            let taskId = UUID()
            tracker.addEntry(TimeEntry(
                taskId: taskId,
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date().addingTimeInterval(-1800)
            ))
            return tracker
        }(),
        tasks: [
            Task(
                id: UUID(),
                title: "Sample Task",
                project: "Sample Project",
                context: "@computer"
            )
        ]
    )
}
