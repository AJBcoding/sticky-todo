# StickyToDo - Integration Test Plan

**Date**: 2025-11-18
**Project Status**: ~97% Complete
**Purpose**: Comprehensive manual and automated testing plan for Phase 1-3 MVP features

---

## Executive Summary

This document outlines the complete integration testing strategy for StickyToDo, covering all 21 advanced features, UI integration work, AppKit canvas, and onboarding flow. The testing phase ensures all components work together correctly before beta release.

### Testing Scope
- ✅ Phase 1: UI Integration (6 workstreams, 21 features)
- ✅ Phase 2: AppKit Canvas + Build Configuration
- ✅ Phase 3: First-Run Experience
- 🔄 Phase 4: Integration Testing (this document)

### Timeline
- **Duration**: 2 weeks
- **Week 1**: Core functionality + Advanced features
- **Week 2**: Edge cases + Performance + Bug fixes

---

## Testing Environment Setup

### Prerequisites
1. **Xcode Configuration**
   - Follow `XCODE_SETUP.md` for initial setup
   - Add Yams package dependency
   - Configure Info.plist with required keys
   - Enable all capabilities

2. **Test Data Preparation**
   - Clean install test (no existing data)
   - Migration test (with existing data)
   - Large dataset test (500+ tasks)
   - Performance test dataset (1000+ tasks)

3. **System Permissions**
   - Grant Siri access
   - Grant Notification permissions
   - Grant Calendar access
   - Enable Spotlight indexing

4. **Testing Tools**
   - Manual testing checklist (this document)
   - Performance monitoring (Instruments)
   - Memory leak detection
   - UI automation tests (optional)

---

## Test Categories

### 1. First-Run Experience (Onboarding)

**Priority**: Critical
**Estimated Time**: 2 hours

#### Test Cases

**TC-O-001: First Launch Detection**
- [ ] Launch app for first time
- [ ] Verify onboarding appears automatically
- [ ] Expected: OnboardingFlow displayed, not main app

**TC-O-002: Welcome Screen**
- [ ] View welcome page
- [ ] Verify 21 features displayed in grid
- [ ] Check GTD overview page
- [ ] Toggle "Include sample data" checkbox
- [ ] Expected: All content readable, checkbox works

**TC-O-003: Directory Picker - Default Location**
- [ ] Accept default directory (~/Documents/StickyToDo)
- [ ] Verify validation passes
- [ ] Check green checkmark appears
- [ ] Expected: Directory created, validation succeeds

**TC-O-004: Directory Picker - Custom Location**
- [ ] Click "Choose Different Location"
- [ ] Select custom directory
- [ ] Verify validation runs
- [ ] Expected: Custom directory accepted if valid

**TC-O-005: Directory Picker - Validation Failures**
- [ ] Select directory with insufficient space (<100 MB)
- [ ] Select read-only directory
- [ ] Expected: Orange warning, issue list displayed

**TC-O-006: Directory Structure Creation**
- [ ] Complete directory picker
- [ ] Navigate to selected directory in Finder
- [ ] Verify subdirectories exist (tasks/, boards/, templates/, etc.)
- [ ] Expected: All subdirectories created

**TC-O-007: Permission Requests - Notifications**
- [ ] Navigate to Permissions step
- [ ] Click "Grant Access" for Notifications
- [ ] Verify system permission dialog appears
- [ ] Grant permission
- [ ] Expected: Green badge shows "Granted"

**TC-O-008: Permission Requests - Calendar**
- [ ] Click "Grant Access" for Calendar
- [ ] Verify system permission dialog appears
- [ ] Grant permission
- [ ] Expected: Green badge shows "Granted"

**TC-O-009: Permission Requests - Siri**
- [ ] Click "Grant Access" for Siri
- [ ] Verify system settings or permission flow
- [ ] Expected: Siri shortcuts become available

**TC-O-010: Permission Requests - Skip**
- [ ] Click "Skip" for a permission
- [ ] Verify can continue to next step
- [ ] Expected: Permission skipped, no error

**TC-O-011: Quick Tour**
- [ ] View all 7 tour pages
- [ ] Verify content for each feature
- [ ] Test "Skip Tour" button
- [ ] Expected: All pages display correctly, skip works

