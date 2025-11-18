//
//  WeeklyReviewManager.swift
//  StickyToDoCore
//
//  Manages weekly review sessions, history, and reminders.
//  Provides session state management and persistence.
//

import Foundation
import Combine

/// Manages weekly review sessions and history
@MainActor
public class WeeklyReviewManager: ObservableObject {

    // MARK: - Singleton

    public static let shared = WeeklyReviewManager()

    // MARK: - Published Properties

    /// Current active review session (nil if none in progress)
    @Published public var currentSession: WeeklyReviewSession?

    /// Review history and statistics
    @Published public var history: WeeklyReviewHistory

    /// Whether a review session is currently active
    @Published public var isReviewInProgress: Bool = false

    /// Timer for tracking session duration
    @Published public var sessionStartTime: Date?

    // MARK: - Private Properties

    private let fileManager = FileManager.default
    private var sessionTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // File paths
    private var currentSessionURL: URL {
        ConfigurationManager.shared.dataDirectory
            .appendingPathComponent("review")
            .appendingPathComponent("current-session.json")
    }

    private var historyURL: URL {
        ConfigurationManager.shared.dataDirectory
            .appendingPathComponent("review")
            .appendingPathComponent("history.json")
    }

    private var completedSessionsDirectory: URL {
        ConfigurationManager.shared.dataDirectory
            .appendingPathComponent("review")
            .appendingPathComponent("completed")
    }

    // MARK: - Initialization

    private init() {
        self.history = WeeklyReviewHistory()
        setupDirectories()
        loadHistory()
        loadCurrentSession()
    }

    // MARK: - Setup

