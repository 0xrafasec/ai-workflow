---
name: spec
description: "Create a feature implementation spec at docs/specs/<feature>.md — scope, approach, affected files, verification. Use when the user says 'spec out feature X', 'write the implementation plan for Y', 'turn this idea into a spec', 'document how we'll build this', or needs a doc the /feature skill can execute from later."
---
Create a feature implementation spec for: $ARGUMENTS

## Context Gathering

Before interviewing, read what already exists:

1. **Check for existing docs:**
   - Read `docs/PRD.md` or `docs/prd/` if they exist
   - Read `docs/ARCHITECTURE.md` for system structure
   - Read `docs/TECHNICAL_DESIGN_DOCUMENT.md` for testing strategy
   - Read `docs/THREAT_MODEL.md` for security context
   - Read `README.md`, `CLAUDE.md`

2. **If no docs exist (inherited project):**
   - Read `README.md` for project overview
   - Explore the directory structure to understand the codebase layout
   - Read key entry points (main files, route definitions, config files)
   - Check `git log --oneline -20` for recent direction
   - Read `package.json`, `Cargo.toml`, `pyproject.toml`, or equivalent for dependencies and project metadata
   - Summarize what you learned to the user before starting the interview — "Here's what I understand about this project so far: ..."

3. **Read any existing spec for this feature** — if the user is revising, don't start from scratch.

## Interview

Use AskUserQuestion to nail down the implementation details. This should be precise enough that the feature can be implemented without further clarification.

1. **What exactly changes?** — Which components, APIs, data models are affected?
2. **API contract** — Exact endpoints, request/response shapes, error codes, status codes
3. **Data model** — Schema changes, migrations, new fields, new tables/collections
4. **Edge cases** — What happens when input is invalid? When dependencies are down? When data is missing? When concurrent requests collide?
5. **Security** — Auth requirements on new endpoints? Input validation rules? Data exposure risks?
6. **Verification** — How do we prove this works? Concrete test cases with inputs and expected outputs.
7. **Dependencies** — Does this depend on other work being done first? Does other work depend on this?

Build on existing architecture, TDD, and security docs if they exist — reference them, don't repeat them.

## Slice (trunk-based)

Before writing, estimate the implementation size (lines of code + tests). Per the global **Trunk-Based Workflow** (see root `CLAUDE.md`), each PR targets ≤200 lines.

- **≤200 lines:** one spec, one PR. Proceed to **Write** below with a single file.
- **>200 lines:** slice the feature into N independently mergeable vertical slices, each ≤200 lines. Write one sub-spec per slice under `docs/specs/<feature_name>/NNN_<slice>.md` (zero-padded, dependency order) plus an index `docs/specs/<feature_name>/README.md`.

**Slicing rules:**
- Every slice must leave `main` deployable. If a slice adds user-visible behavior that isn't ready to ship, call out a **feature flag** in its spec (name the flag, default off).
- Slice vertically (DB → API → UI for *one* capability), not horizontally (all DB, then all API, then all UI). Vertical slices ship value; horizontal slices pile up un-shippable intermediate state.
- No slice depends on an unmerged slice. If B truly needs A's code merged first, mark the dependency explicitly in B's spec and do not start B until A is merged.
- Each slice gets its own branch (`feat/<feature>-<slice-slug>`), its own PR, and is deleted after merge.

**Index file** (`docs/specs/<feature_name>/README.md`):

```markdown
# Feature: [Name]

## Problem
[One paragraph — shared context for all slices.]

## Slices

| # | Slice | Flag | Depends on | Status |
|---|-------|------|------------|--------|
| 001 | [slice-name](001_slice-name.md) | `none` or `flag_name` | — | Not started |
| 002 | [slice-name](002_slice-name.md) | `flag_name` | 001 | Not started |

## Rollout
[When each flag flips on, who owns the decision, what verifies the rollout.]
```

Then write each slice spec using the single-file template below. In each sub-spec, add a `## Feature Flag` section naming the flag and default state (or state `None — slice is user-ready on merge`).

## Write

For a single (≤200 line) spec, write to `docs/specs/<feature_name>.md`:

```markdown
# Feature: [Name]

## Problem
[What problem does this solve? Who is affected?]

## Solution
[High-level approach. What changes and why.]

## Technical Design

### API Changes
[Endpoints, request/response shapes, error codes]

### Data Model
[Schema changes, migrations needed]

### Architecture
[Which components change. How they interact. Reference ARCHITECTURE.md if it exists.]

## Security Considerations
[Auth requirements, input validation, data exposure risks. Reference THREAT_MODEL.md if it exists.]

## Feature Flag
[Flag name and default state, or `None — slice is user-ready on merge`. Required when the slice merges before user-visible behavior is complete.]

## Verification Criteria

### Unit Tests
- [ ] [function/module]: [input] → [expected output]
- [ ] [validation]: [invalid input] → [expected error]
- [ ] [edge case]: [boundary condition] → [expected behavior]

### Integration Tests
- [ ] [API endpoint]: [request] → [response + status code]
- [ ] [database operation]: [action] → [expected state]
- [ ] [service interaction]: [call] → [expected result]

### E2E Tests (if applicable)
- [ ] [user flow]: [steps] → [expected outcome]

*Adapt the layers to what the feature touches. A pure logic change may only need unit tests. An API feature needs unit + integration. A critical user-facing flow needs all three. Reference the Testing Strategy in `docs/TECHNICAL_DESIGN_DOCUMENT.md` if it exists.*

## Out of Scope
[What this does NOT include]
```

## After Writing

1. Present the spec to the user for review. Iterate until they're satisfied.
2. Suggest next steps based on what exists:
   - No architecture doc? → "Define system structure with `/architecture`"
   - No TDD? → "Define testing and dev workflow with `/tdd`"
   - No threat model and there are security concerns? → "Consider `/security`"
   - Specs are done? → "Ready for `/roadmap` or `/feature docs/specs/<name>.md`"
