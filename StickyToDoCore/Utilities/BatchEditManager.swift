//
//  BatchEditManager.swift
//  StickyToDoCore
//
//  Manages batch editing operations for multiple tasks.
//

import Foundation

/// Manages batch editing operations for multiple tasks
public class BatchEditManager {

    // MARK: - Batch Operation Types

    /// Types of batch operations that can be performed
    public enum BatchOperation {
        case complete
        case uncomplete
        case archive
        case delete
        case setStatus(Status)
        case setPriority(Priority)
        case setProject(String?)
        case setContext(String?)
        case addTag(Tag)
        case removeTag(Tag)
        case setDueDate(Date?)
        case setDeferDate(Date?)
        case flag
        case unflag
        case setEffort(Int?)
    }

    /// Result of a batch operation
    public struct BatchResult {
        public let successCount: Int
        public let failureCount: Int
        public let errors: [Error]
        public let modifiedTasks: [Task]

        public var isSuccess: Bool {
            return failureCount == 0
        }

        public init(successCount: Int, failureCount: Int, errors: [Error], modifiedTasks: [Task]) {
            self.successCount = successCount
            self.failureCount = failureCount
            self.errors = errors
            self.modifiedTasks = modifiedTasks
        }
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Batch Operations

    /// Applies a batch operation to multiple tasks
    /// - Parameters:
    ///   - operation: The operation to perform
    ///   - tasks: The tasks to modify
    /// - Returns: The result of the batch operation
    public func applyOperation(_ operation: BatchOperation, to tasks: [Task]) -> BatchResult {
        var modifiedTasks: [Task] = []
        var errors: [Error] = []

        for var task in tasks {
            do {
                switch operation {
                case .complete:
                    task.complete()

                case .uncomplete:
                    task.reopen()

                case .archive:
                    task.complete()

                case .delete:
                    // Delete is handled separately by TaskStore
                    break

                case .setStatus(let status):
                    task.status = status
                    task.touch()

                case .setPriority(let priority):
                    task.priority = priority
                    task.touch()

                case .setProject(let project):
                    task.project = project
                    task.touch()

                case .setContext(let context):
                    task.context = context
                    task.touch()

                case .addTag(let tag):
                    task.addTag(tag)

                case .removeTag(let tag):
                    task.removeTag(tag)

                case .setDueDate(let dueDate):
                    task.due = dueDate
                    task.touch()

                case .setDeferDate(let deferDate):
                    task.defer = deferDate
                    task.touch()

                case .flag:
                    task.flagged = true
                    task.touch()

                case .unflag:
                    task.flagged = false
                    task.touch()

                case .setEffort(let effort):
                    task.effort = effort
                    task.touch()
                }

                modifiedTasks.append(task)
            } catch {
                errors.append(error)
            }
        }

        return BatchResult(
            successCount: modifiedTasks.count,
            failureCount: errors.count,
            errors: errors,
            modifiedTasks: modifiedTasks
        )
    }

    /// Returns a human-readable description of the operation
    /// - Parameter operation: The operation to describe
    /// - Returns: A description string
    public func operationDescription(_ operation: BatchOperation) -> String {
        switch operation {
        case .complete:
            return "Complete tasks"
        case .uncomplete:
            return "Mark as incomplete"
        case .archive:
            return "Archive tasks"
        case .delete:
            return "Delete tasks"
        case .setStatus(let status):
            return "Change status to \(status.displayName)"
        case .setPriority(let priority):
            return "Set priority to \(priority.displayName)"
        case .setProject(let project):
            return project != nil ? "Move to project '\(project!)'" : "Remove from project"
        case .setContext(let context):
            return context != nil ? "Set context to '\(context!)'" : "Remove context"
        case .addTag(let tag):
            return "Add tag '\(tag.name)'"
        case .removeTag(let tag):
            return "Remove tag '\(tag.name)'"
        case .setDueDate(let dueDate):
            return dueDate != nil ? "Set due date" : "Clear due date"
        case .setDeferDate(let deferDate):
            return deferDate != nil ? "Set defer date" : "Clear defer date"
        case .flag:
            return "Flag tasks"
        case .unflag:
            return "Unflag tasks"
        case .setEffort(let effort):
            return effort != nil ? "Set effort to \(effort!) minutes" : "Clear effort estimate"
        }
    }

    /// Returns whether the operation is destructive (requires confirmation)
    /// - Parameter operation: The operation to check
    /// - Returns: True if the operation is destructive
    public func isDestructive(_ operation: BatchOperation) -> Bool {
        switch operation {
        case .delete:
            return true
        case .complete, .uncomplete, .archive:
            return false
        case .setStatus, .setPriority, .setProject, .setContext:
            return false
        case .addTag, .removeTag:
            return false
        case .setDueDate, .setDeferDate, .flag, .unflag, .setEffort:
            return false
        }
    }

    /// Returns a confirmation message for the operation
    /// - Parameters:
    ///   - operation: The operation to confirm
    ///   - taskCount: Number of tasks affected
    /// - Returns: A confirmation message
    public func confirmationMessage(for operation: BatchOperation, taskCount: Int) -> String {
        let taskWord = taskCount == 1 ? "task" : "tasks"

        switch operation {
        case .delete:
            return "Are you sure you want to delete \(taskCount) \(taskWord)? This action cannot be undone."
        case .complete:
            return "Mark \(taskCount) \(taskWord) as complete?"
        case .uncomplete:
            return "Reopen \(taskCount) completed \(taskWord)?"
        case .archive:
            return "Archive \(taskCount) \(taskWord)? They will be marked as completed."
        case .setStatus(let status):
            return "Change status of \(taskCount) \(taskWord) to \(status.displayName)?"
        case .setPriority(let priority):
            return "Set priority of \(taskCount) \(taskWord) to \(priority.displayName)?"
        case .setProject(let project):
            if let project = project {
                return "Move \(taskCount) \(taskWord) to project '\(project)'?"
            } else {
                return "Remove \(taskCount) \(taskWord) from their projects?"
            }
        case .setContext(let context):
            if let context = context {
                return "Set context of \(taskCount) \(taskWord) to '\(context)'?"
            } else {
                return "Remove context from \(taskCount) \(taskWord)?"
            }
        case .addTag(let tag):
            return "Add tag '\(tag.name)' to \(taskCount) \(taskWord)?"
        case .removeTag(let tag):
            return "Remove tag '\(tag.name)' from \(taskCount) \(taskWord)?"
        case .setDueDate(let dueDate):
            if dueDate != nil {
                return "Set due date for \(taskCount) \(taskWord)?"
            } else {
                return "Clear due date from \(taskCount) \(taskWord)?"
            }
        case .setDeferDate(let deferDate):
            if deferDate != nil {
                return "Set defer date for \(taskCount) \(taskWord)?"
            } else {
                return "Clear defer date from \(taskCount) \(taskWord)?"
            }
        case .flag:
            return "Flag \(taskCount) \(taskWord)?"
        case .unflag:
            return "Unflag \(taskCount) \(taskWord)?"
        case .setEffort(let effort):
            if let effort = effort {
                return "Set effort estimate to \(effort) minutes for \(taskCount) \(taskWord)?"
            } else {
                return "Clear effort estimate from \(taskCount) \(taskWord)?"
            }
        }
    }
}
