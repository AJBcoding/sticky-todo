//
//  LayoutEngineTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for LayoutEngine covering kanban layout, grid layout,
//  column assignment, positioning, and collision detection.
//

import XCTest
@testable import StickyToDoCore

final class LayoutEngineTests: XCTestCase {

    var testTasks: [Task]!
    var testBoard: Board!

    override func setUpWithError() throws {
        testTasks = [
            Task(title: "Inbox Task", status: .inbox, priority: .high),
            Task(title: "Next Action", status: .nextAction, priority: .medium),
            Task(title: "Waiting Task", status: .waiting, priority: .low),
            Task(title: "Someday Task", status: .someday, priority: .medium),
            Task(title: "Completed Task", status: .completed, priority: .low)
        ]

        testBoard = Board(
            id: UUID(),
            name: "Test Board",
            type: .status,
            layout: .kanban,
            filter: Filter()
        )
    }

    override func tearDownWithError() throws {
        testTasks = nil
        testBoard = nil
    }

    // MARK: - Constants Tests

    func testDefaultConstants() {
        XCTAssertEqual(LayoutEngine.defaultColumnWidth, 280)
        XCTAssertEqual(LayoutEngine.columnSpacing, 20)
        XCTAssertEqual(LayoutEngine.defaultCardHeight, 120)
        XCTAssertEqual(LayoutEngine.cardSpacing, 12)
        XCTAssertEqual(LayoutEngine.columnPadding, 16)
        XCTAssertEqual(LayoutEngine.gridCellWidth, 240)
        XCTAssertEqual(LayoutEngine.gridCellHeight, 140)
        XCTAssertEqual(LayoutEngine.gridSpacing, 16)
    }

    // MARK: - Kanban Position Calculation Tests

    func testCalculateKanbanPositions() {
        let columns = ["Inbox", "Next Actions", "Waiting", "Done"]

        let positions = LayoutEngine.calculateKanbanPositions(
            tasks: testTasks,
            columns: columns
        ) { task in
            switch task.status {
            case .inbox: return "Inbox"
            case .nextAction: return "Next Actions"
            case .waiting: return "Waiting"
            case .completed: return "Done"
            default: return "Inbox"
            }
        }

        XCTAssertEqual(positions.count, testTasks.count)

        // All tasks should have positions
        for task in testTasks {
            XCTAssertNotNil(positions[task.id])
        }
    }

    func testKanbanPositionsInDifferentColumns() {
        let columns = ["Column 1", "Column 2"]

        let positions = LayoutEngine.calculateKanbanPositions(
            tasks: testTasks,
            columns: columns
        ) { task in
            task.priority == .high ? "Column 1" : "Column 2"
        }

        // Check that high priority tasks are in column 1 (x = padding)
        let highPriorityTask = testTasks.first { $0.priority == .high }!
        let pos = positions[highPriorityTask.id]!

        XCTAssertEqual(pos.x, LayoutEngine.columnPadding)
    }

    func testKanbanPositionsVerticalSpacing() {
        let columns = ["Single Column"]

        let positions = LayoutEngine.calculateKanbanPositions(
            tasks: testTasks,
            columns: columns
        ) { _ in "Single Column" }

        // Convert to array and sort by Y position
        let sortedPositions = positions.values.sorted { $0.y < $1.y }

        // Check vertical spacing
        for i in 1..<sortedPositions.count {
            let diff = sortedPositions[i].y - sortedPositions[i-1].y
            XCTAssertGreaterThanOrEqual(diff, LayoutEngine.defaultCardHeight + LayoutEngine.cardSpacing)
        }
    }

    // MARK: - Task Column Assignment Tests

    func testAssignTaskToStatusBoard() {
        let statusBoard = Board(
            id: UUID(),
            name: "Status Board",
            type: .status,
            layout: .kanban,
            filter: Filter()
        )

        let inboxTask = Task(title: "Test", status: .inbox)
        let column = LayoutEngine.assignTaskToColumn(task: inboxTask, board: statusBoard)

        XCTAssertNotNil(column)
    }

