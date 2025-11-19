//
//  TaskRowView.swift
//  StickyToDo
//
//  Individual task row component for list view.
//

import SwiftUI

/// Individual task row component displaying task information and metadata
///
/// Features:
/// - Toggle for completion status
/// - Inline title editing
/// - Metadata badges (context, project, priority)
/// - Due date with color coding
/// - Effort estimate display
/// - Hover actions and context menu
struct TaskRowView: View {

    // MARK: - Properties

    /// The task to display
    @Binding var task: Task

    /// Whether this row is currently selected
    let isSelected: Bool

    /// Whether to show the editing state
    @State private var isEditing: Bool = false

    /// Edited title when in editing mode
    @State private var editedTitle: String = ""

    /// Whether the row is being hovered
    @State private var isHovered: Bool = false

    /// Indentation level for hierarchical display (0 = top-level)
    let indentationLevel: Int

    /// Whether this task has subtasks
    let hasSubtasks: Bool

    /// Subtask progress (completed, total) - nil if no subtasks
    let subtaskProgress: (completed: Int, total: Int)?

    /// Whether subtasks are expanded (for disclosure triangle)
    @Binding var isExpanded: Bool

    /// Callback when task is tapped
    var onTap: () -> Void

    /// Callback when task completion state changes
    var onToggleComplete: () -> Void

    /// Callback when task should be deleted
    var onDelete: () -> Void

    /// Callback when disclosure triangle is tapped
    var onToggleExpansion: (() -> Void)?

    /// Callback when "Add Subtask" is tapped
    var onAddSubtask: (() -> Void)?

    /// Callback when timer button is tapped
    var onToggleTimer: (() -> Void)?

    /// Callback when "Add to Calendar" is tapped
    var onAddToCalendar: (() -> Void)?

    /// Callback when "Add Reminder" is tapped
    var onAddReminder: (() -> Void)?

    /// Optional search highlights for this task
    var searchHighlights: [SearchHighlight]?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator bar (vertical bar on left side)
            if let colorHex = task.color {
                ColorIndicator(color: colorHex, style: .bar)
            } else {
                // Spacer to maintain alignment when no color
                Spacer()
                    .frame(width: 3)
            }

            // Indentation spacer
            if indentationLevel > 0 {
                Spacer()
                    .frame(width: CGFloat(indentationLevel) * 20)
            }

