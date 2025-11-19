//
//  SpotlightManager.swift
//  StickyToDo
//
//  Manages Spotlight integration for task search and Siri suggestions.
//

import Foundation
import CoreSpotlight
import MobileCoreServices

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Manages Spotlight indexing for tasks
public class SpotlightManager {
    static let shared = SpotlightManager()

    private let searchableIndex = CSSearchableIndex.default()

    // Domain identifiers for different types of content
    private let taskDomainIdentifier = "com.stickytodo.tasks"
    private let projectDomainIdentifier = "com.stickytodo.projects"

    private init() {}

    // MARK: - Task Indexing

    /// Indexes a task for Spotlight search
    func indexTask(_ task: Task) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)

        // Basic attributes
        attributeSet.title = task.title
        attributeSet.contentDescription = task.notes.isEmpty ? nil : task.notes
        attributeSet.keywords = buildKeywords(for: task)

        // Metadata
        attributeSet.addedDate = task.created
        attributeSet.contentModificationDate = task.modified
        attributeSet.identifier = task.id.uuidString

        // Custom attributes
        if let project = task.project {
            attributeSet.metadataModificationDate = Date()
            attributeSet.relatedUniqueIdentifier = project
        }

        if let context = task.context {
            attributeSet.comment = context
        }

        if let due = task.due {
            attributeSet.dueDate = due
        }

        // Status indicators
        attributeSet.completionDate = task.status == .completed ? task.modified : nil

        // Priority
        switch task.priority {
        case .high:
            attributeSet.rankingHint = 1.0
        case .medium:
            attributeSet.rankingHint = 0.5
        case .low:
            attributeSet.rankingHint = 0.2
        }

        // Create searchable item
        let item = CSSearchableItem(
            uniqueIdentifier: task.id.uuidString,
            domainIdentifier: taskDomainIdentifier,
            attributeSet: attributeSet
        )

        // Set expiration for completed tasks (30 days)
        if task.status == .completed {
            item.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        }

        // Index the item
        searchableIndex.indexSearchableItems([item]) { error in
            if let error = error {
                print("Error indexing task '\(task.title)': \(error)")
            }
        }
    }

    /// Indexes multiple tasks
    func indexTasks(_ tasks: [Task]) {
        let items = tasks.map { task -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)

            attributeSet.title = task.title
            attributeSet.contentDescription = task.notes.isEmpty ? nil : task.notes
            attributeSet.keywords = buildKeywords(for: task)
            attributeSet.addedDate = task.created
            attributeSet.contentModificationDate = task.modified
            attributeSet.identifier = task.id.uuidString

            if let project = task.project {
                attributeSet.relatedUniqueIdentifier = project
            }

            if let due = task.due {
                attributeSet.dueDate = due
            }

            switch task.priority {
            case .high:
                attributeSet.rankingHint = 1.0
            case .medium:
                attributeSet.rankingHint = 0.5
            case .low:
                attributeSet.rankingHint = 0.2
            }

            let item = CSSearchableItem(
                uniqueIdentifier: task.id.uuidString,
                domainIdentifier: taskDomainIdentifier,
                attributeSet: attributeSet
            )

            if task.status == .completed {
                item.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
            }

            return item
        }

        searchableIndex.indexSearchableItems(items) { error in
            if let error = error {
                print("Error indexing tasks: \(error)")
            }
        }
    }

    /// Removes a task from Spotlight index
    func deindexTask(_ task: Task) {
        searchableIndex.deleteSearchableItems(withIdentifiers: [task.id.uuidString]) { error in
            if let error = error {
                print("Error deindexing task '\(task.title)': \(error)")
            }
        }
    }

    /// Removes multiple tasks from index
    func deindexTasks(_ tasks: [Task]) {
        let identifiers = tasks.map { $0.id.uuidString }
        searchableIndex.deleteSearchableItems(withIdentifiers: identifiers) { error in
            if let error = error {
                print("Error deindexing tasks: \(error)")
            }
        }
    }

    /// Removes all tasks from Spotlight index
    func clearTaskIndex() {
        searchableIndex.deleteSearchableItems(withDomainIdentifiers: [taskDomainIdentifier]) { error in
            if let error = error {
                print("Error clearing task index: \(error)")
            }
        }
    }

    /// Reindexes all tasks
    func reindexAllTasks(from taskStore: TaskStore) {
        // Clear existing index first
        clearTaskIndex()

        // Index all non-completed tasks
        let activeTasks = taskStore.tasks.filter { $0.status != .completed }
        indexTasks(activeTasks)
    }

    // MARK: - Helper Methods

    private func buildKeywords(for task: Task) -> [String] {
        var keywords: [String] = []

        // Add title words
        keywords.append(contentsOf: task.title.components(separatedBy: .whitespaces))

        // Add project
        if let project = task.project {
            keywords.append(project)
            keywords.append(contentsOf: project.components(separatedBy: .whitespaces))
        }

        // Add context
        if let context = task.context {
            keywords.append(context)
            // Remove @ prefix for better search
            let cleanContext = context.hasPrefix("@") ? String(context.dropFirst()) : context
            keywords.append(cleanContext)
        }

        // Add status
        keywords.append(task.status.rawValue)

        // Add priority
        keywords.append(task.priority.rawValue)

        // Add tags
        keywords.append(contentsOf: task.tags.map { $0.name })

        // Add GTD-related keywords
        switch task.status {
        case .inbox:
            keywords.append(contentsOf: ["inbox", "unprocessed", "new"])
        case .nextAction:
            keywords.append(contentsOf: ["next", "action", "actionable", "todo"])
        case .waiting:
            keywords.append(contentsOf: ["waiting", "blocked"])
        case .someday:
            keywords.append(contentsOf: ["someday", "maybe", "future"])
        case .completed:
            keywords.append(contentsOf: ["completed", "done", "finished"])
        case .project:
            keywords.append(contentsOf: ["project"])
        }

        // Add time-based keywords
        if task.isDueToday {
            keywords.append(contentsOf: ["today", "due today"])
        }
        if task.isOverdue {
            keywords.append(contentsOf: ["overdue", "late"])
        }
        if task.flagged {
            keywords.append(contentsOf: ["flagged", "important", "starred"])
        }

        return keywords.filter { !$0.isEmpty }
    }

    // MARK: - Spotlight Continuation

    /// Handles Spotlight search item selection
    func handleSpotlightContinuation(with identifier: String) -> UUID? {
        return UUID(uuidString: identifier)
    }

    // MARK: - Donations (for Siri suggestions)

    /// Donates a task interaction for Siri suggestions
    #if canImport(AppIntents)
    @available(iOS 16.0, macOS 13.0, *)
    func donateTaskInteraction(_ task: Task, type: InteractionType) {
        // Donations are handled automatically by App Intents framework
        // This is a placeholder for custom donation logic if needed
    }
    #endif

    enum InteractionType {
        case created
        case completed
        case viewed
        case timerStarted
    }
}

// MARK: - Extensions

extension UTType {
    static var task: UTType {
        UTType(exportedAs: "com.stickytodo.task")
    }
}
