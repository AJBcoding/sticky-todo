//
//  TaskHistoryView.swift
//  StickyToDo
//
//  Detailed history view for a specific task.
//  Shows all changes made to a task over time.
//

import SwiftUI

/// View showing the complete history of a specific task
struct TaskHistoryView: View {
    let task: Task
    @ObservedObject var activityLogManager: ActivityLogManager

    @State private var selectedChangeType: ActivityLog.ChangeType?
    @State private var showingExportSheet = false
    @State private var exportFormat: ExportFormat = .csv

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Task header
            taskHeaderView

            Divider()

            // Filter section
            filterSection

            Divider()

            // History list
            if taskLogs.isEmpty {
                emptyStateView
            } else {
                historyListView
            }
        }
        .navigationTitle("Task History")
        .toolbar {
            ToolbarItemGroup {
                Button(action: { showingExportSheet = true }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            exportSheet
        }
    }

    // MARK: - Task Header

    private var taskHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                // Status badge
                Text(task.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)

                // Priority badge
                Text(task.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .cornerRadius(4)

                // Project
                if let project = task.project {
                    Label(project, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Total changes count
                Text("\(taskLogs.count) changes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        HStack {
            Picker("Filter", selection: $selectedChangeType) {
                Text("All Changes").tag(nil as ActivityLog.ChangeType?)
                ForEach(ActivityLog.ChangeType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type as ActivityLog.ChangeType?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 200)

            Spacer()

            Text("\(filteredTaskLogs.count) entries")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - History List

    private var historyListView: some View {
        List {
            ForEach(filteredTaskLogs) { log in
                TaskHistoryRow(log: log)
                    .contextMenu {
                        contextMenu(for: log)
                    }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No History")
                .font(.title2)
                .fontWeight(.medium)

            Text("No activity logs found for this task.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Export Sheet

    private var exportSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                Text("Export \(filteredTaskLogs.count) log entries for '\(task.title)'")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                HStack {
                    Button("Cancel") {
                        showingExportSheet = false
                    }

                    Spacer()

                    Button("Export") {
                        exportLogs()
                        showingExportSheet = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
            .navigationTitle("Export Task History")
            .frame(width: 400, height: 200)
        }
    }

    // MARK: - Context Menu

    private func contextMenu(for log: ActivityLog) -> some View {
        Button(action: {
            copyToClipboard(log: log)
        }) {
            Label("Copy Details", systemImage: "doc.on.doc")
        }
    }

    // MARK: - Computed Properties

    private var taskLogs: [ActivityLog] {
        activityLogManager.logs(forTask: task.id)
    }

    private var filteredTaskLogs: [ActivityLog] {
        if let changeType = selectedChangeType {
            return taskLogs.filter { $0.changeType == changeType }
        }
        return taskLogs
    }

    private var statusColor: Color {
        switch task.status {
        case .completed:
            return .green
        case .nextAction:
            return .blue
        case .inbox:
            return .gray
        default:
            return .orange
        }
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        case .none:
            return .gray
        }
    }

    // MARK: - Actions

    private func exportLogs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = exportFormat == .csv ? [.commaSeparatedText] : [.json]
        panel.nameFieldStringValue = "task-history-\(task.id.uuidString.prefix(8)).\(exportFormat.rawValue.lowercased())"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            do {
                if exportFormat == .csv {
                    try activityLogManager.exportToCSVFile(url: url, logs: filteredTaskLogs)
                } else {
                    try activityLogManager.exportToJSONFile(url: url, logs: filteredTaskLogs)
                }
            } catch {
                print("Export failed: \(error)")
            }
        }
    }

    private func copyToClipboard(log: ActivityLog) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(log.fullDescription, forType: .string)
    }
}

// MARK: - Task History Row

struct TaskHistoryRow: View {
    let log: ActivityLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 12, height: 12)

                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 2)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Change type
                HStack {
                    Image(systemName: log.changeType.icon)
                        .foregroundColor(iconColor)

                    Text(log.changeType.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                }

                // Change details
                if let beforeValue = log.beforeValue, let afterValue = log.afterValue {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Before")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(beforeValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(6)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                        }

                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("After")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(afterValue)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                } else if let afterValue = log.afterValue {
                    Text(afterValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                } else if let beforeValue = log.beforeValue {
                    Text(beforeValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                }

                // Timestamp
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)

                    Text(log.formattedTimestamp)
                        .font(.caption2)

                    Text("(\(log.relativeTimestamp))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var iconColor: Color {
        switch log.changeType {
        case .created:
            return .green
        case .deleted:
            return .red
        case .completed:
            return .green
        case .uncompleted:
            return .orange
        case .flagged:
            return .orange
        case .priorityChanged:
            return .yellow
        case .statusChanged:
            return .blue
        case .dueDateChanged:
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TaskHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let fileIO = MarkdownFileIO(
            rootDirectory: URL(fileURLWithPath: "/tmp/stickytodo-preview")
        )
        let activityLogManager = ActivityLogManager(fileIO: fileIO)
        let task = Task(title: "Sample Task", status: .nextAction, priority: .high)

        return NavigationView {
            TaskHistoryView(
                task: task,
                activityLogManager: activityLogManager
            )
        }
    }
}
#endif
