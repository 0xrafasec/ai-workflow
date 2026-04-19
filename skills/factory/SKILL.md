---
name: factory
description: "Single-milestone/phase delivery pipeline — implements every open issue in one GitHub milestone (or one roadmap phase) as parallel, conflict-free PRs, each pre-reviewed by a fresh-context reviewer agent. Stops with all PRs open for human merge. Use when the user says 'run factory on milestone N', 'ship phase 003_auth', 'open PRs for the auth milestone', or '/factory --milestone <N>'. For end-to-end multi-phase roadmap execution, use /autopilot instead."
---
Run the factory pipeline for: $ARGUMENTS

## What this does

Factory ships **one milestone (== one roadmap phase) at a time**. It scans the milestone's open issues, generates missing specs via speckit, then launches up to 5 parallel worktree writer agents — each implementing one issue on its own branch with lint+typecheck+tests as a hard gate before opening a PR. Every PR is then reviewed by a **separate, fresh-context reviewer agent** (writer/reviewer separation per CLAUDE.md). Reviewer findings are fixed via the writer agent resumed in-place (warm context, cheap), bounded to 2 fix cycles. The final review verdict is posted to the PR. Factory stops with PRs open for human merge — **no auto-merge**.

For multi-phase roadmap execution use `/autopilot` instead. Factory is scoped to exactly one phase/milestone per invocation.

You are the **orchestrator** (opus). You do not implement, review, or fix code yourself. You dispatch agents (sonnet) and aggregate their structured returns. You never read PR diffs or full review prose into your own context — only `{verdict, cycles, pr_url}` summaries.

## Convention: phase ↔ milestone

A roadmap phase file `docs/roadmap/<NNN>_<name>.md` corresponds to a GitHub milestone whose **title exactly equals `<NNN>_<name>`** (e.g., phase file `003_auth.md` ↔ milestone `003_auth`). This is how `/issues` files them and how factory resolves them. No frontmatter, no labels — title match only.

## Parse Arguments

Factory requires exactly one phase/milestone per invocation. Reject calls without a target.

- **`/factory <phase-name>`** — e.g., `/factory 003_auth`. Resolves to roadmap file `docs/roadmap/003_auth.md` AND milestone titled `003_auth`. Both must exist (phase file is the source of truth for spec paths and file lists; milestone is the source of truth for which issues are still open).
- **`/factory --milestone <N>`** — fetch milestone `<N>` via `gh api`, read its title, then resolve the matching `docs/roadmap/<title>.md`. Equivalent to `/factory <title>`.
- **`--no-issues`:** skip GitHub issue creation if a spec exists but no issue is filed yet (still requires a milestone for scoping).
- **`--dry-run`:** scan and report the planned batches + review-loop budget, spawn nothing.
- **`--limit N`:** override the default 5-agent parallel cap (use carefully).

If no argument is passed, **STOP** and tell the user:
> Factory requires a phase or milestone. Use `/factory <phase-name>` or `/factory --milestone <N>`. For full-roadmap execution, use `/autopilot`.

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

## Phase 1: Milestone Scan — What needs to be done

### 1a. Resolve phase + milestone

From the parsed argument, you have a phase name (e.g., `003_auth`).

1. Confirm the phase file exists: `docs/roadmap/<phase-name>.md`. If not → **STOP**: "Phase file `docs/roadmap/<phase-name>.md` not found. Run `/roadmap` or check the phase name."
2. Resolve the milestone by title:
   ```bash
   gh api "repos/{owner}/{repo}/milestones?state=open" --jq ".[] | select(.title == \"<phase-name>\")"
   ```
   If not found → **STOP**: "No open milestone titled `<phase-name>`. Run `/issues <phase-name>` first to create the milestone and issues."

### 1b. Pull open issues for the milestone

```bash
gh issue list --milestone "<phase-name>" --state open --json number,title,body,url,labels
```

**Closed issues are considered done — they are excluded from this run.** No PR-status check needed; closed = shipped.

### 1c. Resolve spec path per issue

For each open issue, grep the issue body for a spec path. Convention from `/issues`: the body contains a line like `Spec: docs/specs/003_auth/login.md` or a markdown link `[spec](docs/specs/...)`.

- If the spec path is present and the file exists → state = `spec-ready`
- If the spec path is present but the file is missing → state = `unstarted` (will spec-gen in Phase 2)
- If no spec path is in the body → fall back to scanning the phase roadmap file for a task whose name matches the issue title; if found, use its spec path. If still nothing → state = `unstarted` with the issue title used as the feature slug

### 1d. File-overlap analysis (NEW — borrowed from /autopilot)

