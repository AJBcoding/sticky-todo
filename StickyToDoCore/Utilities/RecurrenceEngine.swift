//
//  RecurrenceEngine.swift
//  StickyToDo
//
//  Engine for calculating recurrence dates and creating recurring task instances.
//

import Foundation

/// Engine for managing recurring task logic
public enum RecurrenceEngine {

    // MARK: - Next Occurrence Calculation

    /// Calculates the next occurrence date based on a recurrence pattern
    /// - Parameters:
    ///   - date: The base date to calculate from
    ///   - recurrence: The recurrence pattern
    /// - Returns: The next occurrence date, or nil if recurrence is complete
    static func calculateNextOccurrence(from date: Date, recurrence: Recurrence) -> Date? {
        // Check if recurrence is complete
        if recurrence.isComplete {
            return nil
        }

        let calendar = Calendar.current

        switch recurrence.frequency {
        case .daily:
            return calculateDailyOccurrence(from: date, interval: recurrence.interval, calendar: calendar)

        case .weekly:
            return calculateWeeklyOccurrence(
                from: date,
                interval: recurrence.interval,
                daysOfWeek: recurrence.daysOfWeek,
                calendar: calendar
            )

        case .monthly:
            return calculateMonthlyOccurrence(
                from: date,
                interval: recurrence.interval,
                dayOfMonth: recurrence.dayOfMonth,
                useLastDay: recurrence.useLastDayOfMonth,
                calendar: calendar
            )

        case .yearly:
            return calculateYearlyOccurrence(from: date, interval: recurrence.interval, calendar: calendar)

        case .custom:
            // For custom patterns, use daily as fallback
            return calculateDailyOccurrence(from: date, interval: recurrence.interval, calendar: calendar)
        }
    }

    // MARK: - Daily Recurrence

    private static func calculateDailyOccurrence(
        from date: Date,
        interval: Int,
        calendar: Calendar
    ) -> Date? {
        return calendar.date(byAdding: .day, value: interval, to: date)
    }

    // MARK: - Weekly Recurrence

    private static func calculateWeeklyOccurrence(
        from date: Date,
        interval: Int,
        daysOfWeek: [Int]?,
        calendar: Calendar
    ) -> Date? {
        // If no specific days are set, just add weeks
        guard let targetDays = daysOfWeek, !targetDays.isEmpty else {
            return calendar.date(byAdding: .weekOfYear, value: interval, to: date)
        }

        // Get current weekday (0 = Sunday, 6 = Saturday)
        let currentWeekday = calendar.component(.weekday, from: date) - 1 // Convert to 0-based
        let sortedDays = targetDays.sorted()

        // Find next occurrence day in the same week
        if let nextDayInWeek = sortedDays.first(where: { $0 > currentWeekday }) {
            let daysToAdd = nextDayInWeek - currentWeekday
            return calendar.date(byAdding: .day, value: daysToAdd, to: date)
        }

        // No more days this week, move to next occurrence week
        let firstDayNextWeek = sortedDays.first ?? 0
        let daysUntilNextWeek = 7 - currentWeekday + firstDayNextWeek
        let weeksToAdd = interval - 1 // We're already moving to next week
        let totalDaysToAdd = daysUntilNextWeek + (weeksToAdd * 7)

        return calendar.date(byAdding: .day, value: totalDaysToAdd, to: date)
    }

    // MARK: - Monthly Recurrence

    private static func calculateMonthlyOccurrence(
        from date: Date,
        interval: Int,
        dayOfMonth: Int?,
        useLastDay: Bool,
        calendar: Calendar
    ) -> Date? {
        // Get the next month
        guard var nextMonth = calendar.date(byAdding: .month, value: interval, to: date) else {
            return nil
        }

        // Use last day of month if specified
        if useLastDay {
            let range = calendar.range(of: .day, in: .month, for: nextMonth)
            let lastDay = range?.count ?? 28
            var components = calendar.dateComponents([.year, .month], from: nextMonth)
            components.day = lastDay
            return calendar.date(from: components)
        }

        // Use specific day of month
        if let targetDay = dayOfMonth {
            var components = calendar.dateComponents([.year, .month], from: nextMonth)
            components.day = targetDay

            // If the day doesn't exist in this month (e.g., Feb 30), use last day
            let range = calendar.range(of: .day, in: .month, for: nextMonth)
            let maxDay = range?.count ?? 28
            components.day = min(targetDay, maxDay)

            return calendar.date(from: components)
        }

        // No specific day set, use same day as original
        return nextMonth
    }

    // MARK: - Yearly Recurrence

    private static func calculateYearlyOccurrence(
        from date: Date,
        interval: Int,
        calendar: Calendar
    ) -> Date? {
        return calendar.date(byAdding: .year, value: interval, to: date)
    }

    // MARK: - Occurrence Checking

