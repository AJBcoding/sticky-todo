//
//  TaskStore.swift
//  StickyToDo
//
//  In-memory store for all tasks with SwiftUI/AppKit integration.
//  Provides thread-safe access, debounced auto-save, and reactive updates.
//

import Foundation
import Combine
import EventKit

@available(macOS 10.15, *)
/// In-memory store managing all tasks in the application
///
/// TaskStore is the single source of truth for task data. It:
/// - Maintains all tasks in memory for fast access
/// - Publishes changes via Combine for SwiftUI/AppKit reactivity
/// - Debounces writes to disk to avoid excessive I/O
/// - Provides thread-safe access via serial queue
/// - Filters and searches tasks efficiently
///
/// Usage with SwiftUI:
/// ```swift
/// @ObservedObject var taskStore: TaskStore
/// ```
///
/// Usage with AppKit:
/// ```swift
/// taskStore.$tasks.sink { tasks in
///     // Update UI
/// }
/// ```
final class TaskStore: ObservableObject {

    // MARK: - Published Properties

    /// All tasks in the store
    /// Published for SwiftUI/Combine reactivity
    @Published private(set) var tasks: [Task] = []

    /// All unique project names across all tasks
    @Published private(set) var projects: [String] = []

    /// All unique contexts across all tasks
    @Published private(set) var contexts: [String] = []

    // MARK: - Private Properties

    /// File I/O handler for reading/writing markdown files
    private let fileIO: MarkdownFileIO

    /// Rules engine for automation
    private var rulesEngine: RulesEngine

    /// Activity log manager for change tracking
    private var activityLogManager: ActivityLogManager?

    /// Notification manager for scheduling notifications
    private let notificationManager = NotificationManager.shared

    /// Calendar manager for syncing tasks with EventKit
    private let calendarManager = CalendarManager.shared

    /// Spotlight manager for search integration
    private let spotlightManager = SpotlightManager.shared

    /// Serial queue for thread-safe access to tasks
    private let queue = DispatchQueue(label: "com.stickytodo.taskstore", qos: .userInitiated)

    /// Debounce timer for auto-save operations
    private var saveTimers: [UUID: Timer] = [:]

    /// Save debounce interval (500ms as per spec)
    private let saveDebounceInterval: TimeInterval = 0.5

    /// Logger for debugging operations
    private var logger: ((String) -> Void)?

    /// Track which tasks have pending saves
    private var pendingSaves: Set<UUID> = []

    // MARK: - Performance Monitoring

    /// Performance thresholds for task count
    private enum PerformanceThreshold {
        static let warning = 500
        static let alert = 1000
        static let critical = 1500
    }

    /// Last logged performance level to avoid duplicate warnings
    private var lastPerformanceLevel: PerformanceLevel = .normal

    /// Performance monitoring level
    private enum PerformanceLevel {
        case normal
        case warning
        case alert
        case critical
    }

    /// Performance metrics for monitoring
    private struct PerformanceMetrics {
        let taskCount: Int
        let activeTaskCount: Int
        let completedTaskCount: Int
        let timestamp: Date
        let level: PerformanceLevel

        func logMessage() -> String {
            let levelEmoji: String
            switch level {
            case .normal:
                levelEmoji = "✓"
            case .warning:
                levelEmoji = "⚠️"
            case .alert:
                levelEmoji = "🚨"
            case .critical:
                levelEmoji = "❌"
            }

            return """
            \(levelEmoji) Performance Metrics [\(timestamp)]
            Total Tasks: \(taskCount)
            Active Tasks: \(activeTaskCount)
            Completed Tasks: \(completedTaskCount)
            """
        }
    }

    // MARK: - Initialization

    /// Creates a new TaskStore
    ///
    /// - Parameter fileIO: The file I/O handler for persistence
    init(fileIO: MarkdownFileIO) {
        self.fileIO = fileIO
        self.rulesEngine = RulesEngine()
    }

