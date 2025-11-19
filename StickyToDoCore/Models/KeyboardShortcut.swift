//
//  KeyboardShortcut.swift
//  StickyToDoCore
//
//  Model representing a customizable keyboard shortcut.
//  Supports saving/loading from UserDefaults and converting to/from system types.
//

import Foundation
import AppKit
import Carbon.HIToolbox

/// Represents a customizable keyboard shortcut
///
/// This model encapsulates a keyboard shortcut configuration including:
/// - Key code (Carbon virtual key code)
/// - Modifier flags (Command, Shift, Option, Control)
/// - Human-readable description
///
/// The model is Codable for easy persistence to UserDefaults.
public struct KeyboardShortcut: Codable, Equatable {

    // MARK: - Properties

    /// The key character (e.g., "Space", "N", "A")
    public let key: String

    /// The raw modifier flags value (for persistence)
    public let modifierFlags: UInt

    /// The Carbon virtual key code
    public let keyCode: UInt16

    // MARK: - Initialization

    /// Creates a keyboard shortcut from raw values
    /// - Parameters:
    ///   - key: The key character
    ///   - modifierFlags: Raw modifier flags value
    ///   - keyCode: Carbon virtual key code
    public init(key: String, modifierFlags: UInt, keyCode: UInt16) {
        self.key = key
        self.modifierFlags = modifierFlags
        self.keyCode = keyCode
    }

    /// Creates a keyboard shortcut from AppKit types
    /// - Parameters:
    ///   - key: The key character
    ///   - modifiers: NSEvent modifier flags
    ///   - keyCode: Carbon virtual key code
    public init(key: String, modifiers: NSEvent.ModifierFlags, keyCode: UInt16) {
        self.key = key
        self.modifierFlags = Self.modifierFlagsToRawValue(modifiers)
        self.keyCode = keyCode
    }

    // MARK: - Computed Properties

    /// Returns NSEvent.ModifierFlags from the stored raw value
    public var nsEventModifiers: NSEvent.ModifierFlags {
        return Self.rawValueToModifierFlags(modifierFlags)
    }

    /// Human-readable description of the shortcut (e.g., "⌘⇧Space")
    public var description: String {
        var parts: [String] = []

        // Order: Control, Option, Shift, Command (standard macOS order)
        if modifierFlags & 0x001 != 0 { parts.append("⌃") } // Control
        if modifierFlags & 0x020 != 0 { parts.append("⌥") } // Option
        if modifierFlags & 0x008 != 0 { parts.append("⇧") } // Shift
        if modifierFlags & 0x100 != 0 { parts.append("⌘") } // Command

        parts.append(keyDisplayName)

        return parts.joined()
    }

