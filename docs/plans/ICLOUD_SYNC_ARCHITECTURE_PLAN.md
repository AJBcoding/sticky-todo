# iCloud Sync Architecture - Strategic Planning Report

**Date**: 2025-11-18
**Project**: StickyToDo - GTD Task Manager
**Purpose**: Comprehensive architectural plan for iCloud sync implementation
**Effort Estimate**: 2-3 months (High complexity, High value)
**Status**: Strategic Planning (No code changes)

---

## Executive Summary

iCloud sync is identified as essential for multi-device workflows in the Feature Opportunities Assessment (Feature #12). This report provides a comprehensive architectural plan for implementing seamless synchronization across Mac, iPhone, and iPad devices.

**Key Recommendations**:
- **Primary Strategy**: iCloud Drive + NSFileCoordinator (file-based sync)
- **Secondary Layer**: NSUbiquitousKeyValueStore (settings and metadata)
- **Future Consideration**: CloudKit for advanced features (collaboration, v2.0)
- **Timeline**: 2-3 months for full implementation
- **Risk Level**: Medium-High (conflict resolution complexity)

**Why File-Based Sync Wins**:
1. Preserves plain-text architecture (core value proposition)
2. Lower implementation complexity than CloudKit
3. Maintains git-friendliness and user control
4. Natural fit with existing markdown file structure
5. Simpler migration path from local-only

---

## 1. Current Architecture Analysis

### 1.1 Data Storage Model

**File System Organization**:
```
StickyToDo/
├── tasks/
│   ├── active/
│   │   ├── 2025/
│   │   │   ├── 11/
│   │   │   │   ├── uuid-task-title.md
│   │   │   │   └── uuid-another-task.md
│   │   │   └── 12/
│   │   └── 2026/
│   └── archive/
│       └── 2025/
│           └── 11/
│               └── uuid-completed-task.md
├── boards/
│   ├── inbox.md
│   ├── next-actions.md
│   ├── project-name.md
│   └── context-name.md
├── config/
│   └── rules.yaml
├── activity-log/
│   └── activity-log.json
└── time-entries/
    └── 2025/
        └── 11/
            └── uuid.md
```

**File Format**: Markdown with YAML frontmatter
```yaml
---
id: 123e4567-e89b-12d3-a456-426614174000
type: task
title: "Implement iCloud sync"
status: next-action
project: "StickyToDo v2.0"
context: "@computer"
due: 2025-12-01T17:00:00Z
priority: high
flagged: true
tags:
  - name: "feature"
    color: "blue"
positions:
  inbox:
    x: 100
    y: 200
    column: "To Do"
created: 2025-11-18T10:00:00Z
modified: 2025-11-18T14:30:00Z
---

## Task Notes

Detailed notes go here in markdown format.
```

### 1.2 Data Models

**Task Model** (30+ properties):
- Core: id (UUID), title, notes, type, status
- GTD: project, context, due, defer, priority, flagged
- Organization: tags[], attachments[], color
- Hierarchy: parentId, subtaskIds[]
- Board: positions{} (keyed by board ID)
- Recurrence: recurrence, originalTaskId, occurrenceDate
- Time: isTimerRunning, currentTimerStart, totalTimeSpent
- Integration: calendarEventId, notificationIds[]
- Metadata: created, modified

**Board Model**:
- Core: id, type, layout, filter
- Kanban: columns[]
- Visibility: autoHide, hideAfterDays, isVisible
- Customization: title, notes, icon, color
- System: isBuiltIn, order

**Attachment Model**:
- Types: file (URL), link (URL), note (String)
- Metadata: id, name, description, dateAdded

### 1.3 Current Data Layer

**MarkdownFileIO**:
- Reads/writes markdown files with YAML frontmatter
- Creates directory structure automatically
- Handles task/board/rule/time entry persistence
- Uses YAMLParser for frontmatter serialization

**TaskStore** (In-memory):
- Published @ObservedObject for SwiftUI reactivity
- Thread-safe access via serial queue
- Debounced writes (500ms) to avoid excessive I/O
- Maintains derived collections (projects, contexts)
- No existing sync infrastructure

**BoardStore** (In-memory):
- Similar to TaskStore
- Auto-hides inactive project boards
- Manages built-in and custom boards

### 1.4 Key Characteristics

**Strengths**:
- Offline-first by design
- Plain-text, human-readable, git-friendly
- Fast in-memory access
- Low disk I/O via debouncing
- Thread-safe architecture

**Sync Challenges**:
- No conflict resolution mechanism
- No change tracking infrastructure
- File moves on status change (active ↔ archive)
- Debounced writes could cause sync delays
- Attachments stored as file references

---

## 2. iCloud Integration Options Analysis

### 2.1 Option A: iCloud Drive (Document-Based Sync)

**Technology**: NSFileCoordinator + NSMetadataQuery + File Coordination

**How It Works**:
1. Store markdown files in ubiquity container
2. NSFileCoordinator ensures safe concurrent access
3. NSMetadataQuery monitors file changes
4. System handles upload/download automatically
5. File presenters receive conflict notifications

**Pros**:
- ✅ Preserves plain-text architecture
- ✅ Users can access files via Files.app
- ✅ Works with existing markdown structure
- ✅ Simpler than CloudKit (fewer APIs)
- ✅ Built-in version conflict detection
- ✅ Lower engineering effort (4-6 weeks)
- ✅ Maintains git-friendliness
- ✅ No data model transformation needed

**Cons**:
- ❌ Slower sync (file-based, not real-time)
- ❌ Requires manual conflict resolution UI
- ❌ Less granular change tracking
- ❌ No structured queries (must read files)
- ❌ Network efficiency lower than CloudKit

**Best For**:
- Personal use cases
- Maintaining plain-text philosophy
- Users who want file system access
- Gradual multi-device adoption

**Implementation Complexity**: Medium (6-8 weeks)

---

### 2.2 Option B: CloudKit (Database-Based Sync)

**Technology**: CloudKit framework with CKRecord + CKSubscription

**How It Works**:
1. Define CloudKit schema (Task, Board, etc. as CKRecords)
2. Convert Task/Board structs to CKRecords
3. Upload to CloudKit private database
4. Subscribe to changes via push notifications
5. Download and merge changes

**Pros**:
- ✅ Real-time sync (push notifications)
- ✅ Granular change tracking
- ✅ Structured queries (CKQuery)
- ✅ Better conflict resolution (CKRecord timestamps)
- ✅ Network efficiency (delta sync)
- ✅ Built-in conflict handling
- ✅ Suitable for collaboration features

**Cons**:
- ❌ Abandons plain-text architecture
- ❌ No user file access
- ❌ Requires data model transformation
- ❌ More complex (10-12 weeks)
- ❌ Migration path more difficult
- ❌ Loses git-friendliness
- ❌ Vendor lock-in to CloudKit

**Best For**:
- Team collaboration
- Real-time updates
- Apps prioritizing sync speed
- Professional/enterprise use

**Implementation Complexity**: High (10-12 weeks)

---

### 2.3 Option C: NSUbiquitousKeyValueStore (Settings Sync)

**Technology**: NSUbiquitousKeyValueStore (iCloud Key-Value Storage)

**How It Works**:
1. Store lightweight key-value pairs
2. Automatically syncs across devices
3. Limited to 1 MB total storage

**Pros**:
- ✅ Extremely simple API
- ✅ Automatic sync
- ✅ Perfect for preferences
- ✅ Fast implementation (1-2 days)

**Cons**:
- ❌ Only 1 MB limit
- ❌ Not suitable for tasks/boards
- ❌ No file storage

**Best For**:
- User preferences
- App settings
- Last viewed board/perspective
- UI state

**Implementation Complexity**: Very Low (1-2 days)

---

### 2.4 Hybrid Approach (Recommended)

**Strategy**: Combine multiple technologies for optimal results

**Architecture**:
```
┌─────────────────────────────────────────────────┐
│         StickyToDo Sync Architecture            │
├─────────────────────────────────────────────────┤
│                                                 │
│  [Primary] iCloud Drive (File-Based Sync)       │
│  ├── Tasks (markdown files)                     │
│  ├── Boards (markdown files)                    │
│  ├── Rules (YAML)                               │
│  ├── Activity Log (JSON)                        │
│  └── Time Entries (markdown files)              │
│                                                 │
│  [Settings] NSUbiquitousKeyValueStore           │
│  ├── User preferences                           │
│  ├── Last viewed board                          │
│  ├── Window positions                           │
│  └── Sync preferences                           │
│                                                 │
│  [Future] CloudKit (Optional, v2.0)             │
│  └── Real-time collaboration                    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Rationale**:
1. iCloud Drive preserves core philosophy
2. KV Store handles lightweight settings
3. CloudKit available for future collaboration
4. Incremental migration path

---

## 3. Recommended Sync Strategy

### 3.1 Strategic Decision: iCloud Drive

**Primary Choice**: iCloud Drive + NSFileCoordinator

**Why This Wins**:

1. **Preserves Core Value Proposition**
   - Plain-text remains accessible
   - Users maintain file ownership
   - Git workflows still possible
   - No vendor lock-in

2. **Natural Fit with Existing Architecture**
   - Already file-based
   - Minimal data model changes
   - Existing MarkdownFileIO infrastructure
   - No major refactoring

3. **User Control and Transparency**
   - Users see files in Files.app
   - Can manually edit on iOS
   - Export/backup naturally
   - Debug conflicts easily

4. **Lower Risk and Complexity**
   - Well-documented APIs
   - Proven technology
   - Smaller engineering effort
   - Incremental rollout possible

5. **Migration Path**
   - Simple: move files to ubiquity container
   - Reversible: move files back if needed
   - No data transformation

### 3.2 Implementation Philosophy

**Offline-First (No Changes)**:
- Local storage remains primary
- Sync is enhancement, not requirement
- App functions fully offline
- Queue operations when offline

**User Control**:
- Sync toggle in settings
- Manual sync trigger
- Conflict resolution UI with choices
- Sync status always visible

**Conservative Conflict Resolution**:
- Never silently discard changes
- Always prompt user for conflicts
- Preserve both versions
- Detailed diff view

**Performance**:
- Background sync (low priority queue)
- Debounce sync operations (1-2 seconds)
- Batch file operations
- Optimize metadata queries

---

## 4. Architecture Design

### 4.1 Component Architecture

```
┌───────────────────────────────────────────────────────────┐
│                     Application Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  TaskStore   │  │  BoardStore  │  │  Settings    │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                  │                  │            │
└─────────┼──────────────────┼──────────────────┼────────────┘
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼────────────┐
│         ▼                  ▼                  ▼            │
│  ┌─────────────────────────────────────────────────┐      │
│  │          iCloudSyncCoordinator                  │      │
│  │  ├─ Change Detection                            │      │
│  │  ├─ Upload Queue                                │      │
│  │  ├─ Download Manager                            │      │
│  │  ├─ Conflict Detector                           │      │
│  │  └─ Sync Status Publisher                       │      │
│  └────────┬───────────────────────────┬────────────┘      │
│           │                           │                    │
│           ▼                           ▼                    │
│  ┌──────────────────┐       ┌──────────────────┐         │
│  │  FileCoordinator │       │ MetadataObserver │         │
│  │  - Safe writes   │       │  - File changes  │         │
│  │  - Read locks    │       │  - Conflict detect│         │
│  └────────┬─────────┘       └─────────┬────────┘         │
│           │                           │                    │
└───────────┼───────────────────────────┼────────────────────┘
            │                           │
┌───────────┼───────────────────────────┼────────────────────┐
│           ▼                           ▼                    │
│  ┌──────────────────────────────────────────────┐         │
│  │        iCloud Drive Ubiquity Container       │         │
│  │  ┌────────────┐  ┌────────────┐             │         │
│  │  │ Local Cache│  │   Cloud    │             │         │
│  │  └────────────┘  └────────────┘             │         │
│  └──────────────────────────────────────────────┘         │
│                   iCloud Infrastructure                    │
└────────────────────────────────────────────────────────────┘
```

### 4.2 Core Components

#### 4.2.1 iCloudSyncCoordinator

**Responsibilities**:
- Orchestrates all sync operations
- Monitors local and remote changes
- Manages upload/download queues
- Detects and resolves conflicts
- Publishes sync status

**Key Properties**:
```swift
class iCloudSyncCoordinator: ObservableObject {
    // Configuration
    var isSyncEnabled: Bool
    var ubiquityContainerURL: URL?

    // Status
    @Published var syncStatus: SyncStatus
    @Published var lastSyncDate: Date?
    @Published var hasPendingUploads: Int
    @Published var hasConflicts: Int

    // Components
    private let fileCoordinator: NSFileCoordinator
    private let metadataQuery: NSMetadataQuery
    private let uploadQueue: OperationQueue
    private let downloadQueue: OperationQueue
    private let conflictResolver: ConflictResolver

    // Storage
    private let localFileIO: MarkdownFileIO
    private let syncMetadataStore: SyncMetadataStore
}
```

**Sync Status Enum**:
```swift
enum SyncStatus {
    case disabled          // Sync not enabled
    case idle              // Synced, no pending operations
    case uploading(Int)    // Uploading N files
    case downloading(Int)  // Downloading N files
    case conflict(Int)     // N conflicts detected
    case error(Error)      // Sync error occurred
}
```

#### 4.2.2 SyncMetadataStore

**Purpose**: Track sync state per file

**Schema**:
```swift
struct SyncMetadata: Codable {
    let fileURL: URL
    let localModifiedDate: Date
    let cloudModifiedDate: Date?
    let syncState: SyncState
    let conflictVersions: [URL]  // NSFileVersion URLs
    let lastSyncAttempt: Date?
    let syncError: String?
}

enum SyncState: String, Codable {
    case synced           // In sync
    case pendingUpload    // Local changes not uploaded
    case pendingDownload  // Cloud changes not downloaded
    case conflict         // Both changed, needs resolution
    case error            // Sync failed
}
```

**Storage**: Local SQLite database or JSON file
- Fast lookups by file path
- Persist across app launches
- Track per-file sync status

#### 4.2.3 ConflictResolver

**Responsibilities**:
- Detect conflicts (both local and cloud modified)
- Parse both versions
- Present diff UI to user
- Merge changes based on user choice

**Conflict Detection**:
```swift
func detectConflict(
    localURL: URL,
    cloudURL: URL
) -> ConflictInfo? {
    let localModified = localURL.modificationDate
    let cloudModified = cloudURL.modificationDate
    let lastSync = syncMetadata[localURL]?.lastSyncDate

    if localModified > lastSync && cloudModified > lastSync {
        // Both modified since last sync = conflict
        return ConflictInfo(
            localVersion: localURL,
            cloudVersion: cloudURL,
            lastSyncDate: lastSync
        )
    }
    return nil
}
```

**Resolution Strategies**:
1. **User Choice** (Default)
   - Show both versions
   - Let user pick or merge
   - Most conservative approach

2. **Last Write Wins** (Optional setting)
   - Newest modification date wins
   - Automatic resolution
   - Risk: data loss

3. **Smart Merge** (Advanced)
   - Parse both YAML frontmatters
   - Merge non-conflicting fields
   - Prompt only for actual conflicts
   - Most user-friendly

### 4.3 Data Flow Diagrams

#### 4.3.1 Initial Sync (First Device Setup)

```
┌─────────────┐
│   User      │
│ Enables Sync│
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────┐
│ 1. Check iCloud availability     │
│    - NSFileManager.ubiquityURL   │
│    - Prompt if not signed in     │
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│ 2. Create ubiquity container     │
│    - Documents/StickyToDo/       │
│    - Copy directory structure    │
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│ 3. Upload all local files        │
│    - Use NSFileCoordinator       │
│    - Copy to ubiquity container  │
│    - Track upload progress       │
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│ 4. Wait for upload completion    │
│    - Monitor NSMetadataQuery     │
│    - Update sync status          │
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│ 5. Mark as synced                │
│    - Update SyncMetadataStore    │
│    - Display success message     │
└──────────────────────────────────┘
```

#### 4.3.2 Subsequent Device Setup

```
┌─────────────┐
│   User      │
│ Enables Sync│
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────┐
│ 1. Check for existing data       │
│    - Local files exist?          │
│    - Cloud files exist?          │
└────────┬─────────────────────────┘
         │
         ├─ No local files ────────────────┐
         │                                 │
         │                                 ▼
         │                        ┌────────────────┐
         │                        │ 2a. Full Download│
         │                        │  - Download all  │
         │                        │  - Show progress │
         │                        └────────────────┘
         │
         ├─ Local files exist ─────────────┐
         │                                 │
         │                                 ▼
         │                        ┌────────────────┐
         │                        │ 2b. Conflict?  │
         │                        │  - Compare dates│
         │                        └───┬────────────┘
         │                            │
         │                            ├─ Yes → Show conflict UI
         │                            └─ No → Merge
         │
         └──────────────────────────────────┐
                                            ▼
                                   ┌────────────────┐
                                   │ 3. Start Monitor│
                                   │  - NSMetadataQuery│
                                   └────────────────┘
```

#### 4.3.3 Background Sync (Ongoing)

```
┌─────────────────┐
│ Local Change    │ ◄───────── User edits task
└────────┬────────┘
         │
         ▼
┌──────────────────────────────────┐
│ 1. TaskStore.update(task)        │
│    - Update in-memory            │
│    - Trigger debounced save      │
└────────┬─────────────────────────┘
         │
         │ (500ms debounce)
         ▼
┌──────────────────────────────────┐
│ 2. MarkdownFileIO.writeTask()    │
│    - Write to local file         │
│    - Notify SyncCoordinator      │
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│ 3. SyncCoordinator.didChangeFile()│
│    - Mark as pendingUpload       │
│    - Add to upload queue         │
└────────┬─────────────────────────┘
         │
         │ (1-2 sec debounce)
         ▼
┌──────────────────────────────────┐
│ 4. Upload to iCloud              │
│    - NSFileCoordinator.write     │
│    - Copy to ubiquity URL        │
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│ 5. Update metadata               │
│    - Mark as synced              │
│    - Update lastSyncDate         │
└──────────────────────────────────┘


┌─────────────────┐
│ Remote Change   │ ◄───────── Another device
└────────┬────────┘
         │
         ▼
┌──────────────────────────────────┐
│ 1. NSMetadataQuery notification  │
│    - File added/modified         │
│    - Get cloud URL               │
└────────┬─────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│ 2. Check for conflict            │
│    - Local modified since sync?  │
└────────┬─────────────────────────┘
         │
         ├─ No conflict ────────────────┐
         │                              │
         │                              ▼
         │                     ┌────────────────┐
         │                     │ 3a. Download   │
         │                     │  - Replace local│
         │                     │  - Reload store│
         │                     └────────────────┘
         │
         └─ Conflict ──────────────────┐
                                       │
                                       ▼
                              ┌────────────────┐
                              │ 3b. Queue conflict│
                              │  - Show notification│
                              │  - Present resolver│
                              └────────────────┘
```

### 4.4 File Coordination Strategy

**NSFileCoordinator Pattern**:
```swift
// Writing to iCloud
func syncTaskToCloud(task: Task) throws {
    let localURL = localFileIO.taskURL(for: task)
    let cloudURL = cloudTaskURL(for: task)

    let coordinator = NSFileCoordinator(filePresenter: nil)
    var coordinationError: NSError?

    coordinator.coordinate(
        writingItemAt: localURL,
        options: .forMerging,
        writingItemAt: cloudURL,
        options: .forReplacing,
        error: &coordinationError
    ) { (localURL, cloudURL) in
        do {
            // Copy local file to cloud
            try FileManager.default.copyItem(at: localURL, to: cloudURL)

            // Update metadata
            updateSyncMetadata(for: task, cloudURL: cloudURL)

            logger?("Synced task to cloud: \(task.title)")
        } catch {
            logger?("Failed to sync task: \(error)")
        }
    }

    if let error = coordinationError {
        throw error
    }
}
```

**NSMetadataQuery Setup**:
```swift
func startMonitoringCloudChanges() {
    metadataQuery = NSMetadataQuery()

    // Search for all markdown files in tasks/boards directories
    metadataQuery.searchScopes = [
        NSMetadataQueryUbiquitousDocumentsScope
    ]

    metadataQuery.predicate = NSPredicate(
        format: "%K LIKE '*.md'",
        NSMetadataItemFSNameKey
    )

    // Observe changes
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(metadataQueryDidUpdate),
        name: .NSMetadataQueryDidUpdate,
        object: metadataQuery
    )

    metadataQuery.start()
    logger?("Started monitoring iCloud changes")
}

