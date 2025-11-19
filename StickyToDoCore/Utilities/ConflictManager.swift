//
//  ConflictManager.swift
//  StickyToDoCore
//
//  Centralized conflict management for handling file conflicts from external changes.
//  Provides merge strategies and resolution tracking.
//

import Foundation
import Combine

/// Strategy for resolving file conflicts
public enum ConflictResolutionStrategy {
    case keepLocal
    case useExternal
    case merge
    case viewBoth
}

/// Represents a detected file conflict between in-memory and disk versions
public struct FileConflict: Identifiable, Equatable {
    public let id = UUID()
    public let url: URL
    public let localContent: String
    public let externalContent: String
    public let localModificationDate: Date
    public let externalModificationDate: Date

    public init(
        url: URL,
        localContent: String,
        externalContent: String,
        localModificationDate: Date,
        externalModificationDate: Date
    ) {
        self.url = url
        self.localContent = localContent
        self.externalContent = externalContent
        self.localModificationDate = localModificationDate
        self.externalModificationDate = externalModificationDate
    }

    /// Returns true if the contents are identical
    public var hasActualConflict: Bool {
        return localContent != externalContent
    }

    /// Returns the filename
    public var fileName: String {
        return url.lastPathComponent
    }

    public static func == (lhs: FileConflict, rhs: FileConflict) -> Bool {
        return lhs.url == rhs.url
    }
}

/// Result of a conflict resolution
public struct ConflictResolution {
    public let conflict: FileConflict
    public let strategy: ConflictResolutionStrategy
    public let resolvedContent: String
    public let timestamp: Date

    public init(
        conflict: FileConflict,
        strategy: ConflictResolutionStrategy,
        resolvedContent: String,
        timestamp: Date = Date()
    ) {
        self.conflict = conflict
        self.strategy = strategy
        self.resolvedContent = resolvedContent
        self.timestamp = timestamp
    }
}

/// Centralized manager for handling file conflicts
///
/// ConflictManager tracks detected conflicts, provides merge algorithms,
/// and coordinates resolution between the file system and in-memory stores.
///
/// Usage:
/// ```swift
/// let manager = ConflictManager.shared
///
/// // Add a conflict
/// manager.addConflict(conflict)
///
/// // Resolve a conflict
/// try manager.resolve(conflict, strategy: .merge)
///
/// // Observe conflicts
/// manager.$conflicts.sink { conflicts in
///     // Update UI
/// }
/// ```
@MainActor
public class ConflictManager: ObservableObject {

    // MARK: - Singleton

    public static let shared = ConflictManager()

    // MARK: - Published Properties

    /// Active conflicts awaiting resolution
    @Published public private(set) var conflicts: [FileConflict] = []

    /// Recently resolved conflicts (kept for history)
    @Published public private(set) var resolvedConflicts: [ConflictResolution] = []

    /// Number of active conflicts
    public var conflictCount: Int {
        conflicts.count
    }

    /// Whether there are any active conflicts
    public var hasConflicts: Bool {
        !conflicts.isEmpty
    }

    // MARK: - Callbacks

    /// Called when a conflict is added
    public var onConflictAdded: ((FileConflict) -> Void)?

    /// Called when a conflict is resolved
    public var onConflictResolved: ((ConflictResolution) -> Void)?

    /// Called when all conflicts are resolved
    public var onAllConflictsResolved: (() -> Void)?

    // MARK: - Configuration

    /// Maximum number of resolved conflicts to keep in history
    public var maxResolvedHistory = 50

    /// Whether to automatically merge identical conflicts
    public var autoMergeIdenticalContent = true

    // MARK: - Private Properties

    private var logger: ((String) -> Void)?

    // MARK: - Initialization

    private init() {
        // Private initializer for singleton
    }

    /// Configure logging
    public func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    // MARK: - Conflict Management

    /// Adds a conflict to be resolved
    public func addConflict(_ conflict: FileConflict) {
        log("Adding conflict: \(conflict.fileName)")

        // Check if already exists
        if conflicts.contains(where: { $0.url == conflict.url }) {
            log("Conflict already exists for: \(conflict.fileName)")
            return
        }

        // Auto-merge if content is identical
        if autoMergeIdenticalContent && !conflict.hasActualConflict {
            log("Auto-resolving conflict with identical content: \(conflict.fileName)")
            try? resolve(conflict, strategy: .useExternal)
            return
        }

        conflicts.append(conflict)
        onConflictAdded?(conflict)

        // Post notification
        NotificationCenter.default.post(
            name: .fileConflictDetected,
            object: conflict
        )
    }

    /// Removes a conflict without resolving it
    public func removeConflict(_ conflict: FileConflict) {
        conflicts.removeAll { $0.id == conflict.id }
        log("Removed conflict: \(conflict.fileName)")

        checkIfAllResolved()
    }

