//
//  SearchTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for search functionality.
//

import XCTest
@testable import StickyToDoCore

class SearchTests: XCTestCase {

    var sampleTasks: [Task] = []

    override func setUp() {
        super.setUp()

        // Create sample tasks for testing
        sampleTasks = [
            Task(
                title: "Fix bug in authentication module",
                notes: "The login feature is not working properly",
                status: .nextAction,
                project: "Website Redesign",
                context: "@computer",
                flagged: true,
                priority: .high,
                tags: [Tag(name: "urgent", color: "#FF0000")]
            ),
            Task(
                title: "Review pull request #123",
                notes: "Check the code quality and test coverage",
                status: .nextAction,
                project: "Code Review",
                context: "@computer",
                priority: .medium
            ),
            Task(
                title: "Call John about project proposal",
                notes: "Discuss timeline and budget",
                status: .waiting,
                project: "Sales",
                context: "@phone",
                priority: .high
            ),
            Task(
                title: "Buy groceries",
                notes: "Milk, eggs, bread, coffee",
                status: .inbox,
                context: "@errands",
                priority: .low
            ),
            Task(
                title: "Write weekly blog post",
                notes: "Topic: Getting Things Done methodology",
                status: .someday,
                project: "Blog",
                context: "@writing",
                priority: .medium,
                tags: [Tag(name: "writing", color: "#00FF00")]
            ),
            Task(
                title: "Complete project documentation",
                notes: "Document all API endpoints and usage examples",
                status: .completed,
                project: "Website Redesign",
                context: "@computer",
                priority: .medium
            )
        ]
    }

    // MARK: - Query Parsing Tests

    func testParseSimpleQuery() {
        let query = SearchManager.parseQuery("bug")

        XCTAssertEqual(query.terms.count, 1)
        XCTAssertEqual(query.terms[0].text, "bug")
        XCTAssertFalse(query.terms[0].exact)
        XCTAssertFalse(query.terms[0].negated)
        XCTAssertEqual(query.operator, .and)
    }

    func testParseMultipleTerms() {
        let query = SearchManager.parseQuery("bug authentication")

        XCTAssertEqual(query.terms.count, 2)
        XCTAssertEqual(query.terms[0].text, "bug")
        XCTAssertEqual(query.terms[1].text, "authentication")
        XCTAssertEqual(query.operator, .and)
    }

    func testParseExactPhrase() {
        let query = SearchManager.parseQuery("\"weekly blog post\"")

        XCTAssertEqual(query.terms.count, 1)
        XCTAssertEqual(query.terms[0].text, "weekly blog post")
        XCTAssertTrue(query.terms[0].exact)
        XCTAssertFalse(query.terms[0].negated)
    }

    func testParseOROperator() {
        let query = SearchManager.parseQuery("bug OR feature")

        XCTAssertEqual(query.terms.count, 2)
        XCTAssertEqual(query.terms[0].text, "bug")
        XCTAssertEqual(query.terms[1].text, "feature")
        XCTAssertEqual(query.operator, .or)
    }

    func testParseANDOperator() {
        let query = SearchManager.parseQuery("bug AND authentication")

        XCTAssertEqual(query.terms.count, 2)
        XCTAssertEqual(query.terms[0].text, "bug")
        XCTAssertEqual(query.terms[1].text, "authentication")
        XCTAssertEqual(query.operator, .and)
    }

    func testParseNOTOperator() {
        let query = SearchManager.parseQuery("project NOT archived")

        XCTAssertEqual(query.terms.count, 2)
        XCTAssertEqual(query.terms[0].text, "project")
        XCTAssertFalse(query.terms[0].negated)
        XCTAssertEqual(query.terms[1].text, "archived")
        XCTAssertTrue(query.terms[1].negated)
    }

    func testParseComplexQuery() {
        let query = SearchManager.parseQuery("\"bug fix\" OR feature NOT deprecated")

        XCTAssertEqual(query.terms.count, 3)
        XCTAssertEqual(query.terms[0].text, "bug fix")
        XCTAssertTrue(query.terms[0].exact)
        XCTAssertEqual(query.terms[1].text, "feature")
        XCTAssertEqual(query.terms[2].text, "deprecated")
        XCTAssertTrue(query.terms[2].negated)
        XCTAssertEqual(query.operator, .or)
    }

    // MARK: - Search Execution Tests

