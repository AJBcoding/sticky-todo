//
//  ColorPickerView.swift
//  StickyToDo
//
//  SwiftUI color picker component using predefined color palette.
//

import SwiftUI

/// Color picker view displaying predefined color palette
///
/// Features:
/// - Grid layout of color swatches
/// - Supports optional "no color" selection
/// - Visual indication of selected color
/// - Hover effects for better UX
struct ColorPickerView: View {

    // MARK: - Properties

    /// Currently selected color hex string (nil = no color)
    @Binding var selectedColor: String?

    /// Whether to show a "no color" option
    var allowNoColor: Bool = true

    /// Callback when color is selected
    var onColorSelected: ((String?) -> Void)?

    // MARK: - State

    @State private var hoveredColorId: String?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)
                .foregroundColor(.secondary)

            // Color grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 32, maximum: 32), spacing: 8)
            ], spacing: 8) {
                // No color option
                if allowNoColor {
                    noColorSwatch
                }

                // Predefined colors
                ForEach(ColorPalette.allColors) { paletteColor in
                    colorSwatch(for: paletteColor)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }

    // MARK: - No Color Swatch

    private var noColorSwatch: some View {
        ZStack {
            // Diagonal line pattern to indicate "no color"
            Circle()
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 2)
                .background(
                    Circle()
                        .fill(Color.clear)
                )
                .overlay(
                    Path { path in
                        path.move(to: CGPoint(x: 4, y: 28))
                        path.addLine(to: CGPoint(x: 28, y: 4))
                    }
                    .stroke(Color.red, lineWidth: 2)
                )

            // Selection indicator
            if selectedColor == nil {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 3)
            }
        }
        .frame(width: 32, height: 32)
        .contentShape(Circle())
        .onTapGesture {
            selectedColor = nil
            onColorSelected?(nil)
        }
        .onHover { isHovered in
            hoveredColorId = isHovered ? "none" : nil
        }
        .scaleEffect(hoveredColorId == "none" ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: hoveredColorId)
        .help("No Color")
    }

    // MARK: - Color Swatch

    private func colorSwatch(for paletteColor: ColorPalette.PaletteColor) -> some View {
        let isSelected = selectedColor == paletteColor.hex

        return ZStack {
            // Color circle
            Circle()
                .fill(paletteColor.color)
                .shadow(color: .black.opacity(0.1), radius: 1, y: 1)

            // Selection indicator
            if isSelected {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 3)
            }

            // Hover effect
            if hoveredColorId == paletteColor.id && !isSelected {
                Circle()
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
            }
        }
        .frame(width: 32, height: 32)
        .contentShape(Circle())
        .onTapGesture {
            selectedColor = paletteColor.hex
            onColorSelected?(paletteColor.hex)
        }
        .onHover { isHovered in
            hoveredColorId = isHovered ? paletteColor.id : nil
        }
        .scaleEffect(hoveredColorId == paletteColor.id ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: hoveredColorId)
        .help(paletteColor.name)
    }
}

// MARK: - Compact Color Picker

/// Compact inline color picker for use in context menus or popovers
struct CompactColorPickerView: View {

    // MARK: - Properties

    /// Currently selected color hex string (nil = no color)
    @Binding var selectedColor: String?

    /// Callback when color is selected
    var onColorSelected: ((String?) -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // First row: Red to Blue
            HStack(spacing: 6) {
                compactColorButton(ColorPalette.red)
                compactColorButton(ColorPalette.orange)
                compactColorButton(ColorPalette.yellow)
                compactColorButton(ColorPalette.green)
                compactColorButton(ColorPalette.blue)
            }

            // Second row: Purple to Gray + No color
            HStack(spacing: 6) {
                compactColorButton(ColorPalette.indigo)
                compactColorButton(ColorPalette.purple)
                compactColorButton(ColorPalette.pink)
                compactColorButton(ColorPalette.brown)
                compactColorButton(ColorPalette.gray)

                // No color button
                noColorButton
            }
        }
        .padding(8)
    }

    // MARK: - Compact Color Button

    private func compactColorButton(_ paletteColor: ColorPalette.PaletteColor) -> some View {
        let isSelected = selectedColor == paletteColor.hex

        return Circle()
            .fill(paletteColor.color)
            .frame(width: 20, height: 20)
            .overlay(
                Circle()
                    .strokeBorder(
                        isSelected ? Color.white : Color.clear,
                        lineWidth: 2
                    )
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 1
                    )
                    .padding(-2)
            )
            .contentShape(Circle())
            .onTapGesture {
                selectedColor = paletteColor.hex
                onColorSelected?(paletteColor.hex)
            }
            .help(paletteColor.name)
    }

    // MARK: - No Color Button

    private var noColorButton: some View {
        let isSelected = selectedColor == nil

        return ZStack {
            Circle()
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                .background(Circle().fill(Color.clear))
                .overlay(
                    Path { path in
                        path.move(to: CGPoint(x: 2, y: 18))
                        path.addLine(to: CGPoint(x: 18, y: 2))
                    }
                    .stroke(Color.red, lineWidth: 1.5)
                )

            if isSelected {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .padding(-2)
            }
        }
        .frame(width: 20, height: 20)
        .contentShape(Circle())
        .onTapGesture {
            selectedColor = nil
            onColorSelected?(nil)
        }
        .help("No Color")
    }
}

// MARK: - Color Indicator

/// Small color indicator bar/dot for displaying task color
struct ColorIndicator: View {

    // MARK: - Properties

    /// Color hex string (nil = no color)
    let color: String?

    /// Style of indicator
    var style: Style = .bar

    // MARK: - Style

    enum Style {
        case bar    // Vertical bar on the left
        case dot    // Small circular dot
        case badge  // Rounded rectangle badge
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let colorHex = color {
                switch style {
                case .bar:
                    barIndicator(color: Color(hexString: colorHex))
                case .dot:
                    dotIndicator(color: Color(hexString: colorHex))
                case .badge:
                    badgeIndicator(color: Color(hexString: colorHex))
                }
            }
        }
    }

    // MARK: - Indicator Styles

    private func barIndicator(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: 3)
    }

    private func dotIndicator(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    private func badgeIndicator(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(0.2))
            .frame(width: 16, height: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(color, lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview("Color Picker - Full") {
    ColorPickerView(
        selectedColor: .constant("#007AFF"),
        allowNoColor: true
    )
    .padding()
    .frame(width: 300)
}

#Preview("Color Picker - Compact") {
    CompactColorPickerView(
        selectedColor: .constant("#FF3B30")
    )
    .padding()
}

#Preview("Color Indicator - Bar") {
    HStack(spacing: 12) {
        ColorIndicator(color: "#FF3B30", style: .bar)
            .frame(height: 20)
        Text("Task with red color")
    }
    .padding()
}

#Preview("Color Indicator - Dot") {
    HStack(spacing: 8) {
        ColorIndicator(color: "#007AFF", style: .dot)
        Text("Task with blue color")
    }
    .padding()
}

#Preview("Color Indicator - Badge") {
    HStack(spacing: 8) {
        ColorIndicator(color: "#34C759", style: .badge)
        Text("Task with green color")
    }
    .padding()
}
