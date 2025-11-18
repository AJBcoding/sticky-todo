//
//  StickyToDoApp.swift
//  StickyToDo
//
//  Main application entry point.
//

import SwiftUI

@main
struct StickyToDoApp: App {

    // MARK: - Properties

    /// Global hotkey manager for quick capture
    @StateObject private var hotkeyManager = GlobalHotkeyManager()

    /// Flag to show/hide quick capture window
    @State private var showQuickCapture = false

    /// Sample data for quick capture suggestions
    @State private var recentProjects: [String] = ["Website Redesign", "Q4 Planning"]
    @State private var recentContexts: [Context] = Context.defaults

    // MARK: - Scenes

    var body: some Scene {
        // Main application window
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    setupHotkeys()
                }
        }
        .commands {
            commandMenus
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        // Quick Capture window
        WindowGroup("Quick Capture", id: "quick-capture", for: Bool.self) { $showing in
            QuickCaptureView(
                recentProjects: recentProjects,
                recentContexts: recentContexts,
                onCreateTask: { task in
                    handleQuickCaptureTask(task)
                },
                onClose: {
                    closeQuickCaptureWindow()
                }
            )
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Settings window
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }

    // MARK: - Commands

    @CommandsBuilder
    private var commandMenus: some Commands {
        // File menu
        CommandGroup(replacing: .newItem) {
            Button("New Task") {
                // This would need to notify the main window to add a task
                // For now, we'll just print
                print("New Task requested")
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Quick Capture") {
                openQuickCaptureWindow()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Divider()
        }

        // View menu
        CommandGroup(after: .sidebar) {
            Button("Show List View") {
                // Switch to list view
            }
            .keyboardShortcut("l", modifiers: .command)

            Button("Show Board View") {
                // Switch to board view
            }
            .keyboardShortcut("b", modifiers: .command)

            Divider()

            Button("Focus Search") {
                // Focus the search field
            }
            .keyboardShortcut("f", modifiers: .command)
        }

        // Task menu
        CommandMenu("Task") {
            Button("Mark Complete") {
                // Toggle task completion
            }
            .keyboardShortcut(.return, modifiers: .command)

            Button("Flag Task") {
                // Toggle task flag
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])

            Divider()

            Button("Delete Task") {
                // Delete selected task
            }
            .keyboardShortcut(.delete, modifiers: .command)

            Button("Duplicate Task") {
                // Duplicate selected task
            }
            .keyboardShortcut("d", modifiers: .command)

            Divider()

            Menu("Change Status") {
                Button("Inbox") {}
                Button("Next Action") {}
                Button("Waiting") {}
                Button("Someday/Maybe") {}
            }

            Menu("Change Priority") {
                Button("High") {}
                Button("Medium") {}
                Button("Low") {}
            }
        }

        // Window menu
        CommandGroup(after: .windowArrangement) {
            Button("Quick Capture") {
                openQuickCaptureWindow()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        // Help menu
        CommandGroup(replacing: .help) {
            Button("StickyToDo Help") {
                // Open help documentation
                openHelp()
            }

            Button("Keyboard Shortcuts") {
                // Show keyboard shortcuts reference
                showKeyboardShortcuts()
            }
            .keyboardShortcut("/", modifiers: .command)

            Divider()

            Button("Report an Issue") {
                // Open issue tracker
                openIssueTracker()
            }

            Button("About StickyToDo") {
                // Show about window
                showAbout()
            }
        }
    }

    // MARK: - Hotkey Setup

    private func setupHotkeys() {
        // Check for accessibility permissions
        if GlobalHotkeyManager.hasAccessibilityPermissions() {
            hotkeyManager.startMonitoring()

            // Watch for hotkey presses
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("HotkeyPressed"),
                object: nil,
                queue: .main
            ) { _ in
                openQuickCaptureWindow()
            }
        } else {
            // Show permission alert on first launch
            GlobalHotkeyManager.showPermissionAlertIfNeeded()
        }
    }

    // MARK: - Quick Capture

    private func openQuickCaptureWindow() {
        // Open a new quick capture window
        if let url = URL(string: "stickytodo://quick-capture") {
            NSWorkspace.shared.open(url)
        }

        // Alternative approach: use WindowGroup binding
        showQuickCapture = true
    }

    private func closeQuickCaptureWindow() {
        showQuickCapture = false
    }

    private func handleQuickCaptureTask(_ task: Task) {
        // Save the task
        // In a real app, this would save to the data store
        print("Quick capture task created: \(task.title)")

        // Update recent projects and contexts
        if let project = task.project, !recentProjects.contains(project) {
            recentProjects.insert(project, at: 0)
            if recentProjects.count > 5 {
                recentProjects = Array(recentProjects.prefix(5))
            }
        }

        if let contextName = task.context,
           !recentContexts.contains(where: { $0.name == contextName }) {
            if let context = Context.defaults.first(where: { $0.name == contextName }) {
                recentContexts.insert(context, at: 0)
                if recentContexts.count > 5 {
                    recentContexts = Array(recentContexts.prefix(5))
                }
            }
        }
    }

    // MARK: - Menu Actions

    private func openHelp() {
        if let url = URL(string: "https://stickytodo.app/help") {
            NSWorkspace.shared.open(url)
        }
    }

    private func showKeyboardShortcuts() {
        // Show keyboard shortcuts reference window
        print("Showing keyboard shortcuts")
    }

    private func openIssueTracker() {
        if let url = URL(string: "https://github.com/yourusername/stickytodo/issues") {
            NSWorkspace.shared.open(url)
        }
    }

    private func showAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [
                .applicationName: "StickyToDo",
                .applicationVersion: "1.0.0",
                .credits: NSAttributedString(
                    string: "Visual GTD Task Manager\n\nCombining OmniFocus-style GTD with Miro's spatial organization."
                )
            ]
        )
    }
}

