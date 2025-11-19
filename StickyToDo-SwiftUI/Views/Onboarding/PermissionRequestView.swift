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
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .orange.opacity(0.3), radius: 15, x: 0, y: 8)
                .symbolEffect(.bounce, options: .nonRepeating, value: viewModel.currentStep == .notifications)
                .symbolEffect(.wiggle, options: .speed(0.5).repeat(viewModel.notificationStatus == .granted ? 3 : 0), value: viewModel.notificationStatus)
                .scaleEffect(viewModel.notificationStatus == .granted ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.notificationStatus)
                .accessibilityHidden(true)

            // Title
            Text("Stay on Track")
                .font(.system(size: 36, weight: .bold))
                .tracking(0.3)
                .accessibilityAddTraits(.isHeader)

            // Description
            VStack(spacing: 8) {
                Text("Never miss what matters")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("Get timely reminders for due dates, weekly reviews, and timer completions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }

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
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                .symbolEffect(.bounce, options: .nonRepeating, value: viewModel.currentStep == .calendar)
                .symbolEffect(.pulse, options: .speed(0.5).repeat(viewModel.calendarStatus == .granted ? 2 : 0), value: viewModel.calendarStatus)
                .scaleEffect(viewModel.calendarStatus == .granted ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.calendarStatus)
                .accessibilityHidden(true)

            // Title
            Text("Calendar Integration")
                .font(.system(size: 36, weight: .bold))
                .tracking(0.3)
                .accessibilityAddTraits(.isHeader)

            // Description
            VStack(spacing: 8) {
                Text("Your tasks and calendar, unified")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("Two-way sync keeps your tasks and calendar events perfectly aligned")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }

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
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 8)
                .symbolEffect(.bounce, options: .nonRepeating, value: viewModel.currentStep == .siri)
                .symbolEffect(.variableColor, options: .speed(0.5).repeat(viewModel.siriStatus == .granted ? 3 : 0), value: viewModel.siriStatus)
                .scaleEffect(viewModel.siriStatus == .granted ? 1.15 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: viewModel.siriStatus)
                .accessibilityHidden(true)

            // Title
            Text("Siri Integration")
                .font(.system(size: 36, weight: .bold))
                .tracking(0.3)
                .accessibilityAddTraits(.isHeader)

            // Description
            VStack(spacing: 8) {
                Text("Your productivity assistant")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("Manage tasks hands-free with natural voice commands on all your devices")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }

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
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .green.opacity(0.3), radius: 15, x: 0, y: 8)
                .symbolEffect(.bounce, options: .nonRepeating, value: viewModel.currentStep == .spotlight)
                .symbolEffect(.pulse, options: .speed(0.5).repeating, value: viewModel.currentStep == .spotlight)
                .accessibilityHidden(true)

            // Title
            Text("Spotlight Search")
                .font(.system(size: 36, weight: .bold))
                .tracking(0.3)
                .accessibilityAddTraits(.isHeader)

            // Description
            VStack(spacing: 8) {
                Text("Find anything, instantly")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("Search your entire task library from anywhere on your Mac with ⌘Space")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }

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
        HStack(spacing: 16) {
            Button("Skip All") {
                viewModel.skipAll()
                onComplete?()
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .keyboardShortcut(.cancelAction)

            Spacer()

            if viewModel.currentStep != .spotlight {
                Button(action: {
                    viewModel.skipCurrent()
                }) {
                    Text("Skip")
                }
                .buttonStyle(.bordered)
            }

            if viewModel.currentStep == .spotlight {
                Button(action: {
                    viewModel.complete()
                    onComplete?()
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Continue to Quick Tour")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            } else {
                if viewModel.canRequestCurrentPermission {
                    Button(action: {
                        viewModel.requestCurrentPermission()
                    }) {
                        HStack(spacing: 6) {
                            if viewModel.isRequesting {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "hand.raised.fill")
                                    .font(.caption)
                            }
                            Text(viewModel.currentPermissionButtonTitle)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isRequesting)
                } else {
                    Button(action: {
                        viewModel.nextStep()
                    }) {
                        HStack(spacing: 6) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(PermissionStep.allCases, id: \.self) { step in
                RoundedRectangle(cornerRadius: 4)
                    .fill(step == viewModel.currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: step == viewModel.currentStep ? 24 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.currentStep)
                    .shadow(
                        color: step == viewModel.currentStep ? Color.accentColor.opacity(0.3) : .clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.caption)
                .foregroundColor(.purple)
                .symbolEffect(.variableColor, options: .repeating.speed(0.3), isActive: isHovered)

            Text(command)
                .font(.body)
                .foregroundColor(.primary)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.purple.opacity(isHovered ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.purple.opacity(isHovered ? 0.3 : 0.1), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct PermissionStatusBadge: View {
    let status: PermissionStatus

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.title3)
                .symbolEffect(.bounce, options: .nonRepeating, value: status)
                .symbolEffect(.pulse, options: .speed(0.5).repeat(status == .granted ? 2 : 0), value: status)
                .accessibilityHidden(true)

            Text(status.message)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(status.color.opacity(0.15))
                .shadow(
                    color: status.color.opacity(0.2),
                    radius: status == .granted ? 8 : 4,
                    x: 0,
                    y: status == .granted ? 4 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1 : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(status.message)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        .onChange(of: status) { _, _ in
            appeared = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
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
