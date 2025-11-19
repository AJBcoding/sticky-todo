import Cocoa

/// Standalone window for testing the AppKit canvas prototype
///
/// ## Usage:
/// Run this to launch the prototype in a standalone window for testing.
/// This demonstrates all canvas features without requiring a full app.
///
/// ## What to Test:
///
/// ### 1. Pan/Zoom Performance
/// - Option+drag to pan the canvas
/// - Command+scroll to zoom in/out
/// - Zoom to 300% and pan around - should remain smooth
/// - Zoom to 25% and verify all notes are visible
///
/// ### 2. Note Dragging
/// - Click and drag individual notes
/// - Try dragging while zoomed in/out
/// - Drag multiple notes after selection
/// - Verify smooth movement without lag
///
/// ### 3. Lasso Selection
/// - Click empty space and drag to create selection rectangle
/// - Select 10-20 notes at once
/// - Verify visual feedback (blue selection box)
/// - Verify selected notes show blue border
///
/// ### 4. Multi-select
/// - Command+click individual notes to toggle selection
/// - Select 30+ notes and verify performance
/// - Drag a selected group of notes
///
/// ### 5. Keyboard Shortcuts
/// - Delete key to remove selected notes
/// - Command+A to select all
/// - Escape to deselect all
///
/// ### 6. Performance with 100+ Notes
/// - Click "Add Note" repeatedly to add more notes
/// - Load 100+ notes and test interactions
/// - Pan/zoom should remain buttery smooth
/// - Selection should be instant
/// - No lag when dragging notes
///
/// ## Expected Performance Results:
///
/// With 100 notes:
/// - Pan: 60 FPS smooth scrolling
/// - Zoom: Instant response to Command+scroll
/// - Lasso: Real-time selection rectangle drawing
/// - Drag: Notes follow cursor without lag
/// - Multi-select: Instant visual feedback
///
/// ## AppKit Performance Advantages:
///
/// 1. **Direct View Manipulation**: NSView instances can be moved immediately
///    without waiting for state updates or view diffing
///
/// 2. **Efficient Hit Testing**: Built-in NSView hit testing is fast
///    and doesn't require manual geometry calculations
///
/// 3. **Layer Backing**: CALayer provides hardware-accelerated rendering
///    without extra configuration
///
/// 4. **Event Handling**: Direct mouse event handling is more responsive
///    than gesture recognizers
///
/// 5. **Memory Control**: Precise control over view lifecycle and memory
///    usage allows optimization for thousands of views
///
/// ## Comparison Summary:
///
/// ### AppKit Strengths for Canvas:
/// ✓ Better performance with many interactive views
/// ✓ More precise control over scroll/zoom behavior
/// ✓ Easier to implement custom drag and lasso selection
/// ✓ Simpler coordinate space management
/// ✓ Better debugging tools (view hierarchy debugger)
/// ✓ Mature APIs with extensive documentation
/// ✓ Direct access to CALayer for advanced effects
///
/// ### SwiftUI Advantages (for other parts of app):
/// ✓ Less code for simple layouts
/// ✓ Declarative syntax
/// ✓ Automatic state binding
/// ✓ Built-in animations
/// ✓ Better for forms and lists
/// ✓ Cross-platform code sharing
///
/// ## Production Recommendation:
///
/// **Use AppKit for canvas views** because:
/// - Superior performance with 100+ interactive views
/// - Better control over complex interactions
/// - More predictable behavior for drag/zoom/pan
/// - Easier to optimize and debug
/// - Can always embed in SwiftUI using NSViewRepresentable
///
/// **Use SwiftUI for other UI** like:
/// - Sidebar navigation
/// - Inspector panels
/// - Settings screens
/// - Task detail views
/// - Simple forms and lists
///
/// **Hybrid approach** (recommended):
/// - AppKit for canvas (this prototype)
/// - SwiftUI for everything else
/// - NSHostingView to embed SwiftUI in AppKit windows
///
@main
class PrototypeApp: NSObject, NSApplicationDelegate {

    private var window: NSWindow!
    private var controller: CanvasController!

    static func main() {
        let app = NSApplication.shared
        let delegate = PrototypeApp()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        showInstructions()
    }

