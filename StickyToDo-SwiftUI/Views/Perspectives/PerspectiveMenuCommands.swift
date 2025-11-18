//
//  PerspectiveMenuCommands.swift
//  StickyToDo-SwiftUI
//
//  Menu commands and keyboard shortcuts for perspectives.
//

import SwiftUI

/// Menu commands for perspective management
///
/// Provides:
/// - ⌘⇧S: Save current view as perspective
/// - ⌘⌥P: Open perspective editor
/// - Menu items for perspective actions
struct PerspectiveMenuCommands: Commands {

    /// Callback for saving current view as perspective
    let onSavePerspective: () -> Void

    /// Callback for opening perspective editor
    let onEditPerspectives: () -> Void

    /// Callback for importing perspective
    let onImportPerspective: () -> Void

    /// Callback for exporting all perspectives
    let onExportAll: () -> Void

    var body: some Commands {
        CommandMenu("Perspectives") {
            Button("Save as Perspective...") {
                onSavePerspective()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Button("Manage Perspectives...") {
                onEditPerspectives()
            }
            .keyboardShortcut("p", modifiers: [.command, .option])

            Divider()

            Button("Import Perspective...") {
                onImportPerspective()
            }
            .keyboardShortcut("i", modifiers: [.command, .option])

            Button("Export All Perspectives...") {
                onExportAll()
            }
            .keyboardShortcut("e", modifiers: [.command, .option])
        }
    }
}

/// Environment key for perspective actions
struct PerspectiveActionsKey: EnvironmentKey {
    static let defaultValue: PerspectiveActions? = nil
}

extension EnvironmentValues {
    var perspectiveActions: PerspectiveActions? {
        get { self[PerspectiveActionsKey.self] }
        set { self[PerspectiveActionsKey.self] = newValue }
    }
}

/// Actions available for perspective management
struct PerspectiveActions {
    let save: () -> Void
    let edit: () -> Void
    let `import`: () -> Void
    let exportAll: () -> Void
}

// MARK: - Keyboard Shortcut Handler

/// View modifier that adds keyboard shortcuts for perspectives
struct PerspectiveKeyboardShortcuts: ViewModifier {

    let onSave: () -> Void
    let onEdit: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .savePerspectiveShortcut)) { _ in
                onSave()
            }
            .onReceive(NotificationCenter.default.publisher(for: .editPerspectivesShortcut)) { _ in
                onEdit()
            }
    }
}

extension View {
    /// Adds perspective keyboard shortcuts to this view
    func perspectiveKeyboardShortcuts(
        onSave: @escaping () -> Void,
        onEdit: @escaping () -> Void
    ) -> some View {
        modifier(PerspectiveKeyboardShortcuts(onSave: onSave, onEdit: onEdit))
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let savePerspectiveShortcut = Notification.Name("savePerspectiveShortcut")
    static let editPerspectivesShortcut = Notification.Name("editPerspectivesShortcut")
}

// MARK: - Preview

#Preview {
    Text("Perspective Menu Commands")
        .environment(\.perspectiveActions, PerspectiveActions(
            save: { print("Save") },
            edit: { print("Edit") },
            import: { print("Import") },
            exportAll: { print("Export All") }
        ))
}
