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

If the spec doesn't exist, ask the user whether to create one via `/spec <name>` first, or build without a spec (they describe the feature inline). For bugfixes, use `/fix` instead.

## Workflow

1. **Read the spec.** Note the Verification Criteria — your tests must cover each one.

2. **Pick a test strategy.** Read `docs/specs/TECHNICAL_DESIGN_DOCUMENT.md` if it exists; otherwise infer from the project (test dirs, `package.json` / `pyproject.toml` / `Makefile`, 1–2 existing test files). Unit tests always; integration tests when the feature crosses boundaries (API, DB, filesystem, subprocess); e2e only for critical user flows. If no tests exist yet, set up the minimum infrastructure and tell the user.

   **Test placement is a contract, not an implementation detail.** If the spec or existing project structure distinguishes `tests/unit/` from `tests/integration/` (or equivalent layout), mirror that distinction in directory placement based on *what the test covers*, not *how you wrote it*. A test that exercises a module across a real boundary (Qdrant container, respx-stubbed HTTP, tmp_path filesystem) belongs in `tests/integration/` even if it runs fast and mocks a few leaves. A test of pure logic belongs in `tests/unit/` even if the function happens to be in a service-layer file. Getting this wrong scatters integration coverage into the unit suite, where it drifts out of the slow-path CI filter and stops catching the boundary regressions it exists to catch.

3. **Plan if non-trivial.** Touches 3+ files or has non-obvious design decisions? Use Plan Mode to align before writing code.

   For larger scopes (6+ files or multi-phase work), before writing any code produce a **file placement table** derived from the spec — one row per module, with columns: `(source file, test file, test type, depends on)`. This forces you to resolve test-type ambiguity up front against the spec's language, catches underspecified corners, and gives the user a checkpoint before the implementation commits to a structure. If the project already has a `tasks.md` or equivalent task breakdown (e.g., from `/speckit-tasks`), treat it as the source of truth for file paths and test placement and skip generating a duplicate table.

4. **Implement with tests, layer by layer.** Unit → integration → e2e. Run each layer and fix failures before moving on. Tests must cover every Verification Criterion.

5. **Quality checks.** Run the project's lint, typecheck, and full test suite (check CLAUDE.md / Makefile for commands).

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
     - **Spec** — link to `docs/specs/<name>.md`
     - **Security review** — verdict line: `Security: PASS` / `REVIEW` / `FAIL` (from step 6). Never omit this. If the feature has zero security surface, write `Security: PASS (no new inputs/auth/io surface)` so reviewers know you considered it.
     - **Test plan** — which layers (unit/integration/e2e), what they cover, how to run each
