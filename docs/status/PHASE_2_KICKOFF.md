# StickyToDo Phase 2 Kickoff

**Document Version:** 1.0
**Date:** 2025-11-18
**Status:** Planning Phase
**Target Start:** After Phase 1 Release
**Estimated Duration:** 8-12 weeks

---

## Executive Summary

Phase 2 represents the evolution of StickyToDo from a solid macOS MVP to a production-grade, cross-platform productivity system. The primary focus is on scalability, performance optimization, and expanding platform support while maintaining the core philosophy of plain-text data ownership.

**Key Objectives:**
1. Migrate from in-memory storage to SQLite for better performance and scalability
2. Add iOS and iPadOS support with touch-optimized interfaces
3. Implement iCloud sync for seamless cross-device experience
4. Add advanced features deferred from Phase 1
5. Enhance existing features based on user feedback

**Success Criteria:**
- Support 5,000+ tasks without performance degradation
- Launch time remains < 2 seconds even with large datasets
- Successful cross-platform data synchronization
- App Store release on macOS, iOS, and iPadOS
- Maintain 100% plain-text compatibility

---

## Phase 1 Completion Summary

### What We Delivered

**Phase 1 MVP (100% Complete):**
- ✅ 93 Swift files, 37,000+ lines of code
- ✅ Complete GTD-style task management
- ✅ Dual-mode interface (List + Board views)
- ✅ Hybrid SwiftUI/AppKit architecture
- ✅ Plain-text markdown storage
- ✅ 60 FPS canvas performance
- ✅ Comprehensive test suite (80% coverage)
- ✅ Full documentation suite

**Validated Assumptions:**
- Plain-text architecture is viable and performant for 500-1000 tasks
- Hybrid SwiftUI/AppKit approach delivers excellent UX and performance
- In-memory data layer with file I/O meets MVP requirements
- Board-as-filter model eliminates data duplication effectively

**Known Limitations (Phase 1):**
- Performance degrades beyond ~1000 tasks (launch time, search)
- No iOS/iPadOS support
- No multi-device sync
- No collaboration features
- Limited import/export formats
- No subtasks or hierarchical task relationships
- No recurring tasks
- No attachments or rich media

---

## Phase 2 Goals & Features

### 2.1 Performance & Scalability (Priority: Critical)

**Goal:** Support 5,000+ tasks with excellent performance

#### SQLite Migration
**Rationale:** In-memory approach hits limits around 1000 tasks. SQLite provides:
- Fast indexed queries for search and filtering
- Efficient storage for large datasets
- Atomic transactions for data integrity
- Support for complex queries (JOIN, GROUP BY)
- Foundation for future features (full-text search, analytics)

**Implementation:**
- Design SQLite schema matching existing models
- Build migration layer from markdown → SQLite
- Maintain markdown export for data portability
- Keep plain-text as canonical source (with SQLite as cache)
- OR: Make SQLite primary with markdown export on-demand

**Decision Point:** Primary storage model
- **Option A:** SQLite as cache, markdown as source
  - Pros: Maintains plain-text philosophy, version control friendly
  - Cons: More complex sync logic, potential consistency issues
- **Option B:** SQLite as primary, markdown export on demand
  - Pros: Simpler architecture, better performance, easier sync
  - Cons: Loses always-readable plain-text guarantee

**Recommendation:** Option B with robust export tools

#### Performance Targets
- Launch time: < 2s with 5,000 tasks
- Search results: < 100ms for any query
- UI responsiveness: 60 FPS maintained
- File save: < 50ms per task
- Sync time: < 5s for 100 changes

**Estimated Effort:** 3-4 weeks

---

### 2.2 iOS & iPadOS Support (Priority: High)

**Goal:** Native apps for iPhone and iPad with touch-optimized UX

#### Shared Codebase Architecture
- Maximize code reuse from macOS app
- StickyToDoCore framework works across all platforms (models, data layer)
- Platform-specific UI layers (macOS, iOS, iPadOS)
- Shared business logic and state management

**Platform-Specific UI:**

**iOS (iPhone):**
- Single-pane navigation with drill-down
- Bottom tab bar (Inbox, Next Actions, Projects, Boards, Settings)
- Swipe gestures for task actions (complete, defer, delete)
- Pull-to-refresh for sync
- Quick capture via Today widget or Shortcuts integration
- Optimized for one-handed use

