//
//  WeeklyReviewWindowController.swift
//  StickyToDo-AppKit
//
//  AppKit window controller for GTD Weekly Review.
//  Provides guided workflow with step-by-step interface.
//

import Cocoa
import Combine

/// Window controller for the weekly review interface
class WeeklyReviewWindowController: NSWindowController {

    // MARK: - Properties

    private let reviewManager = WeeklyReviewManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var viewController: WeeklyReviewViewController?

    // MARK: - Initialization

    convenience init() {
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Weekly Review"
        window.center()
        window.minSize = NSSize(width: 800, height: 600)

        self.init(window: window)

        // Create and set content view controller
        let viewController = WeeklyReviewViewController()
        self.viewController = viewController
        window.contentViewController = viewController

        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe session completion
        NotificationCenter.default.publisher(for: .weeklyReviewCompleted)
            .sink { [weak self] _ in
                self?.close()
            }
            .store(in: &cancellables)
    }

    // MARK: - Window Lifecycle

    override func windowDidLoad() {
        super.windowDidLoad()
    }
}

// MARK: - View Controller

private class WeeklyReviewViewController: NSViewController {

    // MARK: - Properties

    private let reviewManager = WeeklyReviewManager.shared
    private var cancellables = Set<AnyCancellable>()

    // UI Components
    private let containerView = NSView()
    private let progressView = ProgressHeaderView()
    private let contentScrollView = NSScrollView()
    private let contentView = NSView()
    private let controlsView = NavigationControlsView()

    private var currentStepView: StepContentView?

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
        setupUI()
        setupObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        updateUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.wantsLayer = true

        // Setup scroll view for content
        contentScrollView.hasVerticalScroller = true
        contentScrollView.autohidesScrollers = true
        contentScrollView.documentView = contentView

        // Layout
        view.addSubview(progressView)
        view.addSubview(contentScrollView)
        view.addSubview(controlsView)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        controlsView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Progress view at top
            progressView.topAnchor.constraint(equalTo: view.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 100),

