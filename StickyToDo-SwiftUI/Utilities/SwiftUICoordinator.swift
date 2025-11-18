//
//  SwiftUICoordinator.swift
//  StickyToDo-SwiftUI
//
//  SwiftUI-specific coordinator implementing AppCoordinatorProtocol.
//  Manages navigation, deep links, and window coordination for SwiftUI.
//

import SwiftUI
import Combine

/// SwiftUI implementation of the app coordinator
///
/// This coordinator:
/// - Manages NavigationPath for SwiftUI navigation
/// - Handles deep linking via URL schemes
/// - Coordinates between multiple SwiftUI windows
/// - Bridges SwiftUI @State with Combine publishers
/// - Leverages SwiftUI's automatic view updates via @Published
class SwiftUICoordinator: BaseAppCoordinator, AppCoordinatorProtocol {

    // MARK: - Navigation State

    /// Navigation path for programmatic navigation
    @Published var navigationPath = NavigationPath()

    /// Currently presented sheet
    @Published var presentedSheet: SheetType?

    /// Alert to show
    @Published var alert: AlertType?

    // MARK: - Quick Capture State

    /// Whether quick capture window is shown
    @Published var isQuickCaptureVisible = false

    /// Recent projects for quick capture suggestions
    @Published var recentProjects: [String] = []

    /// Recent contexts for quick capture suggestions
    @Published var recentContexts: [Context] = []

    // MARK: - UI State

    /// Whether inspector is visible
    @Published var isInspectorVisible = true

    /// Whether preferences are shown
    @Published var isPreferencesVisible = false

    // MARK: - Initialization

    override init(dataManager: DataManager = .shared, configManager: ConfigurationManager = .shared) {
        super.init(dataManager: dataManager, configManager: configManager)

        // Restore UI state
        isInspectorVisible = configManager.inspectorVisible

        setupDataObservers()
        setupURLHandling()
    }

    // MARK: - AppCoordinatorProtocol Implementation

    func initialize() async throws {
        // Call base initialization
        try await super.initialize()

        // Setup SwiftUI-specific components
        await MainActor.run {
            loadRecentSuggestions()
        }
    }

    func performFirstRunSetupIfNeeded() {
        if configManager.isFirstRun {
            // Show welcome sheet
            presentedSheet = .welcome
        }
    }

    // MARK: - Navigation

    func navigateToPerspective(_ perspective: Perspective) {
        super.navigateToPerspective(perspective)

        // Clear navigation path to go back to root
        navigationPath = NavigationPath()

        // Save to config
        configManager.lastPerspectiveID = perspective.id

        // Post notification for other observers
        NotificationCenter.default.post(name: .perspectiveSelected, object: perspective)
    }

    func navigateToBoard(_ board: Board) {
        super.navigateToBoard(board)

        // Navigate to board view
        navigationPath.append(NavigationDestination.board(board))

        // Save to config
        configManager.lastBoardID = board.id

        // Post notification
        NotificationCenter.default.post(name: .boardSelected, object: board)
    }

    func showInspector(for task: Task) {
        selectedTask = task
        isInspectorVisible = true
    }

    func hideInspector() {
        isInspectorVisible = false
    }

    func switchViewMode(to mode: ViewMode) {
        super.switchViewMode(to: mode)

        // In SwiftUI, view mode switching is typically handled declaratively
        // Post notification for any observers
        NotificationCenter.default.post(name: .viewModeChanged, object: mode)
    }

    // MARK: - Quick Capture

    func showQuickCapture() {
        isQuickCaptureVisible = true
        NotificationCenter.default.post(name: .quickCaptureTriggered, object: nil)
    }

    func handleQuickCaptureTask(_ task: Task) {
        // Add task to store
        taskStore.add(task)

        // Select the task
        selectedTask = task

        // Update recent suggestions
        updateRecentSuggestions(from: task)

        // Post notification
        NotificationCenter.default.post(
            name: .taskCreated,
            object: task,
            userInfo: ["source": "quickCapture"]
        )

        // Close quick capture
        isQuickCaptureVisible = false

        // Show confirmation
        showNotification(title: "Task Created", message: task.title)
    }

    // MARK: - Window Management

    func showPreferences() {
        isPreferencesVisible = true
    }

    func showMainWindow() {
        // In SwiftUI, windows are managed declaratively
        // Post notification to activate main window
        NSApp.activate(ignoringOtherApps: true)
    }

    func bringAllWindowsToFront() {
        NSApp.arrangeInFront(nil)
    }

    // MARK: - Task Operations (SwiftUI-specific)

    override func createTask(title: String, status: Status = .inbox, perspective: Perspective? = nil) -> Task {
        let task = super.createTask(title: title, status: status, perspective: perspective)

        // Post notification
        NotificationCenter.default.post(name: .taskCreated, object: task)

        // Show confirmation
        showNotification(title: "Task Created", message: task.title)

        return task
    }

