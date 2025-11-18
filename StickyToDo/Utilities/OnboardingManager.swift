//
//  OnboardingManager.swift
//  StickyToDo
//
//  Manages onboarding state, first-run detection, and completion tracking.
//  Provides utilities for checking and managing the first-run experience.
//

import Foundation
import Combine

/// Manages onboarding state and first-run experience
///
/// OnboardingManager provides:
/// - First-run detection via UserDefaults
/// - Onboarding completion tracking
/// - Permission status tracking
/// - Reset capability for testing
@MainActor
public class OnboardingManager: ObservableObject {

    // MARK: - Singleton

    public static let shared = OnboardingManager()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let onboardingVersion = "onboardingVersion"
        static let hasCompletedDirectorySetup = "hasCompletedDirectorySetup"
        static let hasCompletedPermissionSetup = "hasCompletedPermissionSetup"
        static let hasViewedQuickTour = "hasViewedQuickTour"
        static let hasCreatedSampleData = "hasCreatedSampleData"
        static let siriPermissionRequested = "siriPermissionRequested"
        static let notificationPermissionRequested = "notificationPermissionRequested"
        static let calendarPermissionRequested = "calendarPermissionRequested"
    }

    // MARK: - Published Properties

    /// Whether the user has completed the onboarding flow
    @Published public private(set) var hasCompletedOnboarding: Bool

    /// Current onboarding version (used to show onboarding again when major features are added)
    @Published public private(set) var onboardingVersion: Int

    /// Whether directory setup is complete
    @Published public private(set) var hasCompletedDirectorySetup: Bool

    /// Whether permission setup is complete
    @Published public private(set) var hasCompletedPermissionSetup: Bool

    /// Whether user has viewed the quick tour
    @Published public private(set) var hasViewedQuickTour: Bool

    /// Whether sample data was created
    @Published public private(set) var hasCreatedSampleData: Bool

    /// Permission request tracking
    @Published public private(set) var siriPermissionRequested: Bool
    @Published public private(set) var notificationPermissionRequested: Bool
    @Published public private(set) var calendarPermissionRequested: Bool

    // MARK: - Constants

    /// Current version of the onboarding flow (increment when adding new features)
    public static let currentVersion = 1

    // MARK: - Initialization

    private init() {
        // Load state from UserDefaults
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        self.onboardingVersion = UserDefaults.standard.integer(forKey: Keys.onboardingVersion)
        self.hasCompletedDirectorySetup = UserDefaults.standard.bool(forKey: Keys.hasCompletedDirectorySetup)
        self.hasCompletedPermissionSetup = UserDefaults.standard.bool(forKey: Keys.hasCompletedPermissionSetup)
        self.hasViewedQuickTour = UserDefaults.standard.bool(forKey: Keys.hasViewedQuickTour)
        self.hasCreatedSampleData = UserDefaults.standard.bool(forKey: Keys.hasCreatedSampleData)
        self.siriPermissionRequested = UserDefaults.standard.bool(forKey: Keys.siriPermissionRequested)
        self.notificationPermissionRequested = UserDefaults.standard.bool(forKey: Keys.notificationPermissionRequested)
        self.calendarPermissionRequested = UserDefaults.standard.bool(forKey: Keys.calendarPermissionRequested)
    }

    // MARK: - Public Methods

    /// Returns true if onboarding should be shown
    public var shouldShowOnboarding: Bool {
        // Show onboarding if not completed or version is outdated
        return !hasCompletedOnboarding || onboardingVersion < Self.currentVersion
    }

    /// Marks onboarding as complete
    public func markOnboardingComplete() {
        hasCompletedOnboarding = true
        onboardingVersion = Self.currentVersion
        UserDefaults.standard.set(true, forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.set(Self.currentVersion, forKey: Keys.onboardingVersion)
        UserDefaults.standard.synchronize()
    }

    /// Marks directory setup as complete
    public func markDirectorySetupComplete() {
        hasCompletedDirectorySetup = true
        UserDefaults.standard.set(true, forKey: Keys.hasCompletedDirectorySetup)
        UserDefaults.standard.synchronize()
    }

    /// Marks permission setup as complete
    public func markPermissionSetupComplete() {
        hasCompletedPermissionSetup = true
        UserDefaults.standard.set(true, forKey: Keys.hasCompletedPermissionSetup)
        UserDefaults.standard.synchronize()
    }

    /// Marks quick tour as viewed
    public func markQuickTourViewed() {
        hasViewedQuickTour = true
        UserDefaults.standard.set(true, forKey: Keys.hasViewedQuickTour)
        UserDefaults.standard.synchronize()
    }

    /// Marks sample data as created
    public func markSampleDataCreated() {
        hasCreatedSampleData = true
        UserDefaults.standard.set(true, forKey: Keys.hasCreatedSampleData)
        UserDefaults.standard.synchronize()
    }

    /// Marks Siri permission as requested
    public func markSiriPermissionRequested() {
        siriPermissionRequested = true
        UserDefaults.standard.set(true, forKey: Keys.siriPermissionRequested)
        UserDefaults.standard.synchronize()
    }

    /// Marks notification permission as requested
    public func markNotificationPermissionRequested() {
        notificationPermissionRequested = true
        UserDefaults.standard.set(true, forKey: Keys.notificationPermissionRequested)
        UserDefaults.standard.synchronize()
    }

    /// Marks calendar permission as requested
    public func markCalendarPermissionRequested() {
        calendarPermissionRequested = true
        UserDefaults.standard.set(true, forKey: Keys.calendarPermissionRequested)
        UserDefaults.standard.synchronize()
    }

    /// Resets all onboarding state (useful for testing)
    public func resetOnboarding() {
        hasCompletedOnboarding = false
        onboardingVersion = 0
        hasCompletedDirectorySetup = false
        hasCompletedPermissionSetup = false
        hasViewedQuickTour = false
        hasCreatedSampleData = false
        siriPermissionRequested = false
        notificationPermissionRequested = false
        calendarPermissionRequested = false

        UserDefaults.standard.removeObject(forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: Keys.onboardingVersion)
        UserDefaults.standard.removeObject(forKey: Keys.hasCompletedDirectorySetup)
        UserDefaults.standard.removeObject(forKey: Keys.hasCompletedPermissionSetup)
        UserDefaults.standard.removeObject(forKey: Keys.hasViewedQuickTour)
        UserDefaults.standard.removeObject(forKey: Keys.hasCreatedSampleData)
        UserDefaults.standard.removeObject(forKey: Keys.siriPermissionRequested)
        UserDefaults.standard.removeObject(forKey: Keys.notificationPermissionRequested)
        UserDefaults.standard.removeObject(forKey: Keys.calendarPermissionRequested)
        UserDefaults.standard.synchronize()
    }

    /// Checks if onboarding should be shown and returns the reason
    public func onboardingReason() -> OnboardingReason? {
        if !hasCompletedOnboarding {
            return .firstRun
        } else if onboardingVersion < Self.currentVersion {
            return .newVersion(from: onboardingVersion, to: Self.currentVersion)
        }
        return nil
    }
}

// MARK: - Supporting Types

/// Reasons for showing onboarding
public enum OnboardingReason {
    case firstRun
    case newVersion(from: Int, to: Int)

    public var description: String {
        switch self {
        case .firstRun:
            return "Welcome to StickyToDo! Let's get you set up."
        case .newVersion(let from, let to):
            return "Welcome back! We've added new features (v\(from) → v\(to))."
        }
    }
}
