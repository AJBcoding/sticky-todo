//
//  ImportFormat.swift
//  StickyToDo
//
//  Defines all supported import formats and auto-detection.
//

import Foundation

/// Supported import formats for tasks and boards
///
/// The system can auto-detect format in many cases by examining file
/// extension and content structure.
public enum ImportFormat: String, CaseIterable {
    case nativeMarkdown = "native-markdown"
    case taskpaper = "taskpaper"
    case csv = "csv"
    case tsv = "tsv"
    case json = "json"
    case plainTextChecklist = "plain-text-checklist"
}

// MARK: - Format Properties

extension ImportFormat {
    /// File extensions associated with this format
    var fileExtensions: [String] {
        switch self {
        case .nativeMarkdown:
            return ["zip", "md"]
        case .taskpaper:
            return ["taskpaper", "txt"]
        case .csv:
            return ["csv"]
        case .tsv:
            return ["tsv", "tab"]
        case .json:
            return ["json"]
        case .plainTextChecklist:
            return ["txt", "md"]
        }
    }

    /// User-facing display name
    var displayName: String {
        switch self {
        case .nativeMarkdown:
            return "Native Markdown"
        case .taskpaper:
            return "TaskPaper"
        case .csv:
            return "CSV"
        case .tsv:
            return "TSV"
        case .json:
            return "JSON"
        case .plainTextChecklist:
            return "Plain Text Checklist"
        }
    }

    /// Detailed description
    var description: String {
        switch self {
        case .nativeMarkdown:
            return "Native StickyToDo markdown format with YAML frontmatter. Can be a ZIP archive or individual markdown files."
        case .taskpaper:
            return "TaskPaper format with @ tags for metadata. Tasks are text lines with @project, @context, @priority, @due, @done tags."
        case .csv:
            return "Comma-separated values with header row. Columns should include: Title, Status, Project, Context, Due, Priority, Notes."
        case .tsv:
            return "Tab-separated values with header row. Similar to CSV but uses tabs as delimiters."
        case .json:
            return "JSON format with array of task objects. Each task should have properties matching the Task model."
        case .plainTextChecklist:
            return "Simple markdown checklist format with - [ ] for incomplete and - [x] for completed tasks. Best-effort metadata extraction."
        }
    }

    /// Whether this format requires user configuration (column mapping, etc.)
    var requiresConfiguration: Bool {
        switch self {
        case .csv, .tsv:
            return true // May need column mapping
        case .nativeMarkdown, .taskpaper, .json, .plainTextChecklist:
            return false
        }
    }
}

// MARK: - Auto-Detection

extension ImportFormat {
    /// Attempts to auto-detect format from file extension and content
    /// - Parameters:
    ///   - url: File URL to examine
    ///   - content: Optional file content (if already loaded)
    /// - Returns: Detected format, or nil if unable to determine
    static func detect(from url: URL, content: String? = nil) -> ImportFormat? {
        let ext = url.pathExtension.lowercased()

        // Check by extension first
        if ext == "zip" {
            return .nativeMarkdown
        } else if ext == "taskpaper" {
            return .taskpaper
        } else if ext == "csv" {
            return .csv
        } else if ext == "tsv" || ext == "tab" {
            return .tsv
        } else if ext == "json" {
            return .json
        }

        // For .txt and .md, need to examine content
        if ext == "txt" || ext == "md" {
            if let text = content {
                return detectFromContent(text)
            }
        }

        return nil
    }

    /// Detects format by examining file content
    /// - Parameter content: File content to analyze
    /// - Returns: Detected format, or nil if unable to determine
    static func detectFromContent(_ content: String) -> ImportFormat? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for JSON
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            return .json
        }

        // Check for YAML frontmatter (native markdown)
        if trimmed.hasPrefix("---") {
            return .nativeMarkdown
        }

        // Check for TaskPaper format (lines with @ tags)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let tagPattern = try? NSRegularExpression(pattern: "@\\w+", options: [])
        var tagCount = 0
        for line in lines.prefix(20) {
            let range = NSRange(line.startIndex..., in: line)
            if let matches = tagPattern?.matches(in: line, options: [], range: range), !matches.isEmpty {
                tagCount += 1
            }
        }
        if tagCount > lines.count / 3 {
            return .taskpaper
        }

        // Check for CSV (look for commas in header)
        if let firstLine = lines.first, firstLine.contains(",") {
            let fields = firstLine.components(separatedBy: ",")
            if fields.count >= 3 {
                return .csv
            }
        }

        // Check for TSV (look for tabs in header)
        if let firstLine = lines.first, firstLine.contains("\t") {
            let fields = firstLine.components(separatedBy: "\t")
            if fields.count >= 3 {
                return .tsv
            }
        }

        // Check for plain text checklist
        let checklistPattern = try? NSRegularExpression(pattern: "^\\s*[-*]\\s*\\[([ xX])\\]", options: .anchorsMatchLines)
        var checklistCount = 0
        for line in lines.prefix(20) {
            let range = NSRange(line.startIndex..., in: line)
            if let matches = checklistPattern?.matches(in: line, options: [], range: range), !matches.isEmpty {
                checklistCount += 1
            }
        }
        if checklistCount > 0 {
            return .plainTextChecklist
        }

        return nil
    }
}

