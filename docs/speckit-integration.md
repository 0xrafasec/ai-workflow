# Using ai-workflow with GitHub Spec Kit

ai-workflow and [GitHub Spec Kit](https://github.com/github/spec-kit) solve overlapping problems from different angles. This guide shows how to combine them into a single workflow that plays to each tool's strengths.

## Where Each Tool Shines

| Phase | ai-workflow | Spec Kit |
|-------|-------------|----------|
| **Requirements** | Deep interview-driven PRDs (`/prd`) | Structured spec templates (`/speckit.specify`) |
| **Principles** | Global conventions via `CLAUDE.md` | Project constitution (`/speckit.constitution`) |
| **Architecture** | Dedicated architecture docs (`/architecture`) | Embedded in implementation plan (`/speckit.plan`) |
| **Testing strategy** | Dedicated TDD docs (`/tdd`) | Test-first enforcement via constitution articles |
| **Threat modeling** | Dedicated security docs + agents (`/security`) | Available via community extensions |
| **Feature specs** | `/spec` with verification criteria | `/speckit.specify` with acceptance criteria |
| **Task breakdown** | `/roadmap` with phase dependencies | `/speckit.tasks` with parallelization markers |
| **Implementation** | `/feature`, `/autopilot` with worktrees | `/speckit.implement` |
| **Code review** | Language-aware agents (`/code-review`, `/review`) | Community extensions |
| **Security review** | Dedicated agents + `/sec-review` | Community extensions |
| **Governance** | `/adr`, `/rfc` at any point | Constitution amendments |

**ai-workflow** is deeper on design, review, and parallel execution.
**Spec Kit** is stronger on structured templates, traceability, and agent-agnostic portability.

Together, they cover the full lifecycle without gaps.

## Combined Workflow

```mermaid
flowchart TD
    subgraph Discovery ["Discovery & Requirements"]
        A["/prd — Interview-driven PRD"] --> B["PRD document"]
    end

    subgraph Design ["System Design"]
        B --> C["/architecture"]
        B --> D["/tdd"]
        B --> E["/security"]
        C --> F["Architecture doc"]
        D --> G["Testing strategy"]
        E --> H["Threat model"]
    end

    subgraph Constitution ["Project Governance"]
        F --> I["/speckit.constitution"]
        G --> I
        H --> I
        I --> J["Constitution<br/>(informed by ai-workflow design docs)"]
    end

    subgraph Specification ["Feature Specification"]
        B --> K{Choose spec tool}
        K -->|"Deep context needed"| L["/spec — ai-workflow"]
        K -->|"Template traceability needed"| M["/speckit.specify — Spec Kit"]
        L --> N["Feature spec"]
        M --> N
    end

    subgraph Planning ["Planning & Task Breakdown"]
        N --> O["/speckit.plan"]
        O --> P["Implementation plan<br/>(constitutional compliance)"]
        P --> Q{Choose task tool}
        Q -->|"Phased execution"| R["/roadmap — ai-workflow"]
        Q -->|"Flat task list"| S["/speckit.tasks — Spec Kit"]
    end

    subgraph Execution ["Implementation"]
        R --> T["/autopilot<br/>Parallel worktree agents"]
        S --> U["/speckit.implement<br/>or /feature per task"]
        R --> V["/feature per spec"]
    end

    subgraph Review ["Review & Quality"]
        T --> W["/review + /code-review"]
        U --> W
        V --> W
        W --> X["/sec-review"]
        X --> Y["Merge"]
    end

    style Discovery fill:#e8f4f8,stroke:#2196F3
    style Design fill:#e8f4f8,stroke:#2196F3
    style Constitution fill:#fff3e0,stroke:#FF9800
    style Specification fill:#f3e5f5,stroke:#9C27B0
    style Planning fill:#f3e5f5,stroke:#9C27B0
    style Execution fill:#e8f5e9,stroke:#4CAF50
    style Review fill:#e8f4f8,stroke:#2196F3
```

## The Three Integration Patterns

Depending on your team and project, you can integrate at different levels.

### Pattern 1: ai-workflow for design, Spec Kit for execution

Best for: teams that want deep upfront design with structured, traceable task execution.

```mermaid
flowchart LR
    subgraph AW ["ai-workflow"]
        direction TB
        A1["/prd"] --> A2["/architecture"]
        A2 --> A3["/tdd"]
        A3 --> A4["/security"]
        A4 --> A5["/spec"]
    end

    subgraph SK ["Spec Kit"]
        direction TB
        B1["/speckit.constitution"] --> B2["/speckit.plan"]
        B2 --> B3["/speckit.tasks"]
        B3 --> B4["/speckit.implement"]
    end

    subgraph AW2 ["ai-workflow"]
        direction TB
        C1["/code-review"] --> C2["/sec-review"]
    end

    AW -->|"Specs + design docs"| SK
    SK -->|"PRs ready"| AW2

    style AW fill:#e8f4f8,stroke:#2196F3
    style SK fill:#fff3e0,stroke:#FF9800
    style AW2 fill:#e8f4f8,stroke:#2196F3
```

**Steps:**

1. `/prd` — interview and capture requirements
2. `/architecture` + `/tdd` + `/security` — design the system
3. `/spec <feature>` — write detailed feature specs
4. `/speckit.constitution` — encode your architecture decisions and coding standards as constitutional articles (reference the ai-workflow design docs)
5. `/speckit.plan` — create the technical implementation plan
6. `/speckit.tasks` — break into traceable tasks
7. `/speckit.implement` — execute each task
8. `/code-review` + `/sec-review` — review with language-aware agents

**Why this works:** ai-workflow's interview-driven design phase produces richer context than going straight to Spec Kit templates. Spec Kit's constitutional compliance and task traceability then keep implementation disciplined. ai-workflow's review agents catch what CI can't.

---

### Pattern 2: Spec Kit for structure, ai-workflow for power

Best for: teams that like Spec Kit's template discipline but need ai-workflow's parallel execution and deep review.

```mermaid
flowchart LR
    subgraph SK ["Spec Kit"]
        direction TB
        A1["/speckit.constitution"] --> A2["/speckit.specify"]
        A2 --> A3["/speckit.plan"]
        A3 --> A4["/speckit.tasks"]
    end

    subgraph AW ["ai-workflow"]
        direction TB
        B1["/roadmap<br/>(from Spec Kit tasks)"] --> B2["/autopilot<br/>Parallel worktrees"]
        B2 --> B3["/review"]
        B3 --> B4["/code-review"]
        B4 --> B5["/sec-review"]
    end

    SK -->|"tasks.md"| AW

    style SK fill:#fff3e0,stroke:#FF9800
    style AW fill:#e8f4f8,stroke:#2196F3
```

**Steps:**

1. `/speckit.constitution` — establish project principles
2. `/speckit.specify` — create structured feature specs
3. `/speckit.plan` — technical implementation plan
4. `/speckit.tasks` — generate task list with `[P]` parallelization markers
5. `/roadmap` — convert Spec Kit tasks into phased roadmap with dependencies
6. `/autopilot` — execute the roadmap with parallel worktree agents
7. `/review` + `/code-review` + `/sec-review` — full review pipeline

**Why this works:** Spec Kit's templates enforce structure that prevents vague specs. ai-workflow's `/autopilot` can then run multiple tasks in parallel across isolated worktrees — something Spec Kit's `/speckit.implement` does sequentially.

---

### Pattern 3: Cherry-pick the best of each

Best for: solo developers or small teams that want flexibility.

Pick the tool that fits each phase:

| Phase | Recommended | Why |
|-------|-------------|-----|
| Requirements | `/prd` (ai-workflow) | Interactive interview surfaces edge cases better than filling templates |
| Principles | `/speckit.constitution` (Spec Kit) | Constitutional articles are more enforceable than CLAUDE.md conventions |
| Architecture | `/architecture` (ai-workflow) | Dedicated doc is easier to reference than embedded plan sections |
| Testing strategy | `/tdd` (ai-workflow) | Separate doc keeps concerns clean |
| Feature spec | Either — depends on the feature | Use `/spec` for complex features needing deep context; `/speckit.specify` for well-understood features needing traceability |
| Task breakdown | `/speckit.tasks` (Spec Kit) | Better traceability with `[P]` markers and spec references |
| Implementation | `/autopilot` (ai-workflow) | Parallel worktree execution is faster for multi-task phases |
| Code review | `/code-review` (ai-workflow) | Language-specific review guides are deeper |
| Security review | `/sec-review` (ai-workflow) | Dedicated parallel analysis agents |
| Governance | `/adr` (ai-workflow) | Lightweight and can be created at any point |

---

## Setting Up Both Tools

### Install ai-workflow

```bash
git clone https://github.com/0xrafasec/ai-workflow.git
cd ai-workflow
./install.sh
```

### Install Spec Kit

```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.1.4
```

Then initialize in your project:

```bash
cd your-project
specify init .
```

### Connecting the Design Docs

When running `/speckit.constitution`, reference the ai-workflow design docs:

```
Create the project constitution. Use these documents as input:
- Architecture: docs/architecture.md
- Testing strategy: docs/tdd.md
- Security: docs/security.md

Encode the key decisions from these documents as constitutional articles.
```

When running `/speckit.plan`, reference the feature spec:

```
/speckit.plan

Use the feature spec at docs/specs/feature-name.md as the primary input.
The architecture is defined in docs/architecture.md.
```

### Feeding Spec Kit Tasks into ai-workflow

Convert `tasks.md` into a roadmap:

```
/roadmap

Read the tasks from .speckit/features/NNN-feature-name/tasks.md.
Group them into phases based on dependencies.
Tasks marked [P] can run in parallel within the same phase.
```

Then execute:

```
/autopilot docs/roadmap/feature-name.md
```

## Lifecycle Overview

```mermaid
graph TB
    subgraph Idea ["From Idea..."]
        I((Idea))
    end

    subgraph Requirements ["Requirements"]
        I --> PRD["/prd<br/>Interview & capture"]
    end

    subgraph Design ["Design"]
        PRD --> ARCH["/architecture"]
        PRD --> TDD["/tdd"]
        PRD --> SEC["/security"]
    end

    subgraph Governance ["Governance"]
        ARCH --> CONST["/speckit.constitution"]
        TDD --> CONST
        SEC --> CONST
        ADR["/adr — decisions"] -.->|"anytime"| CONST
        RFC["/rfc — proposals"] -.->|"anytime"| CONST
    end

    subgraph Specification ["Specification"]
        PRD --> SPEC["/spec or /speckit.specify"]
    end

    subgraph Planning ["Planning"]
        SPEC --> PLAN["/speckit.plan"]
        CONST --> PLAN
        PLAN --> TASKS["/speckit.tasks or /roadmap"]
    end

    subgraph Implementation ["Implementation"]
        TASKS --> AUTO["/autopilot<br/>Parallel worktrees"]
        TASKS --> FEAT["/feature<br/>One at a time"]
        TASKS --> IMPL["/speckit.implement"]
    end

    subgraph Review ["Review"]
        AUTO --> CR["/code-review"]
        FEAT --> CR
        IMPL --> CR
        CR --> SR["/sec-review"]
        SR --> REV["/review<br/>Writer/reviewer separation"]
    end

    subgraph Ship ["...to Production"]
        REV --> MERGE((Merge & Ship))
    end

    style Idea fill:#fce4ec,stroke:#E91E63
    style Requirements fill:#e8f4f8,stroke:#2196F3
    style Design fill:#e8f4f8,stroke:#2196F3
    style Governance fill:#fff3e0,stroke:#FF9800
    style Specification fill:#f3e5f5,stroke:#9C27B0
    style Planning fill:#f3e5f5,stroke:#9C27B0
    style Implementation fill:#e8f5e9,stroke:#4CAF50
    style Review fill:#e8f4f8,stroke:#2196F3
    style Ship fill:#e8f5e9,stroke:#4CAF50
```

## When to Use Which

| Scenario | Recommendation |
|----------|---------------|
| Greenfield project, solo developer | ai-workflow only — less setup, full lifecycle |
| Team with mixed AI tools (Copilot, Cursor, Claude) | Spec Kit for specs + planning (agent-agnostic), ai-workflow for implementation + review (Claude Code) |
| Existing Spec Kit project, want better reviews | Add ai-workflow's `/code-review` and `/sec-review` |
| Existing ai-workflow project, want better traceability | Add Spec Kit's `/speckit.constitution` and `/speckit.tasks` |
| Large project, many parallel features | Both — Spec Kit for structure, ai-workflow `/autopilot` for execution |
| Compliance-heavy project | Both — Spec Kit constitution for enforcement, ai-workflow `/sec-review` for auditing |
