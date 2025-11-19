//
//  DesignSystem.swift
//  StickyToDo-SwiftUI
//
//  Centralized design system constants for consistent UI/UX.
//

import SwiftUI

/// Design system constants for consistent spacing, sizing, and styling
enum DesignSystem {

    // MARK: - Spacing (8pt Grid System)

    enum Spacing {
        /// 4pt - Extra tight spacing
        static let xxxs: CGFloat = 4

        /// 8pt - Base unit, minimum spacing
        static let xxs: CGFloat = 8

        /// 12pt - Tight spacing (1.5x base)
        static let xs: CGFloat = 12

        /// 16pt - Standard spacing (2x base)
        static let sm: CGFloat = 16

        /// 24pt - Medium spacing (3x base)
        static let md: CGFloat = 24

        /// 32pt - Large spacing (4x base)
        static let lg: CGFloat = 32

        /// 40pt - Extra large spacing (5x base)
        static let xl: CGFloat = 40

        /// 48pt - Extra extra large spacing (6x base)
        static let xxl: CGFloat = 48

        /// 64pt - Massive spacing (8x base)
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        /// 4pt - Small radius for subtle rounding
        static let sm: CGFloat = 4

        /// 6pt - Standard radius for buttons and cards
        static let md: CGFloat = 6

        /// 8pt - Medium radius for containers
        static let lg: CGFloat = 8

        /// 12pt - Large radius for prominent elements
        static let xl: CGFloat = 12

        /// 16pt - Extra large radius
        static let xxl: CGFloat = 16
    }

    // MARK: - Font Sizes

    enum FontSize {
        /// 10pt - Extra small text
        static let xs: Font = .system(size: 10)

        /// 12pt - Small text (captions)
        static let sm: Font = .system(size: 12)

        /// 14pt - Base text size
        static let base: Font = .system(size: 14)

        /// 16pt - Medium text
        static let md: Font = .system(size: 16)

        /// 18pt - Large text
        static let lg: Font = .system(size: 18)

        /// 20pt - Extra large text
        static let xl: Font = .system(size: 20)

        /// 24pt - Heading size
        static let xxl: Font = .system(size: 24)

        /// 32pt - Large heading
        static let xxxl: Font = .system(size: 32)
    }

    // MARK: - Icon Sizes

    enum IconSize {
        /// 12pt - Small icon
        static let sm: CGFloat = 12

        /// 16pt - Standard icon
        static let md: CGFloat = 16

        /// 20pt - Medium icon
        static let lg: CGFloat = 20

        /// 24pt - Large icon
        static let xl: CGFloat = 24

        /// 32pt - Extra large icon
        static let xxl: CGFloat = 32

        /// 48pt - Massive icon
        static let xxxl: CGFloat = 48

        /// 64pt - Hero icon
        static let hero: CGFloat = 64
    }

    // MARK: - Opacity

    enum Opacity {
        /// 0.05 - Subtle background
        static let subtle: Double = 0.05

        /// 0.1 - Light background
        static let light: Double = 0.1

        /// 0.2 - Medium background
        static let medium: Double = 0.2

        /// 0.3 - Prominent background
        static let prominent: Double = 0.3

        /// 0.5 - Half opacity
        static let half: Double = 0.5

        /// 0.8 - Mostly opaque
        static let strong: Double = 0.8
    }

    // MARK: - Animation

    enum Animation {
        /// Fast animation (0.2s)
        static let fast: SwiftUI.Animation = .easeInOut(duration: 0.2)

        /// Standard animation (0.3s)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.3)

        /// Slow animation (0.5s)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.5)

        /// Spring animation
        static let spring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)
    }

    // MARK: - Shadows

    enum Shadow {
        /// Subtle shadow for cards
        static let card: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) =
            (.black.opacity(0.1), 2, 0, 1)

        /// Medium shadow for elevated elements
        static let elevated: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) =
            (.black.opacity(0.15), 8, 0, 4)

        /// Strong shadow for modals
        static let modal: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) =
            (.black.opacity(0.25), 20, 0, 10)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies standard card styling
    func cardStyle() -> some View {
        self
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .shadow(
                color: DesignSystem.Shadow.card.color,
                radius: DesignSystem.Shadow.card.radius,
                x: DesignSystem.Shadow.card.x,
                y: DesignSystem.Shadow.card.y
            )
    }

    /// Applies standard padding
    func standardPadding() -> some View {
        self.padding(DesignSystem.Spacing.md)
    }

    /// Applies compact padding
    func compactPadding() -> some View {
        self.padding(DesignSystem.Spacing.sm)
    }
}
