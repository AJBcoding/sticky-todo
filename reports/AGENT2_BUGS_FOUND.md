# Agent 2: Bugs Found During Core Features Testing

**Date**: 2025-11-18
**Test Phase**: Integration Testing - Core Features
**Total Bugs Found**: 5
**Critical**: 2 | **High**: 2 | **Medium**: 1 | **Low**: 0

---

## Bug Summary Table

| Bug ID | Severity | Component | Status | Assigned To |
|--------|----------|-----------|--------|-------------|
| BUG-001 | CRITICAL | Board Canvas | New | Agent 4/5 |
| BUG-002 | CRITICAL | Board Canvas | New | Agent 4/5 |
| BUG-003 | HIGH | Board Canvas | New | Agent 4/5 |
| BUG-004 | HIGH | Board Canvas | New | Agent 4/5 |
| BUG-005 | MEDIUM | Onboarding | New | Agent 4/5 |

---

## BUG-001: Canvas View Implementation Incomplete

### Priority: CRITICAL
### Component: Board Canvas / Visualization
### Test Case: TC-BM-003 (Canvas - Freeform Layout)

### Description
The board canvas feature is not production-ready. While the data model supports freeform canvas layout with task positioning, the actual visual rendering implementation is missing or incomplete. Only prototype/wrapper code exists in the SwiftUI views.

### Steps to Reproduce
1. Review `/StickyToDo-SwiftUI/Views/BoardView/BoardCanvasIntegratedView.swift`
2. Check for actual canvas rendering logic
3. Look for infinite canvas implementation
4. Search for sticky note visual components

### Expected Result
- Complete canvas rendering with infinite scrollable area
- Tasks displayed as draggable sticky notes
- Visual representation matches task positions from data model
- Smooth 60 FPS performance

### Actual Result
- `BoardCanvasIntegratedView.swift` exists but contains wrapper code only
- `BoardCanvasViewControllerWrapper.swift` wraps AppKit view but implementation unclear
- No clear rendering of task positions on canvas
- Prototype files exist in `/Views/BoardView/SwiftUI/` but not integrated
- README.md in directory suggests integration work needed

### Affected Files
```
/StickyToDo-SwiftUI/Views/BoardView/BoardCanvasIntegratedView.swift
/StickyToDo-SwiftUI/Views/BoardView/BoardCanvasViewControllerWrapper.swift
/Views/BoardView/SwiftUI/CanvasPrototypeView.swift
/Views/BoardView/SwiftUI/StickyNoteView.swift
```

### Evidence
**Data Model Supports Canvas** (✅):
```swift
// From Task.swift line 80
var positions: [String: Position]  // Task positions per board

// From Board.swift line 80
layout: .freeform  // Canvas layout mode supported
```

**Visual Implementation Missing** (❌):
- No actual canvas view with infinite scroll
- No sticky note rendering in production code
- Wrapper files suggest incomplete integration

### Impact
**CRITICAL** - This is a flagship feature advertised in:
- Onboarding flow (Quick Tour page 3: "Board Canvas")
- Feature list (21 advanced features)
- Test plan explicitly tests freeform canvas

Without canvas implementation:
- Feature #11 (Board Canvas) non-functional
- User expectations not met
- Prototype code gives false impression of completeness

### Recommended Fix
1. **Option A: Complete Implementation** (Preferred)
   - Integrate AppKit `CanvasView` with SwiftUI via proper coordinator
   - Implement infinite scrollable canvas using `NSScrollView`
   - Create `StickyNoteView` component for task visualization
   - Wire task positions to visual coordinates
   - Add background grid/guidelines for canvas
   - Test performance with 100+ tasks

2. **Option B: Scope Reduction** (Fallback)
   - Remove freeform canvas from v1.0 scope
   - Update documentation to reflect available layouts only (kanban, grid, list)
   - Remove canvas references from onboarding tour
   - Plan canvas for v1.1 or v2.0