    private func setupDirectories() {
        let reviewDirectory = ConfigurationManager.shared.dataDirectory
            .appendingPathComponent("review")

        // Create review directory if needed
        if !fileManager.fileExists(atPath: reviewDirectory.path) {
            try? fileManager.createDirectory(at: reviewDirectory, withIntermediateDirectories: true)
        }

        // Create completed sessions directory if needed
        if !fileManager.fileExists(atPath: completedSessionsDirectory.path) {
            try? fileManager.createDirectory(at: completedSessionsDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Session Management

    /// Start a new weekly review session
    public func startNewSession() {
        guard currentSession == nil else {
            print("⚠️ A review session is already in progress")
            return
        }

        let newSession = WeeklyReviewSession()
        currentSession = newSession
        isReviewInProgress = true
        sessionStartTime = Date()

        // Start duration timer
        startSessionTimer()

        // Save the session
        saveCurrentSession()

        print("✅ Started new weekly review session: \(newSession.id)")
    }

    /// Resume an existing session
    public func resumeSession() {
        guard let session = currentSession else {
            print("⚠️ No session to resume")
            return
        }

        isReviewInProgress = true
        sessionStartTime = Date()
        startSessionTimer()

        print("✅ Resumed weekly review session: \(session.id)")
    }

    /// Pause the current session
    public func pauseSession() {
        guard var session = currentSession else { return }

        session.isPaused = true
        isReviewInProgress = false
        stopSessionTimer()

        currentSession = session
        saveCurrentSession()

        print("⏸️ Paused weekly review session")
    }

    /// Complete the current step in the session
    public func completeCurrentStep(notes: String = "") {
        guard var session = currentSession else { return }

        session.completeCurrentStep(notes: notes)
        currentSession = session
        saveCurrentSession()

        print("✅ Completed step: \(session.steps[session.currentStepIndex - 1].title)")
    }

    /// Skip the current step
    public func skipCurrentStep() {
        guard var session = currentSession else { return }

        session.skipCurrentStep()
        currentSession = session
        saveCurrentSession()

        print("⏭️ Skipped step")
    }

    /// Go to previous step
    public func previousStep() {
        guard var session = currentSession else { return }

        session.previousStep()
        currentSession = session
        saveCurrentSession()

        print("⏮️ Went to previous step")
    }

    /// Go to a specific step
    public func goToStep(index: Int) {
        guard var session = currentSession else { return }

        session.goToStep(index: index)
        currentSession = session
        saveCurrentSession()

        print("➡️ Jumped to step \(index)")
    }

    /// Update session notes
    public func updateSessionNotes(_ notes: String) {
        guard var session = currentSession else { return }

        session.sessionNotes = notes
        currentSession = session
        saveCurrentSession()
    }

    /// Update current step notes
    public func updateCurrentStepNotes(_ notes: String) {
        guard var session = currentSession,
              session.currentStepIndex < session.steps.count else { return }

        session.steps[session.currentStepIndex].notes = notes
        currentSession = session
        saveCurrentSession()
    }

    /// Complete the entire review session
    public func completeSession() {
        guard var session = currentSession else { return }

        stopSessionTimer()
        session.completeSession()

        // Update history
        updateHistoryWithCompletedSession(session)

        // Archive the session
        archiveSession(session)

        // Clear current session
        currentSession = nil
        isReviewInProgress = false
        sessionStartTime = nil

        // Delete current session file
        try? fileManager.removeItem(at: currentSessionURL)

        print("✅ Completed weekly review session!")
    }

    /// Cancel and discard the current session
    public func cancelSession() {
        stopSessionTimer()
        currentSession = nil
        isReviewInProgress = false
        sessionStartTime = nil

        // Delete current session file
        try? fileManager.removeItem(at: currentSessionURL)

        print("❌ Cancelled weekly review session")
    }

    // MARK: - Timer Management

    private func startSessionTimer() {
        stopSessionTimer()

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard var session = self?.currentSession else { return }
                session.addDuration(1.0)
                self?.currentSession = session
            }
        }
    }

    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    // MARK: - History Management

    private func updateHistoryWithCompletedSession(_ session: WeeklyReviewSession) {
        history.lastReviewDate = session.completedDate ?? Date()
        history.totalReviewsCompleted += 1
        history.completedSessionIDs.append(session.id)

        // Update streak
        updateStreak()

        // Update average duration
        let totalDuration = history.averageDurationMinutes * Double(history.totalReviewsCompleted - 1)
        let newAverage = (totalDuration + (session.durationSeconds / 60.0)) / Double(history.totalReviewsCompleted)
        history.averageDurationMinutes = newAverage

        saveHistory()

        // Update ConfigurationManager
        ConfigurationManager.shared.lastReviewDate = history.lastReviewDate
    }

    private func updateStreak() {
        guard let lastReview = history.lastReviewDate else {
            history.currentStreak = 1
            history.longestStreak = max(history.longestStreak, 1)
            return
        }

        let days = Calendar.current.dateComponents([.day], from: lastReview, to: Date()).day ?? 0

        if days <= 7 {
            // Within a week, continue streak
            history.currentStreak += 1
        } else {
            // Streak broken, reset
            history.currentStreak = 1
        }

        history.longestStreak = max(history.longestStreak, history.currentStreak)
    }

    /// Get a completed session by ID
    public func getCompletedSession(id: UUID) -> WeeklyReviewSession? {
        let sessionURL = completedSessionsDirectory
            .appendingPathComponent("\(id.uuidString).json")

        guard let data = try? Data(contentsOf: sessionURL) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WeeklyReviewSession.self, from: data)
    }

    /// Get all completed sessions
    public func getAllCompletedSessions() -> [WeeklyReviewSession] {
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: completedSessionsDirectory,
            includingPropertiesForKeys: nil
        ) else { return [] }

