//
//  TaskEntity.swift
//  StickyToDo
//
//  App Intents entity representation of a Task for Siri integration.
//

import Foundation
import AppIntents

/// App Intents entity representing a Task for Siri integration
@available(iOS 16.0, macOS 13.0, *)
public struct TaskEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Task"

    static var defaultQuery = TaskQuery()

    var id: UUID
    var title: String
    var notes: String?
    var status: String
    var project: String?
    var context: String?
    var priority: String
    var flagged: Bool
    var dueDate: Date?
    var isTimerRunning: Bool

    var displayRepresentation: DisplayRepresentation {
        var subtitle: String?

        // Build subtitle with project/context info
        if let proj = project, let ctx = context {
            subtitle = "\(proj) • \(ctx)"
        } else if let proj = project {
            subtitle = proj
        } else if let ctx = context {
            subtitle = ctx
        }

        return DisplayRepresentation(
            title: "\(title)",
            subtitle: subtitle.map { LocalizedStringResource(stringLiteral: $0) }
        )
    }

    /// Creates a TaskEntity from a Task
    static func from(task: Task) -> TaskEntity {
        return TaskEntity(
            id: task.id,
            title: task.title,
            notes: task.notes.isEmpty ? nil : task.notes,
            status: task.status.rawValue,
            project: task.project,
            context: task.context,
            priority: task.priority.rawValue,
            flagged: task.flagged,
            dueDate: task.due,
            isTimerRunning: task.isTimerRunning
        )
    }

    /// Converts this entity back to a Task model (requires full data from store)
    func toTask(from store: TaskStore) -> Task? {
        return store.task(withID: id)
    }
}

/// Query for finding tasks via Siri
@available(iOS 16.0, macOS 13.0, *)
public struct TaskQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [TaskEntity] {
        // Access shared task store
        guard let taskStore = AppDelegate.shared?.taskStore else {
            return []
        }

        return identifiers.compactMap { id in
            guard let task = taskStore.task(withID: id) else { return nil }
            return TaskEntity.from(task: task)
        }
    }

    func suggestedEntities() async throws -> [TaskEntity] {
        // Return next actions and flagged tasks as suggestions
        guard let taskStore = AppDelegate.shared?.taskStore else {
            return []
        }

        let nextActions = taskStore.tasks(withStatus: .nextAction).prefix(5)
        let flagged = taskStore.flaggedTasks().prefix(5)

        let suggestions = Array(Set(nextActions + flagged))
            .sorted { $0.modified > $1.modified }
            .prefix(10)

        return suggestions.map { TaskEntity.from(task: $0) }
    }

    func entities(matching string: String) async throws -> [TaskEntity] {
        // Search tasks by title
        guard let taskStore = AppDelegate.shared?.taskStore else {
            return []
        }

        let matchingTasks = taskStore.tasks(matchingSearch: string)
            .prefix(10)

        return matchingTasks.map { TaskEntity.from(task: $0) }
    }
}

/// Priority parameter for Siri intents
@available(iOS 16.0, macOS 13.0, *)
public enum PriorityOption: String, AppEnum {
    case high
    case medium
    case low

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Priority"

    static var caseDisplayRepresentations: [PriorityOption: DisplayRepresentation] = [
        .high: "High",
        .medium: "Medium",
        .low: "Low"
    ]

    var toPriority: Priority {
        switch self {
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
}
