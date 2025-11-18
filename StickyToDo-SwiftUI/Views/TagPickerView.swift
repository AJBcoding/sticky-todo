//
//  TagPickerView.swift
//  StickyToDo
//
//  Tag picker for selecting and managing tags on tasks.
//

import SwiftUI

/// Tag picker view for selecting tags
struct TagPickerView: View {
    @Binding var selectedTags: [Tag]
    @State private var availableTags: [Tag] = Tag.defaultTags
    @State private var showingNewTagSheet = false
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            Divider()

            // Selected tags section
            if !selectedTags.isEmpty {
                selectedTagsSection
                Divider()
            }

            // Available tags
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(filteredTags) { tag in
                        TagRow(
                            tag: tag,
                            isSelected: selectedTags.contains(tag),
                            onToggle: {
                                toggleTag(tag)
                            }
                        )
                    }
                }
                .padding()
            }

            Divider()

            // Add new tag button
            Button(action: { showingNewTagSheet = true }) {
                Label("Create New Tag", systemImage: "plus.circle.fill")
                    .font(.body)
            }
            .buttonStyle(.borderless)
            .padding()
        }
        .frame(minWidth: 300, minHeight: 400)
        .sheet(isPresented: $showingNewTagSheet) {
            NewTagSheet(onSave: { newTag in
                availableTags.append(newTag)
                selectedTags.append(newTag)
            })
        }
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

    private var selectedTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Tags")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)

            FlowLayout(spacing: 8) {
                ForEach(selectedTags) { tag in
                    TagPill(tag: tag, isSelected: true, isRemovable: true) {
                        toggleTag(tag)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return availableTags
        } else {
            return availableTags.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }

    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

/// Individual tag row in the picker
struct TagRow: View {
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                // Icon
                if let icon = tag.icon {
                    Image(systemName: icon)
                        .foregroundColor(Color(hex: tag.color))
                        .frame(width: 20)
                }

                // Tag name
                Text(tag.name)
                    .font(.body)

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

/// Tag pill for displaying tags
struct TagPill: View {
    let tag: Tag
    let isSelected: Bool
    let isRemovable: Bool
    let onTap: () -> Void

    init(tag: Tag, isSelected: Bool = false, isRemovable: Bool = false, onTap: @escaping () -> Void = {}) {
        self.tag = tag
        self.isSelected = isSelected
        self.isRemovable = isRemovable
        self.onTap = onTap
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon = tag.icon {
                Image(systemName: icon)
                    .font(.caption)
            }

            Text(tag.name)
                .font(.caption)
                .fontWeight(.medium)

            if isRemovable {
                Button(action: onTap) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(hex: tag.color))
        .foregroundColor(.white)
        .cornerRadius(12)
        .onTapGesture {
            if !isRemovable {
                onTap()
            }
        }
    }
}

/// Sheet for creating a new tag
struct NewTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Tag) -> Void

    @State private var tagName = ""
    @State private var tagColor = "#007AFF"
    @State private var selectedIcon: String? = nil

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
            Text("Create New Tag")
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

                Button("Create") {
                    let newTag = Tag(
                        name: tagName,
                        color: tagColor,
                        icon: selectedIcon
                    )
                    onSave(newTag)
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

/// Flow layout for tags that wraps to multiple lines
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

struct TagPickerView_Previews: PreviewProvider {
    static var previews: some View {
        TagPickerView(selectedTags: .constant([]))
    }
}
