//
//  SearchBar.swift
//  StickyToDo
//
//  Search bar with recent searches and operator support.
//

import SwiftUI
import Combine

/// Search bar with autocomplete and recent searches
struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool

    let onSearch: (String) -> Void
    let onClear: () -> Void

    @State private var showingRecents: Bool = false
    @State private var recentSearches: [String] = []
    @FocusState private var isFocused: Bool

    // Debouncing
    @State private var searchDebouncer = PassthroughSubject<String, Never>()
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Search icon
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                // Search field
                TextField("Search tasks (try: AND, OR, NOT, \"exact phrase\")", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        performSearch()
                    }
                    .accessibilityLabel("Search tasks")
                    .accessibilityHint("Type to search tasks. Supports AND, OR, NOT operators and exact phrase matching with quotes")
                    .onChange(of: searchText) { newValue in
                        if newValue.isEmpty {
                            isSearching = false
                            onClear()
                        } else {
                            // Debounce search - send to debouncer instead of searching immediately
                            searchDebouncer.send(newValue)
                        }
                    }

                // Clear button
                if !searchText.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                    .accessibilityHint("Double-tap to clear search text")
                }

                // Search button
                Button(action: performSearch) {
                    Text("Search")
                        .fontWeight(.medium)
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(searchText.isEmpty)
                .accessibilityLabel("Perform search")
                .accessibilityHint("Double-tap to search for tasks matching your query")

                // Recent searches button
                Button(action: { showingRecents.toggle() }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Recent searches")
                .accessibilityLabel("Recent searches")
                .accessibilityHint("Double-tap to view and select from recent searches")
            }
            .padding(8)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)

            // Recent searches popover
            if showingRecents && !recentSearches.isEmpty {
                recentSearchesView
            }

            // Search tips
            if isFocused && searchText.isEmpty {
                searchTipsView
            }
        }
        .onAppear {
            loadRecentSearches()
            setupDebouncer()
        }
    }

    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Searches")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button(action: {
                    SearchManager.clearRecentSearches()
                    recentSearches = []
                }) {
                    Text("Clear")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear recent searches")
                .accessibilityHint("Double-tap to delete all recent search history")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(recentSearches.prefix(10), id: \.self) { query in
                        Button(action: {
                            searchText = query
                            showingRecents = false
                            performSearch()
                        }) {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .accessibilityHidden(true)

                                Text(query)
                                    .font(.body)
                                    .lineLimit(1)

                                Spacer()

                                Image(systemName: "arrow.up.backward")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .accessibilityHidden(true)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Search for: \(query)")
                        .accessibilityHint("Double-tap to search for \(query)")
                        .background(
                            Color(.controlBackgroundColor)
                                .opacity(0)
                        )
                        .onHover { isHovered in
                            if isHovered {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }

                        if query != recentSearches.prefix(10).last {
                            Divider()
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(.vertical, 4)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding(.top, 4)
    }

    private var searchTipsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Search Tips:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 2) {
                SearchTipRow(
                    operator: "AND",
                    description: "Both terms must match",
                    example: "bug AND urgent"
                )

                SearchTipRow(
                    operator: "OR",
                    description: "Either term can match",
                    example: "feature OR enhancement"
                )

                SearchTipRow(
                    operator: "NOT",
                    description: "Exclude term",
                    example: "project NOT archived"
                )

                SearchTipRow(
                    operator: "\"...\"",
                    description: "Exact phrase",
                    example: "\"weekly review\""
                )
            }
            .accessibilityElement(children: .contain)
        }
        .padding(8)
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .padding(.top, 4)
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        isSearching = true
        SearchManager.saveRecentSearch(searchText)
        loadRecentSearches()
        onSearch(searchText)
        showingRecents = false
    }

    private func clearSearch() {
        searchText = ""
        isSearching = false
        onClear()
        showingRecents = false
    }

    private func loadRecentSearches() {
        recentSearches = SearchManager.getRecentSearches()
    }

    private func setupDebouncer() {
        // Debounce search queries by 300ms to avoid too many searches
        searchDebouncer
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { query in
                isSearching = true
                onSearch(query)
            }
            .store(in: &cancellables)
    }
}

/// Row showing a search tip
struct SearchTipRow: View {
    let `operator`: String
    let description: String
    let example: String

    var body: some View {
        HStack(spacing: 4) {
            Text(`operator`)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue)
                .cornerRadius(3)

            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("•")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(example)
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search operator \(`operator`): \(description). Example: \(example)")
    }
}

// MARK: - Main Search View

/// Complete search view with bar and results
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss

    let tasks: [Task]
    let onSelectTask: (Task) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(
                searchText: $viewModel.searchText,
                isSearching: $viewModel.isSearching,
                onSearch: { query in
                    viewModel.performSearch(tasks: tasks, query: query)
                },
                onClear: {
                    viewModel.clearResults()
                }
            )
            .padding()

            Divider()

            // Results
            SearchResultsView(
                results: viewModel.results,
                query: viewModel.searchText,
                onSelectTask: { task in
                    onSelectTask(task)
                    dismiss()
                }
            )
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle("Search Tasks")
    }
}

/// View model for search functionality
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var results: [SearchResult] = []

    func performSearch(tasks: [Task], query: String) {
        results = SearchManager.search(tasks: tasks, queryString: query)
    }

    func clearResults() {
        results = []
        isSearching = false
    }
}

// MARK: - Preview

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(
            searchText: .constant(""),
            isSearching: .constant(false),
            onSearch: { _ in },
            onClear: { }
        )
        .padding()
        .frame(width: 500)
    }
}
