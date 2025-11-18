//
//  BoardCanvasView.swift
//  StickyToDo
//
//  SwiftUI board canvas integrating with task data.
//  Supports multiple layout modes: Freeform, Kanban, and Grid.
//

import SwiftUI

/// Board canvas view showing tasks in different layouts
///
/// Integrates the SwiftUI layout views with the actual task data model.
/// Handles task updates, board switching, and metadata changes on drag.
/// Supports Freeform (infinite canvas), Kanban (columns), and Grid (sections) layouts.
struct BoardCanvasView: View {

    // MARK: - Properties

    /// The current board being displayed
    @Binding var board: Board

    /// All tasks to display on the board
    @Binding var tasks: [Task]

    /// Currently selected task IDs
    @Binding var selectedTaskIds: Set<UUID>

    /// Callback when a task is selected
    var onTaskSelected: (UUID) -> Void

    /// Callback when a task is updated
    var onTaskUpdated: (Task) -> Void

    /// Callback when a new task should be created
    var onCreateTask: (Position) -> Void

    /// Callback when board layout is changed
    var onLayoutChanged: ((Layout) -> Void)?

    // MARK: - State

    @StateObject private var viewModel = BoardCanvasViewModel()
    @State private var showGrid = true
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    // MARK: - Computed Properties

