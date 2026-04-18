# Icons

Rlabs uses **[Lucide](https://lucide.dev/)** as its icon system.

- 24px default size, 1.75px stroke, rounded caps
- Color is always `currentColor` — icons inherit text color
- Stroke-only in product UI; solid variants only for status dots

## Loading

### CDN (recommended for prototypes)
```html
<script src="https://unpkg.com/lucide@latest"></script>
<script>lucide.createIcons();</script>
```

### React
```bash
npm install lucide-react
```
```jsx
import { Zap, Link2, Shield } from 'lucide-react';
<Zap size={24} strokeWidth={1.75} />
```

## Brand-specific marks

Custom marks that are NOT part of Lucide live in `assets/logo/` and `assets/brand/`:

- `logo/rlabs-logo.svg` — full wordmark
- `logo/rlabs-mark.svg` — square monogram (favicon, app icon)
- `brand/chain-glyph.svg` — decorative nodes-and-links motif

## Substitution flag

If Rlabs has a proprietary icon set, replace Lucide and update this file. The current setup is a placeholder matched to the modern/clean aesthetic.
