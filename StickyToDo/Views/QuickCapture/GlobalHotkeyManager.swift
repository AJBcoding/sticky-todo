//
//  GlobalHotkeyManager.swift
//  StickyToDo
//
//  Manages global keyboard shortcuts using AppKit.
//

import AppKit
import Combine
import Carbon.HIToolbox

/// Manages global keyboard shortcuts for quick capture
///
/// Uses AppKit's NSEvent.addGlobalMonitorForEvents to register a system-wide
/// hotkey that triggers the quick capture window.
///
/// Default hotkey: Cmd+Shift+Space
///
/// Note: This requires the app to have Accessibility permissions in System Preferences.
class GlobalHotkeyManager: ObservableObject {

    // MARK: - Properties

    /// Published trigger when the hotkey is pressed
    @Published var hotkeyPressed: Bool = false

    /// The event monitor for the global hotkey
    private var eventMonitor: Any?

    /// The current hotkey configuration
    private var hotkeyConfig: HotkeyConfig

    // MARK: - Initialization

    init(hotkey: HotkeyConfig = .default) {
        self.hotkeyConfig = hotkey
    }

    // MARK: - Public Methods

    /// Starts monitoring for the global hotkey
    func startMonitoring() {
        // Stop any existing monitor
        stopMonitoring()

        // Add a global event monitor for key down events
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        print("Global hotkey monitoring started: \(hotkeyConfig.description)")
    }

    /// Stops monitoring for the global hotkey
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
            print("Global hotkey monitoring stopped")
        }
    }

    /// Updates the hotkey configuration
    /// - Parameter config: The new hotkey configuration
    func updateHotkey(_ config: HotkeyConfig) {
        hotkeyConfig = config

        // Restart monitoring with new config
        if eventMonitor != nil {
            startMonitoring()
        }
    }

    // MARK: - Private Methods

    private func handleKeyEvent(_ event: NSEvent) {
        // Check if the event matches our hotkey configuration
        guard event.keyCode == hotkeyConfig.keyCode else { return }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers == hotkeyConfig.modifiers else { return }

        // Trigger the hotkey on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.hotkeyPressed = true

            // Reset after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.hotkeyPressed = false
            }
        }
    }

    // MARK: - Cleanup

    deinit {
        stopMonitoring()
    }
}

// MARK: - Hotkey Configuration

/// Configuration for a keyboard shortcut
struct HotkeyConfig {
    /// The key code (Carbon key code)
    let keyCode: UInt16

    /// The modifier flags (Cmd, Shift, Option, Control)
    let modifiers: NSEvent.ModifierFlags

    /// Human-readable description of the hotkey
    var description: String {
        var parts: [String] = []

        if modifiers.contains(.command) {
            parts.append("⌘")
        }
        if modifiers.contains(.shift) {
            parts.append("⇧")
        }
        if modifiers.contains(.option) {
            parts.append("⌥")
        }
        if modifiers.contains(.control) {
            parts.append("⌃")
        }

        parts.append(keyName)

        return parts.joined()
    }

    /// Human-readable key name
    private var keyName: String {
        switch keyCode {
        case UInt16(kVK_Space):
            return "Space"
        case UInt16(kVK_Return):
            return "Return"
        case UInt16(kVK_Escape):
            return "Escape"
        case UInt16(kVK_Tab):
            return "Tab"
        default:
            return "Key(\(keyCode))"
        }
    }

    /// Default hotkey: Cmd+Shift+Space
    static let `default` = HotkeyConfig(
        keyCode: UInt16(kVK_Space),
        modifiers: [.command, .shift]
    )

    /// Alternative: Cmd+Shift+N
    static let cmdShiftN = HotkeyConfig(
        keyCode: 45, // N key
        modifiers: [.command, .shift]
    )

    /// Alternative: Cmd+Option+Space
    static let cmdOptionSpace = HotkeyConfig(
        keyCode: UInt16(kVK_Space),
        modifiers: [.command, .option]
    )
}

// MARK: - Accessibility Permission Check

extension GlobalHotkeyManager {
    /// Checks if the app has accessibility permissions
    /// - Returns: True if the app has accessibility permissions
    static func hasAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Requests accessibility permissions from the user
    static func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Shows an alert if accessibility permissions are not granted
    static func showPermissionAlertIfNeeded() {
        guard !hasAccessibilityPermissions() else { return }

        let alert = NSAlert()
        alert.messageText = "Accessibility Permissions Required"
        alert.informativeText = "StickyToDo needs accessibility permissions to use global keyboard shortcuts. Please grant access in System Preferences > Security & Privacy > Privacy > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            // Open System Preferences
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - Usage Example
/*
 // In your App or Scene:

 @StateObject private var hotkeyManager = GlobalHotkeyManager()

 var body: some Scene {
     WindowGroup {
         ContentView()
     }
     .onAppear {
         // Check for permissions on first launch
         if GlobalHotkeyManager.hasAccessibilityPermissions() {
             hotkeyManager.startMonitoring()
         } else {
             GlobalHotkeyManager.showPermissionAlertIfNeeded()
         }
     }
     .onChange(of: hotkeyManager.hotkeyPressed) { pressed in
         if pressed {
             // Show quick capture window
             showQuickCaptureWindow()
         }
     }
 }
 */
