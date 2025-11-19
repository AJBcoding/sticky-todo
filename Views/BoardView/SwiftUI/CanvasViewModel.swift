import SwiftUI
import Combine

// MARK: - Data Models

/// Represents a sticky note on the canvas
struct StickyNote: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var content: String
    var color: Color

    init(id: UUID = UUID(), position: CGPoint, content: String, color: Color = .yellow) {
        self.id = id
        self.position = position
        self.content = content
        self.color = color
    }
}

/// Represents the lasso selection rectangle
struct LassoSelection {
    var startPoint: CGPoint
    var currentPoint: CGPoint

    var rect: CGRect {
        let minX = min(startPoint.x, currentPoint.x)
        let minY = min(startPoint.y, currentPoint.y)
        let width = abs(currentPoint.x - startPoint.x)
        let height = abs(currentPoint.y - startPoint.y)
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
}

// MARK: - View Model

/// Main view model managing canvas state, interactions, and performance tracking
@MainActor
class CanvasViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All sticky notes on the canvas
    @Published var notes: [StickyNote] = []

    /// Currently selected note IDs
    @Published var selectedNoteIds: Set<UUID> = []

    /// Canvas offset for panning
    @Published var offset: CGSize = .zero

    /// Current zoom scale
    @Published var scale: CGFloat = 1.0

    /// Active lasso selection (if any)
    @Published var lassoSelection: LassoSelection?

    /// Current drag offset (for visual feedback only, doesn't update actual positions)
    @Published var currentDragOffset: CGSize = .zero

    /// Performance metrics
    @Published var fps: Double = 0
    @Published var renderTime: Double = 0
    @Published var noteCount: Int = 0

    // MARK: - Private Properties

    /// Track which note is currently being dragged
    private var draggedNoteId: UUID?

    /// Performance tracking
    private var lastFrameTime: Date = Date()
    private var frameCount: Int = 0
    private var fpsTimer: Timer?

    // MARK: - Constants

    let minScale: CGFloat = 0.25
    let maxScale: CGFloat = 4.0
    let noteSize = CGSize(width: 200, height: 200)

    // MARK: - Initialization

    init() {
        noteCount = notes.count
        startPerformanceTracking()
    }

    // MARK: - Note Generation

    /// Generate test notes in a grid pattern
    func generateTestNotes(count: Int) {
        notes.removeAll()
        selectedNoteIds.removeAll()

        let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue, .green]
        let gridSize = Int(ceil(sqrt(Double(count))))
        let spacing: CGFloat = 250

        for i in 0..<count {
            let row = i / gridSize
            let col = i % gridSize
            let x = CGFloat(col) * spacing
            let y = CGFloat(row) * spacing

            let note = StickyNote(
                position: CGPoint(x: x, y: y),
                content: "Note \(i + 1)\n\nLorem ipsum dolor sit amet",
                color: colors[i % colors.count]
            )
            notes.append(note)
        }

