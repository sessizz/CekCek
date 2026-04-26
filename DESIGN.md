---
name: CekCek
colors:
  # Brand
  accent: "#2C6BE6"
  accent-dark: "#6199FA"
  accent-subtle: "rgba(44, 107, 230, 0.12)"
  accent-muted: "rgba(44, 107, 230, 0.15)"
  accent-shadow: "rgba(44, 107, 230, 0.40)"

  # Text hierarchy (iOS system semantic)
  on-accent: "#FFFFFF"
  text-primary: "#000000"
  text-secondary: "#3C3C4399"   # ~60 % opacity
  text-tertiary: "#3C3C434D"    # ~30 % opacity

  # Surfaces
  background: "#F2F2F7"         # systemGroupedBackground
  surface: "#FFFFFF"            # secondarySystemGroupedBackground
  surface-elevated: "#FFFFFF"
  surface-material: "rgba(242,242,247,0.85)"  # .regularMaterial approx

  # Semantic
  destructive: "#FF3B30"
  complete: "#34C759"
  warning: "#FF9500"

  # Borders / strokes
  outline: "rgba(0,0,0,0.05)"
  outline-subtle: "rgba(60,60,67,0.18)"
  progress-track: "rgba(60,60,67,0.15)"

typography:
  # SF Pro Rounded — wordmark only
  logo:
    fontFamily: SF Pro Rounded
    fontSize: 18px
    fontWeight: "600"
    letterSpacing: -0.3px

  # SF Pro — primary content
  row-title:
    fontFamily: SF Pro
    fontSize: 16px
    fontWeight: "500"
    lineHeight: 21px

  row-subtitle:
    fontFamily: SF Pro
    fontSize: 13px
    fontWeight: "400"
    lineHeight: 18px

  detail-title:
    fontFamily: SF Pro
    fontSize: 22px
    fontWeight: "700"
    lineHeight: 28px

  detail-subtitle:
    fontFamily: SF Pro
    fontSize: 15px
    fontWeight: "400"
    lineHeight: 20px

  item-text:
    fontFamily: SF Pro
    fontSize: 16px
    fontWeight: "400"
    lineHeight: 21px

  badge-count:
    fontFamily: SF Pro
    fontSize: 13px
    fontWeight: "600"
    lineHeight: 18px

  stat-value:
    fontFamily: SF Pro
    fontSize: 28px
    fontWeight: "700"
    lineHeight: 34px
    fontVariant: monospacedDigit

  stat-label:
    fontFamily: SF Pro
    fontSize: 12px
    fontWeight: "500"
    lineHeight: 16px

  caption:
    fontFamily: SF Pro
    fontSize: 12px
    fontWeight: "400"
    lineHeight: 16px

  section-header:
    fontFamily: SF Pro
    fontSize: 15px
    fontWeight: "600"
    lineHeight: 20px

  checkmark-glyph:
    fontFamily: SF Pro
    fontSize: 11px
    fontWeight: "700"

  toolbar-icon:
    fontFamily: SF Symbols
    fontSize: 17px
    fontWeight: "500"

spacing:
  unit: 4px          # base atom
  xs: 3px
  sm: 8px
  md: 10px
  lg: 12px
  xl: 16px
  2xl: 18px
  3xl: 20px

  # Semantic aliases
  row-vertical: 4px
  row-icon-gap: 12px
  row-trailing-gap: 10px
  badge-h: 8px
  badge-v: 3px
  title-stack: 3px
  detail-header-v: 8px
  detail-title-lead: 10px
  detail-header-stack: 12px
  floating-inner-h: 18px
  floating-inner-v: 10px
  floating-outer-h: 16px
  floating-outer-bottom: 8px
  picker-grid-gap: 8px
  picker-section-gap: 20px

rounded:
  icon-badge: 9px
  picker-cell: 9px
  status-banner: 14px
  stat-card: 18px
  floating-bar: 26px
  badge-pill: 9999px
  checkbox: 9999px    # full circle
  progress-ring: 9999px

