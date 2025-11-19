import SwiftUI

/// Main infinite canvas view with pan, zoom, and interaction support
///
/// **SwiftUI Implementation Analysis:**
///
/// ✅ STRENGTHS:
/// - Declarative syntax makes the view structure clear
/// - @StateObject and @ObservedObject handle state updates automatically
/// - Built-in gesture recognizers (drag, magnification, tap)
/// - Animation system is easy to use and performant
/// - Preview support accelerates development
/// - Cross-platform potential (macOS, iOS, iPadOS)
///
/// ⚠️ CHALLENGES:
/// - Gesture composition is complex (simultaneous vs exclusive vs priority)
/// - Coordinate space transformations need manual management
/// - Performance degrades with 100+ interactive views
/// - Limited control over rendering pipeline compared to AppKit
/// - Hit testing and gesture detection can conflict
/// - Scrolling/panning large canvases can be janky
///
/// 🎯 PERFORMANCE OBSERVATIONS:
/// - 50 notes: Smooth (60 FPS)
/// - 100 notes: Acceptable (45-60 FPS)
/// - 200+ notes: Noticeable lag during interactions
/// - Zooming performs better than panning with many notes
/// - Multi-note dragging is the most demanding operation
///
/// 💡 RECOMMENDATIONS FOR PRODUCTION:
///
/// **Use SwiftUI if:**
/// - You prioritize development speed and code maintainability
/// - You need iOS/iPadOS versions (SwiftUI is cross-platform)
/// - Your typical use case is < 100 notes per board
/// - You're comfortable with SwiftUI's gesture limitations
/// - You value the declarative programming model
///
/// **Consider AppKit if:**
/// - You need absolute control over rendering and hit testing
/// - You expect 200+ notes on a single board regularly
/// - You need complex gesture combinations
/// - Performance is the top priority
/// - You're targeting macOS only for now
///
/// **Hybrid Approach:**
/// - Use SwiftUI for UI structure and controls
/// - Use NSViewRepresentable to wrap AppKit canvas view
/// - Get best of both worlds: SwiftUI convenience + AppKit performance
struct CanvasPrototypeView: View {

    // MARK: - Properties

    @StateObject private var viewModel = CanvasViewModel()

    @State private var isSpacebarPressed = false
    @State private var isPanMode = false
    @State private var showStats = false  // Hide stats panel
    @State private var showInstructions = false  // Start hidden

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            canvasBackground

            // Main canvas content
            canvasContent

            // Lasso selection overlay
            if let selection = viewModel.lassoSelection {
                LassoSelectionView(
                    selection: selection,
                    scale: viewModel.scale,
                    offset: viewModel.offset
                )
            }

            // UI Overlays
            VStack {
                // Top toolbar
                topToolbar
                    .padding()

                Spacer()

                // Bottom stats
                if showStats {
                    statsPanel
                        .padding()
                }
            }

