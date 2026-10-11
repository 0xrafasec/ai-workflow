<p align="center">
  <h1 align="center">AI Workflow</h1>
  <p align="center">
    Full SDLC (Software Development Life Cycle) for AI-assisted coding — from idea to production.<br/>
    Built on SDD (Spec-Driven Development): specs are the source of truth, AI agents execute them.<br/>
    Skills, a reviewer agent, and conventions — installed globally, applied everywhere.<br/><br/>
    For <a href="https://docs.anthropic.com/en/docs/claude-code">Claude Code</a>.
  </p>
</p>

<p align="center">
  <a href="https://github.com/0xrafasec/ai-workflow/blob/main/LICENSE"><img src="https://img.shields.io/github/license/0xrafasec/ai-workflow?style=flat-square" alt="License"></a>
  <a href="https://github.com/0xrafasec/ai-workflow/issues"><img src="https://img.shields.io/github/issues/0xrafasec/ai-workflow?style=flat-square" alt="Issues"></a>
  <a href="https://github.com/0xrafasec/ai-workflow/stargazers"><img src="https://img.shields.io/github/stars/0xrafasec/ai-workflow?style=flat-square" alt="Stars"></a>
</p>

---

## What is this?

AI Workflow covers the entire software development lifecycle for AI-assisted coding — from the initial idea through design, implementation, review, and delivery. It installs as a set of global skills, agents, and conventions that apply to every project you work on.

Each phase of development has dedicated tooling:

- **Discovery** — interview-driven requirements gathering (`/prd`)
- **Design** — architecture with testing strategy, and threat modeling (`/architecture`, `/threat-model`)
- **Specification** — detailed feature specs with verification criteria (`/spec`)
- **Planning** — phased roadmaps with dependency tracking (`/roadmap`)
- **Implementation** — one slice at a time from a spec (`/feature`), or a whole roadmap in parallel across isolated worktrees (`/autopilot`)
- **Review** — every PR is reviewed by a fresh-context `reviewer` agent before it is marked ready (`/pr`); for ad-hoc reviews use Claude Code's built-in `/code-review` and `/security-review`
- **Governance** — decision records at any point (`/adr`)

## Features

- **15 slash-command skills** covering every phase from idea to merged PR
- **One reviewer agent** — a read-only, fresh-context reviewer with a fixed checklist and verdict format, dispatched by `/pr` and `/autopilot`
- **Parallel execution** — worktree-based development with `/autopilot` for full roadmap execution
- **Writer/reviewer separation** — a fresh-context reviewer is always spawned for every branch, never the session that wrote it; merging stays a separate, human-gated decision
- **Notification hooks** — desktop notifications when Claude needs attention
- **Custom status line** — git branch, model and context on one quiet row; rate limits and their reset times appear only once they need attention

## Development Lifecycle

The toolkit implements a layered document pipeline where each phase builds on the ones above it. Humans decide *what* to build through structured interviews and specs; AI agents decide *how* to build it by following those specs with full context.

```
Idea → PRD (why) → Architecture + TDD + Security (how) → Roadmap (when) → Specs (what, per task) → Implementation → Review → Ship
```

A feature spec references the architecture, technical design, and threat model — so implementation agents have complete context without repetition.

### Model Strategy

The workflow uses a tiered model strategy — Opus for decisions, Sonnet for execution:

| Task | Model | Reasoning |
|------|-------|-----------|
| Spec writing, design, interviews | **Opus** | Creative reasoning, edge case discovery |
| Implementation (main session) | **Opus** | Complex design decisions |
| Orchestration (`/autopilot`) | **Opus** | Dependency logic, phase management |
| Review (`reviewer` agent) | **Sonnet** | Small, checklist-driven input: diff + spec |
| Worktree agents (`/autopilot`) | **Sonnet** | Following detailed specs, not designing |

## Quick Start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- `git`, `bash`
- `jq` (status line — required), `notify-send` (Linux) or `osascript` (macOS, built in) for desktop notifications

