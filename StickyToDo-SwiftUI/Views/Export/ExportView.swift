//
//  ExportView.swift
//  StickyToDo-SwiftUI
//
//  Comprehensive export interface with format selection and filtering options.
//

import SwiftUI
import StickyToDoCore

/// Export view with all format options and filtering
struct ExportView: View {

    // MARK: - Environment

    let tasks: [Task]
    let boards: [Board]
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var selectedFormat: ExportFormat = .json
    @State private var includeCompleted: Bool = true
    @State private var includeArchived: Bool = false
    @State private var includeNotes: Bool = true
    @State private var includeBoards: Bool = true
    @State private var filename: String = "StickyToDo-Export"

    // Date range filter
    @State private var useDateRange: Bool = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate: Date = Date()

    // Project/Context filter
    @State private var useProjectFilter: Bool = false
    @State private var selectedProjects: Set<String> = []

    @State private var useContextFilter: Bool = false
    @State private var selectedContexts: Set<String> = []

    // Export state
    @State private var isExporting: Bool = false
    @State private var exportProgress: Double = 0.0
    @State private var exportMessage: String = ""
    @State private var exportResult: ExportResult?
    @State private var exportError: Error?
    @State private var showingResult: Bool = false

    // MARK: - Computed Properties

    private var availableProjects: [String] {
        Array(Set(tasks.compactMap { $0.project })).sorted()
    }

    private var availableContexts: [String] {
        Array(Set(tasks.compactMap { $0.context })).sorted()
    }

    private var exportPreview: ExportPreview {
        let manager = ExportManager()
        let options = buildExportOptions()
        return manager.preview(tasks: tasks, options: options)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                header

                // Format selection
                formatSection

                // Filter options
                filterSection

                // Preview
                previewSection

                // Export button
                exportButton
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 600)
        .navigationTitle("Export Data")
        .sheet(isPresented: $showingResult) {
            if let result = exportResult {
                exportResultSheet(result: result)
            }
        }
        .overlay {
            if isExporting {
                exportingOverlay
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Export Your Data")
                .font(.largeTitle)
                .bold()

            Text("Choose a format and configure export options")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Format Section

    private var formatSection: some View {
        GroupBox("Export Format") {
            VStack(alignment: .leading, spacing: 16) {
                // Format picker
                Picker("Format", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.menu)

                // Format description
                Text(selectedFormat.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Data loss warnings
                if !selectedFormat.dataLossWarnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Limitations", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)

                        ForEach(selectedFormat.dataLossWarnings, id: \.self) { warning in
                            Label(warning, systemImage: "circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .labelStyle(.titleOnly)
                                .padding(.leading, 20)
                        }
                    }
                    .padding(.top, 8)
                }

                // Filename
                HStack {
                    Text("Filename:")
                        .foregroundColor(.secondary)
                    TextField("Export filename", text: $filename)
                        .textFieldStyle(.roundedBorder)
                    Text(".\(selectedFormat.fileExtension)")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        GroupBox("Filter Options") {
            VStack(alignment: .leading, spacing: 16) {
                // Include options
                Toggle("Include completed tasks", isOn: $includeCompleted)
                Toggle("Include archived tasks", isOn: $includeArchived)
                Toggle("Include notes", isOn: $includeNotes)

                if selectedFormat == .nativeMarkdownArchive {
                    Toggle("Include boards", isOn: $includeBoards)
                }

                Divider()

                // Date range filter
                Toggle("Filter by date range", isOn: $useDateRange)

                if useDateRange {
                    HStack {
                        DatePicker("From", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                        Text("to")
                            .foregroundColor(.secondary)
                        DatePicker("To", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.leading, 20)
                }

                Divider()

                // Project filter
                Toggle("Filter by projects", isOn: $useProjectFilter)

                if useProjectFilter && !availableProjects.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(availableProjects, id: \.self) { project in
                                Toggle(project, isOn: Binding(
                                    get: { selectedProjects.contains(project) },
                                    set: { isOn in
                                        if isOn {
                                            selectedProjects.insert(project)
                                        } else {
                                            selectedProjects.remove(project)
                                        }
                                    }
                                ))
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .padding(.leading, 20)
                }

                Divider()

                // Context filter
                Toggle("Filter by contexts", isOn: $useContextFilter)

                if useContextFilter && !availableContexts.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(availableContexts, id: \.self) { context in
                                Toggle(context, isOn: Binding(
                                    get: { selectedContexts.contains(context) },
                                    set: { isOn in
                                        if isOn {
                                            selectedContexts.insert(context)
                                        } else {
                                            selectedContexts.remove(context)
                                        }
                                    }
                                ))
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .padding(.leading, 20)
                }
            }
            .padding()
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        GroupBox("Export Preview") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("\(exportPreview.taskCount) tasks will be exported", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                    Spacer()
                }

                if !exportPreview.projects.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Projects:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(exportPreview.projects.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(2)
                    }
                }

                if !exportPreview.contexts.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contexts:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(exportPreview.contexts.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Export Button

    private var exportButton: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button("Export") {
                performExport()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(exportPreview.taskCount == 0)
        }
    }

    // MARK: - Exporting Overlay

    private var exportingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView(value: exportProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 300)

                Text(exportMessage)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(40)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }

    // MARK: - Export Result Sheet

    private func exportResultSheet(result: ExportResult) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Export Successful")
                .font(.title)
                .bold()

            Text(result.summary)
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("File:")
                        .foregroundColor(.secondary)
                    Text(result.fileURL.lastPathComponent)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("Location:")
                        .foregroundColor(.secondary)
                    Text(result.fileURL.deletingLastPathComponent().path)
                        .font(.caption)
                        .lineLimit(1)
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

            HStack {
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([result.fileURL])
                    showingResult = false
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("Done") {
                    showingResult = false
                    dismiss()
                }
            }
        }
        .padding(40)
        .frame(width: 500)
    }

    // MARK: - Helper Methods

    private func buildExportOptions() -> ExportOptions {
        var options = ExportOptions(format: selectedFormat, filename: filename)
        options.includeCompleted = includeCompleted
        options.includeArchived = includeArchived
        options.includeNotes = includeNotes
        options.includeBoards = includeBoards

        if useDateRange {
            options.dateRange = DateInterval(start: startDate, end: endDate)
        }

        if useProjectFilter && !selectedProjects.isEmpty {
            options.projects = Array(selectedProjects)
        }

        if useContextFilter && !selectedContexts.isEmpty {
            options.contexts = Array(selectedContexts)
        }

        return options
    }

    private func performExport() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: selectedFormat.fileExtension)!]
        savePanel.nameFieldStringValue = "\(filename).\(selectedFormat.fileExtension)"
        savePanel.message = "Choose where to save the export"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            isExporting = true
            exportProgress = 0.0
            exportMessage = "Preparing export..."

            let manager = ExportManager()
            manager.progressHandler = { progress, message in
                self.exportProgress = progress
                self.exportMessage = message
            }

            let options = buildExportOptions()

            Task {
                do {
                    let result = try await manager.export(
                        tasks: tasks,
                        boards: boards,
                        to: url,
                        options: options
                    )

                    await MainActor.run {
                        isExporting = false
                        exportResult = result
                        showingResult = true
                    }
                } catch {
                    await MainActor.run {
                        isExporting = false
                        exportError = error
                        // Show error alert
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ExportView(
        tasks: [
            Task(title: "Sample Task 1", project: "Project A", context: "@home"),
            Task(title: "Sample Task 2", project: "Project B", context: "@work"),
            Task(title: "Sample Task 3", status: .completed)
        ],
        boards: []
    )
}
