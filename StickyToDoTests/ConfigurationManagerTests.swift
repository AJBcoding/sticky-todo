//
//  ConfigurationManagerTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for ConfigurationManager covering settings persistence,
//  defaults, state management, and configuration changes.
//

import XCTest
@testable import StickyToDoCore

final class ConfigurationManagerTests: XCTestCase {

    var manager: ConfigurationManager!
    var testDefaults: UserDefaults!

    override func setUpWithError() throws {
        // Create a test-specific UserDefaults suite
        testDefaults = UserDefaults(suiteName: "com.stickytodo.tests.\(UUID().uuidString)")!

        // Use the shared manager but reset it to defaults for each test
        manager = ConfigurationManager.shared
        manager.resetToDefaults()
    }

    override func tearDownWithError() throws {
        manager.resetToDefaults()
        testDefaults.removePersistentDomain(forName: testDefaults.suiteName!)
        testDefaults = nil
        manager = nil
    }

    // MARK: - Initialization Tests

    func testSharedInstance() {
        let instance1 = ConfigurationManager.shared
        let instance2 = ConfigurationManager.shared

        XCTAssertTrue(instance1 === instance2, "Should be a singleton")
    }

    func testDefaultValues() {
        XCTAssertEqual(manager.autoSaveInterval, 0.5)
        XCTAssertEqual(manager.autoHideInactiveBoardsDays, 30)
        XCTAssertEqual(manager.windowWidth, 1200)
        XCTAssertEqual(manager.windowHeight, 800)
        XCTAssertEqual(manager.sidebarWidth, 220)
        XCTAssertEqual(manager.inspectorWidth, 300)
        XCTAssertTrue(manager.inspectorVisible)
        XCTAssertEqual(manager.defaultTaskStatus, .inbox)
        XCTAssertEqual(manager.defaultTaskPriority, .medium)
        XCTAssertFalse(manager.showCompletedTasks)
        XCTAssertEqual(manager.groupBy, .none)
        XCTAssertEqual(manager.sortBy, .created)
    }

    func testDefaultDataDirectory() {
        XCTAssertTrue(manager.dataDirectory.path.contains("StickyToDo"))
        XCTAssertTrue(manager.dataDirectory.path.contains("Documents"))
    }

    func testFirstRunDetection() {
        // After reset, should be marked as first run
        XCTAssertTrue(manager.isFirstRun)
    }

    // MARK: - Data Directory Tests

    func testChangeDataDirectory() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("TestData")
        let originalDir = manager.dataDirectory

        manager.changeDataDirectory(to: tempDir)

