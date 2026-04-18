# Rlabs Design System

> The operating system for on-chain intelligence.

**Rlabs** builds production-grade solutions at the intersection of **artificial intelligence** and **blockchain**. From autonomous agents that trade and reason on-chain, to verifiable AI pipelines, to bespoke infrastructure for DeFi, DAOs, and consumer dApps — Rlabs engineers the invisible layer that makes AI trustworthy and blockchain useful.

This design system captures the full visual, verbal, and interaction language of the Rlabs brand — designed to scale across presentations, marketing website, desktop product, and mobile apps.

---

## Sources

No existing brand assets, Figma files, or codebase were provided. This design system was authored from scratch based on the following brief:

- Company: **Rlabs** — AI + blockchain solutions studio
- Modes: **Dark** (black / near-black bg) + **Light** (white bg); black and white are fundamental, with harmonious accent colors
- Headings: **Poppins ExtraBold** (all-uppercase or all-lowercase)
- Body: **Roboto**, weights Thin → Bold
- Aesthetic: **Modern, clean, animated, fluid**
- Required: **UX, fluidity, accessibility**
- Surfaces: **Presentations, website, desktop, mobile**

If you have existing Figma files, brand guidelines, logos, or a production codebase, drop them into the project and I'll reconcile this system against the real source of truth.

---

## Index

Root files:
- `README.md` — this file (brand context, content + visual foundations, iconography)
- `SKILL.md` — agent skill manifest for reuse in Claude Code
- `colors_and_type.css` — foundational CSS variables (light + dark, semantic tokens)
- `tokens.css` — spacing, radii, elevation, motion tokens

Folders:
- `fonts/` — webfont files (Poppins, Roboto)
- `assets/` — logos, marks, icons, illustrations, textures
- `preview/` — design-system cards rendered in the Design System tab
- `ui_kits/website/` — marketing site UI kit (JSX components + interactive index.html)
- `ui_kits/app/` — product app UI kit (dashboard, agent console)
- `slides/` — presentation template (title, section, content, quote, comparison)

---

## CONTENT FUNDAMENTALS

Rlabs writes like an engineer who ships. Confident without hype. Technical without gatekeeping. Never sells — demonstrates.

### Voice

- **Direct.** Short sentences. Verbs first. Cut the adverbs.
- **Precise.** Name the thing. "Smart contract audit" beats "blockchain security solution."
- **Low-ego.** We built this. Here's how it works. Use it.
- **Quietly confident.** No exclamation points. No "revolutionary." No "game-changing." The work speaks.

### Casing

- **Display headings** (hero, section openers, slide titles): `lowercase` OR `UPPERCASE` — never title case. Pick one per surface and commit.
- **Body, UI labels, buttons**: sentence case. "Deploy agent", not "Deploy Agent".
- **Product names**: exactly as spelled — `Rlabs` (R capital, lowercase rest), `Onchain Studio`, `Agent Mesh`.

### Person

- **"We"** for the company. "We build…", "We partner with…"
- **"You"** for the reader. Never "users" in user-facing copy.
- Avoid "I" except in founder/personal posts.

### Emoji & symbols

- **No emoji in product UI or marketing copy.** Ever.
- Unicode typographic marks encouraged: `—` (em dash), `→` (arrow), `·` (middot), `◆` (accent), `∎` (end-of-proof as a sign-off).
- Use `→` for CTAs and inline directional cues ("Read the docs →").

### Rhythm

Mix sentence lengths. One short. Then a longer sentence that develops the idea with specifics and weight. Short again. Land it.

### Examples

✅ **Good**
- `intelligence, verified onchain.`
- `We build AI agents that settle onchain and answer for their actions.`
- `Deploy in minutes. Audit in seconds. Trust by default.`
- `Ship to mainnet →`

❌ **Avoid**
- "🚀 Revolutionary AI-powered Web3 solutions!" — hype, emoji, title case, buzzwords.
- "Empowering users to leverage blockchain" — corporate, vague, "users".
- "The #1 Platform for AI × Crypto" — ranking claims, hashtags.

---

## VISUAL FOUNDATIONS

### Palette

The brand is **black and white first**. Color is used deliberately — a single accent per surface, never a rainbow.

