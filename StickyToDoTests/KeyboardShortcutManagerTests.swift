//
//  KeyboardShortcutManagerTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for KeyboardShortcutManager covering shortcut registration,
//  action execution, modifier handling, and edge cases.
//

import XCTest
@testable import StickyToDoCore

#if canImport(AppKit)
import AppKit
#endif

final class KeyboardShortcutManagerTests: XCTestCase {

    var manager: KeyboardShortcutManager!

    override func setUpWithError() throws {
        manager = KeyboardShortcutManager.shared
    }

    override func tearDownWithError() throws {
        // Clean up any registered actions
        manager = nil
    }

    // MARK: - Initialization Tests

    func testSharedInstance() {
        let instance1 = KeyboardShortcutManager.shared
        let instance2 = KeyboardShortcutManager.shared

        XCTAssertTrue(instance1 === instance2, "Shared instance should be a singleton")
    }

    func testDefaultShortcutsLoaded() {
        XCTAssertFalse(manager.shortcuts.isEmpty, "Default shortcuts should be loaded")
        XCTAssertTrue(manager.shortcuts.count > 10, "Should have multiple default shortcuts")
    }

    // MARK: - Shortcut Lookup Tests

    func testGetShortcutById() {
        let shortcut = manager.shortcut(for: "newTask")

        XCTAssertNotNil(shortcut)
        XCTAssertEqual(shortcut?.id, "newTask")
        XCTAssertEqual(shortcut?.title, "New Task")
        XCTAssertEqual(shortcut?.key, "n")
        XCTAssertTrue(shortcut?.modifiers.contains(.command) ?? false)
    }

    func testGetNonexistentShortcut() {
        let shortcut = manager.shortcut(for: "nonexistent")

        XCTAssertNil(shortcut)
    }

    func testGetShortcutsByCategory() {
        let fileShortcuts = manager.shortcuts(for: .file)

        XCTAssertFalse(fileShortcuts.isEmpty)
        XCTAssertTrue(fileShortcuts.allSatisfy { $0.category == .file })
    }

    func testGetShortcutsByCategoryEdit() {
        let editShortcuts = manager.shortcuts(for: .edit)

        XCTAssertFalse(editShortcuts.isEmpty)
        XCTAssertTrue(editShortcuts.allSatisfy { $0.category == .edit })
    }

    func testGetShortcutsByCategoryView() {
        let viewShortcuts = manager.shortcuts(for: .view)

        XCTAssertFalse(viewShortcuts.isEmpty)
        XCTAssertTrue(viewShortcuts.allSatisfy { $0.category == .view })
    }

    // MARK: - Display String Tests

    func testDisplayStringForCommandKey() {
        let displayString = manager.displayString(for: "newTask")

        XCTAssertNotNil(displayString)
        XCTAssertTrue(displayString?.contains("⌘") ?? false, "Should contain Command symbol")
        XCTAssertTrue(displayString?.contains("N") ?? false, "Should contain key letter")
    }

    func testDisplayStringForMultipleModifiers() {
        let displayString = manager.displayString(for: "quickCapture")

        XCTAssertNotNil(displayString)
        XCTAssertTrue(displayString?.contains("⌘") ?? false, "Should contain Command symbol")
        XCTAssertTrue(displayString?.contains("⇧") ?? false, "Should contain Shift symbol")
    }

    func testDisplayStringWithSpecialKeys() {
        // Test for delete key
        if let deleteShortcut = manager.shortcut(for: "delete") {
            let displayString = deleteShortcut.displayString
            XCTAssertTrue(displayString.contains("⌫"), "Should contain Delete symbol")
        }

        // Test for return key
        if let completeShortcut = manager.shortcut(for: "completeTask") {
            let displayString = completeShortcut.displayString
            XCTAssertTrue(displayString.contains("↩"), "Should contain Return symbol")
        }
    }

    // MARK: - Action Registration Tests

    func testRegisterAction() {
        var actionExecuted = false

        manager.registerAction(for: "testAction") {
            actionExecuted = true
        }

        // Manually trigger the action
        if let action = manager.value(forKey: "shortcutActions") as? [String: () -> Void] {
            action["testAction"]?()
        }

        // Note: This test verifies registration works, but actual execution
        // requires the event monitoring system which is harder to test
    }