// MARK: - URL Scheme Handling

extension StickyToDoApp {
    /// Handles custom URL schemes (stickytodo://)
    private func handleURL(_ url: URL) {
        guard url.scheme == "stickytodo" else { return }

        switch url.host {
        case "quick-capture":
            openQuickCaptureWindow()

        case "add":
            // Parse query parameters and create task
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                handleAddTaskFromURL(queryItems)
            }

        default:
            print("Unknown URL scheme: \(url)")
        }
    }

    private func handleAddTaskFromURL(_ queryItems: [URLQueryItem]) {
        var task = Task(title: "New Task")

        for item in queryItems {
            switch item.name {
            case "title":
                task.title = item.value ?? ""
            case "context":
                task.context = item.value
            case "project":
                task.project = item.value
            case "priority":
                if let value = item.value, let priority = Priority(rawValue: value) {
                    task.priority = priority
                }
            case "status":
                if let value = item.value, let status = Status(rawValue: value) {
                    task.status = status
                }
            default:
                break
            }
        }

        handleQuickCaptureTask(task)
    }
}

// MARK: - Usage Examples

/*
 ═══════════════════════════════════════════════════════════════════════════
 KEYBOARD SHORTCUTS REFERENCE
 ═══════════════════════════════════════════════════════════════════════════

 File Operations:
 ⌘N                 New Task
 ⌘⇧N                Quick Capture (global)
 ⌘S                 Save (auto-save enabled)
 ⌘W                 Close Window

 View Navigation:
 ⌘L                 Switch to List View
 ⌘B                 Switch to Board View
 ⌘F                 Focus Search
 ⌘1-9               Jump to Sidebar Item

 Task Operations:
 ⌘↩                 Toggle Task Complete
 ⌘⇧L                Flag Task
 ⌘⌫                 Delete Task
 ⌘D                 Duplicate Task
 Space              Quick Look at Task
 Enter              Edit Task

 Selection:
 ⌘Click             Toggle Selection
 ⇧Click             Add to Selection
 ⌘A                 Select All

 Board View:
 Option+Drag        Lasso Selection
 Pinch              Zoom
 Drag Background    Pan Canvas

 Help:
 ⌘/                 Show Keyboard Shortcuts

 ═══════════════════════════════════════════════════════════════════════════
 URL SCHEME EXAMPLES
 ═══════════════════════════════════════════════════════════════════════════

 Open quick capture:
 stickytodo://quick-capture

 Add task with metadata:
 stickytodo://add?title=Call%20John&context=@phone&project=Website&priority=high

 ═══════════════════════════════════════════════════════════════════════════
 */
