//
//  RecurrencePickerView.swift
//  StickyToDo-AppKit
//
//  AppKit view for editing task recurrence patterns.
//

import AppKit

/// AppKit view for editing recurrence patterns on tasks
class RecurrencePickerView: NSView {

    // MARK: - Properties

    /// The recurrence pattern being edited
    var recurrence: Recurrence? {
        didSet {
            updateUI()
        }
    }

    /// Callback when recurrence changes
    var onChange: ((Recurrence?) -> Void)?

    // MARK: - UI Components

    private let enableCheckbox = NSButton(checkboxWithTitle: "Repeat Task", target: nil, action: nil)
    private let frequencyPopup = NSPopUpButton()
    private let intervalStepper = NSStepper()
    private let intervalLabel = NSTextField(labelWithString: "1")
    private let intervalUnitLabel = NSTextField(labelWithString: "day")

    // Weekly days
    private let weeklyDaysStack = NSStackView()
    private var dayButtons: [NSButton] = []

    // Monthly options
    private let monthlyStack = NSStackView()
    private let dayOfMonthRadio = NSButton(radioButtonWithTitle: "Day", target: nil, action: nil)
    private let lastDayRadio = NSButton(radioButtonWithTitle: "Last day of month", target: nil, action: nil)
    private let dayOfMonthStepper = NSStepper()
    private let dayOfMonthLabel = NSTextField(labelWithString: "1")

    // End condition
    private let neverRadio = NSButton(radioButtonWithTitle: "Never", target: nil, action: nil)
    private let onDateRadio = NSButton(radioButtonWithTitle: "On date", target: nil, action: nil)
    private let afterCountRadio = NSButton(radioButtonWithTitle: "After", target: nil, action: nil)
    private let endDatePicker = NSDatePicker()
    private let countStepper = NSStepper()
    private let countLabel = NSTextField(labelWithString: "10")

    // Container views
    private let mainStack = NSStackView()
    private let settingsContainer = NSView()
    private var previewStack: NSStackView?

    // MARK: - State

    private var isEnabled = false
    private var frequency: RecurrenceFrequency = .daily
    private var interval = 1
    private var selectedDays: Set<Int> = []
    private var dayOfMonth = 1
    private var useLastDayOfMonth = false
    private var endCondition: EndCondition = .never
    private var endDate = Date().addingTimeInterval(86400 * 30)
    private var count = 10

    private enum EndCondition {
        case never
        case onDate
        case afterCount
    }

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        // Main stack
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        // Enable checkbox
        enableCheckbox.target = self
        enableCheckbox.action = #selector(enableCheckboxChanged)
        enableCheckbox.setAccessibilityLabel("Repeat task")
        enableCheckbox.setAccessibilityHelp("Toggle to enable or disable task recurrence")
        mainStack.addArrangedSubview(enableCheckbox)

        // Settings container
        settingsContainer.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(settingsContainer)

