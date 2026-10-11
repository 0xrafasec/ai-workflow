#!/usr/bin/env bash
# SessionStart hook: fetch the current branch's remote and tell Claude when the
# branch is behind it or has diverged. Prints nothing when there is nothing to
# say, never prompts for credentials, and always exits 0 so it cannot block a
# session.

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null) || exit 0
remote=${upstream%%/*}

GIT_TERMINAL_PROMPT=0 \
GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o BatchMode=yes -o ConnectTimeout=5" \
    git fetch --quiet "$remote" >/dev/null 2>&1 || exit 0

counts=$(git rev-list --left-right --count "HEAD...$upstream" 2>/dev/null) || exit 0
ahead=${counts%%[!0-9]*}
behind=${counts##*[!0-9]}
[ "${behind:-0}" -gt 0 ] || exit 0

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "${ahead:-0}" -gt 0 ]; then
    echo "git: '$branch' has diverged from $upstream ($ahead ahead, $behind behind). Reconcile before building; never force-push over the remote commits."
else
    echo "git: '$branch' is $behind commit(s) behind $upstream. Pull before starting work."
fi
exit 0
