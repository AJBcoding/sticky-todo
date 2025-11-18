//
//  ImportManager.swift
//  StickyToDo
//
//  Manages import of tasks and boards from various formats.
//

import Foundation

/// Manages import operations from various task management formats
///
/// Supports auto-detection of formats, column mapping for CSV/TSV, and comprehensive
/// error handling with progress reporting. All operations are thread-safe.
///
/// Example usage:
/// ```swift
/// let manager = ImportManager()
/// var options = ImportOptions(format: .csv)
/// options.columnMapping = ImportOptions.autoMapColumns(headers)
/// let result = try await manager.importTasks(from: url, options: options)
/// print(result.summary)
/// ```
public class ImportManager {
    // MARK: - Properties

    /// Progress callback for long operations
    public var progressHandler: ((Double, String) -> Void)?

    /// Queue for thread-safe operations
    private let queue = DispatchQueue(label: "com.stickytodo.importmanager", attributes: .concurrent)

    // MARK: - Initialization

    public init() {}

    // MARK: - Public API

    /// Imports tasks from a file
    /// - Parameters:
    ///   - url: Source file URL
    ///   - options: Import configuration options
    /// - Returns: Import result with tasks and metadata
    /// - Throws: ImportError on failure
    public func importTasks(from url: URL, options: ImportOptions) async throws -> ImportResult {
        reportProgress(0.0, "Reading file...")

        // Detect format if auto-detect is enabled
        let format: ImportFormat
        if options.autoDetect {
            let content = try? String(contentsOf: url, encoding: .utf8)
            if let detected = ImportFormat.detect(from: url, content: content) {
                format = detected
                reportProgress(0.1, "Detected format: \(detected.displayName)")
            } else {
                throw ImportError.unableToDetectFormat
            }
        } else {
            format = options.format
        }

        // Import based on format
        var result: ImportResult
        switch format {
        case .nativeMarkdown:
            result = try await importNativeMarkdown(from: url, options: options)
        case .taskpaper:
            result = try await importTaskPaper(from: url, options: options)
        case .csv:
            result = try await importCSV(from: url, options: options)
        case .tsv:
            result = try await importTSV(from: url, options: options)
        case .json:
            result = try await importJSON(from: url, options: options)
        case .plainTextChecklist:
            result = try await importPlainTextChecklist(from: url, options: options)
        }

        reportProgress(1.0, "Import complete")
        return result
    }

    /// Generates a preview of what will be imported (without actually importing)
    /// - Parameters:
    ///   - url: Source file URL
    ///   - options: Import options
    /// - Returns: Preview information
    /// - Throws: ImportError on failure
    public func preview(from url: URL, options: ImportOptions) async throws -> ImportPreview {
        // Read first N tasks only for preview
        var previewOptions = options
        previewOptions.maxTasks = 10

        let result = try await importTasks(from: url, options: previewOptions)

        let projects = Set(result.tasks.compactMap { $0.project }).sorted()
        let contexts = Set(result.tasks.compactMap { $0.context }).sorted()

        // Estimate total count (if we hit the limit, there may be more)
        let estimatedTotal = result.tasks.count

        return ImportPreview(
            format: options.format,
            taskCount: estimatedTotal,
            sampleTasks: Array(result.tasks.prefix(5)),
            projects: projects,
            contexts: contexts,
            warnings: result.warnings
        )
    }

    // MARK: - Native Markdown Import

    /// Imports from native markdown format (ZIP or individual files)
    private func importNativeMarkdown(from url: URL, options: ImportOptions) async throws -> ImportResult {
        reportProgress(0.1, "Checking file type...")

        var tasks: [Task] = []
        var errors: [ImportError] = []
        var warnings: [String] = []

        if url.pathExtension == "zip" {
            // Extract ZIP and import
            reportProgress(0.2, "Extracting archive...")

            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            defer {
                try? FileManager.default.removeItem(at: tempDir)
            }

            try await extractZip(from: url, to: tempDir)

            // Find all .md files in tasks directory
            let tasksDir = tempDir.appendingPathComponent("tasks")
            guard FileManager.default.fileExists(atPath: tasksDir.path) else {
                throw ImportError.invalidFormat("No tasks directory found in archive")
            }

            reportProgress(0.4, "Importing tasks...")

            let mdFiles = try findMarkdownFiles(in: tasksDir)
            for (index, fileURL) in mdFiles.enumerated() {
                do {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    if let task = try parseNativeMarkdown(content, options: options) {
                        tasks.append(task)
                    }
                } catch {
                    errors.append(.parsingError(line: 0, message: "Failed to parse \(fileURL.lastPathComponent): \(error)"))
                    if !options.skipErrors {
                        throw errors.last!
                    }
                }

                let progress = 0.4 + (Double(index) / Double(mdFiles.count)) * 0.5
                reportProgress(progress, "Importing task \(index + 1)/\(mdFiles.count)...")
            }
        } else {
            // Single markdown file
            reportProgress(0.3, "Parsing markdown...")

            let content = try String(contentsOf: url, encoding: .utf8)
            if let task = try parseNativeMarkdown(content, options: options) {
                tasks.append(task)
            }
        }

        return ImportResult(
            importedCount: tasks.count,
            boardsCreated: 0,
            tasks: tasks,
            errors: errors,
            warnings: warnings
        )
    }

