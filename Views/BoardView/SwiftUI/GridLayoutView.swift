//
//  GridLayoutView.swift
//  StickyToDo
//
//  SwiftUI Grid layout with section-based organization.
//  Tasks are organized in sections by priority, status, or time.
//

import SwiftUI

/// SwiftUI Grid layout view
///
/// Displays tasks organized in named sections (e.g., by priority, status, or time).
/// Tasks are arranged in a grid within each section with automatic positioning.
struct GridLayoutView: View {

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
    @State private var hoveredSectionId: String?

    /// Number of columns per row
    private let columnsPerRow = 3

    // MARK: - Computed Properties

    /// Tasks that appear on this board
    private var boardTasks: [Task] {
        tasks.filter { $0.matches(board.filter) }
    }

    /// Grid sections
    private var sections: [LayoutEngine.GridSection] {
        LayoutEngine.sectionsForBoard(board)
    }

    /// Grid columns layout
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: LayoutEngine.gridSpacing), count: columnsPerRow)
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(sections, id: \.id) { section in
                    gridSection(section: section)
                }
            }
            .padding(LayoutEngine.gridSpacing)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Section View

    private func gridSection(section: LayoutEngine.GridSection) -> some View {
        let sectionTasks = boardTasks.filter(section.filter)

        // Skip empty sections
        guard !sectionTasks.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: LayoutEngine.gridSpacing) {
                // Section header
                sectionHeader(section: section, taskCount: sectionTasks.count)

                // Tasks grid
                LazyVGrid(columns: gridColumns, spacing: LayoutEngine.gridSpacing) {
                    ForEach(sectionTasks) { task in
                        gridTaskCard(task: task, section: section)
                    }
                }
            }
            .padding(LayoutEngine.gridSpacing)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        hoveredSectionId == section.id ? Color.blue : Color.clear,
                        lineWidth: 2
                    )
            )
            .onDrop(of: [.text], isTargeted: nil) { providers in
                handleDrop(providers: providers, toSection: section.id)
            }
        )
    }

    // MARK: - Section Header

    private func sectionHeader(section: LayoutEngine.GridSection, taskCount: Int) -> some View {
        HStack {
            Text(section.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Text("\(taskCount)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                )

            Spacer()

            Button(action: {
                onCreateTask(section.id)
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Task Card

    private func gridTaskCard(task: Task, section: LayoutEngine.GridSection) -> some View {
        let isSelected = selectedTaskIds.contains(task.id)

        return VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(task.title)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(4)
                .foregroundColor(.primary)

            Spacer()

            // Metadata badges
            HStack(spacing: 4) {
                if task.priority == .high {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }

                if task.flagged {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                }

                if let context = task.context {
                    metadataBadge(text: context, color: .blue)
                }

                if task.isOverdue {
                    metadataBadge(text: "Overdue", color: .red)
                } else if task.isDueToday {
                    metadataBadge(text: "Today", color: .orange)
                }

                Spacer()
            }
        }
        .padding(10)
        .frame(width: LayoutEngine.gridCellWidth, height: LayoutEngine.gridCellHeight)
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
    }

    // MARK: - Metadata Badge

    private func metadataBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9))
            .foregroundColor(color)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
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

        if task.isOverdue {
            return Color.red.opacity(0.1)
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

    private func handleDrop(providers: [NSItemProvider], toSection sectionId: String) -> Bool {
        guard let provider = providers.first else { return false }

        // Show hover state
        hoveredSectionId = sectionId

        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { (item, error) in
            guard let data = item as? Data,
                  let taskIdString = String(data: data, encoding: .utf8),
                  let taskId = UUID(uuidString: taskIdString),
                  let taskIndex = tasks.firstIndex(where: { $0.id == taskId }) else {
                DispatchQueue.main.async {
                    self.hoveredSectionId = nil
                }
                return
            }

            DispatchQueue.main.async {
                // Apply metadata updates for the target section
                var updatedTask = tasks[taskIndex]
                let metadata = LayoutEngine.metadataUpdates(
                    forTask: updatedTask,
                    inSection: sectionId,
                    sections: sections
                )

                // Apply metadata
                for (key, value) in metadata {
                    switch key {
                    case "status":
                        if let statusString = value as? String,
                           let status = Status(rawValue: statusString) {
                            updatedTask.status = status
                        }
                    case "priority":
                        if let priorityString = value as? String,
                           let priority = Priority(rawValue: priorityString) {
                            updatedTask.priority = priority
                        }
                    case "context":
                        if let context = value as? String {
                            updatedTask.context = context
                        }
                    case "project":
                        if let project = value as? String {
                            updatedTask.project = project
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

                // Clear hover state
                self.hoveredSectionId = nil
            }
        }

        return true
    }
}

// MARK: - Preview

#Preview("Grid Layout - Priority Sections") {
    GridLayoutView(
        board: Board(
            id: "flagged",
            type: .custom,
            layout: .grid,
            filter: Filter(flagged: true)
        ),
        tasks: .constant([
            Task(
                title: "Critical bug fix",
                status: .nextAction,
                context: "@computer",
                priority: .high,
                flagged: true
            ),
            Task(
                title: "Update documentation",
                status: .nextAction,
                project: "Website",
                priority: .high
            ),
            Task(
                title: "Review pull requests",
                status: .nextAction,
                priority: .medium
            ),
            Task(
                title: "Organize files",
                status: .nextAction,
                priority: .medium
            ),
            Task(
                title: "Clean up code",
                status: .nextAction,
                priority: .low
            ),
            Task(
                title: "Update dependencies",
                status: .nextAction,
                priority: .low
            ),
        ]),
        selectedTaskIds: .constant([]),
        onTaskSelected: { _ in },
        onTaskUpdated: { _ in },
        onCreateTask: { _ in }
    )
    .frame(width: 900, height: 600)
}

#Preview("Grid Layout - Status Sections") {
    GridLayoutView(
        board: Board(
            id: "next-actions",
            type: .status,
            layout: .grid,
            filter: Filter(status: .nextAction)
        ),
        tasks: .constant([
            Task(
                title: "Process inbox",
                status: .inbox,
                priority: .high
            ),
            Task(
                title: "Call John",
                status: .nextAction,
                context: "@phone",
                priority: .high
            ),
            Task(
                title: "Review mockups",
                status: .nextAction,
                project: "Website"
            ),
            Task(
                title: "Waiting for feedback",
                status: .waiting
            ),
            Task(
                title: "Learn SwiftUI",
                status: .someday
            ),
        ]),
        selectedTaskIds: .constant([]),
        onTaskSelected: { _ in },
        onTaskUpdated: { _ in },
        onCreateTask: { _ in }
    )
    .frame(width: 900, height: 600)
}
