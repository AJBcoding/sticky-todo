//
//  AppDelegate.swift
//  StickyToDo-SwiftUI
//
//  Application delegate for StickyToDo SwiftUI app.
//  Required for App Intents (Siri Shortcuts) integration.
//

import Cocoa
import UserNotifications
import StickyToDoCore

/// Application delegate for SwiftUI app
///
/// This delegate is required for App Intents (Siri Shortcuts) to access
/// the task store and time tracking manager. All AppIntent files reference
/// `AppDelegate.shared?.taskStore` and `AppDelegate.shared?.timeTrackingManager`.
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Shared Instance (for App Intents)

    /// Shared instance for App Intents to access task store and managers
    static weak var shared: AppDelegate?

    // MARK: - Properties

    /// Data manager for accessing stores
    private let dataManager = DataManager.shared

    /// Time tracking manager for timer operations (exposed for App Intents)
    private(set) var timeTrackingManager: TimeTrackingManager!

    // MARK: - App Intents Compatibility

    /// TaskStore accessor for App Intents
    var taskStore: TaskStore? {
        return dataManager.taskStore
    }

    /// BoardStore accessor for App Intents (if needed in future)
    var boardStore: BoardStore? {
        return dataManager.boardStore
    }

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Set shared instance for App Intents
        AppDelegate.shared = self

        // Initialize time tracking manager
        timeTrackingManager = TimeTrackingManager()

        print("✅ SwiftUI AppDelegate initialized for App Intents support")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Clear shared instance
        AppDelegate.shared = nil
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
