//
//  NaturalLanguageParser.swift
//  StickyToDo
//
//  Natural language parser for extracting task metadata from text.
//

import Foundation

/// Parses natural language input to extract task metadata
///
/// Recognizes patterns like:
/// - `@context` → sets context (e.g., "@phone", "@computer")
/// - `#project` → sets project (e.g., "#Website", "#Q4Planning")
/// - `!priority` → sets priority (!high, !medium, !low)
/// - `tomorrow`, `friday`, `nov 20` → sets due date
/// - `^defer:tomorrow` → sets defer date
/// - `//30m` → sets effort estimate in minutes
///
/// Example:
/// ```
/// let result = NaturalLanguageParser.parse("Call John @phone #Website !high tomorrow //30m")
/// // Result:
/// // - title: "Call John"
/// // - context: "@phone"
/// // - project: "Website"
/// // - priority: .high
/// // - due: <tomorrow's date>
/// // - effort: 30
/// ```
enum NaturalLanguageParser {

    // MARK: - Parse Result

    /// Result of parsing natural language input
    struct ParseResult {
        /// The cleaned task title (with metadata removed)
        var title: String

        /// Extracted context (if found)
        var context: String?

        /// Extracted project (if found)
        var project: String?

        /// Extracted priority (if found)
        var priority: Priority?

        /// Extracted due date (if found)
        var due: Date?

        /// Extracted defer date (if found)
        var defer: Date?

        /// Extracted effort estimate in minutes (if found)
        var effort: Int?
    }

    // MARK: - Main Parse Method

    /// Parses the input text and extracts task metadata
    /// - Parameter input: The raw input text
    /// - Returns: A ParseResult with extracted metadata and cleaned title
    static func parse(_ input: String) -> ParseResult {
        var result = ParseResult(title: input)
        var remainingText = input

        // Extract context (@word)
        if let context = extractContext(from: input) {
            result.context = context
            remainingText = remainingText.replacingOccurrences(
                of: "@\(context.dropFirst())",
                with: "",
                options: .caseInsensitive
            )
        }

        // Extract project (#word)
        if let project = extractProject(from: input) {
            result.project = project
            remainingText = remainingText.replacingOccurrences(
                of: "#\(project)",
                with: "",
                options: .caseInsensitive
            )
        }

        // Extract priority (!high, !medium, !low)
        if let priority = extractPriority(from: input) {
            result.priority = priority
            let pattern = "!\\w+"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                remainingText = regex.stringByReplacingMatches(
                    in: remainingText,
                    range: NSRange(remainingText.startIndex..., in: remainingText),
                    withTemplate: ""
                )
            }
        }

        // Extract due date (tomorrow, friday, nov 20, etc.)
        if let due = extractDueDate(from: input) {
            result.due = due
            // Remove common date phrases
            let datePatterns = [
                "tomorrow", "today", "monday", "tuesday", "wednesday",
                "thursday", "friday", "saturday", "sunday",
                "next week", "next month"
            ]
            for pattern in datePatterns {
                remainingText = remainingText.replacingOccurrences(
                    of: pattern,
                    with: "",
                    options: .caseInsensitive
                )
            }
        }

