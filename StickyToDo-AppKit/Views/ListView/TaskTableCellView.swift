//
//  TaskTableCellView.swift
//  StickyToDo-AppKit
//
//  Custom NSTableCellView for displaying tasks with rich metadata.
//  Includes checkbox, title, badges, and visual indicators.
//

import Cocoa

/// Custom table cell view for task display with metadata badges
class TaskTableCellView: NSTableCellView {

    // MARK: - UI Components

    /// Checkbox for task completion
    private let checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)

    /// Task title text field (editable)
    private let titleField = NSTextField()

    /// Container for metadata badges
    private let badgeContainer = NSView()

    /// Context badge
    private let contextBadge = NSTextField(labelWithString: "")

    /// Project badge
    private let projectBadge = NSTextField(labelWithString: "")

    /// Priority indicator
    private let priorityIndicator = NSView()

    /// Due date label
    private let dueLabel = NSTextField(labelWithString: "")

    /// Effort estimate label
    private let effortLabel = NSTextField(labelWithString: "")

    /// Flagged star indicator
    private let flaggedIndicator = NSTextField(labelWithString: "⭐")

    /// Disclosure triangle for subtasks
    private let disclosureButton = NSButton()

    /// Subtask progress indicator
    private let subtaskProgressLabel = NSTextField(labelWithString: "")

    // MARK: - Properties

    /// Callback for checkbox changes
    var onCheckboxToggled: ((Bool) -> Void)?

    /// Callback for title changes
    var onTitleChanged: ((String) -> Void)?

    /// Callback for disclosure triangle toggle
    var onDisclosureToggled: (() -> Void)?

    /// Current task being displayed
    private var currentTask: Task?

    /// Current indentation level
    private var indentationLevel: Int = 0

    /// Whether task has subtasks
    private var hasSubtasks: Bool = false

    /// Whether subtasks are expanded
    private var isExpanded: Bool = false

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
        // Configure checkbox
        checkbox.target = self
        checkbox.action = #selector(checkboxToggled(_:))
        addSubview(checkbox)

        // Configure title field
        titleField.isBordered = false
        titleField.backgroundColor = .clear
        titleField.font = .systemFont(ofSize: 13)
        titleField.delegate = self
        titleField.lineBreakMode = .byTruncatingTail
        addSubview(titleField)

        // Configure badge container
        addSubview(badgeContainer)

        // Configure context badge
        configureBadge(contextBadge, backgroundColor: .systemBlue.withAlphaComponent(0.1), textColor: .systemBlue)
        badgeContainer.addSubview(contextBadge)

        // Configure project badge
        configureBadge(projectBadge, backgroundColor: .systemGreen.withAlphaComponent(0.1), textColor: .systemGreen)
        badgeContainer.addSubview(projectBadge)

        // Configure priority indicator
        priorityIndicator.wantsLayer = true
        priorityIndicator.layer?.cornerRadius = 3
        addSubview(priorityIndicator)

        // Configure due label
        dueLabel.font = .systemFont(ofSize: 11)
        dueLabel.textColor = .secondaryLabelColor
        addSubview(dueLabel)

        // Configure effort label
        effortLabel.font = .systemFont(ofSize: 11)
        effortLabel.textColor = .tertiaryLabelColor
        addSubview(effortLabel)

        // Configure flagged indicator
        flaggedIndicator.font = .systemFont(ofSize: 12)
        flaggedIndicator.isHidden = true
        addSubview(flaggedIndicator)

        // Configure disclosure button
        disclosureButton.isBordered = false
        disclosureButton.title = ""
        disclosureButton.bezelStyle = .disclosure
        disclosureButton.setButtonType(.onOff)
        disclosureButton.target = self
        disclosureButton.action = #selector(disclosureToggled(_:))
        disclosureButton.isHidden = true
        addSubview(disclosureButton)

        // Configure subtask progress label
        configureBadge(subtaskProgressLabel, backgroundColor: .systemOrange.withAlphaComponent(0.1), textColor: .systemOrange)
        subtaskProgressLabel.isHidden = true
        badgeContainer.addSubview(subtaskProgressLabel)
    }

    private func configureBadge(_ badge: NSTextField, backgroundColor: NSColor, textColor: NSColor) {
        badge.isBordered = false
        badge.backgroundColor = backgroundColor
        badge.textColor = textColor
        badge.font = .systemFont(ofSize: 10, weight: .medium)
        badge.alignment = .center
        badge.wantsLayer = true
        badge.layer?.cornerRadius = 3
    }

    override func layout() {
        super.layout()

        let bounds = self.bounds
        let padding: CGFloat = 8
        var xOffset: CGFloat = padding

        // Add indentation
        let indentWidth = CGFloat(indentationLevel) * 20
        xOffset += indentWidth

        // Disclosure triangle (if has subtasks)
        if !disclosureButton.isHidden {
            disclosureButton.frame = NSRect(x: xOffset, y: (bounds.height - 16) / 2, width: 16, height: 16)
            xOffset += disclosureButton.frame.width + 4
        } else if indentationLevel > 0 {
            // Add spacing for alignment with siblings that have disclosure
            xOffset += 20
        }

        // Checkbox (left-aligned)
        checkbox.frame = NSRect(x: xOffset, y: (bounds.height - 18) / 2, width: 18, height: 18)
        xOffset += checkbox.frame.width + 8

        // Priority indicator (small color bar)
        if !priorityIndicator.isHidden {
            priorityIndicator.frame = NSRect(x: xOffset, y: (bounds.height - 16) / 2, width: 3, height: 16)
            xOffset += priorityIndicator.frame.width + 6
        }

        // Title field (expandable)
        let titleWidth: CGFloat = 250
        titleField.frame = NSRect(x: xOffset, y: (bounds.height - 20) / 2, width: titleWidth, height: 20)
        xOffset += titleField.frame.width + 12

        // Badges (subtask progress, context, and project)
        var badgeX: CGFloat = 0

        if !subtaskProgressLabel.isHidden {
            subtaskProgressLabel.sizeToFit()
            var badgeFrame = subtaskProgressLabel.frame
            badgeFrame.size.width += 12
            badgeFrame.size.height = 18
            badgeFrame.origin = NSPoint(x: badgeX, y: (bounds.height - 18) / 2)
            subtaskProgressLabel.frame = badgeFrame
            badgeX += badgeFrame.width + 4
        }

        if !contextBadge.isHidden {
            contextBadge.sizeToFit()
            var badgeFrame = contextBadge.frame
            badgeFrame.size.width += 12
            badgeFrame.size.height = 18
            badgeFrame.origin = NSPoint(x: badgeX, y: (bounds.height - 18) / 2)
            contextBadge.frame = badgeFrame
            badgeX += badgeFrame.width + 4
        }

        if !projectBadge.isHidden {
            projectBadge.sizeToFit()
            var badgeFrame = projectBadge.frame
            badgeFrame.size.width += 12
            badgeFrame.size.height = 18
            badgeFrame.origin = NSPoint(x: badgeX, y: (bounds.height - 18) / 2)
            projectBadge.frame = badgeFrame
            badgeX += badgeFrame.width + 4
        }

        badgeContainer.frame = NSRect(x: xOffset, y: 0, width: badgeX, height: bounds.height)
        xOffset += badgeX + 12

        // Right-aligned items
        var rightOffset = bounds.width - padding

        // Effort label (right-aligned)
        if !effortLabel.isHidden {
            effortLabel.sizeToFit()
            rightOffset -= effortLabel.frame.width
            effortLabel.frame = NSRect(
                x: rightOffset,
                y: (bounds.height - effortLabel.frame.height) / 2,
                width: effortLabel.frame.width,
                height: effortLabel.frame.height
            )
            rightOffset -= 12
        }

        // Due label
        if !dueLabel.isHidden {
            dueLabel.sizeToFit()
            rightOffset -= dueLabel.frame.width
            dueLabel.frame = NSRect(
                x: rightOffset,
                y: (bounds.height - dueLabel.frame.height) / 2,
                width: dueLabel.frame.width,
                height: dueLabel.frame.height
            )
            rightOffset -= 12
        }

        // Flagged indicator
        if !flaggedIndicator.isHidden {
            flaggedIndicator.sizeToFit()
            rightOffset -= flaggedIndicator.frame.width
            flaggedIndicator.frame = NSRect(
                x: rightOffset,
                y: (bounds.height - flaggedIndicator.frame.height) / 2,
                width: flaggedIndicator.frame.width,
                height: flaggedIndicator.frame.height
            )
        }
    }

    // MARK: - Configuration

    /// Configures the cell with task data
    /// - Parameters:
    ///   - task: The task to display
    ///   - indentationLevel: The indentation level (0 = top-level)
    ///   - hasSubtasks: Whether this task has subtasks
    ///   - isExpanded: Whether subtasks are expanded
    ///   - subtaskProgress: Optional subtask completion progress (completed, total)
    func configure(
        with task: Task,
        indentationLevel: Int = 0,
        hasSubtasks: Bool = false,
        isExpanded: Bool = false,
        subtaskProgress: (completed: Int, total: Int)? = nil
    ) {
        currentTask = task
        self.indentationLevel = indentationLevel
        self.hasSubtasks = hasSubtasks
        self.isExpanded = isExpanded

        // Disclosure triangle
        disclosureButton.isHidden = !hasSubtasks
        disclosureButton.state = isExpanded ? .on : .off

        // Subtask progress
        if let progress = subtaskProgress, progress.total > 0 {
            subtaskProgressLabel.stringValue = "\(progress.completed)/\(progress.total)"
            subtaskProgressLabel.isHidden = false

            // Update color based on completion
            if progress.completed == progress.total {
                configureBadge(subtaskProgressLabel, backgroundColor: .systemGreen.withAlphaComponent(0.1), textColor: .systemGreen)
            } else {
                configureBadge(subtaskProgressLabel, backgroundColor: .systemOrange.withAlphaComponent(0.1), textColor: .systemOrange)
            }
        } else {
            subtaskProgressLabel.isHidden = true
        }

        // Checkbox state
        checkbox.state = task.status == .completed ? .on : .off

        // Title
        titleField.stringValue = task.title
        if task.status == .completed {
            titleField.textColor = .secondaryLabelColor
        } else {
            titleField.textColor = .labelColor
        }

        // Priority indicator
        switch task.priority {
        case .high:
            priorityIndicator.isHidden = false
            priorityIndicator.layer?.backgroundColor = NSColor.systemRed.cgColor
        case .medium:
            priorityIndicator.isHidden = false
            priorityIndicator.layer?.backgroundColor = NSColor.systemYellow.cgColor
        case .low:
            priorityIndicator.isHidden = true
        }

        // Context badge
        if let context = task.context {
            contextBadge.stringValue = context
            contextBadge.isHidden = false
        } else {
            contextBadge.isHidden = true
        }

        // Project badge
        if let project = task.project {
            projectBadge.stringValue = project
            projectBadge.isHidden = false
        } else {
            projectBadge.isHidden = true
        }

        // Due date
        if let dueDesc = task.dueDescription {
            dueLabel.stringValue = dueDesc
            dueLabel.isHidden = false

            if task.isOverdue {
                dueLabel.textColor = .systemRed
            } else if task.isDueToday {
                dueLabel.textColor = .systemOrange
            } else {
                dueLabel.textColor = .secondaryLabelColor
            }
        } else {
            dueLabel.isHidden = true
        }

        // Effort
        if let effortDesc = task.effortDescription {
            effortLabel.stringValue = effortDesc
            effortLabel.isHidden = false
        } else {
            effortLabel.isHidden = true
        }

        // Flagged indicator
        flaggedIndicator.isHidden = !task.flagged

        needsLayout = true
    }

    // MARK: - Actions

    @objc private func checkboxToggled(_ sender: NSButton) {
        onCheckboxToggled?(sender.state == .on)
    }

    @objc private func disclosureToggled(_ sender: NSButton) {
        onDisclosureToggled?()
    }

    // MARK: - Editing

    func beginEditingTitle() {
        window?.makeFirstResponder(titleField)
        titleField.currentEditor()?.selectAll(nil)
    }
}

