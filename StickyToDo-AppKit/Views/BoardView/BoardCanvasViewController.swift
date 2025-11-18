//
//  BoardCanvasViewController.swift
//  StickyToDo-AppKit
//
//  Integrates the AppKit canvas prototype with real task data.
//  Manages board switching, task creation/updates, and position tracking.
//  Supports multiple layout modes: Freeform, Kanban, and Grid.
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

    /// Container for the current layout view
    private var containerView: NSView!

    /// Current layout view (freeform, kanban, or grid)
    private var currentLayoutView: NSView?

    // Layout-specific views
    private var scrollView: NSScrollView?
    private var canvasView: CanvasView?
    private var kanbanView: KanbanLayoutView?
    private var gridView: GridLayoutView?

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

    /// Map of task IDs to their sticky note views (for freeform layout)
    private var taskNoteMap: [UUID: StickyNoteView] = [:]

    /// Currently selected task
    private var selectedTask: Task? {
        didSet {
            delegate?.boardCanvasDidSelectTask(selectedTask)
        }
    }

    /// Toolbar items
    private var zoomLabel: NSTextField?
    private var layoutPicker: NSSegmentedControl?

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        setupContainerView()
        setupToolbar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Setup

    private func setupContainerView() {
        containerView = NSView(frame: view.bounds)
        containerView.autoresizingMask = [.width, .height]
        containerView.wantsLayer = true
        view.addSubview(containerView)
    }

    private func setupToolbar() {
        // Toolbar items will be created and added by the window controller
        // This includes layout picker, zoom controls, and add button
    }

    /// Creates the layout picker control for the toolbar
    func createLayoutPicker() -> NSSegmentedControl {
        let picker = NSSegmentedControl(labels: ["Freeform", "Kanban", "Grid"], trackingMode: .selectOne)
        picker.target = self
        picker.action = #selector(layoutPickerChanged(_:))
        picker.segmentStyle = .texturedRounded
        picker.setWidth(100, forSegment: 0)
        picker.setWidth(100, forSegment: 1)
        picker.setWidth(100, forSegment: 2)

        // Set initial selection based on current board layout
        if let board = currentBoard {
            switch board.layout {
            case .freeform:
                picker.selectedSegment = 0
            case .kanban:
                picker.selectedSegment = 1
            case .grid:
                picker.selectedSegment = 2
            }
        }

        self.layoutPicker = picker
        return picker
    }

    /// Creates the zoom label for the toolbar
    func createZoomLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "100%")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        self.zoomLabel = label
        return label
    }

    // MARK: - Layout Management

    private func setupLayoutView(for layout: Layout) {
        // Remove current layout view
        currentLayoutView?.removeFromSuperview()
        currentLayoutView = nil

        // Clear layout-specific views
        scrollView = nil
        canvasView = nil
        kanbanView = nil
        gridView = nil

        guard let board = currentBoard else { return }

        switch layout {
        case .freeform:
            setupFreeformLayout()
        case .kanban:
            setupKanbanLayout(board: board)
        case .grid:
            setupGridLayout(board: board)
        }
    }

    private func setupFreeformLayout() {
        // Create scroll view
        let scroll = NSScrollView(frame: containerView.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.backgroundColor = .white
        scroll.drawsBackground = true
        scroll.usesPredominantAxisScrolling = false
        scroll.horizontalScrollElasticity = .none
        scroll.verticalScrollElasticity = .none

        // Create canvas (large virtual space)
        let canvas = CanvasView(frame: NSRect(x: 0, y: 0, width: 5000, height: 5000))
        canvas.delegate = self

        scroll.documentView = canvas
        containerView.addSubview(scroll)

        // Center initial view
        let centerPoint = NSPoint(
            x: (canvas.frame.width - scroll.contentSize.width) / 2,
            y: (canvas.frame.height - scroll.contentSize.height) / 2
        )
        canvas.scroll(centerPoint)

        scrollView = scroll
        canvasView = canvas
        currentLayoutView = scroll

        // Show zoom controls
        zoomLabel?.isHidden = false

        // Update with current tasks
        updateFreeformCanvas()
    }

    private func setupKanbanLayout(board: Board) {
        let kanban = KanbanLayoutView(board: board)
        kanban.frame = containerView.bounds
        kanban.autoresizingMask = [.width, .height]
        kanban.delegate = self
        kanban.setTasks(displayedTasks)

        containerView.addSubview(kanban)

        kanbanView = kanban
        currentLayoutView = kanban

        // Hide zoom controls (not applicable for kanban)
        zoomLabel?.isHidden = true
    }

    private func setupGridLayout(board: Board) {
        let grid = GridLayoutView(board: board)
        grid.frame = containerView.bounds
        grid.autoresizingMask = [.width, .height]
        grid.delegate = self
        grid.setTasks(displayedTasks)

        containerView.addSubview(grid)

        gridView = grid
        currentLayoutView = grid

        // Hide zoom controls (not applicable for grid)
        zoomLabel?.isHidden = true
    }

    // MARK: - Actions

    @objc private func layoutPickerChanged(_ sender: NSSegmentedControl) {
        guard var board = currentBoard else { return }

        let newLayout: Layout
        switch sender.selectedSegment {
        case 0:
            newLayout = .freeform
        case 1:
            newLayout = .kanban
        case 2:
            newLayout = .grid
        default:
            return
        }

        // Update board layout
        board.layout = newLayout
        currentBoard = board

        // Save updated board configuration
        // (This would typically be handled by the data manager)
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
            clearAll()
            return
        }

        // Filter tasks for this board
        displayedTasks = allTasks.filter { task in
            task.matches(board.filter) && task.isVisible
        }

        // Setup appropriate layout view if needed
        if currentLayoutView == nil || needsLayoutSwitch(to: board.layout) {
            setupLayoutView(for: board.layout)
        }

        // Update the appropriate view
        switch board.layout {
        case .freeform:
            updateFreeformCanvas()
        case .kanban:
            kanbanView?.setTasks(displayedTasks)
        case .grid:
            gridView?.setTasks(displayedTasks)
        }

        // Update layout picker
        updateLayoutPicker(for: board.layout)
    }

    private func needsLayoutSwitch(to layout: Layout) -> Bool {
        switch layout {
        case .freeform:
            return canvasView == nil
        case .kanban:
            return kanbanView == nil
        case .grid:
            return gridView == nil
        }
    }

    private func updateLayoutPicker(for layout: Layout) {
        guard let picker = layoutPicker else { return }

        switch layout {
        case .freeform:
            picker.selectedSegment = 0
        case .kanban:
            picker.selectedSegment = 1
        case .grid:
            picker.selectedSegment = 2
        }
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

    // MARK: - Canvas Management (Freeform Layout)

    private func updateFreeformCanvas() {
        guard let canvas = canvasView else { return }
        guard let board = currentBoard else { return }

        // Remove all existing notes
        canvas.removeAllNotes()
        taskNoteMap.removeAll()

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
            canvas.addNote(noteView)
            taskNoteMap[task.id] = noteView
        }
    }

    private func clearAll() {
        canvasView?.removeAllNotes()
        taskNoteMap.removeAll()
        displayedTasks.removeAll()

        kanbanView?.setTasks([])
        gridView?.setTasks([])
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
        guard let canvas = canvasView else { return }
        canvas.zoomLevel = min(canvas.zoomLevel * 1.2, canvas.maxZoom)
        updateZoomLabel()
    }

    @objc func zoomOut(_ sender: Any?) {
        guard let canvas = canvasView else { return }
        canvas.zoomLevel = max(canvas.zoomLevel / 1.2, canvas.minZoom)
        updateZoomLabel()
    }

    @objc func zoomActual(_ sender: Any?) {
        guard let canvas = canvasView else { return }
        canvas.zoomLevel = 1.0
        updateZoomLabel()
    }

    @objc func zoomToFit(_ sender: Any?) {
        guard let canvas = canvasView else { return }
        canvas.zoomToFit(animated: true)
        updateZoomLabel()
    }

    private func updateZoomLabel() {
        guard let canvas = canvasView else { return }
        let zoomPercentage = Int(canvas.zoomLevel * 100)
        zoomLabel?.stringValue = "\(zoomPercentage)%"
    }
}

