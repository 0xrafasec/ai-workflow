---
name: issues
description: "File GitHub milestones + issues for a roadmap, a phase, or a spec — one milestone per phase, one issue per task/slice — using the trunk-based patterns from /spec, /roadmap, and /feature. Use when the user says 'create the GitHub issues', 'file the issues for this roadmap', 'open issues for this spec', 'make the milestones', or points at docs/roadmap/*.md or docs/specs/*.md and asks to hand them to GitHub."
---
File GitHub milestones and issues for: $ARGUMENTS

## What this skill does

`/issues` is the hand-off between planning artifacts (`docs/roadmap/*.md`, `docs/specs/*.md`) and GitHub. It files:

- **One milestone per phase** — `Phase NNN — <phase-name>`
- **One issue per task/slice** — title `[NNN.N] <task-name>` for a roadmap task, `[NNN.N.N] <slice-name>` for a sliced sub-task, or `[<feature>.NNN] <slice-name>` for a standalone spec's slice.
- **Labels per issue** — `type:<type>`, `complexity:<low|med|high>`, `mvp` or `post-mvp` (if derivable), and `needs-spec` / `spec-ready` / `blocked` as appropriate.
- **Issue body** — spec link, file list, dependencies, verification command, feature flag, acceptance criteria pulled from the spec.

After filing, `/issues` writes the issue numbers back into the source `Issue:` / `Issues:` columns so `/feature` can read them when building branch names.

## Parse arguments

The argument is one of:

- **Roadmap index** — `/issues docs/roadmap/README.md` files *everything*: one milestone per phase file, one issue per task, one issue per slice where a task points at a sliced spec.
- **Phase file** — `/issues docs/roadmap/NNN_<phase>.md` files one milestone + the phase's tasks (and slices where applicable).
- **Sliced spec index** — `/issues docs/specs/<feature>/README.md` files one issue per row in the Slices table. Uses the feature's existing milestone if found (matched by phase reference in the spec), otherwise creates a standalone no-milestone batch.
- **Single spec** — `/issues docs/specs/<feature>.md` files one issue. No milestone unless the spec references a phase.

No argument? Default to `docs/roadmap/README.md` if it exists; otherwise prompt.

## Transport: GitHub MCP first, `gh` fallback

Prefer the **GitHub MCP** (tool names starting with `mcp__github__*` or similar) for every read and write. It gives structured JSON in/out and avoids shelling out.

Detection order at skill start:
1. If `mcp__github__*` tools are available in this session, use them. Call `mcp__github__authenticate` (or the equivalent) first if the server reports unauthenticated. If the MCP tool list includes create/update/list tools for issues, milestones, and labels, run the entire skill through MCP.
2. If GitHub MCP is **not** available, or a specific action isn't exposed by the MCP, fall back to the `gh` CLI. Run `gh auth status` once; if it fails, tell the user to run `gh auth login` (their call — don't do it for them) and stop.
3. **Never mix** mid-run for the same action type. Pick one transport per session; if you start on MCP and hit a missing tool, switch everything remaining to `gh` rather than interleaving.

The MCP-equivalent operations map to these `gh` calls (shown as the fallback reference — use the MCP tool first when present):

| Operation | MCP (preferred) | `gh` fallback |
|-----------|-----------------|---------------|
| List milestones | `mcp__github__list_milestones` | `gh api "repos/{owner}/{repo}/milestones?state=all" --jq '.[]'` |
| Create milestone | `mcp__github__create_milestone` | `gh api "repos/{owner}/{repo}/milestones" -f title=... -f description=...` |
| List labels | `mcp__github__list_labels` | `gh label list --json name,color` |
| Create label | `mcp__github__create_label` | `gh label create "<name>" --color <hex>` |
| Create issue | `mcp__github__create_issue` | `gh issue create --title ... --body-file <tmp> --milestone "..." --label "..."` |
| View issue | `mcp__github__get_issue` | `gh issue view <N> --json title,state,milestone,labels,body` |
| Edit issue | `mcp__github__update_issue` | `gh issue edit <N> --title ... --add-label ... --remove-label ... --milestone ...` |
| Close issue | `mcp__github__close_issue` | `gh issue close <N> --comment "..."` |
| List issues | `mcp__github__list_issues` | `gh issue list --state all --json number,title,labels,milestone` |

