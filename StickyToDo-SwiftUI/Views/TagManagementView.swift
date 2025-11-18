//
//  TagManagementView.swift
//  StickyToDo
//
//  Tag management view for creating, editing, and organizing tags.
//

import SwiftUI

/// Tag management view for settings
struct TagManagementView: View {
    @State private var tags: [Tag] = Tag.defaultTags
    @State private var selectedTag: Tag?
    @State private var showingNewTagSheet = false
    @State private var showingEditSheet = false
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Search bar
            searchBar

            Divider()

            // Tags list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(filteredTags) { tag in
                        TagManagementRow(
                            tag: tag,
                            isSelected: selectedTag?.id == tag.id,
                            onSelect: {
                                selectedTag = tag
                            },
                            onEdit: {
                                selectedTag = tag
                                showingEditSheet = true
                            },
                            onDelete: {
                                deleteTag(tag)
                            }
                        )
                    }
                }
            }

            // Stats footer
            footer
        }
        .sheet(isPresented: $showingNewTagSheet) {
            NewTagSheet(onSave: { newTag in
                tags.append(newTag)
            })
        }
        .sheet(isPresented: $showingEditSheet) {
            if let tag = selectedTag {
                EditTagSheet(tag: tag, onSave: { updatedTag in
                    if let index = tags.firstIndex(where: { $0.id == tag.id }) {
                        tags[index] = updatedTag
                    }
                })
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tag Management")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(tags.count) tags")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showingNewTagSheet = true }) {
                Label("New Tag", systemImage: "plus")
            }
        }
        .padding()
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search tags...", text: $searchText)
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

    private var footer: some View {
        VStack(spacing: 8) {
            Divider()

            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)

                Text("Tags help organize and categorize your tasks. Click on a tag to edit it.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
        }
    }

    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return tags
        } else {
            return tags.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }

    private func deleteTag(_ tag: Tag) {
        tags.removeAll { $0.id == tag.id }
        if selectedTag?.id == tag.id {
            selectedTag = nil
        }
    }
}

/// Row for displaying a tag in the management view
struct TagManagementRow: View {
    let tag: Tag
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(Color(hex: tag.color))
                .frame(width: 12, height: 12)

            // Icon
            if let icon = tag.icon {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: tag.color))
                    .frame(width: 24)
            }

            // Tag name
            Text(tag.name)
                .font(.body)

            Spacer()

            // Tag pill preview
            TagPill(tag: tag, isSelected: false, isRemovable: false)

            // Actions (shown on hover)
            if isHovering || isSelected {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

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
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// Sheet for editing an existing tag
struct EditTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    let tag: Tag
    let onSave: (Tag) -> Void

    @State private var tagName: String
    @State private var tagColor: String
    @State private var selectedIcon: String?

    init(tag: Tag, onSave: @escaping (Tag) -> Void) {
        self.tag = tag
        self.onSave = onSave
        _tagName = State(initialValue: tag.name)
        _tagColor = State(initialValue: tag.color)
        _selectedIcon = State(initialValue: tag.icon)
    }

    private let colorOptions = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#5AC8FA", "#007AFF", "#5856D6", "#AF52DE",
        "#FF2D55", "#A2845E"
    ]

    private let iconOptions = [
        "star.fill", "flag.fill", "exclamationmark.triangle.fill",
        "bolt.fill", "heart.fill", "tag.fill",
        "bookmark.fill", "checkmark.circle.fill", "clock.fill",
        "calendar", "person.fill", "briefcase.fill",
        "house.fill", "cart.fill", "envelope.fill"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Tag")
                .font(.title2)
                .fontWeight(.bold)

            // Tag name
            VStack(alignment: .leading, spacing: 8) {
                Text("Tag Name")
                    .font(.headline)
                TextField("Enter tag name", text: $tagName)
                    .textFieldStyle(.roundedBorder)
            }

            // Color picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(colorOptions, id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.primary, lineWidth: tagColor == color ? 3 : 0)
                            )
                            .onTapGesture {
                                tagColor = color
                            }
                    }
                }
            }

            // Icon picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon (Optional)")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    // None option
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedIcon == nil ? Color.blue.opacity(0.2) : Color.clear)
                            .frame(width: 40, height: 40)

                        Image(systemName: "xmark")
                            .foregroundColor(selectedIcon == nil ? .blue : .secondary)
                    }
                    .onTapGesture {
                        selectedIcon = nil
                    }

                    ForEach(iconOptions, id: \.self) { icon in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                .frame(width: 40, height: 40)

                            Image(systemName: icon)
                                .foregroundColor(selectedIcon == icon ? .blue : .primary)
                        }
                        .onTapGesture {
                            selectedIcon = icon
                        }
                    }
                }
            }

            // Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.headline)

                TagPill(
                    tag: Tag(name: tagName.isEmpty ? "Tag Name" : tagName, color: tagColor, icon: selectedIcon),
                    isSelected: false,
                    isRemovable: false
                )
            }

            Spacer()

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Save") {
                    var updatedTag = tag
                    updatedTag.name = tagName
                    updatedTag.color = tagColor
                    updatedTag.icon = selectedIcon
                    updatedTag.touch()
                    onSave(updatedTag)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(tagName.isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 600)
    }
}

// MARK: - Preview

struct TagManagementView_Previews: PreviewProvider {
    static var previews: some View {
        TagManagementView()
    }
}
