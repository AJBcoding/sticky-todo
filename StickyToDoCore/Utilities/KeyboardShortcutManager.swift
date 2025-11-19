//
//  KeyboardShortcutManager.swift
//  StickyToDoCore
//
//  Created on 2025-11-18.
//  Copyright © 2025 Sticky ToDo. All rights reserved.
//

import Foundation
import Combine

#if canImport(AppKit)
import AppKit
import Carbon
#endif

/// Manages keyboard shortcuts and their actions throughout the app
public class KeyboardShortcutManager: ObservableObject {
    public static let shared = KeyboardShortcutManager()

    // MARK: - Published Properties
    @Published public var shortcuts: [AppShortcut] = []

    // MARK: - Private Properties
    private var eventMonitor: Any?
    private var globalHotkeys: [EventHotKeyRef?] = []
    private var shortcutActions: [String: () -> Void] = [:]

    // MARK: - Initialization
    private init() {
        setupDefaultShortcuts()
    }

    deinit {
        #if canImport(AppKit)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        unregisterGlobalHotkeys()
        #endif
    }

    // MARK: - Setup

    private func setupDefaultShortcuts() {
        shortcuts = [
            // File Menu
            AppShortcut(
                id: "newTask",
                title: "New Task",
                key: "n",
                modifiers: [.command],
                category: .file
            ),
            AppShortcut(
                id: "quickCapture",
                title: "Quick Capture",
                key: " ",
                modifiers: [.command, .shift],
                category: .file,
                isGlobal: true
            ),
            AppShortcut(
                id: "save",
                title: "Save",
                key: "s",
                modifiers: [.command],
                category: .file
            ),
            AppShortcut(
                id: "importTasks",
                title: "Import Tasks...",
                key: "i",
                modifiers: [.command, .shift],
                category: .file
            ),
            AppShortcut(
                id: "exportTasks",
                title: "Export Tasks...",
                key: "e",
                modifiers: [.command, .shift],
                category: .file
            ),

            // Edit Menu
            AppShortcut(
                id: "delete",
                title: "Delete",
                key: "\u{7F}", // Delete key
                modifiers: [],
                category: .edit
            ),
            AppShortcut(
                id: "completeTask",
                title: "Complete Task",
                key: "\r", // Return/Enter key
                modifiers: [.command],
                category: .edit
            ),
            AppShortcut(
                id: "duplicateTask",
                title: "Duplicate Task",
                key: "d",
                modifiers: [.command],
                category: .edit
            ),

            // View Menu
            AppShortcut(
                id: "toggleListView",
                title: "List View",
                key: "l",
                modifiers: [.command],
                category: .view
            ),
            AppShortcut(
                id: "toggleBoardView",
                title: "Board View",
                key: "b",
                modifiers: [.command],
                category: .view
            ),
            AppShortcut(
                id: "toggleInspector",
                title: "Toggle Inspector",
                key: "i",
                modifiers: [.command, .option],
                category: .view
            ),
            AppShortcut(
                id: "toggleSidebar",
                title: "Toggle Sidebar",
                key: "s",
                modifiers: [.command, .option],
                category: .view
            ),
            AppShortcut(
                id: "search",
                title: "Search",
                key: "f",
                modifiers: [.command],
                category: .view
            ),
            AppShortcut(
                id: "zoomIn",
                title: "Zoom In",
                key: "+",
                modifiers: [.command],
                category: .view
            ),
            AppShortcut(
                id: "zoomOut",
                title: "Zoom Out",
                key: "-",
                modifiers: [.command],
                category: .view
            ),
            AppShortcut(
                id: "resetZoom",
                title: "Reset Zoom",
                key: "0",
                modifiers: [.command],
                category: .view
            ),

            // Go Menu (Perspectives)
            AppShortcut(
                id: "perspective1",
                title: "Inbox",
                key: "1",
                modifiers: [.command],
                category: .go
            ),
            AppShortcut(
                id: "perspective2",
                title: "Today",
                key: "2",
                modifiers: [.command],
                category: .go
            ),
            AppShortcut(
                id: "perspective3",
                title: "Upcoming",
                key: "3",
                modifiers: [.command],
                category: .go
            ),
            AppShortcut(
                id: "perspective4",
                title: "Someday",
                key: "4",
                modifiers: [.command],
                category: .go
            ),
            AppShortcut(
                id: "perspective5",
                title: "Completed",
                key: "5",
                modifiers: [.command],
                category: .go
            ),
            AppShortcut(
                id: "perspective6",
                title: "Boards",
                key: "6",
                modifiers: [.command],
                category: .go
            ),

            // GTD
            AppShortcut(
                id: "weeklyReview",
                title: "Weekly Review",
                key: "r",
                modifiers: [.command, .shift],
                category: .go
            ),

            // Navigation
            AppShortcut(
                id: "nextTask",
                title: "Next Task",
                key: "j",
                modifiers: [],
                category: .navigation
            ),
            AppShortcut(
                id: "previousTask",
                title: "Previous Task",
                key: "k",
                modifiers: [],
                category: .navigation
            ),
            AppShortcut(
                id: "quickLook",
                title: "Quick Look",
                key: " ",
                modifiers: [],
                category: .navigation
            ),

            // Board-specific
            AppShortcut(
                id: "selectAll",
                title: "Select All",
                key: "a",
                modifiers: [.command],
                category: .board
            ),
            AppShortcut(
                id: "deselectAll",
                title: "Deselect All",
                key: "d",
                modifiers: [.command, .shift],
                category: .board
            ),

            // Batch Edit Operations
            AppShortcut(
                id: "batchEditMode",
                title: "Batch Edit Mode",
                key: "e",
                modifiers: [.command, .shift],
                category: .edit
            ),
            AppShortcut(
                id: "selectAllTasks",
                title: "Select All Tasks",
                key: "a",
                modifiers: [.command],
                category: .edit
            ),
            AppShortcut(
                id: "batchComplete",
                title: "Complete Selected Tasks",
                key: "\r",
                modifiers: [.command],
                category: .edit
            ),
            AppShortcut(
                id: "batchDelete",
                title: "Delete Selected Tasks",
                key: "\u{7F}",
                modifiers: [.command],
                category: .edit
            ),
            AppShortcut(
                id: "batchSetProject",
                title: "Set Project for Selected",
                key: "p",
                modifiers: [.command, .shift],
                category: .edit
            ),
            AppShortcut(
                id: "batchSetContext",
                title: "Set Context for Selected",
                key: "c",
                modifiers: [.command, .shift],
                category: .edit
            ),
            AppShortcut(
                id: "batchFlag",
                title: "Flag Selected Tasks",
                key: "f",
                modifiers: [.command, .shift],
                category: .edit
            ),
        ]
    }

