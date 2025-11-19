//
//  KeyboardShortcutsWindow.swift
//  StickyToDo-SwiftUI
//
//  Comprehensive keyboard shortcuts reference window.
//  Shows all available shortcuts organized by category.
//

import SwiftUI
import Carbon.HIToolbox
import StickyToDoCore

/// Comprehensive keyboard shortcuts reference window
///
/// Displays all available keyboard shortcuts in the app, organized by:
/// - General shortcuts
/// - Task management
/// - Navigation
/// - Views
/// - Quick capture (customizable)
struct KeyboardShortcutsWindow: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var configManager: ConfigurationManager

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedCategory: ShortcutCategory?

    // MARK: - Computed Properties

    private var currentQuickCaptureShortcut: String {
        var parts: [String] = []

        let modifiers = configManager.quickCaptureHotkeyModifiers
        if modifiers & 0x001 != 0 { parts.append("⌃") }
        if modifiers & 0x020 != 0 { parts.append("⌥") }
        if modifiers & 0x008 != 0 { parts.append("⇧") }
        if modifiers & 0x100 != 0 { parts.append("⌘") }

        let keyCode = configManager.quickCaptureHotkey
        parts.append(keyNameForCode(keyCode))

        return parts.joined()
    }

    private var allCategories: [ShortcutCategory] {
        return [
            generalCategory,
            taskManagementCategory,
            navigationCategory,
            viewsCategory,
            quickCaptureCategory
        ]
    }

    private var filteredCategories: [ShortcutCategory] {
        guard !searchText.isEmpty else { return allCategories }

        return allCategories.map { category in
            let filteredShortcuts = category.shortcuts.filter { shortcut in
                shortcut.description.localizedCaseInsensitiveContains(searchText) ||
                shortcut.keys.localizedCaseInsensitiveContains(searchText)
            }

            return ShortcutCategory(
                name: category.name,
                icon: category.icon,
                shortcuts: filteredShortcuts
            )
        }.filter { !$0.shortcuts.isEmpty }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Search bar
            searchSection

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(filteredCategories, id: \.name) { category in
                        categorySection(category)
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer
            footerSection
        }
        .frame(width: 700, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - View Components

    private var headerSection: some View {
        HStack {
            Image(systemName: "keyboard")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("Keyboard Shortcuts")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(20)
    }

    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search shortcuts...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private func categorySection(_ category: ShortcutCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(.accentColor)
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // Shortcuts list
            VStack(spacing: 8) {
                ForEach(category.shortcuts, id: \.description) { shortcut in
                    shortcutRow(shortcut)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shortcutRow(_ shortcut: KeyboardShortcutInfo) -> some View {
        HStack {
            Text(shortcut.description)
                .font(.body)

            Spacer()

            HStack(spacing: 4) {
                if shortcut.customizable {
                    Image(systemName: "gear")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(shortcut.keys)
                    .font(.body.monospaced())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
            }
        }
        .padding(.vertical, 4)
    }

    private var footerSection: some View {
        HStack {
            Text("💡 Tip: Press ⌘? to show this window anytime")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Settings") {
                openSettings()
            }
            .accessibilityLabel("Open Settings")
        }
        .padding(16)
    }

    // MARK: - Shortcut Categories

    private var generalCategory: ShortcutCategory {
        ShortcutCategory(name: "General", icon: "command", shortcuts: [
            KeyboardShortcutInfo(description: "New task", keys: "⌘N"),
            KeyboardShortcutInfo(description: "Save", keys: "⌘S"),
            KeyboardShortcutInfo(description: "Find", keys: "⌘F"),
            KeyboardShortcutInfo(description: "Show keyboard shortcuts", keys: "⌘?"),
            KeyboardShortcutInfo(description: "Open settings", keys: "⌘,"),
            KeyboardShortcutInfo(description: "Close window", keys: "⌘W"),
            KeyboardShortcutInfo(description: "Quit application", keys: "⌘Q"),
        ])
    }

    private var taskManagementCategory: ShortcutCategory {
        ShortcutCategory(name: "Task Management", icon: "checkmark.circle", shortcuts: [
            KeyboardShortcutInfo(description: "Create new task", keys: "Enter"),
            KeyboardShortcutInfo(description: "Complete task", keys: "⌘↩"),
            KeyboardShortcutInfo(description: "Delete task", keys: "⌘⌫"),
            KeyboardShortcutInfo(description: "Edit task", keys: "E"),
            KeyboardShortcutInfo(description: "Duplicate task", keys: "⌘D"),
            KeyboardShortcutInfo(description: "Flag/unflag task", keys: "⌘⇧F"),
            KeyboardShortcutInfo(description: "Set priority high", keys: "⌘1"),
            KeyboardShortcutInfo(description: "Set priority medium", keys: "⌘2"),
            KeyboardShortcutInfo(description: "Set priority low", keys: "⌘3"),
            KeyboardShortcutInfo(description: "Set due date", keys: "⌘T"),
            KeyboardShortcutInfo(description: "Add note", keys: "⌘⇧N"),
        ])
    }

    private var navigationCategory: ShortcutCategory {
        ShortcutCategory(name: "Navigation", icon: "arrow.left.arrow.right", shortcuts: [
            KeyboardShortcutInfo(description: "Next task", keys: "J or ↓"),
            KeyboardShortcutInfo(description: "Previous task", keys: "K or ↑"),
            KeyboardShortcutInfo(description: "Go to Inbox", keys: "⌘1"),
            KeyboardShortcutInfo(description: "Go to Next Actions", keys: "⌘2"),
            KeyboardShortcutInfo(description: "Go to Flagged", keys: "⌘3"),
            KeyboardShortcutInfo(description: "Go to Waiting", keys: "⌘4"),
            KeyboardShortcutInfo(description: "Go to Someday", keys: "⌘5"),
            KeyboardShortcutInfo(description: "Go to Projects", keys: "⌘6"),
            KeyboardShortcutInfo(description: "Go to Contexts", keys: "⌘7"),
            KeyboardShortcutInfo(description: "Toggle sidebar", keys: "⌘⌥S"),
            KeyboardShortcutInfo(description: "Toggle inspector", keys: "⌘⌥I"),
        ])
    }

    private var viewsCategory: ShortcutCategory {
        ShortcutCategory(name: "Views", icon: "sidebar.left", shortcuts: [
            KeyboardShortcutInfo(description: "Switch to list view", keys: "⌘L"),
            KeyboardShortcutInfo(description: "Switch to board view", keys: "⌘B"),
            KeyboardShortcutInfo(description: "Switch to calendar view", keys: "⌘K"),
            KeyboardShortcutInfo(description: "Group by project", keys: "⌘⇧P"),
            KeyboardShortcutInfo(description: "Group by context", keys: "⌘⇧C"),
            KeyboardShortcutInfo(description: "Group by priority", keys: "⌘⇧R"),
            KeyboardShortcutInfo(description: "Show completed tasks", keys: "⌘⇧H"),
            KeyboardShortcutInfo(description: "Zoom in", keys: "⌘+"),
            KeyboardShortcutInfo(description: "Zoom out", keys: "⌘-"),
            KeyboardShortcutInfo(description: "Reset zoom", keys: "⌘0"),
        ])
    }

    private var quickCaptureCategory: ShortcutCategory {
        ShortcutCategory(name: "Quick Capture", icon: "bolt.fill", shortcuts: [
            KeyboardShortcutInfo(
                description: "Quick capture (global)",
                keys: currentQuickCaptureShortcut,
                customizable: true
            ),
            KeyboardShortcutInfo(description: "Quick capture (in-app)", keys: "⌘⇧N"),
            KeyboardShortcutInfo(description: "Quick capture with clipboard", keys: "⌘⇧V"),
        ])
    }

    // MARK: - Actions

    private func openSettings() {
        // Open settings window
        NotificationCenter.default.post(name: NSNotification.Name("showSettings"), object: nil)
        dismiss()
    }

    // MARK: - Helpers

    private func keyNameForCode(_ keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Escape: return "⎋"
        default:
            // Try to get the character representation
            let keyboard = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
            let layoutData = TISGetInputSourceProperty(keyboard, kTISPropertyUnicodeKeyLayoutData)

            if let layoutData = layoutData {
                let layout = unsafeBitCast(layoutData, to: CFData.self)
                let dataPtr = CFDataGetBytePtr(layout)
                let keyboardLayout = unsafeBitCast(dataPtr, to: UnsafePointer<UCKeyboardLayout>.self)

                var deadKeyState: UInt32 = 0
                var length = 0
                var chars = [UniChar](repeating: 0, count: 4)

                UCKeyTranslate(
                    keyboardLayout,
                    keyCode,
                    UInt16(kUCKeyActionDisplay),
                    0,
                    UInt32(LMGetKbdType()),
                    UInt32(kUCKeyTranslateNoDeadKeysMask),
                    &deadKeyState,
                    4,
                    &length,
                    &chars
                )

                if length > 0 {
                    return String(utf16CodeUnits: chars, count: length).uppercased()
                }
            }

            return "Key(\(keyCode))"
        }
    }
}

// MARK: - Models

/// A category of keyboard shortcuts
private struct ShortcutCategory {
    let name: String
    let icon: String
    let shortcuts: [KeyboardShortcutInfo]
}

/// Information about a single keyboard shortcut
private struct KeyboardShortcutInfo {
    let description: String
    let keys: String
    var customizable: Bool = false
}

// MARK: - Preview

#Preview("Keyboard Shortcuts Window") {
    KeyboardShortcutsWindow()
        .environmentObject(ConfigurationManager.shared)
}