    /// Configure logging for task store operations
    /// - Parameter logger: A closure that receives log messages
    func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
        self.rulesEngine.setLogger(logger)
        self.activityLogManager?.setLogger(logger)
    }

    /// Sets the activity log manager for change tracking
    /// - Parameter manager: The activity log manager to use
    func setActivityLogManager(_ manager: ActivityLogManager) {
        self.activityLogManager = manager
        self.activityLogManager?.setLogger(logger ?? { _ in })
    }

    // MARK: - Performance Monitoring Methods

    /// Checks task count and logs performance warnings/alerts
    /// This method is called after loading and adding tasks
    private func checkPerformanceMetrics() {
        let count = tasks.count
        let activeCount = activeTaskCount
        let completedCount = completedTaskCount

        // Determine performance level
        let currentLevel: PerformanceLevel
        if count >= PerformanceThreshold.critical {
            currentLevel = .critical
        } else if count >= PerformanceThreshold.alert {
            currentLevel = .alert
        } else if count >= PerformanceThreshold.warning {
            currentLevel = .warning
        } else {
            currentLevel = .normal
        }

        // Only log if level has changed or is above normal
        guard currentLevel != lastPerformanceLevel || currentLevel != .normal else {
            return
        }

        // Create metrics
        let metrics = PerformanceMetrics(
            taskCount: count,
            activeTaskCount: activeCount,
            completedTaskCount: completedCount,
            timestamp: Date(),
            level: currentLevel
        )

        // Log metrics
        logger?(metrics.logMessage())

        // Log specific warnings/alerts with actionable suggestions
        switch currentLevel {
        case .normal:
            if lastPerformanceLevel != .normal {
                logger?("✓ Task count is back to normal levels")
            }

        case .warning:
            logger?("""
            ⚠️ WARNING: Task count approaching performance threshold
            Current: \(count) tasks (Warning threshold: \(PerformanceThreshold.warning))

            Recommendation: Consider archiving completed tasks to maintain optimal performance.
            Active tasks: \(activeCount) | Completed tasks: \(completedCount)
            """)

        case .alert:
            logger?("""
            🚨 ALERT: Task count exceeds recommended limit
            Current: \(count) tasks (Alert threshold: \(PerformanceThreshold.alert))

            URGENT: Archive or delete old completed tasks to prevent performance degradation.
            - You have \(completedCount) completed tasks that could be archived
            - Active tasks: \(activeCount)

            Performance may be impacted with this many tasks.
            """)

        case .critical:
            logger?("""
            ❌ CRITICAL: Task count at critical level
            Current: \(count) tasks (Critical threshold: \(PerformanceThreshold.critical))

            IMMEDIATE ACTION REQUIRED:
            1. Archive completed tasks (\(completedCount) available)
            2. Delete unnecessary tasks
            3. Consider splitting tasks into separate data files

            Severe performance degradation likely at this task count!
            """)
        }

        // Update last logged level
        lastPerformanceLevel = currentLevel
    }

    /// Returns current performance metrics as a public API
    /// - Returns: Dictionary with performance information
    func getPerformanceMetrics() -> [String: Any] {
        let count = tasks.count
        let level: String

        if count >= PerformanceThreshold.critical {
            level = "critical"
        } else if count >= PerformanceThreshold.alert {
            level = "alert"
        } else if count >= PerformanceThreshold.warning {
            level = "warning"
        } else {
            level = "normal"
        }

        return [
            "taskCount": count,
            "activeTaskCount": activeTaskCount,
            "completedTaskCount": completedTaskCount,
            "level": level,
            "warningThreshold": PerformanceThreshold.warning,
            "alertThreshold": PerformanceThreshold.alert,
            "criticalThreshold": PerformanceThreshold.critical,
            "percentOfWarning": Double(count) / Double(PerformanceThreshold.warning) * 100.0,
            "percentOfAlert": Double(count) / Double(PerformanceThreshold.alert) * 100.0
        ]
    }

    /// Checks if task count is at or above warning threshold
    var isAtWarningThreshold: Bool {
        return tasks.count >= PerformanceThreshold.warning
    }

    /// Checks if task count is at or above alert threshold
    var isAtAlertThreshold: Bool {
        return tasks.count >= PerformanceThreshold.alert
    }

    /// Checks if task count is at or above critical threshold
    var isAtCriticalThreshold: Bool {
        return tasks.count >= PerformanceThreshold.critical
    }

    /// Returns tasks that are eligible for archiving (completed and older than 30 days)
    func archivableTasksCount() -> Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return tasks.filter { task in
            task.status == .completed && task.modified < thirtyDaysAgo
        }.count
    }

    /// Returns a suggestion message based on current task count
    func getPerformanceSuggestion() -> String? {
        let count = tasks.count

        if count >= PerformanceThreshold.critical {
            return "Critical: \(count) tasks. Archive \(archivableTasksCount()) old completed tasks immediately."
        } else if count >= PerformanceThreshold.alert {
            return "Alert: \(count) tasks. Consider archiving \(archivableTasksCount()) completed tasks."
        } else if count >= PerformanceThreshold.warning {
            return "Warning: \(count) tasks. You may want to archive old completed tasks soon."
        }

        return nil
    }

    // MARK: - Rules Management

    /// Loads automation rules from file system
    func loadRules() throws {
        let rules = try fileIO.loadAllRules()
        rulesEngine = RulesEngine(rules: rules)
        rulesEngine.setLogger(logger ?? { _ in })
        rulesEngine.buildProjectContextMappings(from: tasks)
        logger?("Loaded \(rules.count) automation rules")
    }

    /// Saves automation rules to file system
    func saveRules() throws {
        try fileIO.writeAllRules(rulesEngine.rules)
        logger?("Saved \(rulesEngine.rules.count) automation rules")
    }

    /// Returns all automation rules
    var automationRules: [Rule] {
        return rulesEngine.rules
    }

    /// Adds a new automation rule
    func addRule(_ rule: Rule) {
        rulesEngine.addRule(rule)
        try? saveRules()
    }

    /// Updates an existing automation rule
    func updateRule(_ rule: Rule) {
        rulesEngine.updateRule(rule)
        try? saveRules()
    }

    /// Removes an automation rule
    func removeRule(_ rule: Rule) {
        rulesEngine.removeRule(rule)
        try? saveRules()
    }

    /// Toggles a rule's enabled state
    func toggleRule(_ rule: Rule) {
        rulesEngine.toggleRule(rule)
        try? saveRules()
    }

    /// Loads built-in rule templates
    func loadBuiltInRuleTemplates() {
        rulesEngine.loadBuiltInTemplates()
        try? saveRules()
    }

    // MARK: - Loading

    /// Loads all tasks from the file system
    ///
    /// This should be called once at app launch to populate the in-memory store.
    ///
    /// - Throws: MarkdownFileError if loading fails
    func loadAll() throws {
        logger?("Loading all tasks from file system")

        let loadedTasks = try fileIO.loadAllTasks()

        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.tasks = loadedTasks
                self.updateDerivedData()
                self.logger?("Loaded \(loadedTasks.count) tasks into store")

                // Check performance metrics after loading
                self.checkPerformanceMetrics()
            }
        }
    }

    /// Loads all tasks asynchronously
    func loadAllAsync() async throws {
        logger?("Loading all tasks asynchronously")
        let loadedTasks = try fileIO.loadAllTasks()

        await MainActor.run {
            self.tasks = loadedTasks
            self.updateDerivedData()
            self.logger?("Loaded \(loadedTasks.count) tasks into store")

            // Check performance metrics after loading
            self.checkPerformanceMetrics()
        }
    }

    // MARK: - CRUD Operations

    /// Adds a new task to the store
    ///
    /// The task is immediately added to the in-memory store and written to disk
    /// asynchronously with debouncing.
    ///
    /// - Parameter task: The task to add
    func add(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Check if task already exists
                if !self.tasks.contains(where: { $0.id == task.id }) {
                    // Apply automation rules for task creation
                    let context = TaskChangeContext.taskCreated(task)
                    var modifiedTask = self.rulesEngine.evaluateRules(for: context, task: task)

                    // Schedule notifications for the task
                    Task {
                        await self.scheduleNotifications(for: &modifiedTask)

                        // Update the task with notification IDs
                        if let index = self.tasks.firstIndex(where: { $0.id == modifiedTask.id }) {
                            self.tasks[index] = modifiedTask
                            self.scheduleSave(for: modifiedTask)
                        }
                    }

                    self.tasks.append(modifiedTask)
                    self.updateDerivedData()
                    self.logger?("Added task: \(modifiedTask.title)")

                    // Log the creation
                    let log = ActivityLog.taskCreated(task: modifiedTask)
                    self.activityLogManager?.addLog(log)

                    // Sync with calendar if auto-sync is enabled
                    if self.calendarManager.preferences.autoSyncEnabled {
                        let syncResult = self.calendarManager.syncTask(modifiedTask)
                        if case .success(let eventId) = syncResult, let eventId = eventId {
                            modifiedTask.calendarEventId = eventId
                            if let idx = self.tasks.firstIndex(where: { $0.id == modifiedTask.id }) {
                                self.tasks[idx] = modifiedTask
                            }
                            self.logger?("Synced task to calendar: \(eventId)")
                        }
                    }

                    // Index task in Spotlight for system-wide search
                    self.spotlightManager.indexTask(modifiedTask)

                    // Schedule debounced save
                    self.scheduleSave(for: modifiedTask)

                    // Check performance metrics after adding task
                    self.checkPerformanceMetrics()
                }
            }
        }
    }

    /// Updates an existing task in the store
    ///
    /// - Parameter task: The updated task
    func update(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                guard let index = self.tasks.firstIndex(where: { $0.id == task.id }) else { return }

                let oldTask = self.tasks[index]
                var updatedTask = task
                updatedTask.modified = Date()

                // Generate activity logs for changes
                self.logTaskChanges(from: oldTask, to: updatedTask)

                // Trigger automation rules based on changes
                self.triggerRulesForChanges(from: oldTask, to: &updatedTask)

                // Re-schedule notifications if needed
                self.updateNotifications(from: oldTask, to: &updatedTask)

                // Sync with external services (Calendar, Spotlight)
                self.syncWithExternalServices(&updatedTask)

                self.tasks[index] = updatedTask
                self.updateDerivedData()
                self.logger?("Updated task: \(task.title)")

                // Schedule debounced save
                self.scheduleSave(for: updatedTask)
            }
        }
    }

    /// Updates notifications for a task if dates or status changed
    ///
    /// This method handles notification rescheduling when:
    /// - Due date changes
    /// - Defer date changes
    /// - Task status changes
    ///
    /// - Parameters:
    ///   - oldTask: The previous task state
    ///   - updatedTask: The updated task (modified in-place with new notification IDs)
    private func updateNotifications(from oldTask: Task, to updatedTask: inout Task) {
        let needsReschedule = oldTask.due != updatedTask.due ||
                             oldTask.defer != updatedTask.defer ||
                             oldTask.status != updatedTask.status

        guard needsReschedule else { return }

        Task {
            await self.scheduleNotifications(for: &updatedTask)

            // Update the task with new notification IDs
            if let currentIndex = self.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                self.tasks[currentIndex] = updatedTask
                self.scheduleSave(for: updatedTask)
            }
        }
    }

    /// Syncs a task with external services (Calendar and Spotlight)
    ///
    /// This method handles:
    /// - Calendar event creation/update when auto-sync is enabled
    /// - Spotlight search index updates
    ///
    /// - Parameter task: The task to sync (modified in-place if calendar event ID changes)
    private func syncWithExternalServices(_ task: inout Task) {
        // Sync with calendar if auto-sync is enabled
        if calendarManager.preferences.autoSyncEnabled {
            let syncResult = calendarManager.syncTask(task)
            if case .success(let eventId) = syncResult, let eventId = eventId {
                task.calendarEventId = eventId
                logger?("Updated calendar event: \(eventId)")
            }
        }

        // Update task in Spotlight index
        spotlightManager.indexTask(task)
    }

    /// Deletes a task from the store
    ///
    /// - Parameter task: The task to delete
    func delete(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    let taskToDelete = self.tasks[index]

                    // Cancel all notifications for this task
                    self.notificationManager.cancelNotifications(for: taskToDelete)

                    self.tasks.remove(at: index)
                    self.updateDerivedData()
                    self.logger?("Deleted task: \(task.title)")

                    // Log the deletion
                    let log = ActivityLog.taskDeleted(task: task)
                    self.activityLogManager?.addLog(log)

                    // Delete calendar event if it exists
                    if let eventId = task.calendarEventId {
                        let result = self.calendarManager.deleteEvent(eventId)
                        if case .failure(let error) = result {
                            self.logger?("Failed to delete calendar event: \(error.localizedDescription)")
                        } else {
                            self.logger?("Deleted calendar event: \(eventId)")
                        }
                    }

                    // Cancel any pending save
                    // Remove task from Spotlight index
                    self.spotlightManager.deindexTask(taskToDelete)

                    self.cancelSave(for: task.id)

                    // Update badge count after deletion
                    self.updateBadgeCount()

                    // Check performance metrics after deletion (may have improved)
                    self.checkPerformanceMetrics()

                    // Delete from file system
                    self.queue.async {
                        do {
                            try self.fileIO.deleteTask(task)
                        } catch {
                            self.logger?("Failed to delete task file: \(error)")
                        }
                    }
                }
            }
        }
    }

    /// Saves a task to disk with debouncing
    ///
    /// Multiple rapid calls to save the same task will be coalesced into a single
    /// write operation after the debounce interval.
    ///
    /// - Parameter task: The task to save
    func save(_ task: Task) {
        scheduleSave(for: task)
    }

    /// Immediately saves a task to disk without debouncing
    ///
    /// Use this when you need to ensure a task is persisted immediately,
    /// such as before the app quits.
    ///
    /// - Parameter task: The task to save
    /// - Throws: MarkdownFileError if saving fails
    func saveImmediately(_ task: Task) throws {
        cancelSave(for: task.id)
        try fileIO.writeTask(task)
        logger?("Immediately saved task: \(task.title)")
    }

    /// Immediately saves all tasks to disk
    ///
    /// Use this before the app quits to ensure all pending changes are persisted.
    ///
    /// - Throws: MarkdownFileError if saving fails
    func saveAll() throws {
        logger?("Saving all tasks to disk")

        // Cancel all pending saves
        for taskID in pendingSaves {
            cancelSave(for: taskID)
        }

        // Save all tasks
        for task in tasks {
            try fileIO.writeTask(task)
        }

        logger?("Saved all \(tasks.count) tasks")
    }

    // MARK: - Filtering and Searching

    /// Returns tasks matching a filter
    ///
    /// - Parameter filter: The filter criteria to match
    /// - Returns: Array of tasks matching the filter
    func tasks(matching filter: Filter) -> [Task] {
        return tasks.filter { $0.matches(filter) }
    }

    /// Returns tasks for a specific board
    ///
    /// - Parameter board: The board whose tasks to return
    /// - Returns: Array of tasks matching the board's filter
    func tasks(for board: Board) -> [Task] {
        return tasks.filter { $0.matches(board.filter) }
    }

    /// Returns tasks matching a search query
    ///
    /// - Parameter query: The search string
    /// - Returns: Array of tasks matching the query
    func tasks(matchingSearch query: String) -> [Task] {
        guard !query.isEmpty else { return tasks }
        return tasks.filter { $0.matchesSearch(query) }
    }

    /// Returns tasks for a specific project
    ///
    /// - Parameter project: The project name
    /// - Returns: Array of tasks in that project
    func tasks(forProject project: String) -> [Task] {
        return tasks.filter { $0.project == project }
    }

    /// Returns tasks for a specific context
    ///
    /// - Parameter context: The context name
    /// - Returns: Array of tasks in that context
    func tasks(forContext context: String) -> [Task] {
        return tasks.filter { $0.context == context }
    }

    /// Returns tasks with a specific status
    ///
    /// - Parameter status: The status to filter by
    /// - Returns: Array of tasks with that status
    func tasks(withStatus status: Status) -> [Task] {
        return tasks.filter { $0.status == status }
    }

    /// Returns tasks that are overdue
    ///
    /// - Returns: Array of overdue tasks
    func overdueTasks() -> [Task] {
        return tasks.filter { $0.isOverdue }
    }

    /// Returns tasks due today
    ///
    /// - Returns: Array of tasks due today
    func dueTodayTasks() -> [Task] {
        return tasks.filter { $0.isDueToday }
    }

    /// Returns tasks due this week
    ///
    /// - Returns: Array of tasks due within the next 7 days
    func dueThisWeekTasks() -> [Task] {
        return tasks.filter { $0.isDueThisWeek }
    }

    /// Returns tasks that are flagged
    ///
    /// - Returns: Array of flagged tasks
    func flaggedTasks() -> [Task] {
        return tasks.filter { $0.flagged }
    }

    // MARK: - Batch Operations

    /// Updates multiple tasks at once
    ///
    /// - Parameter tasks: The tasks to update
    func updateBatch(_ tasks: [Task]) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                for task in tasks {
                    if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                        var updatedTask = task
                        updatedTask.modified = Date()
                        self.tasks[index] = updatedTask
                        self.scheduleSave(for: updatedTask)
                    }
                }

                self.updateDerivedData()
                self.logger?("Batch updated \(tasks.count) tasks")
            }
        }
    }

    /// Deletes multiple tasks at once
    ///
    /// - Parameter tasks: The tasks to delete
    func deleteBatch(_ tasks: [Task]) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                let taskIDs = Set(tasks.map { $0.id })
                self.tasks.removeAll { taskIDs.contains($0.id) }
                self.updateDerivedData()
                self.logger?("Batch deleted \(tasks.count) tasks")

                // Check performance metrics after batch deletion
                self.checkPerformanceMetrics()

                // Delete from file system
                self.queue.async {
                    for task in tasks {
                        self.cancelSave(for: task.id)
                        do {
                            try self.fileIO.deleteTask(task)
                        } catch {
                            self.logger?("Failed to delete task file: \(error)")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Task Hierarchy

    /// Returns all subtasks for a given task
    ///
    /// - Parameter task: The parent task
    /// - Returns: Array of subtasks
    func subtasks(for task: Task) -> [Task] {
        return tasks.filter { task.subtaskIds.contains($0.id) }
    }

    /// Returns the parent task for a given task
    ///
    /// - Parameter task: The subtask
    /// - Returns: The parent task, or nil if the task has no parent
    func parentTask(for task: Task) -> Task? {
        guard let parentId = task.parentId else { return nil }
        return self.task(withID: parentId)
    }

    /// Returns all top-level tasks (tasks without a parent)
    ///
    /// - Returns: Array of top-level tasks
    func topLevelTasks() -> [Task] {
        return tasks.filter { !$0.isSubtask }
    }

    /// Returns the indentation level for a task (handles deep hierarchies)
    ///
    /// - Parameter task: The task to check
    /// - Returns: The indentation level (0 = top-level, 1 = first-level subtask, etc.)
    func indentationLevel(for task: Task) -> Int {
        var level = 0
        var currentTask = task

        // Traverse up the parent chain
        while let parentId = currentTask.parentId,
              let parent = self.task(withID: parentId) {
            level += 1
            currentTask = parent

            // Safety check to prevent infinite loops
            if level > 10 {
                logger?("Warning: Task hierarchy depth exceeds 10 levels for task: \(task.title)")
                break
            }
        }

        return level
    }

    /// Completes a task and all its subtasks
    ///
    /// - Parameter task: The task to complete
    func completeWithSubtasks(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Complete the task
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks[index].complete()
                    self.scheduleSave(for: self.tasks[index])
                }

                // Complete all subtasks recursively
                let subtasks = self.subtasks(for: task)
                for subtask in subtasks {
                    self.completeWithSubtasks(subtask)
                }

                self.updateDerivedData()
            }
        }
    }

    /// Uncompletes a task and its parent (if parent is completed)
    ///
    /// When a subtask is marked as incomplete, the parent should also be
    /// marked as incomplete since not all subtasks are done.
    ///
    /// - Parameter task: The task to uncomplete
    func uncompleteWithParent(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Uncomplete the task
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks[index].reopen()
                    self.scheduleSave(for: self.tasks[index])
                }

                // Uncomplete the parent if it's completed
                if let parent = self.parentTask(for: task),
                   parent.status == .completed {
                    self.uncompleteWithParent(parent)
                }

                self.updateDerivedData()
            }
        }
    }

    /// Checks if all subtasks of a task are completed
    ///
    /// - Parameter task: The parent task
    /// - Returns: True if all subtasks are completed, false otherwise
    func areAllSubtasksCompleted(for task: Task) -> Bool {
        let subtasks = self.subtasks(for: task)
        guard !subtasks.isEmpty else { return false }
        return subtasks.allSatisfy { $0.status == .completed }
    }

    /// Returns the completion progress for a task with subtasks
    ///
    /// - Parameter task: The parent task
    /// - Returns: A tuple containing (completed count, total count)
    func subtaskProgress(for task: Task) -> (completed: Int, total: Int) {
        let subtasks = self.subtasks(for: task)
        let completed = subtasks.filter { $0.status == .completed }.count
        return (completed, subtasks.count)
    }

    /// Creates a subtask under a parent task
    ///
    /// - Parameters:
    ///   - title: The title for the new subtask
    ///   - parent: The parent task
    /// - Returns: The newly created subtask
    func createSubtask(title: String, under parent: Task) -> Task {
        var subtask = Task(
            title: title,
            status: parent.status == .completed ? .inbox : parent.status,
            project: parent.project,
            context: parent.context,
            parentId: parent.id
        )

        // Update parent to include this subtask
        if let index = tasks.firstIndex(where: { $0.id == parent.id }) {
            tasks[index].addSubtask(subtask.id)
            scheduleSave(for: tasks[index])
        }

        // Add the subtask to the store
        add(subtask)

        return subtask
    }

    /// Converts a task to a subtask of another task
    ///
    /// - Parameters:
    ///   - task: The task to convert to a subtask
    ///   - parent: The new parent task
    func convertToSubtask(_ task: Task, of parent: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Update the task to have a parent
                if let taskIndex = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks[taskIndex].setParent(parent.id)
                    self.scheduleSave(for: self.tasks[taskIndex])
                }

                // Update the parent to include this task as a subtask
                if let parentIndex = self.tasks.firstIndex(where: { $0.id == parent.id }) {
                    self.tasks[parentIndex].addSubtask(task.id)
                    self.scheduleSave(for: self.tasks[parentIndex])
                }

                self.updateDerivedData()
            }
        }
    }

    /// Promotes a subtask to a top-level task
    ///
    /// - Parameter task: The subtask to promote
    func promoteToTopLevel(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                guard let parentId = task.parentId else { return }

                // Remove from parent's subtask list
                if let parentIndex = self.tasks.firstIndex(where: { $0.id == parentId }) {
                    self.tasks[parentIndex].removeSubtask(task.id)
                    self.scheduleSave(for: self.tasks[parentIndex])
                }

                // Clear the task's parent
                if let taskIndex = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks[taskIndex].setParent(nil)
                    self.scheduleSave(for: self.tasks[taskIndex])
                }

                self.updateDerivedData()
            }
        }
    }

    // MARK: - Statistics

    /// Returns the total number of tasks
    var taskCount: Int {
        return tasks.count
    }

    /// Returns the number of active tasks (not completed)
    var activeTaskCount: Int {
        return tasks.filter { $0.status != .completed }.count
    }

    /// Returns the number of completed tasks
    var completedTaskCount: Int {
        return tasks.filter { $0.status == .completed }.count
    }

    /// Returns the number of tasks in the inbox
    var inboxTaskCount: Int {
        return tasks.filter { $0.status == .inbox }.count
    }

    /// Returns the number of actionable tasks
    var actionableTaskCount: Int {
        return tasks.filter { $0.isActionable }.count
    }

    // MARK: - Private Helpers

    /// Updates derived data like unique projects and contexts
    private func updateDerivedData() {
        // Extract unique projects
        let uniqueProjects = Set(tasks.compactMap { $0.project })
        projects = uniqueProjects.sorted()

        // Extract unique contexts
        let uniqueContexts = Set(tasks.compactMap { $0.context })
        contexts = uniqueContexts.sorted()
    }

    /// Schedules a debounced save for a task
    private func scheduleSave(for task: Task) {
        // Cancel any existing timer for this task
        cancelSave(for: task.id)

        // Mark task as having a pending save
        pendingSaves.insert(task.id)

        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.queue.async {
                do {
                    try self.fileIO.writeTask(task)
                    self.logger?("Debounced save completed for task: \(task.title)")
                } catch {
                    self.logger?("Failed to save task: \(error)")
                }

                DispatchQueue.main.async {
                    self.pendingSaves.remove(task.id)
                    self.saveTimers.removeValue(forKey: task.id)
                }
            }
        }

        saveTimers[task.id] = timer
    }

    /// Cancels a pending save for a task
    private func cancelSave(for taskID: UUID) {
        saveTimers[taskID]?.invalidate()
        saveTimers.removeValue(forKey: taskID)
        pendingSaves.remove(taskID)
    }

    // MARK: - Cleanup

    /// Cancels all pending saves
    ///
    /// Call this before deinitialization to clean up timers
    func cancelAllPendingSaves() {
        for (_, timer) in saveTimers {
            timer.invalidate()
        }
        saveTimers.removeAll()
        pendingSaves.removeAll()
    }

    deinit {
        cancelAllPendingSaves()
    }
}

