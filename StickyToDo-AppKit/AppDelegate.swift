//
//  AppDelegate.swift
//  StickyToDo-AppKit
//
//  Application delegate for StickyToDo AppKit app.
//  Handles app launch, menu setup, and global hotkeys.
//

import Cocoa
import UniformTypeIdentifiers
import UserNotifications
import StickyToDoCore

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Shared Instance (for App Intents)

    /// Shared instance for App Intents to access task store and managers
    static weak var shared: AppDelegate?

    // MARK: - Properties

    /// Main window controller
    private var mainWindowController: MainWindowController!

    /// Quick capture window controller
    private var quickCaptureController: QuickCaptureWindowController!

    /// Notification manager
    private let notificationManager = NotificationManager.shared

    /// Data manager for accessing stores
    private let dataManager = DataManager.shared

    /// Import manager for task imports
    private let importManager = ImportManager()

    /// Export manager for task exports
    private let exportManager = ExportManager()

    /// Time tracking manager for timer operations (exposed for App Intents)
    private(set) var timeTrackingManager: TimeTrackingManager!

    // MARK: - App Intents Compatibility

    /// TaskStore accessor for App Intents
    var taskStore: TaskStore? {
        return dataManager.taskStore
    }

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Set shared instance for App Intents
        AppDelegate.shared = self

        // Initialize time tracking manager
        timeTrackingManager = TimeTrackingManager()

        // Setup notifications
        setupNotifications()

        // Create main window
        mainWindowController = MainWindowController()
        mainWindowController.showWindow(nil)

        // Create quick capture window
        quickCaptureController = QuickCaptureWindowController()
        quickCaptureController.delegate = self

        // Register global hotkey
        quickCaptureController.registerHotKey()

        // Setup menu bar
        setupMenuBar()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Cleanup
        quickCaptureController.unregisterHotKey()

        // Clear shared instance
        AppDelegate.shared = nil

        // Save all tasks to ensure notifications are persisted
        // This would be handled by the TaskStore in a real implementation
    }

    // MARK: - Notification Setup

    private func setupNotifications() {
        // Register notification categories with actions
        let completeAction = UNNotificationAction(
            identifier: NotificationAction.complete.rawValue,
            title: "Complete",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze.rawValue,
            title: "Snooze 1 Hour",
            options: []
        )

        let taskCategory = UNNotificationCategory(
            identifier: NotificationCategory.task.rawValue,
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let weeklyReviewCategory = UNNotificationCategory(
            identifier: NotificationCategory.weeklyReview.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let timerCategory = UNNotificationCategory(
            identifier: NotificationCategory.timer.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            taskCategory,
            weeklyReviewCategory,
            timerCategory
        ])

        // Set delegate (NotificationManager already sets itself as delegate)
        // Check authorization status
        Task {
            await notificationManager.checkAuthorizationStatus()

            // Request permission on first launch if not determined
            if notificationManager.authorizationStatus == .notDetermined {
                _ = await notificationManager.requestAuthorization()
            }
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        let mainMenu = NSMenu()

        // App Menu
        let appMenu = NSMenuItem()
        appMenu.submenu = createAppMenu()
        mainMenu.addItem(appMenu)

        // File Menu
        let fileMenu = NSMenuItem()
        fileMenu.submenu = createFileMenu()
        mainMenu.addItem(fileMenu)

        // Edit Menu
        let editMenu = NSMenuItem()
        editMenu.submenu = createEditMenu()
        mainMenu.addItem(editMenu)

        // View Menu
        let viewMenu = NSMenuItem()
        viewMenu.submenu = createViewMenu()
        mainMenu.addItem(viewMenu)

        // Go Menu
        let goMenu = NSMenuItem()
        goMenu.submenu = createGoMenu()
        mainMenu.addItem(goMenu)

        // Window Menu
        let windowMenu = NSMenuItem()
        windowMenu.submenu = createWindowMenu()
        mainMenu.addItem(windowMenu)

        // Help Menu
        let helpMenu = NSMenuItem()
        helpMenu.submenu = createHelpMenu()
        mainMenu.addItem(helpMenu)

        NSApp.mainMenu = mainMenu
    }

    private func createAppMenu() -> NSMenu {
        let menu = NSMenu(title: "StickyToDo")

        menu.addItem(NSMenuItem(title: "About StickyToDo", action: #selector(showAbout(_:)), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences(_:)), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Hide StickyToDo", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        menu.addItem({
            let item = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
            item.keyEquivalentModifierMask = [.command, .option]
            return item
        }())
        menu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit StickyToDo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        return menu
    }

    private func createFileMenu() -> NSMenu {
        let menu = NSMenu(title: "File")

        menu.addItem(NSMenuItem(title: "New Task", action: #selector(newTask(_:)), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "Quick Capture", action: #selector(showQuickCapture(_:)), keyEquivalent: " ") {
            $0.keyEquivalentModifierMask = [.command, .shift]
        })
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Open Folder...", action: #selector(openDocument(_:)), keyEquivalent: "o"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Import Tasks...", action: #selector(importTasks(_:)), keyEquivalent: "i") {
            $0.keyEquivalentModifierMask = [.command, .shift]
        })
        menu.addItem(NSMenuItem(title: "Export Tasks...", action: #selector(exportTasks(_:)), keyEquivalent: "e") {
            $0.keyEquivalentModifierMask = [.command, .shift]
        })
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Save", action: #selector(save(_:)), keyEquivalent: "s"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))

        return menu
    }

    private func createEditMenu() -> NSMenu {
        let menu = NSMenu(title: "Edit")

        menu.addItem(NSMenuItem(title: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z"))
        menu.addItem(NSMenuItem(title: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        menu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(deleteTask(_:)), keyEquivalent: "\u{7F}"))
        menu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Complete Task", action: #selector(completeTask(_:)), keyEquivalent: "\r") {
            $0.keyEquivalentModifierMask = [.command]
        })
        menu.addItem(NSMenuItem(title: "Duplicate Task", action: #selector(duplicateTask(_:)), keyEquivalent: "d"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Find...", action: #selector(performFind(_:)), keyEquivalent: "f"))
        menu.addItem(NSMenuItem(title: "Find Next", action: #selector(performFindNext(_:)), keyEquivalent: "g"))
        menu.addItem(NSMenuItem(title: "Find Previous", action: #selector(performFindPrevious(_:)), keyEquivalent: "G"))

        return menu
    }

    private func createViewMenu() -> NSMenu {
        let menu = NSMenu(title: "View")

        menu.addItem(NSMenuItem(title: "List View", action: #selector(showListView(_:)), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Board View", action: #selector(showBoardView(_:)), keyEquivalent: "b"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Activity Log", action: #selector(showActivityLog(_:)), keyEquivalent: "a") {
            $0.keyEquivalentModifierMask = [.command, .shift]
        })
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Toggle Inspector", action: #selector(toggleInspector(_:)), keyEquivalent: "i") {
            $0.keyEquivalentModifierMask = [.command, .option]
        })
        menu.addItem(NSMenuItem(title: "Toggle Sidebar", action: #selector(toggleSidebar(_:)), keyEquivalent: "s") {
            $0.keyEquivalentModifierMask = [.command, .option]
        })
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Search", action: #selector(performFind(_:)), keyEquivalent: "f"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Zoom In", action: #selector(zoomIn(_:)), keyEquivalent: "+"))
        menu.addItem(NSMenuItem(title: "Zoom Out", action: #selector(zoomOut(_:)), keyEquivalent: "-"))
        menu.addItem(NSMenuItem(title: "Reset Zoom", action: #selector(zoomActual(_:)), keyEquivalent: "0"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refresh(_:)), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f") {
            $0.keyEquivalentModifierMask = [.command, .control]
        })

        return menu
    }

    private func createGoMenu() -> NSMenu {
        let menu = NSMenu(title: "Go")

        menu.addItem(NSMenuItem(title: "Inbox", action: #selector(goToInbox(_:)), keyEquivalent: "1"))
        menu.addItem(NSMenuItem(title: "Today", action: #selector(goToToday(_:)), keyEquivalent: "2"))
        menu.addItem(NSMenuItem(title: "Upcoming", action: #selector(goToUpcoming(_:)), keyEquivalent: "3"))
        menu.addItem(NSMenuItem(title: "Someday", action: #selector(goToSomeday(_:)), keyEquivalent: "4"))
        menu.addItem(NSMenuItem(title: "Completed", action: #selector(goToCompleted(_:)), keyEquivalent: "5"))
        menu.addItem(NSMenuItem(title: "Boards", action: #selector(goToBoards(_:)), keyEquivalent: "6"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "All Tasks", action: #selector(goToAllTasks(_:)), keyEquivalent: "0") {
            $0.keyEquivalentModifierMask = [.command, .shift]
        })

        return menu
    }

    private func createWindowMenu() -> NSMenu {
        let menu = NSMenu(title: "Window")

        menu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: ""))

        NSApp.windowsMenu = menu
        return menu
    }

    private func createHelpMenu() -> NSMenu {
        let menu = NSMenu(title: "Help")

        menu.addItem(NSMenuItem(title: "StickyToDo Help", action: #selector(showHelp(_:)), keyEquivalent: "?"))
        menu.addItem(NSMenuItem(title: "Keyboard Shortcuts", action: #selector(showKeyboardShortcuts(_:)), keyEquivalent: "/"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Report an Issue...", action: #selector(reportIssue(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "View on GitHub...", action: #selector(viewOnGitHub(_:)), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Performance Monitor...", action: #selector(showPerformanceMonitor(_:)), keyEquivalent: ""))

        return menu
    }

    // MARK: - Menu Actions

    @objc private func showAbout(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(sender)
    }

    @objc private func showPreferences(_ sender: Any?) {
        // Show preferences window
        print("Show preferences")
    }

    @objc private func newTask(_ sender: Any?) {
        // Create new task in main window
        print("New task")
    }

    @objc private func showQuickCapture(_ sender: Any?) {
        quickCaptureController.show()
    }

    @objc private func openDocument(_ sender: Any?) {
        // Show open panel for opening a StickyToDo folder
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Open StickyToDo Folder"
        openPanel.message = "Select a folder containing StickyToDo markdown files"

        openPanel.begin { [weak self] response in
            guard let self = self else { return }

            if response == .OK, let url = openPanel.url {
                print("Open folder: \(url.path)")

                // Reinitialize data manager with new directory
                Task {
                    do {
                        try await self.dataManager.initialize(rootDirectory: url)

                        await MainActor.run {
                            // Update the main window with new data
                            self.mainWindowController?.refreshData()

                            // Show success alert
                            let alert = NSAlert()
                            alert.messageText = "Folder Opened"
                            alert.informativeText = "Successfully loaded \(self.dataManager.statistics.totalTasks) tasks and \(self.dataManager.statistics.totalBoards) boards from \(url.lastPathComponent)"
                            alert.alertStyle = .informational
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    } catch {
                        await MainActor.run {
                            let alert = NSAlert()
                            alert.messageText = "Error Opening Folder"
                            alert.informativeText = "Failed to load tasks from \(url.lastPathComponent): \(error.localizedDescription)"
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                }
            }
        }
    }

    @objc private func performFind(_ sender: Any?) {
        // Focus search field
        print("Find")
    }

    @objc private func performFindNext(_ sender: Any?) {
        print("Find next")
    }

    @objc private func performFindPrevious(_ sender: Any?) {
        print("Find previous")
    }

    @objc private func showListView(_ sender: Any?) {
        print("Show list view")
    }

    @objc private func showBoardView(_ sender: Any?) {
        print("Show board view")
    }

    @objc private func showActivityLog(_ sender: Any?) {
        mainWindowController?.showActivityLog()
    }

    @objc private func toggleInspector(_ sender: Any?) {
        print("Toggle inspector")
        mainWindowController?.toggleInspector()
    }

    @objc private func zoomIn(_ sender: Any?) {
        print("Zoom in")
    }

    @objc private func zoomOut(_ sender: Any?) {
        print("Zoom out")
    }

    @objc private func zoomActual(_ sender: Any?) {
        print("Zoom actual")
    }

    @objc private func save(_ sender: Any?) {
        print("Save")

        // Save all pending changes immediately
        do {
            try dataManager.saveBeforeQuit()

            // Show brief success notification (optional)
            let notification = NSUserNotification()
            notification.title = "Saved"
            notification.informativeText = "All changes have been saved"
            notification.soundName = nil
            NSUserNotificationCenter.default.deliver(notification)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Save Failed"
            alert.informativeText = "Failed to save tasks: \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc private func importTasks(_ sender: Any?) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.json, .plainText]
        openPanel.prompt = "Import Tasks"
        openPanel.message = "Select a file to import tasks from (JSON, CSV, TaskPaper, etc.)"

        openPanel.begin { [weak self] response in
            guard let self = self else { return }

            if response == .OK, let url = openPanel.url {
                print("Import from: \(url.path)")

                // Create import options with auto-detection
                var options = ImportOptions(format: .json)
                options.autoDetect = true
                options.skipErrors = true

                // Show progress window
                Task {
                    do {
                        let result = try await self.importManager.importTasks(from: url, options: options)

                        await MainActor.run {
                            // Add imported tasks to store
                            for task in result.tasks {
                                self.dataManager.taskStore.add(task)
                            }

                            // Refresh the main window
                            self.mainWindowController?.refreshData()

                            // Show success alert with details
                            let alert = NSAlert()
                            alert.messageText = "Import Successful"
                            var message = "Imported \(result.importedCount) task(s) from \(url.lastPathComponent)"

                            if !result.warnings.isEmpty {
                                message += "\n\nWarnings:\n" + result.warnings.joined(separator: "\n")
                            }

                            if !result.errors.isEmpty {
                                message += "\n\nErrors (\(result.errors.count)):\n" + result.errors.prefix(3).map { $0.localizedDescription }.joined(separator: "\n")
                                if result.errors.count > 3 {
                                    message += "\n...and \(result.errors.count - 3) more"
                                }
                            }

                            alert.informativeText = message
                            alert.alertStyle = result.errors.isEmpty ? .informational : .warning
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    } catch {
                        await MainActor.run {
                            let alert = NSAlert()
                            alert.messageText = "Import Failed"
                            alert.informativeText = "Failed to import tasks from \(url.lastPathComponent): \(error.localizedDescription)"
                            alert.alertStyle = .critical
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                }
            }
        }
    }

    @objc private func exportTasks(_ sender: Any?) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "tasks.json"
        savePanel.prompt = "Export Tasks"
        savePanel.message = "Choose a location to save your tasks"

        savePanel.begin { [weak self] response in
            guard let self = self else { return }

            if response == .OK, let url = savePanel.url {
                print("Export to: \(url.path)")

                // Create export options
                var options = ExportOptions(
                    format: .json,
                    filename: url.deletingPathExtension().lastPathComponent
                )
                options.includeCompleted = true
                options.includeNotes = true

                // Get all tasks from the store
                let tasks = self.dataManager.taskStore.tasks

                Task {
                    do {
                        let result = try await self.exportManager.export(
                            tasks: tasks,
                            to: url,
                            options: options
                        )

                        await MainActor.run {
                            // Show success alert
                            let alert = NSAlert()
                            alert.messageText = "Export Successful"
                            var message = "Exported \(result.taskCount) task(s) to \(result.fileURL.lastPathComponent)"

                            if result.fileSize > 0 {
                                let formatter = ByteCountFormatter()
                                formatter.countStyle = .file
                                message += "\nFile size: \(formatter.string(fromByteCount: result.fileSize))"
                            }

                            if !result.warnings.isEmpty {
                                message += "\n\nWarnings:\n" + result.warnings.joined(separator: "\n")
                            }

                            alert.informativeText = message
                            alert.alertStyle = .informational
                            alert.addButton(withTitle: "OK")
                            alert.addButton(withTitle: "Reveal in Finder")

                            let response = alert.runModal()
                            if response == .alertSecondButtonReturn {
                                NSWorkspace.shared.activateFileViewerSelecting([result.fileURL])
                            }
                        }
                    } catch {
                        await MainActor.run {
                            let alert = NSAlert()
                            alert.messageText = "Export Failed"
                            alert.informativeText = "Failed to export tasks: \(error.localizedDescription)"
                            alert.alertStyle = .critical
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                }
            }
        }
    }

    @objc private func deleteTask(_ sender: Any?) {
        print("Delete task")

        // Get the selected task from the main window
        guard let selectedTask = mainWindowController?.getSelectedTask() else {
            NSSound.beep()
            return
        }

        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Delete Task"
        alert.informativeText = "Are you sure you want to delete '\(selectedTask.title)'? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            dataManager.deleteTask(selectedTask)
            mainWindowController?.refreshData()
        }
    }

    @objc private func completeTask(_ sender: Any?) {
        print("Complete task")

        // Get the selected task from the main window
        guard let selectedTask = mainWindowController?.getSelectedTask() else {
            NSSound.beep()
            return
        }

        // Toggle completion status
        var updatedTask = selectedTask
        if updatedTask.status == .completed {
            updatedTask.reopen()
        } else {
            updatedTask.complete()
        }

        dataManager.updateTask(updatedTask)
        mainWindowController?.refreshData()
    }

    @objc private func duplicateTask(_ sender: Any?) {
        print("Duplicate task")

        // Get the selected task from the main window
        guard let selectedTask = mainWindowController?.getSelectedTask() else {
            NSSound.beep()
            return
        }

        // Create a duplicate of the task
        let duplicateTask = selectedTask.duplicate()
        dataManager.taskStore.add(duplicateTask)
        mainWindowController?.refreshData()
    }

    @objc private func toggleSidebar(_ sender: Any?) {
        print("Toggle sidebar")
        mainWindowController?.toggleSidebar()
    }

    @objc private func refresh(_ sender: Any?) {
        print("Refresh")

        // Reload all data from disk
        Task {
            do {
                try await dataManager.taskStore.loadAllAsync()
                try await dataManager.boardStore.loadAllAsync()

                await MainActor.run {
                    mainWindowController?.refreshData()

                    // Show brief success notification
                    let notification = NSUserNotification()
                    notification.title = "Refreshed"
                    notification.informativeText = "Reloaded all tasks and boards from disk"
                    notification.soundName = nil
                    NSUserNotificationCenter.default.deliver(notification)
                }
            } catch {
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "Refresh Failed"
                    alert.informativeText = "Failed to reload data: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }

    @objc private func goToInbox(_ sender: Any?) {
        print("Go to Inbox")
        mainWindowController?.switchToPerspective("inbox")
    }

    @objc private func goToToday(_ sender: Any?) {
        print("Go to Today")
        mainWindowController?.switchToPerspective("today")
    }

    @objc private func goToUpcoming(_ sender: Any?) {
        print("Go to Upcoming")
        mainWindowController?.switchToPerspective("upcoming")
    }

    @objc private func goToSomeday(_ sender: Any?) {
        print("Go to Someday")
        mainWindowController?.switchToPerspective("someday")
    }

    @objc private func goToCompleted(_ sender: Any?) {
        print("Go to Completed")
        mainWindowController?.switchToPerspective("completed")
    }

    @objc private func goToBoards(_ sender: Any?) {
        print("Go to Boards")
        mainWindowController?.switchToPerspective("boards")
    }

    @objc private func goToAllTasks(_ sender: Any?) {
        print("Go to All Tasks")
        mainWindowController?.switchToPerspective("all")
    }

    @objc private func showHelp(_ sender: Any?) {
        if let url = URL(string: "https://github.com/yourusername/stickytodo") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func showKeyboardShortcuts(_ sender: Any?) {
        print("Show keyboard shortcuts")

        // Create a window displaying keyboard shortcuts
        let alert = NSAlert()
        alert.messageText = "Keyboard Shortcuts"
        alert.informativeText = """
        File:
        ⌘N - New Task
        ⌘⇧Space - Quick Capture
        ⌘S - Save
        ⌘⇧I - Import Tasks
        ⌘⇧E - Export Tasks

        Edit:
        ⌘Z - Undo
        ⌘⇧Z - Redo
        ⌘Enter - Complete Task
        ⌘D - Duplicate Task
        ⌘F - Find

        View:
        ⌘L - List View
        ⌘B - Board View
        ⌘⇧A - Activity Log
        ⌘⌥I - Toggle Inspector
        ⌘⌥S - Toggle Sidebar
        ⌘R - Refresh

        Go:
        ⌘1 - Inbox
        ⌘2 - Today
        ⌘3 - Upcoming
        ⌘4 - Someday
        ⌘5 - Completed
        ⌘6 - Boards
        ⌘⇧0 - All Tasks
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func reportIssue(_ sender: Any?) {
        if let url = URL(string: "https://github.com/yourusername/stickytodo/issues") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func viewOnGitHub(_ sender: Any?) {
        if let url = URL(string: "https://github.com/yourusername/stickytodo") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func showPerformanceMonitor(_ sender: Any?) {
        PerformanceMonitor.shared.printReport()
    }
}

// MARK: - QuickCaptureDelegate

extension AppDelegate: QuickCaptureDelegate {
    func quickCaptureDidCreateTask(_ task: Task) {
        // Forward to main window to save task
        print("Quick capture created task: \(task.title)")

        // Save task through data manager
        dataManager.taskStore.add(task)

        // Refresh the main window to show the new task
        mainWindowController?.refreshData()

        // Show brief success notification
        let notification = NSUserNotification()
        notification.title = "Task Created"
        notification.informativeText = task.title
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - NSMenuItem Extension

fileprivate extension NSMenuItem {
    convenience init(title: String, action: Selector?, keyEquivalent: String, configure: ((NSMenuItem) -> Void)? = nil) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)
        configure?(self)
    }
}
