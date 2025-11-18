//
//  QuickCaptureWindowController.swift
//  StickyToDo-AppKit
//
//  Floating quick capture window with natural language parsing.
//  Supports global hotkey (Cmd+Shift+Space) for quick task entry.
//

import Cocoa
import Carbon

/// Protocol for communicating captured tasks
protocol QuickCaptureDelegate: AnyObject {
    func quickCaptureDidCreateTask(_ task: Task)
}

/// Window controller for the quick capture panel
class QuickCaptureWindowController: NSWindowController {

    // MARK: - Properties

    weak var delegate: QuickCaptureDelegate?

    /// Input text field
    private let inputField = NSTextField()

    /// Parser for natural language input
    private let parser = NaturalLanguageParser()

    /// Recent contexts for quick selection
    private var recentContexts: [String] = []

    /// Recent projects for quick selection
    private var recentProjects: [String] = []

    /// Pills container for recent items
    private let pillsContainer = NSView()

    /// Context pills
    private var contextPills: [NSButton] = []

    /// Project pills
    private var projectPills: [NSButton] = []

    /// Hint label
    private let hintLabel = NSTextField(labelWithString: "Hint: Use @context #project !priority tomorrow //30m")

    /// Global hotkey reference
    private var hotKeyRef: EventHotKeyRef?

    // MARK: - Initialization

