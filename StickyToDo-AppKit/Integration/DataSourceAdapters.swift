//
//  DataSourceAdapters.swift
//  StickyToDo-AppKit
//
//  Adapters connecting AppKit views to data stores.
//  Implements NSTableViewDataSource, NSOutlineViewDataSource with Combine integration.
//

import Cocoa
import Combine

// MARK: - Task List Data Source

/// Data source adapter for NSTableView displaying tasks
///
/// This adapter:
/// - Observes TaskStore changes via Combine
/// - Provides task data to NSTableView
/// - Handles filtering, sorting, and grouping
/// - Updates view automatically when data changes
class TaskListDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: - Properties

    /// Reference to the task store
    private let taskStore: TaskStore

    /// Currently displayed tasks (filtered and sorted)
    private(set) var displayedTasks: [Task] = []

    /// Grouped tasks if grouping is enabled
    private(set) var groupedTasks: [(groupName: String, tasks: [Task])] = []

    /// Current filter/perspective
    var currentPerspective: Perspective? {
        didSet {
            refreshTasks()
        }
    }

    /// Whether grouping is enabled
    var isGroupingEnabled: Bool = false {
        didSet {
            refreshTasks()
        }
    }

    /// Expanded groups
    var expandedGroups: Set<String> = []

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Callback when data changes
    var onDataChanged: (() -> Void)?

    // MARK: - Initialization

    init(taskStore: TaskStore) {
        self.taskStore = taskStore
        super.init()

        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe task changes
        taskStore.$tasks
            .sink { [weak self] _ in
                self?.refreshTasks()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Management

    func refreshTasks() {
        if let perspective = currentPerspective {
            displayedTasks = perspective.apply(to: taskStore.tasks)

            if isGroupingEnabled {
                groupedTasks = perspective.group(displayedTasks)
            } else {
                groupedTasks = [("All Tasks", displayedTasks)]
            }
        } else {
            displayedTasks = taskStore.tasks
            groupedTasks = [("All Tasks", displayedTasks)]
        }

        onDataChanged?()
    }

    func setTasks(_ tasks: [Task]) {
        displayedTasks = tasks

        if isGroupingEnabled, let perspective = currentPerspective {
            groupedTasks = perspective.group(tasks)
        } else {
            groupedTasks = [("All Tasks", tasks)]
        }

        onDataChanged?()
    }

    // MARK: - Task Access

    func task(at row: Int) -> Task? {
        if !isGroupingEnabled {
            guard row >= 0 && row < displayedTasks.count else { return nil }
            return displayedTasks[row]
        }

        var currentRow = 0

        for group in groupedTasks {
            // Skip group header
            currentRow += 1

            if expandedGroups.contains(group.groupName) {
                let taskIndex = row - currentRow
                if taskIndex >= 0 && taskIndex < group.tasks.count {
                    return group.tasks[taskIndex]
                }
                currentRow += group.tasks.count
            }
        }

        return nil
    }

    func groupName(at row: Int) -> String? {
        guard isGroupingEnabled else { return nil }

        var currentRow = 0

        for group in groupedTasks {
            if currentRow == row {
                return group.groupName
            }
            currentRow += 1

            if expandedGroups.contains(group.groupName) {
                currentRow += group.tasks.count
            }
        }

        return nil
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        if !isGroupingEnabled {
            return displayedTasks.count
        }

        var count = 0
        for group in groupedTasks {
            count += 1 // Group header

            if expandedGroups.contains(group.groupName) {
                count += group.tasks.count
            }
        }

        return count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        // Using view-based table view, so return nil
        return nil
    }

    // MARK: - NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let columnId = tableColumn?.identifier.rawValue ?? ""

        // Check if this is a group header row
        if let groupName = groupName(at: row) {
            return makeGroupHeaderView(groupName: groupName, tableColumn: tableColumn, tableView: tableView)
        }

        // Regular task row
        guard let task = task(at: row) else { return nil }

        return makeTaskCellView(task: task, columnId: columnId, tableColumn: tableColumn, tableView: tableView)
    }

    private func makeGroupHeaderView(groupName: String, tableColumn: NSTableColumn?, tableView: NSTableView) -> NSView? {
        guard tableColumn?.identifier.rawValue == "title" else {
            return NSView() // Empty view for other columns
        }

        let view = NSTableCellView()
        let textField = NSTextField(labelWithString: groupName.uppercased())
        textField.font = .boldSystemFont(ofSize: 11)
        textField.textColor = .secondaryLabelColor
        textField.frame = NSRect(x: 24, y: 4, width: 300, height: 16)
        textField.autoresizingMask = [.width]
        view.addSubview(textField)

        // Disclosure triangle
        let isExpanded = expandedGroups.contains(groupName)
        let triangle = NSTextField(labelWithString: isExpanded ? "▼" : "▶")
        triangle.font = .systemFont(ofSize: 10)
        triangle.textColor = .tertiaryLabelColor
        triangle.frame = NSRect(x: 8, y: 4, width: 16, height: 16)
        view.addSubview(triangle)

        return view
    }

    private func makeTaskCellView(task: Task, columnId: String, tableColumn: NSTableColumn?, tableView: NSTableView) -> NSView? {
        var cellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView

        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = tableColumn?.identifier
        }

        guard let cell = cellView else { return nil }

        // Remove existing subviews
        cell.subviews.forEach { $0.removeFromSuperview() }

        switch columnId {
        case "checkbox":
            let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(checkboxToggled(_:)))
            checkbox.state = task.status == .completed ? .on : .off
            checkbox.frame = NSRect(x: 8, y: 6, width: 20, height: 18)
            checkbox.representedObject = task
            cell.addSubview(checkbox)

        case "title":
            let textField = NSTextField(labelWithString: task.title)
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.font = .systemFont(ofSize: 13)
            textField.textColor = task.status == .completed ? .secondaryLabelColor : .labelColor
            textField.lineBreakMode = .byTruncatingTail
            textField.frame = NSRect(x: 4, y: 6, width: 300, height: 18)
            textField.autoresizingMask = [.width]
            cell.addSubview(textField)
            cell.textField = textField

        case "project":
            if let project = task.project {
                let textField = NSTextField(labelWithString: project)
                textField.isBordered = false
                textField.backgroundColor = .clear
                textField.font = .systemFont(ofSize: 12)
                textField.textColor = .secondaryLabelColor
                textField.frame = NSRect(x: 4, y: 6, width: 100, height: 18)
                textField.autoresizingMask = [.width]
                cell.addSubview(textField)
            }

        case "context":
            if let context = task.context {
                let textField = NSTextField(labelWithString: context)
                textField.isBordered = false
                textField.backgroundColor = .clear
                textField.font = .systemFont(ofSize: 12)
                textField.textColor = .secondaryLabelColor
                textField.frame = NSRect(x: 4, y: 6, width: 80, height: 18)
                textField.autoresizingMask = [.width]
                cell.addSubview(textField)
            }

        case "due":
            if let dueDesc = task.dueDescription {
                let textField = NSTextField(labelWithString: dueDesc)
                textField.isBordered = false
                textField.backgroundColor = .clear
                textField.font = .systemFont(ofSize: 12)
                textField.textColor = task.isOverdue ? .systemRed : (task.isDueToday ? .systemOrange : .secondaryLabelColor)
                textField.frame = NSRect(x: 4, y: 6, width: 90, height: 18)
                textField.autoresizingMask = [.width]
                cell.addSubview(textField)
            }

        case "priority":
            let textField = NSTextField(labelWithString: task.priority.displayName)
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.font = .systemFont(ofSize: 12)
            textField.textColor = .secondaryLabelColor
            textField.frame = NSRect(x: 4, y: 6, width: 60, height: 18)
            textField.autoresizingMask = [.width]
            cell.addSubview(textField)

        case "effort":
            if let effortDesc = task.effortDescription {
                let textField = NSTextField(labelWithString: effortDesc)
                textField.isBordered = false
                textField.backgroundColor = .clear
                textField.font = .systemFont(ofSize: 12)
                textField.textColor = .tertiaryLabelColor
                textField.frame = NSRect(x: 4, y: 6, width: 50, height: 18)
                textField.autoresizingMask = [.width]
                cell.addSubview(textField)
            }

        default:
            break
        }

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return groupName(at: row) != nil ? 24 : 28
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        // Only select task rows, not group headers
        return groupName(at: row) == nil
    }

    @objc private func checkboxToggled(_ sender: NSButton) {
        // Handled by table view controller's delegate method
    }

    // MARK: - Drag and Drop Support

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        guard let task = task(at: row) else { return nil }

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(task.id.uuidString, forType: .string)
        return pasteboardItem
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        return .move
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        // Handle reordering or moving to different groups
        return false
    }
}

