//
//  SaveAsTemplateView.swift
//  StickyToDo-SwiftUI
//
//  View for creating a template from an existing task.
//

import SwiftUI

/// View for saving a task as a template
struct SaveAsTemplateView: View {
    let task: Task
    let onSave: (TaskTemplate) -> Void
    let onCancel: () -> Void

    @State private var templateName = ""
    @State private var category = ""
    @State private var includeNotes = true
    @State private var includeProject = true
    @State private var includeContext = true
    @State private var includePriority = true
    @State private var includeEffort = true
    @State private var includeTags = true
    @State private var includeFlagged = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Save as Template")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("Cancel template creation")
                .accessibilityHint("Close without saving template")

                Button("Save") {
                    saveTemplate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(templateName.isEmpty)
                .accessibilityLabel("Save template")
                .accessibilityHint("Create template from this task")
            }
            .padding()

            Divider()

            // Form
            Form {
                Section("Template Information") {
                    TextField("Template Name", text: $templateName)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Template name")
                        .accessibilityHint("Enter a name for this template")

                    TextField("Category (optional)", text: $category)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Template category")
                        .accessibilityHint("Optional category to organize templates")
                }

                Section("Task Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title: \(task.title)")
                            .font(.body)
                            .foregroundColor(.primary)

                        if !task.notes.isEmpty {
                            Text("Notes: \(task.notes.prefix(100))\(task.notes.count > 100 ? "..." : "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            if let project = task.project {
                                Label(project, systemImage: "folder")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let context = task.context {
                                Label(context, systemImage: "location")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Label(task.priority.displayName, systemImage: "flag")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }

                Section("Include in Template") {
                    Toggle("Notes", isOn: $includeNotes)
                        .accessibilityLabel("Include notes in template")
                    Toggle("Project", isOn: $includeProject)
                        .disabled(task.project == nil)
                        .accessibilityLabel("Include project in template")
                    Toggle("Context", isOn: $includeContext)
                        .disabled(task.context == nil)
                        .accessibilityLabel("Include context in template")
                    Toggle("Priority", isOn: $includePriority)
                        .accessibilityLabel("Include priority in template")
                    Toggle("Effort Estimate", isOn: $includeEffort)
                        .disabled(task.effort == nil)
                        .accessibilityLabel("Include effort estimate in template")
                    Toggle("Tags", isOn: $includeTags)
                        .disabled(task.tags.isEmpty)
                        .accessibilityLabel("Include tags in template")
                    Toggle("Flagged Status", isOn: $includeFlagged)
                        .accessibilityLabel("Include flagged status in template")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 600)
        .onAppear {
            // Set default template name
            templateName = "\(task.title) Template"
        }
    }

    private func saveTemplate() {
        let template = TaskTemplate(
            name: templateName,
            title: task.title,
            notes: includeNotes ? task.notes : "",
            defaultProject: includeProject ? task.project : nil,
            defaultContext: includeContext ? task.context : nil,
            defaultPriority: includePriority ? task.priority : .medium,
            defaultEffort: includeEffort ? task.effort : nil,
            defaultStatus: task.status,
            tags: includeTags ? task.tags : [],
            subtasks: nil, // Don't include subtasks for now
            defaultFlagged: includeFlagged && task.flagged,
            category: category.isEmpty ? nil : category
        )

        onSave(template)
    }
}

// MARK: - Preview

#Preview("Save as Template") {
    SaveAsTemplateView(
        task: Task(
            title: "Review quarterly goals",
            notes: "Check progress on Q4 objectives and adjust plans as needed.",
            status: .nextAction,
            project: "Planning",
            context: "@computer",
            flagged: true,
            priority: .high,
            effort: 60
        ),
        onSave: { template in
            print("Saved template: \(template.name)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
