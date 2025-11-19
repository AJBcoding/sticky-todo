//
//  CanvasContainerView.swift
//  StickyToDo
//
//  Container view providing toolbar and controls for the board canvas.
//

import SwiftUI

/// Container view that wraps the board canvas with toolbar and controls
///
/// Features:
/// - Toolbar with board title and controls
/// - Zoom controls (+/- buttons and reset)
/// - Grid toggle
/// - Stats panel toggle
/// - Add task button
/// - Selection info
struct CanvasContainerView: View {

    // MARK: - Properties

    /// The current board
    let board: Board

    /// All tasks
    @Binding var tasks: [Task]

    /// Selected task IDs
    @Binding var selectedTaskIds: Set<UUID>

    /// Callbacks
    var onTaskSelected: (UUID) -> Void
    var onTaskUpdated: (Task) -> Void
    var onCreateTask: (Position) -> Void
    var onBoardSettingsRequested: () -> Void

    // MARK: - State

    @State private var showGrid = true
    @State private var showStats = false
    @State private var zoomLevel: CGFloat = 1.0

    // MARK: - Computed Properties

    private var boardTaskCount: Int {
        tasks.filter { $0.matches(board.filter) }.count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Canvas
            BoardCanvasView(
                board: board,
                tasks: $tasks,
                selectedTaskIds: $selectedTaskIds,
                onTaskSelected: onTaskSelected,
                onTaskUpdated: onTaskUpdated,
                onCreateTask: onCreateTask
            )

            // Stats panel (if enabled)
            if showStats {
                Divider()
                statsPanel
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 16) {
            // Board icon and title
            HStack(spacing: 8) {
                if let icon = board.icon {
                    Text(icon)
                        .font(.title2)
                        .accessibilityHidden(true)
                }

                Text(board.displayTitle)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Board: \(board.displayTitle)")

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
                .accessibilityHidden(true)

            // Zoom controls
            HStack(spacing: 8) {
                Button(action: { zoomOut() }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .help("Zoom Out")
                .disabled(zoomLevel <= 0.25)
                .accessibilityLabel("Zoom out")
                .accessibilityHint("Decrease canvas zoom level")

                Text("\(Int(zoomLevel * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
                    .accessibilityLabel("Zoom level: \(Int(zoomLevel * 100)) percent")

                Button(action: { zoomIn() }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .help("Zoom In")
                .disabled(zoomLevel >= 4.0)
                .accessibilityLabel("Zoom in")
                .accessibilityHint("Increase canvas zoom level")

                Button(action: { resetZoom() }) {
                    Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                }
                .help("Reset Zoom")
                .accessibilityLabel("Reset zoom")
                .accessibilityHint("Reset canvas zoom to 100 percent")
            }
            .buttonStyle(.borderless)
            .accessibilityElement(children: .contain)

            Divider()
                .frame(height: 20)
                .accessibilityHidden(true)

            // Grid toggle
            Button(action: { showGrid.toggle() }) {
                Image(systemName: showGrid ? "square.grid.3x3.fill" : "square.grid.3x3")
            }
            .help("Toggle Grid")
            .buttonStyle(.borderless)
            .accessibilityLabel(showGrid ? "Hide grid" : "Show grid")
            .accessibilityHint("Toggle canvas grid visibility")

            // Stats toggle
            Button(action: { showStats.toggle() }) {
                Image(systemName: showStats ? "chart.bar.fill" : "chart.bar")
            }
            .help("Toggle Stats")
            .buttonStyle(.borderless)
            .accessibilityLabel(showStats ? "Hide stats" : "Show stats")
            .accessibilityHint("Toggle statistics panel visibility")

            Divider()
                .frame(height: 20)
                .accessibilityHidden(true)

            // Add task button
            Button(action: { addTaskAtCenter() }) {
                Label("Add Task", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Add new task to board")
            .accessibilityHint("Create a new task at the center of the canvas")

            // Board settings
            Button(action: onBoardSettingsRequested) {
                Image(systemName: "gear")
            }
            .help("Board Settings")
            .buttonStyle(.borderless)
            .accessibilityLabel("Board settings")
            .accessibilityHint("Open board configuration settings")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Stats Panel

    private var statsPanel: some View {
        HStack(spacing: 24) {
            statItem("Total Tasks", value: "\(boardTaskCount)")

            if !selectedTaskIds.isEmpty {
                statItem("Selected", value: "\(selectedTaskIds.count)")
            }

            statItem("Zoom", value: "\(Int(zoomLevel * 100))%")

            Spacer()

            // Layout info
            HStack(spacing: 8) {
                Image(systemName: layoutIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                Text(board.layout.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Layout: \(board.layout.displayName)")

            // Board type info
            HStack(spacing: 8) {
                Image(systemName: boardTypeIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                Text(board.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Board type: \(board.type.displayName)")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Board statistics")
    }

    private func statItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var layoutIcon: String {
        switch board.layout {
        case .freeform:
            return "square.on.square.dashed"
        case .kanban:
            return "square.split.3x1"
        case .grid:
            return "square.grid.3x2"
        }
    }

    private var boardTypeIcon: String {
        switch board.type {
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

    // MARK: - Helper Methods

    private func zoomIn() {
        zoomLevel = min(4.0, zoomLevel * 1.2)
    }

    private func zoomOut() {
        zoomLevel = max(0.25, zoomLevel / 1.2)
    }

    private func resetZoom() {
        zoomLevel = 1.0
    }

    private func addTaskAtCenter() {
        // Add task at center of visible canvas area
        // This is a simplified implementation - in production you'd calculate
        // the actual center of the viewport considering pan and zoom
        let centerPosition = Position(x: 400, y: 300)
        onCreateTask(centerPosition)
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

#Preview("Canvas Container") {
    CanvasContainerView(
        board: Board.projectBoard(name: "Website Redesign"),
        tasks: .constant([
            Task(
                title: "Design mockups",
                status: .nextAction,
                project: "Website Redesign",
                positions: ["website-redesign": Position(x: 200, y: 150)]
            ),
            Task(
                title: "Review content",
                status: .nextAction,
                project: "Website Redesign",
                positions: ["website-redesign": Position(x: 400, y: 200)]
            ),
        ]),
        selectedTaskIds: .constant([]),
        onTaskSelected: { _ in },
        onTaskUpdated: { _ in },
        onCreateTask: { _ in },
        onBoardSettingsRequested: {}
    )
}