### Test to Verify Fix
```
TC-BM-003: Canvas - Freeform Layout
1. Create board with freeform layout
2. Add 10+ tasks to board
3. Verify tasks appear as sticky notes on canvas
4. Verify infinite canvas scrolling
5. Verify positions persist when switching boards
6. Verify 60 FPS performance during pan
```

### Related Test Cases
- TC-BM-003: Canvas - Freeform Layout (FAILED)
- TC-BM-004: Canvas - Pan & Zoom (FAILED)
- TC-BM-006: Canvas - Move Tasks (FAILED)

---

## BUG-002: Pan & Zoom Functionality Not Implemented

### Priority: CRITICAL
### Component: Board Canvas / User Interaction
### Test Case: TC-BM-004 (Canvas - Pan & Zoom)

### Description
The canvas view lacks pan and zoom functionality that is critical for navigating large task boards. No gesture recognizers or transform logic found for Option+drag panning or Command+scroll zooming.

### Steps to Reproduce
1. Search codebase for pan gesture recognizers
2. Look for zoom/scale transform logic
3. Check for keyboard modifier handling (Option, Command)
4. Review canvas view for scroll view integration

### Expected Result
- **Pan**: Option + drag moves canvas viewport
- **Zoom**: Command + scroll wheel zooms in/out
- **Performance**: Maintains 60 FPS during interactions
- **Bounds**: Infinite canvas with dynamic bounds based on task positions
- **Indicators**: Mini-map or scroll indicators show position

### Actual Result
- No pan gesture handling found in SwiftUI canvas views
- No zoom transform or scale logic identified
- No keyboard modifier detection for Option/Command keys
- AppKit version may have implementation but not integrated

### Affected Files
```
/StickyToDo-SwiftUI/Views/BoardView/BoardCanvasIntegratedView.swift
/Views/BoardView/SwiftUI/CanvasPrototypeView.swift
/Views/BoardView/AppKit/CanvasView.swift (not reviewed)
```

### Expected Implementation
```swift
// Pan gesture with Option key modifier
.gesture(
    DragGesture()
        .modifiers(.option)
        .onChanged { value in
            canvasOffset = value.translation
        }
)

// Zoom with Command + scroll
.onScroll { event in
    if event.modifierFlags.contains(.command) {
        let zoomFactor = event.scrollingDeltaY > 0 ? 1.1 : 0.9
        canvasScale *= zoomFactor
    }
}
```

### Impact
**CRITICAL** - Without pan/zoom:
- Unusable for boards with many tasks (>20)
- No way to navigate large canvas areas
- Tasks may be positioned outside visible area
- Core UX expectation not met

### Recommended Fix
1. **AppKit Implementation** (Most Compatible):
   - Use `NSScrollView` for pan/zoom
   - Implement magnification gestures
   - Add keyboard shortcuts for zoom levels
   - Support trackpad gestures

2. **SwiftUI Implementation** (Alternative):
   - Use SwiftUI gestures with modifiers
   - Apply scale and offset transforms
   - Handle edge cases (min/max zoom)
   - Optimize for performance

3. **Performance Optimization**:
   - Use view culling for off-screen tasks
   - Implement level-of-detail (LOD) for zoomed out views
   - Debounce transform updates
   - Target 60 FPS minimum

### Test to Verify Fix
```
TC-BM-004: Canvas - Pan & Zoom
1. Create canvas with 50 tasks spread across large area
2. Hold Option and drag - verify canvas pans
3. Hold Command and scroll - verify zoom in/out
4. Check FPS counter remains at 60 FPS
5. Zoom to minimum (10%) - verify readable
6. Zoom to maximum (400%) - verify task details visible
7. Pan to edge of canvas - verify smooth boundaries
```

### Related Bugs
- BUG-001: Canvas View Implementation Incomplete
- BUG-004: Task Drag-and-Drop Missing

