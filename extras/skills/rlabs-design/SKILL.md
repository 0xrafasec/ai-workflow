---
name: rlabs-design
description: Use this skill to generate well-branded interfaces and assets for Rlabs, either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read `README.md` first — it carries the brand voice, palette rules, motion grammar, accessibility floor, and caveats. Then load the materials that match the surface you're building. **Skipping the matching kit is the most common source of off-brand output.**

## Foundations (load on every surface)

- `colors_and_type.css` — light + dark CSS variables and semantic tokens.
- `tokens.css` — spacing, radii, elevation, motion tokens.
- `assets/logo/` — `rlabs-logo.svg`, `rlabs-mark.svg`. Use these directly; never recreate.
- `assets/brand/chain-glyph.svg` — the chain-of-nodes motif. Use for hero/section accents only.
- `assets/icons.md` — Lucide setup (24px, 1.75px stroke). Stroke-only.

## Surface-specific materials (mandatory before designing)

Pick the bucket that matches what the user asked for and load **everything** in it. Reading just the CSS tokens is not enough — the kits encode component composition, spacing rhythm, and copy patterns that the tokens alone don't convey.

- **Slides / presentations / decks** → load `slides/index.html` end-to-end. It is the canonical 7-slide template (title, section, content, metric, quote, comparison, closing) — copy structure and class names from it instead of inventing new ones.
- **Marketing website / landing pages** → load `ui_kits/website/index.html`, then read each component: `SiteNav.jsx`, `Hero.jsx`, `FeatureGrid.jsx`, `CodeShowcase.jsx`, `Footer.jsx`, plus `README.md`.
- **Product app / dashboard / console** → load `ui_kits/app/index.html`, then read `Sidebar.jsx`, `TopBar.jsx`, `Overview.jsx`, `Agents.jsx`, `Transactions.jsx`, `_shared/Primitives.jsx`, plus `README.md`.

## Preview specimens (consult before inventing)

Before composing a component, check `preview/` for the matching specimen card and match its proportions, padding, and state treatment. These are the source of truth for token application:

- Color: `colors-core.html`, `colors-neutrals*.html`, `colors-accents.html`, `colors-semantic.html`, `colors-modes.html`.
- Type: `type-display.html`, `type-body.html`, `type-mono.html`, `type-scale.html`.
- Spacing & shape: `spacing-scale.html`, `spacing-radii.html`, `spacing-elevation.html`, `spacing-motion.html`, `radii.html`, `elevation.html`.
- Components: `components-buttons.html`, `components-inputs.html`, `components-nav.html`, `components-card.html`, `components-cards.html`, `components-badges.html`.
- Brand application: `brand-logo.html`, `brand-logo-dark.html`, `brand-logo-light.html`, `brand-glyph.html`, `brand-motif.html`, `brand-icons.html`, `brand-voice.html`.

If a token decision feels ambiguous, the preview card wins.

## Output mode

- **Visual artifact** (slides, mocks, throwaway prototypes): copy assets out and emit static HTML the user can open. Reuse the template/kit markup verbatim — adjust content, not structure.
- **Production code**: copy the CSS variables and component patterns into the target codebase. Don't re-derive tokens; reference the existing files.

If invoked with no guidance, ask the user which surface (slides / website / app) and what they want to build, then load the matching kit before producing anything.

## Mandatory verification — Playwright fidelity check

**After applying the design (artifact or production code), you must run a Playwright check before reporting done.** Visual drift between intent and output is the failure mode this skill exists to prevent.

Use the `playwright` MCP (`mcp__plugin_playwright_playwright__*`) — it is available in this environment.

1. **Open the reference** in a tab: the matching `index.html` from `slides/`, `ui_kits/website/`, or `ui_kits/app/`. Take a full-page screenshot.
2. **Open your output** in a second tab. Take a screenshot at the same viewport (default 1440×900 desktop; also 390×844 if mobile is in scope).
3. **Compare against the brand rules** — not just pixel-diff. Check:
   - Typography: Poppins ExtraBold display, Roboto body, JetBrains Mono for hashes/code. Lowercase OR uppercase headings (never title case).
   - Palette: black/white first; ≤1 accent per view; correct surface (`#0A0A0B` dark, `#FAFAF7` light).
   - Radii: 0/4/8/12 only. No pills outside status chips.
   - Spacing: 4px grid (4, 8, 12, 16, 24, 32, 48, 64, 96, 128).
   - Borders: hairline `rgba(_,0.08)` defaults.
   - Motion: hover/press present and on `cubic-bezier(.2,.8,.2,1)`; no bounces.
   - Copy: no emoji, no title case, no hype words, `→` for CTAs.
4. **Fix any drift in place**, re-screenshot, and only then report done. Note the screenshots taken in your final message.

If Playwright is unavailable in the current environment, say so explicitly and list the brand-rule checks you performed by reading the output instead — do not silently skip verification.

## Quick cheat sheet

- **Headings:** Poppins ExtraBold 800, lowercase (or UPPERCASE), tight tracking (-0.02em).
- **Body:** Roboto, 400 default. Medium (500) for UI labels. Light (300) for ledes.
- **Mono:** JetBrains Mono for hashes, code, tabular numbers.
- **Black/white first.** Accents: Signal `#C6F24E`, Ember `#FF5B2E`, Lapis `#2E5BFF`, Violet `#8B5CF6`. One accent per view.
- **Sharp corners** (radius 0–12px; never >12). No rounded pills except status chips.
- **Motion:** `cubic-bezier(.2,.8,.2,1)`, 120/200/320/520ms. Transform + opacity only. No bounces. No linear easings.
- **No emoji** in product or marketing copy. Unicode arrows (`→`) encouraged.
- **Dark surface:** `#0A0A0B` (not pure black).  **Light surface:** `#FAFAF7` (warm paper).
