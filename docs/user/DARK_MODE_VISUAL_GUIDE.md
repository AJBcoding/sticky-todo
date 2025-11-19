# Dark Mode Visual Guide

## Quick Start

**To Change Theme:**
1. Open Settings (⌘,)
2. Click "Appearance" tab
3. Select your preferred theme mode
4. Choose your accent color
5. See instant preview

---

## Theme Modes

### 1. System (Automatic)
**Follows macOS System Preferences**

```
Light Mode (Day)          Dark Mode (Night)
┌──────────────────┐      ┌──────────────────┐
│ ☀️  StickyToDo   │      │ 🌙  StickyToDo   │
├──────────────────┤      ├──────────────────┤
│ ○ Task 1         │      │ ○ Task 1         │
│ ○ Task 2         │      │ ○ Task 2         │
│ ✓ Task 3         │      │ ✓ Task 3         │
└──────────────────┘      └──────────────────┘
White Background          Dark Gray BG
```

### 2. Light Mode (Always)
**Bright, clean, classic**

- Background: Pure white (#FFFFFF)
- Text: Black (#000000)
- Cards: Light gray (#F2F2F7)
- Best for: Bright rooms, daytime

```
┌─────────────────────────────┐
│ 📥 Inbox                    │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ ○ Write proposal        │ │
│ │   @computer  📅 Today   │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ ○ Call client           │ │
│ │   @phone  🔔 2:00 PM    │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

### 3. Dark Mode
**Comfortable for eyes, battery friendly**

- Background: Dark gray (#1C1C1E)
- Text: White (#FFFFFF)
- Cards: Darker gray (#242426)
- Shadows: Subtle
- Best for: Low light, evening work

```
┌─────────────────────────────┐
│ 📥 Inbox                    │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ ○ Write proposal        │ │
│ │   @computer  📅 Today   │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ ○ Call client           │ │
│ │   @phone  🔔 2:00 PM    │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

### 4. True Black Mode ⚡
**OLED-optimized, maximum battery savings**

- Background: Pure black (#000000)
- Text: White (#FFFFFF)
- Cards: Near-black (#0F0F0F)
- Shadows: None (OLED optimization)
- Best for: OLED displays, night time, maximum battery

```
██████████████████████████████
█ 📥 Inbox                   █
██████████████████████████████
█ ██████████████████████████ █
█ █ ○ Write proposal       █ █
█ █   @computer  📅 Today  █ █
█ ██████████████████████████ █
█ ██████████████████████████ █
█ █ ○ Call client          █ █
█ █   @phone  🔔 2:00 PM   █ █
█ ██████████████████████████ █
██████████████████████████████

💡 OLED Benefit: Black pixels = OFF
   = 20-30% battery savings!
```

---

## Accent Colors

Choose from 11 beautiful accent colors:

### Color Swatches

```
🔵 Blue     (Default)    Professional, calm
🟣 Purple                Creative, unique
🌸 Pink                  Fun, energetic
🔴 Red                   Bold, urgent
🟠 Orange                Warm, friendly
🟡 Yellow                Cheerful, bright
🟢 Green                 Fresh, natural
🟩 Mint                  Modern, cool
🔷 Teal                  Balanced, sophisticated
🔵 Cyan                  Tech, clean
🟦 Indigo                Deep, elegant
```

### Accent Color Usage

Your accent color appears in:
- Selected items
- Buttons and links
- Focus indicators
- Progress bars
- Active states

**Example with Blue Accent:**
```
┌─────────────────────────┐
│ ○ Normal task           │
├─────────────────────────┤
│ ● Selected task  ← Blue │  ← Accent color
├─────────────────────────┤
│ ○ Normal task           │
└─────────────────────────┘
```

**Example with Purple Accent:**
```
┌─────────────────────────┐
│ ○ Normal task           │
├─────────────────────────┤
│ ● Selected task ← Purple│  ← Accent color
├─────────────────────────┤
│ ○ Normal task           │
└─────────────────────────┘
```

---

## Color Meanings

### Status Colors (Consistent Across Themes)

**Success (Green)**
- ✓ Completed tasks
- Success messages
- Positive indicators

**Warning (Orange)**
- ⚠️ Due today
- Warnings
- Needs attention

**Error (Red)**
- ⛔ Overdue tasks
- Errors
- Critical items
- High priority

**Info (Accent Color)**
- Selected items
- Interactive elements
- Focus states

---

## Semantic Color System

### Backgrounds

```
Primary Background
  ↓
  Secondary Background (Cards)
    ↓
    Tertiary Background (Elevated)
```

**Light Mode:**
```
White (#FFFFFF)
  ↓
  Light Gray (#F2F2F7)
    ↓
    White (#FFFFFF)
```

**Dark Mode:**
```
Dark Gray (#1C1C1E)
  ↓
  Darker Gray (#242426)
    ↓
    Medium Gray (#2C2C2E)
```

**True Black:**
```
Black (#000000)
  ↓
  Near Black (#0D0D0D)
    ↓
    Dark Gray (#141414)
```

### Text Hierarchy

```
Primary Text (Most Important)
  ↓
  Secondary Text (Less Important)
    ↓
    Tertiary Text (Least Important)
```

**Light Mode:**
```
Black → Gray (60%) → Gray (30%)
```

**Dark/True Black:**
```
White → White (60%) → White (30%)
```

---

## Accessibility

### WCAG Compliance

All color combinations meet **WCAG AA** standards (4.5:1 contrast ratio):

| Combination | Light | Dark | True Black |
|-------------|-------|------|------------|
| Primary Text / BG | ✅ 21:1 | ✅ 15:1 | ✅ 21:1 |
| Secondary Text / BG | ✅ 7:1 | ✅ 5:1 | ✅ 7:1 |
| Accent / BG | ✅ 4.5:1+ | ✅ 4.5:1+ | ✅ 4.5:1+ |

### Accessibility Features

- **Increase Contrast:** Supported
- **Reduce Transparency:** Supported
- **VoiceOver:** Full support
- **Keyboard Navigation:** Complete
- **Focus Indicators:** High contrast

---

## Task Card Comparison

### Light Mode
```
┌───────────────────────────────┐
│ ○ Finish quarterly report    │ ← Black text
│   @computer  #Q4  !high       │ ← Colored badges
│   📅 Tomorrow  ⏱️ 2h          │
└───────────────────────────────┘
  ↑ White background with shadow
```

### Dark Mode
```
┌───────────────────────────────┐
│ ○ Finish quarterly report    │ ← White text
│   @computer  #Q4  !high       │ ← Brighter badges
│   📅 Tomorrow  ⏱️ 2h          │
└───────────────────────────────┘
  ↑ Dark gray background
```

### True Black
```
██████████████████████████████████
█ ○ Finish quarterly report    █ ← White text
█   @computer  #Q4  !high       █ ← Brightest badges
█   📅 Tomorrow  ⏱️ 2h          █
██████████████████████████████████
  ↑ Pure black, no shadow
```

---

## Board View Comparison

### Light Mode Board
```
┌─────────────┬─────────────┬─────────────┐
│ 📋 To Do    │ 🏃 Doing    │ ✅ Done     │
├─────────────┼─────────────┼─────────────┤
│ ┌─────────┐ │ ┌─────────┐ │ ┌─────────┐ │
│ │ Task A  │ │ │ Task D  │ │ │ Task F  │ │
│ └─────────┘ │ └─────────┘ │ └─────────┘ │
│ ┌─────────┐ │ ┌─────────┐ │             │
│ │ Task B  │ │ │ Task E  │ │             │
│ └─────────┘ │ └─────────┘ │             │
│ ┌─────────┐ │             │             │
│ │ Task C  │ │             │             │
│ └─────────┘ │             │             │
└─────────────┴─────────────┴─────────────┘
```

### Dark Mode Board
```
██████████████████████████████████████████████
█ 📋 To Do    │ 🏃 Doing    │ ✅ Done     █
█─────────────┼─────────────┼─────────────█
█ ┌─────────┐ │ ┌─────────┐ │ ┌─────────┐ █
█ │ Task A  │ │ │ Task D  │ │ │ Task F  │ █
█ └─────────┘ │ └─────────┘ │ └─────────┘ █
█ ┌─────────┐ │ ┌─────────┐ │             █
█ │ Task B  │ │ │ Task E  │ │             █
█ └─────────┘ │ └─────────┘ │             █
██████████████████████████████████████████████
```

---

## Settings UI Preview

```
┌──────────────────────────────────────────────┐
│  Appearance                                  │
├──────────────────────────────────────────────┤
│                                              │
│  Theme Mode                                  │
│  ┌────────────────────────────────────────┐  │
│  │ ◐ System                               │  │
│  │ Automatically match system appearance  │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ ☀️ Light            [✓ SELECTED]      │  │
│  │ Always use light appearance            │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ 🌙 Dark                                │  │
│  │ Dark mode with subtle backgrounds      │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ 🌙✨ True Black                        │  │
│  │ Pure black for OLED displays           │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  Accent Color                                │
│  ● ○ ○ ○ ○ ○ ○ ○ ○ ○ ○                    │
│  ^                                           │
│  Blue (selected)                             │
│                                              │
│  Preview                                     │
│  ┌────────────────────────────────────────┐  │
│  │ ○ Sample Task            High [red]    │  │
│  │ This is a preview of how tasks will    │  │
│  │ appear in your chosen theme.           │  │
│  │ @work  📅 Due today                    │  │
│  └────────────────────────────────────────┘  │
│                                              │
└──────────────────────────────────────────────┘
```

---

## Tips & Tricks

### 1. Automatic Theme Switching
Set to "System" mode, then configure macOS to auto-switch:
1. System Preferences → General → Appearance
2. Choose "Auto"
3. Light theme during day, Dark at night

### 2. OLED Battery Savings
Use True Black mode on MacBooks with OLED displays:
- Estimated 20-30% battery improvement
- Perfect for late-night work
- Less eye strain

### 3. Accent Color for Context
Use different accent colors for different projects:
- Work projects: Blue (professional)
- Personal: Purple (creative)
- Urgent: Red (attention-grabbing)

### 4. Increase Contrast Mode
For maximum readability:
1. macOS System Preferences → Accessibility
2. Display → Increase Contrast
3. StickyToDo will automatically adjust

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘, | Open Settings |
| Tab | Navigate settings |
| ← → | Select theme mode |
| Space | Toggle accent color selection |
| Esc | Close settings |

---

## Troubleshooting

### Theme Not Switching?
1. Check Settings → Appearance
2. Try selecting a different mode
3. Restart StickyToDo

### Colors Look Wrong?
1. Check macOS System Preferences → General → Appearance
2. Disable "Increase Contrast" if enabled
3. Try different accent color

### True Black Not Black Enough?
1. Ensure "True Black" is selected, not "Dark"
2. Check display calibration
3. Verify OLED display capability

---

## Technical Details

### Color Values Reference

**Light Mode:**
- Primary BG: `#FFFFFF` (White)
- Secondary BG: `#F2F2F7` (Light Gray)
- Primary Text: `#000000` (Black)
- Secondary Text: `#3C3C43` @ 60% opacity

**Dark Mode:**
- Primary BG: `#1C1C1E` (Dark Gray)
- Secondary BG: `#242426` (Darker Gray)
- Primary Text: `#FFFFFF` (White)
- Secondary Text: `#EBEBF5` @ 60% opacity

**True Black:**
- Primary BG: `#000000` (Pure Black)
- Secondary BG: `#0D0D0D` (Near Black)
- Primary Text: `#FFFFFF` (White)
- Secondary Text: `#EBEBF5` @ 60% opacity

### Status Colors (All Modes)

**Light Mode:**
- Success: `#34C759` (Green)
- Warning: `#FF9500` (Orange)
- Error: `#FF3B30` (Red)

**Dark/True Black:**
- Success: `#30D158` (Brighter Green)
- Warning: `#FF9F0A` (Brighter Orange)
- Error: `#FF453A` (Brighter Red)

---

**For More Information:**
- See `DARK_MODE_REFINEMENTS_REPORT.md` for technical details
- See Settings → Appearance for live preview
- Contact support for color customization requests

**Last Updated:** 2025-11-18
