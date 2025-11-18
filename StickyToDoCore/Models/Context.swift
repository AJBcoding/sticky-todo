//
//  Context.swift
//  StickyToDo
//
//  Context configuration with name, icon, and color.
//

import Foundation

/// Represents a GTD context (location, tool, or energy level required for tasks)
///
/// Contexts are predefined in config/contexts.md and help filter tasks by
/// where or how they can be completed (e.g., @computer, @phone, @home).
struct Context: Identifiable, Codable, Equatable, Hashable {
    /// Unique identifier for the context
    var id: String { name }

    /// Context name, typically prefixed with @ (e.g., "@computer", "@phone")
    var name: String

    /// Icon/emoji representing the context
    var icon: String

    /// Color name for UI display
    var color: String

    /// Order index for sorting contexts in the UI
    var order: Int?

    /// Creates a new context
    /// - Parameters:
    ///   - name: Context name (e.g., "@computer")
    ///   - icon: Icon/emoji (e.g., "💻")
    ///   - color: Color name (e.g., "blue")
    ///   - order: Sort order index
    init(name: String, icon: String, color: String, order: Int? = nil) {
        self.name = name
        self.icon = icon
        self.color = color
        self.order = order
    }
}

extension Context {
    /// Returns the display name without the @ prefix if present
    var displayName: String {
        return name.hasPrefix("@") ? String(name.dropFirst()) : name
    }

    /// Returns the name with @ prefix, adding it if not present
    var prefixedName: String {
        return name.hasPrefix("@") ? name : "@\(name)"
    }

    /// Returns true if this is a location-based context
    var isLocationBased: Bool {
        let locationKeywords = ["home", "office", "work", "errands", "anywhere"]
        let lowercaseName = displayName.lowercased()
        return locationKeywords.contains { lowercaseName.contains($0) }
    }

    /// Returns true if this is a tool-based context
    var isToolBased: Bool {
        let toolKeywords = ["computer", "phone", "online", "offline", "email"]
        let lowercaseName = displayName.lowercased()
        return toolKeywords.contains { lowercaseName.contains($0) }
    }
}

// MARK: - Predefined Contexts

extension Context {
    /// Default contexts provided on first run
    static let defaults: [Context] = [
        Context(name: "@computer", icon: "💻", color: "blue", order: 0),
        Context(name: "@phone", icon: "📱", color: "green", order: 1),
        Context(name: "@home", icon: "🏠", color: "orange", order: 2),
        Context(name: "@errands", icon: "🚗", color: "purple", order: 3),
        Context(name: "@office", icon: "🏢", color: "gray", order: 4)
    ]

    /// Common additional contexts users might want
    static let suggestions: [Context] = [
        Context(name: "@online", icon: "🌐", color: "cyan"),
        Context(name: "@anywhere", icon: "📍", color: "pink"),
        Context(name: "@waiting", icon: "⏳", color: "yellow"),
        Context(name: "@agenda", icon: "👥", color: "red")
    ]
}

// MARK: - Comparable

extension Context: Comparable {
    static func < (lhs: Context, rhs: Context) -> Bool {
        // Sort by order if both have it, otherwise alphabetically
        if let lOrder = lhs.order, let rOrder = rhs.order {
            return lOrder < rOrder
        } else if lhs.order != nil {
            return true
        } else if rhs.order != nil {
            return false
        } else {
            return lhs.name < rhs.name
        }
    }
}
