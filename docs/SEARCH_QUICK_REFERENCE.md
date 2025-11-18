# Search System Quick Reference

## Quick Start

### Basic Usage

```swift
// Search with simple string
let results = SearchManager.search(tasks: allTasks, queryString: "important bug")

// Display results
for result in results {
    print("\(result.task.title) - Score: \(result.relevanceScore)")
}
```

### Advanced Search

```swift
// Use operators
let results = SearchManager.search(
    tasks: allTasks,
    queryString: "\"project review\" AND urgent NOT completed"
)
```

### Show Search UI (SwiftUI)

```swift
.sheet(isPresented: $showingSearch) {
    SearchView(tasks: taskStore.tasks) { selectedTask in
        // Handle selection
        currentTask = selectedTask
    }
}
```

### Show Search UI (AppKit)

```swift
let searchWindow = SearchWindowController(
    tasks: taskStore.tasks,
    onSelectTask: { task in
        self.selectTask(task)
    }
)
searchWindow.showWindow(nil)
```

## Search Operators Cheat Sheet

| Operator | Example | Effect |
|----------|---------|--------|
| `AND` | `bug AND urgent` | Both terms required |
| `OR` | `feature OR bug` | Either term matches |
| `NOT` | `task NOT completed` | Excludes second term |
| `"..."` | `"code review"` | Exact phrase only |

## Relevance Scoring

Results are ranked by:
1. **Field weights:** title (10x) > project (5x) > tags (4x) > context (3x) > notes (1x)
2. **Position bonus:** +50% for matches at start of field
3. **Exact matches:** +100% for quoted phrases
4. **Task properties:**
   - Flagged: +20%
   - High priority: +30%
   - Recent (< 7 days): +10%

## Highlight Colors

- **Match highlight:** Yellow background (50% opacity)
- **Selected result:** Blue border/background

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `⌘F` | Open search |
| `↑/↓` | Navigate results |
| `Enter` | Select task |
| `Esc` | Close search |

## Common Patterns

### Filter by Project

```swift
let projectResults = SearchManager.search(
    tasks: allTasks,
    queryString: "project:\"Website Redesign\""
)
```

### Find Urgent Tasks

```swift
let urgentResults = SearchManager.search(
    tasks: allTasks,
    queryString: "urgent OR high-priority"
)
```

### Exclude Completed

```swift
let activeResults = SearchManager.search(
    tasks: allTasks,
    queryString: "review NOT completed"
)
```

### Recent Searches

```swift
// Save a search
SearchManager.saveRecentSearch("important tasks")

// Get recent searches
let recents = SearchManager.getRecentSearches()

// Clear history
SearchManager.clearRecentSearches()
```

## Example Queries

```
bug                           → Find any task with "bug"
"weekly review"               → Exact phrase match
bug AND urgent                → Must have both terms
feature OR enhancement        → Has either term
project NOT archived          → Has "project" but not "archived"
@computer AND high-priority   → Context + priority
"code review" OR "pull request" → Either exact phrase
```

## API Quick Reference

```swift
// Core search
SearchManager.search(tasks: [Task], queryString: String) -> [SearchResult]

// Parse query
SearchManager.parseQuery(_ queryString: String) -> SearchQuery

// Recent searches
SearchManager.saveRecentSearch(_ query: String)
SearchManager.getRecentSearches() -> [String]
SearchManager.clearRecentSearches()

// Result inspection
result.task                    → The matched task
result.relevanceScore          → Numeric score
result.highlights             → All highlights
result.matchedFields          → Fields with matches
result.highlights(for: "title") → Title highlights only
result.hasMatch(in: "notes")   → Check field match
```

## SwiftUI Views

```swift
// Full search interface
SearchView(
    tasks: [Task],
    onSelectTask: (Task) -> Void
)

// Search bar only
SearchBar(
    searchText: Binding<String>,
    isSearching: Binding<Bool>,
    onSearch: (String) -> Void,
    onClear: () -> Void
)

// Results display
SearchResultsView(
    results: [SearchResult],
    query: String,
    onSelectTask: (Task) -> Void
)

// Highlighted text
HighlightedText(
    text: String,
    highlights: [SearchHighlight],
    font: Font = .body,
    foregroundColor: Color = .primary
)
```

## AppKit Views

```swift
// Search window
SearchWindowController(
    tasks: [Task],
    onSelectTask: (Task) -> Void
)

// Search view controller
SearchViewController(
    tasks: [Task],
    onSelectTask: (Task) -> Void
)
```

## Tips & Tricks

### 1. Combine Operators
```swift
"(bug OR issue) AND NOT fixed"  → Unfixed bugs/issues
```

### 2. Search Tags
```swift
"urgent"                        → Searches tag names
```

### 3. Context Filtering
```swift
"@computer"                     → All computer tasks
"@phone OR @email"              → Communication tasks
```

### 4. Project-Based Search
```swift
"\"Website Redesign\" AND bug"  → Project bugs
```

### 5. Multiple Terms
```swift
"review code quality test"     → All terms (AND by default)
```

## Troubleshooting

### No Results?
- Check spelling
- Try broader terms
- Use OR instead of AND
- Remove NOT operators

### Too Many Results?
- Use exact phrases ("...")
- Add more terms with AND
- Use NOT to exclude
- Be more specific

### Unexpected Results?
- Remember: search is case-insensitive
- Partial matches are allowed
- Check all searchable fields

## Performance Tips

1. **Narrow your search:** More specific = faster
2. **Use exact phrases:** Faster than multiple words
3. **Limit task count:** Filter before searching
4. **Recent searches:** Reuse instead of retyping

## Integration Checklist

- [ ] Import SearchManager
- [ ] Call search method with tasks
- [ ] Display results in UI
- [ ] Handle task selection
- [ ] Add keyboard shortcut
- [ ] Test with sample queries
- [ ] Add to menu/toolbar

## Example Implementation

```swift
import SwiftUI

struct TaskSearchExample: View {
    @State private var searchText = ""
    @State private var results: [SearchResult] = []
    @State private var showingSearch = false

    let tasks: [Task]

    var body: some View {
        VStack {
            // Search button
            Button("Search ⌘F") {
                showingSearch = true
            }
            .keyboardShortcut("f", modifiers: .command)

            // Results count
            Text("\(results.count) results")
        }
        .sheet(isPresented: $showingSearch) {
            SearchView(tasks: tasks) { selectedTask in
                // Handle selection
                print("Selected: \(selectedTask.title)")
                showingSearch = false
            }
        }
    }

    func performSearch(_ query: String) {
        results = SearchManager.search(
            tasks: tasks,
            queryString: query
        )
    }
}
```

---

**Need help?** Check the full documentation in `SEARCH_IMPLEMENTATION_REPORT.md`
