//
//  RecurringTasksExample.swift
//  StickyToDo
//
//  Example code demonstrating recurring tasks usage.
//

import Foundation

// MARK: - Example: Setting Up Recurring Tasks

func exampleSetupRecurringTasks() {
    // Create task store
    let fileIO = MarkdownFileIO(basePath: "~/Documents/StickyToDo")
    let taskStore = TaskStore(fileIO: fileIO)

    // Load existing tasks and check for due recurring instances
    try? taskStore.loadAll()

    // Set up daily check (optional - can also be done via NotificationCenter)
    Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
        taskStore.checkRecurringTasks()
        print("Daily recurring tasks check completed")
    }
}

// MARK: - Example: Creating Common Recurring Tasks

func exampleCreateRecurringTasks(taskStore: TaskStore) {
    // 1. Daily standup (every weekday)
    let standup = Task(
        title: "Daily standup",
        notes: "Review progress and blockers with the team",
        project: "Work",
        context: "@office",
        due: Date(),
        recurrence: .weekdays  // Monday-Friday
    )
    taskStore.add(standup)

    // 2. Weekly review (every Friday)
    let weeklyReview = Task(
        title: "Weekly review",
        notes: "Review accomplishments and plan next week",
        project: "Personal",
        due: Date(),
        recurrence: Recurrence(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [6]  // Friday (0=Sunday, 6=Saturday)
        )
    )
    taskStore.add(weeklyReview)

    // 3. Monthly budget review (first of each month)
    let budgetReview = Task(
        title: "Review monthly budget",
        project: "Finance",
        due: Date(),
        recurrence: Recurrence(
            frequency: .monthly,
            interval: 1,
            dayOfMonth: 1
        )
    )
    taskStore.add(budgetReview)

    // 4. Rent payment (last day of each month)
    let rentPayment = Task(
        title: "Pay rent",
        project: "Finance",
        due: Date(),
        recurrence: Recurrence(
            frequency: .monthly,
            interval: 1,
            useLastDayOfMonth: true
        )
    )
    taskStore.add(rentPayment)

    // 5. Bi-weekly team retrospective
    let retrospective = Task(
        title: "Team retrospective",
        notes: "What went well, what to improve",
        project: "Work",
        due: Date(),
        recurrence: .biweekly
    )
    taskStore.add(retrospective)

    // 6. Quarterly planning (every 3 months)
    let quarterlyPlanning = Task(
        title: "Quarterly planning session",
        project: "Work",
        due: Date(),
        recurrence: Recurrence(
            frequency: .monthly,
            interval: 3
        )
    )
    taskStore.add(quarterlyPlanning)

    // 7. Annual tax filing
    let calendar = Calendar.current
    let taxDate = calendar.date(from: DateComponents(year: 2025, month: 4, day: 15))!
    let taxFiling = Task(
        title: "File annual taxes",
        project: "Finance",
        due: taxDate,
        recurrence: .yearly
    )
    taskStore.add(taxFiling)

    // 8. 30-day fitness challenge (limited recurrence)
    let fitnessChallenge = Task(
        title: "Daily exercise",
        notes: "30-minute workout",
        project: "Health",
        due: Date(),
        recurrence: Recurrence(
            frequency: .daily,
            interval: 1,
            count: 30  // Only 30 occurrences
        )
    )
    taskStore.add(fitnessChallenge)

    // 9. Weekend house cleaning
    let houseCleaning = Task(
        title: "Clean house",
        context: "@home",
        due: Date(),
        recurrence: .weekends  // Saturday and Sunday
    )
    taskStore.add(houseCleaning)

    // 10. Summer project (with end date)
    let summerEndDate = calendar.date(from: DateComponents(year: 2025, month: 9, day: 1))!
    let summerProject = Task(
        title: "Work on summer project",
        notes: "Dedicate time to personal coding project",
        project: "Personal",
        due: Date(),
        recurrence: Recurrence(
            frequency: .daily,
            interval: 1,
            endDate: summerEndDate
        )
    )
    taskStore.add(summerProject)

    // Check for any due occurrences
    taskStore.checkRecurringTasks()
}

// MARK: - Example: Handling Task Completion

func exampleCompleteTask(task: Task, taskStore: TaskStore) {
    if task.isRecurringInstance {
        // Special handling for recurring instances
        // This will:
        // 1. Mark the instance as completed
        // 2. Create the next occurrence
        // 3. Update the template's occurrence count
        taskStore.completeRecurringInstance(task)
        print("Completed recurring instance: \(task.title)")
        print("Next occurrence has been created automatically")
    } else if task.isRecurring {
        // This is a template - don't complete it!
        print("Warning: This is a recurring template. Did you mean to complete an instance?")
    } else {
        // Normal task completion
        var completedTask = task
        completedTask.complete()
        taskStore.update(completedTask)
        print("Completed task: \(task.title)")
    }
}

// MARK: - Example: Modifying Recurring Tasks

func exampleModifyRecurrence(task: Task, taskStore: TaskStore) {
    guard task.isRecurring else {
        print("This is not a recurring task")
        return
    }

    // Change from daily to every other day
    let newRecurrence = Recurrence(
        frequency: .daily,
        interval: 2  // Every 2 days instead of 1
    )

    taskStore.updateRecurrence(for: task, recurrence: newRecurrence)
    print("Updated recurrence pattern")

    // This will also check for any new due occurrences
}

