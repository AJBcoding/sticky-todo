//
//  FileConflict.swift
//  StickyToDoCore
//
//  Model representing a file conflict between in-memory and external versions.
//

import Foundation

/// Represents a file conflict that needs resolution
///
/// FileConflict is created when the FileWatcher detects that a file has been
/// modified externally while we also have unsaved changes in memory.
public struct FileConflict: Identifiable, Codable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this conflict
    public let id: UUID

    /// The file URL where the conflict occurred
    public let url: URL

    /// Our in-memory content (what we were about to save)
    public let localContent: String

    /// The external content (what's currently on disk)
    public let externalContent: String

    /// When our version was last modified
    public let localModificationDate: Date

    /// When the external version was last modified
    public let externalModificationDate: Date

    /// When this conflict was detected
    public let detectedAt: Date

    /// Optional metadata about what changed
    public let metadata: ConflictMetadata?

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        url: URL,
        localContent: String,
        externalContent: String,
        localModificationDate: Date,
        externalModificationDate: Date,
        detectedAt: Date = Date(),
        metadata: ConflictMetadata? = nil
    ) {
        self.id = id
        self.url = url
        self.localContent = localContent
        self.externalContent = externalContent
        self.localModificationDate = localModificationDate
        self.externalModificationDate = externalModificationDate
        self.detectedAt = detectedAt
        self.metadata = metadata
    }

    // MARK: - Computed Properties

    /// The filename without path
    public var fileName: String {
        url.lastPathComponent
    }

    /// The file extension
    public var fileExtension: String {
        url.pathExtension
    }

    /// Returns true if the contents are actually different
    public var hasActualConflict: Bool {
        localContent != externalContent
    }

    /// Returns true if the external version is newer
    public var isExternalNewer: Bool {
        externalModificationDate > localModificationDate
    }

    /// Returns the newer modification date
    public var newerModificationDate: Date {
        max(localModificationDate, externalModificationDate)
    }

    /// Returns the older modification date
    public var olderModificationDate: Date {
        min(localModificationDate, externalModificationDate)
    }

    /// Time interval between the two versions
    public var conflictAge: TimeInterval {
        externalModificationDate.timeIntervalSince(localModificationDate)
    }

    /// Human-readable description of the conflict
    public var description: String {
        """
        File Conflict: \(fileName)
        Local modified: \(localModificationDate)
        External modified: \(externalModificationDate)
        Detected: \(detectedAt)
        Has actual differences: \(hasActualConflict)
        """
    }

    // MARK: - Equatable

    public static func == (lhs: FileConflict, rhs: FileConflict) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Conflict Metadata

/// Additional metadata about a file conflict
public struct ConflictMetadata: Codable, Equatable {

    /// Type of file that conflicted
    public let fileType: FileType

    /// Whether this is a task, board, or config file
    public enum FileType: String, Codable {
        case task
        case board
        case perspective
        case template
        case config
        case unknown
    }

    /// List of specific fields that changed (if parseable)
    public let changedFields: [String]?

    /// Whether the conflict is in frontmatter only
    public let frontmatterOnly: Bool

    /// Whether the conflict is in body content only
    public let bodyOnly: Bool

    /// Estimated merge complexity (0.0 = easy, 1.0 = complex)
    public let mergeComplexity: Double

    public init(
        fileType: FileType,
        changedFields: [String]? = nil,
        frontmatterOnly: Bool = false,
        bodyOnly: Bool = false,
        mergeComplexity: Double = 0.5
    ) {
        self.fileType = fileType
        self.changedFields = changedFields
        self.frontmatterOnly = frontmatterOnly
        self.bodyOnly = bodyOnly
        self.mergeComplexity = mergeComplexity
    }
}

// MARK: - Conflict Analysis

extension FileConflict {

