# Quick Start Guide - Final Polish Features

This guide helps you quickly get started with all the newly implemented polish features.

---

## 1. Generate App Icons

### Quick Method (Placeholder)

```bash
# Create a simple placeholder icon for development
./scripts/create-placeholder-icon.sh

# Generate all icon sizes
./scripts/generate-icons.sh
```

### Professional Method

1. Design your icon (1024x1024px minimum)
2. Save as `assets/icon-source.png`
3. Run: `./scripts/generate-icons.sh assets/icon-source.png`

See `assets/ICON_DESIGN.md` for design guidelines.

---

## 2. Configure Build Settings

### One-Command Setup

```bash
# Configure all build settings automatically
./scripts/configure-build.sh
```

This will:
- Create Info.plist files for all targets
- Generate xcconfig files (Debug/Release)
- Set up version numbering
- Verify project structure

---

## 3. Window State Persistence

### Automatic Usage

Window state is automatically saved when you:
- Move or resize windows
- Toggle inspector or sidebar
- Switch view modes
- Change perspectives
- Adjust zoom level

### Manual Control

```swift
import StickyToDoCore

let stateManager = WindowStateManager.shared

// Save current state
stateManager.saveState()

// Reset to defaults
stateManager.resetToDefaults()

// Access state
print("Current view mode: \(stateManager.viewMode)")
print("Inspector open: \(stateManager.inspectorIsOpen)")
```

---

## 4. Keyboard Shortcuts

### Global Shortcut

- **⌘⇧Space** - Quick Capture (works anywhere in macOS)

### File Operations

- **⌘N** - New Task
- **⌘S** - Save
- **⌘⇧I** - Import Tasks
- **⌘⇧E** - Export Tasks

### Task Management

- **⌘↩** - Complete Task
- **⌘D** - Duplicate Task
- **⌫** - Delete Task

### View Controls

- **⌘L** - Switch to List View
- **⌘B** - Switch to Board View
- **⌘⌥I** - Toggle Inspector
- **⌘⌥S** - Toggle Sidebar
- **⌘F** - Search

### Zoom

- **⌘+** - Zoom In
- **⌘-** - Zoom Out
- **⌘0** - Reset Zoom

### Perspectives

- **⌘1** - Inbox
- **⌘2** - Today
- **⌘3** - Upcoming
- **⌘4** - Someday
- **⌘5** - Completed
- **⌘6** - Boards
- **⌘⇧0** - All Tasks

### Navigation

- **J** - Next Task
- **K** - Previous Task
- **Space** - Quick Look

### Registering Custom Actions

```swift
import StickyToDoCore

let shortcuts = KeyboardShortcutManager.shared

shortcuts.registerAction(for: "newTask") {
    // Your action here
}
```

---

## 5. Performance Monitoring

### Enable Monitoring

```swift
import StickyToDoCore

let monitor = PerformanceMonitor.shared
monitor.isMonitoring = true

// Track app launch
monitor.markLaunchStart()
// ... initialization code
monitor.markLaunchComplete()

// Start memory monitoring
monitor.startMemoryMonitoring()
```

### Track Operations

```swift
// Measure synchronous operations
monitor.measure("loadTasks") {
    // Load tasks
}

// Measure async operations
await monitor.measureAsync("fetchData") {
    await fetchData()
}

// Manual tracking
monitor.startOperation("customOperation")
// ... do work
monitor.endOperation("customOperation")
```

### View Performance Report

```swift
// Print to console
monitor.printReport()

// Or get report object
let report = monitor.generateReport()
print("Launch time: \(report.launchDuration)s")
print("Memory: \(report.currentMemoryUsage) bytes")
```

### From Menu Bar

Select: **Help → Performance Monitor**

---

## 6. Accessibility

### Automatic Features

All UI elements now have:
- Accessibility identifiers for testing
- Descriptive labels for VoiceOver
- Hints for complex interactions
- Proper role assignments

### Testing with VoiceOver

1. Enable VoiceOver: **⌘F5**
2. Navigate with VoiceOver: **⌃⌥→** (next) / **⌃⌥←** (previous)
3. Interact with element: **⌃⌥Space**

### Custom Accessibility

```swift
import StickyToDoCore

// SwiftUI
Text("Task Title")
    .accessibleElement(
        identifier: "taskTitle",
        label: "Task title",
        hint: "The title of the current task"
    )

// AppKit
button.configureAccessibility(
    identifier: "deleteButton",
    label: "Delete task",
    help: "Remove the selected task permanently"
)
```

### VoiceOver Announcements

```swift
import StickyToDoCore

// Announce action completion
AccessibilityHelper.announceTaskCreated("New task")
AccessibilityHelper.announceTaskCompleted("Completed task")
AccessibilityHelper.announceTaskDeleted("Deleted task")
```

---

## 7. Menu Commands (SwiftUI)

### Add to Your App

```swift
import SwiftUI

@main
struct StickyToDoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            AppMenuCommands() // Add this
        }
    }
}
```

