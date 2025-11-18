//
//  WindowStateManagerTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for WindowStateManager covering state persistence,
//  window frame management, and restoration.
//

import XCTest
@testable import StickyToDoCore

#if canImport(AppKit)
import AppKit
#endif

final class WindowStateManagerTests: XCTestCase {

    var manager: WindowStateManager!

    override func setUpWithError() throws {
        manager = WindowStateManager.shared
        manager.resetToDefaults()
    }

    override func tearDownWithError() throws {
        manager.resetToDefaults()
        manager = nil
    }

    // MARK: - Initialization Tests

    func testSharedInstance() {
        let instance1 = WindowStateManager.shared
        let instance2 = WindowStateManager.shared

        XCTAssertTrue(instance1 === instance2)
    }

    func testDefaultValues() {
        XCTAssertTrue(manager.inspectorIsOpen)
        XCTAssertEqual(manager.sidebarWidth, 200)
        XCTAssertEqual(manager.viewMode, .list)
        XCTAssertEqual(manager.selectedPerspective, "inbox")
        XCTAssertEqual(manager.zoomLevel, 1.0)
        XCTAssertEqual(manager.searchQuery, "")
    }

    // MARK: - Inspector State Tests

    func testToggleInspector() {
        let original = manager.inspectorIsOpen

        manager.inspectorIsOpen = !original

        XCTAssertNotEqual(manager.inspectorIsOpen, original)
    }

    func testInspectorStatePersistence() {
        manager.inspectorIsOpen = false
        manager.saveState()

        XCTAssertFalse(manager.inspectorIsOpen)
    }

    // MARK: - Sidebar Width Tests

    func testUpdateSidebarWidth() {
        manager.sidebarWidth = 250

        XCTAssertEqual(manager.sidebarWidth, 250)
    }

    func testSidebarWidthDefaultValue() {
        XCTAssertEqual(manager.sidebarWidth, 200)
    }

    func testZeroSidebarWidth() {
        manager.sidebarWidth = 0

        // Should store zero (UI handles minimum)
        XCTAssertEqual(manager.sidebarWidth, 0)
    }

    // MARK: - View Mode Tests

    func testUpdateViewMode() {
        manager.viewMode = .board

        XCTAssertEqual(manager.viewMode, .board)
    }

    func testViewModeDefaultsList() {
        XCTAssertEqual(manager.viewMode, .list)
    }

    func testViewModeToggle() {
        manager.viewMode = .list
        XCTAssertEqual(manager.viewMode, .list)

        manager.viewMode = .board
        XCTAssertEqual(manager.viewMode, .board)
    }

    // MARK: - Perspective Tests

    func testUpdateSelectedPerspective() {
        manager.selectedPerspective = "today"

        XCTAssertEqual(manager.selectedPerspective, "today")
    }

    func testEmptyPerspectiveString() {
        manager.selectedPerspective = ""

        XCTAssertEqual(manager.selectedPerspective, "")
    }

    // MARK: - Board State Tests

    func testUpdateLastUsedBoard() {
        manager.lastUsedBoard = "board-123"

        XCTAssertEqual(manager.lastUsedBoard, "board-123")
    }

    func testNilLastUsedBoard() {
        manager.lastUsedBoard = "test"
        manager.lastUsedBoard = nil

        XCTAssertNil(manager.lastUsedBoard)
    }

    // MARK: - Search Query Tests

    func testUpdateSearchQuery() {
        manager.searchQuery = "test search"

        XCTAssertEqual(manager.searchQuery, "test search")
    }

    func testEmptySearchQuery() {
        manager.searchQuery = "something"
        manager.searchQuery = ""

        XCTAssertEqual(manager.searchQuery, "")
    }

    // MARK: - Zoom Level Tests

    func testUpdateZoomLevel() {
        manager.zoomLevel = 1.5

        XCTAssertEqual(manager.zoomLevel, 1.5)
    }

    func testZoomLevelDefaultValue() {
        XCTAssertEqual(manager.zoomLevel, 1.0)
    }

    func testZoomLevelRange() {
        manager.zoomLevel = 0.5
        XCTAssertEqual(manager.zoomLevel, 0.5)

        manager.zoomLevel = 2.0
        XCTAssertEqual(manager.zoomLevel, 2.0)
    }

    #if canImport(AppKit)
    // MARK: - Window Frame Tests