            // Content in middle
            contentScrollView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: controlsView.topAnchor),

            // Controls at bottom
            controlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controlsView.heightAnchor.constraint(equalToConstant: 80)
        ])

        // Setup control actions
        controlsView.onPrevious = { [weak self] in
            self?.previousStep()
        }

        controlsView.onNext = { [weak self] in
            self?.nextStep()
        }

        controlsView.onComplete = { [weak self] in
            self?.completeCurrentStep()
        }

        controlsView.onSkip = { [weak self] in
            self?.skipStep()
        }
    }

    private func setupObservers() {
        reviewManager.$currentSession
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateUI()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - UI Updates

    @MainActor
    private func updateUI() {
        if let session = reviewManager.currentSession {
            updateForSession(session)
        } else {
            showWelcomeScreen()
        }
    }

    @MainActor
    private func updateForSession(_ session: WeeklyReviewSession) {
        // Update progress view
        progressView.updateProgress(
            current: session.completedStepsCount,
            total: session.totalStepsCount,
            duration: session.durationString,
            estimatedRemaining: session.estimatedMinutesRemaining
        )

        // Update content
        if let currentStep = session.currentStep {
            showStepContent(step: currentStep, session: session)
        } else {
            showCompletionScreen(session: session)
        }

        // Update controls
        controlsView.updateControls(
            canGoPrevious: session.currentStepIndex > 0,
            canGoNext: session.currentStepIndex < session.totalStepsCount,
            isLastStep: session.currentStepIndex >= session.totalStepsCount - 1
        )
    }

    @MainActor
    private func showWelcomeScreen() {
        // Clear existing content
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let welcomeView = WelcomeView(
            history: reviewManager.history,
            onStartReview: { [weak self] in
                Task { @MainActor in
                    self?.reviewManager.startNewSession()
                }
            }
        )

        contentView.addSubview(welcomeView)
        welcomeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            welcomeView.topAnchor.constraint(equalTo: contentView.topAnchor),
            welcomeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            welcomeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            welcomeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            welcomeView.widthAnchor.constraint(equalTo: contentScrollView.widthAnchor)
        ])

        // Hide progress and controls for welcome screen
        progressView.isHidden = true
        controlsView.isHidden = true
    }

    @MainActor
    private func showStepContent(step: WeeklyReviewStep, session: WeeklyReviewSession) {
        // Clear existing content
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let stepView = StepContentView(step: step, stepNumber: session.currentStepIndex + 1, totalSteps: session.totalStepsCount)
        currentStepView = stepView

        contentView.addSubview(stepView)
        stepView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stepView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stepView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stepView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stepView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stepView.widthAnchor.constraint(equalTo: contentScrollView.widthAnchor)
        ])

        // Show progress and controls
        progressView.isHidden = false
        controlsView.isHidden = false
    }

    @MainActor
    private func showCompletionScreen(session: WeeklyReviewSession) {
        // Clear existing content
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let completionView = CompletionView(
            session: session,
            onFinish: { [weak self] in
                Task { @MainActor in
                    self?.reviewManager.completeSession()
                }
            }
        )

        contentView.addSubview(completionView)
        completionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            completionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            completionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            completionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            completionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            completionView.widthAnchor.constraint(equalTo: contentScrollView.widthAnchor)
        ])

        // Hide controls for completion screen
        controlsView.isHidden = true
    }

    // MARK: - Actions

    private func previousStep() {
        Task { @MainActor in
            reviewManager.previousStep()
        }
    }

    private func nextStep() {
        Task { @MainActor in
            if let session = reviewManager.currentSession,
               session.currentStepIndex < session.totalStepsCount - 1 {
                let notes = currentStepView?.stepNotes ?? ""
                reviewManager.completeCurrentStep(notes: notes)
            } else {
                reviewManager.completeSession()
            }
        }
    }

    private func completeCurrentStep() {
        Task { @MainActor in
            let notes = currentStepView?.stepNotes ?? ""
            reviewManager.completeCurrentStep(notes: notes)
        }
    }

    private func skipStep() {
        Task { @MainActor in
            reviewManager.skipCurrentStep()
        }
    }
}

// MARK: - Progress Header View

private class ProgressHeaderView: NSView {

    private let titleLabel = NSTextField(labelWithString: "Progress")
    private let countLabel = NSTextField(labelWithString: "0 of 0")
    private let progressBar = NSProgressIndicator()
    private let durationLabel = NSTextField(labelWithString: "")
    private let remainingLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        countLabel.font = .systemFont(ofSize: 12)
        countLabel.textColor = .secondaryLabelColor
        durationLabel.font = .systemFont(ofSize: 11)
        durationLabel.textColor = .secondaryLabelColor
        remainingLabel.font = .systemFont(ofSize: 11)
        remainingLabel.textColor = .secondaryLabelColor

        progressBar.isIndeterminate = false
        progressBar.minValue = 0
        progressBar.maxValue = 100

        addSubview(titleLabel)
        addSubview(countLabel)
        addSubview(progressBar)
        addSubview(durationLabel)
        addSubview(remainingLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        remainingLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            countLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            progressBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            durationLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            durationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            remainingLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            remainingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    func updateProgress(current: Int, total: Int, duration: String, estimatedRemaining: Int) {
        countLabel.stringValue = "\(current) of \(total)"
        progressBar.doubleValue = total > 0 ? Double(current) / Double(total) * 100 : 0
        durationLabel.stringValue = "⏱ \(duration)"
        remainingLabel.stringValue = estimatedRemaining > 0 ? "🕐 \(estimatedRemaining)m remaining" : ""
    }
}

// MARK: - Navigation Controls View

private class NavigationControlsView: NSView {

    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?
    var onComplete: (() -> Void)?
    var onSkip: (() -> Void)?