**TC-O-012: Sample Data Generation**
- [ ] Complete onboarding with sample data enabled
- [ ] Open main app
- [ ] Verify 13 sample tasks created
- [ ] Verify 3 sample boards created
- [ ] Verify 7 sample tags created
- [ ] Expected: Sample data appears in app

**TC-O-013: No Sample Data**
- [ ] Reset onboarding
- [ ] Complete flow without sample data
- [ ] Verify app starts empty
- [ ] Expected: No sample data, clean slate

**TC-O-014: Onboarding Completion**
- [ ] Complete full onboarding flow
- [ ] Verify main app opens
- [ ] Restart app
- [ ] Verify onboarding doesn't appear again
- [ ] Expected: Onboarding marked complete

---

### 2. Basic Task Management

**Priority**: Critical
**Estimated Time**: 3 hours

#### Test Cases

**TC-TM-001: Create Task via Quick Capture**
- [ ] Press ⌘N
- [ ] Type task title "Buy groceries"
- [ ] Press Enter
- [ ] Expected: Task created in Inbox, appears in list

**TC-TM-002: Task Properties**
- [ ] Create task
- [ ] Open TaskInspectorView
- [ ] Set due date
- [ ] Set priority (High/Medium/Low)
- [ ] Add notes
- [ ] Set project
- [ ] Set context
- [ ] Expected: All properties saved correctly

**TC-TM-003: Complete Task**
- [ ] Select task
- [ ] Click checkbox or press Space
- [ ] Verify task marked complete
- [ ] Expected: Task moves to Completed section, strikethrough applied

**TC-TM-004: Edit Task**
- [ ] Double-click task or press ⌘E
- [ ] Modify title
- [ ] Change due date
- [ ] Update notes
- [ ] Save changes
- [ ] Expected: Changes persist after save

**TC-TM-005: Delete Task**
- [ ] Select task
- [ ] Press Delete key
- [ ] Confirm deletion
- [ ] Expected: Task removed from list, file deleted from disk

**TC-TM-006: Flag/Unflag Task**
- [ ] Select task
- [ ] Click flag icon or press ⌘F
- [ ] Verify flag appears
- [ ] Click again to unflag
- [ ] Expected: Flag state toggles correctly

**TC-TM-007: Defer Task**
- [ ] Set defer date in future
- [ ] Verify task hidden from Next Actions
- [ ] Change system date (or wait)
- [ ] Expected: Task appears when defer date reached

**TC-TM-008: Task File Persistence**
- [ ] Create task
- [ ] Navigate to tasks/ directory
- [ ] Open .md file in text editor
- [ ] Verify YAML frontmatter correct
- [ ] Edit file externally
- [ ] Reload app
- [ ] Expected: Changes from file reflected in app

---

### 3. Board Management & Canvas

**Priority**: High
**Estimated Time**: 4 hours

#### Test Cases

**TC-BM-001: Create Board**
- [ ] Click "New Board" or press ⌘B
- [ ] Enter board name "Work Projects"
- [ ] Select layout type (Freeform)
- [ ] Expected: Board created, appears in sidebar

**TC-BM-002: Switch Boards**
- [ ] Create multiple boards
- [ ] Click different boards in sidebar
- [ ] Verify task list updates
- [ ] Expected: Only tasks for selected board shown

**TC-BM-003: Canvas - Freeform Layout**
- [ ] Open board with freeform layout
- [ ] Verify canvas view renders
- [ ] Expected: Infinite canvas, tasks as sticky notes

**TC-BM-004: Canvas - Pan & Zoom**
- [ ] Hold Option key + drag to pan
- [ ] Use Command + scroll to zoom
- [ ] Verify smooth 60 FPS performance
- [ ] Expected: Responsive pan/zoom, no lag

**TC-BM-005: Canvas - Lasso Selection**
- [ ] Drag to create lasso
- [ ] Select multiple tasks
- [ ] Verify selection highlights
- [ ] Expected: All tasks in lasso selected

**TC-BM-006: Canvas - Move Tasks**
- [ ] Drag task to new position
- [ ] Release mouse
- [ ] Reload board
- [ ] Expected: Position persisted to task metadata