// MARK: - NSTextFieldDelegate

extension TaskTableCellView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField, textField == titleField else { return }
        onTitleChanged?(textField.stringValue)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            // Enter key - finish editing
            window?.makeFirstResponder(nil)
            return true
        } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // Escape key - cancel editing
            if let task = currentTask {
                titleField.stringValue = task.title
            }
            window?.makeFirstResponder(nil)
            return true
        }
        return false
    }
}

// MARK: - Group Header Cell View

/// Cell view for displaying group headers in the table
class GroupHeaderCellView: NSTableCellView {

    // MARK: - UI Components

    private let disclosureButton = NSButton()
    private let titleLabel = NSTextField(labelWithString: "")
    private let countBadge = NSTextField(labelWithString: "")

    // MARK: - Properties

    var onDisclosureToggled: (() -> Void)?
    private var isExpanded = true

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
        // Configure disclosure button
        disclosureButton.isBordered = false
        disclosureButton.title = ""
        disclosureButton.bezelStyle = .disclosure
        disclosureButton.setButtonType(.onOff)
        disclosureButton.target = self
        disclosureButton.action = #selector(disclosureToggled(_:))
        addSubview(disclosureButton)

        // Configure title label
        titleLabel.isBordered = false
        titleLabel.backgroundColor = .clear
        titleLabel.font = .boldSystemFont(ofSize: 11)
        titleLabel.textColor = .secondaryLabelColor
        addSubview(titleLabel)

