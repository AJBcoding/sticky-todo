//
//  BoardStore.swift
//  StickyToDo
//
//  In-memory store for all boards with SwiftUI/AppKit integration.
//  Manages built-in and custom boards, auto-creation, and persistence.
//

import Foundation
import Combine

/// In-memory store managing all boards in the application
///
/// BoardStore handles:
/// - Built-in system boards (Inbox, Next Actions, etc.)
/// - Dynamic board creation for contexts and projects
/// - Auto-hiding inactive project boards
/// - Debounced writes to disk
/// - Thread-safe access
///
/// Usage:
/// ```swift
/// @ObservedObject var boardStore: BoardStore
/// ```
final class BoardStore: ObservableObject {

    // MARK: - Published Properties

    /// All boards in the store
    @Published private(set) var boards: [Board] = []

    /// Only visible boards (excludes hidden boards)
    @Published private(set) var visibleBoards: [Board] = []

    // MARK: - Private Properties

    /// File I/O handler for reading/writing markdown files
    private let fileIO: MarkdownFileIO

    /// Serial queue for thread-safe access
    private let queue = DispatchQueue(label: "com.stickytodo.boardstore", qos: .userInitiated)

    /// Debounce timer for auto-save operations
    private var saveTimers: [String: Timer] = [:]

    /// Save debounce interval (500ms)
    private let saveDebounceInterval: TimeInterval = 0.5

    /// Logger for debugging
    private var logger: ((String) -> Void)?

    /// Track pending saves
    private var pendingSaves: Set<String> = []

    // MARK: - Initialization

    /// Creates a new BoardStore
    ///
    /// - Parameter fileIO: The file I/O handler for persistence
    init(fileIO: MarkdownFileIO) {
        self.fileIO = fileIO
    }

    /// Configure logging
    func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    // MARK: - Loading

