import Cocoa

/// Main infinite canvas view with pan/zoom support
///
/// ## What Works Well in AppKit:
/// - Direct control over scroll view and clip view
/// - Precise mouse event handling (mouseDown, mouseDragged, scrollWheel)
/// - Easy to implement custom coordinate transformations
/// - NSView geometry system is straightforward
/// - Can directly manipulate subview positions without complex state management
/// - Excellent performance with many subviews
///
/// ## What's Challenging:
/// - More manual coordinate conversion between spaces
/// - Scroll view setup requires understanding documentView/clipView relationship
/// - Zoom requires manual bounds/frame manipulation
/// - No built-in gesture recognizers (need to handle raw events)
///
/// ## Performance Observations:
/// - Handles 100+ NSView instances smoothly
/// - Pan and zoom are buttery smooth with proper implementation
/// - Layer-backed views provide hardware acceleration
/// - Can optimize further with tiles for thousands of notes
///
/// ## Comparison with SwiftUI:
/// - AppKit: More code, more control, better performance for complex interactions
/// - SwiftUI: Less code, declarative, but harder to optimize for large datasets
/// - AppKit: Better for precise mouse/trackpad handling
/// - SwiftUI: Better for simple, reactive UIs
///
/// ## Recommended Approach for Production:
/// For this freeform canvas use case, **AppKit is recommended** because:
/// 1. Superior control over scroll view and zoom behavior
/// 2. Better performance with many interactive subviews
/// 3. More precise mouse event handling for lasso selection
/// 4. Easier to implement advanced features (snap-to-grid, connection lines)
/// 5. More mature APIs for complex interactions
/// 6. Better debugging tools and documentation
///
/// SwiftUI would be better for:
/// - Simple list-based layouts
/// - Reactive UI updates
/// - iOS/macOS code sharing with simple interactions
///
class CanvasView: NSView {

    // MARK: - Properties

    /// All sticky notes on the canvas
    private(set) var noteViews: [StickyNoteView] = []

    /// Lasso selection overlay
    private let selectionOverlay: LassoSelectionOverlay

    /// Current zoom level (1.0 = 100%)
    var zoomLevel: CGFloat = 1.0 {
        didSet {
            applyZoom()
        }
    }

    /// Minimum zoom level
    let minZoom: CGFloat = 0.25

    /// Maximum zoom level
    let maxZoom: CGFloat = 3.0

    /// Panning state
    private var isPanning = false
    private var panStartLocation: NSPoint?

    /// Lasso selection state
    private var isLassoSelecting = false

    /// Selected notes
    private var selectedNotes: Set<UUID> = []

    /// Delegate for canvas events
    weak var delegate: CanvasViewDelegate?

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        self.selectionOverlay = LassoSelectionOverlay(frame: frameRect)

        super.init(frame: frameRect)