        // Configure count badge
        countBadge.isBordered = false
        countBadge.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.1)
        countBadge.textColor = .secondaryLabelColor
        countBadge.font = .systemFont(ofSize: 10, weight: .medium)
        countBadge.alignment = .center
        countBadge.wantsLayer = true
        countBadge.layer?.cornerRadius = 8
        addSubview(countBadge)
    }

    override func layout() {
        super.layout()

        let bounds = self.bounds
        let padding: CGFloat = 8

        // Disclosure button
        disclosureButton.frame = NSRect(x: padding, y: (bounds.height - 16) / 2, width: 16, height: 16)

        // Title label
        titleLabel.sizeToFit()
        titleLabel.frame = NSRect(
            x: disclosureButton.frame.maxX + 4,
            y: (bounds.height - titleLabel.frame.height) / 2,
            width: titleLabel.frame.width,
            height: titleLabel.frame.height
        )

        // Count badge
        countBadge.sizeToFit()
        var badgeFrame = countBadge.frame
        badgeFrame.size.width += 12
        badgeFrame.size.height = 16
        badgeFrame.origin = NSPoint(
            x: titleLabel.frame.maxX + 6,
            y: (bounds.height - 16) / 2
        )
        countBadge.frame = badgeFrame
    }

    // MARK: - Configuration

    func configure(groupName: String, count: Int, expanded: Bool) {
        titleLabel.stringValue = groupName.uppercased()
        countBadge.stringValue = "\(count)"
        isExpanded = expanded
        disclosureButton.state = expanded ? .on : .off
        needsLayout = true
    }

    // MARK: - Actions

    @objc private func disclosureToggled(_ sender: NSButton) {
        onDisclosureToggled?()
    }
}
