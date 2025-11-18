//
//  AppStateInitializer.swift
//  StickyToDo-SwiftUI
//
//  Helper for initializing app state at launch for SwiftUI.
//  Handles data loading, first-run setup, and coordinator initialization.
//

import SwiftUI
import Combine

/// Handles application state initialization for SwiftUI app
///
/// This class:
/// - Initializes DataManager with proper directory
/// - Sets up SwiftUICoordinator
/// - Loads sample data on first run
/// - Configures file watching
/// - Provides observable state for SwiftUI
@MainActor
class AppStateInitializer: ObservableObject {

    // MARK: - Published Properties

    /// Whether initialization is complete
    @Published var isInitialized = false

    /// Whether initialization is in progress
    @Published var isInitializing = false

    /// Initialization error, if any
    @Published var initializationError: Error?

    /// Whether to show error alert
    @Published var showErrorAlert = false

    // MARK: - Properties

    /// Shared instance
    static let shared = AppStateInitializer()

    /// Data manager instance
    private(set) var dataManager: DataManager!

    /// App coordinator
    private(set) var coordinator: SwiftUICoordinator!

    /// Configuration manager
    private(set) var configManager: ConfigurationManager!

    // MARK: - Initialization

    private init() {
        // Private initializer for singleton
    }

    // MARK: - Setup Methods

    /// Initializes the application state
    ///
    /// This should be called in the SwiftUI App's init or .onAppear
    func initialize() async {
        guard !isInitialized && !isInitializing else { return }

        isInitializing = true

        do {
            try await performInitialization()
            isInitialized = true
            isInitializing = false
        } catch {
            initializationError = error
            showErrorAlert = true
            isInitializing = false
        }
    }

    // MARK: - Private Methods

    private func performInitialization() async throws {
        print("🚀 Initializing StickyToDo (SwiftUI)...")

        // Step 1: Initialize ConfigurationManager
        configManager = .shared
        configManager.load()
        print("✅ Configuration loaded")

        // Step 2: Check and create data directory
        let dataDirectory = configManager.dataDirectory
        try ensureDataDirectory(dataDirectory)
        print("✅ Data directory ready: \(dataDirectory.path)")

        // Step 3: Initialize DataManager
        dataManager = .shared
        dataManager.enableLogging = configManager.enableLogging
        dataManager.enableFileWatching = configManager.enableFileWatching

        try await dataManager.initialize(rootDirectory: dataDirectory)
        print("✅ DataManager initialized")
        print("   - Tasks: \(dataManager.taskStore.taskCount)")
        print("   - Boards: \(dataManager.boardStore.boardCount)")

        // Step 4: First run setup
        if configManager.isFirstRun {
            performFirstRunSetup()
        }

        // Step 5: Initialize Coordinator
        coordinator = SwiftUICoordinator(dataManager: dataManager, configManager: configManager)
        try await coordinator.initialize()
        print("✅ Coordinator initialized")

        // Step 6: Restore last state
        restoreLastState()
        print("✅ App state restored")

        // Step 7: Perform first-run UI setup if needed
        coordinator.performFirstRunSetupIfNeeded()

        print("🎉 Initialization complete!")
    }

    private func ensureDataDirectory(_ url: URL) throws {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            print("📁 Created data directory: \(url.path)")
        }
    }

    private func performFirstRunSetup() {
        print("👋 First run detected - setting up...")

        // Create sample data
        dataManager.performFirstRunSetup(createSampleData: true)

        // Create default contexts
        createDefaultContexts()

        // Mark first run as complete
        configManager.isFirstRun = false
        configManager.save()

        print("✅ First run setup complete")
    }

    private func createDefaultContexts() {
        // Default contexts are created automatically by Context.defaults
        // But we can ensure they have boards

        for context in Context.defaults {
            let _ = dataManager.boardStore.getOrCreateContextBoard(for: context)
        }

        print("✅ Created default context boards")
    }

    private func restoreLastState() {
        // Restore last perspective or board
        if let perspectiveID = configManager.lastPerspectiveID,
           let perspective = Perspective.builtInPerspectives.first(where: { $0.id == perspectiveID }) {
            coordinator.navigateToPerspective(perspective)
        } else if let boardID = configManager.lastBoardID,
                  let board = dataManager.boardStore.board(withID: boardID) {
            coordinator.navigateToBoard(board)
        } else {
            // Default to Inbox
            coordinator.navigateToPerspective(.inbox)
        }

        // Restore view mode
        coordinator.switchViewMode(to: configManager.lastViewMode)

        // Restore inspector visibility
        coordinator.isInspectorVisible = configManager.inspectorVisible
    }

    // MARK: - Cleanup

    /// Performs cleanup before app terminates
    func cleanup() {
        print("🧹 Cleaning up app state...")

        do {
            try coordinator.saveBeforeQuit()
            print("✅ State saved")
        } catch {
            print("❌ Failed to save state: \(error)")
        }

        coordinator.cleanup()
        print("✅ Cleanup complete")
    }

    // MARK: - Error Recovery

    /// Allows user to choose a different data directory
    func chooseDataDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Select Data Directory"
        openPanel.message = "Choose where StickyToDo should store its data"

        openPanel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = openPanel.url else {
                return
            }

            Task { @MainActor in
                // Update config and retry
                self.configManager.changeDataDirectory(to: url)
                self.initializationError = nil
                self.showErrorAlert = false
                await self.initialize()
            }
        }
    }
}

// MARK: - App Extension

extension StickyToDoApp {

    /// Initialize app state in the App's init
    func initializeAppState() {
        Task {
            await AppStateInitializer.shared.initialize()
        }
    }

    /// Cleanup on app termination
    func cleanupAppState() {
        AppStateInitializer.shared.cleanup()
    }
}

// MARK: - Error Alert View

/// SwiftUI view for displaying initialization errors
struct InitializationErrorView: View {

    @ObservedObject var initializer: AppStateInitializer

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text("Failed to Initialize")
                .font(.title)
                .fontWeight(.bold)

            if let error = initializer.initializationError {
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Text("Data directory: \(initializer.configManager.dataDirectory.path)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button("Choose Different Directory") {
                    initializer.chooseDataDirectory()
                }

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut(.escape)
            }
            .padding(.top)
        }
        .frame(width: 500, height: 400)
        .padding()
    }
}

// MARK: - Loading View

/// SwiftUI view for displaying initialization progress
struct InitializationLoadingView: View {

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading StickyToDo...")
                .font(.title2)
                .fontWeight(.medium)

            Text("Setting up your workspace...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(width: 400, height: 300)
    }
}

// MARK: - Main Content View Wrapper

/// Wrapper view that handles initialization state
struct AppContentView: View {

    @StateObject private var initializer = AppStateInitializer.shared

    var body: some View {
        Group {
            if initializer.isInitializing {
                InitializationLoadingView()
            } else if initializer.showErrorAlert {
                InitializationErrorView(initializer: initializer)
            } else if initializer.isInitialized {
                ContentView()
                    .environmentObject(initializer.coordinator)
                    .environmentObject(initializer.dataManager)
            } else {
                // Initial state - trigger initialization
                Color.clear
                    .task {
                        await initializer.initialize()
                    }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - Environment Values

struct DataManagerKey: EnvironmentKey {
    static let defaultValue: DataManager? = nil
}

extension EnvironmentValues {
    var dataManager: DataManager? {
        get { self[DataManagerKey.self] }
        set { self[DataManagerKey.self] = newValue }
    }
}
