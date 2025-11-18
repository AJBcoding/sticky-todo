//
//  SettingsView.swift
//  StickyToDo
//
//  Application settings view with multiple tabs.
//

import SwiftUI

/// Settings view with tabbed interface
///
/// Features:
/// - General settings (storage location, default board)
/// - Quick capture settings (hotkey configuration)
/// - Context management (add/edit/delete)
/// - Board settings (show/hide, default layout)
/// - Advanced settings (file watching, debug mode)
struct SettingsView: View {

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)

            QuickCaptureSettingsView()
                .tabItem {
                    Label("Quick Capture", systemImage: "bolt.fill")
                }
                .tag(1)

            ContextsSettingsView()
                .tabItem {
                    Label("Contexts", systemImage: "mappin.circle")
                }
                .tag(2)

            BoardsSettingsView()
                .tabItem {
                    Label("Boards", systemImage: "square.grid.3x2")
                }
                .tag(3)

            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }
                .tag(4)
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    @EnvironmentObject var dataManager: DataManager

    @State private var showingRestartAlert = false

    var body: some View {
        Form {
            Section("Data Storage") {
                HStack {
                    TextField("Storage Location", text: Binding(
                        get: { configManager.dataDirectory.path },
                        set: { _ in }
                    ))
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)

                    Button("Choose...") {
                        chooseStorageLocation()
                    }
                }

                Text("All tasks and boards are stored in plain text markdown files")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if showingRestartAlert {
                    Text("⚠️ Restart required to use new location")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Section("Defaults") {
                Picker("Default Board on Launch", selection: $configManager.defaultBoardOnLaunch) {
                    Text("Last Used").tag(nil as String?)
                    Text("Inbox").tag("inbox" as String?)
                    Text("Next Actions").tag("next-actions" as String?)
                    Text("Flagged").tag("flagged" as String?)
                }

                HStack {
                    Text("Auto-hide Inactive Projects After")
                    TextField("Days", value: $configManager.autoHideInactiveBoardsDays, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("days")
                }
            }

            Section("Performance") {
                HStack {
                    Text("Auto-save Interval")
                    TextField("Seconds", value: $configManager.autoSaveInterval, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("seconds")
                }

                Text("Lower values save more frequently but may impact performance")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func chooseStorageLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to store your StickyToDo data"

        if panel.runModal() == .OK, let url = panel.url {
            configManager.changeDataDirectory(to: url)
            showingRestartAlert = true
        }
    }
}

// MARK: - Quick Capture Settings

struct QuickCaptureSettingsView: View {
    @EnvironmentObject var configManager: ConfigurationManager

    @State private var quickCaptureEnabled = true
    @State private var enableNaturalLanguageParsing = true
    @State private var showRecentSuggestions = true

    var body: some View {
        Form {
            Section("Global Hotkey") {
                Toggle("Enable Global Quick Capture", isOn: $quickCaptureEnabled)

                HStack {
                    Text("Hotkey")
                    Text("⌘⇧Space")
                        .font(.body.monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                        )

                    Button("Change...") {
                        changeHotkey()
                    }
                    .disabled(true) // TODO: Implement hotkey recorder
                }

                if !GlobalHotkeyManager.hasAccessibilityPermissions() {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Accessibility Permissions Required")
                                .font(.caption)
                                .fontWeight(.medium)

                            Text("Grant accessibility permissions to enable global hotkeys")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Button("Open System Preferences") {
                                GlobalHotkeyManager.requestAccessibilityPermissions()
                            }
                            .font(.caption)
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }

            Section("Natural Language Parsing") {
                Toggle("Enable Natural Language Parsing", isOn: $enableNaturalLanguageParsing)

                Text("Automatically extract metadata from text like @phone, #Project, !high")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if enableNaturalLanguageParsing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Supported Patterns:")
                            .font(.caption)
                            .fontWeight(.medium)

                        HStack {
                            Text("@context")
                                .font(.caption.monospaced())
                            Text("Sets context")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("#project")
                                .font(.caption.monospaced())
                            Text("Sets project")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("!high/!medium/!low")
                                .font(.caption.monospaced())
                            Text("Sets priority")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("tomorrow, friday")
                                .font(.caption.monospaced())
                            Text("Sets due date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("//30m, //2h")
                                .font(.caption.monospaced())
                            Text("Sets effort estimate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
            }

            Section("Suggestions") {
                Toggle("Show Recent Projects and Contexts", isOn: $showRecentSuggestions)

                Text("Display quick-select pills for recently used projects and contexts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func changeHotkey() {
        // Show hotkey recorder
        print("Change hotkey requested")
    }
}

// MARK: - Contexts Settings

struct ContextsSettingsView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    @EnvironmentObject var dataManager: DataManager

    @State private var contexts: [Context] = Context.defaults
    @State private var selectedContext: Context?
    @State private var showingAddContext = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Contexts")
                    .font(.headline)

                Spacer()

                Button(action: { showingAddContext = true }) {
                    Label("Add Context", systemImage: "plus")
                }
            }
            .padding()

            Divider()

            // Contexts list
            List(selection: $selectedContext) {
                ForEach(contexts) { context in
                    ContextRow(context: context)
                        .tag(context)
                }
                .onMove { from, to in
                    contexts.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { indices in
                    contexts.remove(atOffsets: indices)
                }
            }

            Divider()

            // Actions
            HStack {
                Button(action: {}) {
                    Label("Restore Defaults", systemImage: "arrow.counterclockwise")
                }

                Spacer()

                Button(action: { deleteSelectedContext() }) {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedContext == nil)
            }
            .padding()
        }
        .sheet(isPresented: $showingAddContext) {
            AddContextSheet(contexts: $contexts)
        }
    }

    private func deleteSelectedContext() {
        guard let context = selectedContext else { return }
        contexts.removeAll(where: { $0.id == context.id })
        selectedContext = nil
    }
}

struct ContextRow: View {
    let context: Context

    var body: some View {
        HStack {
            Text(context.icon)
                .font(.title2)

            Text(context.displayName)
                .font(.body)

            Spacer()

            Circle()
                .fill(colorForName(context.color))
                .frame(width: 20, height: 20)
        }
        .padding(.vertical, 4)
    }

    private func colorForName(_ name: String) -> Color {
        switch name.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "yellow": return .yellow
        case "pink": return .pink
        case "cyan": return .cyan
        default: return .gray
        }
    }
}

struct AddContextSheet: View {
    @Binding var contexts: [Context]
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "📍"
    @State private var color = "blue"

    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Context")
                .font(.headline)

            Form {
                TextField("Name (e.g., @computer)", text: $name)
                TextField("Icon/Emoji", text: $icon)

                Picker("Color", selection: $color) {
                    Text("Blue").tag("blue")
                    Text("Green").tag("green")
                    Text("Orange").tag("orange")
                    Text("Purple").tag("purple")
                    Text("Red").tag("red")
                    Text("Yellow").tag("yellow")
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Button("Add") {
                    let context = Context(
                        name: name.hasPrefix("@") ? name : "@\(name)",
                        icon: icon,
                        color: color,
                        order: contexts.count
                    )
                    contexts.append(context)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

// MARK: - Boards Settings

struct BoardsSettingsView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    @EnvironmentObject var dataManager: DataManager

    @State private var showInbox = true
    @State private var showNextActions = true
    @State private var showFlagged = true
    @State private var showWaiting = true
    @State private var showSomeday = true
    @State private var defaultBoardLayout = "freeform"

    var body: some View {
        Form {
            Section("Built-in Boards Visibility") {
                Toggle("📥 Inbox", isOn: $showInbox)
                Toggle("▶️ Next Actions", isOn: $showNextActions)
                Toggle("⭐ Flagged", isOn: $showFlagged)
                Toggle("⏳ Waiting For", isOn: $showWaiting)
                Toggle("💭 Someday/Maybe", isOn: $showSomeday)
            }

            Section("New Board Defaults") {
                Picker("Default Layout", selection: $defaultBoardLayout) {
                    Text("Freeform").tag("freeform")
                    Text("Kanban").tag("kanban")
                    Text("Grid").tag("grid")
                }

                Text("New boards will use this layout by default")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Sidebar Organization") {
                Text("Drag boards in the sidebar to reorder")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Advanced Settings

struct AdvancedSettingsView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    @EnvironmentObject var dataManager: DataManager

    @State private var conflictResolution = "prompt"

    var body: some View {
        Form {
            Section("File Watching") {
                Toggle("Watch for External Changes", isOn: $configManager.enableFileWatching)

                Text("Automatically reload tasks when files are modified externally")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Conflict Resolution", selection: $conflictResolution) {
                    Text("Always Prompt").tag("prompt")
                    Text("Keep Local Version").tag("local")
                    Text("Keep External Version").tag("external")
                }
            }

            Section("Debug") {
                Toggle("Enable Debug Mode", isOn: $configManager.enableLogging)

                Text("Show additional debugging information in console")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if configManager.enableLogging {
                    Button("Export Diagnostic Logs") {
                        exportLogs()
                    }

                    Button("Reset to Defaults") {
                        configManager.resetToDefaults()
                    }
                    .foregroundColor(.orange)
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Storage Format")
                    Spacer()
                    Text("Markdown + YAML")
                        .foregroundColor(.secondary)
                }

                Button("View Documentation") {
                    openDocumentation()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func exportLogs() {
        // Export diagnostic logs
        if let statistics = dataManager?.statistics {
            print("=== StickyToDo Diagnostic Information ===")
            print(statistics.description)
            print("Data Directory: \(configManager.dataDirectory.path)")
            print("File Watching: \(configManager.enableFileWatching)")
            print("Logging: \(configManager.enableLogging)")
        }
    }

    private func openDocumentation() {
        if let url = URL(string: "https://stickytodo.app/docs") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview("General Settings") {
    GeneralSettingsView()
        .frame(width: 600, height: 500)
}

#Preview("Quick Capture Settings") {
    QuickCaptureSettingsView()
        .frame(width: 600, height: 500)
}

#Preview("Contexts Settings") {
    ContextsSettingsView()
        .frame(width: 600, height: 500)
}

#Preview("Full Settings") {
    SettingsView()
}
