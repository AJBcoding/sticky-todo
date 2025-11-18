//
//  AppCoordinator.swift
//  StickyToDoCore
//
//  Central coordination protocol and base implementation for app-wide coordination.
//  Defines the contract for both AppKit and SwiftUI coordinators.
//

import Foundation
import Combine

/// Protocol defining the coordinator responsibilities for the application
///
/// Coordinators are responsible for:
/// - Managing navigation between views/screens
/// - Coordinating data flow between stores and UI
/// - Handling global actions (hotkeys, menu commands)
/// - Managing window state
///
/// Both AppKit and SwiftUI implementations conform to this protocol
protocol AppCoordinatorProtocol: AnyObject {

    // MARK: - Data Stores

    /// The central data manager
    var dataManager: DataManager { get }

    /// Task store for accessing tasks
    var taskStore: TaskStore { get }

    /// Board store for accessing boards
    var boardStore: BoardStore { get }

    /// Configuration manager for user preferences
    var configManager: ConfigurationManager { get }

    // MARK: - State

    /// Currently selected task (if any)
    var selectedTask: Task? { get set }

    /// Currently active board (if any)
    var activeBoard: Board? { get set }

    /// Currently active perspective (if any)
    var activePerspective: Perspective? { get set }

    /// Current view mode (list or board)
    var viewMode: ViewMode { get set }

    // MARK: - Initialization

    /// Initializes the coordinator with required dependencies
    func initialize() async throws

    /// Performs first-run setup if needed
    func performFirstRunSetupIfNeeded()

    // MARK: - Navigation

    /// Navigates to a specific perspective
    func navigateToPerspective(_ perspective: Perspective)

    /// Navigates to a specific board
    func navigateToBoard(_ board: Board)

    /// Shows the task inspector for a task
    func showInspector(for task: Task)

    /// Hides the task inspector
    func hideInspector()

    /// Switches between list and board view modes
    func switchViewMode(to mode: ViewMode)

    // MARK: - Task Operations

    /// Creates a new task
    @discardableResult
    func createTask(title: String, status: Status, perspective: Perspective?) -> Task

    /// Updates an existing task
    func updateTask(_ task: Task)

    /// Deletes a task
    func deleteTask(_ task: Task)

    /// Toggles task completion
    func toggleTaskCompletion(_ task: Task)

    /// Duplicates a task
    @discardableResult
    func duplicateTask(_ task: Task) -> Task

    /// Batch updates tasks
    func updateBatchTasks(_ tasks: [Task])

    /// Batch deletes tasks
    func deleteBatchTasks(_ tasks: [Task])

    // MARK: - Board Operations

    /// Creates a new board
    @discardableResult
    func createBoard(id: String, type: BoardType, layout: Layout) -> Board

    /// Updates a board
    func updateBoard(_ board: Board)

    /// Deletes a board
    func deleteBoard(_ board: Board)

    // MARK: - Quick Capture

    /// Shows the quick capture window
    func showQuickCapture()

    /// Handles a task created from quick capture
    func handleQuickCaptureTask(_ task: Task)

    // MARK: - Window Management

    /// Shows the preferences window
    func showPreferences()

    /// Shows the main window
    func showMainWindow()

    /// Brings all windows to front
    func bringAllWindowsToFront()

    // MARK: - Search

    /// Performs a search with the given query
    func performSearch(query: String)

    /// Clears the current search
    func clearSearch()

    // MARK: - Cleanup

    /// Saves all pending changes before app quits
    func saveBeforeQuit() throws

    /// Performs cleanup before termination
    func cleanup()
}

/// View mode enumeration
enum ViewMode: String, Codable {
    case list
    case board

    var displayName: String {
        switch self {
        case .list: return "List"
        case .board: return "Board"
        }
    }
}

/// Base coordinator implementation with shared functionality
///
/// This class provides common implementation that both AppKit and SwiftUI
/// coordinators can inherit from or use as a reference.
class BaseAppCoordinator: ObservableObject {

    // MARK: - Published Properties

    /// Currently selected task
    @Published var selectedTask: Task?

    /// Currently active board
    @Published var activeBoard: Board?

    /// Currently active perspective
    @Published var activePerspective: Perspective?

    /// Current view mode
    @Published var viewMode: ViewMode = .list

    /// Search query
    @Published var searchQuery: String = ""

    /// Filtered tasks based on search
    @Published var filteredTasks: [Task] = []

    // MARK: - Dependencies

    let dataManager: DataManager
    let configManager: ConfigurationManager

    // MARK: - Cancellables

