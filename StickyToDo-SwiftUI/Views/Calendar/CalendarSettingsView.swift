//
//  CalendarSettingsView.swift
//  StickyToDo-SwiftUI
//
//  Settings view for calendar integration configuration.
//

import SwiftUI
import EventKit

/// Calendar integration settings view
///
/// Allows users to:
/// - Grant calendar permissions
/// - Select default calendar
/// - Configure auto-sync options
/// - Choose which tasks to sync
@available(macOS 10.15, *)
struct CalendarSettingsView: View {

    // MARK: - Properties

    @ObservedObject private var calendarManager = CalendarManager.shared

    @State private var isRequestingAuth = false
    @State private var showingError = false
    @State private var errorMessage = ""

    // MARK: - Body

    var body: some View {
        Form {
            Section(header: Text("Calendar Access")) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status: \(authorizationStatusText)")
                            .font(.body)

                        if !calendarManager.hasAuthorization {
                            Text("Grant permission to sync tasks with your calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if !calendarManager.hasAuthorization {
                        Button(action: requestAuthorization) {
                            if isRequestingAuth {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Text("Grant Access")
                            }
                        }
                        .disabled(isRequestingAuth)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
            }

            if calendarManager.hasAuthorization {
                Section(header: Text("Sync Settings")) {
                    // Auto-sync toggle
                    Toggle("Enable Auto-Sync", isOn: $calendarManager.preferences.autoSyncEnabled)
                        .onChange(of: calendarManager.preferences.autoSyncEnabled) { _ in
                            calendarManager.savePreferences()
                        }

                    // Default calendar picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Calendar")
                            .font(.headline)

                        Picker("Calendar", selection: $calendarManager.preferences.defaultCalendarId) {
                            Text("System Default")
                                .tag(nil as String?)

                            Divider()

                            ForEach(calendarManager.availableCalendars, id: \.calendarIdentifier) { calendar in
                                HStack {
                                    Circle()
                                        .fill(Color(calendar.color))
                                        .frame(width: 12, height: 12)

                                    Text(calendar.title)
                                }
                                .tag(calendar.calendarIdentifier as String?)
                            }
                        }
                        .onChange(of: calendarManager.preferences.defaultCalendarId) { _ in
                            calendarManager.savePreferences()
                        }
                    }
                    .padding(.vertical, 4)

                    // Sync filter
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Which Tasks to Sync")
                            .font(.headline)

                        Picker("Sync Filter", selection: $calendarManager.preferences.syncFilter) {
                            ForEach(SyncFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue)
                                    .tag(filter)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .onChange(of: calendarManager.preferences.syncFilter) { _ in
                            calendarManager.savePreferences()
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Calendar List")) {
                    if calendarManager.availableCalendars.isEmpty {
                        Text("No calendars available")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        List {
                            ForEach(calendarManager.availableCalendars, id: \.calendarIdentifier) { calendar in
                                HStack {
                                    Circle()
                                        .fill(Color(calendar.color))
                                        .frame(width: 16, height: 16)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(calendar.title)
                                            .font(.body)

                                        if let source = calendar.source?.title {
                                            Text(source)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if !calendar.allowsContentModifications {
                                        Text("Read-only")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .frame(minHeight: 200)
                    }
                }

                Section {
                    Button("Refresh Calendars") {
                        calendarManager.refreshCalendars()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
        .padding()
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if calendarManager.hasAuthorization {
                calendarManager.refreshCalendars()
            }
        }
    }

    // MARK: - Computed Properties

    private var authorizationStatusText: String {
        switch calendarManager.authorizationStatus {
        case .notDetermined:
            return "Not Requested"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .fullAccess:
            return "Full Access"
        case .writeOnly:
            return "Write Only"
        @unknown default:
            return "Unknown"
        }
    }

    // MARK: - Actions

    private func requestAuthorization() {
        isRequestingAuth = true

        calendarManager.requestAuthorization { result in
            isRequestingAuth = false

            switch result {
            case .success(let granted):
                if granted {
                    calendarManager.refreshCalendars()
                } else {
                    errorMessage = "Calendar access was denied. Please grant permission in System Preferences."
                    showingError = true
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarSettingsView()
}
