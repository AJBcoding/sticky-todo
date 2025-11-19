//
//  SettingsView.swift
//  StickyToDo
//
//  Application settings view with multiple tabs.
//

import SwiftUI
import Carbon.HIToolbox
import StickyToDoCore

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
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }
                .tag(0)
                .accessibilityLabel("Appearance settings")
                .accessibilityHint("Customize theme, colors, and dark mode")

            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(1)
                .accessibilityLabel("General settings")
                .accessibilityHint("Configure general application settings")

            QuickCaptureSettingsView()
                .tabItem {
                    Label("Quick Capture", systemImage: "bolt.fill")
                }
                .tag(2)
                .accessibilityLabel("Quick Capture settings")
                .accessibilityHint("Configure quick task capture and hotkeys")

            ContextsSettingsView()
                .tabItem {
                    Label("Contexts", systemImage: "mappin.circle")
                }
                .tag(3)
                .accessibilityLabel("Contexts settings")
                .accessibilityHint("Manage task contexts")

            BoardsSettingsView()
                .tabItem {
                    Label("Boards", systemImage: "square.grid.3x2")
                }
                .tag(4)
                .accessibilityLabel("Boards settings")
                .accessibilityHint("Configure board visibility and defaults")

            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }
                .tag(5)
                .accessibilityLabel("Advanced settings")
                .accessibilityHint("Configure advanced options and debug settings")
        }
        .frame(width: 600, height: 700)
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
                    .accessibilityLabel("Choose storage location")
                    .accessibilityHint("Select a different directory for storing task data")
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
                .accessibilityLabel("Default board on launch")
                .accessibilityHint("Choose which board to show when the app starts")

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
    @State private var showingHotkeyRecorder = false

    private var currentHotkeyDisplay: String {
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

    var body: some View {
        Form {
            Section("Global Hotkey") {
                Toggle("Enable Global Quick Capture", isOn: $quickCaptureEnabled)

                HStack {
                    Text("Hotkey")
                    Text(currentHotkeyDisplay)
                        .font(.body.monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                        )

                    Button("Change...") {
                        showingHotkeyRecorder = true
                    }
                    .accessibilityLabel("Change hotkey")
                    .accessibilityHint("Opens the hotkey recorder to set a custom keyboard shortcut")
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
        .sheet(isPresented: $showingHotkeyRecorder) {
            HotkeyRecorderView()
                .environmentObject(configManager)
        }
    }

    private func keyNameForCode(_ keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Escape: return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        case kVK_F1...kVK_F20:
            return "F\(Int(keyCode) - kVK_F1 + 1)"
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
                .accessibilityLabel("Add new context")
                .accessibilityHint("Double-tap to create a new context")
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
                .accessibilityLabel("Restore default contexts")
                .accessibilityHint("Reset contexts to default values")

                Spacer()

                Button(action: { deleteSelectedContext() }) {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedContext == nil)
                .accessibilityLabel("Delete selected context")
                .accessibilityHint("Remove the currently selected context")
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

// MARK: - Hotkey Recorder

/// View for recording keyboard shortcuts
struct HotkeyRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var configManager: ConfigurationManager

    @State private var isRecording = false
    @State private var recordedKeyCode: UInt16?
    @State private var recordedModifiers: NSEvent.ModifierFlags = []
    @State private var conflictWarning: String?
    @State private var eventMonitor: Any?

    private var hasValidShortcut: Bool {
        recordedKeyCode != nil && !recordedModifiers.isEmpty
    }

    private var displayString: String {
        guard let keyCode = recordedKeyCode else {
            return "Press keys..."
        }

        var parts: [String] = []

        if recordedModifiers.contains(.control) { parts.append("⌃") }
        if recordedModifiers.contains(.option) { parts.append("⌥") }
        if recordedModifiers.contains(.shift) { parts.append("⇧") }
        if recordedModifiers.contains(.command) { parts.append("⌘") }

        parts.append(keyNameForCode(keyCode))

        return parts.joined()
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Record Keyboard Shortcut")
                    .font(.headline)

                Text("Click 'Start Recording' and press your desired key combination")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Recorder display
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isRecording ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
                        .frame(height: 80)

                    Text(displayString)
                        .font(.title2.monospaced())
                        .foregroundColor(isRecording ? .blue : .primary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isRecording ? Color.blue : Color.clear, lineWidth: 2)
                )

                if isRecording {
                    HStack {
                        Image(systemName: "circlebadge.fill")
                            .foregroundColor(.red)
                        Text("Recording... Press your shortcut")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(isRecording ? "Stop Recording" : "Start Recording") {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }

            // Conflict warning
            if let warning = conflictWarning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(warning)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            // Requirements
            VStack(alignment: .leading, spacing: 8) {
                Text("Requirements:")
                    .font(.caption)
                    .fontWeight(.medium)

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(recordedModifiers.isEmpty ? .secondary : .green)
                        .font(.caption)
                    Text("At least one modifier key (⌘, ⌥, ⌃, or ⇧)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(recordedKeyCode == nil ? .secondary : .green)
                        .font(.caption)
                    Text("One regular key or special key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.05))
            )

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    stopRecording()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveHotkey()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasValidShortcut)
            }
        }
        .padding(24)
        .frame(width: 450, height: 450)
        .onDisappear {
            stopRecording()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hotkey recorder")
        .accessibilityHint("Record a new keyboard shortcut for quick capture")
    }

    // MARK: - Recording

    private func startRecording() {
        isRecording = true
        conflictWarning = nil
        recordedKeyCode = nil
        recordedModifiers = []

        // Install event monitor
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [self] event in
            handleKeyEvent(event)
            return nil // Consume the event
        }
    }

    private func stopRecording() {
        isRecording = false

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        if event.type == .flagsChanged {
            // Update modifier flags
            recordedModifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        } else if event.type == .keyDown {
            // Capture the key
            recordedKeyCode = event.keyCode
            recordedModifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])

            // Check for conflicts
            checkForConflicts()

            // Stop recording automatically after capturing a key
            stopRecording()
        }
    }

    // MARK: - Validation

    private func checkForConflicts() {
        guard let keyCode = recordedKeyCode else { return }

        // Define common system shortcuts to warn about
        let systemShortcuts: [(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, description: String)] = [
            (UInt16(kVK_Space), [.command], "Spotlight"),
            (UInt16(kVK_Space), [.command, .option], "Spotlight Finder"),
            (UInt16(kVK_Tab), [.command], "App Switcher"),
            (UInt16(kVK_ANSI_Q), [.command], "Quit Application"),
            (UInt16(kVK_ANSI_W), [.command], "Close Window"),
            (UInt16(kVK_ANSI_H), [.command], "Hide Window"),
            (UInt16(kVK_ANSI_M), [.command], "Minimize Window"),
            (UInt16(kVK_ANSI_C), [.command], "Copy"),
            (UInt16(kVK_ANSI_V), [.command], "Paste"),
            (UInt16(kVK_ANSI_X), [.command], "Cut"),
            (UInt16(kVK_ANSI_Z), [.command], "Undo"),
            (UInt16(kVK_ANSI_A), [.command], "Select All"),
            (UInt16(kVK_ANSI_S), [.command], "Save"),
            (UInt16(kVK_ANSI_P), [.command], "Print"),
            (UInt16(kVK_ANSI_F), [.command], "Find"),
        ]

        for shortcut in systemShortcuts {
            if shortcut.keyCode == keyCode && shortcut.modifiers == recordedModifiers {
                conflictWarning = "⚠️ This shortcut conflicts with system '\(shortcut.description)' command"
                return
            }
        }

        // Check if modifiers are sufficient (need at least one)
        if recordedModifiers.isEmpty {
            conflictWarning = "⚠️ You must use at least one modifier key (⌘, ⌥, ⌃, or ⇧)"
            return
        }

        conflictWarning = nil
    }

    // MARK: - Save

    private func saveHotkey() {
        guard let keyCode = recordedKeyCode, !recordedModifiers.isEmpty else { return }

        // Convert NSEvent.ModifierFlags to our storage format
        var modifierBits: UInt = 0
        if recordedModifiers.contains(.command) { modifierBits |= 0x100 }
        if recordedModifiers.contains(.shift) { modifierBits |= 0x008 }
        if recordedModifiers.contains(.option) { modifierBits |= 0x020 }
        if recordedModifiers.contains(.control) { modifierBits |= 0x001 }

        // Save to configuration
        configManager.quickCaptureHotkey = keyCode
        configManager.quickCaptureHotkeyModifiers = modifierBits

        // Post notification to update global hotkey manager
        NotificationCenter.default.post(
            name: NSNotification.Name("hotkeyChanged"),
            object: nil,
            userInfo: ["keyCode": keyCode, "modifiers": modifierBits]
        )

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
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        case kVK_F1...kVK_F20:
            return "F\(Int(keyCode) - kVK_F1 + 1)"
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
