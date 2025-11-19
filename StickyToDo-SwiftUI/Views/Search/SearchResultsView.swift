//
//  SearchResultsView.swift
//  StickyToDo
//
//  Search results view with highlighting and context preview.
//

import SwiftUI

/// View displaying search results with highlighting
struct SearchResultsView: View {
    let results: [SearchResult]
    let query: String
    let onSelectTask: (Task) -> Void

    @State private var selectedResultId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Results header
            resultsHeader

            Divider()

            // Results list
            if results.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(results) { result in
                            SearchResultRow(
                                result: result,
                                query: query,
                                isSelected: selectedResultId == result.id,
                                onSelect: {
                                    selectedResultId = result.id
                                    onSelectTask(result.task)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var resultsHeader: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.headline)

            Spacer()

            if !query.isEmpty {
                Text("for \"\(query)\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No results found")
                .font(.title2)
                .fontWeight(.medium)

            if !query.isEmpty {
                Text("Try adjusting your search terms")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Row displaying a single search result with highlights
struct SearchResultRow: View {
    let result: SearchResult
    let query: String
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var task: Task

    init(result: SearchResult, query: String, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.result = result
        self.query = query
        self.isSelected = isSelected
        self.onSelect = onSelect
        self._task = State(initialValue: result.task)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Task title with highlighting
                HStack(spacing: 8) {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)

                    HighlightedText(
                        text: result.task.title,
                        highlights: result.highlights(for: "title"),
                        font: .body.weight(.semibold)
                    )

                    Spacer()

                    // Relevance indicator
                    RelevanceBadge(score: result.relevanceScore)
                }

                // Task metadata
                HStack(spacing: 12) {
                    if let project = result.task.project {
                        if result.hasMatch(in: "project") {
                            HighlightedText(
                                text: project,
                                highlights: result.highlights(for: "project"),
                                font: .caption,
                                foregroundColor: .secondary
                            )
                        } else {
                            Text(project)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let context = result.task.context {
                        if result.hasMatch(in: "context") {
                            HighlightedText(
                                text: context,
                                highlights: result.highlights(for: "context"),
                                font: .caption,
                                foregroundColor: .secondary
                            )
                        } else {
                            Text(context)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if result.task.flagged {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    if !result.task.tags.isEmpty {
                        if result.hasMatch(in: "tags") {
                            Text("Tags: \(result.task.tags.map { $0.name }.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.3))
                                .cornerRadius(4)
                        } else {
                            Text(result.task.tags.map { $0.name }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Notes preview with highlighting
                if !result.task.notes.isEmpty && result.hasMatch(in: "notes") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)

                        let notesHighlights = result.highlights(for: "notes")
                        if let firstHighlight = notesHighlights.first {
                            let preview = SearchManager.extractContext(
                                text: result.task.notes,
                                matchRange: firstHighlight.range,
                                contextLength: 60
                            )

                            Text(preview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }

                // Matched fields indicator
                if !result.matchedFields.isEmpty {
                    HStack(spacing: 4) {
                        Text("Matched in:")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        ForEach(Array(result.matchedFields.keys.sorted()), id: \.self) { field in
                            Text(field)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(3)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            searchResultContextMenu
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var searchResultContextMenu: some View {
        // SECTION 1: Quick Actions
        if task.status != .completed {
            Button("Complete", systemImage: "checkmark.circle.fill") {
                task.status = .completed
                updateTask()
            }
        } else {
            Button("Reopen", systemImage: "arrow.uturn.backward.circle") {
                task.status = .nextAction
                updateTask()
            }
        }

        Button(task.flagged ? "Unflag" : "Flag", systemImage: task.flagged ? "star.slash.fill" : "star.fill") {
            task.flagged.toggle()
            updateTask()
        }

        Button("Edit", systemImage: "pencil") {
            onSelect()
        }

        Divider()

        // SECTION 2: Status & Priority
        Menu("Status", systemImage: "text.badge.checkmark") {
            Button("Inbox", systemImage: task.status == .inbox ? "checkmark" : "") {
                task.status = .inbox
                updateTask()
            }

            Button("Next Action", systemImage: task.status == .nextAction ? "checkmark" : "") {
                task.status = .nextAction
                updateTask()
            }

            Button("Waiting", systemImage: task.status == .waiting ? "checkmark" : "") {
                task.status = .waiting
                updateTask()
            }

            Button("Someday", systemImage: task.status == .someday ? "checkmark" : "") {
                task.status = .someday
                updateTask()
            }
        }

        Menu("Priority", systemImage: priorityIcon) {
            Button("High", systemImage: task.priority == .high ? "checkmark" : "") {
                task.priority = .high
                updateTask()
            }

            Button("Medium", systemImage: task.priority == .medium ? "checkmark" : "") {
                task.priority = .medium
                updateTask()
            }

            Button("Low", systemImage: task.priority == .low ? "checkmark" : "") {
                task.priority = .low
                updateTask()
            }
        }

        Divider()

        // SECTION 3: Copy & Share Actions
        Menu("Copy", systemImage: "doc.on.doc") {
            Button("Copy Title", systemImage: "text.quote") {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(task.title, forType: .string)
                #endif
            }
            .accessibilityLabel("Copy task title to clipboard")

            Button("Copy Link", systemImage: "link") {
                let link = "stickytodo://task/\(task.id.uuidString)"
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(link, forType: .string)
                #endif
            }
            .accessibilityLabel("Copy task link to clipboard")
        }
        .accessibilityLabel("Copy task in various formats")

        Button("Share...", systemImage: "square.and.arrow.up") {
            #if os(macOS)
            NotificationCenter.default.post(
                name: NSNotification.Name("ShareTask"),
                object: ["taskId": task.id, "items": [task.title]]
            )
            #endif
        }
        .accessibilityLabel("Share task using system share sheet")

        Divider()

        // SECTION 4: Task Actions
        Button("Open in New Window", systemImage: "rectangle.badge.plus") {
            #if os(macOS)
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenTaskInNewWindow"),
                object: task.id
            )
            #endif
        }
        .accessibilityLabel("Open task in a new window")

        Button("Duplicate", systemImage: "doc.on.doc.fill") {
            NotificationCenter.default.post(
                name: NSNotification.Name("DuplicateTask"),
                object: task.id
            )
        }
        .accessibilityLabel("Duplicate this task")

        Button("Delete", systemImage: "trash", role: .destructive) {
            NotificationCenter.default.post(
                name: NSNotification.Name("DeleteTask"),
                object: task.id
            )
        }
        .accessibilityLabel("Delete this task")
    }

    // MARK: - Helpers

    private var priorityIcon: String {
        switch task.priority {
        case .high:
            return "exclamationmark.3"
        case .medium:
            return "exclamationmark.2"
        case .low:
            return "exclamationmark"
        }
    }

    private func updateTask() {
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateTask"),
            object: task
        )
    }

    private var statusIcon: String {
        switch result.task.status {
        case .completed:
            return "checkmark.circle.fill"
        case .nextAction:
            return "circle.fill"
        case .waiting:
            return "clock.fill"
        case .someday:
            return "tray.fill"
        case .inbox:
            return "circle"
        }
    }

    private var statusColor: Color {
        switch result.task.status {
        case .completed:
            return .green
        case .nextAction:
            return .blue
        case .waiting:
            return .orange
        case .someday:
            return .purple
        case .inbox:
            return .gray
        }
    }
}

/// Badge showing relevance score
struct RelevanceBadge: View {
    let score: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: index < relevanceStars ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
        }
    }

    private var relevanceStars: Int {
        // Map score to 1-5 stars
        // Typical scores range from 0 to ~50
        if score >= 30 {
            return 5
        } else if score >= 20 {
            return 4
        } else if score >= 10 {
            return 3
        } else if score >= 5 {
            return 2
        } else {
            return 1
        }
    }
}

/// Text view with highlighted regions
struct HighlightedText: View {
    let text: String
    let highlights: [SearchHighlight]
    var font: Font = .body
    var foregroundColor: Color = .primary

    var body: some View {
        if highlights.isEmpty {
            Text(text)
                .font(font)
                .foregroundColor(foregroundColor)
        } else {
            // Build attributed text with highlights
            attributedText
                .font(font)
        }
    }

    private var attributedText: Text {
        let nsString = text as NSString
        var result = Text("")
        var lastIndex = 0

        // Sort highlights by position
        let sortedHighlights = highlights.sorted { $0.range.location < $1.range.location }

        for highlight in sortedHighlights {
            // Add text before highlight
            if highlight.range.location > lastIndex {
                let beforeRange = NSRange(
                    location: lastIndex,
                    length: highlight.range.location - lastIndex
                )
                let beforeText = nsString.substring(with: beforeRange)
                result = result + Text(beforeText)
                    .foregroundColor(foregroundColor)
            }

            // Add highlighted text
            let highlightedText = nsString.substring(with: highlight.range)
            result = result + Text(highlightedText)
                .foregroundColor(foregroundColor)
                .background(Color.yellow.opacity(0.5))

            lastIndex = highlight.range.location + highlight.range.length
        }

        // Add remaining text
        if lastIndex < nsString.length {
            let remainingRange = NSRange(
                location: lastIndex,
                length: nsString.length - lastIndex
            )
            let remainingText = nsString.substring(with: remainingRange)
            result = result + Text(remainingText)
                .foregroundColor(foregroundColor)
        }

        return result
    }
}

// MARK: - Preview

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView(
            results: [],
            query: "test",
            onSelectTask: { _ in }
        )
        .frame(width: 600, height: 400)
    }
}