### Install (recommended — one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/0xrafasec/ai-workflow/main/bootstrap.sh | bash
```

This clones the repo into `~/.local/share/ai-workflow`, symlinks the toolkit into `~/.claude`, and puts `aiwf` in `~/.local/bin`. Pin to a specific release with `AIWF_REF=v0.1.0 bash`.

Prefer to read the script before running it? [bootstrap.sh](bootstrap.sh) is short and auditable — the whole toolkit is bash + markdown by design.

### Install from a git clone (no curl)

```bash
git clone https://github.com/0xrafasec/ai-workflow.git
cd ai-workflow
./install.sh          # symlink into ~/.claude + install the aiwf launcher in ~/.local/bin
```

### Manage the install

Once `aiwf` is on your PATH:

```bash
aiwf status            # install dir, version, and symlink health
aiwf update            # git pull + re-link (refuses dirty trees; --force stashes)
aiwf reinstall         # repair broken symlinks
aiwf uninstall         # remove symlinks (--purge deletes the clone too)
aiwf version           # git describe
aiwf help              # all commands
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

### Multiple Claude Code profiles

Claude Code can run isolated profiles — separate login, settings, MCP servers, history — by pointing its own `CLAUDE_CONFIG_DIR` at a different directory:

```bash
alias claude-work='CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude'
```

Each profile carries its own `skills/`, `agents/`, `commands/` and `CLAUDE.md`, so a new profile starts with none of the toolkit. Set `CLAUDE_DIR` to install into it:

```bash
CLAUDE_DIR="$HOME/.claude-work" ./install.sh
# or: CLAUDE_DIR="$HOME/.claude-work" aiwf install
```

**`settings.json` is not shared.** Account, theme, model, status line and enabled plugins are the reason to run separate profiles in the first place, so only the primary `~/.claude` gets the repo's `settings.json` — a secondary `CLAUDE_DIR` keeps its own file untouched. That follows from `CLAUDE_DIR`, not from a flag, so it still holds when `aiwf update` or `aiwf reinstall` re-runs the install for you. Override with `--with-settings` (share one settings file everywhere) or `--no-settings` (skip it even for the primary dir).

What each profile sets for itself, in its own `settings.json` — model, permission mode, theme, status line:

```json
{
  "model": "claude-opus-4-8[1m]",
  "theme": "dark",
  "permissions": { "defaultMode": "bypassPermissions" },
  "statusLine": {
    "type": "command",
    "command": "bash \"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/statusline-command.sh\"",
    "refreshInterval": 30
  }
}
```

`model` takes a full model id, not just an alias, when you want a specific variant — `claude-opus-4-8[1m]` for the 1M-context window, `claude-opus-5`, `claude-sonnet-5`. The status line path resolves per profile, so each one runs the shared script against its own config dir.

`--with-settings` and `--no-settings` are last-wins if you pass both.

Uninstall the same way (`CLAUDE_DIR="$HOME/.claude-work" ./uninstall.sh`). It only removes symlinks, so a profile-local `settings.json` survives, and it leaves `~/.local/bin/aiwf` in place because the launcher is shared by every profile.

`aiwf uninstall --purge` deletes the shared clone every profile links against, so it is refused unless `CLAUDE_DIR` is the primary dir.

### Uninstall

```bash
aiwf uninstall            # remove the symlinks
aiwf uninstall --purge    # remove the symlinks + delete the clone
```

## Skills

Skills are multi-step workflows invoked as slash commands inside Claude Code.

### Planning

| Skill | Description |
|-------|-------------|
| `/prd` | Interview-driven Product Requirements Document |
| `/architecture` | One `docs/ARCHITECTURE.md`: the system (components, data flow, stack, deployment) and how it is engineered (testing strategy, dev env, CI/CD, coding standards) |
| `/threat-model` | STRIDE-style threat model (`docs/THREAT_MODEL.md`) |
| `/adr <title>` | Architecture Decision Record |

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
| `/feature <spec>` | End-to-end feature implementation from a spec. `--commit` auto-commits after completion; `--pr` also opens the PR and runs its review loop |
| `/fix <issue>` | Diagnose and fix a bug from a description, stack trace, or GitHub issue |
| `/autopilot <roadmap>` · `--phase <NNN>` · `--milestone <N>` | Deliver a roadmap, one phase, or one GitHub milestone: develop each task in a worktree → fresh-context review → bounded fix loop → **merge to main**. `--supervised` stops with PRs open for you to merge; `--dry-run` prints the plan. User-invoked only |
| `/new-project <name>` | Scaffold a new project with the full workflow |

