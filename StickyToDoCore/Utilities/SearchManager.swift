//
//  SearchManager.swift
//  StickyToDo
//
//  Full-text search manager with highlighting and relevance ranking.
//

import Foundation

/// Manages full-text search across tasks with ranking and highlighting
public class SearchManager {

    // MARK: - Search Configuration

    /// Maximum number of recent searches to store
    public static let maxRecentSearches = 20

    /// Fields to search across with their weights for relevance ranking
    private static let searchableFields: [(keyPath: KeyPath<Task, String?>, weight: Double, name: String)] = [
        (\.title, 10.0, "title"),
        (\.project, 5.0, "project"),
        (\.context, 3.0, "context"),
        (\.notes, 1.0, "notes")
    ]

    // MARK: - Search Query Parsing

    /// Parses a search query string into a SearchQuery object
    /// Supports: AND, OR, NOT, quotes for exact match
    /// Examples:
    /// - "urgent task" -> SearchQuery with AND terms
    /// - "bug OR feature" -> SearchQuery with OR operator
    /// - "project NOT archived" -> SearchQuery with NOT operator
    /// - "\"exact phrase\"" -> SearchQuery with exact match
    public static func parseQuery(_ queryString: String) -> SearchQuery {
        var terms: [SearchTerm] = []
        var currentTerm = ""
        var inQuotes = false
        var operator: SearchOperator = .and
        var negated = false

        let chars = Array(queryString)
        var i = 0

        while i < chars.count {
            let char = chars[i]

            if char == "\"" {
                if inQuotes {
                    // End of quoted phrase
                    if !currentTerm.isEmpty {
                        terms.append(SearchTerm(text: currentTerm, exact: true, negated: negated))
                        currentTerm = ""
                        negated = false
                    }
                    inQuotes = false
                } else {
                    // Start of quoted phrase
                    if !currentTerm.isEmpty {
                        terms.append(SearchTerm(text: currentTerm, exact: false, negated: negated))
                        currentTerm = ""
                        negated = false
                    }
                    inQuotes = true
                }
            } else if !inQuotes && char.isWhitespace {
                if !currentTerm.isEmpty {
                    // Check for operators
                    let upperTerm = currentTerm.uppercased()
                    if upperTerm == "AND" {
                        operator = .and
                    } else if upperTerm == "OR" {
                        operator = .or
                    } else if upperTerm == "NOT" {
                        negated = true
                    } else {
                        terms.append(SearchTerm(text: currentTerm, exact: false, negated: negated))
                        negated = false
                    }
                    currentTerm = ""
                }
            } else {
                currentTerm.append(char)
            }

            i += 1
        }

        // Add any remaining term
        if !currentTerm.isEmpty {
            terms.append(SearchTerm(text: currentTerm, exact: inQuotes, negated: negated))
        }

        // If no terms, return empty query
        if terms.isEmpty {
            return SearchQuery(terms: [], operator: .and)
        }

        return SearchQuery(terms: terms, operator: operator)
    }

    // MARK: - Search Execution

    /// Searches tasks with the given query and returns ranked results with highlighting
    public static func search(tasks: [Task], query: SearchQuery) -> [SearchResult] {
        var results: [SearchResult] = []

        for task in tasks {
            if let result = matchTask(task, query: query) {
                results.append(result)
            }
        }

        // Sort by relevance score (descending)
        results.sort { $0.relevanceScore > $1.relevanceScore }

        return results
    }

    /// Searches tasks with a simple string query
    public static func search(tasks: [Task], queryString: String) -> [SearchResult] {
        let query = parseQuery(queryString)
        return search(tasks: tasks, query: query)
    }

    // MARK: - Task Matching

