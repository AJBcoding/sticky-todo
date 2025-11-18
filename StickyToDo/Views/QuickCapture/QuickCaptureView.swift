//
//  QuickCaptureView.swift
//  StickyToDo
//
//  Quick capture window for rapid task entry.
//

import SwiftUI

/// Quick capture view for rapid task creation
///
/// Features:
/// - Floating window appearance (used with .windowStyle(.plain))
/// - TextField with submit action
/// - Pills for recent projects/contexts
/// - Natural language parsing
/// - Keyboard shortcuts (Esc to cancel, Enter to submit)
/// - Focus state management for instant typing
struct QuickCaptureView: View {

    // MARK: - Properties

    /// The text being entered
    @State private var inputText: String = ""

    /// Recent projects for quick selection
    let recentProjects: [String]

    /// Recent contexts for quick selection
    let recentContexts: [Context]

    /// Selected project (optional)
    @State private var selectedProject: String?

    /// Selected context (optional)
    @State private var selectedContext: String?

    /// Whether the input field is focused
    @FocusState private var isInputFocused: Bool

    /// Callback when task is created
    var onCreateTask: (Task) -> Void

    /// Callback when window should close
    var onClose: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Main input area
            mainContent

            Divider()

            // Recent suggestions
            if !recentProjects.isEmpty || !recentContexts.isEmpty {
                suggestionsSection
                Divider()
            }

            // Footer with hints
            footer
        }
        .frame(width: 500, height: suggestionsHeight)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 20)
        )
        .onAppear {
            isInputFocused = true
        }
        .onExitCommand {
            onClose()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("Quick Capture")
                .font(.headline)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Input field
            TextField("What do you need to do?", text: $inputText)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($isInputFocused)
                .onSubmit {
                    submitTask()
                }

            // Parsed metadata preview
            if !inputText.isEmpty {
                parsedMetadataPreview
            }
        }
        .padding()
    }

    // MARK: - Parsed Metadata Preview

    @ViewBuilder
    private var parsedMetadataPreview: some View {
        let parsed = NaturalLanguageParser.parse(inputText)

        HStack(spacing: 8) {
            if let context = parsed.context ?? selectedContext {
                MetadataBadge(text: context, color: .blue, icon: "mappin.circle.fill")
            }

            if let project = parsed.project ?? selectedProject {
                MetadataBadge(text: project, color: .purple, icon: "folder.fill")
            }

            if let priority = parsed.priority {
                MetadataBadge(
                    text: priority.displayName,
                    color: priority == .high ? .red : .gray,
                    icon: "exclamationmark.circle.fill"
                )
            }

            if parsed.due != nil {
                MetadataBadge(text: "Due date set", color: .orange, icon: "calendar")
            }

            if let effort = parsed.effort {
                MetadataBadge(text: "\(effort)m", color: .green, icon: "clock.fill")
            }
        }
        .font(.caption)
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recent contexts
            if !recentContexts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent Contexts")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recentContexts.prefix(5), id: \.name) { context in
                                contextPill(context)
                            }
                        }
                    }
                }
            }

            // Recent projects
            if !recentProjects.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent Projects")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recentProjects.prefix(5), id: \.self) { project in
                                projectPill(project)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Pills

    private func contextPill(_ context: Context) -> some View {
        Button(action: {
            if selectedContext == context.name {
                selectedContext = nil
            } else {
                selectedContext = context.name
            }
        }) {
            HStack(spacing: 4) {
                Text(context.icon)
                Text(context.displayName)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selectedContext == context.name ? Color.blue : Color.secondary.opacity(0.2))
            )
            .foregroundColor(selectedContext == context.name ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func projectPill(_ project: String) -> some View {
        Button(action: {
            if selectedProject == project {
                selectedProject = nil
            } else {
                selectedProject = project
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "folder.fill")
                Text(project)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selectedProject == project ? Color.purple : Color.secondary.opacity(0.2))
            )
            .foregroundColor(selectedProject == project ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("💡 Try: \"Call John @phone #Website !high tomorrow\"")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 12) {
                Text("⎋ Cancel")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("↵ Create")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
    }

    // MARK: - Helper Methods

    private var suggestionsHeight: CGFloat {
        if !recentProjects.isEmpty || !recentContexts.isEmpty {
            return 280
        }
        return 180
    }

    private func submitTask() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        // Parse the input text
        let parsed = NaturalLanguageParser.parse(inputText)

        // Create the task
        let task = Task(
            title: parsed.title,
            status: .inbox,
            project: parsed.project ?? selectedProject,
            context: parsed.context ?? selectedContext,
            due: parsed.due,
            defer: parsed.defer,
            priority: parsed.priority ?? .medium,
            effort: parsed.effort
        )

        // Callback
        onCreateTask(task)

        // Reset
        inputText = ""
        selectedProject = nil
        selectedContext = nil

        // Close window
        onClose()
    }
}

// MARK: - Preview

#Preview("Quick Capture") {
    QuickCaptureView(
        recentProjects: ["Website Redesign", "Q4 Planning", "Marketing Campaign"],
        recentContexts: [
            Context(name: "@computer", icon: "💻", color: "blue"),
            Context(name: "@phone", icon: "📱", color: "green"),
            Context(name: "@errands", icon: "🚗", color: "purple"),
        ],
        onCreateTask: { _ in },
        onClose: {}
    )
}

#Preview("Quick Capture - No Suggestions") {
    QuickCaptureView(
        recentProjects: [],
        recentContexts: [],
        onCreateTask: { _ in },
        onClose: {}
    )
}