### Review

There is no review skill. `/pr` dispatches the `reviewer` agent on every branch before marking the PR ready. To review someone else's branch or PR, use Claude Code's built-in `/code-review`; for a security pass, the built-in `/security-review`.

### Delivery

| Skill | Description |
|-------|-------------|
| `/commit` | Stage and commit the working tree as one or more logical conventional commits (local-only, never pushes) |
| `/pr [--draft] [--no-review]` | Push the branch and open a pull request as a **draft**, have the fresh-context `reviewer` agent review it, fix HIGH/MED findings (max 2 cycles), then mark it ready. `--draft` keeps it a draft; `--no-review` skips the review loop |

## Agents

| Agent | What it does |
|-------|--------------|
| `reviewer` | Read-only review of a branch diff against its spec: spec compliance, correctness, security at boundaries, test quality, convention drift. Runs the project's checks itself and returns `PASS` / `FIX_REQUIRED` with `HIGH` / `MED` / `LOW` findings |

## How It Works

### The Document Pipeline

The typical flow from idea to shipped code:

```
/prd                       Define what to build and why
  │
/architecture              System structure + testing strategy, dev env, CI/CD
/threat-model              Threat model
  │
/roadmap                   Phase breakdown from design docs
  │
/spec <feature>            Detail each task in the roadmap
  │
  │   /design [flow]       UI designs in Paper (for UI features)
  │   /verify-design       Diff running UI against Paper refs, fix in place
  │
  ├── /autopilot           Deliver a roadmap, phase or milestone (build, review, fix, merge to main)
  └── /feature <spec>      Or implement one feature at a time
        │
      /pr                  Draft PR → fresh-context reviewer → ready
```

`/fix` can be used anytime for bug fixes (no spec needed). `/adr` can be used at any point to capture a decision.

### Parallel Development

