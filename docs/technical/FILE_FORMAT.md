# StickyToDo File Format Specification

Complete technical specification for StickyToDo's markdown-based file format.

## Overview

StickyToDo stores all data as plain-text markdown files with YAML frontmatter. This ensures:
- **Human-readable** - Edit in any text editor
- **Version control friendly** - Works with git
- **Future-proof** - Standard formats
- **Portable** - Easy to migrate or export

## Directory Structure

```
StickyToDo/
├── tasks/
│   ├── active/
│   │   └── YYYY/
│   │       └── MM/
│   │           └── {uuid}-{slug}.md
│   └── archive/
│       └── YYYY/
│           └── MM/
│               └── {uuid}-{slug}.md
├── boards/
│   ├── inbox.md
│   ├── next-actions.md
│   └── {board-id}.md
└── config/
    ├── contexts.yaml
    ├── perspectives.yaml
    └── settings.yaml
```

### Path Components

**{uuid}** - RFC 4122 UUID v4
- Example: `12345678-1234-1234-1234-123456789012`
- Ensures global uniqueness
- Used as primary identifier

**{slug}** - URL-safe title
- Lowercase, alphanumeric + hyphens
- Truncated to 50 characters
- Example: `buy-groceries-at-whole-foods`
- Generation: `title.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "-")`

**YYYY** - 4-digit year
- Example: `2025`
- From task creation date

**MM** - 2-digit month
- Example: `01` for January, `12` for December
- Zero-padded

## Task File Format

### Complete Example

```markdown
---
id: 12345678-1234-1234-1234-123456789012
type: task
title: Call John about proposal
notes: ""
status: next-action
project: Sales
context: "@phone"
due: 2025-11-20T09:00:00Z
defer: 2025-11-18T09:00:00Z
flagged: true
priority: high
effort: 30
positions:
  freeform-board:
    x: 450.0
    y: 320.0
  website-project:
    x: 100.0
    y: 200.0
created: 2025-11-18T10:30:00Z
modified: 2025-11-18T14:15:00Z
---

Discuss Q4 proposal and timeline.

Key points to cover:
- Budget requirements
- Timeline expectations
- Resource allocation
```

### Field Specifications

#### Required Fields

**id** (String, UUID)
```yaml
id: 12345678-1234-1234-1234-123456789012
```
- Format: RFC 4122 UUID v4
- Must be globally unique
- Generated once at creation
- Never changes

**type** (String, Enum)
```yaml
type: task  # or "note"
```
- Values: `task`, `note`
- Default: `task`
- Determines available metadata

**title** (String)
```yaml
title: "Buy groceries"
```
- Required, non-empty
- Max length: 500 characters (recommended)
- Supports Unicode
- Single line

**status** (String, Enum)
```yaml
status: next-action
```
- Values: `inbox`, `next-action`, `waiting`, `someday`, `completed`
- Default: `inbox`
- Determines file location (active vs. archive)

**created** (DateTime, ISO 8601)
```yaml
created: 2025-11-18T10:30:00Z
```
- Format: ISO 8601 with timezone
- UTC recommended
- Set once at creation
- Never changes

**modified** (DateTime, ISO 8601)
```yaml
modified: 2025-11-18T14:15:00Z
```
- Format: ISO 8601 with timezone
- UTC recommended
- Updated on any change
- Used for sync conflict resolution

#### Optional Fields

**notes** (String)
```yaml
notes: ""  # Empty if no notes
```
- Body content of markdown file
- Supports full markdown
- Can be empty
- Stored separately from frontmatter

**project** (String, Optional)
```yaml
project: "Website Redesign"
```
- Project name
- Case-sensitive
- No # prefix in YAML
- Null if not assigned

**context** (String, Optional)
```yaml
context: "@office"
```
- Context name
- Includes @ prefix
- Case-sensitive
- Null if not assigned

**due** (DateTime, Optional, ISO 8601)
```yaml
due: 2025-11-20T09:00:00Z
```
- Hard deadline
- ISO 8601 format
- Time component optional
- Null if no due date

