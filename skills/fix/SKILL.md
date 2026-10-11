---
name: fix
description: "Diagnose and fix a bug from a description, a stack trace, or a GitHub issue link — reproduce and patch. Stops with a working tree the user can review. Use when the user says 'fix this', 'debug X', 'something is broken', 'why isn't Y working', pastes an error/traceback, or links an issue expecting a patch. Covers root-cause diagnosis, not just symptom patching."
argument-hint: "<description | issue link>"
---
Fix the bug described in $ARGUMENTS.

## Parse Arguments

The argument can be:
- **Bug description:** `/wf:fix users can't login when password contains special chars`
- **Issue link:** `/wf:fix https://github.com/org/repo/issues/42`

## Branch

Before writing code, ensure you are on a short-lived branch named `fix/<slug>`. If currently on `main`/`master`, create the branch now. See the global **Trunk-Based Workflow** in root `CLAUDE.md` for branch/worktree conventions.

## Steps

1. **Understand the bug**

   - If given an issue link: fetch it with `gh issue view` and read the full description, comments, and labels.
   - If given a description: use it directly.
   - Check for existing docs (`CLAUDE.md`, `README.md`, `docs/`) to understand the project context.

2. **Reproduce and locate**

   - Search the codebase for the relevant code paths (use Grep, Glob, read key files).
   - Identify the component, module, or layer where the bug lives.
   - If there are existing tests, run them to see the current failure state.
   - If reproduction requires specific steps, tell the user what you're doing.

3. **Diagnose root cause**

   - Read the relevant code carefully. Trace the data flow from input to failure point.
   - Check `git log` on the affected files for recent changes that may have introduced the bug.
   - Identify the root cause — not just the symptom. Explain it to the user in 1-2 sentences before proceeding.

4. **Discover test strategy** — Before writing the fix, understand the project's test approach:

   a. **Check for a documented strategy:** Read `docs/ARCHITECTURE.md` (in older projects, `docs/TECHNICAL_DESIGN_DOCUMENT.md`) — if it has a Testing Strategy section, follow it.
   b. **If there is none:** Infer from the codebase — look for existing test directories, frameworks, patterns, and naming conventions (same discovery as `/wf:feature` step 2).
   c. **Determine which test layers the bug touches** — a bug in a pure function needs a unit test; a bug in an API endpoint needs an integration test; a bug in a user flow may need an e2e test.

5. **Fix**

   - Make the minimal change that fixes the root cause. Don't refactor surrounding code.
   - Add regression tests at the appropriate layer(s):
     - **Unit test:** Always — proves the root cause logic is fixed
     - **Integration test:** If the bug is at a component boundary (API, database, service interaction)
     - **E2E test:** Only if the bug broke a critical user flow and no e2e coverage existed for it
   - Each regression test must fail without the fix and pass with it.
   - Run the project's test suite and fix any failures.

6. **Run quality checks** — Run the project's lint, typecheck, and test commands (check CLAUDE.md or Makefile for the right commands). Run ALL test layers, not just unit tests.

   **Slice-size gate (trunk-based).** Before reporting completion, run `git diff --stat main...HEAD -- . ':(exclude)**/tests/**' ':(exclude)**/*_test.*' ':(exclude)**/*.test.*' ':(exclude)**/test_*'` (or the same pathspec against `git diff` if working changes are unstaged). If the **non-test** diff exceeds **~500 lines**, stop and propose a split via **AskUserQuestion** — a "fix" that balloons into a refactor is two slices, not one. Never silently leave a >500-line fix in the working tree without the user's explicit override. Count hand-written source only: tests, generated files, lockfiles, pure moves or renames, and deletions do not count.

7. **Report and stop.** Do not review your own fix here — `/wf:pr` dispatches the fresh-context `wf:reviewer` agent once the commits exist. Summarize for the user:
   - **Root cause** — 1–2 sentences on what was actually broken.
   - **Files changed** — `git diff --stat` output, or a short list.
   - **Regression tests** — which layers (unit/integration/e2e) you added, where they live, how to re-run them.
   - **Verification** — lint / typecheck / test commands run and their tail output.
   - **Issue link** — if one was provided, so the user can reference it later.

   Suggested conventional-commit subject for when the user commits: `fix: <what was broken>` (describe the bug, not the change). Example: `fix: login fails when password contains special characters`.

   Then stop. The user reviews the working tree and decides next steps (typically `/wf:commit`, then `/wf:pr`, which runs the review).