    /// Tasks that appear on this board
    private var boardTasks: [Task] {
        tasks.filter { $0.matches(board.filter) }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Layout picker toolbar
            layoutPickerToolbar

            // Content based on layout mode
            layoutContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadTasksIntoViewModel()
        }
        .onChange(of: board.id) { _ in
            loadTasksIntoViewModel()
        }
        .onChange(of: tasks) { _ in
            loadTasksIntoViewModel()
        }
    }

    // MARK: - Layout Picker Toolbar

    private var layoutPickerToolbar: some View {
        HStack {
            // Board title with context menu
            Text(board.displayTitle)
                .font(.headline)
                .foregroundColor(.primary)
                .contextMenu {
                    boardHeaderContextMenu
                }

            Spacer()

            // Layout picker
            Picker("Layout", selection: $board.layout) {
                Text("Freeform").tag(Layout.freeform)
                Text("Kanban").tag(Layout.kanban)
                Text("Grid").tag(Layout.grid)
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            .onChange(of: board.layout) { newLayout in
                onLayoutChanged?(newLayout)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Board Header Context Menu

    @ViewBuilder
    private var boardHeaderContextMenu: some View {
        Button("Rename Board...", systemImage: "pencil") {
            NotificationCenter.default.post(
                name: NSNotification.Name("RenameBaord"),
                object: board.id
            )
        }
        .keyboardShortcut("r", modifiers: .command)
        .accessibilityLabel("Rename this board")

        Button("Duplicate Board", systemImage: "doc.on.doc") {
            NotificationCenter.default.post(
                name: NSNotification.Name("DuplicateBoard"),
                object: board.id
            )
        }
        .keyboardShortcut("d", modifiers: [.command, .shift])
        .accessibilityLabel("Create a duplicate of this board")

        Divider()

        Button("Export Board...", systemImage: "square.and.arrow.up.on.square") {
            NotificationCenter.default.post(
                name: NSNotification.Name("ExportBoard"),
                object: board.id
            )
        }
        .keyboardShortcut("e", modifiers: [.command, .shift])
        .accessibilityLabel("Export board and its tasks")

        Button("Share Board...", systemImage: "square.and.arrow.up") {
            #if os(macOS)
            NotificationCenter.default.post(
                name: NSNotification.Name("ShareBoard"),
                object: board.id
            )
            #endif
        }
        .accessibilityLabel("Share board using system share sheet")

        Divider()

        Button("Board Settings...", systemImage: "gear") {
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenBoardSettings"),
                object: board.id
            )
        }
        .accessibilityLabel("Open board settings")

        Divider()

        if !board.isBuiltIn {
            Button("Delete Board", systemImage: "trash", role: .destructive) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeleteBoard"),
                    object: board.id
                )
            }
            .accessibilityLabel("Delete this board")
        }
    }

    // MARK: - Layout Content

    @ViewBuilder
    private var layoutContent: some View {
        switch board.layout {
        case .freeform:
            freeformLayout
        case .kanban:
            kanbanLayout
        case .grid:
            gridLayout
        }
    }

    // MARK: - Freeform Layout

    private var freeformLayout: some View {
        ZStack {
            // Canvas background with grid
            canvasBackground

            // Task notes
            canvasContent

            // Lasso selection overlay (if active)
            if let selection = viewModel.lassoSelection {
                lassoSelectionOverlay(selection)
            }
        }
    }

    // MARK: - Kanban Layout

    private var kanbanLayout: some View {
        KanbanLayoutView(
            board: board,
            tasks: $tasks,
            selectedTaskIds: $selectedTaskIds,
            onTaskSelected: onTaskSelected,
            onTaskUpdated: onTaskUpdated,
            onCreateTask: { column in
                // Create task in specific column
                // For now, just call the general create task handler
                onCreateTask(Position(x: 0, y: 0))
            }
        )
    }

    // MARK: - Grid Layout

    private var gridLayout: some View {
        GridLayoutView(
            board: board,
            tasks: $tasks,
            selectedTaskIds: $selectedTaskIds,
            onTaskSelected: onTaskSelected,
            onTaskUpdated: onTaskUpdated,
            onCreateTask: { section in
                // Create task in specific section
                // For now, just call the general create task handler
                onCreateTask(Position(x: 0, y: 0))
            }
        )
    }

    // MARK: - Canvas Background

    private var canvasBackground: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.05))
            .overlay(
                Group {
                    if showGrid {
                        gridPattern
                    }
                }
            )
            .gesture(canvasGesture)
    }

    private var gridPattern: some View {
        Canvas { context, size in
            let gridSpacing: CGFloat = 50 * scale
            let offsetX = offset.width.truncatingRemainder(dividingBy: gridSpacing)
            let offsetY = offset.height.truncatingRemainder(dividingBy: gridSpacing)

            context.stroke(
                Path { path in
                    // Vertical lines
                    var x = offsetX
                    while x < size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += gridSpacing
                    }

                    // Horizontal lines
                    var y = offsetY
                    while y < size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += gridSpacing
                    }
                },
                with: .color(.gray.opacity(0.2)),
                lineWidth: 0.5
            )
        }
    }

    // MARK: - Canvas Content

    private var canvasContent: some View {
        ZStack {
            ForEach(boardTasks) { task in
                taskNoteView(for: task)
            }
        }
        .scaleEffect(scale)
        .offset(offset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Task Note View

    private func taskNoteView(for task: Task) -> some View {
        let position = task.position(for: board.id) ?? Position(x: 0, y: 0)
        let isSelected = selectedTaskIds.contains(task.id)

        // Calculate subtask progress if task has subtasks
        let subtaskProgress: (completed: Int, total: Int)? = {
            guard task.hasSubtasks else { return nil }
            let subtaskIds = task.subtaskIds
            let subtasks = tasks.filter { subtaskIds.contains($0.id) }
            guard !subtasks.isEmpty else { return nil }
            let completed = subtasks.filter { $0.status == .completed }.count
            return (completed, subtasks.count)
        }()

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

        return TaskNoteView(
            task: taskBinding,
            isSelected: isSelected,
            subtaskProgress: subtaskProgress,
            onTap: {
                handleTaskTap(task.id)
            },
            onDragStart: {
                viewModel.startDraggingTask(task.id)
            },
            onDragChange: { delta in
                handleTaskDrag(task: task, delta: delta)
            },
            onDragEnd: {
                viewModel.endDraggingTask()
            },
            onDelete: {
                // Delete task from board
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    let taskToDelete = tasks[index]
                    tasks.remove(at: index)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("DeleteTask"),
                        object: taskToDelete.id
                    )
                }
            }
        )
        .position(x: position.x, y: position.y)
    }

    // MARK: - Canvas Gesture

    private var canvasGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if NSEvent.modifierFlags.contains(.option) {
                    // Lasso selection mode
                    if viewModel.lassoSelection == nil {
                        viewModel.startLasso(at: value.startLocation)
                    }
                    viewModel.updateLasso(to: value.location)
                } else {
                    // Pan canvas mode
                    offset = CGSize(
                        width: value.translation.width,
                        height: value.translation.height
                    )
                }
            }
            .onEnded { _ in
                if viewModel.lassoSelection != nil {
                    handleLassoSelection()
                }
            }
            .simultaneously(with:
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(0.25, min(4.0, value))
                    }
            )
    }

    // MARK: - Lasso Selection Overlay

    private func lassoSelectionOverlay(_ selection: LassoSelection) -> some View {
        let rect = CGRect(
            x: min(selection.start.x, selection.end.x),
            y: min(selection.start.y, selection.end.y),
            width: abs(selection.end.x - selection.start.x),
            height: abs(selection.end.y - selection.start.y)
        )

        return Rectangle()
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    // MARK: - Event Handlers

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

    private func handleTaskDrag(task: Task, delta: CGSize) {
        // Update task position
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            let currentPosition = tasks[index].position(for: board.id) ?? Position(x: 0, y: 0)
            let newPosition = Position(
                x: currentPosition.x + delta.width / scale,
                y: currentPosition.y + delta.height / scale
            )

            tasks[index].setPosition(newPosition, for: board.id)
            onTaskUpdated(tasks[index])
        }
    }

    private func handleLassoSelection() {
        guard let lasso = viewModel.lassoSelection else { return }

        let rect = CGRect(
            x: min(lasso.start.x, lasso.end.x),
            y: min(lasso.start.y, lasso.end.y),
            width: abs(lasso.end.x - lasso.start.x),
            height: abs(lasso.end.y - lasso.start.y)
        )

        // Find tasks within lasso rectangle
        var newSelection = Set<UUID>()

        for task in boardTasks {
            if let position = task.position(for: board.id) {
                let point = CGPoint(x: position.x, y: position.y)
                if rect.contains(point) {
                    newSelection.insert(task.id)
                }
            }
        }

        selectedTaskIds = newSelection
        viewModel.endLasso()
    }

    private func loadTasksIntoViewModel() {
        // Sync board tasks into the view model
        // This allows the view model to track state for canvas interactions
        viewModel.loadTasks(boardTasks, for: board.id)
    }
}

