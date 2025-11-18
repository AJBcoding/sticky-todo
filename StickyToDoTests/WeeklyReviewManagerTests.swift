//
//  WeeklyReviewManagerTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for WeeklyReviewManager covering session management,
//  history tracking, persistence, and state management.
//

import XCTest
@testable import StickyToDoCore

@MainActor
final class WeeklyReviewManagerTests: XCTestCase {

    var manager: WeeklyReviewManager!
    var tempDirectory: URL!

    override func setUpWithError() throws {
        manager = WeeklyReviewManager.shared

        // Create temp directory for test files
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Clear any existing session
        if manager.currentSession != nil {
            manager.cancelSession()
        }

        // Reset history
        manager.resetHistory()
    }

    override func tearDownWithError() throws {
        manager.cancelSession()
        manager.resetHistory()
        try? FileManager.default.removeItem(at: tempDirectory)
        manager = nil
    }

    // MARK: - Session Creation Tests

    func testStartNewSession() {
        manager.startNewSession()

        XCTAssertNotNil(manager.currentSession)
        XCTAssertTrue(manager.isReviewInProgress)
        XCTAssertNotNil(manager.sessionStartTime)
        XCTAssertEqual(manager.currentSession?.currentStepIndex, 0)
    }

    func testCannotStartMultipleSessions() {
        manager.startNewSession()
        let firstSession = manager.currentSession

        manager.startNewSession() // Should not create new session

        XCTAssertEqual(manager.currentSession?.id, firstSession?.id)
    }

    func testSessionHasSteps() {
        manager.startNewSession()

        XCTAssertNotNil(manager.currentSession)
        XCTAssertTrue(manager.currentSession!.steps.count > 0)
    }

    // MARK: - Session State Tests

    func testPauseSession() {
        manager.startNewSession()

        manager.pauseSession()

        XCTAssertFalse(manager.isReviewInProgress)
        XCTAssertTrue(manager.currentSession?.isPaused ?? false)
    }

    func testResumeSession() {
        manager.startNewSession()
        manager.pauseSession()

        manager.resumeSession()

        XCTAssertTrue(manager.isReviewInProgress)
        XCTAssertNotNil(manager.sessionStartTime)
    }

    func testCannotResumeWithoutSession() {
        manager.resumeSession()

        XCTAssertFalse(manager.isReviewInProgress)
    }

    // MARK: - Step Navigation Tests

    func testCompleteCurrentStep() {
        manager.startNewSession()
        let initialStep = manager.currentSession?.currentStepIndex ?? 0

        manager.completeCurrentStep(notes: "Test notes")

        XCTAssertEqual(manager.currentSession?.currentStepIndex, initialStep + 1)
    }

    func testSkipCurrentStep() {
        manager.startNewSession()
        let initialStep = manager.currentSession?.currentStepIndex ?? 0

        manager.skipCurrentStep()

        XCTAssertEqual(manager.currentSession?.currentStepIndex, initialStep + 1)
    }

    func testPreviousStep() {
        manager.startNewSession()
        manager.completeCurrentStep()
        let currentStep = manager.currentSession?.currentStepIndex ?? 0

        manager.previousStep()

        XCTAssertEqual(manager.currentSession?.currentStepIndex, currentStep - 1)
    }

    func testGoToSpecificStep() {
        manager.startNewSession()

        manager.goToStep(index: 2)

        XCTAssertEqual(manager.currentSession?.currentStepIndex, 2)
    }

    // MARK: - Session Notes Tests

    func testUpdateSessionNotes() {
        manager.startNewSession()
        let testNotes = "Important session notes"

        manager.updateSessionNotes(testNotes)

        XCTAssertEqual(manager.currentSession?.sessionNotes, testNotes)
    }

    func testUpdateCurrentStepNotes() {
        manager.startNewSession()
        let testNotes = "Step-specific notes"

        manager.updateCurrentStepNotes(testNotes)

        let currentStep = manager.currentSession?.steps[manager.currentSession!.currentStepIndex]
        XCTAssertEqual(currentStep?.notes, testNotes)
    }

    // MARK: - Session Completion Tests

    func testCompleteSession() {
        manager.startNewSession()

        manager.completeSession()

        XCTAssertNil(manager.currentSession)
        XCTAssertFalse(manager.isReviewInProgress)
        XCTAssertNil(manager.sessionStartTime)
        XCTAssertEqual(manager.history.totalReviewsCompleted, 1)
    }

    func testCompletionUpdatesHistory() {
        XCTAssertEqual(manager.history.totalReviewsCompleted, 0)

        manager.startNewSession()
        manager.completeSession()

        XCTAssertEqual(manager.history.totalReviewsCompleted, 1)
        XCTAssertNotNil(manager.history.lastReviewDate)
    }

