//
//  LoadingView.swift
//  StickyToDo-AppKit
//
//  Loading state views for async operations in AppKit.
//  Provides progress indicators, messages, and cancellation options.
//

import Cocoa

/// Generic loading view with spinner and message for AppKit
class LoadingView: NSView {

    // MARK: - Properties

    private let messageLabel: NSTextField
    private let progressIndicator: NSProgressIndicator
    private let cancelButton: NSButton?
    private var onCancel: (() -> Void)?

    // MARK: - Initialization

    init(message: String = "Loading...",
         showProgress: Bool = false,
         canCancel: Bool = false,
         onCancel: (() -> Void)? = nil) {

        // Message label
        messageLabel = NSTextField(labelWithString: message)
        messageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.alignment = .center

        // Progress indicator
        progressIndicator = NSProgressIndicator()
        if showProgress {
            progressIndicator.style = .bar
            progressIndicator.isIndeterminate = false
            progressIndicator.minValue = 0
            progressIndicator.maxValue = 1
        } else {
            progressIndicator.style = .spinning
            progressIndicator.isIndeterminate = true
            progressIndicator.controlSize = .regular
        }

        // Cancel button
        if canCancel {
            cancelButton = NSButton(title: "Cancel", target: nil, action: #selector(cancelAction))
            cancelButton?.bezelStyle = .rounded
        } else {
            cancelButton = nil
        }

        self.onCancel = onCancel

        super.init(frame: .zero)

        setupUI()
        progressIndicator.startAnimation(nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        wantsLayer = true

        // Add subviews
        addSubview(progressIndicator)
        addSubview(messageLabel)
        if let cancelButton = cancelButton {
            cancelButton.target = self
            addSubview(cancelButton)
        }

        // Layout
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        var constraints = [
            progressIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 20),

            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        ]

        if progressIndicator.style == .bar {
            constraints.append(contentsOf: [
                progressIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
                progressIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
                progressIndicator.heightAnchor.constraint(equalToConstant: 20)
            ])
        } else {
            constraints.append(contentsOf: [
                progressIndicator.widthAnchor.constraint(equalToConstant: 32),
                progressIndicator.heightAnchor.constraint(equalToConstant: 32)
            ])
        }

        if let cancelButton = cancelButton {
            cancelButton.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(contentsOf: [
                cancelButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                cancelButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
                cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
            ])
        } else {
            constraints.append(
                messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
            )
        }

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions

    @objc private func cancelAction() {
        onCancel?()
    }

    // MARK: - Public Methods

    func updateProgress(_ value: Double) {
        progressIndicator.doubleValue = value
    }

    func updateMessage(_ message: String) {
        messageLabel.stringValue = message
    }

    // MARK: - Cleanup

    deinit {
        progressIndicator.stopAnimation(nil)
    }
}

/// Inline loading indicator for use within views
class InlineLoadingView: NSView {

    private let progressIndicator: NSProgressIndicator
    private let messageLabel: NSTextField?

    init(message: String? = nil, size: NSControl.ControlSize = .regular) {
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .spinning
        progressIndicator.isIndeterminate = true
        progressIndicator.controlSize = size

        if let message = message {
            messageLabel = NSTextField(labelWithString: message)
            messageLabel?.font = Self.fontSize(for: size)
            messageLabel?.textColor = .secondaryLabelColor
        } else {
            messageLabel = nil
        }

        super.init(frame: .zero)
        setupUI()
        progressIndicator.startAnimation(nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(progressIndicator)
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false

        var constraints = [
            progressIndicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        if let messageLabel = messageLabel {
            addSubview(messageLabel)
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(contentsOf: [
                messageLabel.leadingAnchor.constraint(equalTo: progressIndicator.trailingAnchor, constant: 8),
                messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        } else {
            constraints.append(
                progressIndicator.trailingAnchor.constraint(equalTo: trailingAnchor)
            )
        }

        NSLayoutConstraint.activate(constraints)
    }

    private static func fontSize(for size: NSControl.ControlSize) -> NSFont {
        switch size {
        case .mini:
            return .systemFont(ofSize: 9)
        case .small:
            return .systemFont(ofSize: 11)
        case .regular:
            return .systemFont(ofSize: 13)
        case .large:
            return .systemFont(ofSize: 16)
        @unknown default:
            return .systemFont(ofSize: 13)
        }
    }

    deinit {
        progressIndicator.stopAnimation(nil)
    }
}

/// Loading overlay that covers content
class LoadingOverlayView: NSView {

    private let containerView: NSView
    private let progressIndicator: NSProgressIndicator
    private let messageLabel: NSTextField

    init(message: String = "Loading...", showProgress: Bool = false) {
        // Container for centered content
        containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        containerView.layer?.cornerRadius = 12
        containerView.shadow = NSShadow()
        containerView.shadow?.shadowBlurRadius = 20
        containerView.shadow?.shadowOffset = NSSize(width: 0, height: -5)
        containerView.shadow?.shadowColor = NSColor.black.withAlphaComponent(0.3)

        // Progress indicator
        progressIndicator = NSProgressIndicator()
        if showProgress {
            progressIndicator.style = .bar
            progressIndicator.isIndeterminate = false
            progressIndicator.minValue = 0
            progressIndicator.maxValue = 1
        } else {
            progressIndicator.style = .spinning
            progressIndicator.isIndeterminate = true
            progressIndicator.controlSize = .regular
        }

        // Message
        messageLabel = NSTextField(labelWithString: message)
        messageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        messageLabel.alignment = .center

        super.init(frame: .zero)

        setupUI()
        progressIndicator.startAnimation(nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor

        addSubview(containerView)
        containerView.addSubview(progressIndicator)
        containerView.addSubview(messageLabel)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        var constraints = [
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 250),

            progressIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            progressIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 32),

            messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -32),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -32)
        ]

        if progressIndicator.style == .bar {
            constraints.append(contentsOf: [
                progressIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
                progressIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
                progressIndicator.heightAnchor.constraint(equalToConstant: 20)
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }

    func updateProgress(_ value: Double) {
        progressIndicator.doubleValue = value
    }

    func updateMessage(_ message: String) {
        messageLabel.stringValue = message
    }

    deinit {
        progressIndicator.stopAnimation(nil)
    }
}

/// Loading state manager for async operations in AppKit
@MainActor
class LoadingStateManager {

    var isLoading = false
    var loadingMessage = ""
    var progress: Double?
    var canCancel = false

    private var cancellationHandler: (() -> Void)?
    private var overlayView: LoadingOverlayView?
    private weak var parentView: NSView?

    func startLoading(in view: NSView,
                     message: String = "Loading...",
                     showProgress: Bool = false,
                     canCancel: Bool = false,
                     onCancel: (() -> Void)? = nil) {
        isLoading = true
        loadingMessage = message
        progress = showProgress ? 0.0 : nil
        self.canCancel = canCancel
        cancellationHandler = onCancel
        parentView = view

        // Create and show overlay
        let overlay = LoadingOverlayView(message: message, showProgress: showProgress)
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.width, .height]
        view.addSubview(overlay)
        overlayView = overlay
    }

    func updateProgress(_ value: Double, message: String? = nil) {
        progress = value
        overlayView?.updateProgress(value)

        if let message = message {
            loadingMessage = message
            overlayView?.updateMessage(message)
        }
    }

    func updateMessage(_ message: String) {
        loadingMessage = message
        overlayView?.updateMessage(message)
    }

    func stopLoading() {
        isLoading = false
        loadingMessage = ""
        progress = nil
        canCancel = false
        cancellationHandler = nil

        overlayView?.removeFromSuperview()
        overlayView = nil
        parentView = nil
    }

    func cancel() {
        cancellationHandler?()
        stopLoading()
    }
}

// MARK: - NSView Extension

extension NSView {
    /// Shows a loading overlay
    func showLoadingOverlay(message: String = "Loading...", showProgress: Bool = false) -> LoadingOverlayView {
        let overlay = LoadingOverlayView(message: message, showProgress: showProgress)
        overlay.frame = bounds
        overlay.autoresizingMask = [.width, .height]
        addSubview(overlay)
        return overlay
    }

    /// Removes loading overlay
    func removeLoadingOverlay(_ overlay: LoadingOverlayView) {
        overlay.removeFromSuperview()
    }
}

// MARK: - Async Operation Helpers

extension LoadingStateManager {

    /// Performs an async operation with loading state
    func performWithLoading<T>(
        in view: NSView,
        message: String = "Loading...",
        showProgress: Bool = false,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        startLoading(in: view, message: message, showProgress: showProgress)

        defer {
            stopLoading()
        }

        return try await operation()
    }

    /// Performs an async operation with progress updates
    func performWithProgress<T>(
        in view: NSView,
        message: String = "Loading...",
        operation: @escaping ((_ updateProgress: @escaping (Double, String?) -> Void) async throws -> T)
    ) async throws -> T {
        startLoading(in: view, message: message, showProgress: true)

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