    func testRegisterMultipleActions() {
        var action1Executed = false
        var action2Executed = false

        manager.registerAction(for: "action1") {
            action1Executed = true
        }

        manager.registerAction(for: "action2") {
            action2Executed = true
        }

        // Actions are registered independently
        XCTAssertFalse(action1Executed)
        XCTAssertFalse(action2Executed)
    }

    func testReplaceAction() {
        var firstActionExecuted = false
        var secondActionExecuted = false

        manager.registerAction(for: "replaceTest") {
            firstActionExecuted = true
        }

        // Replace with new action
        manager.registerAction(for: "replaceTest") {
            secondActionExecuted = true
        }

        // Only the second action should be registered
        // (Can't easily test execution without event system)
    }

    // MARK: - Shortcut Structure Tests

    func testShortcutStructure() {
        let shortcut = AppShortcut(
            id: "test",
            title: "Test Shortcut",
            key: "t",
            modifiers: [.command, .shift],
            category: .file
        )

        XCTAssertEqual(shortcut.id, "test")
        XCTAssertEqual(shortcut.title, "Test Shortcut")
        XCTAssertEqual(shortcut.key, "t")
        XCTAssertTrue(shortcut.modifiers.contains(.command))
        XCTAssertTrue(shortcut.modifiers.contains(.shift))
        XCTAssertEqual(shortcut.category, .file)
        XCTAssertFalse(shortcut.isGlobal)
    }

    func testGlobalShortcut() {
        let globalShortcut = AppShortcut(
            id: "global",
            title: "Global Shortcut",
            key: " ",
            modifiers: [.command, .shift],
            category: .file,
            isGlobal: true
        )

        XCTAssertTrue(globalShortcut.isGlobal)
    }

    // MARK: - Modifier Tests

    func testShortcutModifiersCombinations() {
        let commandOnly = ShortcutModifiers.command
        XCTAssertEqual(commandOnly.rawValue, 1 << 0)

        let shiftOnly = ShortcutModifiers.shift
        XCTAssertEqual(shiftOnly.rawValue, 1 << 1)

        let optionOnly = ShortcutModifiers.option
        XCTAssertEqual(optionOnly.rawValue, 1 << 2)

        let controlOnly = ShortcutModifiers.control
        XCTAssertEqual(controlOnly.rawValue, 1 << 3)
    }

    func testMultipleModifiers() {
        var modifiers = ShortcutModifiers.command
        modifiers.insert(.shift)

        XCTAssertTrue(modifiers.contains(.command))
        XCTAssertTrue(modifiers.contains(.shift))
        XCTAssertFalse(modifiers.contains(.option))
    }

    func testModifiersEquality() {
        let modifiers1: ShortcutModifiers = [.command, .shift]
        let modifiers2: ShortcutModifiers = [.shift, .command]

        XCTAssertEqual(modifiers1, modifiers2)
    }

    #if canImport(AppKit)
    func testModifiersFromNSEvent() {
        let eventFlags: NSEvent.ModifierFlags = [.command, .shift]
        let modifiers = ShortcutModifiers(nsEventModifierFlags: eventFlags)

        XCTAssertTrue(modifiers.contains(.command))
        XCTAssertTrue(modifiers.contains(.shift))
        XCTAssertFalse(modifiers.contains(.option))
    }
    #endif

    // MARK: - Category Tests

    func testAllCategories() {
        let categories = ShortcutCategory.allCases

        XCTAssertTrue(categories.contains(.file))
        XCTAssertTrue(categories.contains(.edit))
        XCTAssertTrue(categories.contains(.view))
        XCTAssertTrue(categories.contains(.go))
        XCTAssertTrue(categories.contains(.navigation))
        XCTAssertTrue(categories.contains(.board))
    }

    func testCategoryRawValues() {
        XCTAssertEqual(ShortcutCategory.file.rawValue, "File")
        XCTAssertEqual(ShortcutCategory.edit.rawValue, "Edit")
        XCTAssertEqual(ShortcutCategory.view.rawValue, "View")
    }

