---
name: feature
description: "Implement a feature end-to-end from a spec file at docs/specs/<name>.md — code it and verify it. Stops with a working tree the user can review. Supports --commit (auto-commit) and --pr (auto-commit, open the PR, run its review). Use when the user says 'implement the auth spec', 'build feature X', 'code up the Y spec', 'work through docs/specs/<name>.md', or points at a spec and asks to execute it."
argument-hint: "<spec name | path | #issue> [--commit | --pr]"
---
Implement the feature described in $ARGUMENTS.

## Parse arguments

- `/wf:feature <name>` → resolve to `docs/specs/NNN_<name>.md` (or `docs/specs/NNN_<name>/` for a sliced spec) by matching the suffix after the prefix. Specs carry a roadmap-phase-aligned `NNN` prefix — see `/wf:spec` for the numbering rules. If multiple specs match, ask which.
- `/wf:feature <path>.md` → use explicit path
- `/wf:feature #<N>` → fetch the GitHub issue `#<N>` via `gh issue view <N>`, extract the title and body, then resolve the spec by scanning `docs/specs/` for a file whose `Issue: #<N>` field matches. If found, proceed with that spec. If not found, treat the issue title/body as the feature description and ask (via **AskUserQuestion**) whether to create a spec first or build inline.
- **`--commit`** — after the feature is complete and verified, commit by following the `/wf:commit` skill, skipping only the step where it presents the commit plan for approval. Output only the `git log --oneline -<N>` lines for the new commits.
- **`--pr`** — implies `--commit`, then open the PR by following the `/wf:pr` skill, skipping only the step where it presents the title and body for approval. `/wf:pr`'s fresh-context review loop still runs. Output only the `git log` lines, the PR URL, and the review verdict.

If the spec doesn't exist, use **AskUserQuestion** to ask whether to create one via `/wf:spec <name>` first or build without a spec (they describe the feature inline). For bugfixes, use `/wf:fix` instead.

**Asking the user questions.** Whenever this skill needs a decision from the user mid-flight (missing spec, slice-size override, split shape, ambiguous metadata, etc.), use the **AskUserQuestion** tool — never plain free-text prompts. Phrase the question clearly, lead with your recommendation as the first option labelled "(Recommended)", and keep options mutually exclusive. Free-text follow-up is always available to the user via the auto-injected "Other" choice, so don't pad with a custom-input option.

If the spec lives under `docs/specs/NNN_<feature>/` (sliced spec, per `/wf:spec`'s trunk-based slicing), `/wf:feature` implements **one slice at a time**. The argument must point to a specific slice file (`docs/specs/NNN_<feature>/MMM_<slice>.md`), never the index `README.md`.

## Branch

Before writing code, ensure you are on a short-lived branch named for this slice, **always cut from `main`** (never from another feature branch — trunk forbids stacking).

Branch-name resolution order:
1. If the spec's `## Trunk Metadata` (or its row in the Slices table) has a filled `Issue: #<N>` field, use `<type>/<N>-<slug>` — e.g., `feat/42-jira-sync`. This is the canonical form after `/wf:issues` has run.
2. If no issue is filed yet, fall back to `<type>/<slug>` — e.g., `feat/jira-sync`. When the issue later gets filed, do NOT rename the branch mid-flight; keep the name and put `Closes #<N>` in the PR body.
3. `<type>` comes from the spec's `Type` field (`feat`/`fix`/`refactor`/`chore`/`test`/`docs`/`perf`/`security`).

If the spec is missing `Type` or `Issue`, warn the user and pick the most conservative default (`feat/<slug>`). Don't silently guess.

See the global **Trunk-Based Workflow** in root `CLAUDE.md` for worktree conventions.

## Workflow

1. **Read the spec.** Note the Verification Criteria — your tests must cover each one.

2. **Pick a test strategy.** Read the Testing Strategy in `docs/ARCHITECTURE.md` (in older projects, `docs/TECHNICAL_DESIGN_DOCUMENT.md`) if it exists; otherwise infer from the project (test dirs, `package.json` / `pyproject.toml` / `Makefile`, 1–2 existing test files). Unit tests always; integration tests when the feature crosses boundaries (API, DB, filesystem, subprocess); e2e only for critical user flows. If no tests exist yet, set up the minimum infrastructure and tell the user.

   **Test placement is a contract, not an implementation detail.** If the spec or existing project structure distinguishes `tests/unit/` from `tests/integration/` (or equivalent layout), mirror that distinction in directory placement based on *what the test covers*, not *how you wrote it*. A test that exercises a module across a real boundary (Qdrant container, respx-stubbed HTTP, tmp_path filesystem) belongs in `tests/integration/` even if it runs fast and mocks a few leaves. A test of pure logic belongs in `tests/unit/` even if the function happens to be in a service-layer file. Getting this wrong scatters integration coverage into the unit suite, where it drifts out of the slow-path CI filter and stops catching the boundary regressions it exists to catch.

3. **Plan if non-trivial.** Touches 3+ files or has non-obvious design decisions? Use Plan Mode to align before writing code.

4. **Implement with tests, layer by layer.** Unit → integration → e2e. Run each layer and fix failures before moving on. Tests must cover every Verification Criterion.

5. **Quality checks.** Run the project's lint, typecheck, and full test suite (check CLAUDE.md / Makefile for commands).

   **Slice-size gate (trunk-based).** Before reporting completion, run `git diff --stat main...HEAD -- . ':(exclude)**/tests/**' ':(exclude)**/*_test.*' ':(exclude)**/*.test.*' ':(exclude)**/test_*'` (or the same pathspec against `git diff` if working changes are unstaged). If the **non-test** diff exceeds **~200 lines**, stop and surface the overrun via **AskUserQuestion**:
   - If the spec is a single file: include a "ship as-is" override option plus 1–2 concrete split proposals (e.g., "Split into N sub-slices under `docs/specs/NNN_<name>/MMM_*.md`"). Recommend the option that best matches the diff shape — recommend "ship as-is" only when the bulk is mechanical (formatter reflow, generated lockfile, mass rename) and the substantive review surface is small.
   - If the spec is already one slice of a sliced feature: include "ship as-is", "defer hunks X/Y to a follow-up slice", and any other relevant choice for the user.

   Never silently leave a >200-line slice in the working tree. The gate can be overridden by the user ("ship as-is"), but never by the skill.

   **Feature flag wiring.** If the spec's `## Feature Flag` section names a flag, verify the new behavior is gated by it. If the flag doesn't exist yet in the project, create it (default off) as part of this slice.

6. **Report and stop.** Do not review your own work here. The fresh-context review belongs to `/wf:pr`, which dispatches the `wf:reviewer` agent once the commits exist — reviewing an uncommitted tree from the context that wrote it is the thing the writer/reviewer rule forbids.

   **With `--commit` or `--pr`,** run the flow described under Parse arguments. On a pre-commit hook failure, stop and surface the error — never bypass with `--no-verify`.

   **Otherwise (no flag),** summarize for the user:
   - **Files changed** — `git diff --stat` output, or a short list.
   - **Verification** — lint / typecheck / test commands run and their tail output.
   - **Slice metadata** — for the eventual PR body the user will write: spec link, `Closes #<N>` line from the spec's `Issue:` field (or `Closes: (none — ran before /wf:issues)`), feature-flag state from `## Feature Flag`, and a one-paragraph test plan (which layers were touched, how to re-run them).

   Then stop. The user reviews the working tree and decides next steps (typically `/wf:commit`, then `/wf:pr`, which runs the review).
