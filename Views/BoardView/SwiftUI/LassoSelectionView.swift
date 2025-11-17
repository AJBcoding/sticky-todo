import SwiftUI

/// Lasso selection overlay view
///
/// **SwiftUI Strengths:**
/// - Easy to overlay on top of other views
/// - Built-in shape drawing with Rectangle
/// - Simple animation support
/// - Declarative styling
///
/// **SwiftUI Challenges:**
/// - Gesture detection area needs careful handling
/// - Coordinate transformation between view spaces
/// - Performance with frequent updates during drag
struct LassoSelectionView: View {

    // MARK: - Properties

    let selection: LassoSelection
    let scale: CGFloat
    let offset: CGSize

    // MARK: - Computed Properties

    /// Transform the lasso rectangle from canvas space to screen space
    private var screenRect: CGRect {
        let canvasRect = selection.rect

        return CGRect(
            x: canvasRect.origin.x * scale + offset.width,
            y: canvasRect.origin.y * scale + offset.height,
            width: canvasRect.width * scale,
            height: canvasRect.height * scale
        )
    }

    // MARK: - Body

    var body: some View {
        Rectangle()
            .strokeBorder(
                Color.blue,
                style: StrokeStyle(
                    lineWidth: 2,
                    dash: [8, 4]
                )
            )
            .background(
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
            )
            .frame(width: screenRect.width, height: screenRect.height)
            .position(
                x: screenRect.midX,
                y: screenRect.midY
            )
            .animation(.linear(duration: 0.05), value: screenRect)
            .allowsHitTesting(false) // Allow gestures to pass through
    }
}

// MARK: - Preview

#Preview("Lasso Selection") {
    ZStack {
        // Background
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        // Sample notes
        ForEach(0..<6, id: \.self) { i in
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow)
                .frame(width: 200, height: 200)
                .position(
                    x: CGFloat(i % 3) * 250 + 100,
                    y: CGFloat(i / 3) * 250 + 100
                )
        }

        // Lasso selection
        LassoSelectionView(
            selection: LassoSelection(
                startPoint: CGPoint(x: 50, y: 50),
                currentPoint: CGPoint(x: 450, y: 350)
            ),
            scale: 1.0,
            offset: .zero
        )
    }
}

#Preview("Lasso with Zoom") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        LassoSelectionView(
            selection: LassoSelection(
                startPoint: CGPoint(x: 50, y: 50),
                currentPoint: CGPoint(x: 300, y: 200)
            ),
            scale: 1.5,
            offset: CGSize(width: 50, height: 50)
        )
    }
}

// MARK: - Implementation Notes
/*
 SwiftUI Implementation Notes for Lasso Selection:

 ✅ WORKS WELL:
 - Rectangle shape drawing is performant
 - Dashed stroke style is built-in
 - Semi-transparent fill provides good visual feedback
 - Animation during drag is smooth
 - Overlay pattern is natural in SwiftUI

 ⚠️ CHALLENGES:
 - Coordinate transformation between canvas and screen space is manual
 - Need to carefully manage hit testing to allow underlying gestures
 - Frequent updates during drag can cause some lag
 - Need to account for canvas scale and offset

 💡 DESIGN DECISIONS:
 - Using position() and frame() for placement
 - allowsHitTesting(false) so lasso doesn't block note interactions
 - Minimal animation duration to stay responsive
 - Blue color with opacity for standard selection appearance

 🔧 ALTERNATIVE APPROACHES:
 - Could use Path for more complex selection shapes
 - Could use Canvas API (iOS 15+) for better performance
 - Could implement marquee zoom on double-click
 - Could add handles for resizing the selection
 */
