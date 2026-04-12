---
name: design
description: "Create UI designs with Paper.design MCP: /design (all screens) or /design <page-name>"
---
Create UI designs using Paper.design MCP for: $ARGUMENTS

## Overview

You are a **senior UI designer**. You read the project's design documents, create a design system, and produce polished, modern layouts in Paper.design. Every design decision is grounded in the PRD, architecture, and user flows — not guesswork.

## Parse Arguments

The argument can be:
- **No argument:** `/design` — full design workflow: design system + brand guide, then all screens from PRD
- **Page/flow name:** `/design auth` — design only the auth flow screens, reusing existing design system
- **With phase override:** `/design --system-only` — only create/refine the design system and brand guide
- **With phase override:** `/design --layouts-only` — skip design system, go straight to layouts (assumes system exists)
- **Specific screen:** `/design auth/login` — single screen with all its states

## Context Gathering

Before anything, read what exists:

1. **Design docs (required input):**
   - Read `docs/PRD.md` or `docs/prd/` — the source of *what* screens are needed, user flows, user types
   - Read `docs/specs/ARCHITECTURE.md` — understand the system structure, API shapes, data models
   - Read `docs/specs/TDD.md` — understand tech stack context
   - Read `docs/specs/THREAT_MODEL.md` — security-sensitive screens (auth, payments, admin)
   - Read `README.md`, `CLAUDE.md` for project overview

2. **Existing feature specs:**
   - List and read all files in `docs/specs/` — each spec may describe screens, forms, data displays
   - Extract all user-facing flows, screens, states, and edge cases

3. **Existing design artifacts:**
   - Check `docs/design/DESIGN_SYSTEM.md` — if it exists, use it; don't recreate from scratch
   - Check `docs/design/assets/` — existing screenshots for reference
   - Check Paper.design canvas with `get_basic_info` and `get_tree_summary` — are there existing artboards?

4. **Roadmap context (optional):**
   - Check `docs/roadmap/` — understand phasing and priorities to order screen creation

**Minimum required context:** A PRD or at least one feature spec. If neither exists, stop:
"No PRD or feature specs found. Create one first with `/prd`, then come back to design."

## Phase 1: Discovery Interview

Use AskUserQuestion to gather key design decisions. Keep it focused — ask only what the docs don't answer.

### Question Set (adapt based on what docs already reveal):

1. **Brand direction** — "What feeling should the product evoke? Pick up to 2:"
   - Options: Clean & Professional, Bold & Energetic, Warm & Approachable, Minimal & Sophisticated
   - This drives font choices, color temperature, spacing density, and visual weight

2. **Color palette seed** — "Do you have brand colors or a starting palette? If so, share hex codes. Otherwise, pick a direction:"
   - Options: Provide hex codes, Cool tones (blue/purple/teal), Warm tones (orange/amber/coral), Neutral with accent (gray + one pop color), Dark mode first
   - This becomes the foundation for the full palette generation

3. **Typography preference** — "Which font pairing direction? Distinctive fonts give the product character."
   - Options:
     - Poppins + Roboto (bold headings + clean body, versatile) (Recommended)
     - Bricolage Grotesque + Crimson Pro (bold, editorial character)
     - Space Grotesk + JetBrains Mono (technical, developer-focused)
     - Newsreader + IBM Plex Sans (refined, professional)
   - The user can always provide a custom pairing via "Other"
   - When using Poppins + Roboto: Poppins at 600-800 for headings, Roboto 300-400 for body — leverage the extreme weight contrast
   - Encourage distinctive choices, but respect user preference if they want a familiar pairing

4. **Content density** — "How dense should the UI be?"
   - Options: Spacious / airy (dashboard, marketing), Balanced (most apps) (Recommended), Dense / compact (data-heavy, admin tools)

5. **Visual references** — "Do you have any visual references or inspiration? Share URLs to screenshots, Dribbble shots, landing pages, or existing products you like."
   - Options: No references — design from scratch, Yes — I'll share URLs
   - If the user provides URLs, use `WebFetch` to retrieve and analyze each reference image/page
   - Extract: color palettes, typography feel, layout patterns, density, visual style
   - Summarize what you learned from references and confirm with the user before proceeding
   - References inform but don't dictate — blend inspiration with the project's own identity

