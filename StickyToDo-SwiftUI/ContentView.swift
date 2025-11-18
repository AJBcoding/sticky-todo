//
//  ContentView.swift
//  StickyToDo
//
//  Main application view with sidebar navigation and board/list display.
//

import SwiftUI

struct ContentView: View {

    // MARK: - State Objects

    /// Task data store
    @StateObject private var taskStore: TaskStore

    /// Board data store
    @StateObject private var boardStore: BoardStore

    // MARK: - State

    /// Currently selected board or list
    @State private var selectedView: NavigationItem? = .inbox

    // MARK: - Initialization

    init() {
        // Initialize file I/O
        let fileIO = MarkdownFileIO(rootPath: FileManager.default.homeDirectoryForCurrentUser.path)

        // Initialize stores
        let taskStore = TaskStore(fileIO: fileIO)
        let boardStore = BoardStore(fileIO: fileIO)

        self._taskStore = StateObject(wrappedValue: taskStore)
        self._boardStore = StateObject(wrappedValue: boardStore)
    }

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            // Sidebar
            sidebar
        } detail: {
            // Main content area
            if let selectedView = selectedView {
                detailView(for: selectedView)
            } else {
                emptyView
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .onAppear {
            loadData()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedView) {
            // Built-in Lists
            Section("Lists") {
                NavigationLink(value: NavigationItem.inbox) {
                    Label("Inbox", systemImage: "tray")
                }

                NavigationLink(value: NavigationItem.nextActions) {
                    Label("Next Actions", systemImage: "arrow.right.circle")
                }

                NavigationLink(value: NavigationItem.today) {
                    Label("Today", systemImage: "calendar")
                }

                NavigationLink(value: NavigationItem.flagged) {
                    Label("Flagged", systemImage: "flag.fill")
                }
            }

            // Project Boards
            Section("Projects") {
                ForEach(boardStore.projectBoards.filter { $0.isVisible }) { board in
                    NavigationLink(value: NavigationItem.board(board.id)) {
                        Label(board.displayTitle, systemImage: "folder")
                    }
                }
            }

            // Context Boards
            Section("Contexts") {
                ForEach(boardStore.contextBoards.filter { $0.isVisible }) { board in
                    NavigationLink(value: NavigationItem.board(board.id)) {
                        Label(board.displayTitle, systemImage: "mappin.circle")
                    }
                }
            }

            // Custom Boards
            if !boardStore.customBoards.isEmpty {
                Section("Custom Boards") {
                    ForEach(boardStore.customBoards.filter { $0.isVisible }) { board in
                        NavigationLink(value: NavigationItem.board(board.id)) {
                            Label {
                                Text(board.displayTitle)
                            } icon: {
                                if let icon = board.icon {
                                    Text(icon)
                                } else {
                                    Image(systemName: "star")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("StickyToDo")
        .frame(minWidth: 220)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
    }

    // MARK: - Detail View

    @ViewBuilder
    private func detailView(for item: NavigationItem) -> some View {
        switch item {
        case .inbox:
            boardView(for: Board.inbox)

        case .nextActions:
            boardView(for: Board.nextActions)

        case .today:
            boardView(for: Board.today)

        case .flagged:
            boardView(for: Board.flagged)

        case .board(let boardId):
            if let board = boardStore.board(withID: boardId) {
                boardView(for: board)
            } else {
                Text("Board not found")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func boardView(for board: Board) -> some View {
        BoardCanvasIntegratedView(
            taskStore: taskStore,
            boardStore: boardStore,
            board: board
        )
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 60))

            Text("Welcome to StickyToDo")
                .font(.title)

            Text("Select a list or board from the sidebar to get started")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 20)

            // Quick stats
            VStack(spacing: 8) {
                Text("Quick Stats")
                    .font(.headline)

                HStack(spacing: 24) {
                    statView(label: "Total Tasks", value: "\(taskStore.taskCount)")
                    statView(label: "Active", value: "\(taskStore.activeTaskCount)")
                    statView(label: "Completed", value: "\(taskStore.completedTaskCount)")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func statView(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helper Methods

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }

    private func loadData() {
        // Load data asynchronously
        Task {
            do {
                // Load boards first
                try await boardStore.loadAllAsync()

                // Then load tasks
                try await taskStore.loadAllAsync()

                // Load automation rules
                try taskStore.loadRules()
            } catch {
                print("Error loading data: \(error)")
            }
        }
    }
}

// MARK: - Navigation Item

enum NavigationItem: Hashable {
    case inbox
    case nextActions
    case today
    case flagged
    case board(String)
}

// MARK: - Built-in Boards

extension Board {
    /// Inbox board - all unprocessed tasks
    static let inbox = Board(
        id: "inbox",
        type: .status,
        layout: .freeform,
        filter: Filter(status: .inbox),
        title: "Inbox",
        icon: "📥",
        isBuiltIn: true,
        order: 0
    )

    /// Next Actions board - actionable tasks
    static let nextActions = Board(
        id: "next-actions",
        type: .status,
        layout: .kanban,
        filter: Filter(status: .nextAction),
        columns: ["To Do", "In Progress", "Done"],
        title: "Next Actions",
        icon: "▶️",
        isBuiltIn: true,
        order: 1
    )

    /// Today board - tasks due today
    static let today = Board(
        id: "today",
        type: .custom,
        layout: .grid,
        filter: Filter(isDueToday: true),
        title: "Today",
        icon: "📅",
        isBuiltIn: true,
        order: 2
    )

    /// Flagged board - flagged tasks
    static let flagged = Board(
        id: "flagged",
        type: .custom,
        layout: .grid,
        filter: Filter(flagged: true),
        title: "Flagged",
        icon: "⭐",
        isBuiltIn: true,
        order: 3
    )
}

// MARK: - Preview

#Preview {
    ContentView()
}
