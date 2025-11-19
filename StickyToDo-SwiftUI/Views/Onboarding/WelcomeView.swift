//
//  WelcomeView.swift
//  StickyToDo-SwiftUI
//
//  First-run welcome screen with app introduction and feature highlights.
//  Beautiful, engaging UI to make a great first impression.
//

import SwiftUI

/// Welcome screen shown on first app launch
struct WelcomeView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WelcomeViewModel()

    var onComplete: ((WelcomeConfiguration) -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content
                TabView(selection: $viewModel.currentPage) {
                    welcomePage
                        .tag(0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                    gtdOverviewPage
                        .tag(1)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                    featuresPage
                        .tag(2)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                    configurationPage
                        .tag(3)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(.smooth, value: viewModel.currentPage)

                // Navigation buttons
                bottomBar
                    .padding()
                    .background(.ultraThinMaterial)
            }
            .background(
                AnimatedGradientBackground(page: viewModel.currentPage)
            )
        }
        .frame(width: 700, height: 550)
        .onAppear {
            viewModel.startAnimations()
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "note.text")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                .symbolEffect(.pulse, options: .repeating, value: viewModel.iconPulse)
                .scaleEffect(viewModel.iconScale)
                .rotationEffect(.degrees(viewModel.iconRotation))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: viewModel.iconScale)
                .accessibilityLabel("StickyToDo app icon")
                .accessibilityHidden(true)

            Text("Welcome to StickyToDo")
                .font(.system(size: 40, weight: .bold))
                .tracking(0.5)
                .opacity(viewModel.titleOpacity)
                .offset(y: viewModel.titleOffset)
                .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.2), value: viewModel.titleOpacity)
                .accessibilityAddTraits(.isHeader)

            Text("Your mind is for having ideas, not holding them.")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
                .opacity(viewModel.descriptionOpacity)
                .offset(y: viewModel.descriptionOffset)
                .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.4), value: viewModel.descriptionOpacity)

            Text("A beautiful, GTD-inspired task manager that combines the flexibility of sticky notes with the power of Getting Things Done.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)
                .opacity(viewModel.descriptionOpacity)
                .offset(y: viewModel.descriptionOffset)
                .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.6), value: viewModel.descriptionOpacity)

            Spacer()
        }
        .padding()
    }

    private var gtdOverviewPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                .symbolEffect(.bounce, options: .nonRepeating, value: viewModel.currentPage == 1)
                .symbolEffect(.pulse, options: .speed(0.5).repeat(2), value: viewModel.currentPage == 1)
                .accessibilityHidden(true)

            Text("The GTD Workflow")
                .font(.system(size: 36, weight: .bold))
                .tracking(0.3)
                .accessibilityAddTraits(.isHeader)

            Text("A proven system for stress-free productivity")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 18) {
                GTDStepView(
                    icon: "tray.and.arrow.down",
                    title: "1. Capture Everything",
                    description: "Get every task, idea, and commitment out of your head and into your inbox",
                    index: 0,
                    isVisible: viewModel.currentPage == 1
                )

                GTDStepView(
                    icon: "list.bullet.clipboard",
                    title: "2. Clarify What It Means",
                    description: "Process each item - is it actionable? What's the next action?",
                    index: 1,
                    isVisible: viewModel.currentPage == 1
                )

                GTDStepView(
                    icon: "square.grid.2x2",
                    title: "3. Organize By Context",
                    description: "Group tasks by where you can do them: @computer, @home, @errands",
                    index: 2,
                    isVisible: viewModel.currentPage == 1
                )

                GTDStepView(
                    icon: "arrow.clockwise",
                    title: "4. Review Regularly",
                    description: "Weekly reviews keep your system trusted and current",
                    index: 3,
                    isVisible: viewModel.currentPage == 1
                )

                GTDStepView(
                    icon: "checkmark.circle",
                    title: "5. Do With Confidence",
                    description: "Trust your system and focus on the work that matters now",
                    index: 4,
                    isVisible: viewModel.currentPage == 1
                )
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: 600)

            Spacer()
        }
        .padding()
    }

    private var featuresPage: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Powerful Features")
                    .font(.system(size: 36, weight: .bold))
                    .tracking(0.3)
                    .accessibilityAddTraits(.isHeader)

                Text("Everything you need for productivity mastery")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    FeatureCard(
                        icon: "plus.circle.fill",
                        title: "Quick Capture",
                        description: "Global hotkey (⌘⇧Space) for instant task creation",
                        color: .blue
                    )

                    FeatureCard(
                        icon: "tray.and.arrow.down",
                        title: "Inbox Processing",
                        description: "GTD-style task clarification and organization",
                        color: .orange
                    )

                    FeatureCard(
                        icon: "square.grid.2x2",
                        title: "Board Canvas",
                        description: "Freeform, Kanban, Grid, and List layouts",
                        color: .purple
                    )

                    FeatureCard(
                        icon: "sparkles",
                        title: "Smart Perspectives",
                        description: "Inbox, Today, Upcoming, Flagged, and custom views",
                        color: .pink
                    )

                    FeatureCard(
                        icon: "doc.text",
                        title: "Markdown Storage",
                        description: "Plain text files you can edit anywhere",
                        color: .green
                    )

                    FeatureCard(
                        icon: "waveform.circle",
                        title: "Siri Shortcuts",
                        description: "Voice commands for hands-free task management",
                        color: .indigo
                    )

                    FeatureCard(
                        icon: "arrow.clockwise",
                        title: "Recurring Tasks",
                        description: "Daily, weekly, monthly patterns",
                        color: .teal
                    )

                    FeatureCard(
                        icon: "list.bullet.indent",
                        title: "Subtasks",
                        description: "Break down complex tasks into steps",
                        color: .cyan
                    )

                    FeatureCard(
                        icon: "tag.fill",
                        title: "Tags & Labels",
                        description: "Flexible categorization beyond projects",
                        color: .yellow
                    )

                    FeatureCard(
                        icon: "paperclip",
                        title: "Attachments",
                        description: "Link files and documents to tasks",
                        color: .orange
                    )

                    FeatureCard(
                        icon: "timer",
                        title: "Time Tracking",
                        description: "Built-in timers for focused work",
                        color: .red
                    )

                    FeatureCard(
                        icon: "calendar.badge.plus",
                        title: "Calendar Sync",
                        description: "Two-way sync with macOS Calendar",
                        color: .blue
                    )

                    FeatureCard(
                        icon: "bell.badge",
                        title: "Notifications",
                        description: "Due date reminders and weekly review",
                        color: .orange
                    )

                    FeatureCard(
                        icon: "magnifyingglass",
                        title: "Spotlight Search",
                        description: "Find tasks from anywhere with ⌘Space",
                        color: .green
                    )

                    FeatureCard(
                        icon: "slider.horizontal.3",
                        title: "Advanced Filters",
                        description: "Powerful queries and custom perspectives",
                        color: .purple
                    )

                    FeatureCard(
                        icon: "square.and.arrow.up",
                        title: "Export & Backup",
                        description: "Archive to JSON, CSV, or Markdown",
                        color: .gray
                    )

                    FeatureCard(
                        icon: "paintbrush.fill",
                        title: "Customization",
                        description: "Themes, colors, and layout options",
                        color: .pink
                    )

                    FeatureCard(
                        icon: "keyboard",
                        title: "Keyboard Shortcuts",
                        description: "Navigate without touching the mouse",
                        color: .teal
                    )

                    FeatureCard(
                        icon: "chart.bar.fill",
                        title: "Statistics",
                        description: "Track productivity and completion trends",
                        color: .indigo
                    )

                    FeatureCard(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Weekly Review",
                        description: "GTD-style review workflow",
                        color: .cyan
                    )

                    FeatureCard(
                        icon: "doc.on.doc",
                        title: "Templates",
                        description: "Reusable task templates for common workflows",
                        color: .blue
                    )
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: 300)

            Text("And much more...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
        }
        .padding()
    }

    private var configurationPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "gearshape.2")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                .symbolEffect(.rotate, options: .repeat(3), value: viewModel.currentPage == 3)
                .symbolEffect(.pulse, options: .speed(0.5).repeat(2), value: viewModel.currentPage == 3)
                .accessibilityHidden(true)

            Text("Setup Your Workspace")
                .font(.system(size: 36, weight: .bold))
                .tracking(0.3)
                .accessibilityAddTraits(.isHeader)

            Text("Choose where your tasks will live")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 20) {
                // Storage location
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                            .font(.headline)
                        Text("Storage Location")
                            .font(.headline)
                    }
                    .accessibilityElement(children: .combine)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.dataDirectory.path)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Text("Your tasks will be stored here")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("Choose...") {
                            viewModel.chooseDataDirectory()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Choose storage location")
                        .accessibilityHint("Select a different folder for storing your tasks")
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                }

                // Sample data option
                Toggle(isOn: $viewModel.createSampleData) {
                    HStack {
                        Image(systemName: viewModel.createSampleData ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(viewModel.createSampleData ? .green : .secondary)
                            .font(.title3)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.createSampleData)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Create Sample Data")
                                .font(.headline)

                            Text("Recommended: Start with example tasks, boards, and perspectives to explore all features")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(.switch)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Create sample data")
                .accessibilityValue(viewModel.createSampleData ? "enabled" : "disabled")
                .accessibilityHint("Toggle to start with example tasks and boards")
            }
            .padding(.horizontal, 60)
            .frame(maxWidth: 600)

            Spacer()
        }
        .padding()
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 16) {
            if viewModel.currentPage > 0 {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.currentPage -= 1
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.leftArrow, modifiers: [])
                .accessibilityLabel("Back to previous page")
                .accessibilityHint("Return to the previous onboarding page")
            }

            Spacer()

            if viewModel.currentPage < 3 {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.currentPage += 1
                    }
                }) {
                    HStack(spacing: 6) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.rightArrow, modifiers: [])
                .accessibilityLabel("Next page")
                .accessibilityHint("Continue to the next onboarding page")
            } else {
                Button(action: {
                    viewModel.celebrateCompletion()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        completeOnboarding()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .symbolEffect(.pulse, options: .repeating, value: viewModel.currentPage == 3)
                        Text("Get Started")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .scaleEffect(viewModel.getStartedButtonScale)
                .shadow(color: .accentColor.opacity(0.3), radius: viewModel.getStartedButtonScale > 1.0 ? 12 : 4, x: 0, y: viewModel.getStartedButtonScale > 1.0 ? 6 : 2)
                .accessibilityLabel("Get started with StickyToDo")
                .accessibilityHint("Complete onboarding and start using the app")
            }

            if viewModel.currentPage < 3 {
                Button("Skip") {
                    completeOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("Skip onboarding")
                .accessibilityHint("Skip the rest of onboarding and start using the app")
            }
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        let config = WelcomeConfiguration(
            dataDirectory: viewModel.dataDirectory,
            createSampleData: viewModel.createSampleData
        )
        onComplete?(config)
        dismiss()
    }
}

// MARK: - Supporting Views

struct GTDStepView: View {
    let icon: String
    let title: String
    let description: String
    let index: Int
    let isVisible: Bool

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.15), .cyan.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .scaleEffect(appeared ? 1.0 : 0.5)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce, options: .nonRepeating, value: appeared)
            }
            .frame(width: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -30)
        .scaleEffect(appeared ? 1.0 : 0.95, anchor: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
        .onAppear {
            if isVisible {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(Double(index) * 0.12)) {
                    appeared = true
                }
            }
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue && !appeared {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(Double(index) * 0.12)) {
                    appeared = true
                }
            } else if !newValue {
                appeared = false
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce, options: .nonRepeating, value: isHovered)
                .symbolEffect(.pulse, options: .speed(0.5), isActive: isHovered)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .fontWeight(isHovered ? .semibold : .regular)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? color.opacity(0.08) : Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: color.opacity(isHovered ? 0.25 : 0.05),
                    radius: isHovered ? 10 : 4,
                    x: 0,
                    y: isHovered ? 5 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(isHovered ? 0.3 : 0), lineWidth: 1.5)
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