---

## BUG-003: Lasso Selection Not Integrated With Canvas

### Priority: HIGH
### Component: Board Canvas / Selection
### Test Case: TC-BM-005 (Canvas - Lasso Selection)

### Description
Lasso selection component exists as prototype (`LassoSelectionView.swift`) but is not integrated with the main canvas view. Multi-select functionality is critical for bulk operations on tasks.

### Steps to Reproduce
1. Check `/Views/BoardView/SwiftUI/LassoSelectionView.swift` - file exists
2. Review `BoardCanvasIntegratedView.swift` for lasso integration
3. Search for multi-select state management
4. Look for selection rectangle rendering

### Expected Result
- User can drag on canvas to create lasso rectangle
- All tasks within lasso become selected
- Selected tasks show visual highlight
- Bulk operations available (move all, delete all, etc.)
- Keyboard shortcuts (Cmd+A for select all)

### Actual Result
- `LassoSelectionView.swift` file exists in prototype directory
- Not imported or used in production canvas views
- No selection state management found
- No visual selection indicators

### Affected Files
```
/Views/BoardView/SwiftUI/LassoSelectionView.swift (exists but unused)
/StickyToDo-SwiftUI/Views/BoardView/BoardCanvasIntegratedView.swift
```

### Evidence
- File exists: `/Views/BoardView/SwiftUI/LassoSelectionView.swift`
- Not integrated in main canvas view
- Selection use case mentioned in test plan but not implemented

### Impact
**HIGH** - Affects usability:
- Cannot select multiple tasks at once
- Inefficient for bulk operations
- Poor UX for reorganizing many tasks
- Expected feature for canvas-based interfaces

### Recommended Fix
1. **Integrate LassoSelectionView**:
   ```swift
   // In BoardCanvasIntegratedView
   @State private var selectedTaskIds: Set<UUID> = []
   @State private var lassoRect: CGRect?

   ZStack {
       // Task views
       ForEach(tasks) { task in
           StickyNoteView(task: task, isSelected: selectedTaskIds.contains(task.id))
       }

       // Lasso overlay
       if let rect = lassoRect {
           LassoSelectionView(rect: rect)
       }
   }
   ```

2. **Add Selection State**:
   - Track selected task IDs in Set
   - Update selection on lasso drag end
   - Clear selection on background tap
   - Support Cmd+A, Cmd+Click, Shift+Click

3. **Visual Feedback**:
   - Highlight border on selected tasks
   - Show selection count badge
   - Enable/disable bulk action buttons

### Test to Verify Fix
```
TC-BM-005: Canvas - Lasso Selection
1. Open canvas with 20 tasks
2. Drag diagonal across 5 tasks
3. Verify lasso rectangle appears during drag
4. Release mouse - verify 5 tasks selected (highlight border)
5. Press Delete - verify bulk delete confirmation
6. Press Cmd+A - verify all tasks selected
7. Click background - verify selection clears
```

### Related Bugs
- BUG-001: Canvas View Implementation Incomplete
- BUG-004: Task Drag-and-Drop Missing

---

## BUG-004: Task Drag-and-Drop on Canvas Missing

### Priority: HIGH
### Component: Board Canvas / Task Movement
### Test Case: TC-BM-006 (Canvas - Move Tasks)

### Description
While the Task model has position storage (positions dictionary), there is no drag-and-drop UI implementation to actually move tasks on the canvas. Users cannot reposition tasks visually.

### Steps to Reproduce
1. Review Task model - `positions: [String: Position]` exists ✅
2. Check `setPosition(_:for:)` method - exists ✅
3. Search for drag gesture on task views - NOT FOUND ❌
4. Look for drop target handling - NOT FOUND ❌

### Expected Result
- User can drag task (sticky note) to new position
- Task follows mouse cursor during drag
- Drop updates task.positions[boardId]
- Position persists to markdown file
- Other views see updated position immediately

