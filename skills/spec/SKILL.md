---
name: spec
description: "Create a spec document: /spec architecture, /spec tdd, /spec security, /spec adr, /spec rfc, or /spec <feature-name>"
---
Create a specification document. Argument: $ARGUMENTS

## Determine Mode

Parse the argument to determine which type of spec to create:

- **`architecture`** — System architecture document (components, data flow, deployment)
- **`tdd`** — Technical Design Document (testing strategy, dev environment, CI/CD, coding standards, tooling)
- **`security`** — Threat model and security spec
- **`adr`** or **`adr <title>`** — Architecture Decision Record (captures a single decision)
- **`rfc`** or **`rfc <title>`** — Request for Comments (proposes a significant change for discussion)
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

For inherited projects, focus more on: "Is my understanding correct?" and "What would you change?" rather than "What do you want?"

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

## Mode: tdd

### Interview

Use AskUserQuestion to understand how the team builds, tests, and ships. Adapt based on what the codebase already reveals.

1. **Testing strategy** — What test frameworks are in use? Where do tests live? Are there separate unit/integration/e2e layers? What needs integration tests vs unit tests? Any critical flows that need e2e coverage?
2. **Dev environment** — How do developers set up locally? Docker, nix, manual install? What external services are needed (databases, queues, caches)?
3. **CI/CD pipeline** — What runs on every PR? What runs nightly? What gates block merging? How are deployments triggered?
4. **Coding standards** — Linter config, formatter, type checker? Any style guides or conventions not captured in tooling?
5. **Tooling decisions** — Package manager, build system, monorepo tools? Why these over alternatives?
6. **Error handling & observability** — Logging framework, error tracking, metrics? How do you debug production issues?
7. **Dependencies** — How are deps managed? Pinned versions? Vulnerability scanning? Update cadence?

For inherited projects, explore before asking — "I see you have pytest with a `tests/` folder but no integration tests yet — is that intentional?" and "Your CI runs `make test` but there's no lint step — is that by design?"

### Write

Write to `docs/specs/TDD.md`:

```markdown
# Technical Design Document

**Version:** [version]
**Date:** [date]

## Testing Strategy

[This section is the source of truth that all other skills (/feature, /fix, /roadmap, /autopilot) reference when deciding what tests to write.]

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

## Dev Environment

### Setup

[Step-by-step local setup. Prerequisites, install commands, env vars.]

### External Dependencies

| Service | Local Setup | Purpose |
|---------|------------|---------|
| [e.g., PostgreSQL] | [e.g., docker compose up] | [e.g., primary data store] |

## CI/CD Pipeline

### PR Checks

| Check | Command | Blocks Merge |
|-------|---------|-------------|
| [e.g., Lint] | [e.g., make lint] | Yes |
| [e.g., Unit tests] | [e.g., make test-unit] | Yes |
| [e.g., Integration tests] | [e.g., make test-integration] | Yes |
| [e.g., E2E tests] | [e.g., make test-e2e] | No (nightly) |

### Deployment

[How deployments are triggered. Environments, promotion strategy, rollback procedure.]

## Coding Standards

- **Linter:** [tool and config file]
- **Formatter:** [tool and config file]
- **Type checker:** [tool and config file]
- **Conventions not captured in tooling:** [anything humans need to know]

## Tooling

| Tool | Purpose | Why This Over Alternatives |
|------|---------|---------------------------|
| [tool] | [what it does] | [rationale] |

## Error Handling & Observability

- **Logging:** [framework, format, levels]
- **Error tracking:** [service, how errors are reported]
- **Metrics:** [what's measured, where dashboards live]

## Dependency Management

- **Package manager:** [tool]
- **Version strategy:** [pinned, ranges, etc.]
- **Vulnerability scanning:** [tool, frequency]
- **Update cadence:** [how often, who owns it]
```

Adapt the structure to the project. A small project may skip Observability. A monorepo may need per-package sections. Use judgment.

---

## Mode: adr

### Context

ADRs capture a single decision — the context, options considered, and the choice made. They're lightweight and accumulate over time. Each ADR is a separate numbered file.

### Interview

Use AskUserQuestion to extract the decision. Keep it focused — an ADR is one decision, not a design doc.

1. **What's the decision?** — What are you deciding? What triggered this decision?
2. **Context** — What constraints, requirements, or pressures led to this? What's the current state?
3. **Options considered** — What alternatives did you evaluate? What are the tradeoffs of each?
4. **Decision** — What did you choose and why? What was the deciding factor?
5. **Consequences** — What changes as a result? What are the known downsides you're accepting?

