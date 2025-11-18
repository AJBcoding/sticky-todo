//
//  ErrorPresenter.swift
//  StickyToDo-SwiftUI
//
//  Centralized error handling and presentation for SwiftUI.
//  Manages error alerts, logging, and user-friendly messages.
//

import SwiftUI
import Combine

/// Centralized error presentation and handling
@MainActor
class ErrorPresenter: ObservableObject {

    // MARK: - Published Properties

    @Published var currentError: Error?
    @Published var showErrorAlert = false
    @Published var errorBanners: [ErrorBannerItem] = []

    // MARK: - Properties

    static let shared = ErrorPresenter()

    private var errorLog: [ErrorLogEntry] = []
    private let maxLogSize = 100

    // MARK: - Initialization

    private init() {}

    // MARK: - Error Presentation

    /// Presents an error as an alert
    func presentError(_ error: Error, retry: (() -> Void)? = nil) {
        currentError = error
        showErrorAlert = true
        logError(error)
    }

    /// Shows an error as a dismissible banner
    func showBanner(for error: Error, duration: TimeInterval = 5.0) {
        let banner = ErrorBannerItem(error: error)
        errorBanners.append(banner)
        logError(error)

        // Auto-dismiss after duration
        if duration > 0 {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                dismissBanner(banner)
            }
        }
    }

    /// Dismisses a specific banner
    func dismissBanner(_ banner: ErrorBannerItem) {
        errorBanners.removeAll { $0.id == banner.id }
    }

    /// Dismisses all banners
    func dismissAllBanners() {
        errorBanners.removeAll()
    }

    /// Presents a custom alert with title and message
    func presentAlert(title: String, message: String) {
        let error = CustomAlertError(title: title, message: message)
        presentError(error)
    }

    // MARK: - Error Logging

    /// Logs an error for debugging
    func logError(_ error: Error, context: String? = nil) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            error: error,
            context: context
        )

        errorLog.append(entry)

        // Trim log if too large
        if errorLog.count > maxLogSize {
            errorLog.removeFirst(errorLog.count - maxLogSize)
        }

        // Print to console for debugging
        print("❌ Error: \(error.localizedDescription)")
        if let context = context {
            print("   Context: \(context)")
        }
        if let appError = error as? AppError, let suggestion = appError.recoverySuggestion {
            print("   Suggestion: \(suggestion)")
        }
    }

    // MARK: - Error Recovery

    /// Attempts to recover from an error with a given action
    func attemptRecovery(_ action: @escaping () async throws -> Void) {
        Task {
            do {
                try await action()
                dismissAllBanners()
            } catch {
                presentError(error)
            }
        }
    }

    // MARK: - Error Log Access

    /// Returns the error log for debugging
    func getErrorLog() -> [ErrorLogEntry] {
        errorLog
    }

    /// Clears the error log
    func clearErrorLog() {
        errorLog.removeAll()
    }

    /// Exports error log as text
    func exportErrorLog() -> String {
        errorLog.map { entry in
            let timestamp = DateFormatter.logFormatter.string(from: entry.timestamp)
            var text = "[\(timestamp)] \(entry.error.localizedDescription)"
            if let context = entry.context {
                text += " (Context: \(context))"
            }
            return text
        }.joined(separator: "\n")
    }
}

// MARK: - Supporting Types

/// Banner item for inline error display
struct ErrorBannerItem: Identifiable {
    let id = UUID()
    let error: Error
    let timestamp = Date()
}

/// Error log entry
struct ErrorLogEntry {
    let timestamp: Date
    let error: Error
    let context: String?
}

/// Custom alert error
struct CustomAlertError: LocalizedError {
    let title: String
    let message: String

    var errorDescription: String? { title }
    var recoverySuggestion: String? { message }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

// MARK: - View Extensions

extension View {
    /// Presents errors using the shared ErrorPresenter
    func withErrorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}

struct ErrorHandlingModifier: ViewModifier {

    @StateObject private var errorPresenter = ErrorPresenter.shared

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            // Error banners
            VStack(spacing: 8) {
                ForEach(errorPresenter.errorBanners) { banner in
                    ErrorBanner(error: banner.error) {
                        errorPresenter.dismissBanner(banner)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding()
            .animation(.spring(), value: errorPresenter.errorBanners.count)
        }
        .alert("Error", isPresented: $errorPresenter.showErrorAlert, presenting: errorPresenter.currentError) { error in
            Button("OK") {
                errorPresenter.showErrorAlert = false
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

// MARK: - Environment Key

struct ErrorPresenterKey: EnvironmentKey {
    static let defaultValue = ErrorPresenter.shared
}

extension EnvironmentValues {
    var errorPresenter: ErrorPresenter {
        get { self[ErrorPresenterKey.self] }
        set { self[ErrorPresenterKey.self] = newValue }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @StateObject private var errorPresenter = ErrorPresenter.shared

        var body: some View {
            VStack(spacing: 20) {
                Button("Show Error Alert") {
                    errorPresenter.presentError(
                        AppError.saveFailed("task", NSError(domain: "test", code: 1))
                    )
                }

                Button("Show Error Banner") {
                    errorPresenter.showBanner(
                        for: AppError.conflictDetected([URL(fileURLWithPath: "/test.md")])
                    )
                }

                Button("Show Multiple Banners") {
                    errorPresenter.showBanner(for: AppError.fileNotFound("/file1.md"))
                    errorPresenter.showBanner(for: AppError.fileNotFound("/file2.md"))
                }

                Button("Clear Banners") {
                    errorPresenter.dismissAllBanners()
                }
            }
            .padding()
            .withErrorHandling()
        }
    }

    return PreviewContainer()
        .frame(width: 600, height: 400)
}