**TC-BM-007: Layout Switching - Kanban**
- [ ] Switch board to Kanban layout
- [ ] Verify columns displayed (Inbox, Next, Doing, Done)
- [ ] Drag task between columns
- [ ] Expected: Status updates when moved to column

**TC-BM-008: Layout Switching - Grid**
- [ ] Switch board to Grid layout
- [ ] Verify sections displayed
- [ ] Expected: Tasks organized by project or context

**TC-BM-009: Drag-Drop List to Canvas**
- [ ] Open list view and canvas side-by-side
- [ ] Drag task from list to canvas
- [ ] Verify task appears on canvas
- [ ] Expected: Task added to board, position saved

**TC-BM-010: Board Settings**
- [ ] Open board settings
- [ ] Change auto-hide behavior
- [ ] Change default layout
- [ ] Expected: Settings saved, behavior changes

---

### 4. Advanced Features

**Priority**: High
**Estimated Time**: 6 hours

#### Recurring Tasks

**TC-AF-001: Create Recurring Task**
- [ ] Create task with recurrence pattern
- [ ] Set to "Daily" or "Weekly"
- [ ] Complete task
- [ ] Expected: Next occurrence generated automatically

**TC-AF-002: Recurring Patterns**
- [ ] Test daily recurrence
- [ ] Test weekly recurrence
- [ ] Test monthly recurrence
- [ ] Test custom interval
- [ ] Expected: All patterns generate correctly

#### Subtasks

**TC-AF-003: Add Subtask**
- [ ] Open task inspector
- [ ] Click "Add Subtask"
- [ ] Enter subtask title
- [ ] Expected: Subtask appears in hierarchy

**TC-AF-004: Subtask Hierarchy**
- [ ] Create parent task
- [ ] Add 3 subtasks
- [ ] Add sub-subtask (3 levels deep)
- [ ] Expected: Hierarchy displayed with indentation

**TC-AF-005: Subtask Progress**
- [ ] Complete 2 of 5 subtasks
- [ ] Verify progress indicator shows "2/5"
- [ ] Expected: Progress tracked automatically

#### Attachments

**TC-AF-006: Attach File**
- [ ] Open task inspector
- [ ] Click "Add Attachment" → "Add File"
- [ ] Select file from disk
- [ ] Expected: File copied to attachments/, linked in task

**TC-AF-007: Attach Link**
- [ ] Click "Add Attachment" → "Add Link"
- [ ] Enter URL
- [ ] Expected: Link saved in task metadata

**TC-AF-008: Attach Note**
- [ ] Click "Add Attachment" → "Add Note"
- [ ] Enter note text
- [ ] Expected: Note saved as attachment

**TC-AF-009: Open Attachment**
- [ ] Click attached file
- [ ] Expected: File opens in default application

#### Tags

**TC-AF-010: Create Tag**
- [ ] Open tag picker
- [ ] Create new tag "urgent"
- [ ] Set color to red
- [ ] Choose icon
- [ ] Expected: Tag created with color/icon

**TC-AF-011: Apply Tags**
- [ ] Add tag to task
- [ ] Verify colored badge appears in task row
- [ ] Expected: Tag displays in list and inspector

**TC-AF-012: Filter by Tag**
- [ ] Click tag in sidebar or filter
- [ ] Verify only tagged tasks shown
- [ ] Expected: Filtering works correctly

#### Activity Log

**TC-AF-013: Activity Tracking**
- [ ] Create task
- [ ] Edit multiple properties
- [ ] Open activity log
- [ ] Verify all changes logged
- [ ] Expected: 26 change types tracked automatically

---

### 5. Notifications

**Priority**: High
**Estimated Time**: 2 hours

#### Test Cases

**TC-N-001: Due Date Notifications**
- [ ] Create task with due date in 1 minute
- [ ] Wait for notification
- [ ] Expected: Notification appears at due time

**TC-N-002: Notification Actions - Complete**
- [ ] Receive task notification
- [ ] Click "Complete" action
- [ ] Expected: Task marked complete without opening app

