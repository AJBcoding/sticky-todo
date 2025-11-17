//
//  TaskType.swift
//  StickyToDo
//
//  Task type enumeration for the two-tier task system.
//  Notes are lightweight entries for brainstorming.
//  Tasks carry full GTD metadata and are actionable items.
//

import Foundation

/// Represents the type of a task item in the two-tier system
///
/// - note: Lightweight entry for brainstorming and idea capture
/// - task: Full GTD task with complete metadata and actionable status
enum TaskType: String, Codable, CaseIterable {
    case note
    case task
}

extension TaskType {
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .note:
            return "Note"
        case .task:
            return "Task"
        }
    }

    /// Returns true if this type supports full GTD metadata
    var supportsFullMetadata: Bool {
        return self == .task
    }
}
