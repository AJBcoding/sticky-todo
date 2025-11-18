//
//  StickyToDoAppShortcuts.swift
//  StickyToDo
//
//  App Shortcuts provider for Siri integration.
//  Defines all app shortcuts that appear in Settings > Siri & Search.
//

import Foundation
import AppIntents

/// Provides app shortcuts for StickyToDo
@available(iOS 16.0, macOS 13.0, *)
public struct StickyToDoAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Quick Capture
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add a task in \(.applicationName)",
                "Create a task in \(.applicationName)",
                "New task in \(.applicationName)",
                "Quick capture in \(.applicationName)",
                "Add \(\.$title) to \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )

        // Show Inbox
        AppShortcut(
            intent: ShowInboxIntent(),
            phrases: [
                "Show my inbox in \(.applicationName)",
                "Open inbox in \(.applicationName)",
                "What's in my inbox in \(.applicationName)",
                "Show unprocessed tasks in \(.applicationName)"
            ],
            shortTitle: "Show Inbox",
            systemImageName: "tray"
        )

        // Show Next Actions
        AppShortcut(
            intent: ShowNextActionsIntent(),
            phrases: [
                "Show my next actions in \(.applicationName)",
                "What should I do next in \(.applicationName)",
                "Show actionable tasks in \(.applicationName)",
                "Open next actions in \(.applicationName)"
            ],
            shortTitle: "Next Actions",
            systemImageName: "star.circle"
        )

        // Complete Task
        AppShortcut(
            intent: CompleteTaskIntent(),
            phrases: [
                "Complete a task in \(.applicationName)",
                "Mark task as done in \(.applicationName)",
                "Finish task in \(.applicationName)",
                "Complete \(\.$taskTitle) in \(.applicationName)"
            ],
            shortTitle: "Complete Task",
            systemImageName: "checkmark.circle"
        )

        // Show Today's Tasks
        AppShortcut(
            intent: ShowTodayTasksIntent(),
            phrases: [
                "Show today's tasks in \(.applicationName)",
                "What's due today in \(.applicationName)",
                "Show my tasks for today in \(.applicationName)",
                "What do I need to do today in \(.applicationName)"
            ],
            shortTitle: "Today's Tasks",
            systemImageName: "calendar"
        )

        // Start Timer
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Start timer in \(.applicationName)",
                "Track time in \(.applicationName)",
                "Start tracking time in \(.applicationName)",
                "Begin timer for \(\.$taskTitle) in \(.applicationName)"
            ],
            shortTitle: "Start Timer",
            systemImageName: "timer"
        )

        // Stop Timer
        AppShortcut(
            intent: StopTimerIntent(),
            phrases: [
                "Stop timer in \(.applicationName)",
                "Stop tracking time in \(.applicationName)",
                "End timer in \(.applicationName)",
                "Pause timer in \(.applicationName)"
            ],
            shortTitle: "Stop Timer",
            systemImageName: "timer.square"
        )

        // Flag Task
        AppShortcut(
            intent: FlagTaskIntent(),
            phrases: [
                "Flag a task in \(.applicationName)",
                "Mark task as important in \(.applicationName)",
                "Star \(\.$taskTitle) in \(.applicationName)",
                "Flag \(\.$taskTitle) in \(.applicationName)"
            ],
            shortTitle: "Flag Task",
            systemImageName: "flag.fill"
        )

        // Show Flagged Tasks
        AppShortcut(
            intent: ShowFlaggedTasksIntent(),
            phrases: [
                "Show flagged tasks in \(.applicationName)",
                "Show my flagged items in \(.applicationName)",
                "What's important in \(.applicationName)",
                "Show starred tasks in \(.applicationName)"
            ],
            shortTitle: "Flagged Tasks",
            systemImageName: "flag.circle.fill"
        )

        // Weekly Review
        AppShortcut(
            intent: ShowWeeklyReviewIntent(),
            phrases: [
                "Show weekly review in \(.applicationName)",
                "Start my weekly review in \(.applicationName)",
                "Open weekly planning in \(.applicationName)",
                "Show my weekly summary in \(.applicationName)"
            ],
            shortTitle: "Weekly Review",
            systemImageName: "calendar.badge.checkmark"
        )

        // Add Task to Project
        AppShortcut(
            intent: AddTaskToProjectIntent(),
            phrases: [
                "Add task to project in \(.applicationName)",
                "Add \(\.$title) to \(\.$project) in \(.applicationName)",
                "Create task in project in \(.applicationName)"
            ],
            shortTitle: "Add to Project",
            systemImageName: "folder.badge.plus"
        )
    }

    static var shortcutTileColor: ShortcutTileColor {
        .orange
    }
}

