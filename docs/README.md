# StickyToDo Documentation

Welcome to the StickyToDo documentation hub. This directory contains comprehensive documentation for users, developers, and contributors.

## Quick Navigation

### For Users
Start here if you're using StickyToDo to manage your tasks.

- **[User Documentation](user/)** - Complete user guides and quick references
  - [User Guide](user/USER_GUIDE.md) - Complete usage documentation
  - [Quick Reference](user/QUICK_REFERENCE.md) - Quick reference guide
  - [Keyboard Shortcuts](user/KEYBOARD_SHORTCUTS.md) - All keyboard shortcuts
  - [Feature Guides](user/) - Siri Shortcuts, Search, Recurring Tasks, Batch Editing, Dark Mode

### For Developers
Start here if you're contributing to StickyToDo or building from source.

- **[Developer Documentation](developer/)** - Development setup and guidelines
  - [Development Guide](developer/DEVELOPMENT.md) - Contributing and architecture
  - [Build Setup](developer/BUILD_SETUP.md) - Building the project
  - [Xcode Setup](developer/XCODE_SETUP.md) - Xcode configuration

### For Technical Reference
Start here for technical specifications and architecture details.

- **[Technical Documentation](technical/)** - Specifications and architecture
  - [File Format](technical/FILE_FORMAT.md) - Task file format specification
  - [Search Architecture](technical/SEARCH_ARCHITECTURE.txt) - Search system design
  - [Integration Guides](technical/) - Integration and testing documentation

## Documentation Categories

### [user/](user/) - User Documentation
User-facing documentation including guides, quick references, and feature tutorials.
- User guides and walkthroughs
- Quick reference cards
- Keyboard shortcut lists
- Feature-specific guides (Siri, Search, Recurring Tasks, Batch Editing, Dark Mode)

### [developer/](developer/) - Developer Documentation
Documentation for developers contributing to StickyToDo.
- Development environment setup
- Build configuration
- Xcode and iOS development
- Dependencies and assets
- Contribution guidelines

### [technical/](technical/) - Technical Documentation
Technical specifications, architecture documentation, and integration guides.
- File format specifications
- System architecture
- Integration and testing guides
- Comparisons and analysis

### [implementation/](implementation/) - Implementation Reports
Detailed reports documenting feature implementation and integration.
- Core features (data layer, file watching)
- Search and filtering
- Task features (recurring tasks, inspector)
- Integration (calendar, PDF export, analytics)
- iOS and Siri
- Automation (rules, batch editing)
- UI features (dark mode)
- Status and planning

### [status/](status/) - Project Status & Progress
Project status reports, completion summaries, and progress tracking.
- Project summaries
- Phase reports
- Polish and setup
- Change tracking

### [assessments/](assessments/) - Assessment Reports
Comprehensive assessment and review reports.
- Code and quality reviews
- Performance analysis
- Documentation reviews
- Outstanding work and opportunities

### [plans/](plans/) - Plans & Design Documents
Project planning and design documents.
- Design documents
- Architecture plans
- Strategic planning

### [features/](features/) - Feature Documentation
Feature-specific documentation and specifications.
- Task hierarchy
- Feature descriptions

### [examples/](examples/) - Examples
Example files and demonstrations.
- Task examples
- Subtask examples
- Use case demonstrations

### [handoff/](handoff/) - Handoff Documentation
Project handoff documentation and historical reference materials.
- Knowledge transfer guides
- Visual examples
- Historical documentation

### [pull-requests/](pull-requests/) - Pull Request Documentation
Pull request descriptions and related documentation.
- PR templates
- Phase-specific PRs
- PR descriptions

## Documentation Structure

