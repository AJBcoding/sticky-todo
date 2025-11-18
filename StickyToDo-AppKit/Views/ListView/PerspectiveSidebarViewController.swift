//
//  PerspectiveSidebarViewController.swift
//  StickyToDo-AppKit
//
//  Sidebar view controller displaying perspectives, contexts, and projects.
//  Uses NSOutlineView for hierarchical organization.
//

import Cocoa

/// Protocol for communicating sidebar selection changes
protocol PerspectiveSidebarDelegate: AnyObject {
    func sidebarDidSelectPerspective(_ perspective: Perspective)
    func sidebarDidSelectBoard(_ board: Board)
}

/// Sidebar item types
enum SidebarItem: Hashable {
    case section(String)
    case perspective(Perspective)
    case board(Board)

    var title: String {
        switch self {
        case .section(let name):
            return name
        case .perspective(let p):
            return p.name
        case .board(let b):
            return b.displayTitle
        }
    }

    var icon: String? {
        switch self {
        case .section:
            return nil
        case .perspective(let p):
            return p.icon
        case .board(let b):
            return b.icon
        }
    }

    var isSection: Bool {
        if case .section = self {
            return true
        }
        return false
    }
}

/// View controller for the sidebar displaying perspectives and boards
class PerspectiveSidebarViewController: NSViewController {

    // MARK: - Properties

    weak var delegate: PerspectiveSidebarDelegate?

    /// Scroll view containing the outline view
    private var scrollView: NSScrollView!

    /// Main outline view
    private var outlineView: NSOutlineView!

    /// Data structure for sidebar
    private var sidebarStructure: [(section: String, items: [SidebarItem])] = []

    /// All perspectives
    private var perspectives: [Perspective] = []

    /// Context boards
    private var contextBoards: [Board] = []

    /// Project boards
    private var projectBoards: [Board] = []

    /// Custom boards
    private var customBoards: [Board] = []

    /// Currently selected item
    private var selectedItem: SidebarItem?

