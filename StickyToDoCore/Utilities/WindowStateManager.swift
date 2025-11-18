//
//  WindowStateManager.swift
//  StickyToDoCore
//
//  Created on 2025-11-18.
//  Copyright © 2025 Sticky ToDo. All rights reserved.
//

import Foundation
import Combine

#if canImport(AppKit)
import AppKit
#endif

/// Manages window state persistence across app launches
public class WindowStateManager: ObservableObject {
    public static let shared = WindowStateManager()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Keys
    private enum Keys {
        static let windowFrames = "windowFrames"
        static let inspectorState = "inspectorState"
        static let sidebarWidth = "sidebarWidth"
        static let viewMode = "viewMode"
        static let selectedPerspective = "selectedPerspective"
        static let lastUsedBoard = "lastUsedBoard"
        static let searchQuery = "searchQuery"
        static let windowStates = "windowStates"
        static let lastActiveWindow = "lastActiveWindow"
        static let zoomLevel = "zoomLevel"
        static let sortOrder = "sortOrder"
        static let filterSettings = "filterSettings"
    }

    // MARK: - Published Properties
    @Published public var inspectorIsOpen: Bool = true
    @Published public var sidebarWidth: CGFloat = 200
    @Published public var viewMode: ViewMode = .list
    @Published public var selectedPerspective: String = "inbox"
    @Published public var lastUsedBoard: String?
    @Published public var searchQuery: String = ""
    @Published public var zoomLevel: CGFloat = 1.0

    // MARK: - Window State Tracking
    private var windowStates: [String: WindowState] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    private init() {
        loadState()
        setupObservers()
    }

    // MARK: - State Management

    /// Load all persisted state from UserDefaults
    private func loadState() {
        inspectorIsOpen = defaults.bool(forKey: Keys.inspectorState)
        if inspectorIsOpen == false && !defaults.bool(forKey: Keys.inspectorState + "_set") {
            inspectorIsOpen = true // Default to true on first launch
        }

        sidebarWidth = CGFloat(defaults.double(forKey: Keys.sidebarWidth))
        if sidebarWidth == 0 {
            sidebarWidth = 200 // Default width
        }

        if let viewModeString = defaults.string(forKey: Keys.viewMode),
           let mode = ViewMode(rawValue: viewModeString) {
            viewMode = mode
        }

        selectedPerspective = defaults.string(forKey: Keys.selectedPerspective) ?? "inbox"
        lastUsedBoard = defaults.string(forKey: Keys.lastUsedBoard)
        searchQuery = defaults.string(forKey: Keys.searchQuery) ?? ""

        zoomLevel = CGFloat(defaults.double(forKey: Keys.zoomLevel))
        if zoomLevel == 0 {
            zoomLevel = 1.0
        }

        // Load window states
        if let data = defaults.data(forKey: Keys.windowStates),
           let states = try? decoder.decode([String: WindowState].self, from: data) {
            windowStates = states
        }
    }

    /// Save all current state to UserDefaults
    public func saveState() {
        defaults.set(inspectorIsOpen, forKey: Keys.inspectorState)
        defaults.set(true, forKey: Keys.inspectorState + "_set")
        defaults.set(Double(sidebarWidth), forKey: Keys.sidebarWidth)
        defaults.set(viewMode.rawValue, forKey: Keys.viewMode)
        defaults.set(selectedPerspective, forKey: Keys.selectedPerspective)
        defaults.set(lastUsedBoard, forKey: Keys.lastUsedBoard)
        defaults.set(searchQuery, forKey: Keys.searchQuery)
        defaults.set(Double(zoomLevel), forKey: Keys.zoomLevel)

        // Save window states
        if let data = try? encoder.encode(windowStates) {
            defaults.set(data, forKey: Keys.windowStates)
        }
    }

    /// Setup observers to auto-save on changes
    private func setupObservers() {
        // Auto-save when properties change
        Publishers.Merge4(
            $inspectorIsOpen.dropFirst(),
            $sidebarWidth.dropFirst().map { _ in true },
            $viewMode.dropFirst().map { _ in true },
            $selectedPerspective.dropFirst().map { _ in true }
        )
        .debounce(for: 0.5, scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.saveState()
        }
        .store(in: &cancellables)

        Publishers.Merge3(
            $lastUsedBoard.dropFirst().map { _ in true },
            $searchQuery.dropFirst().map { _ in true },
            $zoomLevel.dropFirst().map { _ in true }
        )
        .debounce(for: 0.5, scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.saveState()
        }
        .store(in: &cancellables)
    }