- **Core neutrals:** pure black `#000000`, near-black `#0A0A0B`, paper `#FAFAF7` (warm off-white, not sterile white).
- **Accent — Signal** `#C6F24E` — acid lime. The "live" color. Used for status, CTAs, agent activity, successful on-chain confirmations.
- **Accent — Ember** `#FF5B2E` — cadmium orange. The "attention" color. Used for alerts, highlights, destructive confirms.
- **Accent — Lapis** `#2E5BFF` — electric blue. The "link / chain" color. Used for hyperlinks, transaction hashes, blockchain affordances.
- **Accent — Violet** `#8B5CF6` — used sparingly for AI/model indicators and gradients on feature moments.
- Never mix more than 2 accents in a single view.

Dark mode uses `#0A0A0B` as the primary surface, not pure black — reduces OLED bloom. Light mode uses paper `#FAFAF7`, not pure white — less fatiguing and distinguishes from default browser chrome.

### Type

- **Display:** Poppins ExtraBold (800). Tight tracking (-0.02em), tight leading (1.0–1.05). Lowercase or uppercase only.
- **Body:** Roboto. Default 400. Thin (100) used sparingly for oversized numerals. Medium (500) for UI labels. Bold (700) for emphasis.
- **Mono:** JetBrains Mono — for code, hashes, addresses, numerical data. Always tabular figures.
- Scale is modular ratio 1.25 (major third).

### Spacing

4px base grid. Scale: 4, 8, 12, 16, 24, 32, 48, 64, 96, 128. No off-grid values.

### Backgrounds

- **Solid surfaces by default.** Not gradients. Not patterns.
- Feature moments (hero, section transitions) use one of:
  - **Noise overlay** — 4% opacity monochrome grain, subtle, adds depth to flat black/white.
  - **Mesh accent** — a single soft radial gradient of one accent color, ~20% opacity, behind content.
  - **Line grid** — 1px hairline grid (`rgba(255,255,255,0.04)` on dark) for technical/schematic sections.
- **Never** use bluish-purple gradient backgrounds, drop-in stock imagery, or decorative illustrations unless custom.
- Imagery when used is **high-contrast black & white**, sometimes duotone with a single accent. Never warm saturated photography.

### Motion

- **Easing:** default `cubic-bezier(0.2, 0.8, 0.2, 1)` — a fluid, confident ease-out.
- **Durations:** `120ms` micro (button press), `200ms` small (hover), `320ms` element (panel reveal), `520ms` page (route transition).
- **Transforms only.** Animate opacity + transform. Never animate width, height, top, or left — layout thrash kills fluidity.
- **Entrance:** fade + 8px translate upward. Exit: fade only.
- **No bounces.** No spring overshoots. Rlabs doesn't wobble. Rlabs glides.
- Respect `prefers-reduced-motion: reduce` — collapse all motion to a 100ms opacity fade.

### States

- **Hover:** on interactive elements, surface lightens by `4%` (dark) or darkens by `4%` (light). On accent buttons, brightness increases `6%`. Cursor always updates.
- **Press / active:** `scale(0.98)` + `120ms` transition. No color change needed — the compression signals it.
- **Focus:** a 2px outline in the current accent color, offset 2px. Visible on keyboard navigation only (`:focus-visible`).
- **Disabled:** `opacity: 0.4`, `cursor: not-allowed`, no hover affordance.

### Borders

- Hairline `1px solid` in `rgba(0,0,0,0.08)` (light) or `rgba(255,255,255,0.08)` (dark) — almost all borders in the system.
- Strong borders (`rgba(_,0.16)`) only for emphasis — focused inputs, selected cards.
- Accent borders used only on interactive selection or live state.

### Shadows / elevation

Dark mode is shadow-light — depth comes from borders and luminance, not shadows. Light mode uses a quiet shadow system:
- `shadow-1`: `0 1px 2px rgba(0,0,0,0.04)` — resting cards
- `shadow-2`: `0 4px 12px rgba(0,0,0,0.06)` — hovered cards, menus
- `shadow-3`: `0 12px 32px rgba(0,0,0,0.10)` — modals, popovers
- Inner shadow: none. The system doesn't use inset shadows.

### Protection layers

