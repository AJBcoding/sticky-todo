//
//  Recurrence.swift
//  StickyToDo
//
//  Represents recurrence patterns for recurring tasks.
//

import Foundation

/// Frequency options for recurring tasks
public enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case custom = "custom"

    /// User-facing display name
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
}

/// Defines how a task should recur
public struct Recurrence: Codable, Equatable {

    // MARK: - Properties

    /// The frequency of recurrence (daily, weekly, monthly, yearly, custom)
    var frequency: RecurrenceFrequency

    /// How often the task recurs (every N days/weeks/months/years)
    /// For example: interval = 2 with frequency = .weekly means "every 2 weeks"
    var interval: Int

    /// For weekly recurrence: which days of the week (0 = Sunday, 6 = Saturday)
    /// Example: [1, 3, 5] means Monday, Wednesday, Friday
    var daysOfWeek: [Int]?

    /// For monthly recurrence: which day of the month (1-31)
    /// If the day doesn't exist in a month, uses the last day (e.g., Feb 30 -> Feb 28/29)
    var dayOfMonth: Int?

    /// For monthly recurrence: use the last day of the month
    var useLastDayOfMonth: Bool

    /// When the recurrence should end (nil = never ends)
    var endDate: Date?

    /// Maximum number of occurrences (nil = unlimited)
    var count: Int?

    /// Number of occurrences created so far (for count-based recurrence)
    var occurrenceCount: Int

    // MARK: - Initialization

    /// Creates a new recurrence pattern
    /// - Parameters:
    ///   - frequency: The recurrence frequency
    ///   - interval: How often to recur (every N periods)
    ///   - daysOfWeek: Days of week for weekly recurrence (0=Sunday)
    ///   - dayOfMonth: Day of month for monthly recurrence
    ///   - useLastDayOfMonth: Use last day of month for monthly recurrence
    ///   - endDate: When recurrence should end
    ///   - count: Maximum number of occurrences
    ///   - occurrenceCount: Current occurrence count
    public init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        dayOfMonth: Int? = nil,
        useLastDayOfMonth: Bool = false,
        endDate: Date? = nil,
        count: Int? = nil,
        occurrenceCount: Int = 0
    ) {
        self.frequency = frequency
        self.interval = max(1, interval) // Ensure interval is at least 1
        self.daysOfWeek = daysOfWeek?.sorted()
        self.dayOfMonth = dayOfMonth
        self.useLastDayOfMonth = useLastDayOfMonth
        self.endDate = endDate
        self.count = count
        self.occurrenceCount = occurrenceCount
    }
}

// MARK: - Computed Properties

extension Recurrence {
    /// Returns true if this recurrence pattern has reached its end
    var isComplete: Bool {
        // Check count-based limit
        if let maxCount = count, occurrenceCount >= maxCount {
            return true
        }

        // Check date-based limit
        if let end = endDate, Date() >= end {
            return true
        }

        return false
    }

    /// Human-readable description of the recurrence pattern
    var description: String {
        var parts: [String] = []

        // Frequency and interval
        switch frequency {
        case .daily:
            if interval == 1 {
                parts.append("Daily")
            } else {
                parts.append("Every \(interval) days")
            }

        case .weekly:
            if interval == 1 {
                parts.append("Weekly")
            } else {
                parts.append("Every \(interval) weeks")
            }

            // Add days of week
            if let days = daysOfWeek, !days.isEmpty {
                let dayNames = days.map { dayName(for: $0) }
                parts.append("on \(dayNames.joined(separator: ", "))")
            }

        case .monthly:
            if interval == 1 {
                parts.append("Monthly")
            } else {
                parts.append("Every \(interval) months")
            }

            // Add day of month
            if useLastDayOfMonth {
                parts.append("on the last day")
            } else if let day = dayOfMonth {
                parts.append("on day \(day)")
            }

        case .yearly:
            if interval == 1 {
                parts.append("Yearly")
            } else {
                parts.append("Every \(interval) years")
            }

        case .custom:
            parts.append("Custom pattern")
        }

        // End condition
        if let end = endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            parts.append("until \(formatter.string(from: end))")
        } else if let maxCount = count {
            parts.append("for \(maxCount) occurrences")
        }

        return parts.joined(separator: " ")
    }

    /// Short description for UI display
    var shortDescription: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly:
            return interval == 1 ? "Weekly" : "Every \(interval) weeks"
        case .monthly:
            return interval == 1 ? "Monthly" : "Every \(interval) months"
        case .yearly:
            return interval == 1 ? "Yearly" : "Every \(interval) years"
        case .custom:
            return "Custom"
        }
    }

    // MARK: - Private Helpers

    private func dayName(for dayIndex: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard dayIndex >= 0 && dayIndex < days.count else { return "" }
        return days[dayIndex]
    }
}

// MARK: - Preset Recurrence Patterns

extension Recurrence {
    /// Daily recurrence (every day)
    static var daily: Recurrence {
        Recurrence(frequency: .daily, interval: 1)
    }

    /// Weekly recurrence (every week on the same day)
    static var weekly: Recurrence {
        Recurrence(frequency: .weekly, interval: 1)
    }

    /// Bi-weekly recurrence (every 2 weeks)
    static var biweekly: Recurrence {
        Recurrence(frequency: .weekly, interval: 2)
    }

    /// Monthly recurrence (every month on the same day)
    static var monthly: Recurrence {
        Recurrence(frequency: .monthly, interval: 1)
    }

    /// Yearly recurrence (every year on the same date)
    static var yearly: Recurrence {
        Recurrence(frequency: .yearly, interval: 1)
    }

    /// Weekday recurrence (Monday through Friday)
    static var weekdays: Recurrence {
        Recurrence(frequency: .weekly, interval: 1, daysOfWeek: [1, 2, 3, 4, 5])
    }

    /// Weekend recurrence (Saturday and Sunday)
    static var weekends: Recurrence {
        Recurrence(frequency: .weekly, interval: 1, daysOfWeek: [0, 6])
    }
}
