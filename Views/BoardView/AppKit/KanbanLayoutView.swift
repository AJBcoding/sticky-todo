//
//  KanbanLayoutView.swift
//  StickyToDo-AppKit
//
//  Kanban board layout with vertical columns for workflow stages.
//  Supports drag-and-drop between columns with automatic metadata updates.
//

import Cocoa

/// Protocol for communicating kanban layout events
protocol KanbanLayoutDelegate: AnyObject {
    func kanbanLayout(_ layout: KanbanLayoutView, didMoveTask task: Task, toColumn column: String)
    func kanbanLayout(_ layout: KanbanLayoutView, didUpdateTask task: Task)
    func kanbanLayout(_ layout: KanbanLayoutView, didSelectTask task: Task?)
    func kanbanLayout(_ layout: KanbanLayoutView, didCreateTaskInColumn column: String)
}

/// Kanban board view with vertical columns
///
/// Displays tasks organized in vertical swim lanes. Each column represents
/// a stage in the workflow. Tasks can be dragged between columns, which
/// automatically updates their metadata.
class KanbanLayoutView: NSView {

    // MARK: - Properties

    weak var delegate: KanbanLayoutDelegate?

    /// Current board configuration
    private var board: Board

    /// Tasks to display
    private var tasks: [Task] = []

    /// Column views
    private var columnViews: [KanbanColumnView] = []

    /// Scroll view containing the columns
    private var scrollView: NSScrollView!

    /// Container for columns
    private var columnsContainer: NSView!

    /// Currently selected task ID
    private var selectedTaskId: UUID?

    // MARK: - Initialization

    init(board: Board) {
        self.board = board
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        setupScrollView()
        layoutColumns()
    }

    private func setupScrollView() {
        scrollView = NSScrollView(frame: bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = false
        scrollView.usesPredominantAxisScrolling = false

        columnsContainer = NSView()
        columnsContainer.wantsLayer = true

        scrollView.documentView = columnsContainer
        addSubview(scrollView)
    }

    // MARK: - Public Methods

    /// Updates the tasks displayed in the kanban board
    func setTasks(_ tasks: [Task]) {
        self.tasks = tasks
        layoutColumns()
    }

    /// Updates the board configuration
    func setBoard(_ board: Board) {
        self.board = board
        layoutColumns()
    }

    /// Refreshes the layout
    func refresh() {
        layoutColumns()
    }

    // MARK: - Layout

    private func layoutColumns() {
        // Remove existing columns
        columnViews.forEach { $0.removeFromSuperview() }
        columnViews.removeAll()

        let columns = board.effectiveColumns
        guard !columns.isEmpty else { return }

        // Group tasks by column
        var tasksByColumn: [String: [Task]] = [:]
        for column in columns {
            tasksByColumn[column] = []
        }

        for task in tasks {
            if let columnName = LayoutEngine.assignTaskToColumn(task: task, board: board) {
                tasksByColumn[columnName]?.append(task)
            } else {
                // Default to first column
                tasksByColumn[columns.first!]?.append(task)
            }
        }

        // Create column views
        let columnWidth = LayoutEngine.defaultColumnWidth
        let spacing = LayoutEngine.columnSpacing

        for (index, column) in columns.enumerated() {
            let columnTasks = tasksByColumn[column] ?? []
            let columnView = KanbanColumnView(
                title: column,
                tasks: columnTasks,
                board: board
            )
            columnView.delegate = self

            let x = CGFloat(index) * (columnWidth + spacing)
            columnView.frame = NSRect(x: x, y: 0, width: columnWidth, height: 600)

            columnsContainer.addSubview(columnView)
            columnViews.append(columnView)
        }

        // Update container size
        let totalWidth = CGFloat(columns.count) * (columnWidth + spacing)
        let maxHeight = columnViews.map { $0.contentHeight }.max() ?? 600
        columnsContainer.frame = NSRect(x: 0, y: 0, width: totalWidth, height: maxHeight)

        // Update column heights
        for columnView in columnViews {
            var frame = columnView.frame
            frame.size.height = maxHeight
            columnView.frame = frame
        }
    }

    // MARK: - Task Management

    private func taskMoved(task: Task, fromColumn: String, toColumn: String) {
        guard fromColumn != toColumn else { return }

        // Notify delegate
        delegate?.kanbanLayout(self, didMoveTask: task, toColumn: toColumn)
    }
}

// MARK: - KanbanColumnViewDelegate

extension KanbanLayoutView: KanbanColumnViewDelegate {
    func kanbanColumn(_ column: KanbanColumnView, didSelectTask task: Task) {
        selectedTaskId = task.id
        delegate?.kanbanLayout(self, didSelectTask: task)
    }

