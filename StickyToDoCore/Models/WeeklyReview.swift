//
//  WeeklyReview.swift
//  StickyToDoCore
//
//  GTD Weekly Review model with guided workflow steps.
//  Tracks review sessions, progress, and completion history.
//

import Foundation

/// Represents a single step in the weekly review process
public struct WeeklyReviewStep: Identifiable, Codable, Equatable {
    /// Unique identifier for the step
    let id: String

    /// Display title for the step
    let title: String

    /// Detailed description of what to do in this step
    let description: String

    /// Which perspective to show during this step (nil = no specific perspective)
    let perspectiveID: String?

    /// Guidance text for what action to take
    let actionGuidance: String

    /// Estimated time to complete this step (in minutes)
    let estimatedMinutes: Int

    /// Whether this step has been completed in the current session
    var isCompleted: Bool

    /// When this step was completed (nil if not completed)
    var completedAt: Date?

    /// Notes taken during this step
    var notes: String

    public init(
        id: String,
        title: String,
        description: String,
        perspectiveID: String? = nil,
        actionGuidance: String,
        estimatedMinutes: Int = 5,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.perspectiveID = perspectiveID
        self.actionGuidance = actionGuidance
        self.estimatedMinutes = estimatedMinutes
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.notes = notes
    }
}

/// Represents a weekly review session
public struct WeeklyReviewSession: Identifiable, Codable, Equatable {
    /// Unique identifier for the session
    let id: UUID

    /// When the review session started
    let startDate: Date

    /// When the review session completed (nil if in progress)
    var completedDate: Date?

    /// Index of the current step (0-based)
    var currentStepIndex: Int

    /// All steps in this review
    var steps: [WeeklyReviewStep]

    /// Overall session notes and reflections
    var sessionNotes: String

    /// Total duration of the review (in seconds)
    var durationSeconds: TimeInterval

    /// Whether the session is currently paused
    var isPaused: Bool

    public init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        completedDate: Date? = nil,
        currentStepIndex: Int = 0,
        steps: [WeeklyReviewStep] = WeeklyReviewStep.defaultSteps,
        sessionNotes: String = "",
        durationSeconds: TimeInterval = 0,
        isPaused: Bool = false
    ) {
        self.id = id
        self.startDate = startDate
        self.completedDate = completedDate
        self.currentStepIndex = currentStepIndex
        self.steps = steps
        self.sessionNotes = sessionNotes
        self.durationSeconds = durationSeconds
        self.isPaused = isPaused
    }
}

// MARK: - WeeklyReviewSession Computed Properties

extension WeeklyReviewSession {
    /// Current step being worked on
    var currentStep: WeeklyReviewStep? {
        guard currentStepIndex >= 0 && currentStepIndex < steps.count else {
            return nil
        }
        return steps[currentStepIndex]
    }

    /// Whether the review is complete
    var isComplete: Bool {
        return completedDate != nil || steps.allSatisfy { $0.isCompleted }
    }

    /// Progress as a percentage (0-100)
    var progressPercentage: Double {
        guard !steps.isEmpty else { return 0 }
        let completed = steps.filter { $0.isCompleted }.count
        return Double(completed) / Double(steps.count) * 100
    }

    /// Number of completed steps
    var completedStepsCount: Int {
        return steps.filter { $0.isCompleted }.count
    }

    /// Total number of steps
    var totalStepsCount: Int {
        return steps.count
    }

    /// Estimated time remaining (in minutes)
    var estimatedMinutesRemaining: Int {
        return steps
            .filter { !$0.isCompleted }
            .reduce(0) { $0 + $1.estimatedMinutes }
    }

    /// Formatted duration string
    var durationString: String {
        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - WeeklyReviewSession Methods

extension WeeklyReviewSession {
    /// Mark the current step as complete and advance to next
    mutating func completeCurrentStep(notes: String = "") {
        guard currentStepIndex < steps.count else { return }

        steps[currentStepIndex].isCompleted = true
        steps[currentStepIndex].completedAt = Date()
        steps[currentStepIndex].notes = notes

        // Move to next step if not at the end
        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
        }
    }

    /// Skip the current step and move to next
    mutating func skipCurrentStep() {
        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
        }
    }

    /// Go back to the previous step
    mutating func previousStep() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
        }
    }

    /// Jump to a specific step
    mutating func goToStep(index: Int) {
        guard index >= 0 && index < steps.count else { return }
        currentStepIndex = index
    }

    /// Complete the entire review session
    mutating func completeSession() {
        completedDate = Date()

        // Mark any incomplete steps as complete
        for index in steps.indices {
            if !steps[index].isCompleted {
                steps[index].isCompleted = true
                steps[index].completedAt = Date()
            }
        }
    }

    /// Reset the session to start over
    mutating func reset() {
        currentStepIndex = 0
        completedDate = nil
        durationSeconds = 0

        for index in steps.indices {
            steps[index].isCompleted = false
            steps[index].completedAt = nil
            steps[index].notes = ""
        }
    }

    /// Add time to the duration
    mutating func addDuration(_ seconds: TimeInterval) {
        durationSeconds += seconds
    }
}

