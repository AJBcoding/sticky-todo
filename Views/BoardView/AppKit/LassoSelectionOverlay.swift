import Cocoa

/// Overlay view for drawing lasso selection rectangle
///
/// ## What Works Well in AppKit:
/// - Direct drawing with NSBezierPath in drawRect
/// - Simple overlay pattern with transparent background
/// - Easy coordinate system manipulation
/// - Efficient redrawing with setNeedsDisplay
/// - Built-in support for dashed lines and stroke patterns
///
/// ## What's Challenging:
/// - Manual coordinate conversion from window to view space
/// - Need to handle view flipping for coordinate system
/// - More verbose than SwiftUI's Shape protocol
///
/// ## Performance Notes:
/// - Drawing is very efficient for simple shapes
/// - No performance issues with frequent redraws
/// - Can optimize with dirty rect if needed for complex scenes
///
class LassoSelectionOverlay: NSView {

    // MARK: - Properties

    /// Start point of selection rectangle (in view coordinates)
    var selectionStart: NSPoint? {
        didSet {
            needsDisplay = true
        }
    }

    /// Current point of selection rectangle (in view coordinates)
    var selectionCurrent: NSPoint? {
        didSet {
            needsDisplay = true
        }
    }

    /// Computed selection rectangle
    var selectionRect: NSRect? {
        guard let start = selectionStart, let current = selectionCurrent else {
            return nil
        }

        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let maxX = max(start.x, current.x)
        let maxY = max(start.y, current.y)

        return NSRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }

    /// Selection rectangle color
    var selectionColor: NSColor = .selectedControlColor

    /// Whether selection is currently active
    var isSelecting: Bool {
        return selectionStart != nil && selectionCurrent != nil
    }

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // Overlay should be transparent and not block mouse events to underlying views
        // We'll handle this by making sure the overlay is only active during selection
        wantsLayer = false  // We don't need layer backing for this simple overlay
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let rect = selectionRect else {
            return
        }

        // Fill with semi-transparent color
        selectionColor.withAlphaComponent(0.15).setFill()
        NSBezierPath(rect: rect).fill()

        // Stroke with dashed border
        selectionColor.withAlphaComponent(0.6).setStroke()

        let path = NSBezierPath(rect: rect)
        path.lineWidth = 2.0

        // Create dashed line pattern
        let dashPattern: [CGFloat] = [6.0, 3.0]
        path.setLineDash(dashPattern, count: dashPattern.count, phase: 0)

        path.stroke()
    }

    // MARK: - Selection Management

    /// Start a new selection at the given point
    func startSelection(at point: NSPoint) {
        selectionStart = point
        selectionCurrent = point
        needsDisplay = true
    }

    /// Update the current selection point
    func updateSelection(to point: NSPoint) {
        selectionCurrent = point
        needsDisplay = true
    }

    /// End the selection and return the final rectangle
    @discardableResult
    func endSelection() -> NSRect? {
        let rect = selectionRect
        selectionStart = nil
        selectionCurrent = nil
        needsDisplay = true
        return rect
    }

    /// Cancel the selection without returning a rectangle
    func cancelSelection() {
        selectionStart = nil
        selectionCurrent = nil
        needsDisplay = true
    }

    // MARK: - Hit Testing

    /// Overlay should not intercept mouse events
    /// Return nil to pass through to views below
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Only intercept during active selection
        if isSelecting {
            return self
        }
        return nil
    }

    // MARK: - Animation Support

    /// Animate selection rectangle appearance (for snap-to-grid or other effects)
    func animateSelection(from startRect: NSRect, to endRect: NSRect, duration: TimeInterval = 0.2) {
        // This could be used for smooth selection snapping in future
        // For now, we use instant updates
    }
}

// MARK: - Geometry Helpers

extension NSRect {
    /// Check if this rectangle intersects with another rectangle
    func intersects(_ other: NSRect) -> Bool {
        return NSIntersectsRect(self, other)
    }

    /// Check if this rectangle fully contains another rectangle
    func fullyContains(_ other: NSRect) -> Bool {
        return NSContainsRect(self, other)
    }

    /// Check if this rectangle contains a point
    func contains(_ point: NSPoint) -> Bool {
        return NSPointInRect(point, self)
    }
}
