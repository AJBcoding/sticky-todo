//
//  DataManager.swift
//  StickyToDo
//
//  Central coordinator for all data operations.
//  Single point of access for both SwiftUI and AppKit apps.
//

import Foundation
import Combine

/// Errors that can occur during data management operations
enum DataManagerError: Error, LocalizedError {
    case notInitialized
    case loadingFailed(Error)
    case savingFailed(Error)
    case invalidDirectory(URL)
    case fileConflict(URL)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "DataManager has not been initialized"
        case .loadingFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .savingFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .invalidDirectory(let url):
            return "Invalid data directory: \(url.path)"
        case .fileConflict(let url):
            return "File conflict detected: \(url.path)"
        }
    }
}

/// Central data manager coordinating all data operations
///
/// DataManager is the single source of truth for the application's data layer.
/// It coordinates:
/// - TaskStore and BoardStore for in-memory data
/// - MarkdownFileIO for persistence
/// - FileWatcher for external change detection
/// - Conflict resolution when files are edited externally
///
/// Usage:
/// ```swift
/// // Initialize at app launch
/// let dataManager = DataManager.shared
/// try await dataManager.initialize(rootDirectory: dataDirectory)
///
/// // Access stores
/// let tasks = dataManager.taskStore.tasks
/// let boards = dataManager.boardStore.boards
///
/// // Create/update tasks
/// dataManager.createTask(title: "New task")
/// dataManager.updateTask(task)
/// ```
final class DataManager: ObservableObject {

    // MARK: - Singleton

    /// Shared instance for dependency injection
    /// Note: You can also create your own instance if needed for testing
    static let shared = DataManager()

    // MARK: - Published Properties

    /// Whether the data manager is initialized and ready to use
    @Published private(set) var isInitialized = false

    /// Whether data is currently being loaded
    @Published private(set) var isLoading = false

    /// Current error state, if any
    @Published private(set) var error: Error?

    // MARK: - Stores

    /// Task store managing all tasks
    private(set) var taskStore: TaskStore!

    /// Board store managing all boards
    private(set) var boardStore: BoardStore!

    // MARK: - Core Components

    /// File I/O handler
    private var fileIO: MarkdownFileIO!

    /// File watcher for external changes
    private var fileWatcher: FileWatcher!

    /// Root directory where all data is stored
    private(set) var rootDirectory: URL?

    // MARK: - Configuration

    /// Whether to enable file watching for external changes
    var enableFileWatching = true

    /// Whether to enable debug logging
    var enableLogging = true

    /// Logger closure
    private var logger: ((String) -> Void)?

    // MARK: - Conflict Handling

    /// Pending file conflicts that need user resolution
    @Published private(set) var pendingConflicts: [FileWatcher.FileConflict] = []

    /// Callback for when a conflict is detected
    var onConflictDetected: ((FileWatcher.FileConflict) -> Void)?

    // MARK: - Initialization

    private init() {
        // Private initializer for singleton pattern
    }

