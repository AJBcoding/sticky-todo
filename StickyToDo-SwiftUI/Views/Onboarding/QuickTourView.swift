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
                .symbolEffect(.bounce, options: .nonRepeating, value: viewModel.currentPage == page.id)
                .symbolEffect(.pulse, options: .speed(0.5).repeat(2), value: viewModel.currentPage == page.id)
                .scaleEffect(viewModel.currentPage == page.id ? 1.0 : 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: viewModel.currentPage)
                .accessibilityHidden(true)

            // Title
            Text(page.title)
                .font(.system(size: 34, weight: .bold))
                .tracking(0.3)
                .opacity(viewModel.currentPage == page.id ? 1 : 0.5)
                .scaleEffect(viewModel.currentPage == page.id ? 1.0 : 0.95)
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: viewModel.currentPage)
                .accessibilityAddTraits(.isHeader)

            // Description
            Text(page.description)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
                .opacity(viewModel.currentPage == page.id ? 1 : 0.5)
                .offset(y: viewModel.currentPage == page.id ? 0 : 10)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: viewModel.currentPage)

            // Feature highlights
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(page.highlights.enumerated()), id: \.offset) { index, highlight in
                    TourHighlight(
                        text: highlight,
                        index: index,
                        isVisible: viewModel.currentPage == page.id
                    )
                }
            }
            .padding(.horizontal, 60)

            // Keyboard shortcut (if applicable)
            if let shortcut = page.keyboardShortcut {
                KeyboardShortcutBadge(
                    shortcut: shortcut,
                    isVisible: viewModel.currentPage == page.id
                )
            }

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
            }

            Spacer()

            if viewModel.currentPage < TourPage.allPages.count - 1 {
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
            } else {
                Button(action: {
                    viewModel.complete()
                    onComplete?()
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Start Using StickyToDo")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<TourPage.allPages.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(index == viewModel.currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: index == viewModel.currentPage ? 24 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.currentPage)
                    .shadow(
                        color: index == viewModel.currentPage ? Color.accentColor.opacity(0.3) : .clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

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
    let index: Int
    let isVisible: Bool

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .font(.title3)
                .symbolEffect(.bounce, options: .nonRepeating, value: appeared)
                .accessibilityHidden(true)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -15)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
        .onAppear {
            if isVisible {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.08)) {
                    appeared = true
                }
            }
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue && !appeared {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.08)) {
                    appeared = true
                }
            } else if !newValue {
                withAnimation(.easeOut(duration: 0.2)) {
                    appeared = false
                }
            }
        }
    }
}

struct KeyboardShortcutBadge: View {
    let shortcut: String
    let isVisible: Bool

    @State private var appeared = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "keyboard")
                .foregroundColor(.secondary)
                .symbolEffect(.wiggle, options: .repeat(1), value: appeared)

            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .bold()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .accentColor.opacity(isHovered ? 0.2 : 0.05),
                    radius: isHovered ? 6 : 3,
                    x: 0,
                    y: isHovered ? 3 : 1
                )
        )
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("Keyboard shortcut: \(shortcut)")
        .onAppear {
            if isVisible {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                    appeared = true
                }
            }
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue && !appeared {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                    appeared = true
                }
            } else if !newValue {
                withAnimation(.easeOut(duration: 0.2)) {
                    appeared = false
                }
            }
        }
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
            title: "Lightning-Fast Capture",
            description: "Never lose a thought again - capture tasks instantly from anywhere",
            highlights: [
                "Global hotkey works even when the app isn't open",
                "Smart parsing: \"Call dentist tomorrow @phone\" becomes a complete task",
                "Everything goes to Inbox - organize later when you're ready",
                "Friction-free capture means your brain can relax"
            ],
            keyboardShortcut: "⌘N or ⌘⇧Space"
        ),

        TourPage(
            id: 1,
            icon: "tray.and.arrow.down",
            gradientColors: [.orange, .red],
            title: "Inbox Zero Made Easy",
            description: "Transform captured thoughts into organized, actionable tasks",
            highlights: [
                "Process one item at a time without overwhelm",
                "Ask: Is it actionable? What's the next action?",
                "Add context (@computer), project, and due dates",
                "Move to Next Actions, Waiting, or Someday/Maybe",
                "Achieve clarity and peace of mind daily"
            ],
            keyboardShortcut: nil
        ),

        TourPage(
            id: 2,
            icon: "square.grid.2x2",
            gradientColors: [.purple, .pink],
            title: "Visual Board Canvas",
            description: "See your work in the way that makes sense to you",
            highlights: [
                "Four layouts: List, Kanban, Grid, and Freeform sticky notes",
                "Drag and drop tasks for satisfying visual organization",
                "Create boards by context: @computer, @home, @errands",
                "Project boards automatically gather related tasks",
                "Your workspace adapts to your thinking style"
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