    /// Matches a single task against a query
    private static func matchTask(_ task: Task, query: SearchQuery) -> SearchResult? {
        var totalScore: Double = 0
        var highlights: [SearchHighlight] = []
        var fieldMatches: [String: Bool] = [:]

        // Search in title
        if let titleScore = matchField(
            text: task.title,
            query: query,
            weight: 10.0,
            fieldName: "title",
            highlights: &highlights
        ) {
            totalScore += titleScore
            fieldMatches["title"] = true
        }

        // Search in project
        if let project = task.project,
           let projectScore = matchField(
               text: project,
               query: query,
               weight: 5.0,
               fieldName: "project",
               highlights: &highlights
           ) {
            totalScore += projectScore
            fieldMatches["project"] = true
        }

        // Search in context
        if let context = task.context,
           let contextScore = matchField(
               text: context,
               query: query,
               weight: 3.0,
               fieldName: "context",
               highlights: &highlights
           ) {
            totalScore += contextScore
            fieldMatches["context"] = true
        }

        // Search in notes
        if let notesScore = matchField(
            text: task.notes,
            query: query,
            weight: 1.0,
            fieldName: "notes",
            highlights: &highlights
        ) {
            totalScore += notesScore
            fieldMatches["notes"] = true
        }

        // Search in tags
        let tagNames = task.tags.map { $0.name }.joined(separator: " ")
        if !tagNames.isEmpty,
           let tagsScore = matchField(
               text: tagNames,
               query: query,
               weight: 4.0,
               fieldName: "tags",
               highlights: &highlights
           ) {
            totalScore += tagsScore
            fieldMatches["tags"] = true
        }

        // If no matches found, return nil
        if totalScore == 0 {
            return nil
        }

        // Apply boosting based on task properties
        totalScore = applyBoostFactors(score: totalScore, task: task)

        return SearchResult(
            task: task,
            relevanceScore: totalScore,
            highlights: highlights,
            matchedFields: fieldMatches
        )
    }

    /// Matches a field against the query
    private static func matchField(
        text: String,
        query: SearchQuery,
        weight: Double,
        fieldName: String,
        highlights: inout [SearchHighlight]
    ) -> Double? {
        var score: Double = 0
        let lowercaseText = text.lowercased()
        var hasMatch = false

        for term in query.terms {
            let lowercaseTerm = term.text.lowercased()

            if term.exact {
                // Exact match
                if let range = lowercaseText.range(of: lowercaseTerm) {
                    if term.negated {
                        return nil // Negated match means no result
                    }
                    hasMatch = true
                    score += weight * 2.0 // Exact matches get double weight

                    // Add highlight
                    let startIndex = text.distance(from: text.startIndex, to: range.lowerBound)
                    let length = lowercaseTerm.count
                    highlights.append(SearchHighlight(
                        fieldName: fieldName,
                        range: NSRange(location: startIndex, length: length),
                        matchedText: String(text[range])
                    ))
                }
            } else {
                // Fuzzy match - contains
                if lowercaseText.contains(lowercaseTerm) {
                    if term.negated {
                        return nil // Negated match means no result
                    }
                    hasMatch = true

                    // Calculate position bonus (matches at start are better)
                    if lowercaseText.hasPrefix(lowercaseTerm) {
                        score += weight * 1.5
                    } else {
                        score += weight
                    }

                    // Find all occurrences for highlighting
                    var searchRange = lowercaseText.startIndex..<lowercaseText.endIndex
                    while let range = lowercaseText.range(of: lowercaseTerm, range: searchRange) {
                        let startIndex = text.distance(from: text.startIndex, to: range.lowerBound)
                        let length = lowercaseTerm.count
                        highlights.append(SearchHighlight(
                            fieldName: fieldName,
                            range: NSRange(location: startIndex, length: length),
                            matchedText: String(text[range])
                        ))

                        // Move search range forward
                        if range.upperBound < lowercaseText.endIndex {
                            searchRange = range.upperBound..<lowercaseText.endIndex
                        } else {
                            break
                        }
                    }
                }
            }
        }

        // Apply operator logic
        switch query.operator {
        case .and:
            // For AND, all non-negated terms must match
            let nonNegatedTerms = query.terms.filter { !$0.negated }
            if !nonNegatedTerms.isEmpty && !hasMatch {
                return nil
            }
        case .or:
            // For OR, at least one term must match
            if !hasMatch {
                return nil
            }
        }

        return hasMatch ? score : nil
    }

