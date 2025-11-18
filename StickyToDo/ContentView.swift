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

    // MARK: - State

    /// All tasks
    @State private var tasks: [Task] = []

    /// All perspectives
    @State private var perspectives: [Perspective] = Perspective.builtInPerspectives

    /// All boards
    @State private var boards: [Board] = Board.builtInBoards

    /// All contexts
    @State private var contexts: [Context] = Context.defaults

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

    // MARK: - Computed Properties

    /// Currently selected task
    private var selectedTask: Task? {
        guard let firstId = selectedTaskIds.first else { return nil }
        return tasks.first(where: { $0.id == firstId })
    }

    /// Currently active perspective
    private var currentPerspective: Perspective? {
        guard let id = selectedPerspectiveId else { return nil }
        return perspectives.first(where: { $0.id == id })
    }

    /// Currently active board
    private var currentBoard: Board? {
        guard let id = selectedBoardId else { return nil }
        return boards.first(where: { $0.id == id })
    }

    // MARK: - Body

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            PerspectiveSidebarView(
                perspectives: perspectives,
                boards: boards,
                tasks: tasks,
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
                boards: boards,
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
        .onAppear {
            loadSampleData()
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
                    tasks: $tasks,
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
                CanvasContainerView(
                    board: board,
                    tasks: $tasks,
                    selectedTaskIds: $selectedTaskIds,
                    onTaskSelected: handleTaskSelected,
                    onTaskUpdated: saveTask,
                    onCreateTask: createTaskAtPosition,
                    onBoardSettingsRequested: showBoardSettings
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

    private var selectedTaskBinding: Binding<Task?> {
        Binding(
            get: {
                guard let firstId = selectedTaskIds.first,
                      let task = tasks.first(where: { $0.id == firstId }) else {
                    return nil
                }
                return task
            },
            set: { newValue in
                if let newValue = newValue,
                   let index = tasks.firstIndex(where: { $0.id == newValue.id }) {
                    tasks[index] = newValue
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
            status: .inbox
        )

        tasks.append(task)
        selectedTaskIds = [task.id]
    }

    private func createTaskAtPosition(_ position: Position) {
        guard let board = currentBoard else { return }

        var task = Task(
            title: "New Task",
            status: .inbox
        )

        task.setPosition(position, for: board.id)
        tasks.append(task)
        selectedTaskIds = [task.id]
    }

    private func deleteTask(_ taskId: UUID) {
        tasks.removeAll(where: { $0.id == taskId })
        selectedTaskIds.remove(taskId)
    }

    private func deleteSelectedTask() {
        guard let taskId = selectedTaskIds.first else { return }
        deleteTask(taskId)
    }

    private func duplicateSelectedTask() {
        guard let task = selectedTask else { return }
        let duplicate = task.duplicate()
        tasks.append(duplicate)
        selectedTaskIds = [duplicate.id]
    }

    private func saveTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
        // In a real app, this would save to disk/database
    }

    private func showSettings() {
        // Open settings window
        // This would typically open a separate settings window
        // For now, we'll just print
        print("Settings requested")
    }

    private func showBoardSettings() {
        // Open board settings
        print("Board settings requested")
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        // Load some sample tasks for demonstration
        tasks = [
            Task(
                title: "Call John about proposal",
                notes: "Discuss the new website design and timeline",
                status: .nextAction,
                project: "Website Redesign",
                context: "@phone",
                due: Date().addingTimeInterval(86400),
                flagged: true,
                priority: .high,
                effort: 30,
                positions: ["inbox": Position(x: 200, y: 150)]
            ),
            Task(
                title: "Review mockups",
                notes: "Check the latest design iterations",
                status: .nextAction,
                project: "Website Redesign",
                context: "@computer",
                priority: .medium,
                effort: 60,
                positions: ["inbox": Position(x: 400, y: 200)]
            ),
            Task(
                title: "Buy groceries",
                status: .nextAction,
                context: "@errands",
                priority: .low,
                effort: 45
            ),
            Task(
                title: "Write Q4 report",
                status: .waiting,
                project: "Q4 Planning",
                context: "@computer",
                due: Date().addingTimeInterval(7 * 86400),
                priority: .high,
                effort: 120
            ),
            Task(
                title: "Research new tools",
                status: .someday,
                project: "Q4 Planning",
                context: "@computer"
            ),
        ]

        // Add context boards for each context
        for context in contexts {
            boards.append(Board.contextBoard(for: context))
        }

        // Add project boards
        let projectNames = Set(tasks.compactMap { $0.project })
        for projectName in projectNames {
            boards.append(Board.projectBoard(name: projectName))
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}