    override func updateTask(_ task: Task) {
        super.updateTask(task)

        // Post notification
        NotificationCenter.default.post(name: .taskUpdated, object: task)
    }

    override func deleteTask(_ task: Task) {
        // Show confirmation alert
        alert = .deleteTask(task) { [weak self] in
            self?.performDeleteTask(task)
        }
    }

    private func performDeleteTask(_ task: Task) {
        super.deleteTask(task)

        // Post notification
        NotificationCenter.default.post(name: .taskDeleted, object: task)

        // Show confirmation
        showNotification(title: "Task Deleted", message: task.title)
    }

    override func deleteBatchTasks(_ tasks: [Task]) {
        // Show confirmation alert
        alert = .deleteTasks(tasks) { [weak self] in
            self?.performDeleteBatchTasks(tasks)
        }
    }

    private func performDeleteBatchTasks(_ tasks: [Task]) {
        super.deleteBatchTasks(tasks)

        // Show confirmation
        showNotification(title: "Tasks Deleted", message: "\(tasks.count) tasks deleted")
    }

    // MARK: - Search

    func performSearch(query: String) {
        super.performSearch(query: query)
    }

    func clearSearch() {
        super.clearSearch()
    }

    // MARK: - Deep Linking

    /// Handles incoming URLs (deep links)
    func handleURL(_ url: URL) {
        guard url.scheme == "stickytodo" else { return }

        switch url.host {
        case "quick-capture":
            showQuickCapture()

        case "add":
            handleAddTaskFromURL(url)

        case "task":
            handleShowTaskFromURL(url)

        case "board":
            handleShowBoardFromURL(url)

        case "perspective":
            handleShowPerspectiveFromURL(url)

        default:
            print("Unknown URL host: \(url.host ?? "nil")")
        }
    }

    private func handleAddTaskFromURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return }

        var title = "New Task"
        var status = Status.inbox
        var context: String?
        var project: String?
        var priority = Priority.medium

        for item in queryItems {
            switch item.name {
            case "title":
                title = item.value ?? title
            case "status":
                if let value = item.value, let s = Status(rawValue: value) {
                    status = s
                }
            case "context":
                context = item.value
            case "project":
                project = item.value
            case "priority":
                if let value = item.value, let p = Priority(rawValue: value) {
                    priority = p
                }
            default:
                break
            }
        }

        var task = Task(title: title, status: status)
        task.context = context
        task.project = project
        task.priority = priority

        handleQuickCaptureTask(task)
    }

    private func handleShowTaskFromURL(_ url: URL) {
        // Extract task ID from URL path
        let taskIDString = url.lastPathComponent
        guard let taskID = UUID(uuidString: taskIDString),
              let task = taskStore.task(withID: taskID) else { return }

        // Show task
        selectedTask = task
        showInspector(for: task)
    }

    private func handleShowBoardFromURL(_ url: URL) {
        // Extract board ID from URL path
        let boardID = url.lastPathComponent
        guard let board = boardStore.board(withID: boardID) else { return }

        // Navigate to board
        navigateToBoard(board)
    }

    private func handleShowPerspectiveFromURL(_ url: URL) {
        // Extract perspective ID from URL path
        let perspectiveID = url.lastPathComponent
        guard let perspective = Perspective.builtInPerspectives.first(where: { $0.id == perspectiveID }) else { return }

        // Navigate to perspective
        navigateToPerspective(perspective)
    }

    // MARK: - Setup

    private func setupDataObservers() {
        // Observe task store changes
        taskStore.$tasks
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Observe board store changes
        boardStore.$boards
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Set up file conflict detection callback
        dataManager.onConflictDetected = { [weak self] conflict in
            self?.handleFileConflict(conflict)
        }
    }

    /// Handles a file conflict detected by the file watcher
    private func handleFileConflict(_ conflict: FileWatcher.FileConflict) {
        // Convert FileWatcher.FileConflict to FileConflictItem and show UI
        DispatchQueue.main.async { [weak self] in
            self?.convertAndShowConflictResolution(for: conflict)
        }
    }

    /// Converts a FileWatcher conflict to FileConflictItem and shows resolution UI
    private func convertAndShowConflictResolution(for conflict: FileWatcher.FileConflict) {
        // Read the current file content from disk
        guard let theirContent = try? String(contentsOf: conflict.url, encoding: .utf8) else {
            print("Failed to read file content for conflict: \(conflict.url.path)")
            return
        }

        // Get our in-memory content as markdown
        guard let ourContent = dataManager.getMarkdownContent(for: conflict.url) else {
            print("Failed to get in-memory content for conflict: \(conflict.url.path)")
            return
        }

        // Create FileConflictItem
        let conflictItem = FileConflictItem(
            url: conflict.url,
            ourContent: ourContent,
            theirContent: theirContent,
            ourModificationDate: conflict.ourModificationDate,
            theirModificationDate: conflict.diskModificationDate
        )

        // Show conflict resolution UI
        showConflictResolution(conflicts: [conflictItem])
    }

    private func setupURLHandling() {
        // URL handling is typically set up in the App struct
        // This method is here for any additional setup needed
    }

    // MARK: - Recent Suggestions

    private func loadRecentSuggestions() {
        // Load from UserDefaults or generate from recent tasks
        let recentTasks = taskStore.tasks
            .sorted { $0.created > $1.created }
            .prefix(20)

        // Extract unique projects
        let projects = Set(recentTasks.compactMap { $0.project })
        recentProjects = Array(projects.prefix(5))

        // Extract unique contexts
        let contextNames = Set(recentTasks.compactMap { $0.context })
        recentContexts = contextNames.compactMap { name in
            Context.defaults.first { $0.name == name }
        }
    }

    private func updateRecentSuggestions(from task: Task) {
        // Add project if new
        if let project = task.project, !recentProjects.contains(project) {
            recentProjects.insert(project, at: 0)
            if recentProjects.count > 5 {
                recentProjects = Array(recentProjects.prefix(5))
            }
        }

        // Add context if new
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

    // MARK: - Conflict Resolution

    /// Shows conflict resolution UI for file conflicts
    func showConflictResolution(conflicts: [FileConflictItem]) {
        presentedSheet = .conflictResolution(conflicts)
    }

    /// Handles resolved conflicts from file watcher
    func handleResolvedConflicts(_ conflicts: [FileConflictItem]) {
        for conflict in conflicts {
            switch conflict.resolution {
            case .keepMine:
                // Keep our version - save it to disk
                try? FileManager.default.createFile(
                    atPath: conflict.url.path,
                    contents: conflict.ourContent.data(using: .utf8),
                    attributes: nil
                )

            case .keepTheirs:
                // Keep their version - reload from disk
                dataManager.reloadFile(at: conflict.url)

            case .viewBoth:
                // Create a backup with timestamp and keep both versions
                let timestamp = DateFormatter.backupFormatter.string(from: Date())
                let backupURL = conflict.url.deletingPathExtension()
                    .appendingPathExtension("backup-\(timestamp)")
                    .appendingPathExtension("md")

                try? FileManager.default.copyItem(at: conflict.url, to: backupURL)
                dataManager.reloadFile(at: conflict.url)

            case .merge(let mergedContent):
                // Save merged content
                try? mergedContent.write(to: conflict.url, atomically: true, encoding: .utf8)
                dataManager.reloadFile(at: conflict.url)

            case .unresolved:
                break
            }
        }

        // Resume file watching
        dataManager.resumeFileWatching()
    }

    // MARK: - Notifications

    private func showNotification(title: String, message: String) {
        // In SwiftUI, we can use a toast-style notification
        // For now, just print (could be extended to show actual UI notification)
        print("📣 \(title): \(message)")

        // Could also post a system notification
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }

    // MARK: - Cleanup

    override func cleanup() {
        super.cleanup()

        // Save inspector visibility
        configManager.inspectorVisible = isInspectorVisible

        // Clear navigation
        navigationPath = NavigationPath()
    }
}

