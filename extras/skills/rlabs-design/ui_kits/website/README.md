# Website UI Kit

Marketing site for Rlabs. Dark by default, with a light-mode toggle planned.

## Components

- `SiteNav.jsx` — sticky top nav with blur backdrop
- `Hero.jsx` — oversized lowercase hero, mesh accent, stat row
- `FeatureGrid.jsx` — 3×2 feature grid with hairline dividers
- `CodeShowcase.jsx` — split-layout code block + copy
- `CodeShowcase.jsx` (CTABand) — centered closer with hairline grid
- `Footer.jsx` — 4-column link footer + sign-off

## Usage

Open `index.html` directly. All components mount under a single React root via inline Babel.

## Notes

- Matches visual foundations in project README: Poppins ExtraBold lowercase display, Roboto body, sharp corners, signal-lime accent.
- No emoji; Unicode arrows (`→`) used for directional affordance.
- Hairline dividers instead of shadows on dark surface.
