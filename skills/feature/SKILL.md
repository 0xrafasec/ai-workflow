---
name: feature
description: "Implement a feature end-to-end from a spec file at docs/specs/<name>.md — code it, commit in logical chunks, optionally push + open a PR. Use when the user says 'implement the auth spec', 'build feature X', 'code up the Y spec', 'work through docs/specs/<name>.md', or points at a spec and asks to execute it."
---
Implement the feature described in $ARGUMENTS.

## Parse arguments

- `/feature <name>` → `docs/specs/<name>.md`, commit only
- `/feature <path>.md` → use explicit path
- `--pr` → also push + open PR (default target: `main`)
- `--pr <branch>` → push + open PR targeting `<branch>`

If the spec doesn't exist, use **AskUserQuestion** to ask whether to create one via `/spec <name>` first or build without a spec (they describe the feature inline). For bugfixes, use `/fix` instead.

**Asking the user questions.** Whenever this skill needs a decision from the user mid-flight (missing spec, slice-size override, split shape, ambiguous metadata, etc.), use the **AskUserQuestion** tool — never plain free-text prompts. Phrase the question clearly, lead with your recommendation as the first option labelled "(Recommended)", and keep options mutually exclusive. Free-text follow-up is always available to the user via the auto-injected "Other" choice, so don't pad with a custom-input option.

