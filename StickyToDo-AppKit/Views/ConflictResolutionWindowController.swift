//
//  ConflictResolutionWindowController.swift
//  StickyToDo-AppKit
//
//  AppKit conflict resolution UI for handling file conflicts from external changes.
//  Shows side-by-side diff and allows user to choose resolution strategy.
//

import Cocoa

/// Represents a file conflict that needs resolution (AppKit version)
class FileConflictItem: NSObject {
    let id = UUID()
    let url: URL
    let ourContent: String
    let theirContent: String
    let ourModificationDate: Date
    let theirModificationDate: Date
    var resolution: ConflictResolution = .unresolved

    var fileName: String {
        url.lastPathComponent
    }

    var hasChanges: Bool {
        ourContent != theirContent
    }

    init(url: URL, ourContent: String, theirContent: String,
         ourModificationDate: Date, theirModificationDate: Date) {
        self.url = url
        self.ourContent = ourContent
        self.theirContent = theirContent
        self.ourModificationDate = ourModificationDate
        self.theirModificationDate = theirModificationDate
        super.init()
    }
}

/// Resolution strategy for a conflict
enum ConflictResolution {
    case unresolved
    case keepMine
    case keepTheirs
    case viewBoth
    case merge(String)
}

/// Window controller for conflict resolution
class ConflictResolutionWindowController: NSWindowController {

    // MARK: - Properties

    private var conflicts: [FileConflictItem] = []
    private var selectedConflictIndex: Int?
    var onResolutionApplied: (([FileConflictItem]) -> Void)?

    // UI Components
    private var conflictTableView: NSTableView!
    private var ourContentTextView: NSTextView!
    private var theirContentTextView: NSTextView!
    private var fileNameLabel: NSTextField!
    private var filePathLabel: NSTextField!
    private var ourDateLabel: NSTextField!
    private var theirDateLabel: NSTextField!
    private var resolutionStatusLabel: NSTextField!

    // MARK: - Initialization

    convenience init(conflicts: [FileConflictItem]) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Resolve File Conflicts"
        window.center()

        self.init(window: window)
        self.conflicts = conflicts
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        guard let window = window else { return }

        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        window.contentView = contentView

        // Create split view
        let splitView = NSSplitView(frame: contentView.bounds)
        splitView.autoresizingMask = [.width, .height]
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        contentView.addSubview(splitView)

        // Left: File list
        let leftPanel = createFileListPanel()
        splitView.addArrangedSubview(leftPanel)

        // Right: Detail view
        let rightPanel = createDetailPanel()
        splitView.addArrangedSubview(rightPanel)

        // Set split view positions
        splitView.setPosition(250, ofDividerAt: 0)

        // Create toolbar
        createToolbar()