    /// Initializes the data manager with a root directory
    ///
    /// This must be called before using the data manager. It will:
    /// 1. Set up the directory structure
    /// 2. Create file I/O and store instances
    /// 3. Load all tasks and boards from disk
    /// 4. Start file watching if enabled
    ///
    /// - Parameter rootDirectory: The root directory for all StickyToDo data
    /// - Throws: DataManagerError if initialization fails
    func initialize(rootDirectory: URL) async throws {
        guard !isInitialized else {
            log("DataManager already initialized")
            return
        }

        log("Initializing DataManager with root directory: \(rootDirectory.path)")

        // Validate directory
        guard rootDirectory.hasDirectoryPath || !FileManager.default.fileExists(atPath: rootDirectory.path) else {
            throw DataManagerError.invalidDirectory(rootDirectory)
        }

        self.rootDirectory = rootDirectory

        // Create file I/O handler
        fileIO = MarkdownFileIO(rootDirectory: rootDirectory)
        if enableLogging {
            fileIO.setLogger { [weak self] message in
                self?.log("FileIO: \(message)")
            }
        }

        // Ensure directory structure exists
        do {
            try fileIO.ensureDirectoryStructure()
        } catch {
            throw DataManagerError.loadingFailed(error)
        }

        // Create stores
        taskStore = TaskStore(fileIO: fileIO)
        boardStore = BoardStore(fileIO: fileIO)

        if enableLogging {
            taskStore.setLogger { [weak self] message in
                self?.log("TaskStore: \(message)")
            }
            boardStore.setLogger { [weak self] message in
                self?.log("BoardStore: \(message)")
            }
        }

        // Load data
        await MainActor.run {
            isLoading = true
        }

        do {
            try await taskStore.loadAllAsync()
            try await boardStore.loadAllAsync()
        } catch {
            await MainActor.run {
                isLoading = false
                self.error = error
            }
            throw DataManagerError.loadingFailed(error)
        }

        // Set up file watcher
        if enableFileWatching {
            setupFileWatcher()
        }

        await MainActor.run {
            isLoading = false
            isInitialized = true
        }

        log("DataManager initialized successfully")
        log("Loaded \(taskStore.taskCount) tasks and \(boardStore.boardCount) boards")
    }

    /// Initializes with a root directory (synchronous version)
    func initialize(rootDirectory: URL) throws {
        guard !isInitialized else { return }

        log("Initializing DataManager synchronously")

        self.rootDirectory = rootDirectory

        // Create file I/O handler
        fileIO = MarkdownFileIO(rootDirectory: rootDirectory)
        if enableLogging {
            fileIO.setLogger { [weak self] message in
                self?.log("FileIO: \(message)")
            }
        }

        // Ensure directory structure
        try fileIO.ensureDirectoryStructure()

        // Create stores
        taskStore = TaskStore(fileIO: fileIO)
        boardStore = BoardStore(fileIO: fileIO)

        if enableLogging {
            taskStore.setLogger { [weak self] message in
                self?.log("TaskStore: \(message)")
            }
            boardStore.setLogger { [weak self] message in
                self?.log("BoardStore: \(message)")
            }
        }

        // Load data
        isLoading = true
        do {
            try taskStore.loadAll()
            try boardStore.loadAll()
        } catch {
            isLoading = false
            self.error = error
            throw DataManagerError.loadingFailed(error)
        }
        isLoading = false

        // Set up file watcher
        if enableFileWatching {
            setupFileWatcher()
        }

        isInitialized = true
        log("DataManager initialized successfully (sync)")
    }

    // MARK: - File Watching

    /// Sets up the file watcher for external changes
    private func setupFileWatcher() {
        guard let rootDir = rootDirectory else { return }

        fileWatcher = FileWatcher()

        if enableLogging {
            fileWatcher.setLogger { [weak self] message in
                self?.log("FileWatcher: \(message)")
            }
        }

        // Set up callbacks
        fileWatcher.onFileCreated = { [weak self] url in
            self?.handleFileCreated(url)
        }

        fileWatcher.onFileModified = { [weak self] url in
            self?.handleFileModified(url)
        }

        fileWatcher.onFileDeleted = { [weak self] url in
            self?.handleFileDeleted(url)
        }

        // Start watching
        fileWatcher.startWatching(directory: rootDir)
        log("File watching enabled")
    }

    /// Handles external file creation
    private func handleFileCreated(_ url: URL) {
        log("External file created: \(url.lastPathComponent)")

        if fileWatcher.isTaskFile(url) {
            loadTaskFromFile(url)
        } else if fileWatcher.isBoardFile(url) {
            loadBoardFromFile(url)
        }
    }

    /// Handles external file modification
    private func handleFileModified(_ url: URL) {
        log("External file modified: \(url.lastPathComponent)")

        if fileWatcher.isTaskFile(url) {
            reloadTaskFromFile(url)
        } else if fileWatcher.isBoardFile(url) {
            reloadBoardFromFile(url)
        }
    }

    /// Handles external file deletion
    private func handleFileDeleted(_ url: URL) {
        log("External file deleted: \(url.lastPathComponent)")

        if fileWatcher.isTaskFile(url) {
            removeTaskByPath(url)
        } else if fileWatcher.isBoardFile(url) {
            removeBoardByPath(url)
        }
    }