If the decision is straightforward (user already knows what they want and why), keep the interview to 1-2 questions to fill in gaps.

### Write

First, check `docs/adr/` for existing ADRs and determine the next number. If no ADRs exist, start at `0001`.

Write to `docs/adr/NNNN-<slug>.md`:

```markdown
# ADR-NNNN: [Title]

**Status:** Proposed | Accepted | Deprecated | Superseded by [ADR-XXXX]
**Date:** [date]
**Deciders:** [who was involved]

## Context

[What is the issue? What forces are at play? What constraints exist?]

## Decision

[What was decided. State it clearly in one sentence, then elaborate if needed.]

## Options Considered

### Option A: [Name]
- **Pros:** [benefits]
- **Cons:** [drawbacks]

### Option B: [Name]
- **Pros:** [benefits]
- **Cons:** [drawbacks]

### Option C: [Name] (if applicable)
- **Pros:** [benefits]
- **Cons:** [drawbacks]

## Consequences

### Positive
- [What improves]

### Negative
- [What gets harder or what risks are accepted]

### Neutral
- [What changes without clear positive/negative valence]

## Related

- [Links to related ADRs, specs, issues, or documents]
```

---

## Mode: rfc

### Context

RFCs are for significant changes that need team input before implementation — new systems, major refactors, breaking changes, process changes. Heavier than an ADR, lighter than a full spec. The goal is to get feedback, not to be exhaustive.

### Interview

Use AskUserQuestion to understand the proposal deeply. Push back on vague motivation — "why now?" and "what happens if we don't do this?"

1. **Proposal** — What are you proposing? What's the elevator pitch?
2. **Motivation** — Why is this needed? What's broken, missing, or changing? What happens if we do nothing?
3. **Scope** — What does this change? What does it NOT change? Where are the boundaries?
4. **Design** — How would this work at a high level? What are the key technical decisions?
5. **Alternatives** — What other approaches were considered? Why not those?
6. **Migration** — If this changes existing behavior, how do we get from here to there? Is it backwards-compatible?
7. **Risks** — What could go wrong? What are the unknowns? What needs prototyping?
8. **Open questions** — What do you want feedback on specifically? What are you least sure about?

### Write

First, check `docs/rfc/` for existing RFCs and determine the next number. If none exist, start at `0001`.

Write to `docs/rfc/NNNN-<slug>.md`:

```markdown
# RFC-NNNN: [Title]

**Status:** Draft | In Review | Accepted | Rejected | Withdrawn
**Author:** [who]
**Date:** [date]
**Review deadline:** [date, if applicable]

## Summary

[2-3 sentence elevator pitch. What is this and why should someone care?]

## Motivation

[Why is this needed? What problem does it solve? What happens if we don't do this?]

## Proposal

[Detailed description of the proposed change. Include diagrams (Mermaid) where they help. This should be concrete enough for someone to evaluate but not a full implementation spec.]

### Key Design Decisions

[Call out the important choices and why you made them.]

## Alternatives Considered

### [Alternative 1]
[Description, why it was rejected]

### [Alternative 2]
[Description, why it was rejected]

## Migration Plan

[If this changes existing behavior: how do we transition? Is it backwards-compatible? What's the rollback plan?]

[If greenfield: skip this section]

## Risks and Open Questions

| Item | Type | Status |
|------|------|--------|
| [concern] | Risk / Question | Open / Resolved: [answer] |

## Feedback Requested

[What specifically do you want reviewers to focus on? What are you least sure about?]

## References

- [Links to related docs, prior art, external resources]
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

*Adapt the layers to what the feature touches. A pure logic change may only need unit tests. An API feature needs unit + integration. A critical user-facing flow needs all three. Reference the Testing Strategy in `docs/specs/TDD.md` if it exists.*

## Out of Scope
[What this does NOT include]
```

---

## After Writing (ALL modes)

1. Present the document to the user for review. Iterate until they're satisfied.
2. Suggest what to do next based on what exists:
   - No architecture spec yet? → "Consider `/spec architecture` next"
   - No TDD yet? → "Consider `/spec tdd` to define testing strategy, dev environment, and CI/CD"
   - No security spec yet and there are security concerns? → "Consider `/spec security`"
   - Making a significant decision? → "Capture it with `/spec adr <title>`"
   - Proposing a big change that needs team input? → "Write an RFC with `/spec rfc <title>`"
   - Specs are done? → "Ready for `/roadmap` or `/feature docs/specs/<name>.md`"