    func kanbanColumn(_ column: KanbanColumnView, didUpdateTask task: Task) {
        delegate?.kanbanLayout(self, didUpdateTask: task)
    }

    func kanbanColumn(_ column: KanbanColumnView, didRequestAddTask columnName: String) {
        delegate?.kanbanLayout(self, didCreateTaskInColumn: columnName)
    }

    func kanbanColumn(_ column: KanbanColumnView, didMoveTask task: Task, toColumn targetColumn: String) {
        // Find source column
        var sourceColumn: String?
        for (columnName, tasks) in columnViewsTaskMap() {
            if tasks.contains(where: { $0.id == task.id }) {
                sourceColumn = columnName
                break
            }
        }

        if let source = sourceColumn {
            taskMoved(task: task, fromColumn: source, toColumn: targetColumn)
        }
    }

    private func columnViewsTaskMap() -> [String: [Task]] {
        var map: [String: [Task]] = [:]
        for columnView in columnViews {
            map[columnView.columnTitle] = columnView.tasks
        }
        return map
    }
}

// MARK: - Kanban Column View

protocol KanbanColumnViewDelegate: AnyObject {
    func kanbanColumn(_ column: KanbanColumnView, didSelectTask task: Task)
    func kanbanColumn(_ column: KanbanColumnView, didUpdateTask task: Task)
    func kanbanColumn(_ column: KanbanColumnView, didRequestAddTask columnName: String)
    func kanbanColumn(_ column: KanbanColumnView, didMoveTask task: Task, toColumn: String)
}

/// A single column in the kanban board
class KanbanColumnView: NSView {

    // MARK: - Properties

    weak var delegate: KanbanColumnViewDelegate?

    let columnTitle: String
    private(set) var tasks: [Task]
    private let board: Board

    private var headerView: NSView!
    private var titleLabel: NSTextField!
    private var countLabel: NSTextField!
    private var addButton: NSButton!
    private var taskCardsContainer: NSView!
    private var taskCardViews: [KanbanTaskCardView] = []

    var contentHeight: CGFloat {
        let headerHeight: CGFloat = 60
        let cardsHeight = CGFloat(tasks.count) * (LayoutEngine.defaultCardHeight + LayoutEngine.cardSpacing)
        let padding: CGFloat = LayoutEngine.columnPadding * 2
        return headerHeight + cardsHeight + padding
    }

    // MARK: - Initialization

    init(title: String, tasks: [Task], board: Board) {
        self.columnTitle = title
        self.tasks = tasks
        self.board = board
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor

        setupHeader()
        setupTasksContainer()
        layoutTaskCards()

        // Register for drag and drop
        registerForDraggedTypes([.string])
    }

