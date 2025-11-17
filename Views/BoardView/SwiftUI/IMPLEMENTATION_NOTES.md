# SwiftUI Canvas Prototype - Implementation Notes

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PrototypeTestApp                         │
│                      (@main entry)                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  CanvasPrototypeView                        │
│  - Main canvas container                                    │
│  - Gesture coordination                                     │
│  - UI overlays and controls                                 │
└────────┬───────────────────────────────┬────────────────────┘
         │                               │
         ▼                               ▼
┌────────────────────┐         ┌─────────────────────┐
│  CanvasViewModel   │◄────────┤  LassoSelectionView │
│  @StateObject      │         │  (when active)      │
│  - State mgmt      │         └─────────────────────┘
│  - Business logic  │
│  - Performance     │
└────────┬───────────┘
         │
         │ ForEach(notes)
         ▼
┌─────────────────────┐
│  StickyNoteView    │
│  (x100 instances)  │
│  - Rendering       │
│  - Drag handling   │
└────────────────────┘
```

## Key Implementation Patterns

### 1. State Management

**ObservableObject Pattern**
```swift
@MainActor
class CanvasViewModel: ObservableObject {
    @Published var notes: [StickyNote] = []
    @Published var selectedNoteIds: Set<UUID> = []
    @Published var offset: CGSize = .zero
    @Published var scale: CGFloat = 1.0
}
```

**Why this works:**
- Automatic UI updates when @Published properties change
- MainActor ensures thread safety
- Type-safe state management
- No manual notification posting

**Performance impact:**
- Every @Published change triggers view update
- With 100 notes, this can cascade quickly
- Mitigation: Batch updates, minimize published properties

### 2. Coordinate Transformation

**Screen ↔ Canvas Conversion**
```swift
func screenToCanvas(_ point: CGPoint) -> CGPoint {
    return CGPoint(
        x: (point.x - offset.width) / scale,
        y: (point.y - offset.height) / scale
    )
}

func canvasToScreen(_ point: CGPoint) -> CGPoint {
    return CGPoint(
        x: point.x * scale + offset.width,
        y: point.y * scale + offset.height
    )
}
```

**Why needed:**
- SwiftUI doesn't provide built-in infinite canvas
- Gestures work in screen space
- Note positions are in canvas space
- Manual transformation is required

**Gotchas:**
- Easy to forget which space you're in
- Lasso selection needs careful handling
- Hit testing must account for transformations

### 3. Gesture Handling

**Priority and Coordination**
```swift
// Canvas gesture (background)
.gesture(
    DragGesture()
        .onChanged { /* pan or lasso */ }
)

// Note gesture (foreground)
.gesture(
    DragGesture(minimumDistance: 5)
        .onChanged { /* drag note */ }
)
```

**Challenge:**
- SwiftUI processes gestures from front to back
- Notes are in front, so their gestures fire first
- Canvas gesture only fires if note gesture doesn't claim it
- Hard to distinguish "drag note" from "click note"

**Solution applied:**
- Use `minimumDistance` to delay gesture start
- Use Option key for lasso mode
- Allow note gestures to take priority
- Canvas pan only works on empty space

**Better solution (in AppKit):**
- NSGestureRecognizer delegate methods
- Can examine gesture targets before claiming
- More control over gesture lifecycle

### 4. Performance Optimization

**Current Optimizations**
```swift
// 1. Local state for drag feedback
@State private var isDragging = false
@State private var currentDragOffset: CGSize = .zero

// 2. Position instead of offset
.position(x: note.position.x + 100, y: note.position.y + 100)
.offset(currentDragOffset) // Only for drag feedback

// 3. Conditional z-index
.zIndex(isDragging || isSelected ? 1000 : 0)

// 4. Limited animations
.animation(.spring(response: 0.2), value: isDragging)
```

**Why these help:**
- Local @State avoids parent view updates
- position() is more performant than offset() for layout
- z-index only applied when necessary
- Animations target specific values, not entire view

**Additional optimizations to consider:**
- Virtualization (only render visible notes)
- Use Canvas API instead of individual views
- Reduce @Published properties
- Implement custom Layout protocol
- Use LazyVStack/LazyVGrid patterns

### 5. Lasso Selection

**Implementation**
```swift
// Model
struct LassoSelection {
    var startPoint: CGPoint
    var currentPoint: CGPoint
    var rect: CGRect { /* calculated */ }
}

