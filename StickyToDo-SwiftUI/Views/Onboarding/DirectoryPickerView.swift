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
                .symbolEffect(.pulse, options: .speed(0.5).repeating, value: viewModel.isValidating)
                .symbolEffect(.bounce, options: .nonRepeating, value: viewModel.validationResult?.isValid)
                .scaleEffect(viewModel.validationResult?.isValid == true ? 1.05 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.validationResult?.isValid)
                .accessibilityHidden(true)

            // Title
            Text("Choose Storage Location")
                .font(.system(size: 36, weight: .bold))
                .tracking(0.3)
                .accessibilityAddTraits(.isHeader)

            // Description
            VStack(spacing: 8) {
                Text("Where should we store your tasks?")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

                Text("All your data is stored locally as plain Markdown files. The default location works great for most users.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }

            // Directory picker
            VStack(spacing: 16) {
                // Current selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                            .font(.headline)
                        Text("Selected Location")
                            .font(.headline)
                    }
                    .accessibilityElement(children: .combine)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.selectedDirectory.path)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            if let validation = viewModel.validationResult {
                                ValidationStatusRow(validation: validation)
                            }
                        }

                        Spacer()

                        Button("Change...") {
                            viewModel.showDirectoryPicker()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Change storage location")
                        .accessibilityHint("Choose a different folder")
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                }

                // Validation details
                if let validation = viewModel.validationResult, !validation.isValid {
                    ValidationIssuesCard(issues: validation.issues)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }

                // Storage info
                if let validation = viewModel.validationResult, validation.isValid {
                    StorageInfoCard(availableSpace: validation.availableSpaceDescription)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
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

// MARK: - Supporting Views

struct ValidationStatusRow: View {
    let validation: DirectoryValidationResult

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(validation.isValid ? .green : .orange)
                .font(.caption)
                .symbolEffect(.bounce, options: .nonRepeating, value: appeared)
                .accessibilityHidden(true)

            Text(validation.message)
                .font(.caption)
                .foregroundColor(validation.isValid ? .green : .orange)
                .fontWeight(.medium)
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(validation.message)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
        .onChange(of: validation.isValid) { _, _ in
            appeared = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct ValidationIssuesCard: View {
    let issues: [String]

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                Text("Validation Issues")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            ForEach(Array(issues.enumerated()), id: \.offset) { index, issue in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(issue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -10)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.05), value: appeared)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Validation issues: \(issues.joined(separator: ", "))")
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}

struct StorageInfoCard: View {
    let availableSpace: String

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "internaldrive")
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .font(.title2)
                .symbolEffect(.bounce, options: .nonRepeating, value: appeared)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Storage Available")
                    .font(.headline)
                    .foregroundColor(.green)

                Text(availableSpace)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
                .symbolEffect(.pulse, options: .repeat(2), value: appeared)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .shadow(color: .green.opacity(0.1), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(appeared ? 1.0 : 0.95)
        .opacity(appeared ? 1 : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Storage available: \(availableSpace)")
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DirectoryPickerView()
        .frame(width: 700, height: 550)
}
