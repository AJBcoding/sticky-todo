//
//  Tag.swift
//  StickyToDo
//
//  Custom tags for categorizing and organizing tasks.
//

import Foundation

/// Represents a custom tag that can be applied to tasks
///
/// Tags provide flexible categorization beyond projects and contexts.
/// Each tag has a name, color, and optional icon for visual identification.
struct Tag: Identifiable, Codable, Hashable {
    // MARK: - Core Properties

    /// Unique identifier for the tag
    let id: UUID

    /// Tag name (e.g., "urgent", "personal", "review")
    var name: String

    /// Color for the tag in hex format (e.g., "#FF5733")
    var color: String

    /// Optional SF Symbol name for the tag icon
    var icon: String?

    /// When this tag was created
    var created: Date

    /// When this tag was last modified
    var modified: Date

    // MARK: - Initialization

    /// Creates a new tag
    /// - Parameters:
    ///   - id: Unique identifier (generates new UUID if not provided)
    ///   - name: Tag name
    ///   - color: Hex color code
    ///   - icon: Optional SF Symbol name
    ///   - created: Creation timestamp (defaults to now)
    ///   - modified: Modification timestamp (defaults to now)
    init(
        id: UUID = UUID(),
        name: String,
        color: String,
        icon: String? = nil,
        created: Date = Date(),
        modified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.created = created
        self.modified = modified
    }
}

// MARK: - Computed Properties

extension Tag {
    /// Returns the display name for this tag
    var displayName: String {
        return name
    }

    /// Returns true if this tag has an icon
    var hasIcon: Bool {
        return icon != nil
    }
}

// MARK: - Predefined Tags

extension Tag {
    /// Urgent tag - for time-sensitive items
    static var urgent: Tag {
        Tag(name: "urgent", color: "#FF3B30", icon: "exclamationmark.triangle.fill")
    }

    /// Important tag - for high-value items
    static var important: Tag {
        Tag(name: "important", color: "#FF9500", icon: "star.fill")
    }

    /// Personal tag - for personal tasks
    static var personal: Tag {
        Tag(name: "personal", color: "#5856D6", icon: "person.fill")
    }

    /// Work tag - for work-related tasks
    static var work: Tag {
        Tag(name: "work", color: "#007AFF", icon: "briefcase.fill")
    }

    /// Review tag - for items needing review
    static var review: Tag {
        Tag(name: "review", color: "#34C759", icon: "checkmark.circle.fill")
    }

    /// Planning tag - for planning and strategy tasks
    static var planning: Tag {
        Tag(name: "planning", color: "#AF52DE", icon: "map.fill")
    }

    /// Meeting tag - for meeting-related tasks
    static var meeting: Tag {
        Tag(name: "meeting", color: "#FF2D55", icon: "person.3.fill")
    }

    /// Research tag - for research tasks
    static var research: Tag {
        Tag(name: "research", color: "#5AC8FA", icon: "magnifyingglass")
    }

    /// Returns all predefined tags
    static var defaultTags: [Tag] {
        return [
            .urgent,
            .important,
            .personal,
            .work,
            .review,
            .planning,
            .meeting,
            .research
        ]
    }
}

// MARK: - Tag Helpers

extension Tag {
    /// Updates the modified timestamp
    mutating func touch() {
        modified = Date()
    }
}