    /// Resolves a conflict using the specified strategy
    public func resolve(_ conflict: FileConflict, strategy: ConflictResolutionStrategy) throws {
        log("Resolving conflict with strategy \(strategy): \(conflict.fileName)")

        let resolvedContent: String

        switch strategy {
        case .keepLocal:
            resolvedContent = conflict.localContent

        case .useExternal:
            resolvedContent = conflict.externalContent

        case .merge:
            resolvedContent = try mergeContent(
                local: conflict.localContent,
                external: conflict.externalContent
            )

        case .viewBoth:
            // Create backup of external version
            try createBackup(for: conflict)
            resolvedContent = conflict.localContent
        }

        // Create resolution record
        let resolution = ConflictResolution(
            conflict: conflict,
            strategy: strategy,
            resolvedContent: resolvedContent
        )

        // Add to resolved history
        resolvedConflicts.insert(resolution, at: 0)
        if resolvedConflicts.count > maxResolvedHistory {
            resolvedConflicts = Array(resolvedConflicts.prefix(maxResolvedHistory))
        }

        // Remove from active conflicts
        conflicts.removeAll { $0.id == conflict.id }

        // Notify
        onConflictResolved?(resolution)

        log("Conflict resolved: \(conflict.fileName)")

        checkIfAllResolved()
    }

    /// Resolves all conflicts with the same strategy
    public func resolveAll(strategy: ConflictResolutionStrategy) throws {
        log("Resolving all \(conflicts.count) conflicts with strategy: \(strategy)")

        let conflictsToResolve = conflicts
        for conflict in conflictsToResolve {
            try resolve(conflict, strategy: strategy)
        }
    }

    /// Clears all conflicts without resolving
    public func clearAll() {
        log("Clearing all \(conflicts.count) conflicts")
        conflicts.removeAll()
        checkIfAllResolved()
    }

    /// Clears resolved conflict history
    public func clearResolvedHistory() {
        log("Clearing resolved conflict history")
        resolvedConflicts.removeAll()
    }

    // MARK: - Merge Strategies

    /// Attempts to merge local and external content intelligently
    private func mergeContent(local: String, external: String) throws -> String {
        // For markdown files, we can attempt a smart merge

        // Split into lines for line-based merge
        let localLines = local.components(separatedBy: .newlines)
        let externalLines = external.components(separatedBy: .newlines)

        // If they differ only in frontmatter, merge the frontmatter
        if let merged = try? mergeFrontmatter(localLines: localLines, externalLines: externalLines) {
            return merged
        }

        // Otherwise, create a conflict marker merge
        return createConflictMarkerMerge(local: local, external: external)
    }

    /// Attempts to merge YAML frontmatter while preserving body
    private func mergeFrontmatter(localLines: [String], externalLines: [String]) throws -> String? {
        // Find frontmatter boundaries
        guard localLines.first == "---",
              externalLines.first == "---" else {
            return nil
        }

        let localEndIndex = localLines.dropFirst().firstIndex(of: "---")
        let externalEndIndex = externalLines.dropFirst().firstIndex(of: "---")

        guard let localEnd = localEndIndex,
              let externalEnd = externalEndIndex else {
            return nil
        }

        // Extract frontmatter and body
        let localFrontmatter = Array(localLines[1..<localEnd])
        let externalFrontmatter = Array(externalLines[1..<externalEnd])

        let localBody = Array(localLines[(localEnd + 1)...])
        let externalBody = Array(externalLines[(externalEnd + 1)...])

        // If bodies are identical, merge frontmatter
        if localBody == externalBody {
            let mergedFrontmatter = mergeFrontmatterFields(
                local: localFrontmatter,
                external: externalFrontmatter
            )

            var result = ["---"]
            result.append(contentsOf: mergedFrontmatter)
            result.append("---")
            result.append(contentsOf: localBody)

            return result.joined(separator: "\n")
        }

        return nil
    }

    /// Merges frontmatter fields, preferring newer values
    private func mergeFrontmatterFields(local: [String], external: [String]) -> [String] {
        var fields: [String: String] = [:]

        // Parse local fields
        for line in local {
            if let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                fields[key] = value
            }
        }

        // Parse and merge external fields
        for line in external {
            if let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                fields[key] = value // External wins for conflicts
            }
        }

        // Convert back to lines
        return fields.map { "\($0.key): \($0.value)" }.sorted()
    }

    /// Creates a Git-style conflict marker merge
    private func createConflictMarkerMerge(local: String, external: String) -> String {
        return """
        <<<<<<< Local Version
        \(local)
        =======
        \(external)
        >>>>>>> External Version
        """
    }

    // MARK: - Backup Management

    /// Creates a backup file for the external version
    private func createBackup(for conflict: FileConflict) throws {
        let backupURL = conflict.url.deletingPathExtension()
            .appendingPathExtension("conflict-backup-\(Date().timeIntervalSince1970)")
            .appendingPathExtension(conflict.url.pathExtension)

        try conflict.externalContent.write(to: backupURL, atomically: true, encoding: .utf8)
        log("Created backup: \(backupURL.lastPathComponent)")
    }

    // MARK: - Helpers

    private func checkIfAllResolved() {
        if conflicts.isEmpty && onAllConflictsResolved != nil {
            log("All conflicts resolved")
            onAllConflictsResolved?()
        }
    }

    private func log(_ message: String) {
        logger?("ConflictManager: \(message)")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    public static let fileConflictDetected = Notification.Name("fileConflictDetected")
    public static let fileConflictResolved = Notification.Name("fileConflictResolved")
    public static let allConflictsResolved = Notification.Name("allConflictsResolved")
}

// MARK: - Statistics

extension ConflictManager {
    /// Returns summary statistics about conflict management
    public var statistics: String {
        return """
        Active Conflicts: \(conflicts.count)
        Resolved (History): \(resolvedConflicts.count)
        Auto-Merge: \(autoMergeIdenticalContent ? "Enabled" : "Disabled")
        """
    }
}
