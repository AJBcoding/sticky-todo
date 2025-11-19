# Sticky ToDo App Icon - Complete Specification

**Version:** 1.0
**Date:** 2025-11-18
**Status:** Ready for Designer Implementation

---

## 1. Executive Summary

This document provides complete specifications for creating the Sticky ToDo app icon. The icon represents a task management application that uses sticky note metaphors, combining simplicity with professional polish suitable for macOS Big Sur and later.

**Key Requirements:**
- Simple, recognizable design that works from 16x16 to 1024x1024 pixels
- Yellow sticky note aesthetic with checkmark symbol
- Flat design with subtle depth (modern macOS style)
- High contrast for accessibility
- Scalable vector source (SVG) for future adaptations

---

## 2. Design Concept

### 2.1 Primary Visual Elements

**Base Element: Sticky Note**
- Shape: Rounded square with subtle corner curl (top-right)
- Dimensions: Occupies ~85% of the icon canvas
- Corner radius: 12% of note width (adaptive)
- Page curl: Small triangular fold in top-right corner

**Accent Element: Checkmark**
- Style: Bold, rounded stroke checkmark (✓)
- Position: Center-right, slightly below vertical center
- Weight: 10-12% of icon width
- Style: Rounded caps and joins for friendly appearance

**Depth Element: Shadow**
- Type: Subtle drop shadow
- Purpose: Lift note slightly off background
- Opacity: 15-25%
- Offset: 2-4% of icon size downward

### 2.2 Design Philosophy

The icon should evoke:
- **Simplicity:** Quick capture, easy organization
- **Familiarity:** Sticky notes are universal
- **Completion:** Checkmark represents getting things done
- **Friendliness:** Warm colors, rounded shapes
- **Professionalism:** Clean, modern aesthetic

---

## 3. Color Specifications

### 3.1 Recommended Color Scheme (Primary)

**Sticky Note Base**
- Primary Color: `#FFD54F` (Material Design Yellow 300)
- Alternative: `#FFEB3B` (Material Design Yellow 500)
- RGB: 255, 213, 79
- HSB: 48°, 69%, 100%

**Page Curl Highlight**
- Color: `#FFE082` (lighter yellow)
- RGB: 255, 224, 130
- Applied to curl triangle for subtle depth

**Checkmark**
- Primary: `#424242` (Material Gray 800)
- Alternative: `#2E7D32` (Material Green 800)
- RGB (Gray): 66, 66, 66
- RGB (Green): 46, 125, 50

**Shadow**
- Color: Black with transparency
- RGBA: `rgba(0, 0, 0, 0.20)`
- Blur radius: 8-12px (varies by icon size)
- Offset: (0, 4px) for subtle lift

### 3.2 Alternative Color Schemes

**Option B: Modern Gradient**
```css
Note Background: Linear gradient
  - From: #FFD54F (top)
  - To: #FFC107 (bottom)
  - Angle: 135° (top-left to bottom-right)

Checkmark: #2E7D32 (Green 800)
Page Curl: rgba(255, 255, 255, 0.4)
Shadow: rgba(0, 0, 0, 0.3)
```

**Option C: Minimal Light**
```css
Note Background: #FFFFFF (white with subtle warmth)
Note Border: 2px solid #FFD54F
Checkmark: #1976D2 (Blue 700)
Shadow: rgba(0, 0, 0, 0.12)
```

### 3.3 Color Space and Profiles

- **Color Space:** sRGB
- **Profile:** Display P3 (for macOS)
- **Format:** PNG-24 with alpha channel
- **Bit Depth:** 8-bit per channel minimum

---

## 4. Dimensional Specifications

### 4.1 Canvas and Composition

**Master Canvas**
- Size: 1024×1024 pixels (minimum)
- Recommended: 2048×2048 pixels for highest quality
- Background: Transparent (alpha channel)
- Safe area: 922×922 pixels (90% of canvas)

**Sticky Note Dimensions** (on 1024×1024 canvas)
- Width: 870 pixels (85% of canvas)
- Height: 870 pixels
- Corner Radius: 104 pixels (12% of width)
- Position: Centered on canvas