            // Disclosure triangle (if task has subtasks)
            if hasSubtasks {
                Button(action: {
                    onToggleExpansion?()
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
            } else if indentationLevel > 0 {
                // Placeholder for alignment
                Spacer()
                    .frame(width: 12, height: 12)
            }

            // Completion checkbox
            Button(action: {
                onToggleComplete()
            }) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(task.status == .completed ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                // Title (with inline editing)
                if isEditing {
                    TextField("Task title", text: $editedTitle, onCommit: {
                        saveEdit()
                    })
                    .textFieldStyle(.plain)
                    .font(.body)
                    .onAppear {
                        editedTitle = task.title
                    }
                } else {
                    // Display title with optional highlighting
                    if let highlights = searchHighlights?.filter({ $0.fieldName == "title" }), !highlights.isEmpty {
                        HighlightedText(
                            text: task.title,
                            highlights: highlights,
                            font: .body,
                            foregroundColor: task.status == .completed ? .secondary : .primary
                        )
                        .strikethrough(task.status == .completed)
                        .lineLimit(2)
                        .onTapGesture {
                            if !isEditing {
                                onTap()
                            }
                        }
                    } else {
                        Text(task.title)
                            .font(.body)
                            .strikethrough(task.status == .completed)
                            .foregroundColor(task.status == .completed ? .secondary : .primary)
                            .lineLimit(2)
                            .onTapGesture {
                                if !isEditing {
                                    onTap()
                                }
                            }
                    }
                }

                // Metadata badges
                HStack(spacing: 6) {
                    // Subtask progress badge (only if has subtasks)
                    if let progress = subtaskProgress, progress.total > 0 {
                        MetadataBadge(
                            text: "\(progress.completed)/\(progress.total)",
                            color: progress.completed == progress.total ? .green : .orange,
                            icon: "checklist"
                        )
                    }

                    // Tags (show first 3)
                    ForEach(Array(task.tags.prefix(3)), id: \.id) { tag in
                        MetadataBadge(
                            text: tag.name,
                            color: Color(hex: tag.color),
                            icon: tag.icon
                        )
                    }

                    // Show count of remaining tags if there are more than 3
                    if task.tags.count > 3 {
                        MetadataBadge(
                            text: "+\(task.tags.count - 3)",
                            color: .gray,
                            icon: "tag"
                        )
                    }

                    // Context badge
                    if let context = task.context {
                        MetadataBadge(
                            text: context,
                            color: .blue,
                            icon: "mappin.circle.fill"
                        )
                    }

                    // Project badge
                    if let project = task.project {
                        MetadataBadge(
                            text: project,
                            color: .purple,
                            icon: "folder.fill"
                        )
                    }

                    // Priority badge (only for high priority)
                    if task.priority == .high {
                        MetadataBadge(
                            text: "High",
                            color: .red,
                            icon: "exclamationmark.circle.fill"
                        )
                    }

                    // Due date badge
                    if let dueDescription = task.dueDescription {
                        MetadataBadge(
                            text: dueDescription,
                            color: task.isOverdue ? .red : (task.isDueToday ? .orange : .gray),
                            icon: "calendar"
                        )
                    }

                    // Effort estimate
                    if let effortDesc = task.effortDescription {
                        MetadataBadge(
                            text: effortDesc,
                            color: .green,
                            icon: "clock.fill"
                        )
                    }

                    // Flagged indicator
                    if task.flagged {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }

                    // Time spent badge (if any time has been tracked)
                    if let timeDesc = task.timeSpentDescription {
                        MetadataBadge(
                            text: timeDesc,
                            color: .cyan,
                            icon: "hourglass"
                        )
                    }

                    // Calendar sync indicator
                    if task.isSyncedToCalendar {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .help("Synced to calendar")
                    }
                }
            }

            Spacer()

            // Timer button (always visible when hovering or timer is running)
            if task.isTimerRunning || isHovered, let toggleTimer = onToggleTimer {
                Button(action: {
                    toggleTimer()
                }) {
                    if task.isTimerRunning {
                        // Show pause icon and current duration
                        HStack(spacing: 4) {
                            if let duration = task.currentTimerDescription {
                                Text(duration)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.orange)
                        }
                    } else {
                        Image(systemName: "play.circle")
                            .foregroundColor(.green)
                    }
                }
                .buttonStyle(.plain)
                .help(task.isTimerRunning ? "Stop timer" : "Start timer")
            }

            // Original spacer removed, now timer button or spacer

            // Hover actions
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: { startEditing() }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            contextMenuContent
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuContent: some View {
        // SECTION 1: Quick Actions
        if task.status != .completed {
            Button("Complete", systemImage: "checkmark.circle.fill") {
                onToggleComplete()
            }
            .keyboardShortcut(.return, modifiers: .command)
        } else {
            Button("Reopen", systemImage: "arrow.uturn.backward.circle") {
                onToggleComplete()
            }
        }

        Button(task.flagged ? "Unflag" : "Flag", systemImage: task.flagged ? "star.slash.fill" : "star.fill") {
            task.flagged.toggle()
        }
        .keyboardShortcut("f", modifiers: [.command, .shift])

        Button("Edit", systemImage: "pencil") {
            startEditing()
        }
        .keyboardShortcut("e", modifiers: .command)

        Divider()

        // SECTION 2: Status & Priority
        Menu("Status", systemImage: "text.badge.checkmark") {
            Button("Inbox", systemImage: task.status == .inbox ? "checkmark" : "") {
                task.status = .inbox
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])

            Button("Next Action", systemImage: task.status == .nextAction ? "checkmark" : "") {
                task.status = .nextAction
            }
            .keyboardShortcut("2", modifiers: [.command, .shift])

            Button("Waiting", systemImage: task.status == .waiting ? "checkmark" : "") {
                task.status = .waiting
            }
            .keyboardShortcut("3", modifiers: [.command, .shift])

            Button("Someday", systemImage: task.status == .someday ? "checkmark" : "") {
                task.status = .someday
            }
            .keyboardShortcut("4", modifiers: [.command, .shift])

            if task.status != .completed {
                Divider()

                Button("Completed", systemImage: task.status == .completed ? "checkmark" : "") {
                    onToggleComplete()
                }
            }
        }

        Menu("Priority", systemImage: priorityIcon) {
            Button("High", systemImage: task.priority == .high ? "checkmark" : "") {
                task.priority = .high
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Button("Medium", systemImage: task.priority == .medium ? "checkmark" : "") {
                task.priority = .medium
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Button("Low", systemImage: task.priority == .low ? "checkmark" : "") {
                task.priority = .low
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])
        }

        Divider()

        // SECTION 3: Time Management
        Menu("Due Date", systemImage: "calendar") {
            Button("Today", systemImage: "calendar.badge.clock") {
                task.due = Calendar.current.startOfDay(for: Date())
            }
            .keyboardShortcut("t", modifiers: [.command, .option])

            Button("Tomorrow", systemImage: "calendar") {
                task.due = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))
            }
            .keyboardShortcut("y", modifiers: [.command, .option])

            Button("This Week", systemImage: "calendar.badge.plus") {
                // Set to end of current week (Sunday)
                let calendar = Calendar.current
                let today = Date()
                let weekday = calendar.component(.weekday, from: today)
                let daysUntilSunday = (8 - weekday) % 7
                task.due = calendar.date(byAdding: .day, value: daysUntilSunday, to: calendar.startOfDay(for: today))
            }

            Button("Next Week", systemImage: "calendar.badge.plus") {
                let calendar = Calendar.current
                task.due = calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.startOfDay(for: Date()))
            }

            Divider()

            Button("Choose Date...", systemImage: "calendar.circle") {
                // This would open a date picker - handled by parent view
            }

            if task.due != nil {
                Divider()

                Button("Clear Due Date", systemImage: "calendar.badge.minus") {
                    task.due = nil
                }
            }
        }

