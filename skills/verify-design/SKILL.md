---
name: verify-design
description: "Diff current UI implementation against Paper design references and list mismatches before editing. Run before any UI work."
---
Verify current UI against Paper design references for: $ARGUMENTS

## Purpose

This skill is a **read-only pre-flight check**. It loads the project's Paper design references, reads the corresponding source files, and produces a structured mismatch report. No files are edited. The report is the output — use it to decide what to change before touching any code.

> Run this at the start of every UI task. Never edit UI code without completing this check first.

## Parse Arguments

- **No argument:** `/verify-design` — check all pages/screens found in the design docs
- **Page or route name:** `/verify-design owner` — check only that page (e.g., `owner/[vin]/page.tsx`)
- **Component name:** `/verify-design Hero` — check a specific component file
- **File path:** `/verify-design web/components/landing/Hero.tsx` — check a specific file

## Step 1: Locate Design References

Look for design docs in this priority order:

1. `docs/design/` — page-level design docs, screenshots, artboard exports
2. `docs/design/DESIGN_SYSTEM.md` — design tokens (colors, type, spacing, radii)
3. `docs/specs/` — feature specs that may include Paper artboard IDs (e.g., `96-0`, `IT-0`)
4. Any `plan.md` or `spec.md` in `specs/` that references Paper artboard IDs — extract the artboard mapping

Build a table of scope from the argument:

| Page / Component | Design Ref | Source File |
|-----------------|-----------|------------|
| Hero            | Paper 4P-0 | web/components/landing/Hero.tsx |
| Owner Dashboard | Paper 96-0 | web/app/(owner)/owner/[vin]/page.tsx |
| ...             | ...        | ...         |

If no design reference exists for a target, note it as **"No design ref found — skipping"** and continue.

**If no design docs exist at all**, stop:
> No design references found. Create them first with `/design` or add artboard exports to `docs/design/`.

## Step 2: Load Design Tokens

Read `docs/design/DESIGN_SYSTEM.md` if it exists. Extract:
- Color tokens (palette, semantic colors)
- Typography (font families, scale, weights, line heights)
- Spacing scale
- Border radii
- Shadow tokens

If the file doesn't exist, check the source config files directly:
- `web/app/globals.css` or `web/tailwind.config.ts` for CSS variables / Tailwind tokens
- `packages/shared/src/tokens/` or similar

Record the resolved token set — you'll use it to evaluate the source files.

## Step 3: Load Paper Artboard Context (if artboard IDs are available)

If the design docs reference Paper artboard IDs (e.g., `4P-0`, `MH-0`, `96-0`):

1. Use the Paper MCP tool `get_basic_info` to list artboards on the canvas
2. For each artboard ID in scope, call `get_screenshot` to capture the current state
3. Call `get_jsx` or `get_computed_styles` on the artboard's key nodes to extract exact values — **do not read sizes or colors from screenshots alone**

If the Paper MCP is not available or no artboard IDs are referenced, skip this step and rely on written design docs.

## Step 4: Read Source Files

For each in-scope page or component, read the corresponding source file(s). Look for files in:
- `web/app/` — Next.js routes
- `web/components/` — React components
- `web/app/globals.css` — global styles and tokens

Read every relevant file. Do not guess — if a component is composed of multiple files, read all of them.

## Step 5: Diff Against Design

For each in-scope item, compare the implementation against the design reference across these dimensions:

### Typography
- Font family (heading, body, mono)
- Font size at each level (h1–h6, body, caption)
- Font weight
- Line height
- Letter spacing
- Are arbitrary values used where tokens should be?

### Color
- Background colors — do they match design tokens?
- Text colors — heading, body, muted
- Border colors
- Shadow values
- Are raw hex values used where CSS variables or Tailwind tokens should be?

### Spacing & Layout
- Padding and margin (card padding, section gaps, component insets)
- Grid or flex layout structure (column count, column widths)
- Gap values between elements
- Max-width constraints on content areas

### Border & Radius
- Border radius values
- Border width and color

### Responsive Behavior
- Breakpoints used — do they match the design's device matrix?
- Layout changes at each breakpoint (e.g., single-column on mobile, two-column on desktop)
- Is the DTC drawer a full-screen Drawer on mobile and a Sheet on tablet+desktop?

### Component Structure
- Are all design-specified sections present? (e.g., header, timeline, grants panel)
- Loading, empty, error, and not-found states — are they all present?
- Are touch targets ≥ 44×44 CSS px on interactive elements?

### Animations
- Is `prefers-reduced-motion` respected?
- Are Framer Motion variants used (not ad-hoc `transition` props)?

## Step 6: Output the Mismatch Report

Produce a structured report. Do not edit any files.

```markdown
# Design Verification Report

**Date:** YYYY-MM-DD
**Scope:** [page/component names checked]
**Design refs loaded:** [list of docs / artboard IDs used]

## Summary

| Page / Component | Mismatches | Status |
|-----------------|-----------|--------|
| Hero.tsx        | 2          | ⚠ REVIEW |
| owner/[vin]/page.tsx | 0     | ✓ PASS |
| ...             | ...        | ...    |

**Overall:** PASS | REVIEW | FAIL
- PASS — zero mismatches
- REVIEW — mismatches found but all LOW severity
- FAIL — one or more HIGH or MEDIUM mismatches

---

## [Page / Component Name]

### HIGH
- **[Dimension]** `file/path:line` — Found: `value`, Expected: `value` (token: `--token-name`)
  > [one-line explanation of the impact]

### MEDIUM
- **[Dimension]** `file/path:line` — Found: `value`, Expected: `value`

### LOW
- **[Dimension]** `file/path:line` — Found: `value`, Expected: `value`

### No design ref
- [Component name] — No Paper artboard or design doc found. Skipped.

---

## What to do next

1. Review the HIGH findings above — these are the most visually impactful mismatches.
2. For each finding, confirm you want to fix it (some may be intentional deviations).
3. Then proceed with editing — or run `/verify-design <component>` again after changes.
```

**Severity guide:**

| Severity | Examples |
|----------|---------|
| HIGH | Wrong font family, wrong primary color, missing a whole page section, broken responsive layout |
| MEDIUM | Font size off by more than 2 steps, wrong spacing in a primary content area, missing loading/error state |
| LOW | 2px spacing off, shadow value slightly wrong, letter-spacing approximation, minor border-radius mismatch |

## Rules

1. **Read-only.** Do NOT edit any source file during this skill. The report is the only output.
2. **Source of truth order:** Paper artboard computed values > design doc written values > token config files > screenshots (lowest trust).
3. **Quote exact values.** Always show the found value and the expected value side by side. Never say "spacing looks off" without specifics.
4. **Token violations are HIGH.** Any hardcoded hex, px, or font name that should be a CSS variable or Tailwind token is at minimum MEDIUM.
5. **Missing states are HIGH.** If a loading, error, empty, or not-found state is absent for a user-facing page, it is a HIGH finding.
6. **Never skip responsive checks.** Even if the argument targets a single component, note if the component has no responsive breakpoint handling.
7. **Stop at the report.** Do not propose fixes inline. Do not ask "should I fix this?" — that disrupts the review. Produce the report, then wait.