    convenience init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 200),
            styleMask: [.titled, .closable, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        panel.title = "Quick Capture"
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true

        self.init(window: panel)
        setupUI()
    }

    deinit {
        unregisterHotKey()
    }

    // MARK: - Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        var yOffset: CGFloat = 20
        let padding: CGFloat = 20

        // Input field
        inputField.frame = NSRect(
            x: padding,
            y: contentView.bounds.height - yOffset - 30,
            width: contentView.bounds.width - 2 * padding,
            height: 30
        )
        inputField.placeholderString = "Enter task... (Esc to cancel, Enter to save)"
        inputField.font = .systemFont(ofSize: 14)
        inputField.delegate = self
        inputField.target = self
        inputField.action = #selector(inputFieldAction(_:))
        contentView.addSubview(inputField)

        yOffset += 40

        // Hint label
        hintLabel.frame = NSRect(
            x: padding,
            y: contentView.bounds.height - yOffset - 16,
            width: contentView.bounds.width - 2 * padding,
            height: 16
        )
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.isBordered = false
        hintLabel.backgroundColor = .clear
        contentView.addSubview(hintLabel)

        yOffset += 24

        // Pills container
        pillsContainer.frame = NSRect(
            x: padding,
            y: contentView.bounds.height - yOffset - 60,
            width: contentView.bounds.width - 2 * padding,
            height: 60
        )
        contentView.addSubview(pillsContainer)

        updatePills()
    }

    private func updatePills() {
        // Clear existing pills
        pillsContainer.subviews.forEach { $0.removeFromSuperview() }
        contextPills.removeAll()
        projectPills.removeAll()

        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        let pillSpacing: CGFloat = 8

        // Add context pills
        if !recentContexts.isEmpty {
            let label = NSTextField(labelWithString: "Contexts:")
            label.font = .systemFont(ofSize: 10, weight: .medium)
            label.textColor = .tertiaryLabelColor
            label.isBordered = false
            label.backgroundColor = .clear
            label.sizeToFit()
            label.frame.origin = NSPoint(x: xOffset, y: yOffset + 6)
            pillsContainer.addSubview(label)
            xOffset += label.frame.width + 8

            for context in recentContexts.prefix(5) {
                let pill = makePill(title: context, color: .systemBlue)
                pill.frame.origin = NSPoint(x: xOffset, y: yOffset)
                pill.target = self
                pill.action = #selector(contextPillClicked(_:))
                pillsContainer.addSubview(pill)
                contextPills.append(pill)
                xOffset += pill.frame.width + pillSpacing
            }
        }

        // Move to next row for projects
        xOffset = 0
        yOffset += 30

        // Add project pills
        if !recentProjects.isEmpty {
            let label = NSTextField(labelWithString: "Projects:")
            label.font = .systemFont(ofSize: 10, weight: .medium)
            label.textColor = .tertiaryLabelColor
            label.isBordered = false
            label.backgroundColor = .clear
            label.sizeToFit()
            label.frame.origin = NSPoint(x: xOffset, y: yOffset + 6)
            pillsContainer.addSubview(label)
            xOffset += label.frame.width + 8

            for project in recentProjects.prefix(5) {
                let pill = makePill(title: project, color: .systemGreen)
                pill.frame.origin = NSPoint(x: xOffset, y: yOffset)
                pill.target = self
                pill.action = #selector(projectPillClicked(_:))
                pillsContainer.addSubview(pill)
                projectPills.append(pill)
                xOffset += pill.frame.width + pillSpacing
            }
        }
    }

    private func makePill(title: String, color: NSColor) -> NSButton {
        let button = NSButton(title: title, target: nil, action: nil)
        button.bezelStyle = .rounded
        button.isBordered = true
        button.font = .systemFont(ofSize: 11)
        button.contentTintColor = color
        button.sizeToFit()

        var frame = button.frame
        frame.size.width += 16
        frame.size.height = 24
        button.frame = frame

        return button
    }

    // MARK: - Public Methods

    /// Shows the quick capture window
    func show() {
        // Center on screen
        window?.center()

        // Show window
        window?.makeKeyAndOrderFront(nil)

        // Focus input field
        inputField.stringValue = ""
        window?.makeFirstResponder(inputField)
    }

    /// Hides the quick capture window
    func hide() {
        window?.orderOut(nil)
    }

    /// Sets recent contexts for pills
    func setRecentContexts(_ contexts: [String]) {
        recentContexts = contexts
        updatePills()
    }

    /// Sets recent projects for pills
    func setRecentProjects(_ projects: [String]) {
        recentProjects = projects
        updatePills()
    }

    /// Registers the global hotkey (Cmd+Shift+Space)
    func registerHotKey() {
        var hotKeyID = EventHotKeyID(signature: UTGetOSTypeFromString("STQC"), id: 1)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Register Cmd+Shift+Space
        let status = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("Failed to register hotkey: \(status)")
        }
    }

    /// Unregisters the global hotkey
    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    // MARK: - Actions

    @objc private func inputFieldAction(_ sender: NSTextField) {
        createTask()
    }

    @objc private func contextPillClicked(_ sender: NSButton) {
        // Append context to input
        let currentText = inputField.stringValue
        inputField.stringValue = currentText + " " + sender.title
        window?.makeFirstResponder(inputField)
    }

    @objc private func projectPillClicked(_ sender: NSButton) {
        // Append project to input
        let currentText = inputField.stringValue
        inputField.stringValue = currentText + " #" + sender.title
        window?.makeFirstResponder(inputField)
    }

    private func createTask() {
        let input = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !input.isEmpty else {
            hide()
            return
        }

        // Parse input
        let parseResult = parser.parse(input)

        // Create task
        var task = Task(
            title: parseResult.title,
            status: .inbox
        )

        // Apply parsed metadata
        task.context = parseResult.context
        task.project = parseResult.project
        task.priority = parseResult.priority ?? .medium
        task.due = parseResult.dueDate
        task.defer = parseResult.deferDate
        task.effort = parseResult.effort

        // Notify delegate
        delegate?.quickCaptureDidCreateTask(task)

        // Clear and hide
        inputField.stringValue = ""
        hide()
    }

    private func cancel() {
        inputField.stringValue = ""
        hide()
    }
}

// MARK: - NSTextFieldDelegate

extension QuickCaptureWindowController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            // Enter key - create task
            createTask()
            return true
        } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // Escape key - cancel
            cancel()
            return true
        }
        return false
    }
}

// MARK: - NSWindowDelegate

extension QuickCaptureWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clear input when window closes
        inputField.stringValue = ""
    }
}