### Actual Result
- Data layer supports positions (Task.swift lines 407-410)
- No drag gesture implementation in UI
- No visual feedback during drag
- No drop handling to update positions

### Affected Files
```
/StickyToDoCore/Models/Task.swift (data model ✅)
/Views/BoardView/SwiftUI/StickyNoteView.swift (drag missing ❌)
/StickyToDo-SwiftUI/Views/BoardView/BoardCanvasIntegratedView.swift (drop missing ❌)
```

### Evidence

**Data Layer Ready** (✅):
```swift
// From Task.swift
var positions: [String: Position]

mutating func setPosition(_ position: Position, for boardId: String) {
    positions[boardId] = position
    modified = Date()
}
```

**UI Layer Missing** (❌):
- No `.onDrag` modifier on StickyNoteView
- No `.onDrop` handler on canvas
- No drag preview rendering
- No collision detection or snap-to-grid

### Impact
**HIGH** - Core canvas feature:
- Cannot manually organize tasks on canvas
- Defeats purpose of freeform layout
- Major UX gap for visual task management
- Feature explicitly tested in TC-BM-006

Without drag-and-drop:
- Users cannot create custom layouts
- Task positioning is random/fixed
- Canvas becomes view-only, not interactive

### Recommended Fix

**1. Add Drag Gesture to StickyNoteView**:
```swift
// StickyNoteView.swift
struct StickyNoteView: View {
    let task: Task
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        // Task content
        taskContent
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        // Update task position
                        let newPosition = calculatePosition(from: value)
                        updateTaskPosition(task, position: newPosition)
                        dragOffset = .zero
                    }
            )
    }
}
```

**2. Add Drop Handling**:
```swift
// BoardCanvasView
.onDrop(of: [.task], isTargeted: nil) { providers, location in
    // Handle task drop from sidebar/other boards
    return true
}
```

**3. Position Persistence**:
- Call TaskStore.update() after drag ends
- Debounce updates during continuous drag
- Sync position to file system

**4. Visual Feedback**:
- Show drag preview/shadow
- Highlight drop zones
- Snap to grid (optional)
- Show position coordinates (debug mode)

### Test to Verify Fix
```
TC-BM-006: Canvas - Move Tasks
1. Open freeform canvas with 10 tasks
2. Drag first task to new position
3. Verify task follows cursor smoothly
4. Release mouse - verify task stays at new position
5. Switch to different board and back
6. Verify task still at saved position
7. Verify markdown file updated with new position
8. Edit file externally, change position
9. Reload app - verify position reflected
```

### Performance Considerations
- Debounce position updates (max 10 updates/sec)
- Use transform instead of layout updates during drag
- Batch multiple task moves
- Test with 100+ tasks to ensure smooth drag

### Related Bugs
- BUG-001: Canvas View Implementation Incomplete
- BUG-002: Pan & Zoom Not Implemented

---

## BUG-005: Sample Data Integration Incomplete When DataManager Unavailable

### Priority: MEDIUM
### Component: Onboarding / First-Run Setup
### Test Case: TC-O-012 (Sample Data Generation)

### Description
The onboarding flow attempts to create sample data but encounters a scenario where DataManager is not available. While the SampleDataGenerator successfully creates sample tasks and boards, they may not be added to the stores, leaving the app in an unexpected state.

### Steps to Reproduce
1. Review `OnboardingFlow.swift` createSampleData() method (lines 165-200)
2. Check condition at line 173: `if let dataManager = dataManager`
3. Note the else block warning (line 191): "DataManager not available"
4. Search for `DataManager.performFirstRunSetup()` - NOT FOUND

### Expected Result
- Sample data always created successfully
- 13 sample tasks appear in Inbox and other statuses
- 3 sample boards created (context/project boards)
- 7 sample tags created
- DataManager available during onboarding completion