### Listen for Menu Actions

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Content")
            .onReceive(NotificationCenter.default.publisher(for: .createNewTask)) { _ in
                // Handle new task
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchToListView)) { _ in
                // Switch to list view
            }
    }
}
```

---

## 8. Running Tests

### Run All Tests

```bash
xcodebuild test -scheme StickyToDoTests
```

### Run Specific Test

```bash
xcodebuild test -scheme StickyToDoTests -only-testing:StickyToDoTests/IntegrationTests/testCreateEditCompleteDeleteTask
```

### Run Performance Tests

```bash
xcodebuild test -scheme StickyToDoTests -only-testing:StickyToDoTests/IntegrationTests/testPerformanceWithLargDataset
```

### View Test Coverage

In Xcode:
1. Product → Test (⌘U)
2. View → Navigators → Show Report Navigator (⌘9)
3. Select test report
4. Click "Coverage" tab

---

## 9. Build Configurations

### Debug Build

```bash
xcodebuild -configuration Debug -scheme StickyToDo-SwiftUI
```

Features:
- No optimization
- All logging enabled
- Performance monitoring ON
- Testability enabled

### Release Build

```bash
xcodebuild -configuration Release -scheme StickyToDo-SwiftUI
```

Features:
- Optimized for size
- Minimal logging
- Performance monitoring OFF
- Code signing required

### Archive for Distribution

```bash
xcodebuild archive \
    -scheme StickyToDo-SwiftUI \
    -archivePath build/StickyToDo.xcarchive
```

---

## 10. Common Tasks

### Change App Version

Edit in Xcode project settings:
- **MARKETING_VERSION:** 1.0.0
- **CURRENT_PROJECT_VERSION:** 1

Or use PlistBuddy:

```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.1.0" Info.plist
```

### Clean Build

```bash
xcodebuild clean -scheme StickyToDo-SwiftUI
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Reset User Defaults (Testing)

```swift
let stateManager = WindowStateManager.shared
stateManager.resetToDefaults()
```

Or from Terminal:

```bash
defaults delete com.stickytodo.app.swiftui
```

### Check Memory Usage

```swift
let monitor = PerformanceMonitor.shared
print("Current: \(monitor.getMemoryUsageString())")
print("Peak: \(monitor.getPeakMemoryUsageString())")
```

---

## 11. Troubleshooting

### Icons Not Showing

```bash
# Rebuild icon cache
./scripts/generate-icons.sh

# Clean and rebuild
xcodebuild clean
xcodebuild build
```

### Keyboard Shortcuts Not Working

```swift
// Re-register shortcuts
let shortcuts = KeyboardShortcutManager.shared
shortcuts.unregisterLocalShortcuts()
shortcuts.registerLocalShortcuts()
```

### Window State Not Persisting

```swift
// Manually save state
WindowStateManager.shared.saveState()

// Check UserDefaults
defaults read com.stickytodo.app.swiftui
```

### Performance Issues

```swift
// Generate performance report
PerformanceMonitor.shared.printReport()

// Reset tracking
PerformanceMonitor.shared.reset()
```

### Build Errors

```bash
# Reconfigure build settings
./scripts/configure-build.sh

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/StickyToDo-*
```

---

## 12. File Locations

| Feature | File Location |
|---------|--------------|
| Window State | `StickyToDoCore/Utilities/WindowStateManager.swift` |
| Performance Monitor | `StickyToDoCore/Utilities/PerformanceMonitor.swift` |
| Keyboard Shortcuts | `StickyToDoCore/Utilities/KeyboardShortcutManager.swift` |
| Accessibility | `StickyToDoCore/Utilities/AccessibilityHelper.swift` |
| SwiftUI Menus | `StickyToDo-SwiftUI/MenuCommands.swift` |
| AppKit Menus | `StickyToDo-AppKit/AppDelegate.swift` |
| Integration Tests | `StickyToDoTests/IntegrationTests.swift` |
| Icon Scripts | `scripts/generate-icons.sh`, `scripts/create-placeholder-icon.sh` |
| Build Config | `scripts/configure-build.sh` |
| Documentation | `docs/` |

---

## 13. Quick Commands Reference

```bash
# Setup
./scripts/configure-build.sh           # Configure build settings
./scripts/create-placeholder-icon.sh   # Create placeholder icon
./scripts/generate-icons.sh            # Generate all icon sizes

# Build
xcodebuild -scheme StickyToDo-SwiftUI  # Build SwiftUI app
xcodebuild -scheme StickyToDo-AppKit   # Build AppKit app

# Test
xcodebuild test -scheme StickyToDoTests                    # Run all tests
xcodebuild test -scheme StickyToDoTests -enableCodeCoverage YES  # With coverage

# Clean
xcodebuild clean                       # Clean build artifacts
rm -rf ~/Library/Developer/Xcode/DerivedData  # Clean derived data

# Archive
xcodebuild archive -scheme StickyToDo-SwiftUI  # Create archive
```

---

## 14. Default Values

| Setting | Default Value |
|---------|--------------|
| Inspector Open | true |
| Sidebar Width | 200pt |
| View Mode | list |
| Selected Perspective | inbox |
| Zoom Level | 1.0 (100%) |
| Search Query | "" (empty) |

---

## 15. Performance Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Launch Time | > 2.0s | > 5.0s |
| Memory Usage | > 250MB | > 500MB |
| Operation Time | > 100ms | > 1000ms |

---

## Support

For issues or questions:

1. Check `docs/FINAL_POLISH.md` for detailed information
2. Check `docs/BUILD_CONFIGURATION.md` for build issues
3. Review integration tests in `StickyToDoTests/`
4. Generate performance report: `PerformanceMonitor.shared.printReport()`

---

**Version:** 1.0.0
**Last Updated:** November 18, 2025