    /// Display name for the key
    private var keyDisplayName: String {
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
            return key.uppercased()
        }
    }

    // MARK: - Validation

    /// Checks if this shortcut is valid
    /// - Returns: True if the shortcut has at least one modifier and a key
    public var isValid: Bool {
        return modifierFlags != 0 && !key.isEmpty
    }

    /// Checks if this shortcut conflicts with common system shortcuts
    /// - Returns: A warning message if there's a conflict, nil otherwise
    public var systemConflictWarning: String? {
        let conflicts: [(keyCode: UInt16, modifiers: UInt, description: String)] = [
            (UInt16(kVK_Space), 0x100, "Spotlight"),
            (UInt16(kVK_Space), 0x120, "Spotlight Finder"),
            (UInt16(kVK_Tab), 0x100, "App Switcher"),
            (UInt16(kVK_ANSI_Q), 0x100, "Quit Application"),
            (UInt16(kVK_ANSI_W), 0x100, "Close Window"),
            (UInt16(kVK_ANSI_H), 0x100, "Hide Window"),
            (UInt16(kVK_ANSI_M), 0x100, "Minimize Window"),
            (UInt16(kVK_ANSI_C), 0x100, "Copy"),
            (UInt16(kVK_ANSI_V), 0x100, "Paste"),
            (UInt16(kVK_ANSI_X), 0x100, "Cut"),
            (UInt16(kVK_ANSI_Z), 0x100, "Undo"),
            (UInt16(kVK_ANSI_A), 0x100, "Select All"),
            (UInt16(kVK_ANSI_S), 0x100, "Save"),
            (UInt16(kVK_ANSI_P), 0x100, "Print"),
            (UInt16(kVK_ANSI_F), 0x100, "Find"),
        ]

        for conflict in conflicts {
            if conflict.keyCode == self.keyCode && conflict.modifiers == self.modifierFlags {
                return "This shortcut conflicts with system '\(conflict.description)' command"
            }
        }

        return nil
    }

    // MARK: - Conversion Helpers

    /// Converts NSEvent.ModifierFlags to raw value for storage
    private static func modifierFlagsToRawValue(_ modifiers: NSEvent.ModifierFlags) -> UInt {
        var value: UInt = 0
        if modifiers.contains(.command) { value |= 0x100 }
        if modifiers.contains(.shift) { value |= 0x008 }
        if modifiers.contains(.option) { value |= 0x020 }
        if modifiers.contains(.control) { value |= 0x001 }
        return value
    }

    /// Converts raw value to NSEvent.ModifierFlags
    private static func rawValueToModifierFlags(_ value: UInt) -> NSEvent.ModifierFlags {
        var modifiers: NSEvent.ModifierFlags = []
        if value & 0x100 != 0 { modifiers.insert(.command) }
        if value & 0x008 != 0 { modifiers.insert(.shift) }
        if value & 0x020 != 0 { modifiers.insert(.option) }
        if value & 0x001 != 0 { modifiers.insert(.control) }
        return modifiers
    }

    // MARK: - Persistence

    /// Saves the shortcut to UserDefaults
    /// - Parameter key: UserDefaults key to use
    public func save(forKey key: String) {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Loads a shortcut from UserDefaults
    /// - Parameter key: UserDefaults key to load from
    /// - Returns: The loaded shortcut, or nil if not found
    public static func load(forKey key: String) -> KeyboardShortcut? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(KeyboardShortcut.self, from: data)
    }

    // MARK: - Default Shortcuts

    /// Default shortcut: Cmd+Shift+Space
    public static let defaultQuickCapture = KeyboardShortcut(
        key: "Space",
        modifierFlags: 0x108, // Cmd (0x100) + Shift (0x008)
        keyCode: UInt16(kVK_Space)
    )

    /// Alternative: Cmd+Shift+N
    public static let cmdShiftN = KeyboardShortcut(
        key: "N",
        modifierFlags: 0x108,
        keyCode: 45
    )

    /// Alternative: Cmd+Option+Space
    public static let cmdOptionSpace = KeyboardShortcut(
        key: "Space",
        modifierFlags: 0x120, // Cmd (0x100) + Option (0x020)
        keyCode: UInt16(kVK_Space)
    )
}

// MARK: - HotkeyConfig Compatibility

extension KeyboardShortcut {
    /// Converts to HotkeyConfig for use with GlobalHotkeyManager
    public func toHotkeyConfig() -> HotkeyConfig {
        return HotkeyConfig(
            keyCode: self.keyCode,
            modifiers: self.nsEventModifiers
        )
    }

    /// Creates from HotkeyConfig
    public init(from config: HotkeyConfig, key: String) {
        self.init(
            key: key,
            modifiers: config.modifiers,
            keyCode: config.keyCode
        )
    }
}

// MARK: - HotkeyConfig (for compatibility)

/// Configuration for a keyboard shortcut (legacy compatibility)
public struct HotkeyConfig {
    /// The key code (Carbon key code)
    public let keyCode: UInt16

    /// The modifier flags (Cmd, Shift, Option, Control)
    public let modifiers: NSEvent.ModifierFlags

    /// Human-readable description of the hotkey
    public var description: String {
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
    public static let `default` = HotkeyConfig(
        keyCode: UInt16(kVK_Space),
        modifiers: [.command, .shift]
    )

    /// Alternative: Cmd+Shift+N
    public static let cmdShiftN = HotkeyConfig(
        keyCode: 45, // N key
        modifiers: [.command, .shift]
    )

    /// Alternative: Cmd+Option+Space
    public static let cmdOptionSpace = HotkeyConfig(
        keyCode: UInt16(kVK_Space),
        modifiers: [.command, .option]
    )
}
