//
//  MainWindowController.swift
//  StickyToDo-AppKit
//
//  Main window controller with three-pane split view.
//  Left: Perspectives sidebar, Center: List or Board view, Right: Inspector.
//

import Cocoa

/// Main window controller managing the application's primary window
class MainWindowController: NSWindowController {

    // MARK: - Properties

    /// Split view controller for three-pane layout
    private var splitViewController: NSSplitViewController!

    /// Sidebar view controller
    private var sidebarViewController: PerspectiveSidebarViewController!

    /// Task list view controller
    private var taskListViewController: TaskListViewController!

    /// Board canvas view controller
    private var boardCanvasViewController: BoardCanvasViewController!

    /// Inspector view controller
    private var inspectorViewController: TaskInspectorViewController!

    /// Container for center content (list or board)
    private var centerContentViewController: NSViewController!

    /// Current view mode (list or board)
    private var viewMode: ViewMode = .list {
        didSet {
            switchViewMode()
        }
    }

    /// Mock data stores (in real app, these would be from data layer)
    private var tasks: [Task] = []
    private var boards: [Board] = []
    private var perspectives: [Perspective] = []
    private var contexts: [String] = ["@computer", "@phone", "@home", "@errands", "@office"]
    private var projects: [String] = []

    /// Currently selected task
    private var selectedTask: Task?

    // MARK: - Initialization

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "StickyToDo"
        window.setFrameAutosaveName("MainWindow")
        window.minSize = NSSize(width: 800, height: 600)

        self.init(window: window)

        setupSplitView()
        setupToolbar()
        loadData()
    }

    // MARK: - Setup

    private func setupSplitView() {
        // Create split view controller
        splitViewController = NSSplitViewController()
        splitViewController.splitView.dividerStyle = .thin

        // Create sidebar
        sidebarViewController = PerspectiveSidebarViewController()
        sidebarViewController.delegate = self
        let sidebarItem = NSSplitViewItem(viewController: sidebarViewController)
        sidebarItem.minimumThickness = 150
        sidebarItem.maximumThickness = 300
        sidebarItem.canCollapse = false
        splitViewController.addSplitViewItem(sidebarItem)

        // Create center content (list view initially)
        taskListViewController = TaskListViewController()
        taskListViewController.delegate = self

        boardCanvasViewController = BoardCanvasViewController()
        boardCanvasViewController.delegate = self

        // Start with list view
        centerContentViewController = taskListViewController
        let centerItem = NSSplitViewItem(viewController: centerContentViewController)
        centerItem.minimumThickness = 400
        splitViewController.addSplitViewItem(centerItem)

        // Create inspector
        inspectorViewController = TaskInspectorViewController()
        inspectorViewController.delegate = self
        let inspectorItem = NSSplitViewItem(viewController: inspectorViewController)
        inspectorItem.minimumThickness = 250
        inspectorItem.maximumThickness = 400
        inspectorItem.canCollapse = true
        splitViewController.addSplitViewItem(inspectorItem)

        // Set split view as window content
        window?.contentViewController = splitViewController
    }

    private func setupToolbar() {
        guard let window = window else { return }

        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = true

        window.toolbar = toolbar
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
    }

    private func loadData() {
        // Load perspectives
        perspectives = Perspective.builtInPerspectives
        sidebarViewController.setPerspectives(perspectives)

        // Load boards
        boards = Board.builtInBoards
        sidebarViewController.setContextBoards(boards.filter { $0.type == .context })
        sidebarViewController.setProjectBoards(boards.filter { $0.type == .project })
        sidebarViewController.setCustomBoards(boards.filter { $0.type == .custom && !$0.isBuiltIn })

        // Set initial perspective
        if let firstPerspective = perspectives.first {
            sidebarViewController.selectPerspective(firstPerspective)
            taskListViewController.setPerspective(firstPerspective)
        }

        // Update inspector with available data
        inspectorViewController.setContexts(contexts)
        inspectorViewController.setProjects(projects)
        inspectorViewController.setBoards(boards)
    }

    // MARK: - View Mode Switching

    private func switchViewMode() {
        // Remove current center view
        if let centerItem = splitViewController.splitViewItems[safe: 1] {
            splitViewController.removeSplitViewItem(centerItem)
        }

        // Add appropriate view controller
        let newViewController: NSViewController
        switch viewMode {
        case .list:
            newViewController = taskListViewController
        case .board:
            newViewController = boardCanvasViewController
        }

        let centerItem = NSSplitViewItem(viewController: newViewController)
        centerItem.minimumThickness = 400
        splitViewController.insertSplitViewItem(centerItem, at: 1)
    }

    // MARK: - Actions

    @objc private func toggleViewMode(_ sender: Any?) {
        viewMode = viewMode == .list ? .board : .list
    }

    @objc private func addTask(_ sender: Any?) {
        // Show quick add panel or create task directly
        var task = Task(title: "New Task", status: .inbox)
        tasks.append(task)
        refreshData()

        // Select the new task
        taskListViewController.selectTask(task)
    }

    @objc private func search(_ sender: NSSearchField) {
        let query = sender.stringValue
        // Implement search filtering
        print("Search: \(query)")
    }

    @objc private func showPreferences(_ sender: Any?) {
        // Show preferences window
        print("Show preferences")
    }

    // MARK: - Data Management

    private func refreshData() {
        // Update all views with current data
        taskListViewController.setTasks(tasks)
        boardCanvasViewController.setTasks(tasks)

        // Update badge counts
        var badgeCounts: [String: Int] = [:]
        for perspective in perspectives {
            let count = perspective.apply(to: tasks).count
            badgeCounts[perspective.id] = count
        }
        for board in boards {
            let count = tasks.filter { $0.matches(board.filter) }.count
            badgeCounts[board.id] = count
        }
        sidebarViewController.setBadgeCounts(badgeCounts)
    }

    private func saveTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
        refreshData()
    }

    private func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        refreshData()
    }
}

