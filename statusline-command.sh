#!/usr/bin/env bash
# Claude Code status line.
#
# Reads the session JSON on stdin and prints two rows:
#
#   ▸ ai-workflow  main ✚2   Opus 5  high   ctx █░░░░░░░ 7% 69k/1M  12m
#
# The dollar cost appears only on API-key billing; on a Claude.ai subscription
# the figure is notional and row 2's rate limits are the real budget.
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
# Parse — a single jq pass emitting US-separated (0x1f) fields.
#
# Not @tsv: tab is IFS whitespace, so `read` collapses runs of it and any empty
# field (no effort level, no output style, no model id) silently shifts every
# later field by one. 0x1f is not IFS whitespace, so empty fields survive.
#
# The gsub replaces the escaping @tsv gave away for free: a directory name may
# legally contain a newline, and an unescaped one makes `read` stop mid-record
# and print a truncated line.
# ---------------------------------------------------------------------------

IFS=$'\x1f' read -r \
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
        ] | map(tostring | gsub("[\n\r\t]"; " ")) | join("\u001f")' 2>/dev/null)"

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

# bar <pct> <width> [colour] — block progress bar. The filled portion is
# coloured by heat() unless an explicit colour is passed; the context bar passes
# one because it grades on absolute tokens rather than percent (see ctx_heat).
bar() {
    local pct=$1 w=$2 col=${3:-} filled i out=""
    [ "$pct" -lt 0 ] && pct=0
    [ "$pct" -gt 100 ] && pct=100
    filled=$(( pct * w / 100 ))
    # Show a sliver for any non-zero usage so "barely used" != "unused".
    [ "$filled" -eq 0 ] && [ "$pct" -gt 0 ] && filled=1
    for ((i = 0; i < w; i++)); do
        if [ "$i" -lt "$filled" ]; then out+="█"; else out+="░"; fi
    done
    [ -z "$col" ] && col=$(heat "$pct")
    printf '%s%s%s' "$col" "$out" "$RESET"
}

# ctx_heat <tokens> <window-size> — colour for the context readout.
#
# Deliberately not heat(): that grades on percent of the window, which says
# nothing useful at 1M. 150k tokens is 75% of a 200k window and 15% of a 1M one,
# yet it is the same amount of context for the model to hold in its head — so a
# percentage-graded bar sits green through an entire working session on Opus and
# only reddens when truncation is imminent, which is far too late to act on.
#
# Claude Code itself ships no "ideal context" threshold. Its only built-in
# levels are end-of-window buffers — warn at window-33k, auto-compact at
# window-13k, blocked at window-3k — which answer "am I about to run out", not
# "am I still sharp".
#
# So amber is anchored on the one first-party long-context figure in the
# product, the rate-limit attribution bucket:
#
#     long_context: `${e}% of your usage was at >150k context`
#
# That is Anthropic flagging >150k as the band that measurably costs more of
# your limit. It is a cost signal, not a quality one — do not read it as a
# published performance threshold.
#
# There is no such threshold to read. Anthropic's own context-engineering
# guidance is deliberately principle-based (context is "a finite resource with
# diminishing marginal returns"; models have an "attention budget" that "every
# new token" depletes) and names no number. Chroma's Context Rot study, the
# reference work here, declines to name one too: across 18 frontier models
# degradation is continuous and non-uniform from the start, varying by task
# rather than tripping at a boundary — it is already measurable at ~113k on
# LongMemEval.
#
# So 150k is not a cliff and nothing gets fast again below it. It is picked to
# be a useful *alert*: low enough to sit above where degradation is real,
# high enough to stay quiet on ordinary sessions. Calibrated against actual
# usage here it lands near the 75th percentile of peak session context
# (median ~99k, p75 ~156k, p90 ~286k), so it fires on the long sessions and
# not the routine ones. A signal that is always on is not a signal.
#
# Red is Claude Code's own warn level (window-33k): past there, auto-compact is
# about to take the decision away from you.
#
# Tune with CLAUDE_STATUSLINE_CTX_IDEAL (tokens).
ctx_heat() {
    local tok=$1 win=$2 ideal=${CLAUDE_STATUSLINE_CTX_IDEAL:-150000} redline

    # No usable window size — fall back to grading the percentage.
    if [ "${win:-0}" -le 0 ] 2>/dev/null; then
        heat "$3"
        return
    fi

    redline=$(( win - 33000 ))
    # Only degenerate windows (smaller than the buffer itself, via a
    # CLAUDE_CODE_MAX_CONTEXT_TOKENS override) need a fallback. Do not clamp
    # this upward in general: on a 200k window the redline is 167k, and
    # rounding it to a percentage of the window would move it off the level
    # Claude Code actually warns at.
    [ "$redline" -le 0 ] && redline=$(( win * 85 / 100 ))
    # Keep amber strictly below red on small windows.
    [ "$ideal" -ge "$redline" ] && ideal=$(( redline * 80 / 100 ))

    if   [ "$tok" -ge "$redline" ]; then printf '%s' "$HOT"
    elif [ "$tok" -ge "$ideal" ];   then printf '%s' "$WARN"
    else                                 printf '%s' "$OK"
    fi
}

