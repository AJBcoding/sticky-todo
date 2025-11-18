//
//  SearchViewController.swift
//  StickyToDo
//
//  AppKit search view controller with highlighting.
//

import Cocoa

/// View controller for search functionality in AppKit
class SearchViewController: NSViewController {

    // MARK: - Properties

    private var tasks: [Task] = []
    private var searchResults: [SearchResult] = []
    private var onSelectTask: ((Task) -> Void)?

    // UI Components
    private let searchField = NSSearchField()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let resultsLabel = NSTextField(labelWithString: "")
    private let tipsLabel = NSTextField(wrappingLabelWithString: "")
    private let recentSearchesButton = NSButton()

    // MARK: - Initialization

    init(tasks: [Task], onSelectTask: @escaping (Task) -> Void) {
        self.tasks = tasks
        self.onSelectTask = onSelectTask
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 500))
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadRecentSearches()
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Configure search field
        searchField.placeholderString = "Search tasks (try: AND, OR, NOT, \"exact phrase\")"
        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(searchFieldChanged)
        searchField.translatesAutoresizingMaskIntoConstraints = false

        // Configure recent searches button
        recentSearchesButton.image = NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: "Recent searches")
        recentSearchesButton.bezelStyle = .rounded
        recentSearchesButton.isBordered = true
        recentSearchesButton.target = self
        recentSearchesButton.action = #selector(showRecentSearches)
        recentSearchesButton.translatesAutoresizingMaskIntoConstraints = false

        // Configure results label
        resultsLabel.font = .systemFont(ofSize: 13, weight: .medium)
        resultsLabel.textColor = .secondaryLabelColor
        resultsLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsLabel.stringValue = "0 results"

        // Configure tips label
        tipsLabel.font = .systemFont(ofSize: 11)
        tipsLabel.textColor = .tertiaryLabelColor
        tipsLabel.translatesAutoresizingMaskIntoConstraints = false
        tipsLabel.stringValue = "Tips: Use AND, OR, NOT for operators. Use \"quotes\" for exact phrases."
        tipsLabel.maximumNumberOfLines = 2

        // Configure table view
        let titleColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("title"))
        titleColumn.title = "Task"
        titleColumn.width = 400
        tableView.addTableColumn(titleColumn)

        let relevanceColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("relevance"))
        relevanceColumn.title = "Relevance"
        relevanceColumn.width = 100
        tableView.addTableColumn(relevanceColumn)

        let matchesColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("matches"))
        matchesColumn.title = "Matches"
        matchesColumn.width = 150
        tableView.addTableColumn(matchesColumn)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick)
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.rowHeight = 60

        // Configure scroll view
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Add subviews
        view.addSubview(searchField)
        view.addSubview(recentSearchesButton)
        view.addSubview(resultsLabel)
        view.addSubview(tipsLabel)
        view.addSubview(scrollView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Search field
            searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchField.trailingAnchor.constraint(equalTo: recentSearchesButton.leadingAnchor, constant: -8),

            // Recent searches button
            recentSearchesButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            recentSearchesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            recentSearchesButton.widthAnchor.constraint(equalToConstant: 32),
            recentSearchesButton.heightAnchor.constraint(equalToConstant: 32),

            // Results label
            resultsLabel.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 12),
            resultsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            // Tips label
            tipsLabel.topAnchor.constraint(equalTo: resultsLabel.bottomAnchor, constant: 4),
            tipsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tipsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Scroll view
            scrollView.topAnchor.constraint(equalTo: tipsLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }

    // MARK: - Search

    @objc private func searchFieldChanged() {
        performSearch()
    }

    private func performSearch() {
        let query = searchField.stringValue

        guard !query.isEmpty else {
            searchResults = []
            tableView.reloadData()
            resultsLabel.stringValue = "0 results"
            return
        }

        // Save to recent searches
        SearchManager.saveRecentSearch(query)

        // Perform search
        searchResults = SearchManager.search(tasks: tasks, queryString: query)

        // Update UI
        tableView.reloadData()
        resultsLabel.stringValue = "\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")"
    }

    @objc private func showRecentSearches() {
        let recentSearches = SearchManager.getRecentSearches()

        guard !recentSearches.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "No Recent Searches"
            alert.informativeText = "You haven't searched for anything yet."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        // Create menu
        let menu = NSMenu()
        menu.autoenablesItems = false

        for (index, search) in recentSearches.prefix(10).enumerated() {
            let item = NSMenuItem(title: search, action: #selector(selectRecentSearch(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let clearItem = NSMenuItem(title: "Clear Recent Searches", action: #selector(clearRecentSearches), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        // Show menu
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: recentSearchesButton.bounds.height), in: recentSearchesButton)
    }

    @objc private func selectRecentSearch(_ sender: NSMenuItem) {
        let recentSearches = SearchManager.getRecentSearches()
        guard sender.tag < recentSearches.count else { return }

        searchField.stringValue = recentSearches[sender.tag]
        performSearch()
    }

    @objc private func clearRecentSearches() {
        SearchManager.clearRecentSearches()

        let alert = NSAlert()
        alert.messageText = "Recent Searches Cleared"
        alert.informativeText = "All recent searches have been removed."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func tableViewDoubleClick() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 && selectedRow < searchResults.count else { return }

        let result = searchResults[selectedRow]
        onSelectTask?(result.task)
        view.window?.close()
    }

    private func loadRecentSearches() {
        // This will be used for autocomplete in the future
        _ = SearchManager.getRecentSearches()
    }

    // MARK: - Public Methods

    func updateTasks(_ tasks: [Task]) {
        self.tasks = tasks
        performSearch()
    }
}

// MARK: - NSSearchFieldDelegate

extension SearchViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        performSearch()
    }
}

// MARK: - NSTableViewDataSource

extension SearchViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return searchResults.count
    }
}

// MARK: - NSTableViewDelegate

extension SearchViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < searchResults.count else { return nil }

        let result = searchResults[row]
        let identifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")

        if identifier.rawValue == "title" {
            let cellView = SearchResultTableCellView()
            cellView.configure(with: result)
            return cellView
        } else if identifier.rawValue == "relevance" {
            let cellView = NSTableCellView()
            let textField = NSTextField(labelWithString: String(format: "%.1f", result.relevanceScore))
            textField.font = .systemFont(ofSize: 12)
            textField.textColor = .secondaryLabelColor
            cellView.addSubview(textField)
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 8)
            ])
            return cellView
        } else if identifier.rawValue == "matches" {
            let cellView = NSTableCellView()
            let textField = NSTextField(labelWithString: result.matchedFields.keys.joined(separator: ", "))
            textField.font = .systemFont(ofSize: 11)
            textField.textColor = .tertiaryLabelColor
            textField.lineBreakMode = .byTruncatingTail
            cellView.addSubview(textField)
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 8),
                textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8)
            ])
            return cellView
        }

        return nil
    }
}

// MARK: - Window Controller

/// Window controller for search window
class SearchWindowController: NSWindowController {

    convenience init(tasks: [Task], onSelectTask: @escaping (Task) -> Void) {
        let viewController = SearchViewController(tasks: tasks, onSelectTask: onSelectTask)

        let window = NSWindow(contentViewController: viewController)
        window.title = "Search Tasks"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 700, height: 500))
        window.center()

        self.init(window: window)
    }
}
