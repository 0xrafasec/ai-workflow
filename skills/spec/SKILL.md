---
name: spec
description: "Create a feature implementation spec at docs/specs/<feature>.md — scope, approach, affected files, verification. Use when the user says 'spec out feature X', 'write the implementation plan for Y', 'turn this idea into a spec', 'document how we'll build this', or needs a doc the /feature skill can execute from later."
---
Create a feature implementation spec for: $ARGUMENTS

## Context Gathering

Before interviewing, read what already exists:

1. **Check for existing docs:**
   - Read `docs/PRD.md` or `docs/prd/` if they exist
   - Read `docs/specs/ARCHITECTURE.md` for system structure
   - Read `docs/specs/TECHNICAL_DESIGN_DOCUMENT.md` for testing strategy
   - Read `docs/specs/THREAT_MODEL.md` for security context
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

## Write

Write to `docs/specs/<feature_name>.md`:

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

*Adapt the layers to what the feature touches. A pure logic change may only need unit tests. An API feature needs unit + integration. A critical user-facing flow needs all three. Reference the Testing Strategy in `docs/specs/TECHNICAL_DESIGN_DOCUMENT.md` if it exists.*

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