**iPadOS (iPad):**
- Three-column layout (Sidebar, List, Inspector)
- Drag-and-drop between panes
- Split view and Slide Over support
- Apple Pencil support for board sketching
- Keyboard shortcuts (Smart Keyboard/Magic Keyboard)
- Optimized for multitasking

**Touch Interactions for Board View:**
- Tap to select note
- Drag to move note
- Pinch to zoom
- Two-finger pan
- Long-press for context menu
- Double-tap to edit
- Lasso select (circle gesture with pencil)

**Challenges:**
- Canvas performance on lower-end devices
- Gesture conflicts (pan vs scroll vs drag)
- Keyboard handling when external keyboard connected/disconnected
- Adapting AppKit canvas to UIKit

**Estimated Effort:** 4-5 weeks

---

### 2.3 iCloud Sync (Priority: High)

**Goal:** Seamless sync across all user devices

#### Sync Architecture

**Option A: CloudKit**
- Apple's native sync framework
- Pros: Native integration, automatic conflict resolution, good performance
- Cons: Apple ecosystem only, complex debugging

**Option B: Custom Sync (CloudKit + Markdown)**
- Use CloudKit to sync markdown files directly
- Pros: Maintains plain-text compatibility, simpler model
- Cons: Manual conflict resolution, potential sync conflicts

**Option C: Hybrid (SQLite + CloudKit)**
- Sync SQLite changes via CloudKit
- Export markdown on demand for backup/portability
- Pros: Best performance, native sync
- Cons: Most complex, less portable

**Recommendation:** Option C (Hybrid) for best UX

#### Conflict Resolution
- Last-write-wins for simple properties
- Merge for list-based properties (contexts, tags)
- User prompt for conflicting edits to same field
- Automatic sync on app launch and every 5 minutes
- Manual sync trigger available

#### Offline Support
- Full offline editing capability
- Queue changes for sync when online
- Optimistic UI updates
- Sync status indicator
- Conflict resolution on reconnect

**Estimated Effort:** 3-4 weeks

---

### 2.4 Advanced Features (Priority: Medium)

Features deferred from Phase 1, now ready for implementation:

#### 2.4.1 Subtasks & Hierarchical Tasks
- Parent-child task relationships
- Nested task rendering in list view
- Drag tasks to create parent-child relationships
- Rollup of subtask completion status
- Outline-style expand/collapse

**Implementation:**
- Add `parentId` field to Task model
- Update SQLite schema with foreign key
- Build recursive query for task trees
- UI: Indent/outdent buttons, drag to nest

**Estimated Effort:** 1-2 weeks

#### 2.4.2 Recurring Tasks
- Repeat patterns (daily, weekly, monthly, yearly)
- Custom repeat rules (every 2 weeks, weekdays only)
- Regenerate task on completion
- Skip/postpone single occurrence
- Template-based creation

**Implementation:**
- Add `recurrence` field with rule specification
- Cron-like syntax for complex patterns
- Background task generator
- Modification to single vs all instances

**Estimated Effort:** 2 weeks

#### 2.4.3 Attachments & Rich Media
- Attach files to tasks
- Image thumbnails in task row
- PDFs, documents, images, videos
- iCloud storage for attachments
- Drag-and-drop to attach

**Implementation:**
- Attachment model (id, taskId, filename, type, size)
- File storage (local + iCloud)
- UI for attachment gallery
- Preview integration (Quick Look)

**Estimated Effort:** 2 weeks

#### 2.4.4 Full-Text Search
- Search across task titles, notes, and attachments
- Search syntax with filters (project:X due:today)
- Instant results with search-as-you-type
- Recent searches saved
- Search results with context highlighting

**Implementation:**
- SQLite FTS5 extension
- Build search index
- Parse search query syntax
- Highlight matching text

**Estimated Effort:** 1-2 weeks

#### 2.4.5 Task Templates
- Reusable task templates for common workflows
- Template variables ({{date}}, {{project}})
- Multi-task templates (checklists)
- Template library
- Share templates

**Implementation:**
- Template model and storage
- Variable substitution engine
- Template picker UI
- Import/export templates

**Estimated Effort:** 1 week

#### 2.4.6 Tags System
- Freeform tags separate from contexts
- Tag autocomplete
- Tag-based filtering and smart boards
- Tag hierarchy (work.urgent, work.someday)
- Tag cloud visualization

**Implementation:**
- Tags as array of strings
- Tag index in SQLite
- Tag autocomplete from existing tags
- Tag filter UI

**Estimated Effort:** 1 week

