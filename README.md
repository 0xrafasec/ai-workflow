<p align="center">
  <h1 align="center">AI Workflow</h1>
  <p align="center">
    Full SDLC (Software Development Life Cycle) for AI-assisted coding — from idea to production.<br/>
    Built on SDD (Spec-Driven Development): specs are the source of truth, AI agents execute them.<br/>
    Fifteen skills, a reviewer agent, and conventions — a Claude Code plugin.<br/><br/>
    For <a href="https://docs.anthropic.com/en/docs/claude-code">Claude Code</a>.
  </p>
</p>

<p align="center">
  <a href="https://github.com/rafagomes/ai-workflow/blob/main/LICENSE"><img src="https://img.shields.io/github/license/rafagomes/ai-workflow?style=flat-square" alt="License"></a>
  <a href="https://github.com/rafagomes/ai-workflow/issues"><img src="https://img.shields.io/github/issues/rafagomes/ai-workflow?style=flat-square" alt="Issues"></a>
  <a href="https://github.com/rafagomes/ai-workflow/stargazers"><img src="https://img.shields.io/github/stars/rafagomes/ai-workflow?style=flat-square" alt="Stars"></a>
</p>

---

## What is this?

AI Workflow is a Claude Code plugin (`wf`) that covers the software development lifecycle for AI-assisted coding — from the initial idea through design, implementation, review, and delivery. It is built on Spec-Driven Development: humans decide *what* to build through structured interviews and specs; agents decide *how* by following those specs with full context.

```
Idea → PRD (why) → Architecture + Threat model (how) → Roadmap (when) → Specs (what, per task) → Implementation → Review → Ship
```

- **15 skills** covering every phase from idea to merged PR
- **One reviewer agent** — read-only, fresh-context, with a fixed checklist and verdict format; every PR passes through it before it is marked ready
- **Trunk-based by construction** — short-lived branches, slices of ≤200 non-test lines, one PR per slice ([why and how](docs/TRUNK_BASED_WORKFLOW.md))
- **Writer/reviewer separation** — the session that wrote the code never reviews it; merging stays a separate, human-gated decision unless you invoke `/wf:autopilot`
- **Global conventions and a status line**, installed from this repo alongside the plugin

## Install

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and `gh`.

### The plugin (skills + reviewer agent)

Inside Claude Code:

```
/plugin marketplace add rafagomes/ai-workflow
/plugin install wf@ai-workflow
```

Or from a shell:

```bash
claude plugin marketplace add rafagomes/ai-workflow
claude plugin install wf@ai-workflow
```

Update with `claude plugin update wf@ai-workflow`; remove with `claude plugin uninstall wf@ai-workflow`.

Skills are namespaced by the plugin: `/wf:spec`, `/wf:feature`, `/wf:pr`, and so on.

### The global conventions and status line (optional)

A plugin cannot ship a global `CLAUDE.md`, a status line, or user settings. To get those, clone the repo and run the installer, which symlinks three files into `~/.claude/`:

```bash
git clone https://github.com/rafagomes/ai-workflow.git
cd ai-workflow
./install.sh
```

