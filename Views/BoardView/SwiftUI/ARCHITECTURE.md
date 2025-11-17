# SwiftUI Canvas Prototype - Architecture Diagram

## Component Hierarchy

```
┌───────────────────────────────────────────────────────────────────────┐
│                         PrototypeTestApp                              │
│                         (@main entry point)                           │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  Window Configuration                                       │    │
│  │  - Size: 1000x700                                          │    │
│  │  - Style: Hidden title bar                                 │    │
│  │  - Commands: Keyboard shortcuts                            │    │
│  └─────────────────────────────────────────────────────────────┘    │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────┐
│                      CanvasPrototypeView                              │
│                      (Main container view)                            │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  ZStack (layered components)                                  │  │
│  │                                                               │  │
│  │  Layer 1: Background & Grid                                  │  │
│  │  ├─ Rectangle (.gray.opacity(0.05))                          │  │
│  │  └─ Canvas API for grid lines                                │  │
│  │                                                               │  │
│  │  Layer 2: Canvas Content (transformed)                       │  │
│  │  ├─ .scaleEffect(viewModel.scale)                            │  │
│  │  ├─ .offset(viewModel.offset)                                │  │
│  │  └─ ForEach(viewModel.notes) { note in                       │  │
│  │       StickyNoteView(note)                                   │  │
│  │     }                                                         │  │
│  │                                                               │  │
│  │  Layer 3: Lasso Selection (if active)                        │  │
│  │  └─ LassoSelectionView(selection)                            │  │
│  │                                                               │  │
│  │  Layer 4: UI Overlays                                        │  │
│  │  ├─ Top Toolbar                                              │  │
│  │  ├─ Stats Panel (bottom)                                     │  │
│  │  └─ Instructions (modal)                                     │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Gesture Handlers                                             │  │
│  │  ├─ DragGesture → Pan/Lasso                                   │  │
│  │  └─ MagnificationGesture → Zoom                               │  │
│  └────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────┬───────────────────────────────────────┘
                                │
                                │ @StateObject
                                ▼
┌───────────────────────────────────────────────────────────────────────┐
│                       CanvasViewModel                                 │
│                       (ObservableObject)                              │
│                                                                       │
│  @Published Properties:                                               │
│  ├─ notes: [StickyNote]                                              │
│  ├─ selectedNoteIds: Set<UUID>                                       │
│  ├─ offset: CGSize                                                   │
│  ├─ scale: CGFloat                                                   │
│  ├─ lassoSelection: LassoSelection?                                  │
│  ├─ fps: Double                                                      │
│  └─ renderTime: Double                                               │
│                                                                       │
│  Business Logic:                                                      │
│  ├─ generateTestNotes(count:)                                        │
│  ├─ pan(delta:)                                                      │
│  ├─ zoom(delta:anchor:)                                              │
│  ├─ startDraggingNote(_:)                                            │
│  ├─ dragNote(delta:)                                                 │
│  ├─ startLasso(at:)                                                  │
│  ├─ updateLasso(to:)                                                 │
│  ├─ endLasso()                                                       │
│  ├─ changeSelectedNotesColor(to:)                                    │
│  └─ deleteSelectedNotes()                                            │
│                                                                       │
│  Coordinate Transforms:                                               │
│  ├─ screenToCanvas(_:)                                               │
│  └─ canvasToScreen(_:)                                               │
└───────────────────────────────────────────────────────────────────────┘

                         │ Updates trigger view refresh
                         ▼
┌───────────────────────────────────────────────────────────────────────┐
│                       Individual Views                                │
└───────────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐  ┌──────────────────────────┐
│    StickyNoteView        │  │  LassoSelectionView      │
│                          │  │                          │
│  Properties:             │  │  Properties:             │
│  ├─ note: StickyNote     │  │  ├─ selection            │
│  ├─ isSelected: Bool     │  │  ├─ scale                │
│  ├─ scale: CGFloat       │  │  └─ offset               │
│  └─ Callbacks:           │  │                          │
│     ├─ onTap             │  │  Rendering:              │
│     ├─ onDragStart       │  │  ├─ Rectangle            │
│     ├─ onDragChange      │  │  ├─ .strokeBorder        │
│     └─ onDragEnd         │  │  └─ Dashed style         │
│                          │  │                          │
│  Rendering:              │  │  Transform:              │
│  ├─ VStack with content  │  │  └─ Canvas → Screen      │
│  ├─ Background color     │  │                          │
│  ├─ Shadow effect        │  │                          │
│  ├─ Selection border     │  │                          │
│  └─ Position transform   │  │                          │
│                          │  │                          │
│  Local State:            │  │                          │
│  ├─ @State isDragging    │  │                          │
│  └─ @State dragOffset    │  │                          │
│                          │  │                          │
│  Gestures:               │  │                          │
│  ├─ DragGesture          │  │                          │
│  └─ TapGesture           │  │                          │
└──────────────────────────┘  └──────────────────────────┘
```

