//
//  AppStateInitializer.swift
//  StickyToDo-AppKit
//
//  Helper for initializing app state at launch.
//  Handles data loading, first-run setup, and coordinator initialization.
//

import Cocoa
import Combine

/// Handles application state initialization for AppKit app
///
/// This class:
/// - Initializes DataManager with proper directory
/// - Sets up AppKitCoordinator
/// - Loads sample data on first run
/// - Configures file watching
/// - Restores window state
class AppStateInitializer {

    // MARK: - Properties

    /// Shared instance
    static let shared = AppStateInitializer()

    /// Data manager instance
    private(set) var dataManager: DataManager!

    /// App coordinator
    private(set) var coordinator: AppKitCoordinator!

    /// Configuration manager
    private(set) var configManager: ConfigurationManager!

    /// Whether initialization is complete
    private(set) var isInitialized = false

    /// Initialization error, if any
    private(set) var initializationError: Error?

    // MARK: - Initialization

    private init() {
        // Private initializer for singleton
    }

    // MARK: - Setup Methods

    /// Initializes the application state
    ///
    /// This should be called early in applicationDidFinishLaunching
    ///
    /// - Parameter completion: Called when initialization completes
    func initialize(completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await performInitialization()

                await MainActor.run {
                    isInitialized = true
                    completion(.success(()))
                }
            } catch {
                await MainActor.run {
                    initializationError = error
                    completion(.failure(error))
                }
            }
        }
    }

    /// Synchronous initialization (blocks until complete)
    func initializeSync() throws {
        let semaphore = DispatchSemaphore(value: 0)
        var capturedError: Error?

        initialize { result in
            if case .failure(let error) = result {
                capturedError = error
            }
            semaphore.signal()
        }

        semaphore.wait()

        if let error = capturedError {
            throw error
        }
    }

    // MARK: - Private Methods

    private func performInitialization() async throws {
        print("🚀 Initializing StickyToDo (AppKit)...")

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
        coordinator = AppKitCoordinator(dataManager: dataManager, configManager: configManager)
        try await coordinator.initialize()
        print("✅ Coordinator initialized")

        // Step 6: Restore last state
        restoreLastState()
        print("✅ App state restored")

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

    // MARK: - Error Handling

    /// Shows an error alert for initialization failures
    func showInitializationError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Failed to Initialize StickyToDo"
        alert.informativeText = """
        An error occurred while initializing the application:

        \(error.localizedDescription)

        Please check that:
        • The data directory is accessible
        • You have write permissions
        • The directory is not corrupted

        Data directory: \(configManager.dataDirectory.path)
        """
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Choose Different Directory")

        let response = alert.runModal()

        if response == .alertSecondButtonReturn {
            showDirectoryPicker()
        } else {
            NSApp.terminate(nil)
        }
    }

    private func showDirectoryPicker() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Select Data Directory"
        openPanel.message = "Choose where StickyToDo should store its data"

        openPanel.begin { [weak self] response in
            guard response == .OK, let url = openPanel.url else {
                NSApp.terminate(nil)
                return
            }

            // Update config and retry
            self?.configManager.changeDataDirectory(to: url)
            self?.retryInitialization()
        }
    }

    private func retryInitialization() {
        initialize { [weak self] result in
            if case .failure(let error) = result {
                self?.showInitializationError(error)
            }
        }
    }
}

// MARK: - Application Delegate Extension

extension AppDelegate {

    /// Call this from applicationDidFinishLaunching
    func initializeAppState() {
        AppStateInitializer.shared.initialize { [weak self] result in
            switch result {
            case .success:
                // Get coordinator instance
                guard let coordinator = AppStateInitializer.shared.coordinator else { return }

                // Wire up main window controller
                self?.mainWindowController?.setDataManager(AppStateInitializer.shared.dataManager)
                self?.mainWindowController?.setCoordinator(coordinator)

                // Show main window
                coordinator.showMainWindow()

                // Perform first-run setup if needed
                coordinator.performFirstRunSetupIfNeeded()

            case .failure(let error):
                AppStateInitializer.shared.showInitializationError(error)
            }
        }
    }

    /// Call this from applicationWillTerminate
    func cleanupAppState() {
        AppStateInitializer.shared.cleanup()
    }
}
