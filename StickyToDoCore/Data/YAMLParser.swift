//
//  YAMLParser.swift
//  StickyToDo
//
//  YAML frontmatter parsing for markdown files.
//  Uses the Yams library to parse YAML and convert to/from Swift model objects.
//

import Foundation
import Yams

/// Errors that can occur during YAML parsing
public enum YAMLParseError: Error, LocalizedError {
    case invalidFormat(String)
    case missingFrontmatter
    case decodingError(Error)
    case encodingError(Error)
    case malformedYAML(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return "Invalid YAML format: \(message)"
        case .missingFrontmatter:
            return "No YAML frontmatter found in document"
        case .decodingError(let error):
            return "Failed to decode YAML: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode YAML: \(error.localizedDescription)"
        case .malformedYAML(let message):
            return "Malformed YAML: \(message)"
        }
    }
}

/// Parser for YAML frontmatter in markdown files
///
/// This parser handles the common pattern of markdown files with YAML frontmatter:
/// ```
/// ---
/// key: value
/// another: data
/// ---
///
/// Body content goes here...
/// ```
///
/// The parser extracts the frontmatter into a Swift Codable object and returns
/// the body content separately.
public struct YAMLParser {

    // MARK: - Configuration

    /// The delimiter used to separate frontmatter from body content
    private static let frontmatterDelimiter = "---"

    /// Logger for debugging YAML parsing issues
    private static var logger: ((String) -> Void)?

    /// Configure logging for YAML parsing operations
    /// - Parameter logger: A closure that receives log messages
    static func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    // MARK: - Parsing

    /// Parses YAML frontmatter from a markdown string
    ///
    /// This method extracts YAML frontmatter delimited by `---` markers and decodes it
    /// into the specified Codable type. The remaining content is returned as the body.
    ///
    /// Example markdown:
    /// ```
    /// ---
    /// title: "My Task"
    /// status: next-action
    /// ---
    ///
    /// This is the task description.
    /// ```
    ///
    /// - Parameter markdown: The complete markdown string with frontmatter
    /// - Returns: A tuple containing the decoded frontmatter object (or nil if parsing fails)
    ///            and the body content as a string
    /// - Throws: YAMLParseError if the format is invalid or decoding fails
    static func parseFrontmatter<T: Decodable>(_ markdown: String) -> (frontmatter: T?, body: String) {
        // Handle empty input
        guard !markdown.isEmpty else {
            logger?("Empty markdown input")
            return (nil, "")
        }

        // Check if the document starts with frontmatter delimiter
        guard markdown.hasPrefix(frontmatterDelimiter) else {
            logger?("No frontmatter delimiter found at start of document")
            return (nil, markdown)
        }

        // Split the markdown into lines
        let lines = markdown.components(separatedBy: .newlines)

        // Find the closing frontmatter delimiter (skip the first line which is the opening delimiter)
        var frontmatterEndIndex = -1
        for (index, line) in lines.enumerated() where index > 0 {
            if line.trimmingCharacters(in: .whitespaces) == frontmatterDelimiter {
                frontmatterEndIndex = index
                break
            }
        }

        // No closing delimiter found
        guard frontmatterEndIndex > 0 else {
            logger?("No closing frontmatter delimiter found")
            return (nil, markdown)
        }

        // Extract frontmatter content (between the two delimiters)
        let frontmatterLines = lines[1..<frontmatterEndIndex]
        let frontmatterYAML = frontmatterLines.joined(separator: "\n")

        // Extract body content (everything after the closing delimiter)
        let bodyLines = lines[(frontmatterEndIndex + 1)...]
        let body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse YAML frontmatter
        do {
            let decoder = YAMLDecoder()
            let frontmatter = try decoder.decode(T.self, from: frontmatterYAML)
            logger?("Successfully parsed frontmatter")
            return (frontmatter, body)
        } catch {
            logger?("Failed to decode frontmatter: \(error)")
            // Return body even if frontmatter parsing fails - graceful degradation
            return (nil, body)
        }
    }

