//
//  CalendarSyncView.swift
//  StickyToDo-SwiftUI
//
//  View for manually syncing tasks with calendar.
//

import SwiftUI
import EventKit

/// View for managing calendar sync operations
///
/// Features:
/// - Add task to calendar
/// - Remove task from calendar
/// - View linked calendar event
/// - Quick sync actions
@available(macOS 10.15, *)
struct CalendarSyncView: View {

    // MARK: - Properties

    @Binding var task: Task
    @ObservedObject private var calendarManager = CalendarManager.shared

    @State private var isSyncing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var selectedCalendar: EKCalendar?

    var onTaskUpdated: ((Task) -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.largeTitle)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text("Calendar Sync")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Sync this task with your calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Task info
            VStack(alignment: .leading, spacing: 8) {
                Text("Task: \(task.title)")
                    .font(.headline)

                if let dueDate = task.due {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text("Due: \(dueDate, formatter: dateFormatter)")
                            .font(.body)
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("No due date set")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }

                if task.isSyncedToCalendar {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Synced to calendar")
                            .font(.body)
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )

            // Authorization check
            if !calendarManager.hasAuthorization {
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.largeTitle)
                        .foregroundColor(.orange)

                    Text("Calendar Access Required")
                        .font(.headline)

                    Text("Please grant calendar access in settings to sync tasks.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Open Settings") {
                        // This would open calendar settings
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if task.due == nil {
                // Can't sync without due date
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.orange)

                    Text("Due Date Required")
                        .font(.headline)

                    Text("Add a due date to this task to sync it with your calendar.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                // Calendar selector
                if !task.isSyncedToCalendar {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Calendar")
                            .font(.headline)

                        Picker("Calendar", selection: $selectedCalendar) {
                            if let defaultCal = calendarManager.defaultCalendar {
                                HStack {
                                    Circle()
                                        .fill(Color(defaultCal.color))
                                        .frame(width: 12, height: 12)
                                    Text("\(defaultCal.title) (Default)")
                                }
                                .tag(defaultCal as EKCalendar?)
                            }

                            Divider()

                            ForEach(calendarManager.availableCalendars, id: \.calendarIdentifier) { calendar in
                                HStack {
                                    Circle()
                                        .fill(Color(calendar.color))
                                        .frame(width: 12, height: 12)
                                    Text(calendar.title)
                                }
                                .tag(calendar as EKCalendar?)
                            }
                        }
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    if task.isSyncedToCalendar {
                        Button(action: updateEvent) {
                            HStack {
                                if isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text("Update Calendar Event")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSyncing)

                        Button(action: viewEvent) {
                            HStack {
                                Image(systemName: "eye")
                                Text("View Event in Calendar")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive, action: removeFromCalendar) {
                            HStack {
                                if isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "trash")
                                }
                                Text("Remove from Calendar")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isSyncing)
                    } else {
                        Button(action: addToCalendar) {
                            HStack {
                                if isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "plus.circle")
                                }
                                Text("Add to Calendar")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSyncing || selectedCalendar == nil)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
        .onAppear {
            selectedCalendar = calendarManager.defaultCalendar
        }
    }

    // MARK: - Date Formatter

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    // MARK: - Actions

    private func addToCalendar() {
        guard let calendar = selectedCalendar else {
            errorMessage = "Please select a calendar"
            showingError = true
            return
        }

        isSyncing = true

        DispatchQueue.global(qos: .userInitiated).async {
            let result = calendarManager.createEvent(from: task, in: calendar)

            DispatchQueue.main.async {
                isSyncing = false

                switch result {
                case .success(let eventId):
                    task.calendarEventId = eventId
                    onTaskUpdated?(task)
                    successMessage = "Task added to calendar successfully"
                    showingSuccess = true

                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func updateEvent() {
        guard let eventId = task.calendarEventId else { return }

        isSyncing = true

        DispatchQueue.global(qos: .userInitiated).async {
            let result = calendarManager.updateEvent(eventId, from: task)

            DispatchQueue.main.async {
                isSyncing = false

                switch result {
                case .success:
                    successMessage = "Calendar event updated successfully"
                    showingSuccess = true

                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func removeFromCalendar() {
        guard let eventId = task.calendarEventId else { return }

        isSyncing = true

        DispatchQueue.global(qos: .userInitiated).async {
            let result = calendarManager.deleteEvent(eventId)

            DispatchQueue.main.async {
                isSyncing = false

                switch result {
                case .success:
                    task.calendarEventId = nil
                    onTaskUpdated?(task)
                    successMessage = "Task removed from calendar"
                    showingSuccess = true

                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func viewEvent() {
        guard let eventId = task.calendarEventId,
              let event = calendarManager.fetchEvent(eventId) else {
            errorMessage = "Could not find calendar event"
            showingError = true
            return
        }

        // Open Calendar app to this event
        let calendarDate = event.startDate
        if let url = URL(string: "x-apple-calendar://ekevent/\(eventId)") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarSyncView(
        task: .constant(Task(
            title: "Sample Task",
            due: Date().addingTimeInterval(86400),
            flagged: true
        ))
    )
}