    /// Loads all boards from the file system and ensures built-in boards exist
    ///
    /// This should be called once at app launch. It will:
    /// 1. Load all boards from the file system
    /// 2. Ensure all built-in boards exist
    /// 3. Sort boards by their order
    ///
    /// - Throws: MarkdownFileError if loading fails
    func loadAll() throws {
        logger?("Loading all boards from file system")

        var loadedBoards = try fileIO.loadAllBoards()

        // Ensure all built-in boards exist
        for builtInBoard in Board.builtInBoards {
            if !loadedBoards.contains(where: { $0.id == builtInBoard.id }) {
                loadedBoards.append(builtInBoard)
                // Save the built-in board to file system
                try? fileIO.writeBoard(builtInBoard)
                logger?("Created missing built-in board: \(builtInBoard.displayTitle)")
            }
        }

        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.boards = loadedBoards.sorted { ($0.order ?? 999) < ($1.order ?? 999) }
                self.updateVisibleBoards()
                self.logger?("Loaded \(loadedBoards.count) boards into store")
            }
        }
    }

    /// Loads all boards asynchronously
    func loadAllAsync() async throws {
        logger?("Loading all boards asynchronously")

        var loadedBoards = try fileIO.loadAllBoards()

        // Ensure all built-in boards exist
        for builtInBoard in Board.builtInBoards {
            if !loadedBoards.contains(where: { $0.id == builtInBoard.id }) {
                loadedBoards.append(builtInBoard)
                try? fileIO.writeBoard(builtInBoard)
                logger?("Created missing built-in board: \(builtInBoard.displayTitle)")
            }
        }

        await MainActor.run {
            self.boards = loadedBoards.sorted { ($0.order ?? 999) < ($1.order ?? 999) }
            self.updateVisibleBoards()
            self.logger?("Loaded \(loadedBoards.count) boards into store")
        }
    }

    // MARK: - CRUD Operations

    /// Adds a new board to the store
    ///
    /// - Parameter board: The board to add
    func add(_ board: Board) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if !self.boards.contains(where: { $0.id == board.id }) {
                    self.boards.append(board)
                    self.boards.sort { ($0.order ?? 999) < ($1.order ?? 999) }
                    self.updateVisibleBoards()
                    self.logger?("Added board: \(board.displayTitle)")

                    // Schedule debounced save
                    self.scheduleSave(for: board)
                }
            }
        }
    }

    /// Updates an existing board
    ///
    /// - Parameter board: The updated board
    func update(_ board: Board) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.boards.firstIndex(where: { $0.id == board.id }) {
                    self.boards[index] = board
                    self.boards.sort { ($0.order ?? 999) < ($1.order ?? 999) }
                    self.updateVisibleBoards()
                    self.logger?("Updated board: \(board.displayTitle)")

                    // Schedule debounced save
                    self.scheduleSave(for: board)
                }
            }
        }
    }

    /// Deletes a board from the store
    ///
    /// Built-in boards cannot be deleted, only hidden.
    ///
    /// - Parameter board: The board to delete
    func delete(_ board: Board) {
        // Don't allow deleting built-in boards
        guard !board.isBuiltIn else {
            logger?("Cannot delete built-in board: \(board.displayTitle)")
            return
        }

        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.boards.firstIndex(where: { $0.id == board.id }) {
                    self.boards.remove(at: index)
                    self.updateVisibleBoards()
                    self.logger?("Deleted board: \(board.displayTitle)")

                    // Cancel pending save
                    self.cancelSave(for: board.id)

                    // Delete from file system
                    self.queue.async {
                        do {
                            try self.fileIO.deleteBoard(board)
                        } catch {
                            self.logger?("Failed to delete board file: \(error)")
                        }
                    }
                }
            }
        }
    }

    /// Saves a board to disk with debouncing
    ///
    /// - Parameter board: The board to save
    func save(_ board: Board) {
        scheduleSave(for: board)
    }

    /// Immediately saves a board to disk without debouncing
    ///
    /// - Parameter board: The board to save
    /// - Throws: MarkdownFileError if saving fails
    func saveImmediately(_ board: Board) throws {
        cancelSave(for: board.id)
        try fileIO.writeBoard(board)
        logger?("Immediately saved board: \(board.displayTitle)")
    }

    /// Immediately saves all boards to disk
    ///
    /// - Throws: MarkdownFileError if saving fails
    func saveAll() throws {
        logger?("Saving all boards to disk")

        // Cancel pending saves
        for boardID in pendingSaves {
            cancelSave(for: boardID)
        }

        // Save all boards
        for board in boards {
            try fileIO.writeBoard(board)
        }

        logger?("Saved all \(boards.count) boards")
    }

    // MARK: - Board Lookup

    /// Finds a board by its ID
    ///
    /// - Parameter id: The board ID
    /// - Returns: The board if found
    func board(withID id: String) -> Board? {
        return boards.first { $0.id == id }
    }

    /// Finds boards by type
    ///
    /// - Parameter type: The board type
    /// - Returns: Array of boards with that type
    func boards(ofType type: BoardType) -> [Board] {
        return boards.filter { $0.type == type }
    }

    /// Returns all context boards
    var contextBoards: [Board] {
        return boards(ofType: .context)
    }

    /// Returns all project boards
    var projectBoards: [Board] {
        return boards(ofType: .project)
    }

    /// Returns all built-in boards
    var builtInBoards: [Board] {
        return boards.filter { $0.isBuiltIn }
    }

    /// Returns all custom boards
    var customBoards: [Board] {
        return boards.filter { !$0.isBuiltIn }
    }

    // MARK: - Dynamic Board Creation

    /// Gets or creates a context board for the given context
    ///
    /// - Parameter context: The context
    /// - Returns: The context board
    func getOrCreateContextBoard(for context: Context) -> Board {
        // Check if board already exists
        if let existing = boards.first(where: { $0.id == context.name }) {
            return existing
        }

        // Create new context board
        let board = Board.contextBoard(for: context)
        add(board)
        logger?("Auto-created context board: \(board.displayTitle)")
        return board
    }

    /// Gets or creates a project board for the given project name
    ///
    /// - Parameter projectName: The project name
    /// - Returns: The project board
    func getOrCreateProjectBoard(for projectName: String) -> Board {
        let boardID = projectName.slugified()

        // Check if board already exists
        if let existing = boards.first(where: { $0.id == boardID }) {
            return existing
        }

        // Create new project board
        let board = Board.projectBoard(name: projectName)
        add(board)
        logger?("Auto-created project board: \(board.displayTitle)")
        return board
    }

    // MARK: - Board Visibility

    /// Hides a board (sets isVisible to false)
    ///
    /// - Parameter board: The board to hide
    func hide(_ board: Board) {
        var updatedBoard = board
        updatedBoard.isVisible = false
        update(updatedBoard)
    }

    /// Shows a board (sets isVisible to true)
    ///
    /// - Parameter board: The board to show
    func show(_ board: Board) {
        var updatedBoard = board
        updatedBoard.isVisible = true
        update(updatedBoard)
    }

    /// Updates visibility based on auto-hide settings
    ///
    /// This should be called periodically (e.g., daily) to auto-hide
    /// inactive project boards.
    ///
    /// - Parameter taskStore: The task store to check for active tasks
    func updateAutoHideStatus(taskStore: TaskStore) {
        let projectBoards = boards.filter { $0.autoHide }

        for board in projectBoards {
            let tasksForBoard = taskStore.tasks(for: board)
            let activeTasks = tasksForBoard.filter { $0.status != .completed }

            if activeTasks.isEmpty {
                // Find last activity date
                let lastActiveDate = tasksForBoard
                    .map { $0.modified }
                    .max() ?? Date.distantPast

                if board.shouldAutoHide(lastActiveDate: lastActiveDate) && board.isVisible {
                    hide(board)
                    logger?("Auto-hiding inactive board: \(board.displayTitle)")
                }
            } else if !board.isVisible {
                // Board has active tasks but is hidden - show it
                show(board)
                logger?("Auto-showing board with active tasks: \(board.displayTitle)")
            }
        }
    }

    /// Updates the visibleBoards array based on isVisible flags
    private func updateVisibleBoards() {
        visibleBoards = boards.filter { $0.isVisible }
    }

    // MARK: - Board Organization

    /// Reorders boards
    ///
    /// - Parameter boardIDs: Array of board IDs in the desired order
    func reorder(_ boardIDs: [String]) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Update order for each board
                for (index, boardID) in boardIDs.enumerated() {
                    if let boardIndex = self.boards.firstIndex(where: { $0.id == boardID }) {
                        self.boards[boardIndex].order = index
                        self.scheduleSave(for: self.boards[boardIndex])
                    }
                }

                // Re-sort boards
                self.boards.sort { ($0.order ?? 999) < ($1.order ?? 999) }
                self.updateVisibleBoards()
                self.logger?("Reordered boards")
            }
        }
    }

    // MARK: - Statistics

    /// Total number of boards
    var boardCount: Int {
        return boards.count
    }

    /// Number of visible boards
    var visibleBoardCount: Int {
        return visibleBoards.count
    }

    /// Number of hidden boards
    var hiddenBoardCount: Int {
        return boards.count - visibleBoards.count
    }

    // MARK: - Private Helpers

    /// Schedules a debounced save for a board
    private func scheduleSave(for board: Board) {
        // Cancel existing timer
        cancelSave(for: board.id)

        // Mark as pending
        pendingSaves.insert(board.id)

        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.queue.async {
                do {
                    try self.fileIO.writeBoard(board)
                    self.logger?("Debounced save completed for board: \(board.displayTitle)")
                } catch {
                    self.logger?("Failed to save board: \(error)")
                }

                DispatchQueue.main.async {
                    self.pendingSaves.remove(board.id)
                    self.saveTimers.removeValue(forKey: board.id)
                }
            }
        }

        saveTimers[board.id] = timer
    }

    /// Cancels a pending save
    private func cancelSave(for boardID: String) {
        saveTimers[boardID]?.invalidate()
        saveTimers.removeValue(forKey: boardID)
        pendingSaves.remove(boardID)
    }

    /// Cancels all pending saves
    func cancelAllPendingSaves() {
        for (_, timer) in saveTimers {
            timer.invalidate()
        }
        saveTimers.removeAll()
        pendingSaves.removeAll()
    }

    deinit {
        cancelAllPendingSaves()
    }
}

