---
name: autopilot
description: "Execute a roadmap end-to-end and AUTONOMOUSLY — phase by phase, task by task: develop in a worktree, review in a fresh context, fix findings, then merge to main. No human gate by default. Use when the user says 'run the roadmap', 'autopilot this', 'ship phases 1-3', 'work through docs/roadmap/', wants unattended multi-phase delivery landed on main, or hands over a roadmap file expecting the whole thing built, reviewed, and merged. Use --supervised to restore per-phase human checkpoints."
---
Execute the roadmap at: $ARGUMENTS

## What autopilot is

Autopilot is **autonomous, end-to-end roadmap delivery**. You read a roadmap and, for every
task in every phase, you run the full delivery pipeline yourself — **develop → review → fix →
merge to `main`** — looping until the roadmap is delivered or a genuine blocker stops you. The
default is **no human checkpoint**: autopilot self-merges each reviewed, green PR to `main` and
moves on. "Autopilot should be autopilot."

This is the deliberate difference from `/factory`, which builds one milestone's PRs and **stops
with them open for a human to merge**. Autopilot **does merge** — invoking it in the default
(autonomous) mode is the user granting that merge authority. If the user wants the old
stop-at-every-phase behaviour, they pass `--supervised` (see Modes).

You are still an **orchestrator**: you do not implement or review code yourself. You parse the
roadmap, dispatch worktree agents for development, dispatch fresh-context agents for review,
triage their verdicts, perform the mechanical git **merge**, update roadmap status, and loop.
The merge is the one state-changing action you perform directly; everything intellectual is
delegated.

## Modes

- **autonomous (default)** — develop, review, fix, and **merge to `main`** for every task, phase
  after phase, with no human gate. Only stop on a genuine blocker (see Stop conditions).
- **`--supervised`** — run each phase, but **stop at the phase boundary with PRs open** and hand
  them to the human to review + merge before continuing (the pre-0.7 behaviour). Use when the user
  says "let me review before merge", the repo has protected branches requiring human approval, or
  the work is high-stakes.

Detect the mode from `$ARGUMENTS` (a `--supervised` token) or from explicit user intent. When in
doubt for a brand-new/unfamiliar repo, ask once which mode they want, then proceed.

## Process

### 1. Parse the roadmap

Read the roadmap file. For each phase extract:
- **Phase name and goal**, and any **feature flag** the phase ships behind.
- **Tasks** — each with: name, spec path, files touched, dependencies, verification command, test
  layers. `complexity:high` tasks point at a **sliced** spec directory — each slice is its own
  task/PR; expand them.
- **Which tasks run in parallel** (no file overlap, no dependency between them) vs **sequential**
  (depend on another task in the same phase).

If the roadmap lacks the detail to do this — missing spec paths, specs that don't exist on disk,
unclear dependencies — **stop and tell the user what's missing**. Do not invent specs.

### 2. Read project context (once)

Read, once, to ground every dispatch — this is the only heavy reading you do:
- `CLAUDE.md` — build/test commands, conventions, merge rules.
- `docs/PRD.md` (or equivalent) — what the project is.
- `docs/ARCHITECTURE.md` — system structure, layering, trust boundaries.
- `docs/TECHNICAL_DESIGN_DOCUMENT.md` — **Testing Strategy** (frameworks, layers, run commands,
  file locations), dev environment, CI/CD, merge/commit conventions.
- `docs/THREAT_MODEL.md` — security model and the untrusted boundaries (if it exists).

Summarize in 3–5 lines, **including the test strategy**. This summary is passed to every agent so
they have context without re-reading everything. If there is no TDD doc, tell agents to discover
test patterns from the codebase.

### 3. Pre-flight (once, before dispatching)

Autonomy fails loudly if the ground isn't solid. Verify, and fix or surface, before Task 1:
- **Specs are committed and on `main`.** Worktree agents branch off committed history; an
  untracked spec is invisible to them. If specs/roadmap/docs are uncommitted, say so and get them
  onto `main` first.
- **Toolchain present** — the build/test/lint tools the verification commands need are installed
  and on PATH (a fresh login shell must resolve them, since agents inherit the user's profile).
- **`gh` is authenticated** and the remote is reachable (agents push branches + open PRs).
- **Merge authority** — confirm you can merge to `main` (solo/trunk repo, or branch protection
  that permits it). If `main` is protected against direct/auto merge, switch to `--supervised`
  and tell the user.
- **Working tree is clean** of unrelated WIP that a merge could entangle.

Surface any gap as a blocker with the fix, rather than dispatching agents that will dead-end.

### 4. Execute phase by phase

For each phase, in dependency order:

#### a. Announce
```
## Phase N: <name>
Goal: <goal>   Flag: <feature-flag or none>
Tasks: <count> (<parallel> parallel, <sequential> sequential)
```

#### b. Skip completed phases
If the roadmap marks a phase done (checkmark/status), announce the skip and move on.

#### c. Plan the task graph
Within the phase, group tasks into **waves**:
- A wave is a set of tasks with **no dependency between them and no shared files** — they develop
  in parallel.
- A task that depends on another waits until that dependency's PR is **merged to `main`** (not
  merely written) — its worktree must branch off the updated `main`.