    private func setupWindow() {
        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "AppKit Canvas Prototype - StickyToDo"
        window.center()

        // Create and set controller
        controller = CanvasController()
        window.contentViewController = controller

        // Show window
        window.makeKeyAndOrderFront(nil)

        // Set app activation policy
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showInstructions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showInstructionsAlert()
        }
    }

    private func showInstructionsAlert() {
        let alert = NSAlert()
        alert.messageText = "AppKit Canvas Prototype"
        alert.informativeText = """
        🖱️ Controls:
        • Drag notes to move them
        • Option+drag to pan canvas
        • Command+scroll to zoom
        • Drag on empty space for lasso selection
        • Delete key to remove notes

        75 notes loaded. Try dragging, panning, and zooming!
        """

        alert.addButton(withTitle: "Start Testing")
        alert.addButton(withTitle: "More Help")

        if alert.runModal() == .alertSecondButtonReturn {
            // Show help again
            self.showDetailedHelp()
        }
    }

    private func showDetailedHelp() {
        let alert = NSAlert()
        alert.messageText = "Detailed Testing Guide"
        alert.informativeText = """
        📋 Test Checklist:

        1. Pan Performance
           □ Option+drag to pan around canvas
           □ Should be smooth with no lag
           □ Try rapid panning movements

        2. Zoom Performance
           □ Command+scroll to zoom in/out
           □ Test zoom from 25% to 300%
           □ Notes should stay sharp at all zoom levels

        3. Note Dragging
           □ Drag individual notes
           □ Drag while zoomed in/out
           □ Drag multiple selected notes together

        4. Lasso Selection
           □ Click+drag empty space
           □ Select 10-20 notes at once
           □ Try overlapping selections

        5. Multi-Select
           □ Command+click to toggle selection
           □ Select 30+ notes
           □ Drag selected group

        6. Stress Test
           □ Add notes until you have 100+
           □ Test all interactions at scale
           □ Monitor responsiveness

        📊 What to Observe:
        • FPS stays at 60 during pan/zoom
        • No lag when dragging notes
        • Instant visual feedback
        • Smooth animations
        • Memory usage stays reasonable

        ✅ AppKit Advantages:
        • Direct view manipulation
        • Efficient event handling
        • Layer-backed rendering
        • Precise coordinate control
        • Better performance at scale
        """

        alert.addButton(withTitle: "Got It!")
        alert.runModal()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Launch Helper

extension PrototypeApp {
    /// Convenience method to launch prototype programmatically
    static func launch() {
        let app = NSApplication.shared
        let delegate = PrototypeApp()
        app.delegate = delegate
        app.run()
    }
}

// MARK: - Testing Utilities

extension CanvasController {
    /// Add random test notes for stress testing
    func addRandomNotes(count: Int) {
        for i in 0..<count {
            let randomX = CGFloat.random(in: 200...4800)
            let randomY = CGFloat.random(in: 200...4800)
            let position = NSPoint(x: randomX, y: randomY)

            let note = StickyNoteView(
                id: UUID(),
                title: "Random Note \(i + 1)",
                color: .randomStickyColor,
                position: position
            )

            canvasView.addNote(note)
        }
    }

    /// Measure rendering performance
    func measureRenderTime() -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Force a full render
        canvasView.needsDisplay = true
        canvasView.displayIfNeeded()

        let endTime = CFAbsoluteTimeGetCurrent()
        return endTime - startTime
    }

    /// Get memory usage estimate
    func estimateMemoryUsage() -> String {
        let noteCount = canvasView.noteViews.count
        let bytesPerNote = MemoryLayout<StickyNoteView>.size
        let totalBytes = noteCount * bytesPerNote

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory

        return formatter.string(fromByteCount: Int64(totalBytes))
    }
}

// MARK: - Performance Monitoring

class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private var frameCount = 0
    private var lastTime = CACurrentMediaTime()
    private var fps: Double = 0

    func recordFrame() {
        frameCount += 1

        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - lastTime

        if elapsed >= 1.0 {
            fps = Double(frameCount) / elapsed
            frameCount = 0
            lastTime = currentTime
        }
    }

    var currentFPS: Double {
        return fps
    }

    var formattedFPS: String {
        return String(format: "%.1f FPS", fps)
    }
}

// MARK: - Debug Helpers

extension NSView {
    /// Print view hierarchy for debugging
    func printHierarchy(indent: Int = 0) {
        let prefix = String(repeating: "  ", count: indent)
        print("\(prefix)↳ \(type(of: self)) frame=\(frame)")

        for subview in subviews {
            subview.printHierarchy(indent: indent + 1)
        }
    }

    /// Highlight view bounds for debugging
    func debugHighlight() {
        wantsLayer = true
        layer?.borderColor = NSColor.red.cgColor
        layer?.borderWidth = 2
    }
}