For each in-scope feature, extract the **files-touched list** from its spec (look for `## Files`, `## Files Touched`, or the roadmap task entry). Build a file→features map.

Two features whose file sets intersect **must not run in the same batch**. Group features into the minimum number of batches such that:
- Each batch has ≤5 features (or `--limit N`)
- No two features in the same batch share any file in their touched-files list
- Within a batch, no feature depends on another feature in the same batch (dependencies from spec/roadmap)

Use a simple greedy bin-packer: sort features by files-touched count descending; place each into the first batch where it doesn't collide; create a new batch if no fit.

If a feature's spec has no files list → place it alone in its own batch (treat unknown as "may collide with anything"). Note this in the report so the user can fix the spec.

### 1e. Report scan + plan

```
## Milestone Scan — <phase-name> (milestone #<N>)

Open issues: 12
In scope (open, not yet PR'd): 10
Already has PR: 2 (skipped — see #45, #46)

### Batches (file-overlap-aware, ≤5 per batch)

Batch 1 (3 features, no file collisions):
  • #12 auth-login        → docs/specs/003_auth/login.md       [spec-ready]
  • #13 auth-register     → docs/specs/003_auth/register.md    [spec-ready]
  • #15 password-reset    → docs/specs/003_auth/reset.md       [unstarted — will gen spec]

Batch 2 (2 features, would collide with batch 1 on src/auth/middleware.ts):
  • #14 auth-middleware   → docs/specs/003_auth/middleware.md  [spec-ready]
  • #16 session-store     → docs/specs/003_auth/session.md     [spec-ready]

Estimated review-loop budget: ~1.3× writer cost (best case 1.0×, worst 1.8× with 2 fix cycles).
```

**Scope for this run:** open issues with no existing PR. Skip issues that already have an open PR (search by `<feature-slug>` in PR title).

If `--dry-run` is set: print the plan and stop here.
> Dry run complete. N features would be processed in M batches. Remove `--dry-run` to execute.

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

<from TECHNICAL_DESIGN_DOCUMENT.md if it exists, otherwise: "Discover from codebase — read existing test files for patterns">

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

### Step 4 — Commit and push

Commit with conventional commit messages, split by logical concern. Push the worktree branch.

**Do NOT run code review yourself.** Review happens in a separate fresh-context agent after the PR is open (writer/reviewer separation per CLAUDE.md). You may be resumed later with specific findings to fix — at that point, fix exactly what's listed and re-run the quality gate. Do not interpret, debate, or expand scope.

### Step 5 — Open PR

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

<verdict from code review: PASS / REVIEW / FAIL>

## Test plan

- Test layers written: <unit | integration | e2e>
- Test files: <list>
- Run with: `<test command>`

## Design fidelity (UI features)

<"Verified against <design-ref>" | "Design ref TBD — see issue comment" | "N/A (no UI)">
EOF
)"
```

### Step 6 — Link issue

If a GitHub issue URL was provided, link the PR to it:
```bash
gh issue comment <issue-number> --body "Implemented in PR <pr-url>"
```

### Return to orchestrator

Report back as a compact JSON-like block — the orchestrator does **not** want diffs or prose:

```
FEATURE: <feature-name>
BRANCH: <branch-name>
PR: <pr-url or "FAILED">
GATE: lint=PASS typecheck=PASS test=PASS  (or fail-detail)
DESIGN_REF: <ok|tbd|n/a>
BLOCKERS: <none | one-line description>
HEAD_SHA: <git rev-parse HEAD>
```

Do NOT paste full command output, full diffs, or full review prose. The orchestrator works from this summary only.

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

## Phase 5.5: Review Loop — fresh-context reviewer per PR

For each PR opened in the batch (skip features whose writer failed and produced no PR), run an independent reviewer agent. Reviewers can run **in parallel across PRs** (one per PR, single dispatch message), but each PR's loop is sequential within itself.

### Token discipline (read this first)

The whole point of this phase is high-quality PR review without burning the budget. The cheap path is:

1. **Reviewer = sonnet, fresh context, NO worktree.** Reviewer reads only what it needs from the open repo + `gh`. Do not give it a worktree (it's not editing).
2. **Reviewer scope is bounded** — explicit "do not read the whole codebase" in its prompt.
3. **Fixer = the SAME writer agent resumed** via SendMessage. Writer's spec/files/test-pattern context is already loaded; respawning a fresh fixer would re-pay that read tax. This is the single biggest token saver in the whole skill — do not deviate.
4. **Re-review reads only the new diff** since the last reviewed SHA, not the full PR.
5. **LOW-only verdicts skip the fix loop** — post nits as PR comments, done.
6. **Hard cap: 2 fix cycles per PR.** After that, post unresolved findings to the PR and hand back to the human.
7. **Orchestrator never ingests review prose.** Reviewer returns a structured verdict block; you store and aggregate it. Never quote review prose into your own context.

### 5.5a. Dispatch reviewer per PR

For each PR in the batch, spawn a reviewer agent in a single message (parallel across PRs). All reviewers run with `model: "sonnet"`, `run_in_background: true`, **no `isolation: "worktree"`** (reviewer doesn't write).

Reviewer prompt:

```
## Factory Reviewer — PR <pr-url>

