# Build Configuration Guide

## Version Information

**Current Version:** 1.0.0 (Build 1)

**Version Numbering:**
- Marketing Version: 1.0.0 (MARKETING_VERSION)
- Build Number: 1 (CURRENT_PROJECT_VERSION)

## Bundle Identifiers

**StickyToDo-SwiftUI:**
- Bundle ID: `com.stickytodo.app.swiftui`
- Product Name: Sticky ToDo
- Display Name: Sticky ToDo

**StickyToDo-AppKit:**
- Bundle ID: `com.stickytodo.app.appkit`
- Product Name: Sticky ToDo AppKit
- Display Name: Sticky ToDo (AppKit)

**StickyToDoCore:**
- Bundle ID: `com.stickytodo.core`
- Product Name: StickyToDoCore
- Type: Framework

## Build Configurations

### Debug Configuration

**Compiler Settings:**
- Optimization Level: None [-O0]
- Swift Optimization: -Onone
- Debug Information Format: DWARF with dSYM
- Enable Testability: YES
- Assertions: Enabled

**Preprocessor Macros:**
- DEBUG=1
- ENABLE_PERFORMANCE_MONITORING=1
- VERBOSE_LOGGING=1

**Code Signing:**
- Code Signing Identity: Development
- Provisioning Profile: Automatic
- Entitlements: Debug.entitlements

### Release Configuration

**Compiler Settings:**
- Optimization Level: Fastest, Smallest [-Os]
- Swift Optimization: -O
- Debug Information Format: DWARF with dSYM
- Enable Testability: NO
- Assertions: Disabled

**Preprocessor Macros:**
- NDEBUG=1

**Code Signing:**
- Code Signing Identity: Developer ID Application
- Provisioning Profile: Production
- Entitlements: Release.entitlements
- Enable Hardened Runtime: YES

**Stripping:**
- Strip Debug Symbols: YES
- Strip Swift Symbols: YES
- Dead Code Stripping: YES

## Deployment Settings

**Minimum macOS Version:** 12.0 (Monterey)
**Target macOS Version:** 14.0 (Sonoma)

**Supported Architectures:**
- Apple Silicon (arm64)
- Intel (x86_64)

**Universal Binary:** YES

## App Sandbox

**Entitlements (both Debug and Release):**

```xml
<!-- File Access -->
<key>com.apple.security.files.user-selected.read-write</key>
<true/>

<!-- Network (for future iCloud sync) -->
<key>com.apple.security.network.client</key>
<true/>

<!-- User Data Access -->
<key>com.apple.security.files.downloads.read-write</key>
<true/>

<!-- Temporary Exception for Development -->
<key>com.apple.security.temporary-exception.files.home-relative-path.read-write</key>
<array>
    <string>Documents/StickyToDo/</string>
</array>
```

## Info.plist Configuration

### Required Keys

**Application Information:**
```xml
<key>CFBundleName</key>
<string>$(PRODUCT_NAME)</string>

<key>CFBundleDisplayName</key>
<string>Sticky ToDo</string>

<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

<key>CFBundleVersion</key>
<string>$(CURRENT_PROJECT_VERSION)</string>

<key>CFBundleShortVersionString</key>
<string>$(MARKETING_VERSION)</string>

<key>CFBundlePackageType</key>
<string>APPL</string>
```

**App Category:**
```xml
<key>LSApplicationCategoryType</key>
<string>public.app-category.productivity</string>
```

**Copyright:**
```xml
<key>NSHumanReadableCopyright</key>
<string>Copyright © 2025 Sticky ToDo. All rights reserved.</string>
```

**High Resolution Support:**
```xml
<key>NSHighResolutionCapable</key>
<true/>

<key>NSSupportsAutomaticGraphicsSwitching</key>
<true/>
```

### Document Types

**Markdown Files:**
```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Markdown Document</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>net.daringfireball.markdown</string>
        </array>
        <key>LSHandlerRank</key>
        <string>Alternate</string>
    </dict>
</array>
```

### URL Schemes

**Deep Linking:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.stickytodo.url</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>stickytodo</string>
        </array>
    </dict>
</array>
```

### Services

**Quick Capture Service:**
```xml
<key>NSServices</key>
<array>
    <dict>
        <key>NSMenuItem</key>
        <dict>
            <key>default</key>
            <string>Quick Capture in Sticky ToDo</string>
        </dict>
        <key>NSMessage</key>
        <string>quickCaptureFromService</string>
        <key>NSPortName</key>
        <string>StickyToDo</string>
        <key>NSSendTypes</key>
        <array>
            <string>NSStringPboardType</string>
        </array>
    </dict>
