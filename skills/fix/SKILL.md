---
name: fix
description: "Diagnose and fix a bug: /fix <description or issue link>"
---
Fix the bug described in $ARGUMENTS.

## Parse Arguments

The argument can be:
- **Bug description:** `/fix users can't login when password contains special chars`
- **Issue link:** `/fix https://github.com/org/repo/issues/42`
- **Description + `--pr`:** `/fix <description> --pr` — fix, commit, push, create PR
- **Description + `--pr <branch>`:** `/fix <description> --pr develop` — fix, commit, push, PR to specific branch

Default behavior is **commit only, no PR**.

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

4. **Fix**

   - Make the minimal change that fixes the root cause. Don't refactor surrounding code.
   - Add a regression test that fails without the fix and passes with it.
   - Run the project's test suite and fix any failures.

5. **Run quality checks** — Run the project's lint, typecheck, and test commands (check CLAUDE.md or Makefile for the right commands).

6. **Stack-aware code review** — Run `/code-review` to perform a full stack-aware review.

   If `/code-review` is not available, fall back to: run `/sec-review` for security, then spawn an architecture-reviewer subagent.

7. **Address findings** — Fix any HIGH severity issues from the review. For MEDIUM issues, use your judgment.

8. **Commit** — Use `fix:` conventional commit message. The message should describe what was broken, not what you changed. Example: `fix: login fails when password contains special characters`.

9. **Ship (conditional):**

   - **No `--pr` flag (default):** Stop here. Tell the user: "Bug fixed and committed on `<current-branch>`."

   - **`--pr`:** Push the current branch and create a PR targeting the repo's default branch (usually `main`).

   - **`--pr <base-branch>`:** Push the current branch and create a PR targeting the specified base branch.

   PR contents:
     - Summary: what was broken and why
     - Root cause analysis (1-2 sentences)
     - What the fix does
     - Regression test description
     - Security review verdict (PASS/REVIEW/FAIL from step 6)
     - Link to issue (if one was provided)
