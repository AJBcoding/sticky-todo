//
//  MarkdownFileIO.swift
//  StickyToDo
//
//  File system I/O for markdown files with YAML frontmatter.
//  Handles reading and writing Task and Board objects to/from the file system.
//

import Foundation

/// Errors that can occur during file I/O operations
enum MarkdownFileError: Error, LocalizedError {
    case fileNotFound(URL)
    case readError(URL, Error)
    case writeError(URL, Error)
    case invalidPath(String)
    case directoryCreationFailed(URL, Error)
    case permissionDenied(URL)
    case taskParsingFailed(URL)
    case boardParsingFailed(URL)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "File not found: \(url.path)"
        case .readError(let url, let error):
            return "Failed to read file \(url.path): \(error.localizedDescription)"
        case .writeError(let url, let error):
            return "Failed to write file \(url.path): \(error.localizedDescription)"
        case .invalidPath(let path):
            return "Invalid file path: \(path)"
        case .directoryCreationFailed(let url, let error):
            return "Failed to create directory \(url.path): \(error.localizedDescription)"
        case .permissionDenied(let url):
            return "Permission denied for file: \(url.path)"
        case .taskParsingFailed(let url):
            return "Failed to parse task from file: \(url.path)"
        case .boardParsingFailed(let url):
            return "Failed to parse board from file: \(url.path)"
        }
    }
}

/// Handles reading and writing markdown files with YAML frontmatter
///
/// This class provides the bridge between the file system and Swift model objects.
/// It uses YAMLParser to handle frontmatter parsing and generation, and manages
/// the file system operations including directory creation and error handling.
class MarkdownFileIO {

    // MARK: - Properties

    /// The root directory for all StickyToDo data
    private let rootDirectory: URL

    /// File manager instance for I/O operations
    private let fileManager: FileManager

    /// Logger for debugging file I/O operations
    private var logger: ((String) -> Void)?

    // MARK: - Initialization

    /// Creates a new MarkdownFileIO instance
    ///
    /// - Parameters:
    ///   - rootDirectory: The root directory where all markdown files are stored
    ///   - fileManager: The file manager to use (defaults to FileManager.default)
    init(rootDirectory: URL, fileManager: FileManager = .default) {
        self.rootDirectory = rootDirectory
        self.fileManager = fileManager
    }

    /// Configure logging for file I/O operations
    /// - Parameter logger: A closure that receives log messages
    func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    // MARK: - Directory Management

    /// Ensures the complete directory structure exists
    ///
    /// Creates the following structure:
    /// ```
    /// root/
    ///   tasks/
    ///     active/
    ///     archive/
    ///   boards/
    ///   config/
    /// ```
    ///
    /// - Throws: MarkdownFileError if directory creation fails
    func ensureDirectoryStructure() throws {
        let directories = [
            rootDirectory.appendingPathComponent("tasks/active"),
            rootDirectory.appendingPathComponent("tasks/archive"),
            rootDirectory.appendingPathComponent("boards"),
            rootDirectory.appendingPathComponent("config")
        ]

        for directory in directories {
            try createDirectoryIfNeeded(directory)
        }

        logger?("Directory structure verified")
    }

    /// Creates a directory if it doesn't already exist
    ///
    /// - Parameter url: The directory URL to create
    /// - Throws: MarkdownFileError.directoryCreationFailed if creation fails
    private func createDirectoryIfNeeded(_ url: URL) throws {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if exists && isDirectory.boolValue {
            // Directory already exists
            return
        }

        do {
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
            logger?("Created directory: \(url.path)")
        } catch {
            logger?("Failed to create directory \(url.path): \(error)")
            throw MarkdownFileError.directoryCreationFailed(url, error)
        }
    }

    // MARK: - Task I/O

    /// Reads a task from a markdown file
    ///
    /// - Parameter url: The URL of the markdown file to read
    /// - Returns: The parsed Task object, or nil if parsing fails
    /// - Throws: MarkdownFileError if reading fails
    func readTask(from url: URL) throws -> Task? {
        logger?("Reading task from: \(url.path)")

        // Read the file contents
        let markdown = try readFileContents(from: url)

        // Parse the frontmatter and body
        let (taskData, body) = YAMLParser.parseTask(markdown)

        guard var task = taskData else {
            logger?("No valid task frontmatter found in: \(url.path)")
            return nil
        }

        // Update the task's notes with the body content
        task.notes = body

        logger?("Successfully read task: \(task.title)")
        return task
    }