        return fileURLs.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try? decoder.decode(WeeklyReviewSession.self, from: data)
        }.sorted { $0.startDate > $1.startDate }
    }

    // MARK: - Persistence

    private func saveCurrentSession() {
        guard let session = currentSession else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(session) else {
            print("⚠️ Failed to encode current session")
            return
        }

        do {
            try data.write(to: currentSessionURL)
            print("💾 Saved current session")
        } catch {
            print("⚠️ Failed to save current session: \(error)")
        }
    }

    private func loadCurrentSession() {
        guard fileManager.fileExists(atPath: currentSessionURL.path),
              let data = try? Data(contentsOf: currentSessionURL) else {
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let session = try? decoder.decode(WeeklyReviewSession.self, from: data) else {
            print("⚠️ Failed to decode current session")
            return
        }

        currentSession = session
        isReviewInProgress = !session.isPaused

        if isReviewInProgress {
            sessionStartTime = Date()
            startSessionTimer()
        }

        print("📂 Loaded current session: \(session.id)")
    }

    private func archiveSession(_ session: WeeklyReviewSession) {
        let sessionURL = completedSessionsDirectory
            .appendingPathComponent("\(session.id.uuidString).json")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(session) else {
            print("⚠️ Failed to encode session for archiving")
            return
        }

        do {
            try data.write(to: sessionURL)
            print("📦 Archived session: \(session.id)")
        } catch {
            print("⚠️ Failed to archive session: \(error)")
        }
    }

    private func saveHistory() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(history) else {
            print("⚠️ Failed to encode history")
            return
        }

        do {
            try data.write(to: historyURL)
            print("💾 Saved review history")
        } catch {
            print("⚠️ Failed to save history: \(error)")
        }
    }

    private func loadHistory() {
        guard fileManager.fileExists(atPath: historyURL.path),
              let data = try? Data(contentsOf: historyURL) else {
            history = WeeklyReviewHistory()
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let loadedHistory = try? decoder.decode(WeeklyReviewHistory.self, from: data) else {
            print("⚠️ Failed to decode history")
            history = WeeklyReviewHistory()
            return
        }

        history = loadedHistory
        print("📂 Loaded review history: \(history.totalReviewsCompleted) reviews completed")
    }

    // MARK: - Export

    /// Export a session as markdown
    public func exportSessionAsMarkdown(_ session: WeeklyReviewSession) -> String {
        var markdown = "# Weekly Review\n\n"
        markdown += "**Date:** \(formatDate(session.startDate))\n"
        markdown += "**Duration:** \(session.durationString)\n"
        markdown += "**Status:** \(session.isComplete ? "Complete" : "In Progress")\n\n"

        if !session.sessionNotes.isEmpty {
            markdown += "## Session Notes\n\n"
            markdown += session.sessionNotes
            markdown += "\n\n"
        }

        markdown += "## Review Steps\n\n"

        for (index, step) in session.steps.enumerated() {
            let status = step.isCompleted ? "✓" : "○"
            markdown += "### \(index + 1). \(status) \(step.title)\n\n"
            markdown += "\(step.description)\n\n"

            if !step.notes.isEmpty {
                markdown += "**Notes:**\n\n"
                markdown += step.notes
                markdown += "\n\n"
            }
        }

        return markdown
    }

    /// Export session to a file
    public func exportSession(_ session: WeeklyReviewSession, to url: URL) throws {
        let markdown = exportSessionAsMarkdown(session)
        try markdown.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Reset all history (use with caution)
    public func resetHistory() {
        history = WeeklyReviewHistory()
        saveHistory()

        // Clear all archived sessions
        if let fileURLs = try? fileManager.contentsOfDirectory(
            at: completedSessionsDirectory,
            includingPropertiesForKeys: nil
        ) {
            for url in fileURLs {
                try? fileManager.removeItem(at: url)
            }
        }

        print("🔄 Reset review history")
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let weeklyReviewStarted = Notification.Name("com.stickytodo.weeklyReviewStarted")
    static let weeklyReviewCompleted = Notification.Name("com.stickytodo.weeklyReviewCompleted")
    static let weeklyReviewStepCompleted = Notification.Name("com.stickytodo.weeklyReviewStepCompleted")
    static let weeklyReviewReminder = Notification.Name("com.stickytodo.weeklyReviewReminder")
}
