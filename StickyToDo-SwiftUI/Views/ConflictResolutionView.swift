//
//  ConflictResolutionView.swift
//  StickyToDo-SwiftUI
//
//  Conflict resolution UI for handling file conflicts from external changes.
//  Shows side-by-side diff and allows user to choose resolution strategy.
//

import SwiftUI

/// Represents a file conflict that needs resolution
struct FileConflictItem: Identifiable {
    let id = UUID()
    let url: URL
    let ourContent: String
    let theirContent: String
    let ourModificationDate: Date
    let theirModificationDate: Date
    var resolution: ConflictResolution = .unresolved

    var fileName: String {
        url.lastPathComponent
    }

    var hasChanges: Bool {
        ourContent != theirContent
    }
}

/// Resolution strategy for a conflict
enum ConflictResolution {
    case unresolved
    case keepMine
    case keepTheirs
    case viewBoth
    case merge(String) // Custom merged content
}

/// Main conflict resolution view
struct ConflictResolutionView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ConflictResolutionViewModel

    init(conflicts: [FileConflictItem]) {
        _viewModel = StateObject(wrappedValue: ConflictResolutionViewModel(conflicts: conflicts))
    }

    var body: some View {
        NavigationStack {
            HSplitView {
                // Left: File list
                conflictListView
                    .frame(minWidth: 250, maxWidth: 350)

                // Right: Detail view
                if let selectedConflict = viewModel.selectedConflict {
                    conflictDetailView(selectedConflict)
                } else {
                    emptySelectionView
                }
            }
            .navigationTitle("Resolve File Conflicts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Close without applying conflict resolutions")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply Resolution") {
                        viewModel.applyResolution()
                        dismiss()
                    }
                    .disabled(!viewModel.allConflictsResolved)
                    .accessibilityLabel("Apply resolution")
                    .accessibilityHint(viewModel.allConflictsResolved ? "Apply all conflict resolutions and close" : "Disabled: resolve all conflicts first")
                }

                ToolbarItemGroup(placement: .automatic) {
                    Button("Keep All Mine") {
                        viewModel.resolveAll(.keepMine)
                    }
                    .accessibilityLabel("Keep all mine")
                    .accessibilityHint("Resolve all conflicts by keeping your versions")

                    Button("Keep All Theirs") {
                        viewModel.resolveAll(.keepTheirs)
                    }
                    .accessibilityLabel("Keep all theirs")
                    .accessibilityHint("Resolve all conflicts by keeping disk versions")
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    // MARK: - Subviews

    private var conflictListView: some View {
        List(selection: $viewModel.selectedConflictID) {
            Section {
                ForEach(viewModel.conflicts) { conflict in
                    ConflictListRow(conflict: conflict)
                        .tag(conflict.id)
                }
            } header: {
                HStack {
                    Text("\(viewModel.conflicts.count) Conflicts")
                    Spacer()
                    if viewModel.allConflictsResolved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func conflictDetailView(_ conflict: FileConflictItem) -> some View {
        VStack(spacing: 0) {
            // Header
            conflictHeader(conflict)

            Divider()

            // Side-by-side diff
            HSplitView {
                // Our version
                ConflictContentView(
                    title: "My Version",
                    subtitle: viewModel.formatDate(conflict.ourModificationDate),
                    content: conflict.ourContent,
                    isSelected: conflict.resolution == .keepMine
                )

                Divider()

                // Their version
                ConflictContentView(
                    title: "Disk Version",
                    subtitle: viewModel.formatDate(conflict.theirModificationDate),
                    content: conflict.theirContent,
                    isSelected: conflict.resolution == .keepTheirs
                )
            }

            Divider()

            // Resolution buttons
            conflictActions(conflict)
        }
    }

    private func conflictHeader(_ conflict: FileConflictItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.orange)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text(conflict.fileName)
                        .font(.headline)

                    Text(conflict.url.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if conflict.resolution != .unresolved {
                    resolutionBadge(conflict.resolution)
                }
            }

            if !conflict.hasChanges {
                Label("Files have identical content", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func conflictActions(_ conflict: FileConflictItem) -> some View {
        HStack(spacing: 16) {
            Button {
                viewModel.resolve(conflict, with: .keepMine)
            } label: {
                Label("Keep My Version", systemImage: "arrow.left.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .accessibilityLabel("Keep my version")
            .accessibilityHint("Use your in-memory changes and discard external changes from disk")

            Button {
                viewModel.resolve(conflict, with: .keepTheirs)
            } label: {
                Label("Keep Disk Version", systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .accessibilityLabel("Keep disk version")
            .accessibilityHint("Use external changes from disk and discard your in-memory changes")

            Spacer()

            Button {
                viewModel.resolve(conflict, with: .viewBoth)
            } label: {
                Label("View Both", systemImage: "eye.fill")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("View both versions")
            .accessibilityHint("Create a backup and keep both versions of the file")

            if conflict.hasChanges {
                Button {
                    viewModel.showMergeEditor(for: conflict)
                } label: {
                    Label("Merge...", systemImage: "arrow.triangle.merge")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Merge changes")
                .accessibilityHint("Manually merge the conflicting changes")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func resolutionBadge(_ resolution: ConflictResolution) -> some View {
        Group {
            switch resolution {
            case .unresolved:
                EmptyView()
            case .keepMine:
                Label("Keep Mine", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            case .keepTheirs:
                Label("Keep Theirs", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.purple)
            case .viewBoth:
                Label("View Both", systemImage: "eye.fill")
                    .foregroundColor(.orange)
            case .merge:
                Label("Merged", systemImage: "arrow.triangle.merge")
                    .foregroundColor(.green)
            }
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(4)
    }

    private var emptySelectionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Select a Conflict")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Choose a file from the list to see the conflicting changes")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Conflict List Row

struct ConflictListRow: View {
    let conflict: FileConflictItem

    var body: some View {
        HStack {
            Image(systemName: conflict.resolution == .unresolved ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(conflict.resolution == .unresolved ? .orange : .green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(conflict.fileName)
                    .font(.body)

                Text(resolutionText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(conflict.fileName), \(resolutionText)")
        .accessibilityHint("Double tap to view and resolve this conflict")
    }

    private var resolutionText: String {
        switch conflict.resolution {
        case .unresolved:
            return "Needs resolution"
        case .keepMine:
            return "Keep my version"
        case .keepTheirs:
            return "Keep disk version"
        case .viewBoth:
            return "View both"
        case .merge:
            return "Merged"
        }
    }
}

// MARK: - Conflict Content View

struct ConflictContentView: View {
    let title: String
    let subtitle: String
    let content: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .blue : .primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), modified \(subtitle)")

            Divider()

            // Content
            ScrollView([.horizontal, .vertical]) {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityLabel("\(title) content")
            .accessibilityValue(content)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isSelected ? "\(title), currently selected" : title)
    }
}

// MARK: - View Model

@MainActor
class ConflictResolutionViewModel: ObservableObject {

    @Published var conflicts: [FileConflictItem]
    @Published var selectedConflictID: UUID?
    @Published var showMergeSheet = false
    @Published var mergeContent = ""

    private var currentMergeConflict: FileConflictItem?
    var onResolutionApplied: (([FileConflictItem]) -> Void)?

    init(conflicts: [FileConflictItem]) {
        self.conflicts = conflicts
        self.selectedConflictID = conflicts.first?.id
    }

    var selectedConflict: FileConflictItem? {
        conflicts.first { $0.id == selectedConflictID }
    }

    var allConflictsResolved: Bool {
        conflicts.allSatisfy { $0.resolution != .unresolved }
    }

    func resolve(_ conflict: FileConflictItem, with resolution: ConflictResolution) {
        if let index = conflicts.firstIndex(where: { $0.id == conflict.id }) {
            conflicts[index].resolution = resolution
        }
    }

    func resolveAll(_ resolution: ConflictResolution) {
        for index in conflicts.indices {
            conflicts[index].resolution = resolution
        }
    }

    func showMergeEditor(for conflict: FileConflictItem) {
        currentMergeConflict = conflict
        mergeContent = conflict.ourContent // Start with our version
        showMergeSheet = true
    }

    func applyMerge() {
        guard let conflict = currentMergeConflict,
              let index = conflicts.firstIndex(where: { $0.id == conflict.id }) else {
            return
        }

        conflicts[index].resolution = .merge(mergeContent)
        showMergeSheet = false
    }

    func applyResolution() {
        onResolutionApplied?(conflicts)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ConflictResolutionView(conflicts: [
        FileConflictItem(
            url: URL(fileURLWithPath: "/Users/test/Documents/StickyToDo/tasks/task1.md"),
            ourContent: "# Task 1\n\nMy version of the content\n\nWith some edits.",
            theirContent: "# Task 1\n\nExternal version of the content\n\nWith different edits.",
            ourModificationDate: Date().addingTimeInterval(-3600),
            theirModificationDate: Date()
        ),
        FileConflictItem(
            url: URL(fileURLWithPath: "/Users/test/Documents/StickyToDo/tasks/task2.md"),
            ourContent: "# Task 2\n\nAnother task",
            theirContent: "# Task 2\n\nAnother task modified externally",
            ourModificationDate: Date().addingTimeInterval(-7200),
            theirModificationDate: Date().addingTimeInterval(-1800)
        )
    ])
}