    private let previousButton = NSButton()
    private let skipButton = NSButton()
    private let completeButton = NSButton()
    private let nextButton = NSButton()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        // Previous button
        previousButton.title = "Previous"
        previousButton.bezelStyle = .rounded
        previousButton.target = self
        previousButton.action = #selector(previousButtonClicked)

        // Skip button
        skipButton.title = "Skip"
        skipButton.bezelStyle = .rounded
        skipButton.target = self
        skipButton.action = #selector(skipButtonClicked)

        // Complete button
        completeButton.title = "Complete Step"
        completeButton.bezelStyle = .rounded
        completeButton.keyEquivalent = "\r"
        completeButton.target = self
        completeButton.action = #selector(completeButtonClicked)

        // Next button
        nextButton.title = "Next"
        nextButton.bezelStyle = .rounded
        nextButton.target = self
        nextButton.action = #selector(nextButtonClicked)

        addSubview(previousButton)
        addSubview(skipButton)
        addSubview(completeButton)
        addSubview(nextButton)

        previousButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        completeButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            previousButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            previousButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            previousButton.widthAnchor.constraint(equalToConstant: 100),

            completeButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 60),
            completeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            completeButton.widthAnchor.constraint(equalToConstant: 140),

            skipButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -60),
            skipButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            skipButton.widthAnchor.constraint(equalToConstant: 80),

            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 100)
        ])
    }

    func updateControls(canGoPrevious: Bool, canGoNext: Bool, isLastStep: Bool) {
        previousButton.isEnabled = canGoPrevious
        nextButton.isEnabled = canGoNext
        nextButton.title = isLastStep ? "Finish" : "Next"
    }

    @objc private func previousButtonClicked() {
        onPrevious?()
    }

    @objc private func skipButtonClicked() {
        onSkip?()
    }

    @objc private func completeButtonClicked() {
        onComplete?()
    }

    @objc private func nextButtonClicked() {
        onNext?()
    }
}

// MARK: - Step Content View

private class StepContentView: NSView {

    private let step: WeeklyReviewStep
    private let stepNumber: Int
    private let totalSteps: Int

    private let stepNumberLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let descriptionLabel = NSTextField(wrappingLabelWithString: "")
    private let guidanceBox = NSBox()
    private let guidanceLabel = NSTextField(wrappingLabelWithString: "")
    private let notesTextView = NSTextView()
    private let notesScrollView = NSScrollView()

    var stepNotes: String {
        return notesTextView.string
    }

    init(step: WeeklyReviewStep, stepNumber: Int, totalSteps: Int) {
        self.step = step
        self.stepNumber = stepNumber
        self.totalSteps = totalSteps
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Step number
        stepNumberLabel.stringValue = "Step \(stepNumber) of \(totalSteps)"
        stepNumberLabel.font = .systemFont(ofSize: 11)
        stepNumberLabel.textColor = .secondaryLabelColor

        // Title
        titleLabel.stringValue = step.title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        // Description
        descriptionLabel.stringValue = step.description
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabelColor

        // Guidance box
        guidanceBox.title = "What to do"
        guidanceBox.titlePosition = .aboveTop
        guidanceBox.boxType = .custom
        guidanceBox.borderType = .lineBorder
        guidanceBox.borderColor = .systemOrange
        guidanceBox.fillColor = NSColor.systemOrange.withAlphaComponent(0.1)

        guidanceLabel.stringValue = step.actionGuidance
        guidanceLabel.font = .systemFont(ofSize: 13)
        guidanceBox.contentView = guidanceLabel

        // Notes
        notesScrollView.hasVerticalScroller = true
        notesScrollView.borderType = .lineBorder
        notesScrollView.documentView = notesTextView
        notesTextView.isEditable = true
        notesTextView.font = .systemFont(ofSize: 13)
        notesTextView.string = step.notes

        addSubview(stepNumberLabel)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(guidanceBox)
        addSubview(notesScrollView)

        stepNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        guidanceBox.translatesAutoresizingMaskIntoConstraints = false
        guidanceLabel.translatesAutoresizingMaskIntoConstraints = false
        notesScrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stepNumberLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stepNumberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),