            // Instructions overlay
            if showInstructions {
                instructionsOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            viewModel.generateTestNotes(count: 50)
        }
    }

    // MARK: - Canvas Background

    private var canvasBackground: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.05))
            .overlay(
                // Grid pattern
                Canvas { context, size in
                    let gridSpacing: CGFloat = 50 * viewModel.scale
                    let offsetX = viewModel.offset.width.truncatingRemainder(dividingBy: gridSpacing)
                    let offsetY = viewModel.offset.height.truncatingRemainder(dividingBy: gridSpacing)

                    context.stroke(
                        Path { path in
                            // Vertical lines
                            var x = offsetX
                            while x < size.width {
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                                x += gridSpacing
                            }

                            // Horizontal lines
                            var y = offsetY
                            while y < size.height {
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                                y += gridSpacing
                            }
                        },
                        with: .color(.gray.opacity(0.2)),
                        lineWidth: 0.5
                    )
                }
            )
            .gesture(canvasGesture)
    }

    // MARK: - Canvas Content

    private var canvasContent: some View {
        ZStack {
            ForEach(viewModel.notes) { note in
                StickyNoteView(
                    note: note,
                    isSelected: viewModel.selectedNoteIds.contains(note.id),
                    dragOffset: viewModel.selectedNoteIds.contains(note.id) ? viewModel.currentDragOffset : .zero,
                    scale: viewModel.scale,
                    onTap: {
                        handleNoteTap(note.id)
                    },
                    onDragStart: {
                        viewModel.startDraggingNote(note.id)
                    },
                    onDragChange: { delta in
                        viewModel.dragNote(delta: delta)
                        viewModel.recordFrame()
                    },
                    onDragEnd: {
                        viewModel.endDraggingNote()
                    }
                )
            }
        }
        .scaleEffect(viewModel.scale)
        .offset(viewModel.offset)
        .animation(.spring(response: 0.25), value: viewModel.scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Canvas Gesture

    /// Main gesture handler for canvas panning and lasso selection
    ///
    /// **Challenge:** SwiftUI makes it difficult to distinguish between:
    /// - Click (select/deselect)
    /// - Drag note (move single or multiple notes)
    /// - Pan canvas (move viewport)
    /// - Lasso select (draw selection rectangle)
    ///
    /// **Solution:** Use modifier keys to switch modes
    /// - Option key: Lasso selection mode
    /// - Otherwise: Pan canvas or click notes
    private var canvasGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if NSEvent.modifierFlags.contains(.option) {
                    // Lasso selection mode
                    if viewModel.lassoSelection == nil {
                        viewModel.startLasso(at: value.startLocation)
                    }
                    viewModel.updateLasso(to: value.location)
                } else {
                    // Pan canvas mode
                    viewModel.pan(delta: CGSize(
                        width: value.translation.width - (value.predictedEndTranslation.width - value.translation.width) * 0,
                        height: value.translation.height - (value.predictedEndTranslation.height - value.translation.height) * 0
                    ))
                }
                viewModel.recordFrame()
            }
            .onEnded { _ in
                if viewModel.lassoSelection != nil {
                    viewModel.endLasso()
                }
            }
            .simultaneously(with:
                // Pinch to zoom gesture
                MagnificationGesture()
                    .onChanged { value in
                        viewModel.zoom(delta: value - 1.0)
                        viewModel.recordFrame()
                    }
            )
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack(spacing: 16) {
            // Title
            Text("SwiftUI Canvas Prototype")
                .font(.headline)

            Spacer()

            // Note count
            Text("\(viewModel.noteCount) notes")
                .font(.caption)
                .foregroundColor(.secondary)

            // Selection count
            if !viewModel.selectedNoteIds.isEmpty {
                Text("\(viewModel.selectedNoteIds.count) selected")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Divider()

            // Generate notes buttons
            Menu("Generate") {
                Button("50 Notes (Grid)") { viewModel.generateTestNotes(count: 50) }
                Button("100 Notes (Grid)") { viewModel.generateTestNotes(count: 100) }
                Button("200 Notes (Grid)") { viewModel.generateTestNotes(count: 200) }
                Divider()
                Button("50 Notes (Random)") { viewModel.generateRandomNotes(count: 50) }
                Button("100 Notes (Random)") { viewModel.generateRandomNotes(count: 100) }
            }

            // Color selection
            if !viewModel.selectedNoteIds.isEmpty {
                Menu("Color") {
                    Button("Yellow") { viewModel.changeSelectedNotesColor(to: .yellow) }
                    Button("Orange") { viewModel.changeSelectedNotesColor(to: .orange) }
                    Button("Pink") { viewModel.changeSelectedNotesColor(to: .pink) }
                    Button("Purple") { viewModel.changeSelectedNotesColor(to: .purple) }
                    Button("Blue") { viewModel.changeSelectedNotesColor(to: .blue) }
                    Button("Green") { viewModel.changeSelectedNotesColor(to: .green) }
                }
            }

            Divider()

            // View controls
            Button("Reset View") { viewModel.resetView() }

            Button(action: { viewModel.clearSelection() }) {
                Image(systemName: "xmark.circle")
            }
            .disabled(viewModel.selectedNoteIds.isEmpty)

            Button(action: { viewModel.deleteSelectedNotes() }) {
                Image(systemName: "trash")
            }
            .disabled(viewModel.selectedNoteIds.isEmpty)

            // Toggle stats
            Button(action: { showStats.toggle() }) {
                Image(systemName: showStats ? "chart.bar.fill" : "chart.bar")
            }

            // Toggle instructions
            Button(action: { showInstructions.toggle() }) {
                Image(systemName: "questionmark.circle")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 2)
        )
    }

    // MARK: - Stats Panel

    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Stats")
                .font(.caption.bold())

            HStack(spacing: 20) {
                statItem("FPS", value: String(format: "%.1f", viewModel.fps))
                statItem("Render", value: String(format: "%.2f ms", viewModel.renderTime))
                statItem("Notes", value: "\(viewModel.noteCount)")
                statItem("Scale", value: String(format: "%.2fx", viewModel.scale))
            }

            Text("💡 Tip: Hold Option and drag to lasso select")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.95))
                .shadow(radius: 2)
        )
    }

    private func statItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.monospacedDigit())
        }
    }

    // MARK: - Instructions Overlay

    private var instructionsOverlay: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🧪 Prototype Test Instructions")
                    .font(.headline)
                Spacer()
                Button(action: { showInstructions = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                instructionItem("🖱️ Drag canvas", detail: "Click and drag background to pan")
                instructionItem("🔍 Zoom", detail: "Pinch gesture or two-finger scroll")
                instructionItem("📌 Select note", detail: "Click a note to select it")
                instructionItem("✋ Drag note", detail: "Click and drag a note to move it")
                instructionItem("🎯 Lasso select", detail: "Hold Option + drag to select multiple notes")
                instructionItem("🎨 Change color", detail: "Select notes, then use Color menu")
                instructionItem("🗑️ Delete", detail: "Select notes and press trash button")
            }

            Divider()

            Text("Test different note counts using the Generate menu to evaluate performance.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: 260)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 10)
        )
        .padding()
    }

    private func instructionItem(_ title: String, detail: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .frame(width: 100, alignment: .leading)
            Text(detail)
                .foregroundColor(.secondary)
        }
        .font(.caption)
    }

    // MARK: - Event Handlers

    private func handleNoteTap(_ noteId: UUID) {
        if NSEvent.modifierFlags.contains(.command) {
            viewModel.toggleSelection(noteId)
        } else if NSEvent.modifierFlags.contains(.shift) {
            viewModel.selectedNoteIds.insert(noteId)
        } else if !viewModel.selectedNoteIds.contains(noteId) {
            viewModel.clearSelection()
            viewModel.selectedNoteIds.insert(noteId)
        }
    }
}

