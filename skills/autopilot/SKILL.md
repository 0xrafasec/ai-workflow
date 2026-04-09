---
name: autopilot
description: Execute a full roadmap automatically, phase by phase, with parallel worktree agents
---
Execute the roadmap at: $ARGUMENTS

## Overview

You are an **orchestrator**. Your job is to stay thin — read the roadmap, dispatch work to subagents, track progress, and pause for human checkpoints. You do NOT implement anything yourself. Every implementation task is delegated to a worktree subagent.

## Process

### 1. Parse the Roadmap

Read the roadmap file. For each phase, extract:
- **Phase name and goal**
- **Tasks** — each with: name, spec path, files touched, dependencies, verification command
- **Which tasks can run in parallel** (no file overlap, no dependency between them)
- **Which tasks must be sequential** (dependency on another task in the same phase)

If the roadmap doesn't have enough detail (missing spec paths, unclear dependencies), stop and tell the user what's missing before proceeding.

### 2. Read Project Context (once)

Read these files to understand the project — this is the only heavy reading you do:
- `CLAUDE.md` — build commands, conventions
- `docs/PRD.md` or equivalent — what the project is
- `docs/specs/ARCHITECTURE.md` — system structure (if exists)
- `docs/specs/TDD.md` — **Testing Strategy**, dev environment, CI/CD (if exists)
- `docs/specs/THREAT_MODEL.md` — security model (if exists)

Summarize what you learned in 3-5 lines, **including the test strategy from TDD.md** (frameworks, test layers, run commands, file locations). This summary will be passed to every subagent so they have project context without reading everything themselves. If no TDD.md exists, note that subagents should discover test patterns from the codebase.

### 3. Execute Phase by Phase

For each phase in order:

#### a. Announce the phase

```
## Phase N: [Name]
Goal: [goal]
Tasks: [count] ([count] parallel, [count] sequential)
```

#### b. Check for completed phases

If the roadmap marks a phase as complete (e.g., with a checkmark), skip it and announce that you're skipping.

#### c. Dispatch parallel tasks

For tasks that can run in parallel (no dependencies between them, no file overlap), spawn them **all at once** using the Agent tool with `isolation: "worktree"`. Each agent gets this prompt:

```
## Project Context
[Your 3-5 line summary from step 2]

## Build & Test Commands
[From CLAUDE.md]

## Test Strategy
[From TDD.md Testing Strategy, or "Discover from codebase — check test directories, frameworks, patterns"]

## Your Task
Phase: [phase name]
Task: [task name]
Spec: [spec path — the agent MUST read this]
Files to modify: [list]
Test layers needed: [from roadmap task — e.g., "Unit + Integration"]
Verification: [command]

## Instructions
1. Read the spec file thoroughly. Also read any referenced specs (architecture, security).
2. If the Test Strategy above says "Discover from codebase", look for existing test directories, frameworks, and patterns before writing any tests.
3. Implement the task following the spec exactly.
4. Write tests at the layers specified above, covering all verification criteria from the spec:
   - **Unit tests:** business logic, validators, pure functions
   - **Integration tests:** API endpoints, database operations, service boundaries
   - **E2E tests:** only if specified for critical user flows
5. Run the verification command and fix any failures.
6. Run the project's lint and typecheck commands.
7. Spawn a security-reviewer subagent to review your changes.
8. Spawn an architecture-reviewer subagent to review your changes.
9. Fix any HIGH severity findings.
10. Commit with conventional commit messages, split by logical concern.
11. Push the branch.
12. Create a PR with:
    - Summary (what changed and why)
    - Link to the spec
    - Security review status
    - Test plan with verification criteria

## Important
- Read the spec FIRST. Do not guess or assume.
- If something is unclear in the spec, make a reasonable decision and document it in the PR.
- Do not modify files outside your task's file list unless absolutely necessary.
- If you encounter a blocker, document it clearly in your final output.
```

For tasks that depend on other tasks within the same phase, wait for the dependency to complete before dispatching.

#### d. Collect results

As each subagent completes, record:
- Task name
- Status: success / failed / blocked
- PR URL (if created)
- Any issues or blockers reported
- Worktree branch name

#### e. Phase summary and checkpoint

After ALL tasks in the phase complete, present a summary:

```
## Phase N Complete

| Task | Status | PR | Notes |
|------|--------|----|-------|
| [name] | success | #URL | — |
| [name] | failed | — | [reason] |

### Action Required
Review and merge the PRs above before continuing.
- [ ] PR 1: [url]
- [ ] PR 2: [url]

When ready, say "continue" to proceed to Phase N+1.
If a task failed, say "retry [task name]" to re-run it.
If you want to stop, say "stop".
```

**Wait for the user.** Do NOT proceed to the next phase automatically. The user needs to:
1. Review each PR
2. Merge them into main
3. Confirm before the next phase (which may depend on merged code)

#### f. Handle user responses

- **"continue"** — proceed to the next phase
- **"retry [task]"** — re-dispatch that specific task as a new worktree agent
- **"skip [task]"** — mark it as skipped and continue
- **"stop"** — halt execution, summarize what was completed and what remains
- **Any other feedback** — address it before continuing

### 4. Final Summary

After all phases complete (or the user stops), present:

```
## Autopilot Summary

### Completed
| Phase | Tasks | PRs Merged |
|-------|-------|------------|
| [phase] | [count] | [urls] |

### Remaining (if stopped early)
| Phase | Tasks | Status |
|-------|-------|--------|
| [phase] | [count] | not started |

### Issues Encountered
- [Any blockers, failures, or workarounds]
```

## Rules

1. **Stay thin.** You are the orchestrator. Do not read implementation files, do not write code, do not review PRs yourself. Delegate everything.
2. **Never skip checkpoints.** Always wait for user confirmation between phases.
3. **Pass context, not files.** Give subagents the spec path and project summary. Let them read the files themselves in their own context.
4. **Track everything.** After each subagent completes, record its result. If context gets heavy, use `/compact`.
5. **Respect dependencies.** If task B depends on task A, never dispatch B until A's PR is merged (not just completed — merged, so the code is on main).
6. **Fail gracefully.** If a subagent fails, report it and let the user decide. Don't retry automatically — the user might want to fix the spec or roadmap first.