```
docs/
├── README.md                    # This file - documentation hub
├── assessments/                 # Assessment reports
│   ├── index.md
│   ├── COMPREHENSIVE_CODE_REVIEW.md
│   ├── COMPREHENSIVE_STATUS_REVIEW.md
│   ├── DOCUMENTATION_REVIEW_REPORT.md
│   ├── PERFORMANCE_REVIEW.md
│   ├── PERFORMANCE_MONITORING_REPORT.md
│   ├── OUTSTANDING_WORK_ASSESSMENT.md
│   └── FEATURE_OPPORTUNITIES_REPORT.md
├── developer/                   # Developer documentation
│   ├── index.md
│   ├── DEVELOPMENT.md
│   ├── BUILD_SETUP.md
│   ├── BUILD_CONFIGURATION.md
│   ├── XCODE_SETUP.md
│   ├── XCODE_BUILD_CONFIGURATION_REPORT.md
│   ├── INFO_PLIST_CONFIGURATION_REPORT.md
│   ├── YAMS_DEPENDENCY_SETUP.md
│   └── ASSETS.md
├── examples/                    # Example files
│   ├── index.md
│   ├── task-with-subtasks.md
│   └── subtask-example.md
├── features/                    # Feature documentation
│   ├── index.md
│   └── task-hierarchy.md
├── handoff/                     # Handoff documentation
│   ├── index.md
│   ├── HANDOFF.md
│   └── PDF_EXPORT_VISUAL_EXAMPLE.md
├── implementation/              # Implementation reports
│   ├── index.md
│   ├── DATA_LAYER_IMPLEMENTATION_SUMMARY.md
│   ├── SETUP_DATA_LAYER.md
│   ├── FILE_WATCHER_CONFLICT_RESOLUTION_REPORT.md
│   ├── SEARCH_IMPLEMENTATION_REPORT.md
│   ├── SEARCH_FILE_MANIFEST.md
│   ├── PERSPECTIVES_IMPLEMENTATION.md
│   ├── RECURRING_TASKS_SUMMARY.md
│   ├── RecurringTasksImplementation.md
│   ├── RECURRING_TASKS_UI_COMPLETION_REPORT.md
│   ├── TASKINSPECTOR_IMPLEMENTATION_REPORT.md
│   ├── TASKINSPECTOR_COMPLETION_SUMMARY.md
│   ├── CALENDAR_INTEGRATION_REPORT.md
│   ├── PDF_EXPORT_IMPLEMENTATION_REPORT.md
│   ├── PDF_EXPORT_SUMMARY.md
│   ├── EXPORT_ANALYTICS_IMPLEMENTATION.md
│   ├── SIRI_SHORTCUTS_IMPLEMENTATION.md
│   ├── SIRI_SHORTCUTS_FILES.md
│   ├── ONBOARDING_WIRING_REPORT.md
│   ├── AUTOMATION_RULES.md
│   ├── IMPLEMENTATION_SUMMARY_AUTOMATION.md
│   ├── BATCH_EDIT_IMPLEMENTATION.md
│   ├── BATCH_EDIT_IMPLEMENTATION_SUMMARY.md
│   ├── DARK_MODE_IMPLEMENTATION_REPORT.md
│   ├── IMPLEMENTATION_STATUS.md
│   ├── IMPLEMENTATION_PLAN.md
│   ├── INTEGRATION_COMPLETE.md
│   └── phase2-subtasks-implementation.md
├── plans/                       # Plans and design
│   ├── index.md
│   ├── 2025-11-17-sticky-todo-design.md
│   └── ICLOUD_SYNC_ARCHITECTURE_PLAN.md
├── pull-requests/               # Pull request docs
│   ├── index.md
│   ├── PULL_REQUEST.md
│   ├── PR_DESCRIPTION.md
│   └── PR_PHASE_2_3.md
├── status/                      # Project status
│   ├── index.md
│   ├── PROJECT_SUMMARY.md
│   ├── PROJECT_COMPLETION_SUMMARY.md
│   ├── NEXT_STEPS.md
│   ├── PHASE_2_KICKOFF.md
│   ├── PHASE2_SUBTASKS_SUMMARY.md
│   ├── PHASE3_COMPLETION_REPORT.md
│   ├── FINAL_POLISH.md
│   ├── POLISH_AND_SETUP_SUMMARY.md
│   ├── QUICK_START_POLISH.md
│   ├── CHANGES_SUMMARY.md
│   └── BEFORE_AFTER_COMPARISON.md
├── technical/                   # Technical specs
│   ├── index.md
│   ├── FILE_FORMAT.md
│   ├── SEARCH_ARCHITECTURE.txt
│   ├── INTEGRATION_GUIDE.md
│   ├── INTEGRATION_TEST_PLAN.md
│   ├── INTEGRATION_VERIFICATION.md
│   └── COMPARISON.md
└── user/                        # User documentation
    ├── index.md
    ├── USER_GUIDE.md
    ├── QUICK_REFERENCE.md
    ├── KEYBOARD_SHORTCUTS.md
    ├── SIRI_SHORTCUTS_GUIDE.md
    ├── SEARCH_QUICK_REFERENCE.md
    ├── RecurringTasksQuickStart.md
    ├── YAMS_QUICK_REFERENCE.md
    ├── DARK_MODE_QUICK_START.md
    ├── BATCH_EDIT_QUICK_REFERENCE.md
    └── BATCH_EDIT_VISUAL_GUIDE.md
```

