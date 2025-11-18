//
//  CustomReminderView.swift
//  StickyToDo-SwiftUI
//
//  View for adding custom reminders to tasks.
//

import SwiftUI

/// View for configuring custom reminders for a task
struct CustomReminderView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    /// The task to add a reminder to
    @Binding var task: Task

    /// Notification manager
    @ObservedObject var notificationManager = NotificationManager.shared

    /// Selected reminder date
    @State private var reminderDate = Date().addingTimeInterval(3600) // 1 hour from now

    /// Selected reminder type
    @State private var reminderType: ReminderType = .custom

    /// Whether to show success message
    @State private var showingSuccess = false

    /// Callback when reminder is added
    var onReminderAdded: (() -> Void)?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Reminder Type", selection: $reminderType) {
                        Text("Custom Time").tag(ReminderType.custom)
                        Text("1 Hour").tag(ReminderType.oneHour)
                        Text("2 Hours").tag(ReminderType.twoHours)
                        Text("Tomorrow 9 AM").tag(ReminderType.tomorrowMorning)
                        Text("This Evening (6 PM)").tag(ReminderType.thisEvening)
                    }
                } header: {
                    Text("When")
                } footer: {
                    Text("Choose when you want to be reminded about this task.")
                }

                if reminderType == .custom {
                    Section {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } header: {
                        Text("Custom Time")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task: \(task.title)")
                            .font(.headline)

                        if let description = reminderDescription {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Reminder Preview")
                }

                Section {
                    HStack {
                        Image(systemName: task.notificationIds.isEmpty ? "bell.slash" : "bell.badge")
                            .foregroundColor(task.notificationIds.isEmpty ? .secondary : .blue)

                        Text(task.notificationIds.isEmpty ?
                             "No active reminders" :
                             "\(task.notificationIds.count) active reminder(s)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Current Reminders")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addReminder()
                    }
                    .disabled(!notificationManager.areNotificationsAvailable)
                }
            }
            .alert("Reminder Added", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                    onReminderAdded?()
                }
            } message: {
                Text("You'll be notified \(reminderDescription ?? "at the selected time")")
            }
        }
    }

    // MARK: - Computed Properties

    private var reminderDescription: String? {
        let date = getReminderDate()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today at \(formatter.string(from: date).components(separatedBy: ", ").last ?? "")"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow at \(formatter.string(from: date).components(separatedBy: ", ").last ?? "")"
        } else {
            return formatter.string(from: date)
        }
    }

    // MARK: - Helper Methods

    private func getReminderDate() -> Date {
        switch reminderType {
        case .custom:
            return reminderDate
        case .oneHour:
            return Date().addingTimeInterval(3600)
        case .twoHours:
            return Date().addingTimeInterval(7200)
        case .tomorrowMorning:
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.day! += 1
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components) ?? Date()
        case .thisEvening:
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 18
            components.minute = 0
            let evening = calendar.date(from: components) ?? Date()
            // If it's already past 6 PM, schedule for tomorrow evening
            return evening > Date() ? evening : calendar.date(byAdding: .day, value: 1, to: evening)!
        }
    }

    private func addReminder() {
        Task {
            let date = getReminderDate()

            // Schedule the notification
            let id = await scheduleCustomNotification(for: task, at: date)

            if let id = id {
                // Update task with notification ID
                task.notificationIds.append(id)
                showingSuccess = true
            }
        }
    }

    private func scheduleCustomNotification(for task: Task, at date: Date) async -> String? {
        guard date > Date() else { return nil }

        let identifier = "\(task.id.uuidString)-custom-\(Int(date.timeIntervalSince1970))"

        let content = UNMutableNotificationContent()
        content.title = "Reminder: \(task.title)"
        content.body = task.notes.isEmpty ? "You asked to be reminded about this task" : task.notes
        content.sound = notificationManager.notificationSound.sound
        content.categoryIdentifier = NotificationCategory.task.rawValue
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "customReminder"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: date.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            return identifier
        } catch {
            print("Failed to schedule custom reminder: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Types

enum ReminderType {
    case custom
    case oneHour
    case twoHours
    case tomorrowMorning
    case thisEvening
}

// MARK: - Preview

#Preview {
    CustomReminderView(
        task: .constant(Task(
            title: "Example Task",
            notes: "This is a task with some notes"
        ))
    )
}
