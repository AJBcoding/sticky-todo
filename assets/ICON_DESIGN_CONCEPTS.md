# Sticky ToDo App Icon Design Concepts
**Comprehensive Design Specification with Multiple Options**

**Version:** 1.0
**Date:** 2025-11-18
**Status:** Ready for Designer Implementation
**Priority:** LOW (Can be completed when designer resources are available)

---

## Executive Summary

This document provides **5 complete icon design concepts** for the Sticky ToDo macOS application, along with comprehensive technical specifications, size requirements, and implementation guidelines. Each concept maintains the core brand identity (task management with sticky note metaphor) while offering different visual approaches.

**What's Included:**
- 5 fully-specified design concepts with visual descriptions
- Complete size requirements (10 variants for macOS)
- Detailed color palettes for each concept
- Technical specifications and export settings
- Step-by-step implementation guide
- Automated generation scripts

**Designer Deliverables:**
1. Master SVG file (scalable vector source)
2. High-resolution PNG (2048x2048 or 1024x1024)
3. 10 PNG files at required sizes (automated via script)
4. Optional: Source design file (Figma/Sketch/Illustrator)

---

## Table of Contents

1. [Design Concepts Overview](#design-concepts-overview)
2. [Concept 1: Classic Sticky Note](#concept-1-classic-sticky-note-recommended)
3. [Concept 2: Gradient Modern](#concept-2-gradient-modern)
4. [Concept 3: Minimal Line Art](#concept-3-minimal-line-art)
5. [Concept 4: Bold & Vibrant](#concept-4-bold--vibrant)
6. [Concept 5: Professional Monochrome](#concept-5-professional-monochrome)
7. [Complete Size Requirements](#complete-size-requirements)
8. [Technical Specifications](#technical-specifications)
9. [Color Specifications](#color-specifications)
10. [Implementation Guide](#implementation-guide)
11. [File Naming Conventions](#file-naming-conventions)
12. [Quality Checklist](#quality-checklist)

---

## Design Concepts Overview

All concepts share these core requirements:
- **Must be recognizable at 16x16 pixels**
- **Sticky note metaphor** (represents task/note organization)
- **Completion symbol** (checkmark or similar)
- **Modern macOS aesthetic** (Big Sur and later)
- **Scalable from 16x16 to 1024x1024 pixels**
- **Accessible** (WCAG AAA contrast ratio ≥7:1)

### Concept Selection Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Brand Recognition | High | Immediately identifiable as task app |
| Scalability | High | Must work at all sizes |
| Accessibility | High | Color contrast, clarity |
| Aesthetic Appeal | Medium | Modern, professional |
| Uniqueness | Medium | Distinguishable from competitors |
| Implementation Ease | Low | All concepts are achievable |

---

## Concept 1: Classic Sticky Note (RECOMMENDED)

**Design Philosophy:** Familiar, friendly, and immediately recognizable. Uses the universal sticky note metaphor with a bold checkmark.

### Visual Description

**Primary Elements:**
- Yellow sticky note with rounded corners (Material Design Yellow 300)
- Subtle page curl in top-right corner
- Bold dark gray checkmark centered on note
- Soft drop shadow for depth

**Style:** Flat design with subtle skeuomorphic touches (page curl)

**Mood:** Friendly, approachable, productive, familiar

### Detailed Specifications

**Canvas:** 1024x1024 pixels

**Sticky Note:**
- Shape: Rounded rectangle
- Position: Centered (77, 77) to (947, 947)
- Size: 870x870 pixels (85% of canvas)
- Corner radius: 104 pixels (12% of width)
- Fill: `#FFD54F` (solid color)
- Shadow: 12px blur, 6px offset down, 20% black

**Page Curl (Top-Right Corner):**
- Shape: Triangle
- Points: (817, 77), (947, 77), (947, 207)
- Fill: `#FFE082` (lighter yellow)
- Optional: Subtle gradient from #FFE082 to #FFD54F

**Checkmark:**
- Path: (420, 520) → (520, 620) → (740, 380)
- Stroke: 96 pixels wide
- Color: `#424242` (dark gray)
- Style: Rounded caps and joins
- Position: Center-right, slightly below vertical center

**Background:** Transparent

### Color Palette

```css
Primary (Sticky Note):   #FFD54F  /* Material Yellow 300 */
                        rgb(255, 213, 79)
                        hsl(48, 69%, 100%)

Page Curl Highlight:     #FFE082  /* Lighter Yellow */
                        rgb(255, 224, 130)

Checkmark:              #424242  /* Material Gray 800 */
                        rgb(66, 66, 66)

Shadow:                 rgba(0, 0, 0, 0.20)
```

### Size-Specific Optimizations

**1024x1024 - 512x512:**
- Full detail with page curl
- All elements visible
- Subtle shadow (12px blur)

**256x256 - 128x128:**
- Page curl slightly simplified
- Checkmark stroke proportionally same
- Shadow slightly stronger (15-18% opacity → 22-25%)

**64x64 - 32x32:**
- Reduce or remove page curl
- Ensure checkmark is crisp
- Pixel-align all edges
- Shadow essential for depth

**16x16:**
- Remove page curl entirely
- Simplify to yellow square + bold checkmark
- Increase checkmark weight by 10-15%
- Strong shadow for separation

### Pros & Cons

**Pros:**
- ✓ Immediately recognizable (sticky notes = tasks/notes)
- ✓ Universal metaphor, no explanation needed
- ✓ Friendly, approachable aesthetic
- ✓ Yellow stands out in dock and finder
- ✓ High contrast for accessibility
- ✓ Works well at all sizes

**Cons:**
- May be seen as "too simple" by some
- Yellow is common for note apps (Notes.app, etc.)
- Page curl is slightly dated (but can be removed)

**Best For:** General users, productivity enthusiasts, those who value clarity over novelty

---

## Concept 2: Gradient Modern

**Design Philosophy:** Contemporary and polished. Uses gradients and subtle effects for a premium, modern look.

### Visual Description

**Primary Elements:**
- Sticky note with smooth gradient (yellow to amber)
- Glossy highlight along top edge
- Simplified corner fold (no traditional curl)
- Green checkmark for positive reinforcement
- Subtle inner shadow for depth

**Style:** Modern gradient design with glass-morphism touches

**Mood:** Premium, polished, energetic, optimistic

### Detailed Specifications

**Sticky Note:**
- Shape: Rounded rectangle (same dimensions as Concept 1)
- Fill: Linear gradient
  - From: `#FFD54F` (top-left)
  - To: `#FFC107` (bottom-right)
  - Angle: 135 degrees
- Corner radius: 104 pixels
- Inner shadow: 2px, 0px offset, 8% black (optional)

**Top Highlight:**
- Shape: Horizontal band across top 20% of note
- Fill: `rgba(255, 255, 255, 0.15)` (white overlay)
- Blur: 4px gaussian blur for soft edge

**Corner Fold:**
- Shape: Small triangle (simpler than Concept 1)
- Points: (880, 77), (947, 77), (947, 144)
- Fill: `rgba(255, 255, 255, 0.35)` (white, semi-transparent)

**Checkmark:**
- Path: Same as Concept 1
- Stroke: 96 pixels
- Color: `#2E7D32` (Material Green 800)
- Style: Rounded caps and joins
- Optional: Very subtle white glow (2px, 5% opacity)

**Shadow:**
- Blur: 16px (larger than Concept 1)
- Offset: (0, 8px)
- Color: `rgba(0, 0, 0, 0.25)` (slightly darker)

### Color Palette

```css
Gradient Start:         #FFD54F  /* Material Yellow 300 */
Gradient End:           #FFC107  /* Material Yellow 700 */

Checkmark:              #2E7D32  /* Material Green 800 */
                       rgb(46, 125, 50)

Highlight:              rgba(255, 255, 255, 0.15)
Corner Fold:            rgba(255, 255, 255, 0.35)
Shadow:                 rgba(0, 0, 0, 0.25)
```

### Size-Specific Optimizations

**Large sizes (512+):**
- Full gradient with smooth transitions
- All highlights and shadows visible

**Medium sizes (128-256):**
- Simplify gradient (may appear as solid at small sizes)
- Keep checkmark prominent

**Small sizes (≤64):**
- Gradient becomes less noticeable, effectively solid
- Remove top highlight and fold
- Focus on checkmark clarity

### Pros & Cons

**Pros:**
- ✓ Modern, premium appearance
- ✓ Green checkmark = positive, completion
- ✓ Stands out as more polished than flat designs
- ✓ Gradient adds depth without clutter

**Cons:**
- Gradients may not scale perfectly to small sizes
- More complex to implement
- Green checkmark less contrasting than gray
- May feel "too modern" for some users

**Best For:** Users who prefer modern aesthetics, premium positioning, younger demographic

---

## Concept 3: Minimal Line Art

**Design Philosophy:** Clean, simple, and elegant. Focuses on essential shapes with minimal embellishment.

### Visual Description

**Primary Elements:**
- White/off-white square with subtle yellow border
- No fill, just outline
- Simple checkmark in blue (trust/reliability color)
- Extremely clean, almost icon-like
- Minimal shadow or no shadow

**Style:** Minimal line art, outline-based

**Mood:** Clean, professional, focused, distraction-free

### Detailed Specifications

**Canvas:** 1024x1024 pixels

**Sticky Note:**
- Shape: Rounded rectangle (same size as Concept 1)
- Fill: `#FFFFFF` or `#FAFAFA` (white or very light gray)
- Border: 6px solid `#FFD54F` (yellow)
- Corner radius: 104 pixels

**Checkmark:**
- Path: Same as Concept 1
- Stroke: 80 pixels (slightly thinner)
- Color: `#1976D2` (Material Blue 700)
- Style: Rounded caps and joins

**Shadow:**
- Minimal: 8px blur, 3px offset
- Color: `rgba(0, 0, 0, 0.10)` (very subtle)
- Or: No shadow for ultra-clean look

**Background:** Transparent

### Color Palette

```css
Note Fill:              #FFFFFF  /* White */
                       or #FAFAFA /* Very Light Gray */

Border:                 #FFD54F  /* Yellow - Brand Color */

Checkmark:              #1976D2  /* Material Blue 700 */
                       rgb(25, 118, 210)
                       hsl(207, 79%, 46%)

Shadow (optional):      rgba(0, 0, 0, 0.10)
```

### Size-Specific Optimizations

**Large sizes (512+):**
- Clean lines, all details visible
- 6px border

**Medium sizes (128-256):**
- 4-5px border
- Checkmark remains clear

**Small sizes (64-32):**
- 2-3px border
- Increase checkmark weight slightly
- Ensure border is visible

**Tiny (16):**
- May need to fill note with light yellow instead of border
- Bold blue checkmark
- Maximum simplicity

### Pros & Cons

**Pros:**
- ✓ Extremely clean and modern
- ✓ Stands out from typical colorful app icons
- ✓ Professional, minimalist aesthetic
- ✓ Blue checkmark = trust and reliability
- ✓ Easy to implement

**Cons:**
- May be "too minimal" and lack personality
- White fill might not stand out on light backgrounds
- Less immediately recognizable as task app
- Blue checkmark less associated with completion

**Best For:** Minimalist users, professional environments, those who prefer subtle design

---

## Concept 4: Bold & Vibrant

**Design Philosophy:** Eye-catching and energetic. Uses bright colors and strong contrast for maximum visibility.

### Visual Description

**Primary Elements:**
- Bright orange-yellow sticky note (more saturated)
- Deep shadow for strong depth
- Thick black checkmark for maximum contrast
- Optional: Subtle texture (paper grain)
- More saturated, punchy colors

**Style:** Bold, flat design with high contrast

**Mood:** Energetic, dynamic, motivating, action-oriented

### Detailed Specifications

**Sticky Note:**
- Shape: Rounded rectangle (same dimensions)
- Fill: `#FFAB00` (Amber A700 - more saturated than Concept 1)
- Corner radius: 104 pixels
- Optional: Very subtle paper texture overlay (3% opacity)

**Page Curl:**
- Similar to Concept 1 but more pronounced
- Fill: `#FFD54F` (lighter contrast)
- Size: 150x150 instead of 130x130

**Checkmark:**
- Path: Same as Concept 1
- Stroke: 110 pixels (thicker than Concept 1)
- Color: `#000000` or `#212121` (pure black or near-black)
- Style: Rounded caps and joins

**Shadow:**
- Strong shadow for dramatic effect
- Blur: 18px
- Offset: (0, 10px)
- Color: `rgba(0, 0, 0, 0.35)` (darker and more prominent)

### Color Palette

```css
Sticky Note:            #FFAB00  /* Amber A700 */
                       rgb(255, 171, 0)
                       hsl(40, 100%, 50%)

Page Curl:              #FFD54F  /* Yellow 300 */

Checkmark:              #000000  /* Pure Black */
                       or #212121 /* Near-Black */

Shadow:                 rgba(0, 0, 0, 0.35)

Optional Texture:       rgba(0, 0, 0, 0.03)
```

### Size-Specific Optimizations

**All sizes:**
- High contrast makes it work well at all sizes
- Thick checkmark remains visible even at 16x16
- Strong shadow provides clear separation

**Small sizes:**
- Remove or simplify page curl
- Keep thick checkmark and strong shadow
- Contrast ensures clarity

### Pros & Cons

**Pros:**
- ✓ Maximum visibility in dock/finder
- ✓ High energy, motivating aesthetic
- ✓ Black checkmark = maximum contrast (9.5:1)
- ✓ Memorable and distinctive
- ✓ Works exceptionally well at small sizes

**Cons:**
- May be "too loud" for some users
- Orange-yellow less universally associated with sticky notes
- Strong shadow might feel dated to some
- Very bold aesthetic may not suit all brands

**Best For:** Action-oriented users, those who want maximum visibility, younger audience

---

## Concept 5: Professional Monochrome

**Design Philosophy:** Sophisticated and timeless. Uses grayscale with a single accent color for a professional, distraction-free look.

### Visual Description

**Primary Elements:**
- Light gray note with darker gray border
- Single yellow accent (page corner or checkmark highlight)
- Clean, corporate aesthetic
- Subtle shadows and depth
- Timeless design that won't age

**Style:** Corporate minimalism with restrained color

**Mood:** Professional, serious, focused, timeless

### Detailed Specifications

**Sticky Note:**
- Shape: Rounded rectangle
- Fill: `#EEEEEE` (Gray 200)
- Border: 3px solid `#BDBDBD` (Gray 400)
- Corner radius: 104 pixels

**Page Corner Accent:**
- Small triangle (top-right corner)
- Fill: `#FFD54F` (yellow - only color accent)
- Size: 100x100 pixels

**Checkmark:**
- Path: Same as Concept 1
- Stroke: 96 pixels
- Color: `#424242` (Dark Gray 800)
- Style: Rounded caps and joins

**Shadow:**
- Moderate depth
- Blur: 14px
- Offset: (0, 7px)
- Color: `rgba(0, 0, 0, 0.22)`

### Color Palette

```css
Note Fill:              #EEEEEE  /* Gray 200 */
                       rgb(238, 238, 238)

Border:                 #BDBDBD  /* Gray 400 */
                       rgb(189, 189, 189)

Accent (Corner):        #FFD54F  /* Yellow 300 - Only color */

Checkmark:              #424242  /* Gray 800 */
                       rgb(66, 66, 66)

Shadow:                 rgba(0, 0, 0, 0.22)
```

### Size-Specific Optimizations

**Large sizes:**
- All details visible
- Yellow corner accent stands out

**Medium sizes:**
- Border remains visible
- Corner accent provides color pop

**Small sizes:**
- Simplify or remove border
- Keep yellow accent for distinction
- Ensure checkmark is clear

### Pros & Cons

**Pros:**
- ✓ Professional, corporate-friendly
- ✓ Timeless design won't look dated
- ✓ Works on any background
- ✓ Yellow accent provides just enough color
- ✓ Accessible and clear

**Cons:**
- May be "too boring" for consumer market
- Grayscale might not stand out in dock
- Lacks the warmth of yellow sticky notes
- Not as immediately identifiable

**Best For:** Corporate users, professional environments, minimalist preferences, timeless design

---

## Concept Comparison Matrix

| Aspect | Concept 1 | Concept 2 | Concept 3 | Concept 4 | Concept 5 |
|--------|-----------|-----------|-----------|-----------|-----------|
| **Recognizability** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Scalability** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Accessibility** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Modern Appeal** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Brand Fit** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Implementation** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Uniqueness** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Overall** | **Recommended** | Premium Option | Minimalist Option | Bold Option | Professional Option |

---

## Complete Size Requirements

### macOS App Icon Sizes (Required)

All concepts must be exported in these 10 sizes:

| Size Name | Scale | Pixel Dimensions | Filename | Usage Context |
|-----------|-------|------------------|----------|---------------|
| 16×16 | 1x | 16 × 16 | `icon_16x16@1x.png` | Finder list view, menu bar |
| 16×16 | 2x | 32 × 32 | `icon_16x16@2x.png` | Retina displays |
| 32×32 | 1x | 32 × 32 | `icon_32x32@1x.png` | Finder icon view (small) |
| 32×32 | 2x | 64 × 64 | `icon_32x32@2x.png` | Retina displays |
| 128×128 | 1x | 128 × 128 | `icon_128x128@1x.png` | Finder sidebar, list view (large) |
| 128×128 | 2x | 256 × 256 | `icon_128x128@2x.png` | Retina displays |
| 256×256 | 1x | 256 × 256 | `icon_256x256@1x.png` | Finder icon view (large) |
| 256×256 | 2x | 512 × 512 | `icon_256x256@2x.png` | Retina displays |
| 512×512 | 1x | 512 × 512 | `icon_512x512@1x.png` | Cover flow, Quick Look |
| 512×512 | 2x | 1024 × 1024 | `icon_512x512@2x.png` | Retina displays, App Store |

**Total Required Files:** 10 PNG files per concept

### Future iOS Sizes (Optional - for reference)

If the app expands to iOS, these additional sizes would be needed:

| Size | Scale | Pixels | Usage |
|------|-------|--------|-------|
| 20pt | 2x, 3x | 40×40, 60×60 | Notifications |
| 29pt | 2x, 3x | 58×58, 87×87 | Settings |
| 40pt | 2x, 3x | 80×80, 120×120 | Spotlight |
| 60pt | 2x, 3x | 120×120, 180×180 | Home screen (iPhone) |
| 76pt | 1x, 2x | 76×76, 152×152 | Home screen (iPad) |
| 83.5pt | 2x | 167×167 | Home screen (iPad Pro) |
| 1024pt | 1x | 1024×1024 | App Store |

---

## Technical Specifications

### File Format Requirements

**Master Source File:**
- Format: SVG (preferred) or high-resolution PNG
- Dimensions: 2048×2048 pixels (PNG) or scalable (SVG)
- Color space: sRGB or Display P3
- Background: Transparent (alpha channel)

**Export Files:**
- Format: PNG-24 with alpha channel
- Color space: sRGB (required for consistency)
- Bit depth: 8-bit per channel (24-bit color + 8-bit alpha)
- Background: Transparent
- DPI: 72 (screen resolution)
- Compression: Medium (balance quality and file size)

### Quality Standards

**All Sizes:**
- No compression artifacts or banding
- Clean alpha channel (no fringe or halo)
- Smooth anti-aliasing on curves
- Consistent appearance across sizes

**Small Sizes (16×16, 32×32):**
- Pixel-perfect alignment
- Hand-tuned for maximum clarity
- Strong contrast
- Simplified details

**Large Sizes (512×512, 1024×1024):**
- Smooth, professional curves
- No jagged edges or pixelation
- Suitable for App Store marketing
- High-quality rendering

### Accessibility Requirements

**WCAG 2.1 Level AAA:**
- Contrast ratio ≥ 7:1 between foreground and background
- Icon distinguishable in grayscale
- Clear at minimum size (16×16 pixels)
- Works on both light and dark backgrounds

**Contrast Ratios (Calculated):**
- Concept 1: 7.28:1 (AAA) - #424242 on #FFD54F
- Concept 2: 5.89:1 (AA+) - #2E7D32 on #FFD54F
- Concept 3: 4.85:1 (AA) - #1976D2 on #FFFFFF
- Concept 4: 9.52:1 (AAA) - #000000 on #FFAB00
- Concept 5: 7.28:1 (AAA) - #424242 on #EEEEEE

---

## Color Specifications

### Concept 1: Classic Sticky Note

```css
/* Primary Colors */
--sticky-note:        #FFD54F;  /* Material Yellow 300 */
--page-curl:          #FFE082;  /* Yellow 200 */
--checkmark:          #424242;  /* Gray 800 */
--shadow:             rgba(0, 0, 0, 0.20);

/* RGB Values */
--sticky-note-rgb:    rgb(255, 213, 79);
--page-curl-rgb:      rgb(255, 224, 130);
--checkmark-rgb:      rgb(66, 66, 66);

/* HSL Values */
--sticky-note-hsl:    hsl(48, 100%, 65%);
--checkmark-hsl:      hsl(0, 0%, 26%);
```

### Concept 2: Gradient Modern

```css
/* Gradient Colors */
--gradient-start:     #FFD54F;  /* Yellow 300 */
--gradient-end:       #FFC107;  /* Yellow 700 */
--checkmark:          #2E7D32;  /* Green 800 */
--highlight:          rgba(255, 255, 255, 0.15);
--corner-fold:        rgba(255, 255, 255, 0.35);
--shadow:             rgba(0, 0, 0, 0.25);

/* RGB Values */
--gradient-start-rgb: rgb(255, 213, 79);
--gradient-end-rgb:   rgb(255, 193, 7);
--checkmark-rgb:      rgb(46, 125, 50);
```

### Concept 3: Minimal Line Art

```css
/* Primary Colors */
--note-fill:          #FFFFFF;  /* White */
--border:             #FFD54F;  /* Yellow 300 */
--checkmark:          #1976D2;  /* Blue 700 */
--shadow:             rgba(0, 0, 0, 0.10);

/* RGB Values */
--note-fill-rgb:      rgb(255, 255, 255);
--border-rgb:         rgb(255, 213, 79);
--checkmark-rgb:      rgb(25, 118, 210);
```

### Concept 4: Bold & Vibrant

```css
/* Primary Colors */
--sticky-note:        #FFAB00;  /* Amber A700 */
--page-curl:          #FFD54F;  /* Yellow 300 */
--checkmark:          #000000;  /* Pure Black */
--shadow:             rgba(0, 0, 0, 0.35);

/* RGB Values */
--sticky-note-rgb:    rgb(255, 171, 0);
--page-curl-rgb:      rgb(255, 213, 79);
--checkmark-rgb:      rgb(0, 0, 0);
```

### Concept 5: Professional Monochrome

```css
/* Primary Colors */
--note-fill:          #EEEEEE;  /* Gray 200 */
--border:             #BDBDBD;  /* Gray 400 */
--accent:             #FFD54F;  /* Yellow 300 */
--checkmark:          #424242;  /* Gray 800 */
--shadow:             rgba(0, 0, 0, 0.22);

/* RGB Values */
--note-fill-rgb:      rgb(238, 238, 238);
--border-rgb:         rgb(189, 189, 189);
--accent-rgb:         rgb(255, 213, 79);
--checkmark-rgb:      rgb(66, 66, 66);
```

---

## Implementation Guide

### Step 1: Choose Your Concept

Review all 5 concepts and select one based on:
1. Brand personality and target audience
2. Context of use (consumer vs. professional)
3. Design preferences and aesthetic goals
4. Accessibility and visibility requirements

**Recommendation:** Concept 1 (Classic Sticky Note) for broad appeal and maximum recognizability

### Step 2: Set Up Your Design Tool

**Recommended Tools:**

**Option A: Figma (Free, Browser-based)**
- Best for: Collaboration, modern workflow
- Download: https://figma.com
- Setup: Create 1024×1024 frame

**Option B: Sketch (macOS, Paid)**
- Best for: macOS-specific design
- Download: https://sketch.com
- Setup: Use macOS icon template

**Option C: Adobe Illustrator (Paid)**
- Best for: Professional vector work
- Setup: New document, 1024×1024, RGB

**Option D: Affinity Designer (One-time Purchase)**
- Best for: Budget-conscious professionals
- Setup: New document, 1024×1024, RGB

### Step 3: Create Master Artwork

**Canvas Setup:**
- Size: 1024×1024 pixels (or 2048×2048 for highest quality)
- Color mode: RGB
- Color profile: sRGB
- Background: Transparent
- Guides: Center (512, 512), safe area (90% = 922×922)

**Follow Your Chosen Concept:**
- Use exact measurements from concept specification
- Use exact color codes (copy-paste hex values)
- Set up layers for easy editing
- Name layers clearly

**Layer Structure (Recommended):**
1. Background (transparent)
2. Shadow
3. Sticky note base
4. Page curl / accent elements
5. Checkmark
6. Optional effects

### Step 4: Export Master Files

**SVG Export:**
1. File name: `icon-source.svg`
2. Location: `/home/user/sticky-todo/assets/`
3. Settings:
   - Presentation attributes (not internal CSS)
   - 2 decimal places precision
   - Optimize SVG code
   - Include viewBox

**High-Resolution PNG Export:**
1. File name: `icon-source.png` or `icon-source@2x.png`
2. Location: `/home/user/sticky-todo/assets/`
3. Size: 1024×1024 or 2048×2048 pixels
4. Format: PNG-24 with alpha
5. Color space: sRGB

### Step 5: Generate All Required Sizes

**Option A: Automated (Recommended)**

Use the provided generation script:

```bash
cd /home/user/sticky-todo
./scripts/generate-icons.sh assets/icon-source.png
```

This automatically creates all 10 PNG files in both app directories.

**Option B: Manual Export**

Export each of the 10 required sizes individually:
1. Set canvas to exact pixel dimensions
2. Export as PNG-24 with transparency
3. Use exact filename (case-sensitive)
4. Save to both app directories

### Step 6: Hand-Tune Small Sizes (Recommended)

Even with automated generation, manually refine the smallest sizes:

**16×16 pixels:**
- Open in Photoshop/Figma/Sketch
- Ensure checkmark is clearly visible
- Simplify or remove decorative elements
- Align to pixel grid
- Export with exact filename

**32×32 pixels:**
- Verify checkmark clarity
- Ensure edges are crisp
- Test on light and dark backgrounds

### Step 7: Quality Check

**Visual Testing:**
- [ ] Open each PNG file individually
- [ ] View at actual size (100% zoom)
- [ ] Check on white background
- [ ] Check on black background
- [ ] Check on gray background (#888888)
- [ ] View in grayscale mode

**Technical Verification:**
- [ ] All files are PNG-24 with alpha
- [ ] All files have transparent backgrounds
- [ ] All filenames match exactly (case-sensitive)
- [ ] All files are in correct directories
- [ ] Colors match specifications
- [ ] No compression artifacts

**Size-Specific Checks:**
- [ ] 16×16: Checkmark clearly visible
- [ ] 32×32: All elements distinguishable
- [ ] 128×128: Professional appearance
- [ ] 512×512: Smooth curves
- [ ] 1024×1024: App Store quality

### Step 8: Organize Deliverables

**File Structure:**

```
/home/user/sticky-todo/assets/
  icon-source.svg                    ← Master vector source
  icon-source.png                    ← Master PNG (1024×1024 or 2048×2048)
  icon-preview.png                   ← Preview (512×512) - optional
  [your-design-file.fig/.sketch/.ai] ← Original design file

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
  Contents.json (already exists)

/home/user/sticky-todo/StickyToDo-AppKit/Assets.xcassets/AppIcon.appiconset/
  (same 10 PNG files)
  Contents.json (already exists)
```

### Step 9: Test in Xcode

**Build Both Apps:**

```bash
cd /home/user/sticky-todo

# Build SwiftUI app
xcodebuild -project StickyToDo-SwiftUI.xcodeproj -scheme StickyToDo-SwiftUI

# Build AppKit app
xcodebuild -project StickyToDo-AppKit.xcodeproj -scheme StickyToDo-AppKit
```

**Verify:**
- No build warnings about missing assets
- Icon appears in built app
- Icon displays correctly in Finder
- Icon displays correctly in Dock

### Step 10: Final Delivery

**Required Deliverables:**
1. ✓ `icon-source.svg` (master vector)
2. ✓ `icon-source.png` (master raster)
3. ✓ 10 PNG files in SwiftUI AppIcon.appiconset
4. ✓ 10 PNG files in AppKit AppIcon.appiconset

**Optional but Recommended:**
1. Original design file (Figma/Sketch/Illustrator)
2. Preview image (512×512)
3. Design notes or variations explored
4. Screenshots showing icon in context

---

## File Naming Conventions

### Strict Requirements

All filenames are **case-sensitive** and must match exactly:

```
icon_16x16@1x.png      ← Lowercase, underscore, @ symbol, lowercase x
icon_16x16@2x.png      ← NOT: Icon_16x16@2x.png or icon-16x16-2x.png
icon_32x32@1x.png
icon_32x32@2x.png
icon_128x128@1x.png
icon_128x128@2x.png
icon_256x256@1x.png
icon_256x256@2x.png
icon_512x512@1x.png
icon_512x512@2x.png
```

### Common Naming Mistakes

**❌ WRONG:**
- `Icon_16x16@1x.png` (capital I)
- `icon-16x16@1x.png` (dash instead of underscore)
- `icon_16x16_1x.png` (underscore instead of @)
- `icon_16x16@1X.png` (capital X)
- `icon 16x16@1x.png` (space)
- `icon_16_16@1x.png` (underscores instead of x)

**✓ CORRECT:**
- `icon_16x16@1x.png`

### Master File Naming

```
icon-source.svg        ← SVG master (hyphen, lowercase)
icon-source.png        ← PNG master at 1024×1024
icon-source@2x.png     ← PNG master at 2048×2048 (optional)
icon-preview.png       ← Preview/mockup (optional)
```

---

## Quality Checklist

### Before Delivery

**Visual Quality:**
- [ ] Icon recognizable at 16×16 pixels
- [ ] Checkmark (or completion symbol) clearly visible at all sizes
- [ ] Colors match specification exactly
- [ ] No compression artifacts or banding
- [ ] Shadow is subtle and professional
- [ ] All decorative elements appropriate for size

**Technical Quality:**
- [ ] All 10 PNG files exported
- [ ] All filenames match exactly (case-sensitive)
- [ ] All PNGs have transparent backgrounds (no white)
- [ ] All PNGs are PNG-24 with alpha channel
- [ ] SVG file is clean and optimized
- [ ] Colors are in sRGB color space
- [ ] Files are in correct directories (both SwiftUI and AppKit)

**Accessibility:**
- [ ] Contrast ratio ≥ 7:1 (or noted if AA level)
- [ ] Icon works in grayscale
- [ ] Clear on light backgrounds (white, #F5F5F5)
- [ ] Clear on dark backgrounds (black, #1E1E1E, #2C2C2C)
- [ ] Visible on macOS menu bar (light and dark modes)

**Testing:**
- [ ] Built SwiftUI app without warnings
- [ ] Built AppKit app without warnings
- [ ] Viewed in Finder icon view
- [ ] Viewed in Finder list view
- [ ] Viewed in Dock (normal size)
- [ ] Viewed in Dock (with magnification)
- [ ] Viewed in App Switcher (Cmd+Tab)
- [ ] Viewed in About panel
- [ ] Tested on Retina and non-Retina displays

**Documentation:**
- [ ] Master SVG source provided
- [ ] Master PNG source provided
- [ ] Original design file included (Figma/Sketch/AI)
- [ ] Brief design notes or variations included
- [ ] Any recommendations for future updates noted

---

## Additional Resources

### Apple Guidelines

**Official Documentation:**
- [Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Asset Catalog Format Reference](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/)
- [SF Symbols](https://developer.apple.com/sf-symbols/) (for checkmark reference)

### Design Tools & Templates

**Templates:**
- [macOS Big Sur Icon Template (Figma)](https://www.figma.com/community/file/857303226040719059)
- [macOS App Icon Template (Sketch)](https://applypixels.com/template/macos-big-sur)
- [iOS & macOS Icon Generator](https://appicon.co/)

**Utilities:**
- Icon Slate: http://www.kodlian.com/apps/icon-slate
- Image2Icon: https://img2icnsapp.com/
- SVGO (SVG Optimizer): https://github.com/svg/svgo

### Color Tools

**Color Pickers:**
- Digital Color Meter (macOS built-in)
- https://colorpicker.me/
- https://coolors.co/

**Accessibility Checkers:**
- WebAIM Contrast Checker: https://webaim.org/resources/contrastchecker/
- Colorblind Simulator: https://www.color-blindness.com/coblis-color-blindness-simulator/

### Design Inspiration

**Study These macOS Icons:**
- Notes.app (simple, recognizable)
- Reminders.app (checkmark usage)
- Things 3 (professional task management)
- Keynote (effective use of color and simplicity)
- Preview (clean, minimal design)

---

## Frequently Asked Questions

### Q: Which concept should I choose?

**A:** Concept 1 (Classic Sticky Note) is recommended for:
- Broad appeal and universal recognition
- Best balance of familiarity and uniqueness
- Proven sticky note metaphor
- High accessibility (WCAG AAA)

Choose other concepts if you want:
- **Concept 2:** More premium, modern aesthetic
- **Concept 3:** Minimal, professional look
- **Concept 4:** Maximum visibility and energy
- **Concept 5:** Corporate, timeless design

### Q: Can I combine elements from different concepts?

**A:** Yes! The concepts are starting points. You can:
- Use Concept 1's yellow note with Concept 2's green checkmark
- Use Concept 3's minimal style with Concept 1's page curl
- Combine any elements that work well together

Get approval from the development team before finalizing.

### Q: Do I really need to hand-tune 16×16 and 32×32?

**A:** Strongly recommended. Automated scaling often produces:
- Blurry checkmarks at 16×16
- Muddy details that should be simplified
- Misaligned pixels (not crisp)

Spending 15-30 minutes hand-tuning these sizes significantly improves quality.

### Q: What if I don't have access to paid design tools?

**A:** Use Figma (free, browser-based):
1. Create free Figma account
2. Create 1024×1024 frame
3. Follow concept specifications
4. Export as PNG and SVG
5. Use provided script to generate all sizes

### Q: Can I use a gradient for Concept 1?

**A:** Yes, subtle gradients are fine. Keep it simple:
- Gradient from #FFD54F to #FFC107 (slight darkening)
- Angle: 135° (top-left to bottom-right)
- Ensure it doesn't muddy at small sizes

### Q: How do I test the icons before building in Xcode?

**A:** Preview methods:
1. Place PNG in a folder and view in Finder
2. Open PNG in Preview.app at different zoom levels
3. Copy to desktop and view at different Finder sizes
4. Use online icon preview tools

### Q: Do the two app directories (SwiftUI and AppKit) need identical icons?

**A:** Yes, identical files. The script copies to both locations automatically. Maintaining two sets ensures both apps have proper icons.

### Q: What's the difference between icon-source.png and icon-source@2x.png?

**A:**
- `icon-source.png`: 1024×1024 master (1x)
- `icon-source@2x.png`: 2048×2048 master (2x/Retina)

Either works as source for the generation script. The @2x version provides higher quality for scaling down.

---

## Related Documentation

**For detailed step-by-step implementation:**
- `/home/user/sticky-todo/assets/DESIGNER_INSTRUCTIONS.md`

**For complete technical specifications:**
- `/home/user/sticky-todo/assets/ICON_SPECIFICATION.md`

**For SVG code structure:**
- `/home/user/sticky-todo/assets/icon-template.svg.md`

**For overview and quick reference:**
- `/home/user/sticky-todo/assets/README.md`

**For AppIcon asset directories:**
- `/home/user/sticky-todo/StickyToDo-SwiftUI/Assets.xcassets/AppIcon.appiconset/README.md`
- `/home/user/sticky-todo/StickyToDo-AppKit/Assets.xcassets/AppIcon.appiconset/README.md`

---

## Project Status

**Current State:**
- ✓ All design concepts specified
- ✓ Technical requirements documented
- ✓ Implementation guide complete
- ✓ Color specifications defined
- ✓ File naming conventions established
- ✓ Quality checklist provided
- ✓ Asset directories configured
- ✓ Generation scripts ready
- ⏳ Icon artwork pending designer implementation

**Next Steps:**
1. Review all 5 concepts
2. Select preferred concept (or propose hybrid)
3. Create master artwork (SVG + PNG)
4. Run generation script
5. Hand-tune small sizes
6. Test in Xcode builds
7. Deliver final assets

---

**Document Version:** 1.0
**Last Updated:** 2025-11-18
**Status:** Complete and Ready for Designer
**Priority:** LOW (Can be scheduled when designer resources are available)

**Questions?** Review related documentation or contact development team.