    /// Analyzes the conflict and generates metadata
    public func analyze() -> ConflictMetadata {
        // Determine file type
        let fileType: ConflictMetadata.FileType
        if url.path.contains("/tasks/") {
            fileType = .task
        } else if url.path.contains("/boards/") {
            fileType = .board
        } else if url.path.contains("/perspectives/") {
            fileType = .perspective
        } else if url.path.contains("/templates/") {
            fileType = .template
        } else if url.path.contains("/config/") {
            fileType = .config
        } else {
            fileType = .unknown
        }

        // Analyze content structure
        let localLines = localContent.components(separatedBy: .newlines)
        let externalLines = externalContent.components(separatedBy: .newlines)

        // Check for frontmatter
        let hasFrontmatter = localLines.first == "---" && externalLines.first == "---"

        var frontmatterOnly = false
        var bodyOnly = false
        var changedFields: [String]? = nil

        if hasFrontmatter {
            // Find frontmatter boundaries
            if let localEndIndex = localLines.dropFirst().firstIndex(of: "---"),
               let externalEndIndex = externalLines.dropFirst().firstIndex(of: "---") {

                let localFrontmatter = Array(localLines[1..<localEndIndex])
                let externalFrontmatter = Array(externalLines[1..<externalEndIndex])

                let localBody = Array(localLines[(localEndIndex + 1)...])
                let externalBody = Array(externalLines[(externalEndIndex + 1)...])

                frontmatterOnly = localFrontmatter != externalFrontmatter && localBody == externalBody
                bodyOnly = localFrontmatter == externalFrontmatter && localBody != externalBody

                // Extract changed fields
                if frontmatterOnly {
                    changedFields = extractChangedFields(
                        local: localFrontmatter,
                        external: externalFrontmatter
                    )
                }
            }
        }

        // Calculate merge complexity
        let complexity = calculateMergeComplexity(
            localLines: localLines,
            externalLines: externalLines
        )

        return ConflictMetadata(
            fileType: fileType,
            changedFields: changedFields,
            frontmatterOnly: frontmatterOnly,
            bodyOnly: bodyOnly,
            mergeComplexity: complexity
        )
    }

    /// Extracts the names of fields that changed in frontmatter
    private func extractChangedFields(local: [String], external: [String]) -> [String] {
        var localFields: [String: String] = [:]
        var externalFields: [String: String] = [:]

        // Parse local fields
        for line in local {
            if let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                localFields[key] = value
            }
        }

        // Parse external fields
        for line in external {
            if let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                externalFields[key] = value
            }
        }

        // Find differences
        var changed: [String] = []

        for (key, value) in localFields {
            if externalFields[key] != value {
                changed.append(key)
            }
        }

        for key in externalFields.keys {
            if localFields[key] == nil {
                changed.append(key)
            }
        }

        return changed.sorted()
    }

    /// Calculates how complex the merge will be (0.0 = trivial, 1.0 = very complex)
    private func calculateMergeComplexity(localLines: [String], externalLines: [String]) -> Double {
        let totalLines = max(localLines.count, externalLines.count)
        guard totalLines > 0 else { return 0.0 }

        var differences = 0

        for i in 0..<totalLines {
            let localLine = i < localLines.count ? localLines[i] : nil
            let externalLine = i < externalLines.count ? externalLines[i] : nil

            if localLine != externalLine {
                differences += 1
            }
        }

        let ratio = Double(differences) / Double(totalLines)

        // Scale to 0.0 - 1.0 range
        // 0% different = 0.0 complexity
        // 100% different = 1.0 complexity
        return min(ratio, 1.0)
    }
}

// MARK: - Convenience Initializers

extension FileConflict {

    /// Creates a FileConflict from a FileWatcher.FileConflict
    public static func from(
        watcherConflict: FileWatcher.FileConflict,
        localContent: String,
        externalContent: String
    ) -> FileConflict {
        return FileConflict(
            url: watcherConflict.url,
            localContent: localContent,
            externalContent: externalContent,
            localModificationDate: watcherConflict.ourModificationDate,
            externalModificationDate: watcherConflict.diskModificationDate
        )
    }
}

// MARK: - FileWatcher Extension

extension FileWatcher {
    /// Information about a file conflict (lightweight version in FileWatcher)
    public struct FileConflict {
        /// The file URL
        public let url: URL

        /// The last modification date we have in memory
        public let ourModificationDate: Date

        /// The modification date on disk
        public let diskModificationDate: Date

        /// The file was modified externally while we had unsaved changes
        public var hasConflict: Bool {
            return diskModificationDate > ourModificationDate
        }

        public init(url: URL, ourModificationDate: Date, diskModificationDate: Date) {
            self.url = url
            self.ourModificationDate = ourModificationDate
            self.diskModificationDate = diskModificationDate
        }
    }
}