// Start
func startLasso(at point: CGPoint) {
    let canvasPoint = screenToCanvas(point)
    lassoSelection = LassoSelection(
        startPoint: canvasPoint,
        currentPoint: canvasPoint
    )
}

// Update
func updateLasso(to point: CGPoint) {
    lassoSelection?.currentPoint = screenToCanvas(point)
}

// End - Select notes
func endLasso() {
    guard let lasso = lassoSelection else { return }
    for note in notes {
        if lasso.rect.contains(note.center) {
            selectedNoteIds.insert(note.id)
        }
    }
}
```

**Key points:**
- Store lasso in canvas coordinates
- Transform to screen coordinates for rendering
- Selection happens on release
- Works at any zoom level

## SwiftUI-Specific Challenges

### Challenge 1: Gesture Ambiguity

**Problem:**
```swift
// Want to detect:
// - Tap on note → select it
// - Drag note → move it
// - Drag background → pan canvas
// - Drag with Option → lasso select

// But SwiftUI makes this hard because:
// - Can't query "what's under cursor" before gesture starts
// - Can't easily cancel one gesture if another should win
// - Priority system is rigid
```

**AppKit equivalent:**
```swift
// In AppKit, you can:
override func mouseDown(at event: NSEvent) {
    let location = convert(event.locationInWindow, from: nil)
    if let note = hitTest(location) {
        // Start note drag
    } else {
        // Start canvas pan or lasso
    }
}
```

### Challenge 2: View Update Cascade

**Problem:**
```swift
// Changing any @Published property triggers:
viewModel.offset.width += delta.width

// Which causes:
1. ViewModel notifies observers
2. CanvasPrototypeView body re-evaluates
3. ForEach re-evaluates for all notes
4. Each StickyNoteView checks if it needs update
5. SwiftUI diff algorithm runs
6. Affected views re-render

// With 100 notes, this happens 100 times per frame during pan
```

**Mitigation:**
```swift
// Use local state for transient changes
@State private var dragOffset: CGSize = .zero

// Only update viewModel on gesture end
.onEnded { value in
    viewModel.applyDrag(dragOffset)
    dragOffset = .zero
}
```

### Challenge 3: Coordinate Space Confusion

**Problem:**
```swift
// Multiple coordinate spaces:
// 1. Global screen coordinates (gesture values)
// 2. View's local coordinates
// 3. Canvas logical coordinates
// 4. Scaled/offset canvas visual coordinates

// Easy to mix them up, causing:
// - Notes appearing in wrong places
// - Selection not matching cursor
// - Zoom anchoring incorrectly
```

**Solution:**
```swift
// Explicit naming and conversion functions
let screenPoint = gesture.location
let canvasPoint = screenToCanvas(screenPoint)
let visualPoint = canvasToScreen(canvasPoint)

// Always document which space a CGPoint is in
```

### Challenge 4: Performance Debugging

**Problem:**
```swift
// SwiftUI's declarative nature makes it hard to know:
// - Which view update triggered re-render
// - How many views actually re-rendered
// - What the render tree looks like
// - Where time is being spent
```

**Tools:**
```swift
// 1. Use Instruments (Time Profiler, SwiftUI)
// 2. Add manual logging
let _ = Self._printChanges() // In body

// 3. Performance monitoring
func recordFrame() {
    frameCount += 1
    renderTime = Date().timeIntervalSince(lastFrameTime)
}
```

## What SwiftUI Does Well

### 1. Declarative UI
```swift
// Clear structure
var body: some View {
    ZStack {
        background
        content
        overlay
        controls
    }
}

// vs AppKit imperative approach
override func layout() {
    backgroundView.frame = bounds
    // ... manual positioning
}
```

### 2. Property Wrappers
```swift
@StateObject var viewModel: CanvasViewModel
@State private var isDragging = false
@Published var notes: [StickyNote]

// Automatic dependency tracking
// No manual observation setup
```

### 3. Previews
```swift
#Preview {
    StickyNoteView(note: sampleNote, ...)
        .frame(width: 400, height: 300)
}

// Live preview in Xcode
// Faster iteration than compile-run-test cycle
```

### 4. Animation
```swift
.animation(.spring(response: 0.3), value: scale)