    /// Writes a task to a markdown file
    ///
    /// This method will:
    /// 1. Create the directory structure if needed (e.g., tasks/active/2025/11/)
    /// 2. Generate markdown with YAML frontmatter from the task
    /// 3. Write the file to the appropriate location
    ///
    /// - Parameters:
    ///   - task: The task to write
    ///   - url: The URL where the file should be written (optional, derived from task if not provided)
    /// - Throws: MarkdownFileError if writing fails
    func writeTask(_ task: Task, to url: URL? = nil) throws {
        // Determine the target URL
        let targetURL = url ?? taskURL(for: task)

        logger?("Writing task to: \(targetURL.path)")

        // Ensure the parent directory exists
        let parentDirectory = targetURL.deletingLastPathComponent()
        try createDirectoryIfNeeded(parentDirectory)

        // Generate markdown with frontmatter
        let markdown: String
        do {
            markdown = try YAMLParser.generateTask(task, body: task.notes)
        } catch {
            logger?("Failed to generate markdown for task: \(error)")
            throw MarkdownFileError.writeError(targetURL, error)
        }

        // Write to file
        try writeFileContents(markdown, to: targetURL)

        logger?("Successfully wrote task: \(task.title)")
    }

    /// Returns the URL where a task should be stored based on its properties
    ///
    /// Format: tasks/active/YYYY/MM/uuid-slug.md or tasks/archive/YYYY/MM/uuid-slug.md
    ///
    /// - Parameter task: The task
    /// - Returns: The URL where the task should be stored
    func taskURL(for task: Task) -> URL {
        return rootDirectory.appendingPathComponent(task.filePath)
    }

    // MARK: - Board I/O

    /// Reads a board from a markdown file
    ///
    /// - Parameter url: The URL of the markdown file to read
    /// - Returns: The parsed Board object, or nil if parsing fails
    /// - Throws: MarkdownFileError if reading fails
    func readBoard(from url: URL) throws -> Board? {
        logger?("Reading board from: \(url.path)")

        // Read the file contents
        let markdown = try readFileContents(from: url)

        // Parse the frontmatter and body
        let (boardData, body) = YAMLParser.parseBoard(markdown)

        guard var board = boardData else {
            logger?("No valid board frontmatter found in: \(url.path)")
            return nil
        }

        // Update the board's notes with the body content
        board.notes = body

        logger?("Successfully read board: \(board.displayTitle)")
        return board
    }

    /// Writes a board to a markdown file
    ///
    /// - Parameters:
    ///   - board: The board to write
    ///   - url: The URL where the file should be written (optional, derived from board if not provided)
    /// - Throws: MarkdownFileError if writing fails
    func writeBoard(_ board: Board, to url: URL? = nil) throws {
        // Determine the target URL
        let targetURL = url ?? boardURL(for: board)

        logger?("Writing board to: \(targetURL.path)")

        // Ensure the boards directory exists
        let boardsDirectory = rootDirectory.appendingPathComponent("boards")
        try createDirectoryIfNeeded(boardsDirectory)

        // Generate markdown with frontmatter
        let markdown: String
        do {
            markdown = try YAMLParser.generateBoard(board, body: board.notes ?? "")
        } catch {
            logger?("Failed to generate markdown for board: \(error)")
            throw MarkdownFileError.writeError(targetURL, error)
        }

        // Write to file
        try writeFileContents(markdown, to: targetURL)

        logger?("Successfully wrote board: \(board.displayTitle)")
    }

    /// Returns the URL where a board should be stored based on its ID
    ///
    /// Format: boards/board-id.md
    ///
    /// - Parameter board: The board
    /// - Returns: The URL where the board should be stored
    func boardURL(for board: Board) -> URL {
        return rootDirectory.appendingPathComponent(board.filePath)
    }

    // MARK: - Bulk Operations

    /// Loads all tasks from the file system
    ///
    /// This method scans both the active and archive directories and loads all
    /// task files it finds. Corrupted files are skipped and logged.
    ///
    /// - Returns: An array of all loaded tasks
    /// - Throws: MarkdownFileError if directory scanning fails
    func loadAllTasks() throws -> [Task] {
        logger?("Loading all tasks from file system")

        var tasks: [Task] = []

        // Load from active directory
        let activeDirectory = rootDirectory.appendingPathComponent("tasks/active")
        if fileManager.fileExists(atPath: activeDirectory.path) {
            let activeTasks = try loadTasksFromDirectory(activeDirectory)
            tasks.append(contentsOf: activeTasks)
            logger?("Loaded \(activeTasks.count) active tasks")
        }

        // Load from archive directory
        let archiveDirectory = rootDirectory.appendingPathComponent("tasks/archive")
        if fileManager.fileExists(atPath: archiveDirectory.path) {
            let archivedTasks = try loadTasksFromDirectory(archiveDirectory)
            tasks.append(contentsOf: archivedTasks)
            logger?("Loaded \(archivedTasks.count) archived tasks")
        }

        logger?("Total tasks loaded: \(tasks.count)")
        return tasks
    }

