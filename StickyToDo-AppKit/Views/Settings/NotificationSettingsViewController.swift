//
//  NotificationSettingsViewController.swift
//  StickyToDo-AppKit
//
//  AppKit view controller for configuring notification settings.
//

import Cocoa
import UserNotifications
import Combine

/// View controller for managing notification preferences
class NotificationSettingsViewController: NSViewController {

    // MARK: - Properties

    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()

    // UI Components
    private let scrollView = NSScrollView()
    private let contentView = NSView()
    private var stackView: NSStackView!

    // Authorization Section
    private let authorizationLabel = NSTextField(labelWithString: "Notification Permission")
    private let authorizationStatusLabel = NSTextField(labelWithString: "")
    private let requestPermissionButton = NSButton(title: "Request Permission", target: nil, action: nil)

    // General Settings
    private let enableNotificationsCheckbox = NSButton(checkboxWithTitle: "Enable Notifications", target: nil, action: nil)
    private let badgeEnabledCheckbox = NSButton(checkboxWithTitle: "Show Badge Count", target: nil, action: nil)

    // Due Date Reminders
    private let dueReminderPopup = NSPopUpButton()
    private let customReminderStepper = NSStepper()
    private let customReminderTextField = NSTextField()

    // Notification Sound
    private let soundPopup = NSPopUpButton()

    // Weekly Review
    private let weeklyReviewPopup = NSPopUpButton()

    // Testing
    private let testNotificationButton = NSButton(title: "Send Test Notification", target: nil, action: nil)
    private let pendingCountLabel = NSTextField(labelWithString: "Pending Notifications: Loading...")

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupBindings()
        updateUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        title = "Notifications"

        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        view.addSubview(scrollView)

        // Setup content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView

        // Create main stack view
        stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 20
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        contentView.addSubview(stackView)

        // Add sections
        addAuthorizationSection()
        addGeneralSection()
        addDueReminderSection()
        addSoundSection()
        addWeeklyReviewSection()
        addNotificationTypesSection()
        addTestingSection()

        // Setup constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func addAuthorizationSection() {
        let section = createSection(title: "Notification Permission")

        // Status row
        let statusStack = NSStackView(views: [
            createLabel("Status:"),
            authorizationStatusLabel
        ])
        statusStack.orientation = .horizontal
        statusStack.spacing = 10
        section.addArrangedSubview(statusStack)

        // Request button
        section.addArrangedSubview(requestPermissionButton)

        // Footer
        let footer = createFooterLabel("Allow StickyToDo to send you notifications about due tasks, deferrals, and weekly reviews.")
        section.addArrangedSubview(footer)

