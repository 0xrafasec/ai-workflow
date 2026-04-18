---
name: rlabs-design
description: Use this skill to generate well-branded interfaces and assets for Rlabs, either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read the `README.md` file within this skill, and explore the other available files:

- `colors_and_type.css` / `tokens.css` — foundational CSS variables. Load these on every surface.
- `fonts/` — Poppins ExtraBold + Roboto (100–700) + JetBrains Mono, as WOFF2.
- `assets/` — logo, mark, chain-motif, icon guidance.
- `preview/` — card specimens for every token and component.
- `ui_kits/website/` — marketing site kit (SiteNav, Hero, FeatureGrid, CodeShowcase, Footer).
- `ui_kits/app/` — product dashboard kit (Sidebar, TopBar, Overview, Agents, Transactions).
- `slides/` — 7-slide presentation template (title, section, content, metric, quote, comparison, closing).

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, copy the CSS variables and component patterns and read the rules here to become an expert in designing with the Rlabs brand.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

## Quick cheat sheet

- **Headings:** Poppins ExtraBold 800, lowercase (or UPPERCASE), tight tracking (-0.02em).
- **Body:** Roboto, 400 default. Medium (500) for UI labels. Light (300) for ledes.
- **Mono:** JetBrains Mono for hashes, code, tabular numbers.
- **Black/white first.** Accents: Signal `#C6F24E`, Ember `#FF5B2E`, Lapis `#2E5BFF`, Violet `#8B5CF6`. One accent per view.
- **Sharp corners** (radius 0–12px; never >12). No rounded pills except status chips.
- **Motion:** `cubic-bezier(.2,.8,.2,1)`, 120/200/320/520ms. Transform + opacity only. No bounces. No linear easings.
- **No emoji** in product or marketing copy. Unicode arrows (`→`) encouraged.
- **Dark surface:** `#0A0A0B` (not pure black).  **Light surface:** `#FAFAF7` (warm paper).