- For text over imagery, use **protection gradients** — a 0 → 80% linear gradient from bottom. Never capsule pills with opaque backgrounds over images.
- Sticky headers use `backdrop-filter: blur(24px) saturate(180%)` + `rgba(10,10,11,0.72)` (dark) or `rgba(250,250,247,0.72)` (light).

### Corner radii

- `0` — primary brand radius. Many surfaces are sharp-cornered. This is the distinctive feature.
- `4px` — small controls (chips, small buttons, inputs).
- `8px` — cards, menus, larger buttons.
- `12px` — modals, prominent feature cards.
- **No `9999px` pills** except for status dots and tag chips.
- **No `16px+` radii.** Rlabs is engineered, not soft.

### Cards

- **Default card:** 1px hairline border, `8px` radius, surface color (not elevated), no shadow (dark) / `shadow-1` (light), 24px interior padding.
- **Feature card:** slightly elevated surface `#111113` (dark) or `#FFFFFF` (light), `12px` radius, `shadow-2`.
- **Never:** rounded corners with colored left-border accent (banned trope).

### Layout

- **12-column fluid grid.** Gutters 24px, page max-width 1280px (content) / 1440px (marketing hero).
- **Fixed elements:** top nav (sticky, 64px desktop, 56px mobile), sidebar in app (264px, collapsible to 64px).
- **Breakpoints:** 640, 768, 1024, 1280, 1536.
- Generous whitespace — section vertical rhythm 96–128px on desktop.

### Transparency & blur

Used only for:
- Sticky nav chrome (blur + alpha background)
- Modal / dialog backdrops (`rgba(0,0,0,0.6)`)
- Hover previews over complex content

Never for decorative "glassmorphism" cards in layouts.

### Accessibility

- All text meets **WCAG AA** minimum (4.5:1 for body, 3:1 for large/display).
- Accent-on-black and accent-on-paper pairs have been contrast-checked.
- Every interactive element has a visible `:focus-visible` state.
- Motion collapses under `prefers-reduced-motion`.
- Icon buttons always carry `aria-label`.
- Minimum hit target 44×44px on mobile, 32×32px on dense desktop surfaces.

---

## ICONOGRAPHY

Rlabs uses a **single, consistent icon family**: **Lucide** icons — 24px, 1.75px stroke, rounded line caps, open interiors.

- Delivered via CDN (see `assets/icons.md`) and mirrored locally under `assets/icons/` for offline use.
- Stroke icons only — **no filled icons** in product UI except for state indicators (e.g. a solid dot for "live").
- **No emoji** in product chrome, marketing copy, or slides. Ever.
- Unicode arrows (`→`, `↗`, `↘`, `⟶`) are allowed inline in copy as typographic flourishes.
- Custom brand marks (the Rlabs monogram, the chain-of-nodes glyph) live in `assets/logo/` as SVG.
- Icon color defaults to `currentColor` — never hard-coded. This means icons adopt text color automatically.

**Flag:** Lucide is used as the icon system here because no existing brand icons were provided. If Rlabs has a proprietary icon set, replace the Lucide imports and update this section.

**Flag:** Poppins and Roboto are loaded from Google Fonts at build time into `fonts/`. JetBrains Mono is a substitution for the "code / hash" mono slot — not specified in the brief. If you have a preferred monospace, swap the file in `fonts/mono/` and update `colors_and_type.css`.

---

## UI Kits

- **`ui_kits/website/`** — marketing site: nav, hero, feature grid, footer, CTA
- **`ui_kits/app/`** — product dashboard: sidebar, topbar, agent console, metric cards, transaction list

Each kit has its own `README.md`, modular `.jsx` components, and an interactive `index.html` demo.

## Slides

- **`slides/`** — presentation template: title, section opener, content, big quote, comparison, agenda, closing. Black and paper variants.

---

## Caveats & flags

- **Fonts loaded from Google Fonts** (Poppins ExtraBold, Roboto 100/300/400/500/700, JetBrains Mono). If Rlabs has proprietary licensed font files, drop them into `fonts/` and re-point `colors_and_type.css`.
- **Icons use Lucide** — substituted because no proprietary icon set was provided. Swap at your preferred icon system if needed.
- **Brand voice, palette, and tone** were invented to the brief. All suggestions are starting points — iterate freely.
- **No codebase, Figma, or existing assets** were attached; nothing was reconciled against prior art. If those exist, drop them into the project and I'll align the system.
