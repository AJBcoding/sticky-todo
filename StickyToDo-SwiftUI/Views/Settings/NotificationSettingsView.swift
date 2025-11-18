//
//  NotificationSettingsView.swift
//  StickyToDo-SwiftUI
//
//  SwiftUI view for configuring notification settings.
//

import SwiftUI
import UserNotifications

/// View for configuring notification preferences
struct NotificationSettingsView: View {

    // MARK: - Properties

    @ObservedObject var notificationManager = NotificationManager.shared

    @State private var showingPermissionAlert = false
    @State private var showingTestNotificationAlert = false
    @State private var customReminderMinutes: Int = 30

    // MARK: - Body

    var body: some View {
        Form {
            // Authorization Section
            Section {
                authorizationStatusRow

                if notificationManager.authorizationStatus != .authorized {
                    requestPermissionButton
                }
            } header: {
                Text("Notification Permission")
            } footer: {
                Text("Allow StickyToDo to send you notifications about due tasks, deferrals, and weekly reviews.")
            }

            // General Settings
            if notificationManager.authorizationStatus == .authorized {
                Section {
                    Toggle("Enable Notifications", isOn: $notificationManager.notificationsEnabled)
                        .onChange(of: notificationManager.notificationsEnabled) { _, newValue in
                            if newValue {
                                // Re-schedule all pending notifications
                                // This would be handled by TaskStore
                            }
                        }

                    Toggle("Show Badge Count", isOn: $notificationManager.badgeEnabled)
                        .help("Display the number of overdue tasks on the app icon")
                } header: {
                    Text("General")
                } footer: {
                    Text("Badge count shows the number of overdue tasks.")
                }

                // Due Date Reminders
                Section {
                    Picker("Reminder Time", selection: $notificationManager.dueReminderTime) {
                        Text("1 Day Before").tag(DueReminderTime.oneDayBefore)
                        Text("1 Hour Before").tag(DueReminderTime.oneHour)
                        Text("15 Minutes Before").tag(DueReminderTime.fifteenMinutes)
                        Text("Multiple Reminders").tag(DueReminderTime.multiple)
                        Text("Custom").tag(DueReminderTime.custom(30))
                    }
                    .disabled(!notificationManager.notificationsEnabled)

                    if case .custom = notificationManager.dueReminderTime {
                        HStack {
                            Stepper("Custom: \(customReminderMinutes) minutes",
                                   value: $customReminderMinutes,
                                   in: 5...1440,
                                   step: 5)
                            .onChange(of: customReminderMinutes) { _, newValue in
                                notificationManager.dueReminderTime = .custom(newValue)
                            }
                        }
                    }
                } header: {
                    Text("Due Date Reminders")
                } footer: {
                    if case .multiple = notificationManager.dueReminderTime {
                        Text("Will send notifications 1 day before and 1 hour before the due date.")
                    } else {
                        Text("Choose when to receive notifications before a task is due.")
                    }
                }

                // Notification Sound
                Section {
                    Picker("Notification Sound", selection: $notificationManager.notificationSound) {
                        ForEach(NotificationSound.allCases, id: \.self) { sound in
                            Text(sound.rawValue).tag(sound)
                        }
                    }
                    .disabled(!notificationManager.notificationsEnabled)
                } header: {
                    Text("Sound")
                } footer: {
                    Text("Choose the sound played when notifications arrive.")
                }

                // Weekly Review
                Section {
                    Picker("Weekly Review", selection: $notificationManager.weeklyReviewSchedule) {
                        ForEach(WeeklyReviewSchedule.allCases, id: \.self) { schedule in
                            Text(schedule.rawValue).tag(schedule)
                        }
                    }
                    .disabled(!notificationManager.notificationsEnabled)
                } header: {
                    Text("Weekly Review")
                } footer: {
                    Text("Receive a reminder to review your tasks and plan for the week.")
                }

                // Notification Types
                Section {
                    notificationTypeRow(
                        title: "Due Date Reminders",
                        description: "When tasks are approaching their due date",
                        enabled: true
                    )

                    notificationTypeRow(
                        title: "Defer Date Notifications",
                        description: "When deferred tasks become available",
                        enabled: true
                    )

                    notificationTypeRow(
                        title: "Timer Completed",
                        description: "When a task timer finishes",
                        enabled: true
                    )

                    notificationTypeRow(
                        title: "Recurring Tasks",
                        description: "When new recurring task instances are created",
                        enabled: true
                    )
                } header: {
                    Text("Notification Types")
                } footer: {
                    Text("All notification types are currently enabled.")
                }

                // Testing & Statistics
                Section {
                    Button("Send Test Notification") {
                        Task {
                            await notificationManager.sendTestNotification()
                            showingTestNotificationAlert = true
                        }
                    }
                    .disabled(!notificationManager.notificationsEnabled)

                    pendingNotificationsRow
                } header: {
                    Text("Testing & Statistics")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Notifications")
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
        #endif
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                openSystemSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please allow notifications in System Settings to receive reminders about your tasks.")
        }
        .alert("Test Notification Sent", isPresented: $showingTestNotificationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A test notification will appear in a moment.")
        }
    }

    // MARK: - View Components

    private var authorizationStatusRow: some View {
        HStack {
            Text("Status")
            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        Group {
            switch notificationManager.authorizationStatus {
            case .authorized:
                Label("Authorized", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .denied:
                Label("Denied", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .notDetermined:
                Label("Not Requested", systemImage: "questionmark.circle.fill")
                    .foregroundColor(.orange)
            case .provisional:
                Label("Provisional", systemImage: "bell.badge.fill")
                    .foregroundColor(.orange)
            case .ephemeral:
                Label("Ephemeral", systemImage: "bell.slash.fill")
                    .foregroundColor(.gray)
            @unknown default:
                Label("Unknown", systemImage: "questionmark.circle")
                    .foregroundColor(.gray)
            }
        }
        .font(.callout)
    }

    private var requestPermissionButton: some View {
        Button("Request Permission") {
            Task {
                let granted = await notificationManager.requestAuthorization()
                if !granted {
                    showingPermissionAlert = true
                }
            }
        }
        .buttonStyle(.borderedProminent)
    }

    private func notificationTypeRow(title: String, description: String, enabled: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(enabled ? .green : .gray)
        }
    }

    private var pendingNotificationsRow: some View {
        HStack {
            Text("Pending Notifications")
            Spacer()
            Text("Loading...")
                .foregroundColor(.secondary)
                .task {
                    await updatePendingCount()
                }
        }
    }

    // MARK: - Helper Methods

    private func updatePendingCount() async {
        // This would be implemented to show pending notification count
    }

    private func openSystemSettings() {
        #if os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
        #else
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
