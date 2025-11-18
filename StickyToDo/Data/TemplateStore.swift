//
//  TemplateStore.swift
//  StickyToDo
//
//  In-memory store for TaskTemplates with CRUD operations and persistence.
//  Manages built-in and custom templates with JSON-based file storage.
//

import Foundation
import Combine

/// In-memory store managing all task templates in the application
///
/// TemplateStore handles:
/// - Built-in task templates (Meeting Notes, Code Review, etc.)
/// - Custom user-created templates
/// - CRUD operations with auto-save
/// - Export/Import of templates
/// - Thread-safe access
/// - Debounced writes to disk
///
/// Templates are stored in: `templates/` directory as JSON files
///
/// Usage:
/// ```swift
/// @ObservedObject var templateStore: TemplateStore
/// ```
final class TemplateStore: ObservableObject {

    // MARK: - Published Properties

    /// All templates in the store
    @Published private(set) var templates: [TaskTemplate] = []

    /// Only visible custom templates (excludes built-in)
    @Published private(set) var customTemplates: [TaskTemplate] = []

    /// Built-in task templates
    @Published private(set) var builtInTemplates: [TaskTemplate] = []

    // MARK: - Private Properties

    /// Root directory for storing template files
    private let templatesDirectory: URL

    /// File manager instance for I/O operations
    private let fileManager: FileManager

    /// Serial queue for thread-safe access
    private let queue = DispatchQueue(label: "com.stickytodo.templatestore", qos: .userInitiated)

    /// Debounce timer for auto-save operations
    private var saveTimers: [UUID: Timer] = [:]

    /// Save debounce interval (500ms)
    private let saveDebounceInterval: TimeInterval = 0.5

    /// Logger for debugging
    private var logger: ((String) -> Void)?

    /// Track pending saves
    private var pendingSaves: Set<UUID> = []

    /// JSON encoder for template serialization
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    /// JSON decoder for template deserialization
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    /// Creates a new TemplateStore
    ///
    /// - Parameters:
    ///   - rootDirectory: The root directory where templates are stored
    ///   - fileManager: The file manager to use (defaults to FileManager.default)
    init(rootDirectory: URL, fileManager: FileManager = .default) {
        self.templatesDirectory = rootDirectory.appendingPathComponent("templates")
        self.fileManager = fileManager
    }

    /// Configure logging
    func setLogger(_ logger: @escaping (String) -> Void) {
        self.logger = logger
    }

    // MARK: - Loading

