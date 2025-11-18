//
//  ActivityLogView.swift
//  StickyToDo
//
//  Comprehensive activity log view with filtering, search, and export.
//  Shows all task changes in chronological order.
//

import SwiftUI

/// Main activity log view
struct ActivityLogView: View {
    @ObservedObject var activityLogManager: ActivityLogManager
    @ObservedObject var taskStore: TaskStore

    @State private var searchQuery: String = ""
    @State private var selectedChangeType: ActivityLog.ChangeType?
    @State private var selectedTaskId: UUID?
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var groupingMode: GroupingMode = .date
    @State private var showingExportSheet = false
    @State private var exportFormat: ExportFormat = .csv

    enum GroupingMode: String, CaseIterable {
        case none = "None"
        case date = "By Date"
        case task = "By Task"
    }

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filters section
                filterSection

                Divider()

                // Log entries
                if filteredLogs.isEmpty {
                    emptyStateView
                } else {
                    logListView
                }
            }
            .navigationTitle("Activity Log")
            .toolbar {
                ToolbarItemGroup {
                    // Export button
                    Button(action: { showingExportSheet = true }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    // Refresh button
                    Button(action: refreshLogs) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                exportSheet
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search activity logs...", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            // Filter controls
            HStack(spacing: 12) {
                // Change type picker
                Picker("Type", selection: $selectedChangeType) {
                    Text("All Types").tag(nil as ActivityLog.ChangeType?)
                    ForEach(ActivityLog.ChangeType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type as ActivityLog.ChangeType?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 200)

                // Grouping mode picker
                Picker("Group", selection: $groupingMode) {
                    ForEach(GroupingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 250)

                Spacer()

                // Stats
                Text("\(filteredLogs.count) entries")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal)

            // Date range filters
            HStack {
                DatePicker("From", selection: Binding(
                    get: { startDate ?? Date.distantPast },
                    set: { startDate = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .disabled(startDate == nil)

                Toggle("", isOn: Binding(
                    get: { startDate != nil },
                    set: { startDate = $0 ? Date() : nil }
                ))

                Spacer()

                DatePicker("To", selection: Binding(
                    get: { endDate ?? Date() },
                    set: { endDate = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .disabled(endDate == nil)

                Toggle("", isOn: Binding(
                    get: { endDate != nil },
                    set: { endDate = $0 ? Date() : nil }
                ))
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Log List View

    private var logListView: some View {
        Group {
            if groupingMode == .none {
                ungroupedListView
            } else if groupingMode == .date {
                dateGroupedListView
            } else {
                taskGroupedListView
            }
        }
    }

    private var ungroupedListView: some View {
        List {
            ForEach(filteredLogs) { log in
                ActivityLogRow(log: log, taskStore: taskStore)
                    .contextMenu {
                        contextMenu(for: log)
                    }
            }
        }
    }

    private var dateGroupedListView: some View {
        List {
            ForEach(groupedByDateKeys, id: \.self) { dateKey in
                Section(header: Text(dateKey).font(.headline)) {
                    ForEach(groupedByDate[dateKey] ?? []) { log in
                        ActivityLogRow(log: log, taskStore: taskStore)
                            .contextMenu {
                                contextMenu(for: log)
                            }
                    }
                }
            }
        }
    }

    private var taskGroupedListView: some View {
        List {
            ForEach(groupedByTaskKeys, id: \.self) { taskId in
                if let taskTitle = groupedByTask[taskId]?.first?.taskTitle {
                    Section(header: Text(taskTitle).font(.headline)) {
                        ForEach(groupedByTask[taskId] ?? []) { log in
                            ActivityLogRow(log: log, taskStore: taskStore)
                                .contextMenu {
                                    contextMenu(for: log)
                                }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Activity Logs")
                .font(.title2)
                .fontWeight(.medium)

            Text("Activity logs will appear here as you work with tasks.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
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

                Text("Export \(filteredLogs.count) log entries")
                    .font(.caption)
                    .foregroundColor(.secondary)

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
            .navigationTitle("Export Activity Log")
            .frame(width: 400, height: 200)
        }
    }

    // MARK: - Context Menu

    private func contextMenu(for log: ActivityLog) -> some View {
        Group {
            Button(action: {
                selectedTaskId = log.taskId
            }) {
                Label("Show Task History", systemImage: "clock")
            }

            Button(action: {
                copyToClipboard(log: log)
            }) {
                Label("Copy Details", systemImage: "doc.on.doc")
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredLogs: [ActivityLog] {
        activityLogManager.filteredLogs(
            taskId: selectedTaskId,
            changeType: selectedChangeType,
            startDate: startDate,
            endDate: endDate,
            searchQuery: searchQuery.isEmpty ? nil : searchQuery
        )
    }

    private var groupedByDate: [String: [ActivityLog]] {
        activityLogManager.groupedByDate(
            taskId: selectedTaskId,
            changeType: selectedChangeType,
            startDate: startDate,
            endDate: endDate,
            searchQuery: searchQuery.isEmpty ? nil : searchQuery
        )
    }

    private var groupedByDateKeys: [String] {
        groupedByDate.keys.sorted(by: >)
    }

    private var groupedByTask: [UUID: [ActivityLog]] {
        Dictionary(grouping: filteredLogs) { $0.taskId }
    }

    private var groupedByTaskKeys: [UUID] {
        groupedByTask.keys.sorted { id1, id2 in
            guard let title1 = groupedByTask[id1]?.first?.taskTitle,
                  let title2 = groupedByTask[id2]?.first?.taskTitle else {
                return false
            }
            return title1 < title2
        }
    }

    // MARK: - Actions

    private func refreshLogs() {
        Task {
            try? await activityLogManager.loadAllAsync()
        }
    }

    private func exportLogs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = exportFormat == .csv ? [.commaSeparatedText] : [.json]
        panel.nameFieldStringValue = "activity-log.\(exportFormat.rawValue.lowercased())"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            do {
                if exportFormat == .csv {
                    try activityLogManager.exportToCSVFile(url: url, logs: filteredLogs)
                } else {
                    try activityLogManager.exportToJSONFile(url: url, logs: filteredLogs)
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

// MARK: - Activity Log Row

struct ActivityLogRow: View {
    let log: ActivityLog
    let taskStore: TaskStore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: log.changeType.icon)
                .foregroundColor(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                // Task title and change type
                HStack {
                    Text(log.taskTitle)
                        .font(.body)
                        .fontWeight(.medium)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(log.changeType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Change details
                if let beforeValue = log.beforeValue, let afterValue = log.afterValue {
                    HStack {
                        Text(beforeValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .strikethrough()

                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(afterValue)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else if let afterValue = log.afterValue {
                    Text(afterValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Timestamp
                Text(log.relativeTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Task status indicator
            if let task = taskStore.task(withID: log.taskId) {
                Circle()
                    .fill(task.status == .completed ? Color.green : Color.blue)
                    .frame(width: 8, height: 8)
            }
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
        default:
            return .blue
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ActivityLogView_Previews: PreviewProvider {
    static var previews: some View {
        let fileIO = MarkdownFileIO(
            rootDirectory: URL(fileURLWithPath: "/tmp/stickytodo-preview")
        )
        let activityLogManager = ActivityLogManager(fileIO: fileIO)
        let taskStore = TaskStore(fileIO: fileIO)

        return ActivityLogView(
            activityLogManager: activityLogManager,
            taskStore: taskStore
        )
    }
}
#endif
