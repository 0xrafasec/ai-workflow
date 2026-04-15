# Spec-Driven Development

> A methodology where specifications are the source of truth for all implementation, testing, and review. AI agents execute specs — not vague instructions.

---

## What is Spec-Driven Development?

Spec-Driven Development (SDD) is a workflow where every feature, fix, and architectural decision is defined in a specification **before** any code is written. The spec is the contract between the human (who decides *what* to build) and the AI agent (who decides *how* to build it).

The core insight: AI is a powerful executor but a poor decision-maker. When you give it a vague instruction like "add authentication", you get code that "looks right" but misses edge cases, security requirements, and integration constraints. When you give it a precise spec with verification criteria, you get code that's correct on the first pass.

**SDD is not waterfall.** Specs are living documents — they get refined through interviews, updated as constraints emerge, and versioned alongside the code. The key difference from ad-hoc prompting is that the spec exists as an artifact that can be reviewed, shared, and referenced by multiple agents.

---

## The Document Hierarchy

Specs don't exist in isolation. They form a layered system where each document builds on the ones above it:

```mermaid
graph TD
    PRD["/prd<br/>Product Requirements"]
    ARCH["/architecture<br/>System Architecture"]
    TDD["/tdd<br/>Technical Design"]
    SEC["/security<br/>Threat Model"]
    SPEC["/spec<br/>Feature Specs"]
    ROAD["/roadmap<br/>Task Breakdown"]
    DESIGN["/design + /verify-design<br/>UI design in Paper"]
    IMPL["/feature · /autopilot · /factory<br/>Implementation"]
    REV["/review or code-review (Anthropic)<br/>Review"]

    PRD --> ARCH
    PRD --> TDD
    PRD --> SEC
    PRD --> DESIGN
    ARCH --> ROAD
    TDD --> ROAD
    SEC --> ROAD
    ROAD --> SPEC
    SPEC --> IMPL
    DESIGN --> IMPL
    IMPL --> REV

    style PRD fill:#4a90d9,stroke:#2c5f8a,color:#fff
    style ARCH fill:#7b68ee,stroke:#5a4fcf,color:#fff
    style TDD fill:#7b68ee,stroke:#5a4fcf,color:#fff
    style SEC fill:#7b68ee,stroke:#5a4fcf,color:#fff
    style SPEC fill:#2ecc71,stroke:#27ae60,color:#fff
    style ROAD fill:#f39c12,stroke:#d68910,color:#fff
    style DESIGN fill:#9b59b6,stroke:#7d3c98,color:#fff
    style IMPL fill:#e74c3c,stroke:#c0392b,color:#fff
    style REV fill:#95a5a6,stroke:#7f8c8d,color:#fff
```

| Layer | Document | Purpose | Created by |
|-------|----------|---------|------------|
| **Why** | PRD | What we're building and why | `/prd` |
| **How (system)** | Architecture | System structure, components, data flow | `/architecture` |
| **How (process)** | TDD | Technical Design — testing, dev env, CI/CD, coding standards | `/tdd` |
| **How (security)** | Threat Model | Trust boundaries, attack surface, defenses | `/security` |
| **When** | Roadmap | Phased tasks from design docs, with dependencies and parallelism | `/roadmap` |
| **What (feature)** | Feature Spec | Detailed implementation spec per task in the roadmap | `/spec` |

The roadmap is generated from the design docs (PRD, architecture, TDD, threat model) — it breaks the project into phased tasks before detailed specs exist. Then each task gets a detailed feature spec (`/spec`) that references the architecture, technical design, and threat model. This means implementation agents have full context without needing everything repeated.

---

## The Interview Pattern

Every spec is created through a structured interview, not a one-shot prompt. The interview pattern ensures completeness:

```mermaid
sequenceDiagram
    participant U as Human
    participant C as Claude (/spec)
    participant D as Existing Docs

    C->>D: Read PRD, Architecture,<br/>TDD, Threat Model
    C->>D: Explore codebase<br/>(inherited projects)
    C->>U: Interview: Problem & scope
    U->>C: Answers
    C->>U: Interview: Technical design,<br/>edge cases, security
    U->>C: Answers
    C->>U: Interview: Verification criteria<br/>(concrete test cases)
    U->>C: Answers
    C->>C: Write spec to<br/>docs/specs/<feature>.md
    C->>U: Present for review
    U->>C: Feedback / approval
    C->>C: Update spec
```

The interview goes deep on the hard parts: edge cases, failure modes, security boundaries, and concrete verification criteria with inputs and expected outputs. The human decides *what*; Claude asks the questions that ensure nothing is missed.

---

## From Spec to Code: The Implementation Pipeline

Once specs exist, implementation follows a deterministic pipeline. This is where the cost of spec-writing pays off — every downstream step has clear inputs.

### Single Feature Flow