    // MARK: - Window Frame Management

    #if canImport(AppKit)
    /// Save window frame for a specific window identifier
    public func saveWindowFrame(_ frame: NSRect, for identifier: String) {
        var state = windowStates[identifier] ?? WindowState(identifier: identifier)
        state.frame = frame
        state.lastModified = Date()
        windowStates[identifier] = state

        defaults.set(identifier, forKey: Keys.lastActiveWindow)
        saveState()
    }

    /// Restore window frame for a specific window identifier
    public func restoreWindowFrame(for identifier: String) -> NSRect? {
        return windowStates[identifier]?.frame
    }

    /// Get the last active window identifier
    public func getLastActiveWindowIdentifier() -> String? {
        return defaults.string(forKey: Keys.lastActiveWindow)
    }

    /// Save window state including position, size, and other properties
    public func saveWindowState(_ window: NSWindow, identifier: String) {
        var state = windowStates[identifier] ?? WindowState(identifier: identifier)
        state.frame = window.frame
        state.isFullScreen = window.styleMask.contains(.fullScreen)
        state.isMiniaturized = window.isMiniaturized
        state.lastModified = Date()

        windowStates[identifier] = state
        saveState()
    }

    /// Restore window state including position and size
    public func restoreWindowState(for window: NSWindow, identifier: String) {
        guard let state = windowStates[identifier] else { return }

        // Set frame
        window.setFrame(state.frame, display: true)

        // Restore other properties
        if state.isMiniaturized {
            window.miniaturize(nil)
        }
    }
    #endif

    // MARK: - Per-Window State

    /// Save state specific to a window instance
    public func saveWindowSpecificState(_ state: WindowSpecificState, for identifier: String) {
        var windowState = windowStates[identifier] ?? WindowState(identifier: identifier)
        windowState.specificState = state
        windowState.lastModified = Date()
        windowStates[identifier] = windowState
        saveState()
    }

    /// Restore state specific to a window instance
    public func restoreWindowSpecificState(for identifier: String) -> WindowSpecificState? {
        return windowStates[identifier]?.specificState
    }

    // MARK: - Reset

    /// Reset all window states
    public func resetAllWindowStates() {
        windowStates.removeAll()
        defaults.removeObject(forKey: Keys.windowStates)
        defaults.removeObject(forKey: Keys.lastActiveWindow)
    }

    /// Reset all persisted state to defaults
    public func resetToDefaults() {
        defaults.removeObject(forKey: Keys.inspectorState)
        defaults.removeObject(forKey: Keys.inspectorState + "_set")
        defaults.removeObject(forKey: Keys.sidebarWidth)
        defaults.removeObject(forKey: Keys.viewMode)
        defaults.removeObject(forKey: Keys.selectedPerspective)
        defaults.removeObject(forKey: Keys.lastUsedBoard)
        defaults.removeObject(forKey: Keys.searchQuery)
        defaults.removeObject(forKey: Keys.zoomLevel)
        defaults.removeObject(forKey: Keys.sortOrder)
        defaults.removeObject(forKey: Keys.filterSettings)
        resetAllWindowStates()

        loadState() // Reload defaults
    }
}

// MARK: - Supporting Types

public enum ViewMode: String, Codable {
    case list
    case board
}

public struct WindowState: Codable {
    var identifier: String
    var frame: CGRect = .zero
    var isFullScreen: Bool = false
    var isMiniaturized: Bool = false
    var lastModified: Date = Date()
    var specificState: WindowSpecificState?

    enum CodingKeys: String, CodingKey {
        case identifier, frame, isFullScreen, isMiniaturized, lastModified, specificState
    }

    public init(identifier: String) {
        self.identifier = identifier
    }
}

public struct WindowSpecificState: Codable {
    var inspectorOpen: Bool = true
    var sidebarWidth: CGFloat = 200
    var selectedPerspective: String = "inbox"
    var viewMode: ViewMode = .list
    var searchQuery: String = ""
    var zoomLevel: CGFloat = 1.0
    var scrollPosition: CGPoint = .zero
    var selectedTaskIDs: [String] = []

    public init() {}
}

// MARK: - CGRect Codable Extension

extension CGRect: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y, width, height
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin.x, forKey: .x)
        try container.encode(origin.y, forKey: .y)
        try container.encode(size.width, forKey: .width)
        try container.encode(size.height, forKey: .height)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(x: x, y: y, width: width, height: height)
    }
}

extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
}
