//
//  Attachment.swift
//  StickyToDo
//
//  Attachments for tasks including files, links, and notes.
//

import Foundation

/// Type of attachment
public enum AttachmentType: Codable, Equatable, Hashable {
    /// File attachment with URL reference
    case file(URL)

    /// Link/URL attachment
    case link(URL)

    /// Text note attachment
    case note(String)
}

/// Represents an attachment associated with a task
///
/// Attachments can be files (stored externally), links, or text notes.
/// For files, we store references rather than copies to avoid duplication.
public struct Attachment: Identifiable, Codable, Hashable {
    // MARK: - Core Properties

    /// Unique identifier for the attachment
    let id: UUID

    /// Type of attachment (file, link, or note)
    var type: AttachmentType

    /// Display name for the attachment
    var name: String

    /// When this attachment was added
    var dateAdded: Date

    /// Optional description or metadata
    var description: String?

    // MARK: - Initialization

    /// Creates a new attachment
    /// - Parameters:
    ///   - id: Unique identifier (generates new UUID if not provided)
    ///   - type: Attachment type
    ///   - name: Display name
    ///   - dateAdded: When the attachment was added (defaults to now)
    ///   - description: Optional description
    public init(
        id: UUID = UUID(),
        type: AttachmentType,
        name: String,
        dateAdded: Date = Date(),
        description: String? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.dateAdded = dateAdded
        self.description = description
    }
}

// MARK: - Computed Properties

extension Attachment {
    /// Returns true if this is a file attachment
    var isFile: Bool {
        if case .file = type {
            return true
        }
        return false
    }

    /// Returns true if this is a link attachment
    var isLink: Bool {
        if case .link = type {
            return true
        }
        return false
    }

    /// Returns true if this is a note attachment
    var isNote: Bool {
        if case .note = type {
            return true
        }
        return false
    }

    /// Returns the URL for file and link attachments
    var url: URL? {
        switch type {
        case .file(let url), .link(let url):
            return url
        case .note:
            return nil
        }
    }

    /// Returns the note text for note attachments
    var noteText: String? {
        if case .note(let text) = type {
            return text
        }
        return nil
    }

    /// Returns the file extension for file attachments
    var fileExtension: String? {
        guard case .file(let url) = type else { return nil }
        return url.pathExtension.lowercased()
    }

    /// Returns a human-readable type description
    var typeDescription: String {
        switch type {
        case .file:
            return "File"
        case .link:
            return "Link"
        case .note:
            return "Note"
        }
    }

    /// Returns an SF Symbol name appropriate for this attachment type
    var iconName: String {
        switch type {
        case .file(let url):
            let ext = url.pathExtension.lowercased()
            switch ext {
            case "pdf":
                return "doc.text.fill"
            case "jpg", "jpeg", "png", "gif", "heic":
                return "photo.fill"
            case "doc", "docx", "txt", "md":
                return "doc.fill"
            case "xls", "xlsx", "csv":
                return "tablecells.fill"
            case "zip", "tar", "gz":
                return "archivebox.fill"
            default:
                return "doc.fill"
            }
        case .link:
            return "link"
        case .note:
            return "note.text"
        }
    }

    /// Returns true if this attachment can be previewed
    var canPreview: Bool {
        guard let ext = fileExtension else { return false }
        let previewableExtensions = ["pdf", "jpg", "jpeg", "png", "gif", "txt", "md"]
        return previewableExtensions.contains(ext)
    }
}

// MARK: - Helper Methods

extension Attachment {
    /// Creates a file attachment from a URL
    /// - Parameters:
    ///   - url: File URL
    ///   - name: Optional custom name (defaults to filename)
    ///   - description: Optional description
    /// - Returns: File attachment
    static func fileAttachment(
        url: URL,
        name: String? = nil,
        description: String? = nil
    ) -> Attachment {
        let displayName = name ?? url.lastPathComponent
        return Attachment(
            type: .file(url),
            name: displayName,
            description: description
        )
    }

    /// Creates a link attachment from a URL
    /// - Parameters:
    ///   - url: Link URL
    ///   - name: Display name for the link
    ///   - description: Optional description
    /// - Returns: Link attachment
    static func linkAttachment(
        url: URL,
        name: String,
        description: String? = nil
    ) -> Attachment {
        return Attachment(
            type: .link(url),
            name: name,
            description: description
        )
    }

    /// Creates a note attachment
    /// - Parameters:
    ///   - text: Note text
    ///   - name: Display name for the note
    ///   - description: Optional description
    /// - Returns: Note attachment
    static func noteAttachment(
        text: String,
        name: String,
        description: String? = nil
    ) -> Attachment {
        return Attachment(
            type: .note(text),
            name: name,
            description: description
        )
    }
}

// MARK: - Validation

extension Attachment {
    /// Validates that a file attachment's URL is accessible
    /// - Returns: True if the file exists and is accessible
    func validateFileAccess() -> Bool {
        guard case .file(let url) = type else { return true }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Validates that a link attachment's URL is valid
    /// - Returns: True if the URL is valid
    func validateLinkURL() -> Bool {
        guard case .link(let url) = type else { return true }
        return url.scheme != nil && url.host != nil
    }
}
