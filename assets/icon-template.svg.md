# SVG Template Specification for Sticky ToDo Icon

**This document provides SVG code structure for the icon design.**

Since this is a specification document, the actual SVG file should be created by a designer using professional design tools. However, this provides the exact SVG structure for reference or programmatic generation.

---

## Complete SVG Template

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="1024" height="1024" viewBox="0 0 1024 1024"
     xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink">

  <title>Sticky ToDo App Icon</title>
  <desc>A yellow sticky note with a checkmark, representing task completion</desc>

  <!-- Define filters and effects -->
  <defs>
    <!-- Drop shadow filter -->
    <filter id="dropShadow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="6"/>
      <feOffset dx="0" dy="6" result="offsetblur"/>
      <feComponentTransfer>
        <feFuncA type="linear" slope="0.20"/>
      </feComponentTransfer>
      <feMerge>
        <feMergeNode/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>

    <!-- Optional: Gradient for modern look -->
    <linearGradient id="noteGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#FFD54F;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#FFC107;stop-opacity:1" />
    </linearGradient>

    <!-- Gradient for page curl -->
    <linearGradient id="curlGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#FFE082;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#FFD54F;stop-opacity:1" />
    </linearGradient>
  </defs>

  <!-- Main icon group -->
  <g id="icon" filter="url(#dropShadow)">

    <!-- Sticky note base -->
    <rect id="sticky-note-base"
          x="77"
          y="77"
          width="870"
          height="870"
          rx="104"
          ry="104"
          fill="#FFD54F"
          stroke="none"/>
    <!-- Alternative: use fill="url(#noteGradient)" for gradient version -->

    <!-- Page curl (top-right corner) -->
    <path id="page-curl"
          d="M 817 77 L 947 77 L 947 207 Z"
          fill="url(#curlGradient)"
          stroke="none"/>
    <!-- Alternative solid fill: fill="#FFE082" -->

    <!-- Checkmark -->
    <path id="checkmark"
          d="M 420 520 L 520 620 L 740 380"
          fill="none"
          stroke="#424242"
          stroke-width="96"
          stroke-linecap="round"
          stroke-linejoin="round"/>
    <!-- Alternative green: stroke="#2E7D32" -->

  </g>

</svg>
```

---

## SVG Structure Breakdown

### 1. Document Setup

```xml
<svg width="1024" height="1024" viewBox="0 0 1024 1024">
```

- **width/height**: 1024×1024 pixels (can scale infinitely)
- **viewBox**: Defines coordinate system (0,0 to 1024,1024)
- **xmlns**: Standard SVG namespace

### 2. Definitions Section

The `<defs>` section contains reusable elements:

**Drop Shadow Filter:**
```xml
<filter id="dropShadow">
  <feGaussianBlur stdDeviation="6"/>     <!-- 12px blur diameter -->
  <feOffset dy="6"/>                      <!-- 6px downward offset -->
  <feComponentTransfer>
    <feFuncA slope="0.20"/>               <!-- 20% opacity -->
  </feComponentTransfer>
</filter>
```

**Gradients:**
- Optional for more modern look
- Can be replaced with solid fills for simpler version

### 3. Main Elements

**Sticky Note (Rounded Rectangle):**
```xml
<rect x="77" y="77" width="870" height="870" rx="104" fill="#FFD54F"/>
```

- **Position**: (77, 77) - centers 870px square in 1024px canvas
- **Size**: 870×870 pixels
- **rx/ry**: 104px corner radius (12% of width)
- **fill**: #FFD54F (primary yellow)

**Page Curl (Triangle Path):**
```xml
<path d="M 817 77 L 947 77 L 947 207 Z"/>
```

- **M 817 77**: Move to starting point (130px from right on top edge)
- **L 947 77**: Line to top-right corner
- **L 947 207**: Line down right edge (130px)
- **Z**: Close path back to start

**Checkmark (Stroked Path):**
```xml
<path d="M 420 520 L 520 620 L 740 380"
      stroke="#424242" stroke-width="96"
      stroke-linecap="round" stroke-linejoin="round"/>
```

- **M 420 520**: Starting point (left bottom of check)
- **L 520 620**: Line to junction point (bottom of check)
- **L 740 380**: Line to top-right endpoint
- **stroke-width**: 96px for bold appearance
- **stroke-linecap/join**: Rounded for friendly look

---

## Path Coordinate Reference

All coordinates for 1024×1024 canvas:

```
Canvas corners:
  Top-left:     (0, 0)
  Top-right:    (1024, 0)
  Bottom-left:  (0, 1024)
  Bottom-right: (1024, 1024)
  Center:       (512, 512)

