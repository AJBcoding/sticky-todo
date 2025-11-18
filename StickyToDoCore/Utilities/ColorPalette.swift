//
//  ColorPalette.swift
//  StickyToDo
//
//  Provides predefined color palette for tasks and boards.
//  Colors match macOS system colors for consistency.
//

import Foundation

/// Predefined color palette for tasks and boards
struct ColorPalette {

    // MARK: - Color Definition

    /// Represents a color in the palette
    struct PaletteColor: Identifiable, Equatable {
        let id: String
        let name: String
        let hex: String

        /// Creates a color with the given properties
        /// - Parameters:
        ///   - id: Unique identifier (matches hex without #)
        ///   - name: Display name
        ///   - hex: Hex color string (e.g., "#FF5733")
        init(id: String, name: String, hex: String) {
            self.id = id
            self.name = name
            self.hex = hex
        }
    }

    // MARK: - Predefined Colors

    /// Red - for high priority, urgent, or critical items
    static let red = PaletteColor(
        id: "FF3B30",
        name: "Red",
        hex: "#FF3B30"
    )

    /// Orange - for warnings, due soon items
    static let orange = PaletteColor(
        id: "FF9500",
        name: "Orange",
        hex: "#FF9500"
    )

    /// Yellow - for flagged items, notes
    static let yellow = PaletteColor(
        id: "FFCC00",
        name: "Yellow",
        hex: "#FFCC00"
    )

    /// Green - for completed, success, positive items
    static let green = PaletteColor(
        id: "34C759",
        name: "Green",
        hex: "#34C759"
    )

    /// Mint - for fresh, new items
    static let mint = PaletteColor(
        id: "00C7BE",
        name: "Mint",
        hex: "#00C7BE"
    )

    /// Teal - for calm, organized items
    static let teal = PaletteColor(
        id: "30B0C7",
        name: "Teal",
        hex: "#30B0C7"
    )

    /// Cyan - for informational items
    static let cyan = PaletteColor(
        id: "32ADE6",
        name: "Cyan",
        hex: "#32ADE6"
    )

    /// Blue - for default, standard items
    static let blue = PaletteColor(
        id: "007AFF",
        name: "Blue",
        hex: "#007AFF"
    )

    /// Indigo - for deep focus items
    static let indigo = PaletteColor(
        id: "5856D6",
        name: "Indigo",
        hex: "#5856D6"
    )

    /// Purple - for creative, special items
    static let purple = PaletteColor(
        id: "AF52DE",
        name: "Purple",
        hex: "#AF52DE"
    )

    /// Pink - for personal, fun items
    static let pink = PaletteColor(
        id: "FF2D55",
        name: "Pink",
        hex: "#FF2D55"
    )

    /// Brown - for grounded, earthy items
    static let brown = PaletteColor(
        id: "A2845E",
        name: "Brown",
        hex: "#A2845E"
    )

    /// Gray - for neutral, inactive items
    static let gray = PaletteColor(
        id: "8E8E93",
        name: "Gray",
        hex: "#8E8E93"
    )

    // MARK: - All Colors Array

    /// Array of all predefined colors in the palette
    static let allColors: [PaletteColor] = [
        red,
        orange,
        yellow,
        green,
        mint,
        teal,
        cyan,
        blue,
        indigo,
        purple,
        pink,
        brown,
        gray
    ]

    // MARK: - Helper Methods

    /// Returns a color by its hex value
    /// - Parameter hex: Hex color string (with or without #)
    /// - Returns: Matching palette color, or nil if not found
    static func color(forHex hex: String) -> PaletteColor? {
        let normalizedHex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        return allColors.first { $0.id.uppercased() == normalizedHex.uppercased() }
    }

    /// Returns a color by its name
    /// - Parameter name: Color name (case-insensitive)
    /// - Returns: Matching palette color, or nil if not found
    static func color(forName name: String) -> PaletteColor? {
        return allColors.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Validates if a hex string is a valid color
    /// - Parameter hex: Hex color string (with or without #)
    /// - Returns: True if valid hex color format
    static func isValidHex(_ hex: String) -> Bool {
        let normalizedHex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let hexRegex = "^[0-9A-Fa-f]{6}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", hexRegex)
        return predicate.evaluate(with: normalizedHex)
    }

    /// Returns the default color for new items
    static var defaultColor: PaletteColor {
        return blue
    }
}

// MARK: - Color Extensions

#if canImport(AppKit)
import AppKit

extension ColorPalette.PaletteColor {
    /// Converts hex string to NSColor
    var nsColor: NSColor {
        return NSColor(hexString: hex) ?? .systemBlue
    }
}

extension NSColor {
    /// Creates NSColor from hex string
    /// - Parameter hexString: Hex color string (with or without #)
    convenience init?(hexString: String) {
        let hex = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString

        guard hex.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(calibratedRed: r, green: g, blue: b, alpha: 1.0)
    }

    /// Converts NSColor to hex string
    var hexString: String {
        guard let rgbColor = usingColorSpace(.deviceRGB) else {
            return "#000000"
        }

        let r = Int(rgbColor.redComponent * 255.0)
        let g = Int(rgbColor.greenComponent * 255.0)
        let b = Int(rgbColor.blueComponent * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

extension ColorPalette.PaletteColor {
    /// Converts hex string to SwiftUI Color
    var color: Color {
        return Color(hexString: hex)
    }
}

extension Color {
    /// Creates SwiftUI Color from hex string
    /// - Parameter hexString: Hex color string (with or without #)
    init(hexString: String) {
        let hex = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString

        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    /// Converts Color to hex string (only works with RGB colors)
    /// Note: This is a best-effort conversion and may not work for all Color types
    var hexString: String? {
        #if canImport(AppKit)
        return NSColor(self).hexString
        #else
        return nil
        #endif
    }
}
#endif
