//
//  NextOccurrencesPreview.swift
//  StickyToDo
//
//  Preview component showing upcoming occurrences for recurring tasks.
//

import SwiftUI

/// Shows a preview of upcoming occurrences for a recurrence pattern
struct NextOccurrencesPreview: View {

    // MARK: - Properties

    /// The recurrence pattern to preview
    let recurrence: Recurrence?

    /// The base date to calculate from (usually the task's due date)
    let baseDate: Date

    /// Number of occurrences to preview (default: 5)
    let count: Int

    // MARK: - Initialization

    init(recurrence: Recurrence?, baseDate: Date = Date(), count: Int = 5) {
        self.recurrence = recurrence
        self.baseDate = baseDate
        self.count = count
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                Text("Next Occurrences")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(combining: .children)
            .accessibilityLabel("Next occurrences preview")

            if let recurrence = recurrence, !recurrence.isComplete {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(calculateNextOccurrences().enumerated()), id: \.offset) { index, date in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .accessibilityHidden(true)

                            Text(formatDate(date, index: index))
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .accessibilityElement(combining: .children)
                        .accessibilityLabel("Occurrence \(index + 1): \(formatDateForAccessibility(date))")
                    }
                }
                .padding(.leading, 8)

                // Show end condition if applicable
                if let endInfo = endConditionInfo {
                    Text(endInfo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.leading, 14)
                        .accessibilityLabel(endInfo)
                }
            } else if recurrence?.isComplete == true {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .accessibilityHidden(true)

                    Text("Recurrence completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.leading, 8)
                .accessibilityElement(combining: .children)
                .accessibilityLabel("Recurrence has completed")
            } else {
                Text("No recurrence pattern set")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.leading, 8)
                    .accessibilityLabel("No recurrence pattern set")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Helper Methods

    /// Calculates the next N occurrences based on the recurrence pattern
    private func calculateNextOccurrences() -> [Date] {
        guard let recurrence = recurrence else { return [] }

        var occurrences: [Date] = []
        var currentDate = baseDate
        var iterationCount = 0
        let maxIterations = count * 2 // Safety limit

        while occurrences.count < count && iterationCount < maxIterations {
            guard let nextDate = RecurrenceEngine.calculateNextOccurrence(
                from: currentDate,
                recurrence: recurrence
            ) else {
                break
            }

            // Check if we've exceeded count limit
            if let maxCount = recurrence.count,
               recurrence.occurrenceCount + occurrences.count >= maxCount {
                break
            }

            // Check if we've exceeded end date
            if let endDate = recurrence.endDate, nextDate > endDate {
                break
            }

            occurrences.append(nextDate)
            currentDate = nextDate
            iterationCount += 1
        }

        return occurrences
    }

    /// Formats a date for display
    private func formatDate(_ date: Date, index: Int) -> String {
        let formatter = DateFormatter()

        // Use relative formatting for near-term dates
        if index == 0 {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }

    /// Formats a date for accessibility (more descriptive)
    private func formatDateForAccessibility(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }

    /// Returns a description of the end condition
    private var endConditionInfo: String? {
        guard let recurrence = recurrence else { return nil }

        if let endDate = recurrence.endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Ends on \(formatter.string(from: endDate))"
        } else if let maxCount = recurrence.count {
            let remaining = maxCount - recurrence.occurrenceCount
            return "Ends after \(remaining) more occurrence\(remaining == 1 ? "" : "s")"
        }

        return nil
    }
}

// MARK: - Preview

#Preview("Daily Recurrence") {
    NextOccurrencesPreview(
        recurrence: Recurrence(frequency: .daily, interval: 1),
        baseDate: Date(),
        count: 5
    )
    .frame(width: 300)
    .padding()
}

#Preview("Weekly on Multiple Days") {
    NextOccurrencesPreview(
        recurrence: Recurrence(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [1, 3, 5] // Mon, Wed, Fri
        ),
        baseDate: Date(),
        count: 5
    )
    .frame(width: 300)
    .padding()
}

#Preview("Monthly with End Date") {
    let endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
    return NextOccurrencesPreview(
        recurrence: Recurrence(
            frequency: .monthly,
            interval: 1,
            endDate: endDate
        ),
        baseDate: Date(),
        count: 5
    )
    .frame(width: 300)
    .padding()
}

#Preview("Yearly with Count Limit") {
    NextOccurrencesPreview(
        recurrence: Recurrence(
            frequency: .yearly,
            interval: 1,
            count: 3
        ),
        baseDate: Date(),
        count: 5
    )
    .frame(width: 300)
    .padding()
}

#Preview("No Recurrence") {
    NextOccurrencesPreview(
        recurrence: nil,
        baseDate: Date(),
        count: 5
    )
    .frame(width: 300)
    .padding()
}

#Preview("Completed Recurrence") {
    let completedRecurrence = Recurrence(
        frequency: .daily,
        interval: 1,
        count: 5,
        occurrenceCount: 5
    )
    return NextOccurrencesPreview(
        recurrence: completedRecurrence,
        baseDate: Date(),
        count: 5
    )
    .frame(width: 300)
    .padding()
}
