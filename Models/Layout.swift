//
//  Layout.swift
//  StickyToDo
//
//  Board layout enumeration defining visual organization.
//

import Foundation

/// Visual layout mode for a board
///
/// - freeform: Infinite canvas with drag-anywhere positioning, ideal for brainstorming
/// - kanban: Vertical columns for workflow stages, tasks move between columns
/// - grid: Named sections with grid/auto-arrange layout, organized by criteria
enum Layout: String, Codable, CaseIterable {
    case freeform
    case kanban
    case grid
}

extension Layout {
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .freeform:
            return "Freeform Canvas"
        case .kanban:
            return "Kanban Board"
        case .grid:
            return "Grid/Sections"
        }
    }

    /// Description of the layout mode
    var description: String {
        switch self {
        case .freeform:
            return "Drag sticky notes anywhere on an infinite canvas"
        case .kanban:
            return "Vertical swim lanes for workflow stages"
        case .grid:
            return "Named sections with auto-arrange layout"
        }
    }

    /// Returns true if this layout supports custom positioning
    var supportsCustomPositions: Bool {
        return self == .freeform
    }

    /// Returns true if this layout requires column definitions
    var requiresColumns: Bool {
        return self == .kanban
    }

    /// Returns true if this layout supports auto-arrangement
    var supportsAutoArrange: Bool {
        switch self {
        case .freeform:
            return false
        case .kanban, .grid:
            return true
        }
    }

    /// Recommended use case for this layout
    var useCase: String {
        switch self {
        case .freeform:
            return "Brainstorming and spatial planning"
        case .kanban:
            return "Workflow and process management"
        case .grid:
            return "Organized task lists by category"
        }
    }
}
