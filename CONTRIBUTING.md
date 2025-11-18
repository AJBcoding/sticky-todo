# Contributing to StickyToDo

Thank you for your interest in contributing to StickyToDo! We welcome contributions from the community and are excited to have you here.

StickyToDo is a macOS task management application that combines GTD methodology with visual boards, all backed by plain-text markdown files. Whether you're fixing a bug, adding a feature, improving documentation, or suggesting enhancements, your contributions are valued.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [How to Report Issues](#how-to-report-issues)
4. [How to Submit Pull Requests](#how-to-submit-pull-requests)
5. [Development Setup](#development-setup)
6. [Code Style Guidelines](#code-style-guidelines)
7. [Testing Requirements](#testing-requirements)
8. [Documentation](#documentation)
9. [Code Review Process](#code-review-process)
10. [Community and Support](#community-and-support)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. By participating in this project, you agree to uphold the following principles:

### Our Pledge

- **Be respectful**: Treat everyone with respect and consideration
- **Be collaborative**: Work together constructively and support fellow contributors
- **Be inclusive**: Welcome people of all backgrounds and experience levels
- **Be professional**: Keep discussions focused and constructive
- **Be patient**: Remember that everyone is learning and growing

### Expected Behavior

- Use welcoming and inclusive language
- Accept constructive criticism gracefully
- Focus on what is best for the project and community
- Show empathy towards other community members
- Provide thoughtful, helpful feedback on contributions

### Unacceptable Behavior

- Harassment, discrimination, or inappropriate comments
- Personal attacks or trolling
- Publishing others' private information without permission
- Any conduct that could reasonably be considered inappropriate in a professional setting

### Enforcement

Project maintainers are responsible for clarifying standards and will take appropriate action in response to unacceptable behavior. This may include removing comments, rejecting contributions, or temporarily/permanently banning contributors.

## Getting Started

### Quick Links

- **Documentation**: See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for detailed architecture and implementation guidance
- **User Guide**: [docs/USER_GUIDE.md](docs/USER_GUIDE.md) explains features from a user perspective
- **File Format**: [docs/FILE_FORMAT.md](docs/FILE_FORMAT.md) documents the markdown format used for data storage
- **Keyboard Shortcuts**: [docs/KEYBOARD_SHORTCUTS.md](docs/KEYBOARD_SHORTCUTS.md) lists all keyboard shortcuts

### Ways to Contribute

- **Report bugs**: Found something that doesn't work? Let us know!
- **Suggest features**: Have an idea for improvement? We'd love to hear it!
- **Fix bugs**: Browse open issues and submit fixes
- **Add features**: Implement new functionality (discuss first for larger changes)
- **Improve documentation**: Fix typos, clarify instructions, add examples
- **Write tests**: Help improve test coverage
- **Review code**: Provide feedback on pull requests

## How to Report Issues

We use GitHub Issues to track bugs, feature requests, and other tasks. Before creating a new issue, please:

1. **Search existing issues** to avoid duplicates
2. **Check the documentation** to ensure it's not a usage question
3. **Verify the issue** with the latest version

### Bug Reports

When reporting a bug, please include:

**Required Information:**
- **Description**: Clear description of the problem
- **Steps to Reproduce**: Numbered steps to reproduce the behavior
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**:
  - macOS version
  - StickyToDo version
  - Xcode version (if building from source)

**Helpful Information:**
- Screenshots or screen recordings
- Sample data files (if applicable, remove sensitive information)
- Crash logs or error messages
- Whether the issue is reproducible

**Example:**
```markdown
**Description**
Tasks are not saving when I close the app.

**Steps to Reproduce**
1. Create a new task with title "Test Task"
2. Close the app without waiting
3. Reopen the app
4. Task is missing

**Expected Behavior**
Tasks should be saved before the app closes.

**Actual Behavior**
Tasks created within the last second before closing are lost.

**Environment**
- macOS: 14.1 (Sonoma)
- StickyToDo: 1.0.0
- Xcode: 15.0
```

### Feature Requests

When suggesting a feature, please include:

- **Problem Statement**: What problem does this solve?
- **Proposed Solution**: How would you like to see it work?
- **Alternatives Considered**: What other approaches did you think about?
- **Use Case**: Describe when and how you would use this feature
- **Impact**: Who would benefit from this feature?

### Questions and Discussions

For questions, general discussions, or ideas that aren't fully formed:
- Use [GitHub Discussions](https://github.com/yourusername/sticky-todo/discussions)
- Check existing discussions first
- Be clear and specific in your questions

## How to Submit Pull Requests

We love pull requests! Here's the process:

### 1. Discuss First (for larger changes)

For significant features or architectural changes:
- Open an issue to discuss the approach before coding
- Get feedback from maintainers
- Agree on the implementation strategy

Small bug fixes and documentation improvements can go straight to PR.

### 2. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR-USERNAME/sticky-todo.git
cd sticky-todo
```

### 3. Create a Branch

Use a descriptive branch name:

```bash
# For features
git checkout -b feature/natural-language-dates

# For bug fixes
git checkout -b fix/task-save-debounce

# For documentation
git checkout -b docs/improve-readme
```

### 4. Make Your Changes

- Follow the [Code Style Guidelines](#code-style-guidelines)
- Add tests for new functionality
- Update documentation as needed
- Keep commits focused and atomic
- Write clear commit messages (see [Commit Message Guidelines](#commit-message-guidelines))

### 5. Test Your Changes

```bash
# Run all tests
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo

# Run specific test
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo \
  -only-testing:StickyToDoTests/YourTestClass/testYourFeature

# Build the project
xcodebuild -project StickyToDo.xcodeproj -scheme StickyToDo build
```

Ensure:
- All tests pass
- No new warnings introduced
- Code builds successfully
- Manual testing performed

### 6. Commit Your Changes

Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
type(scope): brief description

Longer description if needed, explaining the what and why.
Include motivation, context, and any important details.

Closes #123
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code formatting (no functional changes)
- `refactor:` - Code restructuring (no functional changes)
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks, dependencies, build config
- `perf:` - Performance improvements

**Examples:**
```bash
feat(quick-capture): add support for natural language date parsing

Implement parsing for relative dates like "tomorrow", "next week",
and absolute dates like "nov 20". Uses Foundation's date parsing
with custom patterns for common GTD phrases.

Closes #145
```

```bash
fix(task-store): prevent race condition in debounced saves

Tasks created immediately before app quit were being lost.
Added immediate flush of pending saves in applicationWillTerminate.

Fixes #234
```

### 7. Push and Create Pull Request

```bash
git push origin your-branch-name
```

Then create a pull request on GitHub with:

**Title**: Clear, descriptive summary
**Description**: Use this template:

```markdown
## Description
Brief summary of what this PR does and why.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement
- [ ] Test updates

## Related Issues
Closes #123
Relates to #456

## Changes Made
- List key changes
- In bullet points
- Be specific

## Testing Performed
- [ ] Unit tests added/updated
- [ ] All existing tests pass
- [ ] Manual testing completed
- Describe manual testing steps performed

## Screenshots (if applicable)
Add screenshots or recordings for UI changes

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review of code completed
- [ ] Comments added for complex logic
- [ ] Documentation updated (if needed)
- [ ] No new warnings introduced
- [ ] All tests passing
- [ ] Commit messages follow conventions
```

### 8. Respond to Feedback

- Be responsive to review comments
- Make requested changes promptly
- Push updates to the same branch
- Engage in constructive discussion
- Be open to alternative approaches

## Development Setup

### Prerequisites

- **Xcode 15.0 or later**
- **macOS 14.0 (Sonoma) or later**
- **Swift 5.9 or later**
- **Command Line Tools** installed

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/sticky-todo.git
   cd sticky-todo
   ```

2. **Open in Xcode**
   ```bash
   open StickyToDo.xcodeproj
   ```

3. **Install dependencies**
   - Dependencies are managed via Swift Package Manager
   - Xcode will automatically fetch dependencies on first build
   - Main dependency: [Yams](https://github.com/jpsim/Yams) for YAML parsing

4. **Build the project**
   - Select the "StickyToDo" scheme
   - Choose "My Mac" as destination
   - Press ⌘B to build
   - Press ⌘R to run

5. **Run tests**
   - Press ⌘U to run all tests
   - Or use Product → Test in Xcode menu

### Project Structure

```
StickyToDo/
├── StickyToDoCore/           # Core models (shared across targets)
│   ├── Models/               # Task, Board, Perspective, etc.
│   ├── Utilities/            # Helper classes and managers
│   ├── AppIntents/           # Siri Shortcuts integration
│   └── ImportExport/         # Import/export functionality
│
├── StickyToDo/               # Main SwiftUI app (legacy)
│
├── StickyToDo-SwiftUI/       # SwiftUI app implementation
│   ├── Views/                # UI components
│   └── Utilities/            # UI utilities
│
├── StickyToDo-AppKit/        # AppKit components for advanced UI
│
├── StickyToDoTests/          # Unit tests
│
├── Examples/                 # Example code and demonstrations
│
└── docs/                     # Documentation
```

### Detailed Setup

For detailed development environment setup, build configuration, and troubleshooting:
- See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for comprehensive development guide
- See [docs/BUILD_CONFIGURATION.md](docs/BUILD_CONFIGURATION.md) for build settings

## Code Style Guidelines

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these project-specific conventions:

### Naming Conventions

```swift
// Types: PascalCase
class TaskStore { }
struct Task { }
enum Status { }
protocol TaskDelegate { }

// Functions and properties: camelCase
func loadAllTasks() { }
var taskCount: Int
let defaultContext: String

// Constants: camelCase
let maxTaskCount = 1000
let defaultPriority = Priority.medium

// Enum cases: camelCase
enum Status {
    case inbox
    case nextAction
    case waitingFor
}

// Private properties: prefix with underscore is optional but acceptable
private var _cachedTasks: [Task] = []
```

### Code Organization

Use `// MARK:` comments to organize code:

```swift
struct Task {
    // MARK: - Core Properties

    let id: UUID
    var title: String

    // MARK: - GTD Metadata

    var status: Status
    var project: String?

    // MARK: - Initialization

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.status = .inbox
    }

    // MARK: - Public Methods

    func complete() {
        // Implementation
    }

    // MARK: - Private Methods

    private func validate() {
        // Implementation
    }
}
```

### Documentation Comments

Use triple-slash comments (`///`) for documentation:

```swift
/// Represents a task or note in the StickyToDo system.
///
/// Tasks are stored as markdown files with YAML frontmatter in the tasks/ directory.
/// The file system organization is: tasks/active/YYYY/MM/uuid-slug.md or tasks/archive/YYYY/MM/uuid-slug.md
struct Task: Identifiable, Codable {
    // ...
}

/// Creates a new task with the specified parameters.
///
/// - Parameters:
///   - title: The task title (required, must not be empty)
///   - status: Initial status (defaults to .inbox)
///   - project: Optional project assignment
/// - Returns: A newly created task with a unique ID
/// - Throws: TaskError.invalidTitle if title is empty
func createTask(title: String, status: Status = .inbox, project: String? = nil) throws -> Task {
    // Implementation
}
```

### Formatting

- **Indentation**: 4 spaces (no tabs)
- **Line Length**: Aim for 120 characters maximum (not strict)
- **Braces**: Opening brace on same line
  ```swift
  if condition {
      // code
  }
  ```
- **Spacing**: Space after commas, around operators
  ```swift
  let items = [1, 2, 3]
  let result = a + b
  ```

### Best Practices

1. **Prefer `let` over `var`**: Use immutability when possible
   ```swift
   let task = Task(title: "Example")  // Good
   var task = Task(title: "Example")  // Only if mutation needed
   ```

2. **Use guard for early returns**:
   ```swift
   guard let task = tasks.first(where: { $0.id == taskId }) else {
       return nil
   }
   ```

3. **Avoid force unwrapping**: Use optional binding or nil coalescing
   ```swift
   // Avoid
   let title = task!.title

   // Prefer
   guard let task = task else { return }
   let title = task.title
   ```

4. **Use type inference**: Let Swift infer types when clear
   ```swift
   let count = 5                    // Good
   let count: Int = 5               // Unnecessary
   let tasks: [Task] = []           // Good when type isn't obvious
   ```

5. **Meaningful names**: Use descriptive names
   ```swift
   // Avoid
   func proc(t: Task) -> Bool

   // Prefer
   func processTask(_ task: Task) -> Bool
   ```

### SwiftUI Conventions

```swift
struct TaskRowView: View {
    // MARK: - Properties

    let task: Task
    @Binding var isSelected: Bool
    @State private var isHovered = false

    // MARK: - Body

    var body: some View {
        HStack {
            statusIndicator
            taskTitle
            Spacer()
            dueDateBadge
        }
        .onHover { isHovered = $0 }
    }

    // MARK: - Subviews

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }

    private var taskTitle: some View {
        Text(task.title)
            .font(.body)
    }
}
```

## Testing Requirements

We maintain high test coverage to ensure reliability. All contributions should include appropriate tests.

### Test Coverage Goals

- **Models**: 90%+ coverage (core business logic)
- **Data Layer**: 85%+ coverage (persistence and I/O)
- **Stores**: 80%+ coverage (state management)
- **Views**: 60%+ coverage (UI components, harder to test)

### Writing Tests

Follow the **Arrange-Act-Assert** pattern:

```swift
func testTaskCompletion() {
    // Arrange
    let task = Task(title: "Test Task", status: .nextAction)

    // Act
    task.complete()

    // Assert
    XCTAssertEqual(task.status, .completed)
}
```

### Test Categories

**Model Tests** (`ModelTests.swift`):
```swift
func testTaskCreation() {
    let task = Task(title: "New Task")
    XCTAssertNotNil(task.id)
    XCTAssertEqual(task.status, .inbox)
    XCTAssertFalse(task.flagged)
}
```

**Data Layer Tests** (`MarkdownFileIOTests.swift`):
```swift
func testWriteAndReadTask() throws {
    let task = Task(title: "Test")
    try fileIO.writeTask(task)
    let loadedTask = try fileIO.readTask(from: taskURL)
    XCTAssertEqual(loadedTask?.title, "Test")
}
```

**Store Tests** (`TaskStoreTests.swift`):
```swift
func testAddTask() {
    let store = TaskStore()
    let task = Task(title: "New Task")
    store.add(task)
    XCTAssertEqual(store.tasks.count, 1)
    XCTAssertTrue(store.tasks.contains(where: { $0.id == task.id }))
}
```

### Running Tests

```bash
# All tests
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo

# Specific test class
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo \
  -only-testing:StickyToDoTests/ModelTests

# Single test
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo \
  -only-testing:StickyToDoTests/ModelTests/testTaskCreation

# With coverage
xcodebuild test -project StickyToDo.xcodeproj -scheme StickyToDo \
  -enableCodeCoverage YES
```

In Xcode:
- ⌘U - Run all tests
- ⌘⌥U - Run tests with coverage
- Click diamond in gutter - Run single test
- Product → Test - Run tests from menu

### Test Requirements for PRs

Your pull request must:
- Include tests for all new functionality
- Maintain or improve overall test coverage
- Have all tests passing
- Not skip or disable existing tests without justification

## Documentation

### When to Update Documentation

Update documentation when you:
- Add new features
- Change existing behavior
- Modify APIs or interfaces
- Add configuration options
- Change build or setup procedures

### Documentation Files

- **README.md**: Overview, installation, quick start
- **docs/DEVELOPMENT.md**: Architecture, development guide
- **docs/USER_GUIDE.md**: User-facing features and usage
- **docs/FILE_FORMAT.md**: Data format specification
- **docs/KEYBOARD_SHORTCUTS.md**: Keyboard shortcuts reference

### Code Comments

- Use `///` for public API documentation
- Use `//` for inline explanations
- Explain "why" not "what" when the code is clear
- Add comments for complex algorithms
- Document edge cases and assumptions

## Code Review Process

### Review Timeline

- Initial review within 3-5 business days
- Follow-up reviews within 1-2 business days
- Larger PRs may take longer

### What Reviewers Look For

1. **Correctness**: Does it work? Does it solve the problem?
2. **Tests**: Are there tests? Do they cover edge cases?
3. **Code Quality**: Is it readable? Does it follow conventions?
4. **Performance**: Are there any performance concerns?
5. **Security**: Are there any security implications?
6. **Documentation**: Is it documented appropriately?
7. **Breaking Changes**: Does it break existing functionality?

### Responding to Reviews

- Address all comments (even if just to discuss)
- Make requested changes or explain why not
- Mark conversations as resolved when addressed
- Request re-review when ready
- Be patient and professional

### Merging

PRs are merged when:
- All review comments addressed
- All tests passing
- At least one approval from a maintainer
- No merge conflicts
- CI checks passing (when available)

## Community and Support

### Getting Help

- **Documentation**: Check [docs/](docs/) first
- **Issues**: Search existing issues
- **Discussions**: Use GitHub Discussions for questions
- **Email**: Contact maintainers for sensitive issues

### Stay Connected

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General discussions and Q&A
- **Pull Requests**: Code contributions and reviews

### Recognition

Contributors are recognized in:
- [CREDITS.md](CREDITS.md) - All contributors listed
- Git commit history
- Release notes for significant contributions

## License

By contributing to StickyToDo, you agree that your contributions will be licensed under the MIT License, the same license as the project.

## Questions?

If you have questions about contributing, please:
1. Check this guide and other documentation
2. Search existing issues and discussions
3. Open a new discussion on GitHub
4. Contact the maintainers

Thank you for contributing to StickyToDo! We appreciate your time and effort in making this project better.

---

*Happy coding, and may your tasks be well-organized!*
