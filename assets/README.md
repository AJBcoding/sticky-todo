# Sticky ToDo App Assets

This directory contains design assets, specifications, and guidelines for the Sticky ToDo application icons and branding.

---

## Directory Contents

### Design Documentation

**ICON_DESIGN.md**
- Original design guide with concept and quick start instructions
- Overview of the sticky note + checkmark icon concept
- Color palette options and basic specifications
- Quick start guide for creating icons

**ICON_SPECIFICATION.md** ⭐ **Primary Reference**
- Complete, detailed icon specification
- Comprehensive design guidelines
- Dimensional specifications for all sizes
- Color specifications with accessibility considerations
- Design rationale and best practices
- Quality assurance checklist

**DESIGNER_INSTRUCTIONS.md** 📋 **For Designers**
- Step-by-step guide for implementing the icon
- Tool recommendations (Figma, Sketch, Illustrator)
- Detailed construction instructions
- Export settings and file organization
- Common issues and solutions
- Quick reference card

**icon-template.svg.md** 💻 **Technical Reference**
- SVG code structure and specifications
- Path coordinates and mathematical definitions
- Optimization tips and conversion guides
- Tool-specific export settings

### Icon Source Files

**To be created by designer:**

```
icon-source.svg              Master vector source (SVG format)
icon-source.png              Master raster (1024×1024 or 2048×2048)
icon-source@2x.png          High-resolution master (2048×2048)
icon-preview.png            Preview image (512×512)
```

**Delivery checklist:**
- [ ] icon-source.svg (scalable vector)
- [ ] icon-source.png or icon-source@2x.png (high-res raster)
- [ ] Original design file (Figma/Sketch/Illustrator)
- [ ] All 10 PNG sizes (see below)

---

## Icon Specifications Summary

### Design Concept

**Visual Elements:**
- Yellow sticky note with rounded corners
- Subtle page curl in top-right corner
- Bold checkmark symbol
- Drop shadow for depth

**Color Palette:**
- Note: `#FFD54F` (Material Yellow 300)
- Checkmark: `#424242` (Gray 800) or `#2E7D32` (Green 800)
- Page curl: `#FFE082` (lighter yellow)
- Shadow: `rgba(0, 0, 0, 0.20)`

### Required Sizes (macOS)

All icons exported as PNG-24 with transparency:

| Size | Scale | Pixels | Filename |
|------|-------|--------|----------|
| 16×16 | 1x | 16×16 | `icon_16x16@1x.png` |
| 16×16 | 2x | 32×32 | `icon_16x16@2x.png` |
| 32×32 | 1x | 32×32 | `icon_32x32@1x.png` |
| 32×32 | 2x | 64×64 | `icon_32x32@2x.png` |
| 128×128 | 1x | 128×128 | `icon_128x128@1x.png` |
| 128×128 | 2x | 256×256 | `icon_128x128@2x.png` |
| 256×256 | 1x | 256×256 | `icon_256x256@1x.png` |
| 256×256 | 2x | 512×512 | `icon_256x256@2x.png` |
| 512×512 | 1x | 512×512 | `icon_512x512@1x.png` |
| 512×512 | 2x | 1024×1024 | `icon_512x512@2x.png` |

---

## Quick Start for Designers

### Step 1: Read the Specifications

1. Start with **DESIGNER_INSTRUCTIONS.md** for practical guidance
2. Reference **ICON_SPECIFICATION.md** for detailed requirements
3. Use **icon-template.svg.md** for technical SVG details

### Step 2: Create the Icon

**Option A: Design from Scratch**
1. Choose your tool (Figma, Sketch, Illustrator)
2. Follow the step-by-step instructions in DESIGNER_INSTRUCTIONS.md
3. Create 1024×1024 master artwork
4. Export as SVG and PNG

**Option B: Use the Script to Generate Placeholder**
1. Run `./scripts/create-placeholder-icon.sh` to generate a basic version
2. Refine the design in your preferred tool
3. Export final version

### Step 3: Export All Sizes

**Manual Export:**
- Export each size individually from your design tool
- Follow naming convention exactly
- Save to AppIcon.appiconset directories

**Automated Export:**
1. Export high-quality master: `assets/icon-source.png` (1024×1024 or larger)
2. Run: `./scripts/generate-icons.sh assets/icon-source.png`
3. Script automatically creates all 10 required sizes

### Step 4: Verify Quality

Run through the quality checklist:
- [ ] All 10 PNG files generated
- [ ] Files named correctly (case-sensitive)
- [ ] Transparent backgrounds (no white)
- [ ] Checkmark visible at 16×16
- [ ] Colors match specification
- [ ] SVG source is clean and optimized