| Source | Installed as | What it is |
|--------|--------------|------------|
| `dotfiles/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global conventions applied to every project: verification, conventional commits, trunk rules, writer/reviewer separation |
| `statusline-command.sh` | `~/.claude/statusline-command.sh` | The status line described below (needs `jq`) |
| `settings.json` | `~/.claude/settings.json` | Your settings, seeded from `settings.example.json` on first run and never tracked |

An existing file is backed up to `<name>.bak.<timestamp>` before it is replaced, and `./uninstall.sh` removes the symlinks that point into this clone and restores the backup. Flags: `--no-settings` leaves `settings.json` alone, `--with-settings` forces it, `--extra` also links the personal skills under `extras/`.

**Multiple Claude Code profiles.** Claude Code isolates profiles through `CLAUDE_CONFIG_DIR`. Point `CLAUDE_DIR` at a profile to install into it: `CLAUDE_DIR="$HOME/.claude-work" ./install.sh`. A secondary profile keeps its own `settings.json` — account, theme, model and enabled plugins are the reason to have separate profiles — so only the primary `~/.claude` gets the repo's file unless you pass `--with-settings`. The plugin is installed per profile too: run the `claude plugin` commands with `CLAUDE_CONFIG_DIR` set.

**Upgrading from the symlink-based install (before 1.0).** Run `./uninstall.sh` once from your existing clone, at the path the old links point to — it only removes links into its own clone. It sweeps the old skill, agent, command and review-guide symlinks and the `aiwf` launcher — then `git pull`, `./install.sh`, and install the plugin.

## Skills

### Planning

| Skill | What it produces |
|-------|------------------|
| `/wf:prd` | Interview-driven Product Requirements Document (`docs/PRD.md`) |
| `/wf:architecture` | One `docs/ARCHITECTURE.md`: the system (components, data flow, stack, deployment) and how it is engineered (testing strategy, dev environment, CI/CD, coding standards) |
| `/wf:threat-model` | STRIDE-style threat model (`docs/THREAT_MODEL.md`) |
| `/wf:adr <title>` | An Architecture Decision Record (`docs/adr/NNNN-<slug>.md`) |
| `/wf:roadmap` | Phased roadmap, one file per phase (`docs/roadmap/NNN_<phase>.md`) |
| `/wf:spec <feature>` | Feature spec with verification criteria, sliced when it exceeds 200 source lines (`docs/specs/NNN_<feature>.md`) |
| `/wf:issues <roadmap or spec>` | GitHub milestones and issues, one milestone per phase and one issue per task or slice |

### UI design

| Skill | What it does |
|-------|--------------|
| `/wf:design [flow]` | Design system, brand guide and screens in Paper (requires the Paper MCP) |
| `/wf:verify-design [page]` | Diffs the running UI against the Paper artboards with Playwright and fixes mismatches in place |

### Implementation

| Skill | What it does |
|-------|--------------|
| `/wf:feature <spec>` | Implements one spec or slice with tests, runs the checks, stops at the working tree. `--commit` also commits; `--pr` also opens the PR and runs its review |
| `/wf:fix <description or issue>` | Root-cause diagnosis, minimal fix, regression test |
| `/wf:autopilot <roadmap>` · `--phase <NNN>` · `--milestone <N>` | Delivers a roadmap, a phase, or a GitHub milestone: each task developed in a worktree → fresh-context review → bounded fix loop → **merged to `main`**. `--supervised` stops with PRs open for you to merge; `--dry-run` prints the plan. Runs only when you type it |
| `/wf:new-project <name> [stack]` | Scaffolds a repo: `CLAUDE.md`, Makefile, linter and pre-commit config, lint hook, docs skeleton |

### Delivery

| Skill | What it does |
|-------|--------------|
| `/wf:commit` | Splits the working tree into logical conventional commits. Local only |
| `/wf:pr [--draft] [--no-review]` | Pushes and opens the PR as a **draft**, has the `wf:reviewer` agent review it, fixes HIGH/MED findings (max 2 cycles), then marks it ready |

There is no review skill. To review someone else's branch or PR, use Claude Code's built-in `/code-review`; for a security pass, the built-in `/security-review`.

### The session-start hook

The plugin ships one hook. When a session starts in a git repository whose branch tracks a remote, it runs `git fetch` on that remote and, only if the branch is behind or has diverged, tells Claude so before any work begins. It prints nothing otherwise, never prompts for credentials, and gives up quietly when the remote is unreachable.

### The reviewer agent

`wf:reviewer` reviews a branch diff against its spec: spec compliance, correctness, security at boundaries, test quality, convention drift. It is read-only, runs the project's checks itself rather than trusting the writer's output, and returns `PASS` or `FIX_REQUIRED` with `HIGH` / `MED` / `LOW` findings. `/wf:pr` and `/wf:autopilot` dispatch it.

## How it fits together

```
/wf:prd                    What to build and why
  │