**TC-N-003: Notification Actions - Snooze**
- [ ] Receive task notification
- [ ] Click "Snooze 1 Hour" action
- [ ] Wait 1 hour
- [ ] Expected: Notification appears again after snooze

**TC-N-004: Weekly Review Reminder**
- [ ] Enable weekly review notifications
- [ ] Set schedule (e.g., Friday 5 PM)
- [ ] Wait for scheduled time
- [ ] Expected: Weekly review notification appears

**TC-N-005: Badge Count**
- [ ] Create 5 tasks with due dates today
- [ ] Verify app badge shows "5"
- [ ] Complete 2 tasks
- [ ] Expected: Badge updates to "3"

**TC-N-006: Notification Settings**
- [ ] Open Notification Settings
- [ ] Disable due date notifications
- [ ] Create task with due date
- [ ] Expected: No notification received

---

### 6. Search & Spotlight

**Priority**: High
**Estimated Time**: 2 hours

#### Test Cases

**TC-S-001: Basic Search**
- [ ] Press ⌘F
- [ ] Type search query "groceries"
- [ ] Expected: Matching tasks highlighted in yellow

**TC-S-002: Search Debouncing**
- [ ] Type query rapidly
- [ ] Verify search waits 300ms before executing
- [ ] Expected: No lag, smooth typing experience

**TC-S-003: Advanced Search - AND**
- [ ] Search for "project:Work AND @computer"
- [ ] Expected: Only tasks in Work project with @computer context

**TC-S-004: Advanced Search - OR**
- [ ] Search for "urgent OR important"
- [ ] Expected: Tasks containing either term

**TC-S-005: Advanced Search - NOT**
- [ ] Search for "NOT completed"
- [ ] Expected: Only active tasks shown

**TC-S-006: Search Highlighting**
- [ ] Search for specific term
- [ ] Verify yellow highlight on matches
- [ ] Expected: All occurrences highlighted

**TC-S-007: Spotlight Integration**
- [ ] Create task "Test spotlight integration"
- [ ] Wait for indexing (30 seconds)
- [ ] Open Spotlight (⌘Space)
- [ ] Search for "spotlight integration"
- [ ] Expected: Task appears in Spotlight results

**TC-S-008: Spotlight - Open Task**
- [ ] Click task in Spotlight results
- [ ] Expected: StickyToDo opens with task selected

---

### 7. Calendar Integration

**Priority**: High
**Estimated Time**: 2 hours

#### Test Cases

**TC-C-001: Task to Calendar Event**
- [ ] Create task with due date
- [ ] Enable calendar sync
- [ ] Open macOS Calendar app
- [ ] Expected: Event created in Calendar

**TC-C-002: Calendar Event to Task**
- [ ] Create event in Calendar app
- [ ] Wait for sync
- [ ] Open StickyToDo
- [ ] Expected: Task created from event

**TC-C-003: Two-Way Sync**
- [ ] Update task due date
- [ ] Verify Calendar event updates
- [ ] Update event time in Calendar
- [ ] Verify task due date updates
- [ ] Expected: Bi-directional sync works

**TC-C-004: Calendar Settings**
- [ ] Open Calendar Settings
- [ ] Select target calendar
- [ ] Toggle auto-sync
- [ ] Expected: Settings persist, sync behavior changes

**TC-C-005: Permission Handling**
- [ ] Revoke calendar permission in System Settings
- [ ] Attempt to sync
- [ ] Expected: Permission request appears, error message shown

---

### 8. Automation Rules

**Priority**: Medium
**Estimated Time**: 3 hours

#### Test Cases

**TC-R-001: Create Rule**
- [ ] Open Automation Rules
- [ ] Create new rule
- [ ] Set trigger: "taskCreated"
- [ ] Set condition: "project == Work"
- [ ] Set action: "setContext(@office)"
- [ ] Expected: Rule created and saved

**TC-R-002: Rule Execution - Task Created**
- [ ] Create task in Work project
- [ ] Verify context automatically set to @office
- [ ] Expected: Rule triggered on creation

**TC-R-003: Rule Execution - Status Changed**
- [ ] Create rule: statusChanged → completed → sendNotification
- [ ] Complete task
- [ ] Expected: Notification sent