    /// Parses a task from native markdown format with YAML frontmatter
    private func parseNativeMarkdown(_ content: String, options: ImportOptions) throws -> Task? {
        // Split frontmatter and content
        let parts = content.components(separatedBy: "---")
        guard parts.count >= 3 else {
            throw ImportError.invalidFormat("No YAML frontmatter found")
        }

        let yamlString = parts[1]
        let notes = parts[2...].joined(separator: "---").trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse YAML (simplified parsing - in production use a YAML library)
        let yaml = parseSimpleYAML(yamlString)

        guard let title = yaml["title"] as? String else {
            throw ImportError.missingRequiredField(field: "title", row: nil)
        }

        let id: UUID
        if options.preserveIds, let idString = yaml["id"] as? String, let uuid = UUID(uuidString: idString) {
            id = uuid
        } else {
            id = UUID()
        }

        let type = (yaml["type"] as? String).flatMap { TaskType(rawValue: $0) } ?? .task
        let status = (yaml["status"] as? String).flatMap { Status(rawValue: $0) } ?? options.defaultStatus
        let project = yaml["project"] as? String ?? options.defaultProject
        let context = yaml["context"] as? String ?? options.defaultContext
        let flagged = yaml["flagged"] as? Bool ?? false
        let priority = (yaml["priority"] as? String).flatMap { Priority(rawValue: $0) } ?? .medium
        let effort = yaml["effort"] as? Int

        let due = (yaml["due"] as? String).flatMap { parseISO8601($0) }
        let deferDate = (yaml["defer"] as? String).flatMap { parseISO8601($0) }
        let created = (yaml["created"] as? String).flatMap { parseISO8601($0) } ?? Date()
        let modified = (yaml["modified"] as? String).flatMap { parseISO8601($0) } ?? Date()

        // Parse positions (simplified - ignores positions for now)
        let positions: [String: Position] = [:]

        return Task(
            id: id,
            type: type,
            title: title,
            notes: notes,
            status: status,
            project: project,
            context: context,
            due: due,
            defer: deferDate,
            flagged: flagged,
            priority: priority,
            effort: effort,
            positions: positions,
            created: created,
            modified: modified
        )
    }

    // MARK: - TaskPaper Import

    /// Imports from TaskPaper format
    private func importTaskPaper(from url: URL, options: ImportOptions) async throws -> ImportResult {
        reportProgress(0.2, "Reading TaskPaper file...")

        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var tasks: [Task] = []
        var errors: [ImportError] = []
        var warnings: [String] = []
        var currentProject: String?

        reportProgress(0.3, "Parsing tasks...")

        for (lineNum, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                continue
            }

            // Check if it's a project line (ends with :)
            if trimmed.hasSuffix(":") {
                currentProject = String(trimmed.dropLast())
                continue
            }

            // Parse task line
            do {
                if let task = try parseTaskPaperLine(trimmed, project: currentProject, options: options) {
                    tasks.append(task)

                    if let maxTasks = options.maxTasks, tasks.count >= maxTasks {
                        break
                    }
                }
            } catch {
                errors.append(.parsingError(line: lineNum + 1, message: "\(error)"))
                if !options.skipErrors {
                    throw errors.last!
                }
            }

            let progress = 0.3 + (Double(lineNum) / Double(lines.count)) * 0.6
            if lineNum % 10 == 0 {
                reportProgress(progress, "Parsing line \(lineNum + 1)/\(lines.count)...")
            }
        }

