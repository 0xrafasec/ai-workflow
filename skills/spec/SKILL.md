---
name: spec
description: "Create a spec document: /spec architecture, /spec security, or /spec <feature-name>"
---
Create a specification document. Argument: $ARGUMENTS

## Determine Mode

Parse the argument to determine which type of spec to create:

- **`architecture`** — System architecture document
- **`security`** — Threat model and security spec
- **Anything else** — Feature implementation spec (the argument is the feature name)

## Context Gathering (ALL modes)

Before interviewing, **read what already exists** to build context. This is critical — especially for inherited projects with no PRD.

1. **Check for existing docs:**
   - Read `docs/PRD.md` or `docs/prd/` if they exist
   - Read `docs/specs/` for any existing specs
   - Read `README.md`, `CLAUDE.md`
   - Read any whitepaper, design doc, or architecture doc you find

2. **If no docs exist (inherited project):**
   - Read `README.md` for project overview
   - Explore the directory structure to understand the codebase layout
   - Read key entry points (main files, route definitions, config files)
   - Check `git log --oneline -20` for recent direction
   - Read `package.json`, `Cargo.toml`, `pyproject.toml`, or equivalent for dependencies and project metadata
   - Summarize what you learned to the user before starting the interview — "Here's what I understand about this project so far: ..."

3. **Read any existing spec of the same type** — if the user is revising, don't start from scratch.

---

## Mode: architecture

### Interview

Use AskUserQuestion to dig into the system design. Adapt questions based on what you already learned from the codebase.

1. **Components** — What are the main components/services/modules? How do they communicate? What are the trust boundaries?
2. **Data flow** — How does data enter the system, get processed, and get stored? What are the critical paths?
3. **Technology choices** — What stack and why? What are the hard constraints vs preferences?
4. **Deployment** — How does this run? Single binary, microservices, serverless? Where (cloud, on-prem, edge)?
5. **Scaling and performance** — What are the expected loads? Where are the bottlenecks? What needs to be fast?
6. **Integration points** — What external systems does this talk to? What APIs does it expose? What does it depend on?
7. **Key decisions** — What architectural decisions have already been made? What tradeoffs were accepted and why?
8. **Testing** — What test frameworks are in use? Where do tests live? Are there separate unit/integration/e2e layers? What needs integration tests vs unit tests? Any critical flows that need e2e coverage?

For inherited projects, focus more on: "Is my understanding correct?" and "What would you change?" rather than "What do you want?" For testing, explore the existing test directories and patterns before asking — "I see you have pytest with a `tests/` folder but no integration tests yet — is that intentional?"

### Write

Write to `docs/specs/ARCHITECTURE.md`:

```markdown
# Architecture

**Version:** [version]
**Date:** [date]

## System Overview

[High-level description. Include a Mermaid diagram showing major components and their relationships.]

## Components

### [Component 1]
- **Responsibility:** [what it does]
- **Technology:** [stack/language]
- **Interfaces:** [what it exposes, what it consumes]
- **Key design decisions:** [why it's built this way]

### [Component 2]
...

## Data Flow

[How data moves through the system. Use Mermaid sequence or flow diagrams for critical paths.]

## Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| [layer] | [tech] | [why] |

## Testing Strategy

[Define the testing approach for this project. This section is the source of truth that all other skills (/feature, /fix, /roadmap, /autopilot) reference when deciding what tests to write.]

### Test Layers

| Layer | Scope | Framework | Run Command | When to Write |
|-------|-------|-----------|-------------|---------------|
| Unit | Single function/module, no I/O | [e.g., pytest, vitest, go test] | [e.g., make test-unit] | Every change — business logic, pure functions, validators |
| Integration | Component boundaries, real dependencies | [e.g., pytest + testcontainers, supertest] | [e.g., make test-integration] | API endpoints, database queries, service interactions, middleware |
| E2E | Full user flows, production-like environment | [e.g., playwright, cypress, k6] | [e.g., make test-e2e] | Critical user paths, auth flows, payment flows |

### Test Conventions

- **File location:** [e.g., `tests/unit/`, `tests/integration/`, `tests/e2e/` or colocated `__tests__/`]
- **Naming:** [e.g., `test_<module>.py`, `<module>.test.ts`, `<module>_test.go`]
- **Fixtures/factories:** [where shared test helpers live]
- **Test database:** [how integration tests get a database — testcontainers, sqlite, etc.]
- **CI behavior:** [which layers run on PR, which run nightly]

### Coverage Expectations

- Unit tests: cover all business logic, validation, and error paths
- Integration tests: cover all API endpoints, database operations, and external service calls
- E2E tests: cover critical user journeys (list the 3-5 most important flows)

## Deployment Model

[How the system is deployed. Infrastructure, environments, CI/CD.]

## Key Decisions

| Decision | Choice | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| [decision] | [what was chosen] | [what else was considered] | [why] |

## Constraints and Limitations

[Known limitations, technical debt, things that need revisiting.]
```

