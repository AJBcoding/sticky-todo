//
//  CanvasIntegrationTestView.swift
//  StickyToDo-SwiftUI
//
//  Test view for verifying canvas integration with data stores.
//  Tests layout switching, drag-drop, and performance.
//

import SwiftUI

/// Test view for canvas integration
///
/// This view provides a comprehensive test environment for:
/// - Canvas rendering with real task data
/// - Layout switching (freeform, kanban, grid)
/// - Drag-drop between list and canvas
/// - Performance with 50-100 tasks
/// - Pan, zoom, and lasso selection
struct CanvasIntegrationTestView: View {

    // MARK: - State Objects

    @StateObject private var taskStore: TaskStore
    @StateObject private var boardStore: BoardStore

    // MARK: - State

    @State private var testMode: TestMode = .basic
    @State private var showSideList = true
    @State private var currentBoard = Board.inbox

    // MARK: - Initialization

    init() {
        // Create temporary stores for testing
        let fileIO = MarkdownFileIO(rootPath: FileManager.default.temporaryDirectory.path)
        let taskStore = TaskStore(fileIO: fileIO)
        let boardStore = BoardStore(fileIO: fileIO)

        self._taskStore = StateObject(wrappedValue: taskStore)
        self._boardStore = StateObject(wrappedValue: boardStore)
    }

    // MARK: - Body

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(showSideList ? .all : .detailOnly)) {
            // Sidebar with test controls
            testControlsSidebar
        } detail: {
            // Main content
            HStack(spacing: 0) {
                // Canvas
                BoardCanvasIntegratedView(
                    taskStore: taskStore,
                    boardStore: boardStore,
                    board: currentBoard
                )

                // Optional task list
                if showSideList {
                    Divider()

                    TaskListView(
                        taskStore: taskStore,
                        filter: currentBoard.filter,
                        title: "Task List"
                    )
                    .frame(width: 350)
                }
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
        .onAppear {
            loadTestData()
        }
    }

    // MARK: - Test Controls Sidebar

    private var testControlsSidebar: some View {
        List {
            Section("Test Mode") {
                Picker("Data Set", selection: $testMode) {
                    Text("Basic (5 tasks)").tag(TestMode.basic)
                    Text("Medium (25 tasks)").tag(TestMode.medium)
                    Text("Performance (100 tasks)").tag(TestMode.performance)
                }
                .onChange(of: testMode) { _ in
                    loadTestData()
                }

                Button("Reload Test Data") {
                    loadTestData()
                }
            }

            Section("Board Selection") {
                Button("Inbox (Freeform)") {
                    currentBoard = Board.inbox
                }
                Button("Next Actions (Kanban)") {
                    currentBoard = Board.nextActions
                }
                Button("Today (Grid)") {
                    currentBoard = Board.today
                }
            }

            Section("View Options") {
                Toggle("Show Task List", isOn: $showSideList)
            }

            Section("Statistics") {
                VStack(alignment: .leading, spacing: 8) {
                    statRow("Total Tasks", value: "\(taskStore.taskCount)")
                    statRow("Active", value: "\(taskStore.activeTaskCount)")
                    statRow("Completed", value: "\(taskStore.completedTaskCount)")
                    statRow("Boards", value: "\(boardStore.boardCount)")
                }
            }

            Section("Performance Tests") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test these interactions:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("✓ Pan canvas with Option+drag")
                        .font(.caption2)
                    Text("✓ Zoom with Command+scroll")
                        .font(.caption2)
                    Text("✓ Lasso select with drag")
                        .font(.caption2)
                    Text("✓ Multi-select with Cmd+click")
                        .font(.caption2)
                    Text("✓ Drag tasks between views")
                        .font(.caption2)
                    Text("✓ Switch layouts smoothly")
                        .font(.caption2)
                }
            }
        }
        .navigationTitle("Canvas Tests")
        .frame(minWidth: 250)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Test Data Generation

    private func loadTestData() {
        // Clear existing tasks
        let existingTasks = taskStore.tasks
        for task in existingTasks {
            taskStore.delete(task)
        }

        // Generate test data based on mode
        let taskCount: Int
        switch testMode {
        case .basic:
            taskCount = 5
        case .medium:
            taskCount = 25
        case .performance:
            taskCount = 100
        }

        generateTestTasks(count: taskCount)

        // Add built-in boards
        boardStore.add(Board.inbox)
        boardStore.add(Board.nextActions)
        boardStore.add(Board.today)
    }

    private func generateTestTasks(count: Int) {
        let titles = [
            "Design mockups for homepage",
            "Review pull request #123",
            "Update documentation",
            "Fix login bug",
            "Implement search feature",
            "Write unit tests",
            "Deploy to staging",
            "Call client about feedback",
            "Research new frameworks",
            "Plan sprint activities",
            "Code review session",
            "Update dependencies",
            "Performance optimization",
            "Security audit",
            "Refactor authentication",
            "Add analytics tracking",
            "Design system updates",
            "Database migration",
            "API integration",
            "User testing session",
        ]

        let projects = ["Website Redesign", "Mobile App", "API v2", "Marketing Campaign", nil]
        let contexts = ["@office", "@home", "@phone", "@computer", nil]
        let statuses: [Status] = [.inbox, .nextAction, .nextAction, .waiting, .completed]
        let priorities: [Priority] = [.low, .medium, .medium, .high]

        for i in 0..<count {
            let title = titles[i % titles.count] + " (\(i + 1))"
            let status = statuses[i % statuses.count]
            let priority = priorities[i % priorities.count]
            let project = projects[i % projects.count]
            let context = contexts[i % contexts.count]

            // Generate position for freeform layout
            let column = i % 10
            let row = i / 10
            let x = Double(200 + column * 220)
            let y = Double(150 + row * 180)

            var task = Task(
                title: title,
                status: status,
                project: project,
                context: context,
                flagged: i % 7 == 0,
                priority: priority
            )

            // Set positions for different boards
            task.positions = [
                "inbox": Position(x: x, y: y),
                "next-actions": Position(x: x + 100, y: y + 50),
            ]

            taskStore.add(task)
        }
    }
}

// MARK: - Test Mode

enum TestMode {
    case basic
    case medium
    case performance
}

// MARK: - Preview

#Preview("Canvas Integration Test") {
    CanvasIntegrationTestView()
}