**Interview rules:**
- If the PRD already specifies brand direction or colors, skip those questions
- If the user provides brand assets or hex codes, build on them — don't override
- 4-5 questions max. The goal is direction, not exhaustive specification

## Phase 2: Design System + Brand Guide

Create the design system document and the corresponding design system artboard in Paper.

### 2a. Generate the Design System Document

Write to `docs/design/DESIGN_SYSTEM.md`:

```markdown
# Design System

**Project:** [name from PRD]
**Last updated:** [date]
**Brand direction:** [from interview]

## Color Palette

### Primary
| Token | Hex | Usage |
|-------|-----|-------|
| `color-primary-50` | #[lightest] | Backgrounds, hover states |
| `color-primary-100` | #[...] | Subtle backgrounds |
| `color-primary-500` | #[main] | Primary buttons, links |
| `color-primary-700` | #[dark] | Hover states, emphasis |
| `color-primary-900` | #[darkest] | Text on light backgrounds |

### Neutral
| Token | Hex | Usage |
|-------|-----|-------|
| `color-neutral-50` | #fafafa | Page backgrounds |
| `color-neutral-100` | #f4f4f5 | Card backgrounds, subtle dividers |
| `color-neutral-200` | #e4e4e7 | Borders, dividers |
| `color-neutral-400` | #a1a1aa | Placeholder text, disabled states |
| `color-neutral-600` | #52525b | Secondary text |
| `color-neutral-800` | #27272a | Primary text |
| `color-neutral-900` | #18181b | Headings |

### Semantic
| Token | Hex | Usage |
|-------|-----|-------|
| `color-success` | #22c55e | Success messages, confirmations |
| `color-warning` | #f59e0b | Warnings, attention needed |
| `color-error` | #ef4444 | Errors, destructive actions |
| `color-info` | #3b82f6 | Informational, links |

### Dark Mode
| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `color-bg-primary` | #ffffff | #0f0f10 | Page background |
| `color-bg-secondary` | #fafafa | #18181b | Card / surface background |
| `color-bg-tertiary` | #f4f4f5 | #27272a | Subtle backgrounds, hover |
| `color-border` | #e4e4e7 | #3f3f46 | Borders, dividers |
| `color-text-primary` | #18181b | #fafafa | Headings, primary text |
| `color-text-secondary` | #52525b | #a1a1aa | Secondary text, labels |
| `color-text-muted` | #a1a1aa | #71717a | Placeholder, disabled |

**Dark mode rules:**
- Invert the neutral scale — dark backgrounds, light text
- Primary accent colors stay vibrant but shift lightness (+10-15% for dark bg legibility)
- Semantic colors adjust: slightly desaturate on dark backgrounds to reduce eye strain
- Shadows become more subtle on dark (lower opacity) — depth via background tint differences instead
- Borders become more visible (lighter opacity) to separate surfaces
- Never invert brand/accent colors — adjust lightness only

### Application Rule
60% neutral backgrounds / 30% surface & secondary / 10% accent & CTA

## Typography

### Font Stack
- **Headings:** [chosen display font], sans-serif
- **Body:** [chosen body font], sans-serif
- **Mono:** [chosen mono font], monospace (code, data)

### Scale (Major Third — 1.25 ratio)
| Token | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| `text-xs` | 12px | 400 | 1.5 | 0.01em | Captions, fine print |
| `text-sm` | 14px | 400 | 1.5 | 0 | Secondary text, labels |
| `text-base` | 16px | 400 | 1.5 | 0 | Body text |
| `text-lg` | 20px | 500 | 1.4 | -0.01em | Subheadings, card titles |
| `text-xl` | 24px | 600 | 1.3 | -0.015em | Section headings |
| `text-2xl` | 30px | 600 | 1.2 | -0.02em | Page titles |
| `text-3xl` | 36px | 700 | 1.15 | -0.02em | Hero headings |
| `text-4xl` | 48px | 700 | 1.1 | -0.025em | Display, marketing |

### Typography Rules
- Never use pure black (#000) — use neutral-900 (#18181b) or neutral-800
- Body text: 400 weight, 1.5 line-height
- Headings: 600-700 weight, 1.1-1.2 line-height, negative letter-spacing
- Max line width: 680px for reading text

## Spacing

### Base Unit: 4px
| Token | Value | Usage |
|-------|-------|-------|
| `space-1` | 4px | Tight gaps (icon + label) |
| `space-2` | 8px | Related elements |
| `space-3` | 12px | Form fields, list items |
| `space-4` | 16px | Card padding, section gaps |
| `space-6` | 24px | Group separation |
| `space-8` | 32px | Section padding |
| `space-10` | 40px | Major section gaps |
| `space-12` | 48px | Page section separation |
| `space-16` | 64px | Hero sections, major breaks |
| `space-20` | 80px | Page-level vertical rhythm |

## Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| `radius-sm` | 6px | Small elements (badges, chips) |
| `radius-md` | 8px | Buttons, inputs |
| `radius-lg` | 12px | Cards, modals |
| `radius-xl` | 16px | Large cards, hero sections |
| `radius-full` | 9999px | Avatars, circular buttons |

## Shadows
| Token | Value | Usage |
|-------|-------|-------|
| `shadow-sm` | 0 1px 2px rgba(0,0,0,0.05) | Subtle lift |
| `shadow-md` | 0 1px 3px rgba(0,0,0,0.06), 0 6px 16px rgba(0,0,0,0.06) | Cards |
| `shadow-lg` | 0 2px 4px rgba(0,0,0,0.06), 0 12px 32px rgba(0,0,0,0.1) | Dropdowns, modals |
| `shadow-xl` | 0 4px 8px rgba(0,0,0,0.08), 0 20px 48px rgba(0,0,0,0.12) | Dialogs, popovers |

## Components

[Updated as screens are created — each new screen adds its reusable components here]

### Buttons
- **Primary:** [primary-500] bg, white text, radius-md, text-sm 500 weight, px-4 py-2
- **Secondary:** transparent bg, [neutral-200] border, [neutral-800] text
- **Ghost:** transparent bg, no border, [primary-500] text
- **Destructive:** [error] bg, white text

### Inputs
- [neutral-100] bg, [neutral-200] border, radius-md, text-base, px-3 py-2
- Focus: [primary-500] border, [primary-50] bg
- Error: [error] border, [error] text below

### Cards
- [white or neutral-50] bg, shadow-md, radius-lg, p-6
- Hover: shadow-lg, transition 200ms ease

### Navigation
- [defined when first nav screen is created]

### Tables / Data Display
- [defined when first data screen is created]
```

