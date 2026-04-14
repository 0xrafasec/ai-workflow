---
name: factory
description: "End-to-end feature delivery pipeline: roadmap → specs → GitHub issues → parallel worktree agents → PRs. Processes all unstarted roadmap features automatically."
---
Run the factory pipeline for: $ARGUMENTS

## What this does

Factory is an **end-to-end delivery pipeline**. It reads the roadmap, generates missing specs via speckit, optionally creates GitHub issues, then launches up to 5 parallel worktree agents — each implementing one feature on its own branch with lint+build+tests enforced as a hard gate before any PR is opened.

You are the **orchestrator**. You do not implement anything yourself.

## Parse Arguments

- **No argument:** `/factory` — process all unstarted features in `docs/roadmap/*.md`
- **Phase name:** `/factory 003_auth` — process only features in that phase file
- **Feature slug:** `/factory auth-login` — process only the feature whose spec slug matches
- **`--no-issues`:** skip GitHub issue creation regardless of project board availability
- **`--dry-run`:** scan and report what would run, without spawning any agents
- **`--limit N`:** override the default 5-agent parallel cap (use carefully)

## Phase 0: Preflight — Fix friction before it bites

Run all checks in parallel before touching anything else. A single failure here costs 10 seconds; discovering the same failure mid-pipeline wastes 10 minutes.

### 0a. Directory check

```bash
git rev-parse --show-toplevel 2>/dev/null
```

If this fails: **STOP**. Tell the user:
> You are not inside a git repository. `cd` to the project root first, then re-run `/factory`.

If the output does not match the current working directory, **STOP**:
> Current directory `<cwd>` is not the repo root `<toplevel>`. Run `/factory` from `<toplevel>`.

### 0b. Git state check

```bash
git status --short
git branch --show-current
```

