# Design System

**Project:** [name from PRD]
**Last updated:** [date]
**Brand direction:** [from interview]
**Paper file:** [file name visible in `get_basic_info` — e.g. `Project Name`]

---

## Implementation Fidelity Protocol (read before writing any UI code)

This document is the **rules and tokens** layer. The **pixel-perfect source of truth** is the Paper canvas. These two layers together — not either alone — define the design.

**Non-negotiable checklist before you implement any component:**

1. **Find the component in the Paper Canvas Map below.** It lists every artboard and which component lives where. Never implement from the markdown alone.
2. **Pull exact values from the Paper MCP**, not from screenshots (the tool prefix depends on how Paper is installed):
   - `get_basic_info` once per session (confirms you're on the right file)
   - `get_tree_summary` on the target artboard to locate nodes
   - `get_jsx` on the specific component node — returns exact JSX + styles
   - `get_computed_styles` — returns the resolved values (colors, sizes, shadows, etc.)
   - `get_fill_image` when the fill is an image/gradient
3. **Screenshots are the lowest-trust input.** Use `get_screenshot` to sanity-check your implementation visually, but never read sizes or colors off a PNG.
4. **If Paper and this doc disagree, Paper wins.** Update the doc immediately with the correct value; don't silently diverge.
5. **After implementing, run `/wf:verify-design`** to diff the built UI against Paper and close any gaps before declaring done.

Agents doing UI work, including via `/wf:feature`, `/wf:fix` and `/wf:autopilot`, follow this protocol. Steps 1–3 matter most: implementing from markdown alone produces drift.

## Paper Canvas Map

Every component and screen has a named location on the Paper canvas. Cite the path when you reference it in specs or PRs.

| Artboard | Node ID | What lives here | Consult for |
|---|---|---|---|
| `Design System` | [id] | Tokens, palette, type, spacing, status badges, icon rules, tooltip spec | Any token-level question (color, space, radius, type) |
| `Component Library` | [id] | All reusable components in every state (buttons, inputs, controls, badges, avatars, nav, tables, overlays, tooltips, etc.) | Any component implementation — pull JSX/styles from here |
| `<Flow> / <Screen> / <Viewport>` | [id] | One screen or state in its flow group | Page-level layout, page-specific composition |

Rule: **every component spec below ends with a `📐 Paper reference` line** pointing to its canvas location. No exceptions.

---

## Color Palette

**Color harmony:** [method used — e.g., split-complementary, triadic, analogous]

### Primary
| Token | Hex | Usage |
|-------|-----|-------|
| `color-primary-50` | #[lightest] | Backgrounds, hover states |
| `color-primary-100` | #[...] | Subtle backgrounds |
| `color-primary-500` | #[main] | Primary buttons, links |
| `color-primary-700` | #[dark] | Hover states, emphasis |
| `color-primary-900` | #[darkest] | Text on light backgrounds |

### Secondary
| Token | Hex | Usage |
|-------|-----|-------|
| `color-secondary-50` | #[lightest] | Subtle backgrounds, hover |
| `color-secondary-100` | #[...] | Selected backgrounds, badges |
| `color-secondary-500` | #[main] | Secondary buttons, links, chart accents |
| `color-secondary-700` | #[dark] | Hover states, emphasis |
| `color-secondary-900` | #[darkest] | Text on light backgrounds |

### Accent
| Token | Hex | Usage |
|-------|-----|-------|
| `color-accent-50` | #[lightest] | Highlight backgrounds |
| `color-accent-100` | #[...] | Subtle highlights |
| `color-accent-500` | #[main] | Highlights, premium badges, warm touches |
| `color-accent-700` | #[dark] | Hover states |
| `color-accent-900` | #[darkest] | Strong emphasis |

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
| `color-bg-primary` | [from palette] | [from palette] | Page background |
| `color-bg-secondary` | [from palette] | [from palette] | Card / surface background |
| `color-bg-tertiary` | [from palette] | [from palette] | Subtle backgrounds, hover |
| `color-border` | [from palette] | [from palette] | Borders, dividers |
| `color-text-primary` | [from palette] | [from palette] | Headings, primary text |
| `color-text-secondary` | [from palette] | [from palette] | Secondary text, labels |
| `color-text-muted` | [from palette] | [from palette] | Placeholder, disabled |

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

### Type scale (override to suit the aesthetic)
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

**Every component block below ends with a `📐 Paper reference` line pointing to the exact node on the canvas. Implementers pull JSX and computed styles from that node via the Paper MCP rather than translating from the markdown alone.**

### [Component name, e.g. Buttons]
- [Variants and their token usage, e.g. Primary: primary-500 bg, radius-md, text-sm 500]
- 📐 **Paper reference:** `Component Library ▸ [Section]` — variants × states live here. Pull with `get_jsx` per state.

### Navigation
- [defined when first nav screen is created]
- 📐 **Paper reference:** `Component Library ▸ Navigation`

### Tables / Data Display
- [defined when first data screen is created]
- 📐 **Paper reference:** `Component Library ▸ Table`

## Accessibility

### Contrast Ratios (WCAG AA)
| Pairing | Ratio | Pass? |
|---------|-------|-------|
| Primary text on page bg | [calculated] | [Yes/No] |
| Secondary text on page bg | [calculated] | [Yes/No] |
| Muted text on page bg | [calculated] | [Yes/No] |
| Primary button text on primary bg | [calculated] | [Yes/No] |
| Error text on error-bg | [calculated] | [Yes/No] |
| Success text on success-bg | [calculated] | [Yes/No] |

### Minimum Sizes
- Smallest text: 12px (captions only)
- Body text: 16px
- Touch targets: 44x44px minimum
- Interactive element spacing: 8px gap minimum

### Color Independence
- All status indicators use icon + color (never color alone)
- Positive/negative values use a +/- sign or arrow alongside color
- Form errors use icon + colored border + text message
