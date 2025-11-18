//
//  PerspectiveStore.swift
//  StickyToDo
//
//  In-memory store for SmartPerspectives with CRUD operations and persistence.
//  Manages built-in and custom perspectives with JSON-based file storage.
//

import Foundation
import Combine

/// In-memory store managing all smart perspectives in the application
///
/// PerspectiveStore handles:
/// - Built-in smart perspectives (Today's Focus, Quick Wins, etc.)
/// - Custom user-created perspectives
/// - CRUD operations with auto-save
/// - Export/Import of perspectives
/// - Thread-safe access
/// - Debounced writes to disk
///
/// Perspectives are stored in: `perspectives/` directory as JSON files
///
/// Usage:
/// ```swift
/// @ObservedObject var perspectiveStore: PerspectiveStore
/// ```
final class PerspectiveStore: ObservableObject {

    // MARK: - Published Properties

    /// All perspectives in the store
    @Published private(set) var perspectives: [SmartPerspective] = []

    /// Only visible custom perspectives (excludes built-in)
    @Published private(set) var customPerspectives: [SmartPerspective] = []

    /// Built-in smart perspectives
    @Published private(set) var builtInPerspectives: [SmartPerspective] = []

    // MARK: - Private Properties

    /// Root directory for storing perspective files
    private let perspectivesDirectory: URL

    /// File manager instance for I/O operations
    private let fileManager: FileManager

    /// Serial queue for thread-safe access
    private let queue = DispatchQueue(label: "com.stickytodo.perspectivestore", qos: .userInitiated)

    /// Debounce timer for auto-save operations
    private var saveTimers: [UUID: Timer] = [:]

    /// Save debounce interval (500ms)
    private let saveDebounceInterval: TimeInterval = 0.5

    /// Logger for debugging
    private var logger: ((String) -> Void)?

    /// Track pending saves
    private var pendingSaves: Set<UUID> = []

    /// JSON encoder for perspective serialization
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    /// JSON decoder for perspective deserialization
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    /// Creates a new PerspectiveStore
    ///
    /// - Parameters:
    ///   - rootDirectory: The root directory where perspectives are stored
    ///   - fileManager: The file manager to use (defaults to FileManager.default)
    init(rootDirectory: URL, fileManager: FileManager = .default) {
        self.perspectivesDirectory = rootDirectory.appendingPathComponent("perspectives")
        self.fileManager = fileManager
    }

    /// Configure logging
    func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    // MARK: - Loading