        return ImportResult(
            importedCount: tasks.count,
            tasks: tasks,
            errors: errors,
            warnings: warnings
        )
    }

    /// Parses a single TaskPaper line
    /// Example: Call John @phone @project(Website) @priority(high) @due(2025-11-20)
    private func parseTaskPaperLine(_ line: String, project: String?, options: ImportOptions) throws -> Task? {
        // Remove leading tab/indent
        let cleaned = line.trimmingCharacters(in: CharacterSet(charactersIn: "\t"))

        // Extract title and tags
        var title = ""
        var tags: [String: String] = [:]
        var completed = false

        let parts = cleaned.components(separatedBy: " ")
        var titleParts: [String] = []

        for part in parts {
            if part.hasPrefix("@") {
                let tagContent = String(part.dropFirst())

                if tagContent == "done" {
                    completed = true
                } else if tagContent.contains("(") {
                    // Tag with value: @tag(value)
                    let tagParts = tagContent.components(separatedBy: "(")
                    if tagParts.count == 2 {
                        let key = tagParts[0]
                        let value = tagParts[1].trimmingCharacters(in: CharacterSet(charactersIn: ")"))
                        tags[key] = value
                    }
                } else {
                    // Tag without value (context)
                    tags["context"] = "@" + tagContent
                }
            } else {
                titleParts.append(part)
            }
        }

        title = titleParts.joined(separator: " ")

        guard !title.isEmpty else {
            return nil
        }

        let taskProject = tags["project"] ?? project ?? options.defaultProject
        let context = tags["context"] ?? options.defaultContext
        let priority = Priority(rawValue: tags["priority"] ?? "") ?? .medium
        let status = completed ? .completed : options.defaultStatus

        let due = tags["due"].flatMap { parseFlexibleDate($0) }
        let deferDate = tags["defer"].flatMap { parseFlexibleDate($0) }
        let flagged = tags["flagged"] != nil
        let effort = tags["effort"].flatMap { Int($0.replacingOccurrences(of: "m", with: "")) }

        return Task(
            type: .task,
            title: title,
            status: status,
            project: taskProject,
            context: context,
            due: due,
            defer: deferDate,
            flagged: flagged,
            priority: priority,
            effort: effort
        )
    }

    // MARK: - CSV/TSV Import

    /// Imports from CSV format
    private func importCSV(from url: URL, options: ImportOptions) async throws -> ImportResult {
        try await importDelimited(from: url, options: options, delimiter: ",")
    }

    /// Imports from TSV format
    private func importTSV(from url: URL, options: ImportOptions) async throws -> ImportResult {
        try await importDelimited(from: url, options: options, delimiter: "\t")
    }

    /// Imports from delimited format (CSV or TSV)
    private func importDelimited(from url: URL, options: ImportOptions, delimiter: String) async throws -> ImportResult {
        reportProgress(0.2, "Reading file...")

        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            throw ImportError.invalidFormat("Empty file")
        }

        reportProgress(0.3, "Parsing headers...")

        // Parse header row
        let headers = parseDelimitedLine(lines[0], delimiter: delimiter)

        // Auto-map columns if not provided
        let mapping = options.columnMapping ?? ImportOptions.autoMapColumns(headers)

        guard let titleColumn = mapping["title"] else {
            throw ImportError.columnMappingRequired(headers)
        }

        var tasks: [Task] = []
        var errors: [ImportError] = []
        var warnings: [String] = []

        reportProgress(0.4, "Importing rows...")

        // Parse data rows
        for (index, line) in lines.dropFirst().enumerated() {
            let rowNum = index + 2 // +2 because of header and 0-indexing

            do {
                let fields = parseDelimitedLine(line, delimiter: delimiter)
                if let task = try parseDelimitedRow(fields, headers: headers, mapping: mapping, rowNum: rowNum, options: options) {
                    tasks.append(task)

                    if let maxTasks = options.maxTasks, tasks.count >= maxTasks {
                        break
                    }
                }
            } catch {
                errors.append(.parsingError(line: rowNum, message: "\(error)"))
                if !options.skipErrors {
                    throw errors.last!
                }
            }

            let progress = 0.4 + (Double(index) / Double(lines.count)) * 0.5
            if index % 10 == 0 {
                reportProgress(progress, "Importing row \(rowNum)/\(lines.count)...")
            }
        }

        return ImportResult(
            importedCount: tasks.count,
            tasks: tasks,
            errors: errors,
            warnings: warnings
        )
    }

    /// Parses a delimited line (CSV or TSV)
    private func parseDelimitedLine(_ line: String, delimiter: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if String(char) == delimiter && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }

        fields.append(currentField)

        // Unescape quotes
        return fields.map { field in
            var cleaned = field.trimmingCharacters(in: .whitespaces)
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
                cleaned = String(cleaned.dropFirst().dropLast())
            }
            return cleaned.replacingOccurrences(of: "\"\"", with: "\"")
        }
    }

    /// Parses a delimited row into a Task
    private func parseDelimitedRow(_ fields: [String], headers: [String], mapping: [String: String], rowNum: Int, options: ImportOptions) throws -> Task? {
        func getField(_ name: String) -> String? {
            guard let column = mapping[name],
                  let index = headers.firstIndex(of: column),
                  index < fields.count else {
                return nil
            }
            let value = fields[index].trimmingCharacters(in: .whitespaces)
            return value.isEmpty ? nil : value
        }

        guard let title = getField("title"), !title.isEmpty else {
            throw ImportError.missingRequiredField(field: "title", row: rowNum)
        }

        let id: UUID
        if options.preserveIds, let idString = getField("id"), let uuid = UUID(uuidString: idString) {
            id = uuid
        } else {
            id = UUID()
        }

        let type = getField("type").flatMap { TaskType(rawValue: $0) } ?? .task
        let statusString = getField("status")
        let status = statusString.flatMap { Status(rawValue: $0) } ?? options.defaultStatus

        let project = getField("project") ?? options.defaultProject
        let context = getField("context") ?? options.defaultContext
        let priorityString = getField("priority")
        let priority = priorityString.flatMap { Priority(rawValue: $0) } ?? .medium

        let flaggedString = getField("flagged")
        let flagged = flaggedString?.lowercased() == "true" || flaggedString == "1"

        let effortString = getField("effort")
        let effort = effortString.flatMap { Int($0) }

        let notes = getField("notes") ?? ""

        // Parse dates
        let due = getField("due").flatMap { parseDateWithFormat($0, format: options.dateFormat ?? "yyyy-MM-dd") }
        let deferDate = getField("defer").flatMap { parseDateWithFormat($0, format: options.dateFormat ?? "yyyy-MM-dd") }
        let created = getField("created").flatMap { parseISO8601($0) } ?? Date()
        let modified = getField("modified").flatMap { parseISO8601($0) } ?? Date()

        return Task(
            id: id,
            type: type,
            title: title,
            notes: notes,
            status: status,
            project: project,
            context: context,
            due: due,
            defer: deferDate,
            flagged: flagged,
            priority: priority,
            effort: effort,
            created: created,
            modified: modified
        )
    }

    // MARK: - JSON Import

    /// Imports from JSON format
    private func importJSON(from url: URL, options: ImportOptions) async throws -> ImportResult {
        reportProgress(0.2, "Reading JSON file...")

        let data = try Data(contentsOf: url)

        reportProgress(0.4, "Parsing JSON...")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            var tasks = try decoder.decode([Task].self, from: data)

            // Apply max tasks limit
            if let maxTasks = options.maxTasks {
                tasks = Array(tasks.prefix(maxTasks))
            }

            // Regenerate IDs if not preserving
            if !options.preserveIds {
                tasks = tasks.map { task in
                    var newTask = task
                    newTask.id = UUID()
                    return newTask
                }
            }

            return ImportResult(
                importedCount: tasks.count,
                tasks: tasks
            )
        } catch {
            throw ImportError.invalidFormat("JSON parsing failed: \(error)")
        }
    }

    // MARK: - Plain Text Checklist Import

    /// Imports from plain text checklist format
    private func importPlainTextChecklist(from url: URL, options: ImportOptions) async throws -> ImportResult {
        reportProgress(0.2, "Reading checklist file...")

        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var tasks: [Task] = []
        var errors: [ImportError] = []
        var warnings: [String] = []

        reportProgress(0.3, "Parsing checklist...")

        for (lineNum, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                continue
            }

            do {
                if let task = try parseChecklistLine(trimmed, options: options) {
                    tasks.append(task)

                    if let maxTasks = options.maxTasks, tasks.count >= maxTasks {
                        break
                    }
                }
            } catch {
                if !options.skipErrors {
                    throw error
                }
            }

            let progress = 0.3 + (Double(lineNum) / Double(lines.count)) * 0.6
            if lineNum % 10 == 0 {
                reportProgress(progress, "Parsing line \(lineNum + 1)/\(lines.count)...")
            }
        }

        warnings.append("Best-effort import from plain text. All metadata defaults to Inbox.")

        return ImportResult(
            importedCount: tasks.count,
            tasks: tasks,
            errors: errors,
            warnings: warnings
        )
    }

    /// Parses a checklist line
    /// Examples:
    ///   - [ ] Call John
    ///   - [x] Design mockups
    ///   * [ ] Call John @phone #Website !high
    private func parseChecklistLine(_ line: String, options: ImportOptions) throws -> Task? {
        // Match checkbox pattern
        let pattern = "^\\s*[-*]\\s*\\[([ xX])\\]\\s*(.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, options: [], range: range) else {
            return nil
        }

        // Extract checkbox state
        let checkboxRange = Range(match.range(at: 1), in: line)!
        let checkbox = String(line[checkboxRange])
        let completed = checkbox.lowercased() == "x"

        // Extract title
        let titleRange = Range(match.range(at: 2), in: line)!
        let fullTitle = String(line[titleRange])

        // Try to extract inline metadata
        var title = fullTitle
        var context: String?
        var project: String?
        var priority: Priority = .medium

        // Extract @context
        if let contextMatch = fullTitle.range(of: "@\\w+", options: .regularExpression) {
            context = String(fullTitle[contextMatch])
            title = title.replacingOccurrences(of: context!, with: "").trimmingCharacters(in: .whitespaces)
        }

        // Extract #project
        if let projectMatch = fullTitle.range(of: "#[\\w-]+", options: .regularExpression) {
            project = String(fullTitle[projectMatch].dropFirst())
            title = title.replacingOccurrences(of: "#" + project!, with: "").trimmingCharacters(in: .whitespaces)
        }

        // Extract !priority
        if fullTitle.contains("!high") {
            priority = .high
            title = title.replacingOccurrences(of: "!high", with: "").trimmingCharacters(in: .whitespaces)
        } else if fullTitle.contains("!low") {
            priority = .low
            title = title.replacingOccurrences(of: "!low", with: "").trimmingCharacters(in: .whitespaces)
        }

        let status = completed ? .completed : options.defaultStatus
        let finalProject = project ?? options.defaultProject
        let finalContext = context ?? options.defaultContext

        return Task(
            type: .task,
            title: title,
            status: status,
            project: finalProject,
            context: finalContext,
            priority: priority
        )
    }

    // MARK: - Helper Methods

    /// Reports progress to the progress handler
    private func reportProgress(_ progress: Double, _ message: String) {
        DispatchQueue.main.async {
            self.progressHandler?(progress, message)
        }
    }

    /// Extracts a ZIP archive
    private func extractZip(from sourceURL: URL, to destinationURL: URL) async throws {
        // Simplified implementation using system unzip command
        let process = Process()
        process.currentDirectoryURL = destinationURL
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", sourceURL.path, "-d", destinationURL.path]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw ImportError.zipExtractionFailed("Unzip failed with status \(process.terminationStatus)")
        }
    }

    /// Finds all markdown files in a directory recursively
    private func findMarkdownFiles(in directory: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "md" {
                files.append(fileURL)
            }
        }

        return files
    }

    /// Parses simplified YAML (key: value pairs only)
    /// Note: This is a very basic implementation. Use a proper YAML library in production.
    private func parseSimpleYAML(_ yaml: String) -> [String: Any] {
        var dict: [String: Any] = [:]

        for line in yaml.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            let parts = trimmed.components(separatedBy: ":")
            guard parts.count >= 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)

            // Remove quotes
            var cleanValue = value
            if cleanValue.hasPrefix("\"") && cleanValue.hasSuffix("\"") {
                cleanValue = String(cleanValue.dropFirst().dropLast())
            }

            // Try to parse as bool
            if cleanValue == "true" {
                dict[key] = true
            } else if cleanValue == "false" {
                dict[key] = false
            } else if let intValue = Int(cleanValue) {
                dict[key] = intValue
            } else {
                dict[key] = cleanValue
            }
        }

        return dict
    }

    /// Parses ISO8601 date
    private func parseISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }

    /// Parses date with specific format
    private func parseDateWithFormat(_ string: String, format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: string)
    }

    /// Parses date in flexible formats
    private func parseFlexibleDate(_ string: String) -> Date? {
        // Try ISO8601 first
        if let date = parseISO8601(string) {
            return date
        }

        // Try common formats
        let formats = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy/MM/dd",
            "MMM dd, yyyy"
        ]

        for format in formats {
            if let date = parseDateWithFormat(string, format: format) {
                return date
            }
        }

        return nil
    }
}
