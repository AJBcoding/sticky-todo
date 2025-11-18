//
//  ProjectNote.swift
//  StickyToDo
//
//  Notes and documentation for projects.
//

import Foundation

/// Represents a note or documentation for a project
///
/// Project notes provide a space for reference materials, goals, objectives,
/// and other information related to a specific project. They are stored as
/// markdown files in the projects directory.
struct ProjectNote: Identifiable, Codable, Equatable {
    // MARK: - Core Properties

    /// Unique identifier for the note
    let id: UUID

    /// Project name this note belongs to
    var projectName: String

    /// Note content in markdown format
    var content: String

    /// When this note was created
    var created: Date

    /// When this note was last modified
    var modified: Date

    /// Note title (optional, can be derived from first line of content)
    var title: String?

    /// Tags for organizing notes within a project
    var tags: [String]

    // MARK: - Initialization

    /// Creates a new project note
    /// - Parameters:
    ///   - id: Unique identifier (generates new UUID if not provided)
    ///   - projectName: Name of the project
    ///   - content: Markdown content
    ///   - created: Creation timestamp (defaults to now)
    ///   - modified: Modification timestamp (defaults to now)
    ///   - title: Optional title
    ///   - tags: Tags for organization
    init(
        id: UUID = UUID(),
        projectName: String,
        content: String = "",
        created: Date = Date(),
        modified: Date = Date(),
        title: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.projectName = projectName
        self.content = content
        self.created = created
        self.modified = modified
        self.title = title
        self.tags = tags
    }
}

// MARK: - Computed Properties

extension ProjectNote {
    /// Returns the display title for this note
    /// Uses explicit title if set, otherwise derives from first line of content
    var displayTitle: String {
        if let explicitTitle = title, !explicitTitle.isEmpty {
            return explicitTitle
        }

        // Try to get first line of content
        let firstLine = content.components(separatedBy: .newlines).first ?? ""
        if firstLine.hasPrefix("#") {
            // Strip markdown header markers
            let cleaned = firstLine.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
            return cleaned.isEmpty ? "Untitled Note" : cleaned
        }

        return firstLine.isEmpty ? "Untitled Note" : String(firstLine.prefix(50))
    }

    /// Returns the file path for this note
    /// Format: projects/[project-name]/notes/[id]-[slug].md
    var filePath: String {
        let slug = projectName.slugified()
        return "projects/\(slug)/notes/\(id.uuidString).md"
    }

    /// Returns just the filename component
    var fileName: String {
        return "\(id.uuidString).md"
    }

    /// Returns the number of characters in the content
    var characterCount: Int {
        return content.count
    }

    /// Returns the estimated reading time in minutes
    var estimatedReadingTime: Int {
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        // Assuming 200 words per minute reading speed
        return max(1, wordCount / 200)
    }

    /// Returns true if the note has content
    var hasContent: Bool {
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns true if the note has tags
    var hasTags: Bool {
        return !tags.isEmpty
    }
}

// MARK: - Helper Methods

extension ProjectNote {
    /// Updates the modified timestamp
    mutating func touch() {
        modified = Date()
    }

    /// Adds a tag if it doesn't already exist
    /// - Parameter tag: Tag to add
    mutating func addTag(_ tag: String) {
        guard !tags.contains(tag) else { return }
        tags.append(tag)
        touch()
    }

    /// Removes a tag
    /// - Parameter tag: Tag to remove
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        touch()
    }

    /// Searches for text in the note content
    /// - Parameter query: Search query
    /// - Returns: True if the query is found in content or title
    func matchesSearch(_ query: String) -> Bool {
        let lowercaseQuery = query.lowercased()

        if displayTitle.lowercased().contains(lowercaseQuery) {
            return true
        }

        if content.lowercased().contains(lowercaseQuery) {
            return true
        }

        if projectName.lowercased().contains(lowercaseQuery) {
            return true
        }

        if tags.contains(where: { $0.lowercased().contains(lowercaseQuery) }) {
            return true
        }

        return false
    }
}

// MARK: - Templates

extension ProjectNote {
    /// Creates a new project overview note
    /// - Parameter projectName: Name of the project
    /// - Returns: A new project note with overview template
    static func projectOverview(for projectName: String) -> ProjectNote {
        let content = """
        # \(projectName)

        ## Overview
        Brief description of the project and its goals.

        ## Objectives
        - Objective 1
        - Objective 2
        - Objective 3

        ## Timeline
        Start Date: [Date]
        Target Completion: [Date]

        ## Resources
        - Resource 1
        - Resource 2

        ## Notes
        Additional notes and reference materials.
        """

        return ProjectNote(
            projectName: projectName,
            content: content,
            title: "\(projectName) Overview",
            tags: ["overview"]
        )
    }

    /// Creates a new meeting notes template
    /// - Parameters:
    ///   - projectName: Name of the project
    ///   - meetingDate: Date of the meeting
    /// - Returns: A new project note with meeting template
    static func meetingNotes(for projectName: String, date meetingDate: Date = Date()) -> ProjectNote {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dateString = formatter.string(from: meetingDate)

        let content = """
        # Meeting Notes - \(dateString)

        **Date:** \(dateString)
        **Project:** \(projectName)
        **Attendees:**
        -

        ## Agenda
        -

        ## Discussion
        -

        ## Action Items
        -

        ## Next Steps
        -
        """

        return ProjectNote(
            projectName: projectName,
            content: content,
            title: "Meeting - \(dateString)",
            tags: ["meeting"]
        )
    }

    /// Creates a new decisions log
    /// - Parameter projectName: Name of the project
    /// - Returns: A new project note with decisions template
    static func decisionsLog(for projectName: String) -> ProjectNote {
        let content = """
        # Decisions Log

        Track important decisions made during the project.

        ## [Date] - Decision Title
        **Context:** What led to this decision?
        **Decision:** What was decided?
        **Rationale:** Why was this decided?
        **Alternatives Considered:**
        -

        ## [Date] - Decision Title
        **Context:**
        **Decision:**
        **Rationale:**
        **Alternatives Considered:**
        -
        """

        return ProjectNote(
            projectName: projectName,
            content: content,
            title: "Decisions Log",
            tags: ["decisions", "log"]
        )
    }

    /// Creates a new resources note
    /// - Parameter projectName: Name of the project
    /// - Returns: A new project note with resources template
    static func resources(for projectName: String) -> ProjectNote {
        let content = """
        # Resources & References

        ## Documentation
        -

        ## Links
        -

        ## Files
        -

        ## Contacts
        - Name: [Contact info]

        ## Tools
        -

        ## Notes
        -
        """

        return ProjectNote(
            projectName: projectName,
            content: content,
            title: "Resources",
            tags: ["resources", "reference"]
        )
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

        // Truncate to reasonable length
        let maxLength = 50
        if slug.count > maxLength {
            return String(slug.prefix(maxLength))
        }

        return slug.isEmpty ? "untitled" : slug
    }
}