// MARK: - Task Lookup

extension TaskStore {
    /// Finds a task by its ID
    ///
    /// - Parameter id: The task ID to find
    /// - Returns: The task if found, nil otherwise
    func task(withID id: UUID) -> Task? {
        return tasks.first { $0.id == id }
    }

    /// Finds tasks by title (case-insensitive, partial match)
    ///
    /// - Parameter title: The title to search for
    /// - Returns: Array of tasks with matching titles
    func tasks(withTitle title: String) -> [Task] {
        let lowercaseTitle = title.lowercased()
        return tasks.filter { $0.title.lowercased().contains(lowercaseTitle) }
    }
}

// MARK: - Sorting

extension TaskStore {
    /// Sorting options for tasks
    enum SortOrder {
        case title
        case created
        case modified
        case due
        case priority
        case status

        /// Returns a comparator function for this sort order
        var comparator: (Task, Task) -> Bool {
            switch self {
            case .title:
                return { $0.title < $1.title }
            case .created:
                return { $0.created < $1.created }
            case .modified:
                return { $0.modified > $1.modified }
            case .due:
                return { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }
            case .priority:
                return { $0.priority.sortOrder > $1.priority.sortOrder }
            case .status:
                return { $0.status.rawValue < $1.status.rawValue }
            }
        }
    }

