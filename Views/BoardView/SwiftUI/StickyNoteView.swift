import SwiftUI

/// Individual sticky note view component
///
/// **SwiftUI Strengths:**
/// - Declarative syntax makes it easy to define the note appearance
/// - Built-in state management with @Binding
/// - Automatic view updates when data changes
/// - Nice shadow and corner radius modifiers
///
/// **SwiftUI Challenges:**
/// - Gesture handling can be tricky when combined with parent gestures
/// - Need careful gesture priority management
/// - Performance can degrade with many simultaneous view updates
struct StickyNoteView: View {

    // MARK: - Properties

    let note: StickyNote
    let isSelected: Bool
    let scale: CGFloat
    let onTap: () -> Void
    let onDragStart: () -> Void
    let onDragChange: (CGSize) -> Void
    let onDragEnd: () -> Void

    @State private var isDragging = false
    @State private var currentDragOffset: CGSize = .zero

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content
            Text(note.content)
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.8))
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .frame(width: 200, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(note.color)
                .shadow(
                    color: isSelected ? .blue.opacity(0.5) : .black.opacity(0.2),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            // Selection border
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isSelected ? Color.blue : Color.clear,
                    lineWidth: isSelected ? 3 : 0
                )
        )
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.spring(response: 0.2), value: isDragging)
        .animation(.spring(response: 0.2), value: isSelected)
        .position(
            x: note.position.x + 100, // Center the note on its position
            y: note.position.y + 100
        )
        .offset(currentDragOffset)
        .gesture(
            // Note: This is a key challenge in SwiftUI - gesture handling
            // We need to handle note dragging while also allowing canvas panning
            // Using simultaneousGesture or highPriorityGesture affects the behavior
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        onDragStart()
                    }

                    // Store local offset for visual feedback
                    currentDragOffset = value.translation

                    // Notify parent with translation
                    onDragChange(value.translation)
                }
                .onEnded { _ in
                    isDragging = false
                    currentDragOffset = .zero
                    onDragEnd()
                }
        )
        .onTapGesture {
            onTap()
        }
        // Z-index for drag feedback
        .zIndex(isDragging || isSelected ? 1000 : 0)
    }
}

// MARK: - Preview

#Preview("Single Note") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        StickyNoteView(
            note: StickyNote(
                position: CGPoint(x: 100, y: 100),
                content: "Sample Note\n\nThis is a sticky note with some content.",
                color: .yellow
            ),
            isSelected: false,
            scale: 1.0,
            onTap: {},
            onDragStart: {},
            onDragChange: { _ in },
            onDragEnd: {}
        )
    }
}

#Preview("Selected Note") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        StickyNoteView(
            note: StickyNote(
                position: CGPoint(x: 100, y: 100),
                content: "Selected Note\n\nThis note is currently selected.",
                color: .pink
            ),
            isSelected: true,
            scale: 1.0,
            onTap: {},
            onDragStart: {},
            onDragChange: { _ in },
            onDragEnd: {}
        )
    }
}

#Preview("Multiple Colors") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        ForEach([
            (Color.yellow, CGPoint(x: 50, y: 50)),
            (Color.orange, CGPoint(x: 270, y: 50)),
            (Color.pink, CGPoint(x: 50, y: 270)),
            (Color.purple, CGPoint(x: 270, y: 270))
        ], id: \.1.x) { color, position in
            StickyNoteView(
                note: StickyNote(
                    position: position,
                    content: "Note\n\nContent",
                    color: color
                ),
                isSelected: false,
                scale: 1.0,
                onTap: {},
                onDragStart: {},
                onDragChange: { _ in },
                onDragEnd: {}
            )
        }
    }
}

// MARK: - Performance Notes
/*
 SwiftUI Performance Observations for Sticky Notes:

 ✅ WORKS WELL:
 - Rendering 50-100 notes is generally smooth
 - Automatic view diffing reduces unnecessary updates
 - Built-in animations are hardware-accelerated
 - Shadow and corner radius rendering is efficient

 ⚠️ CHALLENGES:
 - Each note is a separate view, so 100 notes = 100 view updates on any change
 - Gesture coordination between note dragging and canvas panning is complex
 - Z-index changes can trigger layout recalculations
 - Simultaneous dragging of multiple selected notes can be laggy

 💡 OPTIMIZATIONS APPLIED:
 - Using position() instead of offset() for better performance
 - Local @State for drag feedback to avoid parent updates
 - Limiting animations to specific properties
 - Using zIndex only when necessary

 🔧 POTENTIAL IMPROVEMENTS:
 - Could use GeometryReader for more control (but adds complexity)
 - Could implement custom layout for better performance
 - Could use UIViewRepresentable for AppKit-level control
 - Could batch updates during multi-note drag operations
 */