**Palette generation rules:**
- Start from the user's seed color(s)
- Generate a full scale (50-900) using HSL: fix hue, vary saturation (-5 to +5) and lightness (95 to 10)
- Ensure WCAG AA contrast ratios: text on backgrounds must be >= 4.5:1
- Avoid pure black/white: use near-black (#18181b) and near-white (#fafafa)

### 2b. Create Design System Artboard in Paper

Create an artboard named "Design System" in Paper.design showing:
- Color swatches (all palette colors as labeled rectangles)
- Typography samples (each scale level with sample text)
- Spacing visualization (rectangles showing scale)
- Component samples (buttons in all variants, inputs, cards)

**Build incrementally** — one visual group per `write_html` call:
1. Color palette section
2. Typography scale section
3. Spacing scale section
4. Button components
5. Input components
6. Card components

Take a screenshot after building the design system artboard.

### 2b-2. Create Component Library Artboard in Paper

Create a separate artboard named "Component Library" that shows every reusable component in **all its states**. This is the interactive reference sheet.

**Build incrementally** — one component group per `write_html` call:

1. **Buttons** — Primary, Secondary, Ghost, Destructive, each in states: default, hover, active, disabled, loading
2. **Inputs** — Text, Password, Textarea, Select, each in states: default, focus, filled, error, disabled
3. **Form elements** — Checkbox, Radio, Toggle, each in on/off/disabled states
4. **Cards** — Default, hover, selected, with/without image, compact variant
5. **Badges / Tags** — All semantic colors (success, warning, error, info) + neutral
6. **Avatars** — Sizes (sm, md, lg), with image, with initials, with status indicator
7. **Navigation items** — Default, hover, active, with icon, with badge count
8. **Modals / Dialogs** — Confirmation, form, alert variants (just the chrome, not full-screen)
9. **Toast / Notifications** — Success, error, warning, info variants
10. **Empty states** — Illustration placeholder + message + CTA pattern

For each component, show a label above it with the component name and state.
Group related states horizontally, component types vertically.

Create a **dark mode variant** of the component library:
- Duplicate the Component Library artboard
- Rename to "Component Library / Dark"
- Apply dark mode tokens: swap backgrounds, text colors, borders, and shadow adjustments

Take screenshots of both light and dark component libraries.

### 2c. Checkpoint: Design System Review

Present the design system to the user:
```
## Design System Ready

Palette: [primary color] + [neutral scale] + [semantic colors]
Typography: [font pairing]
Density: [spacious/balanced/dense]

Screenshot saved. Review the design system artboard in Paper.design.
Say "approved" to proceed to layouts, or give feedback to refine.
```

**Wait for user approval before proceeding to layouts.**

## Phase 3: Screen Inventory

Extract ALL screens needed from the design docs. For each screen, identify:

1. **Flow group** — which user flow it belongs to (Auth, Dashboard, Settings, etc.)
2. **Screen name** — descriptive name (Login, Register, Forgot Password)
3. **States** — all states this screen can be in (default, loading, error, empty, success, filled)
4. **Platform** — Desktop (1440x900) + Mobile (390x844)
5. **Priority** — from roadmap or PRD ordering

### Organize into groups:

```
Auth (horizontal group)
  ├── Login [default] [error] [loading]          ← vertical stack
  ├── Register [default] [error] [success]       ← vertical stack
  ├── Forgot Password [default] [sent]           ← vertical stack
  └── Reset Password [default] [success]         ← vertical stack

Dashboard (horizontal group, next to Auth)
  ├── Overview [populated] [empty] [loading]
  ├── Detail View [populated] [error]
  └── ...
```

Present the screen inventory to the user for confirmation before building.

## Phase 4: Layout Creation

### Canvas Organization Rules

**Horizontal axis = flow groups** — Auth screens, Dashboard screens, Settings screens side by side.
**Vertical axis = states and variants** — default state on top, then error, empty, loading, success below.

**Spacing:**
- 100px gap between screens within a flow group (vertically between states)
- 200px gap between flow groups (horizontally)
- Desktop artboards on the left, Mobile artboards on the right (within each flow group)

**Naming convention:** `[Flow] / [Screen] / [State] / [Platform]`
Example: `Auth / Login / Default / Desktop`, `Auth / Login / Error / Mobile`

### Building Each Screen

For each screen, follow this process:

1. **Create the artboard** with proper name and size
2. **Build incrementally** — one visual group per `write_html` call:
   - Navigation/header first
   - Hero/main content area
   - Individual content sections
   - Forms/interactive elements
   - Footer/secondary content
3. **Apply design system tokens** — use exact colors, fonts, spacing, radius, shadows from the system
4. **Use real-ish content** — never use "Lorem ipsum". Use realistic placeholder text that matches the product context from the PRD

### Design Quality Standards

Every screen must follow these principles. The goal is designs that feel **genuinely crafted**, not generated.

**Anti-slop rules (CRITICAL):**
- Never produce generic, cookie-cutter layouts. Each screen should feel purposeful for its specific context
- Avoid the "AI default" look: evenly-spaced same-size cards, predictable hero sections, boring symmetry
- Vary scale, weight, and rhythm — create visual interest through intentional asymmetry
- Each flow group should explore a slightly different layout approach while staying within the system

**Layout:**
- Use `display: flex` for all containers — flexbox is the only layout mode
- `gap` for all spacing — never margin
- Constrain content width: `max-width: 680px` for text, `1200px` for full layouts
- Generous whitespace — minimum 24px between sections, 48-80px between major blocks
- Use absolute positioning for decorative elements or to break a grid dramatically
- Bento-style asymmetric card layouts for dashboards — not everything needs to be the same size

**Typography:**
- **Avoid generic fonts.** Never default to Inter, Roboto, Open Sans, Lato, or system fonts without a deliberate reason. Choose distinctive typefaces that give the product character
- **Extreme weight contrast:** Pair 100/200 weights against 700/800/900 — not safe 400 vs 600
- **Aggressive size jumps:** Use 3x+ size differences between hierarchy levels for impact — not timid 1.5x steps
- Headings: 600-800 weight, tight line-height (1.05-1.2), negative letter-spacing (-0.02em to -0.03em)
- Body: 400 weight, comfortable line-height (1.5)
- Labels and captions: 500 weight, text-sm, uppercase with `letter-spacing: 0.05em` for refined look
- Consider editorial fonts: Playfair Display, Crimson Pro for premium feel; Bricolage Grotesque, Newsreader for character
- Developer/technical contexts: JetBrains Mono, Fira Code, Space Grotesk, IBM Plex
- High-contrast font pairings: display + monospace, serif + geometric sans — avoid pairing similar fonts

**Color:**
- 60-30-10 rule: 60% neutral, 30% surface/secondary, 10% accent
- Never pure black (#000) or pure white (#fff) — use near-black/near-white
- **Bold dominant colors with sharp accents** — avoid timid, evenly-distributed palettes
- Subtle background differentiation between sections (neutral-50 vs white)
- High contrast for primary actions, muted for secondary
- Draw from cultural aesthetics for inspiration: IDE themes, design movements, editorial design
- Layer CSS gradients as backgrounds instead of flat solid colors for atmosphere

**Depth & Atmosphere:**
- Layered shadows on cards: `0 1px 3px rgba(0,0,0,0.06), 0 6px 16px rgba(0,0,0,0.06)`
- Subtle border + shadow combination for elevated elements
- Create atmosphere over flatness — subtle gradient backgrounds, geometric patterns
- Glassmorphism sparingly: `background: rgba(255,255,255,0.7); backdrop-filter: blur(12px); border: 1px solid rgba(255,255,255,0.3)`
- Visual depth through background tint layers, not just shadows

**Icons:**
- Use Unicode symbols for common actions: arrow (→ ← ↑ ↓), check (✓), close (✕), star (★), bullet (●), warning (⚠), search (⌕), menu (☰), plus (+), settings (⚙)
- Inline SVG (24x24 viewBox, 1.5px stroke, round linecap) for custom icons
- Consistent 20-24px icon sizing

**Modern craft touches:**
- Subtle mesh gradients on hero sections or CTAs — not flat solid color buttons
- Rounded corners consistently (radius-lg for cards, radius-md for buttons)
- Staggered layouts and varied card sizes over rigid grids — Bento-style
- Reduce UI chrome — use spacing and background contrast instead of visible borders
- Contextual decorative elements: subtle geometric patterns, gradient accents, or branded shapes
- Consider animation hints in static designs: show hover states, transition indicators

### Review Checkpoint (MANDATORY)

After every 2-3 screens (or after completing a flow group), take screenshots and evaluate:
- **Spacing:** Uneven gaps, cramped groups, or unintentionally empty areas?
- **Typography:** Text readable? Clear hierarchy between heading/body/caption?
- **Contrast:** Low contrast text? Elements blending into background?
- **Alignment:** Elements sharing a visual lane? Icons aligned across rows?
- **Clipping:** Content cut off at container or artboard edges?
- **Consistency:** Does this screen match the design system? Same tokens everywhere?

Fix issues before moving to the next group. Use `update_styles` for targeted fixes.

### Screenshot Archival

After completing each flow group:
1. Take a screenshot of each artboard using `get_screenshot`
2. Screenshots are referenced in the design system doc under a "Screen Reference" section
3. Note: Paper.design is the source of truth — screenshots are for reference in other phases

### Design System Updates

As new patterns emerge during layout creation, update `docs/design/DESIGN_SYSTEM.md`:
- New component patterns (first table → add Table component section)
- New navigation patterns (first sidebar → add Navigation section)
- Color usage refinements (if a new semantic color is needed)
- Spacing adjustments (if density needs change per section)

Mark updates with the screen that introduced them:
```
### Data Tables
*Added during: Dashboard / Overview*
- Header row: neutral-100 bg, text-sm 600 weight, uppercase
- Body row: white bg, text-base 400, neutral-800 text
- Alternating: neutral-50 bg on even rows
- Hover: primary-50 bg
```

## Execution Flow Summary

```
/design (full)
  1. Read all docs → extract flows and screens
  2. Interview → brand direction, palette, typography, density, references
  3. Create design system doc + Paper artboard (light + dark tokens)
  4. Create component library artboard (light + dark variants)
  5. Checkpoint → user approves design system
  6. Build screen inventory → user confirms
  7. Create layouts group by group:
     For each flow group:
       a. Create all screens (default states first, then variants)
       b. Desktop + Mobile for each
       c. Generate dark mode variants for the group
       d. Review checkpoint after group
       e. Update design system with new patterns
  8. Final review → present complete canvas

/design <flow-name>
  1. Read all docs + existing design system
  2. If no design system exists → run Phase 2 first
  3. Build only the specified flow group (light + dark, desktop + mobile)
  4. Review checkpoint
  5. Update design system with new patterns

/design <flow/screen>
  1. Read all docs + existing design system
  2. Build only the specified screen + all states (light + dark)
  3. Review checkpoint
  4. Update design system with new patterns

/design --system-only
  1. Read all docs
  2. Interview → brand direction, palette, typography, density, references
  3. Create/refine design system doc + Paper artboard
  4. Create/refine component library (light + dark)
  5. Checkpoint → user approves

/design --layouts-only
  1. Read existing design system (required)
  2. Read all docs → extract screens
  3. Skip to Phase 4 layout creation (includes dark mode)
```

## Dark Mode Screens

After completing all light mode screens for a flow group, create dark mode variants:

1. **Duplicate each artboard** using `duplicate_nodes`
2. **Rename** with `/Dark` suffix: `Auth / Login / Default / Desktop / Dark`
3. **Apply dark tokens** using `update_styles` — swap all colors to dark mode values from the design system
4. **Adjust shadows** — reduce shadow opacity, rely more on surface tint differences for depth
5. **Verify contrast** — dark mode is prone to low-contrast text; check readability
6. Place dark variants **below** their light counterparts in the vertical stack

Dark mode is generated per flow group, not as a separate pass. This keeps related screens together.

## Rules

1. **Docs are the source of truth.** Every screen must trace back to a PRD flow, spec, or user story. Don't invent screens.
2. **Design system first.** Never create layouts without an approved design system. If none exists, create it.
3. **Incremental HTML.** One visual group per `write_html` call. Never dump an entire page in one call.
4. **Real content.** Use realistic text from the product domain. Never "Lorem ipsum".
5. **Token discipline.** Every color, font size, spacing value must come from the design system. No magic numbers.
6. **Review religiously.** Screenshot and evaluate after every 2-3 modifications. Fix before moving on.
7. **Update the system.** Every new component pattern gets documented in `DESIGN_SYSTEM.md`.
8. **Wait for approval.** After the design system phase, STOP and wait for user approval before layouts.
9. **Mobile is not an afterthought.** Create mobile variants alongside desktop, not after all desktop screens.
10. **Group by flow, not by component.** Auth screens together, Dashboard screens together — organized for stakeholder review.
11. **Dark mode is not optional.** Every screen gets a dark variant. Generated per flow group, placed below light variants.
12. **Fight the generic.** Every layout should feel deliberately designed for its context. Vary approaches across flows — not every page should use the same card grid. Avoid predictable, safe, "AI-generated" aesthetics.
