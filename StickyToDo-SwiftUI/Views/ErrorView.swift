//
//  ErrorView.swift
//  StickyToDo-SwiftUI
//
//  Generic error display views for SwiftUI.
//  Shows user-friendly error messages with recovery options.
//

import SwiftUI

/// User-facing error types with friendly messages
enum AppError: LocalizedError {
    case fileNotFound(String)
    case fileAccessDenied(String)
    case invalidData(String)
    case saveFailed(String, Error)
    case loadFailed(String, Error)
    case conflictDetected([URL])
    case networkError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .fileAccessDenied(let path):
            return "Cannot access file: \(path)"
        case .invalidData(let description):
            return "Invalid data: \(description)"
        case .saveFailed(let item, _):
            return "Failed to save \(item)"
        case .loadFailed(let item, _):
            return "Failed to load \(item)"
        case .conflictDetected(let urls):
            return "\(urls.count) file conflict(s) detected"
        case .networkError:
            return "Network connection error"
        case .unknown:
            return "An unexpected error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "The file may have been moved or deleted. Please check the file location."
        case .fileAccessDenied:
            return "Check that the app has permission to access this location."
        case .invalidData:
            return "The file may be corrupted or in an unexpected format."
        case .saveFailed:
            return "Check that you have write permissions and enough disk space."
        case .loadFailed:
            return "The file may be corrupted or inaccessible. Try restarting the app."
        case .conflictDetected:
            return "Files were modified externally while you had unsaved changes."
        case .networkError:
            return "Check your internet connection and try again."
        case .unknown:
            return "Please try again. If the problem persists, restart the app."
        }
    }

    var underlyingError: Error? {
        switch self {
        case .saveFailed(_, let error), .loadFailed(_, let error), .networkError(let error), .unknown(let error):
            return error
        default:
            return nil
        }
    }
}

/// Generic error display view
struct ErrorView: View {

    let error: Error
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?

    @State private var shakeOffset: CGFloat = 0
    @State private var appeared = false

    init(error: Error, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            Image(systemName: errorIcon)
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [errorColor, errorColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: errorColor.opacity(0.3), radius: 15, x: 0, y: 8)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.bounce, options: .nonRepeating, value: appeared)
                .offset(x: shakeOffset)
                .scaleEffect(appeared ? 1.0 : 0.8)
                .accessibilityLabel("Error icon")
                .accessibilityHidden(true)

            // Error message
            VStack(spacing: 8) {
                Text(errorTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                    .accessibilityAddTraits(.isHeader)

                if let description = errorDescription {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(errorTitle). \(errorDescription ?? "")")

            // Recovery suggestion
            if let suggestion = recoverySuggestion {
                Text(suggestion)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1.0 : 0.95)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: appeared)
                    .accessibilityLabel("Recovery suggestion: \(suggestion)")
            }

            // Error details (expandable)
            if let underlying = underlyingError {
                DisclosureGroup("Technical Details") {
                    Text(underlying.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .padding()
                }
                .padding(.horizontal)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.5), value: appeared)
                .accessibilityLabel("Technical details")
                .accessibilityHint("Expand to view detailed error information")
            }

            // Actions
            HStack(spacing: 16) {
                if let onRetry = onRetry {
                    Button {
                        onRetry()
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1.0 : 0.9)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: appeared)
                    .accessibilityLabel("Retry operation")
                    .accessibilityHint("Double-tap to retry the failed operation")
                }

                if let onDismiss = onDismiss {
                    Button("Dismiss", action: onDismiss)
                        .buttonStyle(.bordered)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1.0 : 0.9)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.65), value: appeared)
                        .accessibilityLabel("Dismiss error")
                        .accessibilityHint("Double-tap to close this error message")
                }
            }
        }
        .padding(40)
        .frame(maxWidth: 500)
        .onAppear {
            // Trigger entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }

            // Shake animation for error icon
            performShakeAnimation()
        }
    }

    // MARK: - Shake Animation

    private func performShakeAnimation() {
        let shakeSequence: [CGFloat] = [0, -8, 8, -6, 6, -4, 4, -2, 2, 0]

        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    shakeOffset = offset
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var errorIcon: String {
        if error is AppError {
            switch error as! AppError {
            case .fileNotFound, .fileAccessDenied:
                return "folder.fill.badge.questionmark"
            case .invalidData:
                return "doc.badge.exclamationmark"
            case .saveFailed, .loadFailed:
                return "exclamationmark.triangle.fill"
            case .conflictDetected:
                return "arrow.triangle.2.circlepath"
            case .networkError:
                return "wifi.exclamationmark"
            case .unknown:
                return "exclamationmark.circle.fill"
            }
        }
        return "exclamationmark.triangle.fill"
    }

    private var errorColor: Color {
        if error is AppError {
            switch error as! AppError {
            case .conflictDetected:
                return .orange
            case .networkError:
                return .blue
            default:
                return .red
            }
        }
        return .red
    }

    private var errorTitle: String {
        if let appError = error as? AppError {
            switch appError {
            case .conflictDetected:
                return "File Conflicts Detected"
            case .networkError:
                return "Connection Error"
            default:
                return "Something Went Wrong"
            }
        }
        return "Error"
    }

    private var errorDescription: String? {
        error.localizedDescription
    }

    private var recoverySuggestion: String? {
        (error as? AppError)?.recoverySuggestion
    }

    private var underlyingError: Error? {
        (error as? AppError)?.underlyingError
    }
}

/// Compact error banner for inline display
struct ErrorBanner: View {

    let error: Error
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .font(.title3)
                .symbolEffect(.bounce, options: .nonRepeating, value: appeared)
                .offset(x: shakeOffset)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Error")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Error: \(error.localizedDescription)")

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    appeared = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
            .accessibilityHint("Double-tap to dismiss this error message")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
                .shadow(color: .orange.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(appeared ? 1.0 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }

            // Subtle shake
            let shakeSequence: [CGFloat] = [0, -4, 4, -2, 2, 0]
            for (index, offset) in shakeSequence.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    withAnimation(.linear(duration: 0.05)) {
                        shakeOffset = offset
                    }
                }
            }
        }
    }
}

/// Empty state view for when there's no content
struct EmptyStateView: View {

    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var appeared = false
    @State private var iconBounce = false

    init(icon: String,
         title: String,
         message: String,
         actionTitle: String? = nil,
         action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.secondary, Color.secondary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.bounce, options: .nonRepeating, value: appeared)
                .symbolEffect(.pulse, options: .speed(0.5).repeating, value: iconBounce)
                .scaleEffect(appeared ? 1.0 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title). \(message)")

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1.0 : 0.9)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: appeared)
                .accessibilityHint("Double-tap to \(actionTitle.lowercased())")
            }
        }
        .padding(40)
        .frame(maxWidth: 450)
        .onAppear {
            appeared = true
            iconBounce = true
        }
    }
}

// MARK: - Preview

#Preview("Error View") {
    ErrorView(
        error: AppError.saveFailed("task", NSError(domain: "test", code: 1)),
        onRetry: { print("Retry") },
        onDismiss: { print("Dismiss") }
    )
}

#Preview("Error Banner") {
    ErrorBanner(
        error: AppError.conflictDetected([URL(fileURLWithPath: "/test.md")]),
        onDismiss: { print("Dismiss") }
    )
    .padding()
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "tray",
        title: "No Tasks",
        message: "You're all caught up! Create a new task to get started.",
        actionTitle: "Create Task",
        action: { print("Create") }
    )
}