    /// Parses YAML frontmatter from a markdown string, throwing on error
    ///
    /// Unlike `parseFrontmatter`, this method throws if parsing fails rather than
    /// returning nil. Use this when you need to know definitively if parsing succeeded.
    ///
    /// - Parameter markdown: The complete markdown string with frontmatter
    /// - Returns: A tuple containing the decoded frontmatter and body content
    /// - Throws: YAMLParseError if parsing or decoding fails
    static func parseFrontmatterStrict<T: Decodable>(_ markdown: String) throws -> (frontmatter: T, body: String) {
        // Handle empty input
        guard !markdown.isEmpty else {
            throw YAMLParseError.invalidFormat("Empty markdown input")
        }

        // Check if the document starts with frontmatter delimiter
        guard markdown.hasPrefix(frontmatterDelimiter) else {
            throw YAMLParseError.missingFrontmatter
        }

        // Split the markdown into lines
        let lines = markdown.components(separatedBy: .newlines)

        // Find the closing frontmatter delimiter
        var frontmatterEndIndex = -1
        for (index, line) in lines.enumerated() where index > 0 {
            if line.trimmingCharacters(in: .whitespaces) == frontmatterDelimiter {
                frontmatterEndIndex = index
                break
            }
        }

        // No closing delimiter found
        guard frontmatterEndIndex > 0 else {
            throw YAMLParseError.malformedYAML("No closing frontmatter delimiter found")
        }

        // Extract frontmatter content
        let frontmatterLines = lines[1..<frontmatterEndIndex]
        let frontmatterYAML = frontmatterLines.joined(separator: "\n")

        // Extract body content
        let bodyLines = lines[(frontmatterEndIndex + 1)...]
        let body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse YAML frontmatter
        do {
            let decoder = YAMLDecoder()
            let frontmatter = try decoder.decode(T.self, from: frontmatterYAML)
            logger?("Successfully parsed frontmatter (strict mode)")
            return (frontmatter, body)
        } catch {
            logger?("Failed to decode frontmatter (strict mode): \(error)")
            throw YAMLParseError.decodingError(error)
        }
    }

    // MARK: - Generation

    /// Generates a markdown string with YAML frontmatter
    ///
    /// This method encodes a Codable object as YAML frontmatter and combines it
    /// with body content to create a complete markdown document.
    ///
    /// - Parameters:
    ///   - object: The object to encode as YAML frontmatter
    ///   - body: The markdown body content
    /// - Returns: A complete markdown string with frontmatter
    /// - Throws: YAMLParseError if encoding fails
    static func generateFrontmatter<T: Encodable>(_ object: T, body: String) throws -> String {
        do {
            let encoder = YAMLEncoder()
            let yaml = try encoder.encode(object)

            // Ensure body doesn't start with extra newlines
            let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

            // Construct the markdown with frontmatter
            var markdown = frontmatterDelimiter + "\n"
            markdown += yaml

            // Ensure YAML ends with newline before delimiter
            if !yaml.hasSuffix("\n") {
                markdown += "\n"
            }

            markdown += frontmatterDelimiter + "\n"

            // Add body if not empty
            if !trimmedBody.isEmpty {
                markdown += "\n" + trimmedBody + "\n"
            }

            logger?("Successfully generated frontmatter")
            return markdown
        } catch {
            logger?("Failed to encode frontmatter: \(error)")
            throw YAMLParseError.encodingError(error)
        }
    }

    /// Generates a markdown string with YAML frontmatter, using a default body if encoding fails
    ///
    /// This is a graceful version of `generateFrontmatter` that returns a simple
    /// markdown document if YAML encoding fails.
    ///
    /// - Parameters:
    ///   - object: The object to encode as YAML frontmatter
    ///   - body: The markdown body content
    ///   - fallbackTitle: A title to use if encoding fails
    /// - Returns: A markdown string, either with frontmatter or just the body
    static func generateFrontmatterGracefully<T: Encodable>(
        _ object: T,
        body: String,
        fallbackTitle: String = "Untitled"
    ) -> String {
        do {
            return try generateFrontmatter(object, body: body)
        } catch {
            logger?("Graceful fallback: encoding failed, returning body only")
            // Return a simple markdown document without frontmatter
            return "# \(fallbackTitle)\n\n\(body)\n"
        }
    }