    /// Returns sorted tasks
    ///
    /// - Parameter order: The sort order to use
    /// - Returns: Array of tasks sorted by the specified order
    func sortedTasks(by order: SortOrder) -> [Task] {
        return tasks.sorted(by: order.comparator)
    }
}

// MARK: - Recurring Tasks

extension TaskStore {
    /// Returns all recurring template tasks (tasks with recurrence patterns)
    var recurringTasks: [Task] {
        return tasks.filter { $0.isRecurring }
    }

    /// Returns all recurring task instances (tasks created from templates)
    var recurringInstances: [Task] {
        return tasks.filter { $0.isRecurringInstance }
    }

    /// Returns instances of a specific recurring task
    /// - Parameter templateId: The ID of the recurring template task
    /// - Returns: Array of task instances created from this template
    func instances(of templateId: UUID) -> [Task] {
        return tasks.filter { $0.originalTaskId == templateId }
    }

    /// Checks all recurring tasks and creates any due occurrences
    ///
    /// This should be called:
    /// - On app launch
    /// - Daily (via background timer)
    /// - When a recurring task is completed
    ///
    /// - Returns: Number of new occurrences created
    @discardableResult
    func checkRecurringTasks() -> Int {
        var createdCount = 0

        for template in recurringTasks {
            // Get existing instances
            let existingInstances = instances(of: template.id)

            // Create any due occurrences
            let newInstances = RecurrenceEngine.createDueOccurrences(
                from: template,
                existingInstances: existingInstances
            )

            // Add new instances to store
            for instance in newInstances {
                add(instance)
                createdCount += 1
            }

            // Update template's occurrence count if needed
            if !newInstances.isEmpty,
               var recurrence = template.recurrence {
                recurrence.occurrenceCount += newInstances.count

                var updatedTemplate = template
                updatedTemplate.recurrence = recurrence
                update(updatedTemplate)
            }
        }

        if createdCount > 0 {
            logger?("Created \(createdCount) new recurring task occurrences")
        }

        return createdCount
    }

