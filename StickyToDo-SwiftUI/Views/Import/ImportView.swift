//
//  ImportView.swift
//  StickyToDo-SwiftUI
//
//  Comprehensive import interface with format detection and preview.
//

import SwiftUI
import StickyToDoCore
import UniformTypeIdentifiers

/// Import view with format detection, preview, and configuration
struct ImportView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    let onImport: ([Task]) -> Void

    // MARK: - State

    @State private var selectedFileURL: URL?
    @State private var detectedFormat: ImportFormat?
    @State private var selectedFormat: ImportFormat = .json
    @State private var autoDetect: Bool = true

    // Import options
    @State private var defaultProject: String = ""
    @State private var defaultContext: String = ""
    @State private var defaultStatus: Status = .inbox
    @State private var preserveIds: Bool = false
    @State private var createProjects: Bool = true
    @State private var createContexts: Bool = true
    @State private var skipErrors: Bool = true

    // CSV column mapping
    @State private var showColumnMapping: Bool = false
    @State private var csvHeaders: [String] = []
    @State private var columnMapping: [String: String] = [:]

    // Import state
    @State private var isImporting: Bool = false
    @State private var importProgress: Double = 0.0
    @State private var importMessage: String = ""
    @State private var importPreview: ImportPreview?
    @State private var importResult: ImportResult?
    @State private var importError: Error?
    @State private var showingResult: Bool = false
    @State private var showingFilePicker: Bool = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                header

                // File selection
                fileSelectionSection

                // Format selection (if not auto-detected or user wants to override)
                if selectedFileURL != nil {
                    formatSection
                }

                // Import options
                if selectedFileURL != nil {
                    optionsSection
                }

                // Column mapping (for CSV/TSV)
                if showColumnMapping {
                    columnMappingSection
                }

                // Preview
                if let preview = importPreview {
                    previewSection(preview: preview)
                }

                // Import button
                if selectedFileURL != nil {
                    importButton
                }
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 600)
        .navigationTitle("Import Data")
        .sheet(isPresented: $showingResult) {
            if let result = importResult {
                importResultSheet(result: result)
            }
        }
        .overlay {
            if isImporting {
                importingOverlay
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json, .plainText, .commaSeparatedText, .tabSeparatedText, .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result: result)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Import Data")
                .font(.largeTitle)
                .bold()

            Text("Select a file to import tasks into StickyToDo")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - File Selection Section

    private var fileSelectionSection: some View {
        GroupBox("Select File") {
            VStack(alignment: .leading, spacing: 16) {
                if let fileURL = selectedFileURL {
                    HStack {
                        Image(systemName: "doc.fill")
                            .font(.title2)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(fileURL.lastPathComponent)
                                .font(.headline)

                            Text(fileURL.deletingLastPathComponent().path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button("Change") {
                            showingFilePicker = true
                        }
                    }

                    if let format = detectedFormat {
                        Label("Detected format: \(format.displayName)", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No file selected")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Button("Choose File...") {
                            showingFilePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding()
        }
    }

    // MARK: - Format Section

    private var formatSection: some View {
        GroupBox("Import Format") {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Auto-detect format", isOn: $autoDetect)
                    .onChange(of: autoDetect) { _ in
                        if autoDetect, let url = selectedFileURL {
                            detectFormat(from: url)
                        }
                    }

                if !autoDetect {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ImportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedFormat) { _ in
                        updatePreview()
                    }
                }

                // Format description
                let displayFormat = autoDetect ? (detectedFormat ?? selectedFormat) : selectedFormat
                Text(displayFormat.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        GroupBox("Import Options") {
            VStack(alignment: .leading, spacing: 16) {
                // Default project
                HStack {
                    Text("Default project:")
                        .foregroundColor(.secondary)
                    TextField("Inbox", text: $defaultProject)
                        .textFieldStyle(.roundedBorder)
                }

                // Default context
                HStack {
                    Text("Default context:")
                        .foregroundColor(.secondary)
                    TextField("None", text: $defaultContext)
                        .textFieldStyle(.roundedBorder)
                }

                // Default status
                HStack {
                    Text("Default status:")
                        .foregroundColor(.secondary)
                    Picker("", selection: $defaultStatus) {
                        ForEach(Status.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Divider()

                // Toggles
                Toggle("Preserve original IDs (if present)", isOn: $preserveIds)
                Toggle("Create projects from imported data", isOn: $createProjects)
                Toggle("Create contexts from imported data", isOn: $createContexts)
                Toggle("Skip rows with errors (continue on error)", isOn: $skipErrors)
            }
            .padding()
        }
    }

    // MARK: - Column Mapping Section

    private var columnMappingSection: some View {
        GroupBox("Column Mapping") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Map CSV columns to task fields")
                    .font(.headline)

                ForEach(["title", "notes", "status", "project", "context", "due", "priority"], id: \.self) { field in
                    HStack {
                        Text("\(field.capitalized):")
                            .frame(width: 100, alignment: .leading)
                            .foregroundColor(.secondary)

                        Picker("", selection: binding(for: field)) {
                            Text("(not mapped)").tag(nil as String?)
                            ForEach(csvHeaders, id: \.self) { header in
                                Text(header).tag(header as String?)
                            }
                        }
                        .pickerStyle(.menu)

                        if field == "title" && columnMapping[field] == nil {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }

                if columnMapping["title"] == nil {
                    Label("Title column is required", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
        }
    }

    // MARK: - Preview Section

    private func previewSection(preview: ImportPreview) -> some View {
        GroupBox("Import Preview") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(preview.summary, systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                    Spacer()
                }

                if !preview.projects.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Projects:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(preview.projects.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(2)
                    }
                }

                if !preview.contexts.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contexts:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(preview.contexts.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(2)
                    }
                }

                if !preview.sampleTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sample tasks:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(preview.sampleTasks.prefix(3)) { task in
                            HStack {
                                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.status == .completed ? .green : .secondary)
                                Text(task.title)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                if !preview.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Warnings", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)

                        ForEach(preview.warnings, id: \.self) { warning in
                            Text("• \(warning)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Import Button

    private var importButton: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button("Preview") {
                updatePreview()
            }
            .buttonStyle(.bordered)

            Button("Import") {
                performImport()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(importPreview == nil || importPreview?.taskCount == 0)
        }
    }

    // MARK: - Importing Overlay

    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView(value: importProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 300)

                Text(importMessage)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(40)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }

    // MARK: - Import Result Sheet

    private func importResultSheet(result: ImportResult) -> some View {
        VStack(spacing: 20) {
            Image(systemName: result.isSuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(result.isSuccessful ? .green : .orange)

            Text(result.isSuccessful ? "Import Successful" : "Import Completed with Warnings")
                .font(.title)
                .bold()

            Text(result.summary)
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Imported:")
                        .foregroundColor(.secondary)
                    Text("\(result.importedCount) task\(result.importedCount == 1 ? "" : "s")")
                        .font(.system(.body, design: .monospaced))
                }

                if result.boardsCreated > 0 {
                    HStack {
                        Text("Boards created:")
                            .foregroundColor(.secondary)
                        Text("\(result.boardsCreated)")
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            if !result.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Warnings", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    ForEach(result.warnings, id: \.self) { warning in
                        Text("• \(warning)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }

            if !result.errors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Errors (\(result.errors.count))", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)

                    ForEach(Array(result.errors.prefix(5).enumerated()), id: \.offset) { index, error in
                        Text("• \(error.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if result.errors.count > 5 {
                        Text("... and \(result.errors.count - 5) more errors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }

            HStack {
                Button("Done") {
                    showingResult = false

                    // Call completion handler with imported tasks
                    if !result.tasks.isEmpty {
                        onImport(result.tasks)
                    }

                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(width: 500)
    }

    // MARK: - Helper Methods

    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedFileURL = url

            // Detect format
            if autoDetect {
                detectFormat(from: url)
            }

            // Auto-update preview
            updatePreview()

        case .failure(let error):
            importError = error
        }
    }

    private func detectFormat(from url: URL) {
        // Try to read content for better detection
        let content = try? String(contentsOf: url, encoding: .utf8)

        if let detected = ImportFormat.detect(from: url, content: content) {
            detectedFormat = detected
            selectedFormat = detected

            // Check if CSV/TSV requires column mapping
            if detected == .csv || detected == .tsv {
                parseCSVHeaders(from: url, delimiter: detected == .csv ? "," : "\t")
            }
        }
    }

    private func parseCSVHeaders(from url: URL, delimiter: String) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }

        let lines = content.components(separatedBy: .newlines)
        guard let firstLine = lines.first else { return }

        // Parse headers
        let headers = firstLine.components(separatedBy: delimiter)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        csvHeaders = headers

        // Auto-map columns
        columnMapping = ImportOptions.autoMapColumns(headers)

        // Show column mapping if needed
        showColumnMapping = true
    }

    private func updatePreview() {
        guard let fileURL = selectedFileURL else { return }

        let format = autoDetect ? (detectedFormat ?? selectedFormat) : selectedFormat
        var options = buildImportOptions(format: format)
        options.maxTasks = 10 // Limit preview to 10 tasks

        let manager = ImportManager()

        Task {
            do {
                let preview = try await manager.preview(from: fileURL, options: options)
                await MainActor.run {
                    importPreview = preview
                }
            } catch {
                await MainActor.run {
                    importError = error
                    importPreview = nil
                }
            }
        }
    }

    private func performImport() {
        guard let fileURL = selectedFileURL else { return }

        isImporting = true
        importProgress = 0.0
        importMessage = "Preparing import..."

        let manager = ImportManager()
        manager.progressHandler = { progress, message in
            self.importProgress = progress
            self.importMessage = message
        }

        let format = autoDetect ? (detectedFormat ?? selectedFormat) : selectedFormat
        let options = buildImportOptions(format: format)

        Task {
            do {
                let result = try await manager.importTasks(from: fileURL, options: options)

                await MainActor.run {
                    isImporting = false
                    importResult = result
                    showingResult = true
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    importError = error

                    // Show error alert
                    let result = ImportResult(
                        importedCount: 0,
                        tasks: [],
                        errors: [error as? ImportError ?? .ioError(error.localizedDescription)]
                    )
                    importResult = result
                    showingResult = true
                }
            }
        }
    }

    private func buildImportOptions(format: ImportFormat) -> ImportOptions {
        var options = ImportOptions(format: format)
        options.autoDetect = autoDetect
        options.defaultProject = defaultProject.isEmpty ? nil : defaultProject
        options.defaultContext = defaultContext.isEmpty ? nil : defaultContext
        options.defaultStatus = defaultStatus
        options.preserveIds = preserveIds
        options.createProjects = createProjects
        options.createContexts = createContexts
        options.skipErrors = skipErrors

        if format == .csv || format == .tsv {
            options.columnMapping = columnMapping
        }

        return options
    }

    private func binding(for field: String) -> Binding<String?> {
        Binding(
            get: { columnMapping[field] },
            set: { newValue in
                if let value = newValue {
                    columnMapping[field] = value
                } else {
                    columnMapping.removeValue(forKey: field)
                }
                updatePreview()
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ImportView { tasks in
        print("Imported \(tasks.count) tasks")
    }
}
