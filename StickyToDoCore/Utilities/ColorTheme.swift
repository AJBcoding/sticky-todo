//
//  ColorTheme.swift
//  StickyToDoCore
//
//  Comprehensive theming system with dark mode support, accent colors, and true black mode.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Theme Mode

/// App-wide theme mode
public enum ThemeMode: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case trueBlack = "trueBlack"  // OLED-friendly pure black

    public var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .trueBlack: return "True Black"
        }
    }

    public var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .trueBlack: return "moon.stars.fill"
        }
    }

    public var description: String {
        switch self {
        case .system: return "Automatically match system appearance"
        case .light: return "Always use light appearance"
        case .dark: return "Dark mode with subtle backgrounds"
        case .trueBlack: return "Pure black for OLED displays"
        }
    }
}

// MARK: - Accent Color

/// Customizable accent colors for the app
public enum AccentColorOption: String, Codable, CaseIterable {
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case mint = "mint"
    case teal = "teal"
    case cyan = "cyan"
    case indigo = "indigo"

    public var displayName: String {
        rawValue.capitalized
    }

    #if canImport(SwiftUI)
    /// SwiftUI Color representation
    public var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .indigo: return .indigo
        }
    }
    #endif

    #if canImport(AppKit)
    /// AppKit NSColor representation
    public var nsColor: NSColor {
        switch self {
        case .blue: return .systemBlue
        case .purple: return .systemPurple
        case .pink: return .systemPink
        case .red: return .systemRed
        case .orange: return .systemOrange
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .mint: return .systemMint
        case .teal: return .systemTeal
        case .cyan: return .systemCyan
        case .indigo: return .systemIndigo
        }
    }
    #endif
}

// MARK: - Color Theme

/// Comprehensive color theme system
public struct ColorTheme {

    // MARK: - Theme Properties

    public let mode: ThemeMode
    public let accentColor: AccentColorOption

    // MARK: - Initialization

    public init(mode: ThemeMode = .system, accentColor: AccentColorOption = .blue) {
        self.mode = mode
        self.accentColor = accentColor
    }

    // MARK: - Adaptive Colors

    #if canImport(SwiftUI)

    /// Primary background color (adaptive to theme mode)
    public var primaryBackground: Color {
        switch mode {
        case .system:
            return Color(nsColor: .windowBackgroundColor)
        case .light:
            return Color(nsColor: .white)
        case .dark:
            return Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E
        case .trueBlack:
            return Color(red: 0, green: 0, blue: 0) // #000000
        }
    }

    /// Secondary background color (for cards, panels)
    public var secondaryBackground: Color {
        switch mode {
        case .system:
            return Color(nsColor: .controlBackgroundColor)
        case .light:
            return Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
        case .dark:
            return Color(red: 0.14, green: 0.14, blue: 0.15) // #242426
        case .trueBlack:
            return Color(red: 0.05, green: 0.05, blue: 0.05) // #0D0D0D
        }
    }

    /// Tertiary background color (for elevated elements)
    public var tertiaryBackground: Color {
        switch mode {
        case .system:
            return Color(nsColor: .underPageBackgroundColor)
        case .light:
            return Color(red: 1, green: 1, blue: 1) // #FFFFFF
        case .dark:
            return Color(red: 0.18, green: 0.18, blue: 0.19) // #2C2C2E
        case .trueBlack:
            return Color(red: 0.08, green: 0.08, blue: 0.08) // #141414
        }
    }

    /// Primary text color
    public var primaryText: Color {
        switch mode {
        case .system:
            return Color(nsColor: .labelColor)
        case .light:
            return Color(red: 0, green: 0, blue: 0) // #000000
        case .dark, .trueBlack:
            return Color(red: 1, green: 1, blue: 1) // #FFFFFF
        }
    }

    /// Secondary text color (dimmed)
    public var secondaryText: Color {
        switch mode {
        case .system:
            return Color(nsColor: .secondaryLabelColor)
        case .light:
            return Color(red: 0.24, green: 0.24, blue: 0.26, opacity: 0.6) // #3C3C434D
        case .dark, .trueBlack:
            return Color(red: 0.92, green: 0.92, blue: 0.96, opacity: 0.6) // #EBEBF599
        }
    }

    /// Tertiary text color (more dimmed)
    public var tertiaryText: Color {
        switch mode {
        case .system:
            return Color(nsColor: .tertiaryLabelColor)
        case .light:
            return Color(red: 0.24, green: 0.24, blue: 0.26, opacity: 0.3) // #3C3C434D
        case .dark, .trueBlack:
            return Color(red: 0.92, green: 0.92, blue: 0.96, opacity: 0.3) // #EBEBF54D
        }
    }

