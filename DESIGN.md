---
name: HabitAI
description: Habit tracking with an AI coach — warm, encouraging, never a drill sergeant.
colors:
  primary: "#00668A"
  primary-container: "#38BDF8"
  primary-fixed: "#C4E7FF"
  primary-fixed-dim: "#7BD0FF"
  secondary: "#006591"
  secondary-container: "#39B8FD"
  tertiary: "#855300"
  tertiary-container: "#F59E0B"
  error: "#BA1A1A"
  error-container: "#FFDAD6"
  surface: "#F8F9FF"
  surface-container-lowest: "#FFFFFF"
  surface-container-low: "#EFF4FF"
  surface-container: "#E5EEFF"
  surface-container-high: "#DCE9FF"
  surface-container-highest: "#D3E4FE"
  surface-dim: "#CBDBF5"
  on-surface: "#0B1C30"
  on-surface-variant: "#3E484F"
  outline: "#6E7980"
  outline-variant: "#BDC8D1"
  dark-surface: "#0F1620"
  dark-surface-container-low: "#141D28"
  dark-on-surface: "#E2E8F0"
typography:
  display:
    fontFamily: "Manrope, system-ui, sans-serif"
    fontSize: "56px"
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: "-1.12px"
  headline:
    fontFamily: "Manrope, system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "normal"
  title:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "normal"
  body:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  label:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "0.6px"
rounded:
  sm: "8px"
  md: "20px"
  lg: "24px"
  xl: "32px"
  xxl: "36px"
  full: "999px"
spacing:
  xs: "6px"
  sm: "10px"
  md: "18px"
  lg: "20px"
  xl: "24px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface-container-lowest}"
    typography: "{typography.title}"
    rounded: "{rounded.full}"
    height: "56px"
  button-outlined:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    rounded: "{rounded.full}"
    height: "56px"
  card:
    backgroundColor: "{colors.surface-container-lowest}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "20px"
  input:
    backgroundColor: "{colors.surface-container-highest}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "18px 20px"
  chip:
    backgroundColor: "{colors.surface-container-highest}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: "6px 10px"
---

# Design System: HabitAI

## 1. Overview

**Creative North Star: "Editorial Vitality"**

HabitAI feels like a thoughtful friend who happens to keep beautiful notes. The system pairs an editorial display voice (Manrope, set large and tightly tracked) with a calm, layered field of sky-tinted surfaces. Color is mostly held back so that when a streak amber or a hero teal gradient appears, it reads as a small reward, not as decoration. Depth comes from stacking near-white surfaces in faint blue steps, never from hard rules or heavy shadows. The result is a surface that is quiet at rest and warm in the moments that matter.

The register is product: the interface serves a sub-two-minute daily ritual of logging a habit or a mood. Every choice favors earned familiarity over surprise. Buttons are full pills, cards are generously rounded rectangles, fields are soft filled wells. Nothing reinvents a standard affordance for flavor. The aesthetic explicitly rejects the four anti-references in PRODUCT.md: it is not a corporate productivity tool (no Jira chrome), not clinical (no Apple Health sterility), not aggressively gamified (no Duolingo pressure), and not a diary (no journal or paper metaphors).

The most distinctive structural decision is the refusal of the 1px hard border. Separation between layers is carried entirely by tonal surface shifts (`surface` → `surface-container-low` → `surface-container-lowest`) and a soft ambient shadow reserved for genuine elevation. Where a border-like seam is unavoidable, it is a ghost line at 15% opacity, never a visible stroke.

**Key Characteristics:**
- Dual typography: Manrope for display and headlines, Inter for everything functional.
- Sky-tinted neutral system: every surface and text neutral leans toward the brand blue, never pure gray.
- Generous, consistent radii (24px cards, 32px dialogs, 36px sheets, full-pill buttons).
- Color as reward: teal hero gradient and streak amber appear sparingly, against a restrained field.
- No hard borders: depth via tonal surface layering and ambient shadow only.

## 2. Colors

A restrained, sky-tinted system: one serious teal anchor, one luminous sky for moments of energy, an amber reserved for achievement, and a full ladder of blue-tinted neutrals that does the structural work.

