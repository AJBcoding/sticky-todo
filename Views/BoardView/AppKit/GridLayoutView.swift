//
//  GridLayoutView.swift
//  StickyToDo-AppKit
//
//  Grid layout with section-based organization.
//  Tasks are organized in sections by priority, status, or time.
//

import Cocoa

/// Protocol for communicating grid layout events
protocol GridLayoutDelegate: AnyObject {
    func gridLayout(_ layout: GridLayoutView, didSelectTask task: Task?)
    func gridLayout(_ layout: GridLayoutView, didUpdateTask task: Task)
    func gridLayout(_ layout: GridLayoutView, didMoveTask task: Task, toSection section: String)
    func gridLayout(_ layout: GridLayoutView, didCreateTaskInSection section: String)
}

/// Grid layout view with sections
///
/// Displays tasks organized in named sections (e.g., by priority, status, or time).
/// Tasks are arranged in a grid within each section with automatic positioning.
class GridLayoutView: NSView {

    // MARK: - Properties

    weak var delegate: GridLayoutDelegate?

    /// Current board configuration
    private var board: Board

    /// Tasks to display
    private var tasks: [Task] = []

    /// Grid sections
    private var sections: [LayoutEngine.GridSection] = []

    /// Section views
    private var sectionViews: [GridSectionView] = []

    /// Scroll view containing the sections
    private var scrollView: NSScrollView!

    /// Container for sections
    private var sectionsContainer: NSView!

    /// Currently selected task ID
    private var selectedTaskId: UUID?

    /// Number of columns per row
    private let columnsPerRow = 3

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

        // Determine sections based on board type
        sections = LayoutEngine.sectionsForBoard(board)

        setupScrollView()
        layoutSections()
    }

    private func setupScrollView() {
        scrollView = NSScrollView(frame: bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        sectionsContainer = NSView()
        sectionsContainer.wantsLayer = true

        scrollView.documentView = sectionsContainer
        addSubview(scrollView)
    }

    // MARK: - Public Methods

    /// Updates the tasks displayed in the grid
    func setTasks(_ tasks: [Task]) {
        self.tasks = tasks
        layoutSections()
    }

    /// Updates the board configuration
    func setBoard(_ board: Board) {
        self.board = board
        sections = LayoutEngine.sectionsForBoard(board)
        layoutSections()
    }

    /// Refreshes the layout
    func refresh() {
        layoutSections()
    }

    // MARK: - Layout

    private func layoutSections() {
        // Remove existing sections
        sectionViews.forEach { $0.removeFromSuperview() }
        sectionViews.removeAll()

        var currentY: CGFloat = LayoutEngine.gridSpacing

        for section in sections {
            let sectionTasks = tasks.filter(section.filter)

            // Skip empty sections
            if sectionTasks.isEmpty {
                continue
            }

            let sectionView = GridSectionView(
                section: section,
                tasks: sectionTasks,
                columnsPerRow: columnsPerRow,
                board: board
            )
            sectionView.delegate = self

            // Calculate section height
            let rows = (sectionTasks.count + columnsPerRow - 1) / columnsPerRow
            let sectionHeight = 40 + CGFloat(rows) * (LayoutEngine.gridCellHeight + LayoutEngine.gridSpacing) + LayoutEngine.gridSpacing

            sectionView.frame = NSRect(
                x: LayoutEngine.gridSpacing,
                y: currentY,
                width: scrollView.contentSize.width - LayoutEngine.gridSpacing * 2,
                height: sectionHeight
            )

            sectionsContainer.addSubview(sectionView)
            sectionViews.append(sectionView)

            currentY += sectionHeight + 20 // Section spacing
        }

        // Update container size
        sectionsContainer.frame = NSRect(
            x: 0,
            y: 0,
            width: scrollView.contentSize.width,
            height: currentY + LayoutEngine.gridSpacing
        )
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layoutSections()
    }
}

// MARK: - GridSectionViewDelegate

extension GridLayoutView: GridSectionViewDelegate {
    func gridSection(_ section: GridSectionView, didSelectTask task: Task) {
        selectedTaskId = task.id
        delegate?.gridLayout(self, didSelectTask: task)
    }

    func gridSection(_ section: GridSectionView, didUpdateTask task: Task) {
        delegate?.gridLayout(self, didUpdateTask: task)
    }

    func gridSection(_ section: GridSectionView, didRequestAddTask sectionId: String) {
        delegate?.gridLayout(self, didCreateTaskInSection: sectionId)
    }

    func gridSection(_ section: GridSectionView, didMoveTask task: Task, toSection targetSectionId: String) {
        delegate?.gridLayout(self, didMoveTask: task, toSection: targetSectionId)
    }
}

// MARK: - Grid Section View

