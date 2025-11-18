//
//  CalendarSettingsViewController.swift
//  StickyToDo-AppKit
//
//  AppKit view controller for calendar settings.
//

import Cocoa
import SwiftUI

/// AppKit window controller for calendar settings
@available(macOS 10.15, *)
class CalendarSettingsViewController: NSViewController {

    // MARK: - Properties

    private var hostingView: NSHostingView<CalendarSettingsView>?

    // MARK: - Lifecycle

    override func loadView() {
        let settingsView = CalendarSettingsView()
        hostingView = NSHostingView(rootView: settingsView)
        view = hostingView!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Calendar Settings"
        preferredContentSize = NSSize(width: 600, height: 600)
    }
}

/// AppKit window controller wrapper for calendar settings
@available(macOS 10.15, *)
class CalendarSettingsWindowController: NSWindowController {

    // MARK: - Initialization

    convenience init() {
        let viewController = CalendarSettingsViewController()
        let window = NSWindow(contentViewController: viewController)

        window.title = "Calendar Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 600, height: 600))
        window.center()

        self.init(window: window)
    }

    // MARK: - Public Methods

    /// Show the calendar settings window
    func showSettings() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
