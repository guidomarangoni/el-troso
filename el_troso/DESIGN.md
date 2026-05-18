---
name: El Troso
description: >
  A memory companion app for elderly users. The visual language evokes
  aged parchment, sun-warmed earth, and olive groves — a diary that
  lives on a trail, not on a dashboard.
colors:
  primary: "#6B7F5A"
  on-primary: "#FFFFFF"
  secondary: "#C98C3C"
  on-secondary: "#FFFFFF"
  tertiary: "#8B5A3C"
  on-tertiary: "#FFFFFF"
  error: "#8B5A3C"
  on-error: "#FFFFFF"
  surface: "#FFFFFF"
  on-surface: "#3D2F1F"
  surface-container-highest: "#F5EBD6"
  on-surface-variant: "#6B5A47"
  outline: "#6B5A47"
  background: "#F5EBD6"
  on-background: "#3D2F1F"
typography:
  headline-lg:
    fontFamily: System Default
    fontSize: 28px
    fontWeight: "500"
    lineHeight: 36px
  headline-md:
    fontFamily: System Default
    fontSize: 24px
    fontWeight: "500"
    lineHeight: 31px
  headline-sm:
    fontFamily: System Default
    fontSize: 22px
    fontWeight: "400"
    lineHeight: 29px
  title-lg:
    fontFamily: System Default
    fontSize: 22px
    fontWeight: "600"
    lineHeight: 29px
  body-lg:
    fontFamily: System Default
    fontSize: 24px
    fontWeight: "400"
    lineHeight: 34px
  body-md:
    fontFamily: System Default
    fontSize: 20px
    fontWeight: "400"
    lineHeight: 28px
  body-sm:
    fontFamily: System Default
    fontSize: 18px
    fontWeight: "400"
    lineHeight: 24px
  label-lg:
    fontFamily: System Default
    fontSize: 28px
    fontWeight: "600"
    lineHeight: 34px
  label-md:
    fontFamily: System Default
    fontSize: 20px
    fontWeight: "400"
    lineHeight: 24px
  label-sm:
    fontFamily: System Default
    fontSize: 18px
    fontWeight: "400"
    lineHeight: 23px
  display-splash:
    fontFamily: System Default
    fontSize: 48px
    fontWeight: "600"
    lineHeight: 62px
rounded:
  sm: 12px
  DEFAULT: 16px
  md: 18px
  lg: 20px
  xl: 24px
  full: 9999px
spacing:
  unit: 8px
  page-padding: 24px
  card-margin-vertical: 6px
  section-gap: 16px
  chip-padding-h: 16px
  chip-padding-v: 10px
  button-padding-h: 24px
  button-padding-v: 16px
  input-padding: 16px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.lg}"
    height: 64px
    padding: 16px 24px
  button-outlined:
    backgroundColor: transparent
    textColor: "{colors.on-surface}"
    typography: "{typography.label-md}"
    rounded: "{rounded.md}"
    height: 56px
    padding: 12px 20px
  chip-choice:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-md}"
    rounded: "{rounded.xl}"
    padding: 10px 16px
  chip-choice-selected:
    backgroundColor: "{colors.secondary}"
    textColor: "{colors.on-secondary}"
  card-memory:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.DEFAULT}"
    padding: 6px
  input-field:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-md}"
    rounded: "{rounded.DEFAULT}"
    padding: 16px
  input-field-focused:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
  app-bar:
    backgroundColor: "{colors.background}"
    textColor: "{colors.on-surface}"
    typography: "{typography.title-lg}"
    height: 56px
  image-preview:
    rounded: "{rounded.sm}"
    height: 180px
---

## Overview

El Troso ("The Trail" in Veneto dialect) is a memory companion designed
for users over 80. Its visual identity draws from the metaphor of a
**diary carried along a mountain trail** — warm, tactile, and deeply
personal. The interface must feel like parchment touched by sunlight,
not a clinical dashboard.

