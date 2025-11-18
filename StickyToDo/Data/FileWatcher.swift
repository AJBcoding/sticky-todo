//
//  FileWatcher.swift
//  StickyToDo
//
//  FSEvents wrapper for watching external file system changes.
//  Detects when markdown files are created, modified, or deleted outside the app.
//

import Foundation

/// Callback closures for file system events
typealias FileEventCallback = (URL) -> Void

/// File system event types
enum FileEventType {
    case created
    case modified
    case deleted
}

/// Wrapper around FSEvents for monitoring file system changes
///
/// FileWatcher monitors a directory tree for changes to markdown files.
/// When external changes are detected, it notifies the data manager so that
/// the in-memory stores can be updated and conflicts can be resolved.
///
/// Features:
/// - Debouncing to handle rapid successive changes
/// - File type filtering (only .md files)
/// - Thread-safe callbacks
/// - Automatic stream cleanup
final class FileWatcher {

    // MARK: - Properties

    /// The directory being watched
    private var watchedDirectory: URL?

    /// FSEvents stream
    private var eventStream: FSEventStreamRef?

    /// Dispatch queue for FSEvents callbacks
    private let eventQueue = DispatchQueue(label: "com.stickytodo.filewatcher", qos: .background)

    /// Debounce timer to coalesce rapid changes
    private var debounceTimer: Timer?

    /// Debounce interval (200ms to handle rapid changes)
    private let debounceInterval: TimeInterval = 0.2

    /// Pending events to be processed after debounce
    private var pendingEvents: [URL: FileEventType] = [:]

    /// Lock for thread-safe access to pending events
    private let lock = NSLock()

    /// Logger for debugging
    private var logger: ((String) -> Void)?

    // MARK: - Callbacks

    /// Called when a file is created
    var onFileCreated: FileEventCallback?

    /// Called when a file is modified
    var onFileModified: FileEventCallback?

    /// Called when a file is deleted
    var onFileDeleted: FileEventCallback?

    // MARK: - State

    /// Whether the watcher is currently active
    private(set) var isWatching = false

    // MARK: - Initialization

    init() {
        // FileWatcher initialized
    }

    /// Configure logging
    func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    // MARK: - Watching

    /// Starts watching a directory for changes
    ///
    /// This will monitor the directory and all its subdirectories for:
    /// - New .md files created
    /// - Existing .md files modified
    /// - .md files deleted
    ///
    /// - Parameter directory: The root directory to watch
    /// - Returns: True if watching started successfully
    @discardableResult
    func startWatching(directory: URL) -> Bool {
        // Stop any existing watch
        stopWatching()

        guard directory.hasDirectoryPath else {
            logger?("Error: \(directory.path) is not a directory")
            return false
        }

        logger?("Starting to watch directory: \(directory.path)")

        watchedDirectory = directory

        // Create FSEvents stream
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let paths = [directory.path] as CFArray
        let flags = UInt32(kFSEventStreamCreateFlagUseCFTypes |
                          kFSEventStreamCreateFlagFileEvents |
                          kFSEventStreamCreateFlagIgnoreSelf)

        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            fsEventsCallback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.1, // Latency in seconds
            flags
        )

        guard let stream = eventStream else {
            logger?("Failed to create FSEvents stream")
            return false
        }

        // Schedule on run loop
        FSEventStreamSetDispatchQueue(stream, eventQueue)

        // Start the stream
        if !FSEventStreamStart(stream) {
            logger?("Failed to start FSEvents stream")
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
            return false
        }

