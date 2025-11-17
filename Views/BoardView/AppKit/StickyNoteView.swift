import Cocoa

/// NSView-based sticky note representation for AppKit canvas
///
/// ## What Works Well in AppKit:
/// - Native drag and drop with NSView drag APIs
/// - Direct manipulation of view hierarchy (addSubview, removeFromSuperview)
/// - Precise control over event handling and hit testing
/// - Easy to implement custom drawing with drawRect
/// - CALayer backing for smooth animations
/// - View hierarchy naturally handles z-ordering for selection
///
/// ## What's Challenging:
/// - More boilerplate than SwiftUI (manual layout, event handling)
/// - Need to manually manage view state and visual updates
/// - Shadow and border effects require CALayer configuration
/// - Requires more code for animations compared to SwiftUI
///
/// ## Performance Notes:
/// - NSView instances are lightweight and efficient
/// - Layer-backed views provide hardware acceleration
/// - Can easily handle 100+ instances with smooth rendering
/// - Direct memory control allows fine-tuning for thousands of notes
///
class StickyNoteView: NSView {

    // MARK: - Properties

    /// Unique identifier for this note
    let noteId: UUID

    /// Note title/content
    var title: String {
        didSet {
            textField.stringValue = title
        }
    }

    /// Note color
    var color: NSColor {
        didSet {
            needsDisplay = true
        }
    }

    /// Selection state
    var isSelected: Bool = false {
        didSet {
            needsDisplay = true
            updateShadow()
        }
    }

    /// Text field for displaying title
    private let textField: NSTextField

    /// Delegate for handling interactions
    weak var delegate: StickyNoteViewDelegate?

    /// Standard note size (can be customized per note in future)
    static let standardSize = NSSize(width: 200, height: 150)

    // MARK: - Initialization

    init(id: UUID, title: String, color: NSColor, position: NSPoint) {
        self.noteId = id
        self.title = title
        self.color = color

        // Create text field
        self.textField = NSTextField(frame: .zero)

        super.init(frame: NSRect(origin: position, size: Self.standardSize))

        setupView()
        setupTextField()
        setupLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Setup

    private func setupView() {
        // Enable layer backing for better performance and shadow support
        wantsLayer = true

        // Register for drag operations
        registerForDraggedTypes([.string])
    }

    private func setupTextField() {
        textField.stringValue = title
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.isEditable = false
        textField.isSelectable = false
        textField.font = .systemFont(ofSize: 14, weight: .medium)
        textField.textColor = .black
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 0
        textField.alignment = .left

        // Position with padding
        let padding: CGFloat = 12
        textField.frame = NSRect(
            x: padding,
            y: bounds.height - 30,
            width: bounds.width - (padding * 2),
            height: bounds.height - (padding * 2)
        )
        textField.autoresizingMask = [.width, .height]

        addSubview(textField)
    }

    private func setupLayer() {
        guard let layer = layer else { return }

        // Rounded corners
        layer.cornerRadius = 8

        // Shadow for depth
        updateShadow()
    }

    private func updateShadow() {
        guard let layer = layer else { return }

        if isSelected {
            // Stronger shadow and border when selected
            layer.shadowColor = NSColor.selectedControlColor.cgColor
            layer.shadowOpacity = 0.5
            layer.shadowOffset = CGSize(width: 0, height: -2)
            layer.shadowRadius = 8
            layer.borderWidth = 3
            layer.borderColor = NSColor.selectedControlColor.cgColor
        } else {
            // Subtle shadow when not selected
            layer.shadowColor = NSColor.black.cgColor
            layer.shadowOpacity = 0.2
            layer.shadowOffset = CGSize(width: 0, height: -1)
            layer.shadowRadius = 4
            layer.borderWidth = 1
            layer.borderColor = NSColor.black.withAlphaComponent(0.1).cgColor
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Fill background with note color
        color.setFill()
        let path = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)
        path.fill()

        // Add subtle texture overlay for sticky note effect
        NSColor.white.withAlphaComponent(0.1).setFill()
        let texturePath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 7, yRadius: 7)
        texturePath.fill()
    }

    // MARK: - Mouse Events