    // MARK: - Registration

    #if canImport(AppKit)
    /// Register local keyboard shortcuts (app-level)
    public func registerLocalShortcuts() {
        if eventMonitor != nil {
            NSEvent.removeMonitor(eventMonitor!)
        }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Check if this is a shortcut we handle
            if self.handleKeyEvent(event) {
                return nil // Event handled, don't pass it on
            }

            return event // Event not handled, pass it on
        }
    }

    /// Unregister local keyboard shortcuts
    public func unregisterLocalShortcuts() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// Register global keyboard shortcuts (system-wide)
    public func registerGlobalHotkeys() {
        // Get global shortcuts
        let globalShortcuts = shortcuts.filter { $0.isGlobal }

        for shortcut in globalShortcuts {
            registerGlobalHotkey(shortcut)
        }
    }

    /// Unregister all global keyboard shortcuts
    public func unregisterGlobalHotkeys() {
        for hotkey in globalHotkeys {
            if let hotkey = hotkey {
                UnregisterEventHotKey(hotkey)
            }
        }
        globalHotkeys.removeAll()
    }

    private func registerGlobalHotkey(_ shortcut: AppShortcut) {
        // Convert to Carbon key code
        guard let keyCode = carbonKeyCodeForString(shortcut.key) else {
            print("⚠️ Could not convert key '\(shortcut.key)' to Carbon key code")
            return
        }

        var modifierFlags: UInt32 = 0
        if shortcut.modifiers.contains(.command) {
            modifierFlags |= UInt32(cmdKey)
        }
        if shortcut.modifiers.contains(.shift) {
            modifierFlags |= UInt32(shiftKey)
        }
        if shortcut.modifiers.contains(.option) {
            modifierFlags |= UInt32(optionKey)
        }
        if shortcut.modifiers.contains(.control) {
            modifierFlags |= UInt32(controlKey)
        }

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x5354444F), id: UInt32(globalHotkeys.count))

        let status = RegisterEventHotKey(
            UInt32(keyCode),
            modifierFlags,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            globalHotkeys.append(hotKeyRef)
            print("✅ Registered global hotkey: \(shortcut.title)")
        } else {
            print("⚠️ Failed to register global hotkey: \(shortcut.title) (status: \(status))")
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let characters = event.charactersIgnoringModifiers ?? ""
        guard !characters.isEmpty else { return false }

        let key = characters.lowercased()
        let modifiers = ShortcutModifiers(nsEventModifierFlags: event.modifierFlags)

        // Find matching shortcut
        for shortcut in shortcuts where !shortcut.isGlobal {
            if shortcut.key.lowercased() == key && shortcut.modifiers == modifiers {
                executeShortcut(shortcut.id)
                return true
            }
        }

        return false
    }

    private func carbonKeyCodeForString(_ string: String) -> Int? {
        let keyMap: [String: Int] = [
            " ": 49, // Space
            "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3, "g": 5, "h": 4,
            "i": 34, "j": 38, "k": 40, "l": 37, "m": 46, "n": 45, "o": 31,
            "p": 35, "q": 12, "r": 15, "s": 1, "t": 17, "u": 32, "v": 9,
            "w": 13, "x": 7, "y": 16, "z": 6,
            "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23,
            "6": 22, "7": 26, "8": 28, "9": 25,
            "-": 27, "=": 24, "+": 24,
            "\r": 36, "\t": 48, "\u{7F}": 51
        ]

        return keyMap[string.lowercased()]
    }
    #endif

    // MARK: - Action Registration

    /// Register an action for a shortcut
    public func registerAction(for shortcutID: String, action: @escaping () -> Void) {
        shortcutActions[shortcutID] = action
    }

    /// Execute a shortcut action
    private func executeShortcut(_ shortcutID: String) {
        shortcutActions[shortcutID]?()
        NotificationCenter.default.post(name: .shortcutExecuted, object: shortcutID)
    }

    // MARK: - Query

    /// Get shortcut by ID
    public func shortcut(for id: String) -> AppShortcut? {
        return shortcuts.first { $0.id == id }
    }

    /// Get shortcuts for a specific category
    public func shortcuts(for category: ShortcutCategory) -> [AppShortcut] {
        return shortcuts.filter { $0.category == category }
    }

    /// Get display string for a shortcut
    public func displayString(for shortcutID: String) -> String? {
        guard let shortcut = shortcut(for: shortcutID) else { return nil }
        return shortcut.displayString
    }
}