/// Extension to provide access to shared instances
extension AppDelegate {
    static var shared: AppDelegate? {
        #if os(macOS)
        return NSApplication.shared.delegate as? AppDelegate
        #else
        return UIApplication.shared.delegate as? AppDelegate
        #endif
    }
}

/// Sample phrases for documentation and testing
@available(iOS 16.0, macOS 13.0, *)
public struct SiriPhraseSamples {
    static let addTask = [
        "Hey Siri, add a task in StickyToDo",
        "Hey Siri, create 'Call the dentist' in StickyToDo",
        "Hey Siri, quick capture in StickyToDo",
        "Hey Siri, new task in StickyToDo"
    ]

    static let showInbox = [
        "Hey Siri, show my inbox in StickyToDo",
        "Hey Siri, what's in my inbox?",
        "Hey Siri, open inbox in StickyToDo"
    ]

    static let showNextActions = [
        "Hey Siri, show my next actions in StickyToDo",
        "Hey Siri, what should I do next?",
        "Hey Siri, show actionable tasks in StickyToDo"
    ]

    static let completeTask = [
        "Hey Siri, complete a task in StickyToDo",
        "Hey Siri, mark 'Write report' as done in StickyToDo",
        "Hey Siri, finish task in StickyToDo"
    ]

    static let showToday = [
        "Hey Siri, show today's tasks in StickyToDo",
        "Hey Siri, what's due today?",
        "Hey Siri, what do I need to do today?"
    ]

    static let startTimer = [
        "Hey Siri, start timer in StickyToDo",
        "Hey Siri, track time for 'Design mockups' in StickyToDo",
        "Hey Siri, start tracking time in StickyToDo"
    ]

    static let stopTimer = [
        "Hey Siri, stop timer in StickyToDo",
        "Hey Siri, stop tracking time in StickyToDo",
        "Hey Siri, end timer in StickyToDo"
    ]

    static let flagTask = [
        "Hey Siri, flag a task in StickyToDo",
        "Hey Siri, mark 'Design mockups' as important in StickyToDo",
        "Hey Siri, star task in StickyToDo"
    ]

    static let showFlagged = [
        "Hey Siri, show flagged tasks in StickyToDo",
        "Hey Siri, what's important?",
        "Hey Siri, show my starred tasks in StickyToDo"
    ]

    static let weeklyReview = [
        "Hey Siri, show weekly review in StickyToDo",
        "Hey Siri, start my weekly review",
        "Hey Siri, show my weekly summary in StickyToDo"
    ]

    static let addToProject = [
        "Hey Siri, add task to project in StickyToDo",
        "Hey Siri, add 'Finish documentation' to Work in StickyToDo",
        "Hey Siri, create task in Home project in StickyToDo"
    ]

    static var allSamples: [String: [String]] {
        return [
            "Add Task": addTask,
            "Show Inbox": showInbox,
            "Show Next Actions": showNextActions,
            "Complete Task": completeTask,
            "Show Today's Tasks": showToday,
            "Start Timer": startTimer,
            "Stop Timer": stopTimer,
            "Flag Task": flagTask,
            "Show Flagged": showFlagged,
            "Weekly Review": weeklyReview,
            "Add to Project": addToProject
        ]
    }
}
