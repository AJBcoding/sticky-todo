//
//  ErrorPresenter.swift
//  StickyToDo-AppKit
//
//  Centralized error handling and presentation for AppKit.
//  Manages error alerts using NSAlert and user-friendly messages.
//

import Cocoa

/// User-facing error types with friendly messages (AppKit version)
enum AppKitError: LocalizedError {
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

/// Centralized error presentation and handling for AppKit
class ErrorPresenter {

    // MARK: - Properties

    static let shared = ErrorPresenter()

    private var errorLog: [ErrorLogEntry] = []
    private let maxLogSize = 100

    // MARK: - Initialization

    private init() {}

    // MARK: - Error Presentation

    /// Presents an error as an NSAlert
    @MainActor
    func presentError(_ error: Error, window: NSWindow? = nil, retry: (() -> Void)? = nil) {
        let alert = createAlert(for: error, retry: retry)
        logError(error)

        if let window = window {
            alert.beginSheetModal(for: window) { response in
                if response == .alertSecondButtonReturn {
                    retry?()
                }
            }
        } else {
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                retry?()
            }
        }
    }

    /// Shows an error notification
    @MainActor
    func showNotification(for error: Error) {
        let notification = NSUserNotification()
        notification.title = "Error"
        notification.informativeText = error.localizedDescription
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
        logError(error)
    }

    /// Presents a custom alert with title and message
    @MainActor
    func presentAlert(title: String, message: String, window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")

        if let window = window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    /// Presents a confirmation dialog
    @MainActor
    func presentConfirmation(title: String,
                            message: String,
                            confirmTitle: String = "OK",
                            cancelTitle: String = "Cancel",
                            window: NSWindow? = nil,
                            completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: cancelTitle)

        if let window = window {
            alert.beginSheetModal(for: window) { response in
                completion(response == .alertFirstButtonReturn)
            }
        } else {
            let response = alert.runModal()
            completion(response == .alertFirstButtonReturn)
        }
    }

    // MARK: - Alert Creation

    private func createAlert(for error: Error, retry: (() -> Void)?) -> NSAlert {
        let alert = NSAlert()

        // Set message
        alert.messageText = errorTitle(for: error)
        alert.informativeText = errorMessage(for: error)

        // Set style
        alert.alertStyle = errorStyle(for: error)

        // Add buttons
        alert.addButton(withTitle: "OK")
        if retry != nil {
            alert.addButton(withTitle: "Retry")
        }

        // Add details if available
        if let appError = error as? AppKitError,
           let underlying = appError.underlyingError {
            alert.accessoryView = createDetailsView(for: underlying)
        }

        return alert
    }

    private func createDetailsView(for error: Error) -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 100))

        let disclosureButton = NSButton(checkboxWithTitle: "Show Details", target: nil, action: nil)
        disclosureButton.frame = NSRect(x: 0, y: 70, width: 120, height: 20)
        container.addSubview(disclosureButton)

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 65))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .bezelBorder
        scrollView.isHidden = true

        let textView = NSTextView(frame: scrollView.contentView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        textView.string = error.localizedDescription

        scrollView.documentView = textView
        container.addSubview(scrollView)

        disclosureButton.target = scrollView
        disclosureButton.action = #selector(NSView.setHidden(_:))

        return container
    }

    private func errorTitle(for error: Error) -> String {
        if let appError = error as? AppKitError {
            switch appError {
            case .conflictDetected:
                return "File Conflicts Detected"
            case .networkError:
                return "Connection Error"
            case .fileNotFound, .fileAccessDenied:
                return "File Error"
            case .invalidData:
                return "Data Error"
            case .saveFailed:
                return "Save Failed"
            case .loadFailed:
                return "Load Failed"
            case .unknown:
                return "Error"
            }
        }
        return "Error"
    }

    private func errorMessage(for error: Error) -> String {
        var message = error.localizedDescription

        if let appError = error as? AppKitError,
           let suggestion = appError.recoverySuggestion {
            message += "\n\n\(suggestion)"
        }

        return message
    }

    private func errorStyle(for error: Error) -> NSAlert.Style {
        if let appError = error as? AppKitError {
            switch appError {
            case .conflictDetected:
                return .warning
            case .networkError:
                return .informational
            default:
                return .critical
            }
        }
        return .critical
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
        if let appError = error as? AppKitError, let suggestion = appError.recoverySuggestion {
            print("   Suggestion: \(suggestion)")
        }
    }

    // MARK: - Error Recovery

    /// Attempts to recover from an error with a given action
    @MainActor
    func attemptRecovery(_ action: @escaping () async throws -> Void, window: NSWindow? = nil) {
        Task {
            do {
                try await action()
            } catch {
                presentError(error, window: window)
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

    /// Saves error log to file
    @MainActor
    func saveErrorLog(to url: URL) throws {
        let logContent = exportErrorLog()
        try logContent.write(to: url, atomically: true, encoding: .utf8)
    }
}

// MARK: - Supporting Types

/// Error log entry
struct ErrorLogEntry {
    let timestamp: Date
    let error: Error
    let context: String?
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

// MARK: - NSViewController Extension

extension NSViewController {
    /// Convenience method to present errors
    func presentError(_ error: Error, retry: (() -> Void)? = nil) {
        ErrorPresenter.shared.presentError(error, window: view.window, retry: retry)
    }

    /// Convenience method to show alerts
    func showAlert(title: String, message: String) {
        ErrorPresenter.shared.presentAlert(title: title, message: message, window: view.window)
    }

    /// Convenience method to show confirmations
    func showConfirmation(title: String,
                         message: String,
                         confirmTitle: String = "OK",
                         cancelTitle: String = "Cancel",
                         completion: @escaping (Bool) -> Void) {
        ErrorPresenter.shared.presentConfirmation(
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            cancelTitle: cancelTitle,
            window: view.window,
            completion: completion
        )
    }
}

// MARK: - NSWindowController Extension

extension NSWindowController {
    /// Convenience method to present errors
    func presentError(_ error: Error, retry: (() -> Void)? = nil) {
        ErrorPresenter.shared.presentError(error, window: window, retry: retry)
    }

    /// Convenience method to show alerts
    func showAlert(title: String, message: String) {
        ErrorPresenter.shared.presentAlert(title: title, message: message, window: window)
    }

    /// Convenience method to show confirmations
    func showConfirmation(title: String,
                         message: String,
                         confirmTitle: String = "OK",
                         cancelTitle: String = "Cancel",
                         completion: @escaping (Bool) -> Void) {
        ErrorPresenter.shared.presentConfirmation(
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            cancelTitle: cancelTitle,
            window: window,
            completion: completion
        )
    }
}
