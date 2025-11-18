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

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        setupTableView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Expand all groups by default
        expandAllGroups()
    }

    // MARK: - Setup

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

    // MARK: - Context Menu

    private func showContextMenu(for task: Task, at point: NSPoint) {
        let menu = NSMenu()

        // Edit
        let editItem = NSMenuItem(title: "Edit", action: #selector(editTask(_:)), keyEquivalent: "")
        editItem.target = self
        editItem.representedObject = task
        menu.addItem(editItem)

        // Complete/Reopen
        if task.status == .completed {
            let reopenItem = NSMenuItem(title: "Reopen", action: #selector(toggleTaskCompletion(_:)), keyEquivalent: "")
            reopenItem.target = self
            reopenItem.representedObject = task
            menu.addItem(reopenItem)
        } else {
            let completeItem = NSMenuItem(title: "Complete", action: #selector(toggleTaskCompletion(_:)), keyEquivalent: "")
            completeItem.target = self
            completeItem.representedObject = task
            menu.addItem(completeItem)
        }

        menu.addItem(.separator())

        // Duplicate
        let duplicateItem = NSMenuItem(title: "Duplicate", action: #selector(duplicateTask(_:)), keyEquivalent: "")
        duplicateItem.target = self
        duplicateItem.representedObject = task
        menu.addItem(duplicateItem)

        menu.addItem(.separator())

        // Delete
        let deleteItem = NSMenuItem(title: "Delete", action: #selector(deleteTask(_:)), keyEquivalent: "")
        deleteItem.target = self
        deleteItem.representedObject = task
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