If there are uncommitted changes on `main` or the default branch, warn (don't block):
> Working tree has uncommitted changes on `main`. These will not appear in worktrees. Commit or stash before continuing if they're needed by agents.

### 0c. gh auth + scope check

```bash
gh auth status 2>&1
```

Parse the output:
- If `not logged in` → **STOP**: "Run `gh auth login` first, then re-run `/factory`."
- If logged in but **`project` scope missing** → warn unless `--no-issues` is set:
  > gh is authenticated but missing the `project` scope. GitHub issue creation will be skipped.
  > To enable it: `gh auth refresh -s project`
  > Or re-run with `--no-issues` to suppress this warning.
  
  Record `HAS_PROJECT_SCOPE=false` and continue (issue creation will be skipped).
- If logged in with project scope → `HAS_PROJECT_SCOPE=true`.

### 0d. Roadmap exists check

```bash
ls docs/roadmap/*.md 2>/dev/null
```

If no files → **STOP**:
> No roadmap files found in `docs/roadmap/`. Create a roadmap first with `/roadmap`.

### 0e. Build command discovery

Read `CLAUDE.md` (project-level, then global) for lint, typecheck, and test commands. Also check:
- `package.json` scripts for `lint`, `typecheck`/`type-check`, `test`
- `Makefile` for `lint`, `test`, `check` targets
- `pyproject.toml` / `Cargo.toml` for test commands

Record the resolved commands as:
```
LINT_CMD=<command>
TYPECHECK_CMD=<command>
TEST_CMD=<command>
```

If any command can't be resolved, note it — agents will be told to discover it from the codebase.

### 0f. Report preflight results

```
## Preflight

✓ Repo root: /path/to/project
✓ Branch: main (clean)
✓ gh auth: logged in as @username
⚠ gh project scope: missing (issue creation skipped — run `gh auth refresh -s project` to enable)
✓ Roadmap: 4 phase file(s) found
✓ Build commands: lint=`pnpm lint`, typecheck=`pnpm typecheck`, test=`pnpm test`
```

---

## Phase 1: Roadmap Scan — What needs to be done

Read every `docs/roadmap/*.md` file (skip `README.md`). For each file, extract every task and classify it:

**Task states:**
- `unstarted` — no spec exists at the spec path listed in the task, AND no open/merged PR references the task name or spec slug
- `spec-only` — spec exists but no implementation PR found
- `in-progress` — an open PR exists referencing this task
- `done` — a merged PR exists, or the roadmap marks it complete (`[x]` checkbox)

Check PR status with:
```bash
gh pr list --state all --search "<task-slug>" --json number,title,state,url
```

Build a table:

```
## Roadmap Scan

| Phase | Feature | Spec | State | Action |
|-------|---------|------|-------|--------|
| 003_auth | auth-login | specs/003_auth/login.md | unstarted | gen-spec + implement |
| 003_auth | auth-register | specs/003_auth/register.md | spec-only | implement |
| 004_dashboard | overview | specs/004_dashboard/overview.md | in-progress | skip (PR #42 open) |
| 002_foundation | db-schema | specs/002_foundation/db.md | done | skip |
```

**Scope for this run:** only `unstarted` and `spec-only` tasks. Skip `in-progress` (a PR is already open) and `done`.

If `--dry-run` is set: print the table and stop here.
> Dry run complete. N features would be processed. Remove `--dry-run` to execute.

---

## Phase 2: Spec Generation — Fill gaps before building

For each `unstarted` task (spec does not exist), generate the spec using speckit. This phase runs **sequentially** — spec generation is interactive and context-dependent; parallelizing it corrupts the context.

For each unstarted feature, spawn a **foreground subagent** (not background — you need its output before continuing):

```
You are a spec generator for the feature: <feature-name>

## Project context
<3-5 line summary from roadmap README and CLAUDE.md>

## Task from roadmap
<full task block from the roadmap file>

## Your job
1. Read the roadmap task above to understand scope, files, and dependencies.
2. Read any related specs that already exist (listed as dependencies in the task).
3. Run `/speckit-spec <feature-name>` to generate the spec interactively.
   - The spec should be written to: <spec-path from roadmap task>
4. Then run `/speckit-plan <feature-name>` to generate the implementation plan.
5. Then run `/speckit-tasks <feature-name>` to generate the task breakdown.
6. Return: the spec path created, any blockers encountered, and a one-line summary.

## Friction guards
- You are in: <repo root path>. Verify with `pwd` before running any command.
- If speckit asks for a design reference and none exists in `docs/design/`, note it as a blocker and continue with "Design reference: TBD" rather than halting.
- If speckit prompts are interactive, answer based on the roadmap task context.
```

After each spec subagent completes:
- Record: feature name, spec path created, blockers
- If spec creation failed: mark feature as `blocked`, note the reason, continue to next feature

### Design reference check (UI features only)

Before spec generation for any task whose roadmap entry mentions "UI", "page", "component", "screen", or "view":

1. Check `docs/design/` for a matching design file
2. Check Paper MCP (`get_basic_info`) if available — look for a matching artboard
3. If **neither exists**: warn and continue with a placeholder rather than blocking:
   > ⚠ No design reference found for `<feature>`. Spec will note "Design ref: TBD". Run `/verify-design <feature>` before implementation to catch mismatches early.

---

## Phase 3: GitHub Issues — Put work on the board (optional)

Skip this phase if:
- `--no-issues` flag is set
- `HAS_PROJECT_SCOPE=false` (from preflight 0c)

For each feature with a newly created or existing spec:

### 3a. Discover the project board

```bash
gh project list --owner <repo-owner> --format json 2>&1
```

If no projects found: skip issue creation, warn:
> No GitHub Projects found for this repo. Skipping issue creation. Use `--no-issues` to suppress this warning.

If multiple projects found: pick the one whose name contains "backlog", "roadmap", or matches the repo name. If ambiguous, use AskUserQuestion to let the user select.

### 3b. Create issues

For each in-scope feature, check if an issue already exists:
```bash
gh issue list --search "<feature-slug> in:title" --json number,title,url
```

If an issue already exists: skip creation, record its URL.

If no issue exists, create one:
```bash
gh issue create \
  --title "<feature-slug>: <feature description from roadmap>" \
  --body "$(cat <<'EOF'
## Feature

<one-paragraph description from the roadmap task>

## Spec

<spec-path> (generated by /factory)

## Acceptance criteria

<verification command from roadmap task>

## Dependencies

<dependencies listed in roadmap task, or "None">

---
*Created by /factory*
EOF
)" \
  --label "ready"
```

Then add to project board in "Ready" status:
```bash
gh project item-add <project-number> --owner <owner> --url <issue-url>
```

If `gh project item-add` fails with a scope error: record the failure, continue. Issues are created even if board placement fails.

Record: feature → issue URL.

---

## Phase 4: Stop Hook — Gate PRs behind quality checks

Before launching any implementation agent, **register a quality gate** in the project's `.claude/settings.json`.

Read the current `.claude/settings.json` (create it if absent). Add a Stop hook that runs lint, typecheck, and tests:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "<LINT_CMD> && <TYPECHECK_CMD> && <TEST_CMD>",
            "description": "factory quality gate — lint + typecheck + tests must pass before stopping"
          }
        ]
      }
    ]
  }
}
```

If `settings.json` already has Stop hooks, **append** to the hooks array — never overwrite existing hooks.

Save the previous Stop hook state (or absence) so Phase 6 can restore it after the run.

**Note to implementation agents:** The Stop hook will run automatically when you finish. If it fails, you must fix the failures before you can stop. Do not bypass with `--no-verify`. This is intentional — it means broken code cannot be committed.

---

## Phase 5: Parallel Implementation — ≤5 agents, each in its own worktree

Collect all features with status `unstarted` (spec now exists) or `spec-only`. Cap at **5 at a time**.

If more than 5 features are in scope, process them in batches of 5. Complete each batch (all agents done or failed) before starting the next.

### 5a. Dispatch batch

Spawn all agents in the batch **in a single message** using the Agent tool with:
- `isolation: "worktree"` — each agent gets its own git worktree and branch
- `run_in_background: true` — all run concurrently
- `model: "sonnet"` — cost-efficient for implementation work

Each agent receives this prompt:

```
## Factory Agent — Feature: <feature-name>

