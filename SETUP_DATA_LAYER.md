# StickyToDo Data Layer Setup Guide

## Overview

The complete shared data layer has been implemented in `/StickyToDo/Data/`:

✅ **YAMLParser.swift** - YAML frontmatter parsing
✅ **MarkdownFileIO.swift** - File system I/O
✅ **TaskStore.swift** - In-memory task management
✅ **BoardStore.swift** - In-memory board management
✅ **FileWatcher.swift** - FSEvents monitoring
✅ **DataManager.swift** - Central coordinator

## Quick Start

### Step 1: Add Yams Package Dependency

The data layer requires the Yams library for YAML parsing.

**In Xcode:**

1. Open `StickyToDo.xcodeproj` in Xcode
2. Select the project in the Project Navigator (top-level "StickyToDo")
3. In the main editor, select your app target (e.g., "StickyToDo")
4. Click on the "Package Dependencies" tab
5. Click the "+" button at the bottom
6. In the search field, enter: `https://github.com/jpsim/Yams.git`
7. Select "Up to Next Major Version" with "5.0.0" (or latest)
8. Click "Add Package"
9. When prompted, select "Yams" for your target
10. Click "Add Package" again

**Verify Installation:**
- Build the project (Cmd+B)
- The Yams package should appear in the Project Navigator under "Package Dependencies"
- No import errors should appear in YAMLParser.swift

### Step 2: Add Data Layer Files to Xcode

The files have been created but need to be added to your Xcode project:

1. In Xcode, right-click on the `StickyToDo/Data` folder in the Project Navigator
2. Select "Add Files to 'StickyToDo'..."
3. Navigate to `/StickyToDo/Data/`
4. Select all the Swift files:
   - YAMLParser.swift
   - MarkdownFileIO.swift
   - TaskStore.swift
   - BoardStore.swift
   - FileWatcher.swift
   - DataManager.swift
5. Make sure "Copy items if needed" is **UNCHECKED** (files are already in the right place)
6. Make sure your app target is **CHECKED**
7. Click "Add"

### Step 3: Initialize in Your App

**For SwiftUI App:**

Edit `StickyToDo/StickyToDoApp.swift`:

```swift
import SwiftUI

@main
struct StickyToDoApp: App {
    @StateObject private var dataManager = DataManager.shared

    init() {
        // Configure logging for debugging
        DataManager.shared.enableLogging = true
        DataManager.shared.setLogger { message in
            print(message)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager.taskStore)
                .environmentObject(dataManager.boardStore)
                .task {
                    await initializeDataManager()
                }
        }
        .commands {
            CommandGroup(after: .saveItem) {
                Button("Save All Data") {
                    try? dataManager.saveBeforeQuit()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }

    private func initializeDataManager() async {
        do {
            // Get Documents directory
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!

            // Create StickyToDo data directory
            let dataURL = documentsURL.appendingPathComponent("StickyToDo")

            // Initialize data manager
            try await dataManager.initialize(rootDirectory: dataURL)

            // Perform first-run setup (creates sample data if empty)
            dataManager.performFirstRunSetup(createSampleData: true)

            print("Data layer initialized successfully!")
            print(dataManager.statistics.description)
        } catch {
            print("Failed to initialize data layer: \(error)")
        }
    }
}
```

**For AppKit App:**

Edit your `AppDelegate.swift`:

```swift
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let dataManager = DataManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure logging
        dataManager.enableLogging = true
        dataManager.setLogger { message in
            print(message)
        }

        // Initialize data layer
        do {
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!
            let dataURL = documentsURL.appendingPathComponent("StickyToDo")

            try dataManager.initialize(rootDirectory: dataURL)
            dataManager.performFirstRunSetup(createSampleData: true)

            print("Data layer initialized!")
            print(dataManager.statistics.description)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to Initialize"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save all data before quitting
        do {
            try dataManager.saveBeforeQuit()
            dataManager.cleanup()
            return .terminateNow
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to Save Data"
            alert.informativeText = "Some changes may be lost. Quit anyway?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Quit Anyway")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            return response == .alertFirstButtonReturn ? .terminateNow : .terminateCancel
        }
    }
}
```

### Step 4: Test the Implementation

Create a simple test to verify everything works:

**Add to ContentView.swift:**

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var boardStore: BoardStore

    var body: some View {
        VStack(spacing: 20) {
            Text("StickyToDo Data Layer")
                .font(.largeTitle)

            // Statistics
            VStack(alignment: .leading, spacing: 10) {
                Text("📊 Statistics")
                    .font(.headline)

                Text("Tasks: \(taskStore.taskCount)")
                Text("Active: \(taskStore.activeTaskCount)")
                Text("Inbox: \(taskStore.inboxTaskCount)")
                Text("Boards: \(boardStore.boardCount)")
                Text("Visible Boards: \(boardStore.visibleBoardCount)")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            // Task list
            List(taskStore.tasks) { task in
                VStack(alignment: .leading) {
                    Text(task.title)
                        .font(.headline)
                    Text(task.status.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Action buttons
            HStack {
                Button("Add Test Task") {
                    let task = Task(
                        title: "Test task \(Date())",
                        notes: "This is a test task",
                        status: .inbox
                    )
                    taskStore.add(task)
                }

                Button("Clear All") {
                    taskStore.deleteBatch(taskStore.tasks)
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
}
```

### Step 5: Build and Run

1. **Build the project:** Cmd+B
2. **Run the app:** Cmd+R
3. **Check the console** for initialization messages
4. **Verify the data directory** was created:
   - Open Finder
   - Go to `~/Documents/StickyToDo/`
   - You should see `tasks/`, `boards/`, and `config/` directories

### Step 6: Test External File Watching

1. **With the app running**, open Finder
2. Navigate to `~/Documents/StickyToDo/tasks/active/`
3. Find a task markdown file (e.g., `2025/11/uuid-task-name.md`)
4. Open it in a text editor
5. Modify the title in the YAML frontmatter
6. Save the file
7. **The app should detect the change** and update automatically (check console logs)

## Troubleshooting

### Yams Import Error

**Problem:** `import Yams` shows an error
**Solution:**
- Verify Yams was added via Swift Package Manager
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
- Restart Xcode

### Files Not Found in Xcode

**Problem:** Swift files show errors in Xcode
**Solution:**
- Right-click on `StickyToDo/Data` folder
- Choose "Add Files to 'StickyToDo'..."
- Select all the .swift files
- Ensure target membership is correct

### Directory Creation Failed

**Problem:** Error creating directory structure
**Solution:**
- Check app has permission to write to Documents folder
- In macOS System Settings → Privacy & Security → Files and Folders
- Grant permission to the app

### File Watcher Not Working

**Problem:** External file changes not detected
**Solution:**
- Verify `enableFileWatching = true` (it's enabled by default)
- Check console for FSEvents messages
- Ensure you're editing files in the correct directory

## Directory Structure

After initialization, your data will be organized like this:

```
~/Documents/StickyToDo/
├── tasks/
│   ├── active/
│   │   └── 2025/
│   │       └── 11/
│   │           ├── uuid-task-1.md
│   │           └── uuid-task-2.md
│   └── archive/
│       └── 2025/
│           └── 11/
│               └── uuid-completed-task.md
├── boards/
│   ├── inbox.md
│   ├── next-actions.md
│   ├── flagged.md
│   └── custom-board.md
└── config/
    └── (future config files)
```

## Example Usage

### Create a Task

```swift
let dataManager = DataManager.shared

// Simple creation
let task = dataManager.createTask(
    title: "Call John",
    notes: "Discuss project timeline",
    status: .inbox
)

// With full metadata
var detailedTask = dataManager.createTask(title: "Write proposal")
detailedTask.context = "@computer"
detailedTask.project = "Website Redesign"
detailedTask.priority = .high
detailedTask.due = Calendar.current.date(byAdding: .day, value: 3, to: Date())
detailedTask.effort = 120  // 2 hours
detailedTask.flagged = true
dataManager.updateTask(detailedTask)
```

### Filter Tasks

```swift
// By status
let inboxTasks = dataManager.taskStore.tasks(withStatus: .inbox)
let nextActions = dataManager.taskStore.tasks(withStatus: .nextAction)

// By context/project
let phoneTasks = dataManager.taskStore.tasks(forContext: "@phone")
let projectTasks = dataManager.taskStore.tasks(forProject: "Website Redesign")

// Special filters
let overdue = dataManager.taskStore.overdueTasks()
let dueToday = dataManager.taskStore.dueTodayTasks()
let flagged = dataManager.taskStore.flaggedTasks()

// Search
let results = dataManager.taskStore.tasks(matchingSearch: "john")

// Custom filter
let customFilter = Filter(
    status: .nextAction,
    priority: .high,
    dueBefore: Date().addingTimeInterval(86400 * 7)  // Due within a week
)
let filteredTasks = dataManager.taskStore.tasks(matching: customFilter)
```

### Work with Boards

```swift
// Get built-in boards
let inbox = dataManager.boardStore.board(withID: "inbox")
let nextActions = dataManager.boardStore.board(withID: "next-actions")

// Create custom board
let customBoard = dataManager.createBoard(
    id: "urgent",
    type: .custom,
    layout: .grid,
    filter: Filter(priority: .high, flagged: true)
)

// Get tasks for a board
let boardTasks = dataManager.taskStore.tasks(for: inbox!)

// Auto-create context boards
let computerContext = Context(name: "@computer", icon: "💻", color: "blue")
let computerBoard = dataManager.boardStore.getOrCreateContextBoard(for: computerContext)

// Auto-create project boards
let projectBoard = dataManager.boardStore.getOrCreateProjectBoard(for: "Website Redesign")
```

## Next Steps

1. ✅ Data layer is complete and functional
2. 🔄 Integrate with your UI (List View, Board View)
3. 🔄 Implement quick capture
4. 🔄 Add search functionality
5. 🔄 Build conflict resolution UI
6. 🔄 Create unit tests for data layer

## Documentation

Complete documentation is available in:
- `/StickyToDo/Data/README.md` - Detailed component documentation
- Each Swift file has comprehensive inline documentation
- See design doc: `/docs/plans/2025-11-17-sticky-todo-design.md`

## Support

If you encounter issues:

1. **Enable logging:**
   ```swift
   DataManager.shared.enableLogging = true
   ```

2. **Check the console output** for detailed error messages

3. **Verify file structure** in `~/Documents/StickyToDo/`

4. **Test with a clean directory** by moving the existing one and letting it recreate

---

**Ready to use!** The complete shared data layer is now available for both AppKit and SwiftUI apps.