    /// Completes a recurring task instance and creates the next occurrence
    /// - Parameter instance: The instance being completed
    func completeRecurringInstance(_ instance: Task) {
        guard instance.isRecurringInstance,
              let templateId = instance.originalTaskId,
              let template = task(withID: templateId) else {
            return
        }

        // Mark instance as completed
        var completedInstance = instance
        completedInstance.complete()
        update(completedInstance)

        // Create next occurrence
        if let nextInstance = RecurrenceEngine.completeInstanceAndCreateNext(
            instance: instance,
            template: template
        ) {
            add(nextInstance)
            logger?("Created next occurrence of recurring task: \(template.title)")

            // Update template's occurrence count
            if var recurrence = template.recurrence {
                recurrence.occurrenceCount += 1
                var updatedTemplate = template
                updatedTemplate.recurrence = recurrence
                update(updatedTemplate)
            }
        }
    }

    /// Updates the recurrence pattern on a task
    /// - Parameters:
    ///   - task: The task to update
    ///   - recurrence: The new recurrence pattern (nil to remove recurrence)
    func updateRecurrence(for task: Task, recurrence: Recurrence?) {
        let updatedTask = RecurrenceEngine.updateRecurrence(task: task, recurrence: recurrence)
        update(updatedTask)

        // If recurrence was added or changed, check for due occurrences
        if recurrence != nil {
            checkRecurringTasks()
        }
    }

