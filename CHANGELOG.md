# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.8] - 2026-04-19

### Changed
- `/feature #<N>` now resolves directly from a GitHub issue number: fetches the issue via `gh issue view` or GitHub MCP, scans `docs/specs/` for a matching `Issue: #<N>` field, and proceeds with that spec. If no spec is linked, treats the issue title/body as the feature description and asks whether to spec first or build inline.

## [0.5.7] - 2026-04-19

### Changed
- `/feature` gains `--commit` and `--pr` flags for hands-free finishing. `--commit` auto-commits using `/commit`'s grouping logic but skips plan presentation — outputs only `git log --oneline -N`. `--pr` implies `--commit` and also pushes + opens a PR without draft presentation — outputs only the log lines and PR URL. All other output is suppressed when either flag is active. Intended for use in orchestrated flows or when the user trusts the implementation enough to skip the intermediate review step.

## [0.5.6] - 2026-04-18

### Fixed
- `/rlabs-design` — surface-specific kit loading is now mandatory (slides → `slides/index.html`; website → all `ui_kits/website/` components; app → all `ui_kits/app/` components), and `assets/` + `preview/` specimen files are enumerated as first-class references rather than buried under "explore the other available files". Reading only `colors_and_type.css`/`tokens.css` was producing off-brand output because tokens alone don't convey component composition or spacing rhythm.
- `/rlabs-design` — Playwright fidelity check is now required after applying the design: screenshot the matching reference `index.html` and the output at 1440×900 (and 390×844 if mobile in scope), compare against an explicit brand-rule checklist (typography, palette, radii, spacing, borders, motion, copy), fix drift in place, then report. Falls back to a stated manual check if Playwright is unavailable rather than silently skipping verification.

## [0.5.5] - 2026-04-18