- Use **file-overlap awareness**: never put two tasks that touch the same file in the same wave
  (they'd conflict). Sequence them instead.

#### d. Run the per-task pipeline

For every task, run this pipeline. Tasks in the same wave run their pipelines **concurrently**
(dispatch all writers in one message, `run_in_background: true`); dependent tasks wait for the
merge of what they depend on.

**1 — Develop (writer agent).** Dispatch a worktree agent (`isolation: "worktree"`,
`model: "sonnet"` — they follow a detailed spec, they don't design). Writer prompt template below.
It reads the spec, implements, writes the specified test layers, runs the verification + lint +
build, self-fixes, commits (conventional, **split by concern**), pushes, and opens a PR. Record
its branch, PR URL, and worktree path.

**2 — Review (fresh-context reviewer agent).** When the writer's PR is open, dispatch a **separate**
agent with **cold context** (`model: "sonnet"`, a worktree so it can build) — never the writer,
never your own context. Writer/reviewer separation is non-negotiable. The reviewer reads the spec +
the PR diff, **independently runs the verification** (build/tests — does not trust pasted output),
checks spec compliance + correctness + conventions + test adequacy, posts a concise PR comment, and
returns a structured verdict:
```
VERDICT: PASS | FIX_REQUIRED
BUILD: <verification results it actually ran>
FINDINGS:
- [CRITICAL|HIGH|MEDIUM|LOW] file:line — issue — suggested fix
```
PASS = green build and no CRITICAL/HIGH. FIX_REQUIRED otherwise.

**3 — Security gate (when warranted).** If the task touches a trust boundary, auth, crypto, input
validation/parsing, secrets, or dependency/supply-chain, run `/sec-review` (or a security-reviewer
agent, `model: "opus"`) on the diff before merge. A HIGH+ security finding **blocks merge** until
fixed. For plainly non-security tasks (theme tokens, layout chrome, copy), skip — don't burn tokens.

**4 — Fix loop (bounded).** On FIX_REQUIRED, **resume the writer agent via `SendMessage`** (warm
context — it already paid to read the spec and files; a fresh fixer would re-pay) with only the
reviewer's action items. The writer fixes, re-verifies, re-pushes. The reviewer re-runs **on the
new diff only**. Hard cap **2 fix cycles**. If a finding survives 2 cycles it's likely
spec-ambiguity — stop fixing, mark the task `NEEDS_HUMAN`, leave the PR open with the reviewer's
comment, and carry on with independent tasks; surface it at the phase summary.

**5 — Merge (you, the orchestrator).** Once the verdict is PASS (and the security gate, if run, is
clear), merge the PR to `main` yourself:
- Prefer `gh pr merge <n> --rebase --delete-branch` (or `--merge` if the repo convention wants a
  merge commit). **Do not `--squash`** — it destroys the writer's logical commit split, which the
  workflow deliberately preserves. If the repo's CLAUDE.md mandates squash, follow that instead.
- If the branch no longer applies cleanly (main moved under a parallel wave), have the writer
  rebase onto `main` and re-verify, then merge. If the conflict isn't mechanically resolvable,
  stop and surface it.
- After merge: remove the writer's and reviewer's worktrees (`git worktree remove`), confirm the
  remote branch is deleted. Never reuse a merged branch.

**6 — Confirm `main` stays green & record.** Trust the pre-push/CI gate; if the repo has a fast
check, you may run it. Update the roadmap task status (tick the checkbox / set status) and commit
that doc update (`docs:`), so progress is durable and resumable.

#### e. Feature-flag discipline
If the phase ships behind a flag, tasks land with the flag **off**. Flip it **on** only at phase
end, once the whole flow is coherent — as its own small PR through the same pipeline. Respect the
roadmap's flag column; never flip a flag mid-phase.

#### f. Phase summary
After every task in the phase is merged (or parked as `NEEDS_HUMAN`):
```
## Phase N complete
| Task | Status | PR | Merged | Notes |
|------|--------|----|--------|-------|
| <name> | merged / needs-human / blocked | #<n> | ✓ / — | <note> |

Main is green: <verification>. Proceeding to Phase N+1.
(NEEDS_HUMAN / blocked items, if any, listed for you to resolve — autopilot continues with
independent work and will not build on an unmerged dependency.)
```
In autonomous mode, **proceed automatically** to the next phase (its dependencies are merged). In
`--supervised` mode, **stop here** and wait for `continue` / `retry <task>` / `skip <task>` /
`stop`.

### 5. Final summary
When the roadmap is delivered (or you stop):
```
## Autopilot summary
### Delivered to main
| Phase | Tasks | PRs merged |
|-------|-------|------------|
### Parked (needs human)
| Task | PR | Why |
### Remaining (if stopped early)
| Phase | Tasks | Status |
### Notable decisions & blockers
- ...
```

## Writer agent prompt template

```
## Project Context
<your 3–5 line summary, incl. test strategy>

## Build & Test Commands
<from CLAUDE.md / TDD — the exact verify, lint, build commands>

## Test Strategy
<from TDD Testing Strategy, or "Discover from codebase — check test dirs, frameworks, patterns">

## Your Task
Phase: <phase>   Task: <task>
Spec: <spec path — READ THIS FIRST, in full>
Also read: <architecture / threat-model / referenced specs>
Files to create/modify: <list>
Test layers needed: <from roadmap task, e.g. "Unit + Widget">
Verification: <command(s)>
Base branch: main   Branch to create: <type>/<slug>

## Instructions
1. Read the spec FIRST, in full, plus referenced docs. Do not guess or assume.
2. If the test strategy says "Discover from codebase", find existing test dirs/frameworks/patterns first.
3. Implement exactly per spec. Do not touch files outside your task's list unless strictly necessary.
4. Write tests at the layers specified, covering the spec's verification criteria (unit: logic/
   validators/pure fns; widget/integration/e2e only where the spec calls for them).
5. Run the verification command, the linter, and the build; fix until all are green. Paste the
   tail of each in your final report.
6. Commit with conventional-commit messages, SPLIT by logical concern (each commit leaves the tree
   working). Push the branch. Open a PR (base main) with: summary, link to the spec, security note,
   and a test plan listing the spec's verification criteria with pass/fail.
7. Report: branch, PR URL, verification tails, and any blocker or judgement call you made.

## Important
- Read the spec FIRST. Document any reasonable decision you had to make in the PR.
- Don't attempt builds the environment can't do (note them instead).
- You may be resumed with review findings to fix — keep your context.
```

## Rules

1. **Autonomous by default.** Develop → review → fix → **merge to main**, looping through phases
   with no human gate. `--supervised` restores per-phase human checkpoints. Never silently switch
   modes.
2. **Stay thin.** Delegate all implementation and all review. You parse, dispatch, triage, merge,
   and track — you do not read implementation files or write/review code yourself.
3. **Writer ≠ reviewer.** Review always runs as a separate agent with cold context. Never let the
   writing context review its own work; never review it yourself.
4. **Reviewer verifies for real.** The reviewer runs the build/tests itself; a green claim from the
   writer is not evidence.
5. **Respect dependencies via merge, not completion.** A dependent task's worktree must branch off a
   `main` that already contains what it depends on. Wait for the **merge**, not just the PR.
6. **No file-overlap in a wave.** Two parallel writers must never touch the same file.
7. **Bounded fixing.** Max 2 fix cycles per PR; then park as `NEEDS_HUMAN` and move on. Don't loop
   forever on spec-ambiguity.
8. **Preserve commit structure on merge.** Rebase or merge-commit, not squash (unless the repo
   mandates squash).
9. **Security gate for risky diffs.** Trust boundaries / auth / crypto / parsing / secrets / deps →
   `/sec-review` before merge; HIGH+ blocks the merge.
10. **Feature flags off until phase end.** Flip the flag on only once the phase's flow is coherent.
11. **Stop on genuine blockers** (see below) — surface them, don't barrel through.
12. **Resumable.** Keep roadmap status updated and committed so an interrupted run can pick up where
    it left off.

## Stop conditions (even in autonomous mode)

Halt and surface — do not improvise past these:
- A verification/build failure a writer can't fix within 2 cycles, or a reviewer finding that
  survives 2 cycles (spec-ambiguity).
- A merge conflict that isn't mechanically resolvable.
- A spec that is missing, contradictory, or contradicts the architecture.
- A HIGH+ security finding that can't be safely resolved.
- `main` is protected such that you cannot merge (switch to `--supervised`).
- Any destructive or irreversible action outside the roadmap's scope (data migration with loss,
  deleting user data, force-pushing shared history, publishing/releasing) — these need explicit
  human sign-off regardless of mode.