    /// Deletes a recurring task and all its instances
    /// - Parameter template: The recurring template task to delete
    func deleteRecurringTaskAndInstances(_ template: Task) {
        guard template.isRecurring else {
            delete(template)
            return
        }

        // Find and delete all instances
        let instances = instances(of: template.id)
        deleteBatch(instances)

        // Delete the template
        delete(template)

        logger?("Deleted recurring task '\(template.title)' and \(instances.count) instances")
    }

    /// Deletes only future instances of a recurring task
    /// - Parameter template: The recurring template task
    func deleteFutureInstances(of template: Task) {
        guard template.isRecurring else { return }

        let instances = instances(of: template.id)
        let futureInstances = instances.filter { instance in
            guard let occurrenceDate = instance.occurrenceDate else { return false }
            return occurrenceDate > Date() && instance.status != .completed
        }

        deleteBatch(futureInstances)
        logger?("Deleted \(futureInstances.count) future instances of '\(template.title)'")
    }

    /// Stops a recurring task (removes recurrence pattern but keeps existing instances)
    /// - Parameter template: The recurring template task
    func stopRecurrence(for template: Task) {
        var updatedTask = template
        updatedTask.recurrence = nil
        update(updatedTask)
        logger?("Stopped recurrence for task: \(template.title)")
    }
}

// MARK: - Automation Rules Integration

extension TaskStore {
    /// Evaluates automation rules for a task change
    /// - Parameters:
    ///   - context: The change context
    ///   - task: The task to evaluate
    /// - Returns: The modified task after applying rules
    func evaluateAutomationRules(for context: TaskChangeContext, task: Task) -> Task {
        return rulesEngine.evaluateRules(for: context, task: task)
    }

    /// Updates a task and evaluates automation rules for the change
    /// - Parameters:
    ///   - task: The task to update
    ///   - context: The change context describing what changed
    func updateWithRules(_ task: Task, context: TaskChangeContext) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    // Apply automation rules
                    var modifiedTask = self.rulesEngine.evaluateRules(for: context, task: task)
                    modifiedTask.modified = Date()

                    self.tasks[index] = modifiedTask
                    self.updateDerivedData()
                    self.logger?("Updated task with rules: \(task.title)")

                    // Schedule debounced save
                    self.scheduleSave(for: modifiedTask)
                }
            }
        }
    }

    /// Checks all tasks for approaching due dates and triggers rules
    func checkDueDateAutomation() {
        let activeTasks = tasks.filter { $0.status != .completed }
        let modifiedTasks = rulesEngine.checkDueDateRules(for: activeTasks)

        // Update any tasks that were modified by rules
        for modifiedTask in modifiedTasks {
            if let index = tasks.firstIndex(where: { $0.id == modifiedTask.id }) {
                if tasks[index] != modifiedTask {
                    tasks[index] = modifiedTask
                    scheduleSave(for: modifiedTask)
                }
            }
        }
    }

    /// Returns statistics about rule usage
    func getRuleStatistics() -> RuleStatistics {
        return rulesEngine.getRuleStatistics()
    }
}

// MARK: - Activity Logging

