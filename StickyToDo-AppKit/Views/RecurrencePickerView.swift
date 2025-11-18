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

        intervalLabel.isEditable = false
        intervalLabel.isBordered = false
        intervalLabel.backgroundColor = .clear
        intervalLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)

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
        for (index, name) in dayNames.enumerated() {
            let button = NSButton(title: name, target: self, action: #selector(dayButtonClicked(_:)))
            button.setButtonType(.toggle)
            button.bezelStyle = .circular
            button.tag = index
            button.widthAnchor.constraint(equalToConstant: 32).isActive = true
            button.heightAnchor.constraint(equalToConstant: 32).isActive = true
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

        dayOfMonthStepper.minValue = 1
        dayOfMonthStepper.maxValue = 31
        dayOfMonthStepper.integerValue = 1
        dayOfMonthStepper.target = self
        dayOfMonthStepper.action = #selector(dayOfMonthChanged)

        dayOfMonthLabel.isEditable = false
        dayOfMonthLabel.isBordered = false
        dayOfMonthLabel.backgroundColor = .clear

        dayStack.addArrangedSubview(dayOfMonthRadio)
        dayStack.addArrangedSubview(NSTextField(labelWithString: "Day"))
        dayStack.addArrangedSubview(dayOfMonthLabel)
        dayStack.addArrangedSubview(dayOfMonthStepper)

        monthlyStack.addArrangedSubview(dayStack)

        // Last day option
        lastDayRadio.target = self
        lastDayRadio.action = #selector(monthlyOptionChanged)
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
        stack.addArrangedSubview(neverRadio)

        // On date
        let dateStack = NSStackView()
        dateStack.orientation = .vertical
        dateStack.alignment = .leading
        dateStack.spacing = 8

        onDateRadio.target = self
        onDateRadio.action = #selector(endConditionChanged)
        dateStack.addArrangedSubview(onDateRadio)

        endDatePicker.datePickerStyle = .clockAndCalendar
        endDatePicker.dateValue = endDate
        endDatePicker.target = self
        endDatePicker.action = #selector(endDateChanged)
        dateStack.addArrangedSubview(endDatePicker)

        stack.addArrangedSubview(dateStack)

        // After count
        let countStack = NSStackView()
        countStack.orientation = .horizontal
        countStack.spacing = 8

        afterCountRadio.target = self
        afterCountRadio.action = #selector(endConditionChanged)

        countStepper.minValue = 1
        countStepper.maxValue = 999
        countStepper.integerValue = 10
        countStepper.target = self
        countStepper.action = #selector(countChanged)

        countLabel.isEditable = false
        countLabel.isBordered = false
        countLabel.backgroundColor = .clear

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

    // MARK: - Intrinsic Content Size

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 350, height: isEnabled ? 500 : 30)
    }
}
