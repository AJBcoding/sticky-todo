# Quick Color Replacement Guide

**For rapid migration of views to use the theme system**

---

## Setup (Required for all views)

```swift
import StickyToDoCore  // ✅ Add this line

struct MyView: View {
    @Environment(\.colorTheme) private var theme  // ✅ Add this line

    var body: some View {
        // ...
    }
}
```

---

## Find & Replace Patterns

Use your editor's find & replace with regex:

### Text Colors

| Find (Regex) | Replace With |
|--------------|--------------|
| `.foregroundColor\(\.primary\)` | `.foregroundColor(theme.primaryText)` |
| `.foregroundColor\(\.secondary\)` | `.foregroundColor(theme.secondaryText)` |
| `.foregroundColor\(Color\.primary\)` | `.foregroundColor(theme.primaryText)` |
| `.foregroundColor\(Color\.secondary\)` | `.foregroundColor(theme.secondaryText)` |

### Background Colors

| Find (Regex) | Replace With |
|--------------|--------------|
| `.background\(Color\.white\)` | `.background(theme.primaryBackground)` |
| `.background\(Color\(NSColor\.windowBackgroundColor\)\)` | `.background(theme.primaryBackground)` |
| `.background\(Color\(NSColor\.controlBackgroundColor\)\)` | `.background(theme.secondaryBackground)` |

### Status Colors

| Find (Regex) | Replace With |
|--------------|--------------|
| `.foregroundColor\(\.green\)` | `.foregroundColor(theme.success)` |
| `.foregroundColor\(\.orange\)` | `.foregroundColor(theme.warning)` |
| `.foregroundColor\(\.red\)` | `.foregroundColor(theme.error)` |
| `.foregroundColor\(Color\.green\)` | `.foregroundColor(theme.success)` |
| `.foregroundColor\(Color\.orange\)` | `.foregroundColor(theme.warning)` |
| `.foregroundColor\(Color\.red\)` | `.foregroundColor(theme.error)` |

### Accent Color

| Find (Regex) | Replace With |
|--------------|--------------|
| `\.accentColor` | `theme.accent` |
| `Color\.accentColor` | `theme.accent` |
| `.tint\(\.accentColor\)` | `.tint(theme.accent)` |

### Shadows

| Find (Regex) | Replace With |
|--------------|--------------|
| `.shadow\(color: \.black\.opacity\([0-9.]+\)` | `.shadow(color: theme.taskCardShadow` |
| `.shadow\(color: Color\.black\.opacity\([0-9.]+\)` | `.shadow(color: theme.taskCardShadow` |

### Borders

| Find (Regex) | Replace With |
|--------------|--------------|
| `.stroke\(Color\.gray\)` | `.strokeBorder(theme.border)` |
| `.stroke\(\.gray\)` | `.strokeBorder(theme.border)` |

---

## Common Replacements (Copy-Paste)

### TaskRowView Pattern

```swift
// ❌ BEFORE
.foregroundColor(task.isCompleted ? .green : .secondary)

// ✅ AFTER
.foregroundColor(task.isCompleted ? theme.success : theme.secondaryText)
```

### Selection Background

```swift
// ❌ BEFORE
.background(isSelected ? Color.accentColor.opacity(0.1) : .clear)

// ✅ AFTER
.background(isSelected ? theme.selectionBackground : .clear)
```

### Card Style

```swift
// ❌ BEFORE
VStack {
    // content
}
.background(Color.white)
.cornerRadius(8)
.shadow(color: .black.opacity(0.1), radius: 2)

// ✅ AFTER
VStack {
    // content
}
.background(theme.taskCardBackground)
.cornerRadius(8)
.shadow(color: theme.taskCardShadow, radius: 2)
.overlay(
    RoundedRectangle(cornerRadius: 8)
        .strokeBorder(theme.border, lineWidth: 1)
)
```

### Button Styles

```swift
// ❌ BEFORE
Button("Action") { }
    .foregroundColor(.accentColor)

// ✅ AFTER
Button("Action") { }
    .foregroundColor(theme.accent)
```

---

## Special Cases

### Keep These As-Is ✅