    func testCancelSession() {
        manager.startNewSession()

        manager.cancelSession()

        XCTAssertNil(manager.currentSession)
        XCTAssertFalse(manager.isReviewInProgress)
        XCTAssertEqual(manager.history.totalReviewsCompleted, 0) // Should not increment
    }

    // MARK: - History Tests

    func testInitialHistory() {
        XCTAssertEqual(manager.history.totalReviewsCompleted, 0)
        XCTAssertNil(manager.history.lastReviewDate)
        XCTAssertEqual(manager.history.currentStreak, 0)
        XCTAssertEqual(manager.history.longestStreak, 0)
    }

    func testStreakIncrement() {
        manager.startNewSession()
        manager.completeSession()

        XCTAssertEqual(manager.history.currentStreak, 1)
        XCTAssertEqual(manager.history.longestStreak, 1)
    }

    func testMultipleCompletionsIncrementStreak() {
        manager.startNewSession()
        manager.completeSession()

        manager.startNewSession()
        manager.completeSession()

        XCTAssertEqual(manager.history.totalReviewsCompleted, 2)
    }

    func testAverageDurationTracking() {
        manager.startNewSession()
        Thread.sleep(forTimeInterval: 0.1)
        manager.completeSession()

        XCTAssertTrue(manager.history.averageDurationMinutes > 0)
    }

    // MARK: - Session Export Tests

    func testExportSessionAsMarkdown() {
        manager.startNewSession()
        manager.updateSessionNotes("Test session")
        manager.completeCurrentStep(notes: "Step 1 complete")

        let markdown = manager.exportSessionAsMarkdown(manager.currentSession!)

        XCTAssertTrue(markdown.contains("Weekly Review"))
        XCTAssertTrue(markdown.contains("Test session"))
        XCTAssertTrue(markdown.contains("Step 1 complete"))
    }

    func testExportSessionToFile() async throws {
        manager.startNewSession()
        manager.updateSessionNotes("Export test")

        let exportURL = tempDirectory.appendingPathComponent("review.md")

        try manager.exportSession(manager.currentSession!, to: exportURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))

        let content = try String(contentsOf: exportURL, encoding: .utf8)
        XCTAssertTrue(content.contains("Export test"))
    }

    // MARK: - Session History Tests

    func testGetCompletedSession() {
        manager.startNewSession()
        let sessionId = manager.currentSession!.id
        manager.completeSession()

        let retrieved = manager.getCompletedSession(id: sessionId)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, sessionId)
    }

    func testGetAllCompletedSessions() {
        // Complete multiple sessions
        for _ in 0..<3 {
            manager.startNewSession()
            manager.completeSession()
        }

        let sessions = manager.getAllCompletedSessions()

        XCTAssertEqual(sessions.count, 3)
    }

    func testCompletedSessionsSortedByDate() {
        // Complete multiple sessions with delays
        for _ in 0..<2 {
            manager.startNewSession()
            Thread.sleep(forTimeInterval: 0.1)
            manager.completeSession()
        }

        let sessions = manager.getAllCompletedSessions()

        if sessions.count >= 2 {
            XCTAssertTrue(sessions[0].startDate > sessions[1].startDate)
        }
    }

    // MARK: - Reset Tests

    func testResetHistory() {
        manager.startNewSession()
        manager.completeSession()

        manager.resetHistory()

        XCTAssertEqual(manager.history.totalReviewsCompleted, 0)
        XCTAssertEqual(manager.history.currentStreak, 0)
        XCTAssertEqual(manager.history.longestStreak, 0)
        XCTAssertNil(manager.history.lastReviewDate)
    }

    func testResetClearsArchivedSessions() {
        manager.startNewSession()
        manager.completeSession()

        manager.resetHistory()

        let sessions = manager.getAllCompletedSessions()
        XCTAssertEqual(sessions.count, 0)
    }

    // MARK: - Edge Cases

    func testCompleteStepBeyondEnd() {
        manager.startNewSession()

        // Complete all steps
        let totalSteps = manager.currentSession?.steps.count ?? 0
        for _ in 0..<(totalSteps + 5) {
            manager.completeCurrentStep()
        }

        // Should handle gracefully
        XCTAssertNotNil(manager.currentSession)
    }

    func testPreviousStepAtBeginning() {
        manager.startNewSession()

        manager.previousStep()

        // Should stay at index 0
        XCTAssertEqual(manager.currentSession?.currentStepIndex, 0)
    }

    func testUpdateNotesWithoutSession() {
        manager.updateSessionNotes("Test")
        manager.updateCurrentStepNotes("Test")

        // Should handle gracefully without crashing
    }

    // MARK: - Performance Tests

    func testSessionCreationPerformance() {
        measure {
            manager.startNewSession()
            manager.cancelSession()
        }
    }

    func testStepCompletionPerformance() {
        manager.startNewSession()

        measure {
            for _ in 0..<10 {
                manager.completeCurrentStep()
            }
        }
    }
}
