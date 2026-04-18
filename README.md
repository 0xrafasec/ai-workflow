<p align="center">
  <h1 align="center">ai-workflow</h1>
  <p align="center">
    Full SDLC (Software Development Life Cycle) for AI-assisted coding — from idea to production.<br/>
    Built on SDD (Spec-Driven Development): specs are the source of truth, AI agents execute them.<br/>
    Skills, agents, review guides, and conventions — installed globally, applied everywhere.<br/><br/>
    Works with <a href="https://docs.anthropic.com/en/docs/claude-code">Claude Code</a>, <a href="https://www.cursor.com/">Cursor</a>, and <a href="https://openai.com/codex">OpenAI Codex CLI</a>.
  </p>
</p>

<p align="center">
  <a href="https://github.com/0xrafasec/ai-workflow/blob/main/LICENSE"><img src="https://img.shields.io/github/license/0xrafasec/ai-workflow?style=flat-square" alt="License"></a>
  <a href="https://github.com/0xrafasec/ai-workflow/issues"><img src="https://img.shields.io/github/issues/0xrafasec/ai-workflow?style=flat-square" alt="Issues"></a>
  <a href="https://github.com/0xrafasec/ai-workflow/stargazers"><img src="https://img.shields.io/github/stars/0xrafasec/ai-workflow?style=flat-square" alt="Stars"></a>
</p>

---

## What is this?

ai-workflow covers the entire software development lifecycle for AI-assisted coding — from the initial idea through design, implementation, review, and delivery. It installs as a set of global skills, agents, and conventions that apply to every project you work on.

Each phase of development has dedicated tooling:

- **Discovery** — interview-driven requirements gathering (`/prd`)
- **Design** — architecture, technical design, and threat modeling (`/architecture`, `/tdd`, `/security`)
- **Specification** — detailed feature specs with verification criteria (`/spec`)
- **Planning** — phased roadmaps with dependency tracking (`/roadmap`)
- **Implementation** — parallel execution across isolated worktrees (`/feature`, `/autopilot`)
- **Review** — independent, language-aware review with specialized agents (`/review`, `/sec-review`; for stack-aware code review, use Anthropic's official `code-review` skill from `claude-code-plugins`)
- **Governance** — decision records and change proposals at any point (`/adr`, `/rfc`)

## Features

- **18 slash-command skills** covering every phase from idea to merged PR
- **Multi-platform** — native support for Claude Code, Cursor, and OpenAI Codex CLI
- **Specialized review agents** — architecture and security reviewers spawned as subagents
- **Language-aware code review** — auto-detects Go, Rust, TypeScript, or Python and loads stack-specific best practices
- **Parallel execution** — worktree-based development with `/autopilot` for full roadmap execution
- **Writer/reviewer separation** — never review code in the same session that wrote it
- **Notification hooks** — desktop notifications when Claude needs attention (Claude Code)
- **Custom status line** — model, context usage, cost, git branch at a glance (Claude Code)
- **Composable with other tools** — works alongside [GitHub Spec Kit](https://github.com/github/spec-kit) and other SDD toolkits ([integration guide](docs/speckit-integration.md))

## Platform Support

| Platform | How it installs | How skills are invoked |
|----------|----------------|------------------------|
| **Claude Code** | Symlinks into `~/.claude/` — skills, agents, CLAUDE.md, settings | `/skill-name` slash commands |
| **Cursor** | Generates `~/.cursor/rules/aiwf-*.mdc` — one MDC rule per skill | Reference by name: `"follow the /spec workflow for X"` |
| **Codex CLI** | Symlinks each skill into `~/.agents/skills/aiwf-*/` (native Codex skills) + writes `~/.codex/AGENTS.md` with global conventions | `$skill-name` at the prompt (e.g. `$spec`, `$roadmap`) or describe the task and Codex matches by description |

The bootstrap script auto-detects which tools are installed and sets up all of them. You can also install for each platform independently.

## Development Lifecycle

The toolkit implements a layered document pipeline where each phase builds on the ones above it. Humans decide *what* to build through structured interviews and specs; AI agents decide *how* to build it by following those specs with full context.

```
Idea → PRD (why) → Architecture + TDD + Security (how) → Roadmap (when) → Specs (what, per task) → Implementation → Review → Ship
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

- At least one of: [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Cursor](https://www.cursor.com/), or [Codex CLI](https://openai.com/codex)
- `git`, `bash`
- Claude Code extras: `jq` (status line), `notify-send` or equivalent (desktop notifications)

### Install (recommended — one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/0xrafasec/ai-workflow/main/bootstrap.sh | bash
```

This clones the repo into `~/.local/share/ai-workflow`, installs for all detected platforms, and puts `aiwf` in `~/.local/bin`. Pin to a specific release with `AIWF_REF=v0.1.0 bash`.

**Auto-detection:** bootstrap installs for Claude Code always, then checks for Cursor (`~/.cursor` or `cursor` binary) and Codex CLI (`~/.codex` or `codex` binary) and installs those too.

Prefer to read the script before running it? [bootstrap.sh](bootstrap.sh) is short and auditable — the whole toolkit is bash + markdown by design.

### Install from a git clone (no curl)

```bash
git clone https://github.com/0xrafasec/ai-workflow.git
cd ai-workflow
./install.sh          # Claude Code + install the aiwf launcher in ~/.local/bin
aiwf install-cursor   # add Cursor
aiwf install-codex    # add Codex CLI
# or all at once:
aiwf install-all
```

### Per-platform install

```bash
aiwf install           # Claude Code — symlinks into ~/.claude/
aiwf install-cursor    # Cursor — generates ~/.cursor/rules/aiwf-*.mdc
aiwf install-codex     # Codex CLI — symlinks skills into ~/.agents/skills/ + writes ~/.codex/AGENTS.md
aiwf install-all       # all three at once
```

### Manage the install

Once `aiwf` is on your PATH:

```bash
aiwf status            # install dir, version, and per-platform health
aiwf update            # git pull + re-link Claude (refuses dirty trees; --force stashes)
aiwf reinstall         # repair broken Claude symlinks
aiwf uninstall         # remove Claude symlinks (--purge deletes the clone too)
aiwf uninstall-cursor  # remove Cursor rules
aiwf uninstall-codex   # remove Codex instructions
aiwf uninstall-all     # remove from all platforms
aiwf version           # git describe
aiwf help              # all commands
```

**Keeping Cursor/Codex in sync with updates:**

```bash
aiwf update            # pull latest from git
aiwf install-cursor    # regenerate Cursor rules
aiwf install-codex     # recompile Codex instructions
# or just:
aiwf update && aiwf install-all
```

**Update conflict handling.** `aiwf update` fast-forwards `main` by default and refuses to proceed if the working tree is dirty or your local branch is ahead of `origin/main`. Both suggest you've edited the clone directly — which is supported. Resolve by committing/pushing, or use `--force` to auto-stash and hard-reset.

### Selective Claude install

```bash
# Install only specific files into ~/.claude/
./install.sh settings.json
./install.sh skills/feature/SKILL.md CLAUDE.md
# or: aiwf install settings.json
```

The filter matches on path, destination, or basename.

### Uninstall

```bash
aiwf uninstall-all        # remove from all platforms
aiwf uninstall --purge    # remove from Claude + delete the clone
```

## Skills

Skills are multi-step workflows invoked as slash commands inside Claude Code.

### Planning

| Skill | Description |
|-------|-------------|
| `/prd` | Interview-driven Product Requirements Document |
| `/architecture` | System architecture document |
| `/tdd` | Technical Design Document (testing, dev env, CI/CD, coding standards) |
| `/security` | STRIDE-style threat model (`docs/THREAT_MODEL.md`) |
| `/adr <title>` | Architecture Decision Record |
| `/rfc <title>` | Request for Comments |

### Design

| Skill | Description |
|-------|-------------|
| `/design` | Produce distinctive, production-grade UI designs in Paper.design MCP |
| `/verify-design` | Diff the running UI against Paper design refs with Playwright and fix mismatches |

### Implementation

| Skill | Description |
|-------|-------------|
| `/spec <feature>` | Feature implementation spec with verification criteria |
| `/roadmap` | Phased task breakdown from specs |
| `/feature <spec>` | End-to-end feature implementation from a spec |
| `/fix <issue>` | Diagnose and fix a bug from a description, stack trace, or GitHub issue |
| `/autopilot` | Execute a full roadmap with parallel worktree agents |
| `/factory` | End-to-end delivery pipeline — reads roadmap, generates specs, runs parallel `/feature` agents |
| `/new-project <name>` | Scaffold a new project with the full workflow |

### Review

| Skill | Description |
|-------|-------------|
| `/review` | PR/branch review using the writer/reviewer pattern |
| `/sec-review` | Full security audit with parallel analysis agents |

> **Stack-aware code review:** use Anthropic's official `code-review` skill from [`claude-code-plugins`](https://github.com/anthropics/claude-code). The previous in-repo `/code-review` skill was deprecated after a benchmark (see `code-review-workspace/iteration-1/`) showed no detection lift over baseline at ~1.5× the cost. Language-specific guides in `reviews/` are still loaded on demand by `/review`, `/feature`, and `/fix`.

### Delivery

| Skill | Description |
|-------|-------------|
| `/commit` | Stage and commit the working tree as one or more logical conventional commits (local-only, never pushes) |
| `/pr [--draft]` | Open a pull request for the current branch — analyzes all commits in the range, drafts title + body, pushes if needed. `--draft` opens as a draft PR. |

## Agents

Agents are specialized reviewers spawned as subagents during implementation or review.

| Agent | What it reviews |
|-------|-----------------|
| `architecture-reviewer` | Pattern consistency, separation of concerns, API stability, dependency hygiene |
| `security-reviewer` | Injection flaws, auth issues, secrets in code, crypto weaknesses, data exposure |

## Language-Specific Review Guides

`/review`, `/feature`, and `/fix` load the matching guide on demand (and you can pass them to Anthropic's `code-review` skill as stack criteria). Polyglot projects load multiple guides.

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
/security                  Threat model
  │
/roadmap                   Phase breakdown from design docs
  │
/spec <feature>            Detail each task in the roadmap
  │
  │   /design [flow]       UI designs in Paper (for UI features)
  │   /verify-design       Diff running UI against Paper refs, fix in place
  │
  ├── /autopilot           Execute the roadmap automatically
  ├── /factory             End-to-end: gen specs, parallel worktree agents, PRs
  └── /feature <spec>      Or implement one feature at a time
        │
      /review              Independent review in a fresh session
```

`/fix` can be used anytime for bug fixes (no spec needed). `/adr` and `/rfc` can be used at any point to capture decisions or propose changes.

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
├── settings.json              # Hooks, permissions, model config (Claude Code)
├── statusline-command.sh      # Custom status line script (Claude Code)
├── aiwf                       # Toolkit manager CLI
├── install.sh                 # Claude Code symlink installer
├── uninstall.sh               # Claude Code uninstaller
├── bootstrap.sh               # One-liner multi-platform bootstrap
├── adapters/
│   ├── cursor/
│   │   ├── install.sh         # Generates ~/.cursor/rules/aiwf-*.mdc
│   │   └── uninstall.sh       # Removes ~/.cursor/rules/aiwf-*.mdc
│   └── codex/
│       ├── install.sh         # Symlinks skills into ~/.agents/skills/aiwf-* + writes ~/.codex/AGENTS.md
│       └── uninstall.sh       # Removes skill symlinks and AGENTS.md
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
│   ├── security/
│   ├── adr/
│   ├── rfc/
│   ├── spec/
│   ├── roadmap/
│   ├── feature/
│   ├── fix/
│   ├── review/
│   ├── autopilot/
│   ├── new-project/
│   ├── commit/
│   ├── pr/
│   ├── design/
│   ├── verify-design/
│   └── factory/
└── docs/
    ├── WORKFLOW.md            # Full workflow documentation
    └── REFERENCE.md           # Quick reference for all components
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
| [Workflow Guide](docs/WORKFLOW.md) | Full workflow guide — phases, conventions, CI/CD integration, team practices |
| [Reference](docs/REFERENCE.md) | Quick reference for all agents, skills, settings, and daily patterns |
| [Changelog](CHANGELOG.md) | Release notes — what changed in each version |

## Modifying the Toolkit

All config lives in this repo. **Never edit platform config files directly** (`~/.claude/`, `~/.cursor/rules/aiwf-*.mdc`, `~/.codex/AGENTS.md`, `~/.agents/skills/aiwf-*/`) — changes will be lost on the next install or symlink conflict.

To modify anything:

1. Edit the source file in this repo (skills, agents, CLAUDE.md, reviews, etc.)
2. Commit and push

**Claude Code / Codex** — skills are symlinked (`~/.claude/skills/`, `~/.agents/skills/aiwf-*/`), so edits to SKILL.md files in this repo take effect immediately. Re-run `aiwf install-codex` only when adding new skills or changing global conventions/agents/reviews (the AGENTS.md file is compiled, not symlinked).

**Cursor** — uses generated MDC files; regenerate after any change:

```bash
aiwf install-cursor   # regenerate ~/.cursor/rules/aiwf-*.mdc
aiwf install-codex    # re-link skills + recompile ~/.codex/AGENTS.md
# or both:
aiwf install-all
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## Security

See [SECURITY.md](SECURITY.md) for our vulnerability disclosure policy.

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE) — 0xrafasec