extension TaskStore {
    /// Logs changes between two task versions
    /// - Parameters:
    ///   - oldTask: The previous task state
    ///   - newTask: The new task state
    private func logTaskChanges(from oldTask: Task, to newTask: Task) {
        guard let logManager = activityLogManager else { return }

        var logs: [ActivityLog] = []

        // Title changed
        if oldTask.title != newTask.title {
            logs.append(.titleChanged(task: newTask, from: oldTask.title, to: newTask.title))
        }

        // Status changed
        if oldTask.status != newTask.status {
            logs.append(.statusChanged(task: newTask, from: oldTask.status, to: newTask.status))

            // Special cases for completion
            if newTask.status == .completed && oldTask.status != .completed {
                logs.append(.completed(task: newTask))
            } else if oldTask.status == .completed && newTask.status != .completed {
                logs.append(.uncompleted(task: newTask))
            }
        }

        // Priority changed
        if oldTask.priority != newTask.priority {
            logs.append(.priorityChanged(task: newTask, from: oldTask.priority, to: newTask.priority))
        }

        // Project changed
        if oldTask.project != newTask.project {
            logs.append(.projectSet(task: newTask, from: oldTask.project, to: newTask.project))
        }

        // Context changed
        if oldTask.context != newTask.context {
            logs.append(.contextSet(task: newTask, from: oldTask.context, to: newTask.context))
        }

        // Due date changed
        if oldTask.due != newTask.due {
            logs.append(.dueDateChanged(task: newTask, from: oldTask.due, to: newTask.due))
        }

        // Defer date changed
        if oldTask.defer != newTask.defer {
            logs.append(.deferDateChanged(task: newTask, from: oldTask.defer, to: newTask.defer))
        }

        // Flagged changed
        if oldTask.flagged != newTask.flagged {
            if newTask.flagged {
                logs.append(.flagged(task: newTask))
            } else {
                logs.append(.unflagged(task: newTask))
            }
        }

        // Effort changed
        if oldTask.effort != newTask.effort {
            logs.append(.effortChanged(task: newTask, from: oldTask.effort, to: newTask.effort))
        }

        // Type changed
        if oldTask.type != newTask.type {
            logs.append(.typeChanged(task: newTask, from: oldTask.type, to: newTask.type))
        }

        // Notes changed
        if oldTask.notes != newTask.notes {
            logs.append(.notesChanged(task: newTask))
        }

        // Timer started
        if !oldTask.isTimerRunning && newTask.isTimerRunning {
            logs.append(.timerStarted(task: newTask))
        }

        // Timer stopped
        if oldTask.isTimerRunning && !newTask.isTimerRunning {
            if let start = oldTask.currentTimerStart {
                let duration = Date().timeIntervalSince(start)
                logs.append(.timerStopped(task: newTask, duration: duration))
            }
        }

        // Tags added
        let oldTagIds = Set(oldTask.tags.map { $0.id })
        let newTagIds = Set(newTask.tags.map { $0.id })
        let addedTagIds = newTagIds.subtracting(oldTagIds)
        for tagId in addedTagIds {
            if let tag = newTask.tags.first(where: { $0.id == tagId }) {
                logs.append(.tagAdded(task: newTask, tag: tag))
            }
        }

        // Tags removed
        let removedTagIds = oldTagIds.subtracting(newTagIds)
        for tagId in removedTagIds {
            if let tag = oldTask.tags.first(where: { $0.id == tagId }) {
                logs.append(.tagRemoved(task: newTask, tag: tag))
            }
        }

        // Attachments added
        let oldAttachmentIds = Set(oldTask.attachments.map { $0.id })
        let newAttachmentIds = Set(newTask.attachments.map { $0.id })
        let addedAttachmentIds = newAttachmentIds.subtracting(oldAttachmentIds)
        for attachmentId in addedAttachmentIds {
            if let attachment = newTask.attachments.first(where: { $0.id == attachmentId }) {
                logs.append(.attachmentAdded(task: newTask, attachment: attachment))
            }
        }

        // Attachments removed
        let removedAttachmentIds = oldAttachmentIds.subtracting(newAttachmentIds)
        for attachmentId in removedAttachmentIds {
            if let attachment = oldTask.attachments.first(where: { $0.id == attachmentId }) {
                logs.append(.attachmentRemoved(task: newTask, attachment: attachment))
            }
        }

        // Add all logs at once
        if !logs.isEmpty {
            logManager.addLogs(logs)
        }
    }
}

// MARK: - Notification Management

extension TaskStore {
    /// Schedules notifications for a task based on its due and defer dates
    /// - Parameter task: The task to schedule notifications for
    private func scheduleNotifications(for task: inout Task) async {
        // Cancel any existing notifications first
        notificationManager.cancelNotifications(for: task)

        var notificationIds: [String] = []

        // Schedule due date notifications
        if task.due != nil {
            let dueIds = await notificationManager.scheduleDueNotifications(for: task)
            notificationIds.append(contentsOf: dueIds)
        }

        // Schedule defer date notification
        if let deferId = await notificationManager.scheduleDeferNotification(for: task) {
            notificationIds.append(deferId)
        }

        // Schedule recurring task notification if applicable
        if task.isRecurringInstance {
            let recurringIds = await notificationManager.scheduleRecurringTaskNotification(for: task)
            notificationIds.append(contentsOf: recurringIds)
        }

        // Update task with notification IDs
        task.notificationIds = notificationIds

        logger?("Scheduled \(notificationIds.count) notifications for task: \(task.title)")
    }

    /// Starts a timer for a task and schedules completion notification
    /// - Parameters:
    ///   - task: The task to start the timer for
    ///   - duration: Timer duration in seconds
    func startTimer(for task: Task, duration: TimeInterval) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    var updatedTask = self.tasks[index]
                    updatedTask.isTimerRunning = true
                    updatedTask.currentTimerStart = Date()
                    updatedTask.modified = Date()

                    // Schedule timer notification
                    Task {
                        if let timerId = await self.notificationManager.scheduleTimerNotification(for: updatedTask, duration: duration) {
                            updatedTask.notificationIds.append(timerId)
                        }
                    }

                    self.tasks[index] = updatedTask
                    self.scheduleSave(for: updatedTask)
                    self.logger?("Started timer for task: \(task.title)")
                }
            }
        }
    }

    /// Stops the timer for a task
    /// - Parameter task: The task to stop the timer for
    func stopTimer(for task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }),
                   let startTime = self.tasks[index].currentTimerStart {

                    var updatedTask = self.tasks[index]

                    // Calculate elapsed time
                    let elapsed = Date().timeIntervalSince(startTime)
                    updatedTask.totalTimeSpent += elapsed
                    updatedTask.isTimerRunning = false
                    updatedTask.currentTimerStart = nil
                    updatedTask.modified = Date()

                    // Cancel timer notification
                    self.notificationManager.cancelNotifications(for: updatedTask)
                    updatedTask.notificationIds.removeAll()

                    self.tasks[index] = updatedTask
                    self.scheduleSave(for: updatedTask)
                    self.logger?("Stopped timer for task: \(task.title) (elapsed: \(elapsed)s)")
                }
            }
        }
    }

    /// Updates the badge count based on overdue tasks
    func updateBadgeCount() {
        let overdueCount = overdueTasks().count
        notificationManager.updateBadgeCount(overdueCount)
    }

    /// Completes a task and cancels its notifications
    /// - Parameter task: The task to complete
    func completeTask(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    var completedTask = self.tasks[index]
                    completedTask.status = .completed
                    completedTask.modified = Date()

                    // Cancel all notifications for this task
                    self.notificationManager.cancelNotifications(for: completedTask)
                    completedTask.notificationIds.removeAll()

                    // Log activity if manager is available
                    if let logManager = self.activityLogManager {
                        logManager.addLog(.completed(task: completedTask))
                    }

                    self.tasks[index] = completedTask
                    self.updateDerivedData()
                    self.scheduleSave(for: completedTask)
                    self.updateBadgeCount()

                    self.logger?("Completed task: \(task.title)")
                }
            }
        }
    }
}

// MARK: - Intent Donation for Siri Suggestions

#if canImport(AppIntents)
import AppIntents
#endif

@available(iOS 16.0, macOS 13.0, *)
extension TaskStore {
    /// Donates an add task intent when a user creates a task
    /// - Parameter task: The task that was created
    func donateAddTaskIntent(for task: Task) {
        #if canImport(AppIntents)
        let intent = AddTaskIntent()
        intent.title = task.title
        intent.notes = task.notes.isEmpty ? nil : task.notes
        intent.project = task.project
        intent.context = task.context
        intent.priority = PriorityOption(rawValue: task.priority.rawValue) ?? .medium
        intent.dueDate = task.due
        intent.flagged = task.flagged

        // Donation happens automatically when intent is created
        logger?("Donated AddTask intent for: \(task.title)")
        #endif
    }

