//
//  AddTaskToProjectIntent.swift
//  StickyToDo
//
//  Siri intent to quickly add a task to a specific project.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, *)
public struct AddTaskToProjectIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task to Project"

    static var description = IntentDescription(
        "Quickly add a new task to a specific project.",
        categoryName: "Tasks",
        searchKeywords: ["add", "create", "task", "project"]
    )

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Title", description: "The task title")
    var title: String

    @Parameter(title: "Project", description: "Project name")
    var project: String

    @Parameter(title: "Notes", description: "Additional notes for the task")
    var notes: String?

    @Parameter(title: "Context", description: "Context for completing the task")
    var context: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) to \(\.$project)") {
            \.$notes
            \.$context
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            throw TaskError.storeUnavailable
        }

        // Create new task
        let task = Task(
            title: title,
            notes: notes ?? "",
            status: .nextAction, // Auto-promote to next action when adding to project
            project: project,
            context: context
        )

        // Add to store
        await MainActor.run {
            taskStore.add(task)

            // Donate intent for Siri suggestions
            donateIntent(for: task)
        }

        // Create confirmation dialog
        let dialog: IntentDialog = "Added '\(title)' to \(project)"

        // Create snippet view
        let snippetView = AddTaskToProjectResultView(
            title: title,
            project: project,
            context: context,
            notes: notes
        )

        return .result(dialog: dialog, view: snippetView)
    }

    private func donateIntent(for task: Task) {
        // Donate this intent for Siri suggestions
        let intent = AddTaskToProjectIntent()
        intent.title = task.title
        intent.project = task.project ?? ""
        intent.notes = task.notes
        intent.context = task.context
        // Intent donation happens automatically when perform() is called
    }
}

/// Result view shown after adding a task to a project
@available(iOS 16.0, macOS 13.0, *)
public struct AddTaskToProjectResultView: View {
    var title: String
    var project: String
    var context: String?
    var notes: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)

                    Text(project)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            if let ctx = context {
                HStack {
                    Image(systemName: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(ctx)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let noteText = notes, !noteText.isEmpty {
                Text(noteText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Added to \(project)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
}

/// Dynamic project query for autocomplete
@available(iOS 16.0, macOS 13.0, *)
public struct ProjectQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ProjectEntity] {
        guard let taskStore = AppDelegate.shared?.taskStore else {
            return []
        }

        return await MainActor.run {
            identifiers.compactMap { name in
                guard taskStore.projects.contains(name) else { return nil }
                return ProjectEntity(name: name)
            }
        }
    }

    func suggestedEntities() async throws -> [ProjectEntity] {
        guard let taskStore = AppDelegate.shared?.taskStore else {
            return []
        }

        return await MainActor.run {
            taskStore.projects.prefix(10).map { ProjectEntity(name: $0) }
        }
    }

    func entities(matching string: String) async throws -> [ProjectEntity] {
        guard let taskStore = AppDelegate.shared?.taskStore else {
            return []
        }

        return await MainActor.run {
            taskStore.projects
                .filter { $0.lowercased().contains(string.lowercased()) }
                .prefix(10)
                .map { ProjectEntity(name: $0) }
        }
    }
}

/// Project entity for autocomplete
@available(iOS 16.0, macOS 13.0, *)
public struct ProjectEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Project"
    static var defaultQuery = ProjectQuery()

    var id: String { name }
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}
