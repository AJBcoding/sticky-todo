# StickyToDo Asset Guidelines

Complete guide for creating and managing app icons and visual assets for both StickyToDo applications.

## Table of Contents

- [App Icon Requirements](#app-icon-requirements)
- [Design Guidelines](#design-guidelines)
- [Creating the Icon](#creating-the-icon)
- [Export Settings](#export-settings)
- [Asset Catalog Structure](#asset-catalog-structure)
- [Adding Icons to Both Apps](#adding-icons-to-both-apps)
- [Icon Concept](#icon-concept)
- [Additional Assets](#additional-assets)
- [Tools and Resources](#tools-and-resources)

## App Icon Requirements

### macOS Icon Sizes

macOS app icons require multiple sizes for different contexts:

| Size (pixels) | Usage | Required |
|--------------|-------|----------|
| 16x16 | Finder, Dock (small) | Yes |
| 32x32 | Finder, Dock (small @2x) | Yes |
| 64x64 | Finder (medium) | Yes |
| 128x128 | Finder (medium @2x) | Yes |
| 256x256 | Finder (large) | Yes |
| 512x512 | Finder (large @2x), Retina | Yes |
| 1024x1024 | App Store, Retina displays | Yes |

### File Format

- **Format**: PNG (24-bit RGB + 8-bit alpha channel)
- **Color Profile**: sRGB IEC61966-2.1
- **Transparency**: Supported but optional
- **Background**: Can be transparent or opaque

### Shape

- **Rounded Corners**: macOS automatically applies rounded corners
- **Design Area**: Use full 1024x1024 canvas
- **Safe Area**: Keep important elements 64px from edges
- **No Pre-masking**: Don't pre-round the corners yourself

## Design Guidelines

### Visual Style

#### Recommended Approach
- **Simple & Clear**: Icon should be recognizable at 16x16
- **Flat or Dimensional**: Both work well on macOS
- **Vibrant Colors**: Stand out in Dock and Finder
- **Unique Silhouette**: Distinctive shape for quick recognition

#### Things to Avoid
- Overly complex details (won't scale well)
- Text (except when core to the concept)
- Photos or realistic imagery (unless intentional)
- Platform UI elements (don't mimic macOS controls)

### Color Palette

#### Suggested Colors for StickyToDo

**Primary Colors**:
- Yellow: `#FFD60A` (sticky note color)
- Orange: `#FF9500` (warm accent)
- Blue: `#007AFF` (productivity/trust)

**Secondary Colors**:
- Gray: `#8E8E93` (neutral elements)
- Green: `#34C759` (completion/checkmark)
- White: `#FFFFFF` (highlights)

**Gradients** (Optional):
- Yellow to Orange: Warm, energetic
- Blue to Purple: Modern, professional

### Icon Personality

StickyToDo should convey:
- **Productivity**: Efficient task management
- **Simplicity**: Easy to use, uncluttered
- **Reliability**: Trustworthy, stable
- **Friendly**: Approachable, not intimidating

## Creating the Icon

### Method 1: Vector Graphics (Recommended)

#### Using Sketch
1. Create 1024x1024 artboard
2. Design with vectors for perfect scaling
3. Export all required sizes
4. Use File > Export > Multiple sizes

#### Using Figma
1. Create 1024x1024 frame
2. Design with vector shapes
3. Use export settings for multiple sizes
4. File > Export > PNG @ 1x, 2x, etc.

#### Using Adobe Illustrator
1. Create 1024x1024 artboard
2. Design with vector shapes
3. Export as PNG:
   - File > Export > Export for Screens
   - Select all required sizes
   - Format: PNG, sRGB

### Method 2: Raster Graphics

#### Using Photoshop
1. Create 1024x1024 canvas at 72 DPI
2. Design on separate layers
3. Use smart objects for scalability
4. Export each size:
   - File > Export > Export As
   - Format: PNG-24
   - Resize for each required dimension

### Method 3: Icon Generator Tools

#### Online Tools
- [Icon Slate](http://www.kodlian.com/apps/icon-slate) (macOS)
- [Image2Icon](http://www.img2icnsapp.com/) (macOS)
- [MakeAppIcon](https://makeappicon.com/) (Web)

#### Command Line (ImageMagick)
```bash
# Install ImageMagick
brew install imagemagick

# Generate all sizes from 1024x1024 source
convert icon-1024.png -resize 16x16 icon-16.png
convert icon-1024.png -resize 32x32 icon-32.png
convert icon-1024.png -resize 64x64 icon-64.png
convert icon-1024.png -resize 128x128 icon-128.png
convert icon-1024.png -resize 256x256 icon-256.png
convert icon-1024.png -resize 512x512 icon-512.png
```

## Export Settings

### Recommended Export Settings

#### Photoshop/Illustrator
- **Format**: PNG-24
- **Transparency**: Checked (if needed)
- **Interlaced**: Unchecked
- **Color Profile**: sRGB IEC61966-2.1
- **Compression**: Maximum quality

#### Sketch/Figma
- **Format**: PNG
- **Scale**: 1x (for base size)
- **Color Profile**: sRGB
- **Optimize**: Yes
- **Progressive**: No

### Quality Checklist

Before exporting, verify:
- [ ] Icon is centered in artboard
- [ ] No stray pixels outside bounds
- [ ] Colors are vibrant and correct
- [ ] Alpha channel is clean
- [ ] Icon looks good on both light and dark backgrounds

## Asset Catalog Structure

### Location

Assets are stored in Xcode Asset Catalogs:

```
StickyToDo-SwiftUI/Assets.xcassets/
└── AppIcon.appiconset/
    ├── Contents.json
    ├── icon-16.png
    ├── icon-32.png
    ├── icon-64.png
    ├── icon-128.png
    ├── icon-256.png
    ├── icon-512.png
    └── icon-1024.png

StickyToDo-AppKit/Assets.xcassets/
└── AppIcon.appiconset/
    ├── Contents.json
    └── [same icons as above]
```

### Contents.json Format

```json
{
  "images": [
    {
      "size": "16x16",
      "idiom": "mac",
      "filename": "icon-16.png",
      "scale": "1x"
    },
    {
      "size": "16x16",
      "idiom": "mac",
      "filename": "icon-32.png",
      "scale": "2x"
    },
    {
      "size": "32x32",
      "idiom": "mac",
      "filename": "icon-32.png",
      "scale": "1x"
    },
    {
      "size": "32x32",
      "idiom": "mac",
      "filename": "icon-64.png",
      "scale": "2x"
    },
    {
      "size": "128x128",
      "idiom": "mac",
      "filename": "icon-128.png",
      "scale": "1x"
    },
    {
      "size": "128x128",
      "idiom": "mac",
      "filename": "icon-256.png",
      "scale": "2x"
    },
    {
      "size": "256x256",
      "idiom": "mac",
      "filename": "icon-256.png",
      "scale": "1x"
    },
    {
      "size": "256x256",
      "idiom": "mac",
      "filename": "icon-512.png",
      "scale": "2x"
    },
    {
      "size": "512x512",
      "idiom": "mac",
      "filename": "icon-512.png",
      "scale": "1x"
    },
    {
      "size": "512x512",
      "idiom": "mac",
      "filename": "icon-1024.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
```

## Adding Icons to Both Apps

### Method 1: Xcode UI (Recommended)

#### For StickyToDo-SwiftUI:

1. Open `StickyToDo.xcodeproj` in Xcode
2. In the Project Navigator, select `StickyToDo-SwiftUI`
3. Navigate to `Assets.xcassets`
4. Click on `AppIcon`
5. Drag and drop each icon size into the appropriate slot
6. Xcode will automatically create the Contents.json

#### For StickyToDo-AppKit:

Repeat the same process for `StickyToDo-AppKit/Assets.xcassets`

### Method 2: Manual File Copy

```bash
# Navigate to project directory
cd /path/to/sticky-todo

# Copy icons to SwiftUI app
cp icon-*.png StickyToDo-SwiftUI/Assets.xcassets/AppIcon.appiconset/

# Copy icons to AppKit app
cp icon-*.png StickyToDo-AppKit/Assets.xcassets/AppIcon.appiconset/
```

### Method 3: Script Automation

Create a script to copy icons to both apps:

```bash
#!/bin/bash
# copy-icons.sh

ICONS_DIR="./icons"
SWIFTUI_DIR="./StickyToDo-SwiftUI/Assets.xcassets/AppIcon.appiconset"
APPKIT_DIR="./StickyToDo-AppKit/Assets.xcassets/AppIcon.appiconset"

# Copy to SwiftUI app
cp "$ICONS_DIR"/icon-*.png "$SWIFTUI_DIR/"
echo "Icons copied to SwiftUI app"

# Copy to AppKit app
cp "$ICONS_DIR"/icon-*.png "$APPKIT_DIR/"
echo "Icons copied to AppKit app"

echo "Done! Icons updated in both apps."
```

### Verification

After adding icons:

1. Clean build folder (Product > Clean Build Folder)
2. Build the app (⌘B)
3. Run the app (⌘R)
4. Check Dock icon while app is running
5. Check Finder icon in Applications folder

## Icon Concept

### Placeholder SVG Icon Concept

A simple, recognizable icon combining a sticky note with a checkmark:

```svg
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <!-- Background gradient (sticky note yellow) -->
  <defs>
    <linearGradient id="stickyGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#FFD60A;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#FF9500;stop-opacity:1" />
    </linearGradient>
    <filter id="shadow">
      <feDropShadow dx="0" dy="20" stdDeviation="40" flood-opacity="0.3"/>
    </filter>
  </defs>

  <!-- Main sticky note shape -->
  <rect x="128" y="128" width="768" height="768" rx="120"
        fill="url(#stickyGradient)" filter="url(#shadow)"/>

  <!-- Folded corner (top right) -->
  <path d="M 768 128 L 896 128 L 896 256 Z"
        fill="#E88800" opacity="0.7"/>

  <!-- Horizontal lines (ruled paper effect) -->
  <line x1="200" y1="350" x2="824" y2="350" stroke="#FFE44D"
        stroke-width="4" opacity="0.5"/>
  <line x1="200" y1="450" x2="824" y2="450" stroke="#FFE44D"
        stroke-width="4" opacity="0.5"/>
  <line x1="200" y1="550" x2="824" y2="550" stroke="#FFE44D"
        stroke-width="4" opacity="0.5"/>

  <!-- Checkmark -->
  <path d="M 320 512 L 440 640 L 704 320"
        stroke="#34C759" stroke-width="80"
        stroke-linecap="round" stroke-linejoin="round"
        fill="none" opacity="0.9"/>
</svg>
```

### Alternative Concepts

#### Concept 2: List with Checkboxes
- Simplified list view with 3 checkbox items
- First item checked, others unchecked
- Clean, minimal design

#### Concept 3: Board View
- Kanban board representation
- 3 columns with cards
- Sticky note aesthetic

#### Concept 4: Abstract "T" Logo
- Stylized "T" for "ToDo"
- Integrated checkbox or checkmark
- Modern, geometric design

## Additional Assets

### Other Icon Needs

Beyond the app icon, you may want:

1. **Document Icons** (for .stickytodo files)
   - Sizes: 16, 32, 128, 256, 512 px
   - Should relate to app icon but be distinct

2. **Toolbar Icons** (for in-app use)
   - SF Symbols (preferred for macOS)
   - Custom icons: 18x18, 36x36 (1x, 2x)

3. **Status Bar Icons** (if using menu bar)
   - Template images: 18x18, 36x36
   - Black with alpha channel

4. **Quick Capture Icon** (for overlay window)
   - 32x32, 64x64
   - Should be recognizable even when small

### Using SF Symbols

For most in-app icons, use Apple's SF Symbols:

```swift
// SwiftUI
Image(systemName: "checkmark.circle")
Image(systemName: "square.and.pencil")
Image(systemName: "list.bullet")

// AppKit
NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: nil)
```

## Tools and Resources

### Design Tools

**Vector Graphics**:
- [Sketch](https://www.sketch.com/) - macOS design tool ($99/year)
- [Figma](https://www.figma.com/) - Free for individuals
- [Adobe Illustrator](https://www.adobe.com/products/illustrator.html) - Industry standard
- [Affinity Designer](https://affinity.serif.com/designer/) - One-time purchase

**Raster Graphics**:
- [Photoshop](https://www.adobe.com/products/photoshop.html) - Industry standard
- [Pixelmator Pro](https://www.pixelmator.com/pro/) - Mac-native ($39.99)
- [GIMP](https://www.gimp.org/) - Free and open source

**Icon-Specific**:
- [Icon Slate](http://www.kodlian.com/apps/icon-slate) - Mac icon creation
- [Image2Icon](http://www.img2icnsapp.com/) - Convert images to icons

### Icon Inspiration

- [macOS App Icon Gallery](https://www.macosicongallery.com/)
- [Dribbble - App Icons](https://dribbble.com/tags/app-icon)
- [Behance - Icon Design](https://www.behance.net/search/projects?search=app+icon)

### Apple Resources

- [macOS Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/macos/icons-and-images/app-icon/)
- [SF Symbols App](https://developer.apple.com/sf-symbols/)
- [Apple Design Resources](https://developer.apple.com/design/resources/)

## Quick Reference

### Minimal Setup Checklist

- [ ] Create 1024x1024 icon design
- [ ] Export all required sizes (16-1024)
- [ ] Add to SwiftUI Assets.xcassets
- [ ] Add to AppKit Assets.xcassets
- [ ] Verify in Xcode asset catalog
- [ ] Build and test both apps
- [ ] Check icon in Dock and Finder

### File Naming Convention

```
icon-16.png    (16x16)
icon-32.png    (32x32, also used for 16@2x)
icon-64.png    (64x64, also used for 32@2x)
icon-128.png   (128x128)
icon-256.png   (256x256, also used for 128@2x)
icon-512.png   (512x512, also used for 256@2x)
icon-1024.png  (1024x1024, also used for 512@2x)
```

---

**Last Updated**: 2025-11-18
**macOS Version**: 13.0+
**Xcode Version**: 15.0+

For questions about asset creation, consult the [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos).