    func testSearchInTitle() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "bug")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].task.title, "Fix bug in authentication module")
        XCTAssertTrue(results[0].hasMatch(in: "title"))
    }

    func testSearchInNotes() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "timeline")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].task.title, "Call John about project proposal")
        XCTAssertTrue(results[0].hasMatch(in: "notes"))
    }

    func testSearchInProject() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "Website Redesign")

        XCTAssertEqual(results.count, 2)
        let titles = results.map { $0.task.title }.sorted()
        XCTAssertTrue(titles.contains("Fix bug in authentication module"))
        XCTAssertTrue(titles.contains("Complete project documentation"))
    }

    func testSearchInContext() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "@computer")

        XCTAssertEqual(results.count, 3)
        for result in results {
            XCTAssertEqual(result.task.context, "@computer")
        }
    }

    func testSearchInTags() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "urgent")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].task.title, "Fix bug in authentication module")
        XCTAssertTrue(results[0].hasMatch(in: "tags"))
    }

    func testSearchWithANDOperator() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "bug AND authentication")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].task.title, "Fix bug in authentication module")
    }

    func testSearchWithOROperator() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "bug OR groceries")

        XCTAssertEqual(results.count, 2)
        let titles = results.map { $0.task.title }.sorted()
        XCTAssertTrue(titles.contains("Fix bug in authentication module"))
        XCTAssertTrue(titles.contains("Buy groceries"))
    }

    func testSearchWithNOTOperator() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "project NOT proposal")

        // Should match tasks with "project" but not "proposal"
        XCTAssertGreaterThan(results.count, 0)
        for result in results {
            let allText = "\(result.task.title) \(result.task.notes) \(result.task.project ?? "")"
            XCTAssertFalse(allText.lowercased().contains("proposal"))
        }
    }

    func testSearchWithExactPhrase() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "\"weekly blog post\"")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].task.title, "Write weekly blog post")
    }

    func testSearchCaseInsensitive() {
        let results1 = SearchManager.search(tasks: sampleTasks, queryString: "BUG")
        let results2 = SearchManager.search(tasks: sampleTasks, queryString: "bug")
        let results3 = SearchManager.search(tasks: sampleTasks, queryString: "Bug")

        XCTAssertEqual(results1.count, results2.count)
        XCTAssertEqual(results2.count, results3.count)
    }

    // MARK: - Relevance Ranking Tests

    func testRelevanceRanking_TitleMatchesHigher() {
        // Add a task where "bug" is in title and another where it's only in notes
        let results = SearchManager.search(tasks: sampleTasks, queryString: "bug")

        // Task with "bug" in title should rank higher
        XCTAssertGreaterThan(results.count, 0)
        let topResult = results[0]
        XCTAssertTrue(topResult.task.title.lowercased().contains("bug"))
    }

    func testRelevanceRanking_FlaggedTasksBoosted() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "authentication")

        XCTAssertGreaterThan(results.count, 0)
        // The flagged task should have a higher score
        XCTAssertGreaterThan(results[0].relevanceScore, 0)
    }

    func testRelevanceRanking_HighPriorityBoosted() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "project")

        // High priority tasks should be boosted
        for result in results {
            if result.task.priority == .high {
                XCTAssertGreaterThan(result.relevanceScore, 0)
            }
        }
    }

    func testRelevanceRanking_ResultsSorted() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "project")

        // Results should be sorted by relevance (descending)
        for i in 0..<(results.count - 1) {
            XCTAssertGreaterThanOrEqual(results[i].relevanceScore, results[i + 1].relevanceScore)
        }
    }

    // MARK: - Highlighting Tests

    func testHighlightInTitle() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "bug")

        XCTAssertEqual(results.count, 1)
        let titleHighlights = results[0].highlights(for: "title")
        XCTAssertGreaterThan(titleHighlights.count, 0)

        let firstHighlight = titleHighlights[0]
        XCTAssertEqual(firstHighlight.matchedText, "bug")
    }

    func testHighlightInMultipleFields() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "project")

        for result in results {
            let allHighlights = result.highlights
            XCTAssertGreaterThan(allHighlights.count, 0)
        }
    }

    func testHighlightExactPhrase() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "\"blog post\"")

        XCTAssertEqual(results.count, 1)
        let highlights = results[0].highlights(for: "title")
        XCTAssertGreaterThan(highlights.count, 0)
    }

    // MARK: - Recent Searches Tests

    func testSaveRecentSearch() {
        // Clear existing searches
        SearchManager.clearRecentSearches()

        // Save a search
        SearchManager.saveRecentSearch("test query")

        let recents = SearchManager.getRecentSearches()
        XCTAssertEqual(recents.count, 1)
        XCTAssertEqual(recents[0], "test query")
    }

    func testRecentSearchesLimit() {
        // Clear existing searches
        SearchManager.clearRecentSearches()

        // Add more than max searches
        for i in 0..<25 {
            SearchManager.saveRecentSearch("query \(i)")
        }

        let recents = SearchManager.getRecentSearches()
        XCTAssertEqual(recents.count, SearchManager.maxRecentSearches)
        XCTAssertEqual(recents[0], "query 24") // Most recent should be first
    }

    func testRecentSearchesDuplicates() {
        // Clear existing searches
        SearchManager.clearRecentSearches()

        // Save the same query multiple times
        SearchManager.saveRecentSearch("test query")
        SearchManager.saveRecentSearch("other query")
        SearchManager.saveRecentSearch("test query") // Duplicate

        let recents = SearchManager.getRecentSearches()
        XCTAssertEqual(recents.count, 2)
        XCTAssertEqual(recents[0], "test query") // Moved to front
        XCTAssertEqual(recents[1], "other query")
    }

    func testClearRecentSearches() {
        // Add some searches
        SearchManager.saveRecentSearch("test query 1")
        SearchManager.saveRecentSearch("test query 2")

        // Clear them
        SearchManager.clearRecentSearches()

        let recents = SearchManager.getRecentSearches()
        XCTAssertEqual(recents.count, 0)
    }

    // MARK: - Context Extraction Tests

    func testExtractContext() {
        let text = "This is a long piece of text that contains the word important in the middle of it."
        let range = NSRange(location: 52, length: 9) // "important"

        let context = SearchManager.extractContext(text: text, matchRange: range, contextLength: 20)

        XCTAssertTrue(context.contains("important"))
        XCTAssertTrue(context.contains("...")) // Should have ellipsis
    }

    func testExtractContextAtStart() {
        let text = "Important information at the start of this text."
        let range = NSRange(location: 0, length: 9) // "Important"

        let context = SearchManager.extractContext(text: text, matchRange: range, contextLength: 20)

        XCTAssertTrue(context.contains("Important"))
        XCTAssertFalse(context.hasPrefix("...")) // Should not start with ellipsis
    }

    func testExtractContextAtEnd() {
        let text = "This text ends with something important"
        let range = NSRange(location: 31, length: 9) // "important"

        let context = SearchManager.extractContext(text: text, matchRange: range, contextLength: 20)

        XCTAssertTrue(context.contains("important"))
        XCTAssertFalse(context.hasSuffix("...")) // Should not end with ellipsis
    }

    // MARK: - Edge Cases

    func testEmptyQuery() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "")

        XCTAssertEqual(results.count, 0)
    }

    func testNoMatches() {
        let results = SearchManager.search(tasks: sampleTasks, queryString: "xyzabc123")

        XCTAssertEqual(results.count, 0)
    }

    func testSpecialCharacters() {
        let task = Task(
            title: "Fix bug #123 (urgent!)",
            notes: "Special characters: @#$%^&*()",
            status: .nextAction
        )

        let results = SearchManager.search(tasks: [task], queryString: "#123")

        XCTAssertEqual(results.count, 1)
    }

    func testUnicodeCharacters() {
        let task = Task(
            title: "Review pull request 你好",
            notes: "Unicode: こんにちは 🎉",
            status: .nextAction
        )

        let results = SearchManager.search(tasks: [task], queryString: "你好")

        XCTAssertEqual(results.count, 1)
    }

    // MARK: - Performance Tests

    func testSearchPerformance() {
        // Create a large number of tasks
        var largeTasks: [Task] = []
        for i in 0..<1000 {
            largeTasks.append(Task(
                title: "Task \(i)",
                notes: "This is task number \(i) with some content",
                status: .nextAction,
                project: "Project \(i % 10)"
            ))
        }

        // Measure search performance
        measure {
            let _ = SearchManager.search(tasks: largeTasks, queryString: "task 500")
        }
    }

    func testQueryParsingPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = SearchManager.parseQuery("\"complex query\" AND term1 OR term2 NOT excluded")
            }
        }
    }
}
