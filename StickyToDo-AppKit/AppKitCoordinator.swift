//
//  AppKitCoordinator.swift
//  StickyToDo-AppKit
//
//  AppKit-specific coordinator implementing AppCoordinatorProtocol.
//  Wires MainWindowController to data stores and handles AppKit-specific coordination.
//

import Cocoa
import Combine

/// AppKit implementation of the app coordinator
///
/// This coordinator:
/// - Manages the MainWindowController and QuickCaptureWindowController
/// - Wires UI components to data stores via KVO and Combine
/// - Handles navigation between perspectives and boards
/// - Coordinates global hotkeys and menu actions
/// - Updates UI when data changes
class AppKitCoordinator: BaseAppCoordinator, AppCoordinatorProtocol {

    // MARK: - Window Controllers

    /// Main window controller
    private(set) var mainWindowController: MainWindowController?

    /// Quick capture window controller
    private(set) var quickCaptureWindowController: QuickCaptureWindowController?

    // MARK: - UI State

    /// Whether the inspector is visible
    var isInspectorVisible: Bool = true {
        didSet {
            configManager.inspectorVisible = isInspectorVisible
        }
    }

    // MARK: - Initialization

    override init(dataManager: DataManager = .shared, configManager: ConfigurationManager = .shared) {
        super.init(dataManager: dataManager, configManager: configManager)

        // Restore inspector visibility
        isInspectorVisible = configManager.inspectorVisible

        setupDataObservers()
    }

    // MARK: - AppCoordinatorProtocol Implementation

    func initialize() async throws {
        // Call base initialization
        try await super.initialize()

        // Setup AppKit-specific components on main thread
        await MainActor.run {
            setupWindowControllers()
            setupNotificationObservers()
        }
    }

    func performFirstRunSetupIfNeeded() {
        if configManager.isFirstRun {
            // Show onboarding window
            showOnboarding()
        }
    }

    // MARK: - Navigation

    func navigateToPerspective(_ perspective: Perspective) {
        super.navigateToPerspective(perspective)

        // Update main window
        mainWindowController?.showPerspective(perspective)

        // Save to config
        configManager.lastPerspectiveID = perspective.id

        // Post notification
        NotificationCenter.default.post(name: .perspectiveSelected, object: perspective)
    }

    func navigateToBoard(_ board: Board) {
        super.navigateToBoard(board)

        // Update main window
        mainWindowController?.showBoard(board)

        // Save to config
        configManager.lastBoardID = board.id

        // Post notification
        NotificationCenter.default.post(name: .boardSelected, object: board)
    }

    func showInspector(for task: Task) {
        selectedTask = task
        isInspectorVisible = true
        mainWindowController?.showInspector(for: task)
    }

    func hideInspector() {
        isInspectorVisible = false
        mainWindowController?.hideInspector()
    }

    func switchViewMode(to mode: ViewMode) {
        super.switchViewMode(to: mode)
        mainWindowController?.switchViewMode(to: mode)

        NotificationCenter.default.post(name: .viewModeChanged, object: mode)
    }

    // MARK: - Quick Capture

    func showQuickCapture() {
        if quickCaptureWindowController == nil {
            setupQuickCaptureWindow()
        }

        quickCaptureWindowController?.show()
    }

    func handleQuickCaptureTask(_ task: Task) {
        // Add task to store
        taskStore.add(task)

        // Select the task in the main window
        selectedTask = task

        // Update UI
        mainWindowController?.refreshAfterTaskCreated(task)

        // Post notification
        NotificationCenter.default.post(
            name: .taskCreated,
            object: task,
            userInfo: ["source": "quickCapture"]
        )

        // Close quick capture window
        quickCaptureWindowController?.close()
    }

    // MARK: - Window Management