    // MARK: - External File Operations

    /// Loads a task from a file that was created externally
    private func loadTaskFromFile(_ url: URL) {
        do {
            if let task = try fileIO.readTask(from: url) {
                taskStore.add(task)
                log("Loaded external task: \(task.title)")
            }
        } catch {
            log("Failed to load external task: \(error)")
        }
    }

    /// Reloads a task from a file that was modified externally
    private func reloadTaskFromFile(_ url: URL) {
        do {
            if let updatedTask = try fileIO.readTask(from: url) {
                // Check for conflicts with our in-memory version
                if let existingTask = taskStore.task(withID: updatedTask.id) {
                    if let conflict = fileWatcher.checkForConflict(
                        url: url,
                        ourModificationDate: existingTask.modified
                    ) {
                        if conflict.hasConflict {
                            // We have a conflict - notify user
                            handleConflict(conflict)
                            return
                        }
                    }
                }

                taskStore.update(updatedTask)
                log("Reloaded modified task: \(updatedTask.title)")
            }
        } catch {
            log("Failed to reload task: \(error)")
        }
    }

    /// Loads a board from a file that was created externally
    private func loadBoardFromFile(_ url: URL) {
        do {
            if let board = try fileIO.readBoard(from: url) {
                boardStore.add(board)
                log("Loaded external board: \(board.displayTitle)")
            }
        } catch {
            log("Failed to load external board: \(error)")
        }
    }

    /// Reloads a board from a file that was modified externally
    private func reloadBoardFromFile(_ url: URL) {
        do {
            if let updatedBoard = try fileIO.readBoard(from: url) {
                // Check for conflicts with our in-memory version
                if let existingBoard = boardStore.board(withID: updatedBoard.id) {
                    // For boards, we check if the board was modified in memory
                    // A simple heuristic: if the board exists and has been modified, check timestamps
                    if let conflict = fileWatcher.checkForConflict(
                        url: url,
                        ourModificationDate: Date() // Boards don't track modification dates, so we use current time as proxy
                    ) {
                        if conflict.hasConflict {
                            // We have a conflict - notify user
                            handleConflict(conflict)
                            return
                        }
                    }
                }

                boardStore.update(updatedBoard)
                log("Reloaded modified board: \(updatedBoard.displayTitle)")
            }
        } catch {
            log("Failed to reload board: \(error)")
        }
    }

    /// Removes a task when its file is deleted externally
    private func removeTaskByPath(_ url: URL) {
        // Try to find the task by matching the file path
        // This is tricky since we only have the URL
        // For now, just log it - in practice we'd need to parse the UUID from the filename
        log("Task file deleted externally: \(url.lastPathComponent)")
    }

    /// Removes a board when its file is deleted externally
    private func removeBoardByPath(_ url: URL) {
        // Extract board ID from filename
        let boardID = url.deletingPathExtension().lastPathComponent
        if let board = boardStore.board(withID: boardID) {
            boardStore.delete(board)
            log("Removed board due to external deletion: \(board.displayTitle)")
        }
    }

    // MARK: - Conflict Resolution

    /// Handles a file conflict
    private func handleConflict(_ conflict: FileWatcher.FileConflict) {
        log("File conflict detected: \(conflict.url.lastPathComponent)")

        pendingConflicts.append(conflict)
        onConflictDetected?(conflict)
    }

    /// Resolves a conflict by choosing the disk version
    func resolveConflictWithDiskVersion(_ conflict: FileWatcher.FileConflict) {
        log("Resolving conflict with disk version: \(conflict.url.lastPathComponent)")

        if fileWatcher.isTaskFile(conflict.url) {
            reloadTaskFromFile(conflict.url)
        } else if fileWatcher.isBoardFile(conflict.url) {
            reloadBoardFromFile(conflict.url)
        }

        // Remove from pending conflicts
        pendingConflicts.removeAll { $0.url == conflict.url }
    }