### Primary
- **Deep Harbor Teal** (#00668A): The serious, trustworthy anchor. Primary actions, current selection, focus accents, FAB, active nav label. This is the *real* primary in the running app, deeper than the brand's nominal sky blue.
- **Sky** (#38BDF8): The luminous companion (`primary-container`). The bright end of the hero gradient, selected-state tints, highlight surfaces. This is the color the brand thinks of as "the blue"; here it plays the energetic foil to Deep Harbor.
- **Frost** (#C4E7FF / #7BD0FF): `primary-fixed` pair. Soft container fills and on-dark accents.

### Secondary
- **Signal Blue** (#006591 / #39B8FD): Supporting interactive accents and secondary emphasis where primary would over-saturate.

### Tertiary
- **Streak Amber** (#F59E0B, with deep #855300): Reserved almost exclusively for streaks, achievements, and gamification highlights. When amber appears, something was earned.

### Neutral
- **Ink** (#0B1C30): Primary text and headlines. A near-black tinted toward navy, never #000.
- **Slate** (#3E484F): Secondary text, body-medium, captions (`on-surface-variant`).
- **Outline / Outline Variant** (#6E7980 / #BDC8D1): Dividers and ghost seams only, always at low opacity.
- **Surface ladder** (#F8F9FF → #EFF4FF → #E5EEFF → #DCE9FF → #D3E4FE, plus pure-white `surface-container-lowest` #FFFFFF and dim #CBDBF5): The layering vocabulary. Cards sit on `surface-container-lowest` above the `surface` field; deeper containers step up the ladder.
- **Night** (#0F1620 surface, #E2E8F0 text): Dark theme base, also navy-tinted.

### Named Rules
**The Color-As-Reward Rule.** The teal hero gradient and streak amber are earned moments, not background texture. On a resting screen, the dominant colors are sky-tinted neutrals; saturated color covers a small fraction of the surface and marks a primary action or an achievement. Never wash a whole screen in primary.

**The Navy-Tint Rule.** No neutral is ever pure gray or pure black. Every surface, text, and outline color is tinted toward the brand blue. If a neutral looks gray next to the surfaces, it is wrong.

## 3. Typography

**Display Font:** Manrope (with system-ui, sans-serif fallback)
**Body Font:** Inter (with system-ui, sans-serif fallback)

**Character:** Manrope brings a confident, slightly editorial geometry to large headings; Inter keeps everything functional crisp and neutral at small sizes. The pairing reads as "well-kept notebook," warm at the top of the hierarchy and quietly legible everywhere else.

### Hierarchy
- **Display** (Manrope, 700, 36–56px, tight −0.88 to −1.12px tracking): Hero numbers, splash, big celebratory moments only. Rare.
- **Headline** (Manrope, 600–700, 24px+): Screen titles, section headers, dialog titles.
- **Title** (Inter, 600, 14–20px): Card titles, list-item leads, button labels, app-bar title.
- **Body** (Inter, 400, 12–16px): Paragraphs and descriptions. `bodyLarge` 16px on `on-surface`; `bodyMedium`/`bodySmall` step down to `on-surface-variant`. Cap prose at 65–75ch.
- **Label** (Inter, 500–600, 11–14px, +0.1 to +0.6px tracking): Chips, nav labels, metadata, overlines. The only place letter-spacing opens up.

### Named Rules
**The Two-Voice Rule.** Manrope speaks only at display and headline scale. Inter owns titles, body, labels, buttons, and all data. Never set body or a button in Manrope; never set a screen title in Inter.

## 4. Elevation

The system is near-flat by doctrine. Theme elevation is `0` almost everywhere: cards, buttons, app bar, nav bar, dialogs, sheets, FAB all ship at elevation 0. Depth is communicated by the tonal surface ladder first, and by a single soft ambient shadow second, applied only when something genuinely floats.

### Shadow Vocabulary
- **Ambient** (`box-shadow: 0 8px 24px rgba(11,28,48,0.06)`): The default lift, drawn from `AppTheme.ambientShadow()`. Diffuse, low-opacity, navy-tinted. For elevated cards and primary buttons in their active state.
- **Tinted** (`box-shadow: 0 6px 16px <accent>@22%`): `AppTheme.tintedShadow()`. A colored glow under achievement or streak cards, using the card's own accent. Reserved for celebratory surfaces.

### Named Rules
**The Surface-Shift-First Rule.** To separate two layers, change the surface step before reaching for a shadow. A card is `surface-container-lowest` on a `surface` field; that contrast alone is the separation. Shadow is added only when an element must read as floating above the plane (FAB, active primary button, an elevated achievement card).

**The Ghost-Border Rule.** Hard 1px strokes are forbidden. The only allowed seam is `AppTheme.ghostBorder` — outline-variant at 15% opacity — and only where a divider is truly needed.

## 5. Components

### Buttons
- **Shape:** Full pill (`StadiumBorder`, radius = height, so 999px). Universal across filled, elevated, outlined, and text buttons.
- **Primary (FilledButton):** Solid Deep Harbor Teal, white label, full-width by default, 56px tall, Inter 16/600 with +0.2px tracking. Elevation 0.
- **Hero (GradientButton):** The signature CTA. Teal→Sky `heroGradient`, white label, pill, with ambient shadow at 12% when enabled. Light haptic on tap. Use for the single most important action on a screen (onboarding, save plan).
- **Outlined:** Transparent fill, primary label, ghost stroke (outline-variant @ 30%), same 56px pill.
- **Text:** Primary foreground, pill hit area, Inter 15/600. For low-emphasis inline actions.

### Chips
- **Style:** `surface-container-highest` fill, no border, 8px radius (the one place radius goes small), Inter 12/500 with +0.5px tracking, 10×6px padding.
- **State:** Category chips override fill/text with the category pair (see Signature Component). Filter and choice chips follow Material selected/unselected.

### Cards / Containers (SurfaceCard)
- **Corner Style:** 24px radius (default).
- **Background:** `surface-container-lowest` (pure white) by default; pass a category or gradient fill for accent cards.
- **Shadow Strategy:** Flat by default; `elevated: true` applies the Ambient shadow. See Elevation.
- **Border:** None. Separation is the surface shift against the field behind it.
- **Internal Padding:** 20px default (`spacing.lg`).

### Inputs / Fields
- **Style:** Filled, `surface-container-highest` at 40% opacity, 24px radius, **no border** at rest. 18×20px padding. Hint in `on-surface-variant` at 70%.
- **Focus:** Border appears only on focus — primary at 40% opacity, 1.5px. The well "wakes up" rather than being outlined at rest.
- **Error:** Solid error stroke (#BA1A1A) at 1px.

### Navigation
- **Bottom nav:** 4 tabs, transparent background (floats over a glass layer), 72px tall, labels always shown. Indicator is `primary-container` at 25%. Selected label = primary + Inter 600; unselected = on-surface-variant + Inter 500. +0.4px tracking.
- **App bar:** Left-aligned title (not centered), elevation 0, no scroll-under tint, Manrope 20/600, surface background.

### Glass Container (signature surface)
A `BackdropFilter` blur (sigma 20) over a translucent surface (70% opacity), 32px radius, ghost border at 15%. Used **only** for floating chrome: the bottom nav, FABs, and floating overlays. Glass is purposeful here, never a decorative default on content cards.

### Mood Color System (signature)
The mood feature carries its own deliberate palette, independent of the app theme. Each 1–5 rating maps to an emoji and a bg/accent pair (violet → blue → amber → mint → gold in light; deep equivalents in dark). Emotional labels (anxiety, calm, energy, gratitude, focus…) each own a bg/fg pair split by positive/negative valence. The mood entry sheet runs its own dark "zone" palette (terracotta → amber → sage → teal → gold) regardless of app theme. These values live in `MoodTheme`, are mood-only, and are never reused as general UI accents.

## 6. Do's and Don'ts

### Do:
- **Do** anchor primary actions in Deep Harbor Teal (#00668A) and reserve the Teal→Sky hero gradient for the single most important CTA on a screen.
- **Do** separate layers with the surface ladder (`surface` → `surface-container-low` → `surface-container-lowest`) before reaching for any shadow.
- **Do** keep radii generous and consistent: 24px cards, 32px dialogs, 36px sheets, full-pill buttons.
- **Do** tint every neutral toward navy/blue. Pure gray is a bug.
- **Do** reserve Streak Amber (#F59E0B) for streaks, achievements, and gamification — when it shows, something was earned.
- **Do** set screen titles and hero numbers in Manrope; set everything functional (body, labels, buttons, data) in Inter.

### Don't:
- **Don't** use a 1px hard border anywhere. The only seam allowed is the ghost border (outline-variant at 15%). No side-stripe borders ever.
- **Don't** wash a whole screen in saturated primary; color is a reward, not a background.
- **Don't** feel like a corporate productivity tool (no Jira chrome), clinical health app (no Apple Health sterility), aggressive gamification (no Duolingo pressure-tactics), or a diary app (no journal/paper metaphors).
- **Don't** apply glassmorphism to content cards. Glass is for floating chrome only (nav, FAB, overlays).
- **Don't** set body text, labels, or buttons in Manrope; don't set screen titles in Inter.
- **Don't** add shadows to elements that aren't actually floating. Elevation 0 is the default; lift is the exception.
- **Don't** reuse the Mood rating/label colors as general UI accents — they belong to the mood feature only.