Sticky note:
  Top-left:     (77, 77)
  Top-right:    (947, 77)
  Bottom-left:  (77, 947)
  Bottom-right: (947, 947)

Page curl triangle:
  Point 1:      (817, 77)    // Left point on top edge
  Point 2:      (947, 77)    // Top-right corner
  Point 3:      (947, 207)   // Bottom point on right edge

Checkmark:
  Start:        (420, 520)   // Left bottom
  Junction:     (520, 620)   // Middle junction
  End:          (740, 380)   // Top right
```

---

## Alternative Versions

### Simple Version (No Gradients)

```xml
<!-- Replace gradient fills with solid colors -->
<rect fill="#FFD54F"/>           <!-- Sticky note -->
<path fill="#FFE082"/>           <!-- Page curl -->
```

### Green Checkmark Version

```xml
<path stroke="#2E7D32"/>         <!-- Green instead of gray -->
```

### Minimal Version (No Page Curl)

```xml
<!-- Simply omit the page curl path element -->
<rect fill="#FFD54F"/>           <!-- Just note and checkmark -->
<path stroke="#424242"/>
```

---

## Optimization Tips

### Size Optimization

**For smallest file size:**
1. Remove comments
2. Minimize decimal places (1-2 max)
3. Use shorthand attributes
4. Remove unused definitions
5. Compress paths where possible

**Optimized version:**
```xml
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="s"><feGaussianBlur stdDeviation="6"/><feOffset dy="6"/>
    <feComponentTransfer><feFuncA slope=".2"/></feComponentTransfer>
    <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  </defs>
  <g filter="url(#s)">
    <rect x="77" y="77" width="870" height="870" rx="104" fill="#FFD54F"/>
    <path d="M817 77L947 77 947 207Z" fill="#FFE082"/>
    <path d="M420 520L520 620 740 380" stroke="#424242" stroke-width="96"
          stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  </g>
</svg>
```

### Tool-Based Optimization

**SVGO (Command line):**
```bash
npm install -g svgo
svgo icon-source.svg -o icon-source-optimized.svg
```

**Online:**
- https://jakearchibald.github.io/svgomg/
- Upload SVG and adjust optimization settings

---

## Scalability Considerations

### The Power of SVG

This SVG will scale perfectly to any size:

```xml
<!-- Tiny icon -->
<img src="icon.svg" width="16" height="16">

<!-- Huge banner -->
<img src="icon.svg" width="2048" height="2048">

<!-- Perfectly crisp at any size! -->
```

### Responsive Adjustments

For different sizes, you might adjust stroke-width:

```xml
<!-- For very small sizes (16-32px) -->
<path stroke-width="120"/>  <!-- Bolder checkmark -->

<!-- For standard sizes (128-512px) -->
<path stroke-width="96"/>   <!-- Normal weight -->

<!-- For large sizes (1024px+) -->
<path stroke-width="80"/>   <!-- Slightly thinner -->
```

---

## Conversion to PNG

### Using Inkscape (Command Line)

```bash
# Install Inkscape
brew install inkscape  # macOS
apt-get install inkscape  # Linux

# Convert to PNG at different sizes
inkscape icon-source.svg --export-filename=icon_16x16@1x.png -w 16 -h 16
inkscape icon-source.svg --export-filename=icon_512x512@1x.png -w 512 -h 512
inkscape icon-source.svg --export-filename=icon_512x512@2x.png -w 1024 -h 1024
```

### Using ImageMagick

```bash
# Convert SVG to PNG
convert -background none icon-source.svg -resize 1024x1024 icon-1024.png
```

### Using CairoSVG (Python)

```python
import cairosvg

cairosvg.svg2png(
    url="icon-source.svg",
    write_to="icon-1024.png",
    output_width=1024,
    output_height=1024
)
```

---

## Accessibility Enhancements

### Add ARIA Labels

```xml
<svg role="img" aria-labelledby="iconTitle iconDesc">
  <title id="iconTitle">Sticky ToDo</title>
  <desc id="iconDesc">Task management app icon showing a yellow sticky note with checkmark</desc>
  <!-- ... rest of icon ... -->
</svg>
```

### Semantic Grouping

```xml
<g id="sticky-note">
  <rect/>  <!-- Base -->
  <path/>  <!-- Curl -->