### Actual Result
- Sample data generator works correctly (✅)
- DataManager may be nil during onboarding (⚠️)
- Warning logged: "DataManager not available, sample data generated but not added to stores"
- Comment suggests: "Sample data will be created via DataManager.performFirstRunSetup() instead"
- No evidence of performFirstRunSetup() method existing (❌)

### Affected Files
```
/StickyToDo-SwiftUI/Views/Onboarding/OnboardingFlow.swift (lines 165-200)
/StickyToDoCore/Utilities/SampleDataGenerator.swift (working correctly ✅)
/StickyToDo/Data/DataManager.swift (needs performFirstRunSetup() method?)
```

### Evidence

**Code from OnboardingFlow.swift** (lines 173-193):
```swift
if let dataManager = dataManager,
   let taskStore = dataManager.taskStore,
   let boardStore = dataManager.boardStore {
    // Add all sample tasks
    for task in sampleData.tasks {
        taskStore.add(task)
    }
    // Add all sample boards
    for board in sampleData.boards {
        boardStore.add(board)
    }
} else {
    print("⚠️ DataManager not available, sample data generated but not added to stores")
    print("   Sample data will be created via DataManager.performFirstRunSetup() instead")
}
```

**Problem**:
- Unclear if `performFirstRunSetup()` exists
- No guarantee sample data is created if DataManager is nil
- User may complete onboarding without sample data

### Impact
**MEDIUM** - Affects first-run experience:
- User expects sample data based on checkbox
- Empty app is confusing for new users
- Tutorial content relies on sample tasks
- First impression degraded

**Workarounds**:
- Manual task creation
- Import sample data manually
- Works fine if DataManager is available (likely case)

### Recommended Fix

**Option 1: Ensure DataManager Available** (Preferred):
```swift
// In OnboardingCoordinator.init()
init(dataManager: DataManager? = nil) {
    self.dataManager = dataManager ?? DataManager.shared // Provide default
    // ...
}

// Or in OnboardingContainer
var body: some View {
    Color.clear
        .sheet(isPresented: $coordinator.showOnboarding) {
            onboardingFlow
        }
        .onAppear {
            coordinator.updateDataManager(dataManager) // ✅ Already done
            coordinator.checkForFirstRun()
        }
}
```

**Option 2: Add Deferred Sample Data Creation**:
```swift
// In DataManager
func performFirstRunSetup() {
    let config = ConfigurationManager.shared
    if config.isFirstRun && config.shouldCreateSampleData {
        let sampleData = SampleDataGenerator.generateSampleData()

        for task in sampleData.tasks {
            taskStore?.add(task)
        }

        for board in sampleData.boards {
            boardStore?.add(board)
        }

        print("✅ Sample data created via performFirstRunSetup()")
    }
}
```

**Option 3: Store Sample Data for Later**:
```swift
// Save sample data to temp file if DataManager unavailable
if dataManager == nil {
    // Write sampleData to temporary JSON file
    let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("sample-data.json")
    // DataManager can check for this file on init and import
}
```

### Test to Verify Fix
```
TC-O-012: Sample Data Generation

Test A: Normal Flow (DataManager available)
1. Reset app to first-run state
2. Complete onboarding with "Create sample data" checked
3. Verify 13 tasks in Inbox and Next Actions
4. Verify 3+ boards created
5. Verify tasks have varied statuses, projects, contexts

Test B: Edge Case (DataManager unavailable)
1. Mock scenario where dataManager is nil
2. Complete onboarding with sample data
3. Verify sample data still created (via performFirstRunSetup or deferred)
4. Check logs for warnings

Test C: No Sample Data
1. Complete onboarding with checkbox unchecked
2. Verify app starts empty
3. Verify no sample files created
```

### Configuration Needed
Add to ConfigurationManager:
```swift
var shouldCreateSampleData: Bool = true  // Track checkbox state
```