    /// Resolves a conflict by keeping our version
    func resolveConflictWithOurVersion(_ conflict: FileWatcher.FileConflict) {
        log("Resolving conflict with our version: \(conflict.url.lastPathComponent)")

        // Save our version to disk to overwrite external changes
        if fileWatcher.isTaskFile(conflict.url) {
            if let taskID = extractTaskID(from: conflict.url),
               let task = taskStore.task(withID: taskID) {
                try? taskStore.saveImmediately(task)
            }
        } else if fileWatcher.isBoardFile(conflict.url) {
            let boardID = conflict.url.deletingPathExtension().lastPathComponent
            if let board = boardStore.board(withID: boardID) {
                try? boardStore.saveImmediately(board)
            }
        }

        // Remove from pending conflicts
        pendingConflicts.removeAll { $0.url == conflict.url }
    }

    /// Reloads a file from disk (generic method for both tasks and boards)
    func reloadFile(at url: URL) {
        log("Reloading file from disk: \(url.lastPathComponent)")

        if fileWatcher.isTaskFile(url) {
            reloadTaskFromFile(url)
        } else if fileWatcher.isBoardFile(url) {
            reloadBoardFromFile(url)
        } else {
            log("Unknown file type for reload: \(url.path)")
        }
    }

    /// Resumes file watching after conflicts are resolved
    func resumeFileWatching() {
        log("Resuming file watching")

        // If there are still pending conflicts, handle the next one
        if !pendingConflicts.isEmpty {
            log("Warning: \(pendingConflicts.count) conflicts still pending after resume")
        }
    }

    /// Extracts task ID from a task file URL
    func extractTaskID(from url: URL) -> UUID? {
        let filename = url.deletingPathExtension().lastPathComponent
        // Task files are named with UUID
        return UUID(uuidString: filename)
    }

    /// Gets the markdown content for a task or board
    func getMarkdownContent(for url: URL) -> String? {
        do {
            if fileWatcher.isTaskFile(url) {
                if let taskID = extractTaskID(from: url),
                   let task = taskStore.task(withID: taskID) {
                    return try YAMLParser.generateTask(task, body: task.notes)
                }
            } else if fileWatcher.isBoardFile(url) {
                let boardID = url.deletingPathExtension().lastPathComponent
                if let board = boardStore.board(withID: boardID) {
                    return try YAMLParser.generateBoard(board, body: board.notes ?? "")
                }
            }
        } catch {
            log("Failed to generate markdown: \(error)")
        }
        return nil
    }

    // MARK: - Convenience Methods

    /// Creates a new task
    ///
    /// - Parameters:
    ///   - title: Task title
    ///   - notes: Task notes
    ///   - status: Initial status
    /// - Returns: The created task
    @discardableResult
    func createTask(
        title: String,
        notes: String = "",
        status: Status = .inbox
    ) -> Task {
        let task = Task(title: title, notes: notes, status: status)
        taskStore.add(task)
        log("Created task: \(title)")
        return task
    }

    /// Updates a task
    func updateTask(_ task: Task) {
        taskStore.update(task)
    }

    /// Deletes a task
    func deleteTask(_ task: Task) {
        taskStore.delete(task)
    }

    /// Creates a new board
    @discardableResult
    func createBoard(
        id: String,
        type: BoardType,
        layout: Layout = .freeform,
        filter: Filter = Filter()
    ) -> Board {
        let board = Board(id: id, type: type, layout: layout, filter: filter)
        boardStore.add(board)
        log("Created board: \(board.displayTitle)")
        return board
    }

    /// Updates a board
    func updateBoard(_ board: Board) {
        boardStore.update(board)
    }

    /// Deletes a board
    func deleteBoard(_ board: Board) {
        boardStore.delete(board)
    }

    // MARK: - App Lifecycle

    /// Saves all pending changes before the app quits
    ///
    /// This should be called in the app's quit handler to ensure
    /// no data is lost.
    func saveBeforeQuit() throws {
        log("Saving all data before quit")

        do {
            try taskStore.saveAll()
            try boardStore.saveAll()
            log("All data saved successfully")
        } catch {
            log("Failed to save data before quit: \(error)")
            throw DataManagerError.savingFailed(error)
        }
    }

