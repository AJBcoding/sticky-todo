//
//  Board.swift
//  StickyToDo
//
//  Board model representing visual organization of tasks.
//

import Foundation

/// Represents a board for organizing and visualizing tasks
///
/// Boards are stored as markdown files in the boards/ directory.
/// They define how tasks are filtered, displayed, and organized visually.
public struct Board: Identifiable, Codable, Equatable {
    // MARK: - Core Properties

    /// Unique identifier for the board (also used as filename)
    let id: String

    /// Board type, determines metadata update behavior
    var type: BoardType

    /// Visual layout mode for this board
    var layout: Layout

    /// Filter criteria determining which tasks appear on this board
    var filter: Filter

    /// Column names for kanban layout
    var columns: [String]?

    /// Whether to automatically hide this board when it has no active tasks
    var autoHide: Bool

    /// Number of days after which to hide inactive boards
    var hideAfterDays: Int

    /// Custom title for the board (optional, derived from ID if not set)
    var title: String?

    /// Board description/notes in markdown
    var notes: String?

    /// Custom icon for the board
    var icon: String?

    /// Color for the board in the UI
    var color: String?

    /// Whether this is a built-in system board
    var isBuiltIn: Bool

    /// Whether this board is currently visible in the sidebar
    var isVisible: Bool

    /// Sort order for the board in the sidebar
    var order: Int?

    // MARK: - Initialization

    /// Creates a new board
    /// - Parameters:
    ///   - id: Unique identifier (also used as filename)
    ///   - type: Board type
    ///   - layout: Visual layout mode
    ///   - filter: Filter criteria
    ///   - columns: Column names for kanban layout
    ///   - autoHide: Auto-hide when no active tasks
    ///   - hideAfterDays: Days after which to hide
    ///   - title: Custom title
    ///   - notes: Board description
    ///   - icon: Custom icon
    ///   - color: Board color
    ///   - isBuiltIn: Whether this is a system board
    ///   - isVisible: Whether visible in sidebar
    ///   - order: Sort order
    public init(
        id: String,
        type: BoardType,
        layout: Layout = .freeform,
        filter: Filter = Filter(),
        columns: [String]? = nil,
        autoHide: Bool = false,
        hideAfterDays: Int = 7,
        title: String? = nil,
        notes: String? = nil,
        icon: String? = nil,
        color: String? = nil,
        isBuiltIn: Bool = false,
        isVisible: Bool = true,
        order: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.layout = layout
        self.filter = filter
        self.columns = columns
        self.autoHide = autoHide
        self.hideAfterDays = hideAfterDays
        self.title = title
        self.notes = notes
        self.icon = icon
        self.color = color
        self.isBuiltIn = isBuiltIn
        self.isVisible = isVisible
        self.order = order
    }
}

// MARK: - Computed Properties

extension Board {
    /// Returns the display title for this board
    var displayTitle: String {
        if let customTitle = title {
            return customTitle
        }

        // Derive from ID: "inbox" -> "Inbox", "this-week" -> "This Week"
        return id
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    /// Returns the file path for this board
    var filePath: String {
        return "boards/\(id).md"
    }

    /// Returns the relative path from the project root
    var relativePath: String {
        return filePath
    }

    /// Returns just the filename component
    var fileName: String {
        return "\(id).md"
    }

    /// Returns true if this board requires column definitions
    var requiresColumns: Bool {
        return layout.requiresColumns
    }

    /// Returns true if this board supports custom positioning
    var supportsCustomPositions: Bool {
        return layout.supportsCustomPositions
    }
}

// MARK: - Helper Methods

extension Board {
    /// Returns the column names, or default columns if not set and layout requires them
    var effectiveColumns: [String] {
        if let cols = columns, !cols.isEmpty {
            return cols
        }

        // Return default columns based on board type and layout
        if layout == .kanban {
            return defaultKanbanColumns
        }

        return []
    }

    /// Default kanban columns based on board type
    private var defaultKanbanColumns: [String] {
        switch type {
        case .status:
            return ["Inbox", "Next Actions", "Waiting", "Someday"]
        case .project, .context:
            return ["To Do", "In Progress", "Done"]
        case .custom:
            return ["To Do", "Doing", "Done"]
        }
    }

    /// Determines what metadata should be updated when a task is moved to this board
    /// - Parameter columnName: The column name (for kanban boards)
    /// - Returns: Dictionary of metadata keys to update
    func metadataUpdates(forColumn columnName: String? = nil) -> [String: Any] {
        var updates: [String: Any] = [:]

        switch type {
        case .context:
            // Extract context from filter or ID
            if let ctx = filter.context {
                updates["context"] = ctx
            } else if id.hasPrefix("@") {
                updates["context"] = id
            }

        case .project:
            // Extract project from filter or ID
            if let proj = filter.project {
                updates["project"] = proj
            } else {
                // Use display title as project name
                updates["project"] = displayTitle
            }

        case .status:
            // Map column to status if kanban layout
            if layout == .kanban, let column = columnName {
                if let mappedStatus = statusFromColumn(column) {
                    updates["status"] = mappedStatus.rawValue
                }
            } else if let filterStatus = filter.status {
                updates["status"] = filterStatus.rawValue
            }

        case .custom:
            // Custom boards can define their own update rules
            // For now, just apply any flagged filter
            if let flagged = filter.flagged {
                updates["flagged"] = flagged
            }
        }

        return updates
    }