// MARK: - Perspective Sidebar Data Source

/// Data source adapter for NSOutlineView displaying perspectives and boards
///
/// This adapter:
/// - Observes BoardStore changes
/// - Provides hierarchical data to NSOutlineView
/// - Handles sections (Smart, Contexts, Projects, Custom)
/// - Updates badge counts
class PerspectiveSidebarDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {

    // MARK: - Properties

    /// Reference to the board store
    private let boardStore: BoardStore

    /// Reference to the task store for badge counts
    private let taskStore: TaskStore

    /// Sidebar structure
    private var sidebarStructure: [(section: String, items: [SidebarItem])] = []

    /// All perspectives
    var perspectives: [Perspective] = [] {
        didSet {
            buildSidebarStructure()
        }
    }

    /// Badge counts for perspectives and boards
    var badgeCounts: [String: Int] = [:] {
        didSet {
            onDataChanged?()
        }
    }

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Callback when data changes
    var onDataChanged: (() -> Void)?

    // MARK: - Initialization

    init(boardStore: BoardStore, taskStore: TaskStore) {
        self.boardStore = boardStore
        self.taskStore = taskStore
        super.init()

        setupObservers()
        buildSidebarStructure()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe board changes
        boardStore.$boards
            .sink { [weak self] _ in
                self?.buildSidebarStructure()
            }
            .store(in: &cancellables)

        // Observe task changes to update badge counts
        taskStore.$tasks
            .sink { [weak self] _ in
                self?.updateBadgeCounts()
            }
            .store(in: &cancellables)
    }

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
        let contextBoards = boardStore.boards.filter { $0.type == .context && $0.isVisible }
            .sorted { $0.displayTitle < $1.displayTitle }
        if !contextBoards.isEmpty {
            structure.append((
                section: "CONTEXTS",
                items: contextBoards.map { .board($0) }
            ))
        }

