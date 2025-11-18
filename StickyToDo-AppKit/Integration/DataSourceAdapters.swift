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
class TaskListDataSource: NSObject, NSTableViewDataSource {

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
        guard isGroupingEnabled else {
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
class PerspectiveSidebarDataSource: NSObject, NSOutlineViewDataSource {

    // MARK: - Properties

    /// Reference to the board store
    private let boardStore: BoardStore

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

    init(boardStore: BoardStore) {
        self.boardStore = boardStore
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
        onDataChanged?()
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
        updatedTask.position = position
        taskStore.update(updatedTask)
    }

    func createTaskAt(position: Position, title: String) -> Task {
        var task = Task(title: title)
        task.position = position

        // Apply board's context/project
        if let board = currentBoard {
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
