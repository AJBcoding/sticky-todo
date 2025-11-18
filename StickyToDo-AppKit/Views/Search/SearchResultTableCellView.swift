//
//  SearchResultTableCellView.swift
//  StickyToDo
//
//  Table cell view for search results with highlighting.
//

import Cocoa

/// Custom table cell view for displaying search results with highlights
class SearchResultTableCellView: NSTableCellView {

    // MARK: - UI Components

    private let statusImageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let metadataLabel = NSTextField(labelWithString: "")
    private let notesPreviewLabel = NSTextField(wrappingLabelWithString: "")
    private let matchedFieldsLabel = NSTextField(labelWithString: "")
    private let containerStack = NSStackView()

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Configure status image
        statusImageView.imageScaling = .scaleProportionallyDown
        statusImageView.translatesAutoresizingMaskIntoConstraints = false

        // Configure title label
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure metadata label
        metadataLabel.font = .systemFont(ofSize: 11)
        metadataLabel.textColor = .secondaryLabelColor
        metadataLabel.lineBreakMode = .byTruncatingTail
        metadataLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure notes preview label
        notesPreviewLabel.font = .systemFont(ofSize: 10)
        notesPreviewLabel.textColor = .tertiaryLabelColor
        notesPreviewLabel.maximumNumberOfLines = 2
        notesPreviewLabel.lineBreakMode = .byTruncatingTail
        notesPreviewLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure matched fields label
        matchedFieldsLabel.font = .systemFont(ofSize: 9)
        matchedFieldsLabel.textColor = .systemBlue
        matchedFieldsLabel.lineBreakMode = .byTruncatingTail
        matchedFieldsLabel.translatesAutoresizingMaskIntoConstraints = false

        // Add subviews
        addSubview(statusImageView)
        addSubview(titleLabel)
        addSubview(metadataLabel)
        addSubview(notesPreviewLabel)
        addSubview(matchedFieldsLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Status image
            statusImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            statusImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            statusImageView.widthAnchor.constraint(equalToConstant: 16),
            statusImageView.heightAnchor.constraint(equalToConstant: 16),

            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: statusImageView.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            // Metadata label
            metadataLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metadataLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            metadataLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            // Notes preview label
            notesPreviewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            notesPreviewLabel.topAnchor.constraint(equalTo: metadataLabel.bottomAnchor, constant: 4),
            notesPreviewLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            // Matched fields label
            matchedFieldsLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            matchedFieldsLabel.topAnchor.constraint(equalTo: notesPreviewLabel.bottomAnchor, constant: 2),
            matchedFieldsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            matchedFieldsLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Configuration

    func configure(with result: SearchResult) {
        let task = result.task

        // Configure status image
        statusImageView.image = statusImage(for: task.status)
        statusImageView.contentTintColor = statusColor(for: task.status)

        // Configure title with highlighting
        if result.hasMatch(in: "title") {
            titleLabel.attributedStringValue = highlightedText(
                text: task.title,
                highlights: result.highlights(for: "title")
            )
        } else {
            titleLabel.stringValue = task.title
        }

        // Configure metadata
        var metadataParts: [String] = []

        if let project = task.project {
            if result.hasMatch(in: "project") {
                metadataParts.append("📁 " + project)
            } else {
                metadataParts.append(project)
            }
        }

        if let context = task.context {
            if result.hasMatch(in: "context") {
                metadataParts.append("🏷 " + context)
            } else {
                metadataParts.append(context)
            }
        }

        if task.flagged {
            metadataParts.append("🚩")
        }

        if !task.tags.isEmpty {
            if result.hasMatch(in: "tags") {
                metadataParts.append("Tags: " + task.tags.map { $0.name }.joined(separator: ", "))
            }
        }

        metadataLabel.stringValue = metadataParts.joined(separator: " • ")

        // Configure notes preview
        if !task.notes.isEmpty && result.hasMatch(in: "notes") {
            if let firstHighlight = result.highlights(for: "notes").first {
                let preview = SearchManager.extractContext(
                    text: task.notes,
                    matchRange: firstHighlight.range,
                    contextLength: 80
                )
                notesPreviewLabel.stringValue = "Notes: " + preview
                notesPreviewLabel.isHidden = false
            } else {
                notesPreviewLabel.isHidden = true
            }
        } else {
            notesPreviewLabel.isHidden = true
        }

        // Configure matched fields
        let matchedFields = result.matchedFields.keys.sorted().joined(separator: ", ")
        matchedFieldsLabel.stringValue = "Matched in: " + matchedFields
    }

    // MARK: - Helpers

    private func statusImage(for status: Status) -> NSImage? {
        let symbolName: String
        switch status {
        case .inbox:
            symbolName = "circle"
        case .nextAction:
            symbolName = "circle.fill"
        case .waiting:
            symbolName = "clock.fill"
        case .someday:
            symbolName = "tray.fill"
        case .completed:
            symbolName = "checkmark.circle.fill"
        }
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: status.rawValue)
    }

    private func statusColor(for status: Status) -> NSColor {
        switch status {
        case .inbox:
            return .systemGray
        case .nextAction:
            return .systemBlue
        case .waiting:
            return .systemOrange
        case .someday:
            return .systemPurple
        case .completed:
            return .systemGreen
        }
    }

    private func highlightedText(text: String, highlights: [SearchHighlight]) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: (text as NSString).length)

        // Set default attributes
        attributedString.addAttribute(.font, value: NSFont.systemFont(ofSize: 13, weight: .semibold), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

        // Apply highlights
        for highlight in highlights {
            // Ensure range is valid
            let safeRange = NSIntersectionRange(highlight.range, fullRange)
            guard safeRange.length > 0 else { continue }

            // Highlight with yellow background
            attributedString.addAttribute(.backgroundColor, value: NSColor.yellow.withAlphaComponent(0.5), range: safeRange)
            attributedString.addAttribute(.foregroundColor, value: NSColor.black, range: safeRange)
        }

        return attributedString
    }
}