**TC-R-004: Rule Execution - Priority Changed**
- [ ] Create rule: priorityChanged → high → flag
- [ ] Set task to high priority
- [ ] Expected: Task automatically flagged

**TC-R-005: Rule Execution - Tag Added**
- [ ] Create rule: tagAdded → urgent → setPriority(high)
- [ ] Add "urgent" tag to task
- [ ] Expected: Priority set to high

**TC-R-006: Complex Rule Conditions**
- [ ] Create rule with multiple conditions (AND logic)
- [ ] Test with matching and non-matching tasks
- [ ] Expected: Only matching tasks trigger actions

**TC-R-007: Rule Actions - Multiple**
- [ ] Create rule with 3 actions
- [ ] Trigger rule
- [ ] Verify all 3 actions execute
- [ ] Expected: All actions run in order

**TC-R-008: Disable Rule**
- [ ] Disable rule
- [ ] Trigger condition
- [ ] Expected: Rule does not execute

---

### 9. Perspectives & Templates

**Priority**: Medium
**Estimated Time**: 2 hours

#### Perspectives

**TC-P-001: Built-in Perspectives**
- [ ] Click Inbox perspective (⌘1)
- [ ] Verify only inbox tasks shown
- [ ] Test Today, Upcoming, Flagged perspectives
- [ ] Expected: All built-in perspectives filter correctly

**TC-P-002: Create Custom Perspective**
- [ ] Click "New Perspective"
- [ ] Set filters (project, context, priority)
- [ ] Save with keyboard shortcut (⌘5)
- [ ] Expected: Custom perspective created

**TC-P-003: Edit Perspective**
- [ ] Open perspective editor
- [ ] Modify filters
- [ ] Save changes
- [ ] Expected: Perspective updates correctly

**TC-P-004: Perspective Keyboard Shortcuts**
- [ ] Press ⌘1 through ⌘9
- [ ] Verify perspectives switch
- [ ] Expected: All shortcuts work

**TC-P-005: Export/Import Perspectives**
- [ ] Export perspective to file
- [ ] Delete perspective
- [ ] Import from file
- [ ] Expected: Perspective restored correctly

#### Templates

**TC-T-001: Built-in Templates**
- [ ] Open Template Library (⌘⇧T)
- [ ] Verify 7 built-in templates
- [ ] Expected: All templates displayed

**TC-T-002: Use Template**
- [ ] Select "Meeting Notes" template
- [ ] Click "Create Task"
- [ ] Verify task pre-filled with template data
- [ ] Expected: All template fields applied

**TC-T-003: Save as Template**
- [ ] Create task with multiple properties
- [ ] Click "Save as Template"
- [ ] Name template "My Custom Template"
- [ ] Expected: Template saved to library

**TC-T-004: Template Library**
- [ ] Create 5 custom templates
- [ ] Organize by category
- [ ] Expected: Templates organized, searchable

---

### 10. Analytics & Export

**Priority**: Medium
**Estimated Time**: 2 hours

#### Analytics

**TC-AN-001: Analytics Dashboard**
- [ ] Open Analytics Dashboard (⌘⇧A)
- [ ] Verify 5 chart types displayed
- [ ] Expected: Charts show accurate data

**TC-AN-002: Period Filtering**
- [ ] Select "This Week" period
- [ ] Verify data updates
- [ ] Test "This Month", "This Year"
- [ ] Expected: Charts filter by period

**TC-AN-003: Task Completion Stats**
- [ ] Complete 10 tasks
- [ ] Open analytics
- [ ] Verify completion rate correct
- [ ] Expected: Stats accurate

#### Export

**TC-EX-001: Export to Markdown**
- [ ] Open Export View (⌘⇧E)
- [ ] Select "Native Markdown Archive"
- [ ] Export to file
- [ ] Open exported file
- [ ] Expected: All tasks exported correctly

**TC-EX-002: Export to CSV**
- [ ] Select CSV format
- [ ] Export tasks
- [ ] Open in spreadsheet app
- [ ] Expected: CSV formatted correctly