elevation:
  # Floating add bar
  bar:
    color: "rgba(0,0,0,0.08)"
    radius: 16px
    x: 0
    y: 6px
  # Accent action button (+ circle)
  action-button:
    color: "rgba(44,107,230,0.40)"
    radius: 8px
    x: 0
    y: 4px
  # Cloud status banner
  banner:
    color: "rgba(0,0,0,0.06)"
    radius: 10px
    x: 0
    y: 2px

motion:
  # Checkbox ring fills
  checkbox-fill:
    easing: easeInOut
    duration: 180ms
  # Checkmark pop in/out
  checkmark-spring:
    type: spring
    response: 220ms
    dampingFraction: 0.6
  # Item row text fades / strikethrough
  item-toggle:
    easing: easeInOut
    duration: 200ms
  # Progress ring arc
  progress-ring:
    easing: easeInOut
    duration: 300ms
  # Linear progress fill
  progress-bar:
    type: spring
    response: 350ms
    dampingFraction: 0.7
  # Stats numeric counter
  stat-counter:
    type: spring
    response: 300ms

components:
  # Rounded icon badge (checklist row)
  icon-badge:
    size: 36px
    backgroundColor: "{colors.accent}"
    iconColor: "{colors.on-accent}"
    iconSize: 17px
    iconWeight: "500"
    rounded: "{rounded.icon-badge}"
  # Emoji icon badge (no tinted background)
  icon-badge-emoji:
    size: 36px
    backgroundColor: transparent
    fontSize: 28px
    rounded: "{rounded.icon-badge}"
  # Animated checkbox
  checkbox:
    size: 26px
    borderWidth: 1.8px
    borderColor-unchecked: "rgba(60,60,67,0.35)"
    borderColor-checked: "{colors.accent}"
    fill-checked: "{colors.accent}"
    checkmarkSize: 11px
    checkmarkColor: "{colors.on-accent}"
    rounded: "{rounded.checkbox}"
  # Remaining-count pill badge
  badge-remaining:
    backgroundColor: "{colors.accent-subtle}"
    textColor: "{colors.accent}"
    typography: "{typography.badge-count}"
    paddingH: "{spacing.badge-h}"
    paddingV: "{spacing.badge-v}"
    rounded: "{rounded.badge-pill}"
  # Progress ring (list row)
  progress-ring-row:
    size: 26px
    lineWidth: 4px
    trackColor: "rgba(0,0,0,0.12)"
    fillColor: "{colors.accent}"
    fillColor-complete: "{colors.complete}"
  # Progress ring (detail header)
  progress-ring-detail:
    size: 52px
    lineWidth: 5px
    trackColor: "rgba(0,0,0,0.12)"
    fillColor: "{colors.accent}"
    fillColor-complete: "{colors.complete}"
  # Horizontal progress bar
  progress-bar:
    height: 6px
    trackColor: "{colors.progress-track}"
    fillColor: "{colors.accent}"
    rounded: "{rounded.badge-pill}"
  # Floating quick-add bar
  floating-add-bar:
    backgroundColor: "{colors.surface-material}"
    rounded: "{rounded.floating-bar}"
    paddingH: "{spacing.floating-inner-h}"
    paddingV: "{spacing.floating-inner-v}"
    borderColor: "{colors.outline}"
    borderWidth: 0.5px
    shadow: "{elevation.bar}"
  # Floating + circle button
  action-button:
    size: 40px
    backgroundColor: "{colors.accent}"
    iconColor: "{colors.on-accent}"
    iconSize: 16px
    iconWeight: "600"
    rounded: "{rounded.checkbox}"
    shadow: "{elevation.action-button}"
  # Icon picker cell
  picker-cell:
    size: 44px
    rounded: "{rounded.picker-cell}"
    selectedBackground: "{colors.accent-muted}"
    selectedBorder: "{colors.accent}"
    selectedBorderWidth: 2px
    selectedIconColor: "{colors.accent}"
    unselectedIconColor: "{colors.text-primary}"