// MARK: - View Model

@MainActor
class WelcomeViewModel: ObservableObject {

    @Published var currentPage = 0
    @Published var dataDirectory: URL
    @Published var createSampleData = true

    // Animation properties
    @Published var iconScale: CGFloat = 0.5
    @Published var iconRotation: Double = -10
    @Published var iconPulse: Int = 0
    @Published var titleOpacity: Double = 0
    @Published var titleOffset: CGFloat = 20
    @Published var descriptionOpacity: Double = 0
    @Published var descriptionOffset: CGFloat = 20
    @Published var getStartedButtonScale: CGFloat = 1.0
    @Published var isCelebrating = false

    init() {
        // Default to Documents/StickyToDo
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dataDirectory = documents.appendingPathComponent("StickyToDo")
    }

    func startAnimations() {
        // Animate icon
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
            iconRotation = 0
        }

        // Pulse icon after scale animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.iconPulse += 1
        }

        // Animate title
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.2)) {
            titleOpacity = 1.0
            titleOffset = 0
        }

        // Animate description
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.4)) {
            descriptionOpacity = 1.0
            descriptionOffset = 0
        }

        // Start subtle pulse animation on "Get Started" button when on final page
        startButtonPulse()
    }

    private func startButtonPulse() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.currentPage == 3 && !self.isCelebrating {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    self.getStartedButtonScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        self.getStartedButtonScale = 1.0
                    }
                    self.startButtonPulse()
                }
            }
        }
    }

    func celebrateCompletion() {
        isCelebrating = true
        // Celebration animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            getStartedButtonScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                self.getStartedButtonScale = 1.0
            }
        }
    }

    func chooseDataDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Select where to store your StickyToDo data"

        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.dataDirectory = url
            }
        }
    }
}

// MARK: - Configuration

struct WelcomeConfiguration {
    let dataDirectory: URL
    let createSampleData: Bool
}

// MARK: - Animated Background

struct AnimatedGradientBackground: View {
    let page: Int

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 0.8), value: page)
    }

    private var gradientColors: [Color] {
        switch page {
        case 0:
            return [Color.blue.opacity(0.15), Color.purple.opacity(0.15)]
        case 1:
            return [Color.blue.opacity(0.12), Color.cyan.opacity(0.12)]
        case 2:
            return [Color.purple.opacity(0.12), Color.pink.opacity(0.12)]
        case 3:
            return [Color.purple.opacity(0.15), Color.indigo.opacity(0.15)]
        default:
            return [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView()
}