// MARK: - View Mode

enum ViewMode {
    case list
    case board
}

// MARK: - PerspectiveSidebarDelegate

extension MainWindowController: PerspectiveSidebarDelegate {
    func sidebarDidSelectPerspective(_ perspective: Perspective) {
        taskListViewController.setPerspective(perspective)
        taskListViewController.refreshData()
    }

    func sidebarDidSelectBoard(_ board: Board) {
        // Switch to board view and show this board
        viewMode = .board
        boardCanvasViewController.setBoard(board)
        boardCanvasViewController.refreshBoard()
    }
}

// MARK: - TaskListViewControllerDelegate

extension MainWindowController: TaskListViewControllerDelegate {
    func taskListDidSelectTask(_ task: Task?) {
        selectedTask = task
        inspectorViewController.setTask(task)
    }

    func taskListDidUpdateTask(_ task: Task) {
        saveTask(task)
    }

    func taskListDidDeleteTasks(_ tasks: [Task]) {
        for task in tasks {
            deleteTask(task)
        }
    }

    func taskListDidCompleteTask(_ task: Task) {
        var updatedTask = task
        if updatedTask.status == .completed {
            updatedTask.reopen()
        } else {
            updatedTask.complete()
        }
        saveTask(updatedTask)
    }
}

// MARK: - BoardCanvasDelegate

extension MainWindowController: BoardCanvasDelegate {
    func boardCanvasDidCreateTask(_ task: Task) {
        saveTask(task)
    }

    func boardCanvasDidUpdateTask(_ task: Task) {
        saveTask(task)
    }

    func boardCanvasDidSelectTask(_ task: Task?) {
        selectedTask = task
        inspectorViewController.setTask(task)
    }

    func boardCanvasDidPromoteNotes(_ tasks: [Task]) {
        for task in tasks {
            saveTask(task)
        }
    }
}

// MARK: - TaskInspectorDelegate

extension MainWindowController: TaskInspectorDelegate {
    func inspectorDidUpdateTask(_ task: Task) {
        saveTask(task)
    }

    func inspectorDidDeleteTask(_ task: Task) {
        deleteTask(task)
        inspectorViewController.setTask(nil)
    }

    func inspectorDidDuplicateTask(_ task: Task) {
        let duplicate = task.duplicate()
        saveTask(duplicate)
    }
}

// MARK: - NSToolbarDelegate

extension MainWindowController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        switch itemIdentifier.rawValue {
        case "toggleView":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Toggle View"
            item.paletteLabel = "Toggle List/Board View"
            item.toolTip = "Switch between list and board view (⌘L/⌘B)"
            item.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "Toggle View")
            item.target = self
            item.action = #selector(toggleViewMode(_:))
            return item

        case "addTask":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Add Task"
            item.paletteLabel = "Add Task"
            item.toolTip = "Create a new task (⌘N)"
            item.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Add")
            item.target = self
            item.action = #selector(addTask(_:))
            return item

        case "search":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = ""
            item.paletteLabel = "Search"

            let searchField = NSSearchField(frame: NSRect(x: 0, y: 0, width: 200, height: 28))
            searchField.placeholderString = "Search tasks..."
            searchField.target = self
            searchField.action = #selector(search(_:))

            item.view = searchField
            return item

        case "preferences":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Settings"
            item.paletteLabel = "Settings"
            item.toolTip = "Open preferences (⌘,)"
            item.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")
            item.target = self
            item.action = #selector(showPreferences(_:))
            return item

        default:
            return nil
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            NSToolbarItem.Identifier("toggleView"),
            NSToolbarItem.Identifier("addTask"),
            .flexibleSpace,
            NSToolbarItem.Identifier("search"),
            .space,
            NSToolbarItem.Identifier("preferences")
        ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar) + [.space, .flexibleSpace]
    }
}

// MARK: - Array Extension

fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