@objc func metadataQueryDidUpdate(_ notification: Notification) {
    metadataQuery.disableUpdates()

    // Process changed files
    for item in metadataQuery.results {
        guard let metadataItem = item as? NSMetadataItem else { continue }

        if let url = metadataItem.value(forAttribute: NSMetadataItemURLKey) as? URL {
            handleCloudFileChange(url)
        }
    }

    metadataQuery.enableUpdates()
}
```

---

## 5. Data Model Strategy

### 5.1 File-Based Sync (No Schema Changes)

**Key Decision**: Markdown files remain the source of truth

**Advantages**:
- No data model transformation
- Existing serialization works
- Plain-text benefits preserved

**Sync Approach**:
- File-level granularity (one task = one file)
- YAML frontmatter contains all metadata
- File modification dates for conflict detection

### 5.2 Metadata Tracking

**SyncMetadata Database** (Local SQLite):
```sql
CREATE TABLE sync_metadata (
    file_path TEXT PRIMARY KEY,
    local_modified_date INTEGER,
    cloud_modified_date INTEGER,
    last_sync_date INTEGER,
    sync_state TEXT,
    conflict_versions TEXT,  -- JSON array of version URLs
    last_error TEXT,
    retry_count INTEGER DEFAULT 0
);

CREATE INDEX idx_sync_state ON sync_metadata(sync_state);
CREATE INDEX idx_last_sync ON sync_metadata(last_sync_date);
```

**Benefits**:
- Fast lookups for sync status
- Persist sync state across app launches
- Track failures and retries
- Query for pending operations

### 5.3 Attachment Handling

**Challenge**: File attachments stored as URLs

**Strategy**:
1. **Embedded Attachments** (Small files < 1 MB)
   - Base64 encode in YAML frontmatter
   - Sync with task file
   - Simple, no coordination needed

2. **Referenced Attachments** (Large files > 1 MB)
   - Store in separate `attachments/` directory
   - Sync independently
   - Reference by UUID in task
   - Lazy download (on demand)

**Attachment Sync Structure**:
```
iCloud Drive/StickyToDo/
├── tasks/
├── boards/
└── attachments/
    ├── 2025/
    │   └── 11/
    │       ├── uuid-1.pdf
    │       ├── uuid-2.jpg
    │       └── uuid-3.png
    └── metadata.json
