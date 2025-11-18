//
//  ColorPickerView.swift
//  StickyToDo-AppKit
//
//  AppKit color picker component using predefined color palette.
//

import Cocoa

/// AppKit color picker view displaying predefined color palette
///
/// Features:
/// - Grid layout of color swatches
/// - Supports optional "no color" selection
/// - Visual indication of selected color
/// - Mouse tracking for hover effects
class ColorPickerView: NSView {

    // MARK: - Properties

    /// Currently selected color hex string (nil = no color)
    var selectedColor: String? {
        didSet {
            needsDisplay = true
            onColorSelected?(selectedColor)
        }
    }

    /// Whether to show a "no color" option
    var allowNoColor: Bool = true {
        didSet {
            needsLayout = true
        }
    }

    /// Callback when color is selected
    var onColorSelected: ((String?) -> Void)?

    /// Color swatches
    private var colorButtons: [ColorButton] = []

    /// No color button
    private var noColorButton: NoColorButton?

    /// Grid layout parameters
    private let swatchSize: CGFloat = 28
    private let spacing: CGFloat = 8
    private let columnsPerRow: Int = 7

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 8

        // Create no color button if needed
        if allowNoColor {
            let button = NoColorButton()
            button.target = self
            button.action = #selector(noColorButtonClicked)
            addSubview(button)
            noColorButton = button
        }

        // Create color buttons
        for paletteColor in ColorPalette.allColors {
            let button = ColorButton(paletteColor: paletteColor)
            button.target = self
            button.action = #selector(colorButtonClicked(_:))
            addSubview(button)
            colorButtons.append(button)
        }

        updateSelection()
    }

    // MARK: - Layout

    override func layout() {
        super.layout()

        let bounds = self.bounds
        let padding: CGFloat = 12
        var xOffset = padding
        var yOffset = padding
        var column = 0

        // Layout no color button
        if let noColorButton = noColorButton {
            noColorButton.frame = NSRect(
                x: xOffset,
                y: yOffset,
                width: swatchSize,
                height: swatchSize
            )
            xOffset += swatchSize + spacing
            column += 1
        }

        // Layout color buttons
        for button in colorButtons {
            // Move to next row if needed
            if column >= columnsPerRow {
                xOffset = padding
                yOffset += swatchSize + spacing
                column = 0
            }

            button.frame = NSRect(
                x: xOffset,
                y: yOffset,
                width: swatchSize,
                height: swatchSize
            )

            xOffset += swatchSize + spacing
            column += 1
        }
    }

    override var intrinsicContentSize: NSSize {
        let padding: CGFloat = 12
        let rowCount = CGFloat((colorButtons.count + (allowNoColor ? 1 : 0) + columnsPerRow - 1) / columnsPerRow)
        let width = CGFloat(columnsPerRow) * (swatchSize + spacing) - spacing + padding * 2
        let height = rowCount * (swatchSize + spacing) - spacing + padding * 2
        return NSSize(width: width, height: height)
    }

    // MARK: - Actions

    @objc private func colorButtonClicked(_ sender: ColorButton) {
        selectedColor = sender.paletteColor.hex
        updateSelection()
    }

    @objc private func noColorButtonClicked() {
        selectedColor = nil
        updateSelection()
    }

    // MARK: - Selection

    private func updateSelection() {
        // Update no color button
        noColorButton?.isSelected = selectedColor == nil

        // Update color buttons
        for button in colorButtons {
            button.isSelected = selectedColor == button.paletteColor.hex
        }
    }
}

// MARK: - Color Button

/// Custom button for displaying a color swatch
private class ColorButton: NSButton {

    // MARK: - Properties

    let paletteColor: ColorPalette.PaletteColor

    var isSelected: Bool = false {
        didSet {
            needsDisplay = true
        }
    }

    private var isHovered: Bool = false {
        didSet {
            needsDisplay = true
        }
    }

    private var trackingArea: NSTrackingArea?

    // MARK: - Initialization

    init(paletteColor: ColorPalette.PaletteColor) {
        self.paletteColor = paletteColor
        super.init(frame: .zero)
        setupButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupButton() {
        isBordered = false
        title = ""
        wantsLayer = true
        toolTip = paletteColor.name
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )

        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bounds = self.bounds
        let inset: CGFloat = 2

        // Draw color circle
        let colorPath = NSBezierPath(
            ovalIn: bounds.insetBy(dx: inset, dy: inset)
        )
        paletteColor.nsColor.setFill()
        colorPath.fill()

        // Draw shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.1)
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 2
        shadow.set()

        // Draw selection ring
        if isSelected {
            let selectionPath = NSBezierPath(
                ovalIn: bounds.insetBy(dx: -1, dy: -1)
            )
            selectionPath.lineWidth = 2
            NSColor.controlAccentColor.setStroke()
            selectionPath.stroke()
        }

        // Draw hover effect
        if isHovered && !isSelected {
            let hoverPath = NSBezierPath(
                ovalIn: bounds.insetBy(dx: inset, dy: inset)
            )
            hoverPath.lineWidth = 1.5
            NSColor.white.withAlphaComponent(0.5).setStroke()
            hoverPath.stroke()
        }
    }
}

