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
                .foregroundColor(errorColor)
                .symbolRenderingMode(.hierarchical)
                .accessibilityLabel("Error icon")
                .accessibilityHidden(true)

            // Error message
            VStack(spacing: 8) {
                Text(errorTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)

                if let description = errorDescription {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
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
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
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
                    .accessibilityLabel("Retry operation")
                    .accessibilityHint("Double-tap to retry the failed operation")
                }

                if let onDismiss = onDismiss {
                    Button("Dismiss", action: onDismiss)
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Dismiss error")
                        .accessibilityHint("Double-tap to close this error message")
                }
            }
        }
        .padding(40)
        .frame(maxWidth: 500)
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
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
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
            .accessibilityHint("Double-tap to dismiss this error message")
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Empty state view for when there's no content
struct EmptyStateView: View {

    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

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
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title). \(message)")

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Double-tap to \(actionTitle.lowercased())")
            }
        }
        .padding(40)
        .frame(maxWidth: 400)
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
