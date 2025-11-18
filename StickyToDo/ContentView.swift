//
//  ContentView.swift
//  StickyToDo
//
//  Main application view with three-column layout.
//

import SwiftUI

/// Main application content view
///
/// Features:
/// - NavigationSplitView with three columns:
///   - Sidebar: PerspectiveSidebarView
///   - Content: TaskListView OR BoardCanvasView (toggle)
///   - Detail: TaskInspectorView
/// - Toolbar with controls
/// - Searchable interface
/// - View mode switching (List/Board)
struct ContentView: View {

    // MARK: - Environment

    /// Task store managing all tasks
    @EnvironmentObject var taskStore: TaskStore

    /// Board store managing all boards
    @EnvironmentObject var boardStore: BoardStore

    /// Data manager for operations
    @EnvironmentObject var dataManager: DataManager

    /// Configuration manager
    @EnvironmentObject var configManager: ConfigurationManager

    // MARK: - State

    /// All perspectives (built-in)
    private var perspectives: [Perspective] {
        Perspective.builtInPerspectives
    }

    /// All contexts
    private var contexts: [Context] {
        Context.defaults
    }

    /// Selected perspective ID
    @State private var selectedPerspectiveId: String? = "inbox"

    /// Selected board ID
    @State private var selectedBoardId: String?

    /// Selected task IDs
    @State private var selectedTaskIds: Set<UUID> = []

    /// View mode (list or board)
    @State private var viewMode: ViewMode = .list

    /// Search query
    @State private var searchQuery: String = ""

    /// Column visibility
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    /// Error alert
    @State private var showingError = false
    @State private var errorMessage: String = ""

    // MARK: - Computed Properties

    /// Currently selected task
    private var selectedTask: Task? {
        guard let firstId = selectedTaskIds.first else { return nil }
        return taskStore.task(withID: firstId)
    }

    /// Currently active perspective
    private var currentPerspective: Perspective? {
        guard let id = selectedPerspectiveId else { return nil }
        return perspectives.first(where: { $0.id == id })
    }

    /// Currently active board
    private var currentBoard: Board? {
        guard let id = selectedBoardId else { return nil }
        return boardStore.board(withID: id)
    }

