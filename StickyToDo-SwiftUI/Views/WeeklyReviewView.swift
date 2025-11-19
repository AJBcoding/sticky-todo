//
//  WeeklyReviewView.swift
//  StickyToDo-SwiftUI
//
//  Guided GTD Weekly Review interface with step-by-step workflow.
//  Displays current step, progress, and provides navigation controls.
//

import SwiftUI

/// Main weekly review view with guided workflow
struct WeeklyReviewView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var reviewManager = WeeklyReviewManager.shared
    @State private var showExitConfirmation = false
    @State private var currentStepNotes = ""
    @State private var sessionNotes = ""
    @State private var showHistory = false
    @State private var selectedPerspectiveID: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let session = reviewManager.currentSession {
                    // Progress header
                    progressHeader(session: session)

                    Divider()

                    // Main content area
                    if let currentStep = session.currentStep {
                        stepContentView(step: currentStep, session: session)
                    } else {
                        completionView(session: session)
                    }

                    Divider()

                    // Navigation controls
                    navigationControls(session: session)
                } else {
                    welcomeView
                }
            }
            .navigationTitle("Weekly Review")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        if reviewManager.currentSession != nil {
                            showExitConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItemGroup(placement: .automatic) {
                    if reviewManager.currentSession != nil {
                        if reviewManager.isReviewInProgress {
                            Button {
                                reviewManager.pauseSession()
                            } label: {
                                Label("Pause", systemImage: "pause.circle")
                            }
                        } else {
                            Button {
                                reviewManager.resumeSession()
                            } label: {
                                Label("Resume", systemImage: "play.circle")
                            }
                        }
                    }

                    Button {
                        showHistory = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
            .confirmationDialog(
                "Exit Review?",
                isPresented: $showExitConfirmation,
                titleVisibility: .visible
            ) {
                Button("Save and Exit") {
                    reviewManager.pauseSession()
                    dismiss()
                }

                Button("Discard Review", role: .destructive) {
                    reviewManager.cancelSession()
                    dismiss()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your progress will be saved and you can resume later.")
            }
            .sheet(isPresented: $showHistory) {
                ReviewHistoryView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            if let session = reviewManager.currentSession {
                sessionNotes = session.sessionNotes
                if let step = session.currentStep {
                    currentStepNotes = step.notes
                }
            }
        }
    }

    // MARK: - Progress Header

    private func progressHeader(session: WeeklyReviewSession) -> some View {
        VStack(spacing: 12) {
            // Progress bar
            HStack {
                Text("Progress")
                    .font(.headline)

                Spacer()

                Text("\(session.completedStepsCount) of \(session.totalStepsCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: session.progressPercentage, total: 100)
                .progressViewStyle(.linear)

            // Time info
            HStack {
                Label(session.durationString, systemImage: "timer")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if session.estimatedMinutesRemaining > 0 {
                    Label("\(session.estimatedMinutesRemaining)m remaining", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Step Content

    private func stepContentView(step: WeeklyReviewStep, session: WeeklyReviewSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Step header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Step \(session.currentStepIndex + 1) of \(session.totalStepsCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        if step.isCompleted {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    Text(step.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(step.description)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Action guidance
                VStack(alignment: .leading, spacing: 8) {
                    Label("What to do", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundColor(.orange)

                    Text(step.actionGuidance)
                        .font(.body)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }

                // Perspective link
                if let perspectiveID = step.perspectiveID {
                    perspectiveCard(perspectiveID: perspectiveID)
                }

                Divider()

                // Notes for this step
                VStack(alignment: .leading, spacing: 8) {
                    Text("Step Notes")
                        .font(.headline)

                    TextEditor(text: $currentStepNotes)
                        .font(.body)
                        .frame(minHeight: 100)
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(4)
                        .border(Color.secondary.opacity(0.2))
                        .onChange(of: currentStepNotes) { _, newValue in
                            reviewManager.updateCurrentStepNotes(newValue)
                        }

                    Text("Notes are automatically saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Session notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall Session Notes")
                        .font(.headline)

                    TextEditor(text: $sessionNotes)
                        .font(.body)
                        .frame(minHeight: 80)
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(4)
                        .border(Color.secondary.opacity(0.2))
                        .onChange(of: sessionNotes) { _, newValue in
                            reviewManager.updateSessionNotes(newValue)
                        }
                }
            }
            .padding()
        }
    }

    private func perspectiveCard(perspectiveID: String) -> some View {
        HStack {
            Image(systemName: "list.bullet.rectangle")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("View Perspective")
                    .font(.headline)

                Text(perspectiveName(perspectiveID))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                selectedPerspectiveID = perspectiveID
            } label: {
                Label("Open", systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    private func perspectiveName(_ id: String) -> String {
        switch id {
        case "inbox": return "Inbox"
        case "next-actions": return "Next Actions"
        case "due-soon": return "Due Soon"
        case "waiting-for": return "Waiting For"
        case "someday-maybe": return "Someday/Maybe"
        case "all-active": return "All Active"
        default: return id
        }
    }

    // MARK: - Completion View

    private func completionView(session: WeeklyReviewSession) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Review Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Great job! You've completed all \(session.totalStepsCount) steps of your weekly review.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                VStack {
                    Text(session.durationString)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(session.completedStepsCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Steps Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            Button {
                reviewManager.completeSession()
                dismiss()
            } label: {
                Label("Finish Review", systemImage: "checkmark.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Navigation Controls

    private func navigationControls(session: WeeklyReviewSession) -> some View {
        HStack(spacing: 16) {
            // Previous button
            Button {
                reviewManager.previousStep()
                updateNotesForCurrentStep()
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .disabled(session.currentStepIndex == 0)

            Spacer()

            // Skip button
            Button {
                reviewManager.skipCurrentStep()
                updateNotesForCurrentStep()
            } label: {
                Text("Skip")
            }
            .buttonStyle(.bordered)
            .disabled(session.currentStepIndex >= session.totalStepsCount)

            // Complete step button
            if session.currentStepIndex < session.totalStepsCount {
                Button {
                    reviewManager.completeCurrentStep(notes: currentStepNotes)
                    updateNotesForCurrentStep()
                } label: {
                    Label("Complete Step", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [.command])
            }

            // Next/Finish button
            Button {
                if session.currentStepIndex < session.totalStepsCount - 1 {
                    reviewManager.completeCurrentStep(notes: currentStepNotes)
                    updateNotesForCurrentStep()
                } else {
                    reviewManager.completeSession()
                    dismiss()
                }
            } label: {
                if session.currentStepIndex < session.totalStepsCount - 1 {
                    Label("Next", systemImage: "chevron.right")
                } else {
                    Label("Finish Review", systemImage: "checkmark.circle.fill")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("GTD Weekly Review")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("A weekly review is your chance to get clear, get current, and get creative.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // History stats
            if reviewManager.history.totalReviewsCompleted > 0 {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 40)

                    HStack(spacing: 32) {
                        StatView(
                            value: "\(reviewManager.history.totalReviewsCompleted)",
                            label: "Completed"
                        )

                        StatView(
                            value: "\(reviewManager.history.currentStreak)",
                            label: "Week Streak"
                        )

                        StatView(
                            value: "\(Int(reviewManager.history.averageDurationMinutes))m",
                            label: "Avg Time"
                        )
                    }

                    Text(reviewManager.history.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }

            Button {
                reviewManager.startNewSession()
            } label: {
                Label("Start Weekly Review", systemImage: "play.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Estimated time: 45-60 minutes")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Helpers

    private func updateNotesForCurrentStep() {
        if let step = reviewManager.currentSession?.currentStep {
            currentStepNotes = step.notes
        } else {
            currentStepNotes = ""
        }
    }
}

// MARK: - Stat View

private struct StatView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Review History View

struct ReviewHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var reviewManager = WeeklyReviewManager.shared
    @State private var completedSessions: [WeeklyReviewSession] = []
    @State private var selectedSession: WeeklyReviewSession?
    @State private var showExportDialog = false

    var body: some View {
        NavigationStack {
            HSplitView {
                // Left: Session list
                List(selection: $selectedSession) {
                    Section {
                        ForEach(completedSessions) { session in
                            SessionListRow(session: session)
                                .tag(session)
                        }
                    } header: {
                        Text("\(completedSessions.count) Reviews Completed")
                    }
                }
                .frame(minWidth: 250)
                .listStyle(.sidebar)

                // Right: Session detail
                if let session = selectedSession {
                    SessionDetailView(session: session, onExport: {
                        showExportDialog = true
                    })
                } else {
                    emptySelectionView
                }
            }
            .navigationTitle("Review History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            completedSessions = reviewManager.getAllCompletedSessions()
            selectedSession = completedSessions.first
        }
        .fileExporter(
            isPresented: $showExportDialog,
            document: selectedSession.map { MarkdownDocument(content: reviewManager.exportSessionAsMarkdown($0)) },
            contentType: .plainText,
            defaultFilename: "weekly-review-\(selectedSession?.startDate.formatted(date: .numeric, time: .omitted) ?? "export").md"
        ) { result in
            switch result {
            case .success(let url):
                print("✅ Exported to: \(url)")
            case .failure(let error):
                print("⚠️ Export failed: \(error)")
            }
        }
    }

    private var emptySelectionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Select a Review")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Choose a completed review from the list to see details")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Session List Row

private struct SessionListRow: View {
    let session: WeeklyReviewSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startDate.formatted(date: .long, time: .omitted))
                .font(.body)

            HStack {
                Label(session.durationString, systemImage: "timer")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary)

                Text("\(session.completedStepsCount) steps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Session Detail View

private struct SessionDetailView: View {
    let session: WeeklyReviewSession
    let onExport: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.startDate.formatted(date: .long, time: .omitted))
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack {
                        Label(session.durationString, systemImage: "timer")
                        Text("•")
                        Label("\(session.completedStepsCount) steps", systemImage: "checkmark.circle")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                Divider()

                // Session notes
                if !session.sessionNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Notes")
                            .font(.headline)

                        Text(session.sessionNotes)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }

                // Steps
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review Steps")
                        .font(.headline)

                    ForEach(Array(session.steps.enumerated()), id: \.element.id) { index, step in
                        StepCard(step: step, index: index)
                    }
                }

                // Export button
                Button {
                    onExport()
                } label: {
                    Label("Export as Markdown", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}

// MARK: - Step Card

private struct StepCard: View {
    let step: WeeklyReviewStep
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(step.isCompleted ? .green : .secondary)

                Text("\(index + 1). \(step.title)")
                    .font(.headline)

                Spacer()

                if let completedAt = step.completedAt {
                    Text(completedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !step.notes.isEmpty {
                Text(step.notes)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Markdown Document for Export

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var content: String

    init(content: String) {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            content = String(decoding: data, as: UTF8.self)
        } else {
            content = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: content.data(using: .utf8)!)
    }
}

// MARK: - Preview

#Preview("Weekly Review") {
    WeeklyReviewView()
        .frame(width: 900, height: 700)
}

#Preview("Welcome") {
    WeeklyReviewView()
        .frame(width: 800, height: 600)
}