    /// Determines if a new occurrence should be created for a recurring task
    /// - Parameters:
    ///   - task: The recurring template task
    ///   - existingInstances: Currently existing instances of this task
    /// - Returns: True if a new occurrence should be created
    static func shouldCreateNewOccurrence(
        task: Task,
        existingInstances: [Task]
    ) -> Bool {
        // Task must be recurring
        guard task.isRecurring,
              let recurrence = task.recurrence,
              !recurrence.isComplete else {
            return false
        }

        // Calculate next occurrence date
        let baseDate = task.due ?? Date()
        guard let nextDate = calculateNextOccurrence(from: baseDate, recurrence: recurrence) else {
            return false
        }

        // Check if next occurrence is in the future (don't create past occurrences)
        let now = Date()
        guard nextDate <= now else {
            return false
        }

        // Check if an instance already exists for this date
        let calendar = Calendar.current
        let hasExistingInstance = existingInstances.contains { instance in
            guard let occurrenceDate = instance.occurrenceDate else { return false }
            return calendar.isDate(occurrenceDate, inSameDayAs: nextDate)
        }

        return !hasExistingInstance
    }

    // MARK: - Instance Creation

    /// Creates the next occurrence of a recurring task
    /// - Parameters:
    ///   - template: The recurring template task
    ///   - occurrenceDate: The date this occurrence represents (optional, defaults to next occurrence)
    /// - Returns: A new task instance for the next occurrence
    static func createNextOccurrence(
        from template: Task,
        occurrenceDate: Date? = nil
    ) -> Task? {
        guard template.isRecurring,
              var recurrence = template.recurrence,
              !recurrence.isComplete else {
            return nil
        }

        // Calculate occurrence date
        let baseDate = template.due ?? Date()
        let nextDate = occurrenceDate ?? calculateNextOccurrence(from: baseDate, recurrence: recurrence)

        guard let occurrenceDate = nextDate else {
            return nil
        }

        // Increment occurrence count
        recurrence.occurrenceCount += 1

        // Create new task instance
        var newTask = Task(
            type: template.type,
            title: template.title,
            notes: template.notes,
            status: .inbox, // New occurrences start in inbox
            project: template.project,
            context: template.context,
            due: occurrenceDate,
            defer: template.defer,
            flagged: template.flagged,
            priority: template.priority,
            effort: template.effort,
            positions: [:], // Don't copy positions
            parentId: template.parentId,
            subtaskIds: [], // Don't copy subtasks
            recurrence: nil, // Instances don't have recurrence patterns
            originalTaskId: template.id,
            occurrenceDate: occurrenceDate
        )

        return newTask
    }

    // MARK: - Batch Processing

    /// Creates all due occurrences for a recurring task up to the current date
    /// - Parameters:
    ///   - template: The recurring template task
    ///   - existingInstances: Already created instances
    /// - Returns: Array of new task instances to be created
    static func createDueOccurrences(
        from template: Task,
        existingInstances: [Task]
    ) -> [Task] {
        guard template.isRecurring,
              let recurrence = template.recurrence,
              !recurrence.isComplete else {
            return []
        }

        var newInstances: [Task] = []
        var currentDate = template.due ?? Date()
        let now = Date()
        let calendar = Calendar.current

        // Create up to 100 occurrences (safety limit)
        var iterationCount = 0
        let maxIterations = 100

        while iterationCount < maxIterations {
            // Calculate next occurrence
            guard let nextDate = calculateNextOccurrence(from: currentDate, recurrence: recurrence) else {
                break
            }

            // Stop if next occurrence is in the future
            if nextDate > now {
                break
            }

            // Check if this occurrence already exists
            let alreadyExists = existingInstances.contains { instance in
                guard let occurrenceDate = instance.occurrenceDate else { return false }
                return calendar.isDate(occurrenceDate, inSameDayAs: nextDate)
            }

            // Create new instance if it doesn't exist
            if !alreadyExists {
                if let newInstance = createNextOccurrence(from: template, occurrenceDate: nextDate) {
                    newInstances.append(newInstance)
                }
            }

            // Move to next occurrence
            currentDate = nextDate
            iterationCount += 1

            // Check count limit
            if let maxCount = recurrence.count,
               recurrence.occurrenceCount + newInstances.count >= maxCount {
                break
            }

            // Check end date
            if let endDate = recurrence.endDate, nextDate >= endDate {
                break
            }
        }

        return newInstances
    }

    // MARK: - Utilities

    /// Returns all instances of a recurring task
    /// - Parameters:
    ///   - template: The recurring template task
    ///   - allTasks: All tasks in the system
    /// - Returns: Array of task instances created from this template
    static func instances(of template: Task, in allTasks: [Task]) -> [Task] {
        return allTasks.filter { $0.originalTaskId == template.id }
    }

    /// Updates the recurrence pattern on a template task
    /// - Parameters:
    ///   - task: The task to update
    ///   - recurrence: The new recurrence pattern
    /// - Returns: Updated task with new recurrence pattern
    static func updateRecurrence(task: Task, recurrence: Recurrence?) -> Task {
        var updatedTask = task
        updatedTask.recurrence = recurrence
        updatedTask.modified = Date()
        return updatedTask
    }

    /// Completes a recurring task instance and creates the next occurrence
    /// - Parameters:
    ///   - instance: The instance being completed
    ///   - template: The recurring template task
    /// - Returns: The next occurrence task, or nil if no more occurrences
    static func completeInstanceAndCreateNext(
        instance: Task,
        template: Task
    ) -> Task? {
        // Only works for recurring instances
        guard instance.isRecurringInstance else { return nil }

        // Create next occurrence
        return createNextOccurrence(from: template)
    }
}
