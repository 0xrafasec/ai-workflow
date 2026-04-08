# Workflow Toolkit Reference

> Quick reference for all global Claude Code agents, skills, settings, and conventions installed at `~/.claude/`.

---

## Table of Contents

1. [Overview](#overview)
2. [Global Agents](#global-agents)
3. [Language-Specific Review Guides](#language-specific-review-guides)
4. [Global Skills](#global-skills)
5. [Global Settings](#global-settings)
6. [Global CLAUDE.md](#global-claudemd)
7. [File Map](#file-map)
8. [Daily Usage](#daily-usage)

---

## Overview

This toolkit implements the workflow described in [WORKFLOW.md](./WORKFLOW.md). It provides:

- **Agents** — specialized reviewers that can be spawned as subagents
- **Skills** — reusable slash-command workflows (`/prd`, `/spec`, `/feature`, `/review`, `/autopilot`, `/new-project`)
- **Settings** — notification hooks for parallel work
- **CLAUDE.md** — global defaults applied to every project

Everything lives under `~/.claude/` and applies globally. Individual projects can override or extend by adding their own `.claude/` directory.

---

## Global Agents

Agents are spawned as subagents during implementation or review. They run in isolation and return a report.

### security-reviewer

**File:** `~/.claude/agents/security-reviewer.md`

**Purpose:** Reviews code for security vulnerabilities.

**What it checks:**
| Category | Examples |
|----------|----------|
| Injection | SQL, NoSQL, command injection, XXE, template injection, prototype pollution |
| Auth | Authentication bypass, privilege escalation, session management, JWT issues |
| Secrets | Hardcoded API keys, passwords, tokens in source code |
| Crypto | Weak algorithms, missing timing-safe comparisons |
| Data exposure | Sensitive data in logs, API leakage, debug info in production |
| Web | XSS via unsafe methods, SSRF (host/protocol control), open redirects |
| Config | CI/CD injection, insecure defaults, CORS misconfiguration |

**Filtering:**
- Only reports findings with confidence >= 8/10
- Only HIGH or MEDIUM severity
- Excludes noise: DoS, .env in .gitignore, test-only issues, regex DoS, client-side auth, outdated libs

**Output:** Numbered findings with file:line, severity, description, and before/after fix code. Ends with positive practices.

---

### architecture-reviewer

**File:** `~/.claude/agents/architecture-reviewer.md`

**Purpose:** Reviews code for architectural consistency and quality.

**What it checks:**
| Criteria | Description |
|----------|-------------|
| Pattern consistency | Does new code follow existing codebase patterns? |
| Separation of concerns | No god objects, no business logic in controllers |
| Unnecessary abstractions | Flags premature generalization and over-engineering |
| API contract stability | Do changes break existing contracts? |
| Dependency hygiene | Are new dependencies justified and maintained? |
| Error handling | Errors handled at the right layer? |
| Testability | Is code structured for easy testing? |

**Output:** Numbered concerns with file:line, severity (HIGH/MEDIUM/LOW), issue, suggestion. Ends with summary of what's good.

---

## Language-Specific Review Guides

Review guides provide language and framework-specific criteria that are loaded by the `/code-review` skill (and used by `/feature` and `/review`). They augment the base agents with stack-specific knowledge.

### Go (`reviews/go.md`)

**Security focus:** unchecked errors, goroutine leaks, race conditions, `os/exec` injection, `math/rand` misuse, missing HTTP timeouts, `unsafe` package, CGo, template injection.

**Architecture focus:** project structure (`cmd/`, `internal/`), interface design (accept interfaces/return structs, small interfaces), error patterns (sentinel errors, no panic in libraries), concurrency (channel ownership, context propagation, errgroup), testing (table-driven, `t.Helper()`).

### Rust (`reviews/rust.md`)

**Security focus:** `unsafe` blocks (justification required), FFI boundaries (null pointers, panic across FFI), `unwrap()` in library code, integer overflow, `serde` deserialization with untrusted input, `zeroize` for secrets, `cargo audit`.

**Architecture focus:** ownership patterns (excessive `.clone()`, `Rc`/`Arc` proliferation), type system (newtypes, typestate), error design (`thiserror` for libs, `anyhow` for apps), async patterns (blocking in async, cancellation safety, `Send` bounds), module structure (`pub` visibility, re-exports).

### TypeScript (`reviews/typescript.md`)

Covers **Node.js**, **Next.js**, and **Nest.js** with framework-specific sections for each.

**Security focus:** prototype pollution, `eval()`/`child_process.exec()`, JWT in localStorage, missing `sameSite` cookies. **Next.js:** server actions as public endpoints, RSC data leaks, env var exposure. **Nest.js:** missing guards, unvalidated DTOs, exposed internal errors.

**Architecture focus:** type safety (`any` usage, type assertions, Zod at boundaries), async patterns (missing `await`, sequential vs parallel), module design. **Next.js:** client/server boundary, data fetching strategy, route segment config. **Nest.js:** module boundaries, provider scope, dependency injection, repository pattern.

### Python (`reviews/python.md`)

Covers **FastAPI**, **Django**, **Flask**, and general Python.

**Security focus:** `eval()`/`exec()`, `pickle.loads()`, `yaml.load()`, f-string SQL, path traversal, `random` vs `secrets`. **Django:** `DEBUG=True`, `ALLOWED_HOSTS`, raw SQL, CSRF exemption. **FastAPI:** missing response models, WebSocket auth. **Flask:** debug mode, hardcoded secret key.

**Architecture focus:** type hints (`Any` usage, `# type: ignore`), error handling (bare `except`, silenced exceptions), async patterns (blocking in async). **Django:** fat models, manager methods, signals overuse. **FastAPI:** dependency injection, router organization, async all the way. **Testing:** pytest fixtures, factory pattern, mocking boundaries.

---

## Global Skills

Skills are invoked as slash commands. They orchestrate multi-step workflows.

### /prd

**File:** `~/.claude/skills/prd/SKILL.md`

**Purpose:** Interview the user and create a Product Requirements Document. This is the starting point for new projects or major features.

**Usage:**
```
/prd credential-delegation-protocol
/prd user-dashboard-redesign
```

**What it does:**
1. Checks for existing docs (won't duplicate what's already written)
2. Deep interviews you — problem, solution, scope, users, success criteria, constraints, risks
3. Writes to `docs/PRD.md` (or `docs/prd/<name>.md` for sub-feature PRDs)
4. Presents for review and iterates
5. Suggests next steps: which specs to create

**Document structure produced:**
- Problem statement
- Solution overview
- Design principles (non-negotiable properties)
- Scope (in/out with reasons)
- User types
- Key flows
- Success criteria
- Constraints (technical, business, regulatory)
- Risks and open questions
- Future work

---

### /spec

**File:** `~/.claude/skills/spec/SKILL.md`

**Purpose:** Create a specification document. Has three modes depending on the argument.

#### /spec architecture

Creates a system architecture document.

```
/spec architecture
```

**Interview focus:** Components, data flow, technology choices, deployment model, scaling, integration points, key decisions and tradeoffs.

**Writes to:** `docs/specs/ARCHITECTURE.md`

**Document structure:**
- System overview (with Mermaid diagram)
- Components (responsibility, technology, interfaces, design decisions)
- Data flow (with diagrams for critical paths)
- Technology stack table with rationale
- Deployment model
- Key decisions table (decision, choice, alternatives, rationale)
- Constraints and limitations

---

#### /spec security

Creates a threat model and security specification.

```
/spec security
```

**Interview focus:** Trust boundaries, auth/authz, sensitive data inventory, attack surface, threat actors, compliance requirements, existing security measures.

**Writes to:** `docs/specs/THREAT_MODEL.md`

**Document structure:**
- Trust assumptions (with Mermaid trust hierarchy)
- Security properties (non-negotiable invariants)
- Attack surface table
- Threats by category (attack, impact, likelihood, defense)
- Sensitive data inventory (classification, protection at rest/transit, access control)
- Security controls (implemented vs required)
- Compliance requirements

---

#### /spec \<feature-name\>

Creates an implementation spec for a specific feature. This is the most common mode.

```
/spec user-authentication
/spec payment-processing
/spec webhook-system
```

**Interview focus:** Exact API changes, data model changes, edge cases, security considerations, verification criteria (concrete test cases with inputs and outputs).

**Writes to:** `docs/specs/<feature_name>.md`

**Document structure:**
- Problem
- Solution
- Technical design (API changes, data model, architecture)
- Security considerations
- Verification criteria (checkboxes with input -> expected output)
- Out of scope

---

#### Context awareness (all modes)

Before interviewing, `/spec` reads what already exists:
- Existing PRD, specs, README, CLAUDE.md
- **For inherited projects with no docs:** explores the codebase — directory structure, entry points, config files, `git log`, dependencies — then tells you "here's what I understand so far" before starting questions

After writing, it suggests the next logical step:
- No architecture spec? -> "Consider `/spec architecture`"
- Security concerns but no threat model? -> "Consider `/spec security`"
- Specs done? -> "Ready for `/roadmap` or `/feature`"

---

### /feature

**File:** `~/.claude/skills/feature/SKILL.md`

**Purpose:** Implement a feature end-to-end from a spec file.

**Usage:**
```
/feature docs/specs/auth.md                    # implement + commit (no PR)
/feature docs/specs/auth.md --pr               # implement + commit + push + PR to default branch
/feature docs/specs/auth.md --pr develop       # same, but PR targets 'develop'
```

**Default is commit only, no PR.** You control when to ship. The source branch is always your current branch/worktree — `--pr` only controls the **target base branch** for the PR.

**What it does:**
1. Reads the spec thoroughly
2. Checks for a matching roadmap task in `docs/roadmap/`
3. Plans the implementation (enters Plan Mode if complex)
4. Implements the feature with tests covering all verification criteria
5. Runs lint, typecheck, and tests
6. Runs **`/sec-review`** — the full 4-agent parallel security audit (not just the lighter security-reviewer agent)
7. Spawns **architecture-reviewer** subagent
8. Fixes HIGH severity findings from both reviews
9. Commits with conventional commit messages, split by logical concern
10. **If `--pr`:** pushes and creates a PR with summary, spec link, security verdict, architecture summary, and test plan
11. **If no `--pr`:** stops and tells you the feature is ready to ship when you are

---

### /review

**File:** `~/.claude/skills/review/SKILL.md`

**Purpose:** Review a branch or PR using the writer/reviewer pattern.

**Usage:**
```
/review                    # review current branch vs main
/review feature-auth       # review a specific branch
/review 42                 # review PR #42
```

**What it does:**
1. Gathers the diff and commit history
2. Finds the relevant spec in `docs/specs/`
3. Spawns **security-reviewer** and **architecture-reviewer** subagents in parallel
4. Reviews business logic, design decisions, missing cases, test coverage, and spec compliance
5. Produces a consolidated report with verdict: APPROVE, REQUEST_CHANGES, or COMMENT

**Important:** This is a read-only review. It flags issues with line references — it does not rewrite the implementation. Best used in a **fresh session** (not the one that wrote the code).

---

### /new-project

**File:** `~/.claude/skills/new-project/SKILL.md`

**Purpose:** Scaffold a new project with the full workflow structure.

**Usage:**
```
/new-project my-api python/fastapi
/new-project my-cli go
/new-project my-app typescript/nextjs
/new-project my-service            # will ask what stack to use
```

**Arguments:**
- `<project-name>` (required) — the directory name to create
- `[language/framework]` (optional) — the tech stack, used to tailor Makefile, linter, .gitignore, pre-commit hooks to that ecosystem. Examples: `python`, `python/fastapi`, `go`, `rust`, `typescript/nextjs`. If omitted, you'll be asked.

**Where it creates the project:** In your **current working directory** (`$PWD/<project-name>/`). Navigate to the desired parent directory first if needed.

**What it creates:**

```
<project-name>/
  CLAUDE.md                          # Project-specific Claude instructions
  Makefile                           # test, lint, typecheck, build, security-scan targets
  .gitignore                         # Language-appropriate + .claude/ + .env
  .pre-commit-config.yaml            # Linter + type checker + tests + gitleaks
  .claude/
    settings.json                    # Hooks (lint on edit)
    agents/
      security-reviewer.md           # Tailored to project language
      architecture-reviewer.md       # Tailored to project language
    skills/
      feature/
        SKILL.md                     # Feature implementation workflow
      spec/
        SKILL.md                     # Spec creation workflow
  docs/
    specs/                           # Feature specifications go here
    roadmap/                         # Phase/task breakdowns go here
```

**After scaffolding, the suggested next steps are:**
1. `cd <project-name>`
2. `pre-commit install`
3. `/prd <project-name>` — write the product requirements
4. `/spec architecture` — define the system architecture
5. `/spec security` — define the threat model (if applicable)
6. `/spec <first-feature>` — write your first feature spec
7. `/feature docs/specs/<first-feature>.md` — implement it

---

### /autopilot

**File:** `~/.claude/skills/autopilot/SKILL.md`

**Purpose:** Execute an entire roadmap automatically. Dispatches worktree subagents for each task, runs phases in order, parallelizes where possible, and pauses between phases for human review.

**Usage:**
```
/autopilot docs/roadmap.md
/autopilot ROADMAP.md
```

**How it works:**

```
Orchestrator (you — stays thin, only tracks progress)
  |
  Phase 1:
  |  ├── Worktree Agent: task-1 (reads spec, implements, reviews, creates PR)
  |  └── [waits for completion]
  |  → CHECKPOINT: "Review and merge PR, then say 'continue'"
  |
  Phase 2:
  |  ├── Worktree Agent: task-2a (parallel) ──→ PR
  |  ├── Worktree Agent: task-2b (parallel) ──→ PR
  |  └── Worktree Agent: task-2c (sequential, depends on 2a) ──→ PR
  |  → CHECKPOINT: "3 PRs ready. Review, merge, continue?"
  |
  Phase 3: ...
```

**Each worktree subagent independently:**
1. Reads the spec file for its task
2. Implements with tests
3. Runs lint, typecheck, tests
4. Spawns security-reviewer and architecture-reviewer subagents
5. Fixes HIGH severity findings
6. Commits, pushes, creates PR

**Checkpoint commands:**
- `continue` — proceed to next phase
- `retry <task>` — re-run a failed task
- `skip <task>` — skip a task and continue
- `stop` — halt and summarize progress

**Why context isn't lost:** The orchestrator never reads implementation files. Each subagent gets its own context window with only its task's spec. The orchestrator only tracks: task name, status, PR URL, blockers.

**Requirements for the roadmap:**
- Phases in dependency order
- Each task needs: spec path, files to modify, dependencies, verification command
- Parallel tasks must touch different files

---

### /code-review

**File:** `~/.claude/skills/code-review/SKILL.md`

**Purpose:** Stack-aware code review that auto-detects the project's language/framework and runs security + architecture + idiomatic pattern checks with language-specific best practices.

**Usage:**
```
/code-review                 # diff current branch vs main
/code-review diff develop    # diff vs specific branch
/code-review full            # full codebase scan
/code-review full src/       # full scan scoped to a directory
```

**What it does:**
1. Auto-detects the stack by checking marker files (`go.mod`, `Cargo.toml`, `package.json`, `pyproject.toml`, etc.)
2. Loads the corresponding review guides from `reviews/`
3. Spawns 3 parallel agents:
   - **Security** — base security-reviewer + language-specific security criteria
   - **Architecture** — base architecture-reviewer + language-specific architecture patterns
   - **Stack-specific** — idiomatic patterns, common pitfalls, performance antipatterns, testing conventions
4. Deduplicates and consolidates into a single report with verdict (PASS/REVIEW/FAIL)

**Supported stacks:** Go, Rust, TypeScript (Node.js, Next.js, Nest.js), Python (FastAPI, Django, Flask). Polyglot projects load multiple guides.

**Integration:** Used automatically by `/feature` (step 6) and `/review` (step 4). Can also be run standalone.

---

### /sec-review

**File:** `~/.claude/commands/sec-review.md`

**Purpose:** Detailed security audit with parallel analysis agents. More thorough than the security-reviewer agent — this is a full audit tool.

**Usage:**
```
/sec-review                # diff mode vs main
/sec-review full           # full codebase scan
/sec-review diff develop   # diff vs specific branch
/sec-review full src/      # full scan scoped to a directory
```

**What it does:**
1. Spawns 4 parallel agents: injection, auth/crypto, data exposure/web, config/supply chain
2. Each agent reads every file, traces data flow, assigns confidence scores
3. Consolidates findings, deduplicates, filters by confidence >= 8
4. Produces a structured report with verdict (PASS/REVIEW/FAIL) and positive practices

---

## Global Settings

**File:** `~/.claude/settings.json`

### Notification Hooks

Desktop notifications fire whenever Claude needs your attention. Essential for parallel worktree sessions where you're not watching every terminal.

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' '$CLAUDE_NOTIFICATION'"
          }
        ]
      }
    ]
  }
}
```

Uses `notify-send` (Linux/Freedesktop). Fires on any notification event from Claude.

### Other Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| `defaultMode` | `bypassPermissions` | No permission prompts |
| `model` | `opus` | Default to Opus model |
| `statusLine` | custom command | Custom status line script |

---

## Global CLAUDE.md

**File:** `~/.claude/CLAUDE.md`

These defaults apply to **every project** unless overridden by a project-level CLAUDE.md.

**Key rules:**
- Spec first, code second
- Conventional commits: `feat:`, `fix:`, `refactor:`, `chore:`, `test:`, `docs:`, `security:`
- Split commits by logical concern
- `/sec-review` before PR on security-sensitive changes
- Writer/reviewer pattern: never review in the same session that wrote the code
- No unnecessary abstractions
- Validate at system boundaries only
- Tests must cover spec verification criteria
- PRs: one concern, under 200 lines, with summary + spec link + security checklist + test plan
- `/clear` between tasks, `/compact` mid-task, `/rewind` after 2 failed corrections

---

## File Map

```
~/.claude/
  CLAUDE.md                              # Global defaults for all projects
  settings.json                          # Notification hooks, permissions, model
  statusline-command.sh                  # Custom status line script
  agents/
    security-reviewer.md                 # Security review subagent
    architecture-reviewer.md             # Architecture review subagent
  commands/
    sec-review.md                        # /sec-review — detailed security audit
  reviews/
    go.md                                # Go-specific review criteria
    rust.md                              # Rust-specific review criteria
    typescript.md                        # TypeScript/Node/Next/Nest review criteria
    python.md                            # Python/Django/FastAPI/Flask review criteria
  skills/
    prd/
      SKILL.md                           # /prd — product requirements document
    spec/
      SKILL.md                           # /spec — architecture, security, or feature spec
    feature/
      SKILL.md                           # /feature — implement from spec
    review/
      SKILL.md                           # /review — PR/branch review
    code-review/
      SKILL.md                           # /code-review — stack-aware code review
    autopilot/
      SKILL.md                           # /autopilot — execute roadmap automatically
    new-project/
      SKILL.md                           # /new-project — scaffold a project
```

---

## Daily Usage

### New project from scratch
```
cd ~/Projects
/new-project my-app python/fastapi     # Scaffold structure
cd my-app
/prd my-app                            # Define what we're building
/spec architecture                     # Define how it's structured
/spec security                         # Define the threat model
/spec user-authentication              # First feature spec
/feature docs/specs/user-authentication.md  # Implement it
```

### Joining an inherited project
```
cd ~/Projects/existing-app
/spec architecture                     # It reads the codebase first, then interviews you
/spec security                         # Same — explores before asking
/spec new-feature                      # Feature spec, building on what exists
```

### Automated full roadmap execution
```
/autopilot ROADMAP.md                  # Executes phase by phase
# → Phase 1: dispatches agents, waits, shows PRs
# → "continue" to proceed to Phase 2
# → "retry task-name" if something failed
# → "stop" to halt
```

### Parallel work with worktrees (manual)
```bash
claude --worktree task-a --tmux        # Terminal 1
claude --worktree task-b --tmux        # Terminal 2
# Desktop notifications tell you when each needs attention
```

### Reviewing work
```
# In a FRESH session (not the one that wrote the code):
/review                                 # Review current branch
/review feature-auth                    # Review specific branch
```

### Security audit
```
/sec-review                             # Diff mode vs main
/sec-review full                        # Full codebase scan
/sec-review diff develop                # Diff vs specific branch
```

### Context management
```
/clear                                  # Between unrelated tasks
/compact                                # When context gets heavy
/rewind                                 # When an approach keeps failing
```

---

## Document Pipeline

The typical flow from idea to code:

```
/prd                    "What are we building and why?"
  |
  v
/spec architecture      "How is the system structured?"
/spec security          "What are the threats and defenses?"
  |
  v
/spec <feature>         "Exact implementation details for this feature"
  |                     (one per feature, references architecture + security)
  v
 ROADMAP.md             "Phase breakdown with tasks, deps, parallelism"
  |
  +--→ /autopilot       "Execute the whole roadmap automatically"
  |      (dispatches worktree agents, pauses between phases)
  |
  +--→ /feature <spec>  "Or implement one feature at a time manually"
       |
       v
     /review             "Independent review in a fresh session"
```

Not every project needs every step. A small feature on an existing project might just need `/spec <feature>` and `/feature`. A greenfield project with a full roadmap can use `/autopilot` to execute it all.