## Preflight (run these FIRST before anything else)

1. Verify directory: `pwd && git rev-parse --show-toplevel`
   - Both must print the same path: <repo-root>
   - If they differ, `cd <repo-root>` before continuing.
2. Verify you're on the right branch: `git branch --show-current`
   - Should be a new worktree branch, not `main`.

## Project Context

<3-5 line summary: what the project is, tech stack, key conventions>

## Build & Test Commands

- Lint: <LINT_CMD or "discover from package.json/Makefile/CLAUDE.md">
- Typecheck: <TYPECHECK_CMD or "discover">
- Test: <TEST_CMD or "discover">

## Test Strategy

<from TDD.md if it exists, otherwise: "Discover from codebase — read existing test files for patterns">

## Your Feature

- **Name:** <feature-name>
- **Spec:** <spec-path> — READ THIS FIRST
- **Plan:** <plan-path if exists>
- **Tasks:** <tasks-path if exists>
- **Files to touch:** <list from roadmap task>
- **Dependencies:** <list from roadmap, or "None — all dependencies are already merged">
- **Verification:** <command from roadmap task>
- **GitHub issue:** <issue-url or "N/A">
- **Design reference:** <path or artboard ID, or "TBD — run /verify-design <feature> first">

## Instructions

### Step 1 — Read everything before writing anything
Read the spec, plan, and tasks files fully. Also read:
- Any specs listed as dependencies above
- Existing source files you'll be modifying (understand what's there before changing it)
- 1-2 existing test files to understand test patterns

**UI features only:** If a design reference is provided, run `/verify-design <feature>` before writing any component code. List mismatches from the report before proceeding. If design ref is "TBD", note it in the PR and proceed with best-effort alignment.

### Step 2 — Implement following the spec and task breakdown
Follow the task order from tasks.md (if it exists). Write tests alongside implementation:
- Unit tests for logic
- Integration tests for API/DB boundaries
- E2E only if the spec explicitly requires it

### Step 3 — Quality gate (REQUIRED before creating any PR)

Run each command in sequence and **paste the last 30 lines of output**:

