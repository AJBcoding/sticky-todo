//
//  OnboardingWindowController.swift
//  StickyToDo-AppKit
//
//  First-run onboarding window for AppKit.
//  Multi-page welcome flow with GTD introduction and configuration.
//

import Cocoa

/// Configuration from onboarding
struct OnboardingConfiguration {
    let dataDirectory: URL
    let createSampleData: Bool
}

/// Onboarding window controller with multi-page flow
class OnboardingWindowController: NSWindowController {

    // MARK: - Properties

    private var currentPageIndex = 0
    private var pageViewControllers: [NSViewController] = []
    private var containerView: NSView!
    private var pageControl: NSSegmentedControl!
    private var backButton: NSButton!
    private var nextButton: NSButton!
    private var skipButton: NSButton!

    var onComplete: ((OnboardingConfiguration) -> Void)?

    // Configuration
    private var dataDirectory: URL
    private var createSampleData = true

    // MARK: - Initialization

    init() {
        // Default data directory
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dataDirectory = documents.appendingPathComponent("StickyToDo")

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 550),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to StickyToDo"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        setupPages()
        setupUI()
        showPage(0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupPages() {
        pageViewControllers = [
            WelcomePageViewController(),
            GTDPageViewController(),
            FeaturesPageViewController(),
            ConfigurationPageViewController(
                dataDirectory: dataDirectory,
                createSampleData: createSampleData,
                onDataDirectoryChanged: { [weak self] url in
                    self?.dataDirectory = url
                },
                onCreateSampleDataChanged: { [weak self] value in
                    self?.createSampleData = value
                }
            )
        ]
    }

    private func setupUI() {
        guard let window = window, let contentView = window.contentView else { return }

        // Background with gradient effect
        let backgroundView = NSView(frame: contentView.bounds)
        backgroundView.autoresizingMask = [.width, .height]
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        contentView.addSubview(backgroundView)

        // Container for pages
        containerView = NSView(frame: NSRect(x: 0, y: 60, width: contentView.bounds.width, height: contentView.bounds.height - 60))
        containerView.autoresizingMask = [.width, .height]
        contentView.addSubview(containerView)

        // Bottom bar with navigation
        let bottomBar = createBottomBar()
        bottomBar.frame = NSRect(x: 0, y: 0, width: contentView.bounds.width, height: 60)
        bottomBar.autoresizingMask = [.width, .minYMargin]
        contentView.addSubview(bottomBar)
    }

    private func createBottomBar() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        // Back button
        backButton = NSButton(title: "Back", target: self, action: #selector(backAction))
        backButton.bezelStyle = .rounded
        backButton.frame = NSRect(x: 20, y: 15, width: 80, height: 30)
        backButton.autoresizingMask = [.maxXMargin, .maxYMargin]
        container.addSubview(backButton)

        // Skip button
        skipButton = NSButton(title: "Skip", target: self, action: #selector(skipAction))
        skipButton.bezelStyle = .rounded
        skipButton.frame = NSRect(x: 280, y: 15, width: 80, height: 30)
        skipButton.autoresizingMask = [.minXMargin, .maxXMargin, .maxYMargin]
        container.addSubview(skipButton)

        // Next/Done button
        nextButton = NSButton(title: "Next", target: self, action: #selector(nextAction))
        nextButton.bezelStyle = .rounded
        nextButton.keyEquivalent = "\r"
        nextButton.frame = NSRect(x: 600, y: 15, width: 80, height: 30)
        nextButton.autoresizingMask = [.minXMargin, .maxYMargin]
        container.addSubview(nextButton)

        return container
    }

    // MARK: - Navigation

    private func showPage(_ index: Int) {
        guard index >= 0 && index < pageViewControllers.count else { return }

        // Remove current page
        containerView.subviews.forEach { $0.removeFromSuperview() }

        // Add new page
        let pageVC = pageViewControllers[index]
        pageVC.view.frame = containerView.bounds
        pageVC.view.autoresizingMask = [.width, .height]
        containerView.addSubview(pageVC.view)

        currentPageIndex = index

        // Update navigation buttons
        updateNavigationButtons()
    }

    private func updateNavigationButtons() {
        backButton.isHidden = currentPageIndex == 0
        skipButton.isHidden = currentPageIndex == pageViewControllers.count - 1

        if currentPageIndex == pageViewControllers.count - 1 {
            nextButton.title = "Get Started"
        } else {
            nextButton.title = "Next"
        }
    }

    // MARK: - Actions

    @objc private func backAction() {
        if currentPageIndex > 0 {
            showPage(currentPageIndex - 1)
        }
    }

    @objc private func nextAction() {
        if currentPageIndex < pageViewControllers.count - 1 {
            showPage(currentPageIndex + 1)
        } else {
            completeOnboarding()
        }
    }

    @objc private func skipAction() {
        completeOnboarding()
    }

    private func completeOnboarding() {
        let config = OnboardingConfiguration(
            dataDirectory: dataDirectory,
            createSampleData: createSampleData
        )
        onComplete?(config)
        window?.close()
    }
}

// MARK: - Welcome Page

class WelcomePageViewController: NSViewController {

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 490))
        setupUI()
    }

