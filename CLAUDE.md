# Global Defaults

## Workflow
- Spec first, code second - read the spec before implementing
- Commit messages use conventional commits: feat:, fix:, refactor:, chore:, test:, docs:, security:
- Split commits by logical concern; each commit leaves the codebase working
- Security-sensitive changes require /sec-review before PR
- Use the writer/reviewer pattern: never review code in the same session that wrote it

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
