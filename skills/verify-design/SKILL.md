---
name: verify-design
description: "Diff current UI against Paper design refs with Playwright runtime fidelity checks, then fix mismatches in place. Run before (and during) UI work."
---
Verify current UI against Paper design references for: $ARGUMENTS

## Purpose

This skill does a **fix-in-place fidelity pass** against Paper design references. It:

1. Loads Paper artboards + design tokens (source of truth)
2. Reads the corresponding source files
3. Uses **Playwright** to exercise the running app at real viewports (desktop + mobile), capturing screenshots, console errors, and interaction flows
4. **Fixes** mismatches directly — do NOT stop at a report
5. Re-verifies with Playwright and runs lint / typecheck / tests before reporting done

> The user does NOT want a pure report. They want the issues found AND resolved in the same session. Only stop to ask if a mismatch looks intentional or the fix would change scope.

## Parse Arguments

- **No argument:** check all pages with design refs
- **Page / route name:** `/verify-design owner` — check that page
- **Component name / file path:** `/verify-design Hero` or `web/components/landing/Hero.tsx`

Arguments may include free-form notes from the user (specific bugs, reference screenshots, which page to use as a style anchor). Treat those as priority work items.

## Step 1 — Locate design references

Priority:
1. `docs/design/` (page-level docs, artboard exports, `DESIGN_SYSTEM.md`)
2. `specs/**/plan.md` / `tasks.md` / `spec.md` — extract Paper artboard IDs (e.g. `4P-0`, `96-0`, `15D-0`, `17M-0`)
3. `docs/specs/` / `docs/roadmap/` cross-refs

Build a scope table (Page → Paper artboard (desktop) → Paper artboard (mobile) → source file). If both a desktop and mobile artboard exist (e.g. `96-0` + `17M-0`), check **both**.

If no design docs exist at all, stop and tell the user to run `/design` first.

## Step 2 — Load design tokens

Read `docs/design/DESIGN_SYSTEM.md`, `web/app/globals.css`, and `web/tailwind.config.*`. Record palette, type scale, spacing, radii, shadows. Flag hardcoded values in source that duplicate a token.

## Step 3 — Load Paper artboard context

Use the Paper MCP:
- `get_basic_info` once per session
- `get_screenshot` on each artboard in scope (desktop + mobile)
- `get_jsx` / `get_computed_styles` on key nodes — **never read sizes/colors from screenshots alone**

## Step 4 — Read source files

Read every file the target page touches (page, components, global CSS, relevant UI primitives). Don't guess.

## Step 5 — Playwright runtime fidelity (MANDATORY for any UI check)

Ensure the dev server is running (`curl http://localhost:3000`). If it isn't, start it (`pnpm --filter web dev` in background) before using Playwright.

For each in-scope page, drive a real browser:

1. `browser_resize` to desktop (`1440x900`) → `browser_navigate` → `browser_take_screenshot` (full page)
2. `browser_resize` to mobile (`390x844`) → same navigation → full-page screenshot
3. `browser_console_messages` (`level: "error"`) — any runtime error is a HIGH finding
4. Exercise any interactive element the user flagged (menus, drawers, dialogs, forms):
   - Open it, screenshot, try to close it by every documented path (close button, Esc, backdrop click)
   - Trigger the same flow after `prefers-reduced-motion` if motion is in scope
5. Compare the Playwright screenshots against the corresponding Paper screenshots side by side. Diff typography, color, spacing, alignment, and overflow/clipping.

Record findings in memory (not a file) — severity guide below. Track hard failures (console errors, overflow clipping, inoperable controls) as **HIGH**.

## Step 6 — Fix in place

Apply targeted edits. Rules:

- **Don't rewrite entire components** unless truly necessary.
- Prefer token fixes (Tailwind class / CSS var) over ad-hoc values.
- Keep changes scoped to the mismatches found; do not bundle unrelated refactors.
- If a fix would change documented behavior or scope, stop and ask.
- For interactive bugs (menu can't close, backdrop error): fix the interaction, not just the visual.

## Step 7 — Re-verify

After edits:
1. Re-run the Playwright pass (desktop + mobile + interaction flow). Confirm screenshots match Paper and consoles are clean.
2. Run lint + typecheck + tests (`pnpm -w lint`, `pnpm -w typecheck`, `pnpm -w test` or the project's equivalents).
3. Paste the tail of each run to the user.

## Severity guide

| Severity | Examples |
|----------|---------|
| HIGH | Wrong font family, wrong primary color, missing page section, broken responsive layout, runtime console errors, inoperable interactive components (menu/drawer can't close), content overflow / clipping visible at a supported viewport |
| MEDIUM | Font size off by >2 steps, wrong spacing in a primary content area, missing loading/error state, token replaced by hardcoded value |
| LOW | ≤2px spacing drift, slightly off shadow, minor border-radius mismatch |

## Rules

1. **Fix, don't just report.** This skill modifies code. The final message is a summary of what changed + verification output, not a mismatch list.
2. **Source-of-truth order:** Paper computed values > design doc values > token config > screenshots (lowest trust).
3. **Quote exact values** in any before/after explanation.
4. **Token violations are at minimum MEDIUM.** Raw hex/px/font names that should be tokens get replaced.
5. **Missing states are HIGH.** Loading/empty/error/not-found for a user-facing page must exist.
6. **Never skip responsive checks.** Every target is exercised at desktop (1440x900) AND mobile (390x844) via Playwright.
7. **Never skip Playwright.** A static-only pass is not sufficient for this skill. If Playwright is unavailable, say so and stop.
8. **Only ask the user when scope changes** or when a "mismatch" looks like an intentional deviation you can't verify from the spec.

## Dispatch & model fit

This skill is a **single-pass agent**: one invocation reviews + fixes + re-verifies. Do not split into a separate "review" and "fix" cycle — that duplicates the Paper MCP + Playwright load and doubles spend for the same result.

Writer/reviewer separation (from global workflow rules) applies to *code-review* skills. `/verify-design` is a fidelity-fix skill, not a reviewer — it is authored to mutate code. Treating its output as a review-only gate is a misuse.

Model guidance for agents that dispatch this skill to sub-agents:

| Dispatch mode | Model | Rationale |
|---------------|-------|-----------|
| First-pass on a new/changed PR | Sonnet | Analytical comparison + targeted edits; Opus is overkill for rule-matching work |
| Re-verify against a prior delta list | Haiku | Checklist walking on a known set of items |
| Design + implementation from scratch in one shot | Opus | Wider synthesis, ambiguous token choice, layout decisions |

If invoked directly by the user (not via a parent agent), run in the current session at whatever model the user has chosen — do not downgrade for cost.