// vs AppKit
NSAnimationContext.runAnimationGroup { context in
    context.duration = 0.3
    context.timingFunction = CAMediaTimingFunction(
        controlPoints: 0.5, 1.6, 0.5, 0.9
    )
    view.animator().frame = newFrame
}
```

## What AppKit Does Better

### 1. Gesture Control
```swift
// NSGestureRecognizer delegate
func gestureRecognizer(
    _ gestureRecognizer: NSGestureRecognizer,
    shouldRecognizeSimultaneouslyWith other: NSGestureRecognizer
) -> Bool {
    // Fine-grained control over gesture coordination
}

func gestureRecognizer(
    _ gestureRecognizer: NSGestureRecognizer,
    shouldReceive event: NSEvent
) -> Bool {
    // Can inspect event before deciding to handle it
}
```

### 2. Performance
```swift
// NSView dirty rect invalidation
override func draw(_ dirtyRect: NSRect) {
    // Only redraw what changed
}

// Layer-backed views
view.wantsLayer = true
view.layer?.shouldRasterize = true

// Manual control over rendering pipeline
```

### 3. Hit Testing
```swift
override func hitTest(_ point: NSPoint) -> NSView? {
    // Custom hit detection logic
    // Can return nil to pass through
    // Can check children in any order
}
```

### 4. Event Handling
```swift
override func mouseDown(with event: NSEvent) { }
override func mouseDragged(with event: NSEvent) { }
override func mouseUp(with event: NSEvent) { }

// Complete control over event flow
// Can handle or pass to super
// Access to all event properties
```

## Recommended Hybrid Approach

### Structure
```
SwiftUI App Structure
├── ContentView (SwiftUI)
│   ├── Toolbar (SwiftUI)
│   ├── Sidebar (SwiftUI)
│   └── CanvasContainer (SwiftUI)
│       └── CanvasViewRepresentable (Bridge)
│           └── NSCanvasView (AppKit)
│               ├── Gesture recognizers
│               ├── Custom rendering
│               └── Optimal performance
```

### Implementation
```swift
struct CanvasViewRepresentable: NSViewRepresentable {
    @ObservedObject var viewModel: CanvasViewModel

    func makeNSView(context: Context) -> NSCanvasView {
        let view = NSCanvasView()
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: NSCanvasView, context: Context) {
        nsView.notes = viewModel.notes
        nsView.selectedIds = viewModel.selectedNoteIds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, CanvasViewDelegate {
        let viewModel: CanvasViewModel

        func canvasView(_ view: NSCanvasView, didUpdateNotes notes: [StickyNote]) {
            viewModel.notes = notes
        }
    }
}
```

### Benefits
- ✅ SwiftUI for app structure and UI
- ✅ AppKit for performance-critical canvas
- ✅ Clean separation of concerns
- ✅ Best of both worlds
- ✅ Testable architecture

## Testing Recommendations

### Manual Testing
1. Test with 50, 100, 200 notes
2. Test all gesture combinations
3. Test on different hardware
4. Test with external display
5. Test with trackpad vs mouse

### Performance Testing
```swift
// Use Instruments
1. Time Profiler - find bottlenecks
2. SwiftUI - view update tracking
3. Allocations - memory usage
4. Core Animation - rendering issues

// Add manual metrics
- FPS counter
- Frame time
- Gesture latency
- Memory usage
```

### Automated Testing
```swift
// XCTest for ViewModel
func testLassoSelection() {
    let vm = CanvasViewModel()
    vm.generateTestNotes(count: 10)

    vm.startLasso(at: .zero)
    vm.updateLasso(to: CGPoint(x: 100, y: 100))
    vm.endLasso()

    XCTAssertGreaterThan(vm.selectedNoteIds.count, 0)
}

// UI Testing for interactions
func testNoteDrag() {
    let app = XCUIApplication()
    app.launch()

    let note = app.otherElements["note-0"]
    note.drag(to: CGVector(dx: 100, dy: 100))

    // Verify position changed
}
```

## Conclusion

This prototype demonstrates that SwiftUI is **viable but not optimal** for the StickyToDo canvas. The **hybrid approach** (SwiftUI + AppKit) offers the best balance of:

- Development speed
- Performance
- Gesture quality
- Cross-platform potential
- Maintainability

**Next Action:** Create AppKit prototype to validate this recommendation with side-by-side comparison.

---

**Last Updated:** 2025-11-17
**Author:** SwiftUI Canvas Prototype Team
**Status:** Complete - Ready for evaluation