    // MARK: - Body

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            PerspectiveSidebarView(
                perspectives: perspectives,
                boards: boardStore.visibleBoards,
                tasks: taskStore.tasks,
                selectedPerspectiveId: $selectedPerspectiveId,
                selectedBoardId: $selectedBoardId,
                viewMode: $viewMode
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } content: {
            // Main content area (List or Board)
            mainContentView
                .navigationSplitViewColumnWidth(min: 400, ideal: 600)
        } detail: {
            // Inspector panel
            TaskInspectorView(
                task: selectedTaskBinding,
                contexts: contexts,
                boards: boardStore.visibleBoards,
                onDelete: deleteSelectedTask,
                onDuplicate: duplicateSelectedTask,
                onTaskModified: saveTask
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        }
        .navigationTitle("StickyToDo")
        .toolbar {
            toolbarContent
        }
        .searchable(text: $searchQuery, prompt: "Search tasks...")
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadInitialState()
        }
    }

    // MARK: - Main Content View

    @ViewBuilder
    private var mainContentView: some View {
        if viewMode == .list {
            // List view
            if let perspective = currentPerspective {
                TaskListView(
                    perspective: perspective,
                    tasks: taskStoreTasksBinding,
                    selectedTaskIds: $selectedTaskIds,
                    searchQuery: $searchQuery,
                    onTaskSelected: handleTaskSelected,
                    onDeleteTask: deleteTask,
                    onAddTask: addNewTask
                )
            } else {
                placeholderView
            }
        } else {
            // Board view
            if let board = currentBoard {
                BoardCanvasView(
                    board: board,
                    tasks: taskStoreTasksBinding,
                    selectedTaskIds: $selectedTaskIds,
                    onTaskSelected: handleTaskSelected,
                    onTaskUpdated: saveTask,
                    onCreateTask: createTaskAtPosition
                )
            } else {
                placeholderView
            }
        }
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Welcome to StickyToDo")
                .font(.title)

            Text("Select a perspective or board from the sidebar")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // View mode toggle
            Picker("View Mode", selection: $viewMode) {
                Label("List", systemImage: "list.bullet")
                    .tag(ViewMode.list)
                Label("Board", systemImage: "square.grid.3x2")
                    .tag(ViewMode.board)
            }
            .pickerStyle(.segmented)
            .frame(width: 140)

            Divider()

            // Add task button
            Button(action: addNewTask) {
                Label("Add Task", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
            .help("Add New Task (⌘N)")
        }

        ToolbarItem(placement: .automatic) {
            Button(action: showSettings) {
                Image(systemName: "gear")
            }
            .help("Settings")
        }
    }

    // MARK: - Bindings

    /// Binding to the TaskStore's tasks array
    private var taskStoreTasksBinding: Binding<[Task]> {
        Binding(
            get: { taskStore.tasks },
            set: { newTasks in
                // The TaskStore manages its own updates, so we don't set directly
                // This is primarily for child views that expect a binding
            }
        )
    }

    /// Binding to the currently selected task
    private var selectedTaskBinding: Binding<Task?> {
        Binding(
            get: {
                guard let firstId = selectedTaskIds.first,
                      let task = taskStore.task(withID: firstId) else {
                    return nil
                }
                return task
            },
            set: { newValue in
                if let newValue = newValue {
                    saveTask(newValue)
                }
            }
        )
    }

    // MARK: - Actions

    private func handleTaskSelected(_ taskId: UUID) {
        selectedTaskIds = [taskId]
    }

    private func addNewTask() {
        let task = Task(
            title: "New Task",
            status: configManager.defaultTaskStatus
        )

        taskStore.add(task)
        selectedTaskIds = [task.id]
    }

    private func createTaskAtPosition(_ position: Position) {
        guard let board = currentBoard else { return }

        var task = Task(
            title: "New Task",
            status: .inbox
        )

        task.setPosition(position, for: board.id)

        // If this is a context or project board, apply that metadata
        if board.type == .context {
            task.context = board.id
        } else if board.type == .project {
            task.project = board.displayTitle
        }

        taskStore.add(task)
        selectedTaskIds = [task.id]
    }

    private func deleteTask(_ taskId: UUID) {
        guard let task = taskStore.task(withID: taskId) else { return }
        taskStore.delete(task)
        selectedTaskIds.remove(taskId)
    }

    private func deleteSelectedTask() {
        guard let task = selectedTask else { return }
        taskStore.delete(task)
        selectedTaskIds.removeAll()
    }

    private func duplicateSelectedTask() {
        guard let task = selectedTask else { return }
        let duplicate = task.duplicate()
        taskStore.add(duplicate)
        selectedTaskIds = [duplicate.id]
    }

    private func saveTask(_ task: Task) {
        taskStore.update(task)
    }

    private func showSettings() {
        // Open settings window
        // This would typically open a separate settings window
        // For now, we'll just print
        print("Settings requested")
    }

    // MARK: - Initialization

    private func loadInitialState() {
        // Restore last selected perspective/board from configuration
        if let lastPerspectiveID = configManager.lastPerspectiveID {
            selectedPerspectiveId = lastPerspectiveID
            viewMode = .list
        } else if let lastBoardID = configManager.lastBoardID {
            selectedBoardId = lastBoardID
            viewMode = .board
        } else {
            // Default to inbox
            selectedPerspectiveId = "inbox"
            viewMode = .list
        }

        // Restore view mode
        viewMode = configManager.lastViewMode

        // Auto-create boards for contexts and projects
        autoCreateBoards()
    }

    private func autoCreateBoards() {
        // Auto-create context boards
        for context in contexts {
            _ = boardStore.getOrCreateContextBoard(for: context)
        }

        // Auto-create project boards
        for projectName in taskStore.projects {
            _ = boardStore.getOrCreateProjectBoard(for: projectName)
        }
    }

    private func showBoardSettings() {
        // Open board settings
        print("Board settings requested")
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}
