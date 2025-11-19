//
//  DiffView.swift
//  StickyToDo-SwiftUI
//
//  Component for displaying differences between two versions of content.
//  Shows line-by-line or field-by-field differences with visual highlighting.
//

import SwiftUI

/// Displays differences between two text contents
struct DiffView: View {
    let localContent: String
    let externalContent: String

    @State private var diffLines: [DiffLine] = []
    @State private var showUnchangedLines = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Differences")
                    .font(.headline)

                Spacer()

                Toggle("Show Unchanged Lines", isOn: $showUnchangedLines)
                    .toggleStyle(.switch)
                    .font(.caption)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Diff content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredDiffLines) { line in
                        DiffLineView(line: line)
                    }
                }
            }
        }
        .onAppear {
            computeDiff()
        }
        .onChange(of: localContent) { _ in
            computeDiff()
        }
        .onChange(of: externalContent) { _ in
            computeDiff()
        }
    }

    private var filteredDiffLines: [DiffLine] {
        if showUnchangedLines {
            return diffLines
        } else {
            return diffLines.filter { $0.type != .unchanged }
        }
    }

    private func computeDiff() {
        let localLines = localContent.components(separatedBy: .newlines)
        let externalLines = externalContent.components(separatedBy: .newlines)

        var result: [DiffLine] = []
        var localIndex = 0
        var externalIndex = 0

        // Simple line-by-line diff algorithm
        while localIndex < localLines.count || externalIndex < externalLines.count {
            if localIndex >= localLines.count {
                // Only external lines remain (additions)
                result.append(DiffLine(
                    type: .added,
                    lineNumber: externalIndex + 1,
                    content: externalLines[externalIndex]
                ))
                externalIndex += 1
            } else if externalIndex >= externalLines.count {
                // Only local lines remain (deletions)
                result.append(DiffLine(
                    type: .removed,
                    lineNumber: localIndex + 1,
                    content: localLines[localIndex]
                ))
                localIndex += 1
            } else if localLines[localIndex] == externalLines[externalIndex] {
                // Lines match (unchanged)
                result.append(DiffLine(
                    type: .unchanged,
                    lineNumber: localIndex + 1,
                    content: localLines[localIndex]
                ))
                localIndex += 1
                externalIndex += 1
            } else {
                // Lines differ - check if it's a modification or add/remove
                if localIndex + 1 < localLines.count &&
                   localLines[localIndex + 1] == externalLines[externalIndex] {
                    // Local line was removed
                    result.append(DiffLine(
                        type: .removed,
                        lineNumber: localIndex + 1,
                        content: localLines[localIndex]
                    ))
                    localIndex += 1
                } else if externalIndex + 1 < externalLines.count &&
                          localLines[localIndex] == externalLines[externalIndex + 1] {
                    // External line was added
                    result.append(DiffLine(
                        type: .added,
                        lineNumber: externalIndex + 1,
                        content: externalLines[externalIndex]
                    ))
                    externalIndex += 1
                } else {
                    // Modified line
                    result.append(DiffLine(
                        type: .removed,
                        lineNumber: localIndex + 1,
                        content: localLines[localIndex]
                    ))
                    result.append(DiffLine(
                        type: .added,
                        lineNumber: externalIndex + 1,
                        content: externalLines[externalIndex]
                    ))
                    localIndex += 1
                    externalIndex += 1
                }
            }
        }

        diffLines = result
    }
}

// MARK: - Diff Line Model

struct DiffLine: Identifiable {
    let id = UUID()
    let type: DiffType
    let lineNumber: Int
    let content: String

    enum DiffType {
        case unchanged
        case added
        case removed
        case modified
    }
}

// MARK: - Diff Line View

struct DiffLineView: View {
    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Line number
            Text("\(line.lineNumber)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)

            // Diff indicator
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(iconColor)
                .frame(width: 16)

            // Content
            Text(line.content.isEmpty ? " " : line.content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(accessibilityTypeLabel), line \(line.lineNumber): \(line.content)")
    }

    private var iconName: String {
        switch line.type {
        case .unchanged:
            return "equal"
        case .added:
            return "plus"
        case .removed:
            return "minus"
        case .modified:
            return "exclamationmark"
        }
    }

    private var iconColor: Color {
        switch line.type {
        case .unchanged:
            return .secondary
        case .added:
            return .green
        case .removed:
            return .red
        case .modified:
            return .orange
        }
    }

    private var backgroundColor: Color {
        switch line.type {
        case .unchanged:
            return .clear
        case .added:
            return Color.green.opacity(0.1)
        case .removed:
            return Color.red.opacity(0.1)
        case .modified:
            return Color.orange.opacity(0.1)
        }
    }

    private var accessibilityTypeLabel: String {
        switch line.type {
        case .unchanged:
            return "Unchanged"
        case .added:
            return "Added"
        case .removed:
            return "Removed"
        case .modified:
            return "Modified"
        }
    }
}

// MARK: - Field-Based Diff View

/// Displays field-by-field differences for structured content
struct FieldDiffView: View {
    let fields: [FieldDiff]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(fields) { field in
                FieldDiffRow(field: field)
            }
        }
        .padding()
    }
}

struct FieldDiff: Identifiable {
    let id = UUID()
    let name: String
    let localValue: String
    let externalValue: String

    var hasChanged: Bool {
        localValue != externalValue
    }
}

struct FieldDiffRow: View {
    let field: FieldDiff

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Field name
            Text(field.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if field.hasChanged {
                HStack(spacing: 12) {
                    // Local value (removed)
                    HStack {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)

                        Text(field.localValue)
                            .strikethrough()
                            .foregroundColor(.red)
                    }

                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                        .font(.caption2)

                    // External value (added)
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text(field.externalValue)
                            .foregroundColor(.green)
                    }
                }
                .font(.body)
            } else {
                // Unchanged
                HStack {
                    Image(systemName: "equal.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text(field.localValue)
                        .foregroundColor(.secondary)
                }
                .font(.body)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(field.name): \(field.hasChanged ? "changed from \(field.localValue) to \(field.externalValue)" : "unchanged, \(field.localValue)")")
    }
}

// MARK: - Preview

#Preview("Line Diff") {
    DiffView(
        localContent: """
        # Task Title

        This is the local version.
        It has some content here.
        And a third line.
        """,
        externalContent: """
        # Task Title

        This is the external version.
        It has different content here.
        And a third line.
        Plus an extra line.
        """
    )
    .frame(height: 400)
}

#Preview("Field Diff") {
    FieldDiffView(fields: [
        FieldDiff(name: "Title", localValue: "My Task", externalValue: "My Task"),
        FieldDiff(name: "Status", localValue: "inbox", externalValue: "next-action"),
        FieldDiff(name: "Project", localValue: "Work", externalValue: "Personal"),
        FieldDiff(name: "Due", localValue: "2025-11-20", externalValue: "2025-11-25")
    ])
}
