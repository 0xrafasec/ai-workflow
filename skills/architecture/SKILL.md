---
name: architecture
description: "Create or update docs/ARCHITECTURE.md — one document covering the system (components, data flow, stack, deployment, key decisions) and how it is engineered (testing strategy, dev environment, CI/CD, coding standards). Use when the user asks to design the system, map how pieces fit together, define the testing strategy, set up CI/CD or repo conventions, or says 'how should this be structured', 'let's architect this', 'how should we test this', 'write the tech design doc'."
argument-hint: "[focus area]"
---
Create or update the architecture document. Argument: $ARGUMENTS

`docs/ARCHITECTURE.md` has two parts. **System** says what is being built and how the pieces fit. **Engineering** says how it is built, tested and shipped. They live in one file because they share the stack and deployment decisions, and because `/wf:spec`, `/wf:feature`, `/wf:fix` and `/wf:autopilot` read both before touching code.

## Context Gathering

Read what already exists before asking anything:

1. **Existing docs** — `docs/ARCHITECTURE.md` (if revising, don't start from scratch), `docs/PRD.md` or `docs/prd/`, `docs/THREAT_MODEL.md`, `README.md`, `CLAUDE.md`, any whitepaper or design doc.
2. **Legacy split** — if `docs/TECHNICAL_DESIGN_DOCUMENT.md` exists, the project predates the merged document. Read it, carry its content into the Engineering part, and ask whether to delete it once the merged file is written.
3. **The codebase:**
   - Directory structure and key entry points (main files, route definitions, config).
   - `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `Makefile`, `docker-compose.yml` — dependencies, tooling, test commands.
   - Test directories and 1–2 existing test files, to see the patterns (fixtures, helpers, naming).
   - CI config (`.github/workflows/`, `.gitlab-ci.yml`) and linter/formatter config.
   - `git log --oneline -20` for recent direction.

Summarize what you learned before the interview — "Here's what I understand about this project so far: ..."

## Interview

Use AskUserQuestion. Skip anything the codebase already answers; for an inherited project, ask "is my understanding correct?" and "what would you change?" rather than "what do you want?".

**System**

1. **Components** — What are the main components/services/modules? How do they communicate? Where are the trust boundaries?
2. **Data flow** — How does data enter, get processed, and get stored? What are the critical paths?
3. **Technology choices** — What stack and why? Hard constraints versus preferences?
4. **Deployment** — How does this run (single binary, services, serverless) and where?
5. **Scale and performance** — Expected load? Where are the bottlenecks? What must be fast?
6. **Integration points** — What external systems does it talk to? What does it expose?
7. **Key decisions** — What has already been decided, and what tradeoffs were accepted?

**Engineering**

8. **Testing strategy** — Which frameworks? Where do tests live? Which layers exist (unit / integration / e2e), and what belongs in each? Which flows need e2e coverage?
9. **Dev environment** — How does someone set up locally? Which external services are needed?
10. **CI/CD** — What runs on every PR? What blocks a merge? How are deployments triggered and rolled back?
11. **Coding standards** — Linter, formatter, type checker; conventions the tooling does not capture.
12. **Observability and dependencies** — Logging, error tracking, metrics; how dependencies are pinned, scanned and updated.

## Write

Write to `docs/ARCHITECTURE.md`:

```markdown
# Architecture

**Version:** [version]
**Date:** [date]

# Part 1 — System

## System Overview

[High-level description, with a Mermaid diagram of the major components and their relationships.]

## Components

### [Component]
- **Responsibility:** [what it does]
- **Technology:** [stack/language]
- **Interfaces:** [what it exposes, what it consumes]
- **Key design decisions:** [why it is built this way]

## Data Flow

[How data moves through the system. Mermaid sequence or flow diagrams for the critical paths.]

## Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| [layer] | [tech] | [why] |

## Deployment Model

[Infrastructure, environments, how a release reaches production, rollback.]

## Scale and Performance

[Expected load, known bottlenecks, what must be fast.]

## Key Decisions

| Decision | Choice | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| [decision] | [chosen] | [considered] | [why] |

## Constraints and Limitations

[Known limitations, technical debt, things that need revisiting.]

# Part 2 — Engineering

## Testing Strategy

[The source of truth `/wf:feature`, `/wf:fix`, `/wf:spec` and `/wf:autopilot` read when deciding which tests to write. Keep this heading exactly as is.]

### Test Layers

| Layer | Scope | Framework | Run Command | When to Write |
|-------|-------|-----------|-------------|---------------|
| Unit | Single function/module, no I/O | [e.g., pytest, vitest, go test] | [e.g., make test-unit] | Every change — business logic, pure functions, validators |
| Integration | Component boundaries, real dependencies | [e.g., pytest + testcontainers] | [e.g., make test-integration] | API endpoints, database queries, service interactions |
| E2E | Full user flows, production-like environment | [e.g., playwright] | [e.g., make test-e2e] | Critical user paths |

### Test Conventions

- **File location:** [e.g., `tests/unit/`, `tests/integration/`, or colocated `__tests__/`]
- **Naming:** [e.g., `test_<module>.py`, `<module>.test.ts`, `<module>_test.go`]
- **Fixtures/factories:** [where shared test helpers live]
- **Test database:** [how integration tests get one]
- **CI behavior:** [which layers run on PR, which run nightly]

### Coverage Expectations

- Unit: all business logic, validation, and error paths
- Integration: all API endpoints, database operations, and external service calls
- E2E: the critical user journeys — [list the 3–5 that matter]

## Dev Environment

[Step-by-step local setup: prerequisites, install commands, env vars.]

| Service | Local Setup | Purpose |
|---------|------------|---------|
| [e.g., PostgreSQL] | [e.g., docker compose up] | [e.g., primary data store] |

## CI/CD Pipeline

| Check | Command | Blocks Merge |
|-------|---------|-------------|
| [e.g., Lint] | [e.g., make lint] | Yes |
| [e.g., Unit tests] | [e.g., make test-unit] | Yes |
| [e.g., E2E tests] | [e.g., make test-e2e] | No (nightly) |

## Coding Standards

- **Linter:** [tool and config file]
- **Formatter:** [tool and config file]
- **Type checker:** [tool and config file]
- **Conventions not captured in tooling:** [what humans need to know]

## Observability

- **Logging:** [framework, format, levels]
- **Error tracking:** [service]
- **Metrics:** [what is measured, where the dashboards live]

## Dependency Management

- **Package manager / version strategy:** [tool; pinned or ranges]
- **Vulnerability scanning and update cadence:** [tool, frequency, owner]
```

Adapt the structure to the project. A small project may not need Deployment, Scale and Performance, or Observability; a monorepo may need a package layout section or per-package testing notes. Keep the `## Testing Strategy` heading whatever else changes.

## After Writing

1. Present the document for review. Iterate until the user is satisfied.
2. Suggest next steps based on what exists:
   - No threat model and the system has trust boundaries? → "Consider `/wf:threat-model`"
   - A decision here deserves its own record? → "Capture it with `/wf:adr <title>`"
   - Ready to build? → "Create feature specs with `/wf:spec <name>`, then `/wf:roadmap`"
