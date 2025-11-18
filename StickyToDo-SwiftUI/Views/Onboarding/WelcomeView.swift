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

                    gtdOverviewPage
                        .tag(1)

                    featuresPage
                        .tag(2)

                    configurationPage
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Navigation buttons
                bottomBar
                    .padding()
                    .background(.ultraThinMaterial)
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .frame(width: 700, height: 550)
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

            Text("Welcome to StickyToDo")
                .font(.system(size: 36, weight: .bold))

            Text("A GTD-inspired task manager that combines the flexibility of sticky notes with the power of Getting Things Done.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            Spacer()
        }
        .padding()
    }

    private var gtdOverviewPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Getting Things Done")
                .font(.system(size: 32, weight: .bold))

            VStack(alignment: .leading, spacing: 16) {
                GTDStepView(
                    icon: "tray.and.arrow.down",
                    title: "Capture",
                    description: "Quickly capture tasks with natural language"
                )

                GTDStepView(
                    icon: "list.bullet.clipboard",
                    title: "Clarify",
                    description: "Process your inbox and organize tasks"
                )

                GTDStepView(
                    icon: "square.grid.2x2",
                    title: "Organize",
                    description: "Use contexts, projects, and boards"
                )

                GTDStepView(
                    icon: "checkmark.circle",
                    title: "Review & Do",
                    description: "Stay on top of what matters"
                )
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }

    private var featuresPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("Powerful Features")
                .font(.system(size: 32, weight: .bold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                FeatureCard(
                    icon: "square.stack.3d.up",
                    title: "Two Views",
                    description: "Switch between list and board views",
                    color: .blue
                )

                FeatureCard(
                    icon: "text.viewfinder",
                    title: "Quick Capture",
                    description: "Global hotkey for instant task creation",
                    color: .green
                )

                FeatureCard(
                    icon: "doc.text",
                    title: "Markdown Storage",
                    description: "All data stored as plain text files",
                    color: .orange
                )

                FeatureCard(
                    icon: "sparkles",
                    title: "Smart Perspectives",
                    description: "Inbox, Today, Upcoming, and more",
                    color: .purple
                )
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }

    private var configurationPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "gearshape.2")
                .font(.system(size: 80))
                .foregroundColor(.purple)

            Text("Setup Your Workspace")
                .font(.system(size: 32, weight: .bold))

            VStack(alignment: .leading, spacing: 20) {
                // Storage location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Storage Location")
                        .font(.headline)

                    HStack {
                        Text(viewModel.dataDirectory.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Button("Choose...") {
                            viewModel.chooseDataDirectory()
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Sample data option
                Toggle(isOn: $viewModel.createSampleData) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create Sample Data")
                            .font(.headline)

                        Text("Start with example tasks and boards to explore features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(.horizontal, 60)
            .frame(maxWidth: 600)

            Spacer()
        }
        .padding()
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if viewModel.currentPage > 0 {
                Button("Back") {
                    withAnimation {
                        viewModel.currentPage -= 1
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if viewModel.currentPage < 3 {
                Button("Next") {
                    withAnimation {
                        viewModel.currentPage += 1
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Get Started") {
                    completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if viewModel.currentPage < 3 {
                Button("Skip") {
                    completeOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
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

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)

            Text(title)
                .font(.headline)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - View Model

@MainActor
class WelcomeViewModel: ObservableObject {

    @Published var currentPage = 0
    @Published var dataDirectory: URL
    @Published var createSampleData = true

    init() {
        // Default to Documents/StickyToDo
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dataDirectory = documents.appendingPathComponent("StickyToDo")
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

// MARK: - Preview

#Preview {
    WelcomeView()
}
