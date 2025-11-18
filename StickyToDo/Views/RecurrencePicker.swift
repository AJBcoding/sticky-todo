//
//  RecurrencePicker.swift
//  StickyToDo
//
//  SwiftUI view for editing task recurrence patterns.
//

import SwiftUI

/// Picker for editing recurrence patterns on tasks
struct RecurrencePicker: View {

    // MARK: - Properties

    /// The recurrence pattern being edited (nil if not recurring)
    @Binding var recurrence: Recurrence?

    /// Callback when recurrence is modified
    var onChange: () -> Void

    // MARK: - State

    @State private var isEnabled: Bool
    @State private var frequency: RecurrenceFrequency
    @State private var interval: Int
    @State private var selectedDays: Set<Int>
    @State private var dayOfMonth: Int
    @State private var useLastDayOfMonth: Bool
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var hasCount: Bool
    @State private var count: Int

    // MARK: - Initialization

    init(recurrence: Binding<Recurrence?>, onChange: @escaping () -> Void) {
        self._recurrence = recurrence
        self.onChange = onChange

        // Initialize state from recurrence
        let rec = recurrence.wrappedValue
        _isEnabled = State(initialValue: rec != nil)
        _frequency = State(initialValue: rec?.frequency ?? .daily)
        _interval = State(initialValue: rec?.interval ?? 1)
        _selectedDays = State(initialValue: Set(rec?.daysOfWeek ?? []))
        _dayOfMonth = State(initialValue: rec?.dayOfMonth ?? 1)
        _useLastDayOfMonth = State(initialValue: rec?.useLastDayOfMonth ?? false)
        _hasEndDate = State(initialValue: rec?.endDate != nil)
        _endDate = State(initialValue: rec?.endDate ?? Date().addingTimeInterval(86400 * 30))
        _hasCount = State(initialValue: rec?.count != nil)
        _count = State(initialValue: rec?.count ?? 10)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Enable/disable recurrence
            Toggle("Repeat Task", isOn: $isEnabled)
                .font(.headline)
                .onChange(of: isEnabled) { enabled in
                    if enabled {
                        updateRecurrence()
                    } else {
                        recurrence = nil
                        onChange()
                    }
                }

            if isEnabled {
                recurrenceSettingsView
            }
        }
        .padding()
    }

    // MARK: - Recurrence Settings

    @ViewBuilder
    private var recurrenceSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Frequency
            frequencySection

            // Interval
            intervalSection

            // Weekly days picker
            if frequency == .weekly {
                weeklyDaysSection
            }

            // Monthly day picker
            if frequency == .monthly {
                monthlyDaySection
            }

            Divider()

            // End condition
            endConditionSection
        }
    }

    // MARK: - Frequency Section

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Frequency", selection: $frequency) {
                Text("Daily").tag(RecurrenceFrequency.daily)
                Text("Weekly").tag(RecurrenceFrequency.weekly)
                Text("Monthly").tag(RecurrenceFrequency.monthly)
                Text("Yearly").tag(RecurrenceFrequency.yearly)
            }
            .pickerStyle(.segmented)
            .onChange(of: frequency) { _ in
                updateRecurrence()
            }
        }
    }

    // MARK: - Interval Section

    private var intervalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat Every")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Stepper(
                    value: $interval,
                    in: 1...99,
                    onEditingChanged: { _ in updateRecurrence() }
                ) {
                    HStack {
                        Text("\(interval)")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(intervalUnit)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var intervalUnit: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "day" : "days"
        case .weekly:
            return interval == 1 ? "week" : "weeks"
        case .monthly:
            return interval == 1 ? "month" : "months"
        case .yearly:
            return interval == 1 ? "year" : "years"
        case .custom:
            return "interval"
        }
    }

    // MARK: - Weekly Days Section

    private var weeklyDaysSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat On")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(0..<7) { day in
                    dayButton(for: day)
                }
            }
        }
    }

    private func dayButton(for day: Int) -> some View {
        let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
        let fullDayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let isSelected = selectedDays.contains(day)

        return Button(action: {
            if isSelected {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
            }
            updateRecurrence()
        }) {
            Text(dayNames[day])
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(fullDayNames[day])
    }

    // MARK: - Monthly Day Section

    private var monthlyDaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat On")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                // Specific day of month
                HStack {
                    RadioButton(
                        isSelected: !useLastDayOfMonth,
                        action: {
                            useLastDayOfMonth = false
                            updateRecurrence()
                        }
                    )

                    Text("Day")

                    Stepper(
                        value: $dayOfMonth,
                        in: 1...31,
                        onEditingChanged: { _ in
                            useLastDayOfMonth = false
                            updateRecurrence()
                        }
                    ) {
                        Text("\(dayOfMonth)")
                            .fontWeight(.semibold)
                    }
                    .disabled(useLastDayOfMonth)
                }

                // Last day of month
                HStack {
                    RadioButton(
                        isSelected: useLastDayOfMonth,
                        action: {
                            useLastDayOfMonth = true
                            updateRecurrence()
                        }
                    )

                    Text("Last day of month")
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
    }

    // MARK: - End Condition Section

    private var endConditionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ends")
                .font(.caption)
                .foregroundColor(.secondary)

            // Never
            HStack {
                RadioButton(
                    isSelected: !hasEndDate && !hasCount,
                    action: {
                        hasEndDate = false
                        hasCount = false
                        updateRecurrence()
                    }
                )
                Text("Never")
            }

            // On date
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    RadioButton(
                        isSelected: hasEndDate,
                        action: {
                            hasEndDate = true
                            hasCount = false
                            updateRecurrence()
                        }
                    )
                    Text("On date")
                }

                if hasEndDate {
                    DatePicker(
                        "End Date",
                        selection: $endDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .onChange(of: endDate) { _ in
                        updateRecurrence()
                    }
                }
            }

            // After count
            HStack {
                RadioButton(
                    isSelected: hasCount,
                    action: {
                        hasCount = true
                        hasEndDate = false
                        updateRecurrence()
                    }
                )

                Text("After")

                Stepper(
                    value: $count,
                    in: 1...999,
                    onEditingChanged: { _ in updateRecurrence() }
                ) {
                    Text("\(count)")
                        .fontWeight(.semibold)
                }
                .disabled(!hasCount)

                Text("occurrences")
            }
        }
    }

    // MARK: - Helper Methods

    private func updateRecurrence() {
        guard isEnabled else {
            recurrence = nil
            onChange()
            return
        }

        recurrence = Recurrence(
            frequency: frequency,
            interval: interval,
            daysOfWeek: frequency == .weekly ? Array(selectedDays) : nil,
            dayOfMonth: frequency == .monthly && !useLastDayOfMonth ? dayOfMonth : nil,
            useLastDayOfMonth: frequency == .monthly && useLastDayOfMonth,
            endDate: hasEndDate ? endDate : nil,
            count: hasCount ? count : nil,
            occurrenceCount: recurrence?.occurrenceCount ?? 0
        )

        onChange()
    }
}

// MARK: - Radio Button

private struct RadioButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Recurrence Picker - Daily") {
    RecurrencePicker(
        recurrence: .constant(Recurrence(frequency: .daily, interval: 1)),
        onChange: {}
    )
    .frame(width: 400)
}

#Preview("Recurrence Picker - Weekly") {
    RecurrencePicker(
        recurrence: .constant(Recurrence(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [1, 3, 5]
        )),
        onChange: {}
    )
    .frame(width: 400)
}

#Preview("Recurrence Picker - None") {
    RecurrencePicker(
        recurrence: .constant(nil),
        onChange: {}
    )
    .frame(width: 400)
}