        noteCount = notes.count
        print("📝 Generated \(count) test notes")
    }

    /// Generate random scattered notes for more realistic testing
    func generateRandomNotes(count: Int) {
        notes.removeAll()
        selectedNoteIds.removeAll()

        let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue, .green]
        let range: CGFloat = 2000 // Spread notes across a 2000x2000 area

        for i in 0..<count {
            let x = CGFloat.random(in: 0...range)
            let y = CGFloat.random(in: 0...range)

            let note = StickyNote(
                position: CGPoint(x: x, y: y),
                content: "Note \(i + 1)\n\nSample content",
                color: colors[i % colors.count]
            )
            notes.append(note)
        }

        noteCount = notes.count
        print("📝 Generated \(count) random notes")
    }

    // MARK: - Canvas Transformations

    /// Pan the canvas by a given delta
    func pan(delta: CGSize) {
        offset.width += delta.width
        offset.height += delta.height
    }

    /// Zoom the canvas by a given delta
    func zoom(delta: CGFloat, anchor: CGPoint = .zero) {
        let newScale = (scale * (1 + delta)).clamped(to: minScale...maxScale)

        // Zoom towards anchor point if provided
        if anchor != .zero {
            let scaleChange = newScale / scale
            offset.width = anchor.x - (anchor.x - offset.width) * scaleChange
            offset.height = anchor.y - (anchor.y - offset.height) * scaleChange
        }

        scale = newScale
    }

    /// Reset view to origin with default scale
    func resetView() {
        withAnimation(.spring(response: 0.3)) {
            offset = .zero
            scale = 1.0
        }
    }

    // MARK: - Note Manipulation

    /// Store starting positions for drag operation
    private var dragStartPositions: [UUID: CGPoint] = [:]

    /// Start dragging a specific note
    func startDraggingNote(_ noteId: UUID) {
        draggedNoteId = noteId

        // If dragging a note that's not selected, select only that note
        if !selectedNoteIds.contains(noteId) {
            selectedNoteIds = [noteId]
        }

        // Store starting positions for all selected notes
        dragStartPositions.removeAll()
        for id in selectedNoteIds {
            if let note = notes.first(where: { $0.id == id }) {
                dragStartPositions[id] = note.position
            }
        }
    }

    /// Update drag offset (visual only, doesn't change actual positions)
    func dragNote(delta: CGSize) {
        guard draggedNoteId != nil else { return }

        // Adjust delta for current scale and store for visual feedback
        currentDragOffset = CGSize(width: delta.width / scale, height: delta.height / scale)
    }

    /// End dragging and apply final positions
    func endDraggingNote() {
        guard draggedNoteId != nil else { return }

        // Apply the drag offset to actual positions
        for id in selectedNoteIds {
            guard let startPos = dragStartPositions[id],
                  let index = notes.firstIndex(where: { $0.id == id }) else { continue }

            // Set final position = start + offset
            notes[index].position.x = startPos.x + currentDragOffset.width
            notes[index].position.y = startPos.y + currentDragOffset.height
        }

        // Clear drag state
        draggedNoteId = nil
        dragStartPositions.removeAll()
        currentDragOffset = .zero
    }

    /// Add a new note at the given position
    func addNote(at position: CGPoint) {
        let canvasPosition = screenToCanvas(position)
        let note = StickyNote(position: canvasPosition, content: "New Note")
        notes.append(note)
        noteCount = notes.count
    }

    /// Delete selected notes
    func deleteSelectedNotes() {
        notes.removeAll { selectedNoteIds.contains($0.id) }
        selectedNoteIds.removeAll()
        noteCount = notes.count
    }

    // MARK: - Selection

    /// Toggle selection of a note
    func toggleSelection(_ noteId: UUID) {
        if selectedNoteIds.contains(noteId) {
            selectedNoteIds.remove(noteId)
        } else {
            selectedNoteIds.insert(noteId)
        }
    }

    /// Clear all selections
    func clearSelection() {
        selectedNoteIds.removeAll()
    }

    /// Start lasso selection
    func startLasso(at point: CGPoint) {
        let canvasPoint = screenToCanvas(point)
        lassoSelection = LassoSelection(startPoint: canvasPoint, currentPoint: canvasPoint)
    }

    /// Update lasso selection
    func updateLasso(to point: CGPoint) {
        guard lassoSelection != nil else { return }
        let canvasPoint = screenToCanvas(point)
        lassoSelection?.currentPoint = canvasPoint
    }

    /// End lasso selection and select notes within the rectangle
    func endLasso() {
        guard let lasso = lassoSelection else { return }

        let rect = lasso.rect

        // Select all notes whose centers are within the lasso rectangle
        for note in notes {
            let noteCenter = CGPoint(
                x: note.position.x + noteSize.width / 2,
                y: note.position.y + noteSize.height / 2
            )

            if rect.contains(noteCenter) {
                selectedNoteIds.insert(note.id)
            }
        }

        lassoSelection = nil
        print("🎯 Lasso selected \(selectedNoteIds.count) notes")
    }

    /// Cancel lasso selection
    func cancelLasso() {
        lassoSelection = nil
    }

    // MARK: - Batch Operations

    /// Change color of all selected notes
    func changeSelectedNotesColor(to color: Color) {
        for id in selectedNoteIds {
            if let index = notes.firstIndex(where: { $0.id == id }) {
                notes[index].color = color
            }
        }
    }

    /// Update content of all selected notes
    func updateSelectedNotesContent(_ content: String) {
        for id in selectedNoteIds {
            if let index = notes.firstIndex(where: { $0.id == id }) {
                notes[index].content = content
            }
        }
    }

    // MARK: - Coordinate Transformations

    /// Convert screen coordinates to canvas coordinates
    func screenToCanvas(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: (point.x - offset.width) / scale,
            y: (point.y - offset.height) / scale
        )
    }

    /// Convert canvas coordinates to screen coordinates
    func canvasToScreen(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: point.x * scale + offset.width,
            y: point.y * scale + offset.height
        )
    }

    // MARK: - Performance Tracking

    private func startPerformanceTracking() {
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.fps = Double(self.frameCount)
                self.frameCount = 0
            }
        }
    }

    func recordFrame() {
        frameCount += 1
        let now = Date()
        renderTime = now.timeIntervalSince(lastFrameTime) * 1000 // Convert to ms
        lastFrameTime = now
    }

    deinit {
        fpsTimer?.invalidate()
    }
}

// MARK: - Extensions

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
