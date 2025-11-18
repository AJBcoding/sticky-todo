//
//  SampleDataGenerator.swift
//  StickyToDo
//
//  Generates realistic sample data for first-time users.
//  Creates example tasks, boards, perspectives, and templates to demonstrate features.
//

import Foundation
import StickyToDoCore

/// Generates sample data for onboarding and feature demonstration
///
/// SampleDataGenerator creates:
/// - Example tasks with various statuses, contexts, and properties
/// - Sample boards (Personal, Work, Planning)
/// - Sample perspectives (custom views)
/// - Example recurring tasks
/// - Tasks with subtasks, tags, and attachments
@MainActor
public class SampleDataGenerator {

    // MARK: - Public Methods

    /// Generates complete sample data set
    /// - Returns: Result indicating success or failure
    public static func generateSampleData() -> Result<SampleDataSet, SampleDataError> {
        do {
            let tasks = try generateSampleTasks()
            let boards = try generateSampleBoards()
            let tags = generateSampleTags()

            return .success(SampleDataSet(
                tasks: tasks,
                boards: boards,
                tags: tags
            ))
        } catch {
            return .failure(.generationFailed(error.localizedDescription))
        }
    }

    // MARK: - Task Generation

    /// Generates a set of example tasks demonstrating various features
    private static func generateSampleTasks() throws -> [Task] {
        var tasks: [Task] = []
        let now = Date()
        let calendar = Calendar.current

        // 1. Inbox task - Basic capture
        let inboxTask1 = Task(
            title: "Review quarterly goals",
            notes: "Take a look at Q1 objectives and update priorities",
            status: .inbox,
            project: "Planning",
            context: "@computer",
            flagged: false,
            priority: .medium
        )
        tasks.append(inboxTask1)

        // 2. Inbox task with natural language
        let inboxTask2 = Task(
            title: "Schedule dentist appointment",
            notes: "",
            status: .inbox,
            context: "@phone",
            priority: .medium
        )
        tasks.append(inboxTask2)

        // 3. Next Action - Ready to work on
        let nextActionTask1 = Task(
            title: "Finish project proposal",
            notes: """
            # Project Proposal Outline

            - Executive Summary
            - Problem Statement
            - Proposed Solution
            - Timeline & Milestones
            - Budget

            **Deadline**: End of week
            """,
            status: .nextAction,
            project: "Q1 Planning",
            context: "@computer",
            due: calendar.date(byAdding: .day, value: 2, to: now),
            flagged: true,
            priority: .high,
            effort: 120 // 2 hours
        )
        tasks.append(nextActionTask1)

        // 4. Task with due date today
        let todayTask = Task(
            title: "Submit expense report",
            notes: "Include receipts from last week's conference",
            status: .nextAction,
            project: "Administrative",
            context: "@computer",
            due: now,
            priority: .high
        )
        tasks.append(todayTask)

        // 5. Task with subtasks
        let parentTask = Task(
            title: "Plan weekend hiking trip",
            notes: "Need to organize equipment and route",
            status: .nextAction,
            project: "Personal",
            context: "@home",
            due: calendar.date(byAdding: .day, value: 5, to: now),
            priority: .medium
        )
        tasks.append(parentTask)

        // Subtasks
        let subtask1 = Task(
            title: "Check weather forecast",
            status: .nextAction,
            context: "@computer",
            parentId: parentTask.id,
            priority: .medium
        )
        tasks.append(subtask1)

        let subtask2 = Task(
            title: "Pack hiking gear",
            status: .nextAction,
            context: "@home",
            parentId: parentTask.id,
            priority: .medium
        )
        tasks.append(subtask2)

        let subtask3 = Task(
            title: "Download offline maps",
            status: .nextAction,
            context: "@phone",
            parentId: parentTask.id,
            priority: .low
        )
        tasks.append(subtask3)

        // Update parent with subtask IDs
        if var updatedParent = tasks.first(where: { $0.id == parentTask.id }) {
            updatedParent.subtaskIds = [subtask1.id, subtask2.id, subtask3.id]
            tasks.removeAll { $0.id == parentTask.id }
            tasks.append(updatedParent)
        }

        // 6. Waiting task
        let waitingTask = Task(
            title: "Feedback from Sarah on design mockups",
            notes: "Sent mockups on Monday, waiting for review",
            status: .waiting,
            project: "Website Redesign",
            context: "@office",
            priority: .medium
        )
        tasks.append(waitingTask)

        // 7. Someday/Maybe task
        let somedayTask1 = Task(
            title: "Learn SwiftUI advanced animations",
            notes: "Explore advanced animation techniques and spring animations",
            status: .someday,
            project: "Learning",
            context: "@computer",
            priority: .low
        )
        tasks.append(somedayTask1)

        let somedayTask2 = Task(
            title: "Write blog post about productivity systems",
            notes: "Share experiences with GTD methodology",
            status: .someday,
            project: "Writing",
            context: "@computer",
            priority: .low
        )
        tasks.append(somedayTask2)

        // 8. Task with tags
        var taggedTask = Task(
            title: "Review and update team documentation",
            notes: "Focus on onboarding materials and API docs",
            status: .nextAction,
            project: "Team Development",
            context: "@computer",
            due: calendar.date(byAdding: .day, value: 7, to: now),
            priority: .medium
        )
        taggedTask.tags = [
            Tag(name: "documentation", color: "#3498db", icon: "doc.text"),
            Tag(name: "team", color: "#e74c3c", icon: "person.3")
        ]
        tasks.append(taggedTask)

        // 9. Recurring task example
        let recurringTask = Task(
            title: "Weekly team sync",
            notes: "Standing weekly meeting with team leads",
            status: .nextAction,
            project: "Team Management",
            context: "@office",
            due: calendar.date(byAdding: .day, value: 1, to: now),
            priority: .medium
        )
        // Note: Recurrence would be configured separately
        tasks.append(recurringTask)

        // 10. Personal task
        let personalTask1 = Task(
            title: "Call Mom for her birthday",
            notes: "Her birthday is this Friday!",
            status: .nextAction,
            context: "@phone",
            due: calendar.date(byAdding: .day, value: 3, to: now),
            flagged: true,
            priority: .high
        )
        tasks.append(personalTask1)

        // 11. Errands task
        let errandsTask = Task(
            title: "Pick up dry cleaning",
            notes: "Ticket number: 12345",
            status: .nextAction,
            context: "@errands",
            due: calendar.date(byAdding: .day, value: 1, to: now),
            priority: .medium
        )
        tasks.append(errandsTask)

        // 12. Low-effort quick task
        let quickTask = Task(
            title: "Reply to John's email about Q2 budget",
            status: .nextAction,
            project: "Q2 Planning",
            context: "@computer",
            priority: .medium,
            effort: 10 // 10 minutes
        )
        tasks.append(quickTask)

        // 13. Task with defer date
        var deferredTask = Task(
            title: "Research new project management tools",
            notes: "Can't start until current project is done",
            status: .nextAction,
            project: "Tools Research",
            context: "@computer",
            defer: calendar.date(byAdding: .day, value: 14, to: now),
            priority: .low
        )
        tasks.append(deferredTask)

        return tasks
    }

