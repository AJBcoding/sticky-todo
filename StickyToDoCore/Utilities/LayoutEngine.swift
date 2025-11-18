//
//  LayoutEngine.swift
//  StickyToDoCore
//
//  Shared layout logic for auto-positioning tasks in Kanban and Grid layouts.
//  Provides column assignment, grid positioning, and metadata extraction.
//

import Foundation

/// Layout engine providing shared logic for task positioning and organization
///
/// Used by both AppKit and SwiftUI implementations of Kanban and Grid layouts.
/// Handles auto-positioning, column assignment, section organization, and collision detection.
public class LayoutEngine {

    // MARK: - Constants

    /// Default column width for kanban boards
    public static let defaultColumnWidth: Double = 280

    /// Default spacing between columns
    public static let columnSpacing: Double = 20

    /// Default task card height
    public static let defaultCardHeight: Double = 120

    /// Vertical spacing between cards
    public static let cardSpacing: Double = 12

    /// Padding within columns
    public static let columnPadding: Double = 16

    /// Grid cell size for grid layout
    public static let gridCellWidth: Double = 240
    public static let gridCellHeight: Double = 140

    /// Grid spacing
    public static let gridSpacing: Double = 16

    // MARK: - Kanban Layout

    /// Calculates positions for tasks in a kanban column layout
    /// - Parameters:
    ///   - tasks: Tasks to position
    ///   - columns: Column names
    ///   - columnAssigner: Function to determine which column a task belongs to
    /// - Returns: Dictionary mapping task IDs to positions
    public static func calculateKanbanPositions(
        tasks: [Task],
        columns: [String],
        columnAssigner: (Task) -> String?
    ) -> [UUID: Position] {
        var positions: [UUID: Position] = [:]

        // Group tasks by column
        var tasksByColumn: [String: [Task]] = [:]
        for column in columns {
            tasksByColumn[column] = []
        }

        for task in tasks {
            if let column = columnAssigner(task) {
                tasksByColumn[column]?.append(task)
            } else {
                // Default to first column if no assignment
                tasksByColumn[columns.first ?? ""]?.append(task)
            }
        }

        // Calculate positions for each column
        for (columnIndex, column) in columns.enumerated() {
            guard let columnTasks = tasksByColumn[column] else { continue }

            let columnX = Double(columnIndex) * (defaultColumnWidth + columnSpacing) + columnPadding
            var currentY = columnPadding + 60 // Offset for column header

            for task in columnTasks {
                positions[task.id] = Position(x: columnX, y: currentY)
                currentY += defaultCardHeight + cardSpacing
            }
        }

        return positions
    }

    /// Determines which column a task belongs to based on board metadata
    /// - Parameters:
    ///   - task: The task to evaluate
    ///   - board: The board configuration
    /// - Returns: Column name, or nil if no match
    public static func assignTaskToColumn(task: Task, board: Board) -> String? {
        let columns = board.effectiveColumns
        guard !columns.isEmpty else { return nil }

        switch board.type {
        case .status:
            // Map task status to column
            return mapStatusToColumn(status: task.status, columns: columns)

        case .project:
            // Simple three-column layout: To Do, In Progress, Done
            if task.status == .completed {
                return columns.last // "Done"
            } else if task.status == .nextAction {
                return columns.count > 1 ? columns[1] : columns.first // "In Progress"
            } else {
                return columns.first // "To Do"
            }

        case .context:
            // Simple three-column layout
            if task.status == .completed {
                return columns.last
            } else if task.status == .nextAction {
                return columns.count > 1 ? columns[1] : columns.first
            } else {
                return columns.first
            }

        case .custom:
            // Simple mapping for custom boards
            if task.status == .completed {
                return columns.last
            } else if task.status == .nextAction {
                return columns.count > 2 ? columns[1] : columns.first
            } else {
                return columns.first
            }
        }
    }

    /// Maps a task status to a column name
    private static func mapStatusToColumn(status: Status, columns: [String]) -> String? {
        for column in columns {
            let normalized = column.lowercased()

            switch status {
            case .inbox:
                if normalized.contains("inbox") {
                    return column
                }
            case .nextAction:
                if normalized.contains("next") || normalized.contains("action") ||
                   normalized.contains("to do") || normalized.contains("todo") {
                    return column
                }
            case .waiting:
                if normalized.contains("waiting") || normalized.contains("blocked") {
                    return column
                }
            case .someday:
                if normalized.contains("someday") || normalized.contains("maybe") {
                    return column
                }
            case .completed:
                if normalized.contains("done") || normalized.contains("completed") {
                    return column
                }
            }
        }

        // Default to first column if no match
        return columns.first
    }