**TC-EX-003: Export Filters**
- [ ] Apply filters (date range, status)
- [ ] Export
- [ ] Verify only filtered tasks exported
- [ ] Expected: Filters applied to export

**TC-EX-004: All Export Formats**
- [ ] Test all 11 export formats:
  - Native Markdown, Simplified Markdown, TaskPaper
  - OmniFocus, Things, CSV, TSV, JSON, HTML, PDF, iCal
- [ ] Expected: All formats generate valid files

---

### 11. Siri Shortcuts

**Priority**: High
**Estimated Time**: 3 hours

#### Test Cases

**TC-SI-001: Add Task via Siri**
- [ ] Say "Hey Siri, add task in StickyToDo"
- [ ] Speak task title
- [ ] Expected: Task created in Inbox

**TC-SI-002: Complete Task via Siri**
- [ ] Say "Hey Siri, complete task in StickyToDo"
- [ ] Select task from list
- [ ] Expected: Task marked complete

**TC-SI-003: Show Inbox**
- [ ] Say "Hey Siri, show inbox in StickyToDo"
- [ ] Expected: Inbox task count and list spoken

**TC-SI-004: Show Next Actions**
- [ ] Say "Hey Siri, show next actions in StickyToDo"
- [ ] Expected: Next action tasks spoken

**TC-SI-005: Show Today's Tasks**
- [ ] Say "Hey Siri, show today's tasks in StickyToDo"
- [ ] Expected: Tasks due today spoken

**TC-SI-006: Start Timer**
- [ ] Say "Hey Siri, start timer in StickyToDo"
- [ ] Select task
- [ ] Expected: Timer started, confirmation spoken

**TC-SI-007: Stop Timer**
- [ ] Say "Hey Siri, stop timer in StickyToDo"
- [ ] Expected: Timer stopped, duration spoken

**TC-SI-008: Shortcuts App Integration**
- [ ] Open Shortcuts app
- [ ] Verify 7 StickyToDo shortcuts appear
- [ ] Create custom shortcut using StickyToDo actions
- [ ] Expected: All shortcuts available, custom workflows work

**TC-SI-009: Siri Suggestions**
- [ ] Use shortcuts multiple times
- [ ] Check Siri Suggestions
- [ ] Expected: StickyToDo appears in suggestions

---

### 12. Time Tracking

**Priority**: Medium
**Estimated Time**: 1 hour

#### Test Cases

**TC-TT-001: Start Timer**
- [ ] Select task
- [ ] Click "Start Timer"
- [ ] Expected: Timer starts, countdown visible

**TC-TT-002: Stop Timer**
- [ ] Stop running timer
- [ ] Verify session time recorded
- [ ] Expected: Time added to task total

**TC-TT-003: Multiple Sessions**
- [ ] Start and stop timer 3 times
- [ ] Verify total time accumulates
- [ ] Expected: All sessions summed

**TC-TT-004: Timer Notification**
- [ ] Set timer for 25 minutes (Pomodoro)
- [ ] Wait for completion
- [ ] Expected: Notification when timer completes

**TC-TT-005: Time Analytics**
- [ ] Track time on multiple tasks
- [ ] Open Time Analytics View
- [ ] Expected: Charts show accurate time data

---

### 13. Weekly Review

**Priority**: Medium
**Estimated Time**: 1 hour

#### Test Cases

**TC-WR-001: Start Weekly Review**
- [ ] Open Weekly Review View
- [ ] Verify workflow steps displayed
- [ ] Expected: GTD review workflow shown

**TC-WR-002: Review Inbox**
- [ ] Process inbox items
- [ ] Move to Next Actions, Waiting, etc.
- [ ] Expected: Inbox cleared

**TC-WR-003: Review Next Actions**
- [ ] Review all next actions
- [ ] Update contexts and priorities
- [ ] Expected: Actions prioritized

**TC-WR-004: Review Waiting**
- [ ] Review waiting items
- [ ] Follow up on stale items
- [ ] Expected: Waiting list updated

**TC-WR-005: Review Someday/Maybe**
- [ ] Review someday items
- [ ] Promote to active or archive
- [ ] Expected: Someday list curated

**TC-WR-006: Review Statistics**
- [ ] Complete review
- [ ] View completion statistics
- [ ] Expected: Stats show tasks processed

