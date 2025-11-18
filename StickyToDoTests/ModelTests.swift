//
//  ModelTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for all model objects.
//

import XCTest
@testable import StickyToDo

final class ModelTests: XCTestCase {

    // MARK: - Task Tests

    func testTaskCreation() {
        let task = Task(title: "Test Task")

        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.type, .task)
        XCTAssertEqual(task.status, .inbox)
        XCTAssertEqual(task.notes, "")
        XCTAssertNil(task.project)
        XCTAssertNil(task.context)
        XCTAssertNil(task.due)
        XCTAssertNil(task.defer)
        XCTAssertFalse(task.flagged)
        XCTAssertEqual(task.priority, .medium)
        XCTAssertNil(task.effort)
        XCTAssertTrue(task.positions.isEmpty)
    }

    func testTaskWithAllProperties() {
        let dueDate = Date()
        let deferDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate)!

        let task = Task(
            type: .task,
            title: "Complete Task",
            notes: "Detailed notes",
            status: .nextAction,
            project: "TestProject",
            context: "@office",
            due: dueDate,
            defer: deferDate,
            flagged: true,
            priority: .high,
            effort: 60
        )

        XCTAssertEqual(task.type, .task)
        XCTAssertEqual(task.title, "Complete Task")
        XCTAssertEqual(task.notes, "Detailed notes")
        XCTAssertEqual(task.status, .nextAction)
        XCTAssertEqual(task.project, "TestProject")
        XCTAssertEqual(task.context, "@office")
        XCTAssertEqual(task.due, dueDate)
        XCTAssertEqual(task.defer, deferDate)
        XCTAssertTrue(task.flagged)
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.effort, 60)
    }

    func testTaskFilePath() {
        let calendar = Calendar.current
        let created = Date()
        let year = calendar.component(.year, from: created)
        let month = calendar.component(.month, from: created)
        let monthString = String(format: "%02d", month)

        let task = Task(title: "Test Task", created: created)
        let filePath = task.filePath

        XCTAssertTrue(filePath.hasPrefix("tasks/active/\(year)/\(monthString)/"))
        XCTAssertTrue(filePath.hasSuffix(".md"))
        XCTAssertTrue(filePath.contains(task.id.uuidString))
    }

    func testCompletedTaskFilePath() {
        let task = Task(title: "Done Task", status: .completed)
        let filePath = task.filePath

        XCTAssertTrue(filePath.hasPrefix("tasks/archive/"))
    }

    func testTaskSlugification() {
        let task1 = Task(title: "Simple Task")
        XCTAssertTrue(task1.fileName.contains("simple-task"))

        let task2 = Task(title: "Task with Special Ch@racters!!")
        XCTAssertTrue(task2.fileName.contains("task-with-special-ch-racters"))

        let task3 = Task(title: "Very Long Task Title That Should Be Truncated At Some Point Because It Exceeds The Maximum Length Allowed")
        let slug = task3.fileName
        XCTAssertLessThan(slug.count, 100) // Should be truncated
    }

    func testTaskDueStatus() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: now)!
        let farFuture = Calendar.current.date(byAdding: .month, value: 1, to: now)!

        let overdueTask = Task(title: "Overdue", due: yesterday)
        XCTAssertTrue(overdueTask.isOverdue)
        XCTAssertFalse(overdueTask.isDueToday)
        XCTAssertFalse(overdueTask.isDueThisWeek)

        let todayTask = Task(title: "Today", due: now)
        XCTAssertFalse(todayTask.isOverdue)
        XCTAssertTrue(todayTask.isDueToday)
        XCTAssertTrue(todayTask.isDueThisWeek)

        let tomorrowTask = Task(title: "Tomorrow", due: tomorrow)
        XCTAssertFalse(tomorrowTask.isOverdue)
        XCTAssertFalse(tomorrowTask.isDueToday)
        XCTAssertTrue(tomorrowTask.isDueThisWeek)

        let nextWeekTask = Task(title: "Next Week", due: nextWeek)
        XCTAssertFalse(nextWeekTask.isOverdue)
        XCTAssertFalse(nextWeekTask.isDueToday)
        XCTAssertTrue(nextWeekTask.isDueThisWeek)

        let futureTask = Task(title: "Future", due: farFuture)
        XCTAssertFalse(futureTask.isOverdue)
        XCTAssertFalse(futureTask.isDueToday)
        XCTAssertFalse(futureTask.isDueThisWeek)
    }

    func testTaskDeferredStatus() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        let notDeferredTask = Task(title: "Not Deferred")
        XCTAssertFalse(notDeferredTask.isDeferred)

        let pastDeferTask = Task(title: "Past Defer", defer: yesterday)
        XCTAssertFalse(pastDeferTask.isDeferred)

        let futureDeferTask = Task(title: "Future Defer", defer: tomorrow)
        XCTAssertTrue(futureDeferTask.isDeferred)
    }

    func testTaskVisibility() {
        let visibleTask = Task(title: "Visible", status: .nextAction)
        XCTAssertTrue(visibleTask.isVisible)

        let completedTask = Task(title: "Completed", status: .completed)
        XCTAssertFalse(completedTask.isVisible)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let deferredTask = Task(title: "Deferred", defer: tomorrow)
        XCTAssertFalse(deferredTask.isVisible)
    }

    func testTaskActionable() {
        let actionableTask = Task(title: "Actionable", status: .nextAction)
        XCTAssertTrue(actionableTask.isActionable)

        let inboxTask = Task(title: "Inbox", status: .inbox)
        XCTAssertFalse(inboxTask.isActionable)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let deferredActionTask = Task(title: "Deferred Action", status: .nextAction, defer: tomorrow)
        XCTAssertFalse(deferredActionTask.isActionable)
    }

    func testTaskEffortDescription() {
        let task30m = Task(title: "30 min", effort: 30)
        XCTAssertEqual(task30m.effortDescription, "30m")

        let task1h = Task(title: "1 hour", effort: 60)
        XCTAssertEqual(task1h.effortDescription, "1h")

        let task90m = Task(title: "90 min", effort: 90)
        XCTAssertEqual(task90m.effortDescription, "1h 30m")

        let taskNoEffort = Task(title: "No effort")
        XCTAssertNil(taskNoEffort.effortDescription)
    }

    func testTaskPositionManagement() {
        var task = Task(title: "Positioned Task")

        // Test adding position
        let pos1 = Position(x: 100, y: 200)
        task.setPosition(pos1, for: "board-1")
        XCTAssertEqual(task.position(for: "board-1"), pos1)
        XCTAssertTrue(task.isPositioned(on: "board-1"))
        XCTAssertFalse(task.isPositioned(on: "board-2"))

        // Test adding another position
        let pos2 = Position(x: 300, y: 400)
        task.setPosition(pos2, for: "board-2")
        XCTAssertEqual(task.position(for: "board-2"), pos2)
        XCTAssertEqual(task.positions.count, 2)

        // Test removing position
        task.removePosition(for: "board-1")
        XCTAssertNil(task.position(for: "board-1"))
        XCTAssertFalse(task.isPositioned(on: "board-1"))
        XCTAssertEqual(task.positions.count, 1)
    }

    func testTaskStatusTransitions() {
        var task = Task(title: "Status Test", status: .nextAction)

        // Test complete
        task.complete()
        XCTAssertEqual(task.status, .completed)

        // Test reopen
        task.reopen()
        XCTAssertEqual(task.status, .nextAction)

        // Test reopen from non-completed (should have no effect)
        task.status = .inbox
        task.reopen()
        XCTAssertEqual(task.status, .inbox)
    }

    func testTaskTypeTransitions() {
        var note = Task(type: .note, title: "Note", status: .inbox)

        // Test promote to task
        note.promoteToTask()
        XCTAssertEqual(note.type, .task)
        XCTAssertEqual(note.status, .inbox) // Should keep inbox status

        // Test promote again (should have no effect)
        note.promoteToTask()
        XCTAssertEqual(note.type, .task)

        // Test demote to note
        note.demoteToNote()
        XCTAssertEqual(note.type, .note)

        // Test demote again (should have no effect)
        note.demoteToNote()
        XCTAssertEqual(note.type, .note)
    }

    func testTaskDuplication() {
        let original = Task(
            title: "Original",
            notes: "Original notes",
            status: .nextAction,
            project: "Project",
            context: "@office"
        )

        let duplicate = original.duplicate()

        XCTAssertNotEqual(duplicate.id, original.id)
        XCTAssertEqual(duplicate.title, "Original (copy)")
        XCTAssertEqual(duplicate.notes, "Original notes")
        XCTAssertEqual(duplicate.status, .nextAction)
        XCTAssertEqual(duplicate.project, "Project")
        XCTAssertEqual(duplicate.context, "@office")
        XCTAssertTrue(duplicate.positions.isEmpty) // Positions should be cleared
    }

    func testTaskFiltering() {
        let task = Task(
            title: "Test Task",
            status: .nextAction,
            project: "TestProject",
            context: "@office",
            flagged: true,
            priority: .high,
            effort: 30
        )

        // Test matching filters
        XCTAssertTrue(task.matches(Filter(status: .nextAction)))
        XCTAssertTrue(task.matches(Filter(project: "TestProject")))
        XCTAssertTrue(task.matches(Filter(context: "@office")))
        XCTAssertTrue(task.matches(Filter(flagged: true)))
        XCTAssertTrue(task.matches(Filter(priority: .high)))
        XCTAssertTrue(task.matches(Filter(effortMax: 60)))
        XCTAssertTrue(task.matches(Filter(effortMin: 15)))

        // Test non-matching filters
        XCTAssertFalse(task.matches(Filter(status: .inbox)))
        XCTAssertFalse(task.matches(Filter(project: "OtherProject")))
        XCTAssertFalse(task.matches(Filter(context: "@home")))
        XCTAssertFalse(task.matches(Filter(flagged: false)))
        XCTAssertFalse(task.matches(Filter(priority: .low)))
        XCTAssertFalse(task.matches(Filter(effortMax: 15)))
        XCTAssertFalse(task.matches(Filter(effortMin: 60)))

        // Test empty filter (matches all)
        XCTAssertTrue(task.matches(Filter()))
    }

    func testTaskSearching() {
        let task = Task(
            title: "Buy Groceries",
            notes: "Remember to get milk",
            project: "Shopping",
            context: "@errands"
        )

        XCTAssertTrue(task.matchesSearch("groceries"))
        XCTAssertTrue(task.matchesSearch("milk"))
        XCTAssertTrue(task.matchesSearch("shopping"))
        XCTAssertTrue(task.matchesSearch("errands"))
        XCTAssertTrue(task.matchesSearch("BUY")) // Case insensitive
        XCTAssertFalse(task.matchesSearch("office"))
        XCTAssertFalse(task.matchesSearch("computer"))
    }

    // MARK: - Board Tests

    func testBoardCreation() {
        let board = Board(id: "test-board", type: .custom)

        XCTAssertEqual(board.id, "test-board")
        XCTAssertEqual(board.type, .custom)
        XCTAssertEqual(board.layout, .freeform)
        XCTAssertTrue(board.filter.matchesAll)
        XCTAssertNil(board.columns)
        XCTAssertFalse(board.autoHide)
        XCTAssertEqual(board.hideAfterDays, 7)
        XCTAssertFalse(board.isBuiltIn)
        XCTAssertTrue(board.isVisible)
    }

    func testBoardDisplayTitle() {
        let boardWithTitle = Board(id: "test", type: .custom, title: "Custom Title")
        XCTAssertEqual(boardWithTitle.displayTitle, "Custom Title")

        let boardWithoutTitle = Board(id: "my-awesome-board", type: .custom)
        XCTAssertEqual(boardWithoutTitle.displayTitle, "My Awesome Board")
    }

    func testBoardFilePath() {
        let board = Board(id: "test-board", type: .custom)
        XCTAssertEqual(board.filePath, "boards/test-board.md")
        XCTAssertEqual(board.fileName, "test-board.md")
    }

    func testBoardColumns() {
        // Kanban board requires columns
        let kanbanBoard = Board(id: "kanban", type: .status, layout: .kanban)
        XCTAssertTrue(kanbanBoard.requiresColumns)

        // Freeform doesn't require columns
        let freeformBoard = Board(id: "freeform", type: .custom, layout: .freeform)
        XCTAssertFalse(freeformBoard.requiresColumns)
    }

    func testBoardEffectiveColumns() {
        // Custom columns
        let customBoard = Board(
            id: "custom",
            type: .custom,
            layout: .kanban,
            columns: ["Todo", "Done"]
        )
        XCTAssertEqual(customBoard.effectiveColumns, ["Todo", "Done"])

        // Default status columns
        let statusBoard = Board(id: "status", type: .status, layout: .kanban)
        XCTAssertEqual(statusBoard.effectiveColumns, ["Inbox", "Next Actions", "Waiting", "Someday"])

        // Default project columns
        let projectBoard = Board(id: "project", type: .project, layout: .kanban)
        XCTAssertEqual(projectBoard.effectiveColumns, ["To Do", "In Progress", "Done"])
    }

    func testBoardMetadataUpdates() {
        // Context board
        let contextBoard = Board(
            id: "phone",
            type: .context,
            filter: Filter(context: "@phone")
        )
        let contextUpdates = contextBoard.metadataUpdates()
        XCTAssertEqual(contextUpdates["context"] as? String, "@phone")

        // Project board
        let projectBoard = Board(
            id: "website",
            type: .project,
            filter: Filter(project: "Website")
        )
        let projectUpdates = projectBoard.metadataUpdates()
        XCTAssertEqual(projectUpdates["project"] as? String, "Website")

        // Status board with column
        let statusBoard = Board(id: "status", type: .status, layout: .kanban)
        let statusUpdates = statusBoard.metadataUpdates(forColumn: "Next Actions")
        XCTAssertNotNil(statusUpdates["status"])
    }

    func testBoardAutoHide() {
        let board = Board(id: "test", type: .project, autoHide: true, hideAfterDays: 7)

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -8, to: now)!

        XCTAssertFalse(board.shouldAutoHide(lastActiveDate: now))
        XCTAssertFalse(board.shouldAutoHide(lastActiveDate: yesterday))
        XCTAssertTrue(board.shouldAutoHide(lastActiveDate: lastWeek))
    }

    func testBuiltInBoards() {
        let inbox = Board.inbox
        XCTAssertEqual(inbox.id, "inbox")
        XCTAssertTrue(inbox.isBuiltIn)
        XCTAssertEqual(inbox.type, .status)

        let nextActions = Board.nextActions
        XCTAssertEqual(nextActions.id, "next-actions")
        XCTAssertTrue(nextActions.isBuiltIn)

        let allBuiltIn = Board.builtInBoards
        XCTAssertEqual(allBuiltIn.count, 7)
        XCTAssertTrue(allBuiltIn.allSatisfy { $0.isBuiltIn })
    }

    // MARK: - Perspective Tests

    func testPerspectiveCreation() {
        let perspective = Perspective(id: "test", name: "Test Perspective")

        XCTAssertEqual(perspective.id, "test")
        XCTAssertEqual(perspective.name, "Test Perspective")
        XCTAssertEqual(perspective.groupBy, .none)
        XCTAssertEqual(perspective.sortBy, .created)
        XCTAssertEqual(perspective.sortDirection, .ascending)
        XCTAssertFalse(perspective.showCompleted)
        XCTAssertFalse(perspective.showDeferred)
        XCTAssertFalse(perspective.isBuiltIn)
    }

    func testPerspectiveFiltering() {
        let perspective = Perspective(
            id: "next",
            name: "Next Actions",
            filter: Filter(status: .nextAction),
            showCompleted: false
        )

        let tasks = [
            Task(title: "Inbox Task", status: .inbox),
            Task(title: "Next Task", status: .nextAction),
            Task(title: "Completed Task", status: .completed),
            Task(title: "Waiting Task", status: .waiting)
        ]

        let filtered = perspective.apply(to: tasks)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].title, "Next Task")
    }

    func testPerspectiveSorting() {
        let perspective = Perspective(
            id: "sorted",
            name: "Sorted",
            sortBy: .title,
            sortDirection: .ascending
        )

        let tasks = [
            Task(title: "Zebra"),
            Task(title: "Apple"),
            Task(title: "Mango")
        ]

        let sorted = perspective.apply(to: tasks)
        XCTAssertEqual(sorted[0].title, "Apple")
        XCTAssertEqual(sorted[1].title, "Mango")
        XCTAssertEqual(sorted[2].title, "Zebra")
    }

    func testPerspectiveGrouping() {
        let perspective = Perspective(
            id: "grouped",
            name: "Grouped by Context",
            groupBy: .context
        )

        let tasks = [
            Task(title: "Office Task", context: "@office"),
            Task(title: "Home Task", context: "@home"),
            Task(title: "Another Office Task", context: "@office"),
            Task(title: "No Context Task")
        ]

        let groups = perspective.group(tasks)
        XCTAssertTrue(groups.count >= 2)

        // Find office group
        if let officeGroup = groups.first(where: { $0.0 == "@office" }) {
            XCTAssertEqual(officeGroup.1.count, 2)
        }
    }

    func testBuiltInPerspectives() {
        let inbox = Perspective.inbox
        XCTAssertTrue(inbox.isBuiltIn)
        XCTAssertEqual(inbox.filter.status, .inbox)

        let nextActions = Perspective.nextActions
        XCTAssertTrue(nextActions.isBuiltIn)
        XCTAssertEqual(nextActions.groupBy, .context)

        let allBuiltIn = Perspective.builtInPerspectives
        XCTAssertEqual(allBuiltIn.count, 7)
    }

    // MARK: - Filter Tests

    func testFilterMatchesAll() {
        let emptyFilter = Filter()
        XCTAssertTrue(emptyFilter.matchesAll)
        XCTAssertEqual(emptyFilter.criteriaCount, 0)

        let statusFilter = Filter(status: .inbox)
        XCTAssertFalse(statusFilter.matchesAll)
        XCTAssertEqual(statusFilter.criteriaCount, 1)

        let multiFilter = Filter(status: .nextAction, priority: .high, flagged: true)
        XCTAssertFalse(multiFilter.matchesAll)
        XCTAssertEqual(multiFilter.criteriaCount, 3)
    }

    func testPredefinedFilters() {
        XCTAssertEqual(Filter.inbox.status, .inbox)
        XCTAssertEqual(Filter.nextActions.status, .nextAction)
        XCTAssertEqual(Filter.flagged.flagged, true)
        XCTAssertEqual(Filter.waiting.status, .waiting)
        XCTAssertEqual(Filter.someday.status, .someday)
        XCTAssertEqual(Filter.completed.status, .completed)
    }

    // MARK: - Position Tests

    func testPositionCreation() {
        let pos = Position(x: 100, y: 200)
        XCTAssertEqual(pos.x, 100)
        XCTAssertEqual(pos.y, 200)
    }

    func testPositionZero() {
        let zero = Position.zero
        XCTAssertEqual(zero.x, 0)
        XCTAssertEqual(zero.y, 0)
    }

    func testPositionDistance() {
        let pos1 = Position(x: 0, y: 0)
        let pos2 = Position(x: 3, y: 4)

        XCTAssertEqual(pos1.distance(to: pos2), 5.0, accuracy: 0.001)
        XCTAssertEqual(pos2.distance(to: pos1), 5.0, accuracy: 0.001)
    }

    func testPositionOffset() {
        let pos = Position(x: 100, y: 200)

        let offset1 = pos.offset(by: 50, dy: 75)
        XCTAssertEqual(offset1.x, 150)
        XCTAssertEqual(offset1.y, 275)

        let offset2 = pos.offset(by: Position(x: -20, y: -30))
        XCTAssertEqual(offset2.x, 80)
        XCTAssertEqual(offset2.y, 170)
    }

    // MARK: - Priority Tests

    func testPriorityDisplay() {
        XCTAssertEqual(Priority.high.displayName, "High")
        XCTAssertEqual(Priority.medium.displayName, "Medium")
        XCTAssertEqual(Priority.low.displayName, "Low")
    }

    func testPrioritySortOrder() {
        XCTAssertEqual(Priority.high.sortOrder, 3)
        XCTAssertEqual(Priority.medium.sortOrder, 2)
        XCTAssertEqual(Priority.low.sortOrder, 1)

        XCTAssertTrue(Priority.high.sortOrder > Priority.medium.sortOrder)
        XCTAssertTrue(Priority.medium.sortOrder > Priority.low.sortOrder)
    }

    // MARK: - Status Tests

    func testStatusDisplay() {
        XCTAssertEqual(Status.inbox.displayName, "Inbox")
        XCTAssertEqual(Status.nextAction.displayName, "Next Action")
        XCTAssertEqual(Status.waiting.displayName, "Waiting For")
        XCTAssertEqual(Status.someday.displayName, "Someday/Maybe")
        XCTAssertEqual(Status.completed.displayName, "Completed")
    }

    func testStatusProperties() {
        XCTAssertTrue(Status.inbox.isActive)
        XCTAssertTrue(Status.nextAction.isActive)
        XCTAssertFalse(Status.completed.isActive)

        XCTAssertFalse(Status.inbox.isActionable)
        XCTAssertTrue(Status.nextAction.isActionable)
        XCTAssertFalse(Status.completed.isActionable)
    }

    // MARK: - Layout Tests

    func testLayoutProperties() {
        XCTAssertTrue(Layout.freeform.supportsCustomPositions)
        XCTAssertFalse(Layout.kanban.supportsCustomPositions)
        XCTAssertFalse(Layout.grid.supportsCustomPositions)

        XCTAssertFalse(Layout.freeform.requiresColumns)
        XCTAssertTrue(Layout.kanban.requiresColumns)
        XCTAssertFalse(Layout.grid.requiresColumns)

        XCTAssertFalse(Layout.freeform.supportsAutoArrange)
        XCTAssertTrue(Layout.kanban.supportsAutoArrange)
        XCTAssertTrue(Layout.grid.supportsAutoArrange)
    }

    // MARK: - BoardType Tests

    func testBoardTypeProperties() {
        XCTAssertTrue(BoardType.context.supportsAutoCreation)
        XCTAssertTrue(BoardType.project.supportsAutoCreation)
        XCTAssertFalse(BoardType.status.supportsAutoCreation)
        XCTAssertFalse(BoardType.custom.supportsAutoCreation)

        XCTAssertFalse(BoardType.context.supportsAutoHide)
        XCTAssertTrue(BoardType.project.supportsAutoHide)
        XCTAssertFalse(BoardType.status.supportsAutoHide)
        XCTAssertFalse(BoardType.custom.supportsAutoHide)
    }
}