        // Projects section
        let projectBoards = boardStore.boards.filter { $0.type == .project && $0.isVisible }
            .sorted { $0.displayTitle < $1.displayTitle }
        if !projectBoards.isEmpty {
            structure.append((
                section: "PROJECTS",
                items: projectBoards.map { .board($0) }
            ))
        }

        // Custom section
        let customPerspectives = perspectives.filter { !$0.isBuiltIn && $0.isVisible }
        let customBoards = boardStore.boards.filter { $0.type == .custom && !$0.isBuiltIn && $0.isVisible }
        let allCustomItems = (customPerspectives.map { SidebarItem.perspective($0) } +
                              customBoards.map { SidebarItem.board($0) })
            .sorted { $0.title < $1.title }

        if !allCustomItems.isEmpty {
            structure.append((
                section: "CUSTOM",
                items: allCustomItems
            ))
        }

        sidebarStructure = structure
        updateBadgeCounts()
        onDataChanged?()
    }

    private func updateBadgeCounts() {
        var counts: [String: Int] = [:]

        // Count tasks for each perspective
        for perspective in perspectives {
            let tasks = perspective.apply(to: taskStore.tasks)
            counts[perspective.id] = tasks.count
        }

        // Count tasks for each board
        for board in boardStore.boards {
            let tasks = taskStore.tasks(for: board)
            counts[board.id] = tasks.count
        }

        badgeCounts = counts
    }

    // MARK: - Item Access

    func item(at indexPath: IndexPath) -> SidebarItem? {
        guard indexPath.section < sidebarStructure.count else { return nil }
        let section = sidebarStructure[indexPath.section]

        guard indexPath.item < section.items.count else { return nil }
        return section.items[indexPath.item]
    }

    func badgeCount(for item: SidebarItem) -> Int? {
        switch item {
        case .perspective(let p):
            return badgeCounts[p.id]
        case .board(let b):
            return badgeCounts[b.id]
        case .section:
            return nil
        }
    }

    // MARK: - NSOutlineViewDataSource

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            // Root level - return number of sections
            return sidebarStructure.count
        } else if let sectionIndex = item as? Int {
            // Section - return number of items
            return sidebarStructure[sectionIndex].items.count
        }
        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            // Root level - return section index
            return index
        } else if let sectionIndex = item as? Int {
            // Section - return index path
            return IndexPath(item: index, section: sectionIndex)
        }
        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        // Sections are expandable
        return item is Int
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        // Using view-based outline view
        return nil
    }

    // MARK: - NSOutlineViewDelegate

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let sectionIndex = item as? Int {
            // Section header
            let view = NSTableCellView()
            let textField = NSTextField(labelWithString: sidebarStructure[sectionIndex].section)
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.font = .boldSystemFont(ofSize: 11)
            textField.textColor = .tertiaryLabelColor
            textField.frame = NSRect(x: 8, y: 4, width: 200, height: 16)
            view.addSubview(textField)
            return view
        } else if let indexPath = item as? IndexPath {
            // Regular item (perspective or board)
            let sidebarItem = sidebarStructure[indexPath.section].items[indexPath.item]
            return makeSidebarItemView(for: sidebarItem, outlineView: outlineView)
        }
        return nil
    }

    private func makeSidebarItemView(for item: SidebarItem, outlineView: NSOutlineView) -> NSView? {
        let view = NSTableCellView()

        // Icon
        if let icon = item.icon {
            let iconLabel = NSTextField(labelWithString: icon)
            iconLabel.isBordered = false
            iconLabel.backgroundColor = .clear
            iconLabel.font = .systemFont(ofSize: 14)
            iconLabel.alignment = .center
            iconLabel.frame = NSRect(x: 8, y: 6, width: 16, height: 16)
            view.addSubview(iconLabel)
        }

        // Title
        let titleLabel = NSTextField(labelWithString: item.title)
        titleLabel.isBordered = false
        titleLabel.backgroundColor = .clear
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.frame = NSRect(x: item.icon != nil ? 30 : 8, y: 6, width: 120, height: 16)
        view.addSubview(titleLabel)
        view.textField = titleLabel

        // Badge
        if let count = badgeCount(for: item), count > 0 {
            let badgeLabel = NSTextField(labelWithString: "\(count)")
            badgeLabel.isBordered = false
            badgeLabel.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.2)
            badgeLabel.textColor = .secondaryLabelColor
            badgeLabel.font = .systemFont(ofSize: 11, weight: .medium)
            badgeLabel.alignment = .center
            badgeLabel.wantsLayer = true
            badgeLabel.layer?.cornerRadius = 9
            badgeLabel.frame = NSRect(x: 164, y: 5, width: 28, height: 18)
            view.addSubview(badgeLabel)
        }

        return view
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is Int {
            return 24 // Section header
        } else {
            return 28 // Regular item
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
}