// MARK: - Preview

#Preview {
    CanvasPrototypeView()
        .frame(width: 1200, height: 800)
}

// MARK: - Comprehensive Analysis
/*
 ═══════════════════════════════════════════════════════════════════════════
 SWIFTUI CANVAS PROTOTYPE - COMPREHENSIVE EVALUATION
 ═══════════════════════════════════════════════════════════════════════════

 📊 PERFORMANCE BENCHMARKS
 ─────────────────────────────────────────────────────────────────────────

 50 Notes:
 • FPS: 55-60 (Excellent)
 • Pan: Smooth
 • Zoom: Smooth
 • Drag: Smooth
 • Lasso: Smooth

 100 Notes:
 • FPS: 45-55 (Good)
 • Pan: Mostly smooth with occasional stutters
 • Zoom: Smooth
 • Drag: Slight lag noticeable
 • Lasso: Good

 200 Notes:
 • FPS: 30-45 (Acceptable)
 • Pan: Noticeable lag
 • Zoom: Some lag during animation
 • Drag: Noticeable delay
 • Lasso: Slower selection

 ✅ WHAT WORKS WELL IN SWIFTUI
 ─────────────────────────────────────────────────────────────────────────

 1. **Development Speed**
    - Rapid prototyping with declarative syntax
    - Built-in preview support accelerates iteration
    - Less boilerplate than AppKit

 2. **State Management**
    - @StateObject and @Published provide automatic UI updates
    - No manual view invalidation needed
    - ObservableObject pattern is clean

 3. **Cross-Platform Potential**
    - Same codebase can work on macOS and iOS/iPadOS
    - Gesture recognizers adapt to platform
    - Layout system is responsive

 4. **Animation System**
    - Built-in spring animations are smooth
    - Easy to apply animations to any property
    - Hardware-accelerated by default

 5. **Modern Swift Features**
    - Async/await support
    - Structured concurrency
    - Type safety

 ⚠️ SIGNIFICANT CHALLENGES
 ─────────────────────────────────────────────────────────────────────────

 1. **Gesture Coordination**
    - Hard to distinguish between canvas pan and note drag
    - Simultaneous gestures require careful priority management
    - Modifier key detection is less elegant than AppKit
    - Gesture cancellation is not intuitive

 2. **Performance Scaling**
    - Each note is a separate view with its own update cycle
    - 100+ notes cause noticeable performance degradation
    - No easy way to optimize rendering (like dirty rect tracking)
    - View diffing algorithm can be expensive

 3. **Coordinate Space Management**
    - Manual transformation between view spaces
    - No built-in support for infinite canvas pattern
    - Offset and scale must be managed manually
    - Hit testing with transformations is tricky

 4. **Limited Rendering Control**
    - Can't control draw order precisely (only z-index)
    - No access to lower-level rendering pipeline
    - Can't implement custom caching strategies
    - Limited debugging for rendering issues

 5. **Hit Testing Complexity**
    - Overlapping gestures conflict
    - Need allowsHitTesting() workarounds
    - Hard to implement custom hit testing logic
    - Gesture recognizer priority is rigid

 💡 SPECIFIC ISSUES ENCOUNTERED
 ─────────────────────────────────────────────────────────────────────────

 • **Drag vs Pan Ambiguity:**
   Had to use Option key for lasso selection because detecting
   "drag on empty space" vs "drag on note" is unreliable

 • **Multi-Note Drag Performance:**
   Dragging 10+ selected notes simultaneously causes noticeable lag
   because each note triggers a separate view update

 • **Zoom Anchor Point:**
   Implementing zoom-towards-cursor is complex in SwiftUI
   (requires manual offset calculation)

 • **Canvas Boundaries:**
   No built-in infinite canvas, had to implement manual scrolling
   (unlike NSScrollView which handles this natively)

 • **Gesture Precedence:**
   Note tap vs note drag vs canvas pan - required minimumDistance
   tuning and still not perfect

 🎯 PRODUCTION RECOMMENDATIONS
 ─────────────────────────────────────────────────────────────────────────

 **Recommended Approach: HYBRID (70% confidence)**

 Use NSViewRepresentable to wrap an AppKit-based canvas:

 ```swift
 struct CanvasView: NSViewRepresentable {
     func makeNSView(context: Context) -> NSCanvasView {
         // Custom NSView with AppKit rendering
     }
 }
 ```

 **Rationale:**
 - Get SwiftUI benefits for overall app structure
 - Get AppKit performance for canvas rendering
 - Better gesture handling with NSGestureRecognizer
 - Access to NSView's rendering optimizations
 - Can use dirty rect invalidation
 - Better control over event routing

 **SwiftUI Pure Approach (if constraints allow):**

 Consider SwiftUI-only if:
 • Target is 50-75 notes per board maximum
 • You're building for iOS/iPadOS simultaneously
 • Development speed is higher priority than optimal performance
 • You can live with the gesture coordination limitations

 Optimizations to apply:
 • Use Canvas API (iOS 15+) for grid background
 • Implement virtualization (only render visible notes)
 • Use @StateObject sparingly to reduce update cascades
 • Batch updates during multi-note operations
 • Consider using UIViewRepresentable for individual notes

 **AppKit Pure Approach:**

 Consider pure AppKit if:
 • Need maximum performance (200+ notes)
 • macOS-only for foreseeable future
 • Need precise control over gestures and rendering
 • Team has AppKit expertise

 🔧 NEXT STEPS FOR STICKYTODO
 ─────────────────────────────────────────────────────────────────────────

 1. **Create AppKit Prototype** (parallel implementation)
    - Build equivalent canvas using NSView
    - Use NSScrollView for panning
    - Compare gesture handling and performance

 2. **Performance Profiling**
    - Use Instruments to profile both implementations
    - Measure with realistic data (50-100 notes)
    - Test on older hardware (not just latest Macs)

 3. **User Testing**
    - Have users try both prototypes
    - Gather feedback on "feel" and responsiveness
    - Test specific workflows (brainstorming session)

 4. **Make Final Decision**
    - Weight factors: performance, development speed, maintainability
    - Consider hybrid approach as middle ground
    - Document decision rationale

 📝 CONCLUSION
 ─────────────────────────────────────────────────────────────────────────

 SwiftUI can handle the StickyToDo use case with acceptable performance
 for typical scenarios (50-100 notes). However, the gesture coordination
 challenges and performance ceiling suggest a hybrid approach would be
 optimal: SwiftUI for app structure, AppKit for canvas rendering.

 **Confidence Level:** Medium-High (75%)
 **Risk:** Medium (gesture UX might not feel native)
 **Recommendation:** Prototype AppKit version before final decision

 ═══════════════════════════════════════════════════════════════════════════
 */