**Page Curl** (top-right corner)
- Triangle base: 130 pixels
- Triangle height: 130 pixels
- Curl lift: 8-10 pixels from corner

**Checkmark**
- Stroke width: 96 pixels (on 1024×1024 canvas)
- Short arm length: ~200 pixels
- Long arm length: ~360 pixels
- Position: X=600, Y=520 (center-right of note)

**Shadow**
- Blur radius: 12 pixels
- Spread: 0 pixels
- Offset: (0, 6px)
- Opacity: 20%

### 4.2 Required Output Sizes

**macOS App Icon Sizes**

| Size | Scale | Pixels | Usage |
|------|-------|--------|-------|
| 16×16 | 1x | 16×16 | Finder (list view), dock at small size |
| 16×16 | 2x | 32×32 | Retina displays |
| 32×32 | 1x | 32×32 | Finder (icon view) |
| 32×32 | 2x | 64×64 | Retina displays |
| 128×128 | 1x | 128×128 | Sidebar icons |
| 128×128 | 2x | 256×256 | Retina displays |
| 256×256 | 1x | 256×256 | Finder (icon view, large) |
| 256×256 | 2x | 512×512 | Retina displays |
| 512×512 | 1x | 512×512 | Finder (cover flow, preview) |
| 512×512 | 2x | 1024×1024 | Retina displays, App Store |

**iOS App Icon Sizes** (for future iOS version)

| Size | Pixels | Usage |
|------|--------|-------|
| 20×20 | 40×40, 60×60 | Notification icons |
| 29×29 | 58×58, 87×87 | Settings, Spotlight |
| 40×40 | 80×80, 120×120 | Spotlight, notifications |
| 60×60 | 120×120, 180×180 | Home screen (iPhone) |
| 76×76 | 152×152 | Home screen (iPad) |
| 83.5×83.5 | 167×167 | Home screen (iPad Pro) |
| 1024×1024 | 1024×1024 | App Store |

---

## 5. Design Guidelines by Size

### 5.1 Large Sizes (512×512 and up)

**Full Detail:**
- All elements visible and detailed
- Subtle shadow and page curl
- Fine checkmark stroke with rounded caps
- Optional: Very subtle texture on note surface (paper grain at 3-5% opacity)

### 5.2 Medium Sizes (128×128 to 256×256)

**Simplified:**
- Page curl remains visible but simplified
- Shadow slightly more prominent for definition
- Checkmark stroke slightly bolder (proportionally)
- Clean, crisp edges

### 5.3 Small Sizes (32×32 to 64×64)

**Optimized:**
- Page curl may be reduced or removed
- Shadow essential for depth
- Checkmark must remain prominent and clear
- Increase contrast slightly
- Pixel-align all edges

### 5.4 Tiny Sizes (16×16)

**Minimal:**
- Consider removing page curl entirely
- Bold, simple checkmark
- Strong shadow for separation
- Maximum contrast
- Hand-pixel-tune for clarity
- May need to increase checkmark size by 10-15%

---

## 6. Construction Guide

### 6.1 Layer Structure (Recommended)

From bottom to top:

1. **Background Layer** (transparent)
2. **Shadow Layer** (blur effect, 20% opacity)
3. **Sticky Note Base** (yellow fill, rounded rectangle)
4. **Page Curl** (triangle, lighter yellow)
5. **Page Curl Shadow** (subtle inner shadow)
6. **Checkmark** (vector path, dark gray/green)
7. **Optional Texture** (paper grain overlay at 3% opacity)

### 6.2 Vector Path Specifications

**Rounded Rectangle (Sticky Note)**
```
Method: Rectangle with rounded corners
Top-left: (77, 77)
Bottom-right: (947, 947)
Corner radius: 104px
Fill: #FFD54F
```

**Page Curl Triangle**
```
Method: Polygon path
Point 1: (817, 77)    // Left point on top edge
Point 2: (947, 77)    // Top-right corner
Point 3: (947, 207)   // Bottom point on right edge
Fill: Linear gradient from #FFE082 to #FFD54F
```