## Data Flow

### 1. User Interaction Flow

```
User Action → Gesture → View Handler → ViewModel Method → State Change → View Update

Example: Dragging a Note
─────────────────────────

User drags note
    ↓
StickyNoteView.DragGesture.onChanged
    ↓
viewModel.startDraggingNote(id) [first time]
    ↓
viewModel.dragNote(delta: translation)
    ↓
viewModel.notes[index].position updated
    ↓
@Published notes triggers objectWillChange
    ↓
CanvasPrototypeView.body re-evaluated
    ↓
ForEach updates for changed note
    ↓
StickyNoteView re-renders at new position
```

### 2. Lasso Selection Flow

```
User Action (Option + Drag)
    ↓
CanvasPrototypeView.canvasGesture.onChanged
    ↓
Check: NSEvent.modifierFlags.contains(.option)
    ↓
viewModel.startLasso(at: startLocation) [first time]
    ↓
viewModel.updateLasso(to: currentLocation) [continuously]
    ↓
@Published lassoSelection updated
    ↓
LassoSelectionView appears/updates
    ↓
User releases drag
    ↓
canvasGesture.onEnded
    ↓
viewModel.endLasso()
    ↓
Loop through all notes
    ↓
Check if note.center in lasso.rect
    ↓
Add matching notes to selectedNoteIds
    ↓
Clear lassoSelection
    ↓
LassoSelectionView disappears
Notes show selection border
```

### 3. Pan/Zoom Flow

```
Pan:
User drags background → canvasGesture → viewModel.pan(delta) → offset updated
    → entire canvas content moved via .offset()

Zoom:
User pinches → MagnificationGesture → viewModel.zoom(delta) → scale updated
    → entire canvas content scaled via .scaleEffect()

Grid Update:
offset/scale change → Canvas.draw closure re-runs → grid redrawn at new spacing
```

## State Management Pattern

### ObservableObject Pattern

```swift
┌─────────────────────────────────────────────────────────────┐
│  @MainActor class CanvasViewModel: ObservableObject         │
│                                                              │
│  When @Published property changes:                          │
│  1. Property setter called                                  │
│  2. willSet fires                                           │
│  3. objectWillChange.send() called automatically            │
│  4. All observers notified                                  │
│  5. SwiftUI marks views as needing update                   │
│  6. Next render cycle: body re-evaluated                    │
│  7. View diff algorithm runs                                │
│  8. Only changed views re-render                            │
└─────────────────────────────────────────────────────────────┘

Optimization: Local @State
┌─────────────────────────────────────────────────────────────┐
│  StickyNoteView uses @State for transient data:            │
│                                                              │
│  @State private var isDragging = false                      │
│  @State private var currentDragOffset: CGSize = .zero       │
│                                                              │
│  Why? To avoid triggering parent view updates during        │
│  intermediate states (every drag delta).                    │
│                                                              │
│  Only update viewModel when gesture completes.              │
└─────────────────────────────────────────────────────────────┘
```

## Coordinate Systems

