//
//  TaskInspectorViewController.swift
//  StickyToDo-AppKit
//
//  Right sidebar inspector panel for editing task metadata.
//  Displays all fields with appropriate controls.
//

import Cocoa

/// Protocol for communicating task changes from inspector
protocol TaskInspectorDelegate: AnyObject {
    func inspectorDidUpdateTask(_ task: Task)
    func inspectorDidDeleteTask(_ task: Task)
    func inspectorDidDuplicateTask(_ task: Task)
}

/// View controller for the task inspector panel
class TaskInspectorViewController: NSViewController {

    // MARK: - Properties

    weak var delegate: TaskInspectorDelegate?

    /// Scroll view containing all fields
    private var scrollView: NSScrollView!

    /// Container view for all controls
    private var containerView: NSView!

    /// Current task being edited
    private var currentTask: Task? {
        didSet {
            updateUI()
        }
    }

    /// All boards (for "Show on Boards" section)
    private var allBoards: [Board] = []

    // MARK: - UI Controls

    private let titleLabel = NSTextField(labelWithString: "TASK DETAILS")
    private let titleField = NSTextField()

    private let statusLabel = NSTextField(labelWithString: "Status:")
    private let statusPopUp = NSPopUpButton()

    private let projectLabel = NSTextField(labelWithString: "Project:")
    private let projectComboBox = NSComboBox()

    private let contextLabel = NSTextField(labelWithString: "Context:")
    private let contextPopUp = NSPopUpButton()

    private let priorityLabel = NSTextField(labelWithString: "Priority:")
    private let priorityPopUp = NSPopUpButton()

    private let dueDateLabel = NSTextField(labelWithString: "Due Date:")
    private let dueDatePicker = NSDatePicker()
    private let clearDueButton = NSButton(title: "Clear", target: nil, action: nil)

    private let deferDateLabel = NSTextField(labelWithString: "Defer Until:")
    private let deferDatePicker = NSDatePicker()
    private let clearDeferButton = NSButton(title: "Clear", target: nil, action: nil)

    private let effortLabel = NSTextField(labelWithString: "Effort (minutes):")
    private let effortField = NSTextField()

    private let colorLabel = NSTextField(labelWithString: "Color:")
    private let colorPickerView = CompactColorPickerView()