```

**Attachment Metadata**:
```json
{
  "attachments": [
    {
      "id": "uuid-1",
      "filename": "document.pdf",
      "size": 2048576,
      "mimeType": "application/pdf",
      "taskId": "task-uuid",
      "uploaded": "2025-11-18T10:00:00Z"
    }
  ]
}
```

### 5.4 Large File Optimization

**Problem**: Syncing hundreds of tasks at once

**Solutions**:

1. **Batched Upload**:
   - Upload in chunks of 10-20 files
   - Show progress per batch
   - Pausable/resumable

2. **Smart Sync** (Modified files only):
   - Track file modification dates
   - Only sync changed files
   - Skip unchanged files

3. **Compressed Transfer** (Future):
   - Zip multiple files
   - Upload single archive
   - Unzip on other device
   - Reduces overhead

4. **Delta Sync** (Advanced):
   - Compute file diffs
   - Upload only changed bytes
   - Requires custom implementation

---

## 6. Conflict Resolution Strategy

### 6.1 Conflict Detection

**Conflict Occurs When**:
- Local file modified since last sync: `local.modified > metadata.lastSync`
- Cloud file modified since last sync: `cloud.modified > metadata.lastSync`
- Both conditions true simultaneously

**Detection Algorithm**:
```swift
func detectConflict(for task: Task) -> ConflictInfo? {
    let localURL = localFileIO.taskURL(for: task)
    let cloudURL = cloudTaskURL(for: task)

    guard let metadata = syncMetadata[localURL.path] else {
        return nil  // No sync history, not a conflict
    }

    let localModified = localURL.modificationDate ?? .distantPast
    let cloudModified = cloudURL.modificationDate ?? .distantPast
    let lastSync = metadata.lastSyncDate ?? .distantPast

    let localChanged = localModified > lastSync
    let cloudChanged = cloudModified > lastSync

    if localChanged && cloudChanged {
        // Conflict detected
        return ConflictInfo(
            taskId: task.id,
            localVersion: try? readTask(from: localURL),
            cloudVersion: try? readTask(from: cloudURL),
            localModified: localModified,
            cloudModified: cloudModified,
            lastSync: lastSync
        )
    }

    return nil
}
```

### 6.2 Resolution Strategies

#### Strategy 1: User Choice (Default, Most Conservative)

**Flow**:
1. Detect conflict
2. Show notification: "1 conflict detected"
3. User clicks → Opens conflict resolution UI
4. Display side-by-side comparison
5. User chooses: Keep Local | Keep Cloud | Merge
6. Apply choice and mark resolved

**UI Design**:
```
┌──────────────────────────────────────────────────────┐
│  Conflict Detected: "Implement iCloud sync"          │
├──────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────────────┐  ┌─────────────────────┐  │
│  │   Local Version     │  │   Cloud Version     │  │
│  ├─────────────────────┤  ├─────────────────────┤  │
│  │ Modified: 2:30 PM   │  │ Modified: 2:35 PM   │  │
│  │ (This Mac)          │  │ (iPhone)            │  │
│  ├─────────────────────┤  ├─────────────────────┤  │
│  │                     │  │                     │  │
│  │ Title: Implement... │  │ Title: Implement... │  │
│  │ Status: next-action │  │ Status: in-progress │◄─ Diff
│  │ Priority: high      │  │ Priority: high      │  │
│  │ Due: Dec 1          │  │ Due: Dec 1          │  │
│  │                     │  │                     │  │
│  │ Notes:              │  │ Notes:              │  │
│  │ Started work on...  │  │ Made great progress │◄─ Diff
│  │                     │  │ today. Added file...│  │
│  └─────────────────────┘  └─────────────────────┘  │
│                                                       │
│  Differences:                                         │
│  • Status: next-action vs in-progress                │
│  • Notes content changed                             │
│                                                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │ Keep Local  │ │ Keep Cloud  │ │   Merge     │   │
│  └─────────────┘ └─────────────┘ └─────────────┘   │
│                                                       │
│  [Show Details] [Resolve Later] [Cancel]             │
└──────────────────────────────────────────────────────┘
```

**Advantages**:
- ✅ No data loss
- ✅ User in control
- ✅ Transparent process

**Disadvantages**:
- ❌ Requires user intervention
- ❌ Can interrupt workflow

#### Strategy 2: Last Write Wins (Optional, Automatic)

**Flow**:
1. Detect conflict
2. Compare modification dates
3. Newer version wins
4. Silently replace older version
5. Log resolution in activity log

**When to Use**:
- User preference in settings
- Single-user scenarios
- Rapid iteration workflow

**Advantages**:
- ✅ Fully automatic
- ✅ No user interruption
- ✅ Simple logic

**Disadvantages**:
- ❌ Potential data loss
- ❌ No awareness of conflict
- ❌ Can't merge changes

#### Strategy 3: Smart Merge (Advanced)

**Flow**:
1. Detect conflict
2. Parse both YAML frontmatters
3. Compare field-by-field
4. Auto-merge non-conflicting fields
5. Prompt only for true conflicts

**Field-Level Conflict Detection**:
```swift
func smartMerge(local: Task, cloud: Task) -> MergeResult {
    var merged = local
    var conflicts: [FieldConflict] = []

    // Simple fields: take newer
    if cloud.modified > local.modified {
        if cloud.title != local.title {
            conflicts.append(.title(local: local.title, cloud: cloud.title))
        }
        if cloud.status != local.status {
            conflicts.append(.status(local: local.status, cloud: cloud.status))
        }
    }

    // Mergeable fields: union
    let allTags = Set(local.tags).union(Set(cloud.tags))
    merged.tags = Array(allTags)

    // Positions: merge dictionaries
    merged.positions = local.positions.merging(cloud.positions) { local, cloud in
        cloud  // Prefer cloud position if conflict
    }

    // Notes: offer merge if different
    if local.notes != cloud.notes {
        conflicts.append(.notes(local: local.notes, cloud: cloud.notes))
    }

    if conflicts.isEmpty {
        return .autoMerged(merged)
    } else {
        return .needsUserInput(merged, conflicts: conflicts)
    }
}
```

**Advantages**:
- ✅ Minimizes user intervention
- ✅ Intelligent merging
- ✅ Best user experience

**Disadvantages**:
- ❌ Complex implementation
- ❌ Edge cases difficult
- ❌ Requires thorough testing

### 6.3 Conflict Versioning

**NSFileVersion Integration**:
- macOS automatically preserves conflict versions
- Access via `NSFileVersion.unresolvedConflictVersionsOfItem(at: URL)`
- User can inspect all versions
- Manual rollback possible

**Conflict History UI**:
```
┌─────────────────────────────────────────┐
│  Conflict History: "Task Title"         │
├─────────────────────────────────────────┤
│                                         │
│  Current Version (Resolved)             │
│  └─ Modified: Nov 18, 3:00 PM (Mac)     │
│                                         │
│  Conflict Versions:                     │
│  ├─ Version 1: Nov 18, 2:30 PM (Mac)    │
│  ├─ Version 2: Nov 18, 2:35 PM (iPhone) │
│  └─ Version 3: Nov 18, 2:40 PM (iPad)   │
│                                         │
│  [View Version] [Restore] [Delete All]  │
└─────────────────────────────────────────┘
```

### 6.4 Recommended Approach

**Primary**: Smart Merge with User Fallback

1. Attempt automatic field-level merge
2. If successful, apply silently
3. If conflicts remain, show UI with:
   - Auto-merged fields (non-editable)
   - Conflicting fields (user choice)
   - Full versions (for reference)
4. Log all resolutions in activity log

**Settings**:
- Default: Smart merge
- Option: Always ask (conservative)
- Option: Last write wins (risky)

---

## 7. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-3)

**Goal**: Basic iCloud Drive integration without conflicts

**Tasks**:
1. **iCloud Entitlements Setup** (1 day)
   - Add iCloud capability to Xcode project
   - Configure ubiquity container identifier
   - Test entitlement provisioning

2. **Ubiquity Container Access** (2 days)
   - Implement `iCloudManager` class
   - Check for iCloud availability
   - Get ubiquity container URL
   - Handle "not signed in" state

3. **Basic File Upload** (3 days)
   - NSFileCoordinator integration
   - Upload single task to iCloud
   - Monitor upload status
   - Handle upload errors

4. **Basic File Download** (3 days)
   - NSMetadataQuery setup
   - Monitor cloud file changes
   - Download cloud file
   - Replace local file

5. **Settings UI** (2 days)
   - Sync enable/disable toggle
   - Manual sync trigger button
   - Sync status indicator
   - Basic error messages

6. **Testing** (3 days)
   - Test on two devices
   - Verify file synchronization
   - Test offline behavior
   - Document issues

**Deliverable**: Basic sync working (no conflicts)

---

### Phase 2: Sync Infrastructure (Weeks 4-6)

**Goal**: Robust sync with metadata tracking

**Tasks**:
1. **SyncMetadataStore** (4 days)
   - Design SQLite schema
   - Implement CRUD operations
   - Track sync state per file
   - Persist across launches

2. **Upload Queue** (3 days)
   - Batch upload operations
   - Debounce upload triggers
   - Priority queue (recent changes first)
   - Retry failed uploads

3. **Download Queue** (3 days)
   - Batch download operations
   - Handle file deletions
   - Skip unchanged files
   - Retry failed downloads

4. **Progress Tracking** (2 days)
   - Upload progress per file
   - Download progress per file
   - Overall sync progress
   - UI updates

5. **Background Sync** (3 days)
   - Launch background queue
   - Low-priority sync operations
   - Respect battery/network
   - Optimize performance

6. **Testing** (3 days)
   - Sync 100+ tasks
   - Test large files
   - Network interruption testing
   - Performance benchmarks

**Deliverable**: Production-ready sync (still no conflicts)

---

### Phase 3: Conflict Resolution (Weeks 7-9)

**Goal**: Handle conflicts gracefully

**Tasks**:
1. **Conflict Detection** (3 days)
   - Implement detection algorithm
   - Track file modification dates
   - Identify conflicting files
   - Queue conflicts for resolution

2. **ConflictResolver** (5 days)
   - Parse both versions
   - Field-level comparison
   - Smart merge logic
   - Resolution strategies

3. **Conflict UI** (5 days)
   - Side-by-side diff view
   - Field highlighting
   - User choice controls
   - Merge editor

4. **NSFileVersion Integration** (2 days)
   - Access conflict versions
   - Version history UI
   - Manual version restore
   - Clean up old versions

5. **Testing** (4 days)
   - Simulate conflicts
   - Test all resolution strategies
   - Edge case testing
   - User acceptance testing

**Deliverable**: Full conflict resolution

---

### Phase 4: Advanced Features (Weeks 10-12)

**Goal**: Polish and optimize

**Tasks**:
1. **Attachment Sync** (4 days)
   - Separate attachment directory
   - Lazy download attachments
   - Attachment metadata
   - Size limits and warnings

2. **Selective Sync** (3 days)
   - Choose what to sync (tasks, boards, etc.)
   - Sync only active tasks option
   - Archive exclusion option
   - Settings UI

3. **Initial Sync Optimization** (3 days)
   - Compress file batches
   - Parallel uploads
   - Progress UI
   - Time estimates

4. **Sync Status UI** (3 days)
   - Detailed sync history
   - Per-file sync status
   - Error log viewer
   - Manual retry controls

5. **Settings & Preferences** (2 days)
   - Sync frequency options
   - Conflict resolution default
   - Network preferences (WiFi only)
   - Storage quota warnings

6. **Documentation** (2 days)
   - User guide for sync
   - Troubleshooting guide
   - Developer documentation
   - API reference

7. **Testing & QA** (5 days)
   - Full integration testing
   - Multi-device scenarios
   - Performance testing
   - Beta user feedback

**Deliverable**: Production-ready iCloud sync

---

### Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| Phase 1: Foundation | 3 weeks | Basic sync working |
| Phase 2: Infrastructure | 3 weeks | Production sync |
| Phase 3: Conflicts | 3 weeks | Conflict resolution |
| Phase 4: Advanced | 3 weeks | Polish & optimize |
| **Total** | **12 weeks** | **Full iCloud Sync** |

**Buffer**: Add 1-2 weeks for unexpected issues

**Total Estimate**: 2.5-3 months

---

## 8. Edge Cases and Challenges

### 8.1 File System Edge Cases

#### Challenge 1: File Moves (Active ↔ Archive)

**Problem**: Task completion moves file from `tasks/active/` to `tasks/archive/`
- Creates new file in archive
- Deletes file from active
- iCloud sees: delete + create (not move)
- Could trigger conflict on other device

**Solution**:
1. Use NSFileCoordinator for move operations
2. Sync metadata tracks moves (oldPath → newPath)
3. Other devices recognize as move, not delete+create
4. Update positions and references

**Implementation**:
```swift
func moveTaskToArchive(_ task: Task) throws {
    let activeURL = localFileIO.taskURL(for: task)
    var archivedTask = task
    archivedTask.status = .completed
    let archiveURL = localFileIO.taskURL(for: archivedTask)

    let coordinator = NSFileCoordinator(filePresenter: nil)
    var error: NSError?

    coordinator.coordinate(
        writingItemAt: activeURL,
        options: .forMoving,
        writingItemAt: archiveURL,
        options: .forReplacing,
        error: &error
    ) { (fromURL, toURL) in
        try? FileManager.default.moveItem(at: fromURL, to: toURL)

        // Record move in sync metadata
        syncMetadata.recordMove(from: activeURL, to: archiveURL)
    }
}
```

#### Challenge 2: Directory Structure Changes

**Problem**: Year/month directories created dynamically
- New month = new directory
- iCloud must sync empty directories
- Permission issues possible

**Solution**:
- Pre-create directory structure on sync enable
- Monitor directory changes separately
- Ensure consistent structure across devices

#### Challenge 3: Rapid Sequential Edits

**Problem**: User edits task multiple times quickly
- Debounce creates delay
- Multiple versions in flight
- Potential conflicts

**Solution**:
- Track edit sequences with monotonic counter
- Include sequence number in sync metadata
- Resolve by highest sequence number
- Coalesce rapid edits before sync

### 8.2 Network and Performance

#### Challenge 4: Large File Uploads (Attachments)

**Problem**: Syncing 10 MB PDF attachment
- Slow upload on cellular
- Blocks other sync operations
- Battery drain

**Solution**:
- Separate queue for large files
- WiFi-only option for large files
- Pause/resume support
- Background upload tasks
- Warn user before large upload

**Size Thresholds**:
- Small (< 1 MB): Immediate sync
- Medium (1-10 MB): Queue, WiFi preferred
- Large (> 10 MB): Prompt user, WiFi only

#### Challenge 5: Hundreds of Tasks Initial Sync

**Problem**: First sync on new device with 500+ tasks
- Long download time
- Progress unclear
- User may quit app

**Solution**:
1. **Phased Download**:
   - Phase 1: Active tasks (inbox, next actions)
   - Phase 2: Recent tasks (modified last 30 days)
   - Phase 3: Archive (background)

2. **Progress UI**:
   ```
   Syncing Tasks from iCloud
   ▓▓▓▓▓▓▓▓▓░░░░░░░  45% (225/500)

   Downloading: "Implement sync"
   Estimated: 2 minutes remaining

   [Pause] [Continue in Background]
   ```

3. **Background Continuation**:
   - Allow app use during sync
   - Show banner when complete
   - Resume on app relaunch

#### Challenge 6: Network Failures

**Problem**: Upload fails mid-transfer
- Partial file in cloud
- Corrupt sync state
- User confusion

**Solution**:
- Atomic file operations (write to temp, then move)
- Retry logic with exponential backoff
- Mark failed uploads for manual retry
- Show clear error messages
- Offline queue (sync when online)

**Retry Algorithm**:
```swift
func uploadWithRetry(url: URL, maxRetries: Int = 3) async throws {
    var attempt = 0
    var lastError: Error?

    while attempt < maxRetries {
        do {
            try await uploadFile(url)
            return  // Success
        } catch {
            lastError = error
            attempt += 1

            if attempt < maxRetries {
                let delay = pow(2.0, Double(attempt))  // Exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw SyncError.uploadFailed(after: maxRetries, lastError: lastError)
}
```

### 8.3 Storage and Quota

#### Challenge 7: iCloud Storage Quota

**Problem**: User's iCloud storage full
- Sync fails silently or with cryptic error
- User doesn't know why
- Tasks not syncing

**Solution**:
1. **Check Quota Before Sync**:
   ```swift
   func checkiCloudQuota() async -> QuotaStatus {
       guard let containerURL = ubiquityContainerURL else {
           return .unavailable
       }

       let query = NSMetadataQuery()
       // Query storage usage

       return .available(used: usedBytes, total: totalBytes)
   }
   ```

2. **Warn User**:
   ```
   ⚠️ iCloud Storage Almost Full

   You have 45 MB of 50 MB used (90%)
   StickyToDo needs 12 MB to sync all tasks

   [Upgrade Storage] [Manage]
   ```

3. **Selective Sync Options**:
   - Don't sync archive (save space)
   - Don't sync large attachments
   - Download on demand

#### Challenge 8: Orphaned Attachments

**Problem**: Task deleted, attachment file remains
- Wasted storage
- Orphaned files in cloud
- Difficult to clean

**Solution**:
- Reference counting for attachments
- Periodic cleanup task
- "Optimize Storage" feature
- Warn before deleting

### 8.4 Multi-Device Scenarios

#### Challenge 9: Concurrent Edits (Race Condition)

**Problem**: Edit same task simultaneously on Mac and iPhone
- Both devices think they have latest version
- Sync conflict inevitable
- User must resolve

**Solution**:
- Operational transformation (complex)
- Last write wins with notification
- Smart merge if possible
- Clear conflict UI

**Best Practice**:
- Document expected behavior
- Encourage single-device editing
- Notifications when conflict resolved elsewhere

#### Challenge 10: Device Clock Skew

**Problem**: Device system time incorrect
- Modification dates unreliable
- Conflict detection breaks
- Wrong version chosen

**Solution**:
- Use server time when available
- Detect clock skew (compare with server)
- Warn user if detected
- Fallback to version vectors (Lamport timestamps)

**Detection**:
```swift
func detectClockSkew() -> TimeInterval {
    let localTime = Date()
    let cloudTime = getCloudServerTime()  // iCloud metadata
    let skew = localTime.timeIntervalSince(cloudTime)

    if abs(skew) > 60 {  // More than 1 minute off
        logger?("⚠️ Clock skew detected: \(skew) seconds")
        return skew
    }
    return 0
}
```

### 8.5 Data Integrity

#### Challenge 11: Corrupt YAML File

**Problem**: File corrupted during sync
- Parse error when reading
- App crashes
- Data loss

**Solution**:
- Validate YAML before applying
- Keep backup of previous version
- Log parse errors
- Attempt auto-recovery
- Fallback to conflict resolution UI

**Recovery**:
```swift
func readTaskWithRecovery(from url: URL) throws -> Task? {
    do {
        return try readTask(from: url)
    } catch {
        logger?("Parse error: \(error)")

        // Attempt recovery
        if let backup = findBackupVersion(for: url) {
            logger?("Attempting recovery from backup")
            return try? readTask(from: backup)
        }

        // Show error to user
        presentCorruptFileError(url: url, error: error)
        return nil
    }
}
```

#### Challenge 12: Subtask Reference Integrity

**Problem**: Parent task synced, subtask not yet synced
- Broken reference
- Subtask appears orphaned
- UI shows error

**Solution**:
- Validate references after sync
- Queue dependent files together
- Placeholder for missing subtasks
- Auto-resolve when subtask syncs

---

## 9. Sync Settings UI Design

### 9.1 Settings Panel

```
┌──────────────────────────────────────────────────────┐
│  Sync Settings                                       │
├──────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────────────────────────────────────┐    │
│  │  iCloud Sync                                │    │
│  │  ┌───────────────────────────────────────┐  │    │
│  │  │ Enable iCloud Sync            [ON] ▼  │  │    │
│  │  └───────────────────────────────────────┘  │    │
│  │                                              │    │
│  │  Status: ✓ All synced (2 minutes ago)       │    │
│  │  Storage: 12.3 MB / 50 GB available         │    │
│  │  Devices: Mac, iPhone, iPad (3)             │    │
│  │                                              │    │
│  │  [View Sync History] [Troubleshoot]         │    │
│  └─────────────────────────────────────────────┘    │
│                                                       │
│  What to Sync:                                        │
│  ┌─────────────────────────────────────────────┐    │
│  │ ☑ Tasks (active)                            │    │
│  │ ☑ Tasks (archive)                           │    │
│  │ ☑ Boards                                    │    │
│  │ ☑ Rules & Automation                        │    │
│  │ ☑ Activity Log                              │    │
│  │ ☐ Large Attachments (> 10 MB)              │    │
│  └─────────────────────────────────────────────┘    │
│                                                       │
│  Sync Behavior:                                       │
│  ┌─────────────────────────────────────────────┐    │
│  │ Sync Frequency:     [Automatic]      ▼      │    │
│  │   • Automatic (recommended)                 │    │
│  │   • Manual only                             │    │
│  │                                              │    │
│  │ Conflict Resolution: [Smart Merge]   ▼      │    │
│  │   • Smart merge (auto when possible)        │    │
│  │   • Always ask                              │    │
│  │   • Last write wins (risky)                 │    │
│  │                                              │    │
│  │ Network:            [WiFi + Cellular] ▼     │    │
│  │   • WiFi + Cellular                         │    │
│  │   • WiFi only                               │    │
│  │                                              │    │
│  │ ☑ Sync in background                        │    │
│  │ ☑ Show sync notifications                   │    │
│  └─────────────────────────────────────────────┘    │
│                                                       │
│  Advanced:                                            │
│  ┌─────────────────────────────────────────────┐    │
│  │ [Force Full Sync]                           │    │
│  │ [Clear Sync Metadata]                       │    │
│  │ [Reset Sync (Dangerous)]                    │    │
│  │ [Export Sync Logs]                          │    │
│  └─────────────────────────────────────────────┘    │
│                                                       │
└──────────────────────────────────────────────────────┘
```

### 9.2 Sync Status Indicator (Menu Bar)

```
┌────────────────────────────┐
│ ☁️ StickyToDo               │ ← Normal (synced)
├────────────────────────────┤
│ Last sync: 2 minutes ago   │
│ All devices synced         │
├────────────────────────────┤
│ [Sync Now]                 │
│ [View Conflicts]           │
│ [Settings]                 │
└────────────────────────────┘

┌────────────────────────────┐
│ ⟳ StickyToDo (Syncing...)  │ ← Syncing
├────────────────────────────┤
│ Uploading 3 tasks          │
│ ▓▓▓▓▓░░░░░ 45%             │
├────────────────────────────┤
│ [Pause Sync]               │
│ [Settings]                 │
└────────────────────────────┘

┌────────────────────────────┐
│ ⚠️ StickyToDo (2 conflicts) │ ← Conflicts
├────────────────────────────┤
│ 2 tasks need resolution    │
├────────────────────────────┤
│ [Resolve Conflicts]        │
│ [Sync Now]                 │
│ [Settings]                 │
└────────────────────────────┘

┌────────────────────────────┐
│ ☁️❌ StickyToDo (Offline)     │ ← Error/Offline
├────────────────────────────┤
│ No internet connection     │
│ 5 tasks queued to upload   │
├────────────────────────────┤
│ [Retry Now]                │
│ [View Queue]               │
│ [Settings]                 │
└────────────────────────────┘
```

### 9.3 Initial Sync Setup Flow

**Step 1: Enable iCloud Sync**
```
┌──────────────────────────────────────────────┐
│  Enable iCloud Sync                          │
├──────────────────────────────────────────────┤
│                                              │
│  ☁️ Sync your tasks across all devices        │
│                                              │
│  ✓ Automatic sync between Mac, iPhone, iPad │
│  ✓ Always up to date                         │
│  ✓ Secure & private                          │
│  ✓ Works offline                             │
│                                              │
│  Requirements:                               │
│  • Signed in to iCloud                       │
│  • 50 MB free storage (you have 45 GB)       │
│  • Internet connection                       │
│                                              │
│  [Enable iCloud Sync] [Not Now]              │
│                                              │
└──────────────────────────────────────────────┘
```

**Step 2: Choose Sync Mode**
```
┌──────────────────────────────────────────────┐
│  Choose Sync Mode                            │
├──────────────────────────────────────────────┤
│                                              │
│  This device has 247 tasks locally.          │
│  We found 0 tasks in iCloud.                 │
│                                              │
│  How would you like to proceed?              │
│                                              │
│  ○ Upload to iCloud (Recommended)            │
│    Your tasks will be available on all       │
│    devices. Initial upload may take a few    │
│    minutes.                                  │
│                                              │
│  ○ Download from iCloud                      │
│    Replace local tasks with iCloud tasks.    │
│    ⚠️ This will overwrite your local data.   │
│                                              │
│  ○ Merge with iCloud                         │
│    Combine local and cloud tasks. May        │
│    require conflict resolution.              │
│                                              │
│  [Continue] [Cancel]                         │
│                                              │
└──────────────────────────────────────────────┘
```

**Step 3: Upload Progress**
```
┌──────────────────────────────────────────────┐
│  Uploading to iCloud                         │
├──────────────────────────────────────────────┤
│                                              │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░  68% (168/247 tasks)   │
│                                              │
│  Current: "Design iCloud architecture"       │
│  Time remaining: About 1 minute              │
│                                              │
│  What's being uploaded:                      │
│  ✓ Tasks (247)                               │
│  ✓ Boards (12)                               │
│  ✓ Rules (5)                                 │
│  ◌ Activity Log (pending)                    │
│                                              │
│  [Pause] [Continue in Background]            │
│                                              │
└──────────────────────────────────────────────┘
```

**Step 4: Success**
```
┌──────────────────────────────────────────────┐
│  ✓ iCloud Sync Enabled                       │
├──────────────────────────────────────────────┤
│                                              │
│  All 247 tasks synced successfully!          │
│                                              │
│  Your tasks are now available on:            │
│  • This Mac                                  │
│  • Any other device signed in to iCloud      │
│                                              │
│  Next steps:                                 │
│  1. Install StickyToDo on iPhone/iPad        │
│  2. Sign in with same iCloud account         │
│  3. Enable sync – your tasks will appear     │
│                                              │
│  Tip: Changes sync automatically. You can    │
│  view sync status in the menu bar.           │
│                                              │
│  [Done] [View Settings]                      │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 10. Testing Strategy

### 10.1 Test Scenarios

#### Unit Tests

**SyncMetadataStore**:
- ✓ Save/load sync metadata
- ✓ Update sync state
- ✓ Query by sync state
- ✓ Delete metadata

**ConflictResolver**:
- ✓ Detect conflicts correctly
- ✓ Smart merge non-conflicting fields
- ✓ Identify conflicting fields
- ✓ Apply user resolution

**File Coordination**:
- ✓ Safe concurrent reads
- ✓ Safe concurrent writes
- ✓ Move operations
- ✓ Error handling

#### Integration Tests

**Upload Flow**:
1. Create task locally
2. Verify upload to iCloud
3. Check sync metadata updated
4. Verify file in ubiquity container
5. Confirm status = synced

**Download Flow**:
1. Create task in iCloud (simulate)
2. Verify NSMetadataQuery detects
3. Download to local
4. Load into TaskStore
5. Confirm visible in UI

**Conflict Resolution**:
1. Create task on device A
2. Sync to cloud
3. Edit task on device B
4. Edit task on device A (offline)
5. Bring device A online
6. Verify conflict detected
7. Resolve conflict
8. Verify both devices synced

#### Multi-Device Tests

**Scenario 1: Two Devices (Mac + iPhone)**:
1. Enable sync on Mac
2. Create 10 tasks on Mac
3. Wait for sync completion
4. Enable sync on iPhone
5. Verify all 10 tasks appear
6. Edit task on iPhone
7. Verify change appears on Mac
8. Delete task on Mac
9. Verify deletion on iPhone

**Scenario 2: Offline Editing**:
1. Disable WiFi on device A
2. Edit 5 tasks on device A
3. Edit different 5 tasks on device B
4. Enable WiFi on device A
5. Verify all 10 edits synced
6. Confirm no conflicts

**Scenario 3: Conflict Storm**:
1. Edit same task on 3 devices simultaneously
2. Bring all online at once
3. Verify conflict detection
4. Resolve conflicts
5. Ensure data integrity

### 10.2 Performance Tests

**Large Dataset**:
- Load 1000 tasks
- Enable sync
- Measure upload time
- Measure memory usage
- Verify no UI lag

**Rapid Edits**:
- Edit 50 tasks rapidly (< 10 seconds)
- Verify debouncing works
- Confirm all edits synced
- Check no duplicate uploads

**Network Stress**:
- Simulate slow network (100 KB/s)
- Upload 50 MB of attachments
- Verify progress updates
- Test pause/resume
- Confirm completion

### 10.3 Edge Case Tests

**File Moves**:
- Complete task (active → archive)
- Verify move syncs correctly
- No duplicate files
- References updated

**Orphaned Attachments**:
- Delete task with attachment
- Verify attachment cleanup
- No orphaned files in cloud

**Clock Skew**:
- Set device time 1 hour ahead
- Edit task
- Sync with correct-time device
- Verify conflict resolution works

**Storage Quota**:
- Fill iCloud to 99%
- Attempt sync
- Verify quota warning
- Graceful degradation

### 10.4 Beta Testing Plan

**Phase 1: Internal Testing** (1 week)
- Development team uses on real tasks
- 2-3 devices per person
- Report all issues
- Validate core flows

**Phase 2: Closed Beta** (2 weeks)
- 20-30 trusted users
- Provide feedback form
- Monitor crash reports
- Weekly check-ins

**Phase 3: Public Beta** (2 weeks)
- 100-200 users
- TestFlight release
- Collect analytics
- Address critical bugs

**Acceptance Criteria**:
- ✓ 99%+ crash-free rate
- ✓ <5% conflict rate
- ✓ <10 second average sync time
- ✓ 4.5+ user satisfaction score

---

## 11. Migration Plan

### 11.1 Migration from Local-Only to iCloud

**User Communication**:
- Announce feature in release notes
- In-app notification about iCloud sync
- Blog post explaining benefits
- Video tutorial

**Opt-In Approach** (Recommended):
- Default: Sync disabled
- Prompt user to enable
- Explain benefits and requirements
- Clear "Not Now" option

**Migration Flow**:

**Step 1: Pre-Migration Check**
```swift
func canEnableiCloudSync() -> SyncEligibility {
    // Check iCloud account
    guard let _ = FileManager.default.ubiquityIdentityToken else {
        return .notSignedIn
    }

    // Check storage quota
    let requiredSpace = estimateRequiredSpace()
    let availableSpace = getAvailableiCloudSpace()

    if requiredSpace > availableSpace {
        return .insufficientStorage(required: requiredSpace, available: availableSpace)
    }

    // Check for unsupported features
    if hasUnsupportedAttachments() {
        return .unsupportedData
    }

    return .eligible
}
```

**Step 2: Backup Creation**
```swift
func createPreSyncBackup() throws {
    let backupURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("StickyToDo-Backup-\(Date().ISO8601Format())")

    // Copy entire data directory
    try FileManager.default.copyItem(
        at: localFileIO.rootDirectory,
        to: backupURL
    )

    logger?("Created backup at: \(backupURL.path)")

    // Store backup location
    UserDefaults.standard.set(backupURL.path, forKey: "lastSyncBackup")
}
```

**Step 3: Enable Sync**
```swift
func enableiCloudSync() async throws {
    // 1. Create backup
    try createPreSyncBackup()

    // 2. Initialize ubiquity container
    guard let ubiquityURL = FileManager.default.url(
        forUbiquityContainerIdentifier: nil
    ) else {
        throw SyncError.containerUnavailable
    }

    // 3. Create directory structure in iCloud
    try createCloudDirectoryStructure(at: ubiquityURL)

    // 4. Start metadata monitoring
    startMonitoringCloudChanges()

    // 5. Upload all local files
    try await uploadAllLocalFiles()

    // 6. Mark sync as enabled
    UserDefaults.standard.set(true, forKey: "iCloudSyncEnabled")

    logger?("iCloud sync enabled successfully")
}
```

**Step 4: Rollback Plan**

```swift
func disableiCloudSync(deleteCloudData: Bool = false) throws {
    // 1. Stop sync operations
    cancelAllPendingSyncs()

    // 2. Optionally delete cloud data
    if deleteCloudData {
        try deleteAllCloudFiles()
    }

    // 3. Clear sync metadata
    try syncMetadataStore.clear()

    // 4. Mark sync as disabled
    UserDefaults.standard.set(false, forKey: "iCloudSyncEnabled")

    logger?("iCloud sync disabled")
}
```

### 11.2 Data Integrity Validation

**Post-Migration Checks**:
1. **File Count Match**:
   - Count local files
   - Count cloud files
   - Alert if mismatch

2. **Data Integrity**:
   - Parse all cloud files
   - Verify no corruption
   - Check references (subtasks, boards)

3. **Metadata Validation**:
   - All tasks have valid IDs
   - Timestamps reasonable
   - No duplicate IDs

**Validation Script**:
```swift
func validateSyncIntegrity() async -> ValidationReport {
    var report = ValidationReport()

    // Check file counts
    let localTaskCount = try? localFileIO.loadAllTasks().count
    let cloudTaskCount = try? loadAllCloudTasks().count

    report.localTaskCount = localTaskCount ?? 0
    report.cloudTaskCount = cloudTaskCount ?? 0
    report.countMatch = localTaskCount == cloudTaskCount

    // Check for corrupted files
    report.corruptedFiles = findCorruptedFiles()

    // Check for orphaned references
    report.orphanedReferences = findOrphanedReferences()

    return report
}
```

### 11.3 User Communication

**Email Template** (Launch Announcement):
```
Subject: Introducing iCloud Sync for StickyToDo

Hi [Name],

We're excited to announce iCloud Sync for StickyToDo!

Your tasks, boards, and all your GTD workflows can now seamlessly sync across all your Apple devices.

What's New:
✓ Automatic sync between Mac, iPhone, and iPad
✓ Always up to date, everywhere
✓ Works offline - syncs when back online
✓ Smart conflict resolution
✓ Your data stays private and secure

Getting Started:
1. Update StickyToDo to v2.0 on all devices
2. Go to Settings > Sync
3. Enable iCloud Sync
4. Your tasks will sync automatically

Note: This feature is completely optional. If you prefer local-only storage, your workflow remains unchanged.

Questions? Check out our Sync Guide: [link]

Happy syncing!
The StickyToDo Team
```

---

## 12. Technical Challenges and Solutions

### 12.1 Challenge: YAML Frontmatter Conflicts

**Problem**: Merging YAML frontmatter is not trivial
- YAML is order-sensitive
- Formatting differences can cause false conflicts
- Comments could be lost

**Solution**: Structured Merge
```swift
func mergeYAMLFrontmatter(local: Task, cloud: Task) -> Task {
    var merged = local

    // Use newer timestamps for most fields
    if cloud.modified > local.modified {
        merged.title = cloud.title
        merged.status = cloud.status
        merged.project = cloud.project
        merged.context = cloud.context
        merged.due = cloud.due
        merged.priority = cloud.priority
    }

    // Union merge for arrays
    merged.tags = Array(Set(local.tags).union(Set(cloud.tags)))

    // Dictionary merge for positions
    merged.positions = local.positions.merging(cloud.positions) { _, cloud in cloud }

    // Keep newer modification date
    merged.modified = max(local.modified, cloud.modified)

    return merged
}
```

### 12.2 Challenge: Notification Spam

**Problem**: Too many sync notifications
- Upload complete
- Download complete
- Conflicts detected
- Errors occurred
- User gets annoyed

**Solution**: Smart Notification Batching
```swift
class SyncNotificationManager {
    private var pendingNotifications: [SyncNotification] = []
    private var notificationTimer: Timer?

    func scheduleNotification(_ notification: SyncNotification) {
        pendingNotifications.append(notification)

        // Debounce: wait 5 seconds before showing
        notificationTimer?.invalidate()
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            self.showBatchedNotifications()
        }
    }

    func showBatchedNotifications() {
        // Combine similar notifications
        let conflicts = pendingNotifications.filter { $0.type == .conflict }.count
        let errors = pendingNotifications.filter { $0.type == .error }.count

        if conflicts > 0 {
            showNotification(title: "Sync Conflicts", body: "\(conflicts) tasks need resolution")
        }

        if errors > 0 {
            showNotification(title: "Sync Errors", body: "\(errors) tasks failed to sync")
        }

        pendingNotifications.removeAll()
    }
}
```

**Notification Preferences**:
- Show all notifications (verbose)
- Show only important (errors, conflicts)
- Silent (status bar only)
- Disabled

### 12.3 Challenge: Attachment File Size

**Problem**: User uploads 50 MB video attachment
- Exceeds reasonable size
- Wastes storage
- Slow sync

**Solution**: Size Limits and Warnings
```swift
func validateAttachment(_ attachment: Attachment) -> AttachmentValidation {
    guard case .file(let url) = attachment.type else {
        return .valid
    }

    let fileSize = url.fileSize ?? 0

    // Size thresholds
    let warningSize: Int64 = 10 * 1024 * 1024  // 10 MB
    let maxSize: Int64 = 100 * 1024 * 1024     // 100 MB

    if fileSize > maxSize {
        return .tooLarge(size: fileSize, max: maxSize)
    } else if fileSize > warningSize {
        return .warningLarge(size: fileSize)
    }

    return .valid
}
```

**UI Prompt**:
```
⚠️ Large Attachment Warning

The file "video.mp4" is 45 MB.

Large files may:
• Take a long time to sync
• Use significant iCloud storage
• Require WiFi connection

Recommendations:
• Upload to cloud storage (Dropbox, Google Drive)
• Add link instead of file attachment
• Compress the file

[Attach Anyway] [Use Link Instead] [Cancel]
```

### 12.4 Challenge: Battery and Performance

**Problem**: Background sync drains battery
- Constant file monitoring
- Network activity
- CPU usage for parsing

**Solution**: Adaptive Sync
```swift
class AdaptiveSyncScheduler {
    func determineSyncStrategy() -> SyncStrategy {
        let batteryLevel = ProcessInfo.processInfo.batteryLevel
        let isPluggedIn = ProcessInfo.processInfo.isPluggedIn
        let networkType = getNetworkType()

        // Conservative on battery
        if !isPluggedIn && batteryLevel < 0.20 {
            return .manual  // Only sync when user triggers
        }

        // Aggressive when plugged in and on WiFi
        if isPluggedIn && networkType == .wifi {
            return .immediate  // Sync immediately
        }

        // Balanced otherwise
        return .scheduled(interval: 60)  // Every minute
    }
}
```

**Battery-Saving Measures**:
- Reduce NSMetadataQuery update frequency
- Batch file operations
- Defer non-critical syncs
- Suspend sync when battery < 20%

---

## 13. Future Enhancements (Post-v1)

### 13.1 CloudKit Layer (v2.0)

**Why Add CloudKit Later**:
- File-based sync validates architecture
- User feedback informs CloudKit design
- Collaboration features require CloudKit
- Can coexist with file-based sync

**Migration Path**:
1. Phase 1: File-based sync (v2.0)
2. Phase 2: Add CloudKit for real-time features (v2.5)
3. Phase 3: Hybrid (files for storage, CloudKit for collaboration)

**CloudKit Use Cases**:
- Real-time collaboration on boards
- Live cursors
- Push notifications for changes
- Shared workspaces
- Team features

### 13.2 Differential Sync

**Problem**: Large tasks re-uploaded entirely for small changes

**Solution**: Delta sync
- Compute file diffs
- Upload only changed bytes
- Reduce bandwidth
- Faster sync

**Implementation**:
- Use binary diff algorithm (bsdiff)
- Store deltas in metadata
- Apply patches on download
- Fallback to full file if patch fails

### 13.3 End-to-End Encryption

**Problem**: Data in iCloud not encrypted end-to-end
- Apple can read files
- Privacy concern for sensitive tasks

**Solution**: Client-side encryption
- Encrypt before upload
- Decrypt after download
- User-controlled encryption key
- Zero-knowledge architecture

**Trade-offs**:
- Key management complexity
- No web access (encryption in client)
- Search limitations
- Recovery complexity

### 13.4 Offline Mode Improvements

**Current**: Basic offline queue

**Enhanced**:
- Conflict-free replicated data types (CRDTs)
- Operational transformation
- Optimistic UI updates
- Better offline indicators

---

## 14. Success Metrics

### 14.1 Technical Metrics

**Sync Performance**:
- Average sync time: < 10 seconds (for typical changes)
- Initial sync time: < 2 minutes (for 500 tasks)
- Conflict rate: < 5% of sync operations
- Sync success rate: > 99%
- Crash-free sessions: > 99.5%

**Resource Usage**:
- Memory overhead: < 50 MB
- CPU usage during sync: < 20%
- Battery impact: < 5% per day
- Network usage: < 10 MB per day (typical)

### 14.2 User Experience Metrics

**Adoption**:
- Sync enable rate: > 60% of users
- Multi-device usage: > 40% of sync users
- Retention increase: +15% (sync vs non-sync users)

**Satisfaction**:
- Feature satisfaction: > 4.5 / 5.0
- Conflict resolution: < 10% need support
- Perceived reliability: > 90% "always works"

### 14.3 Business Metrics

**Value Proposition**:
- Conversion lift: +20% (free to paid)
- Premium feature justification
- Competitive parity with OmniFocus/Things
- iOS app prerequisite

---

## 15. Conclusion and Recommendations

### 15.1 Strategic Recommendation

**Proceed with iCloud Drive + File-Based Sync**

**Rationale**:
1. **Preserves Core Philosophy**: Plain-text accessibility maintained
2. **Lower Risk**: Proven technology, well-documented
3. **Faster Time to Market**: 2-3 months vs 4-6 months for CloudKit
4. **User Control**: Files remain user-accessible
5. **Reversible**: Can migrate to CloudKit later if needed

### 15.2 Implementation Approach

**Phased Rollout**:
1. **Phase 1 (v2.0)**: Basic file sync (no conflicts)
2. **Phase 2 (v2.1)**: Conflict resolution
3. **Phase 3 (v2.2)**: Attachment sync
4. **Phase 4 (v2.5)**: CloudKit layer (optional, for collaboration)

**Release Strategy**:
- Internal testing: 2 weeks
- Closed beta: 2 weeks
- Public beta: 2 weeks
- General release: After 95%+ satisfaction

### 15.3 Risk Mitigation

**High Risks**:
- Conflict resolution complexity → Start simple, iterate
- User data loss → Comprehensive backups, reversible migration
- Performance issues → Early performance testing, optimization

**Medium Risks**:
- Storage quota issues → Quota warnings, selective sync
- Network reliability → Offline queue, retry logic
- Battery drain → Adaptive sync, user controls

**Mitigation Strategy**:
- Conservative conflict resolution (always ask)
- Automatic backups before migration
- Kill switch to disable sync remotely
- Comprehensive monitoring and analytics

### 15.4 Next Steps

**Immediate Actions** (Week 1):
1. Validate approach with team
2. Spike: Basic iCloud Drive upload/download
3. Prototype conflict UI
4. Review with users (interviews)

**Pre-Development** (Weeks 2-3):
1. Finalize technical design
2. Create detailed implementation tasks
3. Set up test devices
4. Establish success metrics

**Development** (Weeks 4-15):
1. Phase 1: Foundation (weeks 4-6)
2. Phase 2: Infrastructure (weeks 7-9)
3. Phase 3: Conflicts (weeks 10-12)
4. Phase 4: Polish (weeks 13-15)

**Post-Development** (Weeks 16-18):
1. Beta testing
2. Performance optimization
3. Documentation
4. Marketing preparation

---

## Appendix A: API Reference

### A.1 iCloudSyncCoordinator

```swift
class iCloudSyncCoordinator: ObservableObject {
    // MARK: - Configuration

    /// Enable or disable iCloud sync
    var isSyncEnabled: Bool { get set }

    /// The ubiquity container URL (nil if unavailable)
    var ubiquityContainerURL: URL? { get }

    // MARK: - Status

    /// Current sync status
    @Published var syncStatus: SyncStatus

    /// Last successful sync date
    @Published var lastSyncDate: Date?

    /// Number of pending uploads
    @Published var pendingUploads: Int

    /// Number of pending downloads
    @Published var pendingDownloads: Int

    /// Number of unresolved conflicts
    @Published var conflicts: Int

    // MARK: - Methods

    /// Enable iCloud sync
    func enableSync() async throws

    /// Disable iCloud sync
    func disableSync(deleteCloudData: Bool) async throws

    /// Manually trigger a sync
    func syncNow() async throws

    /// Upload a single task
    func upload(task: Task) async throws

    /// Download a single task
    func download(taskId: UUID) async throws

    /// Resolve a conflict
    func resolveConflict(_ conflict: ConflictInfo, resolution: ConflictResolution) async throws
}
```

### A.2 SyncMetadataStore

```swift
class SyncMetadataStore {
    /// Get sync metadata for a file
    func metadata(for url: URL) -> SyncMetadata?

    /// Update sync metadata
    func update(metadata: SyncMetadata) throws

    /// Query files by sync state
    func files(with state: SyncState) -> [URL]

    /// Clear all metadata
    func clear() throws
}
```

### A.3 ConflictResolver

```swift
class ConflictResolver {
    /// Detect conflict between local and cloud versions
    func detectConflict(local: Task, cloud: Task, lastSync: Date) -> ConflictInfo?

    /// Attempt smart merge
    func smartMerge(local: Task, cloud: Task) -> MergeResult

    /// Apply conflict resolution
    func apply(resolution: ConflictResolution, to conflict: ConflictInfo) throws -> Task
}
```

---

## Appendix B: File Formats

### B.1 SyncMetadata Schema

```json
{
  "fileURL": "file:///path/to/task.md",
  "localModifiedDate": "2025-11-18T14:30:00Z",
  "cloudModifiedDate": "2025-11-18T14:35:00Z",
  "lastSyncDate": "2025-11-18T14:00:00Z",
  "syncState": "conflict",
  "conflictVersions": [
    "file:///.conflicts/version-1.md",
    "file:///.conflicts/version-2.md"
  ],
  "lastSyncAttempt": "2025-11-18T14:35:05Z",
  "syncError": null,
  "retryCount": 0
}
```

### B.2 Conflict Info

```json
{
  "taskId": "123e4567-e89b-12d3-a456-426614174000",
  "localVersion": { ...task object... },
  "cloudVersion": { ...task object... },
  "localModified": "2025-11-18T14:30:00Z",
  "cloudModified": "2025-11-18T14:35:00Z",
  "lastSync": "2025-11-18T14:00:00Z",
  "conflictingFields": ["status", "notes"],
  "detectedAt": "2025-11-18T14:36:00Z"
}
```

---

## Appendix C: Glossary

**NSFileCoordinator**: macOS API for safe concurrent file access
**NSMetadataQuery**: macOS API for monitoring file changes in iCloud
**Ubiquity Container**: iCloud storage location for app files
**CloudKit**: Apple's database-as-a-service for iCloud apps
**CKRecord**: CloudKit database record type
**NSUbiquitousKeyValueStore**: iCloud key-value storage (1 MB limit)
**CRDT**: Conflict-free Replicated Data Type
**Operational Transformation**: Algorithm for merging concurrent edits
**Last Write Wins**: Conflict resolution strategy using timestamps
**Smart Merge**: Automatic field-level conflict resolution

---

**Report Version**: 1.0
**Date**: 2025-11-18
**Next Review**: Upon development kickoff
**Status**: Ready for Implementation Planning

---

*This report provides comprehensive architectural guidance for implementing iCloud sync in StickyToDo. All recommendations are based on analysis of the current codebase, Apple platform best practices, and strategic product goals. No code changes were made during this planning phase.*
