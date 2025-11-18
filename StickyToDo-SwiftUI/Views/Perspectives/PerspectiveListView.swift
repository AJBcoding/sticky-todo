//
//  PerspectiveListView.swift
//  StickyToDo-SwiftUI
//
//  List view for managing all saved perspectives.
//

import SwiftUI

/// View for managing all custom perspectives
///
/// Features:
/// - List of all custom perspectives
/// - Create new perspective
/// - Edit existing perspective
/// - Delete perspectives
/// - Export/Import perspectives
/// - Search and filter
struct PerspectiveListView: View {

    // MARK: - Properties

    @ObservedObject var perspectiveStore: PerspectiveStore

    /// Callback when a perspective is selected
    let onSelectPerspective: ((SmartPerspective) -> Void)?

    /// Callback when the view should be dismissed
    let onDismiss: () -> Void

    // MARK: - State

    @State private var searchText = ""
    @State private var showEditor = false
    @State private var editingPerspective: SmartPerspective?
    @State private var showImportPicker = false
    @State private var showExportPicker = false
    @State private var selectedPerspectives: Set<UUID> = []

    // MARK: - Computed Properties

    private var filteredPerspectives: [SmartPerspective] {
        if searchText.isEmpty {
            return perspectiveStore.customPerspectives
        } else {
            return perspectiveStore.customPerspectives.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    private var builtInPerspectives: [SmartPerspective] {
        perspectiveStore.builtInPerspectives
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Search
            searchBar

            // Lists
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Built-in Perspectives
                    if !builtInPerspectives.isEmpty {
                        sectionView(
                            title: "Built-in Smart Perspectives",
                            perspectives: builtInPerspectives,
                            allowEdit: false
                        )
                    }

                    // Custom Perspectives
                    sectionView(
                        title: "Custom Perspectives",
                        perspectives: filteredPerspectives,
                        allowEdit: true
                    )
                }
                .padding()
            }

            Divider()

            // Footer
            footerView
        }
        .frame(minWidth: 600, minHeight: 500)
        .sheet(isPresented: $showEditor) {
            PerspectiveEditorView(
                perspective: editingPerspective,
                onSave: { perspective in
                    if editingPerspective != nil {
                        perspectiveStore.update(perspective)
                    } else {
                        perspectiveStore.create(perspective)
                    }
                    showEditor = false
                    editingPerspective = nil
                },
                onCancel: {
                    showEditor = false
                    editingPerspective = nil
                },
                onExport: { perspective in
                    exportPerspective(perspective)
                }
            )
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $showExportPicker,
            document: PerspectiveDocument(perspectives: Array(selectedPerspectives.compactMap { perspectiveStore.perspective(withID: $0) })),
            contentType: .json,
            defaultFilename: "perspectives.json"
        ) { result in
            handleExport(result)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Text("Manage Perspectives")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search perspectives", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func sectionView(title: String, perspectives: [SmartPerspective], allowEdit: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            if perspectives.isEmpty && allowEdit {
                emptyStateView
            } else {
                ForEach(perspectives) { perspective in
                    perspectiveRow(perspective, allowEdit: allowEdit)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No custom perspectives")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Create a custom perspective to save your favorite filters and views")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                createNewPerspective()
            } label: {
                Label("Create Perspective", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func perspectiveRow(_ perspective: SmartPerspective, allowEdit: Bool) -> some View {
        HStack(spacing: 12) {
            // Icon
            if let icon = perspective.icon {
                Text(icon)
                    .font(.title2)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(perspective.name)
                    .font(.body)
                    .fontWeight(.medium)

                if let description = perspective.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Stats
                HStack(spacing: 12) {
                    if !perspective.rules.isEmpty {
                        Label("\(perspective.rules.count) rule\(perspective.rules.count == 1 ? "" : "s")", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Label(perspective.groupBy.displayName, systemImage: "square.grid.2x2")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Label(perspective.sortBy.displayName, systemImage: "arrow.up.arrow.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                if let onSelect = onSelectPerspective {
                    Button {
                        onSelect(perspective)
                    } label: {
                        Image(systemName: "eye")
                    }
                    .buttonStyle(.plain)
                    .help("View perspective")
                }

                if allowEdit {
                    Button {
                        editPerspective(perspective)
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)
                    .help("Edit perspective")

                    Button {
                        deletePerspective(perspective)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete perspective")
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var footerView: some View {
        HStack {
            // Stats
            Text("\(perspectiveStore.customPerspectiveCount) custom, \(perspectiveStore.builtInPerspectiveCount) built-in")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // Actions
            Button {
                showImportPicker = true
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)

            Button {
                exportAllPerspectives()
            } label: {
                Label("Export All", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)

            Button {
                createNewPerspective()
            } label: {
                Label("New Perspective", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding()
    }

    // MARK: - Actions

    private func createNewPerspective() {
        editingPerspective = nil
        showEditor = true
    }

    private func editPerspective(_ perspective: SmartPerspective) {
        editingPerspective = perspective
        showEditor = true
    }

    private func deletePerspective(_ perspective: SmartPerspective) {
        perspectiveStore.delete(perspective)
    }

    private func exportPerspective(_ perspective: SmartPerspective) {
        selectedPerspectives = [perspective.id]
        showExportPicker = true
    }

    private func exportAllPerspectives() {
        selectedPerspectives = Set(perspectiveStore.customPerspectives.map { $0.id })
        showExportPicker = true
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            do {
                try perspectiveStore.importAndCreate(from: url)
            } catch {
                print("Import failed: \(error)")
            }

        case .failure(let error):
            print("Import picker failed: \(error)")
        }
    }

    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Exported to: \(url)")
        case .failure(let error):
            print("Export failed: \(error)")
        }
    }
}

// MARK: - Perspective Document

import UniformTypeIdentifiers

struct PerspectiveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let perspectives: [SmartPerspective]

    init(perspectives: [SmartPerspective]) {
        self.perspectives = perspectives
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        perspectives = try decoder.decode([SmartPerspective].self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(perspectives)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

#Preview("Perspective List") {
    PerspectiveListView(
        perspectiveStore: {
            let store = PerspectiveStore(rootDirectory: FileManager.default.temporaryDirectory)
            try? store.loadAll()
            return store
        }(),
        onSelectPerspective: { perspective in
            print("Selected: \(perspective.name)")
        },
        onDismiss: {
            print("Dismissed")
        }
    )
}
