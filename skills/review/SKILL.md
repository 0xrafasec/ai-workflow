---
name: review
description: Review a PR or branch using the writer/reviewer pattern
---
Review the changes on the current branch (or the branch/PR specified in $ARGUMENTS).

## Important

You are the **reviewer**, not the writer. Do NOT rewrite the implementation. Flag issues with specific line references.

## Process

1. **Determine the target:**
   - No argument: review current branch changes vs main
   - Branch name: review that branch vs main
   - PR number: fetch the PR and review its changes

2. **Gather context:**
   ```
   git log --oneline main..HEAD
   git diff main...HEAD
   ```

3. **Check spec compliance** - Find the relevant spec in `docs/specs/`. Does the implementation match?

4. **Run stack-aware code review** — Run `/code-review` to auto-detect the stack and spawn parallel agents for security, architecture, and stack-specific idiomatic checks. This loads language-specific review guides (Go, Rust, TypeScript, Python) so findings are tailored to the project.

    If `/code-review` is not available, fall back to spawning **security-reviewer** and **architecture-reviewer** subagents in parallel.

5. **Your own review** - Focus on what subagents won't catch:
   - **Business logic correctness** - Does it solve the actual problem?
   - **Design decisions** - Are the tradeoffs right?
   - **What's missing** - What didn't the author think of?
   - **Test layer coverage** - Check against `docs/specs/TDD.md` Testing Strategy (if it exists) or infer from codebase patterns:
     - Are unit tests present for new business logic?
     - Are integration tests present for new API endpoints, DB operations, or service boundaries?
     - Are e2e tests present for critical user flows (if applicable)?
     - Do tests follow the project's conventions (location, naming, framework)?
     - Are verification criteria from the spec covered at the right test layer?
   - **Edge cases** - Are failure modes handled?

6. **Consolidate findings** into a single report:

   ```markdown
   # Review: [branch/PR]

   ## Verdict: APPROVE | REQUEST_CHANGES | COMMENT

   ## Spec Compliance
   - [Does it match the spec? What's missing?]

   ## Security (from code-review)
   - [Summary of findings]

   ## Architecture (from code-review)
   - [Summary of findings]

   ## Stack-Specific (from code-review)
   - [Language/framework-specific findings]

   ## Business Logic
   - [Your findings]

   ## Test Coverage
   - **Unit:** [Present/Missing — what's covered, what's not]
   - **Integration:** [Present/Missing/N/A — what's covered]
   - **E2E:** [Present/Missing/N/A — what's covered]
   - **Verdict:** [Adequate / Needs more coverage at X layer]

   ## Suggestions
   - [Improvements, not blockers]
   ```