**defer** (DateTime, Optional, ISO 8601)
```yaml
defer: 2025-11-19T09:00:00Z
```
- Start/show date
- ISO 8601 format
- Task hidden until this date
- Null if no defer date

**flagged** (Boolean)
```yaml
flagged: true  # or false
```
- Default: `false`
- Starred for attention
- Boolean value required

**priority** (String, Enum)
```yaml
priority: high  # or medium, low
```
- Values: `high`, `medium`, `low`
- Default: `medium`
- Affects sorting and display

**effort** (Integer, Optional)
```yaml
effort: 30  # minutes
```
- Estimated duration in minutes
- Positive integer
- Null if not estimated
- Display converts to hours if >= 60

**positions** (Dictionary, Optional)
```yaml
positions:
  board-id-1:
    x: 100.0
    y: 200.0
  board-id-2:
    x: 300.0
    y: 400.0
```
- Maps board ID to Position
- Each position has x, y coordinates
- Floating point numbers
- Empty dictionary if not positioned

### YAML Encoding Rules

**Strings:**
```yaml
# Unquoted (preferred for simple strings)
title: Simple task

# Quoted (required for special characters)
title: "Task: with colons"
title: 'Task with "quotes"'

# Multi-line
notes: |
  Line 1
  Line 2
  Line 3
```

**Dates:**
```yaml
# ISO 8601 with timezone (recommended)
due: 2025-11-20T09:00:00Z

# ISO 8601 with offset
due: 2025-11-20T09:00:00-08:00

# Date only (interpreted as start of day, UTC)
due: 2025-11-20
```

**Booleans:**
```yaml
# Lowercase (preferred)
flagged: true
flagged: false

# Also valid
flagged: yes
flagged: no
```

**Null values:**
```yaml
# Explicit null
project: null

# Omit field entirely (preferred)
```

**Numbers:**
```yaml
# Integer
effort: 30

# Float
x: 100.5
y: 200.75
```

### Markdown Body

The content after the closing `---` is the task notes/description.

**Supported Markdown:**
- Headers: `# H1`, `## H2`, etc.
- **Bold**: `**text**` or `__text__`
- *Italic*: `*text*` or `_text_`
- Lists: `- item` or `1. item`
- Links: `[text](url)`
- Code: `` `code` `` or ` ```language ```
- Blockquotes: `> quote`
- Tables
- Task lists: `- [ ] item`

**Example:**
```markdown
---
title: Project planning
---

## Phase 1: Research

- [ ] Review competitor sites
- [ ] Interview stakeholders
- [ ] Create user personas

## Phase 2: Design

Budget: $10,000
Timeline: 6 weeks

See [project docs](link/to/docs) for details.
```

## Board File Format

### Complete Example

```markdown
---
id: website-redesign
type: project
layout: kanban
filter:
  project: "Website Redesign"
columns:
  - "To Do"
  - "In Progress"
  - "Done"
autoHide: true
hideAfterDays: 7
title: "Website Redesign"
icon: "🌐"
color: "blue"
isBuiltIn: false
isVisible: true
order: 10
---

Project board for website redesign initiative.

## Goals
- Modern, responsive design
- Improved UX
- Better performance

## Timeline
Launch: Q2 2025
```

### Field Specifications

#### Required Fields

**id** (String)
```yaml
id: my-project-board
```
- Unique board identifier
- URL-safe characters only
- Used as filename

**type** (String, Enum)
```yaml
type: project  # or context, status, custom
```
- Values: `context`, `project`, `status`, `custom`
- Determines metadata update behavior

**layout** (String, Enum)
```yaml
layout: kanban  # or freeform, grid
```
- Values: `freeform`, `kanban`, `grid`
- Default: `freeform`
- Determines visual layout

#### Optional Fields

**filter** (Object)
```yaml
filter:
  status: next-action
  project: "Website"
  context: "@computer"
  flagged: true
  priority: high
  dueBefore: 2025-12-31T23:59:59Z
  dueAfter: 2025-01-01T00:00:00Z
  effortMax: 120
  effortMin: 15