---

## Scripts

### generate-icons.sh

**Purpose:** Automatically generates all required macOS icon sizes from a source image

**Usage:**
```bash
./scripts/generate-icons.sh [source-file]
./scripts/generate-icons.sh assets/icon-source.png
```

**Requirements:**
- ImageMagick (`brew install imagemagick`)
- Source PNG or SVG file (1024×1024 minimum)

**Output:**
- Creates 10 PNG files in both AppIcon.appiconset directories
- Updates Contents.json files
- Maintains transparency

### create-placeholder-icon.sh

**Purpose:** Creates a simple placeholder icon for development

**Usage:**
```bash
./scripts/create-placeholder-icon.sh
```

**Requirements:**
- ImageMagick (`brew install imagemagick`)

**Output:**
- Creates `assets/icon-source.png` with basic sticky note design
- Simple yellow square with checkmark
- Can be refined by a designer

---

## File Locations

### Source Files (This Directory)

```
/home/user/sticky-todo/assets/
├── ICON_DESIGN.md                    Design guide (original)
├── ICON_SPECIFICATION.md             Complete specification ⭐
├── DESIGNER_INSTRUCTIONS.md          Step-by-step guide 📋
├── icon-template.svg.md              SVG technical spec 💻
├── README.md                         This file
├── icon-source.svg                   Master vector (to be created)
├── icon-source.png                   Master raster (to be created)
└── [designer-source-file]            Original Figma/Sketch/AI file
```

### Generated Icons (Xcode Projects)

**SwiftUI App:**
```
/home/user/sticky-todo/StickyToDo-SwiftUI/Assets.xcassets/AppIcon.appiconset/
├── Contents.json                     Asset catalog configuration ✓
├── icon_16x16@1x.png                To be created
├── icon_16x16@2x.png                To be created
├── icon_32x32@1x.png                To be created
├── icon_32x32@2x.png                To be created
├── icon_128x128@1x.png              To be created
├── icon_128x128@2x.png              To be created
├── icon_256x256@1x.png              To be created
├── icon_256x256@2x.png              To be created
├── icon_512x512@1x.png              To be created
└── icon_512x512@2x.png              To be created
```

**AppKit App:**
```
/home/user/sticky-todo/StickyToDo-AppKit/Assets.xcassets/AppIcon.appiconset/
├── Contents.json                     Asset catalog configuration ✓
└── [same 10 PNG files as above]     To be created
```

---

## Design Principles

### 1. Simplicity
- Icon must be recognizable at 16×16 pixels
- No fine details that disappear at small sizes
- Clean, bold shapes

### 2. Recognizability
- Sticky note metaphor is universally understood
- Checkmark clearly indicates task completion
- Distinct from other productivity apps

### 3. Scalability
- Vector source (SVG) scales infinitely
- Size-specific optimizations for 16×16 and 32×32
- Consistent appearance across all sizes

### 4. Accessibility
- High contrast (7.28:1 ratio)
- Works in grayscale
- Clear for colorblind users
- Visible on light and dark backgrounds

