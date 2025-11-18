//
//  AccessibilityHelper.swift
//  StickyToDoCore
//
//  Created on 2025-11-18.
//  Copyright © 2025 Sticky ToDo. All rights reserved.
//

import Foundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Provides accessibility support and utilities for the app
public class AccessibilityHelper {

    // MARK: - Accessibility Identifiers

    public enum Identifier {
        // Main Views
        public static let mainWindow = "mainWindow"
        public static let taskList = "taskList"
        public static let boardCanvas = "boardCanvas"
        public static let inspector = "inspector"
        public static let sidebar = "sidebar"

        // Toolbar
        public static let newTaskButton = "newTaskButton"
        public static let quickCaptureButton = "quickCaptureButton"
        public static let viewModeToggle = "viewModeToggle"
        public static let searchField = "searchField"

        // Task Actions
        public static let completeTaskButton = "completeTaskButton"
        public static let deleteTaskButton = "deleteTaskButton"
        public static let editTaskButton = "editTaskButton"
        public static let duplicateTaskButton = "duplicateTaskButton"

        // Inspector Fields
        public static let titleField = "titleField"
        public static let notesField = "notesField"
        public static let dueDatePicker = "dueDatePicker"
        public static let priorityPicker = "priorityPicker"
        public static let statusPicker = "statusPicker"
        public static let contextPicker = "contextPicker"

        // Perspectives
        public static let inboxPerspective = "inboxPerspective"
        public static let todayPerspective = "todayPerspective"
        public static let upcomingPerspective = "upcomingPerspective"
        public static let somedayPerspective = "somedayPerspective"
        public static let completedPerspective = "completedPerspective"

        // Board View
        public static let stickyNote = "stickyNote"
        public static let boardBackground = "boardBackground"
        public static let zoomControls = "zoomControls"

        // Quick Capture
        public static let quickCaptureWindow = "quickCaptureWindow"
        public static let quickCaptureField = "quickCaptureField"
        public static let quickCaptureSubmit = "quickCaptureSubmit"

        // Settings
        public static let settingsWindow = "settingsWindow"
        public static let generalSettings = "generalSettings"
        public static let appearanceSettings = "appearanceSettings"
        public static let shortcutsSettings = "shortcutsSettings"
    }

    // MARK: - Accessibility Labels

    public enum Label {
        // Task Properties
        public static func taskTitle(_ title: String) -> String {
            return "Task: \(title)"
        }

        public static func taskStatus(_ status: String) -> String {
            return "Status: \(status)"
        }

        public static func taskPriority(_ priority: String) -> String {
            return "Priority: \(priority)"
        }

        public static func taskDueDate(_ date: Date?) -> String {
            if let date = date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return "Due: \(formatter.string(from: date))"
            }
            return "No due date"
        }

        // Actions
        public static let newTask = "Create new task"
        public static let quickCapture = "Quick capture task"
        public static let completeTask = "Mark task as complete"
        public static let deleteTask = "Delete task"
        public static let editTask = "Edit task"
        public static let duplicateTask = "Duplicate task"

        // View Controls
        public static let listView = "Switch to list view"
        public static let boardView = "Switch to board view"
        public static let toggleInspector = "Toggle inspector panel"
        public static let toggleSidebar = "Toggle sidebar"
        public static let search = "Search tasks"

        // Zoom
        public static let zoomIn = "Zoom in"
        public static let zoomOut = "Zoom out"
        public static let resetZoom = "Reset zoom to 100%"

