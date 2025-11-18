//
//  AnalyticsCalculator.swift
//  StickyToDo
//
//  Calculates comprehensive analytics and statistics for tasks.
//

import Foundation

/// Calculates various analytics and statistics for task data
///
/// Provides insights into:
/// - Task completion rates
/// - Task distribution by status, priority, project
/// - Productivity trends
/// - Average completion time
/// - Most productive days/times
public class AnalyticsCalculator {

    // MARK: - Public Types

    /// Comprehensive analytics result
    public struct Analytics {
        // Completion metrics
        public let totalTasks: Int
        public let completedTasks: Int
        public let activeTasks: Int
        public let completionRate: Double

        // Task distribution
        public let tasksByStatus: [Status: Int]
        public let tasksByPriority: [Priority: Int]
        public let tasksByProject: [String: Int]
        public let tasksByContext: [String: Int]

        // Time metrics
        public let averageCompletionTime: TimeInterval?
        public let totalTimeSpent: TimeInterval
        public let averageTimePerTask: TimeInterval

        // Productivity trends
        public let completionsByWeek: [Date: Int]
        public let completionsByDay: [String: Int] // Day of week
        public let completionsByHour: [Int: Int]

        // Top performers
        public let mostProductiveProjects: [(project: String, completed: Int)]
        public let mostProductiveDays: [(day: String, completed: Int)]

        /// Creates analytics result
        public init(
            totalTasks: Int,
            completedTasks: Int,
            activeTasks: Int,
            completionRate: Double,
            tasksByStatus: [Status: Int],
            tasksByPriority: [Priority: Int],
            tasksByProject: [String: Int],
            tasksByContext: [String: Int],
            averageCompletionTime: TimeInterval?,
            totalTimeSpent: TimeInterval,
            averageTimePerTask: TimeInterval,
            completionsByWeek: [Date: Int],
            completionsByDay: [String: Int],
            completionsByHour: [Int: Int],
            mostProductiveProjects: [(project: String, completed: Int)],
            mostProductiveDays: [(day: String, completed: Int)]
        ) {
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.activeTasks = activeTasks
            self.completionRate = completionRate
            self.tasksByStatus = tasksByStatus
            self.tasksByPriority = tasksByPriority
            self.tasksByProject = tasksByProject
            self.tasksByContext = tasksByContext
            self.averageCompletionTime = averageCompletionTime
            self.totalTimeSpent = totalTimeSpent
            self.averageTimePerTask = averageTimePerTask
            self.completionsByWeek = completionsByWeek
            self.completionsByDay = completionsByDay
            self.completionsByHour = completionsByHour
            self.mostProductiveProjects = mostProductiveProjects
            self.mostProductiveDays = mostProductiveDays
        }
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Public API

    /// Calculates comprehensive analytics for the given tasks
    /// - Parameters:
    ///   - tasks: Tasks to analyze
    ///   - dateRange: Optional date range to filter by (uses created date)
    /// - Returns: Analytics result
    public func calculate(for tasks: [Task], dateRange: DateInterval? = nil) -> Analytics {
        var filteredTasks = tasks

        // Apply date range filter if specified
        if let range = dateRange {
            filteredTasks = tasks.filter { task in
                range.contains(task.created)
            }
        }

        // Basic counts
        let totalTasks = filteredTasks.count
        let completedTasks = filteredTasks.filter { $0.status == .completed }.count
        let activeTasks = filteredTasks.filter { $0.status != .completed }.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0

        // Distribution by status
        let tasksByStatus = Dictionary(grouping: filteredTasks, by: { $0.status })
            .mapValues { $0.count }

        // Distribution by priority
        let tasksByPriority = Dictionary(grouping: filteredTasks, by: { $0.priority })
            .mapValues { $0.count }

        // Distribution by project
        let tasksByProject = Dictionary(grouping: filteredTasks, by: { $0.project ?? "No Project" })
            .mapValues { $0.count }

        // Distribution by context
        let tasksByContext = Dictionary(grouping: filteredTasks.filter { $0.context != nil }, by: { $0.context! })
            .mapValues { $0.count }

        // Time metrics
        let tasksWithTime = filteredTasks.filter { $0.totalTimeSpent > 0 }
        let totalTimeSpent = filteredTasks.reduce(0.0) { $0 + $1.totalTimeSpent }
        let averageTimePerTask = tasksWithTime.isEmpty ? 0.0 : totalTimeSpent / Double(tasksWithTime.count)

        // Average completion time (created to modified for completed tasks)
        let completedTasksWithDates = filteredTasks.filter { $0.status == .completed }
        let averageCompletionTime: TimeInterval?
        if !completedTasksWithDates.isEmpty {
            let totalCompletionTime = completedTasksWithDates.reduce(0.0) { result, task in
                return result + task.modified.timeIntervalSince(task.created)
            }
            averageCompletionTime = totalCompletionTime / Double(completedTasksWithDates.count)
        } else {
            averageCompletionTime = nil
        }

        // Completions by week
        let completionsByWeek = calculateCompletionsByWeek(completedTasksWithDates)

        // Completions by day of week
        let completionsByDay = calculateCompletionsByDay(completedTasksWithDates)

        // Completions by hour
        let completionsByHour = calculateCompletionsByHour(completedTasksWithDates)

        // Most productive projects
        let projectCompletions = Dictionary(grouping: completedTasksWithDates, by: { $0.project ?? "No Project" })
            .mapValues { $0.count }
        let mostProductiveProjects = projectCompletions.sorted { $0.value > $1.value }
            .prefix(5)
            .map { (project: $0.key, completed: $0.value) }

        // Most productive days
        let mostProductiveDays = completionsByDay.sorted { $0.value > $1.value }
            .map { (day: $0.key, completed: $0.value) }

        return Analytics(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            activeTasks: activeTasks,
            completionRate: completionRate,
            tasksByStatus: tasksByStatus,
            tasksByPriority: tasksByPriority,
            tasksByProject: tasksByProject,
            tasksByContext: tasksByContext,
            averageCompletionTime: averageCompletionTime,
            totalTimeSpent: totalTimeSpent,
            averageTimePerTask: averageTimePerTask,
            completionsByWeek: completionsByWeek,
            completionsByDay: completionsByDay,
            completionsByHour: completionsByHour,
            mostProductiveProjects: Array(mostProductiveProjects),
            mostProductiveDays: mostProductiveDays
        )
    }