    private func setupUI() {
        // Icon
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: nil)
        iconView.contentTintColor = .systemBlue
        iconView.frame = NSRect(x: 300, y: 330, width: 100, height: 100)
        view.addSubview(iconView)

        // Title
        let titleLabel = NSTextField(labelWithString: "Welcome to StickyToDo")
        titleLabel.font = .systemFont(ofSize: 36, weight: .bold)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 100, y: 270, width: 500, height: 50)
        view.addSubview(titleLabel)

        // Description
        let descLabel = NSTextField(wrappingLabelWithString: "A GTD-inspired task manager that combines the flexibility of sticky notes with the power of Getting Things Done.")
        descLabel.font = .systemFont(ofSize: 16)
        descLabel.alignment = .center
        descLabel.textColor = .secondaryLabelColor
        descLabel.frame = NSRect(x: 100, y: 200, width: 500, height: 60)
        view.addSubview(descLabel)
    }
}

// MARK: - GTD Page

class GTDPageViewController: NSViewController {

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 490))
        setupUI()
    }

    private func setupUI() {
        // Icon
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: nil)
        iconView.contentTintColor = .systemBlue
        iconView.frame = NSRect(x: 310, y: 380, width: 80, height: 80)
        view.addSubview(iconView)

        // Title
        let titleLabel = NSTextField(labelWithString: "Getting Things Done")
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 150, y: 330, width: 400, height: 40)
        view.addSubview(titleLabel)

        // GTD Steps
        let steps = [
            ("tray.and.arrow.down", "Capture", "Quickly capture tasks with natural language"),
            ("list.bullet.clipboard", "Clarify", "Process your inbox and organize tasks"),
            ("square.grid.2x2", "Organize", "Use contexts, projects, and boards"),
            ("checkmark.circle", "Review & Do", "Stay on top of what matters")
        ]

        var yPosition: CGFloat = 250
        for (icon, title, description) in steps {
            let stepView = createStepView(icon: icon, title: title, description: description)
            stepView.frame = NSRect(x: 100, y: yPosition, width: 500, height: 50)
            view.addSubview(stepView)
            yPosition -= 60
        }
    }

    private func createStepView(icon: String, title: String, description: String) -> NSView {
        let container = NSView()

        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        iconView.contentTintColor = .systemBlue
        iconView.frame = NSRect(x: 0, y: 10, width: 30, height: 30)
        container.addSubview(iconView)

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.frame = NSRect(x: 45, y: 25, width: 150, height: 20)
        container.addSubview(titleLabel)

        let descLabel = NSTextField(labelWithString: description)
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        descLabel.frame = NSRect(x: 45, y: 5, width: 400, height: 20)
        container.addSubview(descLabel)

        return container
    }
}

