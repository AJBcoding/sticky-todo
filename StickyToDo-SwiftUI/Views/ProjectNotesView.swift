//
//  ProjectNotesView.swift
//  StickyToDo
//
//  Project notes view with markdown editor.
//

import SwiftUI

/// Project notes view with markdown support
struct ProjectNotesView: View {
    let projectName: String
    @State private var notes: [ProjectNote] = []
    @State private var selectedNote: ProjectNote?
    @State private var showingNewNoteSheet = false
    @State private var showingTemplateMenu = false
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            // Notes list sidebar
            notesList
                .frame(minWidth: 250, maxWidth: 350)

            // Editor or empty state
            if let note = selectedNote {
                NoteEditorView(note: binding(for: note))
            } else {
                emptyState
            }
        }
    }

    private var notesList: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Search bar
            searchBar

            Divider()

            // Notes
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(filteredNotes) { note in
                        NoteListRow(
                            note: note,
                            isSelected: selectedNote?.id == note.id,
                            onSelect: {
                                selectedNote = note
                            }
                        )
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showingNewNoteSheet = true }) {
                        Label("Blank Note", systemImage: "doc")
                    }

                    Divider()

                    Button(action: { createFromTemplate(.projectOverview(for: projectName)) }) {
                        Label("Project Overview", systemImage: "doc.text")
                    }

                    Button(action: { createFromTemplate(.meetingNotes(for: projectName)) }) {
                        Label("Meeting Notes", systemImage: "person.3")
                    }

                    Button(action: { createFromTemplate(.decisionsLog(for: projectName)) }) {
                        Label("Decisions Log", systemImage: "list.bullet.clipboard")
                    }

                    Button(action: { createFromTemplate(.resources(for: projectName)) }) {
                        Label("Resources", systemImage: "folder")
                    }
                } label: {
                    Label("New Note", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            NewNoteSheet(projectName: projectName, onSave: { note in
                notes.append(note)
                selectedNote = note
            })
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes")
                .font(.headline)

            Text(projectName)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(notes.count) notes")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search notes...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.textBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Note Selected")
                .font(.title3)
                .fontWeight(.medium)

            Text("Select a note from the sidebar or create a new one")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredNotes: [ProjectNote] {
        if searchText.isEmpty {
            return notes.sorted { $0.modified > $1.modified }
        } else {
            return notes
                .filter { $0.matchesSearch(searchText) }
                .sorted { $0.modified > $1.modified }
        }
    }

    private func binding(for note: ProjectNote) -> Binding<ProjectNote> {
        Binding(
            get: {
                notes.first { $0.id == note.id } ?? note
            },
            set: { newValue in
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    notes[index] = newValue
                }
            }
        )
    }

    private func createFromTemplate(_ template: ProjectNote) {
        notes.append(template)
        selectedNote = template
    }
}

/// Row for displaying a note in the list
struct NoteListRow: View {
    let note: ProjectNote
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(note.displayTitle)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(2)

                // Metadata
                HStack(spacing: 8) {
                    Text(note.modified, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if note.hasContent {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text("\(note.estimatedReadingTime) min read")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Tags
                if note.hasTags {
                    FlowLayout(spacing: 4) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Note editor view with markdown support
struct NoteEditorView: View {
    @Binding var note: ProjectNote
    @State private var isEditingTags = false
    @State private var newTag = ""

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Editor
            TextEditor(text: Binding(
                get: { note.content },
                set: { newValue in
                    note.content = newValue
                    note.touch()
                }
            ))
            .font(.system(.body, design: .monospaced))
            .padding()
        }
    }

    private var toolbar: some View {
        HStack {
            // Title editor
            TextField("Note Title", text: Binding(
                get: { note.title ?? "" },
                set: { newValue in
                    note.title = newValue.isEmpty ? nil : newValue
                    note.touch()
                }
            ))
            .textFieldStyle(.plain)
            .font(.title3)
            .fontWeight(.bold)

            Spacer()

            // Tags
            if !note.tags.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(note.tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)

                            Button(action: { removeTag(tag) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }

            // Add tag
            Button(action: { isEditingTags.toggle() }) {
                Image(systemName: "tag")
            }
            .popover(isPresented: $isEditingTags) {
                VStack(spacing: 12) {
                    Text("Add Tag")
                        .font(.headline)

                    HStack {
                        TextField("Tag name", text: $newTag)
                            .textFieldStyle(.roundedBorder)

                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newTag.isEmpty)
                    }
                }
                .padding()
                .frame(width: 250)
            }

            // Info
            Menu {
                Text("Created: \(note.created.formatted())")
                Text("Modified: \(note.modified.formatted())")
                Text("Characters: \(note.characterCount)")
                Text("Reading time: \(note.estimatedReadingTime) min")
            } label: {
                Image(systemName: "info.circle")
            }
        }
        .padding()
    }

    private func addTag() {
        guard !newTag.isEmpty else { return }
        note.addTag(newTag)
        newTag = ""
    }

    private func removeTag(_ tag: String) {
        note.removeTag(tag)
    }
}

/// Sheet for creating a new note
struct NewNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let projectName: String
    let onSave: (ProjectNote) -> Void

    @State private var noteTitle = ""
    @State private var noteContent = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("New Note")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                TextField("Note title", text: $noteTitle)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.headline)
                TextEditor(text: $noteContent)
                    .font(.body)
                    .frame(minHeight: 200)
                    .border(Color.secondary.opacity(0.2))
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Create") {
                    let note = ProjectNote(
                        projectName: projectName,
                        content: noteContent,
                        title: noteTitle
                    )
                    onSave(note)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(noteTitle.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 450)
    }
}

// MARK: - Markdown Toolbar

struct MarkdownToolbar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 16) {
            Button(action: { insertMarkdown("**", "**") }) {
                Image(systemName: "bold")
            }
            .help("Bold")

            Button(action: { insertMarkdown("*", "*") }) {
                Image(systemName: "italic")
            }
            .help("Italic")

            Button(action: { insertMarkdown("[", "](url)") }) {
                Image(systemName: "link")
            }
            .help("Link")

            Button(action: { insertMarkdown("# ", "") }) {
                Image(systemName: "textformat.size")
            }
            .help("Heading")

            Button(action: { insertMarkdown("- ", "") }) {
                Image(systemName: "list.bullet")
            }
            .help("List")

            Button(action: { insertMarkdown("```\n", "\n```") }) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
            }
            .help("Code Block")

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func insertMarkdown(_ prefix: String, _ suffix: String) {
        text += prefix + suffix
    }
}

// MARK: - Preview

struct ProjectNotesView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectNotesView(projectName: "Example Project")
    }
}
