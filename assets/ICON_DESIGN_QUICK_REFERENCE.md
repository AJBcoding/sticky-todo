# Icon Design Quick Reference
**Print-Friendly One-Page Guide for Designers**

---

## Quick Start (60 Seconds)

1. **Read:** `/home/user/sticky-todo/assets/ICON_DESIGN_CONCEPTS.md`
2. **Choose:** One of 5 design concepts (Concept 1 recommended)
3. **Create:** 1024×1024 master artwork in Figma/Sketch/Illustrator
4. **Export:** SVG + high-res PNG to `/home/user/sticky-todo/assets/`
5. **Generate:** Run `./scripts/generate-icons.sh assets/icon-source.png`
6. **Deliver:** Icons automatically created in both app directories

---

## 5 Design Concepts (Choose One)

### 1. Classic Sticky Note ⭐ RECOMMENDED
- Yellow sticky note (#FFD54F) + dark gray checkmark (#424242)
- Subtle page curl, soft shadow
- Most recognizable, universal appeal
- WCAG AAA accessibility (7.28:1 contrast)

### 2. Gradient Modern
- Yellow-to-amber gradient + green checkmark (#2E7D32)
- Glossy highlights, premium feel
- Modern, polished aesthetic
- WCAG AA+ accessibility

### 3. Minimal Line Art
- White fill + yellow border (#FFD54F) + blue checkmark (#1976D2)
- Clean, outline-based design
- Professional, minimal aesthetic
- Best for corporate environments

### 4. Bold & Vibrant
- Bright orange-yellow (#FFAB00) + black checkmark (#000000)
- Strong shadow, high energy
- Maximum visibility in dock
- WCAG AAA accessibility (9.52:1 contrast)

### 5. Professional Monochrome
- Light gray (#EEEEEE) + yellow accent + gray checkmark
- Timeless, corporate aesthetic
- Sophisticated, distraction-free
- Best for professional users

**Full Specifications:** See `ICON_DESIGN_CONCEPTS.md`

---

## Master Canvas Setup

```
Size:              1024×1024 pixels (or 2048×2048 for @2x)
Color Mode:        RGB
Color Space:       sRGB
Background:        Transparent
Safe Area:         922×922 pixels (90% of canvas)
Note Size:         870×870 pixels (centered at 77, 77)
Corner Radius:     104 pixels (12% of note width)
```

---

## Concept 1 Specifications (Most Popular)

**Sticky Note:**
- Position: (77, 77) to (947, 947)
- Size: 870×870 px
- Color: `#FFD54F`
- Corner radius: 104px
- Shadow: 12px blur, 6px down, 20% black

**Page Curl (Top-Right):**
- Triangle: (817, 77), (947, 77), (947, 207)
- Color: `#FFE082`

**Checkmark:**
- Path: (420, 520) → (520, 620) → (740, 380)
- Stroke: 96px, rounded caps/joins
- Color: `#424242`

---

## Required Color Codes (Copy-Paste)

### Concept 1: Classic
```css
#FFD54F   /* Sticky note yellow */
#FFE082   /* Page curl light yellow */
#424242   /* Checkmark dark gray */
rgba(0, 0, 0, 0.20)   /* Shadow */
```

### Concept 2: Gradient
```css
#FFD54F   /* Gradient start */
#FFC107   /* Gradient end */
#2E7D32   /* Checkmark green */
rgba(255, 255, 255, 0.15)   /* Highlight */
```

### Concept 3: Minimal
```css
#FFFFFF   /* Note fill white */
#FFD54F   /* Border yellow */
#1976D2   /* Checkmark blue */
```

### Concept 4: Bold
```css
#FFAB00   /* Note amber */
#000000   /* Checkmark black */
```

### Concept 5: Monochrome
```css
#EEEEEE   /* Note gray */
#FFD54F   /* Accent yellow */
#424242   /* Checkmark gray */
```

---

## Required Export Sizes (10 Files)

| Filename | Pixels | Usage |
|----------|--------|-------|
| `icon_16x16@1x.png` | 16×16 | List view, menu bar |
| `icon_16x16@2x.png` | 32×32 | Retina |
| `icon_32x32@1x.png` | 32×32 | Icon view small |
| `icon_32x32@2x.png` | 64×64 | Retina |
| `icon_128x128@1x.png` | 128×128 | Sidebar, large list |
| `icon_128x128@2x.png` | 256×256 | Retina |
| `icon_256x256@1x.png` | 256×256 | Large icon view |
| `icon_256x256@2x.png` | 512×512 | Retina |
| `icon_512x512@1x.png` | 512×512 | Cover flow |
| `icon_512x512@2x.png` | 1024×1024 | Retina, App Store |

---

## File Naming (Case-Sensitive!)

**✓ CORRECT:**
```
icon_16x16@1x.png      ← Lowercase, underscore, @, lowercase x
icon_source.svg        ← Hyphen for source files
icon_source.png
```

**❌ WRONG:**
```
Icon_16x16@1x.png      ← Capital I
icon-16x16@1x.png      ← Dash instead of underscore
icon_16x16_1x.png      ← Underscore instead of @
icon_16x16@1X.png      ← Capital X
```

---

## Export Settings

### SVG Export
- Filename: `icon-source.svg`
- Location: `/home/user/sticky-todo/assets/`
- Presentation attributes (not CSS)
- 2 decimal places
- Optimized

### PNG Export (Master)
- Filename: `icon-source.png` (1024×1024) or `icon-source@2x.png` (2048×2048)
- Location: `/home/user/sticky-todo/assets/`
- Format: PNG-24 with alpha
- Color space: sRGB
- DPI: 72
- Transparent background

### PNG Export (All Sizes)
- Format: PNG-24 with alpha channel
- Color space: sRGB
- Background: Transparent
- DPI: 72 ppi
- Compression: Medium

---

## Size-Specific Optimizations

### Large (1024×1024 to 512×512)
- ✓ Full detail with all elements
- ✓ Page curl visible
- ✓ Subtle shadow (12px blur)
- ✓ Smooth curves

### Medium (256×256 to 128×128)
- ✓ Page curl slightly simplified
- ✓ Shadow more prominent (20-25%)
- ✓ All elements clear

### Small (64×64 to 32×32)
- ✓ Reduce or remove page curl
- ✓ Pixel-align edges
- ✓ Strong shadow for depth
- ✓ Bold checkmark

### Tiny (16×16) **⚠ Hand-tune!**
- ✓ Remove page curl entirely
- ✓ Simple square + checkmark
- ✓ Increase checkmark weight 10-15%
- ✓ Maximum simplicity
- ✓ Align to pixel grid

---

## Automated Generation (Recommended)

**Step 1:** Create master artwork and export to assets folder
```bash
# Your high-res master goes here:
/home/user/sticky-todo/assets/icon-source.png
```

**Step 2:** Run generation script
```bash
cd /home/user/sticky-todo
./scripts/generate-icons.sh assets/icon-source.png
```

**Step 3:** Done!
- Automatically creates all 10 sizes
- Automatically places in both app directories
- Automatically updates Contents.json

**Optional Step 4:** Hand-tune 16×16 and 32×32 for best quality

---

## Manual Export (Alternative)

If not using script, export each size individually to:

**SwiftUI:**
`/home/user/sticky-todo/StickyToDo-SwiftUI/Assets.xcassets/AppIcon.appiconset/`

**AppKit:**
`/home/user/sticky-todo/StickyToDo-AppKit/Assets.xcassets/AppIcon.appiconset/`

Both directories need identical files.

---

## Layer Structure (Recommended)

From bottom to top:
1. **Background** (transparent)
2. **Shadow** (blur effect, 20% opacity)
3. **Sticky Note Base** (yellow fill, rounded rect)
4. **Page Curl** (triangle, lighter yellow)
5. **Checkmark** (vector path, dark gray)
6. **Optional Effects** (texture, highlights)

Name layers clearly for easy editing.

---

## Quality Checklist (Before Delivery)

**Visual:**
- [ ] Recognizable at 16×16 pixels
- [ ] Checkmark clearly visible at all sizes
- [ ] Colors match spec exactly
- [ ] No artifacts or pixelation
- [ ] Shadow is subtle
- [ ] Works on light AND dark backgrounds

**Technical:**
- [ ] All 10 PNG files exported
- [ ] Filenames match exactly (case-sensitive!)
- [ ] All PNGs have transparent backgrounds
- [ ] SVG source is clean
- [ ] sRGB color space
- [ ] Files in correct directories

**Accessibility:**
- [ ] Contrast ratio ≥ 7:1 (or ≥ 4.5:1 for AA)
- [ ] Works in grayscale
- [ ] Clear on white background
- [ ] Clear on black background

**Testing:**
- [ ] 16×16 checkmark visible
- [ ] 1024×1024 smooth and professional
- [ ] Built app without warnings
- [ ] Viewed in Finder and Dock

---

## Tool-Specific Tips

### Figma
- Create 1024×1024 frame
- Use vector networks for checkmark
- Export: Right panel → Export → SVG/PNG
- Enable "Include 'id' attribute" for SVG

### Sketch
- Create 1024×1024 artboard
- Use vector tool for checkmark
- Make Exportable → Add sizes
- Use built-in export presets

### Illustrator
- New document: 1024×1024, RGB, sRGB
- Use Pen tool for checkmark
- File → Export → Export As → SVG/PNG
- Settings: Presentation attributes, 2 decimals

### Affinity Designer
- New document: 1024×1024, RGB
- Export Persona for exports
- Export as PNG/SVG with transparency

---

## Common Issues & Fixes

### Checkmark not visible at 16×16
- **Fix:** Increase stroke weight by 10-15% for small sizes
- **Fix:** Remove page curl to reduce clutter
- **Fix:** Increase shadow opacity

### Page curl looks messy at small sizes
- **Fix:** Simplify or remove for sizes ≤64px
- **Fix:** Use simpler triangle instead of gradient

### Colors don't match
- **Fix:** Verify RGB color mode (not CMYK)
- **Fix:** Check sRGB color profile
- **Fix:** Copy-paste exact hex codes

### White background instead of transparency
- **Fix:** Remove canvas background fill
- **Fix:** Export as PNG-24 (not PNG-8)
- **Fix:** Enable transparency in export settings

### Icon looks blurry
- **Fix:** Align to pixel grid before exporting
- **Fix:** Hand-tune small sizes pixel-by-pixel
- **Fix:** Export at exact dimensions (no scaling)

---

## Resources

### Official Apple Guidelines
- [App Icons - Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [SF Symbols](https://developer.apple.com/sf-symbols/) (checkmark reference)

### Templates
- [Figma macOS Icon Template](https://www.figma.com/community)
- [Sketch App Icon Templates](https://applypixels.com/template/macos-big-sur)

### Tools
- ImageMagick: `brew install imagemagick` (for scripts)
- SVGO: `npm install -g svgo` (SVG optimization)
- Color Contrast Checker: https://webaim.org/resources/contrastchecker/

---

## File Locations Summary

**Source Files (Your Deliverables):**
```
/home/user/sticky-todo/assets/
  icon-source.svg              ← Master vector (required)
  icon-source.png              ← Master PNG 1024×1024 (required)
  [your-design-file]           ← Figma/Sketch/AI (optional)
```

**Generated Icons (Automated):**
```
/home/user/sticky-todo/StickyToDo-SwiftUI/Assets.xcassets/AppIcon.appiconset/
  icon_16x16@1x.png ... icon_512x512@2x.png (10 files)

/home/user/sticky-todo/StickyToDo-AppKit/Assets.xcassets/AppIcon.appiconset/
  icon_16x16@1x.png ... icon_512x512@2x.png (10 files)
```

---

## Estimated Time

**Full Process:**
- Hour 1: Choose concept, set up canvas, create base elements
- Hour 2: Refine details, adjust proportions, add effects
- Hour 3: Export master files, generate all sizes
- Hour 4: Hand-tune small sizes, test, finalize

**Total:** 3-4 hours for complete implementation

---

## Need More Detail?

**Full Design Concepts:**
`/home/user/sticky-todo/assets/ICON_DESIGN_CONCEPTS.md`

**Step-by-Step Implementation:**
`/home/user/sticky-todo/assets/DESIGNER_INSTRUCTIONS.md`

**Technical Specifications:**
`/home/user/sticky-todo/assets/ICON_SPECIFICATION.md`

**SVG Code Structure:**
`/home/user/sticky-todo/assets/icon-template.svg.md`

---

## Support

**Questions?** Review the full documentation or contact the development team.

**Stuck?** All design specifications are in the related documents.

**Ready?** Start with Concept 1 (Classic Sticky Note) for best results!

---

**Version:** 1.0
**Last Updated:** 2025-11-18
**Status:** Ready for Use

**Print this page and keep it handy while designing!**