```
<LINT_CMD> 2>&1 | tail -30
<TYPECHECK_CMD> 2>&1 | tail -30
<TEST_CMD> 2>&1 | tail -30
```

**If any command fails:** fix the issue, re-run the failing command, paste the new output. Repeat until all three pass. Do NOT create a PR while any check is failing.

If you cannot fix a failure after 3 attempts, document the failure clearly and stop — do not create a PR.

### Step 4 — Code review

Run `/code-review` to check for security and architecture issues. Fix any HIGH severity findings. Re-run the quality gate after fixes.

### Step 5 — Commit and push

Commit with conventional commit messages, split by logical concern. Push the worktree branch.

### Step 6 — Open PR

Create a PR targeting `main` (or the default branch):

```bash
gh pr create \
  --title "<type>(<feature-slug>): <summary>" \
  --base main \
  --body "$(cat <<'EOF'
## Summary

<1-3 bullets of what changed and why>

## Spec

<spec-path>

## Issue

<issue-url or N/A>

## Quality gate

All three checks passed before this PR was opened:

| Check | Result |
|-------|--------|
| Lint | ✓ PASS |
| Typecheck | ✓ PASS |
| Tests | ✓ PASS (N tests, N ms) |

<paste the last 10 lines of each check output here>

## Security review

<verdict from /code-review: PASS / REVIEW / FAIL>

## Test plan

- Test layers written: <unit | integration | e2e>
- Test files: <list>
- Run with: `<test command>`

## Design fidelity (UI features)

<"Verified against <design-ref>" | "Design ref TBD — see issue comment" | "N/A (no UI)">
EOF
)"
```

### Step 7 — Link issue

If a GitHub issue URL was provided, link the PR to it:
```bash
gh issue comment <issue-number> --body "Implemented in PR <pr-url>"
```

### Return to orchestrator

Report back:
- Feature name
- Branch name
- PR URL (or "no PR — quality gate failed")
- Quality gate results (pass/fail per check)
- Any blockers encountered
- Design ref status

## Retry rules

If you hit any of these, recover as described — do not fail immediately:

| Problem | Recovery |
|---------|----------|
| `pwd` ≠ repo root | `cd <repo-root>` and continue |
| `gh pr create` fails with `GraphQL: Could not resolve to a node` | Run `gh repo set-default <owner>/<repo>` then retry once |
| `gh project item-add` fails with scope error | Skip board placement, continue with PR creation |
| Spec file not found at listed path | Search `specs/` for a file matching the feature slug; if found use it; if not, note the missing spec and stop cleanly |
| Design ref not found | Note "Design ref: TBD" in PR body, continue — do not block on missing design |
| Test command not in CLAUDE.md | Check `package.json` scripts, `Makefile`, and existing CI config. Document what you found. |
| Pre-commit hook fails | Fix the underlying issue. Never use `--no-verify`. |
```

### 5b. Monitor progress

You will be notified as each background agent completes. As each finishes, record its result immediately. If it failed, note whether it's:
- **Retriable** — agent reported a fixable blocker (missing dep, wrong path)
- **Blocked** — needs human decision (ambiguous spec, missing design ref)
- **Hard fail** — quality gate failed and agent couldn't fix it

### 5c. Batch complete — present results before next batch

After all agents in the current batch finish:

```
## Batch N/M Complete

| Feature | Branch | PR | Quality Gate | Notes |
|---------|--------|----|-------------|-------|
| auth-login | feat/auth-login | #45 OPEN | ✓ PASS | — |
| auth-register | feat/auth-register | — | ✗ FAIL (tests) | Couldn't fix: see branch |
| dashboard | feat/dashboard | #46 OPEN | ✓ PASS | Design ref was TBD |
```

For **failed agents**: describe the failure clearly. Offer options:
- "retry" — re-dispatch the agent
- "skip" — mark as blocked, continue to next batch
- "stop" — halt the factory run

Wait for user response before dispatching the next batch.

---

## Phase 6: Summary Table

After all batches complete (or the user stops), post the full run summary:

```markdown
## Factory Run Complete