// MARK: - No Color Button

/// Custom button for "no color" option
private class NoColorButton: NSButton {

    // MARK: - Properties

    var isSelected: Bool = false {
        didSet {
            needsDisplay = true
        }
    }

    private var isHovered: Bool = false {
        didSet {
            needsDisplay = true
        }
    }

    private var trackingArea: NSTrackingArea?

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    // MARK: - Setup

    private func setupButton() {
        isBordered = false
        title = ""
        wantsLayer = true
        toolTip = "No Color"
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )

        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bounds = self.bounds
        let inset: CGFloat = 2

        // Draw circle outline
        let circlePath = NSBezierPath(
            ovalIn: bounds.insetBy(dx: inset, dy: inset)
        )
        circlePath.lineWidth = 1.5
        NSColor.secondaryLabelColor.withAlphaComponent(0.3).setStroke()
        circlePath.stroke()

        // Draw diagonal line (no color indicator)
        let linePath = NSBezierPath()
        linePath.move(to: NSPoint(x: bounds.minX + 4, y: bounds.maxY - 4))
        linePath.line(to: NSPoint(x: bounds.maxX - 4, y: bounds.minY + 4))
        linePath.lineWidth = 2
        NSColor.systemRed.setStroke()
        linePath.stroke()

        // Draw selection ring
        if isSelected {
            let selectionPath = NSBezierPath(
                ovalIn: bounds.insetBy(dx: -1, dy: -1)
            )
            selectionPath.lineWidth = 2
            NSColor.controlAccentColor.setStroke()
            selectionPath.stroke()
        }

        // Draw hover effect
        if isHovered && !isSelected {
            let hoverPath = NSBezierPath(
                ovalIn: bounds.insetBy(dx: inset, dy: inset)
            )
            hoverPath.lineWidth = 1.5
            NSColor.white.withAlphaComponent(0.5).setStroke()
            hoverPath.stroke()
        }
    }
}

// MARK: - Compact Color Picker

/// Compact color picker for use in popovers or compact spaces
class CompactColorPickerView: NSView {

    // MARK: - Properties

    /// Currently selected color hex string (nil = no color)
    var selectedColor: String? {
        didSet {
            updateSelection()
        }
    }

    /// Callback when color is selected
    var onColorSelected: ((String?) -> Void)?

    /// Color buttons
    private var colorButtons: [ColorButton] = []

    /// No color button
    private var noColorButton: NoColorButton?

    /// Compact swatch size
    private let swatchSize: CGFloat = 20
    private let spacing: CGFloat = 6

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        // Create compact color buttons for most common colors
        let commonColors: [ColorPalette.PaletteColor] = [
            ColorPalette.red,
            ColorPalette.orange,
            ColorPalette.yellow,
            ColorPalette.green,
            ColorPalette.blue,
            ColorPalette.purple
        ]

        for paletteColor in commonColors {
            let button = ColorButton(paletteColor: paletteColor)
            button.target = self
            button.action = #selector(colorButtonClicked(_:))
            addSubview(button)
            colorButtons.append(button)
        }

        // Add no color button
        let button = NoColorButton()
        button.target = self
        button.action = #selector(noColorButtonClicked)
        addSubview(button)
        noColorButton = button

        updateSelection()
    }

    // MARK: - Layout

    override func layout() {
        super.layout()

        let padding: CGFloat = 8
        var xOffset = padding

        // Layout color buttons
        for button in colorButtons {
            button.frame = NSRect(
                x: xOffset,
                y: padding,
                width: swatchSize,
                height: swatchSize
            )
            xOffset += swatchSize + spacing
        }

        // Layout no color button
        if let noColorButton = noColorButton {
            noColorButton.frame = NSRect(
                x: xOffset,
                y: padding,
                width: swatchSize,
                height: swatchSize
            )
        }
    }

    override var intrinsicContentSize: NSSize {
        let padding: CGFloat = 8
        let buttonCount = CGFloat(colorButtons.count + 1) // +1 for no color button
        let width = buttonCount * swatchSize + (buttonCount - 1) * spacing + padding * 2
        let height = swatchSize + padding * 2
        return NSSize(width: width, height: height)
    }

    // MARK: - Actions

    @objc private func colorButtonClicked(_ sender: ColorButton) {
        selectedColor = sender.paletteColor.hex
        onColorSelected?(selectedColor)
    }

    @objc private func noColorButtonClicked() {
        selectedColor = nil
        onColorSelected?(nil)
    }

    // MARK: - Selection

    private func updateSelection() {
        noColorButton?.isSelected = selectedColor == nil

        for button in colorButtons {
            button.isSelected = selectedColor == button.paletteColor.hex
        }
    }
}