// MARK: - CanvasViewDelegate (Freeform Layout)

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

// MARK: - KanbanLayoutDelegate

extension BoardCanvasViewController: KanbanLayoutDelegate {
    func kanbanLayout(_ layout: KanbanLayoutView, didMoveTask task: Task, toColumn column: String) {
        guard let board = currentBoard,
              let taskIndex = allTasks.firstIndex(where: { $0.id == task.id }) else { return }

        var updatedTask = allTasks[taskIndex]

        // Apply metadata updates
        let metadata = LayoutEngine.metadataUpdates(forTask: updatedTask, inColumn: column, onBoard: board)
        applyMetadata(metadata, to: &updatedTask)

        delegate?.boardCanvasDidUpdateTask(updatedTask)
    }

    func kanbanLayout(_ layout: KanbanLayoutView, didUpdateTask task: Task) {
        delegate?.boardCanvasDidUpdateTask(task)
    }

    func kanbanLayout(_ layout: KanbanLayoutView, didSelectTask task: Task?) {
        selectedTask = task
    }

    func kanbanLayout(_ layout: KanbanLayoutView, didCreateTaskInColumn column: String) {
        guard let board = currentBoard else { return }

        var task = Task(
            type: .task,
            title: "New Task",
            status: .inbox
        )

        // Apply column metadata
        let metadata = LayoutEngine.metadataUpdates(forTask: task, inColumn: column, onBoard: board)
        applyMetadata(metadata, to: &task)

        delegate?.boardCanvasDidCreateTask(task)
    }
}

// MARK: - GridLayoutDelegate

extension BoardCanvasViewController: GridLayoutDelegate {
    func gridLayout(_ layout: GridLayoutView, didSelectTask task: Task?) {
        selectedTask = task
    }

    func gridLayout(_ layout: GridLayoutView, didUpdateTask task: Task) {
        delegate?.boardCanvasDidUpdateTask(task)
    }

    func gridLayout(_ layout: GridLayoutView, didMoveTask task: Task, toSection section: String) {
        guard let taskIndex = allTasks.firstIndex(where: { $0.id == task.id }) else { return }

        var updatedTask = allTasks[taskIndex]

        // Apply metadata updates
        let sections = LayoutEngine.sectionsForBoard(currentBoard!)
        let metadata = LayoutEngine.metadataUpdates(forTask: updatedTask, inSection: section, sections: sections)
        applyMetadata(metadata, to: &updatedTask)

        delegate?.boardCanvasDidUpdateTask(updatedTask)
    }

    func gridLayout(_ layout: GridLayoutView, didCreateTaskInSection section: String) {
        var task = Task(
            type: .task,
            title: "New Task",
            status: .inbox
        )

        // Apply section metadata
        let sections = LayoutEngine.sectionsForBoard(currentBoard!)
        let metadata = LayoutEngine.metadataUpdates(forTask: task, inSection: section, sections: sections)
        applyMetadata(metadata, to: &task)

        delegate?.boardCanvasDidCreateTask(task)
    }
}

// MARK: - Position Extension

extension Position {
    var nsPoint: NSPoint {
        return NSPoint(x: x, y: y)
    }
}