protocol GridSectionViewDelegate: AnyObject {
    func gridSection(_ section: GridSectionView, didSelectTask task: Task)
    func gridSection(_ section: GridSectionView, didUpdateTask task: Task)
    func gridSection(_ section: GridSectionView, didRequestAddTask sectionId: String)
    func gridSection(_ section: GridSectionView, didMoveTask task: Task, toSection: String)
}

/// A single section in the grid layout
class GridSectionView: NSView {

    // MARK: - Properties

    weak var delegate: GridSectionViewDelegate?

    private let section: LayoutEngine.GridSection
    private(set) var tasks: [Task]
    private let columnsPerRow: Int
    private let board: Board

    private var headerView: NSView!
    private var titleLabel: NSTextField!
    private var countLabel: NSTextField!
    private var addButton: NSButton!
    private var cardsContainer: NSView!
    private var taskCardViews: [GridTaskCardView] = []

    // MARK: - Initialization

    init(section: LayoutEngine.GridSection, tasks: [Task], columnsPerRow: Int, board: Board) {
        self.section = section
        self.tasks = tasks
        self.columnsPerRow = columnsPerRow
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
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5).cgColor
        layer?.cornerRadius = 8

        setupHeader()
        setupCardsContainer()
        layoutCards()

        // Register for drag and drop
        registerForDraggedTypes([.string])
    }

    private func setupHeader() {
        headerView = NSView(frame: NSRect(x: 0, y: frame.height - 40, width: frame.width, height: 40))
        headerView.autoresizingMask = [.width, .minYMargin]

        // Title label
        titleLabel = NSTextField(labelWithString: section.title)
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.frame = NSRect(x: 12, y: 12, width: frame.width - 100, height: 20)
        titleLabel.autoresizingMask = [.width]
        headerView.addSubview(titleLabel)

        // Count badge
        countLabel = NSTextField(labelWithString: "\(tasks.count)")
        countLabel.font = .systemFont(ofSize: 12, weight: .medium)
        countLabel.textColor = .secondaryLabelColor
        countLabel.alignment = .center
        countLabel.wantsLayer = true
        countLabel.layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.1).cgColor
        countLabel.layer?.cornerRadius = 10
        countLabel.frame = NSRect(x: frame.width - 80, y: 10, width: 40, height: 20)
        countLabel.autoresizingMask = [.minXMargin]
        headerView.addSubview(countLabel)

        // Add button
        addButton = NSButton(frame: NSRect(x: frame.width - 35, y: 10, width: 25, height: 20))
        addButton.title = "+"
        addButton.font = .systemFont(ofSize: 14, weight: .medium)
        addButton.bezelStyle = .inline
        addButton.target = self
        addButton.action = #selector(addTaskClicked)
        addButton.autoresizingMask = [.minXMargin]
        headerView.addSubview(addButton)

        addSubview(headerView)
    }

    private func setupCardsContainer() {
        cardsContainer = NSView(frame: NSRect(x: 0, y: 0, width: frame.width, height: frame.height - 40))
        cardsContainer.autoresizingMask = [.width, .height]
        addSubview(cardsContainer)
    }

    private func layoutCards() {
        // Remove existing cards
        taskCardViews.forEach { $0.removeFromSuperview() }
        taskCardViews.removeAll()

        // Create new cards in grid
        var column = 0
        var currentY: CGFloat = frame.height - 40 - LayoutEngine.gridSpacing

        for (index, task) in tasks.enumerated() {
            if column == 0 {
                currentY -= LayoutEngine.gridCellHeight
            }

            let x = LayoutEngine.gridSpacing + CGFloat(column) * (LayoutEngine.gridCellWidth + LayoutEngine.gridSpacing)

            let cardView = GridTaskCardView(task: task)
            cardView.delegate = self
            cardView.frame = NSRect(
                x: x,
                y: currentY,
                width: LayoutEngine.gridCellWidth,
                height: LayoutEngine.gridCellHeight
            )

            addSubview(cardView)
            taskCardViews.append(cardView)

            column += 1
            if column >= columnsPerRow {
                column = 0
                currentY -= LayoutEngine.gridSpacing
            }
        }

        // Update count label
        countLabel.stringValue = "\(tasks.count)"
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layoutCards()
    }

    // MARK: - Actions

    @objc private func addTaskClicked() {
        delegate?.gridSection(self, didRequestAddTask: section.id)
    }

    // MARK: - Drag and Drop

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // Highlight section on drag enter
        layer?.borderWidth = 2
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        return .move
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        // Remove highlight
        layer?.borderWidth = 0
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // Remove highlight
        layer?.borderWidth = 0

        // Handle task drop
        guard let taskIdString = sender.draggingPasteboard.string(forType: .string),
              let taskId = UUID(uuidString: taskIdString) else {
            return false
        }

        // Find the task (might be from another section)
        if let task = tasks.first(where: { $0.id == taskId }) {
            delegate?.gridSection(self, didMoveTask: task, toSection: section.id)
            return true
        }

        return false
    }
}