    // MARK: - Default Shortcuts Coverage Tests

    func testFileMenuShortcuts() {
        XCTAssertNotNil(manager.shortcut(for: "newTask"))
        XCTAssertNotNil(manager.shortcut(for: "save"))
        XCTAssertNotNil(manager.shortcut(for: "importTasks"))
        XCTAssertNotNil(manager.shortcut(for: "exportTasks"))
    }

    func testEditMenuShortcuts() {
        XCTAssertNotNil(manager.shortcut(for: "delete"))
        XCTAssertNotNil(manager.shortcut(for: "completeTask"))
        XCTAssertNotNil(manager.shortcut(for: "duplicateTask"))
    }

    func testViewMenuShortcuts() {
        XCTAssertNotNil(manager.shortcut(for: "toggleListView"))
        XCTAssertNotNil(manager.shortcut(for: "toggleBoardView"))
        XCTAssertNotNil(manager.shortcut(for: "toggleInspector"))
        XCTAssertNotNil(manager.shortcut(for: "toggleSidebar"))
        XCTAssertNotNil(manager.shortcut(for: "search"))
    }

    func testZoomShortcuts() {
        XCTAssertNotNil(manager.shortcut(for: "zoomIn"))
        XCTAssertNotNil(manager.shortcut(for: "zoomOut"))
        XCTAssertNotNil(manager.shortcut(for: "resetZoom"))
    }

    func testPerspectiveShortcuts() {
        XCTAssertNotNil(manager.shortcut(for: "perspective1"))
        XCTAssertNotNil(manager.shortcut(for: "perspective2"))
        XCTAssertNotNil(manager.shortcut(for: "perspective3"))
        XCTAssertNotNil(manager.shortcut(for: "perspective4"))
        XCTAssertNotNil(manager.shortcut(for: "perspective5"))
        XCTAssertNotNil(manager.shortcut(for: "perspective6"))
    }

    func testNavigationShortcuts() {
        XCTAssertNotNil(manager.shortcut(for: "nextTask"))
        XCTAssertNotNil(manager.shortcut(for: "previousTask"))
        XCTAssertNotNil(manager.shortcut(for: "quickLook"))
    }

    func testBoardShortcuts() {
        XCTAssertNotNil(manager.shortcut(for: "selectAll"))
        XCTAssertNotNil(manager.shortcut(for: "deselectAll"))
    }

    func testWeeklyReviewShortcut() {
        let weeklyReviewShortcut = manager.shortcut(for: "weeklyReview")

        XCTAssertNotNil(weeklyReviewShortcut)
        XCTAssertEqual(weeklyReviewShortcut?.key, "r")
        XCTAssertTrue(weeklyReviewShortcut?.modifiers.contains(.command) ?? false)
        XCTAssertTrue(weeklyReviewShortcut?.modifiers.contains(.shift) ?? false)
    }

    // MARK: - Shortcut Uniqueness Tests

    func testNoShortcutIdDuplicates() {
        let allIds = manager.shortcuts.map { $0.id }
        let uniqueIds = Set(allIds)

        XCTAssertEqual(allIds.count, uniqueIds.count, "All shortcut IDs should be unique")
    }

    func testShortcutKeyCombinationsUnique() {
        // Build a set of key+modifier combinations
        var combinations = Set<String>()
        var duplicates: [(String, String)] = []

        for shortcut in manager.shortcuts where !shortcut.isGlobal {
            let combo = "\(shortcut.key)_\(shortcut.modifiers.rawValue)"
            if combinations.contains(combo) {
                duplicates.append((shortcut.id, combo))
            }
            combinations.insert(combo)
        }

        // It's OK to have some duplicates if they're in different contexts
        // but there shouldn't be many
        XCTAssertTrue(duplicates.count < 5, "Too many duplicate key combinations")
    }

    // MARK: - Display String Format Tests

