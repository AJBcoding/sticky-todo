//
//  TimeAnalyticsViewController.swift
//  StickyToDo-AppKit
//
//  AppKit view controller for time tracking analytics.
//  Provides comprehensive analytics dashboard with charts and export functionality.
//

import Cocoa
import Combine
import StickyToDoCore

/// Window controller for time analytics
class TimeAnalyticsWindowController: NSWindowController {

    // MARK: - Properties

    private var viewController: TimeAnalyticsViewController?

    // MARK: - Initialization

    convenience init(timeTracker: TimeTrackingManager, tasks: [Task]) {
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Time Analytics"
        window.center()
        window.minSize = NSSize(width: 800, height: 600)

        self.init(window: window)

        // Create and set content view controller
        let viewController = TimeAnalyticsViewController(timeTracker: timeTracker, tasks: tasks)
        self.viewController = viewController
        window.contentViewController = viewController
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }
}

// MARK: - View Controller

class TimeAnalyticsViewController: NSViewController {

    // MARK: - Properties

    private let timeTracker: TimeTrackingManager
    private let tasks: [Task]
    private var cancellables = Set<AnyCancellable>()

    // UI Components
    private let scrollView = NSScrollView()
    private let contentView = NSView()
    private let headerLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let periodSegmentedControl = NSSegmentedControl()
    private let summaryStackView = NSStackView()
    private let chartsContainerView = NSView()
    private let topTasksTableView = NSTableView()
    private let exportButton = NSButton()

    private var selectedPeriod: TimePeriod = .week
    private var analytics: TimeTrackingManager.Analytics?

    // MARK: - Time Period

    enum TimePeriod: Int, CaseIterable {
        case today = 0
        case week = 1
        case month = 2
        case all = 3

        var displayName: String {
            switch self {
            case .today: return "Today"
            case .week: return "This Week"
            case .month: return "This Month"
            case .all: return "All Time"
            }
        }

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

    // MARK: - Initialization

    init(timeTracker: TimeTrackingManager, tasks: [Task]) {
        self.timeTracker = timeTracker
        self.tasks = tasks
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 700))
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        calculateAnalytics()
        updateUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.wantsLayer = true

        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        view.addSubview(scrollView)

        // Configure content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView

