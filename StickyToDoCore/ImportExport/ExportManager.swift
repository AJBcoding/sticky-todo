//
//  ExportManager.swift
//  StickyToDo
//
//  Manages export of tasks and boards to various formats.
//

import Foundation

/// Manages export operations for tasks and boards
///
/// Supports multiple export formats with comprehensive error handling and progress reporting.
/// All operations are thread-safe and can be performed asynchronously.
///
/// Example usage:
/// ```swift
/// let manager = ExportManager()
/// let options = ExportOptions(format: .json, filename: "my-tasks")
/// let result = try await manager.export(tasks: tasks, to: url, options: options)
/// print(result.summary)
/// ```
public class ExportManager {
    // MARK: - Properties

    /// Progress callback for long operations
    public var progressHandler: ((Double, String) -> Void)?

    /// Queue for thread-safe operations
    private let queue = DispatchQueue(label: "com.stickytodo.exportmanager", attributes: .concurrent)

    // MARK: - Initialization

    public init() {}

    // MARK: - Public API

    /// Exports tasks to the specified format
    /// - Parameters:
    ///   - tasks: Tasks to export
    ///   - url: Destination file/directory URL
    ///   - options: Export configuration options
    /// - Returns: Export result with metadata
    /// - Throws: ExportError on failure
    public func export(tasks: [Task], boards: [Board] = [], to url: URL, options: ExportOptions) async throws -> ExportResult {
        // Filter tasks based on options
        let filteredTasks = filterTasks(tasks, options: options)

        reportProgress(0.0, "Preparing export...")

        // Export based on format
        let result: ExportResult
        switch options.format {
        case .nativeMarkdownArchive:
            result = try await exportNativeArchive(tasks: filteredTasks, boards: boards, to: url, options: options)
        case .simplifiedMarkdown:
            result = try await exportSimplifiedMarkdown(tasks: filteredTasks, to: url, options: options)
        case .taskpaper:
            result = try await exportTaskPaper(tasks: filteredTasks, to: url, options: options)
        case .csv:
            result = try await exportCSV(tasks: filteredTasks, to: url, options: options)
        case .tsv:
            result = try await exportTSV(tasks: filteredTasks, to: url, options: options)
        case .json:
            result = try await exportJSON(tasks: filteredTasks, to: url, options: options)
        }

        reportProgress(1.0, "Export complete")
        return result
    }

    /// Generates a preview of what will be exported (without writing files)
    /// - Parameters:
    ///   - tasks: Tasks to preview
    ///   - options: Export options
    /// - Returns: Preview information
    public func preview(tasks: [Task], options: ExportOptions) -> ExportPreview {
        let filtered = filterTasks(tasks, options: options)
        let projects = Set(filtered.compactMap { $0.project }).sorted()
        let contexts = Set(filtered.compactMap { $0.context }).sorted()

        return ExportPreview(
            taskCount: filtered.count,
            projects: projects,
            contexts: contexts,
            warnings: options.format.dataLossWarnings
        )
    }

    // MARK: - Native Markdown Archive

