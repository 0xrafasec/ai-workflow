---
name: roadmap
description: "Create a phased roadmap from specs: /roadmap <phase-name> or /roadmap (to create from all specs)"
---
Create a phased roadmap for: $ARGUMENTS

## Parse Arguments

The argument can be:
- **Phase name:** `/roadmap auth-system` — creates `docs/roadmap/auth-system.md`
- **No argument:** `/roadmap` — scans all specs in `docs/specs/` and creates a full roadmap
- **Spec path:** `/roadmap docs/specs/feature_x.md` — creates a roadmap for a single spec

## Context Gathering

Before anything, read what exists:

1. **Project context:**
   - Read `CLAUDE.md` for build commands and conventions
   - Read `docs/PRD.md` or `docs/prd/` if they exist
   - Read `docs/specs/TDD.md` if it exists
   - Read `README.md` for project overview

2. **Existing specs:**
   - List all files in `docs/specs/`
   - Read each spec to understand what features are planned
   - Note dependencies between specs (one spec referencing another)

3. **Existing roadmap:**
   - Check `docs/roadmap/` — if roadmaps already exist, read them to avoid duplication
   - If the user is adding to an existing roadmap, build on what's there

4. **Codebase state:**
   - Explore the directory structure to understand what already exists
   - Check `git log --oneline -20` for recent work direction
   - Identify which specs (if any) are already partially implemented

If critical context is missing (no specs, no PRD), stop and tell the user:
"No specs found in `docs/specs/`. Create specs first with `/spec <feature-name>`, then come back to build the roadmap."

## Interview

Use AskUserQuestion to refine the roadmap. Adapt questions based on what you learned from the specs and codebase.

1. **Priorities** — Which features are most important? What must ship first? Are there external deadlines?
2. **Dependencies** — Are there features that must be done before others? Shared interfaces or data models that need to exist first?
3. **Parallelization** — How many worktrees/agents can run simultaneously? Any file overlap concerns between features?
4. **Team context** — Is this a solo developer or a team? How many streams of parallel work are practical?
5. **Verification** — What are the build/test/lint commands? Are there integration tests that span features?
6. **Phase boundaries** — Where are the natural checkpoints? What needs human review before continuing?

**Interview rules:**
- If specs are clear and dependencies are obvious, keep the interview short (2-3 questions)
- If specs are vague or there are many features, dig deeper
- Push back on unrealistic parallelization — if two tasks touch the same files, they must be sequential
- Don't ask what's already answered in the specs

## Generate the Roadmap

Create `docs/roadmap/` directory if it doesn't exist.

### Single Phase

If the user gave a phase name or single spec, write to `docs/roadmap/<phase-name>.md`:

```markdown
# Phase: [Name]

## Context
[What this phase accomplishes. Dependencies on prior phases if any.]

## Tasks

### Task 1: [Name]
- **Spec:** docs/specs/[name].md
- **Files:** [list of files to create or modify]
- **Dependencies:** None
- **Tests:** Unit + Integration (sets up data models and API layer)
- **Verification:** [command to verify this task works]
- **Estimated complexity:** Low/Medium/High

### Task 2: [Name]
- **Spec:** docs/specs/[name].md
- **Files:** [list of files to create or modify]
- **Dependencies:** Task 1 (needs [specific thing])
- **Tests:** Unit + Integration (service interactions)
- **Verification:** [command]
- **Estimated complexity:** Medium

### Task 3: [Name] (can parallelize with Task 2)
- **Spec:** docs/specs/[name].md
- **Files:** [list — no overlap with Task 2]
- **Dependencies:** Task 1
- **Tests:** Unit only (pure UI logic, no service boundary)
- **Verification:** [command]
- **Estimated complexity:** Low

## Execution Order

1. **Sequential:** Task 1 (foundation — others depend on it)
2. **Parallel:** Task 2 + Task 3 (no file overlap, both depend only on Task 1)

## Phase Checklist
- [ ] All tasks completed
- [ ] All verification commands pass
- [ ] PRs reviewed and merged
- [ ] Integration tests pass (if applicable)
```

### Full Roadmap

If the user gave no argument (scan all specs), write an index at `docs/roadmap/README.md` plus one file per phase:

**`docs/roadmap/README.md`:**

```markdown
# Roadmap

## Overview
[What the full roadmap accomplishes. High-level project goal.]

## Phases

| # | Phase | Tasks | Dependencies | Status |
|---|-------|-------|-------------|--------|
| 1 | [phase-name](phase-name.md) | [count] | None | Not started |
| 2 | [phase-name](phase-name.md) | [count] | Phase 1 | Not started |
| 3 | [phase-name](phase-name.md) | [count] | Phase 2 | Not started |

## Execution Notes
- [Key parallelization opportunities]
- [Critical path — the longest sequential chain]
- [Known risks or blockers]
```

Then create each `docs/roadmap/<phase-name>.md` using the single-phase format above.

## Key Rules for Task Breakdown

1. **One task = one PR.** Each task should produce a single, reviewable PR.
2. **Identify parallelizable tasks** — tasks that touch different files can run simultaneously in worktrees.
3. **Mark dependencies explicitly** — if Task B needs Task A's output, say so and explain what specifically it needs.
4. **Keep tasks small** — if a task would fill Claude's context window, split it. A task should be completable in one worktree session.
5. **Include verification commands** — every task needs a concrete way to prove it works.
6. **Specify test layers per task** — based on the Testing Strategy in `docs/specs/TDD.md` (or inferred from the codebase), mark which test layers each task needs: Unit, Integration, E2E. A task that touches APIs needs integration tests. A task that implements a critical user flow needs e2e. Pure logic only needs unit.
7. **Foundation first** — shared types, interfaces, data models, and config go in Phase 1. Implementation builds on top.
8. **File overlap = sequential** — if two tasks modify the same file, they cannot run in parallel. Call this out explicitly.

## After Writing

1. Present the roadmap to the user for review. Highlight:
   - The critical path (longest sequential chain)
   - Parallelization opportunities
   - Any specs that seem incomplete or ambiguous

2. Iterate until the user is satisfied.

3. Identify tasks that lack detailed specs:
   - If any task references a spec that doesn't exist yet, flag it
   - Suggest creating specs before execution: "These tasks need specs first — run `/spec <feature-name>` for each, or `/speckit.specify` if using GitHub Spec Kit"
   - Tasks with existing, complete specs are ready to execute immediately

4. Suggest next steps:
   - **Specs needed?** → "Create specs for unspecified tasks: `/spec <feature-name>` (or `/speckit.specify` with Spec Kit)"
   - **All specs ready?** → "Run `/autopilot docs/roadmap/README.md` to execute the full roadmap"
   - **Start one phase?** → "Run `/autopilot docs/roadmap/<phase-name>.md`"
   - **Single task?** → "Run `/feature docs/specs/<name>.md`"
