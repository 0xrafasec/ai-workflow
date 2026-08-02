#!/usr/bin/env bash
# Claude Code status line.
#
# Reads the session JSON on stdin and prints two rows:
#
#   ▸ ai-workflow  main ✚2   Opus 5 (1M)  high   ███░░░░░  6%  $0.76  12m
#   5h ██░░░░░░  1% ↻ Sun 22:00 (4h39m)   7d ██░░░░░░ 18% ↻ Mon 05:00 (11h39m)
#
# The second row is the point of this script: rate limits are shown with the
# weekday + local clock time they reset, plus a countdown, so you can tell at a
# glance whether to keep going or wait it out.
#
# Design notes
#   - One jq pass. The status line re-runs on every event (debounced 300ms) and
#     is cancelled if it is still running when the next update lands, so forking
#     jq a dozen times is the difference between a live bar and a stale one.
#   - Degrades by terminal width using $COLUMNS (Claude Code >= 2.1.153).
#   - Honours NO_COLOR, and drops colour when stdout is redirected.
#   - Never exits non-zero and never prints a partial line: a broken status line
#     is worse than a plain one.
#
# Set a refreshInterval in settings.json so the countdown stays live while the
# session is idle:
#   "statusLine": { "type": "command",
#                   "command": "bash ~/.claude/statusline-command.sh",
#                   "refreshInterval": 30 }

input=$(cat)

# Bail out early to a minimal line if the payload is unusable.
if [ -z "$input" ] || ! command -v jq >/dev/null 2>&1; then
    echo "claude"
    exit 0
fi

# ---------------------------------------------------------------------------
# Palette
# ---------------------------------------------------------------------------
# 256-colour codes, chosen to stay legible on dark and light terminals.

# Claude Code captures stdout rather than attaching a tty, so a tty test would
# disable colour exactly when we want it. Only NO_COLOR turns it off.
if [ -n "${NO_COLOR:-}" ]; then
    COLOR=0
else
    COLOR=1
fi

c() { # c <256-colour-code> -> escape sequence (empty when colour is off)
    [ "$COLOR" = "1" ] && printf '\033[38;5;%sm' "$1"
}
b() { # bold
    [ "$COLOR" = "1" ] && printf '\033[1m'
}
RESET=$([ "$COLOR" = "1" ] && printf '\033[0m')

DIM=$(c 245)        # separators, secondary text
DIR_C=$(c 39)       # cyan   — directory
GIT_C=$(c 141)      # purple — branch
GIT_DIRTY=$(c 215)  # orange — uncommitted work
MODEL_C=$(c 208)    # amber  — model
EFFORT_C=$(c 244)   # grey   — effort / mode flags
COST_C=$(c 78)      # green  — money
TIME_C=$(c 244)     # grey   — duration
RESET_C=$(c 117)    # blue   — reset timestamps
LABEL=$(c 250)      # labels (5h, 7d, ctx)

OK=$(c 78)          # green  — healthy
WARN=$(c 221)       # yellow — getting full
HOT=$(c 203)        # red    — nearly exhausted

SEP=" ${DIM}·${RESET} "

# ---------------------------------------------------------------------------
# Parse — a single jq pass emitting tab-separated fields
# ---------------------------------------------------------------------------

