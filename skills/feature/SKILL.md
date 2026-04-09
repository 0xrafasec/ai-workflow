---
name: feature
description: Implement a feature from a spec file following the workflow
---
Implement the feature described in $ARGUMENTS.

## Parse Arguments

The argument can be:
- **Just a feature name:** `/feature auth` — resolves to `docs/specs/auth.md`, implement, commit, no PR
- **Full spec path:** `/feature docs/specs/auth.md` — same, but explicit path
- **With `--pr`:** `/feature auth --pr` — implement, commit, push, create PR
- **With `--pr <branch>`:** `/feature auth --pr feat/auth` — implement, commit, push to specific branch, create PR

**Spec resolution:** If the argument is not a file path (no `/` or `.md`), resolve it to `docs/specs/<name>.md`. If it is a path, use it as-is.

Default behavior is **commit only, no PR**. The user controls when to ship.

## Steps

1. **Read the spec** at the provided path. If the spec file does not exist:
   - Use AskUserQuestion to ask: "Spec `<path>` not found. Would you like me to:\n\n1. **Create the spec first** — I'll run `/spec <feature-name>` to interview you and create it, then continue with implementation\n2. **Build without a spec** — I'll ask you to describe the feature and implement directly (good for small features, POCs, or quick prototyping)\n"
   - If option 1: run `/spec <feature-name>` (derive the name from the path, e.g. `docs/specs/work-order-api.md` → `work-order-api`), then continue from step 2 with the newly created spec.
   - If option 2: skip spec-dependent steps (verification criteria, spec link in PR). Ask the user to describe the feature, then proceed to step 3.

   **Note:** For bugfixes, use `/fix` instead.

2. **Check for a roadmap task** — Look in `docs/roadmap/` for a task referencing this spec. If found, note dependencies and verification commands.

3. **Plan the implementation** — If the feature is complex (touches 3+ files or has non-obvious design decisions), use Plan Mode to align on the approach before writing code. Otherwise, proceed directly.

4. **Implement with tests** — Write the implementation and tests together. Tests must cover all verification criteria from the spec. Run the test suite after implementation and fix any failures.

5. **Run quality checks** — Run the project's lint, typecheck, and test commands (check CLAUDE.md or Makefile for the right commands).

6. **Stack-aware code review** — Run `/code-review` to perform a full stack-aware review. This auto-detects the project's language/framework and spawns 3 parallel agents: security (with language-specific checks), architecture (with language-specific patterns), and a stack-specific idiomatic review. This replaces the separate `/sec-review` + architecture-reviewer steps with a single, more thorough command.

    If `/code-review` is not available, fall back to: run `/sec-review` for security, then spawn an architecture-reviewer subagent.

7. **Address findings** — Fix any HIGH severity issues from the review. For MEDIUM issues, use your judgment. Re-run `/code-review` if you made significant changes.

8. **Commit** — Use conventional commit messages (feat:, fix:, refactor:, etc.). Split by logical concern. Each commit should leave the codebase working.

9. **Ship (conditional):**

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
