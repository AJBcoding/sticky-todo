//
//  PerspectiveEditorViewController.swift
//  StickyToDo-AppKit
//
//  AppKit view controller for editing smart perspectives.
//

import Cocoa

/// Protocol for perspective editor communication
protocol PerspectiveEditorDelegate: AnyObject {
    func perspectiveEditorDidSave(_ perspective: SmartPerspective)
    func perspectiveEditorDidCancel()
    func perspectiveEditorDidExport(_ perspective: SmartPerspective)
}

/// AppKit view controller for creating and editing smart perspectives
class PerspectiveEditorViewController: NSViewController {

    // MARK: - Properties

    weak var delegate: PerspectiveEditorDelegate?

    /// Perspective being edited (nil for new)
    private var perspective: SmartPerspective?

    /// Form fields
    private var nameField: NSTextField!
    private var descriptionField: NSTextField!
    private var iconButton: NSButton!
    private var colorWell: NSColorWell!
    private var logicPopup: NSPopUpButton!
    private var groupByPopup: NSPopUpButton!
    private var sortByPopup: NSPopUpButton!
    private var sortDirectionPopup: NSPopUpButton!
    private var showCompletedCheckbox: NSButton!
    private var showDeferredCheckbox: NSButton!
    private var rulesTableView: NSTableView!

    /// Current state
    private var rules: [FilterRule] = []
    private var selectedIcon: String = "⭐"

    // MARK: - Initialization

