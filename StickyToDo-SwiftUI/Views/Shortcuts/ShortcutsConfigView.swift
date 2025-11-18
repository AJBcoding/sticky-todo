//
//  ShortcutsConfigView.swift
//  StickyToDo
//
//  Configuration view for managing Siri Shortcuts and App Intents.
//

import SwiftUI

#if canImport(AppIntents)
import AppIntents
#endif

@available(iOS 16.0, macOS 13.0, *)
struct ShortcutsConfigView: View {
    @State private var selectedCategory: ShortcutCategory = .all

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Siri Shortcuts")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Use Siri to quickly access StickyToDo features")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            // Category Filter
            Picker("Category", selection: $selectedCategory) {
                ForEach(ShortcutCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Shortcuts List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredShortcuts, id: \.title) { shortcut in
                        ShortcutCardView(shortcut: shortcut)
                    }
                }
                .padding()
            }

            // Help Section
            VStack(alignment: .leading, spacing: 12) {
                Text("How to Use")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    HelpItemView(
                        icon: "mic.fill",
                        text: "Say 'Hey Siri' followed by any sample phrase"
                    )
                    HelpItemView(
                        icon: "gear",
                        text: "Manage shortcuts in Settings > Siri & Search > StickyToDo"
                    )
                    HelpItemView(
                        icon: "apps.iphone",
                        text: "Use in the Shortcuts app to create automation"
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
        }
    }

    private var filteredShortcuts: [ShortcutInfo] {
        let allShortcuts = ShortcutInfo.allShortcuts
        if selectedCategory == .all {
            return allShortcuts
        }
        return allShortcuts.filter { $0.category == selectedCategory }
    }
}

/// Shortcut information for display
struct ShortcutInfo {
    let title: String
    let description: String
    let category: ShortcutCategory
    let icon: String
    let color: Color
    let samplePhrases: [String]

    static let allShortcuts: [ShortcutInfo] = [
        ShortcutInfo(
            title: "Add Task",
            description: "Quickly capture a new task",
            category: .tasks,
            icon: "plus.circle.fill",
            color: .blue,
            samplePhrases: [
                "Add a task",
                "Create 'Buy groceries'",
                "Quick capture"
            ]
        ),
        ShortcutInfo(
            title: "Complete Task",
            description: "Mark a task as done",
            category: .tasks,
            icon: "checkmark.circle.fill",
            color: .green,
            samplePhrases: [
                "Complete a task",
                "Mark 'Write report' as done",
                "Finish task"
            ]
        ),
        ShortcutInfo(
            title: "Show Inbox",
            description: "View unprocessed tasks",
            category: .navigation,
            icon: "tray.fill",
            color: .purple,
            samplePhrases: [
                "Show my inbox",
                "What's in my inbox",
                "Open inbox"
            ]
        ),
        ShortcutInfo(
            title: "Show Next Actions",
            description: "View actionable tasks",
            category: .navigation,
            icon: "star.circle.fill",
            color: .orange,
            samplePhrases: [
                "Show my next actions",
                "What should I do next",
                "Show actionable tasks"
            ]
        ),
        ShortcutInfo(
            title: "Show Today's Tasks",
            description: "View tasks due today",
            category: .navigation,
            icon: "calendar",
            color: .red,
            samplePhrases: [
                "Show today's tasks",
                "What's due today",
                "What do I need to do today"
            ]
        ),
        ShortcutInfo(
            title: "Start Timer",
            description: "Begin tracking time for a task",
            category: .timeTracking,
            icon: "timer",
            color: .green,
            samplePhrases: [
                "Start timer",
                "Track time for 'Design mockups'",
                "Start tracking time"
            ]
        ),
        ShortcutInfo(
            title: "Stop Timer",
            description: "Stop the running timer",
            category: .timeTracking,
            icon: "timer.square",
            color: .gray,
            samplePhrases: [
                "Stop timer",
                "Stop tracking time",
                "End timer"
            ]
        ),
        ShortcutInfo(
            title: "Flag Task",
            description: "Mark a task as important",
            category: .tasks,
            icon: "flag.fill",
            color: .orange,
            samplePhrases: [
                "Flag a task",
                "Mark task as important",
                "Star 'Design mockups'"
            ]
        ),
        ShortcutInfo(
            title: "Show Flagged Tasks",
            description: "View all flagged tasks",
            category: .navigation,
            icon: "flag.circle.fill",
            color: .orange,
            samplePhrases: [
                "Show flagged tasks",
                "What's important",
                "Show my starred tasks"
            ]
        ),
        ShortcutInfo(
            title: "Weekly Review",
            description: "Open your weekly review",
            category: .planning,
            icon: "calendar.badge.checkmark",
            color: .purple,
            samplePhrases: [
                "Show weekly review",
                "Start my weekly review",
                "Show weekly summary"
            ]
        ),
        ShortcutInfo(
            title: "Add to Project",
            description: "Add a task to a specific project",
            category: .tasks,
            icon: "folder.badge.plus",
            color: .blue,
            samplePhrases: [
                "Add task to project",
                "Add 'Finish docs' to Work",
                "Create task in Home"
            ]
        )
    ]
}

/// Category enumeration
enum ShortcutCategory: String, CaseIterable {
    case all = "All"
    case tasks = "Tasks"
    case navigation = "Navigation"
    case timeTracking = "Time Tracking"
    case planning = "Planning"

    var displayName: String {
        return self.rawValue
    }
}

/// Card view for each shortcut
struct ShortcutCardView: View {
    let shortcut: ShortcutInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: shortcut.icon)
                    .font(.title2)
                    .foregroundColor(shortcut.color)
                    .frame(width: 44, height: 44)
                    .background(shortcut.color.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading) {
                    Text(shortcut.title)
                        .font(.headline)
                    Text(shortcut.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Sample Phrases
            VStack(alignment: .leading, spacing: 6) {
                Text("Sample Phrases")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ForEach(shortcut.samplePhrases, id: \.self) { phrase in
                    HStack {
                        Image(systemName: "mic.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\"Hey Siri, \(phrase)\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/// Help item view
struct HelpItemView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// Preview
@available(iOS 16.0, macOS 13.0, *)
struct ShortcutsConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutsConfigView()
    }
}
