//
//  ExportFormat.swift
//  StickyToDo
//
//  Defines all supported export formats and their properties.
//

import Foundation

/// Supported export formats for tasks and boards
///
/// Each format provides different levels of fidelity and compatibility:
/// - Native Markdown Archive: Full fidelity backup of entire project
/// - Simplified Markdown: Human-readable markdown with inline metadata
/// - TaskPaper: Compatible with TaskPaper app using tag syntax
/// - CSV: Spreadsheet format with metadata columns
/// - TSV: Tab-separated values, better for data with commas
/// - JSON: Structured export for programmatic access
enum ExportFormat: String, CaseIterable {
    case nativeMarkdownArchive = "native-archive"
    case simplifiedMarkdown = "simplified-markdown"
    case taskpaper = "taskpaper"
    case csv = "csv"
    case tsv = "tsv"
    case json = "json"
}

// MARK: - Format Properties

extension ExportFormat {
    /// File extension for this format (without the dot)
    var fileExtension: String {
        switch self {
        case .nativeMarkdownArchive:
            return "zip"
        case .simplifiedMarkdown:
            return "md"
        case .taskpaper:
            return "taskpaper"
        case .csv:
            return "csv"
        case .tsv:
            return "tsv"
        case .json:
            return "json"
        }
    }

    /// MIME type for this format
    var mimeType: String {
        switch self {
        case .nativeMarkdownArchive:
            return "application/zip"
        case .simplifiedMarkdown:
            return "text/markdown"
        case .taskpaper:
            return "text/plain"
        case .csv:
            return "text/csv"
        case .tsv:
            return "text/tab-separated-values"
        case .json:
            return "application/json"
        }
    }

    /// User-facing display name
    var displayName: String {
        switch self {
        case .nativeMarkdownArchive:
            return "Native Markdown Archive (ZIP)"
        case .simplifiedMarkdown:
            return "Simplified Markdown"
        case .taskpaper:
            return "TaskPaper Format"
        case .csv:
            return "CSV (Comma-Separated Values)"
        case .tsv:
            return "TSV (Tab-Separated Values)"
        case .json:
            return "JSON"
        }
    }

    /// Detailed description of the format
    var description: String {
        switch self {
        case .nativeMarkdownArchive:
            return "Complete backup with full fidelity. Includes all tasks, boards, and configuration files in native markdown format with YAML frontmatter. Perfect for backup and restore."
        case .simplifiedMarkdown:
            return "Human-readable markdown files with tasks as checklist items. Metadata included inline (e.g., @context, #project, !priority). Easy to read and edit in any text editor."
        case .taskpaper:
            return "Compatible with TaskPaper app. Uses tag syntax (@context, @project, @priority). Preserves task hierarchy and metadata."
        case .csv:
            return "Spreadsheet format with metadata as columns. Easy to import into Excel, Numbers, or databases. Commas in text are properly escaped."
        case .tsv:
            return "Tab-separated values format. Similar to CSV but uses tabs instead of commas. Better for data containing many commas."
        case .json:
            return "Structured JSON format for programmatic access. Includes full task metadata with ISO8601 date formatting. Ideal for API integrations and data processing."
        }
    }

    /// Whether this format preserves all data with full fidelity
    var isLossless: Bool {
        switch self {
        case .nativeMarkdownArchive:
            return true
        case .simplifiedMarkdown, .taskpaper, .csv, .tsv, .json:
            return false
        }
    }

    /// Whether this format exports to a single file or multiple files
    var isSingleFile: Bool {
        switch self {
        case .nativeMarkdownArchive:
            return true // ZIP archive containing multiple files
        case .simplifiedMarkdown:
            return false // One file per project/board
        case .taskpaper, .csv, .tsv, .json:
            return true
        }
    }