// MARK: - Board Filtering

extension BoardStore {
    /// Returns boards matching a search query
    ///
    /// - Parameter query: The search string
    /// - Returns: Array of boards with matching titles or IDs
    func boards(matchingSearch query: String) -> [Board] {
        guard !query.isEmpty else { return boards }

        let lowercaseQuery = query.lowercased()
        return boards.filter {
            $0.displayTitle.lowercased().contains(lowercaseQuery) ||
            $0.id.lowercased().contains(lowercaseQuery)
        }
    }

    /// Returns boards by layout type
    ///
    /// - Parameter layout: The layout type
    /// - Returns: Array of boards with that layout
    func boards(withLayout layout: Layout) -> [Board] {
        return boards.filter { $0.layout == layout }
    }

    /// Returns all freeform boards
    var freeformBoards: [Board] {
        return boards(withLayout: .freeform)
    }

    /// Returns all kanban boards
    var kanbanBoards: [Board] {
        return boards(withLayout: .kanban)
    }

    /// Returns all grid boards
    var gridBoards: [Board] {
        return boards(withLayout: .grid)
    }
}

// MARK: - String Extension for Slugification

fileprivate extension String {
    /// Converts a string to a URL-safe slug
    func slugified() -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let slug = self
            .lowercased()
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return slug.isEmpty ? "untitled" : slug
    }
}
