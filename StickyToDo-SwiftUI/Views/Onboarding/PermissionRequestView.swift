//
//  PermissionRequestView.swift
//  StickyToDo-SwiftUI
//
//  Permission request flow for onboarding.
//  Handles Siri, Notifications, Calendar, and Spotlight permissions.
//

import SwiftUI
import UserNotifications
import EventKit
import Intents
import StickyToDoCore

/// Permission request view for onboarding flow
struct PermissionRequestView: View {

    @StateObject private var viewModel = PermissionRequestViewModel()
    @Environment(\.dismiss) private var dismiss

    var onComplete: (() -> Void)?

    var body: some View {
        TabView(selection: $viewModel.currentStep) {
            // Notifications permission
            notificationsPermissionPage
                .tag(PermissionStep.notifications)

            // Calendar permission
            calendarPermissionPage
                .tag(PermissionStep.calendar)

            // Siri permission
            siriPermissionPage
                .tag(PermissionStep.siri)

            // Spotlight info
            spotlightInfoPage
                .tag(PermissionStep.spotlight)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(width: 700, height: 550)
        .overlay(alignment: .bottom) {
            bottomBar
                .padding()
                .background(.ultraThinMaterial)
        }
        .overlay(alignment: .top) {
            progressIndicator
                .padding(.top, 20)
        }
    }

    // MARK: - Permission Pages

    private var notificationsPermissionPage: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "bell.badge")
                .font(.system(size: 80))
                .foregroundColor(.orange)
                .symbolEffect(.bounce, value: viewModel.currentStep == .notifications)

            // Title
            Text("Stay on Track")
                .font(.system(size: 32, weight: .bold))

