---
name: pr
description: "Push the current branch and open a pull request via gh — assumes commits already exist. Use when the user says 'open a PR', 'push this up for review', 'ship this branch', 'create a draft PR', 'put this up on GitHub', or is ready to hand a branch off to reviewers. By default opens the PR as a draft, runs a fresh-context review + bounded fixes, then marks it ready on PASS. Supports --draft (stay draft) and --no-review (skip the review loop)."
---
Open a pull request for the current branch. Assumes commits already exist (from `/commit`, `/feature`, `/fix`, or manual commits).

**Default flow (draft → review → fix → ready):** the PR is opened as a *draft*, a fresh-context reviewer subagent reviews the committed branch, HIGH/MED findings are fixed in a bounded loop, and the PR is then flipped to *ready* on a passing review. This honours the writer/reviewer rule in root `CLAUDE.md` — a reviewer with cold context always sees the branch before it becomes review-ready. The escape hatches below opt out.

## Parse Arguments

$ARGUMENTS may contain:
- **`--draft`** — leave the PR as a draft even after the review passes (explicit work-in-progress). The fresh review still runs; only the final `gh pr ready` transition is skipped.
- **`--no-review`** — skip the fresh-context review loop entirely and open the PR directly (ready-for-review, unless `--draft`). Use for trivial or time-critical PRs, or when a fresh-context review of these exact commits already ran (say so when you use it).
- **No flags** — the default flow: open as draft, run the fresh review + bounded fixes, auto-mark ready on PASS.

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
   - **Diff >200 lines?** Run `git diff --stat <base>...HEAD -- . ':(exclude)**/tests/**' ':(exclude)**/*_test.*' ':(exclude)**/*.test.*' ':(exclude)**/test_*'`; if the **non-test** diff exceeds ~200 lines, warn the user and suggest splitting. Proceed only if the user explicitly confirms ("ship it anyway") — this is a warning, not a hard block, since `/pr` runs after commits already exist.
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
   Flow:  draft → fresh review → ready   (or: draft-only [--draft] / direct, no review [--no-review])

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

   **When the review loop runs** (default — anything except `--no-review`), always pass `--draft` here so the branch is never review-ready before its fresh review. When `--no-review` is set, add `--draft` only if the user passed `--draft` (or asked for a draft during approval).

9. **Fresh-context review + bounded fix loop** — **run this by default; skip only when `--no-review` was passed.** You are the writer; you do **not** review your own work (writer/reviewer rule, root `CLAUDE.md`), and an in-session review skill does not count — it runs in your context. Dispatch the `reviewer` agent, which starts cold:

   ```
   Agent(
     subagent_type: "reviewer",
     description: "Review PR branch",
     prompt: "Base: <base>\nSpec: <spec-path, or 'none'>\nVerify: <the project's lint / typecheck / test commands>"
   )
   ```

   The agent definition carries the checklist and the output format; the prompt only supplies the inputs. It returns `VERDICT`, `CHECKS`, `FINDINGS` (`HIGH` / `MED` / `LOW`) and a one-line `SUMMARY`.

   **Process the verdict:**
   - `PASS`, no findings → record `Review: PASS`. Go to step 10.
   - `PASS` with LOW findings only → record `Review: PASS_WITH_NITS`; surface the LOW list verbatim in the final report. Go to step 10.
   - `FIX_REQUIRED` (HIGH/MED present) → fix exactly the listed items in your current context (you're warm). Then re-run the project's lint/typecheck/tests, **commit the fixes** (conventional message) and `git push`, and re-dispatch the reviewer with one extra prompt line: `Previous findings: <list>`.

   **Bounded loop: max 2 fix cycles.** If cycle 2 still returns `FIX_REQUIRED`, record `Review: NEEDS_HUMAN — <count> HIGH/MED unresolved after 2 cycles` (and `Spec ambiguity suspected at <spec-path>` if the same finding category recurred). Do NOT loop further, and do NOT mark the PR ready.

10. **Ready transition (auto-ready on PASS).**
    - If the review is `PASS` or `PASS_WITH_NITS` **and** `--draft` was not passed → run `gh pr ready <url>` to flip the draft to review-ready.
    - If `--draft` was passed → leave it as a draft (report the passing verdict so the user knows it's review-clean WIP).
    - If the review is `NEEDS_HUMAN` → **leave it as a draft** and report the unresolved HIGH/MED findings; the user decides.
    - If `--no-review` was passed → the PR is already in its final state from step 8; nothing to flip.

11. **Return the PR URL and review verdict** — show the PR URL, its final draft/ready state, and the review outcome (`PASS` / `PASS_WITH_NITS` with the LOW nits listed / `NEEDS_HUMAN` with the unresolved items). This is the final output.

12. **Post-merge cleanup reminder.** After the URL, append a one-liner reminder (do not execute — the PR isn't merged yet):

    *"After merge, clean up: `git checkout <base> && git pull && git branch -d <branch> && git push origin --delete <branch>` (and `git worktree remove <path>` if you used a worktree). Trunk-based workflow — never reuse a merged branch."*

## Scope boundary

This skill stops once the PR URL is printed. It does **not**:
- Merge the PR
- Request reviewers (user's call — team/project convention)
- Add labels or milestones
- Close linked issues (the PR body or commits can reference them with `Closes #N`, but that's the user's decision)
- Push to any branch other than the current one