    func testAssignTaskToProjectBoard() {
        let projectBoard = Board(
            id: UUID(),
            name: "Project Board",
            type: .project,
            layout: .kanban,
            filter: Filter()
        )

        let completedTask = Task(title: "Test", status: .completed)
        let column = LayoutEngine.assignTaskToColumn(task: completedTask, board: projectBoard)

        // Completed tasks go to last column
        XCTAssertNotNil(column)
    }

    func testAssignTaskWithNoColumns() {
        var emptyBoard = testBoard
        emptyBoard.columns = []

        let task = Task(title: "Test", status: .inbox)
        let column = LayoutEngine.assignTaskToColumn(task: task, board: emptyBoard)

        XCTAssertNil(column)
    }

    // MARK: - Column Index Calculation Tests

    func testColumnIndexForPoint() {
        let point = Position(x: 150, y: 100)

        let columnIndex = LayoutEngine.columnIndex(for: point, columnCount: 5)

        XCTAssertNotNil(columnIndex)
        XCTAssertEqual(columnIndex, 0)
    }

    func testColumnIndexForSecondColumn() {
        let totalWidth = LayoutEngine.defaultColumnWidth + LayoutEngine.columnSpacing
        let point = Position(x: totalWidth + 10, y: 100)

        let columnIndex = LayoutEngine.columnIndex(for: point, columnCount: 5)

        XCTAssertEqual(columnIndex, 1)
    }

    func testColumnIndexOutOfBounds() {
        let farPoint = Position(x: 10000, y: 100)

        let columnIndex = LayoutEngine.columnIndex(for: farPoint, columnCount: 3)

        XCTAssertNil(columnIndex)
    }

    func testColumnIndexNegativePosition() {
        let negativePoint = Position(x: -100, y: 100)

        let columnIndex = LayoutEngine.columnIndex(for: negativePoint, columnCount: 3)

        XCTAssertNil(columnIndex)
    }

    // MARK: - Grid Section Tests

    func testDefaultPrioritySections() {
        let sections = LayoutEngine.defaultPrioritySections()

        XCTAssertEqual(sections.count, 3)
        XCTAssertEqual(sections[0].id, "high")
        XCTAssertEqual(sections[1].id, "medium")
        XCTAssertEqual(sections[2].id, "low")
    }

    func testDefaultStatusSections() {
        let sections = LayoutEngine.defaultStatusSections()

        XCTAssertEqual(sections.count, 4)
        XCTAssertTrue(sections.contains { $0.id == "inbox" })
        XCTAssertTrue(sections.contains { $0.id == "next" })
        XCTAssertTrue(sections.contains { $0.id == "waiting" })
        XCTAssertTrue(sections.contains { $0.id == "someday" })
    }

    func testDefaultTimeSections() {
        let sections = LayoutEngine.defaultTimeSections()

        XCTAssertEqual(sections.count, 4)
        XCTAssertTrue(sections.contains { $0.id == "overdue" })
        XCTAssertTrue(sections.contains { $0.id == "today" })
        XCTAssertTrue(sections.contains { $0.id == "week" })
        XCTAssertTrue(sections.contains { $0.id == "later" })
    }

    func testSectionFilters() {
        let sections = LayoutEngine.defaultPrioritySections()

        let highPriorityTask = Task(title: "High", priority: .high)
        let mediumPriorityTask = Task(title: "Medium", priority: .medium)

        XCTAssertTrue(sections[0].filter(highPriorityTask))
        XCTAssertFalse(sections[0].filter(mediumPriorityTask))
    }

    // MARK: - Grid Position Calculation Tests

    func testCalculateGridPositions() {
        let sections = LayoutEngine.defaultPrioritySections()

        let positions = LayoutEngine.calculateGridPositions(
            tasks: testTasks,
            sections: sections,
            columnsPerRow: 3
        )

        XCTAssertTrue(positions.count <= testTasks.count)

        // All positions should be non-negative
        for position in positions.values {
            XCTAssertGreaterThanOrEqual(position.x, 0)
            XCTAssertGreaterThanOrEqual(position.y, 0)
        }
    }