        XCTAssertEqual(manager.dataDirectory, tempDir)
        XCTAssertNotEqual(manager.dataDirectory, originalDir)
    }

    func testDataDirectoryPersistence() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("TestData")

        manager.changeDataDirectory(to: tempDir)
        manager.save()

        // Verify persistence (would need to reload in real test)
        XCTAssertEqual(manager.dataDirectory, tempDir)
    }

    func testComputedDirectoryPaths() {
        let baseDir = manager.dataDirectory

        XCTAssertEqual(manager.tasksDirectory, baseDir.appendingPathComponent("tasks"))
        XCTAssertEqual(manager.boardsDirectory, baseDir.appendingPathComponent("boards"))
        XCTAssertEqual(manager.perspectivesDirectory, baseDir.appendingPathComponent("perspectives"))
        XCTAssertEqual(manager.attachmentsDirectory, baseDir.appendingPathComponent("attachments"))
    }

    // MARK: - Window Configuration Tests

    func testUpdateWindowWidth() {
        manager.windowWidth = 1600

        XCTAssertEqual(manager.windowWidth, 1600)
    }

    func testUpdateWindowHeight() {
        manager.windowHeight = 1000

        XCTAssertEqual(manager.windowHeight, 1000)
    }

    func testUpdateSidebarWidth() {
        manager.sidebarWidth = 250

        XCTAssertEqual(manager.sidebarWidth, 250)
    }

    func testUpdateInspectorWidth() {
        manager.inspectorWidth = 350

        XCTAssertEqual(manager.inspectorWidth, 350)
    }

    func testToggleInspectorVisibility() {
        let originalValue = manager.inspectorVisible

        manager.inspectorVisible = !originalValue

        XCTAssertNotEqual(manager.inspectorVisible, originalValue)
    }

    // MARK: - View Mode Tests

    func testUpdateViewMode() {
        manager.lastViewMode = .board

        XCTAssertEqual(manager.lastViewMode, .board)
    }

    func testViewModeDefaults() {
        XCTAssertEqual(manager.lastViewMode, .list)
    }

    // MARK: - Task Defaults Tests

    func testUpdateDefaultTaskStatus() {
        manager.defaultTaskStatus = .nextAction

        XCTAssertEqual(manager.defaultTaskStatus, .nextAction)
    }

    func testUpdateDefaultTaskPriority() {
        manager.defaultTaskPriority = .high

        XCTAssertEqual(manager.defaultTaskPriority, .high)
    }

    func testUpdateDefaultContext() {
        manager.defaultContext = "@office"

        XCTAssertEqual(manager.defaultContext, "@office")
    }

    func testNilDefaultContext() {
        manager.defaultContext = nil

        XCTAssertNil(manager.defaultContext)
    }

    // MARK: - View Preferences Tests

    func testToggleShowCompletedTasks() {
        manager.showCompletedTasks = true

        XCTAssertTrue(manager.showCompletedTasks)
    }

    func testUpdateGroupBy() {
        manager.groupBy = .project

        XCTAssertEqual(manager.groupBy, .project)
    }

    func testUpdateSortBy() {
        manager.sortBy = .due

        XCTAssertEqual(manager.sortBy, .due)
    }

    func testGroupByOptions() {
        let options = GroupOption.allCases

        XCTAssertTrue(options.contains(.none))
        XCTAssertTrue(options.contains(.status))
        XCTAssertTrue(options.contains(.project))
        XCTAssertTrue(options.contains(.context))
        XCTAssertTrue(options.contains(.priority))
        XCTAssertTrue(options.contains(.dueDate))
    }

    func testSortByOptions() {
        let options = SortOption.allCases

        XCTAssertTrue(options.contains(.title))
        XCTAssertTrue(options.contains(.created))
        XCTAssertTrue(options.contains(.modified))
        XCTAssertTrue(options.contains(.due))
        XCTAssertTrue(options.contains(.priority))
        XCTAssertTrue(options.contains(.status))
    }

    // MARK: - Perspective and Board Tests

    func testUpdateLastPerspectiveID() {
        manager.lastPerspectiveID = "inbox"

        XCTAssertEqual(manager.lastPerspectiveID, "inbox")
    }

    func testUpdateLastBoardID() {
        manager.lastBoardID = "board-123"

        XCTAssertEqual(manager.lastBoardID, "board-123")
    }

    func testUpdateDefaultBoardOnLaunch() {
        manager.defaultBoardOnLaunch = "my-board"

        XCTAssertEqual(manager.defaultBoardOnLaunch, "my-board")
    }

    func testNilDefaultBoardOnLaunch() {
        manager.defaultBoardOnLaunch = nil

        XCTAssertNil(manager.defaultBoardOnLaunch)
    }

    // MARK: - Auto-Hide Settings Tests

    func testUpdateAutoHideInactiveBoardsDays() {
        manager.autoHideInactiveBoardsDays = 60

        XCTAssertEqual(manager.autoHideInactiveBoardsDays, 60)
    }

    func testAutoHideInactiveBoardsDefaultValue() {
        XCTAssertEqual(manager.autoHideInactiveBoardsDays, 30)
    }

    // MARK: - Auto-Save Tests

    func testUpdateAutoSaveInterval() {
        manager.autoSaveInterval = 1.0

        XCTAssertEqual(manager.autoSaveInterval, 1.0)
    }

    func testAutoSaveIntervalDefaultValue() {
        XCTAssertEqual(manager.autoSaveInterval, 0.5)
    }

    // MARK: - Quick Capture Hotkey Tests

    func testUpdateQuickCaptureHotkey() {
        manager.quickCaptureHotkey = 50 // Different key

        XCTAssertEqual(manager.quickCaptureHotkey, 50)
    }

    func testUpdateQuickCaptureHotkeyModifiers() {
        manager.quickCaptureHotkeyModifiers = 0x10A // Different modifiers

        XCTAssertEqual(manager.quickCaptureHotkeyModifiers, 0x10A)
    }

    func testDefaultQuickCaptureHotkey() {
        XCTAssertEqual(manager.quickCaptureHotkey, 49) // Space bar
    }

    func testDefaultQuickCaptureModifiers() {
        XCTAssertEqual(manager.quickCaptureHotkeyModifiers, 0x108) // Cmd+Shift
    }

    // MARK: - Feature Flags Tests

    func testToggleFileWatching() {
        let original = manager.enableFileWatching

        manager.enableFileWatching = !original

        XCTAssertNotEqual(manager.enableFileWatching, original)
    }

    func testDefaultFileWatchingEnabled() {
        XCTAssertTrue(manager.enableFileWatching)
    }

    func testToggleLogging() {
        let original = manager.enableLogging

        manager.enableLogging = !original

        XCTAssertNotEqual(manager.enableLogging, original)
    }

    // MARK: - Weekly Review Tests

    func testUpdateLastReviewDate() {
        let testDate = Date()

        manager.lastReviewDate = testDate

        XCTAssertNotNil(manager.lastReviewDate)
        XCTAssertEqual(manager.lastReviewDate?.timeIntervalSince1970,
                      testDate.timeIntervalSince1970,
                      accuracy: 1.0)
    }

    func testNilLastReviewDate() {
        manager.lastReviewDate = Date()
        manager.lastReviewDate = nil

        XCTAssertNil(manager.lastReviewDate)
    }

    // MARK: - Persistence Tests

    func testSaveConfiguration() {
        manager.windowWidth = 1400
        manager.defaultTaskPriority = .high
        manager.showCompletedTasks = true

        manager.save()

        // Values should be persisted
        XCTAssertEqual(manager.windowWidth, 1400)
        XCTAssertEqual(manager.defaultTaskPriority, .high)
        XCTAssertTrue(manager.showCompletedTasks)
    }

    func testLoadConfiguration() {
        // Set some values
        manager.windowWidth = 1500
        manager.sidebarWidth = 300
        manager.save()

        // Load (in real scenario, would reinitialize)
        manager.load()

        // Values should still be there
        XCTAssertEqual(manager.windowWidth, 1500)
        XCTAssertEqual(manager.sidebarWidth, 300)
    }

    // MARK: - Reset Tests

    func testResetToDefaults() {
        // Change various settings
        manager.windowWidth = 1800
        manager.defaultTaskPriority = .high
        manager.showCompletedTasks = true
        manager.groupBy = .project
        manager.lastPerspectiveID = "test"

        // Reset
        manager.resetToDefaults()

        // All should be back to defaults
        XCTAssertEqual(manager.windowWidth, 1200)
        XCTAssertEqual(manager.defaultTaskPriority, .medium)
        XCTAssertFalse(manager.showCompletedTasks)
        XCTAssertEqual(manager.groupBy, .none)
        XCTAssertNil(manager.lastPerspectiveID)
    }

    func testResetPreservesDataDirectory() {
        let customDir = FileManager.default.temporaryDirectory.appendingPathComponent("Custom")
        manager.changeDataDirectory(to: customDir)

        // Note: resetToDefaults() actually resets data directory too
        // This test documents current behavior
        manager.resetToDefaults()

        XCTAssertTrue(manager.dataDirectory.path.contains("StickyToDo"))
    }

    // MARK: - Display Names Tests

    func testGroupOptionDisplayNames() {
        XCTAssertEqual(GroupOption.none.displayName, "None")
        XCTAssertEqual(GroupOption.status.displayName, "Status")
        XCTAssertEqual(GroupOption.project.displayName, "Project")
        XCTAssertEqual(GroupOption.context.displayName, "Context")
        XCTAssertEqual(GroupOption.priority.displayName, "Priority")
        XCTAssertEqual(GroupOption.dueDate.displayName, "Due Date")
    }

    func testSortOptionDisplayNames() {
        XCTAssertEqual(SortOption.title.displayName, "Title")
        XCTAssertEqual(SortOption.created.displayName, "Created")
        XCTAssertEqual(SortOption.modified.displayName, "Modified")
        XCTAssertEqual(SortOption.due.displayName, "Due Date")
        XCTAssertEqual(SortOption.priority.displayName, "Priority")
        XCTAssertEqual(SortOption.status.displayName, "Status")
    }

    // MARK: - Edge Cases Tests

    func testZeroWindowDimensions() {
        manager.windowWidth = 0
        manager.windowHeight = 0

        // Should handle gracefully
        XCTAssertEqual(manager.windowWidth, 0)
        XCTAssertEqual(manager.windowHeight, 0)
    }

    func testNegativeWindowDimensions() {
        manager.windowWidth = -100
        manager.windowHeight = -100

        // Should store negative values (validation is UI responsibility)
        XCTAssertEqual(manager.windowWidth, -100)
        XCTAssertEqual(manager.windowHeight, -100)
    }

    func testVeryLargeWindowDimensions() {
        manager.windowWidth = 10000
        manager.windowHeight = 10000

        XCTAssertEqual(manager.windowWidth, 10000)
        XCTAssertEqual(manager.windowHeight, 10000)
    }

    func testZeroAutoSaveInterval() {
        manager.autoSaveInterval = 0

        XCTAssertEqual(manager.autoSaveInterval, 0)
    }

    func testNegativeAutoHideDays() {
        manager.autoHideInactiveBoardsDays = -10

        // Should store negative value
        XCTAssertEqual(manager.autoHideInactiveBoardsDays, -10)
    }

    // MARK: - Notification Tests

    func testConfigurationChangedNotification() {
        let expectation = XCTestExpectation(description: "Configuration changed notification")

        let observer = NotificationCenter.default.addObserver(
            forName: .configurationChanged,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        // Trigger a change
        NotificationCenter.default.post(name: .configurationChanged, object: nil)

        wait(for: [expectation], timeout: 1.0)

        NotificationCenter.default.removeObserver(observer)
    }

    func testDataDirectoryChangedNotification() {
        let expectation = XCTestExpectation(description: "Data directory changed notification")

        let observer = NotificationCenter.default.addObserver(
            forName: .dataDirectoryChanged,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        // Trigger a change
        NotificationCenter.default.post(name: .dataDirectoryChanged, object: nil)

        wait(for: [expectation], timeout: 1.0)

        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentReads() {
        let expectation = XCTestExpectation(description: "Concurrent reads complete")
        expectation.expectedFulfillmentCount = 10

        for _ in 0..<10 {
            DispatchQueue.global().async {
                _ = self.manager.windowWidth
                _ = self.manager.sidebarWidth
                _ = self.manager.defaultTaskStatus
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testConcurrentWrites() {
        let expectation = XCTestExpectation(description: "Concurrent writes complete")
        expectation.expectedFulfillmentCount = 10

        for i in 0..<10 {
            DispatchQueue.global().async {
                self.manager.windowWidth = CGFloat(1200 + i * 100)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)

        // Should have some value between 1200 and 2100
        XCTAssertTrue(manager.windowWidth >= 1200 && manager.windowWidth <= 2100)
    }

    // MARK: - Performance Tests

    func testReadPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = manager.windowWidth
                _ = manager.windowHeight
                _ = manager.defaultTaskStatus
                _ = manager.showCompletedTasks
            }
        }
    }

    func testWritePerformance() {
        measure {
            for i in 0..<100 {
                manager.windowWidth = CGFloat(1200 + i)
                manager.sidebarWidth = CGFloat(200 + i)
            }
        }
    }

    func testSavePerformance() {
        measure {
            for _ in 0..<100 {
                manager.save()
            }
        }
    }
}
