//
//  ActivityLogViewController.swift
//  StickyToDo
//
//  AppKit view controller for displaying activity logs.
//  Provides filtering, search, and export functionality.
//

import AppKit
import Combine

/// AppKit view controller for activity log
class ActivityLogViewController: NSViewController {

    // MARK: - Properties

    private let activityLogManager: ActivityLogManager
    private let taskStore: TaskStore

    private var cancellables = Set<AnyCancellable>()

    // UI Components
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let searchField = NSSearchField()
    private let changeTypePopup = NSPopUpButton()
    private let groupingControl = NSSegmentedControl()
    private let exportButton = NSButton()
    private let statsLabel = NSTextField()

    // Filtering state
    private var searchQuery: String = ""
    private var selectedChangeType: ActivityLog.ChangeType?
    private var groupingMode: GroupingMode = .date

    enum GroupingMode: Int {
        case none = 0
        case date = 1
        case task = 2
    }

    // Data
    private var filteredLogs: [ActivityLog] = []
    private var groupedData: [(key: String, logs: [ActivityLog])] = []

    // MARK: - Initialization

    init(activityLogManager: ActivityLogManager, taskStore: TaskStore) {
        self.activityLogManager = activityLogManager
        self.taskStore = taskStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        refreshData()
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Search field
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Search activity logs..."
        searchField.target = self
        searchField.action = #selector(searchDidChange)
        view.addSubview(searchField)

        // Change type filter
        changeTypePopup.translatesAutoresizingMaskIntoConstraints = false
        changeTypePopup.addItem(withTitle: "All Types")
        for changeType in ActivityLog.ChangeType.allCases {
            changeTypePopup.addItem(withTitle: changeType.rawValue)
        }
        changeTypePopup.target = self
        changeTypePopup.action = #selector(changeTypeDidChange)
        view.addSubview(changeTypePopup)

        // Grouping control
        groupingControl.translatesAutoresizingMaskIntoConstraints = false
        groupingControl.segmentCount = 3
        groupingControl.setLabel("None", forSegment: 0)
        groupingControl.setLabel("By Date", forSegment: 1)
        groupingControl.setLabel("By Task", forSegment: 2)
        groupingControl.selectedSegment = 1
        groupingControl.target = self
        groupingControl.action = #selector(groupingDidChange)
        view.addSubview(groupingControl)

        // Export button
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.title = "Export"
        exportButton.bezelStyle = .rounded
        exportButton.target = self
        exportButton.action = #selector(exportButtonClicked)
        view.addSubview(exportButton)

        // Stats label
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        statsLabel.isEditable = false
        statsLabel.isBordered = false
        statsLabel.backgroundColor = .clear
        statsLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        statsLabel.textColor = .secondaryLabelColor
        view.addSubview(statsLabel)

        // Table view setup
        tableView.headerView = NSTableHeaderView()
        tableView.usesAutomaticRowHeights = true
        tableView.style = .inset
        tableView.delegate = self
        tableView.dataSource = self

        // Add columns
        let iconColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("icon"))
        iconColumn.title = ""
        iconColumn.width = 30
        tableView.addTableColumn(iconColumn)

