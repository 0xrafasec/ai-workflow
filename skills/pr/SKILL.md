---
name: pr
description: "Push the current branch and open a pull request via gh — assumes commits already exist. Use when the user says 'open a PR', 'push this up for review', 'ship this branch', 'create a draft PR', 'put this up on GitHub', or is ready to hand a branch off to reviewers. Supports --draft for work-in-progress."
---
Open a pull request for the current branch. Assumes commits already exist (from `/commit`, `/feature`, `/fix`, or manual commits).

## Parse Arguments

$ARGUMENTS may contain:
- **`--draft`** — open the PR as a draft (GitHub's "Draft pull request" option). Use for work-in-progress where you want early CI feedback or a review conversation but aren't ready to merge.
- **No flags** — open a normal, review-ready PR.

## Guardrails

A few things that matter, and why:

- **Don't force-push to `main` / `master`.** Force-pushing a shared branch rewrites history under everyone else's feet — it's the single most common way to destroy other people's work. If the user explicitly asks for it, surface the risk and confirm before proceeding.
- **Don't force-push any branch without explicit user confirmation.** Even on feature branches, someone may have pulled or based work off it — ask first.
- **Don't merge, request reviewers, add labels, or close issues as part of this skill.** Those are human judgment calls that depend on team conventions and context this skill doesn't have. Open the PR; let the user drive the rest.
- **Don't add Claude / Anthropic co-author tags in the PR body.** Co-authorship belongs on individual commits (where configured), not repeated in PR descriptions where it just adds noise.
- **If the working tree is dirty, stop and point the user at `/commit`.** This skill opens PRs; it doesn't commit. Mixing the two obscures what the PR actually contains.

## Steps

1. **Check preconditions in parallel:**
   ```
   git status
   git rev-parse --abbrev-ref HEAD
   git remote show origin | grep 'HEAD branch'   # detect base branch (main/master)
   ```

   - **Dirty tree?** Stop and tell the user: *"Working tree has uncommitted changes. Run `/commit` first, then re-run `/pr`."*
   - **On `main` / `master`?** Stop and tell the user: *"You're on `<base>`. Create a feature branch first."*
   - **Branch name doesn't match the trunk-based convention?** (`feat/*`, `fix/*`, `refactor/*`, `docs/*`, `chore/*`, `test/*`, `perf/*`, `security/*`) Warn the user and offer to rename before pushing. The convention lives in root `CLAUDE.md` → **Trunk-Based Workflow**.
   - **Diff >200 lines?** Run `git diff --stat <base>...HEAD`; if it exceeds ~200 lines (tests included), warn the user and suggest splitting. Proceed only if the user explicitly confirms ("ship it anyway") — this is a warning, not a hard block, since `/pr` runs after commits already exist.
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

10. **Post-merge cleanup reminder.** After printing the URL, append a one-liner reminder (do not execute — the PR isn't merged yet):

    *"After merge, clean up: `git checkout <base> && git pull && git branch -d <branch> && git push origin --delete <branch>` (and `git worktree remove <path>` if you used a worktree). Trunk-based workflow — never reuse a merged branch."*

## Scope boundary

This skill stops once the PR URL is printed. It does **not**:
- Merge the PR
- Request reviewers (user's call — team/project convention)
- Add labels or milestones
- Close linked issues (the PR body or commits can reference them with `Closes #N`, but that's the user's decision)
- Push to any branch other than the current one
