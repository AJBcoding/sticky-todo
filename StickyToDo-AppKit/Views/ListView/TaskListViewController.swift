//
//  TaskListViewController.swift
//  StickyToDo-AppKit
//
//  NSViewController managing the task list with NSTableView.
//  Supports grouping, inline editing, keyboard navigation, and drag & drop.
//

import Cocoa

/// Protocol for communicating task list actions
protocol TaskListViewControllerDelegate: AnyObject {
    func taskListDidSelectTask(_ task: Task?)
    func taskListDidUpdateTask(_ task: Task)
    func taskListDidDeleteTasks(_ tasks: [Task])
    func taskListDidCompleteTask(_ task: Task)
}

/// View controller for displaying tasks in a list view with grouping and sorting
class TaskListViewController: NSViewController {

    // MARK: - Properties

    weak var delegate: TaskListViewControllerDelegate?

    /// Scroll view containing the table
    private var scrollView: NSScrollView!

    /// Main table view
    private var tableView: NSTableView!

    /// Current perspective defining filtering and grouping
    private(set) var currentPerspective: Perspective = .inbox {
        didSet {
            refreshData()
        }
    }

    /// All tasks (unfiltered)
    private var allTasks: [Task] = []

    /// Filtered and grouped tasks
    private var groupedTasks: [(groupName: String, tasks: [Task])] = []

    /// Currently selected task
    private(set) var selectedTask: Task? {
        didSet {
            delegate?.taskListDidSelectTask(selectedTask)
        }
    }

    /// Tracks which groups are expanded
    private var expandedGroups: Set<String> = []

    /// Batch edit manager for multi-task operations
    private let batchEditManager = BatchEditManager()

    /// Batch edit mode enabled
    private var isBatchEditMode: Bool = false {
        didSet {
            updateBatchEditUI()
        }
    }

