//
//  Priority.swift
//  StickyToDo
//
//  Task priority enumeration.
//

import Foundation

/// Task priority level
///
/// - high: High priority, urgent or important
/// - medium: Medium priority, default
/// - low: Low priority, can be deferred
enum Priority: String, Codable, CaseIterable {
    case high
    case medium
    case low
}

extension Priority {
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .low:
            return "Low"
        }
    }

    /// Numeric value for sorting (higher number = higher priority)
    var sortOrder: Int {
        switch self {
        case .high:
            return 3
        case .medium:
            return 2
        case .low:
            return 1
        }
    }

    /// Natural language marker used in quick capture
    /// Example: "Call John !high" sets priority to high
    var marker: String {
        switch self {
        case .high:
            return "!high"
        case .medium:
            return "!medium"
        case .low:
            return "!low"
        }
    }

    /// Color coding for UI display
    var colorName: String {
        switch self {
        case .high:
            return "red"
        case .medium:
            return "yellow"
        case .low:
            return "blue"
        }
    }
}