    /// Loads all templates from the file system and ensures built-in templates exist
    ///
    /// This should be called once at app launch. It will:
    /// 1. Create templates directory if needed
    /// 2. Load all custom templates from JSON files
    /// 3. Add built-in templates
    /// 4. Sort templates by usage count and name
    ///
    /// - Throws: Error if loading fails
    func loadAll() throws {
        logger?("Loading all templates from file system")

        // Ensure templates directory exists
        try createDirectoryIfNeeded(templatesDirectory)

        var loadedTemplates: [TaskTemplate] = []

        // Load custom templates from JSON files
        do {
            let files = try fileManager.contentsOfDirectory(
                at: templatesDirectory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )

            for fileURL in files {
                guard fileURL.pathExtension == "json" else { continue }

                do {
                    let data = try Data(contentsOf: fileURL)
                    let template = try decoder.decode(TaskTemplate.self, from: data)
                    loadedTemplates.append(template)
                    logger?("Loaded template: \(template.name)")
                } catch {
                    logger?("Failed to load template from \(fileURL.path): \(error)")
                }
            }
        } catch {
            logger?("Failed to read templates directory: \(error)")
        }

        // Add built-in templates
        let builtIn = TaskTemplate.defaultTemplates

        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.builtInTemplates = builtIn
                self.customTemplates = loadedTemplates.sorted { lhs, rhs in
                    if lhs.useCount != rhs.useCount {
                        return lhs.useCount > rhs.useCount
                    }
                    return lhs.name < rhs.name
                }
                self.templates = builtIn + self.customTemplates
                self.logger?("Loaded \(loadedTemplates.count) custom templates + \(builtIn.count) built-in")
            }
        }
    }

    /// Loads all templates asynchronously
    func loadAllAsync() async throws {
        logger?("Loading all templates asynchronously")

        // Ensure templates directory exists
        try createDirectoryIfNeeded(templatesDirectory)

        var loadedTemplates: [TaskTemplate] = []

        // Load custom templates from JSON files
        do {
            let files = try fileManager.contentsOfDirectory(
                at: templatesDirectory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )

            for fileURL in files {
                guard fileURL.pathExtension == "json" else { continue }

                do {
                    let data = try Data(contentsOf: fileURL)
                    let template = try decoder.decode(TaskTemplate.self, from: data)
                    loadedTemplates.append(template)
                    logger?("Loaded template: \(template.name)")
                } catch {
                    logger?("Failed to load template from \(fileURL.path): \(error)")
                }
            }
        } catch {
            logger?("Failed to read templates directory: \(error)")
        }

        // Add built-in templates
        let builtIn = TaskTemplate.defaultTemplates

        await MainActor.run {
            self.builtInTemplates = builtIn
            self.customTemplates = loadedTemplates.sorted { lhs, rhs in
                if lhs.useCount != rhs.useCount {
                    return lhs.useCount > rhs.useCount
                }
                return lhs.name < rhs.name
            }
            self.templates = builtIn + self.customTemplates
            self.logger?("Loaded \(loadedTemplates.count) custom templates + \(builtIn.count) built-in")
        }
    }

    // MARK: - CRUD Operations

    /// Creates and adds a new template to the store
    ///
    /// - Parameter template: The template to add
    func create(_ template: TaskTemplate) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if !self.templates.contains(where: { $0.id == template.id }) {
                    self.customTemplates.append(template)
                    self.customTemplates.sort { lhs, rhs in
                        if lhs.useCount != rhs.useCount {
                            return lhs.useCount > rhs.useCount
                        }
                        return lhs.name < rhs.name
                    }
                    self.templates = self.builtInTemplates + self.customTemplates
                    self.logger?("Created template: \(template.name)")

                    // Schedule debounced save
                    self.scheduleSave(for: template)
                }
            }
        }
    }

    /// Updates an existing template
    ///
    /// - Parameter template: The updated template
    func update(_ template: TaskTemplate) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.customTemplates.firstIndex(where: { $0.id == template.id }) {
                    var updatedTemplate = template
                    updatedTemplate.modified = Date()

                    self.customTemplates[index] = updatedTemplate
                    self.customTemplates.sort { lhs, rhs in
                        if lhs.useCount != rhs.useCount {
                            return lhs.useCount > rhs.useCount
                        }
                        return lhs.name < rhs.name
                    }
                    self.templates = self.builtInTemplates + self.customTemplates
                    self.logger?("Updated template: \(template.name)")

                    // Schedule debounced save
                    self.scheduleSave(for: updatedTemplate)
                } else if let builtInIndex = self.builtInTemplates.firstIndex(where: { $0.id == template.id }) {
                    var updatedTemplate = template
                    updatedTemplate.modified = Date()
                    self.builtInTemplates[builtInIndex] = updatedTemplate
                    self.templates = self.builtInTemplates + self.customTemplates
                    self.logger?("Updated built-in template: \(template.name)")
                }
            }
        }
    }

    /// Deletes a template from the store
    ///
    /// - Parameter template: The template to delete
    func delete(_ template: TaskTemplate) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.customTemplates.firstIndex(where: { $0.id == template.id }) {
                    self.customTemplates.remove(at: index)
                    self.templates = self.builtInTemplates + self.customTemplates
                    self.logger?("Deleted template: \(template.name)")

                    // Cancel pending save
                    self.cancelSave(for: template.id)

                    // Delete from file system
                    self.queue.async {
                        do {
                            try self.deleteTemplateFile(template)
                        } catch {
                            self.logger?("Failed to delete template file: \(error)")
                        }
                    }
                }
            }
        }
    }

    /// Records that a template was used
    ///
    /// - Parameter template: The template that was used
    func recordUse(of template: TaskTemplate) {
        queue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.customTemplates.firstIndex(where: { $0.id == template.id }) {
                    var updatedTemplate = self.customTemplates[index]
                    updatedTemplate.recordUse()
                    self.customTemplates[index] = updatedTemplate
                    self.customTemplates.sort { lhs, rhs in
                        if lhs.useCount != rhs.useCount {
                            return lhs.useCount > rhs.useCount
                        }
                        return lhs.name < rhs.name
                    }
                    self.templates = self.builtInTemplates + self.customTemplates
                    self.scheduleSave(for: updatedTemplate)
                } else if let builtInIndex = self.builtInTemplates.firstIndex(where: { $0.id == template.id }) {
                    var updatedTemplate = self.builtInTemplates[builtInIndex]
                    updatedTemplate.recordUse()
                    self.builtInTemplates[builtInIndex] = updatedTemplate
                    self.templates = self.builtInTemplates + self.customTemplates
                }
            }
        }
    }

    /// Saves a template to disk with debouncing
    ///
    /// - Parameter template: The template to save
    func save(_ template: TaskTemplate) {
        scheduleSave(for: template)
    }

    /// Immediately saves a template to disk without debouncing
    ///
    /// - Parameter template: The template to save
    /// - Throws: Error if saving fails
    func saveImmediately(_ template: TaskTemplate) throws {
        cancelSave(for: template.id)
        try saveTemplateFile(template)
        logger?("Immediately saved template: \(template.name)")
    }

    /// Immediately saves all custom templates to disk
    ///
    /// - Throws: Error if saving fails
    func saveAll() throws {
        logger?("Saving all custom templates to disk")

        // Cancel pending saves
        for templateID in pendingSaves {
            cancelSave(for: templateID)
        }

        // Save all custom templates
        for template in customTemplates {
            try saveTemplateFile(template)
        }

        logger?("Saved all \(customTemplates.count) custom templates")
    }

    // MARK: - Template Lookup

    /// Finds a template by its ID
    ///
    /// - Parameter id: The template ID
    /// - Returns: The template if found
    func template(withID id: UUID) -> TaskTemplate? {
        return templates.first { $0.id == id }
    }

    /// Finds templates by name (case-insensitive)
    ///
    /// - Parameter name: The template name
    /// - Returns: Array of templates with matching names
    func templates(named name: String) -> [TaskTemplate] {
        let lowercaseName = name.lowercased()
        return templates.filter { $0.name.lowercased().contains(lowercaseName) }
    }

    /// Returns templates in a specific category
    ///
    /// - Parameter category: The category name
    /// - Returns: Array of templates in that category
    func templates(inCategory category: String) -> [TaskTemplate] {
        return templates.filter { $0.category == category }
    }

    /// Returns all unique categories
    var categories: [String] {
        let allCategories = templates.compactMap { $0.category }
        return Array(Set(allCategories)).sorted()
    }

    // MARK: - Export/Import

    /// Exports a template to JSON data
    ///
    /// - Parameter template: The template to export
    /// - Returns: JSON data representing the template
    /// - Throws: Error if encoding fails
    func export(_ template: TaskTemplate) throws -> Data {
        return try encoder.encode(template)
    }

    /// Exports a template to a file
    ///
    /// - Parameters:
    ///   - template: The template to export
    ///   - url: The destination file URL
    /// - Throws: Error if export fails
    func exportToFile(_ template: TaskTemplate, to url: URL) throws {
        let data = try export(template)
        try data.write(to: url, options: .atomic)
        logger?("Exported template '\(template.name)' to \(url.path)")
    }

    /// Imports a template from JSON data
    ///
    /// - Parameter data: JSON data representing a template
    /// - Returns: The imported template with a new ID
    /// - Throws: Error if decoding fails
    func `import`(from data: Data) throws -> TaskTemplate {
        var template = try decoder.decode(TaskTemplate.self, from: data)

        // Assign new ID and timestamps to avoid conflicts
        template = TaskTemplate(
            id: UUID(),
            name: template.name,
            title: template.title,
            notes: template.notes,
            defaultProject: template.defaultProject,
            defaultContext: template.defaultContext,
            defaultPriority: template.defaultPriority,
            defaultEffort: template.defaultEffort,
            defaultStatus: template.defaultStatus,
            tags: template.tags,
            subtasks: template.subtasks,
            defaultFlagged: template.defaultFlagged,
            category: template.category,
            created: Date(),
            modified: Date(),
            useCount: 0
        )

        logger?("Imported template: \(template.name)")
        return template
    }

    /// Imports a template from a file
    ///
    /// - Parameter url: The source file URL
    /// - Returns: The imported template
    /// - Throws: Error if import fails
    func importFromFile(_ url: URL) throws -> TaskTemplate {
        let data = try Data(contentsOf: url)
        let template = try self.import(from: data)
        logger?("Imported template '\(template.name)' from \(url.path)")
        return template
    }

    /// Imports a template and adds it to the store
    ///
    /// - Parameter url: The source file URL
    /// - Throws: Error if import fails
    func importAndCreate(from url: URL) throws {
        let template = try importFromFile(url)
        create(template)
    }

    /// Exports all custom templates to a directory
    ///
    /// - Parameter directory: The destination directory
    /// - Throws: Error if export fails
    func exportAll(to directory: URL) throws {
        try createDirectoryIfNeeded(directory)

        for template in customTemplates {
            let filename = "\(template.name.slugified())-\(template.id.uuidString).json"
            let fileURL = directory.appendingPathComponent(filename)
            try exportToFile(template, to: fileURL)
        }

        logger?("Exported \(customTemplates.count) templates to \(directory.path)")
    }

    // MARK: - Statistics

    /// Total number of templates
    var templateCount: Int {
        return templates.count
    }

    /// Number of custom templates
    var customTemplateCount: Int {
        return customTemplates.count
    }

    /// Number of built-in templates
    var builtInTemplateCount: Int {
        return builtInTemplates.count
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

    /// Returns the URL for a template file
    private func fileURL(for template: TaskTemplate) -> URL {
        let filename = "\(template.id.uuidString).json"
        return templatesDirectory.appendingPathComponent(filename)
    }

    /// Saves a template to a JSON file
    private func saveTemplateFile(_ template: TaskTemplate) throws {
        let url = fileURL(for: template)
        let data = try encoder.encode(template)
        try data.write(to: url, options: .atomic)
    }

    /// Deletes a template file
    private func deleteTemplateFile(_ template: TaskTemplate) throws {
        let url = fileURL(for: template)

        guard fileManager.fileExists(atPath: url.path) else {
            return
        }

        try fileManager.removeItem(at: url)
    }

    /// Schedules a debounced save for a template
    private func scheduleSave(for template: TaskTemplate) {
        // Cancel existing timer
        cancelSave(for: template.id)

        // Mark as pending
        pendingSaves.insert(template.id)

        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.queue.async {
                do {
                    try self.saveTemplateFile(template)
                    self.logger?("Debounced save completed for template: \(template.name)")
                } catch {
                    self.logger?("Failed to save template: \(error)")
                }

                DispatchQueue.main.async {
                    self.pendingSaves.remove(template.id)
                    self.saveTimers.removeValue(forKey: template.id)
                }
            }
        }

        saveTimers[template.id] = timer
    }

    /// Cancels a pending save
    private func cancelSave(for templateID: UUID) {
        saveTimers[templateID]?.invalidate()
        saveTimers.removeValue(forKey: templateID)
        pendingSaves.remove(templateID)
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
