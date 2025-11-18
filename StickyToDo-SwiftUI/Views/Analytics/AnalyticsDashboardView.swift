//
//  AnalyticsDashboardView.swift
//  StickyToDo-SwiftUI
//
//  Comprehensive analytics dashboard with charts and statistics.
//

import SwiftUI
import StickyToDoCore
import Charts

/// Analytics dashboard showing comprehensive task statistics
struct AnalyticsDashboardView: View {

    // MARK: - Properties

    let tasks: [Task]

    // MARK: - State

    @State private var selectedPeriod: TimePeriod = .month
    @State private var analytics: AnalyticsCalculator.Analytics?
    @State private var showExportSheet: Bool = false

    // MARK: - Time Period

    enum TimePeriod: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case quarter = "This Quarter"
        case year = "This Year"
        case all = "All Time"

        var dateRange: DateInterval? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .week:
                let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
                return DateInterval(start: start, end: end)
            case .month:
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                let end = calendar.date(byAdding: .month, value: 1, to: start)!
                return DateInterval(start: start, end: end)
            case .quarter:
                let month = calendar.component(.month, from: now)
                let quarterStartMonth = ((month - 1) / 3) * 3 + 1
                var components = calendar.dateComponents([.year], from: now)
                components.month = quarterStartMonth
                components.day = 1
                let start = calendar.date(from: components)!
                let end = calendar.date(byAdding: .month, value: 3, to: start)!
                return DateInterval(start: start, end: end)
            case .year:
                let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
                let end = calendar.date(byAdding: .year, value: 1, to: start)!
                return DateInterval(start: start, end: end)
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

