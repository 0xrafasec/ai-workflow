---
name: new-project
description: Scaffold a new project with the full AI-assisted development workflow
---
Scaffold a new project with the AI-assisted development workflow.

**Argument format:** `<project-name> [language/framework]`

- `<project-name>` (required) — name of the project directory to create
- `[language/framework]` (optional) — the tech stack, used to tailor Makefile targets, linter config, .gitignore, and pre-commit hooks. Examples: `python`, `python/fastapi`, `go`, `typescript/nextjs`, `rust`. If omitted, you will be asked.

**Examples:**
- `/new-project my-api python/fastapi` — creates `./my-api/` with Python/FastAPI tooling
- `/new-project my-cli go` — creates `./my-cli/` with Go tooling
- `/new-project my-app` — creates `./my-app/`, asks what stack to use

## Process

### 1. Interview (if needed)

If no language/framework was given, ask the user:
- What language/framework?
- What type of project? (API, CLI, library, web app, etc.)
- Any specific tooling preferences? (test framework, linter, etc.)

### 2. Initialize the project

Create the project directory **inside the current working directory** and initialize git:

```bash
mkdir -p <project-name>
cd <project-name>
git init
```

The project is created at `$PWD/<project-name>/`. If you want it elsewhere, `cd` to the desired parent directory first.

### 3. Create workflow structure

Create these directories:

```
.claude/
.claude/agents/
.claude/skills/feature/
.claude/skills/spec/
docs/
docs/specs/
docs/roadmap/
```

### 4. Create CLAUDE.md

Create a `CLAUDE.md` at the project root tailored to the language/framework:

```markdown
# CLAUDE.md

## Build & Test
- `make test` — run test suite
- `make lint` — run linters
- `make typecheck` — type checking (if applicable)
- `make build` — build the project (if applicable)

## Code Style
- [Language-specific conventions that Claude might get wrong]

## Architecture
- [Brief description of project structure]

## Workflow
- All PRs require passing CI + human review
- Commit messages use conventional commits (feat:, fix:, refactor:, chore:)
- Security-sensitive changes require /sec-review before PR
- Features start with a spec in docs/specs/
```

Adapt the build commands and style section to the chosen language/framework.

### 5. Create project-level agents

Copy the security-reviewer and architecture-reviewer into `.claude/agents/`, tailored to the project's language if needed.

### 6. Create project-level feature skill

Create `.claude/skills/feature/SKILL.md` — copy from the global one but adjust if the project has specific patterns.

### 7. Create project-level settings

Create `.claude/settings.json` with hooks appropriate to the language:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "make lint-changed 2>&1 | head -20",
        "description": "Lint after every file edit"
      }
    ]
  }
}
```

### 8. Create Makefile

Create a `Makefile` with standard targets for the chosen language/framework:
- `test` — run tests
- `lint` — run linter
- `typecheck` — run type checker (if applicable)
- `build` — build (if applicable)
- `lint-changed` — lint only changed files
- `security-scan` — run security scanner (gitleaks, bandit, gosec, etc.)

### 9. Create .pre-commit-config.yaml

Set up pre-commit hooks:
- Language-appropriate linter
- Type checker (if applicable)
- Test runner
- gitleaks for secret detection

### 10. Create .gitignore

Appropriate for the language/framework. Always include:
- `.claude/` local files
- `.env`
- Language-specific build artifacts

### 11. Create initial docs

Create `docs/specs/.gitkeep` and `docs/roadmap/.gitkeep` to preserve directory structure.

### 12. Summary

Tell the user what was created and suggest next steps:
- Install pre-commit: `pre-commit install`
- Create their first spec: `/spec <feature-name>`
- Start implementing: `/feature docs/specs/<feature-name>.md`