    /// Badge counts for perspectives/boards
    private var badgeCounts: [String: Int] = [:]

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 400))
        setupOutlineView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildSidebarStructure()
        outlineView.reloadData()
        expandAllSections()

        // Select first perspective by default
        if let firstPerspective = perspectives.first {
            selectPerspective(firstPerspective)
        }
    }

    // MARK: - Setup

    private func setupOutlineView() {
        // Create scroll view
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder

        // Create outline view
        outlineView = NSOutlineView(frame: scrollView.bounds)
        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.headerView = nil
        outlineView.rowSizeStyle = .default
        outlineView.selectionHighlightStyle = .sourceList
        outlineView.floatsGroupRows = false
        outlineView.indentationPerLevel = 8

        // Add column
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("MainColumn"))
        column.width = 200
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        scrollView.documentView = outlineView
        view.addSubview(scrollView)
    }

    // MARK: - Public Methods

    /// Updates perspectives list
    func setPerspectives(_ perspectives: [Perspective]) {
        self.perspectives = perspectives
        buildSidebarStructure()
        outlineView.reloadData()
        expandAllSections()
    }

    /// Updates context boards
    func setContextBoards(_ boards: [Board]) {
        self.contextBoards = boards
        buildSidebarStructure()
        outlineView.reloadData()
        expandAllSections()
    }

    /// Updates project boards
    func setProjectBoards(_ boards: [Board]) {
        self.projectBoards = boards
        buildSidebarStructure()
        outlineView.reloadData()
        expandAllSections()
    }

    /// Updates custom boards
    func setCustomBoards(_ boards: [Board]) {
        self.customBoards = boards
        buildSidebarStructure()
        outlineView.reloadData()
        expandAllSections()
    }

    /// Updates badge counts
    func setBadgeCounts(_ counts: [String: Int]) {
        self.badgeCounts = counts
        outlineView.reloadData()
    }

    /// Selects a specific perspective
    func selectPerspective(_ perspective: Perspective) {
        let item = SidebarItem.perspective(perspective)
        if let row = findRow(for: item) {
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            selectedItem = item
        }
    }

    /// Selects a specific board
    func selectBoard(_ board: Board) {
        let item = SidebarItem.board(board)
        if let row = findRow(for: item) {
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            selectedItem = item
        }
    }

    // MARK: - Private Methods

    private func buildSidebarStructure() {
        var structure: [(section: String, items: [SidebarItem])] = []

        // Smart perspectives section
        let smartPerspectives = perspectives.filter { $0.isBuiltIn && $0.isVisible }
            .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
        if !smartPerspectives.isEmpty {
            structure.append((
                section: "SMART",
                items: smartPerspectives.map { .perspective($0) }
            ))
        }

        // Contexts section
        let visibleContextBoards = contextBoards.filter { $0.isVisible }
            .sorted { $0.displayTitle < $1.displayTitle }
        if !visibleContextBoards.isEmpty {
            structure.append((
                section: "CONTEXTS",
                items: visibleContextBoards.map { .board($0) }
            ))
        }

        // Projects section
        let visibleProjectBoards = projectBoards.filter { $0.isVisible }
            .sorted { $0.displayTitle < $1.displayTitle }
        if !visibleProjectBoards.isEmpty {
            structure.append((
                section: "PROJECTS",
                items: visibleProjectBoards.map { .board($0) }
            ))
        }

        // Custom perspectives/boards section
        let customPerspectives = perspectives.filter { !$0.isBuiltIn && $0.isVisible }
        let allCustomItems = (customPerspectives.map { SidebarItem.perspective($0) } +
                              customBoards.filter { $0.isVisible }.map { SidebarItem.board($0) })
            .sorted { $0.title < $1.title }

        if !allCustomItems.isEmpty {
            structure.append((
                section: "CUSTOM",
                items: allCustomItems
            ))
        }

        sidebarStructure = structure
    }

    private func expandAllSections() {
        for (index, _) in sidebarStructure.enumerated() {
            outlineView.expandItem(index)
        }
    }

    private func findRow(for item: SidebarItem) -> Int? {
        for (sectionIndex, section) in sidebarStructure.enumerated() {
            for (itemIndex, sidebarItem) in section.items.enumerated() {
                if sidebarItem == item {
                    return outlineView.row(forItem: IndexPath(item: itemIndex, section: sectionIndex))
                }
            }
        }
        return nil
    }
}

// MARK: - NSOutlineViewDataSource

extension PerspectiveSidebarViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            // Root level - return number of sections
            return sidebarStructure.count
        } else if let sectionIndex = item as? Int {
            // Section - return number of items in section
            return sidebarStructure[sectionIndex].items.count
        }
        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            // Root level - return section index
            return index
        } else if let sectionIndex = item as? Int {
            // Section - return index path for item
            return IndexPath(item: index, section: sectionIndex)
        }
        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        // Sections are expandable
        return item is Int
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return nil // Using view-based outline view
    }
}

// MARK: - NSOutlineViewDelegate

