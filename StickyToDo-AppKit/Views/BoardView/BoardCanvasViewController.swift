//
//  BoardCanvasViewController.swift
//  StickyToDo-AppKit
//
//  Integrates the AppKit canvas prototype with real task data.
//  Manages board switching, task creation/updates, and position tracking.
//

import Cocoa

/// Protocol for communicating board canvas actions
protocol BoardCanvasDelegate: AnyObject {
    func boardCanvasDidCreateTask(_ task: Task)
    func boardCanvasDidUpdateTask(_ task: Task)
    func boardCanvasDidSelectTask(_ task: Task?)
    func boardCanvasDidPromoteNotes(_ tasks: [Task])
}

/// View controller for the board canvas view
class BoardCanvasViewController: NSViewController {

    // MARK: - Properties

    weak var delegate: BoardCanvasDelegate?

    /// Scroll view containing the canvas
    private var scrollView: NSScrollView!

    /// Main canvas view (from prototype)
    private var canvasView: CanvasView!

    /// Current board being displayed
    private(set) var currentBoard: Board? {
        didSet {
            refreshBoard()
        }
    }

    /// All tasks (unfiltered)
    private var allTasks: [Task] = []

    /// Tasks currently displayed on the board
    private var displayedTasks: [Task] = []

    /// Map of task IDs to their sticky note views
    private var taskNoteMap: [UUID: StickyNoteView] = [:]

    /// Currently selected task
    private var selectedTask: Task? {
        didSet {
            delegate?.boardCanvasDidSelectTask(selectedTask)
        }
    }

    /// Toolbar items
    private var zoomLabel: NSTextField!

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        setupCanvas()
        setupToolbar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Setup

    private func setupCanvas() {
        // Create scroll view
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.backgroundColor = .white
        scrollView.drawsBackground = true
        scrollView.usesPredominantAxisScrolling = false
        scrollView.horizontalScrollElasticity = .none
        scrollView.verticalScrollElasticity = .none

        // Create canvas (large virtual space)
        canvasView = CanvasView(frame: NSRect(x: 0, y: 0, width: 5000, height: 5000))
        canvasView.delegate = self

        scrollView.documentView = canvasView
        view.addSubview(scrollView)

        // Center initial view
        let centerPoint = NSPoint(
            x: (canvasView.frame.width - scrollView.contentSize.width) / 2,
            y: (canvasView.frame.height - scrollView.contentSize.height) / 2
        )
        canvasView.scroll(centerPoint)
    }

    private func setupToolbar() {
        // Toolbar setup will be handled by MainWindowController
    }

    // MARK: - Public Methods

    /// Sets all tasks (will be filtered by current board)
    func setTasks(_ tasks: [Task]) {
        allTasks = tasks
        refreshBoard()
    }

    /// Changes the current board
    func setBoard(_ board: Board) {
        currentBoard = board
    }

    /// Refreshes the board display
    func refreshBoard() {
        guard let board = currentBoard else {
            clearCanvas()
            return
        }

        // Filter tasks for this board
        displayedTasks = allTasks.filter { task in
            task.matches(board.filter) && task.isVisible
        }

        // Update canvas
        updateCanvas()
    }

    /// Creates a new task at the given position
    func createTaskAtPosition(_ position: NSPoint, title: String = "New Note") {
        guard let board = currentBoard else { return }

        var task = Task(
            type: .note, // Start as note for brainstorming
            title: title,
            status: .inbox
        )

        // Set position for this board
        task.setPosition(Position(x: Double(position.x), y: Double(position.y)), for: board.id)

        // Apply board metadata if appropriate
        let metadata = board.metadataUpdates()
        applyMetadata(metadata, to: &task)

        delegate?.boardCanvasDidCreateTask(task)
    }

    /// Promotes selected notes to tasks
    func promoteSelectedNotesToTasks() {
        let selectedNoteViews = canvasView.noteViews.filter { $0.isSelected }
        var tasksToPromote: [Task] = []

        for noteView in selectedNoteViews {
            if var task = displayedTasks.first(where: { $0.id == noteView.id }) {
                task.promoteToTask()
                tasksToPromote.append(task)
            }
        }

        if !tasksToPromote.isEmpty {
            delegate?.boardCanvasDidPromoteNotes(tasksToPromote)
        }
    }

    /// Applies metadata to selected tasks
    func applyMetadataToSelection(_ metadata: [String: Any]) {
        let selectedNoteViews = canvasView.noteViews.filter { $0.isSelected }

        for noteView in selectedNoteViews {
            if var task = displayedTasks.first(where: { $0.id == noteView.id }) {
                applyMetadata(metadata, to: &task)
                delegate?.boardCanvasDidUpdateTask(task)
            }
        }
    }

    // MARK: - Canvas Management

    private func updateCanvas() {
        // Remove all existing notes
        canvasView.removeAllNotes()
        taskNoteMap.removeAll()

        guard let board = currentBoard else { return }

        // Add notes for each task
        for task in displayedTasks {
            // Get position for this board, or use default
            let position: Position
            if let savedPosition = task.position(for: board.id) {
                position = savedPosition
            } else {
                // Auto-layout: find empty spot
                position = findEmptySpot()
            }

            // Create sticky note view
            let noteView = StickyNoteView(
                id: task.id,
                title: task.title,
                color: colorForTask(task),
                position: NSPoint(x: position.x, y: position.y)
            )

            // Add to canvas
            canvasView.addNote(noteView)
            taskNoteMap[task.id] = noteView
        }
    }