        let descriptionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("description"))
        descriptionColumn.title = "Change"
        descriptionColumn.width = 400
        tableView.addTableColumn(descriptionColumn)

        let timestampColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("timestamp"))
        timestampColumn.title = "When"
        timestampColumn.width = 150
        tableView.addTableColumn(timestampColumn)

        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        view.addSubview(scrollView)

        // Layout constraints
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchField.widthAnchor.constraint(equalToConstant: 300),

            changeTypePopup.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            changeTypePopup.leadingAnchor.constraint(equalTo: searchField.trailingAnchor, constant: 12),
            changeTypePopup.widthAnchor.constraint(equalToConstant: 150),

            groupingControl.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            groupingControl.leadingAnchor.constraint(equalTo: changeTypePopup.trailingAnchor, constant: 12),
            groupingControl.widthAnchor.constraint(equalToConstant: 250),

            exportButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            exportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            statsLabel.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            statsLabel.trailingAnchor.constraint(equalTo: exportButton.leadingAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }

    private func setupBindings() {
        // Subscribe to log changes
        activityLogManager.$logs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Management

    private func refreshData() {
        // Filter logs
        filteredLogs = activityLogManager.filteredLogs(
            taskId: nil,
            changeType: selectedChangeType,
            startDate: nil,
            endDate: nil,
            searchQuery: searchQuery.isEmpty ? nil : searchQuery
        )

        // Group if needed
        if groupingMode == .date {
            let grouped = Dictionary(grouping: filteredLogs) { $0.dateKey }
            groupedData = grouped.map { (key: $0.key, logs: $0.value) }
                .sorted { $0.key > $1.key }
        } else if groupingMode == .task {
            let grouped = Dictionary(grouping: filteredLogs) { $0.taskId }
            groupedData = grouped.map { (key: $0.value.first?.taskTitle ?? "Unknown", logs: $0.value) }
                .sorted { $0.key < $1.key }
        } else {
            groupedData = []
        }

        // Update stats
        statsLabel.stringValue = "\(filteredLogs.count) entries"

        // Reload table
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func searchDidChange() {
        searchQuery = searchField.stringValue
        refreshData()
    }

    @objc private func changeTypeDidChange() {
        let index = changeTypePopup.indexOfSelectedItem
        if index == 0 {
            selectedChangeType = nil
        } else {
            selectedChangeType = ActivityLog.ChangeType.allCases[index - 1]
        }
        refreshData()
    }

    @objc private func groupingDidChange() {
        groupingMode = GroupingMode(rawValue: groupingControl.selectedSegment) ?? .date
        refreshData()
    }

    @objc private func exportButtonClicked() {
        let alert = NSAlert()
        alert.messageText = "Export Activity Log"
        alert.informativeText = "Choose export format:"
        alert.addButton(withTitle: "CSV")
        alert.addButton(withTitle: "JSON")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            exportToCSV()
        } else if response == .alertSecondButtonReturn {
            exportToJSON()
        }
    }

    private func exportToCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "activity-log.csv"

        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }

            do {
                try self.activityLogManager.exportToCSVFile(url: url, logs: self.filteredLogs)
                self.showSuccessAlert(message: "Exported \(self.filteredLogs.count) entries to CSV")
            } catch {
                self.showErrorAlert(error: error)
            }
        }
    }

    private func exportToJSON() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "activity-log.json"

        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }

            do {
                try self.activityLogManager.exportToJSONFile(url: url, logs: self.filteredLogs)
                self.showSuccessAlert(message: "Exported \(self.filteredLogs.count) entries to JSON")
            } catch {
                self.showErrorAlert(error: error)
            }
        }
    }

    // MARK: - Helpers

    private func showSuccessAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Export Successful"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }

    private func showErrorAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Export Failed"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.runModal()
    }

    private func log(at row: Int) -> ActivityLog? {
        if groupingMode == .none {
            guard row < filteredLogs.count else { return nil }
            return filteredLogs[row]
        } else {
            // Calculate row index within groups
            var currentRow = 0
            for group in groupedData {
                // Header row
                currentRow += 1
                if currentRow - 1 == row {
                    return nil // Header row
                }

                // Data rows
                for log in group.logs {
                    if currentRow == row {
                        return log
                    }
                    currentRow += 1
                }
            }
            return nil
        }
    }
}

// MARK: - NSTableViewDataSource

extension ActivityLogViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if groupingMode == .none {
            return filteredLogs.count
        } else {
            // Count headers + data rows
            return groupedData.reduce(0) { $0 + 1 + $1.logs.count }
        }
    }
}

// MARK: - NSTableViewDelegate

extension ActivityLogViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnId = tableColumn?.identifier else { return nil }

        let cellView = NSTableCellView()

        if groupingMode != .none {
            // Check if this is a header row
            var currentRow = 0
            for group in groupedData {
                if currentRow == row {
                    // Header row
                    let textField = NSTextField()
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    textField.isEditable = false
                    textField.isBordered = false
                    textField.backgroundColor = .clear
                    textField.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
                    textField.stringValue = group.key
                    cellView.addSubview(textField)
                    return cellView
                }
                currentRow += 1 + group.logs.count
            }
        }

        guard let log = self.log(at: row) else { return cellView }

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear

        switch columnId.rawValue {
        case "icon":
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            if let image = NSImage(systemSymbolName: log.changeType.icon, accessibilityDescription: nil) {
                imageView.image = image
                imageView.contentTintColor = iconColor(for: log.changeType)
            }
            cellView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: cellView.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 16),
                imageView.heightAnchor.constraint(equalToConstant: 16)
            ])

        case "description":
            textField.stringValue = log.fullDescription
            cellView.addSubview(textField)
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
            ])

        case "timestamp":
            textField.stringValue = log.relativeTimestamp
            textField.textColor = .secondaryLabelColor
            textField.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            cellView.addSubview(textField)
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
            ])

        default:
            break
        }

        return cellView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if groupingMode != .none {
            // Check if this is a header row
            var currentRow = 0
            for group in groupedData {
                if currentRow == row {
                    return 28
                }
                currentRow += 1 + group.logs.count
            }
        }
        return 36
    }

    private func iconColor(for changeType: ActivityLog.ChangeType) -> NSColor {
        switch changeType {
        case .created:
            return .systemGreen
        case .deleted:
            return .systemRed
        case .completed:
            return .systemGreen
        case .uncompleted:
            return .systemOrange
        case .flagged:
            return .systemOrange
        case .priorityChanged:
            return .systemYellow
        default:
            return .systemBlue
        }
    }
}