You are a code reviewer. You DO NOT write code. You produce a structured verdict.

## Project context (5 lines max)

<project name, stack, key conventions — same summary used by writers>

## Your inputs (read ONLY these — do NOT explore the codebase)

1. The PR diff:        gh pr diff <pr-number>
2. The spec:           <spec-path>
3. The PR body:        gh pr view <pr-number> --json body --jq .body
4. Selective reads:    only files the diff makes you doubt (e.g., a caller of a changed function). Cap: 3 files.

If you find yourself wanting to read more than 3 extra files, STOP and emit a LOW finding "review-coverage-limited: would benefit from broader read". Do not actually read them.

## Review checklist (focused — not exhaustive)

- Spec compliance: does the diff implement what the spec says, no more, no less?
- Verification criteria: are all spec verification criteria covered by tests in the diff?
- Security: input validation at boundaries, authz, secrets handling, injection surfaces (if applicable to the diff)
- Correctness: obvious bugs, off-by-one, error handling at boundaries, race conditions
- Test quality: do tests actually exercise the change, or are they tautological?
- Convention drift: does the diff respect the patterns of nearby existing code?

Out of scope (do NOT flag):
- Style nits already covered by lint
- Refactoring opportunities unrelated to the diff
- Hypothetical future requirements

## Output — exact format, nothing else

VERDICT: PASS | FIX_REQUIRED
CYCLES_USED: <set by orchestrator on re-review; ignore on first pass>
REVIEWED_SHA: <git rev-parse the head SHA you reviewed against>

FINDINGS:
- [HIGH] <one-line action item — "Add input validation for X in path/to/file.ts:42">
- [MED]  <one-line action item>
- [LOW]  <one-line nit>