    /// Performs cleanup before the app terminates
    func cleanup() {
        log("Cleaning up DataManager")

        // Stop file watching
        fileWatcher?.stopWatching()

        // Cancel pending saves
        taskStore?.cancelAllPendingSaves()
        boardStore?.cancelAllPendingSaves()

        // Try to save any remaining changes
        try? saveBeforeQuit()

        log("DataManager cleanup complete")
    }

    // MARK: - Logging

    /// Sets a custom logger
    func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    /// Internal logging method
    private func log(_ message: String) {
        if enableLogging {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let logMessage = "[\(timestamp)] DataManager: \(message)"
            logger?(logMessage)
            print(logMessage)
        }
    }

    // MARK: - Statistics

    /// Returns summary statistics about the data
    var statistics: DataStatistics {
        return DataStatistics(
            totalTasks: taskStore.taskCount,
            activeTasks: taskStore.activeTaskCount,
            completedTasks: taskStore.completedTaskCount,
            inboxTasks: taskStore.inboxTaskCount,
            totalBoards: boardStore.boardCount,
            visibleBoards: boardStore.visibleBoardCount,
            projects: taskStore.projects.count,
            contexts: taskStore.contexts.count
        )
    }
}

// MARK: - Data Statistics

/// Summary statistics about the data
struct DataStatistics {
    let totalTasks: Int
    let activeTasks: Int
    let completedTasks: Int
    let inboxTasks: Int
    let totalBoards: Int
    let visibleBoards: Int
    let projects: Int
    let contexts: Int

    var description: String {
        return """
        Tasks: \(totalTasks) (\(activeTasks) active, \(completedTasks) completed, \(inboxTasks) inbox)
        Boards: \(totalBoards) (\(visibleBoards) visible)
        Projects: \(projects)
        Contexts: \(contexts)
        """
    }
}

// MARK: - First Run Setup

extension DataManager {
    /// Performs first-run setup
    ///
    /// Creates default contexts and sample data if this is the first time
    /// the app is being run in this directory.
    ///
    /// - Parameter createSampleData: Whether to create sample tasks and boards
    func performFirstRunSetup(createSampleData: Bool = false) {
        guard isInitialized else {
            log("⚠️ Cannot perform first-run setup: DataManager not initialized")
            return
        }

        log("Performing first-run setup")

        // Check if this is actually a first run (no tasks or boards exist)
        guard taskStore.taskCount == 0 && boardStore.boardCount <= Board.builtInBoards.count else {
            log("Not a first run, skipping setup (found \(taskStore.taskCount) tasks, \(boardStore.boardCount) boards)")
            return
        }

        // Check if sample data was already created via onboarding
        if OnboardingManager.shared.hasCreatedSampleData {
            log("Sample data already created via onboarding flow, skipping")
            return
        }

        // Create sample data if requested
        if createSampleData {
            createSampleTasks()
            log("Created sample data")
        }

        log("First-run setup complete")
    }

    /// Creates sample tasks and boards for demonstration using the comprehensive generator
    private func createSampleTasks() {
        log("Generating comprehensive sample data for first-run experience")

        // Use the SampleDataGenerator from StickyToDoCore
        let result = SampleDataGenerator.generateSampleData()

        switch result {
        case .success(let sampleData):
            // Add all sample tasks to the task store
            for task in sampleData.tasks {
                taskStore.add(task)
            }
            log("Added \(sampleData.tasks.count) sample tasks")

            // Add all sample boards to the board store
            for board in sampleData.boards {
                boardStore.add(board)
            }
            log("Added \(sampleData.boards.count) sample boards")

            // Mark sample data as created in OnboardingManager
            Task { @MainActor in
                OnboardingManager.shared.markSampleDataCreated()
            }

            log("✅ Sample data created successfully: \(sampleData.totalItems) total items")

        case .failure(let error):
            log("❌ Failed to generate sample data: \(error.localizedDescription)")
        }
    }
}
