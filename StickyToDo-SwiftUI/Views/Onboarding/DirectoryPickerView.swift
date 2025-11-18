//
//  DirectoryPickerView.swift
//  StickyToDo-SwiftUI
//
//  Directory picker with validation for onboarding.
//  Validates write permissions, disk space, and creates directory structure.
//

import SwiftUI
import AppKit

/// Directory picker view with validation for data storage setup
struct DirectoryPickerView: View {

    @StateObject private var viewModel = DirectoryPickerViewModel()
    @Environment(\.dismiss) private var dismiss

    var onComplete: ((URL) -> Void)?

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)

            // Title
            Text("Choose Storage Location")
                .font(.system(size: 32, weight: .bold))

            // Description
            Text("Select where StickyToDo will store your tasks and data. We recommend using the default location.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            // Directory picker
            VStack(spacing: 16) {
                // Current selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Location")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.selectedDirectory.path)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            if let validation = viewModel.validationResult {
                                HStack(spacing: 6) {
                                    Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(validation.isValid ? .green : .orange)
                                    Text(validation.message)
                                        .font(.caption)
                                        .foregroundColor(validation.isValid ? .green : .orange)
                                }
                            }
                        }

                        Spacer()

                        Button("Change...") {
                            viewModel.showDirectoryPicker()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Validation details
                if let validation = viewModel.validationResult, !validation.isValid {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(validation.issues, id: \.self) { issue in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(.orange)
                                Text(issue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // Storage info
                if let validation = viewModel.validationResult, validation.isValid {
                    HStack {
                        Image(systemName: "internaldrive")
                            .foregroundColor(.secondary)
                        Text("Available space: \(validation.availableSpaceDescription)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 60)
            .frame(maxWidth: 600)

            Spacer()
        }
        .padding()
        .onAppear {
            viewModel.validateDirectory()
        }
    }
}

// MARK: - View Model

@MainActor
class DirectoryPickerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var selectedDirectory: URL
    @Published var validationResult: DirectoryValidationResult?
    @Published var isValidating = false

    // MARK: - Initialization

    init() {
        // Default to ~/Documents/StickyToDo
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.selectedDirectory = documentsURL.appendingPathComponent("StickyToDo")
    }

    // MARK: - Methods

    /// Shows the directory picker
    func showDirectoryPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Select where to store your StickyToDo data"
        panel.directoryURL = selectedDirectory.deletingLastPathComponent()

        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.selectedDirectory = url.appendingPathComponent("StickyToDo")
                self?.validateDirectory()
            }
        }
    }

    /// Validates the selected directory
    func validateDirectory() {
        isValidating = true

        Task {
            let result = await performValidation(for: selectedDirectory)
            await MainActor.run {
                self.validationResult = result
                self.isValidating = false
            }
        }
    }

    /// Performs directory validation checks
    private func performValidation(for url: URL) async -> DirectoryValidationResult {
        var issues: [String] = []
        let fileManager = FileManager.default

        // Check parent directory exists and is writable
        let parentURL = url.deletingLastPathComponent()
        var isDir: ObjCBool = false

        if !fileManager.fileExists(atPath: parentURL.path, isDirectory: &isDir) {
            issues.append("Parent directory does not exist")
            return DirectoryValidationResult(isValid: false, issues: issues)
        }

        if !isDir.boolValue {
            issues.append("Parent path is not a directory")
            return DirectoryValidationResult(isValid: false, issues: issues)
        }

        // Check write permissions
        if !fileManager.isWritableFile(atPath: parentURL.path) {
            issues.append("No write permission for parent directory")
        }

        // Check available disk space
        do {
            let values = try parentURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                let minimumRequired: Int64 = 100 * 1024 * 1024 // 100 MB
                if capacity < minimumRequired {
                    issues.append("Insufficient disk space (less than 100 MB available)")
                }

                // Return validation result with space info
                if issues.isEmpty {
                    return DirectoryValidationResult(
                        isValid: true,
                        issues: [],
                        availableSpace: capacity
                    )
                }
            }
        } catch {
            issues.append("Unable to check disk space: \(error.localizedDescription)")
        }

        return DirectoryValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }

    /// Creates the directory structure
    func createDirectoryStructure() throws {
        let fileManager = FileManager.default

        // Create main directory
        if !fileManager.fileExists(atPath: selectedDirectory.path) {
            try fileManager.createDirectory(at: selectedDirectory, withIntermediateDirectories: true)
        }

        // Create subdirectories
        let subdirectories = [
            "tasks",
            "tasks/active",
            "tasks/archive",
            "boards",
            "perspectives",
            "templates",
            "attachments",
            "config"
        ]

        for subdir in subdirectories {
            let subdirURL = selectedDirectory.appendingPathComponent(subdir)
            if !fileManager.fileExists(atPath: subdirURL.path) {
                try fileManager.createDirectory(at: subdirURL, withIntermediateDirectories: true)
            }
        }

        // Create .stickytodo marker file
        let markerURL = selectedDirectory.appendingPathComponent(".stickytodo")
        let markerContent = """
        # StickyToDo Data Directory
        Created: \(Date())
        Version: 1.0
        """
        try markerContent.write(to: markerURL, atomically: true, encoding: .utf8)
    }
}

// MARK: - Supporting Types

/// Result of directory validation
struct DirectoryValidationResult {
    let isValid: Bool
    let issues: [String]
    var availableSpace: Int64?

    var message: String {
        if isValid {
            return "Valid location - ready to use"
        } else {
            return "Issues detected - please review"
        }
    }

    var availableSpaceDescription: String {
        guard let space = availableSpace else {
            return "Unknown"
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: space)
    }
}

// MARK: - Preview

#Preview {
    DirectoryPickerView()
        .frame(width: 700, height: 550)
}