    func testSaveWindowFrame() {
        let testFrame = NSRect(x: 100, y: 200, width: 800, height: 600)

        manager.saveWindowFrame(testFrame, for: "main-window")

        let restored = manager.restoreWindowFrame(for: "main-window")
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.origin.x, 100, accuracy: 1.0)
        XCTAssertEqual(restored?.origin.y, 200, accuracy: 1.0)
    }

    func testRestoreNonexistentFrame() {
        let restored = manager.restoreWindowFrame(for: "nonexistent")

        XCTAssertNil(restored)
    }

    func testUpdateWindowFrame() {
        let frame1 = NSRect(x: 0, y: 0, width: 800, height: 600)
        let frame2 = NSRect(x: 100, y: 100, width: 900, height: 700)

        manager.saveWindowFrame(frame1, for: "test-window")
        manager.saveWindowFrame(frame2, for: "test-window")

        let restored = manager.restoreWindowFrame(for: "test-window")
        XCTAssertEqual(restored?.origin.x, 100, accuracy: 1.0)
    }
    #endif

    // MARK: - Window Specific State Tests

    func testSaveWindowSpecificState() {
        var state = WindowSpecificState()
        state.inspectorOpen = false
        state.sidebarWidth = 300
        state.viewMode = .board

        manager.saveWindowSpecificState(state, for: "window-1")

        let restored = manager.restoreWindowSpecificState(for: "window-1")
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.inspectorOpen, false)
        XCTAssertEqual(restored?.sidebarWidth, 300)
        XCTAssertEqual(restored?.viewMode, .board)
    }

    func testRestoreNonexistentWindowState() {
        let restored = manager.restoreWindowSpecificState(for: "nonexistent")

        XCTAssertNil(restored)
    }

    func testWindowSpecificStateDefaults() {
        let state = WindowSpecificState()

        XCTAssertTrue(state.inspectorOpen)
        XCTAssertEqual(state.sidebarWidth, 200)
        XCTAssertEqual(state.viewMode, .list)
        XCTAssertEqual(state.searchQuery, "")
        XCTAssertEqual(state.zoomLevel, 1.0)
        XCTAssertEqual(state.scrollPosition, .zero)
        XCTAssertTrue(state.selectedTaskIDs.isEmpty)
    }

    // MARK: - State Persistence Tests

    func testSaveState() {
        manager.viewMode = .board
        manager.sidebarWidth = 250
        manager.inspectorIsOpen = false

        manager.saveState()

        // Values should be persisted
        XCTAssertEqual(manager.viewMode, .board)
        XCTAssertEqual(manager.sidebarWidth, 250)
        XCTAssertFalse(manager.inspectorIsOpen)
    }

    // MARK: - Reset Tests

    func testResetAllWindowStates() {
        manager.saveWindowSpecificState(WindowSpecificState(), for: "window-1")
        manager.saveWindowSpecificState(WindowSpecificState(), for: "window-2")

        manager.resetAllWindowStates()

        XCTAssertNil(manager.restoreWindowSpecificState(for: "window-1"))
        XCTAssertNil(manager.restoreWindowSpecificState(for: "window-2"))
    }

    func testResetToDefaults() {
        manager.viewMode = .board
        manager.sidebarWidth = 300
        manager.inspectorIsOpen = false
        manager.zoomLevel = 2.0

        manager.resetToDefaults()

        XCTAssertEqual(manager.viewMode, .list)
        XCTAssertEqual(manager.sidebarWidth, 200)
        XCTAssertTrue(manager.inspectorIsOpen)
        XCTAssertEqual(manager.zoomLevel, 1.0)
    }

    // MARK: - CGRect Codable Tests

    func testCGRectEncoding() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 200)
        let encoder = JSONEncoder()

        let data = try encoder.encode(rect)

        XCTAssertTrue(data.count > 0)
    }

    func testCGRectDecoding() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 200)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(rect)
        let decoded = try decoder.decode(CGRect.self, from: data)

        XCTAssertEqual(decoded.origin.x, rect.origin.x, accuracy: 0.1)
        XCTAssertEqual(decoded.origin.y, rect.origin.y, accuracy: 0.1)
        XCTAssertEqual(decoded.size.width, rect.size.width, accuracy: 0.1)
        XCTAssertEqual(decoded.size.height, rect.size.height, accuracy: 0.1)
    }

    // MARK: - CGPoint Codable Tests

    func testCGPointEncoding() throws {
        let point = CGPoint(x: 50, y: 100)
        let encoder = JSONEncoder()

        let data = try encoder.encode(point)

        XCTAssertTrue(data.count > 0)
    }

    func testCGPointDecoding() throws {
        let point = CGPoint(x: 50, y: 100)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(point)
        let decoded = try decoder.decode(CGPoint.self, from: data)

        XCTAssertEqual(decoded.x, point.x, accuracy: 0.1)
        XCTAssertEqual(decoded.y, point.y, accuracy: 0.1)
    }

    // MARK: - Window State Structure Tests

    func testWindowStateDefaults() {
        let state = WindowState(identifier: "test")

        XCTAssertEqual(state.identifier, "test")
        XCTAssertEqual(state.frame, .zero)
        XCTAssertFalse(state.isFullScreen)
        XCTAssertFalse(state.isMiniaturized)
        XCTAssertNil(state.specificState)
    }

    // MARK: - Edge Cases

    func testMultipleWindowStates() {
        for i in 0..<10 {
            var state = WindowSpecificState()
            state.sidebarWidth = CGFloat(200 + i * 10)
            manager.saveWindowSpecificState(state, for: "window-\(i)")
        }

        for i in 0..<10 {
            let restored = manager.restoreWindowSpecificState(for: "window-\(i)")
            XCTAssertEqual(restored?.sidebarWidth, CGFloat(200 + i * 10))
        }
    }

    func testVeryLongWindowIdentifier() {
        let longId = String(repeating: "a", count: 1000)
        let state = WindowSpecificState()

        manager.saveWindowSpecificState(state, for: longId)

        let restored = manager.restoreWindowSpecificState(for: longId)
        XCTAssertNotNil(restored)
    }

    // MARK: - Performance Tests

    func testSaveStatePerformance() {
        measure {
            for _ in 0..<100 {
                manager.saveState()
            }
        }
    }

    func testWindowStateStoragePerformance() {
        measure {
            for i in 0..<100 {
                let state = WindowSpecificState()
                manager.saveWindowSpecificState(state, for: "window-\(i)")
            }
        }
    }
}
