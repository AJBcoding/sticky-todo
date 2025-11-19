//
//  ConflictBadge.swift
//  StickyToDo-SwiftUI
//
//  Badge component for displaying file conflict notifications in the toolbar.
//

import SwiftUI

/// Badge that displays the number of active file conflicts
struct ConflictBadge: View {
    @ObservedObject var dataManager: DataManager
    @Binding var showingConflictResolution: Bool

    var body: some View {
        if dataManager.pendingConflicts.count > 0 {
            Button {
                showingConflictResolution = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("\(dataManager.pendingConflicts.count)")
                        .font(.caption)
                        .fontWeight(.semibold)

                    if dataManager.pendingConflicts.count == 1 {
                        Text("conflict")
                            .font(.caption)
                    } else {
                        Text("conflicts")
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(dataManager.pendingConflicts.count) file conflicts")
            .accessibilityHint("Tap to resolve file conflicts")
            .help("File conflicts detected - click to resolve")
        }
    }
}

/// Compact icon-only version for minimal toolbars
struct ConflictBadgeCompact: View {
    @ObservedObject var dataManager: DataManager
    @Binding var showingConflictResolution: Bool

    var body: some View {
        if dataManager.pendingConflicts.count > 0 {
            Button {
                showingConflictResolution = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)

                    // Badge with count
                    Text("\(dataManager.pendingConflicts.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(dataManager.pendingConflicts.count) file conflicts")
            .accessibilityHint("Tap to resolve file conflicts")
            .help("File conflicts detected - click to resolve")
        }
    }
}

/// Status bar item showing conflict count
struct ConflictStatusItem: View {
    @ObservedObject var dataManager: DataManager
    @Binding var showingConflictResolution: Bool

    var body: some View {
        if dataManager.pendingConflicts.count > 0 {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .imageScale(.small)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(dataManager.pendingConflicts.count) File Conflicts")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text("Click to resolve")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Button("Resolve") {
                    showingConflictResolution = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(dataManager.pendingConflicts.count) file conflicts")
            .accessibilityHint("Tap resolve button to open conflict resolution")
        }
    }
}

// MARK: - Preview

#Preview("Conflict Badge") {
    struct PreviewWrapper: View {
        @State private var showingConflictResolution = false
        @StateObject private var dataManager: DataManager = {
            let manager = DataManager.shared
            // Simulate conflicts for preview
            return manager
        }()

        var body: some View {
            VStack(spacing: 20) {
                ConflictBadge(
                    dataManager: dataManager,
                    showingConflictResolution: $showingConflictResolution
                )

                ConflictBadgeCompact(
                    dataManager: dataManager,
                    showingConflictResolution: $showingConflictResolution
                )

                ConflictStatusItem(
                    dataManager: dataManager,
                    showingConflictResolution: $showingConflictResolution
                )
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
