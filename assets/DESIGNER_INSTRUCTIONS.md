# Designer Instructions: Sticky ToDo App Icon

**Quick Start Guide for Designers**

---

## Welcome!

Thank you for creating the Sticky ToDo app icon! This guide provides clear, step-by-step instructions for implementing the icon design.

**Estimated Time:** 2-4 hours (depending on your tool choice and experience)

---

## What You Need to Create

**Primary Deliverable:**
1. One master SVG file (scalable vector source)
2. Ten PNG files at specific sizes for macOS

**Optional but Recommended:**
- Source design file (Figma/Sketch/Illustrator with layers)
- Preview images showing the icon in context

---

## Step-by-Step Instructions

### Step 1: Choose Your Design Tool

**Recommended Options:**

**Option A: Figma** (Free, works in browser)
- Best for: Modern workflow, easy sharing
- Download: https://figma.com
- Pros: Free, collaborative, cloud-based
- Cons: Requires internet connection

**Option B: Adobe Illustrator** (Paid)
- Best for: Professional designers, vector precision
- Pros: Industry standard, powerful tools
- Cons: Paid subscription required

**Option C: Sketch** (macOS only, paid)
- Best for: macOS designers, app icon templates
- Download: https://sketch.com
- Pros: Built for macOS design, great templates
- Cons: macOS only, one-time purchase

**Option D: Affinity Designer** (Paid, one-time)
- Best for: Budget-conscious professionals
- Download: https://affinity.serif.com
- Pros: One-time purchase, professional features
- Cons: Smaller community

### Step 2: Set Up Your Canvas

1. **Create a new document:**
   - Size: 1024×1024 pixels (or 2048×2048 for best quality)
   - Color mode: RGB
   - Color profile: sRGB
   - Background: Transparent

2. **Set up guides:**
   - Center guides (horizontal and vertical)
   - Safe area: 922×922 pixels (centered)
   - Note area: 870×870 pixels (centered)

### Step 3: Draw the Sticky Note

**Base Rectangle:**
1. Draw a rounded rectangle:
   - Size: 870×870 pixels
   - Position: Centered on canvas
   - Corner radius: 104 pixels
   - Fill: `#FFD54F` (yellow)
   - No stroke

**Page Curl (Top-Right Corner):**
1. Draw a triangle using the pen tool:
   - Point 1: 130 pixels from top-right on top edge
   - Point 2: Top-right corner
   - Point 3: 130 pixels from top-right on right edge
2. Fill with lighter yellow: `#FFE082`
3. Optional: Add subtle gradient for depth

**Quick Tip:** The page curl should look like the top-right corner is folding over slightly.

### Step 4: Draw the Checkmark

**Method 1: Using Pen Tool**
1. Create a path with three points:
   - Start point: (420, 520)
   - Middle point: (520, 620)
   - End point: (740, 380)
2. Set stroke:
   - Width: 96 pixels
   - Color: `#424242` (dark gray)
   - Caps: Rounded
   - Joins: Rounded
   - No fill

**Method 2: Using SF Symbols (macOS only)**
1. Open SF Symbols app
2. Find checkmark symbol
3. Export as SVG
4. Import and scale to fit
5. Adjust stroke weight to 96px

**Quick Tip:** The checkmark should be bold and confident, clearly visible even when squinting.

### Step 5: Add Shadow

1. Select the sticky note base layer
2. Add drop shadow effect:
   - Blur: 12 pixels
   - X offset: 0 pixels
   - Y offset: 6 pixels
   - Color: Black
   - Opacity: 20%
   - Spread: 0 pixels

**Quick Tip:** The shadow should be subtle - just enough to lift the note off the background.

### Step 6: Optimize for Small Sizes

**Important:** Icons look different at small sizes!

**Create size-specific versions:**

**For 16×16 and 32×32:**
- Simplify or remove the page curl
- Increase checkmark weight slightly
- Strengthen the shadow (up to 30% opacity)
- Ensure pixel-perfect alignment

**For 128×128 to 512×512:**
- Keep all details
- Standard proportions work well

**Quick Tip:** Export at 16×16 and check if the checkmark is clearly visible. If not, adjust!

### Step 7: Export Master SVG

1. **Clean up your document:**
   - Remove unused layers
   - Merge where appropriate
   - Name layers clearly:
     - "sticky-note-base"
     - "page-curl"
     - "checkmark"
     - "shadow"

2. **Export as SVG:**
   - File name: `icon-source.svg`
   - Include: All layers
   - Optimize: Enable SVG optimization
   - Decimal places: 2
   - Settings: Presentation attributes (not internal CSS)

3. **Save to:** `/home/user/sticky-todo/assets/icon-source.svg`

### Step 8: Export PNG Files

You need to export 10 different PNG files:

**Required Sizes:**

