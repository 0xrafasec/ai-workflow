---
name: feature
description: "Implement a feature end-to-end from a spec file at docs/specs/<name>.md — code it and verify it. Stops with a working tree the user can review. Supports --commit (auto-commit, output only log) and --pr (auto-commit + open PR, output only log + URL). Use when the user says 'implement the auth spec', 'build feature X', 'code up the Y spec', 'work through docs/specs/<name>.md', or points at a spec and asks to execute it."
---
Implement the feature described in $ARGUMENTS.

## Parse arguments

- `/feature <name>` → resolve to `docs/specs/NNN_<name>.md` (or `docs/specs/NNN_<name>/` for a sliced spec) by matching the suffix after the prefix. Specs carry a roadmap-phase-aligned `NNN` prefix — see `/spec` for the numbering rules. If multiple specs match, ask which.
- `/feature <path>.md` → use explicit path
- **`--commit`** — after the feature is complete and verified, auto-commit without presenting a plan for approval. Apply the same grouping logic from `/commit` but skip step 5 (plan presentation). Output only the `git log --oneline -<N>` lines for the new commits. No other output.
- **`--pr`** — implies `--commit`: auto-commit (as above), then immediately open a PR without presenting a draft for approval. Apply the same PR logic from `/pr` but skip step 7 (draft presentation). Output only the `git log --oneline -<N>` lines and the PR URL. No other output.

If the spec doesn't exist, use **AskUserQuestion** to ask whether to create one via `/spec <name>` first or build without a spec (they describe the feature inline). For bugfixes, use `/fix` instead.

**Asking the user questions.** Whenever this skill needs a decision from the user mid-flight (missing spec, slice-size override, split shape, ambiguous metadata, etc.), use the **AskUserQuestion** tool — never plain free-text prompts. Phrase the question clearly, lead with your recommendation as the first option labelled "(Recommended)", and keep options mutually exclusive. Free-text follow-up is always available to the user via the auto-injected "Other" choice, so don't pad with a custom-input option.

If the spec lives under `docs/specs/NNN_<feature>/` (sliced spec, per `/spec`'s trunk-based slicing), `/feature` implements **one slice at a time**. The argument must point to a specific slice file (`docs/specs/NNN_<feature>/MMM_<slice>.md`), never the index `README.md`.

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

   **Parallel implementation (safe-by-default).** When step 3 produced a file placement table, use the `depends on` column to partition rows into **waves**: Wave 0 = rows with no deps; Wave N = rows depending only on Waves 0..N-1. Within a wave, a set of rows is **parallel-safe** only if *all* of these hold:
   - 2+ rows in the wave.
   - Source files are fully disjoint across rows (no two rows edit the same file).
   - Test files are fully disjoint (no shared test module being mutated).
   - No shared test fixtures/factories/mocks are being *modified* (read-only shared fixtures are fine).
   - No row touches a shared config, schema, migration, or generated file (`package.json`, `pyproject.toml`, `go.mod`, `schema.sql`, OpenAPI, codegen outputs) — serialize those.
   - Test infrastructure (runners, CI config, conftest) is already in place — if step 2 is setting it up, do that inline first, then parallelize.
   If any check fails, implement that wave sequentially. When in doubt, serialize — a single retry costs less than a tangled merge.
   For each parallel-safe row in a wave, spawn an implementer subagent with `Agent(subagent_type: "general-purpose", model: "sonnet", ...)`. The prompt must be self-contained: spec path + relevant excerpt, the exact files to create/edit (and "do not touch any other file"), test placement rules from step 2, verification commands, and coding conventions from CLAUDE.md. Use `isolation: "worktree"` when a wave has 3+ agents to prevent working-tree contention; for 2 agents on disjoint files, same-tree is fine.
   After each wave: run the project's test suite, fix failures inline (do not respawn), then dispatch the next wave. Never pipeline waves — always barrier between them.
   If no placement table was produced (scope <6 files) or the table has <2 parallel-safe rows in every wave, implement inline. Do not force parallelism.

5. **Quality checks.** Run the project's lint, typecheck, and full test suite (check CLAUDE.md / Makefile for commands).

   **Slice-size gate (trunk-based).** Before reporting completion, run `git diff --stat main...HEAD` (or `git diff --stat` if working changes are unstaged). If the total diff exceeds **~200 lines** (tests included), stop and surface the overrun via **AskUserQuestion**:
   - If the spec is a single file: include a "ship as-is" override option plus 1–2 concrete split proposals (e.g., "Split into N sub-slices under `docs/specs/NNN_<name>/MMM_*.md`"). Recommend the option that best matches the diff shape — recommend "ship as-is" only when the bulk is mechanical (formatter reflow, generated lockfile, mass rename) and the substantive review surface is small.
   - If the spec is already one slice of a sliced feature: include "ship as-is", "defer hunks X/Y to a follow-up slice", and any other relevant choice for the user.

   Never silently leave a >200-line slice in the working tree. The gate can be overridden by the user ("ship as-is"), but never by the skill.

   **Feature flag wiring.** If the spec's `## Feature Flag` section names a flag, verify the new behavior is gated by it. If the flag doesn't exist yet in the project, create it (default off) as part of this slice.

6. **Self-review (parallel).** Catch the obvious stuff before handing back. Fire security and architecture reviews as concurrent `Agent` calls in a single message — they are independent and should not serialize.
   - Prefer Anthropic's official `code-review` skill (from `claude-code-plugins`) if installed.
   - Otherwise run `/sec-review` for security, and spawn an **architecture-reviewer** subagent (pin `model: "sonnet"`) for architecture, handing it the matching language guide from `reviews/` (`go.md`, `rust.md`, `typescript.md`, `python.md`).

   This is a self-check, not a trust boundary — you're the writer reading the reviewer. A fresh-session `/review` or a human reviewer is still expected before merge.

7. **Report and stop.**

   **If `--pr` or `--commit` was passed**, skip the summary below and go directly to the auto-commit/PR path described here:

   - **Auto-commit (`--commit` or `--pr`):** Apply `/commit`'s grouping and message logic (steps 1–4 of that skill) but skip plan presentation. Stage and commit each group sequentially without asking. On pre-commit hook failure, stop and surface the error — never bypass with `--no-verify`. After all commits land, output only `git log --oneline -<N>` (where N = number of new commits). Nothing else.

   - **Auto-PR (only when `--pr`):** After auto-commit, apply `/pr`'s push and body-drafting logic (steps 1–6 of that skill) but skip draft presentation. Push the branch and create the PR immediately. Output only the PR URL. Nothing else.

   - **Combined output for `--pr`:** one `git log --oneline -<N>` block followed by one PR URL line. No headers, no summaries, no reminders.

   **Otherwise (no flag),** summarize for the user:
   - **Files changed** — `git diff --stat` output, or a short list.
   - **Verification** — lint / typecheck / test commands run and their tail output.
   - **Self-review verdict** — `Security: PASS` / `REVIEW` / `FAIL` from step 6 (or `Security: PASS (no new inputs/auth/io surface)` when zero surface).
   - **Slice metadata** — for the eventual PR body the user will write: spec link, `Closes #<N>` line from the spec's `Issue:` field (or `Closes: (none — ran before /issues)`), feature-flag state from `## Feature Flag`, and a one-paragraph test plan (which layers were touched, how to re-run them).

   Then stop. The user reviews the working tree and decides next steps (typically `/commit` then `/pr`).