    /// Batch edit toolbar
    private var batchEditToolbar: NSView?

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        setupBatchEditToolbar()
        setupTableView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Expand all groups by default
        expandAllGroups()
    }

    // MARK: - Setup

    private func setupBatchEditToolbar() {
        batchEditToolbar = NSView(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        batchEditToolbar?.autoresizingMask = [.width]
        batchEditToolbar?.wantsLayer = true
        batchEditToolbar?.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        // Selection count label
        let countLabel = NSTextField(labelWithString: "0 selected")
        countLabel.frame = NSRect(x: 12, y: 12, width: 100, height: 20)
        countLabel.font = .systemFont(ofSize: 12)
        countLabel.textColor = .secondaryLabelColor
        countLabel.tag = 1001 // Tag to find later
        batchEditToolbar?.addSubview(countLabel)

        // Batch actions button
        let actionsButton = NSButton(title: "Batch Actions", target: self, action: #selector(showBatchActionsMenu(_:)))
        actionsButton.frame = NSRect(x: view.bounds.width - 150, y: 8, width: 130, height: 28)
        actionsButton.autoresizingMask = [.minXMargin]
        actionsButton.bezelStyle = .rounded
        batchEditToolbar?.addSubview(actionsButton)

        // Complete button
        let completeButton = NSButton(image: NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Complete")!, target: self, action: #selector(batchComplete(_:)))
        completeButton.frame = NSRect(x: view.bounds.width - 200, y: 8, width: 32, height: 28)
        completeButton.autoresizingMask = [.minXMargin]
        completeButton.isBordered = true
        completeButton.bezelStyle = .rounded
        batchEditToolbar?.addSubview(completeButton)

        // Delete button
        let deleteButton = NSButton(image: NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete")!, target: self, action: #selector(batchDelete(_:)))
        deleteButton.frame = NSRect(x: view.bounds.width - 240, y: 8, width: 32, height: 28)
        deleteButton.autoresizingMask = [.minXMargin]
        deleteButton.isBordered = true
        deleteButton.bezelStyle = .rounded
        batchEditToolbar?.addSubview(deleteButton)

        batchEditToolbar?.isHidden = true
        view.addSubview(batchEditToolbar!)
    }

    private func updateBatchEditUI() {
        batchEditToolbar?.isHidden = !isBatchEditMode || tableView.selectedRowIndexes.isEmpty

        // Update count label
        if let countLabel = batchEditToolbar?.viewWithTag(1001) as? NSTextField {
            let count = tableView.selectedRowIndexes.count
            countLabel.stringValue = "\(count) selected"
        }

        // Update scroll view frame
        let toolbarHeight: CGFloat = (isBatchEditMode && !tableView.selectedRowIndexes.isEmpty) ? 44 : 0
        scrollView.frame = NSRect(
            x: 0,
            y: 0,
            width: view.bounds.width,
            height: view.bounds.height - toolbarHeight
        )
        batchEditToolbar?.frame = NSRect(
            x: 0,
            y: view.bounds.height - toolbarHeight,
            width: view.bounds.width,
            height: toolbarHeight
        )
    }

    private func setupTableView() {
        // Create scroll view
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder

        // Create table view
        tableView = NSTableView(frame: scrollView.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.rowSizeStyle = .default
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = true
        tableView.allowsEmptySelection = true
        tableView.target = self
        tableView.doubleAction = #selector(handleDoubleClick(_:))

        // Enable drag and drop
        tableView.registerForDraggedTypes([.string])
        tableView.setDraggingSourceOperationMask(.move, forLocal: true)

        // Add columns
        setupColumns()

        scrollView.documentView = tableView
        view.addSubview(scrollView)
    }

    private func setupColumns() {
        // Checkbox column
        let checkboxColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("checkbox"))
        checkboxColumn.width = 30
        checkboxColumn.minWidth = 30
        checkboxColumn.maxWidth = 30
        tableView.addTableColumn(checkboxColumn)

        // Title column (expandable)
        let titleColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("title"))
        titleColumn.title = "Title"
        titleColumn.width = 250
        titleColumn.minWidth = 100
        titleView.addTableColumn(titleColumn)

        // Project column
        let projectColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("project"))
        projectColumn.title = "Project"
        projectColumn.width = 120
        projectColumn.minWidth = 80
        tableView.addTableColumn(projectColumn)

        // Context column
        let contextColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("context"))
        contextColumn.title = "Context"
        contextColumn.width = 100
        contextColumn.minWidth = 80
        tableView.addTableColumn(contextColumn)

        // Due date column
        let dueColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("due"))
        dueColumn.title = "Due"
        dueColumn.width = 100
        dueColumn.minWidth = 80
        tableView.addTableColumn(dueColumn)

        // Priority column
        let priorityColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("priority"))
        priorityColumn.title = "Priority"
        priorityColumn.width = 80
        priorityColumn.minWidth = 60
        tableView.addTableColumn(priorityColumn)

        // Effort column
        let effortColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("effort"))
        effortColumn.title = "Effort"
        effortColumn.width = 60
        effortColumn.minWidth = 50
        tableView.addTableColumn(effortColumn)
    }

    // MARK: - Public Methods

    /// Updates the task list with new data
    func setTasks(_ tasks: [Task]) {
        allTasks = tasks
        refreshData()
    }

    /// Changes the current perspective
    func setPerspective(_ perspective: Perspective) {
        currentPerspective = perspective
    }

    /// Refreshes the table view with current data
    func refreshData() {
        // Apply perspective filtering and sorting
        let filteredTasks = currentPerspective.apply(to: allTasks)

        // Group tasks
        groupedTasks = currentPerspective.group(filteredTasks)

        // Reload table
        tableView.reloadData()

        // Restore expanded state
        restoreExpandedState()
    }

    /// Selects a specific task
    func selectTask(_ task: Task) {
        if let index = findRowForTask(task) {
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            tableView.scrollRowToVisible(index)
        }
    }

    // MARK: - Actions

    @objc private func handleDoubleClick(_ sender: Any?) {
        let row = tableView.clickedRow
        guard row >= 0 else { return }

        if let task = taskForRow(row) {
            // Edit task in inspector
            selectedTask = task
        } else if let groupName = groupNameForRow(row) {
            // Toggle group expansion
            toggleGroup(groupName)
        }
    }

    @objc private func deleteSelectedTasks(_ sender: Any?) {
        let selectedRows = tableView.selectedRowIndexes
        let tasksToDelete = selectedRows.compactMap { taskForRow($0) }

        guard !tasksToDelete.isEmpty else { return }

        let alert = NSAlert()
        alert.messageText = "Delete \(tasksToDelete.count) task(s)?"
        alert.informativeText = "This action cannot be undone."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        alert.beginSheetModal(for: view.window!) { response in
            if response == .alertFirstButtonReturn {
                self.delegate?.taskListDidDeleteTasks(tasksToDelete)
            }
        }
    }

    @objc private func toggleBatchEditMode(_ sender: Any?) {
        isBatchEditMode.toggle()
        if !isBatchEditMode {
            tableView.deselectAll(nil)
        }
    }

    @objc private func showBatchActionsMenu(_ sender: NSButton) {
        let selectedRows = tableView.selectedRowIndexes
        let selectedTasks = selectedRows.compactMap { taskForRow($0) }

        guard !selectedTasks.isEmpty else { return }

        let menu = NSMenu()

        // Status submenu
        let statusMenu = NSMenu()
        statusMenu.addItem(NSMenuItem(title: "Inbox", action: #selector(batchSetStatus(_:)), keyEquivalent: ""))
            .representedObject = Status.inbox
        statusMenu.addItem(NSMenuItem(title: "Next Action", action: #selector(batchSetStatus(_:)), keyEquivalent: ""))
            .representedObject = Status.nextAction
        statusMenu.addItem(NSMenuItem(title: "Waiting", action: #selector(batchSetStatus(_:)), keyEquivalent: ""))
            .representedObject = Status.waiting
        statusMenu.addItem(NSMenuItem(title: "Someday", action: #selector(batchSetStatus(_:)), keyEquivalent: ""))
            .representedObject = Status.someday

        let statusItem = NSMenuItem(title: "Change Status", action: nil, keyEquivalent: "")
        statusItem.submenu = statusMenu
        menu.addItem(statusItem)

        // Priority submenu
        let priorityMenu = NSMenu()
        priorityMenu.addItem(NSMenuItem(title: "High", action: #selector(batchSetPriority(_:)), keyEquivalent: ""))
            .representedObject = Priority.high
        priorityMenu.addItem(NSMenuItem(title: "Medium", action: #selector(batchSetPriority(_:)), keyEquivalent: ""))
            .representedObject = Priority.medium
        priorityMenu.addItem(NSMenuItem(title: "Low", action: #selector(batchSetPriority(_:)), keyEquivalent: ""))
            .representedObject = Priority.low

        let priorityItem = NSMenuItem(title: "Set Priority", action: nil, keyEquivalent: "")
        priorityItem.submenu = priorityMenu
        menu.addItem(priorityItem)

        menu.addItem(.separator())

        // Flag/Unflag
        menu.addItem(NSMenuItem(title: "Flag Tasks", action: #selector(batchFlag(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Unflag Tasks", action: #selector(batchUnflag(_:)), keyEquivalent: ""))

        menu.addItem(.separator())

        // Complete/Uncomplete
        menu.addItem(NSMenuItem(title: "Complete Tasks", action: #selector(batchComplete(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Mark as Incomplete", action: #selector(batchUncomplete(_:)), keyEquivalent: ""))

        menu.addItem(.separator())

        // Archive
        menu.addItem(NSMenuItem(title: "Archive Tasks", action: #selector(batchArchive(_:)), keyEquivalent: ""))

        menu.addItem(.separator())

        // Delete
        let deleteItem = NSMenuItem(title: "Delete Tasks...", action: #selector(batchDelete(_:)), keyEquivalent: "")
        deleteItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
        menu.addItem(deleteItem)

        // Set target for all items
        for item in menu.items {
            item.target = self
            if let submenu = item.submenu {
                for subitem in submenu.items {
                    subitem.target = self
                }
            }
        }

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
    }

    // MARK: - Batch Operations

    @objc private func batchSetStatus(_ sender: NSMenuItem) {
        guard let status = sender.representedObject as? Status else { return }
        let selectedTasks = getSelectedTasks()
        performBatchOperation(.setStatus(status), on: selectedTasks)
    }

    @objc private func batchSetPriority(_ sender: NSMenuItem) {
        guard let priority = sender.representedObject as? Priority else { return }
        let selectedTasks = getSelectedTasks()
        performBatchOperation(.setPriority(priority), on: selectedTasks)
    }

    @objc private func batchFlag(_ sender: Any?) {
        let selectedTasks = getSelectedTasks()
        performBatchOperation(.flag, on: selectedTasks)
    }

    @objc private func batchUnflag(_ sender: Any?) {
        let selectedTasks = getSelectedTasks()
        performBatchOperation(.unflag, on: selectedTasks)
    }

    @objc private func batchComplete(_ sender: Any?) {
        let selectedTasks = getSelectedTasks()
        performBatchOperation(.complete, on: selectedTasks)
    }

    @objc private func batchUncomplete(_ sender: Any?) {
        let selectedTasks = getSelectedTasks()
        performBatchOperation(.uncomplete, on: selectedTasks)
    }

    @objc private func batchArchive(_ sender: Any?) {
        let selectedTasks = getSelectedTasks()
        performBatchOperation(.archive, on: selectedTasks)
    }

    @objc private func batchDelete(_ sender: Any?) {
        let selectedTasks = getSelectedTasks()

        guard !selectedTasks.isEmpty else { return }

        let alert = NSAlert()
        alert.messageText = batchEditManager.confirmationMessage(for: .delete, taskCount: selectedTasks.count)
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        alert.beginSheetModal(for: view.window!) { [weak self] response in
            if response == .alertFirstButtonReturn {
                self?.delegate?.taskListDidDeleteTasks(selectedTasks)
                self?.tableView.deselectAll(nil)
                self?.updateBatchEditUI()
            }
        }
    }

    private func getSelectedTasks() -> [Task] {
        return tableView.selectedRowIndexes.compactMap { taskForRow($0) }
    }

    private func performBatchOperation(_ operation: BatchEditManager.BatchOperation, on tasks: [Task]) {
        guard !tasks.isEmpty else { return }

        let result = batchEditManager.applyOperation(operation, to: tasks)

        // Update all modified tasks via delegate
        for task in result.modifiedTasks {
            delegate?.taskListDidUpdateTask(task)
        }

        // Deselect and update UI
        tableView.deselectAll(nil)
        updateBatchEditUI()
        refreshData()
    }

    // MARK: - Context Menu

    private func showContextMenu(for task: Task, at point: NSPoint) {
        let menu = NSMenu()

        // SECTION 1: Quick Actions
        if task.status != .completed {
            let completeItem = NSMenuItem(title: "Complete", action: #selector(toggleTaskCompletion(_:)), keyEquivalent: "\r")
            completeItem.keyEquivalentModifierMask = [.command]
            completeItem.target = self
            completeItem.representedObject = task
            completeItem.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
            menu.addItem(completeItem)
        } else {
            let reopenItem = NSMenuItem(title: "Reopen", action: #selector(toggleTaskCompletion(_:)), keyEquivalent: "")
            reopenItem.target = self
            reopenItem.representedObject = task
            reopenItem.image = NSImage(systemSymbolName: "arrow.uturn.backward.circle", accessibilityDescription: nil)
            menu.addItem(reopenItem)
        }

        let flagItem = NSMenuItem(title: task.flagged ? "Unflag" : "Flag", action: #selector(toggleFlag(_:)), keyEquivalent: "f")
        flagItem.keyEquivalentModifierMask = [.command, .shift]
        flagItem.target = self
        flagItem.representedObject = task
        flagItem.image = NSImage(systemSymbolName: task.flagged ? "star.slash.fill" : "star.fill", accessibilityDescription: nil)
        menu.addItem(flagItem)

        let editItem = NSMenuItem(title: "Edit", action: #selector(editTask(_:)), keyEquivalent: "e")
        editItem.keyEquivalentModifierMask = [.command]
        editItem.target = self
        editItem.representedObject = task
        editItem.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
        menu.addItem(editItem)

        menu.addItem(.separator())

        // SECTION 2: Status & Priority
        let statusMenu = NSMenu()

        let inboxStatusItem = NSMenuItem(title: "Inbox", action: #selector(changeStatus(_:)), keyEquivalent: "1")
        inboxStatusItem.keyEquivalentModifierMask = [.command, .shift]
        inboxStatusItem.target = self
        inboxStatusItem.representedObject = ["task": task, "status": Status.inbox.rawValue]
        inboxStatusItem.image = NSImage(systemSymbolName: task.status == .inbox ? "checkmark" : "", accessibilityDescription: nil)
        statusMenu.addItem(inboxStatusItem)

        let nextActionItem = NSMenuItem(title: "Next Action", action: #selector(changeStatus(_:)), keyEquivalent: "2")
        nextActionItem.keyEquivalentModifierMask = [.command, .shift]
        nextActionItem.target = self
        nextActionItem.representedObject = ["task": task, "status": Status.nextAction.rawValue]
        nextActionItem.image = NSImage(systemSymbolName: task.status == .nextAction ? "checkmark" : "", accessibilityDescription: nil)
        statusMenu.addItem(nextActionItem)

        let waitingItem = NSMenuItem(title: "Waiting", action: #selector(changeStatus(_:)), keyEquivalent: "3")
        waitingItem.keyEquivalentModifierMask = [.command, .shift]
        waitingItem.target = self
        waitingItem.representedObject = ["task": task, "status": Status.waiting.rawValue]
        waitingItem.image = NSImage(systemSymbolName: task.status == .waiting ? "checkmark" : "", accessibilityDescription: nil)
        statusMenu.addItem(waitingItem)

        let somedayItem = NSMenuItem(title: "Someday", action: #selector(changeStatus(_:)), keyEquivalent: "4")
        somedayItem.keyEquivalentModifierMask = [.command, .shift]
        somedayItem.target = self
        somedayItem.representedObject = ["task": task, "status": Status.someday.rawValue]
        somedayItem.image = NSImage(systemSymbolName: task.status == .someday ? "checkmark" : "", accessibilityDescription: nil)
        statusMenu.addItem(somedayItem)

        let statusMenuItem = NSMenuItem(title: "Status", action: nil, keyEquivalent: "")
        statusMenuItem.image = NSImage(systemSymbolName: "text.badge.checkmark", accessibilityDescription: nil)
        statusMenuItem.submenu = statusMenu
        menu.addItem(statusMenuItem)

        let priorityMenu = NSMenu()

        let highPriorityItem = NSMenuItem(title: "High", action: #selector(changePriority(_:)), keyEquivalent: "h")
        highPriorityItem.keyEquivalentModifierMask = [.command, .shift]
        highPriorityItem.target = self
        highPriorityItem.representedObject = ["task": task, "priority": Priority.high.rawValue]
        highPriorityItem.image = NSImage(systemSymbolName: task.priority == .high ? "checkmark" : "", accessibilityDescription: nil)
        priorityMenu.addItem(highPriorityItem)

        let mediumPriorityItem = NSMenuItem(title: "Medium", action: #selector(changePriority(_:)), keyEquivalent: "m")
        mediumPriorityItem.keyEquivalentModifierMask = [.command, .shift]
        mediumPriorityItem.target = self
        mediumPriorityItem.representedObject = ["task": task, "priority": Priority.medium.rawValue]
        mediumPriorityItem.image = NSImage(systemSymbolName: task.priority == .medium ? "checkmark" : "", accessibilityDescription: nil)
        priorityMenu.addItem(mediumPriorityItem)

        let lowPriorityItem = NSMenuItem(title: "Low", action: #selector(changePriority(_:)), keyEquivalent: "l")
        lowPriorityItem.keyEquivalentModifierMask = [.command, .shift]
        lowPriorityItem.target = self
        lowPriorityItem.representedObject = ["task": task, "priority": Priority.low.rawValue]
        lowPriorityItem.image = NSImage(systemSymbolName: task.priority == .low ? "checkmark" : "", accessibilityDescription: nil)
        priorityMenu.addItem(lowPriorityItem)

        let priorityMenuItem = NSMenuItem(title: "Priority", action: nil, keyEquivalent: "")
        priorityMenuItem.image = NSImage(systemSymbolName: "exclamationmark.3", accessibilityDescription: nil)
        priorityMenuItem.submenu = priorityMenu
        menu.addItem(priorityMenuItem)

        menu.addItem(.separator())

        // SECTION 3: Time Management
        let dueDateMenu = NSMenu()

        let todayItem = NSMenuItem(title: "Today", action: #selector(setDueDate(_:)), keyEquivalent: "t")
        todayItem.keyEquivalentModifierMask = [.command, .option]
        todayItem.target = self
        todayItem.representedObject = ["task": task, "date": "today"]
        todayItem.image = NSImage(systemSymbolName: "calendar.badge.clock", accessibilityDescription: nil)
        dueDateMenu.addItem(todayItem)

        let tomorrowItem = NSMenuItem(title: "Tomorrow", action: #selector(setDueDate(_:)), keyEquivalent: "y")
        tomorrowItem.keyEquivalentModifierMask = [.command, .option]
        tomorrowItem.target = self
        tomorrowItem.representedObject = ["task": task, "date": "tomorrow"]
        tomorrowItem.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: nil)
        dueDateMenu.addItem(tomorrowItem)

        let thisWeekItem = NSMenuItem(title: "This Week", action: #selector(setDueDate(_:)), keyEquivalent: "")
        thisWeekItem.target = self
        thisWeekItem.representedObject = ["task": task, "date": "thisWeek"]
        thisWeekItem.image = NSImage(systemSymbolName: "calendar.badge.plus", accessibilityDescription: nil)
        dueDateMenu.addItem(thisWeekItem)

        let nextWeekItem = NSMenuItem(title: "Next Week", action: #selector(setDueDate(_:)), keyEquivalent: "")
        nextWeekItem.target = self
        nextWeekItem.representedObject = ["task": task, "date": "nextWeek"]
        nextWeekItem.image = NSImage(systemSymbolName: "calendar.badge.plus", accessibilityDescription: nil)
        dueDateMenu.addItem(nextWeekItem)

        dueDateMenu.addItem(.separator())

        let chooseDateItem = NSMenuItem(title: "Choose Date...", action: #selector(chooseDueDate(_:)), keyEquivalent: "")
        chooseDateItem.target = self
        chooseDateItem.representedObject = task
        chooseDateItem.image = NSImage(systemSymbolName: "calendar.circle", accessibilityDescription: nil)
        dueDateMenu.addItem(chooseDateItem)

        if task.due != nil {
            dueDateMenu.addItem(.separator())

            let clearDateItem = NSMenuItem(title: "Clear Due Date", action: #selector(clearDueDate(_:)), keyEquivalent: "")
            clearDateItem.target = self
            clearDateItem.representedObject = task
            clearDateItem.image = NSImage(systemSymbolName: "calendar.badge.minus", accessibilityDescription: nil)
            dueDateMenu.addItem(clearDateItem)
        }

        let dueDateMenuItem = NSMenuItem(title: "Due Date", action: nil, keyEquivalent: "")
        dueDateMenuItem.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: nil)
        dueDateMenuItem.submenu = dueDateMenu
        menu.addItem(dueDateMenuItem)

        menu.addItem(.separator())

        // SECTION 4: Board Management
        let boardMenu = NSMenu()

        let inboxBoardItem = NSMenuItem(title: "Inbox", action: #selector(addToBoard(_:)), keyEquivalent: "")
        inboxBoardItem.target = self
        inboxBoardItem.representedObject = ["task": task, "boardId": "inbox"]
        inboxBoardItem.image = NSImage(systemSymbolName: "tray", accessibilityDescription: nil)
        boardMenu.addItem(inboxBoardItem)

        let nextActionsBoardItem = NSMenuItem(title: "Next Actions", action: #selector(addToBoard(_:)), keyEquivalent: "")
        nextActionsBoardItem.target = self
        nextActionsBoardItem.representedObject = ["task": task, "boardId": "next-actions"]
        nextActionsBoardItem.image = NSImage(systemSymbolName: "arrow.right.circle", accessibilityDescription: nil)
        boardMenu.addItem(nextActionsBoardItem)

        let flaggedBoardItem = NSMenuItem(title: "Flagged", action: #selector(addToBoard(_:)), keyEquivalent: "")
        flaggedBoardItem.target = self
        flaggedBoardItem.representedObject = ["task": task, "boardId": "flagged"]
        flaggedBoardItem.image = NSImage(systemSymbolName: "flag", accessibilityDescription: nil)
        boardMenu.addItem(flaggedBoardItem)

        boardMenu.addItem(.separator())

        let newBoardItem = NSMenuItem(title: "New Board...", action: #selector(createNewBoard(_:)), keyEquivalent: "")
        newBoardItem.target = self
        newBoardItem.representedObject = task
        newBoardItem.image = NSImage(systemSymbolName: "plus.square", accessibilityDescription: nil)
        boardMenu.addItem(newBoardItem)

        let boardMenuItem = NSMenuItem(title: "Add to Board", action: nil, keyEquivalent: "")
        boardMenuItem.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil)
        boardMenuItem.submenu = boardMenu
        menu.addItem(boardMenuItem)

        menu.addItem(.separator())

        // SECTION 5: Copy & Share Actions
        let copyMenu = NSMenu()

        let copyTitleItem = NSMenuItem(title: "Copy Title", action: #selector(copyTitle(_:)), keyEquivalent: "c")
        copyTitleItem.keyEquivalentModifierMask = [.command, .shift]
        copyTitleItem.target = self
        copyTitleItem.representedObject = task
        copyTitleItem.image = NSImage(systemSymbolName: "text.quote", accessibilityDescription: nil)
        copyMenu.addItem(copyTitleItem)

        let copyMarkdownItem = NSMenuItem(title: "Copy as Markdown", action: #selector(copyAsMarkdown(_:)), keyEquivalent: "m")
        copyMarkdownItem.keyEquivalentModifierMask = [.command, .option]
        copyMarkdownItem.target = self
        copyMarkdownItem.representedObject = task
        copyMarkdownItem.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil)
        copyMenu.addItem(copyMarkdownItem)

        let copyLinkItem = NSMenuItem(title: "Copy Link", action: #selector(copyLink(_:)), keyEquivalent: "l")
        copyLinkItem.keyEquivalentModifierMask = [.command, .option]
        copyLinkItem.target = self
        copyLinkItem.representedObject = task
        copyLinkItem.image = NSImage(systemSymbolName: "link", accessibilityDescription: nil)
        copyMenu.addItem(copyLinkItem)

        copyMenu.addItem(.separator())

        let copyPlainTextItem = NSMenuItem(title: "Copy as Plain Text", action: #selector(copyAsPlainText(_:)), keyEquivalent: "")
        copyPlainTextItem.target = self
        copyPlainTextItem.representedObject = task
        copyPlainTextItem.image = NSImage(systemSymbolName: "doc.plaintext", accessibilityDescription: nil)
        copyMenu.addItem(copyPlainTextItem)

        let copyMenuItem = NSMenuItem(title: "Copy", action: nil, keyEquivalent: "")
        copyMenuItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        copyMenuItem.submenu = copyMenu
        menu.addItem(copyMenuItem)

        let shareItem = NSMenuItem(title: "Share...", action: #selector(shareTask(_:)), keyEquivalent: "s")
        shareItem.keyEquivalentModifierMask = [.command, .shift]
        shareItem.target = self
        shareItem.representedObject = task
        shareItem.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)
        menu.addItem(shareItem)

        menu.addItem(.separator())

        // SECTION 6: View Options
        let openMenu = NSMenu()

        let openNewWindowItem = NSMenuItem(title: "Open in New Window", action: #selector(openInNewWindow(_:)), keyEquivalent: "o")
        openNewWindowItem.keyEquivalentModifierMask = [.command, .shift]
        openNewWindowItem.target = self
        openNewWindowItem.representedObject = task
        openNewWindowItem.image = NSImage(systemSymbolName: "rectangle.badge.plus", accessibilityDescription: nil)
        openMenu.addItem(openNewWindowItem)

        let showInFinderItem = NSMenuItem(title: "Show in Finder", action: #selector(showInFinder(_:)), keyEquivalent: "")
        showInFinderItem.target = self
        showInFinderItem.representedObject = task
        showInFinderItem.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
        openMenu.addItem(showInFinderItem)

        let openMenuItem = NSMenuItem(title: "Open", action: nil, keyEquivalent: "")
        openMenuItem.image = NSImage(systemSymbolName: "arrow.up.forward.app", accessibilityDescription: nil)
        openMenuItem.submenu = openMenu
        menu.addItem(openMenuItem)

        menu.addItem(.separator())

        // SECTION 7: Task Actions
        let duplicateItem = NSMenuItem(title: "Duplicate", action: #selector(duplicateTask(_:)), keyEquivalent: "d")
        duplicateItem.keyEquivalentModifierMask = [.command]
        duplicateItem.target = self
        duplicateItem.representedObject = task
        duplicateItem.image = NSImage(systemSymbolName: "doc.on.doc.fill", accessibilityDescription: nil)
        menu.addItem(duplicateItem)

        if task.status == .completed {
            let archiveItem = NSMenuItem(title: "Archive", action: #selector(archiveTask(_:)), keyEquivalent: "")
            archiveItem.target = self
            archiveItem.representedObject = task
            archiveItem.image = NSImage(systemSymbolName: "archivebox", accessibilityDescription: nil)
            menu.addItem(archiveItem)
        }

        let deleteItem = NSMenuItem(title: "Delete", action: #selector(deleteTask(_:)), keyEquivalent: "")
        deleteItem.keyEquivalentModifierMask = [.command]
        deleteItem.target = self
        deleteItem.representedObject = task
        deleteItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
        menu.addItem(deleteItem)

        menu.popUp(positioning: nil, at: point, in: tableView)
    }

    @objc private func editTask(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        selectedTask = task
    }

    @objc private func toggleTaskCompletion(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        delegate?.taskListDidCompleteTask(task)
    }

    @objc private func duplicateTask(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        let duplicate = task.duplicate()
        var mutableTask = duplicate
        delegate?.taskListDidUpdateTask(mutableTask)
    }

    @objc private func deleteTask(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        delegate?.taskListDidDeleteTasks([task])
    }

    @objc private func toggleFlag(_ sender: NSMenuItem) {
        guard var task = sender.representedObject as? Task else { return }
        task.flagged.toggle()
        delegate?.taskListDidUpdateTask(task)
    }

    @objc private func changeStatus(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              var task = dict["task"] as? Task,
              let statusRawValue = dict["status"] as? String,
              let status = Status(rawValue: statusRawValue) else { return }
        task.status = status
        delegate?.taskListDidUpdateTask(task)
    }

    @objc private func changePriority(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              var task = dict["task"] as? Task,
              let priorityRawValue = dict["priority"] as? String,
              let priority = Priority(rawValue: priorityRawValue) else { return }
        task.priority = priority
        delegate?.taskListDidUpdateTask(task)
    }

    @objc private func setDueDate(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              var task = dict["task"] as? Task,
              let dateString = dict["date"] as? String else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch dateString {
        case "today":
            task.due = today
        case "tomorrow":
            task.due = calendar.date(byAdding: .day, value: 1, to: today)
        case "thisWeek":
            let weekday = calendar.component(.weekday, from: Date())
            let daysUntilSunday = (8 - weekday) % 7
            task.due = calendar.date(byAdding: .day, value: daysUntilSunday, to: today)
        case "nextWeek":
            task.due = calendar.date(byAdding: .weekOfYear, value: 1, to: today)
        default:
            return
        }

        delegate?.taskListDidUpdateTask(task)
    }

    @objc private func chooseDueDate(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        // This would open a date picker dialog
        // For now, just a placeholder
        print("Choose due date for task: \(task.title)")
    }

    @objc private func clearDueDate(_ sender: NSMenuItem) {
        guard var task = sender.representedObject as? Task else { return }
        task.due = nil
        delegate?.taskListDidUpdateTask(task)
    }

    @objc private func addToBoard(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              let task = dict["task"] as? Task,
              let boardId = dict["boardId"] as? String else { return }
        NotificationCenter.default.post(
            name: NSNotification.Name("AddTaskToBoard"),
            object: ["taskId": task.id, "boardId": boardId]
        )
    }

    @objc private func createNewBoard(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        NotificationCenter.default.post(
            name: NSNotification.Name("CreateNewBoard"),
            object: task.id
        )
    }

    @objc private func shareTask(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        NotificationCenter.default.post(
            name: NSNotification.Name("ShareTask"),
            object: ["taskId": task.id, "items": [task.title, generateMarkdown(for: task)]]
        )
    }

    @objc private func copyTitle(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(task.title, forType: .string)
    }

    @objc private func copyAsMarkdown(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        let markdown = generateMarkdown(for: task)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
    }

    @objc private func copyLink(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        let link = "stickytodo://task/\(task.id.uuidString)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(link, forType: .string)
    }

    @objc private func copyAsPlainText(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        let plainText = generatePlainText(for: task)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(plainText, forType: .string)
    }

    @objc private func openInNewWindow(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenTaskInNewWindow"),
            object: task.id
        )
    }

    @objc private func showInFinder(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        // This would show the task file in Finder
        // For now, just a placeholder
        print("Show in Finder for task: \(task.title)")
    }

    @objc private func archiveTask(_ sender: NSMenuItem) {
        guard let task = sender.representedObject as? Task else { return }
        NotificationCenter.default.post(
            name: NSNotification.Name("ArchiveTask"),
            object: task.id
        )
    }

    // MARK: - Helper Methods for Copy Actions

    private func generateMarkdown(for task: Task) -> String {
        var markdown = "- [\(task.status == .completed ? "x" : " ")] \(task.title)\n"

        if let project = task.project {
            markdown += "  - Project: \(project)\n"
        }

        if let context = task.context {
            markdown += "  - Context: \(context)\n"
        }

        if task.priority != .medium {
            markdown += "  - Priority: \(task.priority.displayName)\n"
        }

        if let due = task.due {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            markdown += "  - Due: \(formatter.string(from: due))\n"
        }

        if !task.notes.isEmpty {
            markdown += "\n\(task.notes)\n"
        }

        return markdown
    }

    private func generatePlainText(for task: Task) -> String {
        var text = "\(task.title)"

        var details: [String] = []

        if let project = task.project {
            details.append("Project: \(project)")
        }

        if let context = task.context {
            details.append("Context: \(context)")
        }

        if task.priority != .medium {
            details.append("Priority: \(task.priority.displayName)")
        }

        if let due = task.due {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            details.append("Due: \(formatter.string(from: due))")
        }

        if !details.isEmpty {
            text += "\n" + details.joined(separator: " | ")
        }

        if !task.notes.isEmpty {
            text += "\n\n\(task.notes)"
        }

        return text
    }

    // MARK: - Keyboard Navigation

    override func keyDown(with event: NSEvent) {
        let characters = event.charactersIgnoringModifiers ?? ""

        switch characters {
        case "j": // Move down
            selectNextTask()

        case "k": // Move up
            selectPreviousTask()

        case "\r": // Enter - edit task
            if let task = selectedTask {
                beginEditingTask(task)
            }

        case " ": // Space - toggle completion
            if event.modifierFlags.contains(.command), let task = selectedTask {
                delegate?.taskListDidCompleteTask(task)
            }

        case "e": // Toggle batch edit mode (Cmd+Shift+E)
            if event.modifierFlags.contains([.command, .shift]) {
                toggleBatchEditMode(nil)
            } else {
                super.keyDown(with: event)
            }

        case "a": // Select all (Cmd+A)
            if event.modifierFlags.contains(.command) {
                tableView.selectAll(nil)
            } else {
                super.keyDown(with: event)
            }

        default:
            super.keyDown(with: event)
        }
    }

    private func selectNextTask() {
        let currentRow = tableView.selectedRow
        let nextRow = currentRow + 1

        if nextRow < tableView.numberOfRows {
            tableView.selectRowIndexes(IndexSet(integer: nextRow), byExtendingSelection: false)
            tableView.scrollRowToVisible(nextRow)
        }
    }

    private func selectPreviousTask() {
        let currentRow = tableView.selectedRow
        let previousRow = currentRow - 1

        if previousRow >= 0 {
            tableView.selectRowIndexes(IndexSet(integer: previousRow), byExtendingSelection: false)
            tableView.scrollRowToVisible(previousRow)
        }
    }

    private func beginEditingTask(_ task: Task) {
        guard let row = findRowForTask(task) else { return }
        tableView.editColumn(1, row: row, with: nil, select: true)
    }

    // MARK: - Group Management

    private func toggleGroup(_ groupName: String) {
        if expandedGroups.contains(groupName) {
            expandedGroups.remove(groupName)
        } else {
            expandedGroups.insert(groupName)
        }
        refreshData()
    }

    private func expandAllGroups() {
        expandedGroups = Set(groupedTasks.map { $0.groupName })
        refreshData()
    }

    private func restoreExpandedState() {
        // Called after reload to maintain expanded state
    }

    // MARK: - Helper Methods

    private func taskForRow(_ row: Int) -> Task? {
        var currentRow = 0

        for group in groupedTasks {
            // Group header row
            if currentRow == row {
                return nil
            }
            currentRow += 1

            // Task rows (if group is expanded)
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

    private func groupNameForRow(_ row: Int) -> String? {
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

    private func findRowForTask(_ task: Task) -> Int? {
        var currentRow = 0

        for group in groupedTasks {
            currentRow += 1 // Group header

            if expandedGroups.contains(group.groupName) {
                for (index, groupTask) in group.tasks.enumerated() {
                    if groupTask.id == task.id {
                        return currentRow + index
                    }
                }
                currentRow += group.tasks.count
            }
        }

        return nil
    }
}

// MARK: - NSTableViewDataSource

extension TaskListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
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
        return nil // Using view-based table view
    }
}

// MARK: - NSTableViewDelegate

extension TaskListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let columnId = tableColumn?.identifier.rawValue ?? ""

        // Check if this is a group header row
        if let groupName = groupNameForRow(row) {
            return makeGroupHeaderView(groupName: groupName, tableColumn: tableColumn)
        }

        // Regular task row
        guard let task = taskForRow(row) else { return nil }

        return makeTaskCellView(task: task, columnId: columnId, tableColumn: tableColumn)
    }

    private func makeGroupHeaderView(groupName: String, tableColumn: NSTableColumn?) -> NSView? {
        guard tableColumn?.identifier.rawValue == "title" else {
            return NSView() // Empty view for other columns
        }

        let view = NSTableCellView()
        let textField = NSTextField(labelWithString: groupName.uppercased())
        textField.font = .boldSystemFont(ofSize: 11)
        textField.textColor = .secondaryLabelColor
        textField.frame = NSRect(x: 8, y: 4, width: 300, height: 16)
        view.addSubview(textField)

        // Disclosure triangle
        let isExpanded = expandedGroups.contains(groupName)
        let triangle = NSTextField(labelWithString: isExpanded ? "▼" : "▶")
        triangle.font = .systemFont(ofSize: 10)
        triangle.textColor = .tertiaryLabelColor
        triangle.frame = NSRect(x: -8, y: 4, width: 16, height: 16)
        view.addSubview(triangle)

        return view
    }

    private func makeTaskCellView(task: Task, columnId: String, tableColumn: NSTableColumn?) -> NSView? {
        let cellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView
            ?? NSTableCellView()
        cellView.identifier = tableColumn?.identifier

        switch columnId {
        case "checkbox":
            let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleCheckbox(_:)))
            checkbox.state = task.status == .completed ? .on : .off
            checkbox.frame = NSRect(x: 4, y: 4, width: 20, height: 18)
            cellView.addSubview(checkbox)
            return cellView

        case "title":
            cellView.textField?.stringValue = task.title
            cellView.textField?.isEditable = true
            cellView.textField?.delegate = self
            return cellView

        case "project":
            cellView.textField?.stringValue = task.project ?? ""
            cellView.textField?.textColor = .secondaryLabelColor
            return cellView

        case "context":
            cellView.textField?.stringValue = task.context ?? ""
            cellView.textField?.textColor = .secondaryLabelColor
            return cellView

        case "due":
            if let dueDesc = task.dueDescription {
                cellView.textField?.stringValue = dueDesc
                cellView.textField?.textColor = task.isOverdue ? .systemRed : (task.isDueToday ? .systemOrange : .labelColor)
            } else {
                cellView.textField?.stringValue = ""
            }
            return cellView

        case "priority":
            cellView.textField?.stringValue = task.priority.displayName
            cellView.textField?.textColor = .secondaryLabelColor
            return cellView

        case "effort":
            cellView.textField?.stringValue = task.effortDescription ?? ""
            cellView.textField?.textColor = .tertiaryLabelColor
            return cellView

        default:
            return cellView
        }
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return groupNameForRow(row) != nil ? 24 : 28
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        // Only select task rows, not group headers
        return taskForRow(row) != nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        selectedTask = row >= 0 ? taskForRow(row) : nil
        updateBatchEditUI()
    }

    @objc private func toggleCheckbox(_ sender: NSButton) {
        // Find the row containing this checkbox
        var superview = sender.superview
        while superview != nil && !(superview is NSTableRowView) {
            superview = superview?.superview
        }

        guard let rowView = superview as? NSTableRowView,
              let row = tableView.row(for: rowView) as Int?,
              row >= 0,
              let task = taskForRow(row) else { return }

        delegate?.taskListDidCompleteTask(task)
    }
}

// MARK: - NSTextFieldDelegate

extension TaskListViewController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }

        let row = tableView.row(for: textField)
        guard row >= 0, var task = taskForRow(row) else { return }

        // Update task title
        task.title = textField.stringValue
        delegate?.taskListDidUpdateTask(task)
    }
}