If the spec lives under `docs/specs/<feature>/` (sliced spec, per `/spec`'s trunk-based slicing), `/feature` implements **one slice at a time**. The argument must point to a specific slice file (`docs/specs/<feature>/NNN_<slice>.md`), never the index `README.md`.

## Branch

Before writing code, ensure you are on a short-lived branch named for this slice, **always cut from `main`** (never from another feature branch — trunk forbids stacking).

Branch-name resolution order:
1. If the spec's `## Trunk Metadata` (or its row in the Slices table) has a filled `Issue: #<N>` field, use `<type>/<N>-<slug>` — e.g., `feat/42-jira-sync`. This is the canonical form after `/issues` has run.
2. If no issue is filed yet, fall back to `<type>/<slug>` — e.g., `feat/jira-sync`. When the issue later gets filed, do NOT rename the branch mid-flight; keep the name and put `Closes #<N>` in the PR body.
3. `<type>` comes from the spec's `Type` field (`feat`/`fix`/`refactor`/`chore`/`test`/`docs`/`perf`/`security`).

If the spec is missing `Type` or `Issue`, warn the user and pick the most conservative default (`feat/<slug>`). Don't silently guess.

See the global **Trunk-Based Workflow** in root `CLAUDE.md` for worktree conventions.

## Workflow

1. **Read the spec.** Note the Verification Criteria — your tests must cover each one.

2. **Pick a test strategy.** Read `docs/TECHNICAL_DESIGN_DOCUMENT.md` if it exists; otherwise infer from the project (test dirs, `package.json` / `pyproject.toml` / `Makefile`, 1–2 existing test files). Unit tests always; integration tests when the feature crosses boundaries (API, DB, filesystem, subprocess); e2e only for critical user flows. If no tests exist yet, set up the minimum infrastructure and tell the user.

   **Test placement is a contract, not an implementation detail.** If the spec or existing project structure distinguishes `tests/unit/` from `tests/integration/` (or equivalent layout), mirror that distinction in directory placement based on *what the test covers*, not *how you wrote it*. A test that exercises a module across a real boundary (Qdrant container, respx-stubbed HTTP, tmp_path filesystem) belongs in `tests/integration/` even if it runs fast and mocks a few leaves. A test of pure logic belongs in `tests/unit/` even if the function happens to be in a service-layer file. Getting this wrong scatters integration coverage into the unit suite, where it drifts out of the slow-path CI filter and stops catching the boundary regressions it exists to catch.

3. **Plan if non-trivial.** Touches 3+ files or has non-obvious design decisions? Use Plan Mode to align before writing code.

   For larger scopes (6+ files or multi-phase work), before writing any code produce a **file placement table** derived from the spec — one row per module, with columns: `(source file, test file, test type, depends on)`. This forces you to resolve test-type ambiguity up front against the spec's language, catches underspecified corners, and gives the user a checkpoint before the implementation commits to a structure. If the project already has a `tasks.md` or equivalent task breakdown (e.g., from `/speckit-tasks`), treat it as the source of truth for file paths and test placement and skip generating a duplicate table.

4. **Implement with tests, layer by layer.** Unit → integration → e2e. Run each layer and fix failures before moving on. Tests must cover every Verification Criterion.

5. **Quality checks.** Run the project's lint, typecheck, and full test suite (check CLAUDE.md / Makefile for commands).

   **Slice-size gate (trunk-based).** Before committing, run `git diff --stat main...HEAD` (or `git diff --stat` if nothing is committed yet). If the total diff exceeds **~200 lines** (tests included), stop and surface the overrun via **AskUserQuestion**:
   - If the spec is a single file: include a "ship it anyway" override option plus 1–2 concrete split proposals (e.g., "Split into N sub-slices under `docs/specs/<name>/NNN_*.md`"). Recommend the option that best matches the diff shape — recommend "ship it anyway" only when the bulk is mechanical (formatter reflow, generated lockfile, mass rename) and the substantive review surface is small.
   - If the spec is already one slice of a sliced feature: include "ship anyway", "defer hunks X/Y to a follow-up slice", and any other relevant choice for the user.

   Never silently ship a >200-line slice. The gate can be overridden by the user ("ship it anyway"), but never by the skill.

   **Feature flag wiring.** If the spec's `## Feature Flag` section names a flag, verify the new behavior is gated by it before committing. If the flag doesn't exist yet in the project, create it (default off) in the same slice.

6. **Pre-PR self-review.** You are about to ask someone to merge this — catch the obvious stuff first.
   - Prefer Anthropic's official `code-review` skill (from `claude-code-plugins`) if installed.
   - Otherwise run `/sec-review` for security, and spawn an **architecture-reviewer** subagent for architecture, handing it the matching language guide from `reviews/` (`go.md`, `rust.md`, `typescript.md`, `python.md`).

   This is a self-check, not a trust boundary — you're the writer reading the reviewer. Before merge, a fresh-session `/review` or a human reviewer is still required.

7. **Commit, split by logical concern.** Each commit must leave the codebase working. Use conventional messages (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, etc.). Split boundaries that tend to work:
   - A CRUD feature: `db/models` → `schemas/validation` → `endpoints/handlers` → `tests`
   - A refactor: one commit per extracted module (with its tests)
   - A pure utility: one `feat:` commit, one `test:` commit if tests landed separately
   - `docs:` and chore config changes always get their own commit
   
   A single `feat: do the thing` + `docs: add PR body` is almost never the right split — if you're tempted to ship that, look again.

8. **Ship (conditional).**
   - **No `--pr`:** Stop. Tell the user: "Feature implemented and committed on `<current-branch>`. Run with `--pr` when ready to open a PR."
   - **`--pr` / `--pr <base>`:** Push current branch, open PR against `main` (or `<base>`). The PR body **must** contain all of:
     - **Summary** — 1–3 bullets: what changed and why
     - **Spec** — link to `docs/specs/<name>.md` (or the specific slice file)
     - **Closes** — `Closes #<N>` for the tracking issue (from the spec's `Issue:` field). If the slice has no issue yet, write `Closes: (none — ran before /issues)` and open the issue afterwards. Never ship a slice without a tracked issue for more than one merge cycle.
     - **Feature flag** — name the flag and its default state, or `Flag: none (ships user-ready)`. Must match the spec's `## Feature Flag` section.
     - **Security review** — verdict line: `Security: PASS` / `REVIEW` / `FAIL` (from step 6). Never omit this. If the feature has zero security surface, write `Security: PASS (no new inputs/auth/io surface)` so reviewers know you considered it.
     - **Test plan** — which layers (unit/integration/e2e), what they cover, how to run each