    /// Applies boost factors based on task properties
    private static func applyBoostFactors(score: Double, task: Task) -> Double {
        var boostedScore = score

        // Boost flagged tasks
        if task.flagged {
            boostedScore *= 1.2
        }

        // Boost tasks with high priority
        switch task.priority {
        case .high:
            boostedScore *= 1.3
        case .medium:
            boostedScore *= 1.0
        case .low:
            boostedScore *= 0.9
        }

        // Boost recent tasks
        let daysSinceModified = Calendar.current.dateComponents([.day], from: task.modified, to: Date()).day ?? 0
        if daysSinceModified < 7 {
            boostedScore *= 1.1
        }

        return boostedScore
    }

    // MARK: - Recent Searches

    /// Stores recent searches in UserDefaults
    public static func saveRecentSearch(_ query: String) {
        var recents = getRecentSearches()

        // Remove if already exists to move to front
        recents.removeAll { $0 == query }

        // Add to front
        recents.insert(query, at: 0)

        // Limit to max count
        if recents.count > maxRecentSearches {
            recents = Array(recents.prefix(maxRecentSearches))
        }

        UserDefaults.standard.set(recents, forKey: "recentSearches")
    }

    /// Retrieves recent searches from UserDefaults
    public static func getRecentSearches() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }

    /// Clears all recent searches
    public static func clearRecentSearches() {
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }

    // MARK: - Context Preview

    /// Extracts context around a match for preview
    public static func extractContext(text: String, matchRange: NSRange, contextLength: Int = 50) -> String {
        let nsString = text as NSString

        // Calculate preview range
        let matchStart = matchRange.location
        let matchEnd = matchRange.location + matchRange.length

        let previewStart = max(0, matchStart - contextLength)
        let previewEnd = min(nsString.length, matchEnd + contextLength)
        let previewRange = NSRange(location: previewStart, length: previewEnd - previewStart)

        var preview = nsString.substring(with: previewRange)

        // Add ellipsis if truncated
        if previewStart > 0 {
            preview = "..." + preview
        }
        if previewEnd < nsString.length {
            preview = preview + "..."
        }

        return preview
    }
}

// MARK: - Search Models

/// Represents a parsed search query
public struct SearchQuery {
    /// The search terms
    public let terms: [SearchTerm]

    /// The operator to use between terms
    public let operator: SearchOperator

    public init(terms: [SearchTerm], operator: SearchOperator) {
        self.terms = terms
        self.operator = `operator`
    }
}

/// Represents a single search term
public struct SearchTerm {
    /// The text to search for
    public let text: String

    /// Whether this is an exact match (in quotes)
    public let exact: Bool

    /// Whether this term is negated (NOT)
    public let negated: Bool

    public init(text: String, exact: Bool = false, negated: Bool = false) {
        self.text = text
        self.exact = exact
        self.negated = negated
    }
}

/// Search operators
public enum SearchOperator {
    case and
    case or
}

/// Represents a search result with relevance score and highlights
public struct SearchResult: Identifiable {
    public let id: UUID
    public let task: Task
    public let relevanceScore: Double
    public let highlights: [SearchHighlight]
    public let matchedFields: [String: Bool]

    public init(task: Task, relevanceScore: Double, highlights: [SearchHighlight], matchedFields: [String: Bool]) {
        self.id = task.id
        self.task = task
        self.relevanceScore = relevanceScore
        self.highlights = highlights
        self.matchedFields = matchedFields
    }

    /// Returns highlights for a specific field
    public func highlights(for field: String) -> [SearchHighlight] {
        return highlights.filter { $0.fieldName == field }
    }

    /// Returns true if the field has matches
    public func hasMatch(in field: String) -> Bool {
        return matchedFields[field] ?? false
    }
}

/// Represents a highlighted region in search results
public struct SearchHighlight {
    public let fieldName: String
    public let range: NSRange
    public let matchedText: String

    public init(fieldName: String, range: NSRange, matchedText: String) {
        self.fieldName = fieldName
        self.range = range
        self.matchedText = matchedText
    }
}