                if let analytics = analytics {
                    // Summary cards
                    summaryCards(analytics: analytics)

                    // Charts grid
                    chartsGrid(analytics: analytics)

                    // Detailed statistics
                    detailedStatistics(analytics: analytics)
                }
            }
            .padding()
        }
        .frame(minWidth: 900, minHeight: 700)
        .navigationTitle("Analytics Dashboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showExportSheet = true
                } label: {
                    Label("Export Report", systemImage: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            calculateAnalytics()
        }
        .onChange(of: selectedPeriod) { _ in
            calculateAnalytics()
        }
        .sheet(isPresented: $showExportSheet) {
            if let analytics = analytics {
                analyticsExportSheet(analytics: analytics)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analytics Dashboard")
                .font(.largeTitle)
                .bold()

            Text("Comprehensive insights into your task management and productivity")
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
    }

    // MARK: - Summary Cards

    private func summaryCards(analytics: AnalyticsCalculator.Analytics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            SummaryCard(
                title: "Total Tasks",
                value: "\(analytics.totalTasks)",
                icon: "tray.fill",
                color: .blue,
                subtitle: nil
            )

            SummaryCard(
                title: "Completed",
                value: "\(analytics.completedTasks)",
                icon: "checkmark.circle.fill",
                color: .green,
                subtitle: analytics.completionRateString
            )

            SummaryCard(
                title: "Active",
                value: "\(analytics.activeTasks)",
                icon: "circle.fill",
                color: .orange,
                subtitle: nil
            )

            SummaryCard(
                title: "Productivity",
                value: String(format: "%.0f%%", AnalyticsCalculator().productivityScore(for: filteredTasks) * 100),
                icon: "chart.line.uptrend.xyaxis",
                color: .purple,
                subtitle: "Overall score"
            )
        }
    }

    // MARK: - Charts Grid

    private func chartsGrid(analytics: AnalyticsCalculator.Analytics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            // Status distribution (Pie Chart)
            ChartCard(title: "Tasks by Status", icon: "circle.grid.3x3.fill") {
                statusPieChart(analytics: analytics)
            }

            // Priority distribution (Pie Chart)
            ChartCard(title: "Tasks by Priority", icon: "exclamationmark.triangle.fill") {
                priorityPieChart(analytics: analytics)
            }

            // Project distribution (Bar Chart)
            ChartCard(title: "Tasks by Project", icon: "folder.fill") {
                projectBarChart(analytics: analytics)
            }

            // Completion trend (Line Chart)
            ChartCard(title: "Completion Trend", icon: "chart.xyaxis.line") {
                completionTrendChart(analytics: analytics)
            }
        }
    }

    // MARK: - Status Pie Chart

    private func statusPieChart(analytics: AnalyticsCalculator.Analytics) -> some View {
        VStack {
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(Status.allCases, id: \.self) { status in
                        if let count = analytics.tasksByStatus[status], count > 0 {
                            SectorMark(
                                angle: .value("Count", count),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Status", status.displayName))
                            .annotation(position: .overlay) {
                                Text("\(count)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(height: 200)
            } else {
                // Fallback for older macOS versions
                PieChartFallback(data: analytics.tasksByStatus.mapValues { $0 })
            }
        }
    }

    // MARK: - Priority Pie Chart

    private func priorityPieChart(analytics: AnalyticsCalculator.Analytics) -> some View {
        VStack {
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        if let count = analytics.tasksByPriority[priority], count > 0 {
                            SectorMark(
                                angle: .value("Count", count),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Priority", priority.displayName))
                            .annotation(position: .overlay) {
                                Text("\(count)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(height: 200)
            } else {
                PieChartFallback(data: analytics.tasksByPriority.mapValues { $0 })
            }
        }
    }

    // MARK: - Project Bar Chart

    private func projectBarChart(analytics: AnalyticsCalculator.Analytics) -> some View {
        VStack(alignment: .leading) {
            let sortedProjects = analytics.tasksByProject.sorted { $0.value > $1.value }.prefix(10)

            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(Array(sortedProjects), id: \.key) { project, count in
                        BarMark(
                            x: .value("Count", count),
                            y: .value("Project", project)
                        )
                        .foregroundStyle(Color.purple.gradient)
                        .annotation(position: .trailing) {
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 200)
            } else {
                BarChartFallback(data: Dictionary(uniqueKeysWithValues: sortedProjects))
            }
        }
    }

    // MARK: - Completion Trend Chart

    private func completionTrendChart(analytics: AnalyticsCalculator.Analytics) -> some View {
        VStack {
            let weeklyData = AnalyticsCalculator().weeklyCompletionRate(for: filteredTasks, weeks: 12)

            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(weeklyData, id: \.0) { date, count in
                        LineMark(
                            x: .value("Week", date),
                            y: .value("Completions", count)
                        )
                        .foregroundStyle(Color.green.gradient)
                        .symbol(.circle)

                        AreaMark(
                            x: .value("Week", date),
                            y: .value("Completions", count)
                        )
                        .foregroundStyle(Color.green.opacity(0.2).gradient)
                    }
                }
                .frame(height: 200)
            } else {
                LineChartFallback(data: weeklyData)
            }
        }
    }

    // MARK: - Detailed Statistics

    private func detailedStatistics(analytics: AnalyticsCalculator.Analytics) -> some View {
        GroupBox("Detailed Statistics") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                StatRow(label: "Total Time Spent", value: analytics.totalTimeSpentString)
                StatRow(label: "Avg Time/Task", value: analytics.averageTimePerTaskString)
                StatRow(label: "Avg Completion Time", value: analytics.averageCompletionTimeString ?? "N/A")

                StatRow(label: "Projects", value: "\(analytics.tasksByProject.count)")
                StatRow(label: "Contexts", value: "\(analytics.tasksByContext.count)")
                StatRow(label: "Completion Rate", value: analytics.completionRateString)
            }
            .padding()
        }
    }

    // MARK: - Export Sheet

    private func analyticsExportSheet(analytics: AnalyticsCalculator.Analytics) -> some View {
        VStack(spacing: 20) {
            Text("Export Analytics Report")
                .font(.headline)

            Button("Export as HTML") {
                exportAsHTML(analytics: analytics)
            }
            .buttonStyle(.borderedProminent)

            Button("Export as CSV") {
                exportAsCSV(analytics: analytics)
            }

            Button("Cancel") {
                showExportSheet = false
            }
        }
        .padding()
        .frame(width: 400, height: 250)
    }

    // MARK: - Helper Methods

    private var filteredTasks: [Task] {
        guard let range = selectedPeriod.dateRange else { return tasks }
        return tasks.filter { task in
            range.contains(task.created)
        }
    }

    private func calculateAnalytics() {
        let calculator = AnalyticsCalculator()
        analytics = calculator.calculate(for: filteredTasks, dateRange: selectedPeriod.dateRange)
    }

    private func exportAsHTML(analytics: AnalyticsCalculator.Analytics) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.html]
        savePanel.nameFieldStringValue = "analytics-report.html"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            let manager = ExportManager()
            Task {
                do {
                    _ = try await manager.export(
                        tasks: filteredTasks,
                        to: url,
                        options: ExportOptions(format: .html, filename: "analytics-report")
                    )
                    showExportSheet = false
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }

    private func exportAsCSV(analytics: AnalyticsCalculator.Analytics) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "analytics-data.csv"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            let manager = ExportManager()
            Task {
                do {
                    _ = try await manager.export(
                        tasks: filteredTasks,
                        to: url,
                        options: ExportOptions(format: .csv, filename: "analytics-data")
                    )
                    showExportSheet = false
                } catch {
                    print("Export failed: \(error)")
                }
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
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Chart Card

struct ChartCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
            }

            content()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Fallback Charts for macOS < 13

struct PieChartFallback<T: Hashable>: View {
    let data: [T: Int]

    var body: some View {
        VStack {
            Text("Pie chart requires macOS 13+")
                .foregroundColor(.secondary)

            ForEach(Array(data.keys), id: \.self) { key in
                HStack {
                    Text("\(String(describing: key))")
                    Spacer()
                    Text("\(data[key] ?? 0)")
                        .bold()
                }
            }
        }
    }
}

struct BarChartFallback: View {
    let data: [String: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let maxValue = data.values.max() ?? 1

            ForEach(Array(data.keys.sorted()), id: \.self) { key in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(key)
                            .font(.caption)
                        Spacer()
                        Text("\(data[key] ?? 0)")
                            .font(.caption)
                            .bold()
                    }

                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.purple)
                                .frame(width: geometry.size.width * CGFloat(Double(data[key] ?? 0) / Double(maxValue)))
                            Spacer()
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }
}

struct LineChartFallback: View {
    let data: [(Date, Int)]

    var body: some View {
        VStack {
            Text("Line chart requires macOS 13+")
                .foregroundColor(.secondary)

            let formatter = DateFormatter()
            formatter.dateStyle = .short

            ForEach(data.indices, id: \.self) { index in
                HStack {
                    Text(formatter.string(from: data[index].0))
                    Spacer()
                    Text("\(data[index].1)")
                        .bold()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyticsDashboardView(
        tasks: [
            Task(title: "Task 1", status: .completed, priority: .high, project: "Project A"),
            Task(title: "Task 2", status: .nextAction, priority: .medium, project: "Project A"),
            Task(title: "Task 3", status: .completed, priority: .low, project: "Project B"),
            Task(title: "Task 4", status: .inbox, priority: .high, project: "Project B"),
            Task(title: "Task 5", status: .waiting, priority: .medium, project: "Project C")
        ]
    )
}