---

## Performance Testing

**Priority**: High
**Estimated Time**: 4 hours

### Test Scenarios

**PT-001: App Launch Time**
- [ ] Measure cold launch time
- [ ] Target: < 3 seconds
- [ ] Test with 0, 100, 500, 1000 tasks
- [ ] Expected: Launch time acceptable at all scales

**PT-002: Canvas Performance - 100 Tasks**
- [ ] Create board with 100 tasks
- [ ] Pan and zoom canvas
- [ ] Measure FPS using Instruments
- [ ] Expected: Maintain 60 FPS

**PT-003: Canvas Performance - 500 Tasks**
- [ ] Create board with 500 tasks
- [ ] Pan and zoom
- [ ] Expected: Maintain 60 FPS or gracefully degrade

**PT-004: Search Performance**
- [ ] Create 1000 tasks
- [ ] Perform search
- [ ] Measure time to results
- [ ] Expected: Results in < 100ms

**PT-005: File Save Performance**
- [ ] Edit task
- [ ] Measure time to save to disk
- [ ] Expected: Save in < 500ms

**PT-006: Memory Usage**
- [ ] Load 1000 tasks
- [ ] Monitor memory with Instruments
- [ ] Expected: Reasonable memory footprint (< 500 MB)

**PT-007: Memory Leaks**
- [ ] Run app through common workflows
- [ ] Use Xcode memory leak detector
- [ ] Expected: No memory leaks detected

---

## Edge Cases & Error Handling

**Priority**: Medium
**Estimated Time**: 3 hours

### Test Scenarios

**EC-001: Disk Full**
- [ ] Fill disk to < 100 MB free
- [ ] Attempt to create task
- [ ] Expected: Error message, graceful failure

**EC-002: Permission Revocation**
- [ ] Revoke permissions in System Settings
- [ ] Attempt to use feature
- [ ] Expected: Permission re-request or error message

**EC-003: Malformed Task Files**
- [ ] Edit .md file with invalid YAML
- [ ] Reload app
- [ ] Expected: Error logged, task skipped or recovered

**EC-004: Network Issues (Calendar Sync)**
- [ ] Disable network
- [ ] Attempt calendar sync
- [ ] Expected: Offline mode, sync queued for later

**EC-005: Concurrent File Edits**
- [ ] Edit task in app and externally simultaneously
- [ ] Save both
- [ ] Expected: Conflict detection or last-write-wins

**EC-006: Very Long Task Titles**
- [ ] Create task with 1000+ character title
- [ ] Expected: UI doesn't break, truncation works

**EC-007: Special Characters**
- [ ] Create task with emoji, Unicode, special chars
- [ ] Expected: Characters display correctly, save to file

**EC-008: Empty Data Directory**
- [ ] Delete all files from data directory
- [ ] Reload app
- [ ] Expected: App starts with empty state, no crash

---

## Regression Testing

**Priority**: Medium
**Estimated Time**: 2 hours

### Test Previous Functionality

**RT-001: Basic CRUD Operations**
- [ ] Create, Read, Update, Delete tasks
- [ ] Verify all operations still work
- [ ] Expected: No regressions

**RT-002: File Format Compatibility**
- [ ] Load tasks created in previous version
- [ ] Expected: All tasks load correctly

**RT-003: Settings Persistence**
- [ ] Configure all settings
- [ ] Restart app
- [ ] Expected: Settings persisted

---

## Automated Testing

**Priority**: Low (optional)
**Estimated Time**: 8 hours

### Unit Tests
- [ ] Run existing test suite (200+ tests)
- [ ] Verify all tests pass
- [ ] Add tests for new features
- [ ] Target: 80%+ code coverage

### UI Tests
- [ ] Create XCUITest suite for critical paths
- [ ] Test: Create task → Edit → Complete → Delete
- [ ] Test: Onboarding flow
- [ ] Expected: All UI tests pass

---

## Bug Tracking

### Bug Report Template