// MARK: - Features Page

class FeaturesPageViewController: NSViewController {

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 490))
        setupUI()
    }

    private func setupUI() {
        // Title
        let titleLabel = NSTextField(labelWithString: "21 Advanced Features")
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 150, y: 450, width: 400, height: 35)
        view.addSubview(titleLabel)

        // Scroll view for features
        let scrollView = NSScrollView(frame: NSRect(x: 50, y: 50, width: 600, height: 380))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        view.addSubview(scrollView)

        // Container for features
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 580, height: 1000))
        scrollView.documentView = containerView

        // Features grid
        let features = [
            ("plus.circle.fill", "Quick Capture", "⌘⇧Space for instant task creation"),
            ("tray.and.arrow.down", "Inbox Processing", "GTD-style organization"),
            ("square.grid.2x2", "Board Canvas", "Freeform, Kanban, Grid layouts"),
            ("sparkles", "Smart Perspectives", "Inbox, Today, Upcoming, custom"),
            ("doc.text", "Markdown Storage", "Plain text files you own"),
            ("waveform.circle", "Siri Shortcuts", "Voice-controlled tasks"),
            ("arrow.clockwise", "Recurring Tasks", "Daily, weekly, monthly"),
            ("list.bullet.indent", "Subtasks", "Break down complex work"),
            ("tag.fill", "Tags & Labels", "Flexible categorization"),
            ("paperclip", "Attachments", "Link files to tasks"),
            ("timer", "Time Tracking", "Built-in focus timers"),
            ("calendar.badge.plus", "Calendar Sync", "Two-way integration"),
            ("bell.badge", "Notifications", "Smart reminders"),
            ("magnifyingglass", "Spotlight", "⌘Space search"),
            ("slider.horizontal.3", "Advanced Filters", "Custom perspectives"),
            ("square.and.arrow.up", "Export", "JSON, CSV, Markdown"),
            ("paintbrush.fill", "Customization", "Themes and colors"),
            ("keyboard", "Shortcuts", "Mouse-free navigation"),
            ("chart.bar.fill", "Statistics", "Productivity tracking"),
            ("arrow.triangle.2.circlepath", "Weekly Review", "GTD workflow"),
            ("doc.on.doc", "Templates", "Reusable workflows")
        ]

        var xPosition: CGFloat = 10
        var yPosition: CGFloat = 900
        for (index, feature) in features.enumerated() {
            let featureView = createFeatureCard(icon: feature.0, title: feature.1, description: feature.2)
            featureView.frame = NSRect(x: xPosition, y: yPosition, width: 280, height: 90)
            containerView.addSubview(featureView)

            if index % 2 == 1 {
                xPosition = 10
                yPosition -= 100
            } else {
                xPosition = 300
            }
        }

        // Info label
        let infoLabel = NSTextField(labelWithString: "And much more...")
        infoLabel.font = .systemFont(ofSize: 11)
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.alignment = .center
        infoLabel.frame = NSRect(x: 200, y: 20, width: 300, height: 20)
        view.addSubview(infoLabel)
    }

    private func createFeatureCard(icon: String, title: String, description: String) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        container.layer?.cornerRadius = 12

        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        iconView.contentTintColor = .systemBlue
        iconView.frame = NSRect(x: 105, y: 70, width: 40, height: 40)
        container.addSubview(iconView)

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 20, y: 45, width: 210, height: 20)
        container.addSubview(titleLabel)

        let descLabel = NSTextField(wrappingLabelWithString: description)
        descLabel.font = .systemFont(ofSize: 11)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.frame = NSRect(x: 20, y: 10, width: 210, height: 30)
        container.addSubview(descLabel)

        return container
    }
}

// MARK: - Configuration Page

class ConfigurationPageViewController: NSViewController {

