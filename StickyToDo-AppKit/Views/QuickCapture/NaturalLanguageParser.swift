//
//  NaturalLanguageParser.swift
//  StickyToDo-AppKit
//
//  Parses natural language task input to extract metadata.
//  Supports @context, #project, !priority, dates, and effort markers.
//

import Foundation

/// Result of parsing natural language task input
struct ParseResult {
    /// The cleaned task title (with markers removed)
    var title: String

    /// Extracted context (from @context)
    var context: String?

    /// Extracted project (from #project)
    var project: String?

    /// Extracted priority (from !high, !medium, !low)
    var priority: Priority?

    /// Extracted due date (from natural language dates)
    var dueDate: Date?

    /// Extracted defer date (from ^defer:date)
    var deferDate: Date?

    /// Extracted effort estimate in minutes (from //30m)
    var effort: Int?
}

/// Parser for natural language task input
class NaturalLanguageParser {

    // MARK: - Properties

    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()

    // MARK: - Initialization

    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
    }

    // MARK: - Parsing

    /// Parses natural language input to extract task metadata
    /// - Parameter input: The raw input string
    /// - Returns: Parsed result with title and extracted metadata
    func parse(_ input: String) -> ParseResult {
        var result = ParseResult(title: input)
        var cleanedTitle = input

        // Extract context (@context)
        if let context = extractContext(from: input) {
            result.context = context
            cleanedTitle = cleanedTitle.replacingOccurrences(of: "@\(context)", with: "")
        }

        // Extract project (#project)
        if let project = extractProject(from: input) {
            result.project = project
            cleanedTitle = cleanedTitle.replacingOccurrences(of: "#\(project)", with: "")
        }

        // Extract priority (!high, !medium, !low)
        if let priority = extractPriority(from: input) {
            result.priority = priority
            cleanedTitle = cleanedTitle.replacingOccurrences(of: priority.marker, with: "")
        }

        // Extract effort (//30m, //2h, etc.)
        if let effort = extractEffort(from: input) {
            result.effort = effort
            cleanedTitle = removeEffortMarkers(from: cleanedTitle)
        }

        // Extract defer date (^defer:tomorrow, ^defer:friday, etc.)
        if let deferInfo = extractDeferDate(from: input) {
            result.deferDate = deferInfo.date
            cleanedTitle = cleanedTitle.replacingOccurrences(of: deferInfo.marker, with: "")
        }

        // Extract due date (tomorrow, friday, nov 20, etc.)
        // Do this after defer to avoid conflicts
        if let dueInfo = extractDueDate(from: cleanedTitle) {
            result.dueDate = dueInfo.date
            cleanedTitle = cleanedTitle.replacingOccurrences(of: dueInfo.marker, with: "")
        }

        // Clean up the title
        result.title = cleanedTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return result
    }

    // MARK: - Extraction Methods

    private func extractContext(from input: String) -> String? {
        let pattern = "@([a-zA-Z0-9_-]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let range = Range(match.range(at: 1), in: input) else {
            return nil
        }
        return String(input[range])
    }

    private func extractProject(from input: String) -> String? {
        let pattern = "#([a-zA-Z0-9_\\s-]+?)(?=\\s|$|@|!|#|//|\\^)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let range = Range(match.range(at: 1), in: input) else {
            return nil
        }
        return String(input[range]).trimmingCharacters(in: .whitespaces)
    }

    private func extractPriority(from input: String) -> Priority? {
        if input.contains("!high") {
            return .high
        } else if input.contains("!medium") {
            return .medium
        } else if input.contains("!low") {
            return .low
        }
        return nil
    }

    private func extractEffort(from input: String) -> Int? {
        // Match //30m, //2h, //1.5h, etc.
        let pattern = "//\\s*(\\d+(?:\\.\\d+)?)\\s*([mh])"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let valueRange = Range(match.range(at: 1), in: input),
              let unitRange = Range(match.range(at: 2), in: input) else {
            return nil
        }

        let valueString = String(input[valueRange])
        let unit = String(input[unitRange])

        guard let value = Double(valueString) else { return nil }

        if unit == "h" {
            return Int(value * 60)
        } else {
            return Int(value)
        }
    }

    private func removeEffortMarkers(from input: String) -> String {
        let pattern = "//\\s*\\d+(?:\\.\\d+)?\\s*[mh]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        return regex.stringByReplacingMatches(
            in: input,
            range: NSRange(input.startIndex..., in: input),
            withTemplate: ""
        )
    }

    private func extractDeferDate(from input: String) -> (date: Date, marker: String)? {
        // Match ^defer:tomorrow, ^defer:friday, etc.
        let pattern = "\\^defer:(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let dateRange = Range(match.range(at: 1), in: input),
              let fullRange = Range(match.range, in: input) else {
            return nil
        }

        let dateString = String(input[dateRange])
        let fullMarker = String(input[fullRange])

        if let date = parseRelativeDate(dateString) {
            return (date, fullMarker)
        }

        return nil
    }

    private func extractDueDate(from input: String) -> (date: Date, marker: String)? {
        // Common date keywords
        let keywords = [
            "today", "tomorrow", "tonight",
            "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
            "mon", "tue", "wed", "thu", "fri", "sat", "sun"
        ]

        let lowercased = input.lowercased()

        for keyword in keywords {
            if let range = lowercased.range(of: "\\b\(keyword)\\b", options: .regularExpression),
               let date = parseRelativeDate(keyword) {
                return (date, String(input[range]))
            }
        }

        // Try to extract specific dates (Nov 20, 11/20, etc.)
        if let result = extractSpecificDate(from: input) {
            return result
        }

        return nil
    }

    private func parseRelativeDate(_ keyword: String) -> Date? {
        let lowercased = keyword.lowercased()
        let today = calendar.startOfDay(for: Date())

        switch lowercased {
        case "today", "tonight":
            return today

        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: today)

        case "monday", "mon":
            return nextWeekday(.monday, from: today)

        case "tuesday", "tue":
            return nextWeekday(.tuesday, from: today)

        case "wednesday", "wed":
            return nextWeekday(.wednesday, from: today)

        case "thursday", "thu":
            return nextWeekday(.thursday, from: today)

        case "friday", "fri":
            return nextWeekday(.friday, from: today)

        case "saturday", "sat":
            return nextWeekday(.saturday, from: today)

        case "sunday", "sun":
            return nextWeekday(.sunday, from: today)

        default:
            return nil
        }
    }

    private func nextWeekday(_ weekday: Calendar.Component, from date: Date) -> Date? {
        // Map component to weekday number
        let weekdayMap: [Calendar.Component: Int] = [
            .sunday: 1,
            .monday: 2,
            .tuesday: 3,
            .wednesday: 4,
            .thursday: 5,
            .friday: 6,
            .saturday: 7
        ]

        guard let targetWeekday = weekdayMap[weekday] else { return nil }

        let currentWeekday = calendar.component(.weekday, from: date)

        var daysToAdd = targetWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }

    private func extractSpecificDate(from input: String) -> (date: Date, marker: String)? {
        // Try common date formats
        let patterns = [
            // Month DD (Nov 20, November 20)
            "([A-Z][a-z]+)\\s+(\\d{1,2})",
            // MM/DD or M/D
            "(\\d{1,2})/(\\d{1,2})",
            // MM-DD or M-D
            "(\\d{1,2})-(\\d{1,2})"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
                  let fullRange = Range(match.range, in: input) else {
                continue
            }

            let marker = String(input[fullRange])

            // Try to parse the date
            if let date = tryParseDate(marker) {
                return (date, marker)
            }
        }

        return nil
    }

    private func tryParseDate(_ string: String) -> Date? {
        let formats = [
            "MMM d",
            "MMMM d",
            "M/d",
            "M-d"
        ]

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: string) {
                // Adjust year if needed (assume current or next year)
                var components = calendar.dateComponents([.month, .day], from: date)
                components.year = calendar.component(.year, from: Date())

                if let resultDate = calendar.date(from: components) {
                    // If date is in the past, use next year
                    if resultDate < Date() {
                        components.year! += 1
                        return calendar.date(from: components)
                    }
                    return resultDate
                }
            }
        }

        return nil
    }
}

// MARK: - Calendar.Component Extension

fileprivate extension Calendar.Component {
    static let sunday: Calendar.Component = .weekday
    static let monday: Calendar.Component = .weekday
    static let tuesday: Calendar.Component = .weekday
    static let wednesday: Calendar.Component = .weekday
    static let thursday: Calendar.Component = .weekday
    static let friday: Calendar.Component = .weekday
    static let saturday: Calendar.Component = .weekday
}