    /// Calculates which column a point belongs to in kanban layout
    /// - Parameters:
    ///   - point: The point to test
    ///   - columnCount: Number of columns
    /// - Returns: Column index, or nil if outside bounds
    public static func columnIndex(for point: Position, columnCount: Int) -> Int? {
        let totalWidth = defaultColumnWidth + columnSpacing
        let index = Int(point.x / totalWidth)

        if index >= 0 && index < columnCount {
            return index
        }
        return nil
    }

    // MARK: - Grid Layout

    /// Section definition for grid layout
    public struct GridSection {
        public let id: String
        public let title: String
        public let filter: (Task) -> Bool

        public init(id: String, title: String, filter: @escaping (Task) -> Bool) {
            self.id = id
            self.title = title
            self.filter = filter
        }
    }

    /// Default grid sections based on priority
    public static func defaultPrioritySections() -> [GridSection] {
        return [
            GridSection(id: "high", title: "High Priority") { $0.priority == .high },
            GridSection(id: "medium", title: "Medium Priority") { $0.priority == .medium },
            GridSection(id: "low", title: "Low Priority") { $0.priority == .low }
        ]
    }

    /// Default grid sections based on status
    public static func defaultStatusSections() -> [GridSection] {
        return [
            GridSection(id: "inbox", title: "Inbox") { $0.status == .inbox },
            GridSection(id: "next", title: "Next Actions") { $0.status == .nextAction },
            GridSection(id: "waiting", title: "Waiting") { $0.status == .waiting },
            GridSection(id: "someday", title: "Someday/Maybe") { $0.status == .someday }
        ]
    }

    /// Default grid sections based on time
    public static func defaultTimeSections() -> [GridSection] {
        return [
            GridSection(id: "overdue", title: "Overdue") { $0.isOverdue },
            GridSection(id: "today", title: "Due Today") { $0.isDueToday },
            GridSection(id: "week", title: "This Week") { $0.isDueThisWeek },
            GridSection(id: "later", title: "Later") { task in
                !task.isOverdue && !task.isDueToday && !task.isDueThisWeek && task.due != nil
            }
        ]
    }

    /// Calculates grid sections based on board type
    /// - Parameter board: The board configuration
    /// - Returns: Array of grid sections
    public static func sectionsForBoard(_ board: Board) -> [GridSection] {
        // For grid layout, organize by priority by default
        // Can be customized based on board type
        switch board.type {
        case .status:
            return defaultStatusSections()
        case .custom:
            // Check if this is a time-based board
            if board.id.contains("due") || board.id.contains("today") || board.id.contains("week") {
                return defaultTimeSections()
            }
            return defaultPrioritySections()
        default:
            return defaultPrioritySections()
        }
    }

    /// Calculates positions for tasks in a grid layout with sections
    /// - Parameters:
    ///   - tasks: Tasks to position
    ///   - sections: Grid sections
    ///   - columnsPerRow: Number of columns per row
    /// - Returns: Dictionary mapping task IDs to positions
    public static func calculateGridPositions(
        tasks: [Task],
        sections: [GridSection],
        columnsPerRow: Int = 3
    ) -> [UUID: Position] {
        var positions: [UUID: Position] = [:]

        var currentY: Double = gridSpacing

        for section in sections {
            let sectionTasks = tasks.filter(section.filter)

            if sectionTasks.isEmpty {
                continue
            }

            // Reserve space for section header
            currentY += 40

            // Layout tasks in grid
            var column = 0
            var rowY = currentY

            for task in sectionTasks {
                let x = Double(column) * (gridCellWidth + gridSpacing) + gridSpacing
                positions[task.id] = Position(x: x, y: rowY)

                column += 1
                if column >= columnsPerRow {
                    column = 0
                    rowY += gridCellHeight + gridSpacing
                }
            }

            // Move to next section
            let rows = (sectionTasks.count + columnsPerRow - 1) / columnsPerRow
            currentY = rowY + (column > 0 ? gridCellHeight + gridSpacing : 0)
            currentY += 20 // Section spacing
        }

        return positions
    }

