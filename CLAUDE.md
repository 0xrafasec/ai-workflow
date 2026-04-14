# Global Defaults

## Verification
- Always verify work before claiming completion: run lint/build/tests and check outputs against the stated design or spec references.
- Before saying you're done, run lint, typecheck, and tests, and paste the tail of each output. If anything fails, fix and re-run.

## Workflow
- Spec first, code second - read the spec before implementing
- Commit messages use conventional commits: feat:, fix:, refactor:, chore:, test:, docs:, security:
- Split commits by logical concern; each commit leaves the codebase working
- Security-sensitive changes require /sec-review before PR
- Use the writer/reviewer pattern: never review code in the same session that wrote it

## UI Work
- Before implementing UI work, always load and reference the Paper design source; do not proceed without it.

## File Conventions
- Prefer refactoring existing files over creating new ones; ask before introducing parallel docs/configs.

## Git Workflow
- Check you are in the correct project directory and that it is a git repo before running commit/PR/bootstrap commands.

## Code Quality
- No unnecessary abstractions - keep code as simple as it can be
- No speculative features or premature generalization
- Validate at system boundaries (user input, external APIs), trust internal code
- Tests must cover verification criteria from the spec

## PR Structure
- Keep PRs focused: one concern per PR, under 200 lines when possible
- PR description must include: summary, link to spec, security checklist, test plan

## Context Management
- /clear between unrelated tasks
- /compact when context gets heavy mid-task
- /rewind when an approach fails after 2 corrections

## Toolkit (ai-workflow repo)
- All global config (CLAUDE.md, settings.json, agents, skills, commands, reviews) is symlinked from ~/Projects/AI/ai-workflow into ~/.claude/
- NEVER edit files directly in ~/.claude/ — changes will be lost or cause symlink conflicts
- To modify any skill, agent, command, or config: edit the source in ~/Projects/AI/ai-workflow/, then commit and push
- Available skills: /prd, /architecture, /tdd, /security, /adr, /rfc, /spec, /roadmap, /feature, /fix, /commit, /pr, /review, /autopilot, /code-review, /new-project, /sec-review, /verify-design, /factory
- Run `install.sh` after adding new skills or agents to re-symlink
- When adding, removing, or renaming skills/agents/commands: always update install.sh, uninstall.sh, and the "Available skills" list above to stay in sync