        // Timer option
        if let toggleTimer = onToggleTimer {
            Button(task.isTimerRunning ? "Stop Timer" : "Start Timer",
                   systemImage: task.isTimerRunning ? "pause.circle.fill" : "play.circle.fill") {
                toggleTimer()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
        }

        Divider()

        // SECTION 4: Organization
        Menu("Move to Project", systemImage: "folder") {
            Button("No Project", systemImage: task.project == nil ? "checkmark" : "") {
                task.project = nil
            }

            Divider()

            // This would show actual projects from the data store
            // For now, showing placeholder options
            Button("Website Redesign", systemImage: task.project == "Website Redesign" ? "checkmark" : "") {
                task.project = "Website Redesign"
            }

            Button("Marketing Campaign", systemImage: task.project == "Marketing Campaign" ? "checkmark" : "") {
                task.project = "Marketing Campaign"
            }

            Button("Q4 Planning", systemImage: task.project == "Q4 Planning" ? "checkmark" : "") {
                task.project = "Q4 Planning"
            }

            Divider()

            Button("New Project...", systemImage: "folder.badge.plus") {
                // This would open a project creation dialog
            }
        }

        Menu("Change Context", systemImage: "mappin.circle") {
            Button("No Context", systemImage: task.context == nil ? "checkmark" : "") {
                task.context = nil
            }

            Divider()

            // This would show actual contexts from the data store
            // For now, showing placeholder options
            Button("@computer", systemImage: task.context == "@computer" ? "checkmark" : "") {
                task.context = "@computer"
            }

            Button("@phone", systemImage: task.context == "@phone" ? "checkmark" : "") {
                task.context = "@phone"
            }

            Button("@home", systemImage: task.context == "@home" ? "checkmark" : "") {
                task.context = "@home"
            }

            Button("@office", systemImage: task.context == "@office" ? "checkmark" : "") {
                task.context = "@office"
            }

            Button("@errands", systemImage: task.context == "@errands" ? "checkmark" : "") {
                task.context = "@errands"
            }

            Divider()

            Button("New Context...", systemImage: "plus.circle") {
                // This would open a context creation dialog
            }
        }

        Menu("Set Color", systemImage: "paintpalette") {
            // Quick color options
            Button("Red", systemImage: task.color == ColorPalette.red.hex ? "checkmark" : "") {
                task.color = ColorPalette.red.hex
            }

            Button("Orange", systemImage: task.color == ColorPalette.orange.hex ? "checkmark" : "") {
                task.color = ColorPalette.orange.hex
            }

            Button("Yellow", systemImage: task.color == ColorPalette.yellow.hex ? "checkmark" : "") {
                task.color = ColorPalette.yellow.hex
            }

            Button("Green", systemImage: task.color == ColorPalette.green.hex ? "checkmark" : "") {
                task.color = ColorPalette.green.hex
            }

            Button("Blue", systemImage: task.color == ColorPalette.blue.hex ? "checkmark" : "") {
                task.color = ColorPalette.blue.hex
            }

            Button("Purple", systemImage: task.color == ColorPalette.purple.hex ? "checkmark" : "") {
                task.color = ColorPalette.purple.hex
            }

            Divider()

            Button("No Color", systemImage: "xmark.circle") {
                task.color = nil
            }
        }

        Divider()

        // SECTION 5: Subtasks & Integration
        // Subtask menu
        if let addSubtask = onAddSubtask {
            Button("Add Subtask", systemImage: "plus.circle") {
                addSubtask()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])

            Divider()
        }