```
┌─────────────────────────────────────────────────────────────────────┐
│  System 1: Global Screen Coordinates                               │
│  ─────────────────────────────────────────────────────────────────  │
│  Origin: Top-left of screen                                        │
│  Units: Points (retina: 2x pixels)                                 │
│  Used by: Gesture location values                                  │
│  Range: (0,0) to (screenWidth, screenHeight)                       │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
                    gesture.location
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│  System 2: View-Local Screen Coordinates                           │
│  ─────────────────────────────────────────────────────────────────  │
│  Origin: Top-left of view                                          │
│  Units: Points                                                      │
│  Used by: View rendering, layout                                   │
│  Range: (0,0) to (viewWidth, viewHeight)                           │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
                    screenToCanvas() transform
                    point = (point - offset) / scale
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│  System 3: Canvas Logical Coordinates                              │
│  ─────────────────────────────────────────────────────────────────  │
│  Origin: Logical (0,0) of infinite canvas                          │
│  Units: Canvas units (independent of zoom)                         │
│  Used by: Note positions, lasso selection                          │
│  Range: Unlimited (infinite canvas)                                │
│                                                                     │
│  Example: note.position = (1500, 2300)                             │
│  Note always at this logical position regardless of zoom/pan       │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
                    canvasToScreen() transform
                    point = point * scale + offset
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│  System 4: Rendered Screen Position                                │
│  ─────────────────────────────────────────────────────────────────  │
│  Origin: Top-left of view                                          │
│  Units: Points                                                      │
│  Used by: Final rendering via .position()                          │
│                                                                     │
│  Example with scale=2.0, offset=(100, 50):                         │
│  Logical (1500, 2300) → Screen (3100, 4650)                        │
└─────────────────────────────────────────────────────────────────────┘

Key Point: Manual transformation required!
SwiftUI doesn't provide built-in infinite canvas coordinate system.
```

## Gesture Coordination

```
┌──────────────────────────────────────────────────────────────────┐
│                     Gesture Priority                             │
└──────────────────────────────────────────────────────────────────┘

Front-to-back order (SwiftUI evaluates top views first):

1. StickyNoteView Gestures (highest priority)
   ├─ TapGesture → Select/deselect note
   └─ DragGesture(minimumDistance: 5) → Drag note

2. CanvasPrototypeView Background Gestures
   ├─ DragGesture → Pan canvas OR lasso select
   └─ MagnificationGesture → Zoom

Coordination Logic:
┌──────────────────────────────────────────────────────────────────┐
│  func canvasGesture.onChanged(value) {                           │
│    if NSEvent.modifierFlags.contains(.option) {                  │
│      // Lasso mode                                               │
│      if lassoSelection == nil {                                  │
│        startLasso(at: value.startLocation)                       │
│      }                                                            │
│      updateLasso(to: value.location)                             │
│    } else {                                                       │
│      // Pan mode                                                 │
│      pan(delta: value.translation)                               │
│    }                                                              │
│  }                                                                │
└──────────────────────────────────────────────────────────────────┘

Challenge: Can't detect "drag started on empty space" before gesture begins
Solution: Use modifier keys to switch modes
Trade-off: Less intuitive than AppKit's hitTest-based approach
```

## Performance Optimization Strategy

```
┌──────────────────────────────────────────────────────────────────┐
│               View Update Minimization                           │
└──────────────────────────────────────────────────────────────────┘

1. Reduce @Published Properties
   ✓ Only publish what views actually observe
   ✗ Don't publish internal state

2. Local @State for Transient Data
   ✓ Use @State in child views for temporary UI state
   ✓ Only update parent on completion
   ✗ Don't propagate every intermediate value

3. Specific Animation Targets
   ✓ .animation(.spring(), value: specificProperty)
   ✗ .animation(.spring()) [animates all changes]

4. Conditional Modifiers
   ✓ .zIndex(isDragging ? 1000 : 0)
   ✗ Always applying expensive modifiers

5. Structural Identity
   ✓ Use stable IDs in ForEach
   ✓ Implement Equatable for diffing
   ✗ Recreating views unnecessarily

Applied in This Prototype:
├─ ViewModel: Minimal @Published properties
├─ StickyNoteView: Local @State for drag
├─ Animations: Targeted to specific values
├─ Z-index: Only when dragging/selected
└─ ForEach: Stable UUID-based IDs

Result: Acceptable performance up to 100 notes
Limitation: Still degrades beyond that due to fundamental architecture
```

## Thread Safety

