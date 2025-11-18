//
//  AddToSiriButton.swift
//  StickyToDo
//
//  Reusable button component for adding shortcuts to Siri.
//

import SwiftUI

#if canImport(AppIntents)
import AppIntents
import IntentsUI
#endif

/// Button to add a shortcut to Siri
@available(iOS 16.0, macOS 13.0, *)
struct AddToSiriButton: View {
    let shortcut: AppShortcut
    let style: ButtonStyle

    enum ButtonStyle {
        case compact
        case full
    }

    var body: some View {
        #if os(iOS)
        Button(action: {
            // Present Siri shortcut configuration
            presentSiriShortcut()
        }) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.white)
                if style == .full {
                    Text("Add to Siri")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, style == .compact ? 12 : 20)
            .padding(.vertical, style == .compact ? 8 : 12)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(style == .compact ? 8 : 12)
        }
        .buttonStyle(.plain)
        #else
        // macOS doesn't support Add to Siri button
        EmptyView()
        #endif
    }

    private func presentSiriShortcut() {
        #if os(iOS)
        // Request Siri authorization if needed
        INPreferences.requestSiriAuthorization { status in
            if status == .authorized {
                // Present the shortcut UI
                // Note: This requires iOS-specific implementation
            }
        }
        #endif
    }
}

/// Standalone Add to Siri card
@available(iOS 16.0, macOS 13.0, *)
struct SiriShortcutCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/// Inline Siri suggestion banner
@available(iOS 16.0, macOS 13.0, *)
struct SiriSuggestionBanner: View {
    let phrase: String
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "mic.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Siri Suggestion")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text("Say \"\(phrase)\"")
                    .font(.subheadline)
            }

            Spacer()

            Button("Try It") {
                action()
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Previews

@available(iOS 16.0, macOS 13.0, *)
struct AddToSiriButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AddToSiriButton(
                shortcut: AppShortcut(
                    intent: AddTaskIntent(),
                    phrases: ["Add a task"],
                    shortTitle: "Add Task",
                    systemImageName: "plus.circle"
                ),
                style: .full
            )

            AddToSiriButton(
                shortcut: AppShortcut(
                    intent: AddTaskIntent(),
                    phrases: ["Add a task"],
                    shortTitle: "Add Task",
                    systemImageName: "plus.circle"
                ),
                style: .compact
            )

            SiriShortcutCard(
                title: "Add Task",
                description: "Quickly capture a new task",
                icon: "plus.circle.fill",
                color: .blue
            )

            SiriSuggestionBanner(
                phrase: "Hey Siri, show my inbox",
                action: {}
            )
        }
        .padding()
    }
}