        setupView()
        setupSelectionOverlay()
    }

    required init?(coder: NSCoder) {
        self.selectionOverlay = LassoSelectionOverlay(frame: .zero)

        super.init(coder: coder)

        setupView()
        setupSelectionOverlay()
    }

    // MARK: - Setup

    private func setupView() {
        // Large virtual canvas for infinite scrolling
        frame = NSRect(x: 0, y: 0, width: 5000, height: 5000)

        // Background color
        wantsLayer = true
        layer?.backgroundColor = NSColor(white: 0.95, alpha: 1.0).cgColor

        // Accept mouse events
        // Note: We don't register as first responder by default
    }

    private func setupSelectionOverlay() {
        // Add overlay as top-most subview
        selectionOverlay.autoresizingMask = [.width, .height]
        selectionOverlay.frame = bounds
        addSubview(selectionOverlay)
    }

    // MARK: - Note Management

    /// Add a sticky note to the canvas
    func addNote(_ noteView: StickyNoteView) {
        noteView.delegate = self

        // Insert below the selection overlay
        addSubview(noteView, positioned: .below, relativeTo: selectionOverlay)
        noteViews.append(noteView)

        delegate?.canvasView(self, didAddNote: noteView)
    }

    /// Remove a sticky note from the canvas
    func removeNote(_ noteView: StickyNoteView) {
        noteView.removeFromSuperview()
        noteViews.removeAll { $0.noteId == noteView.noteId }
        selectedNotes.remove(noteView.noteId)

        delegate?.canvasView(self, didRemoveNote: noteView)
    }

    /// Remove all notes
    func removeAllNotes() {
        noteViews.forEach { $0.removeFromSuperview() }
        noteViews.removeAll()
        selectedNotes.removeAll()
    }

    /// Get note view by ID
    func noteView(for id: UUID) -> StickyNoteView? {
        return noteViews.first { $0.noteId == id }
    }

    // MARK: - Selection Management

    /// Select a single note exclusively
    func selectNote(_ noteView: StickyNoteView, exclusive: Bool) {
        if exclusive {
            // Deselect all others
            selectedNotes.forEach { id in
                noteViews.first(where: { $0.noteId == id })?.isSelected = false
            }
            selectedNotes.removeAll()
        }

        selectedNotes.insert(noteView.noteId)
        noteView.isSelected = true

        delegate?.canvasView(self, didChangeSelection: Array(selectedNotes))
    }

    /// Toggle selection of a note
    func toggleNoteSelection(_ noteView: StickyNoteView) {
        if selectedNotes.contains(noteView.noteId) {
            selectedNotes.remove(noteView.noteId)
            noteView.isSelected = false
        } else {
            selectedNotes.insert(noteView.noteId)
            noteView.isSelected = true
        }

        delegate?.canvasView(self, didChangeSelection: Array(selectedNotes))
    }

    /// Deselect all notes
    func deselectAll() {
        selectedNotes.forEach { id in
            noteViews.first(where: { $0.noteId == id })?.isSelected = false
        }
        selectedNotes.removeAll()

        delegate?.canvasView(self, didChangeSelection: [])
    }

    /// Select notes within a rectangle
    func selectNotes(in rect: NSRect) {
        var newSelection: Set<UUID> = []

        for noteView in noteViews {
            // Check if note frame intersects with selection rectangle
            if rect.intersects(noteView.frame) {
                newSelection.insert(noteView.noteId)
                noteView.isSelected = true
            } else if !selectedNotes.contains(noteView.noteId) {
                // Deselect if not previously selected
                noteView.isSelected = false
            }
        }

        selectedNotes = newSelection
        delegate?.canvasView(self, didChangeSelection: Array(selectedNotes))
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let locationInView = convert(event.locationInWindow, from: nil)

        // Check if clicking on empty space (not on a note)
        let hitView = hitTest(locationInView)

        if hitView == self || hitView == selectionOverlay {
            // Clicking on empty space - start lasso or pan
            if event.modifierFlags.contains(.option) {
                // Option+drag for panning
                startPanning(at: event.locationInWindow)
            } else {
                // Regular click starts lasso selection
                startLassoSelection(at: locationInView)

                // Deselect all on empty space click (unless shift is held)
                if !event.modifierFlags.contains(.shift) {
                    deselectAll()
                }
            }
        } else {
            // Clicking on a note - let it handle the event
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        if isPanning {
            continuePanning(to: event.locationInWindow)
        } else if isLassoSelecting {
            let locationInView = convert(event.locationInWindow, from: nil)
            continueLassoSelection(to: locationInView)
        } else {
            super.mouseDragged(with: event)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if isPanning {
            endPanning()
        } else if isLassoSelecting {
            endLassoSelection()
        } else {
            super.mouseUp(with: event)
        }
    }

    // MARK: - Panning

    private func startPanning(at point: NSPoint) {
        isPanning = true
        panStartLocation = point
        NSCursor.closedHand.push()
    }

    private func continuePanning(to point: NSPoint) {
        guard let startPoint = panStartLocation else { return }

        let deltaX = point.x - startPoint.x
        let deltaY = point.y - startPoint.y

        // Pan the canvas by adjusting the visible rect
        if let scrollView = enclosingScrollView {
            var rect = scrollView.documentVisibleRect
            rect.origin.x -= deltaX
            rect.origin.y -= deltaY
            scrollView.documentView?.scroll(rect.origin)
        }

        panStartLocation = point
    }

    private func endPanning() {
        isPanning = false
        panStartLocation = nil
        NSCursor.pop()
    }

    // MARK: - Lasso Selection

    private func startLassoSelection(at point: NSPoint) {
        isLassoSelecting = true
        selectionOverlay.startSelection(at: point)
    }

    private func continueLassoSelection(to point: NSPoint) {
        selectionOverlay.updateSelection(to: point)

        // Update selection in real-time
        if let selectionRect = selectionOverlay.selectionRect {
            selectNotes(in: selectionRect)
        }
    }

    private func endLassoSelection() {
        isLassoSelecting = false

        if let selectionRect = selectionOverlay.endSelection() {
            selectNotes(in: selectionRect)
        } else {
            selectionOverlay.cancelSelection()
        }
    }

    // MARK: - Zoom

    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            // Command+scroll for zoom
            let zoomDelta = event.scrollingDeltaY * 0.01
            let newZoom = (zoomLevel - zoomDelta).clamped(to: minZoom...maxZoom)

            if newZoom != zoomLevel {
                zoomLevel = newZoom
                delegate?.canvasView(self, didChangeZoom: zoomLevel)
            }
        } else {
            // Regular scroll for panning
            super.scrollWheel(with: event)
        }
    }

    private func applyZoom() {
        // Scale the bounds to achieve zoom effect
        let scaledSize = NSSize(
            width: frame.width / zoomLevel,
            height: frame.height / zoomLevel
        )
        setBoundsSize(scaledSize)

        needsDisplay = true
    }

    /// Zoom to fit all notes in view
    func zoomToFit(animated: Bool = true) {
        guard !noteViews.isEmpty else { return }

        // Calculate bounding rect of all notes
        var boundingRect = noteViews[0].frame
        for noteView in noteViews.dropFirst() {
            boundingRect = boundingRect.union(noteView.frame)
        }

        // Add padding
        boundingRect = boundingRect.insetBy(dx: -50, dy: -50)

        // Calculate zoom level to fit
        guard let scrollView = enclosingScrollView else { return }
        let visibleRect = scrollView.documentVisibleRect

        let zoomX = visibleRect.width / boundingRect.width
        let zoomY = visibleRect.height / boundingRect.height
        let targetZoom = min(zoomX, zoomY, maxZoom)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.animator().zoomLevel = targetZoom
            }
        } else {
            zoomLevel = targetZoom
        }

        // Scroll to center the bounding rect
        scrollView.documentView?.scroll(boundingRect.origin)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw grid (optional, for visual reference)
        drawGrid(in: dirtyRect)
    }

    private func drawGrid(in rect: NSRect) {
        let gridColor = NSColor(white: 0.9, alpha: 1.0)
        let gridSpacing: CGFloat = 50

        gridColor.setStroke()

        let path = NSBezierPath()
        path.lineWidth = 0.5

        // Vertical lines
        var x = (rect.minX / gridSpacing).rounded(.down) * gridSpacing
        while x <= rect.maxX {
            path.move(to: NSPoint(x: x, y: rect.minY))
            path.line(to: NSPoint(x: x, y: rect.maxY))
            x += gridSpacing
        }

        // Horizontal lines
        var y = (rect.minY / gridSpacing).rounded(.down) * gridSpacing
        while y <= rect.maxY {
            path.move(to: NSPoint(x: rect.minX, y: y))
            path.line(to: NSPoint(x: rect.maxX, y: y))
            y += gridSpacing
        }

        path.stroke()
    }

    // MARK: - Keyboard Support

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 51: // Delete
            deleteSelectedNotes()
        case 0: // A
            if event.modifierFlags.contains(.command) {
                selectAllNotes()
            }
        default:
            super.keyDown(with: event)
        }
    }

    private func selectAllNotes() {
        selectedNotes = Set(noteViews.map { $0.noteId })
        noteViews.forEach { $0.isSelected = true }
        delegate?.canvasView(self, didChangeSelection: Array(selectedNotes))
    }

    private func deleteSelectedNotes() {
        let notesToDelete = noteViews.filter { selectedNotes.contains($0.noteId) }
        notesToDelete.forEach { removeNote($0) }
    }
}