            titleLabel.topAnchor.constraint(equalTo: stepNumberLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),

            guidanceBox.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            guidanceBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            guidanceBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),

            guidanceLabel.topAnchor.constraint(equalTo: guidanceBox.topAnchor, constant: 12),
            guidanceLabel.leadingAnchor.constraint(equalTo: guidanceBox.leadingAnchor, constant: 12),
            guidanceLabel.trailingAnchor.constraint(equalTo: guidanceBox.trailingAnchor, constant: -12),
            guidanceLabel.bottomAnchor.constraint(equalTo: guidanceBox.bottomAnchor, constant: -12),

            notesScrollView.topAnchor.constraint(equalTo: guidanceBox.bottomAnchor, constant: 24),
            notesScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            notesScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            notesScrollView.heightAnchor.constraint(equalToConstant: 150),
            notesScrollView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
    }
}

// MARK: - Welcome View

private class WelcomeView: NSView {

    var onStartReview: (() -> Void)?

    private let iconImageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "GTD Weekly Review")
    private let subtitleLabel = NSTextField(wrappingLabelWithString: "A weekly review is your chance to get clear, get current, and get creative.")
    private let startButton = NSButton()
    private let estimateLabel = NSTextField(labelWithString: "Estimated time: 45-60 minutes")

    init(history: WeeklyReviewHistory, onStartReview: @escaping () -> Void) {
        self.onStartReview = onStartReview
        super.init(frame: .zero)
        setupUI(history: history)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(history: WeeklyReviewHistory) {
        // Icon
        iconImageView.image = NSImage(systemSymbolName: "calendar.badge.checkmark", accessibilityDescription: nil)
        iconImageView.contentTintColor = .systemBlue
        iconImageView.imageScaling = .scaleProportionallyUpOrDown

        // Title
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.alignment = .center

        // Subtitle
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.alignment = .center

        // Start button
        startButton.title = "Start Weekly Review"
        startButton.bezelStyle = .rounded
        startButton.target = self
        startButton.action = #selector(startButtonClicked)
        startButton.keyEquivalent = "\r"

        // Estimate
        estimateLabel.font = .systemFont(ofSize: 11)
        estimateLabel.textColor = .secondaryLabelColor
        estimateLabel.alignment = .center

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(startButton)
        addSubview(estimateLabel)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false
        estimateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -120),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.widthAnchor.constraint(equalToConstant: 500),

            startButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            startButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 200),

            estimateLabel.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 12),
            estimateLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    @objc private func startButtonClicked() {
        onStartReview?()
    }
}

// MARK: - Completion View

private class CompletionView: NSView {

    var onFinish: (() -> Void)?

    private let iconImageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Review Complete!")
    private let subtitleLabel = NSTextField(wrappingLabelWithString: "Great job! You've completed all steps of your weekly review.")
    private let finishButton = NSButton()

    init(session: WeeklyReviewSession, onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        super.init(frame: .zero)
        setupUI(session: session)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(session: WeeklyReviewSession) {
        // Icon
        iconImageView.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
        iconImageView.contentTintColor = .systemGreen
        iconImageView.imageScaling = .scaleProportionallyUpOrDown

        // Title
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.alignment = .center

        // Subtitle
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.alignment = .center

        // Finish button
        finishButton.title = "Finish Review"
        finishButton.bezelStyle = .rounded
        finishButton.target = self
        finishButton.action = #selector(finishButtonClicked)
        finishButton.keyEquivalent = "\r"

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(finishButton)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        finishButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.widthAnchor.constraint(equalToConstant: 500),

            finishButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            finishButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            finishButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }

    @objc private func finishButtonClicked() {
        onFinish?()
    }
}
