//
//  QuickTourView.swift
//  StickyToDo-SwiftUI
//
//  Interactive quick tour showcasing key features.
//  Highlights 5-7 essential features with progressive disclosure.
//

import SwiftUI

/// Quick tour view highlighting key features
struct QuickTourView: View {

    @StateObject private var viewModel = QuickTourViewModel()
    @Environment(\.dismiss) private var dismiss

    var onComplete: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Content
            TabView(selection: $viewModel.currentPage) {
                ForEach(TourPage.allPages, id: \.id) { page in
                    tourPageView(for: page)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Bottom navigation
            bottomBar
                .padding()
                .background(.ultraThinMaterial)
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(width: 700, height: 550)
        .overlay(alignment: .top) {
            progressIndicator
                .padding(.top, 20)
        }
        .overlay(alignment: .topTrailing) {
            skipButton
                .padding()
        }
    }

    // MARK: - Tour Page View

    @ViewBuilder
    private func tourPageView(for page: TourPage) -> some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: page.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: page.gradientColors.first?.opacity(0.3) ?? .clear, radius: 20, x: 0, y: 10)
                .symbolEffect(.bounce, value: viewModel.currentPage == page.id)

            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold))

            // Description
            Text(page.description)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            // Feature highlights
            VStack(alignment: .leading, spacing: 12) {
                ForEach(page.highlights, id: \.self) { highlight in
                    TourHighlight(text: highlight)
                }
            }
            .padding(.horizontal, 60)

            // Keyboard shortcut (if applicable)
            if let shortcut = page.keyboardShortcut {
                KeyboardShortcutBadge(shortcut: shortcut)
            }

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

            if viewModel.currentPage < TourPage.allPages.count - 1 {
                Button("Next") {
                    withAnimation {
                        viewModel.currentPage += 1
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Get Started") {
                    viewModel.complete()
                    onComplete?()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<TourPage.allPages.count, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.spring(), value: viewModel.currentPage)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button("Skip Tour") {
            viewModel.complete()
            onComplete?()
            dismiss()
        }
        .buttonStyle(.plain)
        .foregroundColor(.secondary)
        .font(.callout)
    }
}

// MARK: - Supporting Views

struct TourHighlight: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

struct KeyboardShortcutBadge: View {
    let shortcut: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "keyboard")
                .foregroundColor(.secondary)

            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .bold()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - View Model

@MainActor
class QuickTourViewModel: ObservableObject {

    @Published var currentPage: Int = 0

    func complete() {
        OnboardingManager.shared.markQuickTourViewed()
    }
}

// MARK: - Tour Page Model

struct TourPage: Identifiable {
    let id: Int
    let icon: String
    let gradientColors: [Color]
    let title: String
    let description: String
    let highlights: [String]
    let keyboardShortcut: String?

    static let allPages: [TourPage] = [
        TourPage(
            id: 0,
            icon: "plus.circle.fill",
            gradientColors: [.blue, .cyan],
            title: "Quick Capture",
            description: "Capture tasks instantly from anywhere on your Mac",
            highlights: [
                "Use ⌘N or the global hotkey to create tasks",
                "Natural language parsing: \"Call John tomorrow @phone\"",
                "Tasks land in Inbox for later processing",
                "Capture first, organize later - true GTD workflow"
            ],
            keyboardShortcut: "⌘N or ⌘⇧Space"
        ),

        TourPage(
            id: 1,
            icon: "tray.and.arrow.down",
            gradientColors: [.orange, .red],
            title: "Inbox Processing",
            description: "Turn captured items into actionable tasks",
            highlights: [
                "Process inbox items one by one",
                "Clarify: Is it actionable?",
                "Organize: Add context, project, due date",
                "Move to Next Actions, Waiting, or Someday/Maybe",
                "Archive or delete what's not needed"
            ],
            keyboardShortcut: nil
        ),

        TourPage(
            id: 2,
            icon: "square.grid.2x2",
            gradientColors: [.purple, .pink],
            title: "Board Canvas",
            description: "Visualize tasks with flexible board layouts",
            highlights: [
                "Switch between List, Kanban, Grid, and Freeform layouts",
                "Drag and drop tasks to organize visually",
                "Context boards (@computer, @home, @office)",
                "Project boards with automatic organization",
                "Create custom boards for any workflow"
            ],
            keyboardShortcut: "⌘B"
        ),

        TourPage(
            id: 3,
            icon: "waveform.circle",
            gradientColors: [.purple, .indigo],
            title: "Siri Shortcuts",
            description: "Control tasks with your voice",
            highlights: [
                "\"Add task: Buy groceries\"",
                "\"Show my tasks for today\"",
                "\"What's due this week?\"",
                "\"Complete task: Finish report\"",
                "Works on Mac, iPhone, iPad, and Apple Watch"
            ],
            keyboardShortcut: nil
        ),

        TourPage(
            id: 4,
            icon: "sparkles",
            gradientColors: [.yellow, .orange],
            title: "Smart Perspectives",
            description: "Powerful filtered views of your tasks",
            highlights: [
                "Inbox: Unprocessed items",
                "Today: Due today or flagged",
                "Upcoming: Next 7 days",
                "Flagged: Starred for attention",
                "Custom perspectives with advanced filters"
            ],
            keyboardShortcut: "⌘1-9"
        ),

        TourPage(
            id: 5,
            icon: "magnifyingglass",
            gradientColors: [.green, .mint],
            title: "Search & Spotlight",
            description: "Find any task instantly",
            highlights: [
                "Full-text search across all tasks",
                "Search by title, notes, project, context, tags",
                "Spotlight integration: ⌘Space to search from anywhere",
                "Filter by status, priority, due date, and more",
                "Save searches as custom perspectives"
            ],
            keyboardShortcut: "⌘F"
        ),

        TourPage(
            id: 6,
            icon: "doc.text",
            gradientColors: [.blue, .teal],
            title: "Plain Text Storage",
            description: "Your data stays yours, forever",
            highlights: [
                "Tasks stored as Markdown files",
                "Edit in any text editor",
                "Version control with Git",
                "Easy backup and sync",
                "No vendor lock-in, no cloud dependency"
            ],
            keyboardShortcut: nil
        )
    ]
}

// MARK: - Preview

#Preview {
    QuickTourView()
}