// MARK: - StickyNoteViewDelegate

extension CanvasView: StickyNoteViewDelegate {
    func stickyNoteViewDidRequestSelection(_ noteView: StickyNoteView, exclusive: Bool) {
        selectNote(noteView, exclusive: exclusive)
    }

    func stickyNoteViewDidToggleSelection(_ noteView: StickyNoteView) {
        toggleNoteSelection(noteView)
    }

    func stickyNoteViewDidMove(_ noteView: StickyNoteView, to position: NSPoint) {
        // Notify delegate if needed
        delegate?.canvasView(self, didMoveNote: noteView, to: position)
    }

    func stickyNoteViewDidEndDrag(_ noteView: StickyNoteView) {
        // Could auto-save positions here
    }

    func stickyNoteViewDidUpdateTitle(_ noteView: StickyNoteView, newTitle: String) {
        delegate?.canvasView(self, didUpdateNote: noteView, newTitle: newTitle)
    }
}

// MARK: - CanvasViewDelegate

protocol CanvasViewDelegate: AnyObject {
    func canvasView(_ canvasView: CanvasView, didAddNote noteView: StickyNoteView)
    func canvasView(_ canvasView: CanvasView, didRemoveNote noteView: StickyNoteView)
    func canvasView(_ canvasView: CanvasView, didMoveNote noteView: StickyNoteView, to position: NSPoint)
    func canvasView(_ canvasView: CanvasView, didUpdateNote noteView: StickyNoteView, newTitle: String)
    func canvasView(_ canvasView: CanvasView, didChangeSelection selectedIds: [UUID])
    func canvasView(_ canvasView: CanvasView, didChangeZoom zoom: CGFloat)
}

// MARK: - Utility Extensions

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