#### 2.4.7 Time Tracking
- Start/stop timer on tasks
- Automatic time logging
- Time estimates vs actuals
- Daily/weekly time reports
- Integration with Calendar

**Implementation:**
- TimeEntry model (taskId, start, end, duration)
- Timer UI in inspector
- Background timer notification
- Reporting and analytics

**Estimated Effort:** 2 weeks

**Total Advanced Features Effort:** 10-12 weeks (can be parallelized or staged)

---

### 2.5 Enhanced Existing Features (Priority: Low-Medium)

#### 2.5.1 Board Enhancements
- More layout types (timeline, eisenhower matrix, mindmap)
- Board backgrounds and themes
- Board sharing and collaboration (future Phase 3)
- Board templates
- Enhanced sticky note styling (colors, sizes, shapes)

**Estimated Effort:** 2-3 weeks

#### 2.5.2 Perspectives Enhancements
- Custom perspective builder UI
- More filter operators (contains, starts with, regex)
- Perspective templates and sharing
- Grouped perspectives (folders)
- Perspective-specific views (list, kanban, calendar)

**Estimated Effort:** 1-2 weeks

#### 2.5.3 Import/Export Enhancements
- More formats: Things, Todoist, Asana, Trello
- Bi-directional sync with external services
- Automated backups
- Versioning and restore
- Bulk operations (archive old tasks, mass edit)

**Estimated Effort:** 2 weeks

#### 2.5.4 Reporting & Analytics
- Task completion trends
- Time to completion statistics
- Project burn-down charts
- Context utilization
- Weekly review assistance

**Estimated Effort:** 2-3 weeks

---

## Architecture Changes

### 3.1 Data Layer Architecture (Post-SQLite)

```
┌─────────────────────────────────────────────────────┐
│                  Application Layer                   │
│         (SwiftUI Views, AppKit Canvas)              │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              State Management Layer                  │
│     (TaskStore, BoardStore, ObservableObjects)      │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│               Business Logic Layer                   │
│         (DataManager, SyncManager, etc.)            │
└──────┬────────────────────────────────────┬─────────┘
       │                                    │
┌──────▼─────────────┐           ┌─────────▼──────────┐
│  SQLite Repository │           │  CloudKit Sync     │
│  (Local Database)  │◄─────────►│   (Remote Data)    │
└────────────────────┘           └────────────────────┘
       │                                    │
┌──────▼─────────────┐           ┌─────────▼──────────┐
│ Markdown Exporter  │           │  iCloud Container  │
│  (Backup/Export)   │           │   (File Storage)   │
└────────────────────┘           └────────────────────┘
```

### 3.2 SQLite Schema Design

```sql
-- Tasks Table
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('note', 'task')),
    status TEXT NOT NULL CHECK(status IN ('inbox', 'next', 'waiting', 'someday', 'done')),
    priority INTEGER,
    project TEXT,
    defer_date INTEGER,  -- Unix timestamp
    due_date INTEGER,
    completed_date INTEGER,
    created_date INTEGER NOT NULL,
    modified_date INTEGER NOT NULL,
    effort INTEGER,
    notes TEXT,
    parent_id TEXT,  -- For subtasks
    recurrence TEXT,  -- Recurrence rule
    FOREIGN KEY (parent_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- Task-Context junction table (many-to-many)
CREATE TABLE task_contexts (
    task_id TEXT NOT NULL,
    context TEXT NOT NULL,
    PRIMARY KEY (task_id, context),
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- Task-Tags junction table (many-to-many)
CREATE TABLE task_tags (
    task_id TEXT NOT NULL,
    tag TEXT NOT NULL,
    PRIMARY KEY (task_id, tag),
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- Boards Table
CREATE TABLE boards (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('smart', 'custom')),
    layout TEXT NOT NULL CHECK(layout IN ('freeform', 'kanban', 'grid')),
    icon TEXT,
    color TEXT,
    filter_json TEXT,  -- Serialized filter rules
    created_date INTEGER NOT NULL,
    modified_date INTEGER NOT NULL
);

-- Board Positions (for freeform layout)
CREATE TABLE board_positions (
    board_id TEXT NOT NULL,
    task_id TEXT NOT NULL,
    x REAL NOT NULL,
    y REAL NOT NULL,
    width REAL,
    height REAL,
    PRIMARY KEY (board_id, task_id),
    FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- Attachments Table
CREATE TABLE attachments (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    filename TEXT NOT NULL,
    mime_type TEXT,
    file_size INTEGER,
    cloud_url TEXT,  -- iCloud reference
    created_date INTEGER NOT NULL,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- Time Entries Table
CREATE TABLE time_entries (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    start_time INTEGER NOT NULL,
    end_time INTEGER,
    duration INTEGER,  -- Seconds
    notes TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- Sync Metadata Table
CREATE TABLE sync_metadata (
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    last_synced INTEGER,
    cloud_record_id TEXT,
    conflict_state TEXT,
    PRIMARY KEY (entity_type, entity_id)
);

-- Full-text search index
CREATE VIRTUAL TABLE tasks_fts USING fts5(
    id UNINDEXED,
    title,
    notes,
    content='tasks',
    content_rowid='rowid'
);

-- Indexes for performance
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_project ON tasks(project);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_parent_id ON tasks(parent_id);
CREATE INDEX idx_task_contexts_context ON task_contexts(context);
CREATE INDEX idx_task_tags_tag ON task_tags(tag);
CREATE INDEX idx_attachments_task_id ON attachments(task_id);
CREATE INDEX idx_time_entries_task_id ON time_entries(task_id);
```