Adapt the structure to the project. Small projects may not need Deployment or Scaling sections. Monorepos may need a crate/package layout section. Use judgment.

---

## Mode: security

### Interview

Use AskUserQuestion to understand the security landscape. Adapt based on what the codebase reveals.

1. **Trust boundaries** — What is trusted? What is untrusted? Where are the boundaries?
2. **Authentication** — How do users/agents/services prove identity? What mechanisms exist today?
3. **Authorization** — Who can do what? How are permissions modeled?
4. **Sensitive data** — What data is sensitive? Credentials, PII, financial? Where does it live? How is it protected at rest and in transit?
5. **Attack surface** — What is exposed to the internet? To local users? To other services? What inputs does the system accept?
6. **Threat actors** — Who would attack this? Script kiddies, insiders, nation states? What are their capabilities?
7. **Compliance** — Any regulatory requirements? SOC2, GDPR, HIPAA, PCI?
8. **Existing security measures** — What's already in place? What's missing?

For inherited projects: "I see you're using X for auth — is that intentional or legacy? I notice Y has no input validation — is that a known gap?"

### Write

Write to `docs/specs/THREAT_MODEL.md`:

```markdown
# Threat Model

**Version:** [version]
**Date:** [date]

## Trust Assumptions

[What is the trust model? What is trusted, what is untrusted? Include a Mermaid diagram of the trust hierarchy.]

## Security Properties

[Non-negotiable security invariants. Things that must always hold.]

- [Property 1]
- [Property 2]

## Attack Surface

| Surface | Exposure | Controls |
|---------|----------|----------|
| [surface] | [who can reach it] | [what protects it] |

## Threats

### [Threat Category 1: e.g., Agent Impersonation]

| # | Attack | Impact | Likelihood | Defense |
|---|--------|--------|------------|---------|
| 1 | [attack description] | [what happens] | [Low/Med/High] | [how it's prevented] |

### [Threat Category 2]
...

## Sensitive Data Inventory

| Data | Classification | At Rest | In Transit | Access Control |
|------|---------------|---------|------------|----------------|
| [data type] | [level] | [protection] | [protection] | [who can access] |

## Security Controls

### Implemented
- [Control 1 — what it protects against]

### Required (not yet implemented)
- [Control 1 — what it would protect against, priority]

## Compliance Requirements

[If applicable. Regulatory frameworks, what they require, current status.]
```

---

## Mode: feature (default)

### Interview

Use AskUserQuestion to nail down the implementation details. This should be precise enough that the feature can be implemented without further clarification.

1. **What exactly changes?** — Which components, APIs, data models are affected?
2. **API contract** — Exact endpoints, request/response shapes, error codes, status codes
3. **Data model** — Schema changes, migrations, new fields, new tables/collections
4. **Edge cases** — What happens when input is invalid? When dependencies are down? When data is missing? When concurrent requests collide?
5. **Security** — Auth requirements on new endpoints? Input validation rules? Data exposure risks?
6. **Verification** — How do we prove this works? Concrete test cases with inputs and expected outputs.
7. **Dependencies** — Does this depend on other work being done first? Does other work depend on this?

Build on existing architecture and security specs if they exist — reference them, don't repeat them.

### Write

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

*Adapt the layers to what the feature touches. A pure logic change may only need unit tests. An API feature needs unit + integration. A critical user-facing flow needs all three. Reference the Testing Strategy in `docs/specs/ARCHITECTURE.md` if it exists.*

## Out of Scope
[What this does NOT include]
```

---

## After Writing (ALL modes)

1. Present the document to the user for review. Iterate until they're satisfied.
2. Suggest what to do next based on what exists:
   - No architecture spec yet? → "Consider `/spec architecture` next"
   - No security spec yet and there are security concerns? → "Consider `/spec security`"
   - Specs are done? → "Ready for `/roadmap` or `/feature docs/specs/<name>.md`"