</array>
```

## Build Scripts

### Pre-Build Scripts

**Version Increment (Release only):**
```bash
if [ "${CONFIGURATION}" = "Release" ]; then
    buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}")
    buildNumber=$(($buildNumber + 1))
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${INFOPLIST_FILE}"
fi
```

**SwiftLint:**
```bash
if which swiftlint >/dev/null; then
    swiftlint
else
    echo "warning: SwiftLint not installed"
fi
```

### Post-Build Scripts

**Copy Resources:**
```bash
# Copy default data files
cp -R "${SRCROOT}/Resources/DefaultData" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/Resources/"
```

## Compiler Flags

### Swift Compiler Flags

**Debug:**
- `-Onone` - No optimization
- `-enable-testing` - Enable testing
- `-DDEBUG` - Debug flag

**Release:**
- `-O` - Optimize for speed
- `-whole-module-optimization` - Whole module optimization
- `-enforce-exclusivity=checked` - Memory exclusivity

### Other Swift Flags

**All Configurations:**
- `-warnings-as-errors` (Release only)
- `-enable-bare-slash-regex`
- `-strict-concurrency=complete`

## Linking

**Frameworks:**
- Foundation
- AppKit (AppKit target)
- SwiftUI (SwiftUI target)
- Combine
- UniformTypeIdentifiers

**Framework Search Paths:**
- `$(inherited)`
- `$(BUILT_PRODUCTS_DIR)`

## Code Signing

### Development Signing

**Team ID:** [YOUR_TEAM_ID]
**Signing Certificate:** Apple Development
**Provisioning Profile:** Automatic

### Distribution Signing

**Team ID:** [YOUR_TEAM_ID]
**Signing Certificate:** Developer ID Application
**Provisioning Profile:** None (Direct Distribution)

**Notarization:**
- Enable Hardened Runtime: YES
- Notarize Before Distribution: YES

### Hardened Runtime Entitlements

```xml
<key>com.apple.security.cs.allow-jit</key>
<false/>

<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<false/>

<key>com.apple.security.cs.allow-dyld-environment-variables</key>
<false/>

<key>com.apple.security.cs.disable-library-validation</key>
<false/>
```

## Testing Configuration

**Test Host:** $(BUILT_PRODUCTS_DIR)/StickyToDo.app/Contents/MacOS/StickyToDo

**Test Plans:**
- Unit Tests: Fast, isolated tests
- Integration Tests: Full system tests
- Performance Tests: Benchmarking

**Code Coverage:**
- Gather Coverage Data: YES
- Minimum Coverage: 70%

## Build Settings Checklist

### Before Release Build

- [ ] Update version number in project settings
- [ ] Update copyright year in Info.plist
- [ ] Verify bundle identifiers are correct
- [ ] Check code signing settings
- [ ] Review entitlements
- [ ] Run all tests
- [ ] Test on both Apple Silicon and Intel
- [ ] Verify app icon is included
- [ ] Check for warnings
- [ ] Run static analysis

### Distribution Checklist

- [ ] Create Release build
- [ ] Archive app
- [ ] Export for distribution
- [ ] Sign with Developer ID
- [ ] Notarize with Apple
- [ ] Staple notarization ticket
- [ ] Create DMG installer
- [ ] Test installation on clean system
- [ ] Verify all features work
- [ ] Check for any crashes or errors

## Archive Settings

**Skip Install:** NO (for app targets)
**Installation Directory:** /Applications

**Export Options:**
- Method: Developer ID
- Upload Symbols: YES
- Upload Bitcode: NO (not supported for macOS)
- Manage Version and Build Number: YES

## Performance Optimization

**Swift Compilation Mode:**
- Debug: Incremental
- Release: Whole Module

**Link-Time Optimization:**
- Release: Monolithic

**Asset Catalog Optimization:**
- Compress PNG Files: YES
- Remove Text Metadata: YES
- Optimization: Space

## Localization

**Development Language:** en
**Localized Resources Path:** $(SRCROOT)/Resources/Localizations

**Supported Languages:**
- English (en)
- [Add more as needed]

## Tips for Xcode Configuration

1. Use xcconfig files for shared settings
2. Keep sensitive info out of version control
3. Use build configurations effectively
4. Automate version bumping
5. Set up CI/CD for automated builds
6. Regular archive and notarization testing
7. Monitor build times and optimize
