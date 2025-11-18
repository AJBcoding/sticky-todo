# StickyToDo Data Layer - Quick Reference

## 🚀 Quick Start

### 1. Add Yams Package (5 minutes)
```
Xcode → File → Add Packages → https://github.com/jpsim/Yams.git
```

### 2. Initialize Data Manager (3 lines)
```swift
let dataManager = DataManager.shared
let dataURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    .appendingPathComponent("StickyToDo")
try await dataManager.initialize(rootDirectory: dataURL)
```

### 3. Access Data (SwiftUI)
```swift
@EnvironmentObject var taskStore: TaskStore
@EnvironmentObject var boardStore: BoardStore
```

---

## 📚 Core APIs

### DataManager (Central Access Point)

```swift
// Initialize
try await DataManager.shared.initialize(rootDirectory: url)

// Create
let task = dataManager.createTask(title: "Task", status: .inbox)
let board = dataManager.createBoard(id: "board", type: .custom)

// Access stores
dataManager.taskStore.tasks
dataManager.boardStore.boards

// Lifecycle
try dataManager.saveBeforeQuit()
dataManager.cleanup()
```

### TaskStore (In-Memory Tasks)

```swift
// Properties
taskStore.tasks              // All tasks
taskStore.projects           // Unique projects
taskStore.contexts           // Unique contexts

// CRUD
taskStore.add(task)
taskStore.update(task)
taskStore.delete(task)
taskStore.save(task)         // Debounced

// Filter
taskStore.tasks(withStatus: .inbox)
taskStore.tasks(forContext: "@phone")
taskStore.tasks(forProject: "Project")
taskStore.overdueTasks()
taskStore.dueTodayTasks()
taskStore.flaggedTasks()

// Search
taskStore.tasks(matchingSearch: "query")

// Statistics
taskStore.taskCount
taskStore.activeTaskCount
taskStore.inboxTaskCount
```

### BoardStore (In-Memory Boards)

```swift
// Properties
boardStore.boards            // All boards
boardStore.visibleBoards     // Visible only

// CRUD
boardStore.add(board)
boardStore.update(board)
boardStore.delete(board)

// Lookup
boardStore.board(withID: "inbox")
boardStore.boards(ofType: .context)

// Dynamic Creation
boardStore.getOrCreateContextBoard(for: context)
boardStore.getOrCreateProjectBoard(for: "Project")

// Visibility
boardStore.hide(board)
boardStore.show(board)
boardStore.updateAutoHideStatus(taskStore: taskStore)
```

---

## 🎯 Common Patterns

### Create Task with Metadata
```swift
var task = dataManager.createTask(title: "Call John", status: .inbox)
task.context = "@phone"
task.project = "Sales"
task.priority = .high
task.due = Date().addingTimeInterval(86400)
task.effort = 30
task.flagged = true
dataManager.updateTask(task)
```

### Get Tasks for Board
```swift
let board = boardStore.board(withID: "inbox")!
let tasks = taskStore.tasks(for: board)
```

### Filter with Custom Criteria
```swift
let filter = Filter(
    status: .nextAction,
    priority: .high,
    dueBefore: Date().addingTimeInterval(86400 * 7)
)
let tasks = taskStore.tasks(matching: filter)
```

### Batch Update
```swift
let selectedTasks = taskStore.tasks(forContext: "@phone")
let updated = selectedTasks.map { task in
    var t = task
    t.project = "Project"
    return t
}
taskStore.updateBatch(updated)
```

---

## 📁 File Locations

### Implementation
```
/home/user/sticky-todo/StickyToDo/Data/
├── YAMLParser.swift          (336 lines)
├── MarkdownFileIO.swift      (510 lines)
├── TaskStore.swift           (523 lines)
├── BoardStore.swift          (527 lines)
├── FileWatcher.swift         (386 lines)
├── DataManager.swift         (654 lines)
└── README.md                 (Complete docs)
```

### Documentation
```
/home/user/sticky-todo/
├── SETUP_DATA_LAYER.md                    (Setup guide)
├── DATA_LAYER_IMPLEMENTATION_SUMMARY.md   (Overview)
└── QUICK_REFERENCE.md                     (This file)
```

### Data Storage (Runtime)
```
~/Documents/StickyToDo/
├── tasks/active/YYYY/MM/uuid-title.md
├── tasks/archive/YYYY/MM/uuid-title.md
└── boards/board-id.md
```

---

## 🔧 Configuration

### Enable Logging
```swift
dataManager.enableLogging = true
dataManager.setLogger { message in
    print(message)
}
```

### Disable File Watching
```swift
dataManager.enableFileWatching = false
```

### First-Run Setup
```swift
dataManager.performFirstRunSetup(createSampleData: true)
```

---

## 🐛 Debugging

### Check Initialization
```swift
print(dataManager.isInitialized)
print(dataManager.statistics.description)
```

### Verify File Structure
```bash
ls -la ~/Documents/StickyToDo/
```

### Monitor File Watching
```swift
fileWatcher.setLogger { message in
    print("FileWatcher: \(message)")
}
```

### Force Save All
```swift
try taskStore.saveAll()
try boardStore.saveAll()
```

---

## ⚠️ Important Notes

1. **Always initialize before use**
   ```swift
   try await dataManager.initialize(rootDirectory: url)
   ```

2. **Save before quit**
   ```swift
   try dataManager.saveBeforeQuit()
   dataManager.cleanup()
   ```

3. **Use environment objects in SwiftUI**
   ```swift
   .environmentObject(dataManager.taskStore)
   .environmentObject(dataManager.boardStore)
   ```

4. **Add Yams package dependency**
   - Required for YAML parsing
   - https://github.com/jpsim/Yams.git

5. **Files update on main thread**
   - All @Published properties safe for UI
   - Background operations queued

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Total Lines of Code | 2,936 |
| Implementation Files | 6 |
| Documentation Files | 3 |
| Public APIs | ~100 |
| Dependencies | 1 (Yams) |

---

## ✅ Checklist

- [ ] Add Yams package in Xcode
- [ ] Add .swift files to Xcode project
- [ ] Initialize DataManager in app
- [ ] Test creating a task
- [ ] Verify files created in Documents
- [ ] Test loading after restart
- [ ] Enable logging for debugging
- [ ] Implement save before quit
- [ ] Test external file editing
- [ ] Review complete documentation

---

## 🔗 Links

- **Complete Docs:** `/StickyToDo/Data/README.md`
- **Setup Guide:** `/SETUP_DATA_LAYER.md`
- **Summary:** `/DATA_LAYER_IMPLEMENTATION_SUMMARY.md`
- **Design Doc:** `/docs/plans/2025-11-17-sticky-todo-design.md`
- **Yams Library:** https://github.com/jpsim/Yams

---

**Ready to Use!** 🎉

All data layer components are complete and ready for integration.
