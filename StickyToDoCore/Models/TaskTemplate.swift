//
//  TaskTemplate.swift
//  StickyToDo
//
//  Templates for quickly creating tasks with predefined properties.
//

import Foundation

/// Represents a reusable task template
///
/// Templates allow users to quickly create tasks with predefined properties,
/// saving time on repetitive task creation workflows.
public struct TaskTemplate: Identifiable, Codable, Equatable {
    // MARK: - Core Properties

    /// Unique identifier for the template
    let id: UUID

    /// Template name (displayed in template library)
    var name: String

    /// Default task title
    var title: String

    /// Default notes/description
    var notes: String

    /// Default project
    var defaultProject: String?

    /// Default context
    var defaultContext: String?

    /// Default priority
    var defaultPriority: Priority

    /// Default effort estimate in minutes
    var defaultEffort: Int?

    /// Default status (usually inbox or next-action)
    var defaultStatus: Status

    /// Default tags to apply
    var tags: [Tag]

    /// Subtask titles to create with the task
    var subtasks: [String]?

    /// Whether to set flagged by default
    var defaultFlagged: Bool

    /// Template category for organization
    var category: String?

    /// When this template was created
    var created: Date

    /// When this template was last modified
    var modified: Date

    /// Number of times this template has been used
    var useCount: Int

    // MARK: - Initialization

    /// Creates a new task template
    /// - Parameters:
    ///   - id: Unique identifier (generates new UUID if not provided)
    ///   - name: Template name
    ///   - title: Default task title
    ///   - notes: Default notes
    ///   - defaultProject: Default project
    ///   - defaultContext: Default context
    ///   - defaultPriority: Default priority (defaults to .medium)
    ///   - defaultEffort: Default effort estimate
    ///   - defaultStatus: Default status (defaults to .inbox)
    ///   - tags: Default tags
    ///   - subtasks: Subtask titles
    ///   - defaultFlagged: Whether to flag by default (defaults to false)
    ///   - category: Template category
    ///   - created: Creation timestamp (defaults to now)
    ///   - modified: Modification timestamp (defaults to now)
    ///   - useCount: Usage counter (defaults to 0)
    public init(
        id: UUID = UUID(),
        name: String,
        title: String,
        notes: String = "",
        defaultProject: String? = nil,
        defaultContext: String? = nil,
        defaultPriority: Priority = .medium,
        defaultEffort: Int? = nil,
        defaultStatus: Status = .inbox,
        tags: [Tag] = [],
        subtasks: [String]? = nil,
        defaultFlagged: Bool = false,
        category: String? = nil,
        created: Date = Date(),
        modified: Date = Date(),
        useCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.notes = notes
        self.defaultProject = defaultProject
        self.defaultContext = defaultContext
        self.defaultPriority = defaultPriority
        self.defaultEffort = defaultEffort
        self.defaultStatus = defaultStatus
        self.tags = tags
        self.subtasks = subtasks
        self.defaultFlagged = defaultFlagged
        self.category = category
        self.created = created
        self.modified = modified
        self.useCount = useCount
    }
}

// MARK: - Computed Properties

extension TaskTemplate {
    /// Returns the display name for this template
    var displayName: String {
        return name
    }

    /// Returns true if this template has subtasks defined
    var hasSubtasks: Bool {
        return subtasks?.isEmpty == false
    }

    /// Returns the number of subtasks
    var subtaskCount: Int {
        return subtasks?.count ?? 0
    }

    /// Returns true if this template has been used at least once
    var hasBeenUsed: Bool {
        return useCount > 0
    }
}

// MARK: - Helper Methods

extension TaskTemplate {
    /// Creates a task from this template
    /// - Returns: A new task with properties from this template
    func createTask() -> Task {
        let task = Task(
            title: title,
            notes: notes,
            status: defaultStatus,
            project: defaultProject,
            context: defaultContext,
            flagged: defaultFlagged,
            priority: defaultPriority,
            effort: defaultEffort
        )
        return task
    }

    /// Increments the use count
    mutating func recordUse() {
        useCount += 1
        modified = Date()
    }

    /// Updates the modified timestamp
    mutating func touch() {
        modified = Date()
    }
}

// MARK: - Predefined Templates

extension TaskTemplate {
    /// Meeting notes template
    static var meetingNotes: TaskTemplate {
        TaskTemplate(
            name: "Meeting Notes",
            title: "Meeting: [Topic]",
            notes: """
            **Date:** [Date]
            **Attendees:** [Names]
            **Agenda:**
            -

            **Notes:**
            -

            **Action Items:**
            -
            """,
            defaultProject: nil,
            defaultContext: "@office",
            defaultPriority: .medium,
            defaultEffort: 60,
            defaultStatus: .inbox,
            tags: [.meeting],
            category: "Work"
        )
    }

