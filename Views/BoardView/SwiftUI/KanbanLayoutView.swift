//
//  KanbanLayoutView.swift
//  StickyToDo
//
//  SwiftUI Kanban board layout with vertical columns for workflow stages.
//  Supports drag-and-drop between columns with automatic metadata updates.
//

import SwiftUI

/// SwiftUI Kanban board view
///
/// Displays tasks organized in vertical swim lanes. Each column represents
/// a stage in the workflow. Tasks can be dragged between columns.
struct KanbanLayoutView: View {

    // MARK: - Properties

    /// The current board being displayed
    let board: Board

    /// All tasks to display on the board
    @Binding var tasks: [Task]

    /// Currently selected task IDs
    @Binding var selectedTaskIds: Set<UUID>

    /// Callback when a task is selected
    var onTaskSelected: (UUID) -> Void

    /// Callback when a task is updated
    var onTaskUpdated: (Task) -> Void

    /// Callback when a new task should be created
    var onCreateTask: (String) -> Void

    // MARK: - State

    @State private var draggedTask: Task?

    // MARK: - Computed Properties

    /// Tasks that appear on this board
    private var boardTasks: [Task] {
        tasks.filter { $0.matches(board.filter) }
    }

    /// Columns for this board
    private var columns: [String] {
        board.effectiveColumns
    }

    /// Tasks grouped by column
    private var tasksByColumn: [String: [Task]] {
        var grouped: [String: [Task]] = [:]

        for column in columns {
            grouped[column] = []
        }

        for task in boardTasks {
            if let column = LayoutEngine.assignTaskToColumn(task: task, board: board) {
                grouped[column]?.append(task)
            } else {
                grouped[columns.first ?? ""]?.append(task)
            }
        }

        return grouped
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: LayoutEngine.columnSpacing) {
                ForEach(columns, id: \.self) { column in
                    kanbanColumn(column: column)
                }
            }
            .padding(LayoutEngine.gridSpacing)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Column View