(If VERDICT=PASS with only LOW findings, list them — they'll be posted as PR comments without triggering a fix cycle.)
(If no findings at all, write "FINDINGS: none" and VERDICT: PASS.)

SUMMARY: <one sentence — what's the PR doing and is it ready>
```

### 5.5b. Process reviewer verdicts

For each reviewer return:

| Verdict | Findings | Action |
|---------|----------|--------|
| PASS | none | Post `gh pr review <pr> --approve --body "Factory reviewer: PASS — no findings."`. Done. |
| PASS | LOW only | Post `gh pr review <pr> --comment --body "Factory reviewer: PASS with nits:\n<bullet list of LOW findings>"`. Done. |
| FIX_REQUIRED | HIGH/MED present | Trigger fix cycle (5.5c). |

### 5.5c. Fix cycle (resume the writer agent)

**Resume the writer agent via SendMessage** (not a new Agent call). Pass only the action items, not the reviewer's prose:

```
SendMessage to: <writer-agent-id>

Reviewer found issues. Fix exactly these and nothing else:

- [HIGH] <action item 1>
- [HIGH] <action item 2>
- [MED]  <action item 3>

Do not refactor, do not expand scope. After fixing:
1. Run the quality gate again (lint, typecheck, test) and confirm all PASS.
2. Commit with message: "fix(<feature>): address reviewer findings (cycle <N>)"
3. Push to the same branch.
4. Return: NEW_HEAD_SHA: <sha>, GATE: <results>
```

When the writer returns, **re-dispatch the reviewer** with one extra instruction:

```
This is review cycle <N+1> for the same PR. Read ONLY the diff since the previously reviewed SHA:
   gh pr diff <pr-number>  (full diff is fine — but focus on commits since <previous SHA>)
   git diff <previous-SHA>..HEAD  (use this for laser focus on the fix)

Your previous findings were:
<list>

Verify they are resolved. Find any new issues introduced by the fix. Output the same VERDICT block.
```

### 5.5d. Loop bounds + spec-ambiguity detection

- **Max 2 fix cycles per PR.** After cycle 2, if reviewer still returns FIX_REQUIRED:
  - Post unresolved findings as a PR review comment: `gh pr review <pr> --request-changes --body "Factory reviewer (after 2 fix cycles, escalating to human):\n<findings>"`
  - Mark the PR as `NEEDS_HUMAN` in the summary table.
- **Spec-ambiguity detection:** if the reviewer flags the **same finding category** in cycle 1 and cycle 2 (e.g., both cycles flag input validation in the same area), append to the PR comment: *"⚠ Spec ambiguity suspected — the same finding survived a fix cycle. Consider clarifying the spec at <spec-path> before re-running factory."*

### 5.5e. Reviewer return to orchestrator

Reviewer agents return this compact block (no prose into orchestrator context):

```
PR: <pr-url>
VERDICT: PASS | PASS_WITH_NITS | NEEDS_HUMAN
CYCLES: <0|1|2>
HIGH_OPEN: <count>
MED_OPEN: <count>
LOW_POSTED: <count>
SPEC_AMBIGUITY_FLAGGED: <true|false>
```

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

| Feature | Issue | PR | Gate | Review | Cycles | Status |
|---------|-------|----|------|--------|--------|--------|
| auth-login | #12 | #45 | ✓ | PASS | 0 | READY TO MERGE |
| auth-register | #13 | #46 | ✓ | PASS_WITH_NITS | 0 | READY TO MERGE (3 nits posted) |
| password-reset | #15 | #47 | ✓ | NEEDS_HUMAN | 2 | NEEDS HUMAN — 1 HIGH unresolved (spec ambiguity flagged) |
| auth-middleware | #14 | — | ✗ | — | — | BLOCKED — tests failing |

### Open PRs (review these)
- #45 feat(auth-login): implement login flow — <url> — reviewer PASS
- #46 feat(auth-register): registration flow — <url> — reviewer PASS with 3 nits
- #47 feat(password-reset): reset flow — <url> — ⚠ NEEDS HUMAN, spec ambiguity

### Blocked (needs attention)
- auth-middleware: Branch `feat/auth-middleware` — quality gate failed (tests). See branch for details.

### Spec ambiguity flagged (consider clarifying before re-running)
- password-reset: same finding survived 2 fix cycles — see PR #47 review comment

### Design refs missing (run /verify-design before merging)
- (none this run)

### Next steps
1. Review and merge READY TO MERGE PRs (in dependency order — see roadmap)
2. Address NEEDS_HUMAN PRs: read the reviewer comment, decide fix-or-clarify-spec
3. Fix blocked features (or re-run `/factory <phase>` after fixing)
4. After all PRs merged + closed issues: run `/factory <next-phase>` for the next milestone
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

1. **Orchestrator stays thin.** You scan the milestone, dispatch agents, aggregate compact return blocks. You do not write code, read PR diffs, ingest review prose, or fix failing tests yourself. If you ever find yourself reading a diff in your own context, stop — that's a writer/reviewer agent's job.
2. **One milestone per invocation.** Factory does not loop across phases. For multi-phase execution use `/autopilot`. After a milestone's PRs merge, the user re-invokes factory for the next phase.
3. **Writer/reviewer separation is non-negotiable.** Writers never review their own code. Reviewers are always fresh-context, separate agents. The in-context `code-review` skill branch was removed — never reintroduce it.
4. **Fixer = writer resumed via SendMessage.** Never spawn a fresh fixer agent — the writer's loaded context is the cheapest path. The reviewer is fresh; the fixer is warm.
5. **Preflight is mandatory.** Never skip Phase 0.
6. **Parallel = single message.** All agents in a batch (writers OR reviewers) must be dispatched in one response with `run_in_background: true`.
7. **5-agent cap per batch.** Hard limit on concurrent writers; reviewers also capped at 5 concurrent.
8. **Quality gate is a hard block.** No PR is created while lint/typecheck/tests fail.
9. **File-overlap-aware batching.** No two features in the same writer batch may touch the same file. Group via the greedy bin-packer in Phase 1d.
10. **Review loop bounded at 2 cycles.** After cycle 2, escalate to human via PR comment. Never loop indefinitely.
11. **No auto-merge, ever.** Factory's job ends when PRs are open and reviewed. Merging is the human's call.
12. **Spec-ambiguity escalation.** When the same finding survives a fix cycle, surface it as a spec problem, not a code problem.
13. **Never retry automatically on writer failure.** Present failures to the user; they decide.
14. **Restore settings.json.** Always clean up the Stop hook in Phase 7.
15. **Dependency order matters.** Do not dispatch a feature whose deps aren't merged into `main`.
16. **Secrets stay out of issues, PR bodies, and review comments.**
