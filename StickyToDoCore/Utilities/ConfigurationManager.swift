//
//  ConfigurationManager.swift
//  StickyToDoCore
//
//  Manages app configuration and user preferences.
//  Handles storage location, defaults, and settings persistence.
//

import Foundation
import Combine

/// Manages application configuration and user preferences
///
/// ConfigurationManager provides:
/// - Storage location configuration
/// - User preferences (auto-hide, auto-save, hotkeys)
/// - Persistent settings via UserDefaults
/// - Observable properties for SwiftUI binding
/// - Thread-safe access to configuration
final class ConfigurationManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ConfigurationManager()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let dataDirectory = "dataDirectory"
        static let isFirstRun = "isFirstRun"
        static let lastPerspectiveID = "lastPerspectiveID"
        static let lastBoardID = "lastBoardID"
        static let lastViewMode = "lastViewMode"
        static let defaultBoardOnLaunch = "defaultBoardOnLaunch"
        static let autoHideInactiveBoardsDays = "autoHideInactiveBoardsDays"
        static let autoSaveInterval = "autoSaveInterval"
        static let quickCaptureHotkey = "quickCaptureHotkey"
        static let quickCaptureHotkeyModifiers = "quickCaptureHotkeyModifiers"
        static let enableFileWatching = "enableFileWatching"
        static let enableLogging = "enableLogging"
        static let windowWidth = "windowWidth"
        static let windowHeight = "windowHeight"
        static let sidebarWidth = "sidebarWidth"
        static let inspectorWidth = "inspectorWidth"
        static let inspectorVisible = "inspectorVisible"
        static let defaultTaskStatus = "defaultTaskStatus"
        static let defaultTaskPriority = "defaultTaskPriority"
        static let showCompletedTasks = "showCompletedTasks"
        static let groupBy = "groupBy"
        static let sortBy = "sortBy"
        static let defaultContext = "defaultContext"
        static let lastReviewDate = "lastReviewDate"
    }

    // MARK: - Published Properties

    /// The root directory where all StickyToDo data is stored
    @Published var dataDirectory: URL {
        didSet {
            UserDefaults.standard.set(dataDirectory.path, forKey: Keys.dataDirectory)
        }
    }

    /// Whether this is the first run of the app
    @Published var isFirstRun: Bool {
        didSet {
            UserDefaults.standard.set(isFirstRun, forKey: Keys.isFirstRun)
        }
    }

    /// ID of the last selected perspective
    @Published var lastPerspectiveID: String? {
        didSet {
            UserDefaults.standard.set(lastPerspectiveID, forKey: Keys.lastPerspectiveID)
        }
    }

    /// ID of the last selected board
    @Published var lastBoardID: String? {
        didSet {
            UserDefaults.standard.set(lastBoardID, forKey: Keys.lastBoardID)
        }
    }

    /// Last view mode (list or board)
    @Published var lastViewMode: ViewMode {
        didSet {
            UserDefaults.standard.set(lastViewMode.rawValue, forKey: Keys.lastViewMode)
        }
    }

    /// Default board to show on app launch (nil = use last perspective)
    @Published var defaultBoardOnLaunch: String? {
        didSet {
            UserDefaults.standard.set(defaultBoardOnLaunch, forKey: Keys.defaultBoardOnLaunch)
        }
    }

    /// Number of days before auto-hiding inactive project boards
    @Published var autoHideInactiveBoardsDays: Int {
        didSet {
            UserDefaults.standard.set(autoHideInactiveBoardsDays, forKey: Keys.autoHideInactiveBoardsDays)
        }
    }

    /// Auto-save interval in seconds
    @Published var autoSaveInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(autoSaveInterval, forKey: Keys.autoSaveInterval)
        }
    }

    /// Quick capture hotkey (key code)
    @Published var quickCaptureHotkey: UInt16 {
        didSet {
            UserDefaults.standard.set(Int(quickCaptureHotkey), forKey: Keys.quickCaptureHotkey)
        }
    }

    /// Quick capture hotkey modifiers (command, shift, etc.)
    @Published var quickCaptureHotkeyModifiers: UInt {
        didSet {
            UserDefaults.standard.set(Int(quickCaptureHotkeyModifiers), forKey: Keys.quickCaptureHotkeyModifiers)
        }
    }

    /// Whether to watch files for external changes
    @Published var enableFileWatching: Bool {
        didSet {
            UserDefaults.standard.set(enableFileWatching, forKey: Keys.enableFileWatching)
        }
    }

    /// Whether to enable debug logging
    @Published var enableLogging: Bool {
        didSet {
            UserDefaults.standard.set(enableLogging, forKey: Keys.enableLogging)
        }
    }

    // MARK: - Window Configuration

    /// Main window width
    @Published var windowWidth: CGFloat {
        didSet {
            UserDefaults.standard.set(Double(windowWidth), forKey: Keys.windowWidth)
        }
    }

    /// Main window height
    @Published var windowHeight: CGFloat {
        didSet {
            UserDefaults.standard.set(Double(windowHeight), forKey: Keys.windowHeight)
        }
    }

    /// Sidebar width
    @Published var sidebarWidth: CGFloat {
        didSet {
            UserDefaults.standard.set(Double(sidebarWidth), forKey: Keys.sidebarWidth)
        }
    }

    /// Inspector width
    @Published var inspectorWidth: CGFloat {
        didSet {
            UserDefaults.standard.set(Double(inspectorWidth), forKey: Keys.inspectorWidth)
        }
    }

    /// Whether inspector is visible
    @Published var inspectorVisible: Bool {
        didSet {
            UserDefaults.standard.set(inspectorVisible, forKey: Keys.inspectorVisible)
        }
    }

    // MARK: - Task Defaults

    /// Default status for new tasks
    @Published var defaultTaskStatus: Status {
        didSet {
            UserDefaults.standard.set(defaultTaskStatus.rawValue, forKey: Keys.defaultTaskStatus)
        }
    }

    /// Default priority for new tasks
    @Published var defaultTaskPriority: Priority {
        didSet {
            UserDefaults.standard.set(defaultTaskPriority.rawValue, forKey: Keys.defaultTaskPriority)
        }
    }

    /// Default context for new tasks (nil = no default)
    @Published var defaultContext: String? {
        didSet {
            UserDefaults.standard.set(defaultContext, forKey: Keys.defaultContext)
        }
    }

    // MARK: - View Preferences

    /// Whether to show completed tasks in lists
    @Published var showCompletedTasks: Bool {
        didSet {
            UserDefaults.standard.set(showCompletedTasks, forKey: Keys.showCompletedTasks)
        }
    }

    /// Default grouping option
    @Published var groupBy: GroupOption {
        didSet {
            UserDefaults.standard.set(groupBy.rawValue, forKey: Keys.groupBy)
        }
    }

    /// Default sorting option
    @Published var sortBy: SortOption {
        didSet {
            UserDefaults.standard.set(sortBy.rawValue, forKey: Keys.sortBy)
        }
    }

    // MARK: - Weekly Review

    /// Date of last completed weekly review
    @Published var lastReviewDate: Date? {
        didSet {
            if let date = lastReviewDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Keys.lastReviewDate)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.lastReviewDate)
            }
        }
    }

    // MARK: - Initialization

    private init() {
        // Load all settings from UserDefaults with fallbacks

        // Data directory: default to ~/Documents/StickyToDo
        if let path = UserDefaults.standard.string(forKey: Keys.dataDirectory) {
            self.dataDirectory = URL(fileURLWithPath: path)
        } else {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.dataDirectory = documentsURL.appendingPathComponent("StickyToDo")
        }

        // First run detection
        self.isFirstRun = UserDefaults.standard.object(forKey: Keys.isFirstRun) == nil
            ? true
            : UserDefaults.standard.bool(forKey: Keys.isFirstRun)

        // Last state
        self.lastPerspectiveID = UserDefaults.standard.string(forKey: Keys.lastPerspectiveID)
        self.lastBoardID = UserDefaults.standard.string(forKey: Keys.lastBoardID)

        let viewModeString = UserDefaults.standard.string(forKey: Keys.lastViewMode) ?? ViewMode.list.rawValue
        self.lastViewMode = ViewMode(rawValue: viewModeString) ?? .list

        // Launch preferences
        self.defaultBoardOnLaunch = UserDefaults.standard.string(forKey: Keys.defaultBoardOnLaunch)

        // Auto-hide settings
        self.autoHideInactiveBoardsDays = UserDefaults.standard.object(forKey: Keys.autoHideInactiveBoardsDays) as? Int ?? 30

        // Auto-save interval (default 0.5 seconds)
        self.autoSaveInterval = UserDefaults.standard.object(forKey: Keys.autoSaveInterval) as? TimeInterval ?? 0.5

        // Quick capture hotkey (default: Cmd+Shift+Space = keyCode 49)
        self.quickCaptureHotkey = UInt16(UserDefaults.standard.integer(forKey: Keys.quickCaptureHotkey))
        if self.quickCaptureHotkey == 0 {
            self.quickCaptureHotkey = 49 // Space bar
        }

        // Quick capture modifiers (default: Cmd+Shift)
        self.quickCaptureHotkeyModifiers = UInt(UserDefaults.standard.integer(forKey: Keys.quickCaptureHotkeyModifiers))
        if self.quickCaptureHotkeyModifiers == 0 {
            self.quickCaptureHotkeyModifiers = 0x108 // Cmd+Shift
        }

        // File watching (default: enabled)
        self.enableFileWatching = UserDefaults.standard.object(forKey: Keys.enableFileWatching) as? Bool ?? true

        // Logging (default: disabled in production)
        #if DEBUG
        self.enableLogging = UserDefaults.standard.object(forKey: Keys.enableLogging) as? Bool ?? true
        #else
        self.enableLogging = UserDefaults.standard.object(forKey: Keys.enableLogging) as? Bool ?? false
        #endif

        // Window configuration
        self.windowWidth = CGFloat(UserDefaults.standard.double(forKey: Keys.windowWidth))
        if self.windowWidth == 0 { self.windowWidth = 1200 }

        self.windowHeight = CGFloat(UserDefaults.standard.double(forKey: Keys.windowHeight))
        if self.windowHeight == 0 { self.windowHeight = 800 }

        self.sidebarWidth = CGFloat(UserDefaults.standard.double(forKey: Keys.sidebarWidth))
        if self.sidebarWidth == 0 { self.sidebarWidth = 220 }

        self.inspectorWidth = CGFloat(UserDefaults.standard.double(forKey: Keys.inspectorWidth))
        if self.inspectorWidth == 0 { self.inspectorWidth = 300 }

        self.inspectorVisible = UserDefaults.standard.object(forKey: Keys.inspectorVisible) as? Bool ?? true

        // Task defaults
        let statusString = UserDefaults.standard.string(forKey: Keys.defaultTaskStatus) ?? Status.inbox.rawValue
        self.defaultTaskStatus = Status(rawValue: statusString) ?? .inbox

        let priorityString = UserDefaults.standard.string(forKey: Keys.defaultTaskPriority) ?? Priority.medium.rawValue
        self.defaultTaskPriority = Priority(rawValue: priorityString) ?? .medium

        self.defaultContext = UserDefaults.standard.string(forKey: Keys.defaultContext)

        // View preferences
        self.showCompletedTasks = UserDefaults.standard.object(forKey: Keys.showCompletedTasks) as? Bool ?? false

        let groupByString = UserDefaults.standard.string(forKey: Keys.groupBy) ?? GroupOption.none.rawValue
        self.groupBy = GroupOption(rawValue: groupByString) ?? .none

        let sortByString = UserDefaults.standard.string(forKey: Keys.sortBy) ?? SortOption.created.rawValue
        self.sortBy = SortOption(rawValue: sortByString) ?? .created

        // Weekly Review
        let lastReviewTimestamp = UserDefaults.standard.double(forKey: Keys.lastReviewDate)
        if lastReviewTimestamp > 0 {
            self.lastReviewDate = Date(timeIntervalSince1970: lastReviewTimestamp)
        } else {
            self.lastReviewDate = nil
        }
    }

    // MARK: - Public Methods

    /// Loads configuration from UserDefaults
    func load() {
        // Values are already loaded in init, but we can trigger a refresh if needed
        objectWillChange.send()
    }

    /// Saves all configuration to UserDefaults
    func save() {
        UserDefaults.standard.synchronize()
    }

    /// Resets all settings to defaults
    func resetToDefaults() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        dataDirectory = documentsURL.appendingPathComponent("StickyToDo")

        isFirstRun = true
        lastPerspectiveID = nil
        lastBoardID = nil
        lastViewMode = .list
        defaultBoardOnLaunch = nil
        autoHideInactiveBoardsDays = 30
        autoSaveInterval = 0.5
        quickCaptureHotkey = 49
        quickCaptureHotkeyModifiers = 0x108
        enableFileWatching = true

        #if DEBUG
        enableLogging = true
        #else
        enableLogging = false
        #endif

        windowWidth = 1200
        windowHeight = 800
        sidebarWidth = 220
        inspectorWidth = 300
        inspectorVisible = true

        defaultTaskStatus = .inbox
        defaultTaskPriority = .medium
        defaultContext = nil

        showCompletedTasks = false
        groupBy = .none
        sortBy = .created
        lastReviewDate = nil

        save()
    }

    /// Changes the data directory and clears first-run flag
    func changeDataDirectory(to url: URL) {
        dataDirectory = url
        // Don't reset first-run flag when changing directories
        save()
    }

    // MARK: - Computed Properties

    /// Returns the URL for the tasks directory
    var tasksDirectory: URL {
        return dataDirectory.appendingPathComponent("tasks")
    }

    /// Returns the URL for the boards directory
    var boardsDirectory: URL {
        return dataDirectory.appendingPathComponent("boards")
    }

    /// Returns the URL for the perspectives directory
    var perspectivesDirectory: URL {
        return dataDirectory.appendingPathComponent("perspectives")
    }

    /// Returns the URL for the attachments directory
    var attachmentsDirectory: URL {
        return dataDirectory.appendingPathComponent("attachments")
    }
}

// MARK: - Grouping Options

/// Options for grouping tasks in list view
public enum GroupOption: String, Codable, CaseIterable {
    case none = "none"
    case status = "status"
    case project = "project"
    case context = "context"
    case priority = "priority"
    case dueDate = "dueDate"

    var displayName: String {
        switch self {
        case .none: return "None"
        case .status: return "Status"
        case .project: return "Project"
        case .context: return "Context"
        case .priority: return "Priority"
        case .dueDate: return "Due Date"
        }
    }
}

// MARK: - Sorting Options

/// Options for sorting tasks in list view
public enum SortOption: String, Codable, CaseIterable {
    case title = "title"
    case created = "created"
    case modified = "modified"
    case due = "due"
    case priority = "priority"
    case status = "status"

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .created: return "Created"
        case .modified: return "Modified"
        case .due: return "Due Date"
        case .priority: return "Priority"
        case .status: return "Status"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when configuration changes
    static let configurationChanged = Notification.Name("configurationChanged")

    /// Posted when data directory changes
    static let dataDirectoryChanged = Notification.Name("dataDirectoryChanged")
}
