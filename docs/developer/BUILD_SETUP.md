# StickyToDo Build Setup Guide

Complete guide for building and running both StickyToDo applications.

## Table of Contents

- [Requirements](#requirements)
- [First-Time Xcode Configuration](#first-time-xcode-configuration)
- [Initial Setup](#initial-setup)
- [Swift Package Manager Dependencies](#swift-package-manager-dependencies)
- [Xcode Project Configuration](#xcode-project-configuration)
- [Build Schemes](#build-schemes)
- [Running the Applications](#running-the-applications)
- [Troubleshooting](#troubleshooting)
- [Development Workflow](#development-workflow)

## Requirements

### System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

### Verification

Check your system meets the requirements:

```bash
# Check macOS version
sw_vers

# Check Xcode version
xcodebuild -version

# Check Swift version
swift --version
```

## First-Time Xcode Configuration

### ⚠️ Important: Complete Xcode Setup First

**If this is your first time setting up the project**, you MUST complete the Xcode configuration before building:

1. **Read the comprehensive setup guide**: [XCODE_SETUP.md](XCODE_SETUP.md)
2. **Add required package dependencies** (especially Yams - CRITICAL!)
3. **Configure Info.plist keys** for Siri, Calendar, and Notifications
4. **Verify frameworks and capabilities** are properly configured

### Quick Configuration Check

Run the verification script to check your setup:

```bash
./scripts/configure-xcode.sh
```

This script will verify:
- ✓ Swift package dependencies (Yams)
- ✓ Framework references
- ✓ Entitlements configuration
- ✓ Build settings
- ✓ Test build of StickyToDoCore

**If any checks fail**, refer to [XCODE_SETUP.md](XCODE_SETUP.md) for detailed resolution steps.

### Critical Dependencies

The project **will not compile** without:
- **Yams package** (YAML parsing) - See [Adding Yams](#adding-yams) below
- **AppIntents framework** (Siri shortcuts) - Requires macOS 13.0+ deployment target
- **Proper Info.plist configuration** - See [XCODE_SETUP.md](XCODE_SETUP.md)

### Adding Yams

**Yams is REQUIRED** - add it via Xcode:

1. Open `StickyToDo.xcodeproj`
2. Select the project > **Package Dependencies** tab
3. Click **+** > Enter URL: `https://github.com/jpsim/Yams.git`
4. Select version **5.0.0** or later
5. Add to targets: **StickyToDoCore**, **StickyToDo-SwiftUI**, **StickyToDo-AppKit**

See [XCODE_SETUP.md](XCODE_SETUP.md) for detailed instructions with screenshots guidance.

## Initial Setup

### 1. Clone or Open the Project

If you haven't already, navigate to the project directory:

```bash
cd /path/to/sticky-todo
```

### 2. Open in Xcode

Open the Xcode project:

```bash
open StickyToDo.xcodeproj
```

Or use Xcode's File > Open menu to navigate to `StickyToDo.xcodeproj`.

## Swift Package Manager Dependencies

The project uses Swift Package Manager for dependency management.

### Required Packages

1. **Yams** - YAML parsing for data import/export
   - Repository: https://github.com/jpsim/Yams.git
   - Version: 5.0.0 or later

2. **ZipFoundation** (Optional) - For compressed archive support
   - Repository: https://github.com/weichsel/ZIPFoundation.git
   - Version: 0.9.0 or later

### Adding Dependencies

#### Method 1: Xcode UI

1. In Xcode, select the project in the navigator
2. Select the **StickyToDo** project (not a target)
3. Click the **Package Dependencies** tab
4. Click the **+** button to add a package
5. Enter the package URL and select the version

**For Yams:**
- URL: `https://github.com/jpsim/Yams.git`
- Dependency Rule: Up to Next Major Version
- Version: 5.0.0

**For ZipFoundation (Optional):**
- URL: `https://github.com/weichsel/ZIPFoundation.git`
- Dependency Rule: Up to Next Major Version
- Version: 0.9.0

#### Method 2: Package.swift (Alternative)

If using Swift Package Manager directly:

```swift
dependencies: [
    .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0")
]
```

### Linking Dependencies to Targets

After adding the packages:

1. Select the **StickyToDoCore** target
2. Go to **Build Phases** > **Link Binary With Libraries**
3. Click **+** and add:
   - Yams (from Swift Package Manager)
   - ZipFoundation (if added)

## Xcode Project Configuration

### Project Structure

```
StickyToDo/
├── StickyToDo.xcodeproj/        # Xcode project file
├── StickyToDoCore/              # Shared framework
│   ├── Models/                  # Data models
│   ├── Data/                    # Data layer
│   └── Utilities/               # Shared utilities
├── StickyToDo-SwiftUI/          # SwiftUI application
│   ├── Views/                   # SwiftUI views
│   └── Utilities/               # SwiftUI-specific utilities
├── StickyToDo-AppKit/           # AppKit application
│   ├── Views/                   # AppKit views
│   └── Utilities/               # AppKit-specific utilities
└── StickyToDoTests/             # Unit tests
```

### Targets

The project contains four targets:

1. **StickyToDoCore** (Framework)
   - Shared code between both apps
   - Models, data layer, business logic

2. **StickyToDo-SwiftUI** (Application)
   - Modern SwiftUI-based application
   - Requires StickyToDoCore framework

3. **StickyToDo-AppKit** (Application)
   - Traditional AppKit-based application
   - Requires StickyToDoCore framework

4. **StickyToDoTests** (Test Bundle)
   - Unit tests for the applications

### Adding Files to Targets

When adding new files:

1. Right-click the appropriate folder in Xcode
2. Select **New File...**
3. Choose the template (Swift File, etc.)
4. In the save dialog, ensure the correct target(s) are checked:
   - Core functionality: Check **StickyToDoCore**
   - SwiftUI views: Check **StickyToDo-SwiftUI**
   - AppKit views: Check **StickyToDo-AppKit**

### Build Settings

Key build settings are already configured:

- **Deployment Target**: macOS 13.0
- **Swift Language Version**: Swift 5
- **Code Signing**: Automatic (can be changed as needed)
- **Build Options**: Parallel builds enabled

## Build Schemes

The project includes three schemes:

### 1. StickyToDo-SwiftUI

Builds and runs the SwiftUI version:

```bash
# Command line build
xcodebuild -scheme StickyToDo-SwiftUI -configuration Debug build
```

### 2. StickyToDo-AppKit

Builds and runs the AppKit version:

```bash
# Command line build
xcodebuild -scheme StickyToDo-AppKit -configuration Debug build
```

### 3. StickyToDoCore

Builds only the shared framework:

```bash
# Command line build
xcodebuild -scheme StickyToDoCore -configuration Debug build
```

### Selecting a Scheme in Xcode

1. Click the scheme selector in the toolbar (next to the Run/Stop buttons)
2. Choose the desired scheme:
   - **StickyToDo-SwiftUI** for the SwiftUI app
   - **StickyToDo-AppKit** for the AppKit app
3. Click **Run** (⌘R) to build and launch

## Running the Applications

### Running from Xcode

1. Select the desired scheme (SwiftUI or AppKit)
2. Press **⌘R** or click the **Run** button
3. The app will build and launch

### Running Both Apps Side-by-Side

To run both applications simultaneously:

1. Build the SwiftUI app: Select **StickyToDo-SwiftUI** scheme and press **⌘R**
2. Stop the app (⌘.)
3. Navigate to the built product:
   ```bash
   open ~/Library/Developer/Xcode/DerivedData/StickyToDo-*/Build/Products/Debug/StickyToDo-SwiftUI.app
   ```
4. Switch to the AppKit scheme and press **⌘R**
5. Both apps are now running

### Running from Command Line

Build and run without Xcode:

```bash
# Build SwiftUI app
xcodebuild -scheme StickyToDo-SwiftUI -configuration Debug

# Run SwiftUI app
open ~/Library/Developer/Xcode/DerivedData/StickyToDo-*/Build/Products/Debug/StickyToDo-SwiftUI.app

# Build AppKit app
xcodebuild -scheme StickyToDo-AppKit -configuration Debug

# Run AppKit app
open ~/Library/Developer/Xcode/DerivedData/StickyToDo-*/Build/Products/Debug/StickyToDo-AppKit.app
```

## Troubleshooting

### Common Issues

#### 1. Package Resolution Failed

**Problem**: Xcode can't resolve Swift package dependencies

**Solution**:
```bash
# Reset package caches
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData

# In Xcode: File > Packages > Reset Package Caches
# Then: File > Packages > Resolve Package Versions
```

#### 2. Framework Not Found

**Problem**: `StickyToDoCore.framework` not found during build

**Solution**:
1. Ensure StickyToDoCore builds before the apps
2. Check Build Phases > Dependencies includes StickyToDoCore
3. Clean build folder: Product > Clean Build Folder (⇧⌘K)
4. Rebuild: Product > Build (⌘B)

#### 3. Code Signing Issues

**Problem**: Code signing fails or requires credentials

**Solution**:
1. Open project settings
2. Select each target
3. Go to **Signing & Capabilities**
4. Set **Signing** to "Sign to Run Locally"
5. Or select your development team if available

#### 4. Missing Asset Catalogs

**Problem**: App icon or assets not found

**Solution**:
1. Verify `Assets.xcassets` exists in both app targets
2. Check it's included in **Build Phases > Copy Bundle Resources**
3. See [ASSETS.md](ASSETS.md) for asset creation instructions

#### 5. Build Errors in Swift Files

**Problem**: Compiler errors in newly added files

**Solution**:
1. Verify file is added to correct target
2. Check import statements are correct
3. Ensure framework dependencies are linked
4. Clean and rebuild (⇧⌘K, then ⌘B)

#### 6. Simulator/Device Not Available

**Problem**: "My Mac" destination not available

**Solution**:
1. Go to Xcode > Settings > Platforms
2. Ensure macOS platform is installed
3. Restart Xcode if needed

### Debugging Build Issues

Enable verbose build output:

```bash
xcodebuild -scheme StickyToDo-SwiftUI -configuration Debug -verbose
```

Check build logs:
1. Open the Report Navigator (⌘9)
2. Select the latest build
3. Review errors and warnings

### Performance Issues

If builds are slow:

1. Enable parallel builds:
   - Xcode > Settings > Behaviors > Use > All processes
2. Increase build threads:
   ```bash
   defaults write com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks 8
   ```
3. Clean derived data periodically

## Development Workflow

### Recommended Workflow

1. **Start with StickyToDoCore**
   - Add new models and core logic here
   - Build and test in isolation

2. **Update SwiftUI App**
   - Add SwiftUI-specific views and features
   - Test with SwiftUI previews

3. **Update AppKit App**
   - Add corresponding AppKit views
   - Ensure feature parity

4. **Run Tests**
   - Press ⌘U to run all tests
   - Or use: `xcodebuild test -scheme StickyToDo-SwiftUI`

### Hot Reload and Previews

#### SwiftUI Previews

SwiftUI views support live previews:

1. Open a SwiftUI view file
2. Press ⌥⌘↩ to show Canvas
3. Click Resume to enable live preview
4. Edit code and see changes instantly

#### AppKit Hot Reload

AppKit doesn't support live previews, but you can:

1. Enable "Debug > Debug Workflow > Always Show Disassembly"
2. Use Instruments for UI debugging
3. Build and run frequently for testing

### Version Control

Recommended files to commit:

```
✓ All .swift source files
✓ .xcodeproj/project.pbxproj
✓ Assets.xcassets
✓ Entitlements files
✗ Build artifacts (DerivedData)
✗ User-specific settings (.xcuserdata)
```

The `.gitignore` is already configured appropriately.

### Building for Release

When ready to build for distribution:

1. Select **Product > Archive**
2. Choose **Generic Mac** as destination
3. Wait for archiving to complete
4. Organizer opens with the archive
5. Click **Distribute App**
6. Choose distribution method:
   - **Copy App**: For direct distribution
   - **Developer ID**: For outside App Store
   - **Mac App Store**: For App Store submission

### Performance Profiling

Profile your builds:

```bash
# Time the build
time xcodebuild -scheme StickyToDo-SwiftUI clean build

# Use Instruments for runtime profiling
# Product > Profile (⌘I)
```

### App Intents and Siri Shortcuts Issues

#### Problem: "No such module 'AppIntents'"

**Cause**: AppIntents framework requires macOS 13.0+

**Solution**:
1. Select target > **Build Settings**
2. Search for "deployment target"
3. Set **macOS Deployment Target** to **13.0** or later
4. Clean and rebuild

#### Problem: Siri shortcuts not appearing in System Settings

**Cause**: Info.plist not configured or app not launched

**Solution**:
1. Verify `NSUserActivityTypes` in Info.plist (see [XCODE_SETUP.md](XCODE_SETUP.md))
2. Verify `NSSiriUsageDescription` is set
3. Build and run the app at least once
4. Shortcuts register on first launch
5. Check: System Settings > Siri & Search > Search for "StickyToDo"

#### Problem: "Cannot find type 'TaskEntity' in scope"

**Cause**: AppIntents files not added to correct target

**Solution**:
1. Select `TaskEntity.swift` in Project Navigator
2. File Inspector (⌥⌘1)
3. **Target Membership** section
4. Ensure **StickyToDoCore** is checked
5. Repeat for all AppIntents files

## Next Steps

- Review [XCODE_SETUP.md](XCODE_SETUP.md) for comprehensive Xcode configuration
- Review [DEVELOPMENT.md](DEVELOPMENT.md) for coding guidelines
- Check [ASSETS.md](ASSETS.md) for creating app icons (if file exists)
- Run `scripts/configure-xcode.sh` to verify configuration
- See [NEXT_STEPS.md](../status/NEXT_STEPS.md) for development roadmap

## Support

For issues or questions:

1. Check this documentation
2. Review [HANDOFF.md](../handoff/HANDOFF.md) for project context
3. Check Xcode build logs for specific errors
4. Review Apple's Xcode documentation

---

**Build System**: Xcode Build System (Default)
**Package Manager**: Swift Package Manager
**Minimum Xcode Version**: 15.0
**Last Updated**: 2025-11-18
