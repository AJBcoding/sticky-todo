# App Icon Assets - AppKit

This directory contains the app icon assets for the **Sticky ToDo AppKit** application.

---

## Status

**Current State:** ⏳ Awaiting icon files from designer

**Contents.json:** ✓ Configured and ready

**Required Files:** 10 PNG files (currently missing)

---

## Required Icon Files

The following PNG files must be placed in this directory:

```
icon_16x16@1x.png      (16×16 pixels)
icon_16x16@2x.png      (32×32 pixels)
icon_32x32@1x.png      (32×32 pixels)
icon_32x32@2x.png      (64×64 pixels)
icon_128x128@1x.png    (128×128 pixels)
icon_128x128@2x.png    (256×256 pixels)
icon_256x256@1x.png    (256×256 pixels)
icon_256x256@2x.png    (512×512 pixels)
icon_512x512@1x.png    (512×512 pixels)
icon_512x512@2x.png    (1024×1024 pixels)
```

---

## File Specifications

**Format:** PNG-24 with alpha channel
**Color Space:** sRGB
**Background:** Transparent
**DPI:** 72 (screen resolution)
**Naming:** Exact case-sensitive match required

---

## How to Generate Icons

### Option 1: Automated (Recommended)

If you have a master icon file:

```bash
# From project root
./scripts/generate-icons.sh assets/icon-source.png
```

This will automatically create all 10 PNG files in both SwiftUI and AppKit directories.

### Option 2: Manual Export

Export each size from your design tool (Figma/Sketch/Illustrator):

1. Set canvas to exact pixel dimensions
2. Export as PNG-24 with transparency
3. Use exact filename (case-sensitive)
4. Save to this directory

---

## Design Specifications

**Full specifications:** See `/home/user/sticky-todo/assets/ICON_SPECIFICATION.md`

**Quick reference:**
- Yellow sticky note: `#FFD54F`
- Checkmark: `#424242` (dark gray)
- Page curl: `#FFE082` (light yellow)
- Shadow: `rgba(0, 0, 0, 0.20)`

**Design files:**
- `/home/user/sticky-todo/assets/ICON_DESIGN.md` - Overview
- `/home/user/sticky-todo/assets/DESIGNER_INSTRUCTIONS.md` - Step-by-step guide
- `/home/user/sticky-todo/assets/icon-template.svg.md` - SVG template

---

## Contents.json

The `Contents.json` file is already configured to reference all required icon files:

```json
{
  "images": [
    { "filename": "icon_16x16@1x.png", "size": "16x16", "scale": "1x" },
    { "filename": "icon_16x16@2x.png", "size": "16x16", "scale": "2x" },
    // ... (all 10 sizes)
  ]
}
```

**Status:** ✓ Ready - no changes needed

---

## Testing

After adding icon files:

1. **Build the AppKit app:**
   ```bash
   cd /home/user/sticky-todo
   xcodebuild -project StickyToDo-AppKit.xcodeproj -scheme StickyToDo-AppKit
   ```

2. **Check build output:**
   - No warnings about missing assets
   - No errors about icon catalog

3. **Visual verification:**
   - Run the app
   - Check icon in Finder
   - Check icon in Dock
   - Check icon in App Switcher (Cmd+Tab)
   - Verify on light and dark menu bars

---

## Troubleshooting

### Build Warning: "AppIcon: The app icon set is missing required sizes"

**Solution:** All 10 PNG files must be present with exact filenames.

### Icon Appears with White Background

**Solution:** Export PNG-24 with transparency enabled (alpha channel).

### Icon Looks Blurry or Pixelated

**Solution:** Ensure each PNG is exported at exact pixel dimensions (no scaling).

### Icon Not Updating After File Change

**Solution:**
1. Clean build folder (Product → Clean Build Folder in Xcode)
2. Quit and restart Xcode
3. Rebuild project

---

## File Checklist

Before building:

- [ ] icon_16x16@1x.png (16×16 pixels)
- [ ] icon_16x16@2x.png (32×32 pixels)
- [ ] icon_32x32@1x.png (32×32 pixels)
- [ ] icon_32x32@2x.png (64×64 pixels)
- [ ] icon_128x128@1x.png (128×128 pixels)
- [ ] icon_128x128@2x.png (256×256 pixels)
- [ ] icon_256x256@1x.png (256×256 pixels)
- [ ] icon_256x256@2x.png (512×512 pixels)
- [ ] icon_512x512@1x.png (512×512 pixels)
- [ ] icon_512x512@2x.png (1024×1024 pixels)
- [x] Contents.json (already present and configured)

---

## Related Directories

**SwiftUI icons:** `/home/user/sticky-todo/StickyToDo-SwiftUI/Assets.xcassets/AppIcon.appiconset/`

**Design assets:** `/home/user/sticky-todo/assets/`

**Scripts:** `/home/user/sticky-todo/scripts/`

---

**Last Updated:** 2025-11-18
**Status:** Configured - Awaiting icon files