    /// Code review template
    static var codeReview: TaskTemplate {
        TaskTemplate(
            name: "Code Review",
            title: "Review PR: [PR Number/Title]",
            notes: """
            **PR Link:** [URL]
            **Author:** [Name]
            **Changes:** [Brief description]

            **Review Checklist:**
            - [ ] Code quality and readability
            - [ ] Tests coverage
            - [ ] Documentation
            - [ ] Performance implications
            - [ ] Security considerations

            **Comments:**
            -
            """,
            defaultProject: nil,
            defaultContext: "@computer",
            defaultPriority: .high,
            defaultEffort: 30,
            defaultStatus: .nextAction,
            tags: [.review, .work],
            category: "Development"
        )
    }

    /// Weekly review template
    static var weeklyReview: TaskTemplate {
        TaskTemplate(
            name: "Weekly Review",
            title: "Weekly Review - Week of [Date]",
            notes: """
            **Accomplishments:**
            -

            **Completed Projects:**
            -

            **Ongoing Work:**
            -

            **Next Week Priorities:**
            -

            **Notes & Reflections:**
            -
            """,
            defaultProject: "GTD System",
            defaultContext: nil,
            defaultPriority: .high,
            defaultEffort: 60,
            defaultStatus: .nextAction,
            tags: [.review, .planning],
            defaultFlagged: true,
            category: "GTD"
        )
    }

    /// Blog post template
    static var blogPost: TaskTemplate {
        TaskTemplate(
            name: "Blog Post",
            title: "Write: [Post Title]",
            notes: """
            **Topic:** [Main topic]
            **Target Audience:** [Who is this for?]
            **Key Points:**
            -
            -
            -

            **Outline:**
            1. Introduction
            2. Main content
            3. Conclusion

            **Keywords:** [SEO keywords]
            **Target Length:** [Word count]
            """,
            defaultProject: "Content Creation",
            defaultContext: "@computer",
            defaultPriority: .medium,
            defaultEffort: 120,
            defaultStatus: .nextAction,
            tags: [],
            subtasks: [
                "Research topic",
                "Create outline",
                "Write first draft",
                "Edit and revise",
                "Add images/media",
                "Proofread",
                "Publish"
            ],
            category: "Content"
        )
    }

    /// Research task template
    static var research: TaskTemplate {
        TaskTemplate(
            name: "Research Task",
            title: "Research: [Topic]",
            notes: """
            **Research Question:** [What are you trying to learn?]

            **Sources to Check:**
            -

            **Key Findings:**
            -

            **Next Steps:**
            -
            """,
            defaultProject: nil,
            defaultContext: "@computer",
            defaultPriority: .medium,
            defaultEffort: 60,
            defaultStatus: .nextAction,
            tags: [.research],
            category: "General"
        )
    }

    /// Project planning template
    static var projectPlanning: TaskTemplate {
        TaskTemplate(
            name: "Project Planning",
            title: "Plan: [Project Name]",
            notes: """
            **Project Goal:** [What is the desired outcome?]

            **Stakeholders:**
            -

            **Timeline:** [Start - End]

            **Key Milestones:**
            -

            **Resources Needed:**
            -

            **Risks:**
            -

            **Success Criteria:**
            -
            """,
            defaultProject: nil,
            defaultContext: nil,
            defaultPriority: .high,
            defaultEffort: 90,
            defaultStatus: .nextAction,
            tags: [.planning],
            subtasks: [
                "Define scope",
                "Identify resources",
                "Create timeline",
                "Set milestones",
                "Risk assessment"
            ],
            category: "Planning"
        )
    }

    /// Call template
    static var phoneCall: TaskTemplate {
        TaskTemplate(
            name: "Phone Call",
            title: "Call: [Person/Company]",
            notes: """
            **Phone:** [Number]
            **Purpose:** [Reason for call]
            **Key Points to Discuss:**
            -

            **Questions to Ask:**
            -

            **Notes:**
            -
            """,
            defaultProject: nil,
            defaultContext: "@phone",
            defaultPriority: .medium,
            defaultEffort: 15,
            defaultStatus: .nextAction,
            tags: [],
            category: "Communication"
        )
    }

    /// Returns all built-in templates
    static var defaultTemplates: [TaskTemplate] {
        return [
            .meetingNotes,
            .codeReview,
            .weeklyReview,
            .blogPost,
            .research,
            .projectPlanning,
            .phoneCall
        ]
    }
}