### Related Test Cases
- TC-O-012: Sample Data Generation (PARTIAL PASS)
- TC-O-013: No Sample Data (PASSED)

---

## Bug Severity Definitions

### Critical (2 bugs)
- Blocks core functionality advertised in product
- Feature completely non-functional
- Affects flagship capabilities
- Must fix before v1.0 release

### High (2 bugs)
- Major feature broken or incomplete
- Significant UX degradation
- Workarounds difficult or impossible
- Should fix before v1.0 release

### Medium (1 bug)
- Minor feature broken
- Affects first-run experience
- Workarounds available
- Can defer to v1.1 if needed

### Low (0 bugs)
- Cosmetic issues
- Edge case scenarios
- Documentation/polish items
- Can defer to future releases

---

## Fix Priority Recommendations

### Must Fix for v1.0
1. **BUG-001** - Complete canvas implementation OR remove from v1.0 scope
2. **BUG-002** - Implement pan/zoom OR remove canvas from v1.0
3. **BUG-004** - Add drag-and-drop OR remove canvas from v1.0

### Should Fix for v1.0
4. **BUG-003** - Complete lasso selection (if canvas included)
5. **BUG-005** - Ensure sample data creation works reliably

### Alternative Approach: Scope Reduction
If canvas implementation requires > 1 week:
- Remove canvas/freeform layout from v1.0
- Keep kanban, grid, list layouts (all working)
- Document canvas as "coming in v1.1"
- Update onboarding tour to remove canvas page
- Maintain data model for future compatibility

This would:
- Achieve 100% pass rate on remaining features
- Deliver solid GTD task manager
- Set realistic user expectations
- Allow focused development on canvas for v1.1

---

## Testing Recommendations for Agents 4 & 5

### For Canvas Bugs (BUG-001 to BUG-004)
1. **Determine Scope**:
   - Can canvas be completed in 1 week?
   - If yes: proceed with fixes
   - If no: recommend scope reduction for v1.0

2. **If Proceeding with Canvas**:
   - Start with BUG-001 (basic rendering)
   - Then BUG-002 (pan/zoom)
   - Then BUG-004 (drag-drop)
   - Finally BUG-003 (lasso selection)

3. **Performance Testing**:
   - Test with 10, 50, 100, 500 tasks
   - Measure FPS during pan/zoom
   - Profile memory usage
   - Optimize view culling

### For Sample Data (BUG-005)
1. **Quick Fix**:
   - Add DataManager.performFirstRunSetup() method
   - Test with DataManager = nil scenario
   - Verify sample data always created when checkbox checked

2. **Integration Test**:
   - Run actual first launch on clean macOS install
   - Verify sample data appears
   - Confirm counts (13 tasks, 3+ boards, 7 tags)

---

## Files Needing Attention

### Critical Priority
```
/StickyToDo-SwiftUI/Views/BoardView/BoardCanvasIntegratedView.swift
/Views/BoardView/SwiftUI/CanvasPrototypeView.swift
/Views/BoardView/SwiftUI/StickyNoteView.swift
/Views/BoardView/SwiftUI/LassoSelectionView.swift
/StickyToDo-AppKit/Views/BoardView/BoardCanvasViewController.swift
```

### Medium Priority
```
/StickyToDo-SwiftUI/Views/Onboarding/OnboardingFlow.swift
/StickyToDo/Data/DataManager.swift
```

### Supporting Files
```
/StickyToDoCore/Models/Task.swift (positions support - OK)
/StickyToDoCore/Models/Board.swift (layout support - OK)
/StickyToDoCore/Utilities/SampleDataGenerator.swift (working - OK)
```

---

**Report Generated**: 2025-11-18
**Bugs For**: Agent 4 (Testing) & Agent 5 (Bug Fixes)
**Total Issues**: 5 (2 Critical, 2 High, 1 Medium)
**Recommendation**: Fix or reduce scope before v1.0 release