        // Calendar option
        if let addToCalendar = onAddToCalendar {
            if task.isSyncedToCalendar {
                Button("View in Calendar", systemImage: "calendar.badge.checkmark") {
                    addToCalendar()
                }
            } else {
                Button("Add to Calendar", systemImage: "calendar.badge.plus") {
                    addToCalendar()
                }
            }
        }

        // Reminder option
        if let addReminder = onAddReminder {
            Button(task.notificationIds.isEmpty ? "Add Reminder" : "Edit Reminder",
                   systemImage: task.notificationIds.isEmpty ? "bell.badge.plus" : "bell.badge") {
                addReminder()
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
        }

        Divider()

        // SECTION 5: Board Management
        Menu("Add to Board", systemImage: "square.grid.2x2") {
            // This would show actual boards from the data store
            // For now, showing placeholder options
            Button("Inbox", systemImage: "tray") {
                // Add task to Inbox board
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddTaskToBoard"),
                    object: ["taskId": task.id, "boardId": "inbox"]
                )
            }

            Button("Next Actions", systemImage: "arrow.right.circle") {
                // Add task to Next Actions board
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddTaskToBoard"),
                    object: ["taskId": task.id, "boardId": "next-actions"]
                )
            }

            Button("Flagged", systemImage: "flag") {
                // Add task to Flagged board
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddTaskToBoard"),
                    object: ["taskId": task.id, "boardId": "flagged"]
                )
            }

            Divider()

            Button("New Board...", systemImage: "plus.square") {
                // This would open a board creation dialog
                NotificationCenter.default.post(
                    name: NSNotification.Name("CreateNewBoard"),
                    object: task.id
                )
            }
        }
        .accessibilityLabel("Add task to a board")

        Divider()

        // SECTION 6: Copy & Share Actions
        Menu("Copy", systemImage: "doc.on.doc") {
            Button("Copy Title", systemImage: "text.quote") {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(task.title, forType: .string)
                #endif
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .accessibilityLabel("Copy task title to clipboard")

            Button("Copy as Markdown", systemImage: "doc.text") {
                let markdown = generateMarkdown(for: task)
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(markdown, forType: .string)
                #endif
            }
            .keyboardShortcut("m", modifiers: [.command, .option])
            .accessibilityLabel("Copy task as markdown to clipboard")

            Button("Copy Link", systemImage: "link") {
                let link = "stickytodo://task/\(task.id.uuidString)"
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(link, forType: .string)
                #endif
            }
            .keyboardShortcut("l", modifiers: [.command, .option])
            .accessibilityLabel("Copy task link to clipboard")

            Divider()

            Button("Copy as Plain Text", systemImage: "doc.plaintext") {
                let plainText = generatePlainText(for: task)
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(plainText, forType: .string)
                #endif
            }
            .accessibilityLabel("Copy task as plain text to clipboard")
        }
        .accessibilityLabel("Copy task in various formats")

        Button("Share...", systemImage: "square.and.arrow.up") {
            #if os(macOS)
            // Use macOS Share Sheet
            let sharingItems = [task.title, generateMarkdown(for: task)]
            NotificationCenter.default.post(
                name: NSNotification.Name("ShareTask"),
                object: ["taskId": task.id, "items": sharingItems]
            )
            #endif
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])
        .accessibilityLabel("Share task using system share sheet")

        // SECTION 7: View Options
        Menu("Open", systemImage: "arrow.up.forward.app") {
            Button("Open in New Window", systemImage: "rectangle.badge.plus") {
                // This would open the task in a new window - handled by parent view
                #if os(macOS)
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenTaskInNewWindow"),
                    object: task.id
                )
                #endif
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
            .accessibilityLabel("Open task in a new window")

            Button("Show in Finder", systemImage: "folder") {
                // This would show the task file in Finder if applicable
                #if os(macOS)
                // Placeholder - would need actual file path
                #endif
            }
            .accessibilityLabel("Show task file in Finder")
        }
        .accessibilityLabel("Open task in different ways")

        Divider()

        // SECTION 8: Task Actions
        Button("Duplicate", systemImage: "doc.on.doc.fill") {
            // This would need to be handled by the parent view
            NotificationCenter.default.post(
                name: NSNotification.Name("DuplicateTask"),
                object: task.id
            )
        }
        .keyboardShortcut("d", modifiers: .command)
        .accessibilityLabel("Duplicate this task")

        // Only show archive for completed tasks
        if task.status == .completed {
            Button("Archive", systemImage: "archivebox") {
                // This would archive the task
                NotificationCenter.default.post(
                    name: NSNotification.Name("ArchiveTask"),
                    object: task.id
                )
            }
            .accessibilityLabel("Archive completed task")
        }

        Button("Delete", systemImage: "trash", role: .destructive) {
            onDelete()
        }
        .keyboardShortcut(.delete, modifiers: .command)
        .accessibilityLabel("Delete this task")
    }

    // MARK: - Helper Methods (Extended)

    private var priorityIcon: String {
        switch task.priority {
        case .high:
            return "exclamationmark.3"
        case .medium:
            return "exclamationmark.2"
        case .low:
            return "exclamationmark"
        }
    }

    private func generateMarkdown(for task: Task) -> String {
        var markdown = "- [\(task.status == .completed ? "x" : " ")] \(task.title)\n"

        if let project = task.project {
            markdown += "  - Project: \(project)\n"
        }

        if let context = task.context {
            markdown += "  - Context: \(context)\n"
        }

        if task.priority != .medium {
            markdown += "  - Priority: \(task.priority.displayName)\n"
        }

        if let due = task.due {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            markdown += "  - Due: \(formatter.string(from: due))\n"
        }

        if !task.notes.isEmpty {
            markdown += "\n\(task.notes)\n"
        }

        return markdown
    }

    private func generatePlainText(for task: Task) -> String {
        var text = "\(task.title)"

        var details: [String] = []

        if let project = task.project {
            details.append("Project: \(project)")
        }

        if let context = task.context {
            details.append("Context: \(context)")
        }

        if task.priority != .medium {
            details.append("Priority: \(task.priority.displayName)")
        }

        if let due = task.due {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            details.append("Due: \(formatter.string(from: due))")
        }

        if !details.isEmpty {
            text += "\n" + details.joined(separator: " | ")
        }

        if !task.notes.isEmpty {
            text += "\n\n\(task.notes)"
        }

        return text
    }

    // MARK: - Helper Methods

    private func startEditing() {
        editedTitle = task.title
        isEditing = true
    }

    private func saveEdit() {
        task.title = editedTitle
        isEditing = false
    }
}

