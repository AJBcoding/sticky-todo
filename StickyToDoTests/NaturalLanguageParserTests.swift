//
//  NaturalLanguageParserTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for natural language parsing.
//

import XCTest
@testable import StickyToDo

final class NaturalLanguageParserTests: XCTestCase {

    // MARK: - Context Extraction Tests

    func testExtractContext() {
        let result = NaturalLanguageParser.parse("Call John @phone")

        XCTAssertEqual(result.context, "@phone")
        XCTAssertEqual(result.title, "Call John")
    }

    func testExtractMultipleContextsUsesFirst() {
        let result = NaturalLanguageParser.parse("Task @office @home")

        XCTAssertEqual(result.context, "@office")
        XCTAssertFalse(result.title.contains("@office"))
    }

    func testNoContext() {
        let result = NaturalLanguageParser.parse("Simple task")

        XCTAssertNil(result.context)
        XCTAssertEqual(result.title, "Simple task")
    }

    // MARK: - Project Extraction Tests

    func testExtractProject() {
        let result = NaturalLanguageParser.parse("Review mockups #Website")

        XCTAssertEqual(result.project, "Website")
        XCTAssertEqual(result.title, "Review mockups")
    }

    func testExtractMultiWordProject() {
        let result = NaturalLanguageParser.parse("Create wireframes #Website_Redesign")

        XCTAssertEqual(result.project, "Website Redesign")
        XCTAssertEqual(result.title, "Create wireframes")
    }

    func testExtractProjectWithSpaces() {
        let result = NaturalLanguageParser.parse("Task #Project Name @office")

        XCTAssertEqual(result.project, "Project Name")
        XCTAssertEqual(result.context, "@office")
    }

    // MARK: - Priority Extraction Tests

    func testExtractHighPriority() {
        let result1 = NaturalLanguageParser.parse("Urgent task !high")
        XCTAssertEqual(result1.priority, .high)

        let result2 = NaturalLanguageParser.parse("Urgent task !h")
        XCTAssertEqual(result2.priority, .high)
    }

    func testExtractMediumPriority() {
        let result1 = NaturalLanguageParser.parse("Normal task !medium")
        XCTAssertEqual(result1.priority, .medium)

        let result2 = NaturalLanguageParser.parse("Normal task !m")
        XCTAssertEqual(result2.priority, .medium)
    }

    func testExtractLowPriority() {
        let result1 = NaturalLanguageParser.parse("Later task !low")
        XCTAssertEqual(result1.priority, .low)

        let result2 = NaturalLanguageParser.parse("Later task !l")
        XCTAssertEqual(result2.priority, .low)
    }

    // MARK: - Due Date Extraction Tests