    /// Calculates weekly completion rate for the past N weeks
    /// - Parameters:
    ///   - tasks: Tasks to analyze
    ///   - weeks: Number of weeks to analyze (default: 12)
    /// - Returns: Array of (week start date, completion count) tuples
    public func weeklyCompletionRate(for tasks: [Task], weeks: Int = 12) -> [(Date, Int)] {
        let calendar = Calendar.current
        let now = Date()

        var results: [(Date, Int)] = []

        for weekOffset in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                  let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
                continue
            }

            let completionsThisWeek = tasks.filter { task in
                task.status == .completed &&
                task.modified >= weekStart &&
                task.modified < weekEnd
            }.count

            results.append((weekStart, completionsThisWeek))
        }

        return results.reversed()
    }

    /// Calculates productivity score (0.0 - 1.0) based on various factors
    /// - Parameter tasks: Tasks to analyze
    /// - Returns: Productivity score
    public func productivityScore(for tasks: [Task]) -> Double {
        guard !tasks.isEmpty else { return 0.0 }

        let activeTasks = tasks.filter { $0.status != .completed }
        let completedTasks = tasks.filter { $0.status == .completed }

        // Factor 1: Completion rate (40%)
        let completionFactor = tasks.count > 0 ? Double(completedTasks.count) / Double(tasks.count) : 0.0

        // Factor 2: Next actions vs inbox (30%)
        let inboxTasks = activeTasks.filter { $0.status == .inbox }.count
        let nextActionTasks = activeTasks.filter { $0.status == .nextAction }.count
        let actionFactor = activeTasks.isEmpty ? 1.0 : Double(nextActionTasks) / Double(max(1, inboxTasks + nextActionTasks))

        // Factor 3: Overdue tasks (20%)
        let overdueTasks = activeTasks.filter { $0.isOverdue }.count
        let overdueFactor = activeTasks.isEmpty ? 1.0 : 1.0 - (Double(overdueTasks) / Double(activeTasks.count))

        // Factor 4: Time tracking usage (10%)
        let tasksWithTime = tasks.filter { $0.totalTimeSpent > 0 }.count
        let timeFactor = tasks.isEmpty ? 0.0 : Double(tasksWithTime) / Double(tasks.count)

        // Weighted average
        let score = (completionFactor * 0.4) + (actionFactor * 0.3) + (overdueFactor * 0.2) + (timeFactor * 0.1)

        return min(1.0, max(0.0, score))
    }

    // MARK: - Private Helpers

    private func calculateCompletionsByWeek(_ tasks: [Task]) -> [Date: Int] {
        let calendar = Calendar.current
        var completionsByWeek: [Date: Int] = [:]

        for task in tasks {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: task.modified))!
            completionsByWeek[weekStart, default: 0] += 1
        }

        return completionsByWeek
    }

    private func calculateCompletionsByDay(_ tasks: [Task]) -> [String: Int] {
        let calendar = Calendar.current
        var completionsByDay: [String: Int] = [:]

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE" // Full day name (e.g., "Monday")

        for task in tasks {
            let dayName = dayFormatter.string(from: task.modified)
            completionsByDay[dayName, default: 0] += 1
        }

        return completionsByDay
    }

    private func calculateCompletionsByHour(_ tasks: [Task]) -> [Int: Int] {
        let calendar = Calendar.current
        var completionsByHour: [Int: Int] = [:]

        for task in tasks {
            let hour = calendar.component(.hour, from: task.modified)
            completionsByHour[hour, default: 0] += 1
        }

        return completionsByHour
    }
}

// MARK: - Formatting Helpers

extension AnalyticsCalculator.Analytics {
    /// Human-readable completion rate string
    public var completionRateString: String {
        return String(format: "%.1f%%", completionRate * 100)
    }

    /// Human-readable average completion time string
    public var averageCompletionTimeString: String? {
        guard let avgTime = averageCompletionTime else { return nil }

        let days = Int(avgTime / 86400)
        let hours = Int((avgTime.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((avgTime.truncatingRemainder(dividingBy: 3600)) / 60)

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Human-readable total time spent string
    public var totalTimeSpentString: String {
        let hours = Int(totalTimeSpent / 3600)
        let minutes = Int((totalTimeSpent.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Human-readable average time per task string
    public var averageTimePerTaskString: String {
        let minutes = Int(averageTimePerTask / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