    /// Determines which section a point belongs to
    /// - Parameters:
    ///   - point: The point to test
    ///   - sections: Grid sections
    ///   - tasks: Tasks in the grid
    ///   - columnsPerRow: Number of columns per row
    /// - Returns: Section ID, or nil if outside bounds
    public static func sectionId(
        for point: Position,
        sections: [GridSection],
        tasks: [Task],
        columnsPerRow: Int = 3
    ) -> String? {
        var currentY: Double = gridSpacing

        for section in sections {
            let sectionTasks = tasks.filter(section.filter)

            if sectionTasks.isEmpty {
                continue
            }

            currentY += 40 // Header height

            let rows = (sectionTasks.count + columnsPerRow - 1) / columnsPerRow
            let sectionHeight = Double(rows) * (gridCellHeight + gridSpacing)

            if point.y >= currentY && point.y < currentY + sectionHeight {
                return section.id
            }

            currentY += sectionHeight + 20 // Section spacing
        }

        return nil
    }

    // MARK: - Collision Detection

    /// Checks if two task positions collide
    /// - Parameters:
    ///   - pos1: First position
    ///   - pos2: Second position
    ///   - cardWidth: Width of task card
    ///   - cardHeight: Height of task card
    /// - Returns: True if positions overlap
    public static func positionsCollide(
        _ pos1: Position,
        _ pos2: Position,
        cardWidth: Double = defaultColumnWidth,
        cardHeight: Double = defaultCardHeight
    ) -> Bool {
        let rect1 = CGRect(x: pos1.x, y: pos1.y, width: cardWidth, height: cardHeight)
        let rect2 = CGRect(x: pos2.x, y: pos2.y, width: cardWidth, height: cardHeight)
        return rect1.intersects(rect2)
    }

    /// Finds an empty position near the given position
    /// - Parameters:
    ///   - nearPosition: Preferred position
    ///   - existingPositions: Positions already occupied
    ///   - cardWidth: Width of task card
    ///   - cardHeight: Height of task card
    /// - Returns: A position that doesn't collide with existing ones
    public static func findEmptyPosition(
        near nearPosition: Position,
        avoiding existingPositions: [Position],
        cardWidth: Double = defaultColumnWidth,
        cardHeight: Double = defaultCardHeight
    ) -> Position {
        var testPosition = nearPosition
        let offsets: [(Double, Double)] = [
            (0, 0),
            (0, cardHeight + cardSpacing),
            (0, -(cardHeight + cardSpacing)),
            (cardWidth + columnSpacing, 0),
            (-(cardWidth + columnSpacing), 0)
        ]

        for (dx, dy) in offsets {
            testPosition = Position(x: nearPosition.x + dx, y: nearPosition.y + dy)

            var hasCollision = false
            for existingPos in existingPositions {
                if positionsCollide(testPosition, existingPos, cardWidth: cardWidth, cardHeight: cardHeight) {
                    hasCollision = true
                    break
                }
            }

            if !hasCollision {
                return testPosition
            }
        }

        // If still no empty spot, just offset downward
        return Position(x: nearPosition.x, y: nearPosition.y + cardHeight + cardSpacing)
    }

    // MARK: - Metadata Updates

    /// Determines metadata updates when moving a task to a column
    /// - Parameters:
    ///   - task: The task being moved
    ///   - column: The target column name
    ///   - board: The board configuration
    /// - Returns: Dictionary of metadata updates
    public static func metadataUpdates(
        forTask task: Task,
        inColumn column: String,
        onBoard board: Board
    ) -> [String: Any] {
        var updates = board.metadataUpdates(forColumn: column)

        // Auto-complete when moving to "Done" column
        let normalizedColumn = column.lowercased()
        if normalizedColumn.contains("done") || normalizedColumn.contains("completed") {
            updates["status"] = Status.completed.rawValue
        }

        // Set to next-action when moving to "In Progress" or "Doing"
        if normalizedColumn.contains("progress") || normalizedColumn.contains("doing") {
            updates["status"] = Status.nextAction.rawValue
        }

        return updates
    }

    /// Determines metadata updates when moving a task to a grid section
    /// - Parameters:
    ///   - task: The task being moved
    ///   - sectionId: The target section ID
    ///   - sections: Available sections
    /// - Returns: Dictionary of metadata updates
    public static func metadataUpdates(
        forTask task: Task,
        inSection sectionId: String,
        sections: [GridSection]
    ) -> [String: Any] {
        var updates: [String: Any] = [:]

        // Update based on section type
        if let priority = Priority(rawValue: sectionId) {
            updates["priority"] = priority.rawValue
        }

        if let status = Status(rawValue: sectionId) {
            updates["status"] = status.rawValue
        }

        return updates
    }
}
