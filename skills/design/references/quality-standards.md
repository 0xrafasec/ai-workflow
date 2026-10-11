# Design quality standards

Read before building the first screen. The goal is screens that feel crafted rather than generated: if one screenshot out of context could belong to any other SaaS product, it has failed.

## Avoid the generic

- Fonts: Inter, Roboto, Open Sans, Lato, Poppins, Arial or system-ui as the primary choice, unless the user asks for them.
- Colour: purple-to-blue gradient on white, Indigo 500 as the brand colour, framework defaults with no adjustment. (Neutral and semantic tokens may start from the template, adjusted to the palette.)
- Layout: centred hero over a three-column feature grid, evenly spaced same-size cards, perfect symmetry. Vary scale, weight and rhythm; let each flow group explore a different layout within the system; use bento-style asymmetric cards for dashboards.
- Copy: no "Lorem ipsum", "Your tagline here" or "Feature one". Write specific copy grounded in the PRD.
- Depth: not the same `shadow-md` and 8px radius on everything regardless of aesthetic.
- Icons: use inline SVG (24x24 viewBox, 1.5px stroke, round caps, 20-24px displayed) matched to the aesthetic's weight; a brutalist design wants heavier icons than a luxury one. Plain Unicode only for arrows, check and close, because glyphs like warning and gear render as coloured emoji.

## Layout

- Flex containers with `gap` for spacing (Paper's HTML import handles these reliably). Absolute positioning for decoration or deliberate grid-breaking.
- Content width: `max-width: 680px` for text and 1200px for full layouts, centred or deliberately offset inside the 1440px desktop artboard.
- Whitespace: at least 24px between sections, 48-80px between major blocks. Reduce chrome; separate with spacing and background tint instead of borders.

## Typography

- Strong weight contrast (100-200 against 700-900) and a display-to-body size jump of at least 3x.
- Headings 600-800 weight, line-height 1.05-1.2, letter-spacing -0.02em to -0.03em. Body 400 at line-height 1.5. Labels 500, uppercase with 0.05em tracking.
- Pair dissimilar fonts (display plus mono, serif plus geometric sans).

## Colour and depth

- 60-30-10: 60% neutral, 30% surface and secondary, 10% accent. Bold dominant colours with sharp accents; use the secondary hue for charts, categories and secondary calls to action.
- Near-black (#18181b) and near-white (#fafafa), never #000 or #fff. Subtle background differences between sections.
- Atmosphere: gradient backgrounds or geometric patterns over flat fills. Layered shadows such as `0 1px 3px rgba(0,0,0,0.06), 0 6px 16px rgba(0,0,0,0.06)`. Glassmorphism sparingly.
- Show hover and transition states where a static design can.

## Accessibility (design bugs, fix before moving on)

- Contrast: text at least 4.5:1, large text (18px bold or 24px) at least 3:1. Ratio is (L1 + 0.05) / (L2 + 0.05) on relative luminance.
- Colour is never the only signal: pair it with an icon, label or sign (status dots get text; positive and negative values get a +/- sign or arrow).
- Touch targets at least 44x44px with at least 8px between neighbours. Visible focus state (ring or outline, readable on light and dark) on every interactive element.
- Text: 12px minimum anywhere, 14px for anything users must read, 16px for body. Real text rather than images of text; logical heading order.

## Review checkpoint

After every 2-3 screens or each flow group, take screenshots and check: uneven or cramped spacing, hierarchy and readability, low contrast, alignment across rows, clipping at container or artboard edges, token consistency with the design system, and the accessibility list above. Fix with `update_styles` before moving on.
