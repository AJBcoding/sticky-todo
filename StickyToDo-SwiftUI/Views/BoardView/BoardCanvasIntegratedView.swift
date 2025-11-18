//
//  BoardCanvasIntegratedView.swift
//  StickyToDo-SwiftUI
//
//  Integrated board canvas view with data store connections.
//  Provides a complete board experience with task management and layout switching.
//

import SwiftUI

/// Integrated board canvas view with data store connectivity
///
/// This view provides:
/// - Connection to TaskStore for task data
/// - Connection to BoardStore for board configuration
/// - Reactive updates when data changes
/// - Layout switching controls
/// - Toolbar with board management features
struct BoardCanvasIntegratedView: View {

    // MARK: - Environment Objects

    /// Task data store
    @ObservedObject var taskStore: TaskStore

    /// Board data store
    @ObservedObject var boardStore: BoardStore

    // MARK: - State

    /// Current board being displayed
    @State private var currentBoard: Board

    /// Selected task IDs
    @State private var selectedTaskIds: Set<UUID> = []

    /// Show board settings sheet
    @State private var showBoardSettings = false

    /// Show task creation sheet
    @State private var showTaskCreation = false

    // MARK: - Initialization

    /// Creates an integrated board canvas view
    /// - Parameters:
    ///   - taskStore: The task data store
    ///   - boardStore: The board data store
    ///   - board: The initial board to display
    init(taskStore: TaskStore, boardStore: BoardStore, board: Board) {
        self.taskStore = taskStore
        self.boardStore = boardStore
        self._currentBoard = State(initialValue: board)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Canvas
            BoardCanvasViewControllerWrapper(
                board: $currentBoard,
                tasks: $taskStore.tasks,
                selectedTaskIds: $selectedTaskIds,
                onTaskCreated: handleTaskCreated,
                onTaskUpdated: handleTaskUpdated,
                onSelectionChanged: handleSelectionChanged
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Status bar
            statusBar
        }
        .sheet(isPresented: $showBoardSettings) {
            boardSettingsView
        }
        .sheet(isPresented: $showTaskCreation) {
            taskCreationView
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 16) {
            // Board icon and title
            HStack(spacing: 8) {
                if let icon = currentBoard.icon {
                    Text(icon)
                        .font(.title2)
                        .accessibilityHidden(true)
                }

                Text(currentBoard.displayTitle)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Board: \(currentBoard.displayTitle)")

            Spacer()

            // Task count
            Text("\(boardTaskCount) task\(boardTaskCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityLabel("\(boardTaskCount) task\(boardTaskCount == 1 ? "" : "s") on this board")

            // Selection info
            if !selectedTaskIds.isEmpty {
                Text("(\(selectedTaskIds.count) selected)")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .accessibilityLabel("\(selectedTaskIds.count) task\(selectedTaskIds.count == 1 ? "" : "s") selected")
            }

            Divider()
                .frame(height: 20)

            // Layout picker
            Picker("Layout", selection: $currentBoard.layout) {
                Label("Freeform", systemImage: "square.on.square.dashed")
                    .tag(Layout.freeform)
                Label("Kanban", systemImage: "square.split.3x1")
                    .tag(Layout.kanban)
                Label("Grid", systemImage: "square.grid.3x2")
                    .tag(Layout.grid)
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            .onChange(of: currentBoard.layout) { newLayout in
                handleLayoutChanged(newLayout)
            }
            .accessibilityLabel("Board layout")
            .accessibilityHint("Choose between freeform, kanban, or grid layout for this board")
            .accessibilityValue(currentBoard.layout.displayName)

            Divider()
                .frame(height: 20)

            // Add task button
            Button(action: { showTaskCreation = true }) {
                Label("Add Task", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Add new task to board")
            .accessibilityHint("Double-tap to create a new task on this board")

            // Board settings
            Button(action: { showBoardSettings = true }) {
                Image(systemName: "gear")
            }
            .help("Board Settings")
            .buttonStyle(.borderless)
            .accessibilityLabel("Board settings")
            .accessibilityHint("Double-tap to configure board settings")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 24) {
            // Task stats
            HStack(spacing: 16) {
                statItem("Total", value: "\(boardTaskCount)")
                statItem("Completed", value: "\(completedTaskCount)")
                statItem("Active", value: "\(activeTaskCount)")
            }
            .accessibilityElement(children: .contain)

            Spacer()

            // Layout info
            HStack(spacing: 8) {
                Image(systemName: layoutIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                Text(currentBoard.layout.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Layout: \(currentBoard.layout.displayName)")

            // Board type info
            HStack(spacing: 8) {
                Image(systemName: boardTypeIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                Text(currentBoard.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Board type: \(currentBoard.type.displayName)")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func statItem(_ label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Board Settings View

    private var boardSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Board Settings")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Form {
                TextField("Board Title", text: Binding(
                    get: { currentBoard.title ?? "" },
                    set: { currentBoard.title = $0.isEmpty ? nil : $0 }
                ))
                .accessibilityLabel("Board title")
                .accessibilityHint("Enter a custom title for this board")

                TextField("Icon (emoji)", text: Binding(
                    get: { currentBoard.icon ?? "" },
                    set: { currentBoard.icon = $0.isEmpty ? nil : $0 }
                ))
                .accessibilityLabel("Board icon")
                .accessibilityHint("Enter an emoji to use as the board icon")

                Toggle("Auto-hide when inactive", isOn: $currentBoard.autoHide)
                    .accessibilityLabel("Auto-hide when inactive")
                    .accessibilityHint("Automatically hide this board when not in use")

                if currentBoard.autoHide {
                    Stepper("Hide after \(currentBoard.hideAfterDays) days",
                            value: $currentBoard.hideAfterDays,
                            in: 1...30)
                        .accessibilityLabel("Hide after \(currentBoard.hideAfterDays) days")
                        .accessibilityHint("Set the number of days before auto-hiding")
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    showBoardSettings = false
                }
                .accessibilityLabel("Cancel board settings")
                .accessibilityHint("Discard changes and close settings")

                Button("Save") {
                    saveBoardSettings()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Save board settings")
                .accessibilityHint("Save changes and close settings")
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    // MARK: - Task Creation View

    private var taskCreationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Task")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("A new task will be created on the \(currentBoard.displayTitle) board")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Spacer()
                Button("Cancel") {
                    showTaskCreation = false
                }
                .accessibilityLabel("Cancel task creation")
                .accessibilityHint("Close without creating a task")

                Button("Create Task") {
                    createNewTask()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Create task")
                .accessibilityHint("Create a new task on this board")
            }
        }
        .padding()
        .frame(width: 400, height: 150)
    }

    // MARK: - Computed Properties

    private var boardTasks: [Task] {
        taskStore.tasks.filter { $0.matches(currentBoard.filter) }
    }

    private var boardTaskCount: Int {
        boardTasks.count
    }

    private var completedTaskCount: Int {
        boardTasks.filter { $0.status == .completed }.count
    }

    private var activeTaskCount: Int {
        boardTasks.filter { $0.status != .completed }.count
    }

    private var layoutIcon: String {
        switch currentBoard.layout {
        case .freeform:
            return "square.on.square.dashed"
        case .kanban:
            return "square.split.3x1"
        case .grid:
            return "square.grid.3x2"
        }
    }

    private var boardTypeIcon: String {
        switch currentBoard.type {
        case .context:
            return "mappin.circle"
        case .project:
            return "folder"
        case .status:
            return "checklist"
        case .custom:
            return "star"
        }
    }

    // MARK: - Event Handlers

    private func handleTaskCreated(_ task: Task) {
        taskStore.add(task)
    }

    private func handleTaskUpdated(_ task: Task) {
        taskStore.update(task)
    }

    private func handleSelectionChanged(_ taskIds: [UUID]) {
        selectedTaskIds = Set(taskIds)
    }

    private func handleLayoutChanged(_ newLayout: Layout) {
        // Save updated board configuration
        boardStore.update(currentBoard)
    }

    private func saveBoardSettings() {
        boardStore.update(currentBoard)
        showBoardSettings = false
    }

    private func createNewTask() {
        let task = Task(
            title: "New Task",
            status: .inbox,
            project: currentBoard.type == .project ? currentBoard.filter.project : nil,
            context: currentBoard.type == .context ? currentBoard.filter.context : nil
        )
        taskStore.add(task)
        showTaskCreation = false
    }
}

// MARK: - Layout Extension

extension Layout {
    var displayName: String {
        switch self {
        case .freeform:
            return "Freeform"
        case .kanban:
            return "Kanban"
        case .grid:
            return "Grid"
        }
    }

    var requiresColumns: Bool {
        self == .kanban
    }

    var supportsCustomPositions: Bool {
        self == .freeform
    }
}

// MARK: - BoardType Extension

extension BoardType {
    var displayName: String {
        switch self {
        case .context:
            return "Context"
        case .project:
            return "Project"
        case .status:
            return "Status"
        case .custom:
            return "Custom"
        }
    }
}

// MARK: - Preview

#Preview("Integrated Board Canvas") {
    // Create mock stores
    let fileIO = MarkdownFileIO(rootPath: FileManager.default.temporaryDirectory.path)
    let taskStore = TaskStore(fileIO: fileIO)
    let boardStore = BoardStore(fileIO: fileIO)

    // Add some test tasks
    taskStore.add(Task(
        title: "Design mockups",
        status: .nextAction,
        positions: ["inbox": Position(x: 200, y: 150)]
    ))
    taskStore.add(Task(
        title: "Review code",
        status: .nextAction,
        positions: ["inbox": Position(x: 400, y: 200)]
    ))

    return BoardCanvasIntegratedView(
        taskStore: taskStore,
        boardStore: boardStore,
        board: Board.inbox
    )
    .frame(width: 1000, height: 700)
}
