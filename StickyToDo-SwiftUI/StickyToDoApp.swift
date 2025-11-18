//
//  StickyToDoApp.swift
//  StickyToDo
//
//  Created on 2025-11-17.
//

import SwiftUI
import UserNotifications

@main
struct StickyToDoApp: App {

    @StateObject private var notificationManager = NotificationManager.shared

    init() {
        setupNotifications()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Quick Capture") {
                    // TODO: Implement quick capture
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }

    // MARK: - Notification Setup

    private func setupNotifications() {
        // Register notification categories with actions
        let completeAction = UNNotificationAction(
            identifier: NotificationAction.complete.rawValue,
            title: "Complete",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze.rawValue,
            title: "Snooze 1 Hour",
            options: []
        )

        let taskCategory = UNNotificationCategory(
            identifier: NotificationCategory.task.rawValue,
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let weeklyReviewCategory = UNNotificationCategory(
            identifier: NotificationCategory.weeklyReview.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let timerCategory = UNNotificationCategory(
            identifier: NotificationCategory.timer.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            taskCategory,
            weeklyReviewCategory,
            timerCategory
        ])

        // Check authorization status and request if needed
        Task { @MainActor in
            await notificationManager.checkAuthorizationStatus()

            // Request permission on first launch if not determined
            if notificationManager.authorizationStatus == .notDetermined {
                _ = await notificationManager.requestAuthorization()
            }
        }
    }
}
