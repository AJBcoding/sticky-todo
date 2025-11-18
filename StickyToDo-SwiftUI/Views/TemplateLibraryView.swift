//
//  TemplateLibraryView.swift
//  StickyToDo
//
//  Template library for managing and creating tasks from templates.
//

import SwiftUI

/// Template library view for managing task templates
struct TemplateLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var templateStore: TemplateStore
    @State private var selectedTemplate: TaskTemplate?
    @State private var showingNewTemplateSheet = false
    @State private var showingEditSheet = false
    @State private var searchText = ""
    @State private var selectedCategory: String?

    var onCreate: ((Task) -> Void)?

    private var templates: [TaskTemplate] {
        templateStore.templates
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                Divider()

                HStack(spacing: 0) {
                    // Categories sidebar
                    categoriesSidebar
                        .frame(width: 200)

                    Divider()

                    // Templates list
                    templatesList
                }
            }
            .navigationTitle("Template Library")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewTemplateSheet = true }) {
                        Label("New Template", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewTemplateSheet) {
                NewTemplateSheet(onSave: { template in
                    templateStore.create(template)
                    showingNewTemplateSheet = false
                })
            }
            .sheet(isPresented: $showingEditSheet) {
                if let template = selectedTemplate {
                    EditTemplateSheet(template: template, onSave: { updatedTemplate in
                        templateStore.update(updatedTemplate)
                        showingEditSheet = false
                    })
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search templates...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.textBackgroundColor))
    }

    private var categoriesSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Categories")
                .font(.headline)
                .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    CategoryRow(
                        name: "All Templates",
                        count: templates.count,
                        isSelected: selectedCategory == nil,
                        onSelect: { selectedCategory = nil }
                    )

                    ForEach(categories, id: \.self) { category in
                        CategoryRow(
                            name: category,
                            count: templatesInCategory(category).count,
                            isSelected: selectedCategory == category,
                            onSelect: { selectedCategory = category }
                        )
                    }
                }
            }

            Spacer()
        }
        .background(Color(.controlBackgroundColor))
    }

    private var templatesList: some View {
        Group {
            if filteredTemplates.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 280, maximum: 350), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(filteredTemplates) { template in
                            TemplateCard(
                                template: template,
                                onUse: {
                                    useTemplate(template)
                                },
                                onEdit: {
                                    selectedTemplate = template
                                    showingEditSheet = true
                                },
                                onDelete: {
                                    deleteTemplate(template)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Templates Found")
                .font(.title3)
                .fontWeight(.medium)

            Text("Create a new template or adjust your search")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var categories: [String] {
        templateStore.categories
    }

    private func templatesInCategory(_ category: String) -> [TaskTemplate] {
        templates.filter { $0.category == category }
    }

    private var filteredTemplates: [TaskTemplate] {
        var result = templates

        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.title.lowercased().contains(searchText.lowercased())
            }
        }

        return result.sorted { lhs, rhs in
            if lhs.useCount != rhs.useCount {
                return lhs.useCount > rhs.useCount
            }
            return lhs.name < rhs.name
        }
    }

    private func useTemplate(_ template: TaskTemplate) {
        templateStore.recordUse(of: template)
        let task = template.createTask()
        onCreate?(task)
        dismiss()
    }

    private func deleteTemplate(_ template: TaskTemplate) {
        templateStore.delete(template)
    }
}

/// Category row in the sidebar
struct CategoryRow: View {
    let name: String
    let count: Int
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(name)
                    .font(.body)

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Template card for the grid
struct TemplateCard: View {
    let template: TaskTemplate
    let onUse: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .lineLimit(2)

                    if let category = template.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isHovering {
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Preview
            VStack(alignment: .leading, spacing: 6) {
                Text(template.title)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if !template.notes.isEmpty {
                    Text(template.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }

            // Metadata
            HStack(spacing: 12) {
                if template.hasSubtasks {
                    Label("\(template.subtaskCount)", systemImage: "checklist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !template.tags.isEmpty {
                    Label("\(template.tags.count)", systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if template.hasBeenUsed {
                    Text("Used \(template.useCount)x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Actions
            Button(action: onUse) {
                Text("Use Template")
                    .font(.body)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isHovering ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// Sheet for creating a new template
struct NewTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (TaskTemplate) -> Void

    @State private var name = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var category = ""
    @State private var defaultProject = ""
    @State private var defaultContext = ""
    @State private var defaultPriority: Priority = .medium
    @State private var defaultEffort = ""
    @State private var subtasksText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create Template")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Name")
                        .font(.headline)
                    TextField("e.g., Weekly Review", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Category (Optional)")
                        .font(.headline)
                    TextField("e.g., Work, Personal", text: $category)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Title")
                        .font(.headline)
                    TextField("Task title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Notes")
                        .font(.headline)
                    TextEditor(text: $notes)
                        .font(.body)
                        .frame(minHeight: 100)
                        .border(Color.secondary.opacity(0.2))
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project")
                            .font(.headline)
                        TextField("Optional", text: $defaultProject)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context")
                            .font(.headline)
                        TextField("Optional", text: $defaultContext)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.headline)
                        Picker("Priority", selection: $defaultPriority) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Effort (minutes)")
                            .font(.headline)
                        TextField("Optional", text: $defaultEffort)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Subtasks (one per line, optional)")
                        .font(.headline)
                    TextEditor(text: $subtasksText)
                        .font(.body)
                        .frame(minHeight: 80)
                        .border(Color.secondary.opacity(0.2))
                }

                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)

                    Spacer()

                    Button("Create") {
                        let subtasks = subtasksText
                            .split(separator: "\n")
                            .map { String($0).trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }

                        let template = TaskTemplate(
                            name: name,
                            title: title,
                            notes: notes,
                            defaultProject: defaultProject.isEmpty ? nil : defaultProject,
                            defaultContext: defaultContext.isEmpty ? nil : defaultContext,
                            defaultPriority: defaultPriority,
                            defaultEffort: Int(defaultEffort),
                            subtasks: subtasks.isEmpty ? nil : subtasks,
                            category: category.isEmpty ? nil : category
                        )

                        onSave(template)
                        dismiss()
                    }
                    .keyboardShortcut(.return)
                    .disabled(name.isEmpty || title.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 700)
    }
}

/// Sheet for editing an existing template
struct EditTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let template: TaskTemplate
    let onSave: (TaskTemplate) -> Void

    @State private var name: String
    @State private var title: String
    @State private var notes: String
    @State private var category: String
    @State private var defaultProject: String
    @State private var defaultContext: String
    @State private var defaultPriority: Priority
    @State private var defaultEffort: String
    @State private var subtasksText: String

    init(template: TaskTemplate, onSave: @escaping (TaskTemplate) -> Void) {
        self.template = template
        self.onSave = onSave

        _name = State(initialValue: template.name)
        _title = State(initialValue: template.title)
        _notes = State(initialValue: template.notes)
        _category = State(initialValue: template.category ?? "")
        _defaultProject = State(initialValue: template.defaultProject ?? "")
        _defaultContext = State(initialValue: template.defaultContext ?? "")
        _defaultPriority = State(initialValue: template.defaultPriority)
        _defaultEffort = State(initialValue: template.defaultEffort.map { String($0) } ?? "")
        _subtasksText = State(initialValue: template.subtasks?.joined(separator: "\n") ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Edit Template")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Name")
                        .font(.headline)
                    TextField("e.g., Weekly Review", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Category (Optional)")
                        .font(.headline)
                    TextField("e.g., Work, Personal", text: $category)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Title")
                        .font(.headline)
                    TextField("Task title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Notes")
                        .font(.headline)
                    TextEditor(text: $notes)
                        .font(.body)
                        .frame(minHeight: 100)
                        .border(Color.secondary.opacity(0.2))
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project")
                            .font(.headline)
                        TextField("Optional", text: $defaultProject)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context")
                            .font(.headline)
                        TextField("Optional", text: $defaultContext)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.headline)
                        Picker("Priority", selection: $defaultPriority) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Effort (minutes)")
                            .font(.headline)
                        TextField("Optional", text: $defaultEffort)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Subtasks (one per line, optional)")
                        .font(.headline)
                    TextEditor(text: $subtasksText)
                        .font(.body)
                        .frame(minHeight: 80)
                        .border(Color.secondary.opacity(0.2))
                }

                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)

                    Spacer()

                    Button("Save") {
                        let subtasks = subtasksText
                            .split(separator: "\n")
                            .map { String($0).trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }

                        var updatedTemplate = template
                        updatedTemplate.name = name
                        updatedTemplate.title = title
                        updatedTemplate.notes = notes
                        updatedTemplate.category = category.isEmpty ? nil : category
                        updatedTemplate.defaultProject = defaultProject.isEmpty ? nil : defaultProject
                        updatedTemplate.defaultContext = defaultContext.isEmpty ? nil : defaultContext
                        updatedTemplate.defaultPriority = defaultPriority
                        updatedTemplate.defaultEffort = Int(defaultEffort)
                        updatedTemplate.subtasks = subtasks.isEmpty ? nil : subtasks
                        updatedTemplate.touch()

                        onSave(updatedTemplate)
                        dismiss()
                    }
                    .keyboardShortcut(.return)
                    .disabled(name.isEmpty || title.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 700)
    }
}

// MARK: - Preview

struct TemplateLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        TemplateLibraryView(
            templateStore: {
                let store = TemplateStore(rootDirectory: FileManager.default.temporaryDirectory)
                try? store.loadAll()
                return store
            }(),
            onCreate: { task in
                print("Created task: \(task.title)")
            }
        )
    }
}