    /// Loads all boards from the file system
    ///
    /// - Returns: An array of all loaded boards
    /// - Throws: MarkdownFileError if directory scanning fails
    func loadAllBoards() throws -> [Board] {
        logger?("Loading all boards from file system")

        let boardsDirectory = rootDirectory.appendingPathComponent("boards")

        guard fileManager.fileExists(atPath: boardsDirectory.path) else {
            logger?("Boards directory does not exist yet")
            return []
        }

        let boards = try loadBoardsFromDirectory(boardsDirectory)
        logger?("Total boards loaded: \(boards.count)")
        return boards
    }

    // MARK: - Private Helpers

    /// Recursively loads all tasks from a directory and its subdirectories
    private func loadTasksFromDirectory(_ directory: URL) throws -> [Task] {
        var tasks: [Task] = []

        let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        guard let enumerator = enumerator else {
            throw MarkdownFileError.readError(directory, NSError(domain: "FileManager", code: -1))
        }

        for case let fileURL as URL in enumerator {
            // Only process .md files
            guard fileURL.pathExtension == "md" else { continue }

            do {
                if let task = try readTask(from: fileURL) {
                    tasks.append(task)
                }
            } catch {
                // Log but don't fail - skip corrupted files
                logger?("Failed to load task from \(fileURL.path): \(error)")
            }
        }

        return tasks
    }

    /// Loads all boards from a directory
    private func loadBoardsFromDirectory(_ directory: URL) throws -> [Board] {
        var boards: [Board] = []

        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        for fileURL in contents {
            // Only process .md files
            guard fileURL.pathExtension == "md" else { continue }

            do {
                if let board = try readBoard(from: fileURL) {
                    boards.append(board)
                }
            } catch {
                // Log but don't fail - skip corrupted files
                logger?("Failed to load board from \(fileURL.path): \(error)")
            }
        }

        return boards
    }

    /// Reads the contents of a file as a string
    private func readFileContents(from url: URL) throws -> String {
        // Check if file exists
        guard fileManager.fileExists(atPath: url.path) else {
            throw MarkdownFileError.fileNotFound(url)
        }

        // Check if file is readable
        guard fileManager.isReadableFile(atPath: url.path) else {
            throw MarkdownFileError.permissionDenied(url)
        }

        // Read the file
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw MarkdownFileError.readError(url, error)
        }
    }

    /// Writes a string to a file
    private func writeFileContents(_ contents: String, to url: URL) throws {
        do {
            try contents.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw MarkdownFileError.writeError(url, error)
        }
    }

    // MARK: - File Management

    /// Deletes a task file from the file system
    ///
    /// - Parameter task: The task whose file should be deleted
    /// - Throws: MarkdownFileError if deletion fails
    func deleteTask(_ task: Task) throws {
        let url = taskURL(for: task)
        try deleteFile(at: url)
        logger?("Deleted task file: \(url.path)")
    }

    /// Deletes a board file from the file system
    ///
    /// - Parameter board: The board whose file should be deleted
    /// - Throws: MarkdownFileError if deletion fails
    func deleteBoard(_ board: Board) throws {
        let url = boardURL(for: board)
        try deleteFile(at: url)
        logger?("Deleted board file: \(url.path)")
    }

    /// Deletes a file at the specified URL
    private func deleteFile(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            // File doesn't exist, nothing to delete
            return
        }

        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw MarkdownFileError.writeError(url, error)
        }
    }

    /// Moves a task file (e.g., from active to archive)
    ///
    /// - Parameters:
    ///   - task: The task to move
    ///   - fromURL: The current location
    ///   - toURL: The new location
    /// - Throws: MarkdownFileError if the move fails
    func moveTaskFile(for task: Task, from fromURL: URL, to toURL: URL) throws {
        // Ensure destination directory exists
        let destinationDirectory = toURL.deletingLastPathComponent()
        try createDirectoryIfNeeded(destinationDirectory)

        do {
            // If destination exists, remove it first
            if fileManager.fileExists(atPath: toURL.path) {
                try fileManager.removeItem(at: toURL)
            }

            try fileManager.moveItem(at: fromURL, to: toURL)
            logger?("Moved task file from \(fromURL.path) to \(toURL.path)")
        } catch {
            throw MarkdownFileError.writeError(toURL, error)
        }
    }
}

// MARK: - Utility Extensions

extension MarkdownFileIO {
    /// Returns the URL for the tasks directory
    var tasksDirectory: URL {
        rootDirectory.appendingPathComponent("tasks")
    }

    /// Returns the URL for the active tasks directory
    var activeTasksDirectory: URL {
        rootDirectory.appendingPathComponent("tasks/active")
    }

    /// Returns the URL for the archived tasks directory
    var archivedTasksDirectory: URL {
        rootDirectory.appendingPathComponent("tasks/archive")
    }

    /// Returns the URL for the boards directory
    var boardsDirectory: URL {
        rootDirectory.appendingPathComponent("boards")
    }

    /// Returns the URL for the config directory
    var configDirectory: URL {
        rootDirectory.appendingPathComponent("config")
    }
}