    func testGridPositionsWithMultipleColumns() {
        let sections = LayoutEngine.defaultPrioritySections()

        let positions = LayoutEngine.calculateGridPositions(
            tasks: testTasks,
            sections: sections,
            columnsPerRow: 2
        )

        // Verify horizontal spacing
        let sameRowPositions = positions.values.filter { $0.y < 200 }.sorted { $0.x < $1.x }

        if sameRowPositions.count >= 2 {
            let xDiff = sameRowPositions[1].x - sameRowPositions[0].x
            XCTAssertGreaterThanOrEqual(xDiff, LayoutEngine.gridCellWidth + LayoutEngine.gridSpacing)
        }
    }

    func testGridPositionsEmptySection() {
        let sections = [
            LayoutEngine.GridSection(id: "empty", title: "Empty") { _ in false }
        ]

        let positions = LayoutEngine.calculateGridPositions(
            tasks: testTasks,
            sections: sections,
            columnsPerRow: 3
        )

        XCTAssertEqual(positions.count, 0)
    }

    // MARK: - Section ID Detection Tests

    func testSectionIdForPoint() {
        let sections = LayoutEngine.defaultPrioritySections()

        // Point near the top should be in first section
        let point = Position(x: 100, y: 60)

        let sectionId = LayoutEngine.sectionId(
            for: point,
            sections: sections,
            tasks: testTasks,
            columnsPerRow: 3
        )

        XCTAssertNotNil(sectionId)
    }

    func testSectionIdForOutOfBoundsPoint() {
        let sections = LayoutEngine.defaultPrioritySections()

        let farPoint = Position(x: 1000, y: 10000)

        let sectionId = LayoutEngine.sectionId(
            for: farPoint,
            sections: sections,
            tasks: testTasks,
            columnsPerRow: 3
        )

        XCTAssertNil(sectionId)
    }

    // MARK: - Collision Detection Tests

    func testPositionsCollide() {
        let pos1 = Position(x: 100, y: 100)
        let pos2 = Position(x: 110, y: 110)

        let collides = LayoutEngine.positionsCollide(pos1, pos2)

        XCTAssertTrue(collides)
    }

    func testPositionsDoNotCollide() {
        let pos1 = Position(x: 100, y: 100)
        let pos2 = Position(x: 500, y: 500)

        let collides = LayoutEngine.positionsCollide(pos1, pos2)

        XCTAssertFalse(collides)
    }

    func testPositionsCollideBoundary() {
        let pos1 = Position(x: 0, y: 0)
        let pos2 = Position(
            x: LayoutEngine.defaultColumnWidth,
            y: 0
        )

        let collides = LayoutEngine.positionsCollide(pos1, pos2)

        XCTAssertFalse(collides) // Should not collide at exact boundary
    }

    // MARK: - Find Empty Position Tests

    func testFindEmptyPositionWithNoCollisions() {
        let desired = Position(x: 100, y: 100)
        let existing: [Position] = []

        let empty = LayoutEngine.findEmptyPosition(
            near: desired,
            avoiding: existing
        )

        XCTAssertEqual(empty.x, desired.x)
        XCTAssertEqual(empty.y, desired.y)
    }

    func testFindEmptyPositionWithCollision() {
        let desired = Position(x: 100, y: 100)
        let existing = [Position(x: 100, y: 100)]

        let empty = LayoutEngine.findEmptyPosition(
            near: desired,
            avoiding: existing
        )

        // Should find alternative position
        XCTAssertTrue(empty.x != desired.x || empty.y != desired.y)
    }

    func testFindEmptyPositionWithMultipleCollisions() {
        let desired = Position(x: 100, y: 100)
        let existing = [
            Position(x: 100, y: 100),
            Position(x: 100, y: 100 + LayoutEngine.defaultCardHeight + LayoutEngine.cardSpacing)
        ]

        let empty = LayoutEngine.findEmptyPosition(
            near: desired,
            avoiding: existing
        )

        // Should find alternative position
        XCTAssertTrue(empty.x != desired.x || empty.y != desired.y)
    }