        // Extract defer date (^defer:tomorrow)
        if let deferDate = extractDeferDate(from: input) {
            result.defer = deferDate
            let pattern = "\\^defer:\\S+"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                remainingText = regex.stringByReplacingMatches(
                    in: remainingText,
                    range: NSRange(remainingText.startIndex..., in: remainingText),
                    withTemplate: ""
                )
            }
        }

        // Extract effort (//30m, //2h)
        if let effort = extractEffort(from: input) {
            result.effort = effort
            let pattern = "//\\d+[mh]?"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                remainingText = regex.stringByReplacingMatches(
                    in: remainingText,
                    range: NSRange(remainingText.startIndex..., in: remainingText),
                    withTemplate: ""
                )
            }
        }

        // Clean up the remaining text to get the title
        result.title = remainingText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return result
    }

    // MARK: - Context Extraction

    /// Extracts context from text (pattern: @word)
    private static func extractContext(from text: String) -> String? {
        let pattern = "@(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let context = String(text[range])
        return "@\(context)"
    }

    // MARK: - Project Extraction

    /// Extracts project from text (pattern: #word or #Multiple_Words)
    private static func extractProject(from text: String) -> String? {
        let pattern = "#([\\w\\s]+?)(?=\\s|$|@|!|//|\\^)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return String(text[range])
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "_", with: " ")
    }

    // MARK: - Priority Extraction

    /// Extracts priority from text (pattern: !high, !medium, !low)
    private static func extractPriority(from text: String) -> Priority? {
        let lowercaseText = text.lowercased()

        if lowercaseText.contains("!high") || lowercaseText.contains("!h") {
            return .high
        } else if lowercaseText.contains("!low") || lowercaseText.contains("!l") {
            return .low
        } else if lowercaseText.contains("!medium") || lowercaseText.contains("!m") {
            return .medium
        }

        return nil
    }

    // MARK: - Due Date Extraction

    /// Extracts due date from natural language (tomorrow, friday, nov 20, etc.)
    private static func extractDueDate(from text: String) -> Date? {
        let lowercaseText = text.lowercased()
        let calendar = Calendar.current
        let now = Date()

        // Today
        if lowercaseText.contains("today") {
            return calendar.startOfDay(for: now)
        }

        // Tomorrow
        if lowercaseText.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        }

        // Weekdays
        let weekdays = [
            "monday": 2,
            "tuesday": 3,
            "wednesday": 4,
            "thursday": 5,
            "friday": 6,
            "saturday": 7,
            "sunday": 1
        ]

        for (day, weekdayNum) in weekdays {
            if lowercaseText.contains(day) {
                return nextDate(for: weekdayNum, from: now)
            }
        }

        // Next week
        if lowercaseText.contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        }

        // Next month
        if lowercaseText.contains("next month") {
            return calendar.date(byAdding: .month, value: 1, to: now)
        }

        // Try to parse specific dates (basic implementation)
        // Format: "nov 20", "december 25", etc.
        if let specificDate = parseSpecificDate(from: text) {
            return specificDate
        }

        return nil
    }

    /// Finds the next occurrence of a weekday
    private static func nextDate(for weekday: Int, from date: Date) -> Date? {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: date)

        var daysToAdd = weekday - today
        if daysToAdd <= 0 {
            daysToAdd += 7
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: date))
    }

    /// Parses specific date formats (basic implementation)
    private static func parseSpecificDate(from text: String) -> Date? {
        // This is a simplified implementation
        // In production, you might want to use NSDataDetector or a more robust parser

        let pattern = "(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]* (\\d{1,2})"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ),
              let monthRange = Range(match.range(at: 1), in: text),
              let dayRange = Range(match.range(at: 2), in: text) else {
            return nil
        }

        let monthStr = String(text[monthRange]).lowercased()
        let dayStr = String(text[dayRange])

        guard let day = Int(dayStr) else { return nil }

        let months = ["jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
                      "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12]

        guard let month = months[monthStr] else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)

        var components = DateComponents()
        components.year = currentYear
        components.month = month
        components.day = day

        guard let date = calendar.date(from: components) else { return nil }

        // If the date is in the past, assume next year
        if date < now {
            components.year = currentYear + 1
            return calendar.date(from: components)
        }

        return date
    }

    // MARK: - Defer Date Extraction

    /// Extracts defer date from text (pattern: ^defer:tomorrow)
    private static func extractDeferDate(from text: String) -> Date? {
        let pattern = "\\^defer:(\\S+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let deferText = String(text[range])
        return extractDueDate(from: deferText)
    }

    // MARK: - Effort Extraction

    /// Extracts effort estimate from text (pattern: //30m, //2h)
    private static func extractEffort(from text: String) -> Int? {
        let pattern = "//(\\d+)([mh])?"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ),
              let numberRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let numberStr = String(text[numberRange])
        guard let number = Int(numberStr) else { return nil }

        // Check if it's hours or minutes
        if match.numberOfRanges > 2,
           let unitRange = Range(match.range(at: 2), in: text),
           !text[unitRange].isEmpty {
            let unit = String(text[unitRange])
            if unit == "h" {
                return number * 60 // Convert hours to minutes
            }
        }

        // Default to minutes
        return number
    }
}

// MARK: - Tests / Examples

#if DEBUG
extension NaturalLanguageParser {
    static func runTests() {
        print("Testing NaturalLanguageParser...")

        // Test 1: Full example
        let test1 = parse("Call John @phone #Website !high tomorrow //30m")
        assert(test1.title == "Call John")
        assert(test1.context == "@phone")
        assert(test1.project == "Website")
        assert(test1.priority == .high)
        assert(test1.effort == 30)
        print("✓ Test 1 passed")

        // Test 2: Multiple words project
        let test2 = parse("Review mockups #Website_Redesign @computer")
        assert(test2.title == "Review mockups")
        assert(test2.project == "Website Redesign")
        assert(test2.context == "@computer")
        print("✓ Test 2 passed")

        // Test 3: Effort in hours
        let test3 = parse("Write report //2h")
        assert(test3.title == "Write report")
        assert(test3.effort == 120)
        print("✓ Test 3 passed")

        // Test 4: No metadata
        let test4 = parse("Simple task")
        assert(test4.title == "Simple task")
        assert(test4.context == nil)
        assert(test4.project == nil)
        print("✓ Test 4 passed")

        print("All tests passed!")
    }
}
#endif