The design prioritizes **radical accessibility**: every font size, touch
target, and color contrast has been calibrated against WCAG 2.2 guidelines
and geriatric usability research (Pak & McLaughlin 2018). The absolute
minimum readable text size is 18px; the primary body text for memories is
24px. There is no dark mode — the metaphor is dawn on a hillside, not
midnight.

The overall aesthetic is **Warm Minimalism**: generous whitespace, muted
earth tones, zero decorative complexity, and gentle micro-feedback. The
UI should make Giorgio (the primary persona, 84 years old, early-stage
cognitive decline) feel like he is flipping through a cherished photo
album, not operating software.

## Colors

The palette is deliberately restrained, drawn from the Veneto countryside
that inspires the app's name.

- **Primary — Olive Green (#6B7F5A):** The anchor color. Used for primary
  CTAs, focused input borders, and the "path" metaphor. Evokes the olive
  groves of the Euganean Hills.
- **Secondary — Burnt Ochre (#C98C3C):** The warm highlight. Used for
  selected chips, active tags, and accent moments. Conveys the golden light
  of a late-afternoon passeggiata.
- **Tertiary — Earth Brown (#8B5A3C):** Used sparingly for "fading" states
  and the footprint opacity system. Represents the worn, sun-baked earth
  of a trail walked many times.
- **Background — Parchment Cream (#F5EBD6):** The canvas. Every screen
  rests on this warm, off-white tone. It is never pure white — pure white
  feels institutional.
- **Surface — Pure White (#FFFFFF):** Reserved for cards, inputs, and
  elevated interactive surfaces that need to "lift" from the parchment.
- **Text Primary — Dark Walnut (#3D2F1F):** Deep, warm brown for all
  primary text. Black was rejected as too harsh for prolonged reading by
  elderly eyes.
- **Text Secondary — Warm Umber (#6B5A47):** For captions, metadata,
  outlines, and secondary labels. Maintains warmth while clearly
  establishing hierarchy.

### Footprint Opacity System

Memories that haven't been "walked" recently fade visually. The
trailing icon on each memory card uses one of three opacity levels:

| State | Opacity | Meaning |
|:------|:--------|:--------|
| Bright | 1.0 | Walked in the last 7 days |
| Fading | 0.6 | Walked 8–30 days ago |
| Ghost | 0.3 | Not walked for over 30 days |

## Typography

The system currently uses the platform's default sans-serif font (Roboto
on Android, San Francisco on iOS). A future phase will introduce a custom
serif or humanist font (candidates: Lora, Nunito) via Google Fonts.

Font sizes are **non-negotiable minimums**, driven by clinical readability
research:

- **Body Large (24px):** The primary reading size for memory text. This is
  the heart of the app — Giorgio reads his own memories at this size.
- **Body Medium (20px):** For questions, prompts, and secondary flowing
  text. Still comfortably large.
- **Body Small (18px):** The absolute floor. Used only for timestamps,
  character counters, and Gemma-generated descriptions. Nothing the user
  *must* read falls below this size.
- **Label Large (28px):** CTA button text. Originally specified at 32px
  but reduced to 28px for full-width button balance.
- **Display Splash (48px):** Used only once — the app name "El Troso" on
  the splash screen. A moment of typographic drama.

Line heights are generous (1.3–1.4×) to reduce visual density and improve
tracking for aging eyes.

## Layout & Spacing

The layout follows a single-column model optimized for one-handed
smartphone use. All screens use a consistent 24px page padding.

- **Grid:** No formal grid. Content flows vertically in a single column
  with 24px horizontal margins. The target device is a 6.1" phone
  (Pixel 7a, 411dp wide).
- **Rhythm:** An 8px base unit governs all spacing. Common increments are
  8, 16, 24, and 40px.
- **Touch Targets:** All interactive elements (buttons, chips, list items)
  have a minimum touch target of 48dp, with primary CTAs at 64dp height.
- **Scroll:** Content-heavy screens (Record, Detail) use
  `SingleChildScrollView` with the primary CTA pinned to the bottom via
  `bottomNavigationBar` — always visible, never scrolled away.
- **Keyboard Awareness:** The scaffold respects
  `resizeToAvoidBottomInset`, pushing content upward when the soft
  keyboard appears.

## Elevation & Depth

Depth is achieved through **tonal layering**, not shadows. The design
explicitly avoids drop shadows to maintain the "flat diary" metaphor.

- **Level 0 — Parchment (#F5EBD6):** The base canvas. Scaffold
  backgrounds, app bars, and empty states live here.
- **Level 1 — White Surface (#FFFFFF):** Cards, input fields, and chips
  sit one tonal step above the parchment. They are distinguished by a
  subtle 1px border at 20% opacity of the secondary text color, not by
  elevation or shadow.
- **Level 2 — Overlays:** Bottom sheets (image source picker) and
  confirmation dialogs use the standard Material 3 scrim and surface
  tint. Image loading overlays use `Colors.black45` with centered white
  spinners for clear feedback.

Card elevation is explicitly set to `0` across the entire app. Borders
are warm (`#6B5A47` at 20% opacity) rather than cool gray.

## Shapes

The shape language is **softly rounded** — organic enough to feel friendly
but not so rounded as to appear childish.

- **Cards (16px radius):** Memory cards, chat bubbles. The standard
  container radius.
- **Inputs (16px radius):** Text fields match card radius for visual
  consistency.
- **Primary Buttons (20px radius):** Slightly rounder than cards to
  signal interactivity. 64px height with full-width sizing.
- **Outlined Buttons (18px radius):** A half-step between cards and
  primary buttons.
- **Chips (24px radius):** Pill-shaped for tag and walker selectors.
  The roundest interactive element.
- **Image Previews (12px radius):** Attached images use a tighter radius
  to feel like physical photographs laid on a page.

## Components

### Buttons

Primary CTAs ("Custodisci", "Comincia") use `FilledButton` with olive
green background and white text. They span the full width and stand 64px
tall — intentionally oversized for elderly thumbs. When processing, the
label is replaced by a small `CircularProgressIndicator` (20×20px,
strokeWidth 2).

Secondary actions ("Aggiungi foto", "Registra audio") use `OutlinedButton`
with a 1.5px warm border. They are shorter (56px) and can appear in
side-by-side pairs.

### Chips

`ChoiceChip` elements are used for tag selection (Famiglia, Lavoro,
Viaggi, Casa, Altro) and walker selection (self, child, grandchild,
friend). Unselected chips are white with a warm border; selected chips
flip to burnt ochre background with white text. Chips use 24px
fully-rounded corners.

### Cards

Memory list items are `Card` widgets with zero elevation and a thin warm
border. Each card shows a one-line title (auto-truncated at 70 chars),
a tag chip (if present), and a footprint opacity indicator. Tapping
navigates to the memory detail.

### Inputs

Text fields use `OutlineInputBorder` with 16px radius. The focused state
swaps the border to olive green at 2px width. The mic icon (32px) lives
in the `suffixIcon` position, colored olive green when idle and the
secondary accent when actively listening.

### Image & Audio Indicators

When an image is being described by Gemma, a dark semi-transparent overlay
(`Colors.black45`) appears over the photo preview with a white spinner
and "Sto guardando la foto..." label. Audio recording shows a red stop
icon; completed audio shows a green check with "Audio originale salvato".

### App Bar

Flat, no elevation, parchment background. Title uses `titleLarge` (22px,
semibold). No centered title — left-aligned for natural reading flow.

## Do's and Don'ts

### Do

- Use warm browns and olive greens — never pure black or cool grays
- Maintain 24px minimum for any text Giorgio must read
- Keep every interactive element at least 48dp tall
- Use parchment cream as the base, white only for elevated surfaces
- Show loading states with spinners — never leave the user wondering
- Use Italian as the primary language; English as fallback only

### Don't

- Use drop shadows — depth comes from tonal shifts and thin borders
- Use animations longer than 300ms — responsiveness over spectacle
- Use red for errors — brown earth tones signal "attention needed" without alarm
- Place critical actions behind scrolling — pin CTAs to the bottom
- Use font sizes below 18px for any user-facing text
- Use dark mode — the metaphor is daylight, warmth, and open trails