            // Description
            Text("Get notified about due dates, weekly reviews, and important tasks.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            // Benefits
            VStack(alignment: .leading, spacing: 16) {
                PermissionBenefitRow(
                    icon: "calendar.badge.clock",
                    title: "Due Date Reminders",
                    description: "Never miss a deadline with timely notifications"
                )

                PermissionBenefitRow(
                    icon: "arrow.clockwise",
                    title: "Weekly Review",
                    description: "Stay organized with weekly review reminders"
                )

                PermissionBenefitRow(
                    icon: "timer",
                    title: "Timer Alerts",
                    description: "Get notified when timers complete"
                )
            }
            .padding(.horizontal, 60)

            // Status
            if let status = viewModel.notificationStatus {
                PermissionStatusBadge(status: status)
            }

            Spacer()
        }
        .padding()
    }

    private var calendarPermissionPage: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .symbolEffect(.bounce, value: viewModel.currentStep == .calendar)

            // Title
            Text("Two-Way Calendar Sync")
                .font(.system(size: 32, weight: .bold))

            // Description
            Text("Sync tasks with your calendar for a unified view of your schedule.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            // Benefits
            VStack(alignment: .leading, spacing: 16) {
                PermissionBenefitRow(
                    icon: "arrow.left.arrow.right",
                    title: "Two-Way Sync",
                    description: "Tasks with due dates appear in your calendar"
                )

                PermissionBenefitRow(
                    icon: "eye",
                    title: "Unified View",
                    description: "See tasks alongside meetings and events"
                )

                PermissionBenefitRow(
                    icon: "checkmark.circle",
                    title: "Automatic Updates",
                    description: "Changes sync both ways automatically"
                )
            }
            .padding(.horizontal, 60)

            // Status
            if let status = viewModel.calendarStatus {
                PermissionStatusBadge(status: status)
            }

            Spacer()
        }
        .padding()
    }

    private var siriPermissionPage: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "waveform.circle")
                .font(.system(size: 80))
                .foregroundColor(.purple)
                .symbolEffect(.bounce, value: viewModel.currentStep == .siri)

            // Title
            Text("Siri Integration")
                .font(.system(size: 32, weight: .bold))

            // Description
            Text("Capture tasks hands-free with Siri voice commands.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            // Example commands
            VStack(alignment: .leading, spacing: 12) {
                Text("Example Commands:")
                    .font(.headline)
                    .padding(.bottom, 4)

                SiriCommandExample(command: "Add task: Call the dentist")
                SiriCommandExample(command: "Show my tasks")
                SiriCommandExample(command: "What's due today?")
                SiriCommandExample(command: "Complete task: Finish report")
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .padding(.horizontal, 60)

            // Status
            if let status = viewModel.siriStatus {
                PermissionStatusBadge(status: status)
            }

            Spacer()
        }
        .padding()
    }

    private var spotlightInfoPage: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .symbolEffect(.bounce, value: viewModel.currentStep == .spotlight)

            // Title
            Text("Spotlight Search")
                .font(.system(size: 32, weight: .bold))

            // Description
            Text("Find your tasks instantly from anywhere on your Mac with Spotlight.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            // Benefits
            VStack(alignment: .leading, spacing: 16) {
                PermissionBenefitRow(
                    icon: "command",
                    title: "System-Wide Search",
                    description: "Press ⌘+Space and search for any task"
                )

                PermissionBenefitRow(
                    icon: "bolt.fill",
                    title: "Instant Results",
                    description: "Tasks appear in Spotlight immediately"
                )

                PermissionBenefitRow(
                    icon: "checkmark.circle.fill",
                    title: "Automatic Indexing",
                    description: "No setup required - works automatically"
                )
            }
            .padding(.horizontal, 60)

            // Info badge
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.green)
                Text("No permission required - Spotlight indexing is automatic")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)

            Spacer()
        }
        .padding()
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button("Skip All") {
                viewModel.skipAll()
                onComplete?()
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Spacer()

            if viewModel.currentStep != .spotlight {
                Button("Skip") {
                    viewModel.skipCurrent()
                }
                .buttonStyle(.bordered)
            }

            if viewModel.currentStep == .spotlight {
                Button("Get Started") {
                    viewModel.complete()
                    onComplete?()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                if viewModel.canRequestCurrentPermission {
                    Button(viewModel.currentPermissionButtonTitle) {
                        viewModel.requestCurrentPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isRequesting)
                } else {
                    Button("Next") {
                        viewModel.nextStep()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(PermissionStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step == viewModel.currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.spring(), value: viewModel.currentStep)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}

// MARK: - Supporting Views

struct PermissionBenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct SiriCommandExample: View {
    let command: String

    var body: some View {
        HStack {
            Image(systemName: "quote.opening")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(command)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "quote.closing")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PermissionStatusBadge: View {
    let status: PermissionStatus

    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
            Text(status.message)
                .font(.callout)
                .foregroundColor(status.color)
        }
        .padding(12)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - View Model

@MainActor
class PermissionRequestViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentStep: PermissionStep = .notifications
    @Published var isRequesting = false

    @Published var notificationStatus: PermissionStatus?
    @Published var calendarStatus: PermissionStatus?
    @Published var siriStatus: PermissionStatus?

    // MARK: - Computed Properties

    var canRequestCurrentPermission: Bool {
        switch currentStep {
        case .notifications:
            return notificationStatus == nil || notificationStatus == .notRequested
        case .calendar:
            return calendarStatus == nil || calendarStatus == .notRequested
        case .siri:
            return siriStatus == nil || siriStatus == .notRequested
        case .spotlight:
            return false
        }
    }

    var currentPermissionButtonTitle: String {
        if let status = currentPermissionStatus, status == .granted {
            return "Next"
        }
        return "Allow Access"
    }

    private var currentPermissionStatus: PermissionStatus? {
        switch currentStep {
        case .notifications:
            return notificationStatus
        case .calendar:
            return calendarStatus
        case .siri:
            return siriStatus
        case .spotlight:
            return nil
        }
    }

    // MARK: - Methods

    func requestCurrentPermission() {
        isRequesting = true

        Task {
            switch currentStep {
            case .notifications:
                await requestNotificationPermission()
            case .calendar:
                await requestCalendarPermission()
            case .siri:
                await requestSiriPermission()
            case .spotlight:
                break
            }

            await MainActor.run {
                self.isRequesting = false
                // Auto-advance if granted
                if currentPermissionStatus == .granted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.nextStep()
                    }
                }
            }
        }
    }

    func skipCurrent() {
        nextStep()
    }

    func skipAll() {
        complete()
    }

    func nextStep() {
        if let nextIndex = PermissionStep.allCases.firstIndex(of: currentStep).map({ $0 + 1 }),
           nextIndex < PermissionStep.allCases.count {
            withAnimation {
                currentStep = PermissionStep.allCases[nextIndex]
            }
        }
    }

    func complete() {
        OnboardingManager.shared.markPermissionSetupComplete()
    }

    // MARK: - Permission Requests

    private func requestNotificationPermission() async {
        let granted = await NotificationManager.shared.requestAuthorization()
        await MainActor.run {
            self.notificationStatus = granted ? .granted : .denied
            OnboardingManager.shared.markNotificationPermissionRequested()
        }
    }

    private func requestCalendarPermission() async {
        await withCheckedContinuation { continuation in
            CalendarManager.shared.requestAuthorization { result in
                Task { @MainActor in
                    switch result {
                    case .success(let granted):
                        self.calendarStatus = granted ? .granted : .denied
                    case .failure:
                        self.calendarStatus = .denied
                    }
                    OnboardingManager.shared.markCalendarPermissionRequested()
                    continuation.resume()
                }
            }
        }
    }

    private func requestSiriPermission() async {
        // Request Siri/Intents permission
        let status = await INPreferences.requestSiriAuthorization()
        await MainActor.run {
            switch status {
            case .authorized:
                self.siriStatus = .granted
            case .denied, .restricted:
                self.siriStatus = .denied
            case .notDetermined:
                self.siriStatus = .notRequested
            @unknown default:
                self.siriStatus = .denied
            }
            OnboardingManager.shared.markSiriPermissionRequested()
        }
    }
}

// MARK: - Supporting Types

enum PermissionStep: CaseIterable {
    case notifications
    case calendar
    case siri
    case spotlight
}

enum PermissionStatus {
    case notRequested
    case granted
    case denied

    var icon: String {
        switch self {
        case .notRequested:
            return "questionmark.circle"
        case .granted:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .notRequested:
            return .gray
        case .granted:
            return .green
        case .denied:
            return .orange
        }
    }

    var message: String {
        switch self {
        case .notRequested:
            return "Not requested"
        case .granted:
            return "Access granted"
        case .denied:
            return "Access denied - You can change this in System Settings"
        }
    }
}

// MARK: - Siri Authorization Extension

extension INPreferences {
    static func requestSiriAuthorization() async -> INSiriAuthorizationStatus {
        await withCheckedContinuation { continuation in
            INPreferences.requestSiriAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PermissionRequestView()
}
