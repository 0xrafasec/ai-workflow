<p align="center">
  <h1 align="center">ai-workflow</h1>
  <p align="center">
    Full SDLC (Software Development Life Cycle) for <a href="https://docs.anthropic.com/en/docs/claude-code">Claude Code</a> — from idea to production.<br/>
    Built on SDD (Spec-Driven Development): specs are the source of truth, AI agents execute them.<br/>
    Skills, agents, review guides, and conventions — installed globally, applied everywhere.
  </p>
</p>

<p align="center">
  <a href="https://github.com/0xrafasec/ai-workflow/blob/main/LICENSE"><img src="https://img.shields.io/github/license/0xrafasec/ai-workflow?style=flat-square" alt="License"></a>
  <a href="https://github.com/0xrafasec/ai-workflow/issues"><img src="https://img.shields.io/github/issues/0xrafasec/ai-workflow?style=flat-square" alt="Issues"></a>
  <a href="https://github.com/0xrafasec/ai-workflow/stargazers"><img src="https://img.shields.io/github/stars/0xrafasec/ai-workflow?style=flat-square" alt="Stars"></a>
</p>

---

## What is this?

ai-workflow covers the entire software development lifecycle inside Claude Code — from the initial idea through design, implementation, review, and delivery. It installs as a set of global [skills](https://docs.anthropic.com/en/docs/claude-code/skills), [agents](https://docs.anthropic.com/en/docs/claude-code/sub-agents), and conventions that symlink into `~/.claude/` and apply to every project you work on.

Each phase of development has dedicated tooling:

- **Discovery** — interview-driven requirements gathering (`/prd`)
- **Design** — architecture, technical design, and threat modeling (`/architecture`, `/tdd`, `/security`)
- **Specification** — detailed feature specs with verification criteria (`/spec`)
- **Planning** — phased roadmaps with dependency tracking (`/roadmap`)
- **Implementation** — parallel execution across isolated worktrees (`/feature`, `/autopilot`)
- **Review** — independent, language-aware review with specialized agents (`/review`, `/code-review`, `/sec-review`)
- **Governance** — decision records and change proposals at any point (`/adr`, `/rfc`)

## Features

- **15 slash-command skills** covering every phase from idea to merged PR
- **Specialized review agents** — architecture and security reviewers spawned as subagents
- **Language-aware code review** — auto-detects Go, Rust, TypeScript, or Python and loads stack-specific best practices
- **Parallel execution** — worktree-based development with `/autopilot` for full roadmap execution
- **Writer/reviewer separation** — never review code in the same session that wrote it
- **Notification hooks** — desktop notifications when Claude needs attention
- **Custom status line** — model, context usage, cost, git branch at a glance
- **Composable with other tools** — works alongside [GitHub Spec Kit](https://github.com/github/spec-kit) and other SDD toolkits ([integration guide](docs/speckit-integration.md))

## Development Lifecycle

The toolkit implements a layered document pipeline where each phase builds on the ones above it. Humans decide *what* to build through structured interviews and specs; AI agents decide *how* to build it by following those specs with full context.

```
Idea → PRD (why) → Architecture + TDD + Security (how) → Specs (what) → Roadmap (when) → Implementation → Review → Ship
```

A feature spec references the architecture, technical design, and threat model — so implementation agents have complete context without repetition.

For a detailed explanation with diagrams, see [docs/spec-driven-development.md](docs/spec-driven-development.md).

### Model Strategy

The workflow uses a tiered model strategy — Opus for decisions, Sonnet for execution:

| Task | Model | Reasoning |
|------|-------|-----------|
| Spec writing, design, interviews | **Opus** | Creative reasoning, edge case discovery |
| Implementation (main session) | **Opus** | Complex design decisions |
| Security review | **Opus** | False negatives are catastrophic |
| Orchestration (`/autopilot`) | **Opus** | Dependency logic, phase management |
| Architecture review | **Sonnet** | Structured criteria, checklist-driven |
| Stack-specific review | **Sonnet** | Pattern matching against review guides |
| Worktree agents (`/autopilot`) | **Sonnet** | Following detailed specs, not designing |

## Quick Start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- `jq` (for the status line script)
- `notify-send` (Linux) or equivalent (for desktop notifications)

### Install

```bash
git clone https://github.com/0xrafasec/ai-workflow.git
cd ai-workflow
./install.sh
```

This symlinks everything into `~/.claude/`. Your existing config is backed up automatically.

### Uninstall

```bash
./uninstall.sh
```

Removes symlinks and restores any previous backups.

### Selective Install

```bash
# Install only specific files
./install.sh settings.json
./install.sh skills/feature/SKILL.md CLAUDE.md
```

The filter matches on path, destination, or basename.

## Skills

Skills are multi-step workflows invoked as slash commands inside Claude Code.

### Planning

| Skill | Description |
|-------|-------------|
| `/prd` | Interview-driven Product Requirements Document |
| `/architecture` | System architecture document |
| `/tdd` | Technical Design Document (testing, dev env, CI/CD, coding standards) |
| `/adr <title>` | Architecture Decision Record |
| `/rfc <title>` | Request for Comments |

### Implementation

| Skill | Description |
|-------|-------------|
| `/spec <feature>` | Feature implementation spec with verification criteria |
| `/roadmap` | Phased task breakdown from specs |
| `/feature <spec>` | End-to-end feature implementation from a spec |
| `/autopilot` | Execute a full roadmap with parallel worktree agents |
| `/new-project <name>` | Scaffold a new project with the full workflow |

### Review

| Skill | Description |
|-------|-------------|
| `/review` | PR/branch review using the writer/reviewer pattern |
| `/code-review` | Stack-aware review with language-specific best practices |
| `/sec-review` | Full security audit with parallel analysis agents |

## Agents

Agents are specialized reviewers spawned as subagents during implementation or review.

| Agent | What it reviews |
|-------|-----------------|
| `architecture-reviewer` | Pattern consistency, separation of concerns, API stability, dependency hygiene |
| `security-reviewer` | Injection flaws, auth issues, secrets in code, crypto weaknesses, data exposure |

## Language-Specific Review Guides

`/code-review` auto-detects your stack and loads the matching guide. Polyglot projects load multiple guides.

| Guide | Covers |
|-------|--------|
| Go | Error handling, concurrency, injection, interface design, project layout |
| Rust | Unsafe audit, FFI, ownership, async patterns, error design, type system |
| TypeScript | Node.js, Next.js, Nest.js — prototype pollution, SSR, DI, async patterns |
| Python | Django, FastAPI, Flask — injection, path traversal, async, ORM patterns |

## How It Works

### The Document Pipeline

The typical flow from idea to shipped code:

```
/prd                       Define what to build and why
  │
/architecture              System structure
/tdd                       Technical design (testing, dev env, CI/CD, standards)
  │
/spec <feature>            Implementation details per feature
  │
/roadmap                   Phase breakdown with dependencies
  │
  ├── /autopilot           Execute the roadmap automatically
  │
  └── /feature <spec>      Or implement one feature at a time
        │
      /review              Independent review in a fresh session
```

`/adr` and `/rfc` can be used at any point to capture decisions or propose changes.

### Parallel Development

Each task runs in its own [git worktree](https://git-scm.com/docs/git-worktree), isolated from other work:

```bash
claude --worktree feature-auth
claude --worktree feature-dashboard
```

`/autopilot` takes this further — it reads a roadmap and dispatches parallel worktree agents for independent tasks, then sequences dependent ones.

### Quality Gates

```
Hooks          →  Lint and format on every edit
Pre-commit     →  Tests, type checks on every commit
Subagent review →  Security + architecture review before PR
CI/CD          →  Full build, SAST, dependency scan
Human review   →  Business logic, design decisions, edge cases
```

## Project Structure

```
ai-workflow/
├── CLAUDE.md                  # Global conventions (symlinked to ~/.claude/)
├── settings.json              # Hooks, permissions, model config
├── statusline-command.sh      # Custom status line script
├── install.sh                 # Symlink installer
├── uninstall.sh               # Clean uninstaller
├── agents/
│   ├── architecture-reviewer.md
│   └── security-reviewer.md
├── commands/
│   └── sec-review.md
├── reviews/
│   ├── go.md
│   ├── rust.md
│   ├── typescript.md
│   └── python.md
├── skills/
│   ├── prd/
│   ├── architecture/
│   ├── tdd/
│   ├── adr/
│   ├── rfc/
│   ├── spec/
│   ├── roadmap/
│   ├── feature/
│   ├── fix/
│   ├── review/
│   ├── code-review/
│   ├── autopilot/
│   ├── new-project/
│   └── security/
├── WORKFLOW.md                # Full workflow documentation
└── REFERENCE.md               # Quick reference for all components
```

## Configuration

### Global Conventions (`CLAUDE.md`)

Installed at `~/.claude/CLAUDE.md`, these conventions apply to every Claude Code session:

- Conventional commits (`feat:`, `fix:`, `refactor:`, etc.)
- Spec-first development
- Writer/reviewer separation
- PRs under 200 lines, one concern each

### Settings (`settings.json`)

Desktop notification hooks, permission mode, and model preference. See `settings.json` for the current config.

### Status Line

The bundled `statusline-command.sh` shows model name, context usage percentage, estimated session cost, pending tasks, and git branch — directly in Claude Code's status bar.

## Documentation

| Document | Description |
|----------|-------------|
| [Spec-Driven Development](docs/spec-driven-development.md) | Detailed explanation of the SDD methodology with Mermaid diagrams |
| [Spec Kit Integration](docs/speckit-integration.md) | How to combine ai-workflow with GitHub Spec Kit |
| [WORKFLOW.md](WORKFLOW.md) | Full workflow guide — phases, conventions, CI/CD integration, team practices |
| [REFERENCE.md](REFERENCE.md) | Quick reference for all agents, skills, settings, and daily patterns |

## Modifying the Toolkit

All config is symlinked from this repo into `~/.claude/`. **Never edit files directly in `~/.claude/`** — changes will be lost or cause symlink conflicts.

To modify anything:

1. Edit the source file in this repo
2. Commit and push
3. Run `./install.sh` if you added new files

Changes to existing symlinked files take effect immediately — no reinstall needed.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## Security

See [SECURITY.md](SECURITY.md) for our vulnerability disclosure policy.

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE) — 0xrafasec