### 3.3 Migration Strategy

**Phase 2.1: SQLite Foundation (Weeks 1-2)**
- Implement SQLite schema
- Build repository layer (CRUD operations)
- Create migration from markdown to SQLite
- Build SQLite → markdown export

**Phase 2.2: Integration (Weeks 3-4)**
- Replace FileIO with SQLite in DataManager
- Update TaskStore/BoardStore to use repositories
- Maintain markdown export for compatibility
- Comprehensive testing with existing data

**Phase 2.3: Optimization (Week 5)**
- Add indexes and query optimization
- Implement full-text search
- Performance testing and tuning
- Migration tools and documentation

### 3.4 Multi-Platform Code Organization

```
StickyToDo/
├── Shared/                          # Cross-platform code
│   ├── StickyToDoCore/             # Models, data layer (100% shared)
│   │   ├── Models/
│   │   ├── Data/
│   │   │   ├── SQLite/
│   │   │   ├── CloudKit/
│   │   │   └── Repositories/
│   │   └── Utilities/
│   ├── ViewModels/                 # Business logic (90% shared)
│   └── Extensions/                 # Swift extensions (100% shared)
│
├── macOS/                          # macOS-specific
│   ├── Views/                      # SwiftUI views (70% shared with iOS)
│   ├── AppKit/                     # AppKit canvas (macOS only)
│   ├── MenuBar/                    # Menu commands
│   └── StickyToDo-macOS.swift     # App entry point
│
├── iOS/                            # iOS-specific
│   ├── Views/                      # SwiftUI views adapted for iOS
│   ├── Widgets/                    # Today widget
│   ├── Shortcuts/                  # Siri Shortcuts
│   └── StickyToDo-iOS.swift       # App entry point
│
├── iPadOS/                         # iPadOS-specific (shares most with iOS)
│   ├── Views/                      # iPad-optimized layouts
│   └── Canvas/                     # Touch-optimized canvas
│
└── Tests/                          # Test targets
    ├── SharedTests/                # Core tests (run on all platforms)
    ├── macOSTests/
    └── iOSTests/
```

---

## Timeline & Milestones

### Phase 2 Roadmap (12 weeks)

**Weeks 1-4: Foundation**
- Week 1: SQLite schema and repository layer
- Week 2: Migration tools and testing
- Week 3: Integration with existing app
- Week 4: Performance optimization and tuning

**Milestone 1:** SQLite migration complete, app running on new data layer

**Weeks 5-8: Multi-Platform**
- Week 5: iOS app skeleton and shared code extraction
- Week 6: iOS UI implementation (list views, perspectives)
- Week 7: iPad UI implementation (multi-pane layout)
- Week 8: Touch-optimized canvas for iOS/iPadOS

**Milestone 2:** iOS and iPadOS apps functional with local data

**Weeks 9-10: Sync**
- Week 9: CloudKit integration and sync logic
- Week 10: Conflict resolution and offline support

**Milestone 3:** iCloud sync working across all platforms

**Weeks 11-12: Advanced Features & Polish**
- Week 11: Priority advanced features (subtasks, recurring tasks)
- Week 12: Testing, bug fixes, documentation

**Milestone 4:** Phase 2 feature-complete, ready for beta testing

### Optional Extensions (Choose based on priorities)
- +2 weeks: Full-text search and templates
- +2 weeks: Attachments and time tracking
- +2 weeks: Enhanced boards and perspectives
- +3 weeks: Additional import/export formats
- +2 weeks: Reporting and analytics

