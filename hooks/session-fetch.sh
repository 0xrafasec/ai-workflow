#!/usr/bin/env bash
# SessionStart hook: fetch the current branch's remote and tell Claude when the
# branch is behind it or has diverged. Prints nothing when there is nothing to
# say, never prompts for credentials, and always exits 0 so it cannot block a
# session.
#
# The repository may not be trusted, so two things are deliberate:
#   - git runs with every config key that names a program to execute pinned
#     (fsmonitor, hooks, ssh, proxy, askpass, credential helpers, upload-pack,
#     the ext:: transport), so a hostile .git/config cannot run code here;
#   - the message contains only numbers. Branch and remote names come from the
#     repository and would land in Claude's context, so they are never printed.

g() {
    GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true SSH_ASKPASS=true \
    GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=5" \
    git -c core.fsmonitor=false -c core.hooksPath=/dev/null -c core.gitProxy= \
        -c credential.helper= -c protocol.ext.allow=never "$@"
}

g rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
branch=$(g symbolic-ref --quiet --short HEAD 2>/dev/null) || exit 0
remote=$(g config --get "branch.$branch.remote" 2>/dev/null) || exit 0
[ -n "$remote" ] && [ "$remote" != "." ] || exit 0

g fetch --quiet --no-recurse-submodules --upload-pack=git-upload-pack "$remote" >/dev/null 2>&1 || exit 0

counts=$(g rev-list --left-right --count 'HEAD...@{u}' 2>/dev/null) || exit 0
ahead=${counts%%[!0-9]*}
behind=${counts##*[!0-9]}
case "$ahead$behind" in ''|*[!0-9]*) exit 0 ;; esac
[ "$behind" -gt 0 ] || exit 0

if [ "$ahead" -gt 0 ]; then
    echo "git: the current branch has diverged from its upstream ($ahead ahead, $behind behind). Reconcile before building; never force-push over the remote commits."
else
    echo "git: the current branch is $behind commit(s) behind its upstream. Pull before starting work."
fi
exit 0
