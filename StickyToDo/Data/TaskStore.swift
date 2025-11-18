//
//  TaskStore.swift
//  StickyToDo
//
//  In-memory store for all tasks with SwiftUI/AppKit integration.
//  Provides thread-safe access, debounced auto-save, and reactive updates.
//

import Foundation
import Combine

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

    // MARK: - Initialization

    /// Creates a new TaskStore
    ///
    /// - Parameter fileIO: The file I/O handler for persistence
    init(fileIO: MarkdownFileIO) {
        self.fileIO = fileIO
    }

    /// Configure logging for task store operations
    /// - Parameter logger: A closure that receives log messages
    func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
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
                    self.tasks.append(task)
                    self.updateDerivedData()
                    self.logger?("Added task: \(task.title)")

                    // Schedule debounced save
                    self.scheduleSave(for: task)
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
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    var updatedTask = task
                    updatedTask.modified = Date()
                    self.tasks[index] = updatedTask
                    self.updateDerivedData()
                    self.logger?("Updated task: \(task.title)")

                    // Schedule debounced save
                    self.scheduleSave(for: updatedTask)
                }
            }
        }
    }

    /// Deletes a task from the store
    ///
    /// - Parameter task: The task to delete
    func delete(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks.remove(at: index)
                    self.updateDerivedData()
                    self.logger?("Deleted task: \(task.title)")

                    // Cancel any pending save
                    self.cancelSave(for: task.id)

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
