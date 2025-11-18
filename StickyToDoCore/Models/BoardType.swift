//
//  BoardType.swift
//  StickyToDo
//
//  Board type enumeration defining metadata update behavior.
//

import Foundation

/// Type of board, which determines what metadata is updated when tasks are moved
///
/// - context: Moving a task to this board sets the task's context field
/// - project: Moving a task to this board sets the task's project field
/// - status: Moving a task to this board sets the task's status field
/// - custom: User-defined rules determine what metadata is updated
enum BoardType: String, Codable, CaseIterable {
    case context
    case project
    case status
    case custom
}

extension BoardType {
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .context:
            return "Context"
        case .project:
            return "Project"
        case .status:
            return "Status"
        case .custom:
            return "Custom"
        }
    }

    /// Description of what happens when a task is moved to this board type
    var metadataEffect: String {
        switch self {
        case .context:
            return "Sets task context"
        case .project:
            return "Sets task project"
        case .status:
            return "Sets task status"
        case .custom:
            return "Applies custom rules"
        }
    }

    /// Returns true if this board type supports auto-creation
    var supportsAutoCreation: Bool {
        switch self {
        case .context, .project:
            return true
        case .status, .custom:
            return false
        }
    }

    /// Returns true if this board type supports auto-hide
    var supportsAutoHide: Bool {
        return self == .project
    }
}