    /// Donates a complete task intent when a user completes a task
    /// - Parameter task: The task that was completed
    func donateCompleteTaskIntent(for task: Task) {
        #if canImport(AppIntents)
        let intent = CompleteTaskIntent()
        intent.task = TaskEntity.from(task: task)
        intent.taskTitle = task.title

        logger?("Donated CompleteTask intent for: \(task.title)")
        #endif
    }

    /// Donates a flag task intent when a user flags/unflags a task
    /// - Parameter task: The task that was flagged
    func donateFlagTaskIntent(for task: Task) {
        #if canImport(AppIntents)
        let intent = FlagTaskIntent()
        intent.task = TaskEntity.from(task: task)
        intent.taskTitle = task.title
        intent.flagged = task.flagged

        logger?("Donated FlagTask intent for: \(task.title)")
        #endif
    }

    /// Donates a start timer intent when a user starts a timer
    /// - Parameter task: The task with running timer
    func donateStartTimerIntent(for task: Task) {
        #if canImport(AppIntents)
        let intent = StartTimerIntent()
        intent.task = TaskEntity.from(task: task)
        intent.taskTitle = task.title

        logger?("Donated StartTimer intent for: \(task.title)")
        #endif
    }

    /// Donates a stop timer intent when a user stops a timer
    func donateStopTimerIntent() {
        #if canImport(AppIntents)
        let intent = StopTimerIntent()

        logger?("Donated StopTimer intent")
        #endif
    }

    /// Donates add to project intent when task is added to a project
    /// - Parameter task: The task added to a project
    func donateAddToProjectIntent(for task: Task) {
        #if canImport(AppIntents)
        guard let project = task.project else { return }

        let intent = AddTaskToProjectIntent()
        intent.title = task.title
        intent.project = project
        intent.notes = task.notes.isEmpty ? nil : task.notes
        intent.context = task.context

        logger?("Donated AddToProject intent for: \(task.title) in \(project)")
        #endif
    }

    /// Donates show inbox intent when user views inbox
    func donateShowInboxIntent() {
        #if canImport(AppIntents)
        let intent = ShowInboxIntent()

        logger?("Donated ShowInbox intent")
        #endif
    }

    /// Donates show next actions intent when user views next actions
    /// - Parameter context: Optional context filter
    func donateShowNextActionsIntent(context: String? = nil) {
        #if canImport(AppIntents)
        let intent = ShowNextActionsIntent()
        intent.contextFilter = context

        logger?("Donated ShowNextActions intent")
        #endif
    }

    /// Donates show today intent when user views today's tasks
    func donateShowTodayIntent() {
        #if canImport(AppIntents)
        let intent = ShowTodayTasksIntent()

        logger?("Donated ShowToday intent")
        #endif
    }

    /// Donates show flagged intent when user views flagged tasks
    /// - Parameter project: Optional project filter
    func donateShowFlaggedIntent(project: String? = nil) {
        #if canImport(AppIntents)
        let intent = ShowFlaggedTasksIntent()
        intent.projectFilter = project

        logger?("Donated ShowFlagged intent")
        #endif
    }

    /// Donates weekly review intent when user opens weekly review
    func donateWeeklyReviewIntent() {
        #if canImport(AppIntents)
        let intent = ShowWeeklyReviewIntent()

        logger?("Donated WeeklyReview intent")
        #endif
    }
}

// MARK: - Calendar Integration

@available(macOS 10.15, *)
extension TaskStore {
    /// Syncs all tasks with calendar
    func syncAllTasksWithCalendar() {
        let taskIds = tasks.map { $0.id }
        var syncedCount = 0
        
        for taskId in taskIds {
            if let task = task(withID: taskId) {
                let syncResult = calendarManager.syncTask(task)
                if case .success(let eventId) = syncResult, let eventId = eventId {
                    if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                        tasks[index].calendarEventId = eventId
                        scheduleSave(for: tasks[index])
                        syncedCount += 1
                    }
                }
            }
        }
        
        logger?("Synced \(syncedCount) tasks with calendar")
    }
    
    /// Triggers automation rules based on task changes
    private func triggerRulesForChanges(from oldTask: Task, to updatedTask: inout Task) {
        // Status changed
        if oldTask.status != updatedTask.status {
            let context = TaskChangeContext.statusChanged(from: oldTask.status, to: updatedTask.status, task: updatedTask)
            updatedTask = rulesEngine.evaluateRules(for: context, task: updatedTask)

            // Check if completed
            if updatedTask.status == .completed && oldTask.status != .completed {
                let completedContext = TaskChangeContext.taskCompleted(updatedTask)
                updatedTask = rulesEngine.evaluateRules(for: completedContext, task: updatedTask)
            }
        }

        // Priority changed
        if oldTask.priority != updatedTask.priority {
            let context = TaskChangeContext.priorityChanged(from: oldTask.priority, to: updatedTask.priority, task: updatedTask)
            updatedTask = rulesEngine.evaluateRules(for: context, task: updatedTask)
        }

        // Flagged state changed
        if oldTask.flagged != updatedTask.flagged {
            if updatedTask.flagged {
                let context = TaskChangeContext.taskFlagged(updatedTask)
                updatedTask = rulesEngine.evaluateRules(for: context, task: updatedTask)
            } else {
                let context = TaskChangeContext.taskUnflagged(updatedTask)
                updatedTask = rulesEngine.evaluateRules(for: context, task: updatedTask)
            }
        }

        // Project changed
        if oldTask.project != updatedTask.project, let project = updatedTask.project {
            let context = TaskChangeContext.projectSet(project, to: updatedTask)
            updatedTask = rulesEngine.evaluateRules(for: context, task: updatedTask)
        }

        // Context changed
        if oldTask.context != updatedTask.context, let context = updatedTask.context {
            let changeContext = TaskChangeContext.contextSet(context, to: updatedTask)
            updatedTask = rulesEngine.evaluateRules(for: changeContext, task: updatedTask)
        }

        // Tags added
        let oldTagNames = Set(oldTask.tags.map { $0.name })
        let newTagNames = Set(updatedTask.tags.map { $0.name })
        let addedTags = newTagNames.subtracting(oldTagNames)
        for tagName in addedTags {
            let context = TaskChangeContext.tagAdded(tagName, to: updatedTask)
            updatedTask = rulesEngine.evaluateRules(for: context, task: updatedTask)
        }
    }
}