If the exact MCP tool name differs from the table, use whichever MCP tool matches the operation — inspect the available MCP tools, don't hard-code the name.

## Preflight

1. **Pick transport** (above). Stop if neither works.
2. **Confirm we're in a git repo with a GitHub remote** — `git remote get-url origin` and check it's a github.com URL. If not, stop.
3. **Read the source file(s) top-to-bottom** — parse the Tasks and Slices tables, collect `Type`, `Complexity`, `Feature flag`, `Dependencies`, `Spec`, and the existing `Issue:` / `Issues:` columns.
4. **Detect already-filed issues.**
   - For each row that already has a `#<N>` in the `Issue` column, fetch the issue (MCP `get_issue` or `gh issue view`).
   - Classify each as `match` (still aligned with the source), `drift` (title/labels/milestone or body need an update), or `gone` (issue was closed or deleted).
   - Present a short summary to the user: `X rows already filed: Y match / Z drift / W gone`. Ask what to do about drift/gone rows. Options:
     - **Update in place** — patch titles/labels/milestone/body.
     - **Close + refile** — close the drifted issue with a comment pointing to its replacement, then file a fresh one and update the `Issue` column.
     - **Skip** — leave as-is (use this when the drift is intentional).
   - Rows without an `Issue` value are always new.
5. **Fetch existing milestones** — match phase filenames against existing milestone titles so reruns are idempotent.
6. **Dry-run the plan.** Before any write, print the full list of what will be created or changed — milestones, issues (title + labels + milestone), and writebacks. Ask the user to confirm before proceeding.

## Milestone shape

