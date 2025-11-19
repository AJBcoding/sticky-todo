# Xcode Setup Guide for StickyToDo

Complete step-by-step guide for configuring Xcode to build the StickyToDo applications with all dependencies, capabilities, and configuration.

**Last Updated**: 2025-11-18
**Xcode Version**: 15.0+
**macOS Version**: 13.0 (Ventura) or later

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Project Setup](#initial-project-setup)
- [Swift Package Dependencies](#swift-package-dependencies)
- [Info.plist Configuration](#infoplist-configuration)
- [Capabilities and Entitlements](#capabilities-and-entitlements)
- [Framework References](#framework-references)
- [Build Settings](#build-settings)
- [Troubleshooting](#troubleshooting)
- [Verification Checklist](#verification-checklist)

---

## Prerequisites

### System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **Xcode Command Line Tools**: Installed

### Verify Your System

```bash
# Check macOS version
sw_vers

# Check Xcode version
xcodebuild -version

# Check Swift version
swift --version

# Verify Command Line Tools
xcode-select -p
```

Expected output for Xcode:
```
Xcode 15.0
Build version 15A240d
```

---

## Initial Project Setup

### 1. Open the Project

```bash
cd /path/to/sticky-todo
open StickyToDo.xcodeproj
```

Or use Xcode:
- File > Open
- Navigate to `StickyToDo.xcodeproj`
- Click Open

### 2. Verify Project Structure

The project should contain these targets:

1. **StickyToDoCore** - Framework
   - Contains shared models, business logic, and App Intents
   - Required by both app targets

2. **StickyToDo-SwiftUI** - macOS Application
   - Modern SwiftUI-based interface
   - Primary application target

3. **StickyToDo-AppKit** - macOS Application
   - Traditional AppKit-based interface
   - Alternative UI implementation

4. **StickyToDoTests** - Unit Test Bundle
   - Test suite for core functionality

---

## Swift Package Dependencies

### Required Package: Yams

**Yams** is CRITICAL - the entire project depends on it for YAML parsing. Nothing will compile without it.

#### Add Yams via Xcode UI

1. **Open Package Dependencies**
   - Click on the project in the Project Navigator
   - Select the **StickyToDo** project (blue icon at the top)
   - Click the **Package Dependencies** tab

2. **Add Package**
   - Click the **+** button at the bottom left
   - A sheet will appear

3. **Enter Repository URL**
   ```
   https://github.com/jpsim/Yams.git
   ```

4. **Configure Version**
   - Dependency Rule: **Up to Next Major Version**
   - Version: **5.0.0**
   - Click **Add Package**

5. **Select Targets**

   When prompted "Choose Package Products for StickyToDo":

   **Add `Yams` to these targets:**
   - ✅ StickyToDoCore
   - ✅ StickyToDo-SwiftUI
   - ✅ StickyToDo-AppKit

   Click **Add Package**

#### Verify Package Installation

1. In the Project Navigator, you should see a "Package Dependencies" section
2. Expand it to see "Yams"
3. Click on each target and go to **Build Phases > Link Binary With Libraries**
4. Verify "Yams" appears in the list

#### Command Line Verification

```bash
# Resolve packages from command line
xcodebuild -resolvePackageDependencies

# Expected output should include:
# Resolved source packages:
#   Yams: https://github.com/jpsim/Yams.git @ 5.x.x
```

#### Troubleshooting Package Issues

**Problem**: "Package resolution failed"

**Solution**:
```bash
# Reset package caches
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData

# In Xcode:
# File > Packages > Reset Package Caches
# File > Packages > Resolve Package Versions
```

---

## Info.plist Configuration

### Important Note About Info.plist

**Modern Xcode projects often don't have a separate Info.plist file**. Instead, they use build settings in the target configuration.

To check your configuration:
1. Select a target (e.g., StickyToDo-SwiftUI)
2. Go to the **Info** tab
3. Add keys directly in this interface

### Required Info.plist Keys for Both App Targets

#### Privacy Descriptions (REQUIRED)

These strings explain to users why the app needs certain permissions:

| Key | Value | Purpose |
|-----|-------|---------|
| `NSSiriUsageDescription` | "StickyToDo uses Siri to help you manage tasks with your voice. You can add tasks, check your inbox, and start timers using Siri shortcuts." | Required for Siri integration |
| `NSUserNotificationsUsageDescription` | "StickyToDo sends notifications for task reminders, due dates, and timer alerts to help you stay on track." | Required for notifications (future feature) |
| `NSCalendarsUsageDescription` | "StickyToDo can sync with your calendar to show tasks with due dates alongside your events." | Required for Calendar integration |
| `NSRemindersUsageDescription` | "StickyToDo can import tasks from Reminders to help you consolidate your task lists." | Required for Reminders access (import feature) |

#### User Activity Types (REQUIRED for App Intents)

Add these activity types to enable Siri shortcuts:

```xml
<key>NSUserActivityTypes</key>
<array>
    <string>AddTaskIntent</string>
    <string>CompleteTaskIntent</string>
    <string>ShowInboxIntent</string>
    <string>ShowNextActionsIntent</string>
    <string>ShowTodayTasksIntent</string>
    <string>StartTimerIntent</string>
    <string>StopTimerIntent</string>
    <string>FlagTaskIntent</string>
    <string>ShowFlaggedTasksIntent</string>
    <string>ShowWeeklyReviewIntent</string>
    <string>AddTaskToProjectIntent</string>
</array>
```

#### Bundle Identifier (REQUIRED)

Each target needs a unique bundle identifier:

- **StickyToDo-SwiftUI**: `com.yourcompany.StickyToDo`
- **StickyToDo-AppKit**: `com.yourcompany.StickyToDo-AppKit`
- **StickyToDoCore**: `com.yourcompany.StickyToDoCore`

To configure:
1. Select target
2. Go to **Signing & Capabilities**
3. Set **Bundle Identifier** (or set in **Build Settings** > **Product Bundle Identifier**)

#### App Category (RECOMMENDED)

```xml
<key>LSApplicationCategoryType</key>
<string>public.app-category.productivity</string>
```

#### Document Types (OPTIONAL - for opening .md files)

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeExtensions</key>
        <array>
            <string>md</string>
            <string>markdown</string>
        </array>
        <key>CFBundleTypeName</key>
        <string>Markdown Document</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSHandlerRank</key>
        <string>Alternate</string>
    </dict>
</array>
```

### Adding Info.plist Keys via Xcode UI

#### Method 1: Info Tab (Recommended)

1. Select target (e.g., **StickyToDo-SwiftUI**)
2. Click **Info** tab
3. Hover over any row and click **+** to add a new key
4. Start typing the key name (Xcode will autocomplete)
5. Select the key from the dropdown
6. Enter the value string

**Example - Adding Siri Usage Description:**
1. Click **+**
2. Type "Privacy - Siri" (autocompletes to `NSSiriUsageDescription`)
3. Press Enter
4. Type the description: "StickyToDo uses Siri to help you manage tasks..."

#### Method 2: Raw Keys & Values

If autocomplete doesn't work:
1. Right-click in the Info tab
2. Select "Show Raw Keys & Values"
3. Click **+**
4. Enter the exact key (e.g., `NSSiriUsageDescription`)
5. Set Type to **String**
6. Enter the value

#### Method 3: Source Code (Advanced)

If your target has an actual `Info.plist` file:
1. Right-click `Info.plist` in Project Navigator
2. Select **Open As > Source Code**
3. Add keys directly in XML format
4. Right-click again > **Open As > Property List** to return

### Repeat for All App Targets

You must configure Info.plist keys for:
- ✅ **StickyToDo-SwiftUI**
- ✅ **StickyToDo-AppKit**

The StickyToDoCore framework does NOT need these privacy keys (frameworks don't show UI).

---

## Capabilities and Entitlements

### Understanding Capabilities

Capabilities enable specific iOS/macOS features. They modify:
1. **Entitlements file** (.entitlements)
2. **Provisioning profile** (for code signing)
3. **App capabilities** on your developer account

### Current Entitlements

#### StickyToDo-SwiftUI.entitlements

Located at: `/StickyToDo-SwiftUI/StickyToDo.entitlements`

Current contents:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <false/>
</dict>
</plist>
```

#### StickyToDo-AppKit.entitlements

Located at: `/StickyToDo-AppKit/StickyToDo-AppKit.entitlements`

Current contents:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

### Required Capabilities to Enable

#### 1. App Intents (for Siri Shortcuts)

App Intents is a **code-based capability** (no UI toggle needed in Xcode).

Requirements:
- ✅ Import `AppIntents` framework
- ✅ Implement `AppIntent` protocols (already done in `/StickyToDoCore/AppIntents/`)
- ✅ Add `NSUserActivityTypes` to Info.plist (see above)
- ✅ Implement `AppShortcutsProvider` (already done in `StickyToDoAppShortcuts.swift`)

**No additional entitlement needed** - App Intents works automatically with the code implementation.

#### 2. User Notifications (Future Feature)

To enable:
1. Select target > **Signing & Capabilities**
2. Click **+ Capability**
3. Search for "User Notifications"
4. Click to add

This adds to entitlements:
```xml
<key>aps-environment</key>
<string>development</string>
```

**Note**: Not required for MVP but will be needed for task reminders.

#### 3. Calendar Access (Optional Integration)

Calendar access is **permission-based only** (no capability required).

Requirements:
- ✅ Add `NSCalendarsUsageDescription` to Info.plist (see above)
- ✅ Request permission in code:
```swift
import EventKit

let eventStore = EKEventStore()
try await eventStore.requestAccess(to: .event)
```

**No entitlement needed** - just the privacy description.

#### 4. Spotlight Integration (System-Wide Search)

Spotlight is **code-based only** (no capability required).

Requirements:
- ✅ Import `CoreSpotlight` framework
- ✅ Implement `CSSearchableIndex` (already done in `SpotlightManager.swift`)

**No entitlement needed** - Spotlight integration is automatic.

#### 5. App Sandbox (Already Configured)

App Sandbox is **already enabled** with file access:

Current entitlements provide:
- ✅ Read/write to user-selected files
- ✅ Sandboxed environment
- ❌ No network access (set to false)

**No changes needed** unless you want to add network features later.

### Signing Configuration

#### For Local Development

1. Select target > **Signing & Capabilities**
2. **Automatically manage signing**: ✅ Checked
3. **Team**: Select "Sign to Run Locally" or your developer team
4. **Signing Certificate**: Development

#### For Distribution

1. **Automatically manage signing**: ✅ Checked (recommended)
2. **Team**: Select your developer team
3. **Signing Certificate**: Developer ID Application (for outside App Store)
   - OR Apple Distribution (for App Store)

---

## Framework References

### Frameworks Required by StickyToDoCore

The core framework needs these system frameworks:

| Framework | Purpose | Status |
|-----------|---------|--------|
| `Foundation` | Core Swift/Objective-C foundation | ✅ Auto-linked |
| `AppIntents` | Siri shortcuts and app intents | ⚠️ Add if missing |
| `Intents` | Legacy Siri support | ⚠️ Add if missing |
| `CoreSpotlight` | System-wide search indexing | ⚠️ Add if missing |
| `EventKit` | Calendar integration | ⚠️ Add if needed |

### Frameworks Required by StickyToDo-SwiftUI

The SwiftUI app needs:

| Framework | Purpose | Status |
|-----------|---------|--------|
| `SwiftUI` | Modern declarative UI | ✅ Auto-linked |
| `Combine` | Reactive programming | ✅ Auto-linked |
| `AppKit` | macOS UI integration | ✅ Auto-linked |
| `UserNotifications` | Local notifications | ⚠️ Add if needed |
| `StickyToDoCore` | Shared core framework | ✅ Linked |

### Frameworks Required by StickyToDo-AppKit

The AppKit app needs:

| Framework | Purpose | Status |
|-----------|---------|--------|
| `AppKit` | Traditional macOS UI | ✅ Auto-linked |
| `Combine` | Reactive programming | ✅ Auto-linked |
| `CoreGraphics` | 2D rendering | ✅ Auto-linked |
| `StickyToDoCore` | Shared core framework | ✅ Linked |

### How to Add Frameworks

Most frameworks are auto-linked when you import them. To manually add:

1. Select target
2. **Build Phases** > **Link Binary With Libraries**
3. Click **+**
4. Search for framework (e.g., "AppIntents")
5. Click **Add**
6. Status should show "Required" or "Optional"

### Framework Import Statements

In your Swift files, import frameworks as needed:

```swift
// Core functionality
import Foundation
import Combine

// UI frameworks
import SwiftUI  // For SwiftUI target
import AppKit   // For AppKit target

// App Intents (Siri)
import AppIntents
import Intents
import IntentsUI  // iOS only

// Calendar integration
import EventKit

// Notifications
import UserNotifications

// Spotlight
import CoreSpotlight

// Local framework
import StickyToDoCore
```

---

## Build Settings

### Recommended Build Settings

Most build settings are already configured, but verify these:

#### Deployment Target

- **macOS Deployment Target**: 13.0

  To check/set:
  1. Select target
  2. **Build Settings** tab
  3. Search "deployment target"
  4. Set **macOS Deployment Target** to **13.0**

#### Swift Language Version

- **Swift Language Version**: Swift 5

  To check:
  1. **Build Settings** > Search "swift language"
  2. Verify **Swift Language Version** = **Swift 5**

#### Code Signing

For development:
1. **Build Settings** > Search "code signing"
2. **Code Signing Identity**: Sign to Run Locally
3. **Development Team**: None (or your team)

#### Other OS Frameworks and Libraries (Deprecated)

If you see this setting:
1. **Build Settings** > **Linking** > **Other Linker Flags**
2. Should be empty or contain: `-ObjC`

### Build Configuration

Two build configurations exist:
- **Debug**: For development (includes debug symbols)
- **Release**: For distribution (optimized)

To switch:
1. **Product** > **Scheme** > **Edit Scheme**
2. Select **Run** on left
3. **Info** tab > **Build Configuration**
4. Choose **Debug** (for development)

---

## Troubleshooting

### Common Build Issues

#### 1. "Cannot find 'Yams' in scope"

**Problem**: Yams package not added or not linked

**Solution**:
```bash
# Reset packages
File > Packages > Reset Package Caches
File > Packages > Resolve Package Versions

# Clean build
Product > Clean Build Folder (⇧⌘K)

# Rebuild
Product > Build (⌘B)
```

If still failing:
1. Remove Yams from Package Dependencies
2. Re-add it following steps in "Swift Package Dependencies" section
3. Ensure it's added to all three targets

#### 2. "No such module 'AppIntents'"

**Problem**: AppIntents framework not linked

**Solution**:
1. Select **StickyToDoCore** target
2. **Build Phases** > **Link Binary With Libraries**
3. Click **+**
4. Search for "AppIntents"
5. Add it
6. Clean and rebuild

**Also check**: Deployment target must be macOS 13.0+ for AppIntents

#### 3. "Missing required module 'StickyToDoCore'"

**Problem**: App targets can't find the core framework

**Solution**:
1. Select **StickyToDo-SwiftUI** target
2. **Build Phases** > **Dependencies**
3. Click **+**
4. Add **StickyToDoCore**
5. Also check **Link Binary With Libraries** includes `StickyToDoCore.framework`
6. Repeat for **StickyToDo-AppKit**

#### 4. Code Signing Failures

**Problem**: "Signing for 'StickyToDo-SwiftUI' requires a development team"

**Solution**:
1. Select target > **Signing & Capabilities**
2. Check **Automatically manage signing**
3. Select **Team**: "Sign to Run Locally"
4. Or sign in to Xcode with your Apple ID:
   - Xcode > Settings > Accounts
   - Click **+** > Add Apple ID
   - Select your team in target settings

#### 5. "No NSUserActivityTypes found"

**Problem**: Siri shortcuts not appearing in Settings

**Solution**:
1. Verify Info.plist includes `NSUserActivityTypes` array
2. Verify all intent names match exactly (case-sensitive)
3. Clean build folder
4. Rebuild
5. Uninstall app from Mac
6. Reinstall (shortcuts register on first launch)

#### 6. Entitlements File Not Found

**Problem**: "Code signing entitlements file not found"

**Solution**:
1. Select target > **Build Settings**
2. Search for "entitlements"
3. **Code Signing Entitlements** should point to:
   - SwiftUI: `StickyToDo-SwiftUI/StickyToDo.entitlements`
   - AppKit: `StickyToDo-AppKit/StickyToDo-AppKit.entitlements`
4. If missing, create new entitlements file:
   - File > New > File
   - Resource > Property List
   - Save as `StickyToDo.entitlements`
   - Set path in build settings

### Build Performance Issues

If builds are slow:

```bash
# Enable parallel builds
defaults write com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks 8

# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/StickyToDo-*

# Clean build folder in Xcode
Product > Clean Build Folder (⇧⌘K)
```

### Debugging Build Errors

Enable verbose build output:

```bash
xcodebuild -scheme StickyToDo-SwiftUI -configuration Debug -verbose | tee build.log
```

Check logs in Xcode:
1. Show **Report Navigator** (⌘9)
2. Click latest build
3. Expand sections to see detailed errors
4. Click error to jump to source location

---

## Verification Checklist

Use this checklist to verify your Xcode configuration is complete:

### Package Dependencies
- [ ] Yams package added (version 5.0.0+)
- [ ] Yams linked to StickyToDoCore
- [ ] Yams linked to StickyToDo-SwiftUI
- [ ] Yams linked to StickyToDo-AppKit
- [ ] Package resolution successful (no errors)

### Info.plist Configuration (StickyToDo-SwiftUI)
- [ ] `NSSiriUsageDescription` added with description
- [ ] `NSUserActivityTypes` array added with all intents
- [ ] Bundle Identifier set (e.g., `com.yourcompany.StickyToDo`)
- [ ] Optional: Calendar, Reminders descriptions if using those features

### Info.plist Configuration (StickyToDo-AppKit)
- [ ] `NSSiriUsageDescription` added with description
- [ ] `NSUserActivityTypes` array added with all intents
- [ ] Bundle Identifier set (e.g., `com.yourcompany.StickyToDo-AppKit`)
- [ ] Optional: Calendar, Reminders descriptions if using those features

### Entitlements
- [ ] App Sandbox enabled (both targets)
- [ ] File access enabled for user-selected files (both targets)
- [ ] Entitlements file paths correct in Build Settings

### Frameworks (StickyToDoCore)
- [ ] AppIntents framework available
- [ ] Intents framework available
- [ ] CoreSpotlight framework available
- [ ] Foundation auto-linked

### Frameworks (SwiftUI Target)
- [ ] StickyToDoCore linked
- [ ] SwiftUI available
- [ ] AppKit available
- [ ] Combine available

### Frameworks (AppKit Target)
- [ ] StickyToDoCore linked
- [ ] AppKit available
- [ ] Combine available

### Build Settings
- [ ] Deployment target = macOS 13.0
- [ ] Swift Language Version = Swift 5
- [ ] Code signing configured
- [ ] All targets build successfully

### Build Dependencies
- [ ] StickyToDo-SwiftUI depends on StickyToDoCore
- [ ] StickyToDo-AppKit depends on StickyToDoCore
- [ ] StickyToDoTests depends on StickyToDoCore

### Test Build
- [ ] Clean build folder (⇧⌘K)
- [ ] Build StickyToDoCore scheme (⌘B)
- [ ] Build StickyToDo-SwiftUI scheme (⌘B)
- [ ] Build StickyToDo-AppKit scheme (⌘B)
- [ ] Run tests (⌘U)
- [ ] All builds succeed without errors

### Runtime Verification
- [ ] Run StickyToDo-SwiftUI (⌘R)
- [ ] App launches without crashes
- [ ] No missing framework errors in console
- [ ] Open System Settings > Siri & Search
- [ ] Search for "StickyToDo"
- [ ] Verify shortcuts appear

---

## Next Steps

After completing this setup:

1. **Test the build**: Run `xcodebuild -scheme StickyToDo-SwiftUI build`
2. **Verify Siri integration**: Check System Settings > Siri & Search for shortcuts
3. **Review BUILD_SETUP.md**: See [BUILD_SETUP.md](BUILD_SETUP.md) for build commands
4. **Start development**: Refer to [NEXT_STEPS.md](NEXT_STEPS.md) for development roadmap

---

## Additional Resources

- [Apple's App Intents Documentation](https://developer.apple.com/documentation/appintents)
- [Swift Package Manager Guide](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)

---

**Configuration Complete**: If all checklist items are checked, your Xcode project is properly configured and ready to build!

**Questions?** Refer to the [Troubleshooting](#troubleshooting) section or check build logs for specific errors.

---

**Last Updated**: 2025-11-18
**Maintained By**: StickyToDo Development Team
