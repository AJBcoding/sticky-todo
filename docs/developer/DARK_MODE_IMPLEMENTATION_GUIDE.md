# Dark Mode Implementation Guide for Developers

## Quick Reference

### Adding Theme Support to a View

**3 Steps:**
1. Import StickyToDoCore
2. Add @Environment property
3. Replace hardcoded colors

```swift
// BEFORE
import SwiftUI

struct MyView: View {
    var body: some View {
        Text("Hello")
            .foregroundColor(.primary)  // ❌ Hardcoded
            .background(Color.white)     // ❌ Hardcoded
    }
}

// AFTER
import SwiftUI
import StickyToDoCore  // ✅ Step 1

struct MyView: View {
    @Environment(\.colorTheme) private var theme  // ✅ Step 2

    var body: some View {
        Text("Hello")
            .foregroundColor(theme.primaryText)      // ✅ Step 3
            .background(theme.primaryBackground)     // ✅ Step 3
    }
}
```

---

## Semantic Colors Reference

### Backgrounds

```swift
theme.primaryBackground    // Main window background
theme.secondaryBackground  // Cards, panels
theme.tertiaryBackground   // Elevated elements
theme.sidebarBackground    // Sidebar specific
theme.taskCardBackground   // Task cards
```

**When to use:**
- `primaryBackground` → Root views, main content area
- `secondaryBackground` → Cards, list items, panels
- `tertiaryBackground` → Popovers, tooltips, floating elements
- `sidebarBackground` → Sidebar, inspector panels
- `taskCardBackground` → Task cards, note cards

### Text

```swift
theme.primaryText      // Main text (highest contrast)
theme.secondaryText    // Supporting text (medium contrast)
theme.tertiaryText     // Hints, captions (low contrast)
```

**When to use:**
- `primaryText` → Titles, headings, important content
- `secondaryText` → Descriptions, subtitles, metadata
- `tertiaryText` → Placeholders, hints, disabled text

### UI Elements

```swift
theme.separator           // Dividers, lines
theme.border              // Borders, outlines
theme.hoverBackground     // Hover states
theme.selectionBackground // Selected items
theme.taskCardShadow      // Shadows (auto-disabled in true black)
```

**When to use:**
- `separator` → Dividers between sections, list items
- `border` → Card borders, text field outlines
- `hoverBackground` → Mouse hover effects
- `selectionBackground` → Selected list items, focused elements
- `taskCardShadow` → Drop shadows (automatically nil in true black)

### Status Colors

```swift
theme.accent   // Interactive elements (uses user's chosen accent)
theme.success  // Positive, completed, success
theme.warning  // Attention needed, due soon
theme.error    // Errors, overdue, critical
```

**When to use:**
- `accent` → Buttons, links, selected states, progress bars
- `success` → Checkmarks, completion states, positive messages
- `warning` → Due today, warnings, needs attention
- `error` → Overdue tasks, errors, destructive actions, high priority

---

## Common Patterns

### 1. Task Row

```swift
struct TaskRowView: View {
    @Binding var task: Task
    @Environment(\.colorTheme) private var theme

    var body: some View {
        HStack {
            // Completion checkbox
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? theme.success : theme.secondaryText)

            // Title
            Text(task.title)
                .foregroundColor(task.isCompleted ? theme.secondaryText : theme.primaryText)
                .strikethrough(task.isCompleted)

            Spacer()

            // Priority indicator
            if task.priority == .high {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(theme.error)
            }

            // Due date
            if let dueDate = task.dueDate {
                Text(dueDate.formatted())
                    .foregroundColor(task.isOverdue ? theme.error : theme.warning)
            }
        }
        .padding()
        .background(theme.taskCardBackground)
        .cornerRadius(8)
        .shadow(color: theme.taskCardShadow, radius: 2)
    }
}
```

### 2. Card Component

```swift
struct CardView<Content: View>: View {
    @Environment(\.colorTheme) private var theme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(theme.taskCardBackground)
            .cornerRadius(12)
            .shadow(color: theme.taskCardShadow, radius: 4, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(theme.border, lineWidth: 1)
            )
    }
}

// Usage
CardView {
    Text("Hello")
}
```

### 3. List with Selection

```swift
struct TaskListView: View {
    @Environment(\.colorTheme) private var theme
    @Binding var tasks: [Task]
    @Binding var selectedTaskId: UUID?

    var body: some View {
        List(tasks) { task in
            TaskRow(task: task)
                .background(
                    selectedTaskId == task.id
                        ? theme.selectionBackground
                        : Color.clear
                )
                .onTapGesture {
                    selectedTaskId = task.id
                }
        }
        .background(theme.primaryBackground)
    }
}
```

### 4. Form/Settings

```swift
struct SettingsView: View {
    @Environment(\.colorTheme) private var theme
    @State private var name = ""
    @State private var enabled = true

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .foregroundColor(theme.primaryText)

                Toggle("Enabled", isOn: $enabled)
                    .tint(theme.accent)

                Text("This is a description")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
        }
        .formStyle(.grouped)
        .background(theme.primaryBackground)
    }
}
```