    /// Loads all perspectives from the file system and ensures built-in perspectives exist
    ///
    /// This should be called once at app launch. It will:
    /// 1. Create perspectives directory if needed
    /// 2. Load all custom perspectives from JSON files
    /// 3. Add built-in perspectives
    /// 4. Sort perspectives by creation date
    ///
    /// - Throws: Error if loading fails
    func loadAll() throws {
        logger?("Loading all perspectives from file system")

        // Ensure perspectives directory exists
        try createDirectoryIfNeeded(perspectivesDirectory)

        var loadedPerspectives: [SmartPerspective] = []

        // Load custom perspectives from JSON files
        do {
            let files = try fileManager.contentsOfDirectory(
                at: perspectivesDirectory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )

            for fileURL in files {
                guard fileURL.pathExtension == "json" else { continue }

                do {
                    let data = try Data(contentsOf: fileURL)
                    let perspective = try decoder.decode(SmartPerspective.self, from: data)

                    // Only load custom perspectives (built-in ones are added separately)
                    if !perspective.isBuiltIn {
                        loadedPerspectives.append(perspective)
                        logger?("Loaded perspective: \(perspective.name)")
                    }
                } catch {
                    logger?("Failed to load perspective from \(fileURL.path): \(error)")
                }
            }
        } catch {
            logger?("Failed to read perspectives directory: \(error)")
        }

        // Add built-in perspectives
        let builtIn = SmartPerspective.builtInSmartPerspectives

        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.builtInPerspectives = builtIn
                self.customPerspectives = loadedPerspectives.sorted { $0.created < $1.created }
                self.perspectives = builtIn + self.customPerspectives
                self.logger?("Loaded \(loadedPerspectives.count) custom perspectives + \(builtIn.count) built-in")
            }
        }
    }

    /// Loads all perspectives asynchronously
    func loadAllAsync() async throws {
        logger?("Loading all perspectives asynchronously")

        // Ensure perspectives directory exists
        try createDirectoryIfNeeded(perspectivesDirectory)

        var loadedPerspectives: [SmartPerspective] = []

        // Load custom perspectives from JSON files
        do {
            let files = try fileManager.contentsOfDirectory(
                at: perspectivesDirectory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )

            for fileURL in files {
                guard fileURL.pathExtension == "json" else { continue }

                do {
                    let data = try Data(contentsOf: fileURL)
                    let perspective = try decoder.decode(SmartPerspective.self, from: data)

                    if !perspective.isBuiltIn {
                        loadedPerspectives.append(perspective)
                        logger?("Loaded perspective: \(perspective.name)")
                    }
                } catch {
                    logger?("Failed to load perspective from \(fileURL.path): \(error)")
                }
            }
        } catch {
            logger?("Failed to read perspectives directory: \(error)")
        }

        // Add built-in perspectives
        let builtIn = SmartPerspective.builtInSmartPerspectives

        await MainActor.run {
            self.builtInPerspectives = builtIn
            self.customPerspectives = loadedPerspectives.sorted { $0.created < $1.created }
            self.perspectives = builtIn + self.customPerspectives
            self.logger?("Loaded \(loadedPerspectives.count) custom perspectives + \(builtIn.count) built-in")
        }
    }

    // MARK: - CRUD Operations

    /// Creates and adds a new perspective to the store
    ///
    /// - Parameter perspective: The perspective to add
    func create(_ perspective: SmartPerspective) {
        guard !perspective.isBuiltIn else {
            logger?("Cannot create built-in perspective: \(perspective.name)")
            return
        }

        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if !self.perspectives.contains(where: { $0.id == perspective.id }) {
                    self.customPerspectives.append(perspective)
                    self.customPerspectives.sort { $0.created < $1.created }
                    self.perspectives = self.builtInPerspectives + self.customPerspectives
                    self.logger?("Created perspective: \(perspective.name)")

                    // Schedule debounced save
                    self.scheduleSave(for: perspective)
                }
            }
        }
    }

    /// Updates an existing perspective
    ///
    /// - Parameter perspective: The updated perspective
    func update(_ perspective: SmartPerspective) {
        guard !perspective.isBuiltIn else {
            logger?("Cannot update built-in perspective: \(perspective.name)")
            return
        }

        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.customPerspectives.firstIndex(where: { $0.id == perspective.id }) {
                    var updatedPerspective = perspective
                    updatedPerspective.modified = Date()

                    self.customPerspectives[index] = updatedPerspective
                    self.customPerspectives.sort { $0.created < $1.created }
                    self.perspectives = self.builtInPerspectives + self.customPerspectives
                    self.logger?("Updated perspective: \(perspective.name)")

                    // Schedule debounced save
                    self.scheduleSave(for: updatedPerspective)
                }
            }
        }
    }

    /// Deletes a perspective from the store
    ///
    /// Built-in perspectives cannot be deleted.
    ///
    /// - Parameter perspective: The perspective to delete
    func delete(_ perspective: SmartPerspective) {
        // Don't allow deleting built-in perspectives
        guard !perspective.isBuiltIn else {
            logger?("Cannot delete built-in perspective: \(perspective.name)")
            return
        }

        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.customPerspectives.firstIndex(where: { $0.id == perspective.id }) {
                    self.customPerspectives.remove(at: index)
                    self.perspectives = self.builtInPerspectives + self.customPerspectives
                    self.logger?("Deleted perspective: \(perspective.name)")

                    // Cancel pending save
                    self.cancelSave(for: perspective.id)

                    // Delete from file system
                    self.queue.async {
                        do {
                            try self.deletePerspectiveFile(perspective)
                        } catch {
                            self.logger?("Failed to delete perspective file: \(error)")
                        }
                    }
                }
            }
        }
    }

    /// Saves a perspective to disk with debouncing
    ///
    /// - Parameter perspective: The perspective to save
    func save(_ perspective: SmartPerspective) {
        guard !perspective.isBuiltIn else { return }
        scheduleSave(for: perspective)
    }

    /// Immediately saves a perspective to disk without debouncing
    ///
    /// - Parameter perspective: The perspective to save
    /// - Throws: Error if saving fails
    func saveImmediately(_ perspective: SmartPerspective) throws {
        guard !perspective.isBuiltIn else { return }

        cancelSave(for: perspective.id)
        try savePerspectiveFile(perspective)
        logger?("Immediately saved perspective: \(perspective.name)")
    }

    /// Immediately saves all custom perspectives to disk
    ///
    /// - Throws: Error if saving fails
    func saveAll() throws {
        logger?("Saving all custom perspectives to disk")

        // Cancel pending saves
        for perspectiveID in pendingSaves {
            cancelSave(for: perspectiveID)
        }

        // Save all custom perspectives
        for perspective in customPerspectives {
            try savePerspectiveFile(perspective)
        }

        logger?("Saved all \(customPerspectives.count) custom perspectives")
    }

    // MARK: - Perspective Lookup

    /// Finds a perspective by its ID
    ///
    /// - Parameter id: The perspective ID
    /// - Returns: The perspective if found
    func perspective(withID id: UUID) -> SmartPerspective? {
        return perspectives.first { $0.id == id }
    }

    /// Finds perspectives by name (case-insensitive)
    ///
    /// - Parameter name: The perspective name
    /// - Returns: Array of perspectives with matching names
    func perspectives(named name: String) -> [SmartPerspective] {
        let lowercaseName = name.lowercased()
        return perspectives.filter { $0.name.lowercased().contains(lowercaseName) }
    }

    // MARK: - Export/Import

    /// Exports a perspective to JSON data
    ///
    /// - Parameter perspective: The perspective to export
    /// - Returns: JSON data representing the perspective
    /// - Throws: Error if encoding fails
    func export(_ perspective: SmartPerspective) throws -> Data {
        return try encoder.encode(perspective)
    }

    /// Exports a perspective to a file
    ///
    /// - Parameters:
    ///   - perspective: The perspective to export
    ///   - url: The destination file URL
    /// - Throws: Error if export fails
    func exportToFile(_ perspective: SmartPerspective, to url: URL) throws {
        let data = try export(perspective)
        try data.write(to: url, options: .atomic)
        logger?("Exported perspective '\(perspective.name)' to \(url.path)")
    }

    /// Imports a perspective from JSON data
    ///
    /// - Parameter data: JSON data representing a perspective
    /// - Returns: The imported perspective with a new ID
    /// - Throws: Error if decoding fails
    func `import`(from data: Data) throws -> SmartPerspective {
        var perspective = try decoder.decode(SmartPerspective.self, from: data)

        // Assign new ID and timestamps to avoid conflicts
        perspective = SmartPerspective(
            id: UUID(),
            name: perspective.name,
            description: perspective.description,
            rules: perspective.rules,
            logic: perspective.logic,
            groupBy: perspective.groupBy,
            sortBy: perspective.sortBy,
            sortDirection: perspective.sortDirection,
            showCompleted: perspective.showCompleted,
            showDeferred: perspective.showDeferred,
            icon: perspective.icon,
            color: perspective.color,
            isBuiltIn: false, // Imported perspectives are never built-in
            created: Date(),
            modified: Date()
        )

        logger?("Imported perspective: \(perspective.name)")
        return perspective
    }

    /// Imports a perspective from a file
    ///
    /// - Parameter url: The source file URL
    /// - Returns: The imported perspective
    /// - Throws: Error if import fails
    func importFromFile(_ url: URL) throws -> SmartPerspective {
        let data = try Data(contentsOf: url)
        let perspective = try self.import(from: data)
        logger?("Imported perspective '\(perspective.name)' from \(url.path)")
        return perspective
    }

    /// Imports a perspective and adds it to the store
    ///
    /// - Parameter url: The source file URL
    /// - Throws: Error if import fails
    func importAndCreate(from url: URL) throws {
        let perspective = try importFromFile(url)
        create(perspective)
    }

    /// Exports all custom perspectives to a directory
    ///
    /// - Parameter directory: The destination directory
    /// - Throws: Error if export fails
    func exportAll(to directory: URL) throws {
        try createDirectoryIfNeeded(directory)

        for perspective in customPerspectives {
            let filename = "\(perspective.name.slugified())-\(perspective.id.uuidString).json"
            let fileURL = directory.appendingPathComponent(filename)
            try exportToFile(perspective, to: fileURL)
        }

        logger?("Exported \(customPerspectives.count) perspectives to \(directory.path)")
    }

    // MARK: - Statistics

    /// Total number of perspectives
    var perspectiveCount: Int {
        return perspectives.count
    }

    /// Number of custom perspectives
    var customPerspectiveCount: Int {
        return customPerspectives.count
    }

    /// Number of built-in perspectives
    var builtInPerspectiveCount: Int {
        return builtInPerspectives.count
    }

    // MARK: - Private Helpers

    /// Creates a directory if it doesn't already exist
    private func createDirectoryIfNeeded(_ url: URL) throws {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if exists && isDirectory.boolValue {
            return
        }

        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
        logger?("Created directory: \(url.path)")
    }

    /// Returns the URL for a perspective file
    private func fileURL(for perspective: SmartPerspective) -> URL {
        let filename = "\(perspective.id.uuidString).json"
        return perspectivesDirectory.appendingPathComponent(filename)
    }

    /// Saves a perspective to a JSON file
    private func savePerspectiveFile(_ perspective: SmartPerspective) throws {
        let url = fileURL(for: perspective)
        let data = try encoder.encode(perspective)
        try data.write(to: url, options: .atomic)
    }

    /// Deletes a perspective file
    private func deletePerspectiveFile(_ perspective: SmartPerspective) throws {
        let url = fileURL(for: perspective)

        guard fileManager.fileExists(atPath: url.path) else {
            return
        }

        try fileManager.removeItem(at: url)
    }

    /// Schedules a debounced save for a perspective
    private func scheduleSave(for perspective: SmartPerspective) {
        // Cancel existing timer
        cancelSave(for: perspective.id)

        // Mark as pending
        pendingSaves.insert(perspective.id)

        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.queue.async {
                do {
                    try self.savePerspectiveFile(perspective)
                    self.logger?("Debounced save completed for perspective: \(perspective.name)")
                } catch {
                    self.logger?("Failed to save perspective: \(error)")
                }

                DispatchQueue.main.async {
                    self.pendingSaves.remove(perspective.id)
                    self.saveTimers.removeValue(forKey: perspective.id)
                }
            }
        }

        saveTimers[perspective.id] = timer
    }

    /// Cancels a pending save
    private func cancelSave(for perspectiveID: UUID) {
        saveTimers[perspectiveID]?.invalidate()
        saveTimers.removeValue(forKey: perspectiveID)
        pendingSaves.remove(perspectiveID)
    }

    /// Cancels all pending saves
    func cancelAllPendingSaves() {
        for (_, timer) in saveTimers {
            timer.invalidate()
        }
        saveTimers.removeAll()
        pendingSaves.removeAll()
    }

    deinit {
        cancelAllPendingSaves()
    }
}

// MARK: - String Extension for Slugification

fileprivate extension String {
    /// Converts a string to a URL-safe slug
    func slugified() -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let slug = self
            .lowercased()
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return slug.isEmpty ? "untitled" : slug
    }
}
