//
//  OnboardingFlow.swift
//  StickyToDo-SwiftUI
//
//  Manages the onboarding flow and coordination with app state.
//  Handles first-run detection and sample data generation.
//

import SwiftUI
import Combine
import StickyToDoCore

/// Coordinator for the onboarding flow
@MainActor
class OnboardingCoordinator: ObservableObject {

    // MARK: - Published Properties

    @Published var showOnboarding = false
    @Published var isComplete = false
    @Published var currentStep: OnboardingStep = .welcome
    @Published var showDirectoryPicker = false
    @Published var showPermissions = false
    @Published var showQuickTour = false

    // MARK: - Configuration State

    @Published var selectedDirectory: URL?
    @Published var createSampleData = true

    // MARK: - Properties

    private let onboardingManager = OnboardingManager.shared
    private let configManager = ConfigurationManager.shared

    // MARK: - Initialization

    init() {
        // Default directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.selectedDirectory = documentsURL.appendingPathComponent("StickyToDo")
    }

    // MARK: - Methods

    /// Checks if onboarding should be shown
    func checkForFirstRun() {
        showOnboarding = onboardingManager.shouldShowOnboarding
    }

    /// Starts the onboarding flow
    func startOnboarding() {
        currentStep = .welcome
        showOnboarding = true
    }

    /// Advances to the next onboarding step
    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .directory
        case .directory:
            currentStep = .permissions
        case .permissions:
            currentStep = .quickTour
        case .quickTour:
            completeOnboarding()
        }
    }

    /// Skips optional steps
    func skipToCompletion() {
        completeOnboarding()
    }

    /// Completes the onboarding flow
    func completeOnboarding() {
        Task {
            // 1. Setup directory structure
            await setupDirectoryStructure()

            // 2. Update configuration
            if let directory = selectedDirectory {
                configManager.changeDataDirectory(to: directory)
            }

            // 3. Create sample data if requested
            if createSampleData {
                await createSampleData()
            }

            // 4. Mark onboarding as complete
            onboardingManager.markOnboardingComplete()
            configManager.isFirstRun = false
            configManager.save()

            // 5. Finish
            await MainActor.run {
                isComplete = true
                showOnboarding = false
            }
        }
    }

    // MARK: - Directory Setup

    /// Sets up the directory structure
    private func setupDirectoryStructure() async {
        guard let directory = selectedDirectory else { return }

        do {
            let fileManager = FileManager.default

            // Create main directory
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            // Create subdirectories
            let subdirectories = [
                "tasks",
                "tasks/active",
                "tasks/archive",
                "boards",
                "perspectives",
                "templates",
                "attachments",
                "config"
            ]

            for subdir in subdirectories {
                let subdirURL = directory.appendingPathComponent(subdir)
                if !fileManager.fileExists(atPath: subdirURL.path) {
                    try fileManager.createDirectory(at: subdirURL, withIntermediateDirectories: true)
                }
            }

            // Create .stickytodo marker file
            let markerURL = directory.appendingPathComponent(".stickytodo")
            let markerContent = """
            # StickyToDo Data Directory
            Created: \(Date())
            Version: 1.0
            """
            try markerContent.write(to: markerURL, atomically: true, encoding: .utf8)

            onboardingManager.markDirectorySetupComplete()
            print("✅ Directory structure created at: \(directory.path)")
        } catch {
            print("❌ Error creating directory structure: \(error)")
        }
    }

    // MARK: - Sample Data

    /// Creates sample data for the user to explore
    private func createSampleData() async {
        print("📦 Creating sample data...")

        let result = SampleDataGenerator.generateSampleData()

        switch result {
        case .success(let sampleData):
            // TODO: Add tasks and boards to data stores
            // This would require access to TaskStore and BoardStore
            print("✅ Sample data created: \(sampleData.totalItems) items")
            onboardingManager.markSampleDataCreated()

        case .failure(let error):
            print("❌ Error creating sample data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

/// Onboarding flow steps
enum OnboardingStep {
    case welcome
    case directory
    case permissions
    case quickTour
}

// MARK: - Onboarding Container View

/// Container view that manages onboarding presentation
struct OnboardingContainer: View {

    @StateObject private var coordinator = OnboardingCoordinator()

    var body: some View {
        Color.clear
            .sheet(isPresented: $coordinator.showOnboarding) {
                onboardingFlow
            }
            .onAppear {
                coordinator.checkForFirstRun()
            }
    }

    @ViewBuilder
    private var onboardingFlow: some View {
        switch coordinator.currentStep {
        case .welcome:
            WelcomeView { config in
                coordinator.selectedDirectory = config.dataDirectory
                coordinator.createSampleData = config.createSampleData
                coordinator.nextStep()
            }

        case .directory:
            DirectoryPickerView { directory in
                coordinator.selectedDirectory = directory
                coordinator.nextStep()
            }

        case .permissions:
            PermissionRequestView {
                coordinator.nextStep()
            }

        case .quickTour:
            QuickTourView {
                coordinator.completeOnboarding()
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Presents onboarding flow if needed
    func withOnboarding() -> some View {
        self.overlay(
            OnboardingContainer()
        )
    }
}

// MARK: - Preview

#Preview("Onboarding Flow") {
    Color.gray
        .withOnboarding()
}
