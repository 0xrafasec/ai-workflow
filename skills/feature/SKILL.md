---
name: feature
description: "Implement a feature end-to-end from a spec file at docs/specs/<name>.md — code it, commit in logical chunks, optionally push + open a PR. Use when the user says 'implement the auth spec', 'build feature X', 'code up the Y spec', 'work through docs/specs/<name>.md', or points at a spec and asks to execute it."
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

3. **Discover test strategy** — Before writing any code, determine how to test this feature:

   a. **Check for TDD:** Read `docs/specs/TECHNICAL_DESIGN_DOCUMENT.md` — if it has a Testing Strategy section, follow it (frameworks, file locations, naming conventions, coverage expectations).

   b. **If no TDD:** Infer from the codebase:
      - Look for existing test directories (`tests/`, `__tests__/`, `*_test.go`, `*.test.ts`, `test_*.py`, `spec/`)
      - Check `package.json`, `pyproject.toml`, `Cargo.toml`, `Makefile` for test commands and frameworks
      - Read 1-2 existing test files to understand the patterns (fixtures, helpers, naming)
      - Check for separate test layers (unit vs integration vs e2e directories)

   c. **If no tests exist at all:** Read `docs/PRD.md` or `README.md` for project context, then set up the test infrastructure as part of the implementation (create test directories, add test dependencies if needed). Tell the user what you're setting up.

   d. **Determine which test layers this feature needs** based on the spec's Verification Criteria:
      - **Unit tests:** Always — for business logic, validators, pure functions
      - **Integration tests:** If the feature touches APIs, database, external services, or component boundaries
      - **E2E tests:** If the feature is a critical user flow (auth, payments, onboarding) or the spec explicitly requires them

4. **Plan the implementation** — If the feature is complex (touches 3+ files or has non-obvious design decisions), use Plan Mode to align on the approach before writing code. Include the test plan in the implementation plan. Otherwise, proceed directly.

5. **Implement with tests** — Write implementation and tests together, organized by layer:
   - **Unit tests first** — they validate core logic and are fastest to run
   - **Integration tests next** — they validate component interactions
   - **E2E tests last** — only for critical flows identified in step 3d
   
   Tests must cover all verification criteria from the spec. Run each test layer after writing it and fix failures before moving to the next layer.

6. **Run quality checks** — Run the project's lint, typecheck, and test commands (check CLAUDE.md or Makefile for the right commands). Run ALL test layers, not just unit tests.

7. **Stack-aware code review** — Prefer Anthropic's official `code-review` skill (from `claude-code-plugins`) if installed. Otherwise, run `/sec-review` for security and spawn an **architecture-reviewer** subagent for architecture, passing the matching language guide from `reviews/` (`go.md`, `rust.md`, `typescript.md`, `python.md`) as stack-specific criteria.

    **Scope of this pass:** this is a pre-PR self-check. Reviewer subagents have fresh context, but *you* (the writer) are reading and acting on their findings — that's not a true writer/reviewer separation. Treat it as catching the obvious problems before anyone else sees the PR, not as the final trust boundary. Before merge, run `/review` in a **fresh session** (or have a human review the PR) so a reviewer who never watched the code being written can weigh in.

8. **Address findings** — Fix any HIGH severity issues from the review. For MEDIUM issues, use your judgment. Re-run the review if you made significant changes.

9. **Commit** — Use conventional commit messages (feat:, fix:, refactor:, etc.). Split by logical concern. Each commit should leave the codebase working.

10. **Ship (conditional):**

    - **No `--pr` flag (default):** Stop here. Tell the user: "Feature implemented and committed on `<current-branch>`. Run with `--pr` when ready to open a PR."

    - **`--pr`:** Push the current branch and create a PR targeting the repo's default branch (usually `main`).

    - **`--pr <base-branch>`:** Push the current branch and create a PR targeting the specified base branch. Example: `--pr develop` opens a PR from your current branch into `develop`.

    PR contents:
      - Summary (1-3 bullets of what changed and why)
      - Link to the spec
      - Security review verdict (PASS/REVIEW/FAIL from step 7)
      - Architecture review summary
      - Test plan: which test layers were written (unit/integration/e2e), what they cover, how to run each layer

    The source branch is always your current branch (or worktree branch). `--pr` only controls where the PR points to.