- **Title:** `Phase NNN — <phase-name>` (exact, copy from `docs/roadmap/NNN_<phase-name>.md`'s `# Phase NNN:` heading)
- **Description:** copy the phase's `## Context` paragraph (truncate to ~500 chars).
- **Due date:** skip unless the phase file names one.

Create via MCP `create_milestone` (preferred) or `gh api "repos/{owner}/{repo}/milestones" -f title="..." -f description="..."` (fallback).

## Issue shape

**Title patterns:**

| Source | Title |
|--------|-------|
| Roadmap task (single-file spec) | `[NNN.N] <task-name>` — e.g., `[003.2] Jira sync worker` |
| Roadmap task (sliced spec, sub-issue) | `[NNN.N.N] <slice-name>` — e.g., `[003.2.1] Jira issue-list fetcher` |
| Standalone spec slice | `[<feature>.NNN] <slice-name>` — e.g., `[atlassian.002] Confluence page index` |
| Standalone single-file spec | `<feature-name>` — e.g., `atlassian-integration` |

**Labels (apply in this order):**

- `type:<type>` — from the spec's `Type` field (one of `feat`, `fix`, `refactor`, `chore`, `test`, `docs`, `perf`, `security`).
- `complexity:low` / `complexity:med` / `complexity:high` — from the spec's `Complexity` field.
- `mvp` or `post-mvp` — derivable only from the roadmap index's MVP column. Omit when not derivable.
- `needs-spec` — if the task's spec file doesn't exist yet.
- `spec-ready` — if the spec exists and has a filled-in Verification section.
- `blocked` — if `Dependencies` names another task whose issue is still open.

**Bootstrap the labels on first run.** Via MCP `list_labels` + `create_label` (preferred) or `gh label list --json name --jq '.[].name'` + `gh label create "<name>" --color <color>` (fallback). Enumerate existing labels and create only what's missing, using this default palette:

- `type:feat` — `1d76db` (blue)
- `type:fix` — `d73a4a` (red)
- `type:refactor` — `a2eeef` (cyan)
- `type:chore` — `cccccc` (grey)
- `type:test` — `0e8a16` (green)
- `type:docs` — `0075ca` (dark blue)
- `type:perf` — `fbca04` (yellow)
- `type:security` — `b60205` (dark red)
- `complexity:low` — `c2e0c6` (light green)
- `complexity:med` — `fef2c0` (light yellow)
- `complexity:high` — `f9d0c4` (light red)
- `mvp` — `0e8a16` (green)
- `post-mvp` — `cfd3d7` (light grey)
- `needs-spec` — `e99695` (salmon)
- `spec-ready` — `c5def5` (pale blue)
- `blocked` — `b60205` (dark red)

**Body template:**

```markdown
## Context
<one-paragraph summary from the task's Context or the spec's Problem>

## Spec
- File: [<path>](<path>)
- Trunk metadata: type=<type>, flag=<flag>, complexity=<complexity>

## Files
<bullet list of files from the task's Files field>

## Dependencies
<explicit task-ids or issue #s; `None` if independent>

## Verification
```
<verification command from the spec>
```

## Acceptance Criteria
<pull Verification Criteria bullets from the spec — each becomes a `- [ ]` checklist item>

## Feature Flag
<flag name and default, or `None — slice is user-ready on merge`>

## Branch
`<type>/<issue-number>-<slug>` — created with `gh issue develop` after this issue is filed, or manually via `git checkout -b <type>/<this-issue-number>-<slug>`.

---
Filed by `/issues` from `<source-file>`.
```

Create via MCP `create_issue` (preferred; pass title/body/milestone/labels as fields) or `gh issue create --title "..." --body-file <tmp> --milestone "Phase NNN — <name>" --label "type:feat" --label "complexity:med" ...` (fallback).

## Execution mode: per-milestone confirmation

For roadmap/phase inputs, file **one milestone + its issues at a time**, in roadmap order. After each milestone batch:

1. Print the created milestone URL + issue URLs and numbers.
2. Patch the `Issue:` / `Issues:` columns in the source roadmap/spec files with the newly-minted `#<N>` values.
3. Ask: **"Proceed to Phase NNN+1?"** — halt on anything other than yes.

This keeps a broken run recoverable (stop after any batch and fix the source file) and keeps writebacks atomic per phase.

For single-spec inputs, skip the confirmation loop — file the issue(s), writeback, done.

## Writeback

After filing, update the source Markdown in place:

- **Roadmap tasks:** replace `- **Issues:** —` with `- **Issues:** #<N>` (or `#<N>, #<N+1>, ...` for sliced tasks).
- **Spec Slices table:** replace the `—` in the `Issue` column with `#<N>`.
- **Single-spec Trunk Metadata:** replace `- **Issue:** — (filled by `/issues`)` with `- **Issue:** #<N>`.

Do this with `Edit` (exact-string replace), not by rewriting the file — preserve surrounding formatting.

If a row was updated in place (not newly filed), leave the `Issue:` column alone.

## Idempotency rules

- Re-running on a fully-filed source is a no-op: dry-run shows 0 creates, 0 updates.
- Re-running after some rows were hand-closed on GitHub treats them as `gone` and offers refile/skip.
- Re-running after the source spec was edited surfaces drift for every affected row; user decides update-in-place vs. close+refile.
- Never delete issues; close them with a pointer comment instead. The user can clean up closed issues manually.

## After writing

1. Print a final summary: N milestones created, M issues created, K updated, list the URLs.
2. Suggest the next step based on what's now in place:
   - **All tasks have issues?** → "Run `/autopilot docs/roadmap/NNN_<phase>.md` to execute a phase, or `/feature docs/specs/<name>.md` to implement one task/slice."
   - **Only the first phase was filed?** → "Re-run `/issues docs/roadmap/README.md` to continue filing the remaining phases, or file per phase with `/issues docs/roadmap/NNN_<phase>.md` as you get to them."