        // Perspectives
        public static let inbox = "Show inbox tasks"
        public static let today = "Show today's tasks"
        public static let upcoming = "Show upcoming tasks"
        public static let someday = "Show someday tasks"
        public static let completed = "Show completed tasks"
    }

    // MARK: - Accessibility Hints

    public enum Hint {
        public static let newTask = "Double-click to create a new task"
        public static let taskRow = "Double-click to edit, right-click for options"
        public static let stickyNote = "Drag to move, resize by dragging edges"
        public static let quickCapture = "Type task description and press Return"
        public static let search = "Type to filter tasks"
        public static let perspective = "Click to view tasks in this perspective"
    }

    // MARK: - Accessibility Values

    public static func taskCompletionValue(isCompleted: Bool) -> String {
        return isCompleted ? "Completed" : "Not completed"
    }

    public static func zoomValue(_ level: CGFloat) -> String {
        return String(format: "%.0f%%", level * 100)
    }

    public static func taskCountValue(_ count: Int) -> String {
        return "\(count) \(count == 1 ? "task" : "tasks")"
    }

    // MARK: - VoiceOver Announcements

    #if canImport(AppKit)
    public static func announce(_ message: String) {
        DispatchQueue.main.async {
            NSAccessibility.post(
                element: NSApp as Any,
                notification: .announcementRequested,
                userInfo: [
                    .announcement: message,
                    .priority: NSAccessibility.PriorityLevel.high
                ]
            )
        }
    }

    public static func announceTaskCreated(_ title: String) {
        announce("Task created: \(title)")
    }

    public static func announceTaskCompleted(_ title: String) {
        announce("Task completed: \(title)")
    }

    public static func announceTaskDeleted(_ title: String) {
        announce("Task deleted: \(title)")
    }

    public static func announcePerspectiveChanged(_ perspective: String) {
        announce("Switched to \(perspective)")
    }

    public static func announceViewModeChanged(_ mode: String) {
        announce("Switched to \(mode) view")
    }
    #endif

    // MARK: - Keyboard Navigation

    public static let focusableElements = [
        "taskList",
        "searchField",
        "newTaskButton",
        "inspector"
    ]

    // MARK: - High Contrast Support

    #if canImport(AppKit)
    public static var isHighContrastEnabled: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }

    public static var shouldReduceTransparency: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }

    public static var shouldReduceMotion: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    public static var shouldDifferentiateWithoutColor: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
    }
    #endif

    // MARK: - Color Adjustments for Accessibility

    public static func adjustedColor(_ color: NSColor) -> NSColor {
        #if canImport(AppKit)
        if isHighContrastEnabled {
            // Increase contrast
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0

            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

            // Increase saturation and adjust brightness for better contrast
            let adjustedSaturation = min(saturation * 1.2, 1.0)
            let adjustedBrightness = brightness < 0.5 ? brightness * 0.8 : min(brightness * 1.1, 1.0)

            return NSColor(hue: hue, saturation: adjustedSaturation, brightness: adjustedBrightness, alpha: alpha)
        }
        #endif
        return color
    }

    // MARK: - Text Size Adjustments

    public static func adjustedFontSize(_ baseSize: CGFloat) -> CGFloat {
        #if canImport(AppKit)
        // Scale based on system accessibility settings
        let contentSizeCategory = NSFont.systemFontSize / 13.0 // Default system font size is 13
        return baseSize * contentSizeCategory
        #else
        return baseSize
        #endif
    }

    // MARK: - Animation Timing

    public static func animationDuration(_ baseDuration: TimeInterval) -> TimeInterval {
        #if canImport(AppKit)
        if shouldReduceMotion {
            return 0.0 // No animation
        }
        #endif
        return baseDuration
    }
}

// MARK: - SwiftUI Extensions

#if canImport(SwiftUI)
public extension View {
    /// Add accessibility label and identifier
    func accessibleElement(
        identifier: String,
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityIdentifier(identifier)
            .accessibilityLabel(label)
            .modifier(AccessibilityHintModifier(hint: hint))
            .modifier(AccessibilityValueModifier(value: value))
    }

    /// Mark as a task row with proper accessibility
    func accessibleTaskRow(
        task: Task,
        index: Int
    ) -> some View {
        self
            .accessibilityIdentifier("taskRow_\(task.id)")
            .accessibilityLabel(AccessibilityHelper.Label.taskTitle(task.title))
            .accessibilityHint(AccessibilityHelper.Hint.taskRow)
            .accessibilityValue(AccessibilityHelper.taskCompletionValue(isCompleted: task.status == .done))
            .accessibilityAddTraits(task.status == .done ? [.isButton] : [])
    }
}

private struct AccessibilityHintModifier: ViewModifier {
    let hint: String?

    func body(content: Content) -> some View {
        if let hint = hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}

private struct AccessibilityValueModifier: ViewModifier {
    let value: String?

    func body(content: Content) -> some View {
        if let value = value {
            content.accessibilityValue(value)
        } else {
            content
        }
    }
}
#endif

// MARK: - AppKit Extensions

#if canImport(AppKit)
public extension NSView {
    /// Configure accessibility for a view
    func configureAccessibility(
        identifier: String,
        label: String? = nil,
        help: String? = nil,
        role: NSAccessibility.Role? = nil
    ) {
        self.setAccessibilityIdentifier(identifier)

        if let label = label {
            self.setAccessibilityLabel(label)
        }

        if let help = help {
            self.setAccessibilityHelp(help)
        }

        if let role = role {
            self.setAccessibilityRole(role)
        }
    }
}

public extension NSControl {
    /// Configure accessibility for a control
    func configureAccessibility(
        identifier: String,
        label: String,
        help: String? = nil
    ) {
        (self as NSView).configureAccessibility(
            identifier: identifier,
            label: label,
            help: help,
            role: .button
        )
    }
}
#endif