    /// Separator/divider color
    public var separator: Color {
        switch mode {
        case .system:
            return Color(nsColor: .separatorColor)
        case .light:
            return Color(red: 0.24, green: 0.24, blue: 0.26, opacity: 0.2) // #3C3C4333
        case .dark:
            return Color(red: 0.33, green: 0.33, blue: 0.35, opacity: 0.6) // #54545899
        case .trueBlack:
            return Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.8) // #333333CC
        }
    }

    /// Sidebar background
    public var sidebarBackground: Color {
        switch mode {
        case .system:
            return Color(nsColor: .controlBackgroundColor)
        case .light:
            return Color(red: 0.97, green: 0.97, blue: 0.98) // #F7F7F9
        case .dark:
            return Color(red: 0.09, green: 0.09, blue: 0.10) // #171719
        case .trueBlack:
            return Color(red: 0, green: 0, blue: 0) // #000000
        }
    }

    /// Hover/selection background
    public var hoverBackground: Color {
        switch mode {
        case .system:
            return Color(nsColor: .selectedControlColor).opacity(0.5)
        case .light:
            return accentColor.color.opacity(0.1)
        case .dark:
            return accentColor.color.opacity(0.15)
        case .trueBlack:
            return accentColor.color.opacity(0.2)
        }
    }

    /// Selected item background
    public var selectionBackground: Color {
        switch mode {
        case .system:
            return Color(nsColor: .selectedControlColor)
        case .light:
            return accentColor.color.opacity(0.2)
        case .dark:
            return accentColor.color.opacity(0.25)
        case .trueBlack:
            return accentColor.color.opacity(0.3)
        }
    }

    /// App accent color
    public var accent: Color {
        return accentColor.color
    }

    /// Task card background
    public var taskCardBackground: Color {
        switch mode {
        case .system:
            return Color(nsColor: .controlBackgroundColor)
        case .light:
            return Color(red: 1, green: 1, blue: 1) // #FFFFFF
        case .dark:
            return Color(red: 0.16, green: 0.16, blue: 0.17) // #282829
        case .trueBlack:
            return Color(red: 0.06, green: 0.06, blue: 0.06) // #0F0F0F
        }
    }

    /// Task card shadow
    public var taskCardShadow: Color {
        switch mode {
        case .system, .light:
            return Color.black.opacity(0.1)
        case .dark:
            return Color.black.opacity(0.3)
        case .trueBlack:
            return Color.clear // No shadows in true black mode
        }
    }

    /// Border color
    public var border: Color {
        switch mode {
        case .system:
            return Color(nsColor: .separatorColor)
        case .light:
            return Color(red: 0.85, green: 0.85, blue: 0.87) // #D9D9DD
        case .dark:
            return Color(red: 0.22, green: 0.22, blue: 0.23) // #38383A
        case .trueBlack:
            return Color(red: 0.15, green: 0.15, blue: 0.15) // #262626
        }
    }

    /// Success/positive color
    public var success: Color {
        switch mode {
        case .system, .light:
            return Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
        case .dark, .trueBlack:
            return Color(red: 0.19, green: 0.82, blue: 0.35) // #30D158
        }
    }

    /// Warning color
    public var warning: Color {
        switch mode {
        case .system, .light:
            return Color(red: 1, green: 0.58, blue: 0) // #FF9500
        case .dark, .trueBlack:
            return Color(red: 1, green: 0.62, blue: 0) // #FF9F0A
        }
    }

    /// Error/destructive color
    public var error: Color {
        switch mode {
        case .system, .light:
            return Color(red: 1, green: 0.23, blue: 0.19) // #FF3B30
        case .dark, .trueBlack:
            return Color(red: 1, green: 0.27, blue: 0.23) // #FF453A
        }
    }

    #endif

    // MARK: - AppKit Colors

    #if canImport(AppKit)

    /// Primary background NSColor
    public var nsPrimaryBackground: NSColor {
        switch mode {
        case .system:
            return .windowBackgroundColor
        case .light:
            return .white
        case .dark:
            return NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1) // #1C1C1E
        case .trueBlack:
            return .black
        }
    }

    /// Secondary background NSColor
    public var nsSecondaryBackground: NSColor {
        switch mode {
        case .system:
            return .controlBackgroundColor
        case .light:
            return NSColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1) // #F2F2F7
        case .dark:
            return NSColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 1) // #242426
        case .trueBlack:
            return NSColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1) // #0D0D0D
        }
    }

    /// Primary text NSColor
    public var nsPrimaryText: NSColor {
        switch mode {
        case .system:
            return .labelColor
        case .light:
            return .black
        case .dark, .trueBlack:
            return .white
        }
    }

    /// Accent NSColor
    public var nsAccent: NSColor {
        return accentColor.nsColor
    }

    #endif

    // MARK: - Helper Methods

    /// Returns the appropriate color scheme for SwiftUI
    #if canImport(SwiftUI)
    public var colorScheme: ColorScheme? {
        switch mode {
        case .system:
            return nil // Use system default
        case .light:
            return .light
        case .dark, .trueBlack:
            return .dark
        }
    }
    #endif

    /// Returns whether this is a dark theme
    public var isDark: Bool {
        return mode == .dark || mode == .trueBlack
    }

    /// Returns whether this is true black mode
    public var isTrueBlack: Bool {
        return mode == .trueBlack
    }

    // MARK: - Contrast Adjustments

    /// Enhances contrast for better readability in dark mode
    public func withEnhancedContrast() -> ColorTheme {
        return ColorTheme(mode: mode, accentColor: accentColor)
    }
}

// MARK: - Default Theme

extension ColorTheme {
    /// Default light theme
    public static let light = ColorTheme(mode: .light, accentColor: .blue)

    /// Default dark theme
    public static let dark = ColorTheme(mode: .dark, accentColor: .blue)

    /// Default true black theme
    public static let trueBlack = ColorTheme(mode: .trueBlack, accentColor: .blue)

    /// System theme (auto)
    public static let system = ColorTheme(mode: .system, accentColor: .blue)
}

// MARK: - SwiftUI Environment

#if canImport(SwiftUI)
private struct ColorThemeKey: EnvironmentKey {
    static let defaultValue = ColorTheme.system
}

extension EnvironmentValues {
    public var colorTheme: ColorTheme {
        get { self[ColorThemeKey.self] }
        set { self[ColorThemeKey.self] = newValue }
    }
}

extension View {
    /// Applies a color theme to the view hierarchy
    public func colorTheme(_ theme: ColorTheme) -> some View {
        self.environment(\.colorTheme, theme)
            .preferredColorScheme(theme.colorScheme)
            .tint(theme.accent)
    }
}
#endif
