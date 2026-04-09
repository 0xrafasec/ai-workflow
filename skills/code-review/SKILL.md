---
name: code-review
description: Stack-aware code review — detects the project language/framework and runs security + architecture review with language-specific best practices
---
Run a stack-aware code review. Argument: $ARGUMENTS

## 1. Determine Scope

Parse the argument:

- **No argument:** diff current branch vs `main`
- **`diff`:** diff current branch vs `main`
- **`diff <branch>`:** diff current branch vs specified branch
- **`full`:** review all source files
- **`full <path>`:** review source files under a specific directory
- **Branch name:** diff that branch vs `main`
- **PR number:** fetch the PR diff

Gather context:
```
git log --oneline <base-branch>..HEAD
git diff <base-branch>...HEAD
```

If no changes in diff mode, tell the user and suggest `/code-review full`.

## 2. Detect the Stack

Auto-detect by checking for marker files. Check **all** — projects can be polyglot.

| Marker | Stack | Guide |
|--------|-------|-------|
| `go.mod` | Go | `reviews/go.md` |
| `Cargo.toml` | Rust | `reviews/rust.md` |
| `package.json` with `next` in deps | Next.js | `reviews/typescript.md` (Next.js sections) |
| `package.json` with `@nestjs/core` in deps | Nest.js | `reviews/typescript.md` (Nest.js sections) |
| `package.json` or `tsconfig.json` | Node.js / TypeScript | `reviews/typescript.md` |
| `pyproject.toml`, `setup.py`, `requirements.txt`, `Pipfile` | Python | `reviews/python.md` |
| `manage.py` or `django` in deps | Python (Django) | `reviews/python.md` (Django sections) |
| `fastapi` in deps | Python (FastAPI) | `reviews/python.md` (FastAPI sections) |
| `flask` in deps | Python (Flask) | `reviews/python.md` (Flask sections) |

If the stack can't be detected, ask the user.

Announce what you found:
```
Detected stack: Go, Next.js (TypeScript)
Loading guides: go.md, typescript.md
```

## 3. Load Review Guides

Read the corresponding review guides. Look for them in this order:
1. **Project-level:** `.claude/reviews/` in the project root (project-specific overrides)
2. **Global:** `~/.claude/reviews/` (this repo's files, if installed via `install.sh`)
3. **This repo directly:** `reviews/` relative to the skill file's parent directory

Read every matched guide. These contain language-specific security and architecture criteria that supplement the base agents.

Also read the base agent files:
- `agents/security-reviewer.md`
- `agents/architecture-reviewer.md`

## 4. Launch Parallel Review Agents

Spawn **3 parallel subagents** using the Agent tool. Each gets the diff/file list, the base agent prompt, AND the language-specific guide content.

### Agent 1: Security Review (stack-aware) — model: opus

Spawn this agent with `model: "opus"`. Security review is critical and must use the highest-quality model.

```
You are a senior security engineer reviewing code for vulnerabilities.

## Base Criteria
[Full content of agents/security-reviewer.md]

## Language-Specific Security Criteria
[The SECURITY section from each matched review guide — include all if polyglot]

## Detected Stack: [stack name(s)]
## Detected Frameworks: [Next.js, Nest.js, FastAPI, Django, etc.]

## Changes to Review
[diff or file list]

Apply BOTH the base criteria and the language-specific criteria.
For each finding, note which guide criterion it violates.
Follow the output format from the base security-reviewer.
```

### Agent 2: Architecture Review (stack-aware) — model: sonnet

Spawn this agent with `model: "sonnet"`. Architecture review follows structured criteria and doesn't require the most expensive model.

```
You are a senior software architect reviewing code for quality and consistency.

## Base Criteria
[Full content of agents/architecture-reviewer.md]

## Language-Specific Architecture Criteria
[The ARCHITECTURE section from each matched review guide — include all if polyglot]

## Detected Stack: [stack name(s)]
## Detected Frameworks: [Next.js, Nest.js, FastAPI, Django, etc.]

## Changes to Review
[diff or file list]

Apply BOTH the base criteria and the language-specific criteria.
For each finding, note which guide criterion it violates.
Follow the output format from the base architecture-reviewer.
```

### Agent 3: Stack-Specific Patterns — model: sonnet

Spawn this agent with `model: "sonnet"`. Stack-specific pattern checks are checklist-driven against loaded review guides.

```
You are a [stack] expert reviewing code for idiomatic patterns and common pitfalls.

## Stack: [detected stack(s)]
## Frameworks: [detected frameworks]

## Full Review Guide(s):
[Full content of each matched review guide]

Focus on things the security and architecture reviewers might miss:
1. **Idiomatic code** — does it follow [stack] conventions?
2. **Common pitfalls** — known footguns specific to this stack/framework?
3. **Performance** — stack-specific performance antipatterns?
4. **Testing** — do tests follow [stack] testing conventions?

## Changes to Review
[diff or file list]

Output format — for each finding:
## [N]. [Category]: `file/path:line`
- **Severity:** HIGH | MEDIUM | LOW
- **Issue:** One-line description
- **Suggestion:** How to fix, with code if helpful
```

## 5. Consolidate Report

After all agents complete:

1. Collect all findings
2. **Deduplicate** — if two agents flag the same line, keep the one with more context
3. Sort by severity (HIGH first)

Output:

```markdown
# Code Review Report

**Stack:** [detected stack(s) and frameworks]
**Mode:** [Diff against `<branch>` | Full scan]
**Branch:** [current branch]
**Date:** YYYY-MM-DD

## Verdict: PASS | REVIEW | FAIL

| Metric | Value |
|--------|-------|
| Files reviewed | N |
| Security findings | N (H high, M medium) |
| Architecture findings | N (H high, M medium, L low) |
| Stack-specific findings | N (H high, M medium, L low) |

## Security Findings
[From Agent 1, sorted by severity]

## Architecture Findings
[From Agent 2, sorted by severity]

## Stack-Specific Findings
[From Agent 3, sorted by severity]

## Positive Practices
[Combined from all agents — things done correctly, citing language-specific best practices]
```

**Verdict:**
- **PASS** — zero findings
- **REVIEW** — only MEDIUM or LOW findings
- **FAIL** — any HIGH finding

## 6. Rules

- Do NOT modify any files — this is read-only
- Do NOT run tests or build commands
- Be concise — actionable fixes, not essays
- If zero findings, output the full report with PASS verdict and positive practices
- For polyglot projects, ensure each file is reviewed against the correct language guide