# strftime for an epoch, portable across BSD (macOS) and GNU date.
#
# GNU first, for the same reason as the stat probe below: a wrong-platform flag
# that happens to exit 0 would poison every caller. GNU `date -r` means
# --reference=FILE and fails on a bare epoch, BSD `date -d` wants a DST value
# and fails on "@<epoch>", so either ordering works — but only one of them
# fails loudly, and this one is the loud one on the platform we can test.
epoch_fmt() {
    local ts=$1 fmt=$2
    date -d "@$ts" +"$fmt" 2>/dev/null && return 0
    date -r "$ts" +"$fmt" 2>/dev/null
}

# days_from_civil <y> <m> <d> -> days since 1970-01-01 (Hinnant's algorithm).
#
# Pure shell arithmetic. Used to diff two *local calendar dates*, which is what
# "is this tomorrow" actually means. Adding 86400 to an epoch does not answer
# that question: on a 23-hour spring-forward day it skips a calendar day, and on
# a 25-hour fall-back day it lands back on today.
days_from_civil() {
    local y=$((10#$1)) m=$((10#$2)) d=$((10#$3)) era yoe doy doe
    [ "$m" -le 2 ] && y=$(( y - 1 ))
    era=$(( (y >= 0 ? y : y - 399) / 400 ))
    yoe=$(( y - era * 400 ))
    doy=$(( (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1 ))
    doe=$(( yoe * 365 + yoe / 4 - yoe / 100 + doy ))
    printf '%d' $(( era * 146097 + doe - 719468 ))
}

# reset_label <reset-epoch> <now-ymd> -> "today 22:00" / "tomorrow 05:00" /
# "Mon 10 Aug 05:00"
#
# A bare weekday is ambiguous for the 7-day window: it can land up to a week
# out, so "Mon 05:00" reads as *this* Monday when it usually is not. Anchor on
# today/tomorrow when the reset is that close, and carry the full date when it
# is not.
#
# One `date` call: this runs on every status-line render, and the file's whole
# design is about not forking per field.
reset_label() {
    local reset=$1 now_ymd=$2 stamp reset_ymd hhmm long delta
    # %d not %-d: BSD strftime has no glibc '-' padding flag.
    stamp=$(epoch_fmt "$reset" '%Y-%m-%d|%H:%M|%a %d %b %H:%M')
    [ -z "$stamp" ] && return 0

    IFS='|' read -r reset_ymd hhmm long <<<"$stamp"
    if [ -z "$now_ymd" ]; then
        printf '%s' "$long"
        return 0
    fi

    delta=$(( $(days_from_civil ${reset_ymd//-/ }) - $(days_from_civil ${now_ymd//-/ }) ))
    case "$delta" in
        0) printf 'today %s' "$hhmm" ;;
        1) printf 'tomorrow %s' "$hhmm" ;;
        *) printf '%s' "$long" ;;
    esac
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

# tok_short <tokens> -> "812" / "69k" / "1M" / "1.4M"
#
# The percentage alone is unreadable on a 1M-context model: 69k tokens in reads
# as 7%, which looks broken next to a session that clearly has a lot of history
# in it. Printing the absolute count next to it makes the ratio self-evident.
tok_short() {
    local n=$1 whole frac
    if [ "$n" -ge 1000000 ]; then
        whole=$(( n / 1000000 ))
        frac=$(( (n % 1000000) / 100000 ))
        if [ "$frac" -eq 0 ]; then printf '%dM' "$whole"
        else                       printf '%d.%dM' "$whole" "$frac"
        fi
    elif [ "$n" -ge 1000 ]; then
        printf '%dk' $(( n / 1000 ))
    else
        printf '%d' "$n"
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
        # GNU first: on GNU coreutils `stat -f` means --file-system and exits 0
        # with a filesystem dump, so a BSD-first probe never falls through.
        cache_mtime=$(stat -c %Y "$git_cache" 2>/dev/null || stat -f %m "$git_cache" 2>/dev/null)
        case "$cache_mtime" in
            ''|*[!0-9]*) cache_mtime=0 ;;
        esac
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

# Context window.
#
# ctx_pct is context_window.used_percentage straight from the payload — the same
# figure Claude Code computes for itself, round((input + cache_creation +
# cache_read) / context_window_size * 100). Do not re-derive it from the token
# fields: the denominator is not a constant (200k, 1M, or a
# CLAUDE_CODE_MAX_CONTEXT_TOKENS override, decided per session) and guessing it
# is exactly how this readout goes wrong.
if [ -n "$ctx_pct" ]; then
    # Graded on absolute tokens, so the colour means "still sharp / past the
    # recommended range / about to be compacted" rather than "fraction full".
    ctx_col=$(ctx_heat "${in_tok:-0}" "${ctx_size:-0}" "$ctx_pct")
    if [ "$width" -ge 80 ]; then
        row1+="${SEP}${LABEL}ctx${RESET} $(bar "$ctx_pct" 8 "$ctx_col") ${ctx_col}${ctx_pct}%${RESET}"
    else
        row1+="${SEP}${LABEL}ctx${RESET} ${ctx_col}${ctx_pct}%${RESET}"
    fi
    # Absolute counts, so a low percentage on a 1M window is legible as "69k of
    # 1M" rather than an implausible-looking 7%.
    if [ "$width" -ge 100 ] && [ "${ctx_size:-0}" -gt 0 ] 2>/dev/null; then
        row1+=" ${DIM}$(tok_short "${in_tok:-0}")/$(tok_short "$ctx_size")${RESET}"
    fi
fi

# Cost — only on usage-based billing.
#
# cost.total_cost_usd is always populated, but on a Claude.ai subscription it is
# a notional API-list-price valuation of the tokens, not money owed: the plan is
# a flat fee and what actually constrains you is the rate limits in row 2. Shown
# next to a $100/mo plan the figure reads as a bill and badly misleads — a
# session can show $139 while sitting at 23% of the 5h window.
#
# Claude Code's own /cost does exactly this: for subscribers it prints "You are
# currently using your subscription to power your Claude Code usage" and never
# renders a dollar amount, falling through to the "Total cost:" block only on
# API-key billing. Match that.
#
# rate_limits is the documented discriminator — "only present for subscribers
# after first API response" — and parses to -1 here when absent.
on_subscription=0
[ "${h5_pct:--1}" -ge 0 ] 2>/dev/null && on_subscription=1
[ "${d7_pct:--1}" -ge 0 ] 2>/dev/null && on_subscription=1

if [ "$on_subscription" = "0" ] && [ -n "$cost" ] && [ "$cost" != "0" ]; then
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

# Both segments share one clock read — two `date` forks per render, not one per
# segment per field.
read -r now_epoch now_ymd <<<"$(date '+%s %Y-%m-%d')"

# limit_segment <label> <used-pct> <resets-at-epoch>
limit_segment() {
    local label=$1 pct=$2 reset=$3 seg eta when
    [ -z "$pct" ] && return 0
    [ "$pct" -lt 0 ] 2>/dev/null && return 0

    seg="${LABEL}${label}${RESET}"
    [ "$width" -ge 70 ] && seg+=" $(bar "$pct" 8)"
    seg+=" $(heat "$pct")$(printf '%3d%%' "$pct")${RESET}"

    if [ -n "$reset" ] && [ "$reset" -gt 0 ] 2>/dev/null; then
        eta=$(( reset - now_epoch ))
        when=$(reset_label "$reset" "$now_ymd")
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