---

## Brand & Style

CekCek is a native iOS and macOS maintenance checklist app for RV and caravan owners. The interface language is **clean, purposeful, and calm** — inspired by Apple's Human Interface Guidelines while adding a distinctive brand accent.

The single brand colour — a confident cornflower blue (`#2C6BE6`, lighter at `#6199FA` in dark mode) — does all the expressive work. Everything else defers to system neutrals, giving the UI a "first-party" feel while the blue punctuates interactive affordances, progress, and completion states. The wordmark "**çek**<span style="color:#2C6BE6">**çek**" splits the app name into two weights: the first in system primary, the second in accent blue, making the logo a micro-demonstration of the whole colour system.

There are no custom backgrounds, no decorative gradients, and no heavy illustration. Depth comes exclusively from iOS system materials (`.regularMaterial`, `.thinMaterial`) and two carefully scoped drop shadows.

---

## Colors

**Accent blue** is the only non-system colour.  It appears on:

- Icon badges (filled rounded square)
- Checkbox circle when ticked
- Progress ring arc and linear progress fill
- Remaining-count pill badge (at 12 % opacity for background, full for text)
- The floating `+` action button
- Swipe-action edit button
- The second half of the wordmark

**System semantic colours** are used everywhere else — `.primary`, `.secondary`, `.tertiary` for text; `systemGroupedBackground` / `secondarySystemGroupedBackground` for the page / card layering; and `.regularMaterial` for the floating bottom bar, so it adapts to both light and dark mode without any conditional logic.

**Semantic overrides:**
- Completion state → system green (`#34C759`)
- Destructive actions → system red (`#FF3B30`)
- CloudKit sync warning → system orange (`#FF9500`)

---

## Typography

The entire app uses **SF Pro** (the system typeface) with no custom font loading. The only exception is the two-word logo, which uses the **SF Pro Rounded** variant for a slightly softer, more playful terminal style.

**Hierarchy in practice:**

| Role | Size | Weight |
|---|---|---|
| Detail page title | 22 pt | Bold |
| Row title | 16 pt | Medium |
| Item text | 16 pt | Regular |
| Row subtitle / metadata | 13 pt | Regular |
| Badge count | 13 pt | Semibold |
| Section header | 15 pt | Semibold |
| Stat value | 28 pt | Bold, monospaced digits |
| Stat label | 12 pt | Medium |
| Checkmark glyph | 11 pt | Bold |

Strikethrough is applied to completed checklist items at reduced opacity (`.secondary`), providing a clear "done" state without removing content from view.

---

## Layout & Spacing