    private func setupHeader() {
        headerView = NSView(frame: NSRect(x: 0, y: frame.height - 60, width: frame.width, height: 60))
        headerView.autoresizingMask = [.width, .minYMargin]
        headerView.wantsLayer = true

        // Title label
        titleLabel = NSTextField(labelWithString: columnTitle)
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.frame = NSRect(x: 12, y: 28, width: frame.width - 80, height: 20)
        titleLabel.autoresizingMask = [.width]
        headerView.addSubview(titleLabel)

        // Count badge
        countLabel = NSTextField(labelWithString: "\(tasks.count)")
        countLabel.font = .systemFont(ofSize: 12, weight: .medium)
        countLabel.textColor = .secondaryLabelColor
        countLabel.alignment = .center
        countLabel.frame = NSRect(x: frame.width - 60, y: 28, width: 30, height: 20)
        countLabel.autoresizingMask = [.minXMargin]
        headerView.addSubview(countLabel)

        // Add button
        addButton = NSButton(frame: NSRect(x: 12, y: 8, width: frame.width - 24, height: 16))
        addButton.title = "+ Add Task"
        addButton.font = .systemFont(ofSize: 11)
        addButton.bezelStyle = .inline
        addButton.target = self
        addButton.action = #selector(addTaskClicked)
        addButton.autoresizingMask = [.width]
        headerView.addSubview(addButton)

        addSubview(headerView)
    }

    private func setupTasksContainer() {
        taskCardsContainer = NSView(frame: NSRect(x: 0, y: 0, width: frame.width, height: frame.height - 60))
        taskCardsContainer.autoresizingMask = [.width, .height]
        addSubview(taskCardsContainer)
    }

    private func layoutTaskCards() {
        // Remove existing cards
        taskCardViews.forEach { $0.removeFromSuperview() }
        taskCardViews.removeAll()

        // Create new cards
        var yOffset: CGFloat = frame.height - 60 - LayoutEngine.columnPadding

        for task in tasks {
            yOffset -= LayoutEngine.defaultCardHeight

            let cardView = KanbanTaskCardView(task: task)
            cardView.delegate = self
            cardView.frame = NSRect(
                x: LayoutEngine.columnPadding,
                y: yOffset,
                width: frame.width - (LayoutEngine.columnPadding * 2),
                height: LayoutEngine.defaultCardHeight
            )

            addSubview(cardView)
            taskCardViews.append(cardView)

            yOffset -= LayoutEngine.cardSpacing
        }

        // Update count label
        countLabel.stringValue = "\(tasks.count)"
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layoutTaskCards()
    }

    // MARK: - Actions

    @objc private func addTaskClicked() {
        delegate?.kanbanColumn(self, didRequestAddTask: columnTitle)
    }

    // MARK: - Drag and Drop

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .move
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // Handle task drop
        guard let taskIdString = sender.draggingPasteboard.string(forType: .string),
              let taskId = UUID(uuidString: taskIdString),
              let task = tasks.first(where: { $0.id == taskId }) else {
            return false
        }

        delegate?.kanbanColumn(self, didMoveTask: task, toColumn: columnTitle)
        return true
    }
}

// MARK: - KanbanTaskCardViewDelegate

extension KanbanColumnView: KanbanTaskCardViewDelegate {
    func kanbanTaskCard(_ card: KanbanTaskCardView, didSelectTask task: Task) {
        delegate?.kanbanColumn(self, didSelectTask: task)
    }

    func kanbanTaskCard(_ card: KanbanTaskCardView, didUpdateTask task: Task) {
        delegate?.kanbanColumn(self, didUpdateTask: task)
    }

    func kanbanTaskCard(_ card: KanbanTaskCardView, didBeginDraggingTask task: Task) {
        // Visual feedback for drag start
        card.alphaValue = 0.5
    }

    func kanbanTaskCard(_ card: KanbanTaskCardView, didEndDraggingTask task: Task) {
        // Restore visual state
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            card.animator().alphaValue = 1.0
        }
    }
}

// MARK: - Kanban Task Card View

protocol KanbanTaskCardViewDelegate: AnyObject {
    func kanbanTaskCard(_ card: KanbanTaskCardView, didSelectTask task: Task)
    func kanbanTaskCard(_ card: KanbanTaskCardView, didUpdateTask task: Task)
    func kanbanTaskCard(_ card: KanbanTaskCardView, didBeginDraggingTask task: Task)
    func kanbanTaskCard(_ card: KanbanTaskCardView, didEndDraggingTask task: Task)
}

/// Individual task card in a kanban column
class KanbanTaskCardView: NSView {

    // MARK: - Properties

    weak var delegate: KanbanTaskCardViewDelegate?

