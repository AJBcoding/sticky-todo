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
/// - HTML: Web-viewable formatted reports
/// - PDF: Printable formatted reports (via HTML)
/// - iCal: Calendar format for calendar apps
/// - OmniFocus: Compatible with OmniFocus using TaskPaper-like format
/// - Things: Compatible with Things app using JSON format
public enum ExportFormat: String, CaseIterable {
    case nativeMarkdownArchive = "native-archive"
    case simplifiedMarkdown = "simplified-markdown"
    case taskpaper = "taskpaper"
    case omnifocus = "omnifocus"
    case things = "things"
    case csv = "csv"
    case tsv = "tsv"
    case json = "json"
    case html = "html"
    case pdf = "pdf"
    case ical = "ical"
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
        case .omnifocus:
            return "taskpaper"
        case .things:
            return "json"
        case .csv:
            return "csv"
        case .tsv:
            return "tsv"
        case .json:
            return "json"
        case .html:
            return "html"
        case .pdf:
            return "pdf"
        case .ical:
            return "ics"
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
        case .omnifocus:
            return "text/plain"
        case .things:
            return "application/json"
        case .csv:
            return "text/csv"
        case .tsv:
            return "text/tab-separated-values"
        case .json:
            return "application/json"
        case .html:
            return "text/html"
        case .pdf:
            return "application/pdf"
        case .ical:
            return "text/calendar"
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
        case .omnifocus:
            return "OmniFocus Format"
        case .things:
            return "Things Format"
        case .csv:
            return "CSV (Comma-Separated Values)"
        case .tsv:
            return "TSV (Tab-Separated Values)"
        case .json:
            return "JSON"
        case .html:
            return "HTML (Web Report)"
        case .pdf:
            return "PDF (Formatted Report)"
        case .ical:
            return "iCal (Calendar)"
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
        case .omnifocus:
            return "Compatible with OmniFocus app. Uses TaskPaper-like format with special tags for projects, contexts, due dates, and defer dates. Can be imported directly into OmniFocus."
        case .things:
            return "Compatible with Things app. Uses Things' JSON import format with support for projects, areas, tags, due dates, and notes. Can be imported using Things URL scheme."
        case .csv:
            return "Spreadsheet format with metadata as columns. Easy to import into Excel, Numbers, or databases. Commas in text are properly escaped."
        case .tsv:
            return "Tab-separated values format. Similar to CSV but uses tabs instead of commas. Better for data containing many commas."
        case .json:
            return "Structured JSON format for programmatic access. Includes full task metadata with ISO8601 date formatting. Ideal for API integrations and data processing."
        case .html:
            return "Formatted HTML report with styled tables and charts. Can be viewed in any web browser. Includes task lists grouped by project and status with full metadata."
        case .pdf:
            return "Printable PDF report generated from HTML. Professional formatting with tables and statistics. Ideal for sharing or archiving. Requires HTML rendering."
        case .ical:
            return "iCalendar format compatible with Calendar, Google Calendar, Outlook, and other calendar applications. Exports tasks as calendar events using due dates."
        }
    }

    /// Whether this format preserves all data with full fidelity
    var isLossless: Bool {
        switch self {
        case .nativeMarkdownArchive:
            return true
        case .simplifiedMarkdown, .taskpaper, .omnifocus, .things, .csv, .tsv, .json, .html, .pdf, .ical:
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
        case .taskpaper, .omnifocus, .things, .csv, .tsv, .json, .html, .pdf, .ical:
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
        case .omnifocus:
            return [
                "Board positions will be lost",
                "Some task metadata may not map perfectly to OmniFocus",
                "Time tracking data will be lost",
                "Subtasks may need manual organization in OmniFocus"
            ]
        case .things:
            return [
                "Board positions will be lost",
                "Some task metadata may not map perfectly to Things",
                "Time tracking data will be lost",
                "Effort estimates will be lost"
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
        case .html:
            return [
                "Board positions will be lost",
                "This is a read-only report format",
                "Cannot be imported back into StickyToDo",
                "Optimized for viewing, not data preservation"
            ]
        case .pdf:
            return [
                "Board positions will be lost",
                "This is a read-only report format",
                "Cannot be imported back into StickyToDo",
                "Data cannot be extracted or edited"
            ]
        case .ical:
            return [
                "Only tasks with due dates will be exported",
                "Task notes and many metadata fields will be lost",
                "Cannot be imported back into StickyToDo",
                "Optimized for calendar viewing only"
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

/// CSV column options for customizable export
public enum CSVColumn: String, CaseIterable, Codable {
    case id = "ID"
    case type = "Type"
    case title = "Title"
    case status = "Status"
    case project = "Project"
    case context = "Context"
    case due = "Due Date"
    case deferDate = "Defer Date"
    case flagged = "Flagged"
    case priority = "Priority"
    case effort = "Effort"
    case created = "Created"
    case modified = "Modified"
    case notes = "Notes"
    case tags = "Tags"
    case timeSpent = "Time Spent"
    case completionDate = "Completion Date"
}

/// Export template presets for common use cases
public enum ExportTemplate: String, CaseIterable {
    case fullBackup = "Full Backup"
    case activeTasksOnly = "Active Tasks Only"
    case completedThisWeek = "Completed This Week"
    case completedThisMonth = "Completed This Month"
    case overdueTasksOnly = "Overdue Tasks Only"
    case highPriorityOnly = "High Priority Only"
    case projectSummary = "Project Summary"
    case contextLists = "Context Lists"
    case customRange = "Custom Date Range"

    /// Creates export options for this template
    func createOptions(format: ExportFormat = .json) -> ExportOptions {
        var options = ExportOptions(format: format, filename: self.rawValue.replacingOccurrences(of: " ", with: "-"))

        switch self {
        case .fullBackup:
            options.includeCompleted = true
            options.includeArchived = true
            options.includeNotes = true
            options.includeBoards = true

        case .activeTasksOnly:
            options.includeCompleted = false
            options.includeArchived = false
            options.includeNotes = false

        case .completedThisWeek:
            let calendar = Calendar.current
            let now = Date()
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            options.dateRange = DateInterval(start: weekStart, end: weekEnd)
            options.includeCompleted = true
            options.includeArchived = false
            options.includeNotes = false

        case .completedThisMonth:
            let calendar = Calendar.current
            let now = Date()
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            options.dateRange = DateInterval(start: monthStart, end: monthEnd)
            options.includeCompleted = true
            options.includeArchived = false
            options.includeNotes = false

        case .overdueTasksOnly:
            options.includeCompleted = false
            options.filter = Filter(dueBefore: Date())

        case .highPriorityOnly:
            options.filter = Filter(priority: .high)
            options.includeCompleted = false

        case .projectSummary:
            options.includeNotes = false
            options.csvColumns = [.project, .title, .status, .priority, .due]

        case .contextLists:
            options.includeNotes = false
            options.csvColumns = [.context, .title, .status, .due]

        case .customRange:
            // User will customize
            break
        }

        return options
    }
}

/// Configuration options for export operations
public struct ExportOptions {
    /// The format to export to
    public var format: ExportFormat

    /// Whether to include completed tasks
    public var includeCompleted: Bool

    /// Whether to include archived tasks
    public var includeArchived: Bool

    /// Whether to include notes (or only tasks)
    public var includeNotes: Bool

    /// Whether to include board configurations
    public var includeBoards: Bool

    /// Filter to limit which tasks are exported (nil = all tasks)
    public var filter: Filter?

    /// Base filename (without extension)
    public var filename: String

    /// Date range for filtering tasks (by creation date)
    public var dateRange: DateInterval?

    /// Projects to include (nil = all projects)
    public var projects: [String]?

    /// Contexts to include (nil = all contexts)
    public var contexts: [String]?

    /// Custom CSV columns to include (nil = all columns)
    public var csvColumns: [CSVColumn]?

    /// Export template to use
    public var template: ExportTemplate?

    /// Creates default export options
    /// - Parameters:
    ///   - format: Export format
    ///   - filename: Base filename
    public init(format: ExportFormat, filename: String = "StickyToDo-Export") {
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
        self.csvColumns = nil
        self.template = nil
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
public struct ExportResult {
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
    public init(
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