---

## Risk Assessment & Mitigation

### Technical Risks

**Risk 1: SQLite Migration Data Loss**
- **Impact:** Critical
- **Likelihood:** Low
- **Mitigation:**
  - Comprehensive backup before migration
  - Extensive testing with sample data
  - Ability to rollback to markdown
  - Migration validation step

**Risk 2: CloudKit Sync Complexity**
- **Impact:** High
- **Likelihood:** Medium
- **Mitigation:**
  - Start with simple last-write-wins
  - Incremental rollout (beta users first)
  - Robust conflict resolution UI
  - Manual sync override option

**Risk 3: iOS Performance on Canvas**
- **Impact:** Medium
- **Likelihood:** Medium
- **Mitigation:**
  - Early performance testing on target devices
  - Viewport culling and lazy rendering
  - Simplified rendering for lower-end devices
  - Metal rendering investigation

**Risk 4: Multi-Platform Code Divergence**
- **Impact:** Medium
- **Likelihood:** High
- **Mitigation:**
  - Maximize shared code from start
  - Unified testing across platforms
  - Code reviews for platform-specific changes
  - Refactoring budget

**Risk 5: App Store Rejection**
- **Impact:** High
- **Likelihood:** Low
- **Mitigation:**
  - Review guidelines early and often
  - Privacy policy and data handling clear
  - Test on physical devices
  - Beta testing via TestFlight

### Business Risks

**Risk 6: Feature Creep**
- **Impact:** High
- **Likelihood:** High
- **Mitigation:**
  - Strict prioritization (must-have vs nice-to-have)
  - Time-boxing for feature development
  - Regular scope reviews
  - Phase 3 parking lot for deferred features

**Risk 7: Market Changes**
- **Impact:** Medium
- **Likelihood:** Medium
- **Mitigation:**
  - Monitor competitor releases
  - Regular user feedback loops
  - Flexible roadmap adjustments
  - MVP mindset (ship and iterate)

---

## Success Metrics

### Performance Metrics
- [ ] Launch time < 2s with 5,000 tasks
- [ ] Search results < 100ms
- [ ] Sync time < 5s for 100 changes
- [ ] UI 60 FPS on all platforms
- [ ] Battery impact < 5% per hour of active use (iOS)

### Feature Metrics
- [ ] All Phase 1 features available on iOS/iPadOS
- [ ] Sync success rate > 99.9%
- [ ] Data migration success rate 100%
- [ ] Zero data loss incidents
- [ ] Advanced features adoption > 30%

### Quality Metrics
- [ ] Test coverage > 80%
- [ ] Crash-free rate > 99.5%
- [ ] App Store rating > 4.5 stars
- [ ] Critical bugs resolved within 48 hours
- [ ] User-reported sync conflicts < 1%

### Adoption Metrics
- [ ] iOS downloads > 50% of macOS downloads
- [ ] Multi-device users > 40% of user base
- [ ] Daily active users increased by 2x
- [ ] Retention rate (30-day) > 60%

---

## Dependencies & Prerequisites

### Before Starting Phase 2

**Code Completion:**
- [ ] Phase 1 released and stable
- [ ] All critical bugs resolved
- [ ] Performance baselines established
- [ ] Documentation complete

**Infrastructure:**
- [ ] Apple Developer Program membership
- [ ] CloudKit container configured
- [ ] TestFlight set up for beta testing
- [ ] Crash reporting service configured (Crashlytics, Sentry)
- [ ] Analytics infrastructure (if applicable)

**Team:**
- [ ] iOS developer familiar with SwiftUI
- [ ] Database engineer for SQLite optimization
- [ ] QA resource for multi-platform testing
- [ ] Technical writer for documentation

**Resources:**
- [ ] Test devices (iPhone, iPad, multiple Mac models)
- [ ] Beta tester pool recruited
- [ ] App Store assets (screenshots, videos, descriptions)

---

## Decision Points

### Critical Decisions Needed Before Phase 2

**Decision 1: Primary Data Storage**
- [ ] SQLite as primary with markdown export
- [ ] Markdown as primary with SQLite cache
- **Deadline:** Week 1

**Decision 2: Sync Strategy**
- [ ] CloudKit native
- [ ] CloudKit + markdown files
- [ ] Hybrid SQLite + CloudKit
- **Deadline:** Week 1

