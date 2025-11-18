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
            Text(board.displayTitle)
                .font(.headline)
                .foregroundColor(.primary)

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

        return TaskNoteView(
            task: task,
            isSelected: isSelected,
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
    let task: Task
    let isSelected: Bool
    let onTap: () -> Void
    let onDragStart: () -> Void
    let onDragChange: (CGSize) -> Void
    let onDragEnd: () -> Void

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
    }

    private var noteColor: Color {
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