func exampleStopRecurrence(task: Task, taskStore: TaskStore) {
    guard task.isRecurring else {
        print("This is not a recurring task")
        return
    }

    // Remove recurrence but keep existing instances
    taskStore.stopRecurrence(for: task)
    print("Stopped recurrence. Existing instances remain.")
}

func exampleDeleteRecurringTask(task: Task, taskStore: TaskStore) {
    guard task.isRecurring else {
        print("This is not a recurring task")
        return
    }

    // Delete template and all instances
    taskStore.deleteRecurringTaskAndInstances(task)
    print("Deleted recurring task and all its instances")

    // Or delete only future instances
    // taskStore.deleteFutureInstances(of: task)
}

// MARK: - Example: Querying Recurring Tasks

func exampleQueryRecurringTasks(taskStore: TaskStore) {
    // Get all recurring templates
    let templates = taskStore.recurringTasks
    print("Recurring templates: \(templates.count)")

    for template in templates {
        if let recurrence = template.recurrence {
            print("- \(template.title): \(recurrence.shortDescription)")
            if let nextDate = template.nextOccurrence {
                print("  Next: \(nextDate)")
            }
        }
    }

    // Get all recurring instances
    let instances = taskStore.recurringInstances
    print("\nRecurring instances: \(instances.count)")

    // Get instances for a specific template
    if let firstTemplate = templates.first {
        let templateInstances = taskStore.instances(of: firstTemplate.id)
        print("\nInstances of '\(firstTemplate.title)': \(templateInstances.count)")

        for instance in templateInstances {
            let status = instance.status == .completed ? "✓" : "○"
            let dateStr = instance.occurrenceDate.map { "\($0)" } ?? "unknown"
            print("  \(status) \(dateStr)")
        }
    }
}

// MARK: - Example: Custom Recurrence Patterns

func exampleCustomPatterns() -> [Recurrence] {
    var patterns: [Recurrence] = []

    // Every Monday and Wednesday
    patterns.append(Recurrence(
        frequency: .weekly,
        interval: 1,
        daysOfWeek: [2, 4]  // Tuesday (2), Thursday (4)
    ))

    // First Monday of each month (approximation - use day 1-7)
    patterns.append(Recurrence(
        frequency: .monthly,
        interval: 1,
        dayOfMonth: 1
    ))

    // Every 6 weeks
    patterns.append(Recurrence(
        frequency: .weekly,
        interval: 6
    ))

    // Quarterly (every 3 months) on the 15th
    patterns.append(Recurrence(
        frequency: .monthly,
        interval: 3,
        dayOfMonth: 15
    ))

    // 100-day challenge
    patterns.append(Recurrence(
        frequency: .daily,
        interval: 1,
        count: 100
    ))

    return patterns
}

// MARK: - Example: UI Integration (SwiftUI)

#if canImport(SwiftUI)
import SwiftUI

struct RecurringTaskExampleView: View {
    @State private var task: Task?
    @ObservedObject var taskStore: TaskStore

    var body: some View {
        VStack {
            if let task = task {
                // Show recurrence picker
                RecurrencePicker(
                    recurrence: Binding(
                        get: { task.recurrence },
                        set: { newRecurrence in
                            var updatedTask = task
                            updatedTask.recurrence = newRecurrence
                            taskStore.update(updatedTask)
                            self.task = updatedTask
                        }
                    ),
                    onChange: {
                        print("Recurrence changed")
                    }
                )

                // Show next occurrence
                if let nextDate = task.nextOccurrence {
                    Text("Next occurrence: \(nextDate, style: .date)")
                        .foregroundColor(.secondary)
                }

                // Show instance info
                if task.isRecurringInstance {
                    VStack(alignment: .leading) {
                        Text("Recurring Instance")
                            .font(.caption)
                        if let occurrenceDate = task.occurrenceDate {
                            Text("Occurrence: \(occurrenceDate, style: .date)")
                                .font(.caption2)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}
#endif

// MARK: - Example: Complete Workflow

func exampleCompleteWorkflow() {
    print("=== Recurring Tasks Complete Workflow Example ===\n")

    // 1. Initialize
    let fileIO = MarkdownFileIO(basePath: "~/Documents/StickyToDo")
    let taskStore = TaskStore(fileIO: fileIO)

    // 2. Create a recurring task
    print("Creating daily task...")
    let dailyTask = Task(
        title: "Morning meditation",
        notes: "10 minutes of mindfulness",
        due: Date(),
        recurrence: .daily
    )
    taskStore.add(dailyTask)

    // 3. Check for due occurrences (creates first instance)
    print("Checking for due occurrences...")
    let created = taskStore.checkRecurringTasks()
    print("Created \(created) instances\n")

    // 4. Query instances
    print("Querying instances...")
    let instances = taskStore.instances(of: dailyTask.id)
    print("Found \(instances.count) instances\n")

    // 5. Complete an instance
    if let firstInstance = instances.first {
        print("Completing instance...")
        taskStore.completeRecurringInstance(firstInstance)
        print("Instance completed, next one created\n")
    }

    // 6. Modify recurrence
    print("Changing to every 2 days...")
    let newRecurrence = Recurrence(frequency: .daily, interval: 2)
    taskStore.updateRecurrence(for: dailyTask, recurrence: newRecurrence)
    print("Recurrence updated\n")

    // 7. View status
    print("Final status:")
    print("- Template: \(dailyTask.title)")
    print("- Pattern: \(newRecurrence.description)")
    print("- Instances: \(taskStore.instances(of: dailyTask.id).count)")
    print("- Next: \(dailyTask.nextOccurrence?.description ?? "N/A")")
}