| Filename | Dimensions | Notes |
|----------|------------|-------|
| `icon_16x16@1x.png` | 16×16 px | Hand-tune for clarity |
| `icon_16x16@2x.png` | 32×32 px | Hand-tune for clarity |
| `icon_32x32@1x.png` | 32×32 px | Standard export |
| `icon_32x32@2x.png` | 64×64 px | Standard export |
| `icon_128x128@1x.png` | 128×128 px | Standard export |
| `icon_128x128@2x.png` | 256×256 px | Standard export |
| `icon_256x256@1x.png` | 256×256 px | Standard export |
| `icon_256x256@2x.png` | 512×512 px | Standard export |
| `icon_512x512@1x.png` | 512×512 px | Standard export |
| `icon_512x512@2x.png` | 1024×1024 px | App Store icon |

**Export Settings for Each PNG:**
- Format: PNG-24
- Transparency: Yes
- Color profile: sRGB
- DPI: 72 (screen resolution)
- Compression: Medium (balance quality/file size)

**Quick Tip:** You can use the provided script to generate all sizes automatically from your master PNG! (See Step 9)

### Step 9: Use the Icon Generator Script (Optional but Recommended)

If you have ImageMagick installed, you can automate the export:

1. **Export one high-quality master PNG:**
   - Name: `icon-source.png`
   - Size: 1024×1024 or 2048×2048
   - Save to: `/home/user/sticky-todo/assets/`

2. **Run the generation script:**
   ```bash
   cd /home/user/sticky-todo
   ./scripts/generate-icons.sh assets/icon-source.png
   ```

This will automatically generate all 10 required sizes!

**Note:** You may still want to hand-tune the 16×16 and 32×32 versions for optimal clarity.

### Step 10: Organize Your Deliverables

**Final File Structure:**

```
/home/user/sticky-todo/assets/
  icon-source.svg              ← Master vector source
  icon-source.png              ← Master raster (1024×1024 or 2048×2048)
  icon-preview.png             ← Preview image (512×512)
  [your-source-file.fig/ai/sketch]  ← Original design file

/home/user/sticky-todo/StickyToDo-SwiftUI/Assets.xcassets/AppIcon.appiconset/
  icon_16x16@1x.png
  icon_16x16@2x.png
  icon_32x32@1x.png
  icon_32x32@2x.png
  icon_128x128@1x.png
  icon_128x128@2x.png
  icon_256x256@1x.png
  icon_256x256@2x.png
  icon_512x512@1x.png
  icon_512x512@2x.png
  Contents.json                ← Already exists

/home/user/sticky-todo/StickyToDo-AppKit/Assets.xcassets/AppIcon.appiconset/
  (Same files as above)
```

---

## Quality Checklist

Before submitting your work, verify:

### Visual Quality
- [ ] Icon is recognizable at 16×16 pixels
- [ ] Checkmark is clearly visible at all sizes
- [ ] Colors match specification exactly (#FFD54F for note, #424242 for checkmark)
- [ ] No compression artifacts or pixelation
- [ ] Shadow is subtle and professional
- [ ] Page curl doesn't create confusion at small sizes

### Technical Quality
- [ ] All 10 PNG files are exported
- [ ] File names match exactly (case-sensitive!)
- [ ] All PNGs have transparent backgrounds
- [ ] SVG file is clean and optimized
- [ ] Colors are in sRGB color space
- [ ] Files are saved in correct directories

### Testing
- [ ] Open each PNG file individually to verify
- [ ] Check 16×16 version - is checkmark visible?
- [ ] Check 1024×1024 version - smooth and professional?
- [ ] View icon on light background (white)
- [ ] View icon on dark background (black/dark gray)
- [ ] Icon looks good in grayscale

---

## Common Issues and Solutions

### Issue: Checkmark not visible at 16×16

**Solution:**
- Increase checkmark stroke weight by 10-15% for small sizes
- Reduce or remove page curl
- Increase shadow opacity to 25-30%
- Ensure checkmark is centered and prominent

### Issue: Page curl looks messy at small sizes

**Solution:**
- Simplify the curl for small sizes
- Remove it entirely for 16×16 and 32×32
- Use a simpler triangle shape instead of gradient

### Issue: Colors don't match specification

**Solution:**
- Verify color mode is RGB (not CMYK)
- Check color profile is sRGB
- Double-check hex values: #FFD54F and #424242
- Disable any color management in export settings

### Issue: PNG files have white background instead of transparency

**Solution:**
- Ensure artboard/canvas has no background fill
- Export as PNG-24 (not PNG-8)
- Enable transparency in export settings
- Check "Transparent Background" option

### Issue: Icon looks blurry at certain sizes

**Solution:**
- Align edges to pixel grid before exporting
- Use crisp edges rendering mode
- Hand-tune small sizes (16×16, 32×32) pixel-by-pixel
- Ensure you're exporting at exact pixel dimensions

### Issue: Shadow is too heavy or too light

**Solution:**
- Test on both light and dark backgrounds
- Adjust opacity between 15-25%
- Ensure blur radius is appropriate for size (10-12px)
- Shadow should be barely noticeable but provide depth

---

## Design Tips from Professionals

### Tip 1: Test, Test, Test
"View your icon at actual size constantly. What looks good at 1024px might be invisible at 16px." - Apple Design Team

### Tip 2: Embrace Simplification
"The best icons are simple enough for a child to draw from memory." - Icon design principle

### Tip 3: Contrast is King
"If your icon doesn't work in grayscale, it doesn't work." - Design maxim

### Tip 4: Pixel-Perfect Small Sizes
"Always hand-tune 16×16 icons. Automatic scaling never gets it right." - macOS designers

### Tip 5: Study the Masters
Open Finder and look at macOS app icons. Notice how simple they are. That's intentional!

---

## Alternative: Quick Start with Templates

### Figma Template (Recommended for Beginners)

1. Download a macOS app icon template from Figma Community
2. Search for "macOS Big Sur app icon template"
3. Use the 1024×1024 artboard
4. Follow Steps 3-5 above to create the design
5. Export using the template's built-in export settings

### Sketch Template

1. Download from https://applypixels.com/template/macos-big-sur
2. Open the template
3. Work in the 1024×1024 artboard
4. Use the included export presets

---

## Need Help?

### Resources

**Official Guidelines:**
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/app-icons
- SF Symbols (for checkmark reference): https://developer.apple.com/sf-symbols/

**Tutorial Videos:**
- Search YouTube for: "macOS app icon design tutorial"
- Recommended: "How to design app icons for macOS Big Sur"

**Color Picker Tools:**
- Use Digital Color Meter (macOS built-in)
- Online: https://colorpicker.me
- Verify hex codes match exactly

**Icon Testing:**
- Preview icons in Finder: Place PNG in a folder and view
- Check in Preview.app at different zoom levels
- Test on actual macOS dock if possible

---

## Delivery Instructions

### What to Send

1. **Required Files:**
   - `icon-source.svg` (master vector)
   - All 10 PNG files (correctly named)
   - Place in appropriate directories (see Step 10)

2. **Recommended Files:**
   - Your original design file (Figma/Sketch/Illustrator)
   - `icon-preview.png` (512×512 preview)
   - Screenshots of icon at different sizes

3. **Documentation:**
   - Brief notes on any design decisions
   - Any variations you explored
   - Recommendations for future updates

### How to Deliver

**Option A: Direct File Placement**
Copy all files to the appropriate directories as shown in Step 10.

**Option B: Archive**
Create a ZIP file with organized folders and deliver to the development team.

**Option C: Cloud Share**
Share via Dropbox, Google Drive, or similar with organized folder structure.

---

## Timeline

**Typical Design Process:**

- **Hour 1:** Setup, create base sticky note and checkmark
- **Hour 2:** Refine details, add shadow and page curl
- **Hour 3:** Export and optimize for different sizes
- **Hour 4:** Test, refine, and finalize deliverables

**Allow extra time for:**
- Learning new tools (if needed)
- Iteration and feedback
- Hand-tuning small sizes

---

## Final Notes

### Design Freedom

While this specification is detailed, you have creative freedom for:
- Exact page curl style (as long as it's subtle)
- Shadow blur radius (within 10-14px range)
- Minor positioning adjustments for visual balance
- Alternative color scheme (if justified and approved)

### Communication

If you have questions or want to try a different approach:
1. Create mockups showing your alternative
2. Explain your reasoning
3. Get approval before proceeding with full export

### Quality Over Speed

Take your time to get it right. A well-crafted icon will represent the app for years. It's worth the extra hour to perfect it.

---

**Good luck! We're excited to see your design come to life!**

---

## Quick Reference Card

```
📐 Canvas Size:        1024×1024 px
📏 Note Size:          870×870 px (centered)
🎨 Note Color:         #FFD54F
✓ Checkmark Color:     #424242
📍 Corner Radius:      104 px
✏️ Checkmark Stroke:   96 px
🌓 Shadow:             0, 6px, 12px blur, 20% opacity
📦 Export:             10 PNG files + 1 SVG file
```

**Color Codes to Copy-Paste:**
```
#FFD54F   (Sticky note yellow)
#FFE082   (Page curl highlight)
#424242   (Checkmark dark gray)
rgba(0, 0, 0, 0.20)   (Shadow)
```

---

**Document Version:** 1.0
**Last Updated:** 2025-11-18
**Questions?** Refer to `/assets/ICON_SPECIFICATION.md` for detailed technical specs.