**Checkmark Path**
```
Method: Stroked path with rounded caps
Point 1: (420, 520)   // Left bottom of check
Point 2: (520, 620)   // Junction point
Point 3: (740, 380)   // Top right
Stroke: 96px
Caps: Rounded
Joins: Rounded
Color: #424242
```

### 6.3 Shadow Specifications

**Drop Shadow Effect**
```
Blur: 12px
Spread: 0px
X-offset: 0px
Y-offset: 6px
Color: rgba(0, 0, 0, 0.20)
Apply to: Sticky Note Base layer
```

---

## 7. Technical Requirements

### 7.1 File Formats

**Source Files** (Designer provides)
- SVG (vector, infinite scalability)
- Figma/Sketch source file (if applicable)
- PSD with layers (if using Photoshop)

**Export Files** (Generated from source)
- PNG-24 with alpha channel
- All sizes listed in Section 4.2
- sRGB color space
- 72 DPI (standard for screen)

### 7.2 Quality Standards

**General**
- No compression artifacts
- Clean alpha channel (no fringe)
- Consistent appearance across all sizes
- Crisp edges at all resolutions

**Small Size Testing** (16×16, 32×32)
- Icon must be recognizable
- Checkmark clearly visible
- No blurry or muddy appearance
- Sharp pixel boundaries

**Large Size Testing** (512×512, 1024×1024)
- Smooth curves and edges
- No pixelation or jagged lines
- Professional finish
- Suitable for App Store marketing

### 7.3 Delivery Format

**File Naming Convention**
```
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
```

**Directory Structure**
```
assets/
  icon-source.svg           // Master SVG source
  icon-source@2x.png        // 2048×2048 master PNG
  icon-preview.png          // Quick preview (512×512)
```

---

## 8. Design Rationale

### 8.1 Why Yellow Sticky Notes?

- **Universal Recognition:** Sticky notes are globally recognized for quick notes and reminders
- **Warm & Approachable:** Yellow is friendly, energetic, and positive
- **Mental Model:** Users already associate sticky notes with task management
- **Differentiation:** Distinct from blue/green productivity apps

### 8.2 Why a Checkmark?

- **Immediate Understanding:** Universal symbol for completion and tasks
- **Action-Oriented:** Suggests getting things done (GTD methodology)
- **Positive Association:** Checkmarks = success, accomplishment
- **Simplicity:** Simple geometric shape that scales well

### 8.3 Design Decisions

**Rounded Corners**
- Modern macOS Big Sur design language
- Friendlier than sharp corners
- Better appearance at small sizes

**Flat Design with Subtle Depth**
- Follows current design trends
- Shadow provides necessary depth without skeuomorphism
- Page curl adds personality without overdesign

**Bold Checkmark**
- Ensures visibility at 16×16 pixels
- Contrasts well with yellow background
- Rounded style matches overall aesthetic

---

## 9. Accessibility Considerations

### 9.1 Contrast Requirements