IFS=$'\t' read -r \
    model_name model_id cur_dir proj_dir top_cwd \
    ctx_pct ctx_size in_tok out_tok \
    cost dur_ms lines_add lines_del \
    h5_pct h5_reset d7_pct d7_reset \
    effort fast thinking style over200k \
    <<<"$(printf '%s' "$input" | jq -r '
        [ .model.display_name // "",
          .model.id // "",
          .workspace.current_dir // "",
          .workspace.project_dir // "",
          .cwd // "",
          (.context_window.used_percentage // 0 | floor),
          .context_window.context_window_size // 0,
          .context_window.total_input_tokens // 0,
          .context_window.total_output_tokens // 0,
          .cost.total_cost_usd // 0,
          .cost.total_duration_ms // 0,
          .cost.total_lines_added // 0,
          .cost.total_lines_removed // 0,
          (.rate_limits.five_hour.used_percentage // -1 | floor),
          .rate_limits.five_hour.resets_at // 0,
          (.rate_limits.seven_day.used_percentage // -1 | floor),
          .rate_limits.seven_day.resets_at // 0,
          .effort.level // "",
          (.fast_mode // false | tostring),
          (.thinking.enabled // false | tostring),
          .output_style.name // "",
          (.exceeds_200k_tokens // false | tostring)
        ] | @tsv' 2>/dev/null)"

# If jq failed the fields are empty — fall back rather than print garbage.
if [ -z "$model_name" ] && [ -z "$cur_dir" ] && [ -z "$top_cwd" ]; then
    echo "claude"
    exit 0
fi

width=${COLUMNS:-100}
[ "$width" -lt 20 ] 2>/dev/null && width=100

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Colour for a 0-100 utilisation value: green -> yellow -> red.
heat() {
    local pct=$1
    if   [ "$pct" -ge 90 ]; then printf '%s' "$HOT"
    elif [ "$pct" -ge 70 ]; then printf '%s' "$WARN"
    else                         printf '%s' "$OK"
    fi
}

# bar <pct> <width> — block progress bar, filled portion coloured by heat.
bar() {
    local pct=$1 w=$2 filled i out=""
    [ "$pct" -lt 0 ] && pct=0
    [ "$pct" -gt 100 ] && pct=100
    filled=$(( pct * w / 100 ))
    # Show a sliver for any non-zero usage so "barely used" != "unused".
    [ "$filled" -eq 0 ] && [ "$pct" -gt 0 ] && filled=1
    for ((i = 0; i < w; i++)); do
        if [ "$i" -lt "$filled" ]; then out+="█"; else out+="░"; fi
    done
    printf '%s%s%s' "$(heat "$pct")" "$out" "$RESET"
}

# strftime for an epoch, portable across BSD (macOS) and GNU date.
epoch_fmt() {
    local ts=$1 fmt=$2
    if date -r "$ts" +"$fmt" 2>/dev/null; then
        return 0
    fi
    date -d "@$ts" +"$fmt" 2>/dev/null
}

# human_eta <seconds> -> "4h39m" / "39m" / "<1m"
human_eta() {
    local s=$1 h m
    [ "$s" -le 0 ] && { printf 'now'; return; }
    h=$(( s / 3600 ))
    m=$(( (s % 3600) / 60 ))
    if   [ "$h" -gt 0 ]; then printf '%dh%02dm' "$h" "$m"
    elif [ "$m" -gt 0 ]; then printf '%dm' "$m"
    else                      printf '<1m'
    fi
}

# ---------------------------------------------------------------------------
# Row 1 — where you are, what you're driving, what it costs
# ---------------------------------------------------------------------------

# Prefer the directory actually being worked in. project_dir can point at the
# session root (e.g. $HOME) which makes every project look identically named.
lookup_dir="${cur_dir:-${top_cwd:-$proj_dir}}"
dir_label=$(basename "$lookup_dir" 2>/dev/null)
[ "$lookup_dir" = "$HOME" ] && dir_label="~"

row1="${DIR_C}$(b)${dir_label}${RESET}"

# Git: branch + dirty count. Cached for 3s — git status is the slowest thing
# here and this script runs on every keystroke-ish event.
if [ -n "$lookup_dir" ] && [ -d "$lookup_dir" ]; then
    git_cache="${TMPDIR:-/tmp}/.claude-statusline-git-$(id -u)-$(printf '%s' "$lookup_dir" | cksum | cut -d' ' -f1)"
    now_s=$(date +%s)
    cache_age=999
    if [ -f "$git_cache" ]; then
        cache_mtime=$(stat -f %m "$git_cache" 2>/dev/null || stat -c %Y "$git_cache" 2>/dev/null || echo 0)
        cache_age=$(( now_s - cache_mtime ))
    fi
    if [ "$cache_age" -lt 3 ]; then
        git_info=$(cat "$git_cache" 2>/dev/null)
    else
        git_branch=$(git -C "$lookup_dir" branch --show-current 2>/dev/null)
        if [ -n "$git_branch" ]; then
            git_dirty=$(git -C "$lookup_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            git_info="${git_branch}	${git_dirty}"
        else
            git_info=""
        fi
        printf '%s' "$git_info" > "$git_cache" 2>/dev/null
    fi
    if [ -n "$git_info" ]; then
        IFS=$'\t' read -r git_branch git_dirty <<<"$git_info"
        row1+="${SEP}${GIT_C}${git_branch}${RESET}"
        if [ -n "$git_dirty" ] && [ "$git_dirty" -gt 0 ] 2>/dev/null; then
            row1+=" ${GIT_DIRTY}✚${git_dirty}${RESET}"
        fi
    fi
fi

# Model — trim the noisy "(1M context)" suffix down to "(1M)".
model_short=${model_name/ context/}
[ -n "$model_short" ] && row1+="${SEP}${MODEL_C}${model_short}${RESET}"

# Mode flags: effort, fast mode, non-default output style.
flags=""
[ -n "$effort" ] && [ "$effort" != "null" ] && flags+=" ${effort}"
[ "$fast" = "true" ] && flags+=" ⚡"
[ -n "$style" ] && [ "$style" != "default" ] && flags+=" ${style}"
[ -n "$flags" ] && row1+="${SEP}${EFFORT_C}${flags# }${RESET}"

# Context window
if [ -n "$ctx_pct" ]; then
    if [ "$width" -ge 80 ]; then
        row1+="${SEP}${LABEL}ctx${RESET} $(bar "$ctx_pct" 8) $(heat "$ctx_pct")${ctx_pct}%${RESET}"
    else
        row1+="${SEP}${LABEL}ctx${RESET} $(heat "$ctx_pct")${ctx_pct}%${RESET}"
    fi
fi

# Cost — taken straight from the payload, not re-derived from token counts.
if [ -n "$cost" ] && [ "$cost" != "0" ]; then
    cost_fmt=$(printf '$%.2f' "$cost" 2>/dev/null)
    [ "$cost_fmt" = "\$0.00" ] && cost_fmt=$(printf '$%.3f' "$cost" 2>/dev/null)
    row1+="${SEP}${COST_C}${cost_fmt}${RESET}"
fi

# Wall-clock session duration
if [ -n "$dur_ms" ] && [ "$dur_ms" -gt 0 ] 2>/dev/null; then
    total_s=$(( dur_ms / 1000 ))
    if [ "$total_s" -ge 3600 ]; then
        dur_fmt=$(printf '%dh%02dm' $(( total_s / 3600 )) $(( (total_s % 3600) / 60 )))
    else
        dur_fmt=$(printf '%dm' $(( total_s / 60 )))
    fi
    row1+="${SEP}${TIME_C}${dur_fmt}${RESET}"
fi

# Lines changed, when there are any and there's room for them.
if [ "$width" -ge 110 ]; then
    if [ "${lines_add:-0}" -gt 0 ] 2>/dev/null || [ "${lines_del:-0}" -gt 0 ] 2>/dev/null; then
        row1+="${SEP}${OK}+${lines_add}${RESET}${DIM}/${RESET}${HOT}-${lines_del}${RESET}"
    fi
fi

echo -e "$row1"

# ---------------------------------------------------------------------------
# Row 2 — rate limits, with the day + hour they reset
# ---------------------------------------------------------------------------

# limit_segment <label> <used-pct> <resets-at-epoch>
limit_segment() {
    local label=$1 pct=$2 reset=$3 seg now eta when
    [ -z "$pct" ] && return 0
    [ "$pct" -lt 0 ] 2>/dev/null && return 0

    seg="${LABEL}${label}${RESET}"
    [ "$width" -ge 70 ] && seg+=" $(bar "$pct" 8)"
    seg+=" $(heat "$pct")$(printf '%3d%%' "$pct")${RESET}"

    if [ -n "$reset" ] && [ "$reset" -gt 0 ] 2>/dev/null; then
        now=$(date +%s)
        eta=$(( reset - now ))
        # Weekday + 24h local time: the "day and hour" the allowance returns.
        when=$(epoch_fmt "$reset" '%a %H:%M')
        if [ -n "$when" ]; then
            seg+=" ${DIM}↻${RESET} ${RESET_C}${when}${RESET}"
            [ "$width" -ge 90 ] && seg+=" ${DIM}($(human_eta "$eta"))${RESET}"
        fi
    fi
    printf '%s' "$seg"
}

row2=""
h5_seg=$(limit_segment "5h" "$h5_pct" "$h5_reset")
d7_seg=$(limit_segment "7d" "$d7_pct" "$d7_reset")

[ -n "$h5_seg" ] && row2="$h5_seg"
if [ -n "$d7_seg" ]; then
    [ -n "$row2" ] && row2+="${DIM}   ${RESET}"
    row2+="$d7_seg"
fi

# Only print a second row when the API actually reported limits (absent on
# API-key billing, where there is nothing to reset).
[ -n "$row2" ] && echo -e "$row2"

exit 0
