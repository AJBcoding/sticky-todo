import Cocoa

/// NSViewController for managing the canvas view and its interactions
///
/// ## What Works Well in AppKit:
/// - NSViewController pattern is mature and well-understood
/// - Easy integration with NSScrollView
/// - Straightforward toolbar and menu management
/// - Simple state management without complex publishers
/// - Direct access to window and view hierarchy
///
/// ## What's Challenging:
/// - More boilerplate for UI setup compared to SwiftUI
/// - Need to manually wire up actions and targets
/// - Toolbar creation is verbose
///
/// ## Performance Notes:
/// - Controller overhead is minimal
/// - State updates are synchronous and predictable
/// - Easy to profile and optimize
///
class CanvasController: NSViewController {

    // MARK: - Properties

    /// Main canvas view
    internal var canvasView: CanvasView!

    /// Scroll view wrapping the canvas
    private var scrollView: NSScrollView!

    /// Toolbar items
    private var zoomLabel: NSTextField!

    /// Status bar showing selection count
    private var statusLabel: NSTextField!

    /// Current zoom percentage for display
    private var zoomPercentage: Int {
        return Int(canvasView.zoomLevel * 100)
    }

    /// Model data (in real app, this would come from data layer)
    struct NoteData {
        let id: UUID
        let title: String
        let color: NSColor
        let position: NSPoint
    }

    // MARK: - Lifecycle

    override func loadView() {
        // Create main container view
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view = containerView

        setupScrollView()
        setupCanvas()
        setupStatusBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup toolbar
        setupToolbar()

        // Load test data
        loadTestData()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        // Make canvas first responder for keyboard events
        view.window?.makeFirstResponder(canvasView)
    }

    // MARK: - Setup

    private func setupScrollView() {
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.backgroundColor = .white
        scrollView.drawsBackground = true

        // Enable smooth scrolling
        scrollView.usesPredominantAxisScrolling = false
        scrollView.horizontalScrollElasticity = .none
        scrollView.verticalScrollElasticity = .none

        view.addSubview(scrollView)
    }

    private func setupCanvas() {
        // Create large canvas (5000x5000 virtual space)
        canvasView = CanvasView(frame: NSRect(x: 0, y: 0, width: 5000, height: 5000))
        canvasView.delegate = self

        scrollView.documentView = canvasView

        // Scroll to show the notes area (notes start around 200,200)
        // This will be called after the view is laid out
        DispatchQueue.main.async {
            self.scrollToNotesArea()
        }
    }

    private func scrollToNotesArea() {
        // Center view on the notes area (approximately 200-2500 x, 200-2000 y)
        let notesCenter = NSPoint(x: 1350, y: 1100)

        // Calculate visible rect center
        let visibleRect = scrollView.contentView.bounds
        let scrollPoint = NSPoint(
            x: notesCenter.x - visibleRect.width / 2,
            y: notesCenter.y - visibleRect.height / 2
        )

        canvasView.scroll(scrollPoint)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func setupStatusBar() {
        // Status bar at bottom
        let statusBar = NSView(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: 24))
        statusBar.autoresizingMask = [.width]
        statusBar.wantsLayer = true
        statusBar.layer?.backgroundColor = NSColor(white: 0.95, alpha: 1.0).cgColor

        statusLabel = NSTextField(labelWithString: "0 notes")
        statusLabel.frame = NSRect(x: 10, y: 4, width: 200, height: 16)
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor

        statusBar.addSubview(statusLabel)
        view.addSubview(statusBar)

        // Adjust scroll view to make room for status bar
        var scrollFrame = scrollView.frame
        scrollFrame.size.height -= 24
        scrollFrame.origin.y = 24
        scrollView.frame = scrollFrame
    }