    /// Track drag start position
    private var dragStartLocation: NSPoint?

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        // Store drag start location in window coordinates
        dragStartLocation = event.locationInWindow

        // Notify delegate about selection
        let modifierFlags = event.modifierFlags
        if modifierFlags.contains(.command) {
            // Command+click toggles selection
            delegate?.stickyNoteViewDidToggleSelection(self)
        } else if !isSelected {
            // Regular click selects this note exclusively
            delegate?.stickyNoteViewDidRequestSelection(self, exclusive: true)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        guard let startLocation = dragStartLocation else { return }

        let currentLocation = event.locationInWindow
        let deltaX = currentLocation.x - startLocation.x
        let deltaY = currentLocation.y - startLocation.y

        // Move the view
        var newOrigin = frame.origin
        newOrigin.x += deltaX
        newOrigin.y += deltaY

        // Update frame (parent view will handle bounds checking if needed)
        frame.origin = newOrigin

        // Update drag start for next event
        dragStartLocation = currentLocation

        // Notify delegate about drag
        delegate?.stickyNoteViewDidMove(self, to: newOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        dragStartLocation = nil

        // Notify delegate that drag ended
        delegate?.stickyNoteViewDidEndDrag(self)
    }

    // MARK: - Double-click to edit

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            // Double-click to edit
            enableEditing()
        } else {
            super.mouseDown(with: event)
        }
    }

    private func enableEditing() {
        textField.isEditable = true
        textField.isSelectable = true
        window?.makeFirstResponder(textField)
        textField.selectText(nil)
    }

    func disableEditing() {
        textField.isEditable = false
        textField.isSelectable = false
        title = textField.stringValue
        delegate?.stickyNoteViewDidUpdateTitle(self, newTitle: title)
    }

    // MARK: - Hit Testing

    /// Ensure we respond to mouse events within our bounds
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Return self if point is within bounds, enabling mouse events
        if bounds.contains(point) {
            return self
        }
        return nil
    }

    // MARK: - Animation Support

    /// Animate to new position
    func animateToPosition(_ position: NSPoint, duration: TimeInterval = 0.3) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animator().frame.origin = position
        }
    }

    /// Pulse animation for feedback
    func pulse() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            animator().alphaValue = 0.7
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                self.animator().alphaValue = 1.0
            }
        }
    }
}

// MARK: - Delegate Protocol

protocol StickyNoteViewDelegate: AnyObject {
    /// Called when user requests to select this note exclusively or toggle selection
    func stickyNoteViewDidRequestSelection(_ noteView: StickyNoteView, exclusive: Bool)

    /// Called when user toggles selection with modifier key
    func stickyNoteViewDidToggleSelection(_ noteView: StickyNoteView)

    /// Called when note is moved
    func stickyNoteViewDidMove(_ noteView: StickyNoteView, to position: NSPoint)

    /// Called when drag ends
    func stickyNoteViewDidEndDrag(_ noteView: StickyNoteView)

    /// Called when title is updated
    func stickyNoteViewDidUpdateTitle(_ noteView: StickyNoteView, newTitle: String)
}

// MARK: - Convenience Extensions

extension NSColor {
    /// Sticky note color palette
    static let stickyYellow = NSColor(red: 1.0, green: 0.98, blue: 0.70, alpha: 1.0)
    static let stickyPink = NSColor(red: 1.0, green: 0.85, blue: 0.90, alpha: 1.0)
    static let stickyBlue = NSColor(red: 0.70, green: 0.90, blue: 1.0, alpha: 1.0)
    static let stickyGreen = NSColor(red: 0.85, green: 1.0, blue: 0.85, alpha: 1.0)
    static let stickyOrange = NSColor(red: 1.0, green: 0.90, blue: 0.70, alpha: 1.0)
    static let stickyPurple = NSColor(red: 0.92, green: 0.85, blue: 1.0, alpha: 1.0)

    static var randomStickyColor: NSColor {
        let colors: [NSColor] = [.stickyYellow, .stickyPink, .stickyBlue, .stickyGreen, .stickyOrange, .stickyPurple]
        return colors.randomElement() ?? .stickyYellow
    }
}