// MARK: - Metadata Badge

/// Small capsule badge for displaying task metadata
struct MetadataBadge: View {
    let text: String
    let color: Color
    let icon: String?

    init(text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 3) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9))
            }
            Text(text)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
        )
        .foregroundColor(color)
    }
}

// MARK: - Preview

#Preview("Task Row - Normal") {
    TaskRowView(
        task: .constant(Task(
            title: "Call John about proposal",
            status: .nextAction,
            project: "Website Redesign",
            context: "@phone",
            due: Date().addingTimeInterval(86400),
            priority: .high,
            effort: 30
        )),
        isSelected: false,
        indentationLevel: 0,
        hasSubtasks: false,
        subtaskProgress: nil,
        isExpanded: .constant(false),
        onTap: {},
        onToggleComplete: {},
        onDelete: {},
        onToggleExpansion: nil,
        onAddSubtask: {},
        onToggleTimer: {},
        searchHighlights: nil
    )
    .padding()
}

#Preview("Task Row - With Subtasks") {
    TaskRowView(
        task: .constant(Task(
            title: "Complete website redesign",
            status: .nextAction,
            project: "Website Redesign"
        )),
        isSelected: false,
        indentationLevel: 0,
        hasSubtasks: true,
        subtaskProgress: (completed: 2, total: 5),
        isExpanded: .constant(true),
        onTap: {},
        onToggleComplete: {},
        onDelete: {},
        onToggleExpansion: {},
        onAddSubtask: {},
        searchHighlights: nil
    )
    .padding()
}

#Preview("Task Row - Subtask") {
    TaskRowView(
        task: .constant(Task(
            title: "Design homepage mockup",
            status: .completed,
            project: "Website Redesign"
        )),
        isSelected: false,
        indentationLevel: 1,
        hasSubtasks: false,
        subtaskProgress: nil,
        isExpanded: .constant(false),
        onTap: {},
        onToggleComplete: {},
        onDelete: {},
        onToggleExpansion: nil,
        onAddSubtask: {},
        onToggleTimer: {},
        searchHighlights: nil
    )
    .padding()
}

#Preview("Task Row - Selected") {
    TaskRowView(
        task: .constant(Task(
            title: "Selected task",
            flagged: true
        )),
        isSelected: true,
        indentationLevel: 0,
        hasSubtasks: false,
        subtaskProgress: nil,
        isExpanded: .constant(false),
        onTap: {},
        onToggleComplete: {},
        onDelete: {},
        onToggleExpansion: nil,
        onAddSubtask: {},
        onToggleTimer: {},
        searchHighlights: nil
    )
    .padding()
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