**ColorPalette task colors** (these are user-chosen, not theme colors):
```swift
// ✅ CORRECT - Don't change these
ColorPalette.blue.color
ColorPalette.red.color
task.color  // This is the user's chosen task label color
```

**System colors that need to stay** (rare cases):
```swift
// ✅ CORRECT - Keep these
Color.clear
Color.white.opacity(0.0)
```

### Context-Sensitive Replacements

**Completed task text:**
```swift
// ❌ BEFORE
.foregroundColor(task.isCompleted ? .gray : .primary)

// ✅ AFTER
.foregroundColor(task.isCompleted ? theme.secondaryText : theme.primaryText)
```

**Status indicators:**
```swift
// ❌ BEFORE
switch status {
case .error: return .red
case .success: return .green
case .warning: return .orange
default: return .gray
}

// ✅ AFTER
switch status {
case .error: return theme.error
case .success: return theme.success
case .warning: return theme.warning
default: return theme.secondaryText
}
```

---

## Testing After Replacement

After updating a view:

1. **Build** to check for compile errors
2. **Run** in all 4 theme modes:
   - System (with macOS set to light)
   - System (with macOS set to dark)
   - Light (forced)
   - Dark (forced)
   - True Black (forced)
3. **Test** with all 11 accent colors
4. **Verify** readability and contrast

---

## Validation Checklist

After migration:

- [ ] No more `.foregroundColor(.primary)` or `.secondary`
- [ ] No more `Color.white` or `Color.black` backgrounds
- [ ] No more `.green`, `.red`, `.orange` for status
- [ ] No more `.accentColor` (use `theme.accent`)
- [ ] All shadows use `theme.taskCardShadow`
- [ ] All borders use `theme.border`
- [ ] File imports `StickyToDoCore`
- [ ] View has `@Environment(\.colorTheme) private var theme`
- [ ] Builds without errors
- [ ] Looks good in light mode
- [ ] Looks good in dark mode
- [ ] Looks good in true black mode

---

## Quick Stats

After migration, your view should have:

- **0** instances of `.primary` or `.secondary` (except in comments)
- **0** instances of `Color.white` or `Color.black` (except ColorPalette)
- **5+** instances of `theme.`
- **1** `@Environment(\.colorTheme)` declaration
- **1** `import StickyToDoCore` statement

---

## Example: Full Before/After

### Before (TaskRowView excerpt)

```swift
import SwiftUI

struct TaskRowView: View {
    @Binding var task: Task
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .secondary)

            Text(task.title)
                .foregroundColor(task.isCompleted ? .secondary : .primary)

            Spacer()

            if task.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}
```

### After (TaskRowView excerpt)

```swift
import SwiftUI
import StickyToDoCore  // ✅ Added

struct TaskRowView: View {
    @Binding var task: Task
    let isSelected: Bool
    @Environment(\.colorTheme) private var theme  // ✅ Added

    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? theme.success : theme.secondaryText)  // ✅ Changed

            Text(task.title)
                .foregroundColor(task.isCompleted ? theme.secondaryText : theme.primaryText)  // ✅ Changed

            Spacer()

            if task.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(theme.error)  // ✅ Changed
            }
        }
        .padding()
        .background(isSelected ? theme.selectionBackground : theme.taskCardBackground)  // ✅ Changed
        .cornerRadius(8)
        .shadow(color: theme.taskCardShadow, radius: 2)  // ✅ Changed
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(theme.border, lineWidth: 1)  // ✅ Added
        )
    }
}
```

**Changes:**
- Added `import StickyToDoCore`
- Added `@Environment(\.colorTheme) private var theme`
- Replaced 6 hardcoded colors with semantic colors
- Added border overlay for better visual hierarchy

---

## Time Estimates

| View Size | Estimated Time |
|-----------|----------------|
| Small (< 100 lines) | 5-10 minutes |
| Medium (100-300 lines) | 10-20 minutes |
| Large (300+ lines) | 20-30 minutes |

**Pro tip:** Use find & replace in your editor to speed up the process!

---

**Last Updated:** 2025-11-18
**See Also:**
- DARK_MODE_IMPLEMENTATION_GUIDE.md (detailed guide)
- DARK_MODE_REFINEMENTS_REPORT.md (technical details)
