# App Icon Design Guide

## Design Concept

The Sticky ToDo app icon should be simple, recognizable, and evoke the concept of sticky notes and task management.

### Primary Design: Yellow Sticky Note with Checkmark

**Visual Elements:**
- Base: A yellow sticky note (square with slightly curled top-right corner)
- Color: Warm yellow (#FFD54F or #FFEB3B)
- Accent: Bold checkmark in a contrasting color (dark gray #424242 or green #4CAF50)
- Shadow: Subtle drop shadow to give depth
- Style: Flat design with minimal gradients

### Design Specifications

**Dimensions:**
- Source file: 1024x1024 pixels minimum (recommend 2048x2048 for best quality)
- Format: PNG with transparency or SVG for vector scaling
- Color space: sRGB

**Layout:**
1. Background: Transparent or subtle gradient
2. Sticky note: Centered, taking up ~80% of canvas
3. Checkmark: Positioned in center-right of note, bold and clear
4. Corner curl: Subtle but visible even at small sizes

### Color Palette

**Option 1: Classic Yellow**
- Note: #FFD54F (Material Yellow 300)
- Checkmark: #424242 (Gray 800)
- Shadow: rgba(0, 0, 0, 0.2)
- Curl: #FFE082 (lighter yellow)

**Option 2: Modern Gradient**
- Note: Linear gradient from #FFD54F to #FFC107
- Checkmark: #2E7D32 (Green 800)
- Shadow: rgba(0, 0, 0, 0.3)
- Curl: rgba(255, 255, 255, 0.5)

**Option 3: Minimal**
- Note: White (#FFFFFF) with subtle yellow tint
- Checkmark: #1976D2 (Blue 700)
- Border: #FFD54F (yellow outline)
- Shadow: rgba(0, 0, 0, 0.15)

## Creating the Icon

### Option A: Using Figma or Sketch

1. Create a new 1024x1024 artboard
2. Draw a rounded rectangle (900x900) with slight corner radius
3. Add a small triangle in top-right for page curl effect
4. Add checkmark using SF Symbols or custom path
5. Apply colors and shadows
6. Export as PNG at 2x resolution (2048x2048)

### Option B: Using Adobe Illustrator

1. Create 1024x1024 canvas
2. Use Rectangle Tool for sticky note base
3. Use Pen Tool for corner curl detail
4. Import or draw checkmark symbol
5. Apply gradients and effects
6. Save as high-res PNG or SVG

### Option C: Using Icon Generator Tools

**Recommended Tools:**
- [Icon Slate](http://www.kodlian.com/apps/icon-slate) - macOS icon generator
- [Image2Icon](https://img2icnsapp.com/) - Convert images to icns
- [Figma](https://figma.com) - Free design tool
- [Canva](https://canva.com) - Template-based design

## Quick Start with ImageMagick

If you just need a placeholder icon, you can generate a simple one:

```bash
# Create a simple yellow square with checkmark (placeholder)
convert -size 1024x1024 xc:#FFD54F \
    -gravity center \
    -pointsize 600 \
    -font "SF-Pro-Display-Bold" \
    -fill "#424242" \
    -annotate +0+0 "✓" \
    assets/icon-source.png
```

Then run the generation script:

```bash
./scripts/generate-icons.sh assets/icon-source.png
```

## Icon Sizes Generated

The generation script will create all required macOS icon sizes:

- 16x16 (1x and 2x)
- 32x32 (1x and 2x)
- 128x128 (1x and 2x)
- 256x256 (1x and 2x)
- 512x512 (1x and 2x)
- 1024x1024 (for App Store)

## Testing Your Icon

1. Build and run the app
2. Check the icon in:
   - Dock
   - Finder
   - App Switcher (Cmd+Tab)
   - About panel
3. Test at different screen resolutions
4. Verify it looks good on light and dark backgrounds

## Best Practices

1. **Simplicity**: Icon should be recognizable at 16x16 pixels
2. **Uniqueness**: Differentiate from other task management apps
3. **Consistency**: Follow macOS Human Interface Guidelines
4. **Testing**: View icon on multiple backgrounds and sizes
5. **Accessibility**: Ensure good contrast for visibility

## Resources

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [macOS App Icon Template](https://applypixels.com/template/macos-big-sur)
- [SF Symbols](https://developer.apple.com/sf-symbols/) - For checkmark glyphs
