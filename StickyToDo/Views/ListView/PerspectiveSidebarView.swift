//
//  PerspectiveSidebarView.swift
//  StickyToDo
//
//  Sidebar navigation for perspectives and boards.
//

import SwiftUI

/// Sidebar view for navigating between perspectives and boards
///
/// Features:
/// - Grouped sections with disclosure groups
/// - Badge counts for each perspective/board
/// - Selection binding
/// - Custom icons and colors
/// - Keyboard shortcuts (1-9 for quick navigation)
struct PerspectiveSidebarView: View {

    // MARK: - Properties

    /// All available perspectives
    let perspectives: [Perspective]

    /// All available boards
    let boards: [Board]

    /// All tasks (for counting badges)
    let tasks: [Task]

    /// Currently selected perspective ID
    @Binding var selectedPerspectiveId: String?

    /// Currently selected board ID
    @Binding var selectedBoardId: String?

    /// View mode (list or board)
    @Binding var viewMode: ViewMode

    // MARK: - State

    @State private var showContexts = true
    @State private var showProjects = true
    @State private var showCustomBoards = true

    // MARK: - Computed Properties

    /// Built-in GTD perspectives
    private var builtInPerspectives: [Perspective] {
        perspectives.filter { $0.isBuiltIn && $0.isVisible }
            .sorted { ($0.order ?? 999) < ($1.order ?? 999) }
    }

    /// Custom user perspectives
    private var customPerspectives: [Perspective] {
        perspectives.filter { !$0.isBuiltIn && $0.isVisible }
            .sorted { $0.name < $1.name }
    }

    /// Context boards
    private var contextBoards: [Board] {
        boards.filter { $0.type == .context && $0.isVisible }
            .sorted { ($0.order ?? 999) < ($1.order ?? 999) }
    }

    /// Project boards
    private var projectBoards: [Board] {
        boards.filter { $0.type == .project && $0.isVisible }
            .sorted { $0.displayTitle < $1.displayTitle }
    }

    /// Custom boards
    private var customBoards: [Board] {
        boards.filter { $0.type == .custom && !$0.isBuiltIn && $0.isVisible }
            .sorted { $0.displayTitle < $1.displayTitle }
    }

    // MARK: - Body

    var body: some View {
        List(selection: selectionBinding) {
            // GTD Perspectives
            Section("SMART") {
                ForEach(builtInPerspectives) { perspective in
                    PerspectiveRow(
                        perspective: perspective,
                        count: taskCount(for: perspective),
                        isSelected: selectedPerspectiveId == perspective.id
                    )
                    .tag(SidebarItem.perspective(perspective.id))
                }
            }

            // Contexts
            if !contextBoards.isEmpty {
                Section("CONTEXTS", isExpanded: $showContexts) {
                    ForEach(contextBoards) { board in
                        BoardRow(
                            board: board,
                            count: taskCount(for: board),
                            isSelected: selectedBoardId == board.id
                        )
                        .tag(SidebarItem.board(board.id))
                    }
                }
            }

            // Projects
            if !projectBoards.isEmpty {
                Section("PROJECTS", isExpanded: $showProjects) {
                    ForEach(projectBoards) { board in
                        BoardRow(
                            board: board,
                            count: taskCount(for: board),
                            isSelected: selectedBoardId == board.id
                        )
                        .tag(SidebarItem.board(board.id))
                    }
                }
            }

            // Custom Boards
            if !customBoards.isEmpty {
                Section("CUSTOM", isExpanded: $showCustomBoards) {
                    ForEach(customBoards) { board in
                        BoardRow(
                            board: board,
                            count: taskCount(for: board),
                            isSelected: selectedBoardId == board.id
                        )
                        .tag(SidebarItem.board(board.id))
                    }
                }
            }

            // Custom Perspectives
            if !customPerspectives.isEmpty {
                Section("SAVED PERSPECTIVES") {
                    ForEach(customPerspectives) { perspective in
                        PerspectiveRow(
                            perspective: perspective,
                            count: taskCount(for: perspective),
                            isSelected: selectedPerspectiveId == perspective.id
                        )
                        .tag(SidebarItem.perspective(perspective.id))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)
    }

    // MARK: - Selection Binding

    private var selectionBinding: Binding<SidebarItem?> {
        Binding(
            get: {
                if let perspectiveId = selectedPerspectiveId {
                    return .perspective(perspectiveId)
                } else if let boardId = selectedBoardId {
                    return .board(boardId)
                }
                return nil
            },
            set: { newValue in
                switch newValue {
                case .perspective(let id):
                    selectedPerspectiveId = id
                    selectedBoardId = nil
                    viewMode = .list
                case .board(let id):
                    selectedBoardId = id
                    selectedPerspectiveId = nil
                    viewMode = .board
                case .none:
                    selectedPerspectiveId = nil
                    selectedBoardId = nil
                }
            }
        )
    }

    // MARK: - Helper Methods

    /// Calculates the number of tasks matching a perspective
    private func taskCount(for perspective: Perspective) -> Int {
        perspective.apply(to: tasks).count
    }

    /// Calculates the number of tasks matching a board filter
    private func taskCount(for board: Board) -> Int {
        tasks.filter { $0.matches(board.filter) }.count
    }
}

// MARK: - Perspective Row

struct PerspectiveRow: View {
    let perspective: Perspective
    let count: Int
    let isSelected: Bool

    var body: some View {
        HStack {
            // Icon
            if let icon = perspective.icon {
                Text(icon)
                    .font(.body)
            }

            // Name
            Text(perspective.name)
                .font(.body)

            Spacer()

            // Badge count
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                    )
            }
        }
    }
}

// MARK: - Board Row

struct BoardRow: View {
    let board: Board
    let count: Int
    let isSelected: Bool

    var body: some View {
        HStack {
            // Icon
            if let icon = board.icon {
                Text(icon)
                    .font(.body)
            }

            // Name
            Text(board.displayTitle)
                .font(.body)
                .lineLimit(1)

            Spacer()

            // Badge count
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                    )
            }
        }
    }
}

// MARK: - Sidebar Item

enum SidebarItem: Hashable {
    case perspective(String)
    case board(String)
}

// MARK: - View Mode

enum ViewMode: String {
    case list
    case board
}

// MARK: - Preview

#Preview("Sidebar") {
    PerspectiveSidebarView(
        perspectives: Perspective.builtInPerspectives,
        boards: [
            .inbox,
            .nextActions,
            .flagged,
            Board.contextBoard(for: Context(name: "@computer", icon: "💻", color: "blue")),
            Board.contextBoard(for: Context(name: "@phone", icon: "📱", color: "green")),
            Board.projectBoard(name: "Website Redesign"),
            Board.projectBoard(name: "Q4 Planning"),
        ],
        tasks: [
            Task(title: "Task 1", status: .inbox),
            Task(title: "Task 2", status: .nextAction, context: "@computer"),
            Task(title: "Task 3", status: .nextAction, context: "@phone"),
            Task(title: "Task 4", project: "Website Redesign"),
        ],
        selectedPerspectiveId: .constant("inbox"),
        selectedBoardId: .constant(nil),
        viewMode: .constant(.list)
    )
}