    /// Data loss warnings for this format
    var dataLossWarnings: [String] {
        switch self {
        case .nativeMarkdownArchive:
            return []
        case .simplifiedMarkdown:
            return [
                "Board positions will be lost",
                "Board layout configurations will not be preserved",
                "Custom board settings will not be included"
            ]
        case .taskpaper:
            return [
                "Board positions will be lost",
                "Effort estimates may not be preserved",
                "Board configurations will not be included",
                "Defer dates use @defer tag (may not be standard)"
            ]
        case .csv, .tsv:
            return [
                "Board positions will be lost",
                "Multi-line notes may be escaped in a single cell",
                "Markdown formatting in notes will be preserved as plain text",
                "Board configurations will not be included"
            ]
        case .json:
            return [
                "Board configurations will not be included (tasks only)",
                "Custom positions are included but may need special handling"
            ]
        }
    }
}

// MARK: - Recommended Formats

extension ExportFormat {
    /// Recommended format for backup/restore
    static var backup: ExportFormat {
        return .nativeMarkdownArchive
    }

    /// Recommended format for sharing with others
    static var sharing: ExportFormat {
        return .simplifiedMarkdown
    }

    /// Recommended format for data analysis
    static var dataAnalysis: ExportFormat {
        return .csv
    }

    /// Recommended format for API/programmatic access
    static var programmatic: ExportFormat {
        return .json
    }
}

// MARK: - Export Options

/// Configuration options for export operations
struct ExportOptions {
    /// The format to export to
    var format: ExportFormat

    /// Whether to include completed tasks
    var includeCompleted: Bool

    /// Whether to include archived tasks
    var includeArchived: Bool

    /// Whether to include notes (or only tasks)
    var includeNotes: Bool

    /// Whether to include board configurations
    var includeBoards: Bool

    /// Filter to limit which tasks are exported (nil = all tasks)
    var filter: Filter?

    /// Base filename (without extension)
    var filename: String

    /// Date range for filtering tasks (by creation date)
    var dateRange: DateInterval?

    /// Projects to include (nil = all projects)
    var projects: [String]?

    /// Contexts to include (nil = all contexts)
    var contexts: [String]?

    /// Creates default export options
    /// - Parameters:
    ///   - format: Export format
    ///   - filename: Base filename
    init(format: ExportFormat, filename: String = "StickyToDo-Export") {
        self.format = format
        self.filename = filename
        self.includeCompleted = true
        self.includeArchived = false
        self.includeNotes = true
        self.includeBoards = true
        self.filter = nil
        self.dateRange = nil
        self.projects = nil
        self.contexts = nil
    }

    /// Creates backup export options (all data)
    static func backup(filename: String = "StickyToDo-Backup") -> ExportOptions {
        var options = ExportOptions(format: .nativeMarkdownArchive, filename: filename)
        options.includeCompleted = true
        options.includeArchived = true
        options.includeNotes = true
        options.includeBoards = true
        return options
    }

    /// Creates export options for active tasks only
    static func activeTasks(format: ExportFormat, filename: String = "Active-Tasks") -> ExportOptions {
        var options = ExportOptions(format: format, filename: filename)
        options.includeCompleted = false
        options.includeArchived = false
        options.includeNotes = false
        return options
    }
}

// MARK: - Export Result

/// Result of an export operation
struct ExportResult {
    /// The exported file URL
    var fileURL: URL

    /// The format that was exported
    var format: ExportFormat

    /// Number of tasks exported
    var taskCount: Int

    /// Number of boards exported (if applicable)
    var boardCount: Int

    /// File size in bytes
    var fileSize: Int64

    /// Export timestamp
    var timestamp: Date

    /// Any warnings generated during export
    var warnings: [String]

    /// Creates an export result
    init(
        fileURL: URL,
        format: ExportFormat,
        taskCount: Int,
        boardCount: Int = 0,
        fileSize: Int64 = 0,
        timestamp: Date = Date(),
        warnings: [String] = []
    ) {
        self.fileURL = fileURL
        self.format = format
        self.taskCount = taskCount
        self.boardCount = boardCount
        self.fileSize = fileSize
        self.timestamp = timestamp
        self.warnings = warnings
    }

    /// Human-readable summary of the export
    var summary: String {
        var parts: [String] = []
        parts.append("\(taskCount) task\(taskCount == 1 ? "" : "s")")

        if boardCount > 0 {
            parts.append("\(boardCount) board\(boardCount == 1 ? "" : "s")")
        }

        let sizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        parts.append("(\(sizeString))")

        return "Exported " + parts.joined(separator: ", ")
    }
}
