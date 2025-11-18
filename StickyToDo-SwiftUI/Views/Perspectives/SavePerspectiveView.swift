//
//  SavePerspectiveView.swift
//  StickyToDo-SwiftUI
//
//  Dialog for saving current filter state as a new perspective.
//

import SwiftUI

/// View for creating a new smart perspective from current filter state
///
/// Features:
/// - Name and description input
/// - Icon picker (emoji)
/// - Color picker
/// - Preview of filter rules
/// - Save/Cancel actions
struct SavePerspectiveView: View {

    // MARK: - Properties

    /// Current filter rules to save
    let rules: [FilterRule]

    /// Current filter logic
    let logic: FilterLogic

    /// Current grouping option
    let groupBy: GroupBy

    /// Current sorting option
    let sortBy: SortBy

    /// Current sort direction
    let sortDirection: SortDirection

    /// Show completed tasks setting
    let showCompleted: Bool

    /// Show deferred tasks setting
    let showDeferred: Bool

    /// Callback when perspective is saved
    let onSave: (SmartPerspective) -> Void

    /// Callback when cancelled
    let onCancel: () -> Void

    // MARK: - State

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var icon: String = "⭐"
    @State private var color: String = "#007AFF"
    @State private var showIconPicker = false

    /// Common emoji icons for perspectives
    private let commonIcons = [
        "⭐", "🎯", "🔥", "💡", "✅", "📌", "🚀",
        "⚡", "💪", "🎨", "📊", "🔍", "📝", "⏰",
        "🌟", "🎓", "🏆", "💼", "📱", "💻", "🏠"
    ]

    /// Common colors for perspectives
    private let commonColors = [
        ("Blue", "#007AFF"),
        ("Purple", "#5856D6"),
        ("Pink", "#FF2D55"),
        ("Red", "#FF3B30"),
        ("Orange", "#FF9500"),
        ("Yellow", "#FFCC00"),
        ("Green", "#34C759"),
        ("Teal", "#5AC8FA"),
        ("Indigo", "#5856D6"),
        ("Gray", "#8E8E93")
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Save as Perspective")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    savePerspective()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section("Details") {
                    // Name
                    TextField("Perspective Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    // Description
                    TextField("Description (optional)", text: $description)
                        .textFieldStyle(.roundedBorder)

                    // Icon and Color
                    HStack {
                        // Icon
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Icon")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button {
                                showIconPicker.toggle()
                            } label: {
                                Text(icon)
                                    .font(.largeTitle)
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        // Color
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Color")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                ForEach(commonColors.prefix(5), id: \.1) { colorName, colorHex in
                                    Button {
                                        color = colorHex
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: colorHex))
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(Color.primary.opacity(0.3), lineWidth: color == colorHex ? 2 : 0)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                Section("Filter Configuration") {
                    // Rules summary
                    if rules.isEmpty {
                        Text("No filter rules")
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(rules) { rule in
                                HStack {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .foregroundColor(.secondary)

                                    Text(ruleDescription(rule))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // Logic
                    HStack {
                        Text("Logic:")
                            .foregroundColor(.secondary)
                        Text(logic == .and ? "Match ALL rules" : "Match ANY rule")
                            .fontWeight(.medium)
                    }
                    .font(.caption)

                    // Grouping
                    HStack {
                        Text("Group by:")
                            .foregroundColor(.secondary)
                        Text(groupBy.displayName)
                            .fontWeight(.medium)
                    }
                    .font(.caption)

                    // Sorting
                    HStack {
                        Text("Sort by:")
                            .foregroundColor(.secondary)
                        Text("\(sortBy.displayName) (\(sortDirection == .ascending ? "Ascending" : "Descending"))")
                            .fontWeight(.medium)
                    }
                    .font(.caption)

                    // Visibility
                    HStack {
                        Text("Show completed:")
                            .foregroundColor(.secondary)
                        Text(showCompleted ? "Yes" : "No")
                            .fontWeight(.medium)
                    }
                    .font(.caption)

                    HStack {
                        Text("Show deferred:")
                            .foregroundColor(.secondary)
                        Text(showDeferred ? "Yes" : "No")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 600)
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(selectedIcon: $icon, icons: commonIcons)
        }
    }

    // MARK: - Helpers

    private func ruleDescription(_ rule: FilterRule) -> String {
        let property = rule.property.displayName
        let op = rule.operatorType.displayName
        let value = valueDescription(rule.value)
        return "\(property) \(op) \(value)"
    }

    private func valueDescription(_ value: FilterValue) -> String {
        switch value {
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return "\(num)"
        case .date(let date):
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        case .boolean(let bool):
            return bool ? "true" : "false"
        case .dateRange(let range):
            return range.displayName
        case .stringArray(let arr):
            return arr.joined(separator: ", ")
        }
    }

    private func savePerspective() {
        let perspective = SmartPerspective(
            name: name,
            description: description.isEmpty ? nil : description,
            rules: rules,
            logic: logic,
            groupBy: groupBy,
            sortBy: sortBy,
            sortDirection: sortDirection,
            showCompleted: showCompleted,
            showDeferred: showDeferred,
            icon: icon,
            color: color,
            isBuiltIn: false
        )

        onSave(perspective)
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Binding var selectedIcon: String
    let icons: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Choose Icon")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            Text(icon)
                                .font(.largeTitle)
                                .frame(width: 60, height: 60)
                                .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 500)
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

#Preview("Save Perspective") {
    SavePerspectiveView(
        rules: [
            FilterRule(
                property: .status,
                operatorType: .equals,
                value: .string("nextAction")
            ),
            FilterRule(
                property: .priority,
                operatorType: .equals,
                value: .string("high")
            )
        ],
        logic: .and,
        groupBy: .context,
        sortBy: .priority,
        sortDirection: .descending,
        showCompleted: false,
        showDeferred: false,
        onSave: { perspective in
            print("Saved: \(perspective.name)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
