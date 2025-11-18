//
//  Status.swift
//  StickyToDo
//
//  Task status enumeration following GTD methodology.
//

import Foundation

/// GTD-style task status
///
/// - inbox: New task awaiting processing
/// - nextAction: Task ready to be worked on
/// - waiting: Task blocked, waiting for something
/// - someday: Task deferred to future consideration
/// - completed: Task finished
public enum Status: String, Codable, CaseIterable {
    case inbox = "inbox"
    case nextAction = "next-action"
    case waiting = "waiting"
    case someday = "someday"
    case completed = "completed"
}

extension Status {
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .inbox:
            return "Inbox"
        case .nextAction:
            return "Next Action"
        case .waiting:
            return "Waiting For"
        case .someday:
            return "Someday/Maybe"
        case .completed:
            return "Completed"
        }
    }

    /// Returns true if this status represents an active task
    var isActive: Bool {
        return self != .completed
    }

    /// Returns true if this status represents an actionable task
    var isActionable: Bool {
        return self == .nextAction
    }

    /// Color coding for UI display
    var colorName: String {
        switch self {
        case .inbox:
            return "blue"
        case .nextAction:
            return "green"
        case .waiting:
            return "orange"
        case .someday:
            return "purple"
        case .completed:
            return "gray"
        }
    }
}