```
- All filter fields optional
- Multiple criteria combined with AND
- See Filter Object specification below

**columns** (Array of Strings)
```yaml
columns:
  - "To Do"
  - "In Progress"
  - "Done"
```
- Required for kanban layout
- Optional for others
- Order matters
- Unicode supported

**autoHide** (Boolean)
```yaml
autoHide: true
```
- Default: `false`
- Hide when no active tasks

**hideAfterDays** (Integer)
```yaml
hideAfterDays: 7
```
- Default: `7`
- Days of inactivity before auto-hide
- Only relevant if autoHide is true

**title** (String, Optional)
```yaml
title: "Custom Title"
```
- Display name
- If omitted, derived from ID
- Unicode supported

**notes** (String)
```yaml
notes: ""
```
- Board description
- Markdown supported
- Stored in file body

**icon** (String, Optional)
```yaml
icon: "📁"
```
- Emoji or text icon
- Single character recommended
- Used in UI

**color** (String, Optional)
```yaml
color: "blue"
```
- Color name or hex code
- Used for UI theming

**isBuiltIn** (Boolean)
```yaml
isBuiltIn: false
```
- Default: `false`
- True for system boards
- Built-in boards can't be deleted

**isVisible** (Boolean)
```yaml
isVisible: true
```
- Default: `true`
- Controls sidebar visibility

**order** (Integer, Optional)
```yaml
order: 10
```
- Sort position in sidebar
- Lower numbers first
- Null orders go to end

### Filter Object

All fields are optional. Multiple criteria are ANDed together.

```yaml
filter:
  # Task type
  type: task  # or note

  # Status
  status: next-action  # inbox, next-action, waiting, someday, completed

  # Text fields
  project: "Project Name"
  context: "@context"

  # Boolean
  flagged: true  # or false

  # Priority
  priority: high  # medium, low

  # Date ranges
  dueBefore: 2025-12-31T23:59:59Z
  dueAfter: 2025-01-01T00:00:00Z
  deferAfter: 2025-11-18T00:00:00Z

  # Effort ranges (minutes)
  effortMax: 120
  effortMin: 15

  # Advanced (future)
  expression: "project:Website AND context:@computer"
```

## Configuration Files

### contexts.yaml

```yaml
contexts:
  - name: "@office"
    icon: "🏢"
    color: "blue"
    description: "At the office"
    active: true

  - name: "@home"
    icon: "🏠"
    color: "green"
    description: "At home"
    active: true

  - name: "@computer"
    icon: "💻"
    color: "gray"
    description: "Requires computer"
    active: true

  - name: "@phone"
    icon: "📱"
    color: "purple"
    description: "Phone calls"
    active: true

  - name: "@errands"
    icon: "🚗"
    color: "orange"
    description: "Out and about"
    active: true

  - name: "@anywhere"
    icon: "🌍"
    color: "teal"
    description: "No specific location"
    active: true
```

### perspectives.yaml

```yaml
perspectives:
  - id: quick-wins
    name: "Quick Wins"
    filter:
      status: next-action
      effortMax: 30
      priority: high
    groupBy: context
    sortBy: due
    sortDirection: ascending
    showCompleted: false
    showDeferred: false
    icon: "⚡"
    color: "yellow"
    isBuiltIn: false
    isVisible: true
    order: 20
```

### settings.yaml

```yaml
# Application settings
app:
  dataDirectory: "~/Documents/StickyToDo"
  language: "en"
  theme: "auto"  # light, dark, auto

# Quick capture
quickCapture:
  globalHotkey: "⌘⇧Space"
  defaultStatus: "inbox"
  defaultContext: null
  defaultProject: null

# File watching
fileWatcher:
  enabled: true
  debounceInterval: 500  # milliseconds

# Sync
sync:
  enabled: true
  provider: "icloud"  # icloud, dropbox, none
  conflictResolution: "ask"  # ask, ours, theirs

# UI preferences
ui:
  defaultView: "list"  # list, board
  sidebarVisible: true
  inspectorVisible: false
  compactMode: false