    private func kanbanColumn(column: String) -> some View {
        let columnTasks = tasksByColumn[column] ?? []

        return VStack(alignment: .leading, spacing: 0) {
            // Column header
            columnHeader(column: column, taskCount: columnTasks.count)

            // Task cards
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: LayoutEngine.cardSpacing) {
                    ForEach(columnTasks) { task in
                        kanbanTaskCard(task: task, column: column)
                    }
                }
                .padding(LayoutEngine.columnPadding)
            }
        }
        .frame(width: LayoutEngine.defaultColumnWidth)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers: providers, toColumn: column)
        }
    }

    // MARK: - Column Header

    private func columnHeader(column: String, taskCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(column)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(taskCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Button(action: {
                onCreateTask(column)
            }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                    Text("Add Task")
                        .font(.system(size: 11))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Task Card

    private func kanbanTaskCard(task: Task, column: String) -> some View {
        let isSelected = selectedTaskIds.contains(task.id)

        // Find the binding for this task
        let taskBinding = Binding<Task>(
            get: {
                tasks.first(where: { $0.id == task.id }) ?? task
            },
            set: { newValue in
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index] = newValue
                    onTaskUpdated(newValue)
                }
            }
        )

        return VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(task.title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(3)
                .foregroundColor(.primary)

            // Metadata badges
            HStack(spacing: 4) {
                if let context = task.context {
                    metadataBadge(text: context, color: .blue)
                }

                if let project = task.project {
                    metadataBadge(text: project, color: .purple)
                }

                if task.priority == .high {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }

                if task.flagged {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }

                if let dueDesc = task.dueDescription {
                    metadataBadge(
                        text: dueDesc,
                        color: task.isOverdue ? .red : .gray
                    )
                }

                Spacer()
            }
        }
        .padding(12)
        .frame(height: LayoutEngine.defaultCardHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(colorForTask(task))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.blue : Color(NSColor.separatorColor), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .onTapGesture {
            handleTaskTap(task.id)
        }
        .onDrag {
            self.draggedTask = task
            return NSItemProvider(object: task.id.uuidString as NSString)
        }
        .contextMenu {
            kanbanTaskContextMenu(task: taskBinding)
        }
    }

    // MARK: - Kanban Task Context Menu

    @ViewBuilder
    private func kanbanTaskContextMenu(task: Binding<Task>) -> some View {
        // SECTION 1: Quick Actions
        if task.wrappedValue.status != .completed {
            Button("Complete", systemImage: "checkmark.circle.fill") {
                task.wrappedValue.status = .completed
            }
        } else {
            Button("Reopen", systemImage: "arrow.uturn.backward.circle") {
                task.wrappedValue.status = .nextAction
            }
        }

        Button(task.wrappedValue.flagged ? "Unflag" : "Flag",
               systemImage: task.wrappedValue.flagged ? "star.slash.fill" : "star.fill") {
            task.wrappedValue.flagged.toggle()
        }

        Divider()

        // SECTION 2: Status & Priority
        Menu("Status", systemImage: "text.badge.checkmark") {
            Button("Inbox", systemImage: task.wrappedValue.status == .inbox ? "checkmark" : "") {
                task.wrappedValue.status = .inbox
            }

            Button("Next Action", systemImage: task.wrappedValue.status == .nextAction ? "checkmark" : "") {
                task.wrappedValue.status = .nextAction
            }

            Button("Waiting", systemImage: task.wrappedValue.status == .waiting ? "checkmark" : "") {
                task.wrappedValue.status = .waiting
            }

            Button("Someday", systemImage: task.wrappedValue.status == .someday ? "checkmark" : "") {
                task.wrappedValue.status = .someday
            }

            if task.wrappedValue.status != .completed {
                Divider()

                Button("Completed", systemImage: task.wrappedValue.status == .completed ? "checkmark" : "") {
                    task.wrappedValue.status = .completed
                }
            }
        }

        Menu("Priority", systemImage: priorityIcon(for: task.wrappedValue)) {
            Button("High", systemImage: task.wrappedValue.priority == .high ? "checkmark" : "") {
                task.wrappedValue.priority = .high
            }

            Button("Medium", systemImage: task.wrappedValue.priority == .medium ? "checkmark" : "") {
                task.wrappedValue.priority = .medium
            }

            Button("Low", systemImage: task.wrappedValue.priority == .low ? "checkmark" : "") {
                task.wrappedValue.priority = .low
            }
        }

        Divider()

        // SECTION 3: Time Management
        Menu("Due Date", systemImage: "calendar") {
            Button("Today", systemImage: "calendar.badge.clock") {
                task.wrappedValue.due = Calendar.current.startOfDay(for: Date())
            }

            Button("Tomorrow", systemImage: "calendar") {
                task.wrappedValue.due = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))
            }

            Button("This Week", systemImage: "calendar.badge.plus") {
                let calendar = Calendar.current
                let today = Date()
                let weekday = calendar.component(.weekday, from: today)
                let daysUntilSunday = (8 - weekday) % 7
                task.wrappedValue.due = calendar.date(byAdding: .day, value: daysUntilSunday, to: calendar.startOfDay(for: today))
            }

            Button("Next Week", systemImage: "calendar.badge.plus") {
                let calendar = Calendar.current
                task.wrappedValue.due = calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.startOfDay(for: Date()))
            }

            Divider()

            Button("Choose Date...", systemImage: "calendar.circle") {
                // This would open a date picker
            }

            if task.wrappedValue.due != nil {
                Divider()

                Button("Clear Due Date", systemImage: "calendar.badge.minus") {
                    task.wrappedValue.due = nil
                }
            }
        }

        Divider()

        // SECTION 4: Organization
        Menu("Move to Project", systemImage: "folder") {
            Button("No Project", systemImage: task.wrappedValue.project == nil ? "checkmark" : "") {
                task.wrappedValue.project = nil
            }

            Divider()

            Button("Website Redesign", systemImage: task.wrappedValue.project == "Website Redesign" ? "checkmark" : "") {
                task.wrappedValue.project = "Website Redesign"
            }

            Button("Marketing Campaign", systemImage: task.wrappedValue.project == "Marketing Campaign" ? "checkmark" : "") {
                task.wrappedValue.project = "Marketing Campaign"
            }

            Button("Q4 Planning", systemImage: task.wrappedValue.project == "Q4 Planning" ? "checkmark" : "") {
                task.wrappedValue.project = "Q4 Planning"
            }

            Divider()

            Button("New Project...", systemImage: "folder.badge.plus") {
                // This would open a project creation dialog
            }
        }

        Menu("Change Context", systemImage: "mappin.circle") {
            Button("No Context", systemImage: task.wrappedValue.context == nil ? "checkmark" : "") {
                task.wrappedValue.context = nil
            }

            Divider()

            Button("@computer", systemImage: task.wrappedValue.context == "@computer" ? "checkmark" : "") {
                task.wrappedValue.context = "@computer"
            }

            Button("@phone", systemImage: task.wrappedValue.context == "@phone" ? "checkmark" : "") {
                task.wrappedValue.context = "@phone"
            }

            Button("@home", systemImage: task.wrappedValue.context == "@home" ? "checkmark" : "") {
                task.wrappedValue.context = "@home"
            }

            Button("@office", systemImage: task.wrappedValue.context == "@office" ? "checkmark" : "") {
                task.wrappedValue.context = "@office"
            }

            Button("@errands", systemImage: task.wrappedValue.context == "@errands" ? "checkmark" : "") {
                task.wrappedValue.context = "@errands"
            }

            Divider()

            Button("New Context...", systemImage: "plus.circle") {
                // This would open a context creation dialog
            }
        }

        Menu("Set Color", systemImage: "paintpalette") {
            Button("Red", systemImage: task.wrappedValue.color == ColorPalette.red.hex ? "checkmark" : "") {
                task.wrappedValue.color = ColorPalette.red.hex
            }

            Button("Orange", systemImage: task.wrappedValue.color == ColorPalette.orange.hex ? "checkmark" : "") {
                task.wrappedValue.color = ColorPalette.orange.hex
            }

            Button("Yellow", systemImage: task.wrappedValue.color == ColorPalette.yellow.hex ? "checkmark" : "") {
                task.wrappedValue.color = ColorPalette.yellow.hex
            }

            Button("Green", systemImage: task.wrappedValue.color == ColorPalette.green.hex ? "checkmark" : "") {
                task.wrappedValue.color = ColorPalette.green.hex
            }

            Button("Blue", systemImage: task.wrappedValue.color == ColorPalette.blue.hex ? "checkmark" : "") {
                task.wrappedValue.color = ColorPalette.blue.hex
            }

            Button("Purple", systemImage: task.wrappedValue.color == ColorPalette.purple.hex ? "checkmark" : "") {
                task.wrappedValue.color = ColorPalette.purple.hex
            }

            Divider()

            Button("No Color", systemImage: "xmark.circle") {
                task.wrappedValue.color = nil
            }
        }

        Divider()

        // SECTION 5: Board Management
        Menu("Add to Board", systemImage: "square.grid.2x2") {
            Button("Inbox", systemImage: "tray") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddTaskToBoard"),
                    object: ["taskId": task.wrappedValue.id, "boardId": "inbox"]
                )
            }

            Button("Next Actions", systemImage: "arrow.right.circle") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddTaskToBoard"),
                    object: ["taskId": task.wrappedValue.id, "boardId": "next-actions"]
                )
            }

            Button("Flagged", systemImage: "flag") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddTaskToBoard"),
                    object: ["taskId": task.wrappedValue.id, "boardId": "flagged"]
                )
            }

            Divider()

            Button("New Board...", systemImage: "plus.square") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("CreateNewBoard"),
                    object: task.wrappedValue.id
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
                NSPasteboard.general.setString(task.wrappedValue.title, forType: .string)
                #endif
            }

            Button("Copy as Markdown", systemImage: "doc.text") {
                let markdown = generateMarkdown(for: task.wrappedValue)
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(markdown, forType: .string)
                #endif
            }

            Button("Copy Link", systemImage: "link") {
                let link = "stickytodo://task/\(task.wrappedValue.id.uuidString)"
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(link, forType: .string)
                #endif
            }

            Divider()

            Button("Copy as Plain Text", systemImage: "doc.plaintext") {
                let plainText = generatePlainText(for: task.wrappedValue)
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
            let sharingItems = [task.wrappedValue.title, generateMarkdown(for: task.wrappedValue)]
            NotificationCenter.default.post(
                name: NSNotification.Name("ShareTask"),
                object: ["taskId": task.wrappedValue.id, "items": sharingItems]
            )
            #endif
        }
        .accessibilityLabel("Share task using system share sheet")

        Divider()

        // SECTION 7: View Options
        Menu("Open", systemImage: "arrow.up.forward.app") {
            Button("Open in New Window", systemImage: "rectangle.badge.plus") {
                #if os(macOS)
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenTaskInNewWindow"),
                    object: task.wrappedValue.id
                )
                #endif
            }

            Button("Show in Finder", systemImage: "folder") {
                // This would show the task file in Finder if applicable
            }
        }

        Divider()

        // SECTION 6: Task Actions
        Button("Duplicate", systemImage: "doc.on.doc.fill") {
            NotificationCenter.default.post(
                name: NSNotification.Name("DuplicateTask"),
                object: task.wrappedValue.id
            )
        }

        if task.wrappedValue.status == .completed {
            Button("Archive", systemImage: "archivebox") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ArchiveTask"),
                    object: task.wrappedValue.id
                )
            }
        }

        Button("Delete", systemImage: "trash", role: .destructive) {
            if let index = tasks.firstIndex(where: { $0.id == task.wrappedValue.id }) {
                let taskToDelete = tasks[index]
                tasks.remove(at: index)
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeleteTask"),
                    object: taskToDelete.id
                )
            }
        }
    }

    // MARK: - Metadata Badge

    private func metadataBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundColor(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
    }

    // MARK: - Helpers

    private func colorForTask(_ task: Task) -> Color {
        if task.status == .completed {
            return Color.green.opacity(0.15)
        }

        switch task.priority {
        case .high:
            return Color.red.opacity(0.1)
        case .medium:
            return Color.yellow.opacity(0.15)
        case .low:
            return Color.blue.opacity(0.1)
        }
    }

    private func priorityIcon(for task: Task) -> String {
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

    private func handleTaskTap(_ taskId: UUID) {
        if NSEvent.modifierFlags.contains(.command) {
            // Toggle selection
            if selectedTaskIds.contains(taskId) {
                selectedTaskIds.remove(taskId)
            } else {
                selectedTaskIds.insert(taskId)
            }
        } else {
            // Single selection
            selectedTaskIds = [taskId]
        }

        onTaskSelected(taskId)
    }

    private func handleDrop(providers: [NSItemProvider], toColumn column: String) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { (item, error) in
            guard let data = item as? Data,
                  let taskIdString = String(data: data, encoding: .utf8),
                  let taskId = UUID(uuidString: taskIdString),
                  let taskIndex = tasks.firstIndex(where: { $0.id == taskId }) else {
                return
            }

            DispatchQueue.main.async {
                // Apply metadata updates for the target column
                var updatedTask = tasks[taskIndex]
                let metadata = LayoutEngine.metadataUpdates(
                    forTask: updatedTask,
                    inColumn: column,
                    onBoard: board
                )

                // Apply metadata
                for (key, value) in metadata {
                    switch key {
                    case "status":
                        if let statusString = value as? String,
                           let status = Status(rawValue: statusString) {
                            updatedTask.status = status
                        }
                    case "context":
                        if let context = value as? String {
                            updatedTask.context = context
                        }
                    case "project":
                        if let project = value as? String {
                            updatedTask.project = project
                        }
                    case "priority":
                        if let priorityString = value as? String,
                           let priority = Priority(rawValue: priorityString) {
                            updatedTask.priority = priority
                        }
                    case "flagged":
                        if let flagged = value as? Bool {
                            updatedTask.flagged = flagged
                        }
                    default:
                        break
                    }
                }

                updatedTask.modified = Date()
                tasks[taskIndex] = updatedTask
                onTaskUpdated(updatedTask)
            }
        }

        return true
    }
}

// MARK: - Preview

#Preview("Kanban Board") {
    KanbanLayoutView(
        board: Board(
            id: "next-actions",
            type: .status,
            layout: .kanban,
            filter: Filter(status: .nextAction),
            columns: ["To Do", "In Progress", "Done"]
        ),
        tasks: .constant([
            Task(
                title: "Call John about proposal",
                status: .inbox,
                context: "@phone",
                priority: .high,
                flagged: true
            ),
            Task(
                title: "Review mockups",
                status: .nextAction,
                project: "Website",
                priority: .medium
            ),
            Task(
                title: "Write report",
                status: .nextAction,
                priority: .low
            ),
            Task(
                title: "Deploy to production",
                status: .completed,
                project: "Website"
            ),
        ]),
        selectedTaskIds: .constant([]),
        onTaskSelected: { _ in },
        onTaskUpdated: { _ in },
        onCreateTask: { _ in }
    )
    .frame(width: 900, height: 600)
}
