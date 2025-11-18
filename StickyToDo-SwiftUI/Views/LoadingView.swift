//
//  LoadingView.swift
//  StickyToDo-SwiftUI
//
//  Loading state views for async operations.
//  Provides progress indicators, messages, and cancellation options.
//

import SwiftUI

/// Generic loading view with spinner and message
struct LoadingView: View {

    let message: String
    let showProgress: Bool
    let progress: Double?
    let canCancel: Bool
    let onCancel: (() -> Void)?

    init(message: String = "Loading...",
         showProgress: Bool = false,
         progress: Double? = nil,
         canCancel: Bool = false,
         onCancel: (() -> Void)? = nil) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
        self.canCancel = canCancel
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 20) {
            if showProgress, let progress = progress {
                ProgressView(value: progress) {
                    Text(message)
                }
                .frame(width: 200)
            } else {
                ProgressView()
                    .scaleEffect(1.5)

                Text(message)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            if canCancel, let onCancel = onCancel {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .frame(maxWidth: 300)
    }
}

/// Inline loading indicator for use within views
struct InlineLoadingView: View {

    let message: String?
    let size: ControlSize

    init(message: String? = nil, size: ControlSize = .regular) {
        self.message = message
        self.size = size
    }

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(size)

            if let message = message {
                Text(message)
                    .font(fontSize)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var fontSize: Font {
        switch size {
        case .mini:
            return .caption2
        case .small:
            return .caption
        case .regular:
            return .body
        case .large:
            return .title3
        @unknown default:
            return .body
        }
    }
}

/// Overlay loading view that covers the entire content
struct LoadingOverlay: View {

    let message: String
    let showProgress: Bool
    let progress: Double?

    init(message: String = "Loading...",
         showProgress: Bool = false,
         progress: Double? = nil) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                if showProgress, let progress = progress {
                    ProgressView(value: progress)
                        .frame(width: 200)
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                }

                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 20)
        }
    }
}

/// Loading state manager for async operations
@MainActor
class LoadingStateManager: ObservableObject {

    @Published var isLoading = false
    @Published var loadingMessage = ""
    @Published var progress: Double?
    @Published var canCancel = false

    private var cancellationHandler: (() -> Void)?

    func startLoading(message: String = "Loading...",
                     showProgress: Bool = false,
                     canCancel: Bool = false,
                     onCancel: (() -> Void)? = nil) {
        isLoading = true
        loadingMessage = message
        progress = showProgress ? 0.0 : nil
        self.canCancel = canCancel
        cancellationHandler = onCancel
    }

    func updateProgress(_ value: Double, message: String? = nil) {
        progress = value
        if let message = message {
            loadingMessage = message
        }
    }

    func updateMessage(_ message: String) {
        loadingMessage = message
    }

    func stopLoading() {
        isLoading = false
        loadingMessage = ""
        progress = nil
        canCancel = false
        cancellationHandler = nil
    }

    func cancel() {
        cancellationHandler?()
        stopLoading()
    }
}

// MARK: - View Extensions

extension View {
    /// Shows a loading overlay when condition is true
    func loadingOverlay(isLoading: Bool,
                       message: String = "Loading...",
                       showProgress: Bool = false,
                       progress: Double? = nil) -> some View {
        overlay {
            if isLoading {
                LoadingOverlay(
                    message: message,
                    showProgress: showProgress,
                    progress: progress
                )
            }
        }
    }

    /// Shows a loading overlay managed by LoadingStateManager
    func loadingOverlay(manager: LoadingStateManager) -> some View {
        overlay {
            if manager.isLoading {
                LoadingOverlay(
                    message: manager.loadingMessage,
                    showProgress: manager.progress != nil,
                    progress: manager.progress
                )
            }
        }
    }
}

// MARK: - Async Operation Helpers

extension LoadingStateManager {

    /// Performs an async operation with loading state
    func performWithLoading<T>(
        message: String = "Loading...",
        showProgress: Bool = false,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        startLoading(message: message, showProgress: showProgress)

        defer {
            stopLoading()
        }

        return try await operation()
    }

    /// Performs an async operation with progress updates
    func performWithProgress<T>(
        message: String = "Loading...",
        operation: @escaping ((_ updateProgress: @escaping (Double, String?) -> Void) async throws -> T)
    ) async throws -> T {
        startLoading(message: message, showProgress: true)

        defer {
            stopLoading()
        }

        return try await operation { [weak self] progress, message in
            await MainActor.run {
                self?.updateProgress(progress, message: message)
            }
        }
    }
}

// MARK: - Skeleton Loading Views

/// Skeleton loading placeholder
struct SkeletonView: View {

    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var isAnimating = false
    @State private var phase: CGFloat = 0

    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.gray.opacity(0.25), location: 0),
                        .init(color: Color.gray.opacity(0.15), location: phase - 0.2),
                        .init(color: Color.gray.opacity(0.05), location: phase),
                        .init(color: Color.gray.opacity(0.15), location: phase + 0.2),
                        .init(color: Color.gray.opacity(0.25), location: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .opacity(isAnimating ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: isAnimating)
            .accessibilityLabel("Loading")
            .accessibilityHidden(true)
            .onAppear {
                isAnimating = true
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

/// Skeleton list row
struct SkeletonListRow: View {

    let index: Int

    init(index: Int = 0) {
        self.index = index
    }

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            SkeletonView(width: 20, height: 20, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(width: 200, height: 16)
                SkeletonView(width: 120, height: 12)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .accessibilityLabel("Loading item")
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(Double(index) * 0.05)) {
                appeared = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Loading View") {
    LoadingView(message: "Loading tasks...", canCancel: true) {
        print("Cancelled")
    }
}

#Preview("Loading with Progress") {
    LoadingView(
        message: "Importing files...",
        showProgress: true,
        progress: 0.65
    )
}

#Preview("Inline Loading") {
    VStack(spacing: 20) {
        InlineLoadingView(message: "Loading...", size: .small)
        InlineLoadingView(message: "Processing...", size: .regular)
        InlineLoadingView(message: "Saving...", size: .large)
    }
    .padding()
}

#Preview("Loading Overlay") {
    Text("Content behind overlay")
        .frame(width: 400, height: 300)
        .loadingOverlay(isLoading: true, message: "Loading data...")
}

#Preview("Skeleton Views") {
    VStack(spacing: 12) {
        SkeletonListRow(index: 0)
        SkeletonListRow(index: 1)
        SkeletonListRow(index: 2)
        SkeletonListRow(index: 3)
        SkeletonListRow(index: 4)
    }
    .padding()
}