    private let flaggedLabel = NSTextField(labelWithString: "Flagged:")
    private let flaggedCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)

    private let notesLabel = NSTextField(labelWithString: "Notes:")
    private let notesScrollView = NSScrollView()
    private let notesTextView = NSTextView()

    private let boardsLabel = NSTextField(labelWithString: "SHOW ON BOARDS")
    private let boardsListView = NSTableView()

    private let actionButtonsStack = NSStackView()
    private let deleteButton = NSButton(title: "Delete", target: nil, action: nil)
    private let duplicateButton = NSButton(title: "Duplicate", target: nil, action: nil)

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 600))
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureControls()
        updateUI()
    }

    // MARK: - Setup

    private func setupUI() {
        // Create scroll view
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        // Create container view
        containerView = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 1200))
        containerView.wantsLayer = true

        // Layout controls
        layoutControls()

        scrollView.documentView = containerView
        view.addSubview(scrollView)
    }

    private func layoutControls() {
        var yOffset: CGFloat = 20
        let padding: CGFloat = 16
        let labelWidth: CGFloat = 100
        let controlWidth: CGFloat = 248

        // Helper to add a control
        func addControl(_ control: NSView, height: CGFloat) {
            control.frame = NSRect(x: padding, y: yOffset, width: controlWidth, height: height)
            containerView.addSubview(control)
            yOffset += height + 12
        }

        // Helper to add a labeled control
        func addLabeledControl(label: NSTextField, control: NSView, controlHeight: CGFloat) {
            label.frame = NSRect(x: padding, y: yOffset + 4, width: labelWidth, height: 16)
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textColor = .secondaryLabelColor
            label.isBordered = false
            label.backgroundColor = .clear
            containerView.addSubview(label)

            control.frame = NSRect(x: padding, y: yOffset + 24, width: controlWidth, height: controlHeight)
            containerView.addSubview(control)
            yOffset += 24 + controlHeight + 16
        }

        // Title header
        titleLabel.font = .boldSystemFont(ofSize: 11)
        titleLabel.textColor = .tertiaryLabelColor
        titleLabel.isBordered = false
        titleLabel.backgroundColor = .clear
        addControl(titleLabel, height: 20)

        // Title field
        titleField.placeholderString = "Task title"
        addControl(titleField, height: 24)

        // Status
        addLabeledControl(label: statusLabel, control: statusPopUp, controlHeight: 24)

        // Project
        addLabeledControl(label: projectLabel, control: projectComboBox, controlHeight: 24)

        // Context
        addLabeledControl(label: contextLabel, control: contextPopUp, controlHeight: 24)

        // Priority
        addLabeledControl(label: priorityLabel, control: priorityPopUp, controlHeight: 24)

        // Due date with clear button
        let dueContainer = NSView(frame: NSRect(x: 0, y: 0, width: controlWidth, height: 24))
        dueDatePicker.frame = NSRect(x: 0, y: 0, width: controlWidth - 60, height: 24)
        dueDatePicker.datePickerStyle = .textFieldAndStepper
        dueDatePicker.datePickerElements = .yearMonthDay
        dueContainer.addSubview(dueDatePicker)

        clearDueButton.frame = NSRect(x: controlWidth - 55, y: 0, width: 55, height: 24)
        clearDueButton.bezelStyle = .rounded
        clearDueButton.font = .systemFont(ofSize: 11)
        clearDueButton.target = self
        clearDueButton.action = #selector(clearDueDate(_:))
        dueContainer.addSubview(clearDueButton)

        addLabeledControl(label: dueDateLabel, control: dueContainer, controlHeight: 24)

        // Defer date with clear button
        let deferContainer = NSView(frame: NSRect(x: 0, y: 0, width: controlWidth, height: 24))
        deferDatePicker.frame = NSRect(x: 0, y: 0, width: controlWidth - 60, height: 24)
        deferDatePicker.datePickerStyle = .textFieldAndStepper
        deferDatePicker.datePickerElements = .yearMonthDay
        deferContainer.addSubview(deferDatePicker)

        clearDeferButton.frame = NSRect(x: controlWidth - 55, y: 0, width: 55, height: 24)
        clearDeferButton.bezelStyle = .rounded
        clearDeferButton.font = .systemFont(ofSize: 11)
        clearDeferButton.target = self
        clearDeferButton.action = #selector(clearDeferDate(_:))
        deferContainer.addSubview(clearDeferButton)

        addLabeledControl(label: deferDateLabel, control: deferContainer, controlHeight: 24)

        // Effort
        effortField.placeholderString = "e.g., 30"
        addLabeledControl(label: effortLabel, control: effortField, controlHeight: 24)

        // Color picker
        colorPickerView.onColorSelected = { [weak self] color in
            self?.colorChanged(color)
        }
        addLabeledControl(label: colorLabel, control: colorPickerView, controlHeight: 44)

        // Flagged
        let flaggedContainer = NSView(frame: NSRect(x: 0, y: 0, width: controlWidth, height: 24))
        flaggedCheckbox.frame = NSRect(x: 0, y: 4, width: 20, height: 18)
        flaggedContainer.addSubview(flaggedCheckbox)

        let flaggedText = NSTextField(labelWithString: "Star this task for attention")
        flaggedText.font = .systemFont(ofSize: 11)
        flaggedText.textColor = .secondaryLabelColor
        flaggedText.isBordered = false
        flaggedText.backgroundColor = .clear
        flaggedText.frame = NSRect(x: 24, y: 6, width: 200, height: 16)
        flaggedContainer.addSubview(flaggedText)

        addLabeledControl(label: flaggedLabel, control: flaggedContainer, controlHeight: 24)

        // Notes
        notesScrollView.frame = NSRect(x: 0, y: 0, width: controlWidth, height: 200)
        notesScrollView.hasVerticalScroller = true
        notesScrollView.hasHorizontalScroller = false
        notesScrollView.borderType = .bezelBorder
        notesScrollView.autohidesScrollers = true

        notesTextView.isRichText = false
        notesTextView.allowsUndo = true
        notesTextView.font = .systemFont(ofSize: 12)
        notesTextView.textContainerInset = NSSize(width: 4, height: 4)

        notesScrollView.documentView = notesTextView

        addLabeledControl(label: notesLabel, control: notesScrollView, controlHeight: 200)

        // Boards section
        boardsLabel.font = .boldSystemFont(ofSize: 11)
        boardsLabel.textColor = .tertiaryLabelColor
        boardsLabel.isBordered = false
        boardsLabel.backgroundColor = .clear
        addControl(boardsLabel, height: 20)

        // Boards list (simple table)
        let boardsScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: controlWidth, height: 100))
        boardsScrollView.hasVerticalScroller = true
        boardsScrollView.borderType = .bezelBorder

        boardsListView.headerView = nil
        boardsListView.rowSizeStyle = .small

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("board"))
        column.width = controlWidth - 20
        boardsListView.addTableColumn(column)

        boardsScrollView.documentView = boardsListView

        addControl(boardsScrollView, height: 100)

        // Action buttons
        deleteButton.bezelStyle = .rounded
        deleteButton.target = self
        deleteButton.action = #selector(deleteTask(_:))

        duplicateButton.bezelStyle = .rounded
        duplicateButton.target = self
        duplicateButton.action = #selector(duplicateTask(_:))

        actionButtonsStack.orientation = .horizontal
        actionButtonsStack.distribution = .fillEqually
        actionButtonsStack.spacing = 8
        actionButtonsStack.addArrangedSubview(duplicateButton)
        actionButtonsStack.addArrangedSubview(deleteButton)

        addControl(actionButtonsStack, height: 28)

        // Update container height
        containerView.frame.size.height = yOffset + 20
    }

    private func configureControls() {
        // Status popup
        statusPopUp.removeAllItems()
        for status in Status.allCases {
            statusPopUp.addItem(withTitle: status.displayName)
            statusPopUp.lastItem?.representedObject = status
        }
        statusPopUp.target = self
        statusPopUp.action = #selector(fieldChanged(_:))

        // Priority popup
        priorityPopUp.removeAllItems()
        for priority in Priority.allCases {
            priorityPopUp.addItem(withTitle: priority.displayName)
            priorityPopUp.lastItem?.representedObject = priority
        }
        priorityPopUp.target = self
        priorityPopUp.action = #selector(fieldChanged(_:))

        // Context popup (will be populated with contexts)
        contextPopUp.removeAllItems()
        contextPopUp.addItem(withTitle: "None")
        contextPopUp.target = self
        contextPopUp.action = #selector(fieldChanged(_:))

        // Project combo box
        projectComboBox.target = self
        projectComboBox.action = #selector(fieldChanged(_:))

        // Text fields
        titleField.target = self
        titleField.action = #selector(fieldChanged(_:))

        effortField.target = self
        effortField.action = #selector(fieldChanged(_:))

        // Date pickers
        dueDatePicker.target = self
        dueDatePicker.action = #selector(fieldChanged(_:))

        deferDatePicker.target = self
        deferDatePicker.action = #selector(fieldChanged(_:))

        // Flagged checkbox
        flaggedCheckbox.target = self
        flaggedCheckbox.action = #selector(fieldChanged(_:))
    }

    // MARK: - Public Methods

    /// Sets the task to display in the inspector
    func setTask(_ task: Task?) {
        currentTask = task
    }

    /// Sets the list of all boards
    func setBoards(_ boards: [Board]) {
        allBoards = boards
        updateBoardsList()
    }

    /// Sets available contexts for the context popup
    func setContexts(_ contexts: [String]) {
        contextPopUp.removeAllItems()
        contextPopUp.addItem(withTitle: "None")
        for context in contexts {
            contextPopUp.addItem(withTitle: context)
        }
        updateUI()
    }

    /// Sets available projects for autocomplete
    func setProjects(_ projects: [String]) {
        projectComboBox.removeAllItems()
        projectComboBox.addItems(withObjectValues: projects)
        updateUI()
    }

    // MARK: - UI Updates

    private func updateUI() {
        guard let task = currentTask else {
            // No task selected - show empty state
            titleField.isEnabled = false
            titleField.stringValue = ""
            disableAllControls()
            return
        }

        // Enable controls
        enableAllControls()

        // Populate fields
        titleField.stringValue = task.title

        // Status
        if let index = Status.allCases.firstIndex(of: task.status) {
            statusPopUp.selectItem(at: index)
        }

        // Project
        projectComboBox.stringValue = task.project ?? ""

        // Context
        if let context = task.context,
           let index = (0..<contextPopUp.numberOfItems).first(where: { contextPopUp.item(at: $0)?.title == context }) {
            contextPopUp.selectItem(at: index)
        } else {
            contextPopUp.selectItem(at: 0) // "None"
        }

        // Priority
        if let index = Priority.allCases.firstIndex(of: task.priority) {
            priorityPopUp.selectItem(at: index)
        }

        // Due date
        if let due = task.due {
            dueDatePicker.dateValue = due
        } else {
            dueDatePicker.dateValue = Date()
        }

        // Defer date
        if let deferDate = task.defer {
            deferDatePicker.dateValue = deferDate
        } else {
            deferDatePicker.dateValue = Date()
        }

        // Effort
        if let effort = task.effort {
            effortField.stringValue = "\(effort)"
        } else {
            effortField.stringValue = ""
        }

        // Color
        colorPickerView.selectedColor = task.color

        // Flagged
        flaggedCheckbox.state = task.flagged ? .on : .off

        // Notes
        notesTextView.string = task.notes

        // Update boards list
        updateBoardsList()
    }

    private func updateBoardsList() {
        guard let task = currentTask else { return }

        // Find boards that would show this task
        let matchingBoards = allBoards.filter { board in
            task.matches(board.filter)
        }

        // Update table (simplified - would need proper data source)
        boardsListView.reloadData()
    }

    private func disableAllControls() {
        titleField.isEnabled = false
        statusPopUp.isEnabled = false
        projectComboBox.isEnabled = false
        contextPopUp.isEnabled = false
        priorityPopUp.isEnabled = false
        dueDatePicker.isEnabled = false
        deferDatePicker.isEnabled = false
        clearDueButton.isEnabled = false
        clearDeferButton.isEnabled = false
        effortField.isEnabled = false
        flaggedCheckbox.isEnabled = false
        notesTextView.isEditable = false
        deleteButton.isEnabled = false
        duplicateButton.isEnabled = false
    }

    private func enableAllControls() {
        titleField.isEnabled = true
        statusPopUp.isEnabled = true
        projectComboBox.isEnabled = true
        contextPopUp.isEnabled = true
        priorityPopUp.isEnabled = true
        dueDatePicker.isEnabled = true
        deferDatePicker.isEnabled = true
        clearDueButton.isEnabled = true
        clearDeferButton.isEnabled = true
        effortField.isEnabled = true
        flaggedCheckbox.isEnabled = true
        notesTextView.isEditable = true
        deleteButton.isEnabled = true
        duplicateButton.isEnabled = true
    }

    // MARK: - Actions

    @objc private func fieldChanged(_ sender: Any?) {
        guard var task = currentTask else { return }

        // Update task based on which field changed
        task.title = titleField.stringValue

        if let selectedStatus = statusPopUp.selectedItem?.representedObject as? Status {
            task.status = selectedStatus
        }

        task.project = projectComboBox.stringValue.isEmpty ? nil : projectComboBox.stringValue

        if contextPopUp.indexOfSelectedItem > 0 {
            task.context = contextPopUp.titleOfSelectedItem
        } else {
            task.context = nil
        }

        if let selectedPriority = priorityPopUp.selectedItem?.representedObject as? Priority {
            task.priority = selectedPriority
        }

        // Handle dates - only set if they've been modified
        // For simplicity, we'll set them if the control sent the action
        if sender as? NSDatePicker == dueDatePicker {
            task.due = dueDatePicker.dateValue
        }

        if sender as? NSDatePicker == deferDatePicker {
            task.defer = deferDatePicker.dateValue
        }

        // Effort
        if let effortValue = Int(effortField.stringValue) {
            task.effort = effortValue
        } else if effortField.stringValue.isEmpty {
            task.effort = nil
        }

        // Flagged
        task.flagged = flaggedCheckbox.state == .on

        // Notes
        task.notes = notesTextView.string

        // Update timestamp
        task.modified = Date()

        // Notify delegate
        delegate?.inspectorDidUpdateTask(task)

        // Update current task
        currentTask = task
    }

    @objc private func clearDueDate(_ sender: Any?) {
        guard var task = currentTask else { return }
        task.due = nil
        task.modified = Date()
        delegate?.inspectorDidUpdateTask(task)
        currentTask = task
    }

    @objc private func clearDeferDate(_ sender: Any?) {
        guard var task = currentTask else { return }
        task.defer = nil
        task.modified = Date()
        delegate?.inspectorDidUpdateTask(task)
        currentTask = task
    }

    private func colorChanged(_ color: String?) {
        guard var task = currentTask else { return }
        task.color = color
        task.modified = Date()
        delegate?.inspectorDidUpdateTask(task)
        currentTask = task
    }

    @objc private func deleteTask(_ sender: Any?) {
        guard let task = currentTask else { return }

        let alert = NSAlert()
        alert.messageText = "Delete this task?"
        alert.informativeText = "This action cannot be undone."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        alert.beginSheetModal(for: view.window!) { response in
            if response == .alertFirstButtonReturn {
                self.delegate?.inspectorDidDeleteTask(task)
            }
        }
    }

    @objc private func duplicateTask(_ sender: Any?) {
        guard let task = currentTask else { return }
        delegate?.inspectorDidDuplicateTask(task)
    }
}