        // Load initial selection
        if !conflicts.isEmpty {
            selectedConflictIndex = 0
            updateDetailView()
        }
    }

    private func createFileListPanel() -> NSView {
        let container = NSView()

        // Header
        let headerLabel = NSTextField(labelWithString: "\(conflicts.count) Conflicts")
        headerLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerLabel)

        // Table view
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder

        conflictTableView = NSTableView()
        conflictTableView.headerView = nil
        conflictTableView.rowHeight = 50
        conflictTableView.delegate = self
        conflictTableView.dataSource = self
        conflictTableView.selectionHighlightStyle = .regular
        conflictTableView.allowsEmptySelection = false

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("conflict"))
        column.width = 230
        conflictTableView.addTableColumn(column)

        scrollView.documentView = conflictTableView
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createDetailPanel() -> NSView {
        let container = NSView()

        // Header section
        let headerContainer = createHeaderSection()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerContainer)

        // Content split view (our vs their)
        let contentSplitView = NSSplitView()
        contentSplitView.translatesAutoresizingMaskIntoConstraints = false
        contentSplitView.isVertical = true
        contentSplitView.dividerStyle = .thin
        container.addSubview(contentSplitView)

        // Our version
        let ourPanel = createContentPanel(title: "My Version")
        ourContentTextView = (ourPanel.subviews.last as? NSScrollView)?.documentView as? NSTextView
        contentSplitView.addArrangedSubview(ourPanel)

        // Their version
        let theirPanel = createContentPanel(title: "Disk Version")
        theirContentTextView = (theirPanel.subviews.last as? NSScrollView)?.documentView as? NSTextView
        contentSplitView.addArrangedSubview(theirPanel)

        // Action buttons
        let actionContainer = createActionButtons()
        actionContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(actionContainer)

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: container.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 80),

            contentSplitView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            contentSplitView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentSplitView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentSplitView.bottomAnchor.constraint(equalTo: actionContainer.topAnchor),

            actionContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            actionContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            actionContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            actionContainer.heightAnchor.constraint(equalToConstant: 60)
        ])

        return container
    }

    private func createHeaderSection() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        fileNameLabel = NSTextField(labelWithString: "")
        fileNameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false

        filePathLabel = NSTextField(labelWithString: "")
        filePathLabel.font = .systemFont(ofSize: 11)
        filePathLabel.textColor = .secondaryLabelColor
        filePathLabel.translatesAutoresizingMaskIntoConstraints = false

        resolutionStatusLabel = NSTextField(labelWithString: "")
        resolutionStatusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        resolutionStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(fileNameLabel)
        container.addSubview(filePathLabel)
        container.addSubview(resolutionStatusLabel)

        NSLayoutConstraint.activate([
            fileNameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            fileNameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            fileNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: resolutionStatusLabel.leadingAnchor, constant: -16),

            filePathLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 4),
            filePathLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            filePathLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            resolutionStatusLabel.centerYAnchor.constraint(equalTo: fileNameLabel.centerYAnchor),
            resolutionStatusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])

        return container
    }

    private func createContentPanel(title: String) -> NSView {
        let container = NSView()

        // Header
        let headerLabel = NSTextField(labelWithString: title)
        headerLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerLabel)

        let dateLabel = NSTextField(labelWithString: "")
        dateLabel.font = .systemFont(ofSize: 10)
        dateLabel.textColor = .secondaryLabelColor
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(dateLabel)

        if title == "My Version" {
            ourDateLabel = dateLabel
        } else {
            theirDateLabel = dateLabel
        }

        // Text view
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .lineBorder

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 10, height: 10)

        scrollView.documentView = textView
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),

            dateLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 2),
            dateLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),

            scrollView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createActionButtons() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        let keepMineButton = NSButton(title: "Keep My Version", target: self, action: #selector(keepMineAction))
        keepMineButton.bezelStyle = .rounded
        keepMineButton.translatesAutoresizingMaskIntoConstraints = false

        let keepTheirsButton = NSButton(title: "Keep Disk Version", target: self, action: #selector(keepTheirsAction))
        keepTheirsButton.bezelStyle = .rounded
        keepTheirsButton.translatesAutoresizingMaskIntoConstraints = false

        let viewBothButton = NSButton(title: "View Both", target: self, action: #selector(viewBothAction))
        viewBothButton.bezelStyle = .rounded
        viewBothButton.translatesAutoresizingMaskIntoConstraints = false

        let mergeButton = NSButton(title: "Merge...", target: self, action: #selector(mergeAction))
        mergeButton.bezelStyle = .rounded
        mergeButton.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(keepMineButton)
        container.addSubview(keepTheirsButton)
        container.addSubview(viewBothButton)
        container.addSubview(mergeButton)

        NSLayoutConstraint.activate([
            keepMineButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            keepMineButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            keepTheirsButton.leadingAnchor.constraint(equalTo: keepMineButton.trailingAnchor, constant: 8),
            keepTheirsButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            mergeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            mergeButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            viewBothButton.trailingAnchor.constraint(equalTo: mergeButton.leadingAnchor, constant: -8),
            viewBothButton.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func createToolbar() {
        let toolbar = NSToolbar(identifier: "ConflictResolutionToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        window?.toolbar = toolbar
    }

    // MARK: - Actions

    @objc private func keepMineAction() {
        guard let index = selectedConflictIndex else { return }
        conflicts[index].resolution = .keepMine
        updateDetailView()
        conflictTableView.reloadData()
    }

    @objc private func keepTheirsAction() {
        guard let index = selectedConflictIndex else { return }
        conflicts[index].resolution = .keepTheirs
        updateDetailView()
        conflictTableView.reloadData()
    }

    @objc private func viewBothAction() {
        guard let index = selectedConflictIndex else { return }
        conflicts[index].resolution = .viewBoth
        updateDetailView()
        conflictTableView.reloadData()
    }

    @objc private func mergeAction() {
        guard let index = selectedConflictIndex else { return }
        // Show merge sheet (simplified for now)
        let alert = NSAlert()
        alert.messageText = "Merge Content"
        alert.informativeText = "This will open a merge editor (feature pending)"
        alert.runModal()
    }

    @objc private func keepAllMineAction() {
        for index in conflicts.indices {
            conflicts[index].resolution = .keepMine
        }
        updateDetailView()
        conflictTableView.reloadData()
    }

    @objc private func keepAllTheirsAction() {
        for index in conflicts.indices {
            conflicts[index].resolution = .keepTheirs
        }
        updateDetailView()
        conflictTableView.reloadData()
    }

    @objc private func applyResolutionAction() {
        onResolutionApplied?(conflicts)
        window?.close()
    }

    @objc private func cancelAction() {
        window?.close()
    }

    // MARK: - Helper Methods

    private func updateDetailView() {
        guard let index = selectedConflictIndex else { return }
        let conflict = conflicts[index]

        fileNameLabel.stringValue = conflict.fileName
        filePathLabel.stringValue = conflict.url.path
        ourContentTextView.string = conflict.ourContent
        theirContentTextView.string = conflict.theirContent

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        ourDateLabel.stringValue = formatter.string(from: conflict.ourModificationDate)
        theirDateLabel.stringValue = formatter.string(from: conflict.theirModificationDate)

        resolutionStatusLabel.stringValue = resolutionText(conflict.resolution)
        resolutionStatusLabel.textColor = conflict.resolution == .unresolved ? .systemOrange : .systemGreen
    }

    private func resolutionText(_ resolution: ConflictResolution) -> String {
        switch resolution {
        case .unresolved:
            return "⚠ Needs Resolution"
        case .keepMine:
            return "✓ Keep My Version"
        case .keepTheirs:
            return "✓ Keep Disk Version"
        case .viewBoth:
            return "👁 View Both"
        case .merge:
            return "✓ Merged"
        }
    }

    private var allConflictsResolved: Bool {
        conflicts.allSatisfy { $0.resolution != .unresolved }
    }
}

// MARK: - NSTableViewDataSource

extension ConflictResolutionWindowController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return conflicts.count
    }
}

// MARK: - NSTableViewDelegate

extension ConflictResolutionWindowController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let conflict = conflicts[row]

        let cellView = NSView()
        cellView.wantsLayer = true

        let iconImageView = NSImageView()
        iconImageView.image = NSImage(systemSymbolName: conflict.resolution == .unresolved ? "exclamationmark.triangle.fill" : "checkmark.circle.fill", accessibilityDescription: nil)
        iconImageView.contentTintColor = conflict.resolution == .unresolved ? .systemOrange : .systemGreen
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = NSTextField(labelWithString: conflict.fileName)
        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let statusLabel = NSTextField(labelWithString: resolutionText(conflict.resolution))
        statusLabel.font = .systemFont(ofSize: 10)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        cellView.addSubview(iconImageView)
        cellView.addSubview(nameLabel)
        cellView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 8),
            iconImageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8),

            statusLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            statusLabel.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8)
        ])

        return cellView
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        selectedConflictIndex = conflictTableView.selectedRow
        if selectedConflictIndex != -1 {
            updateDetailView()
        }
    }
}

// MARK: - NSToolbarDelegate

extension ConflictResolutionWindowController: NSToolbarDelegate {

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "keepAllMine":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Keep All Mine"
            item.target = self
            item.action = #selector(keepAllMineAction)
            return item

        case "keepAllTheirs":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Keep All Theirs"
            item.target = self
            item.action = #selector(keepAllTheirsAction)
            return item

        case "apply":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Apply Resolution"
            item.target = self
            item.action = #selector(applyResolutionAction)
            return item

        case "cancel":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Cancel"
            item.target = self
            item.action = #selector(cancelAction)
            return item

        default:
            return nil
        }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .init("keepAllMine"),
            .init("keepAllTheirs"),
            .flexibleSpace,
            .init("cancel"),
            .init("apply")
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .init("keepAllMine"),
            .init("keepAllTheirs"),
            .flexibleSpace,
            .init("cancel"),
            .init("apply")
        ]
    }
}