    private var dataDirectory: URL
    private var createSampleData: Bool
    private let onDataDirectoryChanged: (URL) -> Void
    private let onCreateSampleDataChanged: (Bool) -> Void

    private var pathLabel: NSTextField!
    private var sampleDataCheckbox: NSButton!

    init(dataDirectory: URL,
         createSampleData: Bool,
         onDataDirectoryChanged: @escaping (URL) -> Void,
         onCreateSampleDataChanged: @escaping (Bool) -> Void) {
        self.dataDirectory = dataDirectory
        self.createSampleData = createSampleData
        self.onDataDirectoryChanged = onDataDirectoryChanged
        self.onCreateSampleDataChanged = onCreateSampleDataChanged
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 490))
        setupUI()
    }

    private func setupUI() {
        // Icon
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: nil)
        iconView.contentTintColor = .systemPurple
        iconView.frame = NSRect(x: 310, y: 370, width: 80, height: 80)
        view.addSubview(iconView)

        // Title
        let titleLabel = NSTextField(labelWithString: "Setup Your Workspace")
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 150, y: 320, width: 400, height: 40)
        view.addSubview(titleLabel)

        // Storage location section
        let storageLabel = NSTextField(labelWithString: "Storage Location")
        storageLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        storageLabel.frame = NSRect(x: 100, y: 270, width: 500, height: 20)
        view.addSubview(storageLabel)

        let pathContainer = NSView()
        pathContainer.wantsLayer = true
        pathContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        pathContainer.layer?.cornerRadius = 8
        pathContainer.frame = NSRect(x: 100, y: 230, width: 500, height: 35)
        view.addSubview(pathContainer)

        pathLabel = NSTextField(labelWithString: dataDirectory.path)
        pathLabel.font = .systemFont(ofSize: 11)
        pathLabel.textColor = .secondaryLabelColor
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.frame = NSRect(x: 10, y: 8, width: 390, height: 20)
        pathContainer.addSubview(pathLabel)

        let chooseButton = NSButton(title: "Choose...", target: self, action: #selector(chooseDirectory))
        chooseButton.bezelStyle = .rounded
        chooseButton.frame = NSRect(x: 410, y: 3, width: 80, height: 28)
        pathContainer.addSubview(chooseButton)

        // Sample data section
        let sampleContainer = NSView()
        sampleContainer.wantsLayer = true
        sampleContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        sampleContainer.layer?.cornerRadius = 8
        sampleContainer.frame = NSRect(x: 100, y: 150, width: 500, height: 60)
        view.addSubview(sampleContainer)

        let sampleTitleLabel = NSTextField(labelWithString: "Create Sample Data")
        sampleTitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        sampleTitleLabel.frame = NSRect(x: 15, y: 32, width: 400, height: 20)
        sampleContainer.addSubview(sampleTitleLabel)

        let sampleDescLabel = NSTextField(labelWithString: "Start with example tasks and boards to explore features")
        sampleDescLabel.font = .systemFont(ofSize: 11)
        sampleDescLabel.textColor = .secondaryLabelColor
        sampleDescLabel.frame = NSRect(x: 15, y: 12, width: 400, height: 18)
        sampleContainer.addSubview(sampleDescLabel)

        sampleDataCheckbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleSampleData))
        sampleDataCheckbox.state = createSampleData ? .on : .off
        sampleDataCheckbox.frame = NSRect(x: 465, y: 20, width: 20, height: 20)
        sampleContainer.addSubview(sampleDataCheckbox)
    }

    @objc private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Select where to store your StickyToDo data"

        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }

            self.dataDirectory = url
            self.pathLabel.stringValue = url.path
            self.onDataDirectoryChanged(url)
        }
    }

    @objc private func toggleSampleData() {
        createSampleData = sampleDataCheckbox.state == .on
        onCreateSampleDataChanged(createSampleData)
    }
}
