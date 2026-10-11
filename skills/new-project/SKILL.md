---
name: new-project
description: "Scaffold a new project with the full AI-assisted development workflow — Makefile targets, linter/formatter configs, pre-commit hooks, CLAUDE.md, docs skeleton, tailored to the chosen stack (python, go, typescript/nextjs, rust, etc.). Use when the user says 'start a new project', 'bootstrap a repo', 'scaffold X', 'set up a fresh codebase for Y', 'init a new service'."
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
docs/
docs/specs/
docs/roadmap/
docs/adr/
```

**Note:** The workflow skills are installed globally. Do NOT create project-level copies of them — they'd duplicate and drift from the global versions. Only create project-level settings.

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
- Security-sensitive changes require /security-review before PR
- Features start with a spec in docs/specs/
```

Adapt the build commands and style section to the chosen language/framework.

### 5. Create project-level settings

Create `.claude/settings.json` with hooks appropriate to the language. A `PostToolUse` hook only reaches Claude when it exits 2 and writes to stderr, so the lint command must fail loudly rather than pipe into `head`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "out=$(make lint-changed 2>&1) || { echo \"$out\" | head -20 >&2; exit 2; }"
          }
        ]
      }
    ]
  }
}
```

### 6. Create Makefile

Create a `Makefile` with standard targets for the chosen language/framework:
- `test` — run tests
- `lint` — run linter
- `typecheck` — run type checker (if applicable)
- `build` — build (if applicable)
- `lint-changed` — lint only changed files
- `security-scan` — run security scanner (gitleaks, bandit, gosec, etc.)

### 7. Create .pre-commit-config.yaml

Set up pre-commit hooks:
- Language-appropriate linter
- Type checker (if applicable)
- Test runner
- gitleaks for secret detection

### 8. Create .gitignore

Appropriate for the language/framework. Always include:
- `.claude/settings.local.json` (personal overrides — `.claude/settings.json` itself is committed)
- `.env`
- Language-specific build artifacts

### 9. Create initial docs

Create `.gitkeep` files to preserve directory structure:
- `docs/specs/.gitkeep`
- `docs/roadmap/.gitkeep`
- `docs/adr/.gitkeep`

### 10. Summary

Tell the user what was created and suggest next steps:
1. `cd <project-name>`
2. `pre-commit install`
3. `/prd <project-name>` — define what we're building
4. `/architecture` — define system structure, testing strategy, dev environment, CI/CD
5. `/threat-model` — define the threat model (if applicable)
6. `/spec <first-feature>` — write your first feature spec
7. `/feature docs/specs/<first-feature>.md` — implement it