### 5. Brand Consistency
- Yellow (#FFD54F) as primary brand color
- Rounded, friendly aesthetic
- Professional but approachable
- Aligns with app's GTD methodology + visual organization

---

## Color Specifications

### Primary Color Scheme

```css
/* Sticky Note */
#FFD54F   /* Material Yellow 300 */
rgb(255, 213, 79)
hsl(48, 69%, 100%)

/* Page Curl Highlight */
#FFE082   /* Lighter yellow */
rgb(255, 224, 130)

/* Checkmark */
#424242   /* Material Gray 800 */
rgb(66, 66, 66)

/* Shadow */
rgba(0, 0, 0, 0.20)
```

### Alternative Schemes

See **ICON_SPECIFICATION.md** Section 3 for:
- Modern gradient option
- Minimal light option
- Green checkmark variation

---

## Quality Standards

### Visual Quality
- No compression artifacts
- Clean alpha channel (no white fringe)
- Smooth curves at large sizes
- Crisp edges at small sizes
- Hand-tuned 16×16 and 32×32 for clarity

### Technical Quality
- PNG-24 format with alpha
- sRGB color space
- 72 DPI (screen resolution)
- Exact dimensions (no scaling needed)
- Proper file naming (case-sensitive)

### Accessibility
- Contrast ratio ≥ 7:1 (WCAG AAA)
- Recognizable in grayscale
- Clear on light and dark backgrounds
- Visible at minimum size (16×16)

---

## Testing Checklist

Before finalizing:

### Size Testing
- [ ] 16×16: Checkmark clearly visible
- [ ] 32×32: All elements distinguishable
- [ ] 128×128: Professional appearance
- [ ] 512×512: Smooth curves, no pixelation
- [ ] 1024×1024: App Store quality

### Background Testing
- [ ] White background
- [ ] Light gray background (#F5F5F5)
- [ ] Dark background (#1E1E1E)
- [ ] Black background
- [ ] macOS menu bar (light and dark)

### Context Testing
- [ ] Finder icon view
- [ ] Finder list view (small)
- [ ] Dock (normal size)
- [ ] Dock (small magnification)
- [ ] App Switcher (Cmd+Tab)
- [ ] About panel

### Accessibility Testing
- [ ] Grayscale mode
- [ ] Deuteranopia (red-green colorblind)
- [ ] Protanopia (red-blind)
- [ ] High contrast mode

---

## Resources

### Apple Guidelines
- [Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [SF Symbols](https://developer.apple.com/sf-symbols/) - For checkmark reference
- [macOS Icon Templates](https://applypixels.com/template/macos-big-sur)

### Design Tools
- **Figma:** https://figma.com (free, collaborative)
- **Sketch:** https://sketch.com (macOS, paid)
- **Adobe Illustrator:** Industry standard (paid)
- **Affinity Designer:** One-time purchase alternative

### Icon Utilities
- **Icon Slate:** http://www.kodlian.com/apps/icon-slate (macOS icon generator)
- **Image2Icon:** https://img2icnsapp.com/ (PNG to ICNS converter)

### Development Tools
- **ImageMagick:** `brew install imagemagick` (batch conversion)
- **Inkscape:** Free vector editor with CLI export
- **SVGO:** SVG optimizer (`npm install -g svgo`)

---

## FAQ

### Q: What's the difference between 1x and 2x?

**A:** 1x is for standard resolution displays, 2x is for Retina displays (double pixel density). The 2x version has twice the dimensions (e.g., 16×16@2x = 32×32 pixels).

### Q: Why are there two AppIcon.appiconset directories?

**A:** The project has both SwiftUI and AppKit implementations. Each needs its own copy of the icon assets.

### Q: Can I use a different color scheme?

**A:** Yes, but get approval first. Alternative schemes are documented in ICON_SPECIFICATION.md. The yellow scheme is recommended for brand recognition.

### Q: Do I need to create the icons manually for each size?

**A:** No! Create one high-quality master (1024×1024 or larger), then use `./scripts/generate-icons.sh` to automatically create all sizes. You may want to hand-tune 16×16 and 32×32 afterward.

### Q: What if I don't have ImageMagick?

**A:** Install it with `brew install imagemagick` on macOS, or export all sizes manually from your design tool.

### Q: Should the page curl be visible at 16×16?

**A:** No. At very small sizes (16×16, 32×32), simplify or remove the page curl. The checkmark and basic note shape are most important.

### Q: What color space should I use?

**A:** sRGB for all exports. This is standard for screen display and ensures consistent colors across devices.

### Q: Can I test the icons before delivering?

**A:** Yes! Copy them to the AppIcon.appiconset directories and build the Xcode project. Check the icon in Finder, Dock, and App Switcher.

---

## Next Steps

### For Designers

1. **Read documentation:** DESIGNER_INSTRUCTIONS.md
2. **Create master artwork:** 1024×1024 or 2048×2048
3. **Export SVG source:** icon-source.svg
4. **Generate all sizes:** Use script or manual export
5. **Test quality:** Run through checklist
6. **Deliver files:** Place in correct directories

### For Developers

Once icons are received:

1. Verify all 10 PNG files exist in both AppIcon.appiconset directories
2. Verify Contents.json references correct filenames (already configured ✓)
3. Build both SwiftUI and AppKit projects
4. Test icon appearance in Finder, Dock, App Switcher
5. Check on both light and dark menu bars
6. Verify no build warnings about missing assets

---

## Status

**Current State:**
- ✓ Design specifications complete
- ✓ Designer instructions complete
- ✓ SVG template specification complete
- ✓ Contents.json files configured
- ✓ Icon generation scripts ready
- ⏳ Icon artwork pending (to be created by designer)
- ⏳ SVG source pending
- ⏳ PNG files pending (10 files × 2 locations)

**Ready for designer implementation!**

---

## Contact

For questions or clarifications:
- Review this README
- Check DESIGNER_INSTRUCTIONS.md for practical guidance
- Reference ICON_SPECIFICATION.md for technical details
- Consult icon-template.svg.md for SVG code structure

---

**Last Updated:** 2025-11-18
**Version:** 1.0
**Status:** Ready for Implementation
