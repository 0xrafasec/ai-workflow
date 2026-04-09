---
name: architecture
description: Create or update the system architecture document
---
Create the system architecture document. Argument: $ARGUMENTS

## Context Gathering

Before interviewing, read what already exists:

1. **Check for existing docs:**
   - Read `docs/PRD.md` or `docs/prd/` if they exist
   - Read `docs/specs/ARCHITECTURE.md` — if revising, don't start from scratch
   - Read `README.md`, `CLAUDE.md`
   - Read any whitepaper, design doc, or existing architecture doc

2. **If no docs exist (inherited project):**
   - Read `README.md` for project overview
   - Explore the directory structure to understand the codebase layout
   - Read key entry points (main files, route definitions, config files)
   - Check `git log --oneline -20` for recent direction
   - Read `package.json`, `Cargo.toml`, `pyproject.toml`, or equivalent for dependencies and project metadata
   - Summarize what you learned to the user before starting the interview — "Here's what I understand about this project so far: ..."

## Interview

Use AskUserQuestion to dig into the system design. Adapt questions based on what you already learned from the codebase.

1. **Components** — What are the main components/services/modules? How do they communicate? What are the trust boundaries?
2. **Data flow** — How does data enter the system, get processed, and get stored? What are the critical paths?
3. **Technology choices** — What stack and why? What are the hard constraints vs preferences?
4. **Deployment** — How does this run? Single binary, microservices, serverless? Where (cloud, on-prem, edge)?
5. **Scaling and performance** — What are the expected loads? Where are the bottlenecks? What needs to be fast?
6. **Integration points** — What external systems does this talk to? What APIs does it expose? What does it depend on?
7. **Key decisions** — What architectural decisions have already been made? What tradeoffs were accepted and why?

For inherited projects, focus more on: "Is my understanding correct?" and "What would you change?" rather than "What do you want?"

## Write

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

## After Writing

1. Present the document to the user for review. Iterate until they're satisfied.
2. Suggest next steps based on what exists:
   - No TDD yet? → "Define testing and dev workflow with `/tdd`"
   - No threat model? → "Consider `/security` for the threat model"
   - Ready to build? → "Create feature specs with `/spec <name>`, then `/roadmap`"