// MARK: - Sheet Types

enum SheetType: Identifiable {
    case welcome
    case preferences
    case taskDetail(Task)
    case boardSettings(Board)
    case help
    case conflictResolution([FileConflictItem])

    var id: String {
        switch self {
        case .welcome: return "welcome"
        case .preferences: return "preferences"
        case .taskDetail(let task): return "task-\(task.id)"
        case .boardSettings(let board): return "board-\(board.id)"
        case .help: return "help"
        case .conflictResolution: return "conflictResolution"
        }
    }
}

// MARK: - Alert Types

enum AlertType: Identifiable {
    case deleteTask(Task, onConfirm: () -> Void)
    case deleteTasks([Task], onConfirm: () -> Void)
    case error(String, message: String)
    case info(String, message: String)

    var id: String {
        switch self {
        case .deleteTask(let task, _): return "delete-task-\(task.id)"
        case .deleteTasks(let tasks, _): return "delete-tasks-\(tasks.count)"
        case .error(let title, _): return "error-\(title)"
        case .info(let title, _): return "info-\(title)"
        }
    }
}

// MARK: - Navigation Destination

enum NavigationDestination: Hashable {
    case board(Board)
    case task(Task)
    case settings

    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.board(let b1), .board(let b2)):
            return b1.id == b2.id
        case (.task(let t1), .task(let t2)):
            return t1.id == t2.id
        case (.settings, .settings):
            return true
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .board(let board):
            hasher.combine("board")
            hasher.combine(board.id)
        case .task(let task):
            hasher.combine("task")
            hasher.combine(task.id)
        case .settings:
            hasher.combine("settings")
        }
    }
}

// MARK: - Environment Key

struct CoordinatorKey: EnvironmentKey {
    static let defaultValue: SwiftUICoordinator = SwiftUICoordinator()
}

extension EnvironmentValues {
    var coordinator: SwiftUICoordinator {
        get { self[CoordinatorKey.self] }
        set { self[CoordinatorKey.self] = newValue }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