        stackView.addArrangedSubview(section)
    }

    private func addGeneralSection() {
        let section = createSection(title: "General")

        section.addArrangedSubview(enableNotificationsCheckbox)
        section.addArrangedSubview(badgeEnabledCheckbox)

        let footer = createFooterLabel("Badge count shows the number of overdue tasks.")
        section.addArrangedSubview(footer)

        stackView.addArrangedSubview(section)
    }

    private func addDueReminderSection() {
        let section = createSection(title: "Due Date Reminders")

        // Popup menu
        dueReminderPopup.removeAllItems()
        dueReminderPopup.addItems(withTitles: [
            "1 Day Before",
            "1 Hour Before",
            "15 Minutes Before",
            "Multiple Reminders",
            "Custom"
        ])

        let popupStack = NSStackView(views: [
            createLabel("Reminder Time:"),
            dueReminderPopup
        ])
        popupStack.orientation = .horizontal
        popupStack.spacing = 10
        section.addArrangedSubview(popupStack)

        // Custom stepper
        customReminderStepper.minValue = 5
        customReminderStepper.maxValue = 1440
        customReminderStepper.increment = 5
        customReminderStepper.valueWraps = false

        customReminderTextField.stringValue = "30"
        customReminderTextField.isEditable = false
        customReminderTextField.isBordered = false
        customReminderTextField.backgroundColor = .clear

        let customStack = NSStackView(views: [
            createLabel("Custom:"),
            customReminderTextField,
            createLabel("minutes"),
            customReminderStepper
        ])
        customStack.orientation = .horizontal
        customStack.spacing = 5
        customStack.isHidden = true
        section.addArrangedSubview(customStack)

        let footer = createFooterLabel("Choose when to receive notifications before a task is due.")
        section.addArrangedSubview(footer)

        stackView.addArrangedSubview(section)
    }

    private func addSoundSection() {
        let section = createSection(title: "Sound")

        soundPopup.removeAllItems()
        soundPopup.addItems(withTitles: NotificationSound.allCases.map { $0.rawValue })

        let soundStack = NSStackView(views: [
            createLabel("Notification Sound:"),
            soundPopup
        ])
        soundStack.orientation = .horizontal
        soundStack.spacing = 10
        section.addArrangedSubview(soundStack)

        let footer = createFooterLabel("Choose the sound played when notifications arrive.")
        section.addArrangedSubview(footer)

        stackView.addArrangedSubview(section)
    }

    private func addWeeklyReviewSection() {
        let section = createSection(title: "Weekly Review")

        weeklyReviewPopup.removeAllItems()
        weeklyReviewPopup.addItems(withTitles: WeeklyReviewSchedule.allCases.map { $0.rawValue })

        let reviewStack = NSStackView(views: [
            createLabel("Schedule:"),
            weeklyReviewPopup
        ])
        reviewStack.orientation = .horizontal
        reviewStack.spacing = 10
        section.addArrangedSubview(reviewStack)

        let footer = createFooterLabel("Receive a reminder to review your tasks and plan for the week.")
        section.addArrangedSubview(footer)

        stackView.addArrangedSubview(section)
    }

    private func addNotificationTypesSection() {
        let section = createSection(title: "Notification Types")

        let types = [
            ("Due Date Reminders", "When tasks are approaching their due date"),
            ("Defer Date Notifications", "When deferred tasks become available"),
            ("Timer Completed", "When a task timer finishes"),
            ("Recurring Tasks", "When new recurring task instances are created")
        ]

        for (title, description) in types {
            let typeView = createNotificationType(title: title, description: description)
            section.addArrangedSubview(typeView)
        }

        let footer = createFooterLabel("All notification types are currently enabled.")
        section.addArrangedSubview(footer)

        stackView.addArrangedSubview(section)
    }

    private func addTestingSection() {
        let section = createSection(title: "Testing & Statistics")

        section.addArrangedSubview(testNotificationButton)
        section.addArrangedSubview(pendingCountLabel)

        stackView.addArrangedSubview(section)
    }

    // MARK: - Helper Methods

    private func createSection(title: String) -> NSStackView {
        let section = NSStackView()
        section.translatesAutoresizingMaskIntoConstraints = false
        section.orientation = .vertical
        section.alignment = .leading
        section.spacing = 8

        // Header
        let header = NSTextField(labelWithString: title)
        header.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        header.textColor = .secondaryLabelColor
        section.addArrangedSubview(header)

        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.widthAnchor.constraint(equalToConstant: 500).isActive = true
        section.addArrangedSubview(separator)

        return section
    }

    private func createLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return label
    }

    private func createFooterLabel(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        label.preferredMaxLayoutWidth = 500
        return label
    }

    private func createNotificationType(title: String, description: String) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = createLabel(title)
        titleLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let descLabel = createFooterLabel(description)
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        let checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        checkbox.state = .on
        checkbox.isEnabled = false
        checkbox.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(descLabel)
        container.addSubview(checkbox)

        NSLayoutConstraint.activate([
            checkbox.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            checkbox.topAnchor.constraint(equalTo: container.topAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),

            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            descLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Actions Setup

    private func setupActions() {
        requestPermissionButton.target = self
        requestPermissionButton.action = #selector(requestPermissionTapped)

        enableNotificationsCheckbox.target = self
        enableNotificationsCheckbox.action = #selector(enableNotificationsToggled)

        badgeEnabledCheckbox.target = self
        badgeEnabledCheckbox.action = #selector(badgeEnabledToggled)

        dueReminderPopup.target = self
        dueReminderPopup.action = #selector(dueReminderChanged)

        customReminderStepper.target = self
        customReminderStepper.action = #selector(customReminderChanged)

        soundPopup.target = self
        soundPopup.action = #selector(soundChanged)

        weeklyReviewPopup.target = self
        weeklyReviewPopup.action = #selector(weeklyReviewChanged)

        testNotificationButton.target = self
        testNotificationButton.action = #selector(testNotificationTapped)
    }

    // MARK: - Bindings

    private func setupBindings() {
        notificationManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)

        notificationManager.$notificationsEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.enableNotificationsCheckbox.state = enabled ? .on : .off
                self?.updateEnabledStates()
            }
            .store(in: &cancellables)

        notificationManager.$badgeEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.badgeEnabledCheckbox.state = enabled ? .on : .off
            }
            .store(in: &cancellables)
    }

    private func updateUI() {
        // Update authorization status
        let status = notificationManager.authorizationStatus
        switch status {
        case .authorized:
            authorizationStatusLabel.stringValue = "✓ Authorized"
            authorizationStatusLabel.textColor = .systemGreen
            requestPermissionButton.isHidden = true
        case .denied:
            authorizationStatusLabel.stringValue = "✗ Denied"
            authorizationStatusLabel.textColor = .systemRed
            requestPermissionButton.isHidden = true
        case .notDetermined:
            authorizationStatusLabel.stringValue = "? Not Requested"
            authorizationStatusLabel.textColor = .systemOrange
            requestPermissionButton.isHidden = false
        default:
            authorizationStatusLabel.stringValue = "Unknown"
            authorizationStatusLabel.textColor = .secondaryLabelColor
            requestPermissionButton.isHidden = true
        }

        updateEnabledStates()
        updatePendingCount()
    }

    private func updateEnabledStates() {
        let enabled = notificationManager.notificationsEnabled &&
                     notificationManager.authorizationStatus == .authorized

        dueReminderPopup.isEnabled = enabled
        soundPopup.isEnabled = enabled
        weeklyReviewPopup.isEnabled = enabled
        testNotificationButton.isEnabled = enabled
    }

    private func updatePendingCount() {
        Task { @MainActor in
            let count = await notificationManager.getPendingNotificationCount()
            pendingCountLabel.stringValue = "Pending Notifications: \(count)"
        }
    }

    // MARK: - Actions

    @objc private func requestPermissionTapped() {
        Task { @MainActor in
            let granted = await notificationManager.requestAuthorization()
            if !granted {
                let alert = NSAlert()
                alert.messageText = "Permission Required"
                alert.informativeText = "Please allow notifications in System Settings to receive reminders about your tasks."
                alert.addButton(withTitle: "Open Settings")
                alert.addButton(withTitle: "Cancel")

                if alert.runModal() == .alertFirstButtonReturn {
                    openSystemSettings()
                }
            }
            updateUI()
        }
    }

    @objc private func enableNotificationsToggled() {
        notificationManager.notificationsEnabled = enableNotificationsCheckbox.state == .on
    }

    @objc private func badgeEnabledToggled() {
        notificationManager.badgeEnabled = badgeEnabledCheckbox.state == .on
    }

    @objc private func dueReminderChanged() {
        let index = dueReminderPopup.indexOfSelectedItem
        switch index {
        case 0:
            notificationManager.dueReminderTime = .oneDayBefore
        case 1:
            notificationManager.dueReminderTime = .oneHour
        case 2:
            notificationManager.dueReminderTime = .fifteenMinutes
        case 3:
            notificationManager.dueReminderTime = .multiple
        case 4:
            notificationManager.dueReminderTime = .custom(30)
        default:
            break
        }
    }

    @objc private func customReminderChanged() {
        let minutes = Int(customReminderStepper.intValue)
        customReminderTextField.stringValue = "\(minutes)"
        notificationManager.dueReminderTime = .custom(minutes)
    }

    @objc private func soundChanged() {
        let index = soundPopup.indexOfSelectedItem
        if index >= 0 && index < NotificationSound.allCases.count {
            notificationManager.notificationSound = NotificationSound.allCases[index]
        }
    }

    @objc private func weeklyReviewChanged() {
        let index = weeklyReviewPopup.indexOfSelectedItem
        if index >= 0 && index < WeeklyReviewSchedule.allCases.count {
            notificationManager.weeklyReviewSchedule = WeeklyReviewSchedule.allCases[index]
        }
    }

    @objc private func testNotificationTapped() {
        Task { @MainActor in
            await notificationManager.sendTestNotification()

            let alert = NSAlert()
            alert.messageText = "Test Notification Sent"
            alert.informativeText = "A test notification will appear in a moment."
            alert.addButton(withTitle: "OK")
            alert.runModal()

            updatePendingCount()
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}
