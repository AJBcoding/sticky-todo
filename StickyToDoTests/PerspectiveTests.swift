//
//  PerspectiveTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for SmartPerspective and PerspectiveStore.
//

import XCTest
import Combine
@testable import StickyToDo

final class PerspectiveTests: XCTestCase {

    var tempDirectory: URL!
    var perspectiveStore: PerspectiveStore!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PerspectiveTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        perspectiveStore = PerspectiveStore(rootDirectory: tempDirectory)
        cancellables = []
    }

    override func tearDown() async throws {
        perspectiveStore.cancelAllPendingSaves()
        cancellables = nil
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - SmartPerspective Tests

    func testSmartPerspectiveCreation() {
        let perspective = SmartPerspective(
            name: "Test Perspective",
            description: "A test perspective",
            rules: [],
            logic: .and,
            groupBy: .context,
            sortBy: .priority,
            sortDirection: .descending,
            showCompleted: false,
            showDeferred: false
        )

        XCTAssertEqual(perspective.name, "Test Perspective")
        XCTAssertEqual(perspective.description, "A test perspective")
        XCTAssertEqual(perspective.groupBy, .context)
        XCTAssertEqual(perspective.sortBy, .priority)
        XCTAssertEqual(perspective.sortDirection, .descending)
        XCTAssertFalse(perspective.showCompleted)
        XCTAssertFalse(perspective.showDeferred)
        XCTAssertFalse(perspective.isBuiltIn)
    }

    func testBuiltInPerspectives() {
        let builtIn = SmartPerspective.builtInSmartPerspectives

        XCTAssertFalse(builtIn.isEmpty)
        XCTAssertTrue(builtIn.allSatisfy { $0.isBuiltIn })

        // Check that expected perspectives exist
        XCTAssertTrue(builtIn.contains { $0.name == "Today's Focus" })
        XCTAssertTrue(builtIn.contains { $0.name == "Quick Wins" })
        XCTAssertTrue(builtIn.contains { $0.name == "Waiting This Week" })
    }

    func testFilterRuleMatching() {
        let task = Task(
            title: "Test Task",
            status: .nextAction,
            priority: .high,
            context: "@computer",
            project: "Test Project"
        )

        // Test status rule
        let statusRule = FilterRule(
            property: .status,
            operatorType: .equals,
            value: .string("nextAction")
        )
        XCTAssertTrue(statusRule.matches(task))

        // Test priority rule
        let priorityRule = FilterRule(
            property: .priority,
            operatorType: .equals,
            value: .string("high")
        )
        XCTAssertTrue(priorityRule.matches(task))

        // Test title contains rule
        let titleRule = FilterRule(
            property: .title,
            operatorType: .contains,
            value: .string("Test")
        )
        XCTAssertTrue(titleRule.matches(task))

        // Test context rule
        let contextRule = FilterRule(
            property: .context,
            operatorType: .equals,
            value: .string("@computer")
        )
        XCTAssertTrue(contextRule.matches(task))
    }

    func testPerspectiveFilteringAND() {
        let tasks = [
            Task(title: "Task 1", status: .nextAction, priority: .high),
            Task(title: "Task 2", status: .nextAction, priority: .low),
            Task(title: "Task 3", status: .waiting, priority: .high),
            Task(title: "Task 4", status: .nextAction, priority: .high)
        ]

        let perspective = SmartPerspective(
            name: "High Priority Next Actions",
            rules: [
                FilterRule(property: .status, operatorType: .equals, value: .string("nextAction")),
                FilterRule(property: .priority, operatorType: .equals, value: .string("high"))
            ],
            logic: .and
        )

        let filtered = perspective.apply(to: tasks)

        // Should match tasks 1 and 4 (next action AND high priority)
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains { $0.title == "Task 1" })
        XCTAssertTrue(filtered.contains { $0.title == "Task 4" })
    }

    func testPerspectiveFilteringOR() {
        let tasks = [
            Task(title: "Task 1", status: .nextAction, priority: .high),
            Task(title: "Task 2", status: .nextAction, priority: .low),
            Task(title: "Task 3", status: .waiting, priority: .high),
            Task(title: "Task 4", status: .someday, priority: .low)
        ]

        let perspective = SmartPerspective(
            name: "Next Action OR High Priority",
            rules: [
                FilterRule(property: .status, operatorType: .equals, value: .string("nextAction")),
                FilterRule(property: .priority, operatorType: .equals, value: .string("high"))
            ],
            logic: .or
        )

        let filtered = perspective.apply(to: tasks)

        // Should match tasks 1, 2, 3 (next action OR high priority)
        XCTAssertEqual(filtered.count, 3)
        XCTAssertTrue(filtered.contains { $0.title == "Task 1" })
        XCTAssertTrue(filtered.contains { $0.title == "Task 2" })
        XCTAssertTrue(filtered.contains { $0.title == "Task 3" })
    }

    func testPerspectiveSorting() {
        let tasks = [
            Task(title: "C Task", priority: .low, created: Date().addingTimeInterval(-300)),
            Task(title: "A Task", priority: .high, created: Date().addingTimeInterval(-100)),
            Task(title: "B Task", priority: .medium, created: Date().addingTimeInterval(-200))
        ]

        // Test sorting by title ascending
        let titlePerspective = SmartPerspective(
            name: "By Title",
            sortBy: .title,
            sortDirection: .ascending
        )
        let titleSorted = titlePerspective.apply(to: tasks)
        XCTAssertEqual(titleSorted[0].title, "A Task")
        XCTAssertEqual(titleSorted[1].title, "B Task")
        XCTAssertEqual(titleSorted[2].title, "C Task")

        // Test sorting by priority descending
        let priorityPerspective = SmartPerspective(
            name: "By Priority",
            sortBy: .priority,
            sortDirection: .descending
        )
        let prioritySorted = priorityPerspective.apply(to: tasks)
        XCTAssertEqual(prioritySorted[0].priority, .high)
        XCTAssertEqual(prioritySorted[1].priority, .medium)
        XCTAssertEqual(prioritySorted[2].priority, .low)
    }

    func testShowCompletedFilter() {
        let tasks = [
            Task(title: "Active", status: .nextAction),
            Task(title: "Completed", status: .completed),
            Task(title: "Waiting", status: .waiting)
        ]

        // Don't show completed
        let hideCompleted = SmartPerspective(
            name: "Hide Completed",
            showCompleted: false
        )
        let filtered1 = hideCompleted.apply(to: tasks)
        XCTAssertEqual(filtered1.count, 2)
        XCTAssertFalse(filtered1.contains { $0.status == .completed })

        // Show completed
        let showCompleted = SmartPerspective(
            name: "Show Completed",
            showCompleted: true
        )
        let filtered2 = showCompleted.apply(to: tasks)
        XCTAssertEqual(filtered2.count, 3)
    }

    func testDateRangeFiltering() {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let tasks = [
            Task(title: "Due Today", due: today.addingTimeInterval(3600)),
            Task(title: "Due Tomorrow", due: tomorrow.addingTimeInterval(3600)),
            Task(title: "Due Next Week", due: Calendar.current.date(byAdding: .day, value: 7, to: today)!),
            Task(title: "No Due Date")
        ]

        let todayPerspective = SmartPerspective(
            name: "Due Today",
            rules: [
                FilterRule(property: .dueDate, operatorType: .isWithin, value: .dateRange(.today))
            ]
        )

        let filtered = todayPerspective.apply(to: tasks)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].title, "Due Today")
    }

    // MARK: - PerspectiveStore Tests

    func testPerspectiveStoreInitialState() {
        XCTAssertEqual(perspectiveStore.perspectives.count, 0)
        XCTAssertEqual(perspectiveStore.customPerspectives.count, 0)
        XCTAssertEqual(perspectiveStore.builtInPerspectives.count, 0)
    }

    func testLoadAllPerspectives() throws {
        try perspectiveStore.loadAll()

        let expectation = XCTestExpectation(description: "Perspectives loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Should have loaded built-in perspectives
        XCTAssertGreaterThan(perspectiveStore.builtInPerspectives.count, 0)
        XCTAssertEqual(perspectiveStore.perspectives.count, perspectiveStore.builtInPerspectives.count)
    }

    func testCreatePerspective() throws {
        try perspectiveStore.loadAll()

        let expectation = XCTestExpectation(description: "Load complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let initialCount = perspectiveStore.customPerspectives.count

        let perspective = SmartPerspective(
            name: "Test Custom",
            description: "A test perspective"
        )

        perspectiveStore.create(perspective)

        let createExpectation = XCTestExpectation(description: "Create complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            createExpectation.fulfill()
        }
        wait(for: [createExpectation], timeout: 2.0)

        XCTAssertEqual(perspectiveStore.customPerspectives.count, initialCount + 1)
        XCTAssertNotNil(perspectiveStore.perspective(withID: perspective.id))
    }

    func testUpdatePerspective() throws {
        try perspectiveStore.loadAll()

        let loadExpectation = XCTestExpectation(description: "Load complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 2.0)

        var perspective = SmartPerspective(
            name: "Original Name",
            description: "Original description"
        )
        perspectiveStore.create(perspective)

        let createExpectation = XCTestExpectation(description: "Create complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            createExpectation.fulfill()
        }
        wait(for: [createExpectation], timeout: 2.0)

        // Update the perspective
        perspective = SmartPerspective(
            id: perspective.id,
            name: "Updated Name",
            description: "Updated description",
            created: perspective.created
        )
        perspectiveStore.update(perspective)

        let updateExpectation = XCTestExpectation(description: "Update complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateExpectation.fulfill()
        }
        wait(for: [updateExpectation], timeout: 2.0)

        let updated = perspectiveStore.perspective(withID: perspective.id)
        XCTAssertEqual(updated?.name, "Updated Name")
        XCTAssertEqual(updated?.description, "Updated description")
    }

    func testDeletePerspective() throws {
        try perspectiveStore.loadAll()

        let loadExpectation = XCTestExpectation(description: "Load complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 2.0)

        let perspective = SmartPerspective(name: "To Delete")
        perspectiveStore.create(perspective)

        let createExpectation = XCTestExpectation(description: "Create complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            createExpectation.fulfill()
        }
        wait(for: [createExpectation], timeout: 2.0)

        let beforeCount = perspectiveStore.customPerspectives.count

        perspectiveStore.delete(perspective)

        let deleteExpectation = XCTestExpectation(description: "Delete complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 2.0)

        XCTAssertEqual(perspectiveStore.customPerspectives.count, beforeCount - 1)
        XCTAssertNil(perspectiveStore.perspective(withID: perspective.id))
    }

    func testCannotDeleteBuiltInPerspective() throws {
        try perspectiveStore.loadAll()

        let expectation = XCTestExpectation(description: "Load complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let builtInCount = perspectiveStore.builtInPerspectives.count
        guard let builtIn = perspectiveStore.builtInPerspectives.first else {
            XCTFail("No built-in perspectives")
            return
        }

        perspectiveStore.delete(builtIn)

        let deleteExpectation = XCTestExpectation(description: "Delete attempt")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 2.0)

        // Built-in perspective should still exist
        XCTAssertEqual(perspectiveStore.builtInPerspectives.count, builtInCount)
    }

    func testExportImportPerspective() throws {
        let perspective = SmartPerspective(
            name: "Export Test",
            description: "A perspective to export",
            rules: [
                FilterRule(property: .status, operatorType: .equals, value: .string("nextAction"))
            ],
            logic: .and,
            groupBy: .context,
            sortBy: .priority,
            sortDirection: .descending
        )

        // Export
        let data = try perspectiveStore.export(perspective)
        XCTAssertFalse(data.isEmpty)

        // Import
        let imported = try perspectiveStore.import(from: data)
        XCTAssertEqual(imported.name, perspective.name)
        XCTAssertEqual(imported.description, perspective.description)
        XCTAssertEqual(imported.rules.count, perspective.rules.count)
        XCTAssertEqual(imported.logic, perspective.logic)
        XCTAssertEqual(imported.groupBy, perspective.groupBy)
        XCTAssertEqual(imported.sortBy, perspective.sortBy)
        XCTAssertFalse(imported.isBuiltIn) // Imported perspectives are never built-in
        XCTAssertNotEqual(imported.id, perspective.id) // New ID assigned
    }

    func testPersistence() throws {
        // Create and save perspectives
        try perspectiveStore.loadAll()

        let loadExpectation = XCTestExpectation(description: "Load complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 2.0)

        let perspective1 = SmartPerspective(name: "Perspective 1")
        let perspective2 = SmartPerspective(name: "Perspective 2")

        perspectiveStore.create(perspective1)
        perspectiveStore.create(perspective2)

        let createExpectation = XCTestExpectation(description: "Create complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            createExpectation.fulfill()
        }
        wait(for: [createExpectation], timeout: 2.0)

        // Save all
        try perspectiveStore.saveAll()

        let saveExpectation = XCTestExpectation(description: "Save complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            saveExpectation.fulfill()
        }
        wait(for: [saveExpectation], timeout: 2.0)

        // Create new store and load
        let newStore = PerspectiveStore(rootDirectory: tempDirectory)
        try newStore.loadAll()

        let reloadExpectation = XCTestExpectation(description: "Reload complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            reloadExpectation.fulfill()
        }
        wait(for: [reloadExpectation], timeout: 2.0)

        // Should have loaded the saved perspectives
        XCTAssertEqual(newStore.customPerspectives.count, 2)
        XCTAssertTrue(newStore.customPerspectives.contains { $0.name == "Perspective 1" })
        XCTAssertTrue(newStore.customPerspectives.contains { $0.name == "Perspective 2" })
    }

    func testFindPerspectivesByName() throws {
        try perspectiveStore.loadAll()

        let loadExpectation = XCTestExpectation(description: "Load complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 2.0)

        let p1 = SmartPerspective(name: "Work Tasks")
        let p2 = SmartPerspective(name: "Work Projects")
        let p3 = SmartPerspective(name: "Personal")

        perspectiveStore.create(p1)
        perspectiveStore.create(p2)
        perspectiveStore.create(p3)

        let createExpectation = XCTestExpectation(description: "Create complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            createExpectation.fulfill()
        }
        wait(for: [createExpectation], timeout: 2.0)

        let workPerspectives = perspectiveStore.perspectives(named: "Work")
        XCTAssertEqual(workPerspectives.count, 2)
        XCTAssertTrue(workPerspectives.contains { $0.name == "Work Tasks" })
        XCTAssertTrue(workPerspectives.contains { $0.name == "Work Projects" })
    }

    // MARK: - FilterRule Tests

    func testStringOperators() {
        let task = Task(title: "Complete project documentation")

        let containsRule = FilterRule(property: .title, operatorType: .contains, value: .string("project"))
        XCTAssertTrue(containsRule.matches(task))

        let startsWithRule = FilterRule(property: .title, operatorType: .startsWith, value: .string("Complete"))
        XCTAssertTrue(startsWithRule.matches(task))

        let endsWithRule = FilterRule(property: .title, operatorType: .endsWith, value: .string("documentation"))
        XCTAssertTrue(endsWithRule.matches(task))

        let notContainsRule = FilterRule(property: .title, operatorType: .notContains, value: .string("urgent"))
        XCTAssertTrue(notContainsRule.matches(task))
    }

    func testNumberOperators() {
        let task = Task(title: "Quick task", effort: 30)

        let lessThanRule = FilterRule(property: .effort, operatorType: .lessThan, value: .number(60))
        XCTAssertTrue(lessThanRule.matches(task))

        let greaterThanRule = FilterRule(property: .effort, operatorType: .greaterThan, value: .number(15))
        XCTAssertTrue(greaterThanRule.matches(task))

        let equalsRule = FilterRule(property: .effort, operatorType: .equals, value: .number(30))
        XCTAssertTrue(equalsRule.matches(task))
    }

    func testBooleanOperators() {
        let flaggedTask = Task(title: "Important", flagged: true)
        let unflaggedTask = Task(title: "Not important", flagged: false)

        let isTrueRule = FilterRule(property: .flagged, operatorType: .isTrue, value: .boolean(true))
        XCTAssertTrue(isTrueRule.matches(flaggedTask))
        XCTAssertFalse(isTrueRule.matches(unflaggedTask))

        let isFalseRule = FilterRule(property: .flagged, operatorType: .isFalse, value: .boolean(false))
        XCTAssertFalse(isFalseRule.matches(flaggedTask))
        XCTAssertTrue(isFalseRule.matches(unflaggedTask))
    }
}