// MARK: - Supporting Types

public struct AppShortcut: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let key: String
    public let modifiers: ShortcutModifiers
    public let category: ShortcutCategory
    public let isGlobal: Bool

    public init(
        id: String,
        title: String,
        key: String,
        modifiers: ShortcutModifiers = [],
        category: ShortcutCategory,
        isGlobal: Bool = false
    ) {
        self.id = id
        self.title = title
        self.key = key
        self.modifiers = modifiers
        self.category = category
        self.isGlobal = isGlobal
    }

    public var displayString: String {
        var parts: [String] = []

        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }

        // Format key nicely
        let displayKey: String
        switch key {
        case " ": displayKey = "Space"
        case "\r": displayKey = "↩"
        case "\t": displayKey = "⇥"
        case "\u{7F}": displayKey = "⌫"
        default: displayKey = key.uppercased()
        }

        parts.append(displayKey)
        return parts.joined()
    }
}

public struct ShortcutModifiers: OptionSet, Equatable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let command = ShortcutModifiers(rawValue: 1 << 0)
    public static let shift = ShortcutModifiers(rawValue: 1 << 1)
    public static let option = ShortcutModifiers(rawValue: 1 << 2)
    public static let control = ShortcutModifiers(rawValue: 1 << 3)

    #if canImport(AppKit)
    public init(nsEventModifierFlags flags: NSEvent.ModifierFlags) {
        var modifiers = ShortcutModifiers()
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        self = modifiers
    }
    #endif
}

public enum ShortcutCategory: String, CaseIterable {
    case file = "File"
    case edit = "Edit"
    case view = "View"
    case go = "Go"
    case navigation = "Navigation"
    case board = "Board"
    case window = "Window"
    case help = "Help"
}

// MARK: - Notifications

public extension Notification.Name {
    static let shortcutExecuted = Notification.Name("com.stickytodo.shortcutExecuted")
}
