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

    /// Global data manager (single source of truth)
    @StateObject private var dataManager = DataManager.shared

    /// Configuration manager
    @StateObject private var configManager = ConfigurationManager.shared

    /// Global hotkey manager for quick capture
    @StateObject private var hotkeyManager = GlobalHotkeyManager()

    /// Flag to show/hide quick capture window
    @State private var showQuickCapture = false

    /// Initialization state
    @State private var isInitialized = false
    @State private var initializationError: Error?
    @State private var showInitializationError = false

    // MARK: - Scenes

    var body: some Scene {
        // Main application window
        WindowGroup {
            Group {
                if isInitialized,
                   let taskStore = dataManager.taskStore,
                   let boardStore = dataManager.boardStore {
                    ContentView()
                        .environmentObject(taskStore)
                        .environmentObject(boardStore)
                        .environmentObject(dataManager)
                        .environmentObject(configManager)
                        .frame(minWidth: 900, minHeight: 600)
                } else if isInitialized {
                    // Initialization completed but stores not ready - show error
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)

                        Text("Initialization Error")
                            .font(.title)

                        Text("Data stores failed to initialize properly. Please restart the application.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)

                        Button("Quit") {
                            NSApplication.shared.terminate(nil)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(width: 400, height: 300)
                } else {
                    VStack(spacing: 20) {
                        ProgressView("Loading StickyToDo...")
                            .controlSize(.large)

                        if let error = initializationError {
                            Text("Error: \(error.localizedDescription)")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .frame(width: 400, height: 200)
                }
            }
            .onAppear {
                initializeApp()
                setupHotkeys()
            }
            .alert("Initialization Error", isPresented: $showInitializationError) {
                Button("OK") {}
            } message: {
                if let error = initializationError {
                    Text(error.localizedDescription)
                }
            }
        }
        .commands {
            commandMenus
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .handlesExternalEvents(matching: ["main"])

        // Quick Capture window
        WindowGroup("Quick Capture", id: "quick-capture", for: Bool.self) { $showing in
            if isInitialized,
               let taskStore = dataManager.taskStore {
                QuickCaptureView(
                    recentProjects: Array(taskStore.projects.prefix(5)),
                    recentContexts: Array(taskStore.contexts.prefix(5)).map {
                        Context.defaults.first(where: { $0.name == $0 }) ?? Context(name: $0, icon: "📍", color: "blue")
                    },
                    onCreateTask: { task in
                        handleQuickCaptureTask(task)
                    },
                    onClose: {
                        closeQuickCaptureWindow()
                    }
                )
                .environmentObject(taskStore)
                .environmentObject(dataManager)
            } else {
                ProgressView("Loading...")
                    .frame(width: 200, height: 100)
            }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .handlesExternalEvents(matching: ["quick-capture"])

        // Settings window
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(configManager)
                .environmentObject(dataManager)
        }
        #endif
    }

    // MARK: - Initialization

    /// Initializes the app and data manager
    private func initializeApp() {
        guard !isInitialized else { return }

        Task {
            do {
                // Get data directory from configuration
                let dataDirectory = configManager.dataDirectory

                // Initialize DataManager
                try await dataManager.initialize(rootDirectory: dataDirectory)

                // Enable logging if configured
                dataManager.enableLogging = configManager.enableLogging
                dataManager.enableFileWatching = configManager.enableFileWatching

                // Perform first-run setup if needed
                if configManager.isFirstRun {
                    dataManager.performFirstRunSetup(createSampleData: true)
                    configManager.isFirstRun = false
                }

                await MainActor.run {
                    isInitialized = true
                }
            } catch {
                await MainActor.run {
                    initializationError = error
                    showInitializationError = true
                }
            }
        }
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
            // Load hotkey from configuration
            let hotkeyConfig = HotkeyConfig(
                keyCode: configManager.quickCaptureHotkey,
                modifiers: modifierFlagsFromBits(configManager.quickCaptureHotkeyModifiers)
            )
            hotkeyManager.updateHotkey(hotkeyConfig)
            hotkeyManager.startMonitoring()

            // Watch for hotkey presses
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("HotkeyPressed"),
                object: nil,
                queue: .main
            ) { _ in
                openQuickCaptureWindow()
            }

            // Watch for hotkey changes from settings
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("hotkeyChanged"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self else { return }
                if let keyCode = notification.userInfo?["keyCode"] as? UInt16,
                   let modifiers = notification.userInfo?["modifiers"] as? UInt {
                    let newConfig = HotkeyConfig(
                        keyCode: keyCode,
                        modifiers: self.modifierFlagsFromBits(modifiers)
                    )
                    self.hotkeyManager.updateHotkey(newConfig)
                    print("✅ Hotkey updated to: \(newConfig.description)")
                }
            }
        } else {
            // Show permission alert on first launch
            GlobalHotkeyManager.showPermissionAlertIfNeeded()
        }
    }

    /// Converts modifier bit flags to NSEvent.ModifierFlags
    private func modifierFlagsFromBits(_ bits: UInt) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if bits & 0x001 != 0 { flags.insert(.control) }
        if bits & 0x008 != 0 { flags.insert(.shift) }
        if bits & 0x020 != 0 { flags.insert(.option) }
        if bits & 0x100 != 0 { flags.insert(.command) }
        return flags
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
        guard isInitialized else { return }

        // Add the task to the data store
        dataManager.taskStore.add(task)
        print("Quick capture task created: \(task.title)")
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
        guard isInitialized else { return }

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