/wf:architecture           System structure + testing strategy, dev env, CI/CD
/wf:threat-model           Threat model (when there are trust boundaries)
  │
/wf:roadmap                Phases and tasks
/wf:spec <feature>         One spec per task, sliced to ≤200 source lines
/wf:issues                 Milestones + issues on GitHub
  │
  │   /wf:design           UI designs in Paper (for UI work)
  │   /wf:verify-design    Diff the running UI against Paper, fix in place
  │
  ├── /wf:autopilot        Deliver a roadmap, phase or milestone end to end
  └── /wf:feature <spec>   Or implement one slice at a time
        │
      /wf:commit           Logical conventional commits
      /wf:pr               Draft PR → fresh-context reviewer → ready
        │
      you merge
```

`/wf:fix` works at any time, without a spec. `/wf:adr` records a decision whenever one is made.

### When to use what

Not every change needs every step.

| Situation | Path |
|-----------|------|
| A bug | `/wf:fix` → `/wf:commit` → `/wf:pr` |
| A small, well-understood change | `/wf:spec` → `/wf:feature` → `/wf:commit` → `/wf:pr` |
| A feature larger than one PR | `/wf:spec` (it slices) → `/wf:issues` → `/wf:feature` per slice |
| A new project | `/wf:new-project` → `/wf:prd` → `/wf:architecture` → `/wf:threat-model` → `/wf:roadmap` → `/wf:spec` per task |
| An inherited codebase with no docs | `/wf:architecture` first — it explores the code and asks you to confirm what it found — then `/wf:threat-model` if needed, then specs as you go |
| A planned phase you want delivered unattended | `/wf:autopilot --phase <NNN>` (add `--supervised` to keep the merge) |
| A decision worth remembering | `/wf:adr` |

## Repository layout

```
ai-workflow/
├── .claude-plugin/
│   ├── plugin.json            # The wf plugin manifest
│   └── marketplace.json       # Lets this repo be added as a marketplace
├── skills/<name>/SKILL.md     # The 15 skills
├── agents/reviewer.md         # The reviewer agent
├── hooks/                     # SessionStart hook: fetch and report a stale branch
├── dotfiles/CLAUDE.md         # Global conventions (symlinked to ~/.claude/CLAUDE.md)
├── statusline-command.sh      # Status line script
├── settings.example.json      # Seed for your untracked settings.json
├── install.sh / uninstall.sh  # Symlink the three personal files above
├── extras/                    # Opt-in personal skills (./install.sh --extra)
├── CLAUDE.md                  # Rules for working IN this repo (not installed)
└── docs/
    ├── TRUNK_BASED_WORKFLOW.md
    └── SKILL_QUALITY.md
```

## Configuration

### Global conventions (`dotfiles/CLAUDE.md`)

Installed at `~/.claude/CLAUDE.md` and applied to every Claude Code session in every project: verify before claiming done, conventional commits split by concern, spec first, a fresh reviewer for every branch, human-gated merges, and the trunk rules. The repo-root `CLAUDE.md` is separate — it holds the rules for working inside this repo and is not installed.

### Settings (`settings.json`)

`settings.example.json` seeds a desktop-notification hook, the status line, and a plugin list with `wf` enabled from this repo's marketplace. It sets no permission mode and no model — choose those yourself. Your `settings.json` is gitignored; edit it freely.

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

## Modifying the toolkit

Edit the sources in this repo, never the installed copies. To try a change before publishing it, load the working tree as the plugin for one session:

```bash
claude --plugin-dir /path/to/ai-workflow
```

`claude plugin validate .` checks the manifests and every skill and agent definition. `dotfiles/CLAUDE.md` and `statusline-command.sh` are symlinked, so edits to them apply immediately.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## Security

See [SECURITY.md](SECURITY.md) for our vulnerability disclosure policy.

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE) — 0xrafasec