```
┌──────────────────────────────────────────────────────────────────┐
│  @MainActor class CanvasViewModel: ObservableObject              │
└──────────────────────────────────────────────────────────────────┘

All ViewModel operations on main thread:
✓ UI updates are synchronous
✓ No race conditions
✓ Simple mental model

Performance trade-off:
⚠ Can't offload work to background threads easily
⚠ Heavy computation blocks UI

Future optimization:
Could move note position calculations to background:
```swift
Task.detached {
  let newPositions = await heavyCalculation()
  await MainActor.run {
    viewModel.updatePositions(newPositions)
  }
}
```
```

## Component Responsibilities

```
┌─────────────────────────────────────────────────────────────────┐
│  PrototypeTestApp                                               │
│  ─────────────────────────────────────────────────────────────  │
│  ✓ Application lifecycle                                       │
│  ✓ Window configuration                                        │
│  ✓ Menu commands                                               │
│  ✓ Keyboard shortcuts                                          │
│  ✓ Settings management                                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  CanvasPrototypeView                                            │
│  ─────────────────────────────────────────────────────────────  │
│  ✓ View layout and composition                                 │
│  ✓ Gesture recognition                                         │
│  ✓ UI controls (toolbar, stats, instructions)                  │
│  ✓ Delegate user actions to ViewModel                          │
│  ✗ Business logic (belongs in ViewModel)                       │
│  ✗ State management (belongs in ViewModel)                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  CanvasViewModel                                                │
│  ─────────────────────────────────────────────────────────────  │
│  ✓ State management (@Published properties)                    │
│  ✓ Business logic (pan, zoom, select, drag)                    │
│  ✓ Data generation (test notes)                                │
│  ✓ Coordinate transformations                                  │
│  ✓ Performance tracking                                        │
│  ✗ View rendering (belongs in Views)                           │
│  ✗ Gesture handling (belongs in Views)                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  StickyNoteView                                                 │
│  ─────────────────────────────────────────────────────────────  │
│  ✓ Note visual rendering                                       │
│  ✓ Selection state display                                     │
│  ✓ Drag gesture handling                                       │
│  ✓ Tap gesture handling                                        │
│  ✓ Local transient state (@State)                              │
│  ✗ Note data management (belongs in ViewModel)                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  LassoSelectionView                                             │
│  ─────────────────────────────────────────────────────────────  │
│  ✓ Lasso rectangle rendering                                   │
│  ✓ Coordinate transformation for display                       │
│  ✗ Selection logic (belongs in ViewModel)                      │
│  ✗ Gesture handling (belongs in CanvasPrototypeView)           │
└─────────────────────────────────────────────────────────────────┘

Clean separation: MVVM pattern
Views → observe ViewModel → update automatically
ViewModel → pure Swift → testable without UI
```

## Testing Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Testing Layers                           │
└─────────────────────────────────────────────────────────────────┘

Unit Tests (ViewModel):
├─ Test business logic in isolation
├─ No UI dependencies
├─ Fast execution
└─ Example:
    func testLassoSelection() {
      let vm = CanvasViewModel()
      vm.generateTestNotes(count: 10)
      vm.startLasso(at: .zero)
      vm.updateLasso(to: CGPoint(x: 500, y: 500))
      vm.endLasso()
      XCTAssertGreaterThan(vm.selectedNoteIds.count, 0)
    }

Integration Tests (View + ViewModel):
├─ Test view-viewmodel interaction
├─ Use ViewInspector or similar
├─ Moderate execution speed
└─ Example:
    func testNoteSelection() {
      let view = CanvasPrototypeView()
      // Test that clicking note updates selection
    }

UI Tests (Full App):
├─ Test complete user workflows
├─ Use XCUITest
├─ Slow execution
└─ Example:
    func testDragNote() {
      let app = XCUIApplication()
      app.launch()
      app.otherElements["note-0"].drag(to: ...)
    }

Performance Tests:
├─ Measure FPS with different note counts
├─ Use XCTest metrics
└─ Example:
    func testPerformance100Notes() {
      measure {
        vm.generateTestNotes(count: 100)
        // Simulate interactions
      }
    }
```

---

This architecture provides a clean, testable, and maintainable structure following SwiftUI best practices and MVVM pattern.