    private func setupToolbar() {
        guard let window = view.window else { return }

        let toolbar = NSToolbar(identifier: "CanvasToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel

        window.toolbar = toolbar
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
    }

    // MARK: - Test Data

    /// Load test data to demonstrate performance with 50-100 notes
    private func loadTestData() {
        let noteCount = 75
        let gridColumns = 10
        let noteSpacing: CGFloat = 250

        for i in 0..<noteCount {
            let row = i / gridColumns
            let col = i % gridColumns

            // Calculate position with some randomness
            let baseX = CGFloat(col) * noteSpacing + 200
            let baseY = CGFloat(row) * noteSpacing + 200
            let randomOffsetX = CGFloat.random(in: -50...50)
            let randomOffsetY = CGFloat.random(in: -50...50)

            let position = NSPoint(
                x: baseX + randomOffsetX,
                y: baseY + randomOffsetY
            )

            let note = StickyNoteView(
                id: UUID(),
                title: generateTestTitle(index: i),
                color: .randomStickyColor,
                position: position
            )

            canvasView.addNote(note)
        }

        updateStatusBar()
    }

    private func generateTestTitle(index: Int) -> String {
        let titles = [
            "Design mockups",
            "Call client",
            "Review PR #123",
            "Update documentation",
            "Fix login bug",
            "Implement feature X",
            "Write tests",
            "Deploy to staging",
            "Team meeting",
            "Code review",
            "Research options",
            "Plan sprint",
            "Refactor module",
            "Update dependencies",
            "Security audit",
        ]

        return "\(titles[index % titles.count]) (\(index + 1))"
    }

    // MARK: - Actions

    @objc private func addNote(_ sender: Any?) {
        // Add new note at center of visible area
        let visibleRect = scrollView.documentVisibleRect
        let centerPoint = NSPoint(
            x: visibleRect.midX,
            y: visibleRect.midY
        )

        let note = StickyNoteView(
            id: UUID(),
            title: "New Note",
            color: .randomStickyColor,
            position: centerPoint
        )

        canvasView.addNote(note)
        updateStatusBar()
    }

    @objc private func zoomIn(_ sender: Any?) {
        let newZoom = min(canvasView.zoomLevel * 1.2, canvasView.maxZoom)
        canvasView.zoomLevel = newZoom
        updateZoomLabel()
    }

    @objc private func zoomOut(_ sender: Any?) {
        let newZoom = max(canvasView.zoomLevel / 1.2, canvasView.minZoom)
        canvasView.zoomLevel = newZoom
        updateZoomLabel()
    }

    @objc private func zoomActual(_ sender: Any?) {
        canvasView.zoomLevel = 1.0
        updateZoomLabel()
    }

    @objc private func zoomToFit(_ sender: Any?) {
        canvasView.zoomToFit(animated: true)
        updateZoomLabel()
    }

    @objc private func clearAll(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "Clear All Notes?"
        alert.informativeText = "This will remove all notes from the canvas. This action cannot be undone."
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            canvasView.removeAllNotes()
            updateStatusBar()
        }
    }