    /// Maps a column name to a status value
    private func statusFromColumn(_ column: String) -> Status? {
        let normalized = column.lowercased()

        if normalized.contains("inbox") {
            return .inbox
        } else if normalized.contains("next") || normalized.contains("action") || normalized.contains("to do") {
            return .nextAction
        } else if normalized.contains("waiting") || normalized.contains("blocked") {
            return .waiting
        } else if normalized.contains("someday") || normalized.contains("maybe") {
            return .someday
        } else if normalized.contains("done") || normalized.contains("completed") {
            return .completed
        }

        return nil
    }

    /// Returns true if this board should be hidden based on last activity
    /// - Parameter lastActiveDate: The last date this board had active tasks
    /// - Returns: True if the board should be auto-hidden
    func shouldAutoHide(lastActiveDate: Date) -> Bool {
        guard autoHide else { return false }

        let daysSinceActive = Calendar.current.dateComponents([.day], from: lastActiveDate, to: Date()).day ?? 0
        return daysSinceActive >= hideAfterDays
    }
}

// MARK: - Built-in Boards

extension Board {
    /// Creates the Inbox board
    static var inbox: Board {
        Board(
            id: "inbox",
            type: .status,
            layout: .kanban,
            filter: .inbox,
            columns: ["Inbox"],
            icon: "📥",
            color: "blue",
            isBuiltIn: true,
            order: 0
        )
    }

    /// Creates the Next Actions board
    static var nextActions: Board {
        Board(
            id: "next-actions",
            type: .status,
            layout: .kanban,
            filter: .nextActions,
            columns: ["Next Actions"],
            icon: "▶️",
            color: "green",
            isBuiltIn: true,
            order: 1
        )
    }

    /// Creates the Flagged board
    static var flagged: Board {
        Board(
            id: "flagged",
            type: .custom,
            layout: .grid,
            filter: .flagged,
            icon: "⭐",
            color: "yellow",
            isBuiltIn: true,
            order: 2
        )
    }

    /// Creates the Waiting For board
    static var waitingFor: Board {
        Board(
            id: "waiting-for",
            type: .status,
            layout: .kanban,
            filter: .waiting,
            columns: ["Waiting For"],
            icon: "⏳",
            color: "orange",
            isBuiltIn: true,
            order: 3
        )
    }

    /// Creates the Someday/Maybe board
    static var someday: Board {
        Board(
            id: "someday-maybe",
            type: .status,
            layout: .grid,
            filter: .someday,
            icon: "💭",
            color: "purple",
            isBuiltIn: true,
            order: 4
        )
    }

    /// Creates the Due Today board
    static var dueToday: Board {
        Board(
            id: "due-today",
            type: .custom,
            layout: .grid,
            filter: .dueToday,
            icon: "📅",
            color: "red",
            isBuiltIn: true,
            order: 5
        )
    }

    /// Creates the Due This Week board
    static var dueThisWeek: Board {
        Board(
            id: "due-this-week",
            type: .custom,
            layout: .grid,
            filter: .dueThisWeek,
            icon: "📆",
            color: "orange",
            isBuiltIn: true,
            order: 6
        )
    }

    /// Creates a context board
    static func contextBoard(for context: Context) -> Board {
        Board(
            id: context.name,
            type: .context,
            layout: .kanban,
            filter: Filter(context: context.name),
            columns: ["To Do", "In Progress", "Done"],
            icon: context.icon,
            color: context.color,
            isBuiltIn: false
        )
    }

    /// Creates a project board
    static func projectBoard(name: String, projectName: String? = nil) -> Board {
        Board(
            id: name.slugified(),
            type: .project,
            layout: .kanban,
            filter: Filter(project: projectName ?? name),
            columns: ["To Do", "In Progress", "Done"],
            autoHide: true,
            hideAfterDays: 7,
            title: name,
            icon: "📁",
            color: "blue",
            isBuiltIn: false
        )
    }

    /// Returns all built-in boards
    static var builtInBoards: [Board] {
        return [
            .inbox,
            .nextActions,
            .flagged,
            .waitingFor,
            .someday,
            .dueToday,
            .dueThisWeek
        ]
    }
}

// MARK: - String Extensions

fileprivate extension String {
    /// Converts a string to a URL-safe slug
    func slugified() -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let slug = self
            .lowercased()
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return slug.isEmpty ? "untitled" : slug
    }
}
