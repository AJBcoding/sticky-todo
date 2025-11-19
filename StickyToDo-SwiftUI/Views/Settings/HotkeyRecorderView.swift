//
//  HotkeyRecorderView.swift
//  StickyToDo-SwiftUI
//
//  Interactive view for recording custom keyboard shortcuts.
//  Provides real-time feedback, validation, and conflict detection.
//

import SwiftUI
import Carbon.HIToolbox
import StickyToDoCore

/// View for recording keyboard shortcuts with real-time feedback
///
/// Features:
/// - Live key press detection
/// - Modifier key validation
/// - System shortcut conflict detection
/// - Visual feedback during recording
/// - Clear requirements display
struct HotkeyRecorderView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var configManager: ConfigurationManager

    // MARK: - State

    @State private var isRecording = false
    @State private var recordedKeyCode: UInt16?
    @State private var recordedModifiers: NSEvent.ModifierFlags = []
    @State private var conflictWarning: String?
    @State private var eventMonitor: Any?

    // MARK: - Computed Properties

    /// Whether we have a valid shortcut (key + at least one modifier)
    private var hasValidShortcut: Bool {
        recordedKeyCode != nil && !recordedModifiers.isEmpty
    }

    /// Display string for the current/recorded shortcut
    private var displayString: String {
        guard let keyCode = recordedKeyCode else {
            return isRecording ? "Press keys..." : "Click 'Start Recording'"
        }

        var parts: [String] = []

        // Standard modifier order: Control, Option, Shift, Command
        if recordedModifiers.contains(.control) { parts.append("⌃") }
        if recordedModifiers.contains(.option) { parts.append("⌥") }
        if recordedModifiers.contains(.shift) { parts.append("⇧") }
        if recordedModifiers.contains(.command) { parts.append("⌘") }

        parts.append(keyNameForCode(keyCode))

        return parts.joined()
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // Header
            headerSection

            // Recorder display
            recorderSection

            // Conflict warning
            if let warning = conflictWarning {
                warningSection(warning)
            }

            // Requirements checklist
            requirementsSection

            Spacer()

            // Action buttons
            actionButtons
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

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Record Keyboard Shortcut")
                .font(.headline)

            Text("Click 'Start Recording' and press your desired key combination")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var recorderSection: some View {
        VStack(spacing: 16) {
            // Recording display box
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

            // Recording indicator
            if isRecording {
                HStack {
                    Image(systemName: "circlebadge.fill")
                        .foregroundColor(.red)
                    Text("Recording... Press your shortcut")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Start/Stop button
            Button(isRecording ? "Stop Recording" : "Start Recording") {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
            .keyboardShortcut(.defaultAction)
        }
    }

    private func warningSection(_ warning: String) -> some View {
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

    private var requirementsSection: some View {
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
    }

    private var actionButtons: some View {
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

    // MARK: - Recording

    private func startRecording() {
        isRecording = true
        conflictWarning = nil
        recordedKeyCode = nil
        recordedModifiers = []

        // Install local event monitor to capture key events
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
            // Update modifier flags as they change
            recordedModifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        } else if event.type == .keyDown {
            // Capture the key press
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

        // Check if we have at least one modifier
        if recordedModifiers.isEmpty {
            conflictWarning = "You must use at least one modifier key (⌘, ⌥, ⌃, or ⇧)"
            return
        }

        // Create a temporary KeyboardShortcut to check for conflicts
        let tempShortcut = KeyboardShortcut(
            key: keyNameForCode(keyCode),
            modifiers: recordedModifiers,
            keyCode: keyCode
        )

        // Check system conflicts
        if let warning = tempShortcut.systemConflictWarning {
            conflictWarning = "⚠️ \(warning)"
        } else {
            conflictWarning = nil
        }
    }

    // MARK: - Save

    private func saveHotkey() {
        guard let keyCode = recordedKeyCode, !recordedModifiers.isEmpty else { return }

        // Convert NSEvent.ModifierFlags to storage format
        var modifierBits: UInt = 0
        if recordedModifiers.contains(.command) { modifierBits |= 0x100 }
        if recordedModifiers.contains(.shift) { modifierBits |= 0x008 }
        if recordedModifiers.contains(.option) { modifierBits |= 0x020 }
        if recordedModifiers.contains(.control) { modifierBits |= 0x001 }

        // Save to configuration manager
        configManager.quickCaptureHotkey = keyCode
        configManager.quickCaptureHotkeyModifiers = modifierBits

        // Create and save KeyboardShortcut model for future use
        let shortcut = KeyboardShortcut(
            key: keyNameForCode(keyCode),
            modifierFlags: modifierBits,
            keyCode: keyCode
        )
        shortcut.save(forKey: "globalHotkey")

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

#Preview("Hotkey Recorder") {
    HotkeyRecorderView()
        .environmentObject(ConfigurationManager.shared)
}
