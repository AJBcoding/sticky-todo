//
//  AppearanceSettingsView.swift
//  StickyToDo
//
//  Appearance settings with theme mode and accent color customization.
//  Includes dark mode, true black mode, and accessibility support.
//

import SwiftUI
import StickyToDoCore

/// Appearance settings view for theme customization
///
/// Features:
/// - Theme mode selection (System, Light, Dark, True Black)
/// - Accent color picker with 11 color options
/// - Live theme preview
/// - Accessibility labels and hints
/// - OLED-friendly true black mode
struct AppearanceSettingsView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    @Environment(\.colorScheme) private var systemColorScheme

    // MARK: - Computed Properties

    private var currentTheme: ColorTheme {
        configManager.colorTheme
    }

    private var effectiveColorScheme: ColorScheme {
        switch configManager.themeMode {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark, .trueBlack:
            return .dark
        }
    }

    // MARK: - Body

    var body: some View {
        Form {
            // Theme Mode Section
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Theme Mode")
                        .font(.headline)

                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        ThemeModeRow(
                            mode: mode,
                            isSelected: configManager.themeMode == mode,
                            onSelect: { configManager.themeMode = mode }
                        )
                    }
                }
            } header: {
                Label("Appearance", systemImage: "paintbrush.fill")
            } footer: {
                Text("Choose how StickyToDo looks. System matches your macOS appearance settings.")
                    .font(.caption)
            }

            // Accent Color Section
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Accent Color")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 50), spacing: 12)
                    ], spacing: 12) {
                        ForEach(AccentColorOption.allCases, id: \.self) { color in
                            AccentColorButton(
                                color: color,
                                isSelected: configManager.accentColor == color,
                                onSelect: { configManager.accentColor = color }
                            )
                        }
                    }
                }
            } header: {
                Label("Accent Color", systemImage: "paintpalette.fill")
            } footer: {
                Text("Used for highlights, buttons, and interactive elements throughout the app.")
                    .font(.caption)
            }

            // Preview Section
            Section {
                ThemePreview(theme: currentTheme)
            } header: {
                Label("Preview", systemImage: "eye.fill")
            } footer: {
                Text("Preview how your tasks and boards will look with the current theme.")
                    .font(.caption)
            }

            // Contrast & Accessibility
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "accessibility")
                            .foregroundColor(.secondary)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Accessibility")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("All themes meet WCAG contrast requirements for readability")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if configManager.themeMode == .trueBlack {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.green)
                                .font(.caption)

                            Text("OLED-optimized for battery savings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Label("Accessibility", systemImage: "hand.raised.fill")
            }
        }
        .formStyle(.grouped)
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Appearance settings")
    }
}

// MARK: - Theme Mode Row

struct ThemeModeRow: View {
    let mode: ThemeMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: mode.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.primary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.05) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.secondary.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.displayName) theme")
        .accessibilityHint(mode.description)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Accent Color Button

struct AccentColorButton: View {
    let color: AccentColorOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.color)
                        .frame(width: 40, height: 40)

                    if isSelected {
                        Circle()
                            .strokeBorder(Color.primary, lineWidth: 3)
                            .frame(width: 50, height: 50)

                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(color.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.displayName) accent color")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Double-tap to select \(color.displayName) as accent color")
    }
}

// MARK: - Theme Preview

struct ThemePreview: View {
    let theme: ColorTheme

    var body: some View {
        VStack(spacing: 16) {
            // Preview title
            HStack {
                Text("Current Theme Preview")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)

                Spacer()

                Circle()
                    .fill(theme.accent)
                    .frame(width: 12, height: 12)

                Text(theme.isDark ? "Dark" : "Light")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }

            Divider()
                .background(theme.separator)

            // Task card preview
            VStack(spacing: 12) {
                // Sample task card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .strokeBorder(theme.accent, lineWidth: 2)
                            .frame(width: 20, height: 20)

                        Text("Sample Task")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryText)

                        Spacer()

                        Text("High")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.error.opacity(0.2))
                            .foregroundColor(theme.error)
                            .cornerRadius(4)
                    }

                    Text("This is a preview of how tasks will appear in your chosen theme.")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)

                    HStack {
                        Label("@work", systemImage: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundColor(theme.tertiaryText)

                        Label("Due today", systemImage: "calendar")
                            .font(.caption2)
                            .foregroundColor(theme.warning)
                    }
                }
                .padding(12)
                .background(theme.taskCardBackground)
                .cornerRadius(8)
                .shadow(color: theme.taskCardShadow, radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(theme.border, lineWidth: 1)
                )

                // Color swatches
                HStack(spacing: 8) {
                    ColorSwatch(label: "Success", color: theme.success)
                    ColorSwatch(label: "Warning", color: theme.warning)
                    ColorSwatch(label: "Error", color: theme.error)
                }
            }

            // Background info
            if theme.isTrueBlack {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(theme.accent)
                        .font(.caption)

                    Text("Pure black backgrounds save battery on OLED displays")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText)
                }
                .padding(8)
                .background(theme.accent.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(16)
        .background(theme.primaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Color Swatch

struct ColorSwatch: View {
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Appearance Settings") {
    AppearanceSettingsView()
        .environmentObject(ConfigurationManager.shared)
        .frame(width: 600, height: 700)
}

#Preview("Theme Mode Row - Selected") {
    ThemeModeRow(
        mode: .dark,
        isSelected: true,
        onSelect: {}
    )
    .padding()
    .frame(width: 400)
}

#Preview("Theme Mode Row - Unselected") {
    ThemeModeRow(
        mode: .light,
        isSelected: false,
        onSelect: {}
    )
    .padding()
    .frame(width: 400)
}

#Preview("Accent Color Grid") {
    VStack {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 50), spacing: 12)
        ], spacing: 12) {
            ForEach(AccentColorOption.allCases, id: \.self) { color in
                AccentColorButton(
                    color: color,
                    isSelected: color == .blue,
                    onSelect: {}
                )
            }
        }
    }
    .padding()
    .frame(width: 400)
}

#Preview("Theme Preview - Light") {
    ThemePreview(theme: .light)
        .padding()
        .frame(width: 400)
}

#Preview("Theme Preview - Dark") {
    ThemePreview(theme: .dark)
        .padding()
        .frame(width: 400)
        .preferredColorScheme(.dark)
}

#Preview("Theme Preview - True Black") {
    ThemePreview(theme: .trueBlack)
        .padding()
        .frame(width: 400)
        .preferredColorScheme(.dark)
}