    init(perspective: SmartPerspective? = nil) {
        self.perspective = perspective
        super.init(nibName: nil, bundle: nil)

        // Initialize state from perspective
        if let perspective = perspective {
            self.rules = perspective.rules
            self.selectedIcon = perspective.icon ?? "⭐"
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 600))
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = perspective == nil ? "New Perspective" : "Edit Perspective"
        loadPerspectiveData()
    }

    // MARK: - Setup

    private func setupUI() {
        let contentView = NSStackView()
        contentView.orientation = .vertical
        contentView.spacing = 20
        contentView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Header section
        let headerView = createHeaderSection()
        contentView.addArrangedSubview(headerView)

        // Basic info section
        let basicInfoView = createBasicInfoSection()
        contentView.addArrangedSubview(basicInfoView)

        // Filter rules section
        let rulesView = createRulesSection()
        contentView.addArrangedSubview(rulesView)

        // Display options section
        let displayView = createDisplayOptionsSection()
        contentView.addArrangedSubview(displayView)

        // Buttons
        let buttonsView = createButtonsSection()
        contentView.addArrangedSubview(buttonsView)

        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func createHeaderSection() -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 10

        let titleLabel = NSTextField(labelWithString: perspective == nil ? "New Perspective" : "Edit Perspective")
        titleLabel.font = .boldSystemFont(ofSize: 16)
        stack.addArrangedSubview(titleLabel)

        return stack
    }

    private func createBasicInfoSection() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 12

        // Section title
        let sectionLabel = NSTextField(labelWithString: "Basic Information")
        sectionLabel.font = .boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(sectionLabel)

        // Name
        let nameStack = NSStackView()
        nameStack.orientation = .horizontal
        nameStack.spacing = 10
        let nameLabel = NSTextField(labelWithString: "Name:")
        nameLabel.alignment = .right
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameField = NSTextField()
        nameField.placeholderString = "Perspective Name"
        nameStack.addArrangedSubview(nameLabel)
        nameStack.addArrangedSubview(nameField)
        stack.addArrangedSubview(nameStack)

        // Description
        let descStack = NSStackView()
        descStack.orientation = .horizontal
        descStack.spacing = 10
        let descLabel = NSTextField(labelWithString: "Description:")
        descLabel.alignment = .right
        descLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        descriptionField = NSTextField()
        descriptionField.placeholderString = "Optional description"
        descStack.addArrangedSubview(descLabel)
        descStack.addArrangedSubview(descriptionField)
        stack.addArrangedSubview(descStack)

        // Icon and Color
        let iconColorStack = NSStackView()
        iconColorStack.orientation = .horizontal
        iconColorStack.spacing = 20

        // Icon
        iconButton = NSButton(title: selectedIcon, target: self, action: #selector(selectIcon(_:)))
        iconButton.bezelStyle = .rounded
        iconButton.font = .systemFont(ofSize: 32)
        let iconLabel = NSTextField(labelWithString: "Icon:")
        iconLabel.alignment = .right
        iconColorStack.addArrangedSubview(iconLabel)
        iconColorStack.addArrangedSubview(iconButton)

        // Color
        colorWell = NSColorWell()
        colorWell.color = NSColor(hex: perspective?.color ?? "#007AFF")
        let colorLabel = NSTextField(labelWithString: "Color:")
        colorLabel.alignment = .right
        iconColorStack.addArrangedSubview(colorLabel)
        iconColorStack.addArrangedSubview(colorWell)

        stack.addArrangedSubview(iconColorStack)

        return stack
    }

    private func createRulesSection() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 12

        // Section title
        let sectionLabel = NSTextField(labelWithString: "Filter Rules")
        sectionLabel.font = .boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(sectionLabel)

        // Logic popup
        let logicStack = NSStackView()
        logicStack.orientation = .horizontal
        logicStack.spacing = 10
        let logicLabel = NSTextField(labelWithString: "Match:")
        logicLabel.alignment = .right
        logicPopup = NSPopUpButton()
        logicPopup.addItem(withTitle: "ALL rules (AND)")
        logicPopup.addItem(withTitle: "ANY rule (OR)")
        logicStack.addArrangedSubview(logicLabel)
        logicStack.addArrangedSubview(logicPopup)
        stack.addArrangedSubview(logicStack)

        // Rules table (simplified - just show count)
        let rulesLabel = NSTextField(labelWithString: "\(rules.count) rule\(rules.count == 1 ? "" : "s") defined")
        rulesLabel.font = .systemFont(ofSize: 11)
        rulesLabel.textColor = .secondaryLabelColor
        stack.addArrangedSubview(rulesLabel)

        // Add rule button
        let addButton = NSButton(title: "Add Rule", target: self, action: #selector(addRule(_:)))
        addButton.bezelStyle = .rounded
        stack.addArrangedSubview(addButton)

        return stack
    }

    private func createDisplayOptionsSection() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 12

        // Section title
        let sectionLabel = NSTextField(labelWithString: "Display Options")
        sectionLabel.font = .boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(sectionLabel)

        // Group by
        let groupStack = NSStackView()
        groupStack.orientation = .horizontal
        groupStack.spacing = 10
        let groupLabel = NSTextField(labelWithString: "Group by:")
        groupLabel.alignment = .right
        groupByPopup = NSPopUpButton()
        for groupBy in GroupBy.allCases {
            groupByPopup.addItem(withTitle: groupBy.displayName)
        }
        groupStack.addArrangedSubview(groupLabel)
        groupStack.addArrangedSubview(groupByPopup)
        stack.addArrangedSubview(groupStack)

        // Sort by
        let sortStack = NSStackView()
        sortStack.orientation = .horizontal
        sortStack.spacing = 10
        let sortLabel = NSTextField(labelWithString: "Sort by:")
        sortLabel.alignment = .right
        sortByPopup = NSPopUpButton()
        for sortBy in SortBy.allCases {
            sortByPopup.addItem(withTitle: sortBy.displayName)
        }
        sortDirectionPopup = NSPopUpButton()
        sortDirectionPopup.addItem(withTitle: "Ascending")
        sortDirectionPopup.addItem(withTitle: "Descending")
        sortStack.addArrangedSubview(sortLabel)
        sortStack.addArrangedSubview(sortByPopup)
        sortStack.addArrangedSubview(sortDirectionPopup)
        stack.addArrangedSubview(sortStack)

        // Checkboxes
        showCompletedCheckbox = NSButton(checkboxWithTitle: "Show completed tasks", target: self, action: nil)
        showDeferredCheckbox = NSButton(checkboxWithTitle: "Show deferred tasks", target: self, action: nil)
        stack.addArrangedSubview(showCompletedCheckbox)
        stack.addArrangedSubview(showDeferredCheckbox)

        return stack
    }

    private func createButtonsSection() -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // Escape

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Return

        stack.addArrangedSubview(cancelButton)
        stack.addArrangedSubview(saveButton)

        if perspective != nil {
            let exportButton = NSButton(title: "Export", target: self, action: #selector(export(_:)))
            exportButton.bezelStyle = .rounded
            stack.addArrangedSubview(exportButton)
        }

        return stack
    }

    // MARK: - Data Management

    private func loadPerspectiveData() {
        guard let perspective = perspective else { return }

        nameField.stringValue = perspective.name
        descriptionField.stringValue = perspective.description ?? ""
        iconButton.title = perspective.icon ?? "⭐"
        colorWell.color = NSColor(hex: perspective.color ?? "#007AFF")

        logicPopup.selectItem(at: perspective.logic == .and ? 0 : 1)

        if let index = GroupBy.allCases.firstIndex(of: perspective.groupBy) {
            groupByPopup.selectItem(at: index)
        }

        if let index = SortBy.allCases.firstIndex(of: perspective.sortBy) {
            sortByPopup.selectItem(at: index)
        }

        sortDirectionPopup.selectItem(at: perspective.sortDirection == .ascending ? 0 : 1)

        showCompletedCheckbox.state = perspective.showCompleted ? .on : .off
        showDeferredCheckbox.state = perspective.showDeferred ? .on : .off
    }

    private func createPerspective() -> SmartPerspective {
        let groupBy = GroupBy.allCases[groupByPopup.indexOfSelectedItem]
        let sortBy = SortBy.allCases[sortByPopup.indexOfSelectedItem]
        let sortDirection: SortDirection = sortDirectionPopup.indexOfSelectedItem == 0 ? .ascending : .descending
        let logic: FilterLogic = logicPopup.indexOfSelectedItem == 0 ? .and : .or

        return SmartPerspective(
            id: perspective?.id ?? UUID(),
            name: nameField.stringValue,
            description: descriptionField.stringValue.isEmpty ? nil : descriptionField.stringValue,
            rules: rules,
            logic: logic,
            groupBy: groupBy,
            sortBy: sortBy,
            sortDirection: sortDirection,
            showCompleted: showCompletedCheckbox.state == .on,
            showDeferred: showDeferredCheckbox.state == .on,
            icon: iconButton.title,
            color: colorWell.color.toHex(),
            isBuiltIn: false,
            created: perspective?.created ?? Date(),
            modified: Date()
        )
    }

    // MARK: - Actions

    @objc private func selectIcon(_ sender: Any) {
        // Show simple icon picker alert
        let alert = NSAlert()
        alert.messageText = "Select Icon"
        alert.informativeText = "Enter an emoji to use as the perspective icon"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputField.stringValue = iconButton.title
        alert.accessoryView = inputField

        if alert.runModal() == .alertFirstButtonReturn {
            iconButton.title = inputField.stringValue
            selectedIcon = inputField.stringValue
        }
    }

    @objc private func addRule(_ sender: Any) {
        // For simplicity, just show an alert
        let alert = NSAlert()
        alert.messageText = "Add Rule"
        alert.informativeText = "Use the SwiftUI interface to add and edit filter rules."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func cancel(_ sender: Any) {
        delegate?.perspectiveEditorDidCancel()
    }

    @objc private func save(_ sender: Any) {
        guard !nameField.stringValue.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "Name Required"
            alert.informativeText = "Please enter a name for the perspective."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        let perspective = createPerspective()
        delegate?.perspectiveEditorDidSave(perspective)
    }

    @objc private func export(_ sender: Any) {
        let perspective = createPerspective()
        delegate?.perspectiveEditorDidExport(perspective)
    }
}

// MARK: - NSColor Extension

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }

    func toHex() -> String {
        guard let components = cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