        isWatching = true
        logger?("Successfully started watching directory")
        return true
    }

    /// Stops watching for file changes
    func stopWatching() {
        guard let stream = eventStream else { return }

        logger?("Stopping file watcher")

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)

        eventStream = nil
        watchedDirectory = nil
        isWatching = false

        // Cancel any pending debounce timer
        debounceTimer?.invalidate()
        debounceTimer = nil

        logger?("File watcher stopped")
    }

    // MARK: - Event Handling

    /// FSEvents callback function
    private let fsEventsCallback: FSEventStreamCallback = { (
        streamRef,
        contextInfo,
        numEvents,
        eventPaths,
        eventFlags,
        eventIds
    ) in
        guard let contextInfo = contextInfo else { return }

        let watcher = Unmanaged<FileWatcher>.fromOpaque(contextInfo).takeUnretainedValue()
        let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]
        let flags = Array(UnsafeBufferPointer(start: eventFlags, count: numEvents))

        watcher.processEvents(paths: paths, flags: flags)
    }

    /// Processes FSEvents
    private func processEvents(paths: [String], flags: [FSEventStreamEventFlags]) {
        lock.lock()
        defer { lock.unlock() }

        for (index, path) in paths.enumerated() {
            let url = URL(fileURLWithPath: path)

            // Only process .md files
            guard url.pathExtension == "md" else { continue }

            let flag = flags[index]

            // Determine event type
            if flag & UInt32(kFSEventStreamEventFlagItemCreated) != 0 {
                pendingEvents[url] = .created
                logger?("Detected file created: \(url.lastPathComponent)")
            } else if flag & UInt32(kFSEventStreamEventFlagItemModified) != 0 {
                // Only treat as modified if not already marked as created
                if pendingEvents[url] != .created {
                    pendingEvents[url] = .modified
                    logger?("Detected file modified: \(url.lastPathComponent)")
                }
            } else if flag & UInt32(kFSEventStreamEventFlagItemRemoved) != 0 {
                pendingEvents[url] = .deleted
                logger?("Detected file deleted: \(url.lastPathComponent)")
            }
        }

        // Schedule debounced processing
        scheduleDebounce()
    }

    /// Schedules debounced event processing
    private func scheduleDebounce() {
        // Cancel existing timer
        debounceTimer?.invalidate()

        // Create new timer on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.debounceTimer = Timer.scheduledTimer(
                withTimeInterval: self.debounceInterval,
                repeats: false
            ) { [weak self] _ in
                self?.processPendingEvents()
            }
        }
    }

    /// Processes all pending events after debounce period
    private func processPendingEvents() {
        lock.lock()
        let events = pendingEvents
        pendingEvents.removeAll()
        lock.unlock()

        logger?("Processing \(events.count) debounced file events")

        // Process events on main thread for callback safety
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            for (url, eventType) in events {
                switch eventType {
                case .created:
                    self.onFileCreated?(url)
                case .modified:
                    self.onFileModified?(url)
                case .deleted:
                    self.onFileDeleted?(url)
                }
            }
        }
    }

    // MARK: - Cleanup

    deinit {
        stopWatching()
    }
}

// MARK: - Conflict Detection

extension FileWatcher {
    /// Information about a file conflict
    struct FileConflict {
        /// The file URL
        let url: URL

        /// The last modification date we have in memory
        let ourModificationDate: Date

        /// The modification date on disk
        let diskModificationDate: Date

        /// The file was modified externally while we had unsaved changes
        var hasConflict: Bool {
            return diskModificationDate > ourModificationDate
        }
    }

    /// Checks if a file has been modified more recently on disk than in memory
    ///
    /// - Parameters:
    ///   - url: The file URL to check
    ///   - ourModificationDate: The modification date we have in memory
    /// - Returns: FileConflict information, or nil if file doesn't exist
    func checkForConflict(url: URL, ourModificationDate: Date) -> FileConflict? {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let diskModDate = attributes[.modificationDate] as? Date {
                return FileConflict(
                    url: url,
                    ourModificationDate: ourModificationDate,
                    diskModificationDate: diskModDate
                )
            }
        } catch {
            logger?("Failed to get file attributes for \(url.path): \(error)")
        }

        return nil
    }
}

// MARK: - Helper Functions

extension FileWatcher {
    /// Returns true if a URL is within the watched directory
    ///
    /// - Parameter url: The URL to check
    /// - Returns: True if the URL is a descendant of the watched directory
    func isPathWatched(_ url: URL) -> Bool {
        guard let watchedDir = watchedDirectory else { return false }

        return url.path.hasPrefix(watchedDir.path)
    }

    /// Determines if a file is a task file based on its path
    ///
    /// - Parameter url: The file URL
    /// - Returns: True if the file is in the tasks directory
    func isTaskFile(_ url: URL) -> Bool {
        return url.path.contains("/tasks/")
    }

    /// Determines if a file is a board file based on its path
    ///
    /// - Parameter url: The file URL
    /// - Returns: True if the file is in the boards directory
    func isBoardFile(_ url: URL) -> Bool {
        return url.path.contains("/boards/")
    }

    /// Determines if a file is a config file based on its path
    ///
    /// - Parameter url: The file URL
    /// - Returns: True if the file is in the config directory
    func isConfigFile(_ url: URL) -> Bool {
        return url.path.contains("/config/")
    }
}

// MARK: - Statistics

extension FileWatcher {
    /// Returns information about the watched directory
    var watchInfo: String {
        guard let dir = watchedDirectory else {
            return "Not watching any directory"
        }

        return """
        Watching: \(dir.path)
        Status: \(isWatching ? "Active" : "Inactive")
        Pending events: \(pendingEvents.count)
        """
    }
}
