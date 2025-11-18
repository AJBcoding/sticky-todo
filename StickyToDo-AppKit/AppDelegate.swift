//
//  AppDelegate.swift
//  StickyToDo-AppKit
//
//  Application delegate for StickyToDo AppKit app.
//  Handles app launch, menu setup, and global hotkeys.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    /// Main window controller
    private var mainWindowController: MainWindowController!

    /// Quick capture window controller
    private var quickCaptureController: QuickCaptureWindowController!

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create main window
        mainWindowController = MainWindowController()
        mainWindowController.showWindow(nil)

        // Create quick capture window
        quickCaptureController = QuickCaptureWindowController()
        quickCaptureController.delegate = self

        // Register global hotkey
        quickCaptureController.registerHotKey()

        // Setup menu bar
        setupMenuBar()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Cleanup
        quickCaptureController.unregisterHotKey()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        let mainMenu = NSMenu()

        // App Menu
        let appMenu = NSMenuItem()
        appMenu.submenu = createAppMenu()
        mainMenu.addItem(appMenu)

        // File Menu
        let fileMenu = NSMenuItem()
        fileMenu.submenu = createFileMenu()
        mainMenu.addItem(fileMenu)

        // Edit Menu
        let editMenu = NSMenuItem()
        editMenu.submenu = createEditMenu()
        mainMenu.addItem(editMenu)

        // View Menu
        let viewMenu = NSMenuItem()
        viewMenu.submenu = createViewMenu()
        mainMenu.addItem(viewMenu)

        // Go Menu
        let goMenu = NSMenuItem()
        goMenu.submenu = createGoMenu()
        mainMenu.addItem(goMenu)

        // Window Menu
        let windowMenu = NSMenuItem()
        windowMenu.submenu = createWindowMenu()
        mainMenu.addItem(windowMenu)

        // Help Menu
        let helpMenu = NSMenuItem()
        helpMenu.submenu = createHelpMenu()
        mainMenu.addItem(helpMenu)

        NSApp.mainMenu = mainMenu
    }

    private func createAppMenu() -> NSMenu {
        let menu = NSMenu(title: "StickyToDo")

        menu.addItem(NSMenuItem(title: "About StickyToDo", action: #selector(showAbout(_:)), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences(_:)), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Hide StickyToDo", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        menu.addItem({
            let item = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
            item.keyEquivalentModifierMask = [.command, .option]
            return item
        }())
        menu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit StickyToDo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        return menu
    }

    private func createFileMenu() -> NSMenu {
        let menu = NSMenu(title: "File")

        menu.addItem(NSMenuItem(title: "New Task", action: #selector(newTask(_:)), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "Quick Capture", action: #selector(showQuickCapture(_:)), keyEquivalent: "n") {
            $0.keyEquivalentModifierMask = [.command, .shift]
        })
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Open...", action: #selector(openDocument(_:)), keyEquivalent: "o"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))

        return menu
    }

    private func createEditMenu() -> NSMenu {
        let menu = NSMenu(title: "Edit")

        menu.addItem(NSMenuItem(title: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z"))
        menu.addItem(NSMenuItem(title: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        menu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(NSText.delete(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Find...", action: #selector(performFind(_:)), keyEquivalent: "f"))
        menu.addItem(NSMenuItem(title: "Find Next", action: #selector(performFindNext(_:)), keyEquivalent: "g"))
        menu.addItem(NSMenuItem(title: "Find Previous", action: #selector(performFindPrevious(_:)), keyEquivalent: "G"))

        return menu
    }

    private func createViewMenu() -> NSMenu {
        let menu = NSMenu(title: "View")

        menu.addItem(NSMenuItem(title: "Show List View", action: #selector(showListView(_:)), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "Show Board View", action: #selector(showBoardView(_:)), keyEquivalent: "b"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Show Inspector", action: #selector(toggleInspector(_:)), keyEquivalent: "i") {
            $0.keyEquivalentModifierMask = [.command, .option]
        })
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Zoom In", action: #selector(zoomIn(_:)), keyEquivalent: "+"))
        menu.addItem(NSMenuItem(title: "Zoom Out", action: #selector(zoomOut(_:)), keyEquivalent: "-"))
        menu.addItem(NSMenuItem(title: "Actual Size", action: #selector(zoomActual(_:)), keyEquivalent: "0"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f") {
            $0.keyEquivalentModifierMask = [.command, .control]
        })

        return menu
    }

    private func createGoMenu() -> NSMenu {
        let menu = NSMenu(title: "Go")

        menu.addItem(NSMenuItem(title: "Inbox", action: #selector(goToInbox(_:)), keyEquivalent: "1"))
        menu.addItem(NSMenuItem(title: "Next Actions", action: #selector(goToNextActions(_:)), keyEquivalent: "2"))
        menu.addItem(NSMenuItem(title: "Flagged", action: #selector(goToFlagged(_:)), keyEquivalent: "3"))
        menu.addItem(NSMenuItem(title: "Due Soon", action: #selector(goToDueSoon(_:)), keyEquivalent: "4"))

        return menu
    }

    private func createWindowMenu() -> NSMenu {
        let menu = NSMenu(title: "Window")

        menu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: ""))

        NSApp.windowsMenu = menu
        return menu
    }

    private func createHelpMenu() -> NSMenu {
        let menu = NSMenu(title: "Help")

        menu.addItem(NSMenuItem(title: "StickyToDo Help", action: #selector(showHelp(_:)), keyEquivalent: "?"))

        return menu
    }

    // MARK: - Menu Actions

    @objc private func showAbout(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(sender)
    }

    @objc private func showPreferences(_ sender: Any?) {
        // Show preferences window
        print("Show preferences")
    }

    @objc private func newTask(_ sender: Any?) {
        // Create new task in main window
        print("New task")
    }

    @objc private func showQuickCapture(_ sender: Any?) {
        quickCaptureController.show()
    }

    @objc private func openDocument(_ sender: Any?) {
        // Show open panel for opening a StickyToDo folder
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Open StickyToDo Folder"
        openPanel.message = "Select a folder containing StickyToDo markdown files"

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                print("Open folder: \(url.path)")
                // TODO: Load tasks from folder
            }
        }
    }

    @objc private func performFind(_ sender: Any?) {
        // Focus search field
        print("Find")
    }

    @objc private func performFindNext(_ sender: Any?) {
        print("Find next")
    }

    @objc private func performFindPrevious(_ sender: Any?) {
        print("Find previous")
    }

    @objc private func showListView(_ sender: Any?) {
        print("Show list view")
    }

    @objc private func showBoardView(_ sender: Any?) {
        print("Show board view")
    }

    @objc private func toggleInspector(_ sender: Any?) {
        print("Toggle inspector")
    }

    @objc private func zoomIn(_ sender: Any?) {
        print("Zoom in")
    }

    @objc private func zoomOut(_ sender: Any?) {
        print("Zoom out")
    }

    @objc private func zoomActual(_ sender: Any?) {
        print("Zoom actual")
    }

    @objc private func goToInbox(_ sender: Any?) {
        print("Go to Inbox")
    }

    @objc private func goToNextActions(_ sender: Any?) {
        print("Go to Next Actions")
    }

    @objc private func goToFlagged(_ sender: Any?) {
        print("Go to Flagged")
    }

    @objc private func goToDueSoon(_ sender: Any?) {
        print("Go to Due Soon")
    }

    @objc private func showHelp(_ sender: Any?) {
        if let url = URL(string: "https://github.com/yourusername/stickytodo") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - QuickCaptureDelegate

extension AppDelegate: QuickCaptureDelegate {
    func quickCaptureDidCreateTask(_ task: Task) {
        // Forward to main window to save task
        print("Quick capture created task: \(task.title)")
        // TODO: Save task through data layer
    }
}

// MARK: - NSMenuItem Extension

fileprivate extension NSMenuItem {
    convenience init(title: String, action: Selector?, keyEquivalent: String, configure: ((NSMenuItem) -> Void)? = nil) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)
        configure?(self)
    }
}
