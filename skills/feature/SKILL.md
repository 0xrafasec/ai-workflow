---
name: feature
description: Implement a feature from a spec file following the workflow
---
Implement the feature described in $ARGUMENTS.

## Parse Arguments

The argument can be:
- **Just a spec path:** `/feature docs/specs/auth.md` — implement, commit, no PR
- **Spec path + `--pr`:** `/feature docs/specs/auth.md --pr` — implement, commit, push, create PR
- **Spec path + `--pr <branch>`:** `/feature docs/specs/auth.md --pr feat/auth` — implement, commit, push to specific branch, create PR

Default behavior is **commit only, no PR**. The user controls when to ship.

## Steps

1. **Read the spec** at the provided path. Understand the problem, solution, technical design, security considerations, and verification criteria thoroughly.

2. **Check for a roadmap task** — Look in `docs/roadmap/` for a task referencing this spec. If found, note dependencies and verification commands.

3. **Plan the implementation** — If the feature is complex (touches 3+ files or has non-obvious design decisions), use Plan Mode to align on the approach before writing code. Otherwise, proceed directly.

4. **Implement with tests** — Write the implementation and tests together. Tests must cover all verification criteria from the spec. Run the test suite after implementation and fix any failures.

5. **Run quality checks** — Run the project's lint, typecheck, and test commands (check CLAUDE.md or Makefile for the right commands).

6. **Security review** — Run `/sec-review` (the full security audit with 4 parallel agents). This is more thorough than just spawning the security-reviewer agent. It covers injection, auth/crypto, data exposure, and config/supply chain in parallel.

7. **Architecture review** — Spawn an architecture-reviewer subagent to review your changes for pattern consistency, separation of concerns, unnecessary abstractions, and API stability.

8. **Address findings** — Fix any HIGH severity issues from both reviews. For MEDIUM issues, use your judgment. Re-run the affected review if you made significant changes.

9. **Commit** — Use conventional commit messages (feat:, fix:, refactor:, etc.). Split by logical concern. Each commit should leave the codebase working.

10. **Ship (conditional):**

    - **No `--pr` flag (default):** Stop here. Tell the user: "Feature implemented and committed on `<current-branch>`. Run with `--pr` when ready to open a PR."

    - **`--pr`:** Push the current branch and create a PR targeting the repo's default branch (usually `main`).

    - **`--pr <base-branch>`:** Push the current branch and create a PR targeting the specified base branch. Example: `--pr develop` opens a PR from your current branch into `develop`.

    PR contents:
      - Summary (1-3 bullets of what changed and why)
      - Link to the spec
      - Security review verdict (PASS/REVIEW/FAIL from step 6)
      - Architecture review summary
      - Test plan with verification criteria from the spec

    The source branch is always your current branch (or worktree branch). `--pr` only controls where the PR points to.