        setupSettingsView()
        updateUI()
    }

    private func setupSettingsView() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        settingsContainer.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: settingsContainer.topAnchor),
            stack.leadingAnchor.constraint(equalTo: settingsContainer.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: settingsContainer.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: settingsContainer.bottomAnchor)
        ])

        // Frequency section
        let frequencyLabel = NSTextField(labelWithString: "Frequency")
        frequencyLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        frequencyLabel.textColor = .secondaryLabelColor
        stack.addArrangedSubview(frequencyLabel)

        frequencyPopup.addItems(withTitles: ["Daily", "Weekly", "Monthly", "Yearly"])
        frequencyPopup.target = self
        frequencyPopup.action = #selector(frequencyChanged)
        frequencyPopup.setAccessibilityLabel("Recurrence frequency")
        frequencyPopup.setAccessibilityHelp("Select how often the task repeats")
        stack.addArrangedSubview(frequencyPopup)

        // Interval section
        let intervalStack = NSStackView()
        intervalStack.orientation = .horizontal
        intervalStack.spacing = 8

        let intervalTitleLabel = NSTextField(labelWithString: "Repeat Every")
        intervalTitleLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        intervalTitleLabel.textColor = .secondaryLabelColor

        intervalStepper.minValue = 1
        intervalStepper.maxValue = 99
        intervalStepper.integerValue = 1
        intervalStepper.target = self
        intervalStepper.action = #selector(intervalChanged)
        intervalStepper.setAccessibilityLabel("Repeat interval")
        intervalStepper.setAccessibilityHelp("Adjust how many periods between each occurrence")

        intervalLabel.isEditable = false
        intervalLabel.isBordered = false
        intervalLabel.backgroundColor = .clear
        intervalLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        intervalLabel.setAccessibilityLabel("Interval value")

        intervalUnitLabel.isEditable = false
        intervalUnitLabel.isBordered = false
        intervalUnitLabel.backgroundColor = .clear
        intervalUnitLabel.textColor = .secondaryLabelColor

        stack.addArrangedSubview(intervalTitleLabel)
        intervalStack.addArrangedSubview(intervalLabel)
        intervalStack.addArrangedSubview(intervalStepper)
        intervalStack.addArrangedSubview(intervalUnitLabel)
        stack.addArrangedSubview(intervalStack)

        // Weekly days section
        setupWeeklyDaysSection()
        stack.addArrangedSubview(weeklyDaysStack)

        // Monthly section
        setupMonthlySection()
        stack.addArrangedSubview(monthlyStack)

        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.widthAnchor.constraint(equalToConstant: 300).isActive = true
        stack.addArrangedSubview(separator)

        // End condition section
        setupEndConditionSection(in: stack)

        // Separator before preview
        let previewSeparator = NSBox()
        previewSeparator.boxType = .separator
        previewSeparator.translatesAutoresizingMaskIntoConstraints = false
        previewSeparator.widthAnchor.constraint(equalToConstant: 300).isActive = true
        stack.addArrangedSubview(previewSeparator)

        // Preview section
        let preview = createPreviewSection()
        stack.addArrangedSubview(preview)
        previewStack = preview
    }

    private func setupWeeklyDaysSection() {
        weeklyDaysStack.orientation = .vertical
        weeklyDaysStack.alignment = .leading
        weeklyDaysStack.spacing = 8

        let label = NSTextField(labelWithString: "Repeat On")
        label.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        weeklyDaysStack.addArrangedSubview(label)

        let buttonsStack = NSStackView()
        buttonsStack.orientation = .horizontal
        buttonsStack.spacing = 4

        let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
        let fullDayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        for (index, name) in dayNames.enumerated() {
            let button = NSButton(title: name, target: self, action: #selector(dayButtonClicked(_:)))
            button.setButtonType(.toggle)
            button.bezelStyle = .circular
            button.tag = index
            button.widthAnchor.constraint(equalToConstant: 32).isActive = true
            button.heightAnchor.constraint(equalToConstant: 32).isActive = true
            button.setAccessibilityLabel(fullDayNames[index])
            button.setAccessibilityHelp("Toggle \(fullDayNames[index]) for weekly recurrence")
            dayButtons.append(button)
            buttonsStack.addArrangedSubview(button)
        }

        weeklyDaysStack.addArrangedSubview(buttonsStack)
    }

    private func setupMonthlySection() {
        monthlyStack.orientation = .vertical
        monthlyStack.alignment = .leading
        monthlyStack.spacing = 8

        let label = NSTextField(labelWithString: "Repeat On")
        label.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        monthlyStack.addArrangedSubview(label)

        // Day of month option
        let dayStack = NSStackView()
        dayStack.orientation = .horizontal
        dayStack.spacing = 8

        dayOfMonthRadio.target = self
        dayOfMonthRadio.action = #selector(monthlyOptionChanged)
        dayOfMonthRadio.setAccessibilityLabel("Specific day of month")
        dayOfMonthRadio.setAccessibilityHelp("Select to repeat on a specific day number")

        dayOfMonthStepper.minValue = 1
        dayOfMonthStepper.maxValue = 31
        dayOfMonthStepper.integerValue = 1
        dayOfMonthStepper.target = self
        dayOfMonthStepper.action = #selector(dayOfMonthChanged)
        dayOfMonthStepper.setAccessibilityLabel("Day of month")
        dayOfMonthStepper.setAccessibilityHelp("Adjust which day of the month to repeat on")

        dayOfMonthLabel.isEditable = false
        dayOfMonthLabel.isBordered = false
        dayOfMonthLabel.backgroundColor = .clear
        dayOfMonthLabel.setAccessibilityLabel("Day number")

        dayStack.addArrangedSubview(dayOfMonthRadio)
        dayStack.addArrangedSubview(NSTextField(labelWithString: "Day"))
        dayStack.addArrangedSubview(dayOfMonthLabel)
        dayStack.addArrangedSubview(dayOfMonthStepper)

        monthlyStack.addArrangedSubview(dayStack)

        // Last day option
        lastDayRadio.target = self
        lastDayRadio.action = #selector(monthlyOptionChanged)
        lastDayRadio.setAccessibilityLabel("Last day of month")
        lastDayRadio.setAccessibilityHelp("Select to repeat on the last day of each month")
        monthlyStack.addArrangedSubview(lastDayRadio)
    }

    private func setupEndConditionSection(in stack: NSStackView) {
        let label = NSTextField(labelWithString: "Ends")
        label.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        stack.addArrangedSubview(label)

        // Never
        neverRadio.target = self
        neverRadio.action = #selector(endConditionChanged)
        neverRadio.setAccessibilityLabel("Never ends")
        neverRadio.setAccessibilityHelp("Select for unlimited recurrence")
        stack.addArrangedSubview(neverRadio)

        // On date
        let dateStack = NSStackView()
        dateStack.orientation = .vertical
        dateStack.alignment = .leading
        dateStack.spacing = 8

        onDateRadio.target = self
        onDateRadio.action = #selector(endConditionChanged)
        onDateRadio.setAccessibilityLabel("Ends on date")
        onDateRadio.setAccessibilityHelp("Select to end recurrence on a specific date")
        dateStack.addArrangedSubview(onDateRadio)

        endDatePicker.datePickerStyle = .clockAndCalendar
        endDatePicker.dateValue = endDate
        endDatePicker.target = self
        endDatePicker.action = #selector(endDateChanged)
        endDatePicker.setAccessibilityLabel("End date")
        endDatePicker.setAccessibilityHelp("Select when the recurrence should end")
        dateStack.addArrangedSubview(endDatePicker)

        stack.addArrangedSubview(dateStack)

        // After count
        let countStack = NSStackView()
        countStack.orientation = .horizontal
        countStack.spacing = 8

        afterCountRadio.target = self
        afterCountRadio.action = #selector(endConditionChanged)
        afterCountRadio.setAccessibilityLabel("Ends after count")
        afterCountRadio.setAccessibilityHelp("Select to end after a specific number of occurrences")

        countStepper.minValue = 1
        countStepper.maxValue = 999
        countStepper.integerValue = 10
        countStepper.target = self
        countStepper.action = #selector(countChanged)
        countStepper.setAccessibilityLabel("Number of occurrences")
        countStepper.setAccessibilityHelp("Adjust how many times the task should repeat")

        countLabel.isEditable = false
        countLabel.isBordered = false
        countLabel.backgroundColor = .clear
        countLabel.setAccessibilityLabel("Occurrence count")

        countStack.addArrangedSubview(afterCountRadio)
        countStack.addArrangedSubview(countLabel)
        countStack.addArrangedSubview(countStepper)
        countStack.addArrangedSubview(NSTextField(labelWithString: "occurrences"))

        stack.addArrangedSubview(countStack)
    }

    // MARK: - Actions

    @objc private func enableCheckboxChanged() {
        isEnabled = enableCheckbox.state == .on
        updateRecurrence()
        updateUI()
    }

    @objc private func frequencyChanged() {
        let frequencies: [RecurrenceFrequency] = [.daily, .weekly, .monthly, .yearly]
        frequency = frequencies[frequencyPopup.indexOfSelectedItem]
        updateIntervalUnit()
        updateRecurrence()
        updateUI()
    }

    @objc private func intervalChanged() {
        interval = intervalStepper.integerValue
        intervalLabel.stringValue = "\(interval)"
        updateIntervalUnit()
        updateRecurrence()
    }

    @objc private func dayButtonClicked(_ sender: NSButton) {
        let day = sender.tag
        if sender.state == .on {
            selectedDays.insert(day)
        } else {
            selectedDays.remove(day)
        }
        updateRecurrence()
    }

    @objc private func monthlyOptionChanged() {
        useLastDayOfMonth = lastDayRadio.state == .on
        dayOfMonthRadio.state = useLastDayOfMonth ? .off : .on
        lastDayRadio.state = useLastDayOfMonth ? .on : .off
        dayOfMonthStepper.isEnabled = !useLastDayOfMonth
        updateRecurrence()
    }

    @objc private func dayOfMonthChanged() {
        dayOfMonth = dayOfMonthStepper.integerValue
        dayOfMonthLabel.stringValue = "\(dayOfMonth)"
        useLastDayOfMonth = false
        dayOfMonthRadio.state = .on
        lastDayRadio.state = .off
        updateRecurrence()
    }

    @objc private func endConditionChanged() {
        if neverRadio.state == .on {
            endCondition = .never
            onDateRadio.state = .off
            afterCountRadio.state = .off
        } else if onDateRadio.state == .on {
            endCondition = .onDate
            neverRadio.state = .off
            afterCountRadio.state = .off
        } else if afterCountRadio.state == .on {
            endCondition = .afterCount
            neverRadio.state = .off
            onDateRadio.state = .off
        }

        endDatePicker.isEnabled = endCondition == .onDate
        countStepper.isEnabled = endCondition == .afterCount
        updateRecurrence()
    }

    @objc private func endDateChanged() {
        endDate = endDatePicker.dateValue
        updateRecurrence()
    }

    @objc private func countChanged() {
        count = countStepper.integerValue
        countLabel.stringValue = "\(count)"
        updateRecurrence()
    }

    // MARK: - Helper Methods

    private func updateIntervalUnit() {
        switch frequency {
        case .daily:
            intervalUnitLabel.stringValue = interval == 1 ? "day" : "days"
        case .weekly:
            intervalUnitLabel.stringValue = interval == 1 ? "week" : "weeks"
        case .monthly:
            intervalUnitLabel.stringValue = interval == 1 ? "month" : "months"
        case .yearly:
            intervalUnitLabel.stringValue = interval == 1 ? "year" : "years"
        case .custom:
            intervalUnitLabel.stringValue = "interval"
        }
    }

    private func updateUI() {
        enableCheckbox.state = isEnabled ? .on : .off
        settingsContainer.isHidden = !isEnabled

        if let rec = recurrence {
            isEnabled = true
            frequency = rec.frequency
            interval = rec.interval
            selectedDays = Set(rec.daysOfWeek ?? [])
            dayOfMonth = rec.dayOfMonth ?? 1
            useLastDayOfMonth = rec.useLastDayOfMonth

            if rec.endDate != nil {
                endCondition = .onDate
                endDate = rec.endDate!
            } else if rec.count != nil {
                endCondition = .afterCount
                count = rec.count!
            } else {
                endCondition = .never
            }

            // Update UI controls
            frequencyPopup.selectItem(at: [RecurrenceFrequency.daily, .weekly, .monthly, .yearly].firstIndex(of: frequency) ?? 0)
            intervalStepper.integerValue = interval
            intervalLabel.stringValue = "\(interval)"
            updateIntervalUnit()

            // Update day buttons
            for (index, button) in dayButtons.enumerated() {
                button.state = selectedDays.contains(index) ? .on : .off
            }

            // Update monthly options
            dayOfMonthRadio.state = useLastDayOfMonth ? .off : .on
            lastDayRadio.state = useLastDayOfMonth ? .on : .off
            dayOfMonthStepper.integerValue = dayOfMonth
            dayOfMonthLabel.stringValue = "\(dayOfMonth)"
            dayOfMonthStepper.isEnabled = !useLastDayOfMonth

            // Update end condition
            neverRadio.state = endCondition == .never ? .on : .off
            onDateRadio.state = endCondition == .onDate ? .on : .off
            afterCountRadio.state = endCondition == .afterCount ? .on : .off
            endDatePicker.dateValue = endDate
            endDatePicker.isEnabled = endCondition == .onDate
            countStepper.integerValue = count
            countLabel.stringValue = "\(count)"
            countStepper.isEnabled = endCondition == .afterCount
        }

        // Show/hide frequency-specific sections
        weeklyDaysStack.isHidden = frequency != .weekly || !isEnabled
        monthlyStack.isHidden = frequency != .monthly || !isEnabled
        previewStack?.isHidden = !isEnabled

        // Update preview
        if isEnabled {
            updatePreviewSection()
        }
    }

    private func updateRecurrence() {
        guard isEnabled else {
            recurrence = nil
            onChange?(nil)
            return
        }

        recurrence = Recurrence(
            frequency: frequency,
            interval: interval,
            daysOfWeek: frequency == .weekly ? Array(selectedDays) : nil,
            dayOfMonth: frequency == .monthly && !useLastDayOfMonth ? dayOfMonth : nil,
            useLastDayOfMonth: frequency == .monthly && useLastDayOfMonth,
            endDate: endCondition == .onDate ? endDate : nil,
            count: endCondition == .afterCount ? count : nil,
            occurrenceCount: recurrence?.occurrenceCount ?? 0
        )

        onChange?(recurrence)
    }

    // MARK: - Preview Section

    private func createPreviewSection() -> NSStackView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        // Header
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.spacing = 6

        let iconLabel = NSTextField(labelWithString: "📅")
        iconLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        headerStack.addArrangedSubview(iconLabel)

        let titleLabel = NSTextField(labelWithString: "Next Occurrences")
        titleLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor
        headerStack.addArrangedSubview(titleLabel)

        container.addArrangedSubview(headerStack)

        // Content container
        let contentContainer = NSView()
        contentContainer.wantsLayer = true
        contentContainer.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.05).cgColor
        contentContainer.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
        contentContainer.layer?.borderWidth = 1
        contentContainer.layer?.cornerRadius = 8
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 6
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -12),
            contentContainer.widthAnchor.constraint(equalToConstant: 300)
        ])

        container.addArrangedSubview(contentContainer)
        container.setAccessibilityLabel("Next occurrences preview")

        return container
    }

    private func updatePreviewSection() {
        guard let container = previewStack?.arrangedSubviews.last as? NSView,
              let contentStack = container.subviews.first as? NSStackView else {
            return
        }

        // Clear existing content
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if let recurrence = recurrence, !recurrence.isComplete {
            let occurrences = calculateNextOccurrences()

            for (index, date) in occurrences.enumerated() {
                let rowStack = NSStackView()
                rowStack.orientation = .horizontal
                rowStack.spacing = 8

                // Bullet point
                let bullet = NSView()
                bullet.wantsLayer = true
                bullet.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.3).cgColor
                bullet.layer?.cornerRadius = 3
                bullet.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    bullet.widthAnchor.constraint(equalToConstant: 6),
                    bullet.heightAnchor.constraint(equalToConstant: 6)
                ])
                rowStack.addArrangedSubview(bullet)

                // Date label
                let dateLabel = NSTextField(labelWithString: formatDate(date, index: index))
                dateLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
                dateLabel.textColor = .labelColor
                dateLabel.isEditable = false
                dateLabel.isBordered = false
                dateLabel.backgroundColor = .clear
                dateLabel.setAccessibilityLabel("Occurrence \(index + 1): \(formatDateForAccessibility(date))")
                rowStack.addArrangedSubview(dateLabel)

                contentStack.addArrangedSubview(rowStack)
            }

            // Show end condition if applicable
            if let endInfo = endConditionInfo {
                let endLabel = NSTextField(labelWithString: endInfo)
                endLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize - 1)
                endLabel.textColor = .secondaryLabelColor
                endLabel.isEditable = false
                endLabel.isBordered = false
                endLabel.backgroundColor = .clear
                endLabel.lineBreakMode = .byWordWrapping
                endLabel.setAccessibilityLabel(endInfo)

                let indentedStack = NSStackView()
                indentedStack.orientation = .horizontal
                indentedStack.spacing = 14
                let spacer = NSView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                spacer.widthAnchor.constraint(equalToConstant: 14).isActive = true
                indentedStack.addArrangedSubview(spacer)
                indentedStack.addArrangedSubview(endLabel)

                contentStack.addArrangedSubview(indentedStack)
            }
        } else if recurrence?.isComplete == true {
            let completedStack = NSStackView()
            completedStack.orientation = .horizontal
            completedStack.spacing = 8

            let checkLabel = NSTextField(labelWithString: "✓")
            checkLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
            checkLabel.textColor = NSColor.systemGreen
            completedStack.addArrangedSubview(checkLabel)

            let messageLabel = NSTextField(labelWithString: "Recurrence completed")
            messageLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
            messageLabel.textColor = .secondaryLabelColor
            messageLabel.isEditable = false
            messageLabel.isBordered = false
            messageLabel.backgroundColor = .clear
            completedStack.addArrangedSubview(messageLabel)

            contentStack.addArrangedSubview(completedStack)
        } else {
            let messageLabel = NSTextField(labelWithString: "No recurrence pattern set")
            messageLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
            messageLabel.textColor = .secondaryLabelColor
            messageLabel.isEditable = false
            messageLabel.isBordered = false
            messageLabel.backgroundColor = .clear
            contentStack.addArrangedSubview(messageLabel)
        }
    }

    private func calculateNextOccurrences() -> [Date] {
        guard let recurrence = recurrence else { return [] }

        var occurrences: [Date] = []
        var currentDate = Date()
        var iterationCount = 0
        let maxIterations = 10 // Safety limit

        while occurrences.count < 5 && iterationCount < maxIterations {
            guard let nextDate = RecurrenceEngine.calculateNextOccurrence(
                from: currentDate,
                recurrence: recurrence
            ) else {
                break
            }

            // Check if we've exceeded count limit
            if let maxCount = recurrence.count,
               recurrence.occurrenceCount + occurrences.count >= maxCount {
                break
            }

            // Check if we've exceeded end date
            if let endDate = recurrence.endDate, nextDate > endDate {
                break
            }

            occurrences.append(nextDate)
            currentDate = nextDate
            iterationCount += 1
        }

        return occurrences
    }

    private func formatDate(_ date: Date, index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }

    private func formatDateForAccessibility(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }

    private var endConditionInfo: String? {
        guard let recurrence = recurrence else { return nil }

        if let endDate = recurrence.endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Ends on \(formatter.string(from: endDate))"
        } else if let maxCount = recurrence.count {
            let remaining = maxCount - recurrence.occurrenceCount
            return "Ends after \(remaining) more occurrence\(remaining == 1 ? "" : "s")"
        }

        return nil
    }

    // MARK: - Intrinsic Content Size

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 350, height: isEnabled ? 600 : 30)
    }
}