The spacing scale uses **4 pt as the base atom**, with the majority of values landing on 4, 8, 10, 12, 16, 18, 20. No value in the production UI exceeds 26 pt (the floating bar's `cornerRadius`).

**List rows** follow a fixed anatomy:
- 36 × 36 icon badge — corner radius 9
- 12 pt gap to text column
- Text column (title 16 pt / subtitle 13 pt, 3 pt apart)
- `Spacer()`
- Trailing cluster: remaining-count pill + 10 pt gap + 26 pt progress ring

**Detail header** sits in a `Section` with a hidden separator. It stacks:
1. 52 pt progress ring + title column side-by-side (12 pt VStack)
2. 6 pt linear progress bar spanning full width

**Floating add bar** is docked above the safe-area bottom inset using `safeAreaInset(edge: .bottom)`. Its pill shape (cornerRadius 26) and `.regularMaterial` background mean it floats visually above the list without obscuring content.

---

## Elevation & Depth

Two shadows exist in the entire system:

1. **Floating add bar** — large, diffused: `y +6, blur 16, rgba(0,0,0,0.08)`. Barely perceptible; conveys "floating" without weight.
2. **Accent action button** — coloured: `y +4, blur 8, rgba(44,107,230,0.40)`. The blue tint on the shadow reinforces brand identity and prevents the shadow from reading as "dirty grey".

All other depth cues are tonal: the grouped-background / white-card iOS layering system handles the page-vs-content separation automatically.

---

## Shapes

| Element | Corner radius | Rationale |
|---|---|---|
| Icon badge (36 × 36) | 9 pt | iOS app-icon proportion at small size |
| Icon picker cell (44 × 44) | 9 pt | Matches icon badge |
| CloudKit status banner | 14 pt | Soft card feel |
| Stat card | 18 pt | Generous rounding for a data chip |
| Floating add bar | 26 pt | Full-pill proportion at ~56 pt height |
| Remaining-count badge | 9999 pt (capsule) | Fully adaptive to digit count |
| Checkbox / + button | 9999 pt (circle) | Pure circles |
| Progress bar | 9999 pt (capsule) | Continuous tapered fill |

The vocabulary is deliberately narrow: two functional radii (9 and 26) handle almost all interactive surfaces.

---

## Motion

Animation is additive and brief. Nothing exceeds 350 ms. Springs are preferred over duration-based curves for state transitions because they feel physically grounded.

| Moment | Curve | Timing |
|---|---|---|
| Checkbox ring fills with colour | easeInOut | 180 ms |
| Checkmark pops in / scales out | spring (resp 220 ms, damp 0.6) | — |
| Item text fades / gains strikethrough | easeInOut | 200 ms |
| Progress ring arc grows | easeInOut | 300 ms |
| Linear progress fill advances | spring (resp 350 ms, damp 0.7) | — |
| Stat value rolls | spring (resp 300 ms) | — |

The checkmark spring (`dampingFraction: 0.6`) intentionally undershoots slightly, giving the icon a brief "bounce" that makes checking off a task feel satisfying without being cartoonish.

---

## Components

### Checklist Row

The row combines three visual systems: the icon badge (identity), the text column (status), and the trailing cluster (urgency). The remaining-count pill is only shown when tasks remain; it disappears entirely on completion, replaced by a solid green progress ring.

### Animated Checkbox

The checkbox is a custom `ZStack` of two `Circle` layers — a stroke ring and a fill — animated independently. The ring changes colour first (easeInOut, 180 ms), then the fill follows at the same pace. The SF Symbols checkmark scales from 0 → 1 on a spring, creating a tactile "click" sensation. On uncheck, the sequence reverses.

### Floating Add Bar

The bar serves dual purpose: a direct-entry text field (type → Return to add instantly) and a `+` button that opens the full sheet for richer input. The field uses `.submitLabel(.done)` so the keyboard shows a prominent "Done" key. The bar never dismisses the keyboard after a quick-add, enabling rapid sequential entry.

### Progress Ring

A thin `Circle` stroke in `.quaternary` (system near-invisible) forms the track. The progress arc uses a separate `Circle` stroke with `.lineCap(.round)` trimmed from `0` to `progress`. At 100 %, the colour transitions to system green and a checkmark SF Symbol fades in at the centre.

### Icon System

Icons are stored as a single `String` field (`iconName`) that holds either an SF Symbols name or a Unicode emoji character. Detection is via a scalar-value check (`unicodeScalars.contains { $0.value > 127 }`). SF Symbol icons render white on the accent-blue badge. Emoji icons render at 28 pt on a transparent background — no badge frame — so their inherent colour palette shows through.

### Icon Picker

A `LazyVGrid` with 6 equal flexible columns, divided into `GroupBox` sections: SF Symbols (4 thematic categories, 48 icons) and Emoji (4 categories, 64 characters). Selected cells gain an accent-tinted background and a 2 pt accent border with no fill change on the icon itself, keeping the SF Symbol its natural colour while indicating selection.