Each task runs in its own [git worktree](https://git-scm.com/docs/git-worktree), isolated from other work:

```bash
claude --worktree feature-auth
claude --worktree feature-dashboard
```

`/autopilot` takes this further — it reads a roadmap and runs the full pipeline for every task (develop in a worktree → review in a fresh context → fix → **merge to `main`**), dispatching independent tasks in parallel waves and sequencing dependent ones after their merge. It is autonomous by default (no human gate); `--supervised` never merges: it stops with the PRs open whenever the remaining work is waiting on your merge, and resumes on `continue`.

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
├── CLAUDE.md                  # Project-only rules (loads when working IN this repo)
├── dotfiles/CLAUDE.md          # Global conventions (symlinked to ~/.claude/)
├── settings.json              # Hooks, permissions, model config (Claude Code)
├── statusline-command.sh      # Custom status line script (Claude Code)
├── aiwf                       # Toolkit manager CLI
├── install.sh                 # Claude Code symlink installer
├── uninstall.sh               # Claude Code uninstaller
├── bootstrap.sh               # One-liner bootstrap
├── agents/
│   └── reviewer.md
├── skills/
│   ├── prd/
│   ├── architecture/
│   ├── threat-model/
│   ├── adr/
│   ├── spec/
│   ├── roadmap/
│   ├── feature/
│   ├── fix/
│   ├── autopilot/
│   ├── new-project/
│   ├── commit/
│   ├── pr/
│   ├── design/
│   ├── issues/
│   └── verify-design/
└── docs/
    ├── TRUNK_BASED_WORKFLOW.md  # Trunk-based rules, recipes, FAQ
    └── SKILL_QUALITY.md         # How skills are benchmarked
```

## Configuration

### Global Conventions (`dotfiles/CLAUDE.md`)

Source: `dotfiles/CLAUDE.md`. Installed at `~/.claude/CLAUDE.md` (symlink). Applies to every Claude Code session in every project. The repo-root `CLAUDE.md` is **separate** — it's the project-only rules for working inside the ai-workflow repo itself, and is not installed.

- Conventional commits (`feat:`, `fix:`, `refactor:`, etc.)
- Spec-first development
- Writer/reviewer separation
- PRs under 200 lines of non-test diff, one concern each

### Settings (`settings.json`)

Desktop notification hooks, permission mode, and model preference. See `settings.json` for the current config.

### Status Line

The bundled `statusline-command.sh` renders one row in Claude Code's status bar, and a second only when a rate limit needs attention:

```
ai-workflow · main ✚2 · Opus 5 (1M) · high · ctx 69k/1M
5h ███████░  88% ↻ today 22:00 (39m)
```

**Row 1 — identity:** directory, git branch + uncommitted count, model, reasoning effort (plus `⚡` in fast mode and any non-default output style), and the context in absolute tokens. Only the uncommitted count and the context count move while you work (and the cost, on API-key billing), so the rest can be read once and then ignored.

**Row 2 — rate-limit alert:** a window (5-hour, 7-day) is drawn only once it reaches 70% used, with a usage bar and **the local clock time the allowance resets**, followed by a countdown. Below that there is no decision to make, so the row is not printed. Set `CLAUDE_STATUSLINE_LIMIT_SHOW` to another percentage to move the threshold, or to `0` to always show both windows.

The reset stamp is anchored so it can't be misread: `today 22:00` and `tomorrow 05:00` when the reset is that close, and the full `Mon 10 Aug 05:00` otherwise. A bare weekday would be ambiguous for the 7-day window, which can land up to a week out.

Limit bars and percentages are green below 70%, amber from 70–89% and red at 90%+; at the default threshold a window is therefore never drawn green. The context count is graded on absolute tokens instead: amber past 150k (`CLAUDE_STATUSLINE_CTX_IDEAL`), red once auto-compact is close.

Details worth knowing:

- **No context bar or percentage.** On a 1M window the percentage stays in single digits for a whole working session, so the token count carries the meaning and its colour says whether to act.
- **Cost appears only on API-key billing**, from `cost.total_cost_usd`. On a Claude.ai subscription the figure is notional and is not shown.
- **Set `refreshInterval`** in `settings.json` (30s is a good default) so the reset countdown keeps ticking while the session is idle. Status lines are otherwise event-driven and the clock would freeze.
- **Width-adaptive** via `$COLUMNS` (needs Claude Code ≥ 2.1.153): countdowns drop below 90 columns, limit bars below 70, and the context window size below 80.
- Honours `NO_COLOR`, runs a single `jq` pass, caches `git status` for 3s, and always exits 0 — a broken status line is worse than a plain one.

## Documentation

| Document | Description |
|----------|-------------|
| [Trunk-Based Workflow](docs/TRUNK_BASED_WORKFLOW.md) | Why and how the toolkit enforces trunk-based development — rules, recipes, FAQ |
| [Skill Quality](docs/SKILL_QUALITY.md) | How skills are benchmarked before and after changes |
| [Changelog](CHANGELOG.md) | Release notes — what changed in each version |

## Modifying the Toolkit

All config lives in this repo. **Never edit the installed files under `~/.claude/` directly** — changes will be lost on the next install or symlink conflict.

To modify anything:

1. Edit the source file in this repo (skills, agents, CLAUDE.md, reviews, etc.)
2. Commit and push

Skills are symlinked into `~/.claude/skills/`, so edits to SKILL.md files in this repo take effect immediately. Re-run `aiwf install` only when adding, removing, or renaming a skill, agent, or command.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## Security

See [SECURITY.md](SECURITY.md) for our vulnerability disclosure policy.

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE) — 0xrafasec