// MARK: - Task Note View

struct TaskNoteView: View {
    @Binding var task: Task
    let isSelected: Bool
    let subtaskProgress: (completed: Int, total: Int)?
    let onTap: () -> Void
    let onDragStart: () -> Void
    let onDragChange: (CGSize) -> Void
    let onDragEnd: () -> Void
    let onDelete: (() -> Void)?

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(task.title)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(3)

            // Metadata badges
            HStack(spacing: 4) {
                // Subtask progress
                if let progress = subtaskProgress, progress.total > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "checklist")
                            .font(.system(size: 9))
                        Text("\(progress.completed)/\(progress.total)")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(
                            progress.completed == progress.total
                                ? Color.green.opacity(0.2)
                                : Color.orange.opacity(0.2)
                        )
                    )
                    .foregroundColor(
                        progress.completed == progress.total
                            ? .green
                            : .orange
                    )
                }

                if let context = task.context {
                    Text(context)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.2)))
                }

                if task.flagged {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }

                if task.priority == .high {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .frame(width: 160, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(noteColor)
                .shadow(color: .black.opacity(0.1), radius: isSelected ? 4 : 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .offset(dragOffset)
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if dragOffset == .zero {
                        onDragStart()
                    }
                    dragOffset = value.translation
                    onDragChange(value.translation)
                }
                .onEnded { _ in
                    dragOffset = .zero
                    onDragEnd()
                }
        )
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
                task.status = .completed
            }
        } else {
            Button("Reopen", systemImage: "arrow.uturn.backward.circle") {
                task.status = .nextAction
            }
        }

        Button(task.flagged ? "Unflag" : "Flag", systemImage: task.flagged ? "star.slash.fill" : "star.fill") {
            task.flagged.toggle()
        }

        Divider()

        // SECTION 2: Status & Priority
        Menu("Status", systemImage: "text.badge.checkmark") {
            Button("Inbox", systemImage: task.status == .inbox ? "checkmark" : "") {
                task.status = .inbox
            }

            Button("Next Action", systemImage: task.status == .nextAction ? "checkmark" : "") {
                task.status = .nextAction
            }

            Button("Waiting", systemImage: task.status == .waiting ? "checkmark" : "") {
                task.status = .waiting
            }

            Button("Someday", systemImage: task.status == .someday ? "checkmark" : "") {
                task.status = .someday
            }

            if task.status != .completed {
                Divider()

                Button("Completed", systemImage: task.status == .completed ? "checkmark" : "") {
                    task.status = .completed
                }
            }
        }

        Menu("Priority", systemImage: priorityIcon) {
            Button("High", systemImage: task.priority == .high ? "checkmark" : "") {
                task.priority = .high
            }

            Button("Medium", systemImage: task.priority == .medium ? "checkmark" : "") {
                task.priority = .medium
            }

            Button("Low", systemImage: task.priority == .low ? "checkmark" : "") {
                task.priority = .low
            }
        }

        Divider()

        // SECTION 3: Time Management
        Menu("Due Date", systemImage: "calendar") {
            Button("Today", systemImage: "calendar.badge.clock") {
                task.due = Calendar.current.startOfDay(for: Date())
            }

            Button("Tomorrow", systemImage: "calendar") {
                task.due = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))
            }

            Button("This Week", systemImage: "calendar.badge.plus") {
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
                // This would open a date picker
            }

            if task.due != nil {
                Divider()

                Button("Clear Due Date", systemImage: "calendar.badge.minus") {
                    task.due = nil
                }
            }
        }

        Divider()

        // SECTION 4: Organization
        Menu("Move to Project", systemImage: "folder") {
            Button("No Project", systemImage: task.project == nil ? "checkmark" : "") {
                task.project = nil
            }

            Divider()

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

        // SECTION 5: Board Management
        Menu("Add to Board", systemImage: "square.grid.2x2") {
            Button("Inbox", systemImage: "tray") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddTaskToBoard"),
                    object: ["taskId": task.id, "boardId": "inbox"]
                )
            }

            Button("Next Actions", systemImage: "arrow.right.circle") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddTaskToBoard"),
                    object: ["taskId": task.id, "boardId": "next-actions"]
                )
            }

            Button("Flagged", systemImage: "flag") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddTaskToBoard"),
                    object: ["taskId": task.id, "boardId": "flagged"]
                )
            }

            Divider()

            Button("New Board...", systemImage: "plus.square") {
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

            Button("Copy as Markdown", systemImage: "doc.text") {
                let markdown = generateMarkdown(for: task)
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(markdown, forType: .string)
                #endif
            }

            Button("Copy Link", systemImage: "link") {
                let link = "stickytodo://task/\(task.id.uuidString)"
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(link, forType: .string)
                #endif
            }

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
            let sharingItems = [task.title, generateMarkdown(for: task)]
            NotificationCenter.default.post(
                name: NSNotification.Name("ShareTask"),
                object: ["taskId": task.id, "items": sharingItems]
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
                    object: task.id
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
                object: task.id
            )
        }

        if task.status == .completed {
            Button("Archive", systemImage: "archivebox") {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ArchiveTask"),
                    object: task.id
                )
            }
        }

        if let deleteHandler = onDelete {
            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteHandler()
            }
        }
    }

    // MARK: - Helper Properties

    private var noteColor: Color {
        // Use task color if available
        if let colorHex = task.color {
            return Color(hexString: colorHex).opacity(0.3)
        }

        // Otherwise, use status-based colors
        switch task.status {
        case .completed:
            return Color.green.opacity(0.2)
        case .waiting:
            return Color.orange.opacity(0.2)
        case .someday:
            return Color.purple.opacity(0.2)
        default:
            return Color.yellow.opacity(0.3)
        }
    }

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

    // MARK: - Helper Methods

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
}