**Run date:** YYYY-MM-DD HH:MM
**Features processed:** N
**PRs opened:** N
**Quality gate failures:** N
**Blocked (need human):** N

### Results

| Feature | Phase | Spec | Issue | PR | Gate | Status |
|---------|-------|------|-------|-----|------|--------|
| auth-login | 003 | ✓ | #12 | #45 | ✓ | READY FOR REVIEW |
| auth-register | 003 | ✓ | #13 | — | ✗ | BLOCKED — tests failing |
| dashboard | 004 | ✓ | #14 | #46 | ✓ | READY FOR REVIEW |

### Open PRs (review these)
- #45 feat(auth-login): implement login flow — <url>
- #46 feat(dashboard): owner dashboard scaffold — <url>

### Blocked (needs attention)
- auth-register: Branch `feat/auth-register` — quality gate failed (tests). See branch for details.

### Design refs missing (run /verify-design before merging)
- dashboard: no Paper artboard found — design ref marked TBD in PR

### Next steps
1. Review and merge open PRs (in dependency order — see roadmap)
2. Fix blocked features (or re-run `/factory auth-register` after fixing)
3. For features with TBD design refs: run `/verify-design <feature>` and fix mismatches before merging
4. After all PRs merged: run `/factory` again to pick up any remaining unstarted features
```

---

## Phase 7: Cleanup

Restore the Stop hook to its pre-factory state:
- If `settings.json` had no Stop hooks before the run: remove the factory Stop hook entry
- If `settings.json` had existing Stop hooks: remove only the factory-added entry (match by `description` field)
- Leave `settings.json` unchanged if removal would make it invalid JSON

Notify the user:
> Factory quality gate removed from `.claude/settings.json`. Your pre-factory hook config has been restored.

---

## Retry Patterns Reference

These are the friction patterns this factory is hardened against. Each preflight or agent prompt section above handles these — this is the summary for your own recovery decisions as orchestrator.

| Friction | Where it hits | Guard |
|----------|--------------|-------|
| Wrong cwd | Any git/gh command | Preflight 0a; each agent verifies cwd first |
| Missing `gh project` scope | Issue creation | Preflight 0c; degrades gracefully to `--no-issues` |
| Design reference missing | UI spec gen + impl | Phase 2 design check; agents note TBD, don't block |
| Spec path mismatch | Agent can't find spec | Agent searches `specs/` by slug before failing |
| Pre-commit hook failure | Agent commit step | Agents fix the issue, never `--no-verify` |
| `gh pr create` node error | PR creation | Agent runs `gh repo set-default`, retries once |
| Quality gate failure | Pre-PR check | Agent fixes, re-runs up to 3 times, then stops cleanly |
| Agent context overflow | Long implementation | Agent uses `/compact` mid-task; reports it in summary |

---

## Rules

1. **Orchestrator stays thin.** You read the roadmap, dispatch agents, track results. You do not write code, review code, or fix failing tests yourself.
2. **Preflight is mandatory.** Never skip Phase 0. Every Phase 0 failure that isn't caught costs 10+ minutes downstream.
3. **Parallel = single message.** All agents in a batch must be dispatched in one response with `run_in_background: true`. Never dispatch one and wait before dispatching the next.
4. **5-agent cap.** Never dispatch more than 5 worktree agents at once. This is a resource and reviewability limit, not a suggestion.
5. **Quality gate is a hard block.** No PR is created by any agent while lint, typecheck, or tests are failing. This is non-negotiable.
6. **Never retry automatically.** When an agent fails, present the failure to the user and wait for their decision. They may want to fix the spec or roadmap before retrying.
7. **Design refs are warned, not blocked.** A missing design reference is a warning. It goes in the PR body as "Design ref: TBD". It never blocks spec generation or implementation.
8. **Restore settings.json.** Always clean up the Stop hook in Phase 7, even if the run fails partway through.
9. **Dependency order matters.** Do not dispatch an agent for a feature whose dependencies have not been merged into main. If a batch would include such a feature, skip it and note why.
10. **Secrets stay out of issues.** When creating GitHub issues, never include env var values, tokens, API keys, or credentials — even as examples.