### Fixed
- `/spec` — collapsed the three restatements of the `NNN`-prefix rule (Hard Requirements, Spec Numbering, Slice section) into one **Spec Numbering & Path** section, and the two copies of the trunk-metadata field definitions (Slices table columns + single-file `## Trunk Metadata` block) into one shared subsection. Same rules, stated once each.
- `/issues` — dependency references in issue bodies now use `{{issue:<slice-id>}}` placeholders during creation and get rewritten to real `#N` values in a second pass once the `slice-id → #N` mapping is known. Writing raw `#001`, `#002` during creation auto-linked those tokens to whatever issues already existed in the repo (issue #1, #2, …), silently producing wrong cross-references. The per-milestone loop now runs pass 2 before writing back to source spec files so downstream references use final issue numbers.

## [0.5.4] - 2026-04-18

### Fixed
- `/spec` now prefixes every spec with a zero-padded `NNN` that mirrors the roadmap phase number (`docs/specs/002_jira-sync.md`), with `.A`/`.B` letter suffixes when a phase has multiple specs. Sliced specs use the directory form `docs/specs/NNN_<feature>/` with `README.md` + `MMM_<slice>.md` inside — the directory itself is how "sliced" is identified, no extra marker. Previously spec filenames carried no ordering signal, so reading `docs/specs/` gave no hint which came first or how specs mapped back to roadmap phases. `/roadmap`, `/feature`, and `/issues` updated to reference the new prefixed paths.

## [0.5.3] - 2026-04-18

### Fixed
- `/feature` and `/fix` no longer commit, push, or open PRs — both stop after implementation, verification, and self-review with a structured report (files changed, lint/typecheck/test tail, security verdict, slice metadata, suggested commit subjects). The previous `--pr` flag and auto-commit step quietly turned every run into a shipped PR before the user had a chance to read the diff; the user reviews the working tree, then ships via `/commit` + `/pr`. Orchestrators (`/autopilot`, `/factory`) keep their auto-commit/PR behavior — that is where it earns its keep.
- `/feature` `Asking the user questions` rule now requires the `AskUserQuestion` tool for every mid-flight decision (missing spec, slice-size override, split shape, ambiguous metadata) — free-text prompts were ambiguous to parse and easy to skip.

### Changed
- Canonical feature flow in `CLAUDE.md` now reads: `/spec → (slice if >200 lines) → /issues → /feature <spec> → review the diff → /commit → /pr → /review → merge → cleanup`.
- `docs/TRUNK_BASED_WORKFLOW.md` and `docs/REFERENCE.md` recipes updated to drop `--pr` from `/feature` and `/fix`.

## [0.5.2] - 2026-04-18

### Fixed
- `/issues` now uses the `AskUserQuestion` tool for every interactive decision — drift/gone reconciliation, dry-run confirmation, roadmap-index horizon, and the per-milestone "proceed to next phase?" loop. Free-text confirmations were easy to miss and ambiguous to parse ("ok", "sure", "go"); structured options make each decision one click with an explicit recommended default, and batch the horizon + dry-run prompts into a single call on roadmap-index runs.

## [0.5.1] - 2026-04-18

### Added
- `/issues` — **two-milestone horizon** as the default pacing recommendation for roadmap-index inputs. The skill now proposes filing only the current phase + the next phase (not the entire roadmap), names the phases it's skipping, and asks before filing more. Rolling forward is idempotent: re-running advances the window once phases complete. This is the team practice that translates cleanly to solo work — it gives team discipline (issue-per-PR, milestone-scoped) without team overhead (stale labels, quarter-long backlogs, triage meetings).

### Changed
- `/issues` "After writing" guidance now reinforces the horizon: when the current phase is roughly halfway done, re-run to file the next-next phase.

## [0.5.0] - 2026-04-18

### Added
- `/issues` skill — files GitHub milestones (one per phase) and issues (one per task/slice) from `docs/roadmap/*.md` and `docs/specs/*.md`. Polymorphic input: a roadmap index, a single phase, a sliced spec's `README.md`, or a single-file spec. Uses the GitHub MCP as the primary transport with `gh` CLI as a fallback. Per-milestone confirmation loop keeps broken runs recoverable. Writes issue numbers back into the source Markdown so `/feature` can derive branch names.
- Label taxonomy bootstrapped on first `/issues` run: `type:feat|fix|refactor|chore|test|docs|perf|security`, `complexity:low|med|high`, `mvp|post-mvp`, `needs-spec|spec-ready|blocked`, each with a default color.

### Changed
- `/spec` now emits a trunk-aware Slices table with `Type`, `Flag`, `Depends on`, `Complexity`, and `Issue` columns — the table is the source of truth for `/issues`. Single-file specs get a `## Trunk Metadata` block with the same fields so `/issues` can file them too.
- `/roadmap` tasks now carry `Type`, `Feature flag`, `Milestone`, and `Issues` fields. `complexity:high` tasks must point at a sliced directory-form spec (one PR per slice). Phase template gains a `## Trunk Alignment` section naming flags and shipping state.
- `/feature` derives branch names from the spec's `Issue` field — canonical form is `<type>/<issue-number>-<slug>` (e.g., `feat/42-jira-sync`). Falls back to `<type>/<slug>` when no issue is filed yet. PR body now requires `Closes #<N>` and a `Feature flag` line matching the spec.
- Canonical feature flow in `CLAUDE.md` now reads: `/spec → (slice if >200 lines) → /issues → /feature <spec> --pr → /review → merge → cleanup`.

## [0.4.0] - 2026-04-18

### Added
- `docs/TRUNK_BASED_WORKFLOW.md` — full guide explaining the shift from Git Flow to trunk-based development, why it fits AI-assisted work, the seven rules, skill-enforcement table, recipes, and FAQ.
- `Trunk-Based Workflow` section in global `CLAUDE.md` codifying branch naming (`feat/*`, `fix/*`, `refactor/*`, `docs/*`, `chore/*`, `test/*`, `perf/*`, `security/*`), short-lived branches, ≤200-line slices, feature-flag expectations, worktree placement, and delete-after-merge.
- Slicing step in `/spec`: when a feature is estimated >200 lines, produces sub-specs under `docs/specs/<feature>/NNN_<slice>.md` with an index `README.md` and per-slice feature-flag section.
- `## Feature Flag` section in the single-file spec template.
- Branch precondition + slice-size gate in `/feature` and `/fix` (blocks commits when `git diff --stat` exceeds ~200 lines; requires explicit user override).
- Branch-name validation, diff-size warning, and post-merge cleanup reminder in `/pr`.

### Changed
- `PR Structure` in `CLAUDE.md` now cross-references the new Trunk-Based Workflow section for slicing and feature-flag rules.
- `docs/REFERENCE.md` overview now points at `TRUNK_BASED_WORKFLOW.md` alongside `WORKFLOW.md`.

## [0.3.0] - 2026-04-18

### Added
- `extras/` opt-in tree with `--extra` flag on `install.sh` for personal add-ons that stay outside the core workflow.
- `/rlabs-design` as the first extra — personal brand design system (tokens, typography, assets, UI kits, preview cards). Installed only when `./install.sh --extra` is passed.

### Changed
- Project-wide docs moved from `docs/specs/` to `docs/` root: `ARCHITECTURE.md`, `TECHNICAL_DESIGN_DOCUMENT.md`, and `THREAT_MODEL.md`. `docs/specs/` is now reserved for individual feature specs only.
- All skill references updated accordingly across `architecture`, `tdd`, `security`, `adr`, `rfc`, `spec`, `roadmap`, `design`, `autopilot`, `feature`, `fix`, `review` skills, plus `README.md` and `docs/REFERENCE.md`.

## [0.2.0] - 2026-04-15

### Added
- Multi-platform support: Cursor and OpenAI Codex CLI adapters alongside Claude Code (`aiwf install-cursor`, `aiwf install-codex`, `aiwf install-all`).
- `/design` skill for producing distinctive, production-grade UI designs via the Paper.design MCP, including multi-hue palette and accessibility guidance.
- `/verify-design` skill — diffs the running UI against Paper refs with Playwright and fixes mismatches in place.
- `/factory` skill — end-to-end delivery pipeline that reads the roadmap, generates specs, and runs parallel `/feature` agents.
- `/commit` and `/pr` skills for splitting the working tree into logical conventional commits and opening pull requests.
- Roadmap skill now requires an MVP boundary in every full roadmap and numbers phase files with a `001_` prefix.
- Verification, UI work, file convention, and git workflow sections added to the global `CLAUDE.md`.

### Changed
- `/feature` skill rewritten (v2) with benchmark-driven trims.
- `/design` skill pushed toward distinctive aesthetic commitments.
- Skill descriptions polished, guardrails reframed, and model guidance added across the suite.
- Enabled 8 additional `claude-plugins-official` plugins in `settings.json`.
- `WORKFLOW.md` and `REFERENCE.md` moved under `docs/`.

### Deprecated
- In-repo `/code-review` skill deprecated in favor of Anthropic's official `code-review` skill from `claude-code-plugins` (benchmark showed no detection lift at ~1.5× the cost). Language-specific review guides in `reviews/` remain in use by `/review`, `/feature`, and `/fix`.

### Fixed
- Codex adapter: install skills as native Codex skills under `~/.agents/skills/aiwf-*/`, write `AGENTS.md` (not `instructions.md`), and raise `project_doc_max_bytes` so `AGENTS.md` is not truncated.

### Documentation
- README and `REFERENCE.md` updated for multi-platform support.
- References refreshed for `/design`, `/verify-design`, and `/factory`; review-layer diagram fixed.
- Bare `code-review` references disambiguated as Anthropic's skill.
- Codex invocation clarified as `$<name>` with symlink layout documented.

## [0.1.0] - 2026-04-11

Initial tagged release: full SDLC toolkit for AI-assisted coding — skills, agents, review guides, hooks, and the `aiwf` launcher for Claude Code.

[Unreleased]: https://github.com/0xrafasec/ai-workflow/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/0xrafasec/ai-workflow/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/0xrafasec/ai-workflow/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/0xrafasec/ai-workflow/releases/tag/v0.1.0