    var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(dataManager: DataManager = .shared, configManager: ConfigurationManager = .shared) {
        self.dataManager = dataManager
        self.configManager = configManager

        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearchInternal(query: query)
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    var taskStore: TaskStore {
        return dataManager.taskStore
    }

    var boardStore: BoardStore {
        return dataManager.boardStore
    }

    // MARK: - Task Operations

    func createTask(title: String, status: Status = .inbox, perspective: Perspective? = nil) -> Task {
        let task = dataManager.createTask(title: title, status: status)

        // If we have an active board, apply its context/project to the new task
        if let board = activeBoard {
            var updatedTask = task

            switch board.type {
            case .context:
                if let contextName = board.filter.context {
                    updatedTask.context = contextName
                }
            case .project:
                if let projectName = board.filter.project {
                    updatedTask.project = projectName
                }
            default:
                break
            }

            if updatedTask != task {
                dataManager.updateTask(updatedTask)
                return updatedTask
            }
        }

        return task
    }

    func updateTask(_ task: Task) {
        dataManager.updateTask(task)

        // Update selected task if it's the same
        if selectedTask?.id == task.id {
            selectedTask = task
        }
    }

    func deleteTask(_ task: Task) {
        dataManager.deleteTask(task)

        // Clear selection if deleted task was selected
        if selectedTask?.id == task.id {
            selectedTask = nil
        }
    }

    func toggleTaskCompletion(_ task: Task) {
        var updatedTask = task

        if updatedTask.status == .completed {
            updatedTask.reopen()
        } else {
            updatedTask.complete()
        }

        updateTask(updatedTask)
    }

    func duplicateTask(_ task: Task) -> Task {
        var duplicate = task.duplicate()
        dataManager.taskStore.add(duplicate)
        return duplicate
    }

    func updateBatchTasks(_ tasks: [Task]) {
        taskStore.updateBatch(tasks)
    }

    func deleteBatchTasks(_ tasks: [Task]) {
        taskStore.deleteBatch(tasks)

        // Clear selection if it was in the deleted batch
        if let selected = selectedTask, tasks.contains(where: { $0.id == selected.id }) {
            selectedTask = nil
        }
    }

    // MARK: - Board Operations

    func createBoard(id: String, type: BoardType, layout: Layout = .freeform) -> Board {
        return dataManager.createBoard(id: id, type: type, layout: layout)
    }

    func updateBoard(_ board: Board) {
        dataManager.updateBoard(board)

        // Update active board if it's the same
        if activeBoard?.id == board.id {
            activeBoard = board
        }
    }

    func deleteBoard(_ board: Board) {
        dataManager.deleteBoard(board)

        // Clear active board if it was deleted
        if activeBoard?.id == board.id {
            activeBoard = nil
        }
    }

    // MARK: - Navigation

    func navigateToPerspective(_ perspective: Perspective) {
        activePerspective = perspective
        activeBoard = nil
        viewMode = .list
    }

    func navigateToBoard(_ board: Board) {
        activeBoard = board
        activePerspective = nil
        viewMode = .board
    }

    func switchViewMode(to mode: ViewMode) {
        viewMode = mode
    }

    // MARK: - Search

    private func performSearchInternal(query: String) {
        if query.isEmpty {
            filteredTasks = []
        } else {
            filteredTasks = taskStore.tasks(matchingSearch: query)
        }
    }

    func performSearch(query: String) {
        searchQuery = query
    }

    func clearSearch() {
        searchQuery = ""
        filteredTasks = []
    }

    // MARK: - Lifecycle

    func initialize() async throws {
        // Load configuration
        configManager.load()

        // Get data directory from config
        let dataDirectory = configManager.dataDirectory

        // Initialize data manager
        try await dataManager.initialize(rootDirectory: dataDirectory)

        // Perform first run setup if needed
        if configManager.isFirstRun {
            dataManager.performFirstRunSetup(createSampleData: true)
            configManager.isFirstRun = false
            configManager.save()
        }

        // Load last used perspective or default to Inbox
        if let lastPerspectiveID = configManager.lastPerspectiveID,
           let perspective = Perspective.builtInPerspectives.first(where: { $0.id == lastPerspectiveID }) {
            activePerspective = perspective
        } else {
            activePerspective = .inbox
        }

        // Restore view mode
        viewMode = configManager.lastViewMode
    }

    func saveBeforeQuit() throws {
        // Save current state to config
        if let perspective = activePerspective {
            configManager.lastPerspectiveID = perspective.id
        }
        configManager.lastViewMode = viewMode
        configManager.save()

        // Save all data
        try dataManager.saveBeforeQuit()
    }

    func cleanup() {
        dataManager.cleanup()
        cancellables.removeAll()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a task is created
    static let taskCreated = Notification.Name("taskCreated")

    /// Posted when a task is updated
    static let taskUpdated = Notification.Name("taskUpdated")

    /// Posted when a task is deleted
    static let taskDeleted = Notification.Name("taskDeleted")

    /// Posted when a board is selected
    static let boardSelected = Notification.Name("boardSelected")

    /// Posted when a perspective is selected
    static let perspectiveSelected = Notification.Name("perspectiveSelected")

    /// Posted when view mode changes
    static let viewModeChanged = Notification.Name("viewModeChanged")

    /// Posted when quick capture is triggered
    static let quickCaptureTriggered = Notification.Name("quickCaptureTriggered")
}