    func testExtractToday() {
        let result = NaturalLanguageParser.parse("Task due today")

        XCTAssertNotNil(result.due)
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDateInToday(result.due!))
    }

    func testExtractTomorrow() {
        let result = NaturalLanguageParser.parse("Task due tomorrow")

        XCTAssertNotNil(result.due)
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDateInTomorrow(result.due!))
    }

    func testExtractWeekday() {
        let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

        for day in weekdays {
            let result = NaturalLanguageParser.parse("Task due \(day)")
            XCTAssertNotNil(result.due, "Failed to parse: \(day)")
        }
    }

    func testExtractNextWeek() {
        let result = NaturalLanguageParser.parse("Task due next week")

        XCTAssertNotNil(result.due)
        // Should be roughly 7 days from now
        let daysDifference = Calendar.current.dateComponents([.day], from: Date(), to: result.due!).day
        XCTAssertEqual(daysDifference, 7, accuracy: 1)
    }

    func testExtractNextMonth() {
        let result = NaturalLanguageParser.parse("Task due next month")

        XCTAssertNotNil(result.due)
        // Should be roughly 30 days from now
        let daysDifference = Calendar.current.dateComponents([.day], from: Date(), to: result.due!).day
        XCTAssertGreaterThan(daysDifference ?? 0, 25)
    }

    func testExtractSpecificDate() {
        let result = NaturalLanguageParser.parse("Task due Nov 20")

        XCTAssertNotNil(result.due)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: result.due!)
        XCTAssertEqual(components.month, 11)
        XCTAssertEqual(components.day, 20)
    }

    // MARK: - Defer Date Extraction Tests

    func testExtractDeferDate() {
        let result = NaturalLanguageParser.parse("Task ^defer:tomorrow")

        XCTAssertNotNil(result.defer)
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDateInTomorrow(result.defer!))
    }

    func testExtractDeferDateWithWeekday() {
        let result = NaturalLanguageParser.parse("Task ^defer:friday")

        XCTAssertNotNil(result.defer)
    }

    // MARK: - Effort Extraction Tests

    func testExtractEffortInMinutes() {
        let result = NaturalLanguageParser.parse("Task //30m")

        XCTAssertEqual(result.effort, 30)
        XCTAssertEqual(result.title, "Task")
    }

    func testExtractEffortInHours() {
        let result = NaturalLanguageParser.parse("Task //2h")

        XCTAssertEqual(result.effort, 120)
        XCTAssertEqual(result.title, "Task")
    }

    func testExtractEffortDefaultMinutes() {
        let result = NaturalLanguageParser.parse("Task //45")

        XCTAssertEqual(result.effort, 45)
    }

    // MARK: - Combined Pattern Tests

    func testFullExample() {
        let result = NaturalLanguageParser.parse("Call John @phone #Website !high tomorrow //30m")

        XCTAssertEqual(result.title, "Call John")
        XCTAssertEqual(result.context, "@phone")
        XCTAssertEqual(result.project, "Website")
        XCTAssertEqual(result.priority, .high)
        XCTAssertNotNil(result.due)
        XCTAssertEqual(result.effort, 30)
    }

    func testComplexProjectName() {
        let result = NaturalLanguageParser.parse("Review mockups #Website_Redesign @computer !high")

        XCTAssertEqual(result.title, "Review mockups")
        XCTAssertEqual(result.project, "Website Redesign")
        XCTAssertEqual(result.context, "@computer")
        XCTAssertEqual(result.priority, .high)
    }

    func testMultipleMetadata() {
        let result = NaturalLanguageParser.parse("Important task @office #Q4Planning !high tomorrow //2h")

        XCTAssertEqual(result.title, "Important task")
        XCTAssertEqual(result.context, "@office")
        XCTAssertEqual(result.project, "Q4Planning")
        XCTAssertEqual(result.priority, .high)
        XCTAssertNotNil(result.due)
        XCTAssertEqual(result.effort, 120)
    }

    // MARK: - Edge Cases

    func testPlainText() {
        let result = NaturalLanguageParser.parse("Just a plain task")

        XCTAssertEqual(result.title, "Just a plain task")
        XCTAssertNil(result.context)
        XCTAssertNil(result.project)
        XCTAssertNil(result.priority)
        XCTAssertNil(result.due)
        XCTAssertNil(result.effort)
    }

    func testEmptyString() {
        let result = NaturalLanguageParser.parse("")

        XCTAssertEqual(result.title, "")
    }

    func testOnlyMetadata() {
        let result = NaturalLanguageParser.parse("@office #Project !high")

        XCTAssertEqual(result.context, "@office")
        XCTAssertEqual(result.project, "Project")
        XCTAssertEqual(result.priority, .high)
        // Title should be empty or minimal after metadata removal
        XCTAssertTrue(result.title.isEmpty || result.title.count < 5)
    }

    func testMultipleSpaces() {
        let result = NaturalLanguageParser.parse("Task    with    spaces   @office")

        XCTAssertEqual(result.title, "Task with spaces")
        XCTAssertEqual(result.context, "@office")
    }

    func testSpecialCharacters() {
        let result = NaturalLanguageParser.parse("Buy café supplies! @errands #Shopping")

        XCTAssertTrue(result.title.contains("café"))
        XCTAssertEqual(result.context, "@errands")
        XCTAssertEqual(result.project, "Shopping")
    }

    // MARK: - Whitespace Handling Tests

    func testLeadingTrailingWhitespace() {
        let result = NaturalLanguageParser.parse("  Task with whitespace  @office  ")

        XCTAssertEqual(result.title, "Task with whitespace")
        XCTAssertEqual(result.context, "@office")
    }

    func testNewlinesInInput() {
        let result = NaturalLanguageParser.parse("Task\nwith\nnewlines @office")

        XCTAssertTrue(result.title.contains("Task"))
        XCTAssertEqual(result.context, "@office")
    }

    // MARK: - Priority Case Sensitivity Tests

    func testPriorityCaseInsensitive() {
        let result1 = NaturalLanguageParser.parse("Task !HIGH")
        XCTAssertEqual(result1.priority, .high)

        let result2 = NaturalLanguageParser.parse("Task !High")
        XCTAssertEqual(result2.priority, .high)

        let result3 = NaturalLanguageParser.parse("Task !low")
        XCTAssertEqual(result3.priority, .low)
    }

    // MARK: - Real World Examples

    func testRealWorldExample1() {
        let result = NaturalLanguageParser.parse("Send proposal to client @computer #ProjectAlpha !high friday //1h")

        XCTAssertEqual(result.title, "Send proposal to client")
        XCTAssertEqual(result.context, "@computer")
        XCTAssertEqual(result.project, "ProjectAlpha")
        XCTAssertEqual(result.priority, .high)
        XCTAssertNotNil(result.due)
        XCTAssertEqual(result.effort, 60)
    }

    func testRealWorldExample2() {
        let result = NaturalLanguageParser.parse("Buy groceries @errands #PersonalLife !low tomorrow //30m")

        XCTAssertEqual(result.title, "Buy groceries")
        XCTAssertEqual(result.context, "@errands")
        XCTAssertEqual(result.project, "PersonalLife")
        XCTAssertEqual(result.priority, .low)
        XCTAssertNotNil(result.due)
        XCTAssertEqual(result.effort, 30)
    }

    func testRealWorldExample3() {
        let result = NaturalLanguageParser.parse("Review pull request #OpenSource @computer //15m")

        XCTAssertEqual(result.title, "Review pull request")
        XCTAssertEqual(result.project, "OpenSource")
        XCTAssertEqual(result.context, "@computer")
        XCTAssertEqual(result.effort, 15)
    }

    // MARK: - Malformed Input Tests

    func testIncompleteMetadata() {
        let result = NaturalLanguageParser.parse("Task @ # !")

        // Should handle gracefully
        XCTAssertNotNil(result.title)
    }

    func testMetadataAtEnd() {
        let result = NaturalLanguageParser.parse("Complete task @office")

        XCTAssertEqual(result.title, "Complete task")
        XCTAssertEqual(result.context, "@office")
    }

    func testMetadataAtStart() {
        let result = NaturalLanguageParser.parse("@office Complete task")

        XCTAssertEqual(result.context, "@office")
        XCTAssertTrue(result.title.contains("Complete task"))
    }

    func testMetadataInMiddle() {
        let result = NaturalLanguageParser.parse("Complete @office task today")

        XCTAssertEqual(result.context, "@office")
        XCTAssertTrue(result.title.contains("Complete"))
        XCTAssertTrue(result.title.contains("task"))
    }
}