// MARK: - Board Canvas View Model

class BoardCanvasViewModel: ObservableObject {
    @Published var lassoSelection: LassoSelection?
    @Published var draggedTaskId: UUID?

    private var currentBoardId: String = ""
    private var currentTasks: [Task] = []

    func loadTasks(_ tasks: [Task], for boardId: String) {
        currentBoardId = boardId
        currentTasks = tasks
    }

    func startLasso(at point: CGPoint) {
        lassoSelection = LassoSelection(start: point, end: point)
    }

    func updateLasso(to point: CGPoint) {
        lassoSelection?.end = point
    }

    func endLasso() {
        lassoSelection = nil
    }

    func startDraggingTask(_ taskId: UUID) {
        draggedTaskId = taskId
    }

    func endDraggingTask() {
        draggedTaskId = nil
    }
}

// MARK: - Lasso Selection

struct LassoSelection {
    var start: CGPoint
    var end: CGPoint
}

// MARK: - Preview

#Preview("Board Canvas - Freeform") {
    BoardCanvasView(
        board: .constant(Board.inbox),
        tasks: .constant([
            Task(
                title: "Call John",
                status: .inbox,
                context: "@phone",
                priority: .high,
                positions: ["inbox": Position(x: 200, y: 150)]
            ),
            Task(
                title: "Review mockups",
                status: .nextAction,
                project: "Website",
                positions: ["inbox": Position(x: 400, y: 200)]
            ),
            Task(
                title: "Write report",
                status: .completed,
                positions: ["inbox": Position(x: 300, y: 350)]
            ),
        ]),
        selectedTaskIds: .constant([]),
        onTaskSelected: { _ in },
        onTaskUpdated: { _ in },
        onCreateTask: { _ in }
    )
}