```mermaid
flowchart LR
    SPEC["Read Spec"] --> TEST_STRATEGY["Discover<br/>Test Strategy"]
    TEST_STRATEGY --> PLAN["Plan<br/>(if complex)"]
    PLAN --> IMPL["Implement<br/>+ Tests"]
    IMPL --> QUALITY["Lint<br/>Typecheck<br/>Tests"]
    QUALITY --> REVIEW["code-review skill<br/>(Anthropic)"]
    REVIEW --> FIX["Fix HIGH<br/>findings"]
    FIX --> COMMIT["Commit<br/>+ PR"]

    style SPEC fill:#2ecc71,stroke:#27ae60,color:#fff
    style REVIEW fill:#e74c3c,stroke:#c0392b,color:#fff
    style COMMIT fill:#4a90d9,stroke:#2c5f8a,color:#fff
```

### Automated Roadmap Execution (/autopilot)

For projects with multiple features, `/autopilot` orchestrates the entire roadmap:

```mermaid
flowchart TB
    ORCH["Orchestrator<br/>(reads roadmap, stays thin)"]

    subgraph Phase1["Phase 1"]
        T1["Worktree Agent<br/>Task 1"]
    end

    subgraph Phase2["Phase 2 (parallel tasks)"]
        T2A["Worktree Agent<br/>Task 2a"]
        T2B["Worktree Agent<br/>Task 2b"]
    end

    subgraph Phase3["Phase 3"]
        T3["Worktree Agent<br/>Task 3"]
    end

    ORCH --> Phase1
    Phase1 -->|"Checkpoint:<br/>review + merge PRs"| Phase2
    Phase2 -->|"Checkpoint:<br/>review + merge PRs"| Phase3

    T1 --> PR1["PR #1"]
    T2A --> PR2["PR #2"]
    T2B --> PR3["PR #3"]
    T3 --> PR4["PR #4"]

    style ORCH fill:#f39c12,stroke:#d68910,color:#fff
    style T1 fill:#4a90d9,stroke:#2c5f8a,color:#fff
    style T2A fill:#4a90d9,stroke:#2c5f8a,color:#fff
    style T2B fill:#4a90d9,stroke:#2c5f8a,color:#fff
    style T3 fill:#4a90d9,stroke:#2c5f8a,color:#fff
    style PR1 fill:#2ecc71,stroke:#27ae60,color:#fff
    style PR2 fill:#2ecc71,stroke:#27ae60,color:#fff
    style PR3 fill:#2ecc71,stroke:#27ae60,color:#fff
    style PR4 fill:#2ecc71,stroke:#27ae60,color:#fff
```

Each worktree agent independently:
1. Reads its assigned spec
2. Implements with tests at the right layers
3. Runs quality checks
4. Spawns security + architecture reviewers
5. Fixes HIGH severity findings
6. Commits, pushes, creates PR

The orchestrator never touches code — it only tracks progress and pauses between phases for human review.

---

## The Review Layer

Every implementation goes through a stack-aware review before merge. `/review`, `/feature`, `/fix`, and `/factory` all follow the same two-path pattern: prefer Anthropic's official `code-review` skill if installed, otherwise fall back to `/sec-review` plus the `architecture-reviewer` agent. In both paths, the matching language guide from `reviews/` (`go.md`, `rust.md`, `typescript.md`, `python.md`) is loaded — passed as stack criteria to Anthropic's skill, or to the fallback agents directly.

```mermaid
flowchart TB
    TRIGGER["/review · /feature · /fix · /factory"]
    DETECT["Detect stack →<br/>load matching<br/>reviews/*.md guide"]

    TRIGGER --> DETECT
    DETECT --> CHOICE{"Anthropic<br/>code-review skill<br/>installed?"}

    CHOICE -->|Yes — preferred| CR["Anthropic code-review skill<br/>(stack criteria passed in)"]
    CHOICE -->|No — fallback| FB["In-repo fallback<br/>(runs in parallel)"]

    FB --> SEC["/sec-review<br/>(Opus)"]
    FB --> ARCH["architecture-reviewer agent<br/>(Sonnet)"]

    CR --> REPORT["Consolidated findings<br/>PASS / REVIEW / FAIL"]
    SEC --> REPORT
    ARCH --> REPORT

    style TRIGGER fill:#f39c12,stroke:#d68910,color:#fff
    style DETECT fill:#95a5a6,stroke:#7f8c8d,color:#fff
    style CHOICE fill:#f5f5f5,stroke:#999,color:#333
    style CR fill:#2ecc71,stroke:#27ae60,color:#fff
    style FB fill:#9b59b6,stroke:#7d3c98,color:#fff
    style SEC fill:#e74c3c,stroke:#c0392b,color:#fff
    style ARCH fill:#4a90d9,stroke:#2c5f8a,color:#fff
    style REPORT fill:#2ecc71,stroke:#27ae60,color:#fff
```

> The previous in-repo `/code-review` skill fanned out to three nested subagents (security, architecture, stack) loading `reviews/` guides as sectioned prompts. It was deprecated after a benchmark (`code-review-workspace/iteration-1/`) showed no detection lift over a no-skill baseline at ~1.5× the cost, and its nested subagents didn't execute in parallel as designed.