    private func clearCanvas() {
        canvasView.removeAllNotes()
        taskNoteMap.removeAll()
        displayedTasks.removeAll()
    }

    private func findEmptySpot() -> Position {
        // Simple grid layout for new items
        let gridSize: CGFloat = 250
        let startX: CGFloat = 200
        let startY: CGFloat = 200

        var testX = startX
        var testY = startY

        // Find first empty spot
        while true {
            let testRect = NSRect(x: testX, y: testY, width: 200, height: 150)
            var overlaps = false

            for noteView in canvasView.noteViews {
                if noteView.frame.intersects(testRect) {
                    overlaps = true
                    break
                }
            }

            if !overlaps {
                return Position(x: Double(testX), y: Double(testY))
            }

            testX += gridSize
            if testX > canvasView.frame.width - 400 {
                testX = startX
                testY += gridSize
            }

            // Safety: don't loop forever
            if testY > canvasView.frame.height - 400 {
                break
            }
        }

        // Fallback to random position
        return Position(
            x: Double.random(in: 200...800),
            y: Double.random(in: 200...800)
        )
    }

    private func colorForTask(_ task: Task) -> NSColor {
        // Color based on status, priority, or type
        if task.type == .note {
            return .systemYellow
        }

        switch task.priority {
        case .high:
            return .systemRed.withAlphaComponent(0.3)
        case .medium:
            return .systemBlue.withAlphaComponent(0.3)
        case .low:
            return .systemGray.withAlphaComponent(0.3)
        }
    }

    private func applyMetadata(_ metadata: [String: Any], to task: inout Task) {
        for (key, value) in metadata {
            switch key {
            case "context":
                if let context = value as? String {
                    task.context = context
                }
            case "project":
                if let project = value as? String {
                    task.project = project
                }
            case "status":
                if let statusString = value as? String,
                   let status = Status(rawValue: statusString) {
                    task.status = status
                }
            case "priority":
                if let priorityString = value as? String,
                   let priority = Priority(rawValue: priorityString) {
                    task.priority = priority
                }
            case "flagged":
                if let flagged = value as? Bool {
                    task.flagged = flagged
                }
            default:
                break
            }
        }
        task.modified = Date()
    }

    // MARK: - Actions

    @objc func addNote(_ sender: Any?) {
        // Add note at center of visible area
        let visibleRect = scrollView.documentVisibleRect
        let centerPoint = NSPoint(x: visibleRect.midX, y: visibleRect.midY)
        createTaskAtPosition(centerPoint, title: "New Note")
    }

    @objc func zoomIn(_ sender: Any?) {
        canvasView.zoomLevel = min(canvasView.zoomLevel * 1.2, canvasView.maxZoom)
        updateZoomLabel()
    }

    @objc func zoomOut(_ sender: Any?) {
        canvasView.zoomLevel = max(canvasView.zoomLevel / 1.2, canvasView.minZoom)
        updateZoomLabel()
    }

    @objc func zoomActual(_ sender: Any?) {
        canvasView.zoomLevel = 1.0
        updateZoomLabel()
    }

    @objc func zoomToFit(_ sender: Any?) {
        canvasView.zoomToFit(animated: true)
        updateZoomLabel()
    }

    private func updateZoomLabel() {
        let zoomPercentage = Int(canvasView.zoomLevel * 100)
        zoomLabel?.stringValue = "\(zoomPercentage)%"
    }
}

// MARK: - CanvasViewDelegate

extension BoardCanvasViewController: CanvasViewDelegate {
    func canvasView(_ canvasView: CanvasView, didAddNote noteView: StickyNoteView) {
        // Note added
    }

    func canvasView(_ canvasView: CanvasView, didRemoveNote noteView: StickyNoteView) {
        // Note removed
        taskNoteMap.removeValue(forKey: noteView.id)
    }

    func canvasView(_ canvasView: CanvasView, didMoveNote noteView: StickyNoteView, to position: NSPoint) {
        // Update task position
        guard let board = currentBoard,
              var task = displayedTasks.first(where: { $0.id == noteView.id }) else { return }

        task.setPosition(Position(x: Double(position.x), y: Double(position.y)), for: board.id)
        delegate?.boardCanvasDidUpdateTask(task)
    }

    func canvasView(_ canvasView: CanvasView, didUpdateNote noteView: StickyNoteView, newTitle: String) {
        // Update task title
        guard var task = displayedTasks.first(where: { $0.id == noteView.id }) else { return }

        task.title = newTitle
        delegate?.boardCanvasDidUpdateTask(task)
    }

    func canvasView(_ canvasView: CanvasView, didChangeSelection selectedIds: [UUID]) {
        // Update selected task
        if selectedIds.count == 1,
           let taskId = selectedIds.first,
           let task = displayedTasks.first(where: { $0.id == taskId }) {
            selectedTask = task
        } else {
            selectedTask = nil
        }
    }

    func canvasView(_ canvasView: CanvasView, didChangeZoom zoom: CGFloat) {
        updateZoomLabel()
    }
}

// MARK: - Position Extension

extension Position {
    var nsPoint: NSPoint {
        return NSPoint(x: x, y: y)
    }
}
