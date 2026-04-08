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

4. **Spawn parallel review subagents:**
   - **security-reviewer** - Security analysis of the changes
   - **architecture-reviewer** - Architectural consistency review

5. **Your own review** - Focus on what subagents won't catch:
   - **Business logic correctness** - Does it solve the actual problem?
   - **Design decisions** - Are the tradeoffs right?
   - **What's missing** - What didn't the author think of?
   - **Test coverage** - Are verification criteria from the spec covered?
   - **Edge cases** - Are failure modes handled?

6. **Consolidate findings** into a single report:

   ```markdown
   # Review: [branch/PR]

   ## Verdict: APPROVE | REQUEST_CHANGES | COMMENT

   ## Spec Compliance
   - [Does it match the spec? What's missing?]

   ## Security (from subagent)
   - [Summary of findings]

   ## Architecture (from subagent)
   - [Summary of findings]

   ## Business Logic
   - [Your findings]

   ## Suggestions
   - [Improvements, not blockers]
   ```
