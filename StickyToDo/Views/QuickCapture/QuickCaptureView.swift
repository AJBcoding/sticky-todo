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
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(
                    color: DesignSystem.Shadow.modal.color,
                    radius: DesignSystem.Shadow.modal.radius,
                    x: DesignSystem.Shadow.modal.x,
                    y: DesignSystem.Shadow.modal.y
                )
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
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
                .accessibilityHidden(true)

            Text("Quick Capture")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close quick capture")
            .accessibilityHint("Double-tap to close this window")
        }
        .padding(DesignSystem.Spacing.sm)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Input field
            TextField("What do you need to do?", text: $inputText)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($isInputFocused)
                .onSubmit {
                    submitTask()
                }
                .accessibilityLabel("Task description")
                .accessibilityHint("Enter what you need to do. Press return to create the task")

            // Parsed metadata preview
            if !inputText.isEmpty {
                parsedMetadataPreview
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .animation(DesignSystem.Animation.standard, value: inputText.isEmpty)
    }

    // MARK: - Parsed Metadata Preview

    @ViewBuilder
    private var parsedMetadataPreview: some View {
        let parsed = NaturalLanguageParser.parse(inputText)

        HStack(spacing: DesignSystem.Spacing.xxs) {
            if let context = parsed.context ?? selectedContext {
                MetadataBadge(text: context, color: .blue, icon: "mappin.circle.fill")
                    .transition(.scale.combined(with: .opacity))
            }

            if let project = parsed.project ?? selectedProject {
                MetadataBadge(text: project, color: .purple, icon: "folder.fill")
                    .transition(.scale.combined(with: .opacity))
            }

            if let priority = parsed.priority {
                MetadataBadge(
                    text: priority.displayName,
                    color: priority == .high ? .red : .gray,
                    icon: "exclamationmark.circle.fill"
                )
                .transition(.scale.combined(with: .opacity))
            }

            if parsed.due != nil {
                MetadataBadge(text: "Due date set", color: .orange, icon: "calendar")
                    .transition(.scale.combined(with: .opacity))
            }

            if let effort = parsed.effort {
                MetadataBadge(text: "\(effort)m", color: .green, icon: "clock.fill")
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .font(.caption)
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            // Recent contexts
            if !recentContexts.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text("Recent Contexts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityAddTraits(.isHeader)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            ForEach(recentContexts.prefix(5), id: \.name) { context in
                                contextPill(context)
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                }
            }

            // Recent projects
            if !recentProjects.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text("Recent Projects")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityAddTraits(.isHeader)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            ForEach(recentProjects.prefix(5), id: \.self) { project in
                                projectPill(project)
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
    }

    // MARK: - Pills

    private func contextPill(_ context: Context) -> some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.fast) {
                if selectedContext == context.name {
                    selectedContext = nil
                } else {
                    selectedContext = context.name
                }
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Text(context.icon)
                Text(context.displayName)
            }
            .font(.caption)
            .padding(.horizontal, DesignSystem.Spacing.xxs + 2)
            .padding(.vertical, DesignSystem.Spacing.xxxs + 2)
            .background(
                Capsule()
                    .fill(selectedContext == context.name ? Color.blue : Color.secondary.opacity(DesignSystem.Opacity.medium))
            )
            .foregroundColor(selectedContext == context.name ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(context.displayName)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(selectedContext == context.name ? "Selected" : "Not selected")
        .accessibilityHint("Double-tap to \(selectedContext == context.name ? "deselect" : "select") this context")
    }

    private func projectPill(_ project: String) -> some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.fast) {
                if selectedProject == project {
                    selectedProject = nil
                } else {
                    selectedProject = project
                }
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: "folder.fill")
                Text(project)
            }
            .font(.caption)
            .padding(.horizontal, DesignSystem.Spacing.xxs + 2)
            .padding(.vertical, DesignSystem.Spacing.xxxs + 2)
            .background(
                Capsule()
                    .fill(selectedProject == project ? Color.purple : Color.secondary.opacity(DesignSystem.Opacity.medium))
            )
            .foregroundColor(selectedProject == project ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Project: \(project)")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(selectedProject == project ? "Selected" : "Not selected")
        .accessibilityHint("Double-tap to \(selectedProject == project ? "deselect" : "select") this project")
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xxxs) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)

                Text("Try: \"Call John @phone #Website !high tomorrow\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Tip: You can use @ for context, # for project, ! for priority, and date words like tomorrow")

            Spacer()

            HStack(spacing: DesignSystem.Spacing.xs) {
                Label("Cancel", systemImage: "escape")
                    .labelStyle(.iconOnly)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Cancel")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Label("Create", systemImage: "return")
                    .labelStyle(.iconOnly)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Create")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(Color.secondary.opacity(DesignSystem.Opacity.subtle))
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