```markdown
**Bug ID**: BUG-XXX
**Priority**: Critical/High/Medium/Low
**Component**: (e.g., Canvas, Search, Onboarding)
**Steps to Reproduce**:
1. ...
2. ...
**Expected Result**: ...
**Actual Result**: ...
**System**: macOS version, Xcode version
**Screenshots**: (if applicable)
**Workaround**: (if known)
**Status**: New/In Progress/Fixed/Closed
```

### Priority Definitions
- **Critical**: App crashes, data loss, security issues
- **High**: Major feature broken, poor UX, data corruption risk
- **Medium**: Minor feature broken, cosmetic issues
- **Low**: Edge cases, nice-to-have improvements

---

## Test Completion Criteria

### Minimum Pass Criteria
- [ ] All Critical test cases pass
- [ ] All High priority test cases pass
- [ ] No Critical or High severity bugs open
- [ ] Performance targets met (launch < 3s, search < 100ms, 60 FPS canvas)
- [ ] No memory leaks detected
- [ ] All 21 features functional end-to-end

### Nice to Have
- [ ] All Medium priority test cases pass
- [ ] All Low priority test cases pass
- [ ] UI tests automated
- [ ] 85%+ code coverage
- [ ] Beta tester feedback incorporated

---

## Beta Testing

### Beta Tester Recruitment
- [ ] Identify 5-10 beta testers
- [ ] Provide TestFlight build or DMG
- [ ] Create feedback form

### Beta Test Focus Areas
1. Onboarding experience
2. Daily workflow usage
3. Performance on different hardware
4. Edge cases and bugs
5. Feature requests

### Feedback Collection
- [ ] Weekly feedback survey
- [ ] Bug reports via GitHub Issues
- [ ] Feature requests logged
- [ ] Crash reports analyzed

---

## Timeline

### Week 1: Core Testing
**Monday**
- Onboarding (2 hours)
- Basic task management (3 hours)

**Tuesday**
- Board management & canvas (4 hours)
- Advanced features part 1 (3 hours)

**Wednesday**
- Advanced features part 2 (3 hours)
- Notifications (2 hours)

**Thursday**
- Search & Spotlight (2 hours)
- Calendar integration (2 hours)
- Automation rules (3 hours)

**Friday**
- Perspectives & templates (2 hours)
- Analytics & export (2 hours)
- Siri shortcuts (3 hours)

### Week 2: Edge Cases & Performance
**Monday**
- Time tracking (1 hour)
- Weekly review (1 hour)
- Performance testing (4 hours)

**Tuesday**
- Edge cases & error handling (3 hours)
- Regression testing (2 hours)

**Wednesday**
- Bug fixes (full day)

**Thursday**
- Re-test fixed bugs
- Final polish
- Documentation updates

**Friday**
- Beta release preparation
- Release notes
- Final verification

---

## Deliverables

1. **Test Results Document**
   - All test cases executed with pass/fail
   - Bug reports for failures
   - Performance metrics

2. **Bug Database**
   - GitHub Issues with all bugs
   - Prioritized and assigned
   - Fix status tracked

3. **Performance Report**
   - Launch times
   - FPS measurements
   - Memory usage
   - Search performance

4. **Beta Test Report**
   - Tester feedback summary
   - Common issues
   - Feature requests
   - Usability insights

5. **Release Readiness Assessment**
   - Go/no-go recommendation
   - Outstanding issues
   - Risk assessment

---

## Success Metrics

### Quantitative
- 95%+ test cases pass
- 0 critical bugs
- < 3 high severity bugs
- App launch < 3 seconds
- Search results < 100ms
- Canvas maintains 60 FPS with 100 tasks
- Memory usage < 500 MB with 1000 tasks

### Qualitative
- Onboarding is clear and helpful
- UI is responsive and polished
- Features work as expected
- Beta testers satisfied (4+ stars)
- No major usability issues

---

## Conclusion

This integration test plan ensures comprehensive validation of StickyToDo before beta release. By systematically testing all features, performance, and edge cases, we can confidently deliver a high-quality v1.0 product.

**Estimated Total Testing Time**: ~60 hours (2 weeks for 1 tester, or 1 week for 2 testers in parallel)

---

**Plan Created**: 2025-11-18
**Status**: Ready for Execution
**Next Step**: Begin Week 1 testing