</g>
<g id="completion-symbol">
  <path/>  <!-- Checkmark -->
</g>
```

---

## Testing Your SVG

### Validation

**Online Validators:**
- https://validator.w3.org/ (paste SVG code)
- Check for syntax errors

### Visual Testing

**In Browser:**
1. Save SVG file
2. Open in Chrome/Safari/Firefox
3. Zoom in/out to test scaling
4. Test on light and dark backgrounds

**In Finder (macOS):**
1. Save SVG to Desktop
2. Use Quick Look (Space bar)
3. View at different sizes

### Conversion Testing

Convert to PNG and verify:
```bash
# Quick test conversion
convert icon-source.svg -resize 512x512 test-output.png
open test-output.png
```

---

## Version Control Recommendations

### Git-Friendly SVG

Keep SVG readable for version control:

```xml
<!-- Good: Formatted, readable -->
<svg>
  <rect x="77" y="77" width="870" height="870"/>
  <path d="M 420 520 L 520 620"/>
</svg>

<!-- Bad: Minified, hard to track changes -->
<svg><rect x="77" y="77" width="870" height="870"/><path d="M420 520L520 620"/></svg>
```

### Commit Strategy

```bash
git add assets/icon-source.svg
git commit -m "Update app icon: adjust checkmark position"
```

Keep optimized versions separate from source:
- Source: `icon-source.svg` (readable, versioned)
- Optimized: `icon-optimized.svg` (minified, for production)

---

## Common SVG Issues and Fixes

### Issue: Shadow not showing

**Fix:** Ensure filter is applied and referenced correctly
```xml
<filter id="dropShadow">...</filter>
<g filter="url(#dropShadow)">...</g>  <!-- Correct reference -->
```

### Issue: Rounded corners not working

**Fix:** Use both `rx` and `ry` attributes
```xml
<rect rx="104" ry="104"/>  <!-- Both required for uniform rounding -->
```

### Issue: Colors not matching

**Fix:** Use exact hex codes (case-insensitive but consistent)
```xml
fill="#FFD54F"   <!-- Correct -->
fill="#ffd54f"   <!-- Also works (lowercase) -->
fill="yellow"    <!-- Wrong! Not specific enough -->
```

### Issue: Checkmark looks pixelated

**Fix:** Ensure `stroke-linecap` and `stroke-linejoin` are set
```xml
stroke-linecap="round" stroke-linejoin="round"
```

---

## Export Settings by Tool

### Figma Export Settings

1. Select icon group
2. Add export setting: "SVG"
3. Settings:
   - ☑ Include "id" attribute
   - ☑ Outline text
   - ☐ Flatten transform (keep hierarchy)
4. Export

### Sketch Export Settings

1. Select artboard
2. Make Exportable → Add SVG
3. Settings:
   - Format: SVG
   - Attributes: Presentation attributes
   - Precision: 2 decimal places
4. Export

### Illustrator Export Settings

1. File → Export → Export As
2. Format: SVG
3. Settings:
   - Styling: Presentation attributes
   - Font: Convert to outlines
   - Images: Embed
   - Decimal places: 2
   - Minify: Off (for source file)
4. Export

---

## Final SVG Checklist

Before delivering your SVG:

- [ ] Valid XML syntax (no unclosed tags)
- [ ] Correct viewBox (0 0 1024 1024)
- [ ] All paths use correct coordinates
- [ ] Colors match specification exactly
- [ ] Filter (shadow) is properly defined and applied
- [ ] Stroke attributes are set correctly
- [ ] File size is reasonable (<10KB uncompressed)
- [ ] Opens correctly in browsers
- [ ] Scales properly at different sizes
- [ ] Converts cleanly to PNG

---

## Additional Resources

**SVG References:**
- MDN SVG Tutorial: https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial
- SVG Specification: https://www.w3.org/TR/SVG2/
- SVG Path Reference: https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial/Paths

**Tools:**
- SVGOMG (optimizer): https://jakearchibald.github.io/svgomg/
- SVG Path Editor: https://yqnn.github.io/svg-path-editor/
- Inkscape: https://inkscape.org/

**Testing:**
- SVG Viewer: https://www.svgviewer.dev/
- Can I Use (browser support): https://caniuse.com/?search=svg

---

**Document Version:** 1.0
**Last Updated:** 2025-11-18

**Next Steps:**
1. Create the SVG using your preferred design tool
2. Export following the specifications above
3. Validate the SVG
4. Convert to PNG using the generation script
5. Test at all required sizes