    // MARK: - Board Generation

    /// Generates sample boards for different contexts and projects
    private static func generateSampleBoards() throws -> [Board] {
        var boards: [Board] = []

        // 1. Personal Board - Freeform layout
        let personalBoard = Board(
            id: "personal",
            type: .context,
            layout: .freeform,
            filter: Filter(context: "@home"),
            title: "Personal",
            notes: "Personal projects and home tasks",
            icon: "🏠",
            color: "blue",
            isBuiltIn: false,
            isVisible: true,
            order: 100
        )
        boards.append(personalBoard)

        // 2. Work Board - Kanban layout
        let workBoard = Board(
            id: "work",
            type: .context,
            layout: .kanban,
            filter: Filter(context: "@office"),
            columns: ["To Do", "In Progress", "Review", "Done"],
            title: "Work",
            notes: "Work-related tasks and projects",
            icon: "💼",
            color: "green",
            isBuiltIn: false,
            isVisible: true,
            order: 101
        )
        boards.append(workBoard)

        // 3. Planning Board - Grid layout
        let planningBoard = Board(
            id: "planning",
            type: .project,
            layout: .grid,
            filter: Filter(project: "Planning"),
            title: "Planning",
            notes: "Strategic planning and goal setting",
            icon: "📋",
            color: "purple",
            isBuiltIn: false,
            isVisible: true,
            order: 102
        )
        boards.append(planningBoard)

        return boards
    }

    // MARK: - Tag Generation

    /// Generates sample tags for categorization
    private static func generateSampleTags() -> [Tag] {
        return [
            Tag(name: "urgent", color: "#e74c3c", icon: "exclamationmark.circle"),
            Tag(name: "review", color: "#f39c12", icon: "eye"),
            Tag(name: "waiting", color: "#95a5a6", icon: "clock"),
            Tag(name: "personal", color: "#3498db", icon: "person"),
            Tag(name: "work", color: "#2ecc71", icon: "briefcase"),
            Tag(name: "learning", color: "#9b59b6", icon: "book"),
            Tag(name: "creative", color: "#e91e63", icon: "paintbrush")
        ]
    }
}

// MARK: - Supporting Types

/// Container for generated sample data
public struct SampleDataSet {
    public let tasks: [Task]
    public let boards: [Board]
    public let tags: [Tag]

    public var totalItems: Int {
        return tasks.count + boards.count + tags.count
    }
}

/// Errors that can occur during sample data generation
public enum SampleDataError: LocalizedError {
    case generationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .generationFailed(let message):
            return "Failed to generate sample data: \(message)"
        }
    }
}

// MARK: - Filter Extension

extension Filter {
    /// Convenience initializer for context filter
    convenience init(context: String) {
        self.init()
        self.context = context
    }

    /// Convenience initializer for project filter
    convenience init(project: String) {
        self.init()
        self.project = project
    }
}
