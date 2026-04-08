# AI Workflow

A spec-driven, security-first development workflow toolkit for [Claude Code](https://claude.ai/code). Includes global agents, skills, commands, and conventions that apply across all projects.

## Quick Start

```bash
git clone git@github.com:0xrafasec/ai-workflow.git
cd ai-workflow
./install.sh    # symlinks everything into ~/.claude/
```

To remove:

```bash
./uninstall.sh  # removes symlinks, restores backups
```

## What's Included

### Agents

Specialized reviewers spawned as subagents during implementation or review.

| Agent | Purpose |
|-------|---------|
| `security-reviewer` | Reviews code for injection, auth flaws, secrets, crypto issues, data exposure, XSS/SSRF, config problems |
| `architecture-reviewer` | Reviews for pattern consistency, separation of concerns, unnecessary abstractions, API stability, dependency hygiene |

### Skills (Slash Commands)

Reusable multi-step workflows invoked as slash commands.

| Command | Purpose |
|---------|---------|
| `/prd` | Interview and create a Product Requirements Document |
| `/spec architecture` | Create a system architecture document |
| `/spec security` | Create a threat model |
| `/spec <feature>` | Create a feature implementation spec |
| `/feature <spec-path>` | Implement a feature end-to-end from a spec |
| `/review` | Review a branch/PR using the writer/reviewer pattern |
| `/new-project <name> [stack]` | Scaffold a new project with the full workflow |
| `/autopilot <roadmap-path>` | Execute a full roadmap phase by phase with parallel worktree agents |
| `/sec-review` | Full security audit with 4 parallel analysis agents |

### Config

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Global defaults — conventions, commit style, quality rules |
| `settings.json` | Desktop notification hooks, permissions, model preference |
| `statusline-command.sh` | Custom status line showing model, context usage, cost, git branch |

## Document Pipeline

The typical flow from idea to shipped code:

```
/prd                       Define what we're building and why
  |
/spec architecture         Define system structure
/spec security             Define threats and defenses
  |
/spec <feature>            Exact implementation details per feature
  |
ROADMAP.md                 Phase breakdown with tasks and dependencies
  |
  +---> /autopilot         Execute the whole roadmap automatically
  |
  +---> /feature <spec>    Or implement one feature at a time
          |
        /review            Independent review in a fresh session
```

## Workflow Principles

- **Spec first, code second** — AI executes specs; vague specs produce vague code
- **Parallel by default** — worktrees enable multiple streams without conflicts
- **Security is shift-left** — review during development, not after
- **Writer/reviewer separation** — never review code in the same session that wrote it
- **Layered quality gates** — hooks, pre-commit, subagent review, CI, human review

## Docs

- [WORKFLOW.md](WORKFLOW.md) — Full workflow documentation with phases, conventions, and CI/CD integration
- [REFERENCE.md](REFERENCE.md) — Quick reference for all agents, skills, settings, and daily usage patterns

## Requirements

- [Claude Code](https://claude.ai/code) CLI installed
- `jq` (for statusline script)
- `notify-send` (Linux — for desktop notifications)