    // MARK: - Validation

    /// Checks if a markdown string contains valid YAML frontmatter
    ///
    /// - Parameter markdown: The markdown string to check
    /// - Returns: True if the string contains properly delimited frontmatter
    static func hasFrontmatter(_ markdown: String) -> Bool {
        guard markdown.hasPrefix(frontmatterDelimiter) else {
            return false
        }

        let lines = markdown.components(separatedBy: .newlines)

        // Look for closing delimiter
        for (index, line) in lines.enumerated() where index > 0 {
            if line.trimmingCharacters(in: .whitespaces) == frontmatterDelimiter {
                return true
            }
        }

        return false
    }

    /// Extracts just the raw YAML string from frontmatter
    ///
    /// - Parameter markdown: The markdown string with frontmatter
    /// - Returns: The raw YAML string, or nil if no frontmatter found
    static func extractRawYAML(_ markdown: String) -> String? {
        guard markdown.hasPrefix(frontmatterDelimiter) else {
            return nil
        }

        let lines = markdown.components(separatedBy: .newlines)

        var frontmatterEndIndex = -1
        for (index, line) in lines.enumerated() where index > 0 {
            if line.trimmingCharacters(in: .whitespaces) == frontmatterDelimiter {
                frontmatterEndIndex = index
                break
            }
        }

        guard frontmatterEndIndex > 0 else {
            return nil
        }

        let frontmatterLines = lines[1..<frontmatterEndIndex]
        return frontmatterLines.joined(separator: "\n")
    }
}

// MARK: - Convenience Extensions

extension YAMLParser {
    /// Parses a Task from markdown with frontmatter
    static func parseTask(_ markdown: String) -> (task: Task?, body: String) {
        return parseFrontmatter(markdown)
    }

    /// Parses a Board from markdown with frontmatter
    static func parseBoard(_ markdown: String) -> (board: Board?, body: String) {
        return parseFrontmatter(markdown)
    }

    /// Generates markdown for a Task
    static func generateTask(_ task: Task, body: String) throws -> String {
        return try generateFrontmatter(task, body: body)
    }

    /// Generates markdown for a Board
    static func generateBoard(_ board: Board, body: String) throws -> String {
        return try generateFrontmatter(board, body: body)
    }

    /// Parses an array of Rules from YAML (without markdown frontmatter)
    static func parseRules(_ yamlString: String) -> [Rule] {
        do {
            let decoder = YAMLDecoder()
            let rules = try decoder.decode([Rule].self, from: yamlString)
            logger?("Successfully parsed \(rules.count) rules")
            return rules
        } catch {
            logger?("Failed to parse rules: \(error)")
            return []
        }
    }

    /// Generates YAML for an array of Rules (without markdown)
    static func generateRules(_ rules: [Rule]) throws -> String {
        do {
            let encoder = YAMLEncoder()
            let yaml = try encoder.encode(rules)
            logger?("Successfully generated YAML for \(rules.count) rules")
            return yaml
        } catch {
            logger?("Failed to generate rules YAML: \(error)")
            throw YAMLParseError.encodingError(error)
        }
    }

    /// Parses a TimeEntry from markdown with frontmatter
    static func parseTimeEntry(_ markdown: String) -> (entry: TimeEntry?, body: String) {
        return parseFrontmatter(markdown)
    }

    /// Generates markdown for a TimeEntry
    static func generateTimeEntry(_ entry: TimeEntry, body: String) throws -> String {
        return try generateFrontmatter(entry, body: body)
    }
}
