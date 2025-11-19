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

    /// PerspectiveStore for managing smart perspectives
    @ObservedObject var perspectiveStore: PerspectiveStore

    /// Callback when user wants to create new perspective
    var onCreatePerspective: (() -> Void)?

    /// Callback when user wants to edit perspectives
    var onEditPerspectives: (() -> Void)?

    // MARK: - State

    @State private var showContexts = true
    @State private var showProjects = true
    @State private var showCustomBoards = true
    @State private var showSmartPerspectives = true
    @State private var perspectiveToEdit: SmartPerspective?
    @State private var showingPerspectiveEditor = false

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

    /// Smart perspectives from PerspectiveStore
    private var smartPerspectives: [SmartPerspective] {
        perspectiveStore.customPerspectives
    }

    /// Built-in smart perspectives
    private var builtInSmartPerspectives: [SmartPerspective] {
        perspectiveStore.builtInPerspectives
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
            Section("PERSPECTIVES") {
                ForEach(builtInPerspectives) { perspective in
                    PerspectiveRow(
                        perspective: perspective,
                        count: taskCount(for: perspective),
                        isSelected: selectedPerspectiveId == perspective.id
                    )
                    .tag(SidebarItem.perspective(perspective.id))
                }
            }

            // Smart Perspectives (Built-in)
            if !builtInSmartPerspectives.isEmpty {
                Section("SMART PERSPECTIVES", isExpanded: $showSmartPerspectives) {
                    ForEach(builtInSmartPerspectives) { smartPerspective in
                        SmartPerspectiveRow(
                            perspective: smartPerspective,
                            count: taskCount(for: smartPerspective),
                            isSelected: false
                        )
                        .tag(SidebarItem.smartPerspective(smartPerspective.id.uuidString))
                    }
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

            // Custom Smart Perspectives
            if !smartPerspectives.isEmpty {
                Section {
                    ForEach(smartPerspectives) { smartPerspective in
                        SmartPerspectiveRow(
                            perspective: smartPerspective,
                            count: taskCount(for: smartPerspective),
                            isSelected: false
                        )
                        .tag(SidebarItem.smartPerspective(smartPerspective.id.uuidString))
                        .contextMenu {
                            Button("Edit") {
                                perspectiveToEdit = smartPerspective
                                showingPerspectiveEditor = true
                            }
                            Button("Duplicate") {
                                var duplicated = smartPerspective
                                duplicated.name = "\(smartPerspective.name) Copy"
                                perspectiveStore.create(duplicated)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                perspectiveStore.delete(smartPerspective)
                            }
                        }
                    }

                    // Add perspective button
                    Button {
                        onCreatePerspective?()
                    } label: {
                        Label("New Perspective", systemImage: "plus.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                } header: {
                    HStack {
                        Text("CUSTOM PERSPECTIVES")
                        Spacer()
                        Button {
                            onEditPerspectives?()
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // Empty state with add button
                Section("CUSTOM PERSPECTIVES") {
                    Button {
                        onCreatePerspective?()
                    } label: {
                        Label("New Perspective", systemImage: "plus.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)
        .sheet(isPresented: $showingPerspectiveEditor) {
            if let perspective = perspectiveToEdit {
                PerspectiveEditorView(
                    perspective: perspective,
                    onSave: { updatedPerspective in
                        perspectiveStore.update(updatedPerspective)
                        showingPerspectiveEditor = false
                        perspectiveToEdit = nil
                    },
                    onCancel: {
                        showingPerspectiveEditor = false
                        perspectiveToEdit = nil
                    }
                )
            }
        }
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

    /// Calculates the number of tasks matching a smart perspective
    private func taskCount(for perspective: SmartPerspective) -> Int {
        perspective.apply(to: tasks).count
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

// MARK: - Smart Perspective Row

struct SmartPerspectiveRow: View {
    let perspective: SmartPerspective
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

// MARK: - Sidebar Item

enum SidebarItem: Hashable {
    case perspective(String)
    case board(String)
    case smartPerspective(String)
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
        viewMode: .constant(.list),
        perspectiveStore: {
            let store = PerspectiveStore(rootDirectory: FileManager.default.temporaryDirectory)
            try? store.loadAll()
            return store
        }(),
        onCreatePerspective: {},
        onEditPerspectives: {}
    )
}