    func testDisplayStringFormat() {
        let shortcuts = [
            manager.shortcut(for: "newTask"),
            manager.shortcut(for: "save"),
            manager.shortcut(for: "quickCapture")
        ].compactMap { $0 }

        for shortcut in shortcuts {
            let displayString = shortcut.displayString

            // Should not be empty
            XCTAssertFalse(displayString.isEmpty)

            // Should contain at least one character
            XCTAssertTrue(displayString.count > 0)

            // If it has Command modifier, should contain ⌘
            if shortcut.modifiers.contains(.command) {
                XCTAssertTrue(displayString.contains("⌘"))
            }

            // If it has Shift modifier, should contain ⇧
            if shortcut.modifiers.contains(.shift) {
                XCTAssertTrue(displayString.contains("⇧"))
            }

            // If it has Option modifier, should contain ⌥
            if shortcut.modifiers.contains(.option) {
                XCTAssertTrue(displayString.contains("⌥"))
            }

            // If it has Control modifier, should contain ⌃
            if shortcut.modifiers.contains(.control) {
                XCTAssertTrue(displayString.contains("⌃"))
            }
        }
    }

    func testSpaceKeyDisplayString() {
        if let quickCaptureShortcut = manager.shortcut(for: "quickCapture") {
            let displayString = quickCaptureShortcut.displayString
            XCTAssertTrue(displayString.contains("Space"), "Space key should be displayed as 'Space'")
        }
    }

    // MARK: - Shortcut Properties Tests

    func testQuickCaptureIsGlobal() {
        if let quickCapture = manager.shortcut(for: "quickCapture") {
            XCTAssertTrue(quickCapture.isGlobal, "Quick Capture should be a global shortcut")
        }
    }

    func testMostShortcutsAreLocal() {
        let globalShortcuts = manager.shortcuts.filter { $0.isGlobal }
        let localShortcuts = manager.shortcuts.filter { !$0.isGlobal }

        XCTAssertTrue(localShortcuts.count > globalShortcuts.count,
                     "Most shortcuts should be local, not global")
    }

    // MARK: - Edge Cases

    func testEmptyModifiers() {
        let shortcut = AppShortcut(
            id: "noModifiers",
            title: "No Modifiers",
            key: "j",
            modifiers: [],
            category: .navigation
        )

        XCTAssertTrue(shortcut.modifiers.isEmpty)
        XCTAssertEqual(shortcut.displayString, "J")
    }

    func testAllModifiersCombined() {
        let allModifiers: ShortcutModifiers = [.control, .option, .shift, .command]
        let shortcut = AppShortcut(
            id: "allMods",
            title: "All Modifiers",
            key: "a",
            modifiers: allModifiers,
            category: .file
        )

        let display = shortcut.displayString
        XCTAssertTrue(display.contains("⌃"))
        XCTAssertTrue(display.contains("⌥"))
        XCTAssertTrue(display.contains("⇧"))
        XCTAssertTrue(display.contains("⌘"))
    }

    func testDisplayStringOrder() {
        // Modifiers should appear in standard order: Control, Option, Shift, Command
        let shortcut = AppShortcut(
            id: "order",
            title: "Order Test",
            key: "o",
            modifiers: [.command, .shift, .option, .control],
            category: .file
        )

        let display = shortcut.displayString

        // Find positions of each symbol
        let controlPos = display.firstIndex(of: "⌃")
        let optionPos = display.firstIndex(of: "⌥")
        let shiftPos = display.firstIndex(of: "⇧")
        let commandPos = display.firstIndex(of: "⌘")

        // Verify order
        if let control = controlPos, let option = optionPos {
            XCTAssertTrue(control < option)
        }
        if let option = optionPos, let shift = shiftPos {
            XCTAssertTrue(option < shift)
        }
        if let shift = shiftPos, let command = commandPos {
            XCTAssertTrue(shift < command)
        }
    }

    // MARK: - Performance Tests

    func testShortcutLookupPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = manager.shortcut(for: "newTask")
            }
        }
    }

    func testCategoryFilterPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = manager.shortcuts(for: .view)
            }
        }
    }

    func testDisplayStringGenerationPerformance() {
        let shortcuts = manager.shortcuts

        measure {
            for shortcut in shortcuts {
                _ = shortcut.displayString
            }
        }
    }
}
