//
//  YAMLParserTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for YAML frontmatter parsing.
//

import XCTest
@testable import StickyToDo

final class YAMLParserTests: XCTestCase {

    // MARK: - Basic Parsing Tests

    func testParseValidFrontmatter() throws {
        let markdown = """
        ---
        id: 12345678-1234-1234-1234-123456789012
        type: task
        title: Test Task
        status: inbox
        flagged: false
        priority: medium
        ---

        This is the body content.
        """

        struct TestFrontmatter: Codable {
            let id: String
            let type: String
            let title: String
            let status: String
            let flagged: Bool
            let priority: String
        }

        let (frontmatter, body): (TestFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        XCTAssertNotNil(frontmatter)
        XCTAssertEqual(frontmatter?.title, "Test Task")
        XCTAssertEqual(frontmatter?.status, "inbox")
        XCTAssertEqual(frontmatter?.flagged, false)
        XCTAssertEqual(body, "This is the body content.")
    }

    func testParseFrontmatterWithoutBody() {
        let markdown = """
        ---
        title: Task Without Body
        status: inbox
        ---
        """

        struct SimpleFrontmatter: Codable {
            let title: String
            let status: String
        }

        let (frontmatter, body): (SimpleFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        XCTAssertNotNil(frontmatter)
        XCTAssertEqual(frontmatter?.title, "Task Without Body")
        XCTAssertEqual(body, "")
    }

    func testParseMarkdownWithoutFrontmatter() {
        let markdown = "Just some plain markdown without frontmatter."

        struct AnyFrontmatter: Codable {
            let title: String?
        }

        let (frontmatter, body): (AnyFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        XCTAssertNil(frontmatter)
        XCTAssertEqual(body, markdown)
    }

    func testParseEmptyMarkdown() {
        let markdown = ""

        struct AnyFrontmatter: Codable {
            let title: String?
        }

        let (frontmatter, body): (AnyFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        XCTAssertNil(frontmatter)
        XCTAssertEqual(body, "")
    }

    func testParseMalformedFrontmatter() {
        let markdown = """
        ---
        This is not valid YAML
        random: content: with: colons
        ---

        Body content.
        """

        struct AnyFrontmatter: Codable {
            let title: String?
        }

        let (frontmatter, body): (AnyFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        // Should gracefully handle malformed YAML
        XCTAssertNil(frontmatter)
        XCTAssertEqual(body, "Body content.")
    }

    func testParseUnclosedFrontmatter() {
        let markdown = """
        ---
        title: Unclosed
        status: inbox

        This should be treated as body since there's no closing delimiter.
        """

        struct AnyFrontmatter: Codable {
            let title: String?
        }

        let (frontmatter, body): (AnyFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        XCTAssertNil(frontmatter)
        XCTAssertEqual(body, markdown)
    }

    func testParseComplexYAML() {
        let markdown = """
        ---
        id: 12345678-1234-1234-1234-123456789012
        title: Complex Task
        tags:
          - urgent
          - review
        metadata:
          created: 2023-01-01
          priority: high
        positions:
          board-1:
            x: 100
            y: 200
        ---

        Complex body with multiple lines.
        And some more content.
        """

        struct ComplexFrontmatter: Codable {
            let id: String
            let title: String
            let tags: [String]?
        }

        let (frontmatter, body): (ComplexFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        XCTAssertNotNil(frontmatter)
        XCTAssertEqual(frontmatter?.title, "Complex Task")
        XCTAssertEqual(frontmatter?.tags?.count, 2)
        XCTAssertTrue(body.contains("Complex body"))
    }

    // MARK: - Strict Parsing Tests

    func testStrictParseValidFrontmatter() throws {
        let markdown = """
        ---
        title: Strict Test
        status: inbox
        ---

        Body content.
        """

        struct StrictFrontmatter: Codable {
            let title: String
            let status: String
        }

        let (frontmatter, body) = try YAMLParser.parseFrontmatterStrict(markdown) as (StrictFrontmatter, String)

        XCTAssertEqual(frontmatter.title, "Strict Test")
        XCTAssertEqual(frontmatter.status, "inbox")
        XCTAssertEqual(body, "Body content.")
    }

    func testStrictParseThrowsOnEmptyInput() {
        let markdown = ""

        struct AnyFrontmatter: Codable {}

        XCTAssertThrowsError(try YAMLParser.parseFrontmatterStrict(markdown) as (AnyFrontmatter, String)) { error in
            XCTAssertTrue(error is YAMLParseError)
        }
    }

    func testStrictParseThrowsOnMissingFrontmatter() {
        let markdown = "No frontmatter here"

        struct AnyFrontmatter: Codable {}

        XCTAssertThrowsError(try YAMLParser.parseFrontmatterStrict(markdown) as (AnyFrontmatter, String)) { error in
            XCTAssertTrue(error is YAMLParseError)
        }
    }

    func testStrictParseThrowsOnUnclosedFrontmatter() {
        let markdown = """
        ---
        title: Unclosed
        """

        struct AnyFrontmatter: Codable {}

        XCTAssertThrowsError(try YAMLParser.parseFrontmatterStrict(markdown) as (AnyFrontmatter, String)) { error in
            XCTAssertTrue(error is YAMLParseError)
        }
    }

    // MARK: - Generation Tests

    func testGenerateFrontmatter() throws {
        struct TestData: Codable {
            let title: String
            let status: String
            let flagged: Bool
        }

        let data = TestData(title: "Generated Task", status: "inbox", flagged: true)
        let body = "Generated body content."

        let markdown = try YAMLParser.generateFrontmatter(data, body: body)

        XCTAssertTrue(markdown.hasPrefix("---\n"))
        XCTAssertTrue(markdown.contains("title:"))
        XCTAssertTrue(markdown.contains("Generated Task"))
        XCTAssertTrue(markdown.contains("status:"))
        XCTAssertTrue(markdown.contains("inbox"))
        XCTAssertTrue(markdown.contains("flagged:"))
        XCTAssertTrue(markdown.contains("Generated body content."))
    }

    func testGenerateFrontmatterWithEmptyBody() throws {
        struct TestData: Codable {
            let title: String
        }

        let data = TestData(title: "No Body Task")
        let markdown = try YAMLParser.generateFrontmatter(data, body: "")

        XCTAssertTrue(markdown.hasPrefix("---\n"))
        XCTAssertTrue(markdown.contains("title:"))
        XCTAssertTrue(markdown.contains("No Body Task"))
    }

    func testGenerateFrontmatterWithComplexData() throws {
        struct ComplexData: Codable {
            let title: String
            let tags: [String]
            let nested: NestedData
        }

        struct NestedData: Codable {
            let priority: String
            let value: Int
        }

        let data = ComplexData(
            title: "Complex",
            tags: ["tag1", "tag2"],
            nested: NestedData(priority: "high", value: 42)
        )

        let markdown = try YAMLParser.generateFrontmatter(data, body: "Complex body")

        XCTAssertTrue(markdown.hasPrefix("---\n"))
        XCTAssertTrue(markdown.contains("title:"))
        XCTAssertTrue(markdown.contains("Complex"))
        XCTAssertTrue(markdown.contains("tags:"))
        XCTAssertTrue(markdown.contains("nested:"))
        XCTAssertTrue(markdown.contains("Complex body"))
    }

    // MARK: - Round-Trip Tests

    func testRoundTripSimpleData() throws {
        struct SimpleData: Codable, Equatable {
            let title: String
            let status: String
            let priority: String
        }

        let original = SimpleData(title: "Round Trip", status: "inbox", priority: "high")
        let originalBody = "Original body content."

        // Generate markdown
        let markdown = try YAMLParser.generateFrontmatter(original, body: originalBody)

        // Parse it back
        let (parsed, parsedBody): (SimpleData?, String) = YAMLParser.parseFrontmatter(markdown)

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed, original)
        XCTAssertEqual(parsedBody, originalBody)
    }

    func testRoundTripTask() throws {
        let original = Task(
            title: "Round Trip Task",
            notes: "These are my notes.",
            status: .nextAction,
            project: "TestProject",
            context: "@office",
            flagged: true,
            priority: .high,
            effort: 60
        )

        // Generate markdown
        let markdown = try YAMLParser.generateTask(original, body: original.notes)

        // Parse it back
        let (parsed, parsedBody) = YAMLParser.parseTask(markdown)

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.title, original.title)
        XCTAssertEqual(parsed?.status, original.status)
        XCTAssertEqual(parsed?.project, original.project)
        XCTAssertEqual(parsed?.context, original.context)
        XCTAssertEqual(parsed?.flagged, original.flagged)
        XCTAssertEqual(parsed?.priority, original.priority)
        XCTAssertEqual(parsed?.effort, original.effort)
        XCTAssertEqual(parsedBody, original.notes)
    }

    func testRoundTripBoard() throws {
        let original = Board(
            id: "test-board",
            type: .project,
            layout: .kanban,
            filter: Filter(project: "TestProject"),
            columns: ["Todo", "In Progress", "Done"],
            title: "Test Board",
            notes: "Board notes go here."
        )

        // Generate markdown
        let markdown = try YAMLParser.generateBoard(original, body: original.notes ?? "")

        // Parse it back
        let (parsed, parsedBody) = YAMLParser.parseBoard(markdown)

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.id, original.id)
        XCTAssertEqual(parsed?.type, original.type)
        XCTAssertEqual(parsed?.layout, original.layout)
        XCTAssertEqual(parsed?.columns, original.columns)
        XCTAssertEqual(parsed?.title, original.title)
        XCTAssertEqual(parsedBody, original.notes)
    }

    // MARK: - Unicode and Special Characters Tests

    func testParseUnicodeContent() {
        let markdown = """
        ---
        title: "Test with émojis 🚀 and unicode ñ"
        notes: "Special characters: «quotes» and —dashes—"
        ---

        Body with 中文, العربية, and emoji 🎉
        """

        struct UnicodeFrontmatter: Codable {
            let title: String
            let notes: String
        }

        let (frontmatter, body): (UnicodeFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        XCTAssertNotNil(frontmatter)
        XCTAssertTrue(frontmatter?.title.contains("🚀") ?? false)
        XCTAssertTrue(frontmatter?.title.contains("ñ") ?? false)
        XCTAssertTrue(body.contains("中文"))
        XCTAssertTrue(body.contains("🎉"))
    }

    func testGenerateUnicodeContent() throws {
        struct UnicodeData: Codable {
            let title: String
            let emoji: String
        }

        let data = UnicodeData(title: "Unicode Test 日本語", emoji: "🎨")
        let body = "Body with special chars: café, naïve, 🚀"

        let markdown = try YAMLParser.generateFrontmatter(data, body: body)

        XCTAssertTrue(markdown.contains("日本語"))
        XCTAssertTrue(markdown.contains("🎨"))
        XCTAssertTrue(markdown.contains("café"))
        XCTAssertTrue(markdown.contains("🚀"))
    }

    // MARK: - Edge Cases

    func testParseEmptyFrontmatter() {
        let markdown = """
        ---
        ---

        Just body content.
        """

        struct AnyFrontmatter: Codable {
            let title: String?
        }

        let (frontmatter, body): (AnyFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        // Empty frontmatter should still parse
        XCTAssertEqual(body, "Just body content.")
    }

    func testParseWhitespaceAroundDelimiters() {
        let markdown = """
           ---
        title: Whitespace Test
           ---

        Body content.
        """

        struct WhitespaceFrontmatter: Codable {
            let title: String
        }

        let (frontmatter, body): (WhitespaceFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        // Should handle whitespace around delimiters
        XCTAssertNotNil(frontmatter)
        XCTAssertEqual(frontmatter?.title, "Whitespace Test")
    }

    func testParseMultilineFrontmatter() {
        let markdown = """
        ---
        title: Multiline Task
        description: |
          This is a multiline
          description that spans
          multiple lines.
        ---

        Body.
        """

        struct MultilineFrontmatter: Codable {
            let title: String
            let description: String
        }

        let (frontmatter, body): (MultilineFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        XCTAssertNotNil(frontmatter)
        XCTAssertEqual(frontmatter?.title, "Multiline Task")
        XCTAssertTrue(frontmatter?.description.contains("multiple lines") ?? false)
    }

    func testParseBodyWithDashes() {
        let markdown = """
        ---
        title: Test
        ---

        This body has --- dashes in it.
        And another --- line.
        """

        struct SimpleFrontmatter: Codable {
            let title: String
        }

        let (frontmatter, body): (SimpleFrontmatter?, String) = YAMLParser.parseFrontmatter(markdown)

        XCTAssertNotNil(frontmatter)
        XCTAssertTrue(body.contains("--- dashes"))
        XCTAssertTrue(body.contains("--- line"))
    }

    // MARK: - Validation Tests

    func testHasFrontmatter() {
        let withFrontmatter = """
        ---
        title: Test
        ---
        """
        XCTAssertTrue(YAMLParser.hasFrontmatter(withFrontmatter))

        let withoutFrontmatter = "Just plain text"
        XCTAssertFalse(YAMLParser.hasFrontmatter(withoutFrontmatter))

        let incomplete = """
        ---
        title: Incomplete
        """
        XCTAssertFalse(YAMLParser.hasFrontmatter(incomplete))

        let empty = ""
        XCTAssertFalse(YAMLParser.hasFrontmatter(empty))
    }

    func testExtractRawYAML() {
        let markdown = """
        ---
        title: Test Task
        status: inbox
        priority: high
        ---

        Body content.
        """

        let rawYAML = YAMLParser.extractRawYAML(markdown)

        XCTAssertNotNil(rawYAML)
        XCTAssertTrue(rawYAML?.contains("title: Test Task") ?? false)
        XCTAssertTrue(rawYAML?.contains("status: inbox") ?? false)
        XCTAssertTrue(rawYAML?.contains("priority: high") ?? false)
        XCTAssertFalse(rawYAML?.contains("---") ?? true)
        XCTAssertFalse(rawYAML?.contains("Body content") ?? true)
    }

    func testExtractRawYAMLWithoutFrontmatter() {
        let markdown = "No frontmatter"
        let rawYAML = YAMLParser.extractRawYAML(markdown)

        XCTAssertNil(rawYAML)
    }

    // MARK: - Error Handling Tests

    func testErrorDescriptions() {
        let invalidFormat = YAMLParseError.invalidFormat("test message")
        XCTAssertNotNil(invalidFormat.errorDescription)
        XCTAssertTrue(invalidFormat.errorDescription?.contains("test message") ?? false)

        let missingFrontmatter = YAMLParseError.missingFrontmatter
        XCTAssertNotNil(missingFrontmatter.errorDescription)

        let malformedYAML = YAMLParseError.malformedYAML("syntax error")
        XCTAssertNotNil(malformedYAML.errorDescription)
        XCTAssertTrue(malformedYAML.errorDescription?.contains("syntax error") ?? false)
    }
}
