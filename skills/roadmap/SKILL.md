---
name: roadmap
description: "Create a phased roadmap from design docs: /roadmap <phase-name> or /roadmap (full roadmap)"
---
Create a phased roadmap for: $ARGUMENTS

## Parse Arguments

The argument can be:
- **Phase name:** `/roadmap auth-system` — creates `docs/roadmap/NNN_auth-system.md` where `NNN` is the next available 3-digit prefix
- **No argument:** `/roadmap` — reads PRD, architecture, and any existing specs to create a full roadmap with numbered phase files
- **Doc path:** `/roadmap docs/specs/feature_x.md` — creates a roadmap for a single spec or feature area

## Phase Numbering

All phase files get a zero-padded 3-digit prefix so phase order is obvious at a glance and files sort correctly: `001_foundations.md`, `002_api-layer.md`, `003_frontend.md`, etc. The index file `docs/roadmap/README.md` stays **unnumbered** — it's the table of contents, not a phase.

**Rules:**
- **Scan, don't renumber.** Before creating a phase, list `docs/roadmap/` and extract existing `NNN_*.md` prefixes. Use `max(existing) + 1`, zero-padded to 3 digits. Never renumber existing files — commits, PRs, and specs may reference them by name.
- **Full roadmap from scratch:** first phase is `001_`, numbered in dependency order.
- **Adding to an existing roadmap:** continue from the next available number.
- **Separator is underscore** (`001_auth-system.md`), not dash, to keep the numeric prefix visually distinct from the kebab-case phase slug.

## Context Gathering

Before anything, read what exists:

1. **Design docs (primary input for the roadmap):**
   - Read `docs/PRD.md` or `docs/prd/` — the source of *what* needs to be built
   - Read `docs/specs/ARCHITECTURE.md` — the source of *how* the system is structured
   - Read `docs/specs/TDD.md` — testing strategy, dev environment, CI/CD
   - Read `docs/specs/THREAT_MODEL.md` — security constraints, trust boundaries
   - Read `CLAUDE.md` for build commands and conventions
   - Read `README.md` for project overview

2. **Existing specs (optional — specs may not exist yet):**
   - List all files in `docs/specs/`
   - If feature specs exist, read them — they add detail to the roadmap
   - If no feature specs exist, that's fine — the roadmap will define *what* needs to be specified

3. **Existing roadmap:**
   - Check `docs/roadmap/` — if roadmaps already exist, read them to avoid duplication
   - If the user is adding to an existing roadmap, build on what's there

4. **Codebase state:**
   - Explore the directory structure to understand what already exists
   - Check `git log --oneline -20` for recent work direction
   - Identify what (if anything) is already implemented

**Minimum required context:** A PRD or architecture doc. The roadmap breaks down *what the design docs describe* into phased, executable work. If neither exists, stop and tell the user:
"No PRD or architecture doc found. Create one first with `/prd` or `/architecture`, then come back to build the roadmap."

## Interview

Use AskUserQuestion to refine the roadmap. Adapt questions based on what you learned from the design docs and codebase.

1. **Priorities** — Which features are most important? What must ship first? Are there external deadlines?
2. **Dependencies** — Are there features that must be done before others? Shared interfaces or data models that need to exist first?
3. **Parallelization** — How many worktrees/agents can run simultaneously? Any file overlap concerns between features?
4. **Team context** — Is this a solo developer or a team? How many streams of parallel work are practical?
5. **Verification** — What are the build/test/lint commands? Are there integration tests that span features?
6. **Phase boundaries** — Where are the natural checkpoints? What needs human review before continuing?

**Interview rules:**
- If design docs are clear and dependencies are obvious, keep the interview short (2-3 questions)
- If the PRD is broad or there are many features, dig deeper
- Push back on unrealistic parallelization — if two tasks touch the same files, they must be sequential
- Don't ask what's already answered in the design docs

## Generate the Roadmap

Create `docs/roadmap/` directory if it doesn't exist.

### Single Phase

If the user gave a phase name or single feature area, compute the next prefix (see Phase Numbering above) and write to `docs/roadmap/NNN_<phase-name>.md`:

```markdown
# Phase: [Name]

## Context
[What this phase accomplishes. Dependencies on prior phases if any.]

## Tasks

### Task 1: [Name]
- **Spec:** docs/specs/[name].md (exists | needs creation)
- **Files:** [list of files to create or modify]
- **Dependencies:** None
- **Tests:** Unit + Integration (sets up data models and API layer)
- **Verification:** [command to verify this task works]
- **Estimated complexity:** Low/Medium/High

### Task 2: [Name]
- **Spec:** docs/specs/[name].md (exists | needs creation)
- **Files:** [list of files to create or modify]
- **Dependencies:** Task 1 (needs [specific thing])
- **Tests:** Unit + Integration (service interactions)
- **Verification:** [command]
- **Estimated complexity:** Medium

### Task 3: [Name] (can parallelize with Task 2)
- **Spec:** docs/specs/[name].md (exists | needs creation)
- **Files:** [list — no overlap with Task 2]
- **Dependencies:** Task 1
- **Tests:** Unit only (pure UI logic, no service boundary)
- **Verification:** [command]
- **Estimated complexity:** Low

## Execution Order

1. **Sequential:** Task 1 (foundation — others depend on it)
2. **Parallel:** Task 2 + Task 3 (no file overlap, both depend only on Task 1)

## Phase Checklist
- [ ] All tasks have detailed specs
- [ ] All tasks completed
- [ ] All verification commands pass
- [ ] PRs reviewed and merged
- [ ] Integration tests pass (if applicable)
```

### Full Roadmap

If the user gave no argument (build from design docs), write an index at `docs/roadmap/README.md` plus one file per phase:

**`docs/roadmap/README.md`:**

```markdown
# Roadmap

## Overview
[What the full roadmap accomplishes. High-level project goal.]

## Phases

| # | Phase | Tasks | Dependencies | Status |
|---|-------|-------|-------------|--------|
| 001 | [phase-name](001_phase-name.md) | [count] | None | Not started |
| 002 | [phase-name](002_phase-name.md) | [count] | 001 | Not started |
| 003 | [phase-name](003_phase-name.md) | [count] | 002 | Not started |

## Execution Notes
- [Key parallelization opportunities]
- [Critical path — the longest sequential chain]
- [Known risks or blockers]
```

Then create each `docs/roadmap/NNN_<phase-name>.md` using the single-phase format above, numbering phases in dependency order starting at `001_`.

## Key Rules for Task Breakdown

1. **One task = one PR.** Each task should produce a single, reviewable PR.
2. **Identify parallelizable tasks** — tasks that touch different files can run simultaneously in worktrees.
3. **Mark dependencies explicitly** — if Task B needs Task A's output, say so and explain what specifically it needs.
4. **Keep tasks small** — if a task would fill Claude's context window, split it. A task should be completable in one worktree session.
5. **Include verification commands** — every task needs a concrete way to prove it works.
6. **Specify test layers per task** — based on the Testing Strategy in `docs/specs/TDD.md` (or inferred from the codebase), mark which test layers each task needs: Unit, Integration, E2E. A task that touches APIs needs integration tests. A task that implements a critical user flow needs e2e. Pure logic only needs unit.
7. **Foundation first** — shared types, interfaces, data models, and config go in Phase 1. Implementation builds on top.
8. **File overlap = sequential** — if two tasks modify the same file, they cannot run in parallel. Call this out explicitly.
9. **Mark spec status per task** — for each task, indicate whether a detailed spec exists or needs to be created. Tasks without specs need `/spec` or `/speckit.specify` before execution.

## After Writing

1. Present the roadmap to the user for review. Highlight:
   - The critical path (longest sequential chain)
   - Parallelization opportunities
   - Which tasks already have specs and which need them

2. Iterate until the user is satisfied.

3. Suggest next steps based on spec coverage:
   - **Tasks need specs?** → "Create detailed specs before executing: `/spec <feature-name>` for each task (or `/speckit.specify` with GitHub Spec Kit)"
   - **All tasks have specs?** → "Run `/autopilot docs/roadmap/README.md` to execute the full roadmap"
   - **Start one phase?** → "Run `/autopilot docs/roadmap/NNN_<phase-name>.md`" (use the actual numbered filename)
   - **Single task?** → "Run `/feature docs/specs/<name>.md`"