### 5. Button Styles

```swift
// Primary button (filled with accent color)
Button("Save") { }
    .buttonStyle(.borderedProminent)
    .tint(theme.accent)

// Secondary button (outlined)
Button("Cancel") { }
    .buttonStyle(.bordered)
    .foregroundColor(theme.accent)

// Destructive button
Button("Delete") { }
    .buttonStyle(.borderedProminent)
    .tint(theme.error)

// Text button
Button("Learn More") { }
    .buttonStyle(.plain)
    .foregroundColor(theme.accent)
```

### 6. Status Indicators

```swift
struct StatusBadge: View {
    @Environment(\.colorTheme) private var theme
    let status: Status

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(status.displayName)
                .font(.caption)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .cornerRadius(4)
    }

    private var statusColor: Color {
        switch status {
        case .completed:
            return theme.success
        case .inProgress:
            return theme.warning
        case .blocked:
            return theme.error
        default:
            return theme.secondaryText
        }
    }
}
```

---

## Migration Checklist

When updating a view to use the theme system:

### ✅ Required Changes

- [ ] Add `import StickyToDoCore`
- [ ] Add `@Environment(\.colorTheme) private var theme`
- [ ] Replace `.foregroundColor(.primary)` → `theme.primaryText`
- [ ] Replace `.foregroundColor(.secondary)` → `theme.secondaryText`
- [ ] Replace `.background(Color.white)` → `theme.primaryBackground`
- [ ] Replace hardcoded colors with semantic equivalents

### ✅ Common Replacements

| Hardcoded | Semantic |
|-----------|----------|
| `.primary` | `theme.primaryText` |
| `.secondary` | `theme.secondaryText` |
| `Color.white` | `theme.primaryBackground` |
| `Color(NSColor.windowBackgroundColor)` | `theme.primaryBackground` |
| `Color(NSColor.controlBackgroundColor)` | `theme.secondaryBackground` |
| `Color.gray` | `theme.secondaryText` or `theme.border` |
| `.green` | `theme.success` |
| `.orange` | `theme.warning` |
| `.red` | `theme.error` |
| `.accentColor` | `theme.accent` |

### ✅ Special Cases

**Shadows:**
```swift
// BEFORE
.shadow(color: .black.opacity(0.1), radius: 2)

// AFTER (auto-disabled in true black mode)
.shadow(color: theme.taskCardShadow, radius: 2)
```

**Borders:**
```swift
// BEFORE
.overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

// AFTER
.overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(theme.border))
```

**Task Colors (ColorPalette):**
```swift
// These are intentionally NOT themed (they're user-chosen)
ColorPalette.blue.color  // ✅ Correct - task label colors
theme.accent              // ❌ Wrong - this is the app accent
```

---

## AppKit Integration

### NSViewController

```swift
import AppKit
import StickyToDoCore

class MyViewController: NSViewController {
    private var theme: ColorTheme {
        ConfigurationManager.shared.colorTheme
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        observeThemeChanges()
    }

    private func applyTheme() {
        view.wantsLayer = true
        view.layer?.backgroundColor = theme.nsPrimaryBackground.cgColor

        // Update text colors, borders, etc.
    }

    private func observeThemeChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: .themeChanged,
            object: nil
        )
    }

    @objc private func themeChanged() {
        applyTheme()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

### NSView Subclass

```swift
class ThemedView: NSView {
    private var theme: ColorTheme {
        ConfigurationManager.shared.colorTheme
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        observeThemeChanges()
        updateColors()
    }

    private func observeThemeChanges() {
        NotificationCenter.default.addObserver(
            forName: .themeChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateColors()
        }
    }

    private func updateColors() {
        layer?.backgroundColor = theme.nsPrimaryBackground.cgColor
        needsDisplay = true
    }
}
```

---

## Testing

### Unit Tests

```swift
import XCTest
@testable import StickyToDoCore

class ColorThemeTests: XCTestCase {

    func testLightThemeColors() {
        let theme = ColorTheme.light

        XCTAssertEqual(theme.mode, .light)
        XCTAssertFalse(theme.isDark)
        XCTAssertFalse(theme.isTrueBlack)
    }

    func testDarkThemeColors() {
        let theme = ColorTheme.dark

        XCTAssertEqual(theme.mode, .dark)
        XCTAssertTrue(theme.isDark)
        XCTAssertFalse(theme.isTrueBlack)
    }

    func testTrueBlackThemeColors() {
        let theme = ColorTheme.trueBlack

        XCTAssertEqual(theme.mode, .trueBlack)
        XCTAssertTrue(theme.isDark)
        XCTAssertTrue(theme.isTrueBlack)

        // Verify pure black background
        #if canImport(SwiftUI)
        // Note: Direct color comparison is difficult in SwiftUI
        // Best to test via visual snapshot tests
        #endif
    }

    func testAccentColorPropagation() {
        let blueTheme = ColorTheme(mode: .light, accentColor: .blue)
        let purpleTheme = ColorTheme(mode: .light, accentColor: .purple)

        XCTAssertNotEqual(blueTheme.accent, purpleTheme.accent)
    }
}
```

### SwiftUI Preview Tests

```swift
#Preview("Light Theme") {
    MyView()
        .colorTheme(.light)
        .frame(width: 400, height: 300)
}