#Preview("Board Canvas - Kanban") {
    BoardCanvasView(
        board: .constant(Board(
            id: "next-actions",
            type: .status,
            layout: .kanban,
            filter: Filter(status: .nextAction),
            columns: ["To Do", "In Progress", "Done"]
        )),
        tasks: .constant([
            Task(
                title: "Call John",
                status: .inbox,
                context: "@phone",
                priority: .high
            ),
            Task(
                title: "Review mockups",
                status: .nextAction,
                project: "Website"
            ),
            Task(
                title: "Write report",
                status: .completed
            ),
        ]),
        selectedTaskIds: .constant([]),
        onTaskSelected: { _ in },
        onTaskUpdated: { _ in },
        onCreateTask: { _ in }
    )
}

#Preview("Board Canvas - Grid") {
    BoardCanvasView(
        board: .constant(Board(
            id: "flagged",
            type: .custom,
            layout: .grid,
            filter: Filter(flagged: true)
        )),
        tasks: .constant([
            Task(
                title: "Critical bug fix",
                status: .nextAction,
                priority: .high
            ),
            Task(
                title: "Update docs",
                status: .nextAction,
                priority: .medium
            ),
            Task(
                title: "Clean up",
                status: .nextAction,
                priority: .low
            ),
        ]),
        selectedTaskIds: .constant([]),
        onTaskSelected: { _ in },
        onTaskUpdated: { _ in },
        onCreateTask: { _ in }
    )
}
