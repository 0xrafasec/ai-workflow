# Architecture document template

Copy this structure into `docs/ARCHITECTURE.md` and fill it in. Drop sections that do not apply; keep the `## Testing Strategy` heading exactly as is.

````markdown
# Architecture

**Last updated:** [date]

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
````