    /// Exports complete project structure as ZIP
    private func exportNativeArchive(tasks: [Task], boards: [Board], to url: URL, options: ExportOptions) async throws -> ExportResult {
        reportProgress(0.1, "Creating temporary directory...")

        // Create temporary directory for archive contents
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        reportProgress(0.2, "Writing task files...")

        // Group tasks by their file paths
        var taskCount = 0
        for (index, task) in tasks.enumerated() {
            let taskPath = tempDir.appendingPathComponent(task.filePath)
            try FileManager.default.createDirectory(
                at: taskPath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let content = try renderNativeMarkdown(task: task)
            try content.write(to: taskPath, atomically: true, encoding: .utf8)
            taskCount += 1

            let progress = 0.2 + (Double(index) / Double(tasks.count)) * 0.4
            reportProgress(progress, "Writing task \(index + 1)/\(tasks.count)...")
        }

        reportProgress(0.6, "Writing board files...")

        // Write board files if included
        var boardCount = 0
        if options.includeBoards {
            let boardsDir = tempDir.appendingPathComponent("boards")
            try FileManager.default.createDirectory(at: boardsDir, withIntermediateDirectories: true)

            for board in boards {
                let boardPath = boardsDir.appendingPathComponent(board.fileName)
                let content = try renderBoardMarkdown(board: board)
                try content.write(to: boardPath, atomically: true, encoding: .utf8)
                boardCount += 1
            }
        }

        reportProgress(0.7, "Creating ZIP archive...")

        // Create ZIP archive
        let zipURL = url.pathExtension == "zip" ? url : url.appendingPathExtension("zip")
        try await createZipArchive(from: tempDir, to: zipURL)

        reportProgress(0.9, "Finalizing...")

        // Get file size
        let attrs = try FileManager.default.attributesOfItem(atPath: zipURL.path)
        let fileSize = attrs[.size] as? Int64 ?? 0

        return ExportResult(
            fileURL: zipURL,
            format: .nativeMarkdownArchive,
            taskCount: taskCount,
            boardCount: boardCount,
            fileSize: fileSize,
            warnings: []
        )
    }

    /// Renders a task in native markdown format with YAML frontmatter
    private func renderNativeMarkdown(task: Task) throws -> String {
        var yaml = "---\n"
        yaml += "type: \(task.type.rawValue)\n"
        yaml += "title: \"\(escapeYAML(task.title))\"\n"
        yaml += "status: \(task.status.rawValue)\n"

        if let project = task.project {
            yaml += "project: \"\(escapeYAML(project))\"\n"
        }

        if let context = task.context {
            yaml += "context: \"\(escapeYAML(context))\"\n"
        }

        if let due = task.due {
            yaml += "due: \(formatISO8601(due))\n"
        }

        if let defer = task.defer {
            yaml += "defer: \(formatISO8601(defer))\n"
        }

        if task.flagged {
            yaml += "flagged: true\n"
        }

        yaml += "priority: \(task.priority.rawValue)\n"

        if let effort = task.effort {
            yaml += "effort: \(effort)\n"
        }

        // Write positions
        if !task.positions.isEmpty {
            yaml += "positions:\n"
            for (boardId, position) in task.positions.sorted(by: { $0.key < $1.key }) {
                yaml += "  \(boardId): {x: \(position.x), y: \(position.y)}\n"
            }
        }

        yaml += "created: \(formatISO8601(task.created))\n"
        yaml += "modified: \(formatISO8601(task.modified))\n"
        yaml += "---\n\n"

        yaml += task.notes

        return yaml
    }

    /// Renders a board in native markdown format
    private func renderBoardMarkdown(board: Board) throws -> String {
        var yaml = "---\n"
        yaml += "type: \(board.type.rawValue)\n"
        yaml += "layout: \(board.layout.rawValue)\n"

        // Write filter
        yaml += "filter:\n"
        if let type = board.filter.type {
            yaml += "  type: \(type.rawValue)\n"
        }
        if let status = board.filter.status {
            yaml += "  status: \(status.rawValue)\n"
        }
        if let project = board.filter.project {
            yaml += "  project: \"\(escapeYAML(project))\"\n"
        }
        if let context = board.filter.context {
            yaml += "  context: \"\(escapeYAML(context))\"\n"
        }
        if let flagged = board.filter.flagged {
            yaml += "  flagged: \(flagged)\n"
        }

        if let columns = board.columns, !columns.isEmpty {
            yaml += "columns: [\(columns.map { "\"\($0)\"" }.joined(separator: ", "))]\n"
        }

        yaml += "autoHide: \(board.autoHide)\n"
        yaml += "hideAfterDays: \(board.hideAfterDays)\n"

        yaml += "---\n\n"
        yaml += "# \(board.displayTitle)\n\n"

        if let notes = board.notes {
            yaml += notes
        }

        return yaml
    }

    // MARK: - Simplified Markdown

    /// Exports tasks as simplified markdown files (one per project/board)
    private func exportSimplifiedMarkdown(tasks: [Task], to url: URL, options: ExportOptions) async throws -> ExportResult {
        reportProgress(0.1, "Grouping tasks...")

        // Group tasks by project (nil project goes to "Inbox")
        let grouped = Dictionary(grouping: tasks) { $0.project ?? "Inbox" }

        reportProgress(0.2, "Writing markdown files...")

        // Create directory if exporting multiple files
        let baseURL = url.pathExtension == "md" ? url.deletingLastPathComponent() : url
        if grouped.count > 1 {
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }

        var totalTasks = 0
        var warnings: [String] = []

        for (index, (project, projectTasks)) in grouped.enumerated() {
            let filename = "\(project.slugified()).md"
            let fileURL = grouped.count == 1 ? url : baseURL.appendingPathComponent(filename)

            var content = "# \(project)\n\n"

            // Sort tasks by status, then priority
            let sorted = projectTasks.sorted { t1, t2 in
                if t1.status != t2.status {
                    return t1.status.rawValue < t2.status.rawValue
                }
                return t1.priority.sortOrder > t2.priority.sortOrder
            }

            for task in sorted {
                content += renderSimplifiedTask(task)
            }

            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            totalTasks += projectTasks.count

            let progress = 0.2 + (Double(index) / Double(grouped.count)) * 0.7
            reportProgress(progress, "Writing project \(index + 1)/\(grouped.count)...")
        }

        warnings.append(contentsOf: ExportFormat.simplifiedMarkdown.dataLossWarnings)

        let finalURL = grouped.count == 1 ? url : baseURL
        let fileSize = try calculateDirectorySize(finalURL)

        return ExportResult(
            fileURL: finalURL,
            format: .simplifiedMarkdown,
            taskCount: totalTasks,
            fileSize: fileSize,
            warnings: warnings
        )
    }

    /// Renders a task in simplified markdown format
    /// Example: - [ ] Call John @phone !high (due: 2025-11-20)
    private func renderSimplifiedTask(_ task: Task) -> String {
        let checkbox = task.status == .completed ? "[x]" : "[ ]"
        var line = "- \(checkbox) \(task.title)"

        // Add inline metadata
        var metadata: [String] = []

        if let context = task.context {
            metadata.append(context)
        }

        if let project = task.project {
            metadata.append("#\(project.replacingOccurrences(of: " ", with: "-"))")
        }

        switch task.priority {
        case .high:
            metadata.append("!high")
        case .low:
            metadata.append("!low")
        case .medium:
            break // Don't show medium priority
        }

        if let due = task.due {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            metadata.append("(due: \(formatter.string(from: due)))")
        }

        if task.status == .completed {
            metadata.append("(completed)")
        } else if task.status == .waiting {
            metadata.append("(waiting)")
        }

        if !metadata.isEmpty {
            line += " " + metadata.joined(separator: " ")
        }

        line += "\n"

        // Add notes as indented content
        if !task.notes.isEmpty {
            let indentedNotes = task.notes.components(separatedBy: .newlines)
                .map { "  \($0)" }
                .joined(separator: "\n")
            line += indentedNotes + "\n"
        }

        line += "\n"
        return line
    }

    // MARK: - TaskPaper Format

    /// Exports tasks in TaskPaper format
    private func exportTaskPaper(tasks: [Task], to url: URL, options: ExportOptions) async throws -> ExportResult {
        reportProgress(0.2, "Converting to TaskPaper format...")

        var content = ""
        let grouped = Dictionary(grouping: tasks) { $0.project ?? "Inbox" }

        for (project, projectTasks) in grouped.sorted(by: { $0.key < $1.key }) {
            content += "\(project):\n"

            for task in projectTasks.sorted(by: { $0.created < $1.created }) {
                content += renderTaskPaperTask(task)
            }

            content += "\n"
        }

        reportProgress(0.8, "Writing file...")

        let fileURL = url.pathExtension == "taskpaper" ? url : url.appendingPathExtension("taskpaper")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attrs[.size] as? Int64 ?? 0

        return ExportResult(
            fileURL: fileURL,
            format: .taskpaper,
            taskCount: tasks.count,
            fileSize: fileSize,
            warnings: ExportFormat.taskpaper.dataLossWarnings
        )
    }

    /// Renders a task in TaskPaper format
    /// Example: Call John @phone @project(Website) @priority(high) @due(2025-11-20)
    private func renderTaskPaperTask(_ task: Task) -> String {
        var line = "\t\(task.title)"

        if task.status == .completed {
            line += " @done"
        }

        if let context = task.context {
            line += " \(context)"
        }

        if let project = task.project {
            line += " @project(\(project))"
        }

        if task.priority != .medium {
            line += " @priority(\(task.priority.rawValue))"
        }

        if let due = task.due {
            line += " @due(\(formatShortDate(due)))"
        }

        if let defer = task.defer {
            line += " @defer(\(formatShortDate(defer)))"
        }

        if task.flagged {
            line += " @flagged"
        }

        if task.status == .waiting {
            line += " @waiting"
        }

        if let effort = task.effort {
            line += " @effort(\(effort)m)"
        }

        line += "\n"

        // Add notes as indented lines
        if !task.notes.isEmpty {
            let indentedNotes = task.notes.components(separatedBy: .newlines)
                .map { "\t\t\($0)" }
                .joined(separator: "\n")
            line += indentedNotes + "\n"
        }

        return line
    }

    // MARK: - CSV Export

    /// Exports tasks as CSV
    private func exportCSV(tasks: [Task], to url: URL, options: ExportOptions) async throws -> ExportResult {
        try await exportDelimited(tasks: tasks, to: url, options: options, delimiter: ",", format: .csv)
    }

    // MARK: - TSV Export

    /// Exports tasks as TSV
    private func exportTSV(tasks: [Task], to url: URL, options: ExportOptions) async throws -> ExportResult {
        try await exportDelimited(tasks: tasks, to: url, options: options, delimiter: "\t", format: .tsv)
    }

    /// Exports tasks in delimited format (CSV or TSV)
    private func exportDelimited(tasks: [Task], to url: URL, options: ExportOptions, delimiter: String, format: ExportFormat) async throws -> ExportResult {
        reportProgress(0.2, "Converting to \(format.displayName)...")

        // Header row
        let headers = [
            "ID", "Type", "Title", "Status", "Project", "Context",
            "Due", "Defer", "Flagged", "Priority", "Effort",
            "Created", "Modified", "Notes"
        ]

        var rows: [[String]] = [headers]

        // Data rows
        for task in tasks {
            let row = [
                task.id.uuidString,
                task.type.rawValue,
                task.title,
                task.status.rawValue,
                task.project ?? "",
                task.context ?? "",
                task.due.map(formatShortDate) ?? "",
                task.defer.map(formatShortDate) ?? "",
                task.flagged ? "true" : "false",
                task.priority.rawValue,
                task.effort.map(String.init) ?? "",
                formatISO8601(task.created),
                formatISO8601(task.modified),
                task.notes
            ]
            rows.append(row)
        }

        reportProgress(0.6, "Writing file...")

        // Convert to delimited format
        let content = rows.map { row in
            row.map { field in
                escapeDelimited(field, delimiter: delimiter)
            }.joined(separator: delimiter)
        }.joined(separator: "\n")

        let ext = format.fileExtension
        let fileURL = url.pathExtension == ext ? url : url.appendingPathExtension(ext)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attrs[.size] as? Int64 ?? 0

        return ExportResult(
            fileURL: fileURL,
            format: format,
            taskCount: tasks.count,
            fileSize: fileSize,
            warnings: format.dataLossWarnings
        )
    }

    // MARK: - JSON Export

    /// Exports tasks as JSON
    private func exportJSON(tasks: [Task], to url: URL, options: ExportOptions) async throws -> ExportResult {
        reportProgress(0.2, "Converting to JSON...")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(tasks)

        reportProgress(0.8, "Writing file...")

        let fileURL = url.pathExtension == "json" ? url : url.appendingPathExtension("json")
        try data.write(to: fileURL)

        let fileSize = Int64(data.count)

        return ExportResult(
            fileURL: fileURL,
            format: .json,
            taskCount: tasks.count,
            fileSize: fileSize,
            warnings: ExportFormat.json.dataLossWarnings
        )
    }

    // MARK: - Helper Methods

    /// Filters tasks based on export options
    private func filterTasks(_ tasks: [Task], options: ExportOptions) -> [Task] {
        var filtered = tasks

        // Apply completion filter
        if !options.includeCompleted {
            filtered = filtered.filter { $0.status != .completed }
        }

        // Apply archived filter (assuming archived = completed and old)
        if !options.includeArchived {
            let archiveCutoff = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { task in
                task.status != .completed || task.modified > archiveCutoff
            }
        }

        // Apply notes filter
        if !options.includeNotes {
            filtered = filtered.filter { $0.type == .task }
        }

        // Apply custom filter
        if let customFilter = options.filter {
            filtered = filtered.filter { $0.matches(customFilter) }
        }

        // Apply date range
        if let dateRange = options.dateRange {
            filtered = filtered.filter { task in
                dateRange.contains(task.created)
            }
        }

        // Apply project filter
        if let projects = options.projects, !projects.isEmpty {
            filtered = filtered.filter { task in
                guard let project = task.project else { return false }
                return projects.contains(project)
            }
        }

        // Apply context filter
        if let contexts = options.contexts, !contexts.isEmpty {
            filtered = filtered.filter { task in
                guard let context = task.context else { return false }
                return contexts.contains(context)
            }
        }

        return filtered
    }

    /// Reports progress to the progress handler
    private func reportProgress(_ progress: Double, _ message: String) {
        DispatchQueue.main.async {
            self.progressHandler?(progress, message)
        }
    }

    /// Creates a ZIP archive from a directory
    private func createZipArchive(from sourceURL: URL, to destinationURL: URL) async throws {
        // This is a simplified implementation. In production, use a library like ZIPFoundation
        // For now, we'll use the system's zip command if available

        let process = Process()
        process.currentDirectoryURL = sourceURL.deletingLastPathComponent()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-q", destinationURL.path, sourceURL.lastPathComponent]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw ExportError.zipCreationFailed("ZIP creation failed with status \(process.terminationStatus)")
        }
    }

    /// Calculates total size of a directory
    private func calculateDirectorySize(_ url: URL) throws -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            totalSize += attrs[.size] as? Int64 ?? 0
        }

        return totalSize
    }

    /// Escapes a string for YAML format
    private func escapeYAML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// Escapes a field for delimited format (CSV/TSV)
    private func escapeDelimited(_ field: String, delimiter: String) -> String {
        let needsEscaping = field.contains(delimiter) || field.contains("\"") || field.contains("\n")

        if !needsEscaping {
            return field
        }

        // Escape quotes by doubling them
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")

        // Wrap in quotes
        return "\"\(escaped)\""
    }

    /// Formats a date in ISO8601 format
    private func formatISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }

    /// Formats a date in short format (YYYY-MM-DD)
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Export Errors

/// Errors that can occur during export
public enum ExportError: Error, CustomStringConvertible {
    case fileWriteFailed(String)
    case directoryCreationFailed(String)
    case zipCreationFailed(String)
    case invalidURL(String)
    case encodingFailed(String)
    case permissionDenied(String)

    public var description: String {
        switch self {
        case .fileWriteFailed(let message):
            return "Failed to write file: \(message)"
        case .directoryCreationFailed(let message):
            return "Failed to create directory: \(message)"
        case .zipCreationFailed(let message):
            return "Failed to create ZIP archive: \(message)"
        case .invalidURL(let message):
            return "Invalid URL: \(message)"
        case .encodingFailed(let message):
            return "Encoding failed: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        }
    }
}

// MARK: - Export Preview

/// Preview information for an export operation
public struct ExportPreview {
    public let taskCount: Int
    public let projects: [String]
    public let contexts: [String]
    public let warnings: [String]

    public init(taskCount: Int, projects: [String], contexts: [String], warnings: [String]) {
        self.taskCount = taskCount
        self.projects = projects
        self.contexts = contexts
        self.warnings = warnings
    }
}

// MARK: - String Extensions

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