// MARK: - Import Options

/// Configuration options for import operations
public struct ImportOptions {
    /// The format to import from
    var format: ImportFormat

    /// Whether to auto-detect format if possible
    var autoDetect: Bool

    /// Default project for imported tasks (nil = Inbox)
    var defaultProject: String?

    /// Default context for imported tasks
    var defaultContext: String?

    /// Default status for imported tasks
    var defaultStatus: Status

    /// Whether to preserve original IDs (if present in import)
    var preserveIds: Bool

    /// Whether to create projects/boards from imported data
    var createProjects: Bool

    /// Whether to create context boards from imported data
    var createContexts: Bool

    /// Column mapping for CSV/TSV imports
    var columnMapping: [String: String]?

    /// Date format string for parsing dates in CSV/TSV
    var dateFormat: String?

    /// Whether to skip rows with errors (or fail on first error)
    var skipErrors: Bool

    /// Maximum number of tasks to import (nil = no limit)
    var maxTasks: Int?

    /// Creates default import options
    /// - Parameter format: Import format
    public init(format: ImportFormat) {
        self.format = format
        self.autoDetect = true
        self.defaultProject = nil
        self.defaultContext = nil
        self.defaultStatus = .inbox
        self.preserveIds = false
        self.createProjects = true
        self.createContexts = true
        self.columnMapping = nil
        self.dateFormat = "yyyy-MM-dd"
        self.skipErrors = true
        self.maxTasks = nil
    }

    /// Creates options with auto-detection enabled
    static var autoDetect: ImportOptions {
        var options = ImportOptions(format: .plainTextChecklist)
        options.autoDetect = true
        return options
    }

    /// Standard column names for CSV/TSV mapping
    static var standardColumnNames: [String: [String]] {
        return [
            "title": ["title", "task", "name", "subject", "summary"],
            "notes": ["notes", "description", "details", "body", "content"],
            "status": ["status", "state"],
            "project": ["project", "folder", "area"],
            "context": ["context", "tag", "tags", "location"],
            "due": ["due", "duedate", "due_date", "deadline"],
            "defer": ["defer", "start", "startdate", "start_date"],
            "priority": ["priority", "importance", "pri"],
            "effort": ["effort", "estimate", "duration", "time"],
            "flagged": ["flagged", "starred", "favorite", "important"],
            "completed": ["completed", "done", "finished"]
        ]
    }

    /// Attempts to auto-map columns based on standard names
    /// - Parameter headers: Column headers from CSV/TSV
    /// - Returns: Suggested column mapping
    static func autoMapColumns(_ headers: [String]) -> [String: String] {
        var mapping: [String: String] = [:]
        let normalizedHeaders = headers.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }

        for (field, variants) in standardColumnNames {
            for (index, header) in normalizedHeaders.enumerated() {
                if variants.contains(header) {
                    mapping[field] = headers[index]
                    break
                }
            }
        }

        return mapping
    }
}

// MARK: - Import Result

/// Result of an import operation
public struct ImportResult {
    /// Number of tasks successfully imported
    var importedCount: Int

    /// Number of boards created
    var boardsCreated: Int

    /// Tasks that were imported
    var tasks: [Task]

    /// Errors encountered during import
    var errors: [ImportError]

    /// Warnings generated during import
    var warnings: [String]

    /// Import timestamp
    var timestamp: Date

    /// Creates an import result
    public init(
        importedCount: Int = 0,
        boardsCreated: Int = 0,
        tasks: [Task] = [],
        errors: [ImportError] = [],
        warnings: [String] = [],
        timestamp: Date = Date()
    ) {
        self.importedCount = importedCount
        self.boardsCreated = boardsCreated
        self.tasks = tasks
        self.errors = errors
        self.warnings = warnings
        self.timestamp = timestamp
    }