    private let task: Task
    private var isSelected = false
    private var titleLabel: NSTextField!
    private var metadataStack: NSStackView!

    // MARK: - Initialization

    init(task: Task) {
        self.task = task
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = colorForTask(task).cgColor
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor

        // Shadow
        shadow = NSShadow()
        shadow?.shadowColor = NSColor.black.withAlphaComponent(0.15)
        shadow?.shadowOffset = NSSize(width: 0, height: -2)
        shadow?.shadowBlurRadius = 4

        setupContent()

        // Enable drag
        registerForDraggedTypes([.string])
    }

    private func setupContent() {
        // Title
        titleLabel = NSTextField(labelWithString: task.title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.maximumNumberOfLines = 3
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.frame = NSRect(x: 12, y: frame.height - 50, width: frame.width - 24, height: 40)
        titleLabel.autoresizingMask = [.width, .minYMargin]
        addSubview(titleLabel)

        // Metadata badges
        metadataStack = NSStackView()
        metadataStack.orientation = .horizontal
        metadataStack.spacing = 4
        metadataStack.alignment = .centerY
        metadataStack.frame = NSRect(x: 12, y: 8, width: frame.width - 24, height: 20)
        metadataStack.autoresizingMask = [.width, .maxYMargin]
        addSubview(metadataStack)

        addMetadataBadges()
    }

    private func addMetadataBadges() {
        // Context badge
        if let context = task.context {
            let badge = createBadge(text: context, color: .systemBlue)
            metadataStack.addArrangedSubview(badge)
        }

        // Project badge
        if let project = task.project {
            let badge = createBadge(text: project, color: .systemPurple)
            metadataStack.addArrangedSubview(badge)
        }

        // Priority indicator
        if task.priority == .high {
            let indicator = NSImageView(image: NSImage(systemSymbolName: "exclamationmark.circle.fill", accessibilityDescription: nil)!)
            indicator.contentTintColor = .systemRed
            metadataStack.addArrangedSubview(indicator)
        }

        // Flagged indicator
        if task.flagged {
            let indicator = NSImageView(image: NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)!)
            indicator.contentTintColor = .systemYellow
            metadataStack.addArrangedSubview(indicator)
        }

        // Due date
        if let dueDesc = task.dueDescription {
            let badge = createBadge(text: dueDesc, color: task.isOverdue ? .systemRed : .systemGray)
            metadataStack.addArrangedSubview(badge)
        }
    }

    private func createBadge(text: String, color: NSColor) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = color.withAlphaComponent(0.2).cgColor
        container.layer?.cornerRadius = 3

        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 10)
        label.textColor = color
        label.frame = NSRect(x: 4, y: 2, width: 60, height: 14)
        label.sizeToFit()

        container.frame = NSRect(x: 0, y: 0, width: label.frame.width + 8, height: 18)
        container.addSubview(label)

        return container
    }

    private func colorForTask(_ task: Task) -> NSColor {
        if task.status == .completed {
            return .systemGreen.withAlphaComponent(0.15)
        }

        switch task.priority {
        case .high:
            return .systemRed.withAlphaComponent(0.1)
        case .medium:
            return .systemYellow.withAlphaComponent(0.15)
        case .low:
            return .systemBlue.withAlphaComponent(0.1)
        }
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        delegate?.kanbanTaskCard(self, didSelectTask: task)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let taskId = task.id.uuidString.data(using: .utf8) else { return }

        let draggingItem = NSDraggingItem(pasteboardWriter: task.id.uuidString as NSString)
        draggingItem.setDraggingFrame(bounds, contents: snapshot())

        delegate?.kanbanTaskCard(self, didBeginDraggingTask: task)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    private func snapshot() -> NSImage {
        let image = NSImage(size: bounds.size)
        image.lockFocus()
        layer?.render(in: NSGraphicsContext.current!.cgContext)
        image.unlockFocus()
        return image
    }
}

// MARK: - NSDraggingSource

extension KanbanTaskCardView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        delegate?.kanbanTaskCard(self, didEndDraggingTask: task)
    }
}