// MARK: - Board Canvas Data Source

/// Data source adapter for board canvas views
///
/// This adapter:
/// - Provides tasks for a specific board
/// - Handles position updates
/// - Manages task creation/deletion on board
class BoardCanvasDataSource: NSObject {

    // MARK: - Properties

    /// Reference to the task store
    private let taskStore: TaskStore

    /// Current board
    var currentBoard: Board? {
        didSet {
            refreshTasks()
        }
    }

    /// Tasks on this board
    private(set) var tasks: [Task] = []

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Callback when data changes
    var onDataChanged: (() -> Void)?

    // MARK: - Initialization

    init(taskStore: TaskStore) {
        self.taskStore = taskStore
        super.init()

        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        taskStore.$tasks
            .sink { [weak self] _ in
                self?.refreshTasks()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Management

    func refreshTasks() {
        if let board = currentBoard {
            tasks = taskStore.tasks(for: board)
        } else {
            tasks = []
        }

        onDataChanged?()
    }

    func task(at index: Int) -> Task? {
        guard index >= 0 && index < tasks.count else { return nil }
        return tasks[index]
    }

    func updateTaskPosition(_ task: Task, position: Position) {
        var updatedTask = task
        if let board = currentBoard {
            updatedTask.setPosition(position, for: board.id)
            taskStore.update(updatedTask)
        }
    }

    func createTaskAt(position: Position, title: String) -> Task {
        var task = Task(type: .note, title: title)

        // Set position for current board
        if let board = currentBoard {
            task.setPosition(position, for: board.id)

            // Apply board's context/project
            switch board.type {
            case .context:
                if let contextName = board.filter.context {
                    task.context = contextName
                }
            case .project:
                if let projectName = board.filter.project {
                    task.project = projectName
                }
            default:
                break
            }
        }

        taskStore.add(task)
        return task
    }
}

// MARK: - Sidebar Item

/// Represents an item in the sidebar (perspective or board)
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