    /// Whether the import was successful (no errors)
    var isSuccessful: Bool {
        return errors.isEmpty
    }

    /// Whether the import was partial (some errors but some success)
    var isPartialSuccess: Bool {
        return importedCount > 0 && !errors.isEmpty
    }

    /// Human-readable summary
    var summary: String {
        if isSuccessful {
            var parts: [String] = []
            parts.append("Successfully imported \(importedCount) task\(importedCount == 1 ? "" : "s")")
            if boardsCreated > 0 {
                parts.append("created \(boardsCreated) board\(boardsCreated == 1 ? "" : "s")")
            }
            return parts.joined(separator: ", ")
        } else if isPartialSuccess {
            return "Imported \(importedCount) task\(importedCount == 1 ? "" : "s") with \(errors.count) error\(errors.count == 1 ? "" : "s")"
        } else {
            return "Import failed with \(errors.count) error\(errors.count == 1 ? "" : "s")"
        }
    }
}

// MARK: - Import Error

/// Error types for import operations
public enum ImportError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case invalidFormat(String)
    case unableToDetectFormat
    case corruptedData(String)
    case missingRequiredField(field: String, row: Int?)
    case invalidDate(value: String, field: String, row: Int?)
    case invalidEnum(value: String, field: String, row: Int?)
    case parsingError(line: Int, message: String)
    case zipExtractionFailed(String)
    case unsupportedVersion(String)
    case columnMappingRequired([String])
    case duplicateId(UUID)
    case ioError(String)

    var description: String {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .unableToDetectFormat:
            return "Unable to detect file format. Please specify format explicitly."
        case .corruptedData(let message):
            return "Corrupted data: \(message)"
        case .missingRequiredField(let field, let row):
            if let row = row {
                return "Missing required field '\(field)' at row \(row)"
            } else {
                return "Missing required field '\(field)'"
            }
        case .invalidDate(let value, let field, let row):
            if let row = row {
                return "Invalid date '\(value)' for field '\(field)' at row \(row)"
            } else {
                return "Invalid date '\(value)' for field '\(field)'"
            }
        case .invalidEnum(let value, let field, let row):
            if let row = row {
                return "Invalid value '\(value)' for field '\(field)' at row \(row)"
            } else {
                return "Invalid value '\(value)' for field '\(field)'"
            }
        case .parsingError(let line, let message):
            return "Parsing error at line \(line): \(message)"
        case .zipExtractionFailed(let message):
            return "Failed to extract ZIP archive: \(message)"
        case .unsupportedVersion(let version):
            return "Unsupported format version: \(version)"
        case .columnMappingRequired(let headers):
            return "Column mapping required. Found headers: \(headers.joined(separator: ", "))"
        case .duplicateId(let id):
            return "Duplicate task ID: \(id.uuidString)"
        case .ioError(let message):
            return "I/O error: \(message)"
        }
    }
}

// MARK: - Import Preview

/// Preview of data to be imported (for user confirmation)
public struct ImportPreview {
    /// Format detected or specified
    var format: ImportFormat

    /// Estimated number of tasks to import
    var taskCount: Int

    /// Sample tasks (first few)
    var sampleTasks: [Task]

    /// Projects that will be created
    var projects: [String]

    /// Contexts that will be created
    var contexts: [String]

    /// Warnings about the import
    var warnings: [String]

    /// Column mapping preview (for CSV/TSV)
    var columnMapping: [String: String]?

    /// Creates a preview
    public init(
        format: ImportFormat,
        taskCount: Int,
        sampleTasks: [Task] = [],
        projects: [String] = [],
        contexts: [String] = [],
        warnings: [String] = [],
        columnMapping: [String: String]? = nil
    ) {
        self.format = format
        self.taskCount = taskCount
        self.sampleTasks = sampleTasks
        self.projects = projects
        self.contexts = contexts
        self.warnings = warnings
        self.columnMapping = columnMapping
    }

    /// Human-readable summary
    var summary: String {
        var parts: [String] = []
        parts.append("\(taskCount) task\(taskCount == 1 ? "" : "s") in \(format.displayName) format")

        if !projects.isEmpty {
            parts.append("\(projects.count) project\(projects.count == 1 ? "" : "s")")
        }

        if !contexts.isEmpty {
            parts.append("\(contexts.count) context\(contexts.count == 1 ? "" : "s")")
        }

        return "Will import " + parts.joined(separator: ", ")
    }
}