## Finding What You Need

### "I want to use StickyToDo"
→ Start with [user/USER_GUIDE.md](user/USER_GUIDE.md) for comprehensive usage documentation
→ See [user/QUICK_REFERENCE.md](user/QUICK_REFERENCE.md) for quick reference

### "I want to contribute code"
→ Start with [developer/DEVELOPMENT.md](developer/DEVELOPMENT.md)
→ See [developer/BUILD_SETUP.md](developer/BUILD_SETUP.md) to build the project

### "I want to understand how it works"
→ Start with [technical/FILE_FORMAT.md](technical/FILE_FORMAT.md) for the data format
→ See [plans/2025-11-17-sticky-todo-design.md](plans/2025-11-17-sticky-todo-design.md) for design philosophy

### "I want to understand a specific feature"
→ Check [implementation/](implementation/) for feature implementation reports
→ Check [user/](user/) for user-facing feature guides

### "I want to know the project status"
→ See [status/PROJECT_SUMMARY.md](status/PROJECT_SUMMARY.md)
→ See [status/NEXT_STEPS.md](status/NEXT_STEPS.md) for upcoming work

### "I'm taking over this project"
→ Start with [handoff/HANDOFF.md](handoff/HANDOFF.md)
→ Review [assessments/](assessments/) for code and quality reviews

## Document Types

### Guides
Step-by-step instructions for accomplishing tasks.
- Found in: `user/`, `developer/`
- Examples: USER_GUIDE.md, DEVELOPMENT.md, BUILD_SETUP.md

### Quick References
Condensed reference materials for quick lookup.
- Found in: `user/`
- Examples: QUICK_REFERENCE.md, KEYBOARD_SHORTCUTS.md

### Reports
Detailed documentation of completed work.
- Found in: `implementation/`, `assessments/`, `status/`
- Examples: Implementation reports, code reviews, status summaries

### Specifications
Technical specifications and data formats.
- Found in: `technical/`
- Examples: FILE_FORMAT.md, SEARCH_ARCHITECTURE.txt

### Plans
Design documents and strategic planning.
- Found in: `plans/`
- Examples: Design documents, architecture plans

## Contributing to Documentation

When adding documentation:
1. Place it in the appropriate category directory
2. Update the category's `index.md` file
3. Use clear, descriptive filenames
4. Follow existing formatting conventions
5. Link to related documents

### Documentation Guidelines
- Use Markdown format (.md)
- Include a clear title and purpose
- Provide a table of contents for long documents
- Link to related documentation
- Keep user docs separate from developer docs
- Update index files when adding new documents

## Support

- **Main README**: [../README.md](../README.md)
- **Contributing**: [../CONTRIBUTING.md](../CONTRIBUTING.md)
- **Credits**: [../CREDITS.md](../CREDITS.md)
- **License**: [../LICENSE](../LICENSE)

## Version

**Documentation Version**: 1.0
**Last Updated**: 2025-11-18
**Status**: Complete and Organized

---

**Your tasks. Your format. Your control.**