#Preview("Dark Theme") {
    MyView()
        .colorTheme(.dark)
        .frame(width: 400, height: 300)
        .preferredColorScheme(.dark)
}

#Preview("True Black Theme") {
    MyView()
        .colorTheme(.trueBlack)
        .frame(width: 400, height: 300)
        .preferredColorScheme(.dark)
}

#Preview("All Accent Colors") {
    VStack {
        ForEach(AccentColorOption.allCases, id: \.self) { accent in
            MyView()
                .colorTheme(ColorTheme(mode: .light, accentColor: accent))
        }
    }
}
```

---

## Performance Tips

### ✅ Do's

```swift
// ✅ Cache theme in computed property
private var theme: ColorTheme {
    ConfigurationManager.shared.colorTheme
}

// ✅ Use @Environment (automatically updates)
@Environment(\.colorTheme) private var theme

// ✅ Observe notifications for AppKit
NotificationCenter.default.addObserver(forName: .themeChanged, ...)
```

### ❌ Don'ts

```swift
// ❌ Don't create new themes repeatedly
var body: some View {
    Text("Hello")
        .foregroundColor(ColorTheme.dark.primaryText)  // Bad!
}

// ❌ Don't ignore theme in favor of hardcoded colors
.foregroundColor(.white)  // Bad! Won't adapt to theme

// ❌ Don't forget to remove observers
deinit {
    // MUST remove observers to prevent leaks
    NotificationCenter.default.removeObserver(self)
}
```

---

## Accessibility Considerations

### Contrast Requirements

All semantic colors meet **WCAG AA** requirements (4.5:1 ratio):

```swift
// ✅ These automatically meet contrast requirements
theme.primaryText / theme.primaryBackground     // > 15:1
theme.secondaryText / theme.primaryBackground   // > 5:1
theme.accent / theme.primaryBackground          // > 4.5:1

// ⚠️ Be careful with custom colors
Color.pink.opacity(0.3) / theme.primaryBackground  // May fail!
```

### Test with Accessibility Features

```swift
// Test your views with:
// 1. Increase Contrast enabled
// 2. Reduce Transparency enabled
// 3. VoiceOver enabled

// The theme system handles these automatically,
// but test custom colors carefully
```

---

## Troubleshooting

### Theme not updating?

**Problem:** Colors don't change when theme is switched.

**Solutions:**
1. Verify `@Environment(\.colorTheme)` is added
2. Check that `.colorTheme(...)` modifier is applied at app root
3. Ensure view is in the hierarchy (not cached)
4. For AppKit, verify notification observer is set up

### Colors look wrong?

**Problem:** Theme colors don't match expected values.

**Solutions:**
1. Check you're using correct semantic color (e.g., `primaryText` not `secondary`)
2. Verify theme mode is set correctly in Settings
3. Check for hardcoded opacity that might be interfering
4. Test in both light and dark system appearance

### Performance issues?

**Problem:** App slows down when switching themes.

**Solutions:**
1. Don't create new ColorTheme instances repeatedly
2. Use `@Environment` instead of `ConfigurationManager.shared.colorTheme`
3. Batch UI updates in AppKit using `CATransaction`
4. Profile with Instruments to find bottlenecks

---

## Resources

### Related Files

- `/StickyToDoCore/Utilities/ColorTheme.swift` - Theme definitions
- `/StickyToDoCore/Utilities/ColorPalette.swift` - Task label colors
- `/StickyToDo/Views/Settings/AppearanceSettingsView.swift` - Settings UI
- `/StickyToDoCore/Utilities/ConfigurationManager.swift` - Persistence

### Documentation

- `DARK_MODE_REFINEMENTS_REPORT.md` - Implementation details
- `DARK_MODE_VISUAL_GUIDE.md` - User-facing guide
- Apple HIG: Dark Mode Guidelines
- WCAG 2.1 Contrast Requirements

---

## Quick Checklist for PR Reviews

When reviewing theme-related changes:

- [ ] All hardcoded colors replaced with semantic equivalents
- [ ] `import StickyToDoCore` present
- [ ] `@Environment(\.colorTheme)` declared
- [ ] Shadows use `theme.taskCardShadow` (auto-disabled in true black)
- [ ] Text uses `primaryText` / `secondaryText` / `tertiaryText`
- [ ] Backgrounds use `primaryBackground` / `secondaryBackground` / etc.
- [ ] Status colors use `success` / `warning` / `error`
- [ ] Interactive elements use `accent`
- [ ] Works in all 4 theme modes (system/light/dark/true black)
- [ ] Works with all 11 accent colors
- [ ] Accessibility contrast requirements met
- [ ] AppKit observers cleaned up in deinit

---

**Last Updated:** 2025-11-18
**Maintainers:** StickyToDo Development Team
**Questions?** See DARK_MODE_REFINEMENTS_REPORT.md or Settings → Appearance