    @objc private func performanceTest(_ sender: Any?) {
        // Show performance test dialog
        let alert = NSAlert()
        alert.messageText = "Performance Test"
        alert.informativeText = """
        Current note count: \(canvasView.noteViews.count)
        Zoom level: \(zoomPercentage)%

        Try these interactions:
        • Drag individual notes
        • Pan with Option+drag
        • Zoom with Command+scroll
        • Lasso select with click+drag
        • Multi-select with Command+click

        Performance should remain smooth with 100+ notes.
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - UI Updates

    private func updateZoomLabel() {
        zoomLabel?.stringValue = "\(zoomPercentage)%"
    }

    private func updateStatusBar() {
        let noteCount = canvasView.noteViews.count
        let selectedCount = canvasView.noteViews.filter { $0.isSelected }.count

        if selectedCount > 0 {
            statusLabel.stringValue = "\(noteCount) notes, \(selectedCount) selected"
        } else {
            statusLabel.stringValue = "\(noteCount) notes"
        }
    }
}

// MARK: - CanvasViewDelegate

extension CanvasController: CanvasViewDelegate {
    func canvasView(_ canvasView: CanvasView, didAddNote noteView: StickyNoteView) {
        updateStatusBar()
    }

    func canvasView(_ canvasView: CanvasView, didRemoveNote noteView: StickyNoteView) {
        updateStatusBar()
    }

    func canvasView(_ canvasView: CanvasView, didMoveNote noteView: StickyNoteView, to position: NSPoint) {
        // Could save position to model here
    }

    func canvasView(_ canvasView: CanvasView, didUpdateNote noteView: StickyNoteView, newTitle: String) {
        // Could save title to model here
    }

    func canvasView(_ canvasView: CanvasView, didChangeSelection selectedIds: [UUID]) {
        updateStatusBar()
    }

    func canvasView(_ canvasView: CanvasView, didChangeZoom zoom: CGFloat) {
        updateZoomLabel()
    }
}

// MARK: - NSToolbarDelegate

extension CanvasController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        switch itemIdentifier.rawValue {
        case "addNote":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Add Note"
            item.paletteLabel = "Add Note"
            item.toolTip = "Add a new sticky note"
            item.image = NSImage(systemSymbolName: "plus.square", accessibilityDescription: "Add")
            item.target = self
            item.action = #selector(addNote(_:))
            return item

        case "zoomIn":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Zoom In"
            item.paletteLabel = "Zoom In"
            item.toolTip = "Zoom in (⌘+)"
            item.image = NSImage(systemSymbolName: "plus.magnifyingglass", accessibilityDescription: "Zoom In")
            item.target = self
            item.action = #selector(zoomIn(_:))
            return item

        case "zoomOut":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Zoom Out"
            item.paletteLabel = "Zoom Out"
            item.toolTip = "Zoom out (⌘-)"
            item.image = NSImage(systemSymbolName: "minus.magnifyingglass", accessibilityDescription: "Zoom Out")
            item.target = self
            item.action = #selector(zoomOut(_:))
            return item

        case "zoomActual":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "100%"
            item.paletteLabel = "Actual Size"
            item.toolTip = "Zoom to 100% (⌘0)"
            item.image = NSImage(systemSymbolName: "1.magnifyingglass", accessibilityDescription: "100%")
            item.target = self
            item.action = #selector(zoomActual(_:))
            return item

        case "zoomToFit":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Fit"
            item.paletteLabel = "Zoom to Fit"
            item.toolTip = "Zoom to fit all notes"
            item.image = NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: "Fit")
            item.target = self
            item.action = #selector(zoomToFit(_:))
            return item

        case "zoomLabel":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = ""
            item.paletteLabel = "Zoom Level"

            zoomLabel = NSTextField(labelWithString: "100%")
            zoomLabel.font = .systemFont(ofSize: 13)
            zoomLabel.alignment = .center
            zoomLabel.frame = NSRect(x: 0, y: 0, width: 60, height: 24)

            item.view = zoomLabel
            return item

        case "clearAll":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Clear All"
            item.paletteLabel = "Clear All"
            item.toolTip = "Remove all notes"
            item.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Clear")
            item.target = self
            item.action = #selector(clearAll(_:))
            return item

        case "performanceTest":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Performance"
            item.paletteLabel = "Performance Test"
            item.toolTip = "Show performance test info"
            item.image = NSImage(systemSymbolName: "speedometer", accessibilityDescription: "Performance")
            item.target = self
            item.action = #selector(performanceTest(_:))
            return item

        default:
            return nil
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            NSToolbarItem.Identifier("addNote"),
            .space,
            NSToolbarItem.Identifier("zoomOut"),
            NSToolbarItem.Identifier("zoomLabel"),
            NSToolbarItem.Identifier("zoomIn"),
            NSToolbarItem.Identifier("zoomActual"),
            NSToolbarItem.Identifier("zoomToFit"),
            .flexibleSpace,
            NSToolbarItem.Identifier("performanceTest"),
            NSToolbarItem.Identifier("clearAll"),
        ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }
}
