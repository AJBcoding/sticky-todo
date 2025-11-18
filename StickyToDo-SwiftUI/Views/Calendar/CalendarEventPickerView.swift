//
//  CalendarEventPickerView.swift
//  StickyToDo-SwiftUI
//
//  View for selecting existing calendar events to link with tasks.
//

import SwiftUI
import EventKit

/// Calendar event picker for linking existing events with tasks
///
/// Allows users to:
/// - Browse upcoming calendar events
/// - Search for specific events
/// - Link an event to a task
/// - View event details
@available(macOS 10.15, *)
struct CalendarEventPickerView: View {

    // MARK: - Properties

    @ObservedObject private var calendarManager = CalendarManager.shared

    @State private var events: [EKEvent] = []
    @State private var selectedEvent: EKEvent?
    @State private var searchText = ""
    @State private var dateRange: DateRange = .week
    @State private var isLoading = false

    var onEventSelected: ((EKEvent) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Select Calendar Event")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose an existing calendar event to link with this task")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Cancel") {
                    onCancel?()
                }
            }
            .padding()

            Divider()

            // Search and filters
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search events...", text: $searchText)
                    .textFieldStyle(.plain)

                Picker("Range", selection: $dateRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue)
                            .tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                .onChange(of: dateRange) { _ in
                    loadEvents()
                }

                Button(action: loadEvents) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
            .padding()

            Divider()

            // Events list
            if !calendarManager.hasAuthorization {
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.largeTitle)
                        .foregroundColor(.orange)

                    Text("Calendar Access Required")
                        .font(.headline)

                    Text("Please grant calendar access to view events.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading events...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredEvents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    Text("No Events Found")
                        .font(.headline)

                    Text("No calendar events in the selected date range")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredEvents, id: \.eventIdentifier, selection: $selectedEvent) { event in
                    EventRow(event: event)
                        .tag(event)
                        .onTapGesture {
                            selectedEvent = event
                        }
                }
            }

            Divider()

            // Action buttons
            HStack {
                Spacer()

                Button("Cancel") {
                    onCancel?()
                }
                .keyboardShortcut(.cancelAction)

                Button("Select") {
                    if let event = selectedEvent {
                        onEventSelected?(event)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedEvent == nil)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            loadEvents()
        }
    }

    // MARK: - Computed Properties

    private var filteredEvents: [EKEvent] {
        if searchText.isEmpty {
            return events
        } else {
            let lowercaseSearch = searchText.lowercased()
            return events.filter { event in
                event.title.lowercased().contains(lowercaseSearch) ||
                event.notes?.lowercased().contains(lowercaseSearch) == true
            }
        }
    }

    // MARK: - Actions

    private func loadEvents() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            let (start, end) = dateRange.dateRange
            let loadedEvents = calendarManager.fetchEvents(from: start, to: end)
                .sorted { $0.startDate < $1.startDate }

            DispatchQueue.main.async {
                events = loadedEvents
                isLoading = false
            }
        }
    }
}

// MARK: - Event Row

@available(macOS 10.15, *)
private struct EventRow: View {
    let event: EKEvent

    var body: some View {
        HStack(spacing: 12) {
            // Calendar color indicator
            Circle()
                .fill(Color(event.calendar.color))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(event.title)
                    .font(.body)
                    .lineLimit(1)

                // Date and time
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatEventDate(event))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if event.isAllDay {
                        Text("All Day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.2))
                            )
                    }
                }

                // Calendar name
                Text(event.calendar.title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Indicators
            VStack(alignment: .trailing, spacing: 4) {
                if event.hasAlarms {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if event.hasRecurrenceRules {
                    Image(systemName: "repeat")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                if event.hasAttendees {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatEventDate(_ event: EKEvent) -> String {
        let formatter = DateFormatter()

        if event.isAllDay {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: event.startDate)
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let start = formatter.string(from: event.startDate)
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let end = formatter.string(from: event.endDate)
            return "\(start) - \(end)"
        }
    }
}

// MARK: - Date Range

enum DateRange: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"

    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .week:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, end)

        case .month:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)

        case .year:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarEventPickerView()
}