---

## Model Strategy: Quality Where It Matters

Not every task requires the same level of reasoning. The workflow uses a tiered model strategy to optimize cost without sacrificing quality where it matters most:

```mermaid
flowchart LR
    subgraph OPUS["Opus (highest reasoning)"]
        direction TB
        O1["Design & Planning"]
        O2["Implementation"]
        O3["Security Review"]
        O4["Orchestration"]
    end

    subgraph SONNET["Sonnet (efficient execution)"]
        direction TB
        S1["Architecture Review"]
        S2["Stack-Specific Review"]
        S3["Worktree Agents<br/>(spec execution)"]
    end

    style OPUS fill:#e74c3c,stroke:#c0392b,color:#fff
    style SONNET fill:#4a90d9,stroke:#2c5f8a,color:#fff
```

| Task Type | Model | Why |
|-----------|-------|-----|
| Spec writing, interviews, design | **Opus** | Creative reasoning, catching edge cases |
| Implementation (main session) | **Opus** | Complex design decisions |
| Security review | **Opus** | False negatives are catastrophic |
| Orchestration (`/autopilot`) | **Opus** | Dependency logic, phase management |
| Architecture review | **Sonnet** | Structured criteria, checklist-driven |
| Stack-specific review | **Sonnet** | Matching against loaded review guides |
| Worktree agents (`/autopilot`) | **Sonnet** | Following detailed specs, not designing |

The principle: **Opus for decisions, Sonnet for execution.** Security is the exception — even though it follows structured criteria, the cost of missing a vulnerability far outweighs the savings from a cheaper model.

---

## Quality Gates: Defense in Depth

SDD doesn't rely on any single gate. Quality is enforced at every layer:

```mermaid
flowchart TB
    subgraph L1["Layer 1: Hooks (every edit)"]
        H1["Lint on file change"]
        H2["Typecheck on file change"]
    end

    subgraph L2["Layer 2: Pre-commit (every commit)"]
        PC1["Full test suite"]
        PC2["Security scan (gitleaks)"]
        PC3["Type checking"]
    end

    subgraph L3["Layer 3: Agent Review (per feature)"]
        AR1["Security reviewer (Opus)"]
        AR2["Architecture reviewer (Sonnet)"]
        AR3["Stack-specific reviewer (Sonnet)"]
    end

    subgraph L4["Layer 4: CI/CD (per PR)"]
        CI1["Full build"]
        CI2["All test layers"]
        CI3["SAST + dependency scan"]
    end

    subgraph L5["Layer 5: Human Review (per PR)"]
        HR1["Business logic correctness"]
        HR2["Design decisions"]
        HR3["What's missing?"]
    end

    L1 --> L2 --> L3 --> L4 --> L5

    style L1 fill:#2ecc71,stroke:#27ae60,color:#fff
    style L2 fill:#4a90d9,stroke:#2c5f8a,color:#fff
    style L3 fill:#f39c12,stroke:#d68910,color:#fff
    style L4 fill:#e74c3c,stroke:#c0392b,color:#fff
    style L5 fill:#7b68ee,stroke:#5a4fcf,color:#fff
```

---

## When to Use What

Not every project needs every step. Here's a decision guide:

| Scenario | What to use |
|----------|-------------|
| Quick fix or small feature on existing project | `/spec` + `/feature` |
| New feature touching multiple components | `/spec` + `/feature` (with Plan Mode) |
| Greenfield project | `/new-project` + `/prd` + `/architecture` + `/tdd` + `/security` + `/spec` + `/feature` |
| Full roadmap with many features | All of the above + `/roadmap` + `/autopilot` |
| Architectural decision | `/adr` |
| Significant change needing team input | `/rfc` |
| Bug fix | `/fix` (creates regression test, no spec needed) |
| Security audit | `/sec-review` (standalone, 4 parallel agents on Opus) |
| Code review | Anthropic's `code-review` skill (standalone) or `/review` (full PR review with spec compliance) |

---

## Key Principles

1. **Specs are contracts, not documentation.** They define what "done" means. Verification criteria are concrete test cases with inputs and expected outputs — not vague acceptance criteria.

2. **The human decides what; the AI decides how.** Specs capture decisions. Implementation agents have freedom in *how* they build, but not in *what* they build.

3. **Context flows down, never up.** Higher-level documents (PRD, architecture) inform lower-level ones (specs, roadmap). Implementation agents read the spec and its references — they don't need the full conversation history.

4. **Review is separate from writing.** The writer/reviewer pattern uses fresh sessions to avoid confirmation bias. The agent that wrote the code never reviews it.

5. **Security is non-negotiable.** Security review always runs on the highest-quality model. The cost of a missed vulnerability dwarfs any model cost savings.

6. **Parallel by default.** Worktrees, background agents, and phased roadmaps allow multiple streams of work without conflicts. The orchestrator stays thin — it tracks progress, not code.
