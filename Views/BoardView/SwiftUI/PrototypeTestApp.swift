import SwiftUI

/// Standalone test application for the SwiftUI canvas prototype
///
/// **How to Run This Prototype:**
///
/// 1. Create a new macOS project in Xcode
/// 2. Copy all files from Views/BoardView/SwiftUI/ into the project
/// 3. Replace the App struct with this file
/// 4. Run on macOS (Command+R)
///
/// **Or use this as the App entry point:**
///
/// Set this as your @main App struct and it will launch the prototype
/// directly for testing.
@main
struct PrototypeTestApp: App {

    var body: some Scene {
        WindowGroup {
            CanvasPrototypeView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Custom commands for testing
            CommandGroup(after: .newItem) {
                Button("Generate 50 Notes") {
                    NotificationCenter.default.post(name: .generateNotes, object: 50)
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Generate 100 Notes") {
                    NotificationCenter.default.post(name: .generateNotes, object: 100)
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("Generate 200 Notes") {
                    NotificationCenter.default.post(name: .generateNotes, object: 200)
                }
                .keyboardShortcut("3", modifiers: [.command])

                Divider()

                Button("Clear Selection") {
                    NotificationCenter.default.post(name: .clearSelection, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command])

                Button("Delete Selected") {
                    NotificationCenter.default.post(name: .deleteSelected, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: [.command])

                Divider()

                Button("Reset View") {
                    NotificationCenter.default.post(name: .resetView, object: nil)
                }
                .keyboardShortcut("0", modifiers: [.command])
            }

            CommandGroup(after: .help) {
                Button("Show Instructions") {
                    NotificationCenter.default.post(name: .showInstructions, object: nil)
                }
                .keyboardShortcut("/", modifiers: [.command])
            }
        }

        // Settings window (optional)
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

// MARK: - Settings View

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            PerformanceSettingsView()
                .tabItem {
                    Label("Performance", systemImage: "speedometer")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showGrid") private var showGrid = true
    @AppStorage("showStats") private var showStats = true
    @AppStorage("snapToGrid") private var snapToGrid = false

    var body: some View {
        Form {
            Section("Display") {
                Toggle("Show Grid", isOn: $showGrid)
                Toggle("Show Performance Stats", isOn: $showStats)
            }

            Section("Behavior") {
                Toggle("Snap to Grid", isOn: $snapToGrid)
            }
        }
        .padding()
    }
}

struct PerformanceSettingsView: View {
    @AppStorage("targetFPS") private var targetFPS = 60.0
    @AppStorage("enableAnimations") private var enableAnimations = true

    var body: some View {
        Form {
            Section("Performance") {
                HStack {
                    Text("Target FPS:")
                    Slider(value: $targetFPS, in: 30...120, step: 15)
                    Text("\(Int(targetFPS))")
                        .frame(width: 40)
                }

                Toggle("Enable Animations", isOn: $enableAnimations)
            }

            Section("Benchmarks") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Test your system with different note counts:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    BenchmarkRow(noteCount: 50, expectedFPS: "55-60")
                    BenchmarkRow(noteCount: 100, expectedFPS: "45-55")
                    BenchmarkRow(noteCount: 200, expectedFPS: "30-45")
                }
            }
        }
        .padding()
    }
}

struct BenchmarkRow: View {
    let noteCount: Int
    let expectedFPS: String

    var body: some View {
        HStack {
            Text("\(noteCount) notes:")
                .frame(width: 100, alignment: .leading)
            Text("Expected FPS: \(expectedFPS)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("SwiftUI Canvas Prototype")
                .font(.title)

            Text("Version 1.0")
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Purpose:")
                    .font(.headline)
                Text("This prototype evaluates SwiftUI's suitability for building an infinite canvas with sticky notes, testing performance, gestures, and user interactions.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("For:")
                    .font(.headline)
                Text("StickyToDo - Visual GTD Task Manager")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(40)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let generateNotes = Notification.Name("generateNotes")
    static let clearSelection = Notification.Name("clearSelection")
    static let deleteSelected = Notification.Name("deleteSelected")
    static let resetView = Notification.Name("resetView")
    static let showInstructions = Notification.Name("showInstructions")
}

// MARK: - Usage Instructions
/*
 ═══════════════════════════════════════════════════════════════════════════
 HOW TO TEST THIS PROTOTYPE
 ═══════════════════════════════════════════════════════════════════════════

 **Option 1: Standalone Xcode Project**

 1. Create a new macOS App project in Xcode:
    - Open Xcode
    - File > New > Project
    - Choose "macOS" > "App"
    - Name it "StickyTodoPrototype"
    - Interface: SwiftUI
    - Language: Swift

 2. Copy files:
    - Copy all 5 Swift files from Views/BoardView/SwiftUI/
    - Add them to your Xcode project

 3. Update the App entry point:
    - Replace the default App struct with PrototypeTestApp
    - Or change @main to point to PrototypeTestApp

 4. Run:
    - Press Command+R
    - Or Product > Run

 **Option 2: Add to Existing Project**

 If you already have a StickyToDo Xcode project:

 1. Add all files to your project
 2. Add a new menu item or button to launch CanvasPrototypeView
 3. Test within your app context

 **Option 3: Swift Playgrounds (macOS)**

 You can also test in Swift Playgrounds on macOS:

 1. Open Swift Playgrounds
 2. Create a new macOS playground
 3. Paste the code from all files
 4. Run

 ═══════════════════════════════════════════════════════════════════════════
 TESTING CHECKLIST
 ═══════════════════════════════════════════════════════════════════════════

 Basic Functionality:
 ☐ Canvas pans smoothly when dragging background
 ☐ Pinch gesture zooms in and out
 ☐ Grid background updates with pan/zoom
 ☐ Notes render in correct positions
 ☐ Notes can be clicked to select
 ☐ Notes can be dragged individually
 ☐ Selection state is visually clear (blue border)

 Lasso Selection:
 ☐ Hold Option and drag to create lasso rectangle
 ☐ Lasso selection has dashed blue border
 ☐ Notes inside lasso get selected on release
 ☐ Can select multiple notes with lasso
 ☐ Lasso works at different zoom levels

 Multi-Selection:
 ☐ Command+click toggles individual note selection
 ☐ Shift+click adds to selection
 ☐ Can change color of multiple selected notes
 ☐ Can drag multiple selected notes together
 ☐ Can delete multiple selected notes

 Performance (50 notes):
 ☐ FPS stays above 50
 ☐ Pan gesture is smooth
 ☐ Zoom gesture is smooth
 ☐ Note dragging has no lag
 ☐ Lasso selection is responsive

 Performance (100 notes):
 ☐ FPS stays above 40
 ☐ Pan gesture is mostly smooth
 ☐ Note dragging is acceptable
 ☐ No crashes or freezes

 Performance (200 notes):
 ☐ App remains usable (even if slow)
 ☐ No crashes
 ☐ All features still work
 ☐ Note actual FPS for comparison

 Edge Cases:
 ☐ Zoom to min scale (0.25x)
 ☐ Zoom to max scale (4.0x)
 ☐ Pan to extreme coordinates
 ☐ Select all notes
 ☐ Delete all notes
 ☐ Generate notes multiple times

 ═══════════════════════════════════════════════════════════════════════════
 EVALUATION CRITERIA
 ═══════════════════════════════════════════════════════════════════════════

 Rate each aspect from 1 (Poor) to 5 (Excellent):

 Performance:
 [ ] 50 notes - Overall smoothness
 [ ] 100 notes - Overall smoothness
 [ ] Zoom performance
 [ ] Pan performance
 [ ] Multi-note drag performance

 Gesture Handling:
 [ ] Accuracy of gesture detection
 [ ] Intuitiveness of interactions
 [ ] Canvas pan vs note drag distinction
 [ ] Lasso selection usability
 [ ] Multi-touch gesture support

 User Experience:
 [ ] Visual feedback quality
 [ ] Animation smoothness
 [ ] Response to input
 [ ] Overall "feel"
 [ ] Professional appearance

 Development Experience:
 [ ] Code clarity and maintainability
 [ ] Ease of adding features
 [ ] Debugging experience
 [ ] SwiftUI limitations impact

 Final Recommendation:
 [ ] Use SwiftUI for production (5 = definitely, 1 = definitely not)

 Notes:
 _________________________________________________________________________
 _________________________________________________________________________
 _________________________________________________________________________

 ═══════════════════════════════════════════════════════════════════════════
 */