    // MARK: - Metadata Updates Tests

    func testMetadataUpdatesForDoneColumn() {
        let task = Task(title: "Test", status: .nextAction)

        let updates = LayoutEngine.metadataUpdates(
            forTask: task,
            inColumn: "Done",
            onBoard: testBoard
        )

        if let status = updates["status"] as? String {
            XCTAssertEqual(status, Status.completed.rawValue)
        }
    }

    func testMetadataUpdatesForInProgressColumn() {
        let task = Task(title: "Test", status: .inbox)

        let updates = LayoutEngine.metadataUpdates(
            forTask: task,
            inColumn: "In Progress",
            onBoard: testBoard
        )

        if let status = updates["status"] as? String {
            XCTAssertEqual(status, Status.nextAction.rawValue)
        }
    }

    func testMetadataUpdatesForGridSection() {
        let task = Task(title: "Test", priority: .medium)
        let sections = LayoutEngine.defaultPrioritySections()

        let updates = LayoutEngine.metadataUpdates(
            forTask: task,
            inSection: "high",
            sections: sections
        )

        if let priority = updates["priority"] as? String {
            XCTAssertEqual(priority, Priority.high.rawValue)
        }
    }

    // MARK: - Edge Cases

    func testEmptyTaskList() {
        let columns = ["Column 1", "Column 2"]

        let positions = LayoutEngine.calculateKanbanPositions(
            tasks: [],
            columns: columns
        ) { _ in "Column 1" }

        XCTAssertEqual(positions.count, 0)
    }

    func testSingleTask() {
        let task = Task(title: "Single", status: .inbox)
        let columns = ["Inbox"]

        let positions = LayoutEngine.calculateKanbanPositions(
            tasks: [task],
            columns: columns
        ) { _ in "Inbox" }

        XCTAssertEqual(positions.count, 1)
        XCTAssertNotNil(positions[task.id])
    }

    func testManyTasksInOneColumn() {
        let manyTasks = (0..<100).map { Task(title: "Task \($0)", status: .inbox) }
        let columns = ["Inbox"]

        let positions = LayoutEngine.calculateKanbanPositions(
            tasks: manyTasks,
            columns: columns
        ) { _ in "Inbox" }

        XCTAssertEqual(positions.count, 100)

        // Check vertical distribution
        let yPositions = positions.values.map { $0.y }.sorted()
        for i in 1..<yPositions.count {
            XCTAssertGreaterThan(yPositions[i], yPositions[i-1])
        }
    }

    // MARK: - Performance Tests

    func testKanbanPositionCalculationPerformance() {
        let largeTasks = (0..<1000).map { Task(title: "Task \($0)", status: .inbox) }
        let columns = ["Column 1", "Column 2", "Column 3"]

        measure {
            _ = LayoutEngine.calculateKanbanPositions(
                tasks: largeTasks,
                columns: columns
            ) { task in
                columns[Int(task.title.split(separator: " ")[1])! % columns.count]
            }
        }
    }

    func testGridPositionCalculationPerformance() {
        let largeTasks = (0..<1000).map { Task(title: "Task \($0)", priority: .medium) }
        let sections = LayoutEngine.defaultPrioritySections()

        measure {
            _ = LayoutEngine.calculateGridPositions(
                tasks: largeTasks,
                sections: sections,
                columnsPerRow: 3
            )
        }
    }

    func testCollisionDetectionPerformance() {
        let positions = (0..<1000).map { Position(x: Double($0), y: Double($0)) }

        measure {
            for i in 0..<100 {
                _ = LayoutEngine.findEmptyPosition(
                    near: Position(x: 50, y: 50),
                    avoiding: Array(positions[0..<min(i+1, positions.count)])
                )
            }
        }
    }
}
