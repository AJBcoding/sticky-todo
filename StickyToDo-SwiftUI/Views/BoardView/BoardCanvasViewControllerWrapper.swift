//
//  BoardCanvasViewControllerWrapper.swift
//  StickyToDo-SwiftUI
//
//  NSViewControllerRepresentable wrapper for the AppKit BoardCanvasViewController.
//  Enables integration of the high-performance AppKit canvas into SwiftUI.
//

import SwiftUI
import AppKit

/// SwiftUI wrapper for the AppKit BoardCanvasViewController
///
/// This wrapper bridges the AppKit canvas implementation with SwiftUI,
/// providing:
/// - Pan/zoom/lasso selection functionality from AppKit
/// - Layout switching (freeform, kanban, grid)
/// - Task position tracking and updates
/// - Integration with SwiftUI data stores
///
/// Usage:
/// ```swift
/// BoardCanvasViewControllerWrapper(
///     board: $currentBoard,
///     tasks: $tasks,
///     onTaskCreated: { task in ... },
///     onTaskUpdated: { task in ... }
/// )
/// ```
struct BoardCanvasViewControllerWrapper: NSViewControllerRepresentable {

    // MARK: - Properties

    /// The current board being displayed
    @Binding var board: Board

    /// All tasks (will be filtered by board)
    @Binding var tasks: [Task]

    /// Currently selected task IDs
    @Binding var selectedTaskIds: Set<UUID>

    /// Callback when a new task is created
    var onTaskCreated: (Task) -> Void

    /// Callback when a task is updated
    var onTaskUpdated: (Task) -> Void

    /// Callback when task selection changes
    var onSelectionChanged: ([UUID]) -> Void

    // MARK: - NSViewControllerRepresentable

    /// Creates the AppKit view controller
    func makeNSViewController(context: Context) -> BoardCanvasViewController {
        let viewController = BoardCanvasViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    /// Updates the AppKit view controller when SwiftUI state changes
    func updateNSViewController(_ viewController: BoardCanvasViewController, context: Context) {
        // Update board if changed
        if viewController.currentBoard?.id != board.id {
            viewController.setBoard(board)
        }

        // Update tasks
        viewController.setTasks(tasks)

        // Update coordinator bindings
        context.coordinator.selectedTaskIds = $selectedTaskIds
        context.coordinator.onTaskCreated = onTaskCreated
        context.coordinator.onTaskUpdated = onTaskUpdated
        context.coordinator.onSelectionChanged = onSelectionChanged
    }

    /// Creates the coordinator for managing callbacks
    func makeCoordinator() -> Coordinator {
        Coordinator(
            selectedTaskIds: $selectedTaskIds,
            onTaskCreated: onTaskCreated,
            onTaskUpdated: onTaskUpdated,
            onSelectionChanged: onSelectionChanged
        )
    }

    // MARK: - Coordinator

    /// Coordinator handles communication between AppKit and SwiftUI
    class Coordinator: NSObject, BoardCanvasDelegate {

        // MARK: - Properties

        /// Binding to selected task IDs
        var selectedTaskIds: Binding<Set<UUID>>

        /// Callback for task creation
        var onTaskCreated: (Task) -> Void

        /// Callback for task updates
        var onTaskUpdated: (Task) -> Void

        /// Callback for selection changes
        var onSelectionChanged: ([UUID]) -> Void

        // MARK: - Initialization

        init(
            selectedTaskIds: Binding<Set<UUID>>,
            onTaskCreated: @escaping (Task) -> Void,
            onTaskUpdated: @escaping (Task) -> Void,
            onSelectionChanged: @escaping ([UUID]) -> Void
        ) {
            self.selectedTaskIds = selectedTaskIds
            self.onTaskCreated = onTaskCreated
            self.onTaskUpdated = onTaskUpdated
            self.onSelectionChanged = onSelectionChanged
        }

        // MARK: - BoardCanvasDelegate

        func boardCanvasDidCreateTask(_ task: Task) {
            // Call the SwiftUI callback
            onTaskCreated(task)
        }

        func boardCanvasDidUpdateTask(_ task: Task) {
            // Call the SwiftUI callback
            onTaskUpdated(task)
        }

        func boardCanvasDidSelectTask(_ task: Task?) {
            // Update selection in SwiftUI
            if let task = task {
                selectedTaskIds.wrappedValue = [task.id]
                onSelectionChanged([task.id])
            } else {
                selectedTaskIds.wrappedValue = []
                onSelectionChanged([])
            }
        }

        func boardCanvasDidPromoteNotes(_ tasks: [Task]) {
            // Update all promoted tasks
            for task in tasks {
                onTaskUpdated(task)
            }
        }
    }
}

// MARK: - Preview

#Preview("AppKit Canvas Wrapper") {
    BoardCanvasViewControllerWrapper(
        board: .constant(Board.inbox),
        tasks: .constant([
            Task(
                title: "Design mockups",
                status: .nextAction,
                positions: ["inbox": Position(x: 200, y: 150)]
            ),
            Task(
                title: "Review code",
                status: .nextAction,
                positions: ["inbox": Position(x: 400, y: 200)]
            ),
            Task(
                title: "Update docs",
                status: .completed,
                positions: ["inbox": Position(x: 300, y: 350)]
            ),
        ]),
        selectedTaskIds: .constant([]),
        onTaskCreated: { task in
            print("Task created: \(task.title)")
        },
        onTaskUpdated: { task in
            print("Task updated: \(task.title)")
        },
        onSelectionChanged: { ids in
            print("Selection changed: \(ids.count) tasks")
        }
    )
    .frame(width: 800, height: 600)
}
