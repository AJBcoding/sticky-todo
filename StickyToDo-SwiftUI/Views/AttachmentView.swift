//
//  AttachmentView.swift
//  StickyToDo
//
//  View for managing task attachments.
//

import SwiftUI
import UniformTypeIdentifiers

/// View for managing attachments on a task
struct AttachmentView: View {
    @Binding var attachments: [Attachment]
    @State private var showingAddMenu = false
    @State private var showingAddLinkSheet = false
    @State private var showingAddNoteSheet = false
    @State private var selectedAttachment: Attachment?
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Attachments list or empty state
            if attachments.isEmpty {
                emptyState
            } else {
                attachmentsList
            }
        }
        .sheet(isPresented: $showingAddLinkSheet) {
            AddLinkSheet(onSave: { attachment in
                attachments.append(attachment)
            })
        }
        .sheet(isPresented: $showingAddNoteSheet) {
            AddNoteSheet(onSave: { attachment in
                attachments.append(attachment)
            })
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
        }
        .overlay(
            isDragging ? dragOverlay : nil
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Attachments")
                    .font(.headline)

                Text("\(attachments.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Menu {
                Button(action: { showingAddLinkSheet = true }) {
                    Label("Add Link", systemImage: "link")
                }

                Button(action: { showingAddNoteSheet = true }) {
                    Label("Add Note", systemImage: "note.text")
                }

                Button(action: { /* File picker */ }) {
                    Label("Add File", systemImage: "doc")
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "paperclip")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Attachments")
                .font(.title3)
                .fontWeight(.medium)

            Text("Drag and drop files, or use the + button to add links and notes")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var attachmentsList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(attachments) { attachment in
                    AttachmentRow(
                        attachment: attachment,
                        onOpen: {
                            openAttachment(attachment)
                        },
                        onDelete: {
                            deleteAttachment(attachment)
                        }
                    )
                }
            }
        }
    }

    private var dragOverlay: some View {
        ZStack {
            Color.blue.opacity(0.1)

            VStack(spacing: 16) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)

                Text("Drop files to attach")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url = url else { return }

                DispatchQueue.main.async {
                    let attachment = Attachment.fileAttachment(url: url)
                    attachments.append(attachment)
                }
            }
        }
        return true
    }

    private func openAttachment(_ attachment: Attachment) {
        if let url = attachment.url {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #else
            UIApplication.shared.open(url)
            #endif
        }
    }

    private func deleteAttachment(_ attachment: Attachment) {
        attachments.removeAll { $0.id == attachment.id }
    }
}

/// Row for displaying an attachment
struct AttachmentRow: View {
    let attachment: Attachment
    let onOpen: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: attachment.iconName)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(attachment.name)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(attachment.typeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let description = attachment.description {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Text("·")
                        .foregroundColor(.secondary)
                    Text(attachment.dateAdded, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            if isHovering {
                HStack(spacing: 12) {
                    if attachment.url != nil {
                        Button(action: onOpen) {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isHovering ? Color(.controlBackgroundColor) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if attachment.url != nil {
                onOpen()
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// Sheet for adding a link attachment
struct AddLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Attachment) -> Void

    @State private var linkName = ""
    @State private var linkURL = ""
    @State private var linkDescription = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Link")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                TextField("Link name", text: $linkName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("URL")
                    .font(.headline)
                TextField("https://example.com", text: $linkURL)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.headline)
                TextField("Description", text: $linkDescription)
                    .textFieldStyle(.roundedBorder)
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Add") {
                    if let url = URL(string: linkURL) {
                        let attachment = Attachment.linkAttachment(
                            url: url,
                            name: linkName,
                            description: linkDescription.isEmpty ? nil : linkDescription
                        )
                        onSave(attachment)
                        dismiss()
                    }
                }
                .keyboardShortcut(.return)
                .disabled(linkName.isEmpty || linkURL.isEmpty || URL(string: linkURL) == nil)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

/// Sheet for adding a note attachment
struct AddNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Attachment) -> Void

    @State private var noteName = ""
    @State private var noteText = ""
    @State private var noteDescription = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Note")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                TextField("Note name", text: $noteName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.headline)
                TextField("Description", text: $noteDescription)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Note")
                    .font(.headline)
                TextEditor(text: $noteText)
                    .font(.body)
                    .frame(minHeight: 150)
                    .border(Color.secondary.opacity(0.2))
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Add") {
                    let attachment = Attachment.noteAttachment(
                        text: noteText,
                        name: noteName,
                        description: noteDescription.isEmpty ? nil : noteDescription
                    )
                    onSave(attachment)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(noteName.isEmpty || noteText.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 450)
    }
}

// MARK: - Preview

struct AttachmentView_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentView(attachments: .constant([
            Attachment.linkAttachment(
                url: URL(string: "https://example.com")!,
                name: "Example Link",
                description: "A sample link"
            ),
            Attachment.noteAttachment(
                text: "This is a note",
                name: "Sample Note"
            )
        ]))
    }
}
