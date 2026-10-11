# Contributing to ai-workflow

Thanks for your interest in contributing. This guide covers how to report issues, suggest improvements, and submit changes.

## Reporting Bugs

Open an [issue](https://github.com/rafagomes/ai-workflow/issues/new?template=bug_report.md) with:

- **What happened** — the actual behavior
- **What you expected** — the correct behavior
- **Steps to reproduce** — minimal instructions to trigger the bug
- **Environment** — OS, Claude Code version, shell

## Suggesting Features

Open an [issue](https://github.com/rafagomes/ai-workflow/issues/new?template=feature_request.md) with:

- **Problem** — what you're trying to do and why the current toolkit doesn't support it
- **Proposed solution** — how you'd like it to work
- **Alternatives considered** — other approaches you thought about

## Submitting Changes

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/<your-username>/ai-workflow.git
   cd ai-workflow
   ```
3. Create a branch:
   ```bash
   git checkout -b feat/your-feature
   ```

### Development

After making changes, validate the plugin and try it in a session:

```bash
claude plugin validate .
claude --plugin-dir .
```

Skills and agents are discovered from `skills/` and `agents/`; nothing needs registering. `install.sh` and `uninstall.sh` only handle the global `CLAUDE.md`, the status line and `settings.json`.

### Commit Conventions

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
feat:       New skill, agent, or capability
fix:        Bug fix in existing functionality
refactor:   Code restructuring without behavior change
docs:       Documentation changes
chore:      Maintenance (install scripts, config)
test:       Test additions or changes
```

Each commit should leave the toolkit in a working state. Split unrelated changes into separate commits.

### Pull Requests

1. Keep PRs focused — one concern per PR
2. Write a clear description of what changed and why
3. Link to any related issues
4. Run `claude plugin validate .`; if you touched `install.sh` or `uninstall.sh`, run them against a throwaway `CLAUDE_DIR`

### What Makes a Good Skill

If you're contributing a new skill:

- **Single purpose** — one clear workflow per skill
- **Self-contained** — the SKILL.md should include all instructions Claude needs
- **Consistent** — follow the patterns in existing skills
- **Documented** — update the README skills table

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to uphold it.

## Questions?

Open a [discussion](https://github.com/rafagomes/ai-workflow/discussions) or an issue. No question is too small.