**Decision 3: Platform Priority**
- [ ] macOS first, then iOS/iPadOS
- [ ] All platforms simultaneously
- [ ] iOS first, then macOS enhancements
- **Deadline:** Before Phase 2 start

**Decision 4: Feature Set**
- [ ] Full feature parity across platforms
- [ ] Core features on all, advanced features on macOS
- [ ] Platform-specific feature sets
- **Deadline:** Week 4

**Decision 5: Monetization**
- [ ] Free with optional tips
- [ ] Freemium (free + paid features)
- [ ] Paid upfront
- [ ] Subscription
- **Deadline:** Before App Store submission

---

## Communication & Collaboration

### Stakeholder Updates
- **Weekly:** Progress reports to project owner
- **Bi-weekly:** Demo of completed features
- **Monthly:** Roadmap review and adjustment

### User Feedback
- **Beta Program:** Recruit 50-100 beta testers
- **Feedback Channels:** In-app feedback, email, forums
- **Survey:** Monthly user satisfaction survey

### Documentation
- **Internal:** Architecture decision records (ADRs)
- **External:** Migration guides, API changes, new features
- **User:** Updated user guide, video tutorials, FAQs

---

## Transition from Phase 1 to Phase 2

### Immediate Actions (Week 0)
1. Create Phase 2 branch: `git checkout -b phase-2/sqlite-migration`
2. Set up SQLite dependencies (SQLite.swift or GRDB)
3. Design SQLite schema (review and finalize)
4. Create migration test data set
5. Set up CloudKit container in Apple Developer portal
6. Recruit beta testers
7. Finalize Phase 2 priorities and timeline

### Knowledge Transfer
- Review all Phase 1 documentation
- Code walkthrough sessions for new team members
- Architecture deep-dive presentations
- Set up development environment for all platforms

### Phase 1 Maintenance Plan
- Security updates only during Phase 2 development
- Critical bug fixes on maintenance branch
- No new features in Phase 1
- Merge critical fixes to Phase 2 branch

---

## Appendix

### A. Technology Stack (Phase 2)

**Core:**
- Swift 5.9+
- SwiftUI (iOS 17+, macOS 14+)
- AppKit (macOS 13+)
- UIKit (for iPad-specific features)

**Data:**
- SQLite 3.x
- GRDB or SQLite.swift (wrapper library)
- CloudKit (sync)
- Core Data (considered but rejected in favor of SQLite)

**Platform:**
- Xcode 15+
- iOS 17+, iPadOS 17+, macOS 14+
- Swift Package Manager

**Services:**
- iCloud (sync and storage)
- CloudKit (data sync)
- StoreKit (if monetization needed)

**Development:**
- Git / GitHub
- TestFlight (beta distribution)
- Instruments (performance profiling)

### B. Recommended Reading

**SQLite:**
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [GRDB Documentation](https://github.com/groue/GRDB.swift)
- "Using SQLite" by Jay A. Kreibich

**CloudKit:**
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [CloudKit Design Guide](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/)
- WWDC sessions on CloudKit

**Multi-Platform SwiftUI:**
- [SwiftUI Essentials](https://developer.apple.com/tutorials/swiftui)
- "SwiftUI for Masterminds" by J.D. Gauchat
- Platform-specific Human Interface Guidelines

### C. Phase 3 Preview (Future)

Features deferred to Phase 3:
- Collaboration and sharing
- Team workspaces
- Real-time sync and presence
- Web interface
- Third-party integrations (Zapier, webhooks)
- AI-powered features (smart categorization, suggestions)
- Advanced analytics and insights
- Custom theming and branding

---

## Sign-Off

**Phase 2 Plan Approved By:**

- [ ] Product Owner: _________________ Date: _________
- [ ] Technical Lead: _________________ Date: _________
- [ ] Design Lead: _________________ Date: _________
- [ ] QA Lead: _________________ Date: _________

**Ready to Start Phase 2:** ☐ Yes  ☐ No

**If No, blocking issues:**
___________________________________________________________________
___________________________________________________________________
___________________________________________________________________

---

**Document Status:** Draft → Review → Approved → In Progress
**Current Status:** Ready for Review
**Last Updated:** 2025-11-18
**Next Review:** Before Phase 2 Start

For questions or feedback, contact the project team or refer to:
- Phase 1 Handoff: `HANDOFF.md`
- Integration Verification: `docs/INTEGRATION_VERIFICATION.md`
- Project Summary: `PROJECT_SUMMARY.md`