// MARK: - Default GTD Weekly Review Steps

extension WeeklyReviewStep {
    /// The standard GTD weekly review steps
    static var defaultSteps: [WeeklyReviewStep] {
        return [
            WeeklyReviewStep(
                id: "get-clear",
                title: "Get Clear",
                description: "Process all loose ends. Empty your inbox and capture any outstanding thoughts, ideas, or tasks.",
                perspectiveID: "inbox",
                actionGuidance: "Review and process every item in your inbox until it reaches zero. Clarify what each item is and what action it requires.",
                estimatedMinutes: 10
            ),
            WeeklyReviewStep(
                id: "review-next-actions",
                title: "Get Current",
                description: "Review your Next Actions list to ensure it's up to date.",
                perspectiveID: "next-actions",
                actionGuidance: "Scan through all next actions. Mark any as complete, delete items no longer relevant, and ensure each action is still the right next step.",
                estimatedMinutes: 10
            ),
            WeeklyReviewStep(
                id: "review-calendar",
                title: "Review Calendar",
                description: "Look at the past week and the upcoming 2-4 weeks.",
                perspectiveID: "due-soon",
                actionGuidance: "Review completed items from last week for any follow-ups needed. Look ahead to upcoming commitments and deadlines. Create any necessary next actions.",
                estimatedMinutes: 5
            ),
            WeeklyReviewStep(
                id: "review-waiting",
                title: "Review Waiting For",
                description: "Check on all items you're waiting for from others.",
                perspectiveID: "waiting-for",
                actionGuidance: "Review each waiting-for item. Send follow-up reminders where needed. Mark as complete any items that have been delivered.",
                estimatedMinutes: 5
            ),
            WeeklyReviewStep(
                id: "review-projects",
                title: "Review Projects",
                description: "Ensure each project has at least one next action defined.",
                perspectiveID: "all-active",
                actionGuidance: "Go through each active project. Verify it has a next action. If a project is complete, mark it done. If it's stalled, either define the next action or move to someday/maybe.",
                estimatedMinutes: 15
            ),
            WeeklyReviewStep(
                id: "review-someday",
                title: "Review Someday/Maybe",
                description: "Look at your someday/maybe list for items to activate.",
                perspectiveID: "someday-maybe",
                actionGuidance: "Review your someday/maybe items. Are any ready to be activated as projects? Delete anything no longer of interest. Add any new ideas you've captured.",
                estimatedMinutes: 5
            ),
            WeeklyReviewStep(
                id: "get-creative",
                title: "Get Creative",
                description: "Think about the bigger picture and brainstorm new ideas.",
                perspectiveID: nil,
                actionGuidance: "Take a moment to reflect on your goals and vision. Capture any new ideas, projects, or possibilities. Review your areas of focus and responsibility. What needs attention?",
                estimatedMinutes: 10
            )
        ]
    }
}

// MARK: - Review History Summary

/// Summary of weekly review completion history
public struct WeeklyReviewHistory: Codable {
    /// Date of last completed review
    var lastReviewDate: Date?

    /// Total number of completed reviews
    var totalReviewsCompleted: Int

    /// Current streak (consecutive weeks with reviews)
    var currentStreak: Int

    /// Longest streak ever achieved
    var longestStreak: Int

    /// Average duration of completed reviews (in minutes)
    var averageDurationMinutes: Double

    /// IDs of all completed review sessions
    var completedSessionIDs: [UUID]

    public init(
        lastReviewDate: Date? = nil,
        totalReviewsCompleted: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        averageDurationMinutes: Double = 0,
        completedSessionIDs: [UUID] = []
    ) {
        self.lastReviewDate = lastReviewDate
        self.totalReviewsCompleted = totalReviewsCompleted
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.averageDurationMinutes = averageDurationMinutes
        self.completedSessionIDs = completedSessionIDs
    }
}

extension WeeklyReviewHistory {
    /// Days since last review
    var daysSinceLastReview: Int? {
        guard let lastReview = lastReviewDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: lastReview, to: Date()).day
        return days
    }

    /// Whether a review is overdue (more than 7 days)
    var isOverdue: Bool {
        guard let days = daysSinceLastReview else { return true }
        return days > 7
    }

    /// Status message for display
    var statusMessage: String {
        guard let lastReview = lastReviewDate else {
            return "No reviews completed yet"
        }

        guard let days = daysSinceLastReview else {
            return "Last review date unknown"
        }

        if days == 0 {
            return "Reviewed today!"
        } else if days == 1 {
            return "Reviewed yesterday"
        } else if days < 7 {
            return "Reviewed \(days) days ago"
        } else {
            let weeks = days / 7
            return weeks == 1 ? "Reviewed 1 week ago" : "Reviewed \(weeks) weeks ago"
        }
    }
}
