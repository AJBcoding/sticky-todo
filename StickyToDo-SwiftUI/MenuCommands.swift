//
//  MenuCommands.swift
//  StickyToDo-SwiftUI
//
//  Created on 2025-11-18.
//  Copyright © 2025 Sticky ToDo. All rights reserved.
//

import SwiftUI

/// Custom menu commands for the SwiftUI app
struct AppMenuCommands: Commands {
    @FocusedBinding(\.selectedTasks) private var selectedTasks
    @FocusedValue(\.viewMode) private var viewMode
    @FocusedValue(\.canImportExport) private var canImportExport

    var body: some Commands {
        // Replace the default File menu
        CommandGroup(replacing: .newItem) {
            Button("New Task") {
                NotificationCenter.default.post(name: .createNewTask, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Quick Capture...") {
                NotificationCenter.default.post(name: .showQuickCapture, object: nil)
            }
            .keyboardShortcut(" ", modifiers: [.command, .shift])

            Divider()

            Button("Import Tasks...") {
                NotificationCenter.default.post(name: .importTasks, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
            .disabled(canImportExport != true)

            Button("Export Tasks...") {
                NotificationCenter.default.post(name: .exportTasks, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(canImportExport != true)
        }

        // Enhance Edit menu
        CommandGroup(after: .pasteboard) {
            Divider()

            Button("Complete Task") {
                NotificationCenter.default.post(name: .completeTask, object: nil)
            }
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(selectedTasks?.isEmpty ?? true)

            Button("Duplicate Task") {
                NotificationCenter.default.post(name: .duplicateTask, object: nil)
            }
            .keyboardShortcut("d", modifiers: .command)
            .disabled(selectedTasks?.isEmpty ?? true)

            Divider()

            Button("Delete") {
                NotificationCenter.default.post(name: .deleteTask, object: nil)
            }
            .keyboardShortcut(.delete, modifiers: [])
            .disabled(selectedTasks?.isEmpty ?? true)
        }

        // View menu
        CommandMenu("View") {
            Button("List View") {
                NotificationCenter.default.post(name: .switchToListView, object: nil)
            }
            .keyboardShortcut("l", modifiers: .command)

            Button("Board View") {
                NotificationCenter.default.post(name: .switchToBoardView, object: nil)
            }
            .keyboardShortcut("b", modifiers: .command)

            Divider()

            Toggle("Inspector", isOn: Binding(
                get: { WindowStateManager.shared.inspectorIsOpen },
                set: { WindowStateManager.shared.inspectorIsOpen = $0 }
            ))
            .keyboardShortcut("i", modifiers: [.command, .option])

            Toggle("Sidebar", isOn: Binding(
                get: { true }, // TODO: Connect to actual sidebar state
                set: { _ in NotificationCenter.default.post(name: .toggleSidebar, object: nil) }
            ))
            .keyboardShortcut("s", modifiers: [.command, .option])

            Divider()

            Button("Search") {
                NotificationCenter.default.post(name: .focusSearch, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)

            Divider()

            Button("Zoom In") {
                NotificationCenter.default.post(name: .zoomIn, object: nil)
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Zoom Out") {
                NotificationCenter.default.post(name: .zoomOut, object: nil)
            }
            .keyboardShortcut("-", modifiers: .command)

            Button("Reset Zoom") {
                NotificationCenter.default.post(name: .resetZoom, object: nil)
            }
            .keyboardShortcut("0", modifiers: .command)

            Divider()

            Button("Refresh") {
                NotificationCenter.default.post(name: .refresh, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
        }

        // Tools menu
        CommandMenu("Tools") {
            Button("Analytics Dashboard...") {
                NotificationCenter.default.post(name: .showAnalyticsDashboard, object: nil)
            }
            .keyboardShortcut("a", modifiers: [.command, .option])

            Button("Automation Rules...") {
                NotificationCenter.default.post(name: .showAutomationRules, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command, .option])

            Divider()

            Button("Calendar Settings...") {
                NotificationCenter.default.post(name: .showCalendarSettings, object: nil)
            }
            .keyboardShortcut("c", modifiers: [.command, .option])

            Button("Weekly Review...") {
                NotificationCenter.default.post(name: .showWeeklyReview, object: nil)
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
        }

        // Go menu for perspectives
        CommandMenu("Go") {
            Button("Inbox") {
                NotificationCenter.default.post(name: .switchPerspective, object: "inbox")
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Today") {
                NotificationCenter.default.post(name: .switchPerspective, object: "today")
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("Upcoming") {
                NotificationCenter.default.post(name: .switchPerspective, object: "upcoming")
            }
            .keyboardShortcut("3", modifiers: .command)

            Button("Someday") {
                NotificationCenter.default.post(name: .switchPerspective, object: "someday")
            }
            .keyboardShortcut("4", modifiers: .command)

            Button("Completed") {
                NotificationCenter.default.post(name: .switchPerspective, object: "completed")
            }
            .keyboardShortcut("5", modifiers: .command)

            Button("Boards") {
                NotificationCenter.default.post(name: .switchPerspective, object: "boards")
            }
            .keyboardShortcut("6", modifiers: .command)

            Divider()

            Button("All Tasks") {
                NotificationCenter.default.post(name: .switchPerspective, object: "all")
            }
            .keyboardShortcut("0", modifiers: [.command, .shift])
        }

        // Help menu
        CommandGroup(replacing: .help) {
            Button("Sticky ToDo Help") {
                NotificationCenter.default.post(name: .showHelp, object: nil)
            }
            .keyboardShortcut("?", modifiers: .command)

            Button("Keyboard Shortcuts") {
                NotificationCenter.default.post(name: .showKeyboardShortcuts, object: nil)
            }
            .keyboardShortcut("/", modifiers: .command)

            Divider()

            Button("Report an Issue...") {
                if let url = URL(string: "https://github.com/yourusername/sticky-todo/issues") {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("View on GitHub...") {
                if let url = URL(string: "https://github.com/yourusername/sticky-todo") {
                    NSWorkspace.shared.open(url)
                }
            }

            Divider()

            Button("About Sticky ToDo") {
                NotificationCenter.default.post(name: .showAbout, object: nil)
            }
        }

        // Toolbar commands
        CommandGroup(after: .toolbar) {
            Button("Customize Toolbar...") {
                NotificationCenter.default.post(name: .customizeToolbar, object: nil)
            }
        }
    }
}

// MARK: - Focused Values

struct SelectedTasksKey: FocusedValueKey {
    typealias Value = Set<String>
}

struct ViewModeKey: FocusedValueKey {
    typealias Value = ViewMode
}

struct CanImportExportKey: FocusedValueKey {
    typealias Value = Bool
}

extension FocusedValues {
    var selectedTasks: Binding<Set<String>>? {
        get { self[SelectedTasksKey.self] }
        set { self[SelectedTasksKey.self] = newValue }
    }

    var viewMode: ViewMode? {
        get { self[ViewModeKey.self] }
        set { self[ViewModeKey.self] = newValue }
    }

    var canImportExport: Bool? {
        get { self[CanImportExportKey.self] }
        set { self[CanImportExportKey.self] = newValue }
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let createNewTask = Notification.Name("createNewTask")
    static let showQuickCapture = Notification.Name("showQuickCapture")
    static let importTasks = Notification.Name("importTasks")
    static let exportTasks = Notification.Name("exportTasks")
    static let completeTask = Notification.Name("completeTask")
    static let duplicateTask = Notification.Name("duplicateTask")
    static let deleteTask = Notification.Name("deleteTask")
    static let switchToListView = Notification.Name("switchToListView")
    static let switchToBoardView = Notification.Name("switchToBoardView")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let focusSearch = Notification.Name("focusSearch")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let resetZoom = Notification.Name("resetZoom")
    static let refresh = Notification.Name("refresh")
    static let switchPerspective = Notification.Name("switchPerspective")
    static let showHelp = Notification.Name("showHelp")
    static let showKeyboardShortcuts = Notification.Name("showKeyboardShortcuts")
    static let showAbout = Notification.Name("showAbout")
    static let customizeToolbar = Notification.Name("customizeToolbar")
    static let showAutomationRules = Notification.Name("showAutomationRules")
    static let showWeeklyReview = Notification.Name("showWeeklyReview")
    static let showCalendarSettings = Notification.Name("showCalendarSettings")
    static let showAnalyticsDashboard = Notification.Name("showAnalyticsDashboard")
}
