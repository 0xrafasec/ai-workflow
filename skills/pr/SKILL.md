---
name: pr
description: "Open a pull request for the current branch: /pr [--draft]"
---
Open a pull request for the current branch. Assumes commits already exist (from `/commit`, `/feature`, `/fix`, or manual commits).

## Parse Arguments

$ARGUMENTS may contain:
- **`--draft`** — open the PR as a draft (GitHub's "Draft pull request" option). Use for work-in-progress where you want early CI feedback or a review conversation but aren't ready to merge.
- **No flags** — open a normal, review-ready PR.

## Important

- **Never** force-push to `main` / `master`. Warn the user if they explicitly ask for it.
- **Never** force-push without explicit user confirmation.
- **Never** merge the PR, request reviewers, add labels, or close issues. Those are explicit follow-up actions.
- **Do not** add Claude / Anthropic co-author tags to the PR body. Those belong in individual commits (and only when configured), not in PR descriptions.
- If the working tree is dirty, stop and tell the user to run `/commit` first. This skill never commits.

## Steps

1. **Check preconditions in parallel:**
   ```
   git status
   git rev-parse --abbrev-ref HEAD
   git remote show origin | grep 'HEAD branch'   # detect base branch (main/master)
   ```

   - **Dirty tree?** Stop and tell the user: *"Working tree has uncommitted changes. Run `/commit` first, then re-run `/pr`."*
   - **On `main` / `master`?** Stop and tell the user: *"You're on `<base>`. Create a feature branch first."*
   - Record the base branch name (usually `main`, sometimes `master` or `develop`).

2. **Gather the commit range** — with the base branch resolved:
   ```
   git log <base>..HEAD --oneline
   git diff <base>...HEAD --stat
   git diff <base>...HEAD        # for the full picture when drafting the body
   ```

   If `<base>..HEAD` is empty, stop and tell the user there's nothing to PR.

3. **Check upstream state:**
   ```
   git rev-parse --abbrev-ref --symbolic-full-name @{u}   # upstream branch, if any
   git status -sb                                          # ahead/behind counts
   ```

   - **No upstream:** push with `git push -u origin <branch>`.
   - **Behind upstream:** stop and tell the user to pull / rebase first. Don't auto-pull.
   - **Ahead of upstream:** push with `git push origin <branch>` (fast-forward).
   - **Up to date:** proceed.

4. **Analyze ALL commits in the range** (not just the latest) to draft the PR. Read each commit message and the overall diff — the PR summary describes the *whole branch*, not the tip commit.

5. **Draft the title** — concise, under 70 chars, imperative mood, **no type prefix** (`feat:`, `fix:`, etc. belong in commit messages — GitHub's PR UI already shows the branch). Describe the outcome, not the mechanism.
   - Good: `Add rate limiting to auth endpoints`
   - Bad: `feat: added rate limiter middleware with token bucket algorithm`

6. **Draft the body** — use these sections, in order, and **omit sections that don't apply**:

   ```markdown
   ## Summary
   - <1-3 bullets on what changed and why>

   ## Spec
   <link to the spec file if one exists — scan docs/specs/, specs/, or
   a feature dir for a matching spec. Omit this section entirely if
   there is no spec.>

   ## Security checklist
   <Only include this section if the diff touches: auth, sessions, crypto,
   password handling, input validation, SQL/command construction, file
   uploads, secrets, env vars, or external API calls. Omit entirely
   otherwise.>
   - [ ] Inputs validated at system boundary
   - [ ] No secrets or credentials in code/logs
   - [ ] Auth/authz checks unchanged or reviewed
   - [ ] External API calls use timeouts and error handling
   - [ ] <any other checks specific to what changed>

   ## Test plan
   - [ ] <how to verify change 1>
   - [ ] <how to verify change 2>
   - [ ] <commands to run, URLs to hit, manual steps>
   ```

   **Rules for the body:**
   - If a section header has nothing to say, delete the header. Empty sections are noise.
   - The Test Plan is **always required** — even "run the existing test suite" counts.
   - Don't pad. A focused 5-line body beats a templated 30-line one.

7. **Present the draft** — show the user:
   ```
   Title: <title>
   Base:  <base-branch>
   Head:  <current-branch>
   Draft: yes|no

   Body:
   <full body>
   ```
   Wait for approval. Accept edits ("reword title", "add X to test plan", "drop security section"). Revise and re-present until approved.

8. **Create the PR** — use `gh pr create` with a HEREDOC for the body:
   ```
   gh pr create \
     --base <base> \
     --title "<title>" \
     [--draft] \
     --body "$(cat <<'EOF'
   <body>
   EOF
   )"
   ```

   Add `--draft` **only** if the user passed `--draft` in $ARGUMENTS (or explicitly asked for a draft during the approval step).

9. **Return the PR URL** — `gh pr create` prints it on success. Show it to the user as the final output.

## Scope boundary

This skill stops once the PR URL is printed. It does **not**:
- Merge the PR
- Request reviewers (user's call — team/project convention)
- Add labels or milestones
- Close linked issues (the PR body or commits can reference them with `Closes #N`, but that's the user's decision)
- Push to any branch other than the current one