    func showPreferences() {
        // Show preferences window (create if needed)
        // This would be implemented based on your preferences window setup
        NSApp.sendAction(#selector(AppDelegate.showPreferences(_:)), to: nil, from: nil)
    }

    func showMainWindow() {
        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    func bringAllWindowsToFront() {
        NSApp.arrangeInFront(nil)
    }

    // MARK: - Conflict Resolution

    private var conflictWindowController: ConflictResolutionWindowController?

    /// Shows conflict resolution UI for file conflicts
    func showConflictResolution(conflicts: [FileConflictItem]) {
        let controller = ConflictResolutionWindowController(conflicts: conflicts)
        controller.onResolutionApplied = { [weak self] resolvedConflicts in
            self?.handleResolvedConflicts(resolvedConflicts)
        }
        conflictWindowController = controller
        controller.showWindow(nil)
    }

    /// Handles resolved conflicts from file watcher
    private func handleResolvedConflicts(_ conflicts: [FileConflictItem]) {
        for conflict in conflicts {
            switch conflict.resolution {
            case .keepMine:
                // Keep our version - save it to disk
                try? conflict.ourContent.write(to: conflict.url, atomically: true, encoding: .utf8)

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
        conflictWindowController = nil
    }

    // MARK: - Onboarding

    private var onboardingWindowController: OnboardingWindowController?

    /// Shows onboarding for first-run experience
    func showOnboarding() {
        let controller = OnboardingWindowController()
        controller.onComplete = { [weak self] config in
            self?.handleOnboardingComplete(with: config)
        }
        onboardingWindowController = controller
        controller.showWindow(nil)
    }

    private func handleOnboardingComplete(with config: OnboardingConfiguration) {
        // Update data directory if changed
        if config.dataDirectory != configManager.dataDirectory {
            configManager.changeDataDirectory(to: config.dataDirectory)
        }

        // Create sample data if requested
        if config.createSampleData {
            dataManager.performFirstRunSetup(createSampleData: true)
        }

        // Mark first run as complete
        configManager.isFirstRun = false
        configManager.save()

        onboardingWindowController = nil
    }

    // MARK: - Task Operations (AppKit-specific overrides)

    override func createTask(title: String, status: Status = .inbox, perspective: Perspective? = nil) -> Task {
        let task = super.createTask(title: title, status: status, perspective: perspective)

        // Update UI
        mainWindowController?.refreshAfterTaskCreated(task)

        // Post notification
        NotificationCenter.default.post(name: .taskCreated, object: task)

        return task
    }

    override func updateTask(_ task: Task) {
        super.updateTask(task)

        // Update UI
        mainWindowController?.refreshAfterTaskUpdated(task)

        // Post notification
        NotificationCenter.default.post(name: .taskUpdated, object: task)
    }

    override func deleteTask(_ task: Task) {
        super.deleteTask(task)

        // Update UI
        mainWindowController?.refreshAfterTaskDeleted(task)

        // Post notification
        NotificationCenter.default.post(name: .taskDeleted, object: task)
    }

    // MARK: - Search

    func performSearch(query: String) {
        super.performSearch(query: query)
        mainWindowController?.updateSearchResults(filteredTasks)
    }

    func clearSearch() {
        super.clearSearch()
        mainWindowController?.clearSearchResults()
    }

    // MARK: - Setup

    private func setupWindowControllers() {
        // Main window controller should already be created by AppDelegate
        // We'll get a reference to it
        if let existingMainWindow = NSApp.windows.first(where: { $0.windowController is MainWindowController })?.windowController as? MainWindowController {
            mainWindowController = existingMainWindow
            wireMainWindowController()
        }
    }

    private func setupQuickCaptureWindow() {
        quickCaptureWindowController = QuickCaptureWindowController()
        quickCaptureWindowController?.delegate = self
    }

    private func wireMainWindowController() {
        guard let controller = mainWindowController else { return }

        // Set initial data
        controller.setDataManager(dataManager)
        controller.setCoordinator(self)

        // Set initial state
        if let perspective = activePerspective {
            controller.showPerspective(perspective)
        }

        controller.switchViewMode(to: viewMode)

        if isInspectorVisible, let task = selectedTask {
            controller.showInspector(for: task)
        } else if !isInspectorVisible {
            controller.hideInspector()
        }
    }

    // MARK: - Data Observers

    private func setupDataObservers() {
        // Observe task store changes
        taskStore.$tasks
            .sink { [weak self] tasks in
                self?.handleTasksChanged(tasks)
            }
            .store(in: &cancellables)

        // Observe board store changes
        boardStore.$boards
            .sink { [weak self] boards in
                self?.handleBoardsChanged(boards)
            }
            .store(in: &cancellables)

        // Observe selected task changes
        $selectedTask
            .sink { [weak self] task in
                self?.handleSelectedTaskChanged(task)
            }
            .store(in: &cancellables)
    }

    private func setupNotificationObservers() {
        // Observe data manager state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataLoadingChanged),
            name: NSNotification.Name("DataLoadingStateChanged"),
            object: nil
        )

        // Observe file conflicts
        dataManager.onConflictDetected = { [weak self] conflict in
            self?.handleFileConflict(conflict)
        }
    }

    // MARK: - Change Handlers

    private func handleTasksChanged(_ tasks: [Task]) {
        // Update main window
        mainWindowController?.refreshTaskList()

        // Update badge counts in sidebar
        updateBadgeCounts()
    }

    private func handleBoardsChanged(_ boards: [Board]) {
        // Update main window sidebar
        mainWindowController?.refreshSidebar()
    }

    private func handleSelectedTaskChanged(_ task: Task?) {
        if let task = task, isInspectorVisible {
            mainWindowController?.updateInspector(with: task)
        }
    }

    @objc private func handleDataLoadingChanged() {
        // Show/hide loading indicator
        if dataManager.isLoading {
            mainWindowController?.showLoadingIndicator()
        } else {
            mainWindowController?.hideLoadingIndicator()
        }
    }

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
            log("Failed to read file content for conflict: \(conflict.url.path)")
            return
        }

        // Get our in-memory content as markdown
        guard let ourContent = dataManager.getMarkdownContent(for: conflict.url) else {
            log("Failed to get in-memory content for conflict: \(conflict.url.path)")
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

    // MARK: - Badge Counts

    private func updateBadgeCounts() {
        var counts: [String: Int] = [:]

        // Count tasks for each perspective
        for perspective in Perspective.builtInPerspectives {
            let tasks = perspective.apply(to: taskStore.tasks)
            counts[perspective.id] = tasks.count
        }

        // Count tasks for each board
        for board in boardStore.boards {
            let tasks = taskStore.tasks(for: board)
            counts[board.id] = tasks.count
        }

        mainWindowController?.updateBadgeCounts(counts)
    }

    // MARK: - UI Helpers

    private func showWelcomeMessage() {
        let alert = NSAlert()
        alert.messageText = "Welcome to StickyToDo!"
        alert.informativeText = """
        StickyToDo combines GTD task management with visual organization.

        Get started by:
        • Creating tasks in the Inbox
        • Organizing them on boards
        • Using ⌘⇧Space for quick capture

        Your data is saved in:
        \(configManager.dataDirectory.path)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Get Started")
        alert.runModal()
    }

    private func showConflictDialog(for conflict: FileWatcher.FileConflict) {
        let alert = NSAlert()
        alert.messageText = "File Conflict Detected"
        alert.informativeText = """
        The file "\(conflict.url.lastPathComponent)" was modified both in StickyToDo and externally.

        Which version would you like to keep?
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Keep My Version")
        alert.addButton(withTitle: "Use Disk Version")
        alert.addButton(withTitle: "Show Both")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            // Keep our version
            dataManager.resolveConflictWithOurVersion(conflict)

        case .alertSecondButtonReturn:
            // Use disk version
            dataManager.resolveConflictWithDiskVersion(conflict)

        case .alertThirdButtonReturn:
            // Show both (create a duplicate)
            // This would need additional implementation
            break

        default:
            break
        }
    }

    // MARK: - Cleanup

    override func cleanup() {
        super.cleanup()

        // Remove notification observers
        NotificationCenter.default.removeObserver(self)

        // Cleanup window controllers
        quickCaptureWindowController?.unregisterHotKey()
        quickCaptureWindowController = nil
    }
}

// MARK: - QuickCaptureDelegate

extension AppKitCoordinator: QuickCaptureDelegate {
    func quickCaptureDidCreateTask(_ task: Task) {
        handleQuickCaptureTask(task)
    }
}

// MARK: - MainWindowController Extension

extension MainWindowController {

    /// Sets the data manager
    func setDataManager(_ dataManager: DataManager) {
        // This would be implemented in MainWindowController
        // to receive the data manager instance
    }

    /// Sets the coordinator
    func setCoordinator(_ coordinator: AppKitCoordinator) {
        // This would be implemented in MainWindowController
        // to receive the coordinator instance
    }

    /// Shows a specific perspective
    func showPerspective(_ perspective: Perspective) {
        // Implementation in MainWindowController
    }

    /// Shows a specific board
    func showBoard(_ board: Board) {
        // Implementation in MainWindowController
    }

    /// Shows the inspector for a task
    func showInspector(for task: Task) {
        // Implementation in MainWindowController
    }

    /// Hides the inspector
    func hideInspector() {
        // Implementation in MainWindowController
    }

    /// Switches view mode
    func switchViewMode(to mode: ViewMode) {
        // Implementation in MainWindowController
    }

    /// Refreshes after task created
    func refreshAfterTaskCreated(_ task: Task) {
        // Implementation in MainWindowController
    }

    /// Refreshes after task updated
    func refreshAfterTaskUpdated(_ task: Task) {
        // Implementation in MainWindowController
    }

    /// Refreshes after task deleted
    func refreshAfterTaskDeleted(_ task: Task) {
        // Implementation in MainWindowController
    }

    /// Updates search results
    func updateSearchResults(_ tasks: [Task]) {
        // Implementation in MainWindowController
    }

    /// Clears search results
    func clearSearchResults() {
        // Implementation in MainWindowController
    }

    /// Refreshes task list
    func refreshTaskList() {
        // Implementation in MainWindowController
    }

    /// Refreshes sidebar
    func refreshSidebar() {
        // Implementation in MainWindowController
    }

    /// Updates inspector
    func updateInspector(with task: Task) {
        // Implementation in MainWindowController
    }

    /// Shows loading indicator
    func showLoadingIndicator() {
        // Implementation in MainWindowController
    }

    /// Hides loading indicator
    func hideLoadingIndicator() {
        // Implementation in MainWindowController
    }

    /// Updates badge counts
    func updateBadgeCounts(_ counts: [String: Int]) {
        // Implementation in MainWindowController
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