extension PerspectiveSidebarViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let sectionIndex = item as? Int {
            // Section header
            return makeSectionHeaderView(for: sidebarStructure[sectionIndex].section)
        } else if let indexPath = item as? IndexPath {
            // Regular item (perspective or board)
            let sidebarItem = sidebarStructure[indexPath.section].items[indexPath.item]
            return makeItemView(for: sidebarItem)
        }
        return nil
    }

    private func makeSectionHeaderView(for title: String) -> NSView? {
        let view = NSTableCellView()

        let textField = NSTextField(labelWithString: title)
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.font = .boldSystemFont(ofSize: 11)
        textField.textColor = .tertiaryLabelColor
        textField.frame = NSRect(x: 8, y: 4, width: 200, height: 16)

        view.addSubview(textField)
        return view
    }

    private func makeItemView(for item: SidebarItem) -> NSView? {
        let view = SidebarItemCellView()
        view.identifier = NSUserInterfaceItemIdentifier("SidebarItemCell")

        // Configure with item data
        let badgeCount: Int?
        switch item {
        case .perspective(let p):
            badgeCount = badgeCounts[p.id]
        case .board(let b):
            badgeCount = badgeCounts[b.id]
        case .section:
            badgeCount = nil
        }

        view.configure(title: item.title, icon: item.icon, badgeCount: badgeCount)

        return view
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is Int {
            // Section header
            return 24
        } else {
            // Regular item
            return 28
        }
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        // Only select items, not sections
        return item is IndexPath
    }

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        // Sections are group items
        return item is Int
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        let row = outlineView.selectedRow
        guard row >= 0 else { return }

        let item = outlineView.item(atRow: row)

        if let indexPath = item as? IndexPath {
            let sidebarItem = sidebarStructure[indexPath.section].items[indexPath.item]
            selectedItem = sidebarItem

            switch sidebarItem {
            case .perspective(let perspective):
                delegate?.sidebarDidSelectPerspective(perspective)
            case .board(let board):
                delegate?.sidebarDidSelectBoard(board)
            case .section:
                break
            }
        }
    }
}

// MARK: - Sidebar Item Cell View

/// Custom cell view for sidebar items
class SidebarItemCellView: NSTableCellView {

    // MARK: - UI Components

    private let iconLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let badgeLabel = NSTextField(labelWithString: "")

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        // Configure icon label
        iconLabel.isBordered = false
        iconLabel.backgroundColor = .clear
        iconLabel.font = .systemFont(ofSize: 14)
        iconLabel.alignment = .center
        addSubview(iconLabel)

        // Configure title label
        titleLabel.isBordered = false
        titleLabel.backgroundColor = .clear
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.lineBreakMode = .byTruncatingTail
        addSubview(titleLabel)

        // Configure badge label
        badgeLabel.isBordered = false
        badgeLabel.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.2)
        badgeLabel.textColor = .secondaryLabelColor
        badgeLabel.font = .systemFont(ofSize: 11, weight: .medium)
        badgeLabel.alignment = .center
        badgeLabel.wantsLayer = true
        badgeLabel.layer?.cornerRadius = 9
        badgeLabel.isHidden = true
        addSubview(badgeLabel)
    }

    override func layout() {
        super.layout()

        let bounds = self.bounds
        let padding: CGFloat = 8
        var xOffset = padding

        // Icon
        if !iconLabel.isHidden {
            iconLabel.frame = NSRect(x: xOffset, y: (bounds.height - 16) / 2, width: 16, height: 16)
            xOffset += iconLabel.frame.width + 6
        }

        // Title
        let titleWidth = bounds.width - xOffset - padding - (badgeLabel.isHidden ? 0 : 32)
        titleLabel.frame = NSRect(x: xOffset, y: (bounds.height - 16) / 2, width: titleWidth, height: 16)

        // Badge (right-aligned)
        if !badgeLabel.isHidden {
            badgeLabel.frame = NSRect(
                x: bounds.width - padding - 24,
                y: (bounds.height - 18) / 2,
                width: 24,
                height: 18
            )
        }
    }

    // MARK: - Configuration

    func configure(title: String, icon: String?, badgeCount: Int?) {
        titleLabel.stringValue = title

        if let icon = icon {
            iconLabel.stringValue = icon
            iconLabel.isHidden = false
        } else {
            iconLabel.isHidden = true
        }

        if let count = badgeCount, count > 0 {
            badgeLabel.stringValue = "\(count)"
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }

        needsLayout = true
    }
}

// MARK: - IndexPath Extension

extension IndexPath {
    init(item: Int, section: Int) {
        self.init(indexes: [section, item])
    }

    var section: Int {
        return self[0]
    }

    var item: Int {
        return self[1]
    }
}