// MARK: - GridTaskCardViewDelegate

extension GridSectionView: GridTaskCardViewDelegate {
    func gridTaskCard(_ card: GridTaskCardView, didSelectTask task: Task) {
        delegate?.gridSection(self, didSelectTask: task)
    }

    func gridTaskCard(_ card: GridTaskCardView, didUpdateTask task: Task) {
        delegate?.gridSection(self, didUpdateTask: task)
    }

    func gridTaskCard(_ card: GridTaskCardView, didBeginDraggingTask task: Task) {
        card.alphaValue = 0.5
    }

    func gridTaskCard(_ card: GridTaskCardView, didEndDraggingTask task: Task) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            card.animator().alphaValue = 1.0
        }
    }
}

// MARK: - Grid Task Card View

protocol GridTaskCardViewDelegate: AnyObject {
    func gridTaskCard(_ card: GridTaskCardView, didSelectTask task: Task)
    func gridTaskCard(_ card: GridTaskCardView, didUpdateTask task: Task)
    func gridTaskCard(_ card: GridTaskCardView, didBeginDraggingTask task: Task)
    func gridTaskCard(_ card: GridTaskCardView, didEndDraggingTask task: Task)
}

/// Individual task card in the grid layout
class GridTaskCardView: NSView {

    // MARK: - Properties

    weak var delegate: GridTaskCardViewDelegate?

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
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.maximumNumberOfLines = 4
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.frame = NSRect(x: 10, y: frame.height - 70, width: frame.width - 20, height: 60)
        titleLabel.autoresizingMask = [.width, .minYMargin]
        addSubview(titleLabel)

        // Metadata badges
        metadataStack = NSStackView()
        metadataStack.orientation = .horizontal
        metadataStack.spacing = 4
        metadataStack.alignment = .centerY
        metadataStack.frame = NSRect(x: 10, y: 8, width: frame.width - 20, height: 20)
        metadataStack.autoresizingMask = [.width, .maxYMargin]
        addSubview(metadataStack)

        addMetadataBadges()
    }

    private func addMetadataBadges() {
        // Priority indicator
        if task.priority == .high {
            let indicator = NSImageView(image: NSImage(systemSymbolName: "exclamationmark.circle.fill", accessibilityDescription: nil)!)
            indicator.contentTintColor = .systemRed
            indicator.frame = NSRect(x: 0, y: 0, width: 16, height: 16)
            metadataStack.addArrangedSubview(indicator)
        }

        // Flagged indicator
        if task.flagged {
            let indicator = NSImageView(image: NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)!)
            indicator.contentTintColor = .systemYellow
            indicator.frame = NSRect(x: 0, y: 0, width: 16, height: 16)
            metadataStack.addArrangedSubview(indicator)
        }

        // Context badge
        if let context = task.context {
            let badge = createBadge(text: context, color: .systemBlue)
            metadataStack.addArrangedSubview(badge)
        }

        // Due date indicator
        if task.isOverdue {
            let badge = createBadge(text: "Overdue", color: .systemRed)
            metadataStack.addArrangedSubview(badge)
        } else if task.isDueToday {
            let badge = createBadge(text: "Today", color: .systemOrange)
            metadataStack.addArrangedSubview(badge)
        }
    }

    private func createBadge(text: String, color: NSColor) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = color.withAlphaComponent(0.2).cgColor
        container.layer?.cornerRadius = 3

        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 9)
        label.textColor = color
        label.frame = NSRect(x: 3, y: 1, width: 40, height: 12)
        label.sizeToFit()

        container.frame = NSRect(x: 0, y: 0, width: label.frame.width + 6, height: 16)
        container.addSubview(label)

        return container
    }

    private func colorForTask(_ task: Task) -> NSColor {
        if task.status == .completed {
            return .systemGreen.withAlphaComponent(0.15)
        }

        if task.isOverdue {
            return .systemRed.withAlphaComponent(0.1)
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
        delegate?.gridTaskCard(self, didSelectTask: task)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let taskId = task.id.uuidString.data(using: .utf8) else { return }

        let draggingItem = NSDraggingItem(pasteboardWriter: task.id.uuidString as NSString)
        draggingItem.setDraggingFrame(bounds, contents: snapshot())

        delegate?.gridTaskCard(self, didBeginDraggingTask: task)

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

extension GridTaskCardView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        delegate?.gridTaskCard(self, didEndDraggingTask: task)
    }
}