        // Header
        headerLabel.font = .systemFont(ofSize: 28, weight: .bold)
        headerLabel.stringValue = "Time Tracking Analytics"
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerLabel)

        // Subtitle
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.stringValue = "Insights into your productivity and time allocation"
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)

        // Period selector
        periodSegmentedControl.segmentCount = TimePeriod.allCases.count
        for period in TimePeriod.allCases {
            periodSegmentedControl.setLabel(period.displayName, forSegment: period.rawValue)
        }
        periodSegmentedControl.selectedSegment = selectedPeriod.rawValue
        periodSegmentedControl.target = self
        periodSegmentedControl.action = #selector(periodChanged(_:))
        periodSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(periodSegmentedControl)

        // Summary cards
        summaryStackView.orientation = .horizontal
        summaryStackView.distribution = .fillEqually
        summaryStackView.spacing = 16
        summaryStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(summaryStackView)

        // Charts container
        chartsContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartsContainerView)

        // Top tasks table
        topTasksTableView.style = .inset
        let scrollViewContainer = NSScrollView()
        scrollViewContainer.documentView = topTasksTableView
        scrollViewContainer.hasVerticalScroller = true
        scrollViewContainer.translatesAutoresizingMaskIntoConstraints = false

        let taskColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("task"))
        taskColumn.title = "Task"
        taskColumn.width = 400
        topTasksTableView.addTableColumn(taskColumn)

        let durationColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("duration"))
        durationColumn.title = "Duration"
        durationColumn.width = 150
        topTasksTableView.addTableColumn(durationColumn)

        topTasksTableView.dataSource = self
        topTasksTableView.delegate = self

        contentView.addSubview(scrollViewContainer)

        // Export button
        exportButton.title = "Export to CSV"
        exportButton.bezelStyle = .rounded
        exportButton.target = self
        exportButton.action = #selector(exportToCSV(_:))
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(exportButton)

        // Layout
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            periodSegmentedControl.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            periodSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            periodSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            summaryStackView.topAnchor.constraint(equalTo: periodSegmentedControl.bottomAnchor, constant: 24),
            summaryStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            summaryStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            summaryStackView.heightAnchor.constraint(equalToConstant: 80),

            chartsContainerView.topAnchor.constraint(equalTo: summaryStackView.bottomAnchor, constant: 24),
            chartsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            chartsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            chartsContainerView.heightAnchor.constraint(equalToConstant: 300),

            scrollViewContainer.topAnchor.constraint(equalTo: chartsContainerView.bottomAnchor, constant: 24),
            scrollViewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            scrollViewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            scrollViewContainer.heightAnchor.constraint(equalToConstant: 300),

            exportButton.topAnchor.constraint(equalTo: scrollViewContainer.bottomAnchor, constant: 24),
            exportButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            exportButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Analytics

    private func calculateAnalytics() {
        // Filter entries by selected period
        let entries: [TimeEntry]
        if let range = selectedPeriod.dateRange {
            entries = timeTracker.timeEntries.filter { entry in
                entry.startTime >= range.lowerBound && entry.startTime <= range.upperBound
            }
        } else {
            entries = timeTracker.timeEntries
        }

        // Create temporary tracker with filtered entries
        let tempTracker = TimeTrackingManager()
        tempTracker.loadEntries(entries)

        analytics = tempTracker.calculateAnalytics(for: tasks)
    }

    private func updateUI() {
        guard let analytics = analytics else { return }

        // Update summary cards
        summaryStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let totalTimeCard = createSummaryCard(
            title: "Total Time",
            value: TimeTrackingManager.formatDuration(analytics.totalTime),
            color: .systemBlue
        )
        summaryStackView.addArrangedSubview(totalTimeCard)

        let entriesCard = createSummaryCard(
            title: "Entries",
            value: "\(analytics.entryCount)",
            color: .systemGreen
        )
        summaryStackView.addArrangedSubview(entriesCard)

        let avgCard = createSummaryCard(
            title: "Avg/Task",
            value: TimeTrackingManager.formatDuration(analytics.averageTimePerTask),
            color: .systemOrange
        )
        summaryStackView.addArrangedSubview(avgCard)

        // Update charts
        updateCharts()

        // Reload table
        topTasksTableView.reloadData()
    }

    private func updateCharts() {
        guard let analytics = analytics else { return }

        // Clear existing charts
        chartsContainerView.subviews.forEach { $0.removeFromSuperview() }

        // Create simple bar chart view for projects
        if !analytics.timeByProject.isEmpty {
            let chartView = createBarChartView(
                title: "Time by Project",
                data: analytics.timeByProject.sorted { $0.value > $1.value },
                color: .systemPurple
            )
            chartsContainerView.addSubview(chartView)

            chartView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                chartView.topAnchor.constraint(equalTo: chartsContainerView.topAnchor),
                chartView.leadingAnchor.constraint(equalTo: chartsContainerView.leadingAnchor),
                chartView.trailingAnchor.constraint(equalTo: chartsContainerView.trailingAnchor),
                chartView.heightAnchor.constraint(equalToConstant: 280)
            ])
        }
    }

    private func createSummaryCard(title: String, value: String, color: NSColor) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        container.layer?.cornerRadius = 8

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = color
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
        ])

        return container
    }

    private func createBarChartView(title: String, data: [(key: String, value: TimeInterval)], color: NSColor) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        container.layer?.cornerRadius = 8

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        var lastView: NSView = titleLabel
        let maxValue = data.map { $0.value }.max() ?? 1

        for item in data.prefix(5) {
            let barView = createBarRow(label: item.key, value: item.value, maxValue: maxValue, color: color)
            barView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(barView)

            NSLayoutConstraint.activate([
                barView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 8),
                barView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                barView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
                barView.heightAnchor.constraint(equalToConstant: 40)
            ])

            lastView = barView
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
        ])

        return container
    }

    private func createBarRow(label: String, value: TimeInterval, maxValue: TimeInterval, color: NSColor) -> NSView {
        let container = NSView()

        let labelField = NSTextField(labelWithString: label)
        labelField.font = .systemFont(ofSize: 12)
        labelField.translatesAutoresizingMaskIntoConstraints = false

        let valueField = NSTextField(labelWithString: TimeTrackingManager.formatDuration(value))
        valueField.font = .systemFont(ofSize: 12)
        valueField.textColor = .secondaryLabelColor
        valueField.translatesAutoresizingMaskIntoConstraints = false
        valueField.alignment = .right

        let barBackground = NSView()
        barBackground.wantsLayer = true
        barBackground.layer?.backgroundColor = color.withAlphaComponent(0.2).cgColor
        barBackground.layer?.cornerRadius = 4
        barBackground.translatesAutoresizingMaskIntoConstraints = false

        let barFill = NSView()
        barFill.wantsLayer = true
        barFill.layer?.backgroundColor = color.cgColor
        barFill.layer?.cornerRadius = 4
        barFill.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(labelField)
        container.addSubview(valueField)
        container.addSubview(barBackground)
        barBackground.addSubview(barFill)

        let percentage = CGFloat(value / maxValue)

        NSLayoutConstraint.activate([
            labelField.topAnchor.constraint(equalTo: container.topAnchor),
            labelField.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            valueField.topAnchor.constraint(equalTo: container.topAnchor),
            valueField.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            barBackground.topAnchor.constraint(equalTo: labelField.bottomAnchor, constant: 4),
            barBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            barBackground.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            barBackground.heightAnchor.constraint(equalToConstant: 20),

            barFill.topAnchor.constraint(equalTo: barBackground.topAnchor),
            barFill.leadingAnchor.constraint(equalTo: barBackground.leadingAnchor),
            barFill.bottomAnchor.constraint(equalTo: barBackground.bottomAnchor),
            barFill.widthAnchor.constraint(equalTo: barBackground.widthAnchor, multiplier: percentage)
        ])

        return container
    }

    // MARK: - Actions

    @objc private func periodChanged(_ sender: NSSegmentedControl) {
        guard let period = TimePeriod(rawValue: sender.selectedSegment) else { return }
        selectedPeriod = period
        calculateAnalytics()
        updateUI()
    }

    @objc private func exportToCSV(_ sender: NSButton) {
        let csv = timeTracker.exportToCSV(tasks: tasks, dateRange: selectedPeriod.dateRange)

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "time-entries-\(selectedPeriod.displayName.lowercased().replacingOccurrences(of: " ", with: "-")).csv"

        savePanel.beginSheetModal(for: view.window!) { response in
            if response == .OK, let url = savePanel.url {
                try? csv.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

// MARK: - Table View Data Source & Delegate

extension TimeAnalyticsViewController: NSTableViewDataSource, NSTableViewDelegate {

    private var topTasks: [(task: Task, duration: TimeInterval)] {
        return timeTracker.topTasks(count: 10, from: tasks)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return topTasks.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let taskData = topTasks[row]

        if tableColumn?.identifier.rawValue == "task" {
            let cellView = NSTableCellView()
            let textField = NSTextField(labelWithString: taskData.task.title)
            textField.translatesAutoresizingMaskIntoConstraints = false
            cellView.addSubview(textField)

            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
            ])

            return cellView
        } else if tableColumn?.identifier.rawValue == "duration" {
            let cellView = NSTableCellView()
            let textField = NSTextField(labelWithString: TimeTrackingManager.formatDuration(taskData.duration))
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.alignment = .right
            cellView.addSubview(textField)

            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
            ])

            return cellView
        }

        return nil
    }
}