**WCAG 2.1 Guidelines**
- Checkmark contrast ratio: 7.28:1 (AAA level)
- Dark gray (#424242) on yellow (#FFD54F) meets AAA standard
- Icon is distinguishable in grayscale

### 9.2 Visual Clarity

- **High contrast elements:** Checkmark stands out clearly
- **Simple shapes:** Easy to recognize for users with low vision
- **No fine details required:** Works for colorblind users
- **Size adaptability:** Remains clear even at 16×16 pixels

### 9.3 Testing Checklist

- [ ] Test in grayscale mode
- [ ] Test with deuteranopia simulation (red-green colorblind)
- [ ] Test on light and dark macOS backgrounds
- [ ] Verify 16×16 pixel clarity
- [ ] Check contrast ratios with color analyzer

---

## 10. Brand Consistency

### 10.1 App Design Language

The icon should align with the app's overall design:
- **Color Palette:** Yellow (#FFD54F) as primary brand color
- **Typography:** SF Pro (macOS system font) - rounded, modern
- **UI Elements:** Rounded corners throughout app interface
- **Tone:** Professional yet approachable, efficient yet friendly

### 10.2 Marketing Materials

The icon design can extend to:
- App Store screenshots backgrounds
- Website hero imagery
- Social media profile pictures
- Documentation headers
- Splash screen (if applicable)

---

## 11. Reference Images

### 11.1 Inspiration Sources

**macOS Icons to Study:**
- Notes.app: Simple, recognizable, functional
- Reminders.app: Clean checkmark usage
- Keynote: Effective use of color and simplicity
- Things 3: Professional task management aesthetic

### 11.2 Avoid These Patterns

- ❌ Overly complex illustrations
- ❌ Fine text or intricate details
- ❌ More than 2-3 colors
- ❌ Gradients that muddy at small sizes
- ❌ Extremely thin strokes
- ❌ Literal clipart appearance

---

## 12. Quality Assurance Checklist

### 12.1 Before Delivery

Designer should verify:

- [ ] All 10 macOS icon sizes generated
- [ ] Files named according to convention
- [ ] PNG files have transparent backgrounds
- [ ] No compression artifacts
- [ ] Colors match specification (sRGB)
- [ ] SVG source is clean and optimized
- [ ] Icon looks good on light backgrounds
- [ ] Icon looks good on dark backgrounds
- [ ] 16×16 version is hand-tuned for clarity
- [ ] Checkmark is clearly visible at all sizes
- [ ] Page curl doesn't create muddy appearance at small sizes
- [ ] Shadow provides sufficient depth without being heavy
- [ ] All files are organized and ready for Xcode integration

### 12.2 Approval Testing

Development team will test:

- [ ] Build app with new icons
- [ ] Check Finder icon display
- [ ] Check Dock appearance (normal and small sizes)
- [ ] Check App Switcher (Cmd+Tab)
- [ ] Check About panel
- [ ] Test on Retina and non-Retina displays
- [ ] Verify on light and dark menu bars
- [ ] Check App Store preview

---

## 13. Implementation Notes

### 13.1 Xcode Integration

1. Icons will be placed in `AppIcon.appiconset` directories
2. `Contents.json` file references all icon files
3. No alpha channel in App Store icon (1024×1024)
4. All other sizes support transparency

### 13.2 Asset Catalog Structure

```
StickyToDo-SwiftUI/Assets.xcassets/
  AppIcon.appiconset/
    Contents.json
    icon_16x16@1x.png
    icon_16x16@2x.png
    ... (all sizes)

StickyToDo-AppKit/Assets.xcassets/
  AppIcon.appiconset/
    Contents.json
    icon_16x16@1x.png
    icon_16x16@2x.png
    ... (all sizes)
```

---

## 14. Contact & Questions

For questions or clarifications about this specification:
- Review existing design guide: `/assets/ICON_DESIGN.md`
- Check designer instructions: `/assets/DESIGNER_INSTRUCTIONS.md`
- SVG template specification: `/assets/icon-template.svg.md`

---

## Appendix A: Color Swatch Reference

```
Primary Yellow:     #FFD54F  rgb(255, 213, 79)  hsl(48, 100%, 65%)
Light Yellow:       #FFE082  rgb(255, 224, 130) hsl(48, 100%, 75%)
Darker Yellow:      #FFC107  rgb(255, 193, 7)   hsl(45, 100%, 51%)

Dark Gray:          #424242  rgb(66, 66, 66)    hsl(0, 0%, 26%)
Green:              #2E7D32  rgb(46, 125, 50)   hsl(123, 46%, 34%)
Blue:               #1976D2  rgb(25, 118, 210)  hsl(207, 79%, 46%)

Shadow:             rgba(0, 0, 0, 0.20)
Curl Highlight:     rgba(255, 255, 255, 0.40)
```

## Appendix B: Measurement Reference (1024×1024 canvas)

```
Canvas size:        1024 × 1024 px
Safe area:          922 × 922 px (90%)
Note size:          870 × 870 px (85%)
Note position:      (77, 77) to (947, 947)
Corner radius:      104 px
Curl size:          130 × 130 px
Checkmark stroke:   96 px
Shadow blur:        12 px
Shadow offset:      (0, 6px)
```

---

**Document Version:** 1.0
**Last Updated:** 2025-11-18
**Status:** Approved for Implementation
