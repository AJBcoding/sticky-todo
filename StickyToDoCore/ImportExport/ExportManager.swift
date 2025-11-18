//
//  ExportManager.swift
//  StickyToDo
//
//  Manages export of tasks and boards to various formats.
//

import Foundation
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(AppKit)
import AppKit
#endif

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
        case .omnifocus:
            result = try await exportOmniFocus(tasks: filteredTasks, to: url, options: options)
        case .things:
            result = try await exportThings(tasks: filteredTasks, to: url, options: options)
        case .csv:
            result = try await exportCSV(tasks: filteredTasks, to: url, options: options)
        case .tsv:
            result = try await exportTSV(tasks: filteredTasks, to: url, options: options)
        case .json:
            result = try await exportJSON(tasks: filteredTasks, to: url, options: options)
        case .html:
            result = try await exportHTML(tasks: filteredTasks, to: url, options: options)
        case .pdf:
            result = try await exportPDF(tasks: filteredTasks, to: url, options: options)
        case .ical:
            result = try await exportiCal(tasks: filteredTasks, to: url, options: options)
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

    // MARK: - OmniFocus Export

    /// Exports tasks in OmniFocus-compatible TaskPaper format
    private func exportOmniFocus(tasks: [Task], to url: URL, options: ExportOptions) async throws -> ExportResult {
        reportProgress(0.2, "Converting to OmniFocus format...")

        var content = ""
        let grouped = Dictionary(grouping: tasks) { $0.project ?? "Inbox" }

        for (project, projectTasks) in grouped.sorted(by: { $0.key < $1.key }) {
            content += "\(project):\n"

            for task in projectTasks.sorted(by: { $0.created < $1.created }) {
                content += renderOmniFocusTask(task)
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
            format: .omnifocus,
            taskCount: tasks.count,
            fileSize: fileSize,
            warnings: ExportFormat.omnifocus.dataLossWarnings
        )
    }

    /// Renders a task in OmniFocus-compatible TaskPaper format
    /// OmniFocus recognizes: @context, @defer(), @due(), @parallel, @sequential, @done
    private func renderOmniFocusTask(_ task: Task) -> String {
        var line = "\t- \(task.title)"

        if task.status == .completed {
            line += " @done(\(formatShortDate(task.modified)))"
        }

        if let context = task.context {
            line += " \(context)"
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

        // Map priority to OmniFocus tags
        switch task.priority {
        case .high:
            line += " @priority(1)"
        case .medium:
            line += " @priority(2)"
        case .low:
            line += " @priority(3)"
        }

        if task.status == .waiting {
            line += " @waiting"
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

    // MARK: - Things Export

    /// Exports tasks in Things-compatible JSON format
    private func exportThings(tasks: [Task], to url: URL, options: ExportOptions) async throws -> ExportResult {
        reportProgress(0.2, "Converting to Things format...")

        // Things JSON format structure
        var thingsItems: [[String: Any]] = []

        for task in tasks {
            var item: [String: Any] = [
                "type": "to-do",
                "title": task.title,
                "notes": task.notes
            ]

            // Project mapping (Things calls them "projects" or "areas")
            if let project = task.project {
                item["list"] = project
            }

            // Tags (Things uses tags for contexts)
            var tags: [String] = []
            if let context = task.context {
                tags.append(context.replacingOccurrences(of: "@", with: ""))
            }
            if !tags.isEmpty {
                item["tags"] = tags
            }

            // Due date
            if let due = task.due {
                item["when"] = formatShortDate(due)
            }

            // Defer date (Things calls this "when")
            if let defer = task.defer {
                item["deadline"] = formatShortDate(defer)
            }

            // Completed status
            if task.status == .completed {
                item["completed"] = true
                item["completed-date"] = formatShortDate(task.modified)
            }

            // Checklist items (subtasks)
            if !task.subtaskIds.isEmpty {
                item["checklist-items"] = task.subtaskIds.map { ["title": $0.uuidString] }
            }

            thingsItems.append(item)
        }

        // Create wrapper array for Things import
        let thingsData = thingsItems

        reportProgress(0.6, "Writing file...")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(thingsData)

        let fileURL = url.pathExtension == "json" ? url : url.appendingPathExtension("json")
        try data.write(to: fileURL)

        let fileSize = Int64(data.count)

        return ExportResult(
            fileURL: fileURL,
            format: .things,
            taskCount: tasks.count,
            fileSize: fileSize,
            warnings: ExportFormat.things.dataLossWarnings
        )
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

        // Determine which columns to include
        let columns = options.csvColumns ?? CSVColumn.allCases

        // Header row
        let headers = columns.map { $0.rawValue }

        var rows: [[String]] = [headers]

        // Data rows
        for task in tasks {
            var row: [String] = []

            for column in columns {
                let value: String
                switch column {
                case .id:
                    value = task.id.uuidString
                case .type:
                    value = task.type.rawValue
                case .title:
                    value = task.title
                case .status:
                    value = task.status.rawValue
                case .project:
                    value = task.project ?? ""
                case .context:
                    value = task.context ?? ""
                case .due:
                    value = task.due.map(formatShortDate) ?? ""
                case .deferDate:
                    value = task.defer.map(formatShortDate) ?? ""
                case .flagged:
                    value = task.flagged ? "true" : "false"
                case .priority:
                    value = task.priority.rawValue
                case .effort:
                    value = task.effort.map(String.init) ?? ""
                case .created:
                    value = formatISO8601(task.created)
                case .modified:
                    value = formatISO8601(task.modified)
                case .notes:
                    value = task.notes
                case .tags:
                    value = task.tags.map { $0.name }.joined(separator: ", ")
                case .timeSpent:
                    value = task.timeSpentDescription ?? ""
                case .completionDate:
                    value = task.status == .completed ? formatShortDate(task.modified) : ""
                }
                row.append(value)
            }
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

    // MARK: - HTML Export

    /// Exports tasks as formatted HTML report
    private func exportHTML(tasks: [Task], to url: URL, options: ExportOptions) async throws -> ExportResult {
        reportProgress(0.2, "Generating HTML report...")

        let analytics = AnalyticsCalculator().calculate(for: tasks)
        let html = generateHTMLReport(tasks: tasks, analytics: analytics, options: options)

        reportProgress(0.8, "Writing file...")

        let fileURL = url.pathExtension == "html" ? url : url.appendingPathExtension("html")
        try html.write(to: fileURL, atomically: true, encoding: .utf8)

        let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attrs[.size] as? Int64 ?? 0

        return ExportResult(
            fileURL: fileURL,
            format: .html,
            taskCount: tasks.count,
            fileSize: fileSize,
            warnings: ExportFormat.html.dataLossWarnings
        )
    }

    /// Generates HTML report content
    private func generateHTMLReport(tasks: [Task], analytics: AnalyticsCalculator.Analytics, options: ExportOptions) -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>StickyToDo Export - \(options.filename)</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 20px;
                    background: #f5f5f5;
                }
                .header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 40px;
                    border-radius: 10px;
                    margin-bottom: 30px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                }
                .header h1 { font-size: 2.5em; margin-bottom: 10px; }
                .header p { opacity: 0.9; font-size: 1.1em; }
                .stats {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 20px;
                    margin-bottom: 30px;
                }
                .stat-card {
                    background: white;
                    padding: 20px;
                    border-radius: 8px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }
                .stat-card h3 {
                    font-size: 0.9em;
                    color: #666;
                    text-transform: uppercase;
                    margin-bottom: 10px;
                }
                .stat-card .value {
                    font-size: 2em;
                    font-weight: bold;
                    color: #667eea;
                }
                .section {
                    background: white;
                    padding: 30px;
                    border-radius: 8px;
                    margin-bottom: 20px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }
                .section h2 {
                    color: #667eea;
                    margin-bottom: 20px;
                    padding-bottom: 10px;
                    border-bottom: 2px solid #eee;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 20px;
                }
                th, td {
                    padding: 12px;
                    text-align: left;
                    border-bottom: 1px solid #eee;
                }
                th {
                    background: #f8f9fa;
                    font-weight: 600;
                    color: #666;
                    text-transform: uppercase;
                    font-size: 0.85em;
                }
                tr:hover { background: #f8f9fa; }
                .status-badge {
                    display: inline-block;
                    padding: 4px 12px;
                    border-radius: 12px;
                    font-size: 0.85em;
                    font-weight: 500;
                }
                .status-inbox { background: #e3f2fd; color: #1976d2; }
                .status-next-action { background: #e8f5e9; color: #388e3c; }
                .status-waiting { background: #fff3e0; color: #f57c00; }
                .status-someday { background: #f3e5f5; color: #7b1fa2; }
                .status-completed { background: #e0e0e0; color: #616161; }
                .priority-high { color: #d32f2f; font-weight: bold; }
                .priority-medium { color: #f57c00; }
                .priority-low { color: #1976d2; }
                .chart-bar {
                    display: flex;
                    align-items: center;
                    margin-bottom: 15px;
                }
                .chart-label {
                    width: 150px;
                    font-size: 0.9em;
                    color: #666;
                }
                .chart-bar-container {
                    flex: 1;
                    background: #e0e0e0;
                    border-radius: 4px;
                    height: 24px;
                    position: relative;
                    overflow: hidden;
                }
                .chart-bar-fill {
                    background: linear-gradient(90deg, #667eea, #764ba2);
                    height: 100%;
                    border-radius: 4px;
                    transition: width 0.3s;
                }
                .chart-value {
                    margin-left: 10px;
                    font-weight: 600;
                    color: #667eea;
                    min-width: 40px;
                }
                .footer {
                    text-align: center;
                    margin-top: 40px;
                    padding: 20px;
                    color: #999;
                    font-size: 0.9em;
                }
                @media print {
                    body { background: white; }
                    .section, .stat-card { box-shadow: none; border: 1px solid #ddd; }
                }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>📋 StickyToDo Export</h1>
                <p>Generated on \(formatLongDate(Date()))</p>
            </div>

            <div class="stats">
                <div class="stat-card">
                    <h3>Total Tasks</h3>
                    <div class="value">\(analytics.totalTasks)</div>
                </div>
                <div class="stat-card">
                    <h3>Completed</h3>
                    <div class="value">\(analytics.completedTasks)</div>
                </div>
                <div class="stat-card">
                    <h3>Active</h3>
                    <div class="value">\(analytics.activeTasks)</div>
                </div>
                <div class="stat-card">
                    <h3>Completion Rate</h3>
                    <div class="value">\(analytics.completionRateString)</div>
                </div>
            </div>

            <div class="section">
                <h2>📊 Task Distribution</h2>

                <h3 style="margin-top: 20px;">By Status</h3>
        """

        // Status distribution chart
        let maxStatusCount = analytics.tasksByStatus.values.max() ?? 1
        for status in Status.allCases {
            let count = analytics.tasksByStatus[status] ?? 0
            let percentage = maxStatusCount > 0 ? (Double(count) / Double(maxStatusCount)) * 100 : 0
            html += """
                <div class="chart-bar">
                    <div class="chart-label">\(status.displayName)</div>
                    <div class="chart-bar-container">
                        <div class="chart-bar-fill" style="width: \(percentage)%"></div>
                    </div>
                    <div class="chart-value">\(count)</div>
                </div>
            """
        }

        html += """
                <h3 style="margin-top: 30px;">By Priority</h3>
        """

        // Priority distribution chart
        let maxPriorityCount = analytics.tasksByPriority.values.max() ?? 1
        for priority in Priority.allCases {
            let count = analytics.tasksByPriority[priority] ?? 0
            let percentage = maxPriorityCount > 0 ? (Double(count) / Double(maxPriorityCount)) * 100 : 0
            html += """
                <div class="chart-bar">
                    <div class="chart-label">\(priority.displayName)</div>
                    <div class="chart-bar-container">
                        <div class="chart-bar-fill" style="width: \(percentage)%"></div>
                    </div>
                    <div class="chart-value">\(count)</div>
                </div>
            """
        }

        html += """
            </div>

            <div class="section">
                <h2>📝 All Tasks</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Title</th>
                            <th>Status</th>
                            <th>Priority</th>
                            <th>Project</th>
                            <th>Due Date</th>
                        </tr>
                    </thead>
                    <tbody>
        """

        // Task table
        for task in tasks.sorted(by: { $0.created > $1.created }) {
            let statusClass = "status-\(task.status.rawValue)"
            let priorityClass = "priority-\(task.priority.rawValue)"
            let dueDate = task.due.map { formatShortDate($0) } ?? "-"
            let project = task.project ?? "-"

            html += """
                        <tr>
                            <td>\(escapeHTML(task.title))</td>
                            <td><span class="status-badge \(statusClass)">\(task.status.displayName)</span></td>
                            <td class="\(priorityClass)">\(task.priority.displayName)</td>
                            <td>\(escapeHTML(project))</td>
                            <td>\(dueDate)</td>
                        </tr>
            """
        }

        html += """
                    </tbody>
                </table>
            </div>

            <div class="footer">
                <p>Exported from StickyToDo • \(tasks.count) task\(tasks.count == 1 ? "" : "s")</p>
            </div>
        </body>
        </html>
        """

        return html
    }

    // MARK: - PDF Export

    /// Exports tasks as PDF report using PDFKit
    private func exportPDF(tasks: [Task], to url: URL, options: ExportOptions) async throws -> ExportResult {
        #if canImport(PDFKit) && canImport(AppKit)
        reportProgress(0.1, "Calculating analytics...")

        let analytics = AnalyticsCalculator().calculate(for: tasks)

        reportProgress(0.3, "Creating PDF document...")

        // Create PDF document
        let pdfDocument = PDFDocument()
        let pageWidth: CGFloat = 612 // 8.5 inches at 72 DPI
        let pageHeight: CGFloat = 792 // 11 inches at 72 DPI
        let margin: CGFloat = 50

        var currentPage = 0
        var yPosition: CGFloat = margin

        // Helper function to add a new page
        func addPage() -> PDFPage? {
            let page = PDFPage()
            pdfDocument.insert(page, at: currentPage)
            currentPage += 1
            yPosition = margin
            return page
        }

        // Helper function to check if we need a new page
        func checkPageBreak(requiredSpace: CGFloat) -> PDFPage? {
            if yPosition + requiredSpace > pageHeight - margin {
                return addPage()
            }
            return nil
        }

        // Page 1: Title and Summary
        reportProgress(0.4, "Generating title page...")

        guard var page = addPage() else {
            throw ExportError.encodingFailed("Failed to create PDF page")
        }

        // Title
        let titleFont = NSFont.boldSystemFont(ofSize: 28)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        let title = "StickyToDo Export Report"
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: margin, y: pageHeight - yPosition - titleSize.height, width: pageWidth - 2 * margin, height: titleSize.height)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        yPosition += titleSize.height + 10

        // Subtitle
        let subtitleFont = NSFont.systemFont(ofSize: 14)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: NSColor.darkGray
        ]
        let subtitle = "Generated on \(formatLongDate(Date()))"
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        let subtitleRect = CGRect(x: margin, y: pageHeight - yPosition - subtitleSize.height, width: pageWidth - 2 * margin, height: subtitleSize.height)
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        yPosition += subtitleSize.height + 40

        // Summary Statistics Box
        let statsBoxY = pageHeight - yPosition - 150
        let statsBox = CGRect(x: margin, y: statsBoxY, width: pageWidth - 2 * margin, height: 140)

        // Draw box background
        NSColor(calibratedRed: 0.95, green: 0.95, blue: 0.98, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: statsBox, xRadius: 8, yRadius: 8).fill()

        // Draw stats
        let statsFont = NSFont.systemFont(ofSize: 12)
        let statsLabelFont = NSFont.boldSystemFont(ofSize: 12)
        let statsY = statsBoxY + 100

        let stats = [
            ("Total Tasks:", "\(analytics.totalTasks)"),
            ("Completed:", "\(analytics.completedTasks)"),
            ("Active:", "\(analytics.activeTasks)"),
            ("Completion Rate:", analytics.completionRateString)
        ]

        for (index, (label, value)) in stats.enumerated() {
            let x = margin + 20 + CGFloat(index % 2) * 250
            let y = statsY - CGFloat(index / 2) * 30

            let labelAttrs: [NSAttributedString.Key: Any] = [.font: statsLabelFont, .foregroundColor: NSColor.darkGray]
            let valueAttrs: [NSAttributedString.Key: Any] = [.font: statsFont, .foregroundColor: NSColor.black]

            label.draw(at: CGPoint(x: x, y: y), withAttributes: labelAttrs)
            value.draw(at: CGPoint(x: x + 120, y: y), withAttributes: valueAttrs)
        }

        yPosition += 180

        // Task Distribution
        reportProgress(0.5, "Adding task distribution...")

        if let newPage = checkPageBreak(requiredSpace: 200) {
            page = newPage
        }

        let sectionFont = NSFont.boldSystemFont(ofSize: 18)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: NSColor.black
        ]

        let distributionTitle = "Task Distribution"
        let distTitleSize = distributionTitle.size(withAttributes: sectionAttributes)
        let distTitleRect = CGRect(x: margin, y: pageHeight - yPosition - distTitleSize.height, width: pageWidth - 2 * margin, height: distTitleSize.height)
        distributionTitle.draw(in: distTitleRect, withAttributes: sectionAttributes)
        yPosition += distTitleSize.height + 20

        // By Status
        let subsectionFont = NSFont.boldSystemFont(ofSize: 14)
        let subsectionAttributes: [NSAttributedString.Key: Any] = [
            .font: subsectionFont,
            .foregroundColor: NSColor.darkGray
        ]

        let statusTitle = "By Status:"
        let statusTitleSize = statusTitle.size(withAttributes: subsectionAttributes)
        let statusTitleRect = CGRect(x: margin, y: pageHeight - yPosition - statusTitleSize.height, width: pageWidth - 2 * margin, height: statusTitleSize.height)
        statusTitle.draw(in: statusTitleRect, withAttributes: subsectionAttributes)
        yPosition += statusTitleSize.height + 10

        let itemFont = NSFont.systemFont(ofSize: 12)
        let itemAttributes: [NSAttributedString.Key: Any] = [
            .font: itemFont,
            .foregroundColor: NSColor.black
        ]

        for status in Status.allCases {
            if let newPage = checkPageBreak(requiredSpace: 20) {
                page = newPage
            }

            let count = analytics.tasksByStatus[status] ?? 0
            let statusLine = "  • \(status.displayName): \(count)"
            let statusLineSize = statusLine.size(withAttributes: itemAttributes)
            let statusLineRect = CGRect(x: margin + 10, y: pageHeight - yPosition - statusLineSize.height, width: pageWidth - 2 * margin, height: statusLineSize.height)
            statusLine.draw(in: statusLineRect, withAttributes: itemAttributes)
            yPosition += statusLineSize.height + 5
        }

        yPosition += 15

        // By Priority
        if let newPage = checkPageBreak(requiredSpace: 100) {
            page = newPage
        }

        let priorityTitle = "By Priority:"
        let priorityTitleSize = priorityTitle.size(withAttributes: subsectionAttributes)
        let priorityTitleRect = CGRect(x: margin, y: pageHeight - yPosition - priorityTitleSize.height, width: pageWidth - 2 * margin, height: priorityTitleSize.height)
        priorityTitle.draw(in: priorityTitleRect, withAttributes: subsectionAttributes)
        yPosition += priorityTitleSize.height + 10

        for priority in Priority.allCases {
            if let newPage = checkPageBreak(requiredSpace: 20) {
                page = newPage
            }

            let count = analytics.tasksByPriority[priority] ?? 0
            let priorityLine = "  • \(priority.displayName): \(count)"
            let priorityLineSize = priorityLine.size(withAttributes: itemAttributes)
            let priorityLineRect = CGRect(x: margin + 10, y: pageHeight - yPosition - priorityLineSize.height, width: pageWidth - 2 * margin, height: priorityLineSize.height)
            priorityLine.draw(in: priorityLineRect, withAttributes: itemAttributes)
            yPosition += priorityLineSize.height + 5
        }

        yPosition += 30

        // Task Details
        reportProgress(0.6, "Adding task details...")

        // Start new page for tasks
        page = addPage() ?? page

        let tasksTitle = "Task Details"
        let tasksTitleSize = tasksTitle.size(withAttributes: sectionAttributes)
        let tasksTitleRect = CGRect(x: margin, y: pageHeight - yPosition - tasksTitleSize.height, width: pageWidth - 2 * margin, height: tasksTitleSize.height)
        tasksTitle.draw(in: tasksTitleRect, withAttributes: sectionAttributes)
        yPosition += tasksTitleSize.height + 20

        // Group tasks by project
        let grouped = Dictionary(grouping: tasks) { $0.project ?? "Inbox" }
        let sortedProjects = grouped.keys.sorted()

        let taskTitleFont = NSFont.boldSystemFont(ofSize: 11)
        let taskMetaFont = NSFont.systemFont(ofSize: 10)

        for (projectIndex, project) in sortedProjects.enumerated() {
            reportProgress(0.6 + (Double(projectIndex) / Double(sortedProjects.count)) * 0.3, "Adding tasks for \(project)...")

            if let newPage = checkPageBreak(requiredSpace: 40) {
                page = newPage
            }

            // Project header
            let projectHeader = "Project: \(project)"
            let projectHeaderSize = projectHeader.size(withAttributes: subsectionAttributes)
            let projectHeaderRect = CGRect(x: margin, y: pageHeight - yPosition - projectHeaderSize.height, width: pageWidth - 2 * margin, height: projectHeaderSize.height)
            projectHeader.draw(in: projectHeaderRect, withAttributes: subsectionAttributes)
            yPosition += projectHeaderSize.height + 10

            // Draw line
            let lineY = pageHeight - yPosition
            NSColor.lightGray.setStroke()
            let linePath = NSBezierPath()
            linePath.move(to: CGPoint(x: margin, y: lineY))
            linePath.line(to: CGPoint(x: pageWidth - margin, y: lineY))
            linePath.lineWidth = 0.5
            linePath.stroke()
            yPosition += 10

            // Tasks in project
            let projectTasks = grouped[project] ?? []
            let sortedTasks = projectTasks.sorted { $0.created > $1.created }

            for task in sortedTasks {
                let requiredSpace: CGFloat = task.notes.isEmpty ? 40 : 80
                if let newPage = checkPageBreak(requiredSpace: requiredSpace) {
                    page = newPage
                }

                // Task title with status indicator
                let statusIcon = task.status == .completed ? "✓" : "○"
                let taskTitle = "\(statusIcon) \(task.title)"
                let taskTitleAttrs: [NSAttributedString.Key: Any] = [
                    .font: taskTitleFont,
                    .foregroundColor: task.status == .completed ? NSColor.darkGray : NSColor.black
                ]

                let taskTitleSize = taskTitle.size(withAttributes: taskTitleAttrs)
                let taskTitleRect = CGRect(x: margin + 20, y: pageHeight - yPosition - taskTitleSize.height, width: pageWidth - 2 * margin - 40, height: taskTitleSize.height)
                taskTitle.draw(in: taskTitleRect, withAttributes: taskTitleAttrs)
                yPosition += taskTitleSize.height + 5

                // Metadata line
                var metadata: [String] = []
                metadata.append("Status: \(task.status.displayName)")
                metadata.append("Priority: \(task.priority.displayName)")

                if let context = task.context {
                    metadata.append("Context: \(context)")
                }

                if let due = task.due {
                    metadata.append("Due: \(formatShortDate(due))")
                }

                let metadataLine = metadata.joined(separator: " • ")
                let metadataAttrs: [NSAttributedString.Key: Any] = [
                    .font: taskMetaFont,
                    .foregroundColor: NSColor.gray
                ]

                let metadataSize = metadataLine.size(withAttributes: metadataAttrs)
                let metadataRect = CGRect(x: margin + 30, y: pageHeight - yPosition - metadataSize.height, width: pageWidth - 2 * margin - 50, height: metadataSize.height)
                metadataLine.draw(in: metadataRect, withAttributes: metadataAttrs)
                yPosition += metadataSize.height + 3

                // Notes (truncated if too long)
                if !task.notes.isEmpty {
                    let notesPreview = task.notes.prefix(200) + (task.notes.count > 200 ? "..." : "")
                    let notesAttrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: 9),
                        .foregroundColor: NSColor.darkGray
                    ]

                    let notesSize = String(notesPreview).size(withAttributes: notesAttrs)
                    let notesRect = CGRect(x: margin + 30, y: pageHeight - yPosition - notesSize.height, width: pageWidth - 2 * margin - 50, height: min(notesSize.height, 30))
                    String(notesPreview).draw(in: notesRect, withAttributes: notesAttrs)
                    yPosition += min(notesSize.height, 30) + 3
                }

                yPosition += 15 // Space between tasks
            }

            yPosition += 10 // Space between projects
        }

        reportProgress(0.95, "Writing PDF file...")

        // Write to file
        let pdfURL = url.pathExtension == "pdf" ? url : url.appendingPathExtension("pdf")
        pdfDocument.write(to: pdfURL)

        let attrs = try FileManager.default.attributesOfItem(atPath: pdfURL.path)
        let fileSize = attrs[.size] as? Int64 ?? 0

        return ExportResult(
            fileURL: pdfURL,
            format: .pdf,
            taskCount: tasks.count,
            fileSize: fileSize,
            warnings: ExportFormat.pdf.dataLossWarnings
        )
        #else
        // Fallback for platforms without PDFKit
        throw ExportError.encodingFailed("PDF export requires PDFKit which is not available on this platform")
        #endif
    }

    // MARK: - iCal Export

    /// Exports tasks as iCalendar format
    private func exportiCal(tasks: [Task], to url: URL, options: ExportOptions) async throws -> ExportResult {
        reportProgress(0.2, "Generating iCalendar file...")

        // Only export tasks with due dates
        let tasksWithDueDates = tasks.filter { $0.due != nil }

        var ical = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//StickyToDo//Export//EN
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        X-WR-CALNAME:StickyToDo Tasks
        X-WR-TIMEZONE:UTC
        X-WR-CALDESC:Tasks exported from StickyToDo

        """

        reportProgress(0.4, "Adding tasks...")

        for task in tasksWithDueDates {
            ical += renderTaskAsVTODO(task)
        }

        ical += "END:VCALENDAR\n"

        reportProgress(0.8, "Writing file...")

        let fileURL = url.pathExtension == "ics" ? url : url.appendingPathExtension("ics")
        try ical.write(to: fileURL, atomically: true, encoding: .utf8)

        let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attrs[.size] as? Int64 ?? 0

        var warnings = ExportFormat.ical.dataLossWarnings
        if tasksWithDueDates.count < tasks.count {
            warnings.append("\(tasks.count - tasksWithDueDates.count) task(s) without due dates were skipped")
        }

        return ExportResult(
            fileURL: fileURL,
            format: .ical,
            taskCount: tasksWithDueDates.count,
            fileSize: fileSize,
            warnings: warnings
        )
    }

    /// Renders a task as iCalendar VTODO component
    private func renderTaskAsVTODO(_ task: Task) -> String {
        guard let dueDate = task.due else { return "" }

        var vtodo = "BEGIN:VTODO\n"
        vtodo += "UID:\(task.id.uuidString)\n"
        vtodo += "DTSTAMP:\(formatICalDate(task.created))\n"
        vtodo += "SUMMARY:\(escapeICalText(task.title))\n"

        if !task.notes.isEmpty {
            vtodo += "DESCRIPTION:\(escapeICalText(task.notes))\n"
        }

        vtodo += "DUE:\(formatICalDate(dueDate))\n"
        vtodo += "CREATED:\(formatICalDate(task.created))\n"
        vtodo += "LAST-MODIFIED:\(formatICalDate(task.modified))\n"

        // Status mapping
        let status: String
        switch task.status {
        case .completed:
            status = "COMPLETED"
        case .nextAction:
            status = "IN-PROCESS"
        default:
            status = "NEEDS-ACTION"
        }
        vtodo += "STATUS:\(status)\n"

        // Priority mapping (iCal uses 1-9, where 1 is highest)
        let priority: Int
        switch task.priority {
        case .high:
            priority = 1
        case .medium:
            priority = 5
        case .low:
            priority = 9
        }
        vtodo += "PRIORITY:\(priority)\n"

        if let project = task.project {
            vtodo += "CATEGORIES:\(escapeICalText(project))\n"
        }

        if let context = task.context {
            vtodo += "LOCATION:\(escapeICalText(context))\n"
        }

        if task.status == .completed {
            vtodo += "COMPLETED:\(formatICalDate(task.modified))\n"
            vtodo += "PERCENT-COMPLETE:100\n"
        }

        vtodo += "END:VTODO\n"

        return vtodo
    }

    /// Formats a date in iCal format (YYYYMMDDTHHMMSSZ)
    private func formatICalDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    /// Escapes text for iCal format
    private func escapeICalText(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    /// Formats a date in long format for display
    private func formatLongDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Escapes HTML special characters
    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
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