# Advanced
advanced:
  logLevel: "info"  # debug, info, warn, error
  saveDebounceInterval: 500  # milliseconds
  maxUndoSteps: 50
```

## Migration and Import/Export

### Exporting Tasks

**Individual Task:**
```bash
# Copy task file
cp "tasks/active/2025/11/uuid-title.md" exported/
```

**All Tasks:**
```bash
# Tar archive
tar -czf tasks-backup.tar.gz tasks/

# Zip archive
zip -r tasks-backup.zip tasks/
```

### Importing Tasks

1. **Place files** in appropriate directory structure
2. **Ensure unique UUIDs** - Generate new if duplicates
3. **Restart StickyToDo** - Will auto-detect new files
4. **Or use File → Import** - Built-in import dialog

### Converting from Other Formats

**From Plain Markdown:**
```bash
# Add minimal frontmatter
cat > task.md <<EOF
---
id: $(uuidgen)
type: task
title: "Task from markdown"
status: inbox
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
modified: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
---

$(cat original.md)
EOF
```

**From CSV:**
```python
import csv, uuid, datetime, yaml

with open('tasks.csv') as f:
    reader = csv.DictReader(f)
    for row in reader:
        frontmatter = {
            'id': str(uuid.uuid4()),
            'type': 'task',
            'title': row['title'],
            'status': row.get('status', 'inbox'),
            'created': datetime.datetime.utcnow().isoformat() + 'Z',
            'modified': datetime.datetime.utcnow().isoformat() + 'Z',
        }
        if row.get('project'):
            frontmatter['project'] = row['project']

        with open(f"tasks/{frontmatter['id']}.md", 'w') as out:
            out.write('---\n')
            yaml.dump(frontmatter, out)
            out.write('---\n\n')
            out.write(row.get('notes', ''))
```

## Validation

### YAML Lint

```bash
# Validate YAML syntax
yamllint task.md
```

### Schema Validation

```yaml
# JSON Schema for task frontmatter
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["id", "type", "title", "status", "created", "modified"],
  "properties": {
    "id": {"type": "string", "format": "uuid"},
    "type": {"enum": ["task", "note"]},
    "title": {"type": "string", "minLength": 1},
    "status": {"enum": ["inbox", "next-action", "waiting", "someday", "completed"]},
    "project": {"type": ["string", "null"]},
    "context": {"type": ["string", "null"]},
    "due": {"type": ["string", "null"], "format": "date-time"},
    "defer": {"type": ["string", "null"], "format": "date-time"},
    "flagged": {"type": "boolean"},
    "priority": {"enum": ["high", "medium", "low"]},
    "effort": {"type": ["integer", "null"], "minimum": 1},
    "created": {"type": "string", "format": "date-time"},
    "modified": {"type": "string", "format": "date-time"}
  }
}
```

## Best Practices

### File Naming
- Use descriptive slugs
- Keep slugs under 50 characters
- Avoid special characters
- Use hyphens, not underscores

### Frontmatter
- Keep fields alphabetically sorted (optional but recommended)
- Use lowercase for enum values
- Include timezone in dates
- Omit null fields rather than explicit null

### Markdown
- Use consistent heading levels
- Include blank line after frontmatter closing `---`
- End file with newline
- Use reference-style links for readability

### Version Control
```gitignore
# .gitignore
tasks/archive/  # Optional: archive can get large
.DS_Store
*.swp
*~
```

```bash
# Commit messages
git commit -m "Add: Buy groceries task"
git commit -m "Complete: Website redesign planning"
git commit -m "Update: Change project context to @home"
```

---

## Appendix: Full Schema Reference

See the [JSON Schema files](../schemas/) for machine-readable format specifications:
- `task-schema.json` - Task file format
- `board-schema.json` - Board file format
- `context-schema.json` - Context configuration
- `perspective-schema.json` - Perspective configuration
- `settings-schema.json` - Application settings

---

*Last updated: 2025-11-18*

For more information:
- [User Guide](USER_GUIDE.md)
- [Keyboard Shortcuts](KEYBOARD_SHORTCUTS.md)
- [Development Guide](DEVELOPMENT.md)
