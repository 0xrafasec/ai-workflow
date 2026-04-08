#!/usr/bin/env bash
# Claude Code status line script
# Receives JSON on stdin; outputs a single status line string.

input=$(cat)

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // empty')

# --- Context window usage ---
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# --- Rate limits ---
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# --- Working directory / project name ---
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')
if [ -n "$project_dir" ]; then
  dir_label=$(basename "$project_dir")
elif [ -n "$cwd" ]; then
  dir_label=$(basename "$cwd")
fi

# --- Git branch ---
lookup_dir="${project_dir:-$cwd}"
if [ -n "$lookup_dir" ]; then
  git_branch=$(git -C "$lookup_dir" branch --show-current 2>/dev/null)
fi

# --- Estimated session cost ---
# Pricing approximation (USD per 1M tokens) — adjust if model changes.
# Defaults to claude-sonnet-4 pricing: $3 input / $15 output.
in_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
if command -v bc &>/dev/null; then
  cost=$(echo "scale=4; ($in_tok * 3 + $out_tok * 15) / 1000000" | bc 2>/dev/null)
  if [ -n "$cost" ] && [ "$cost" != "0" ] && [ "$cost" != ".0000" ]; then
    cost_label=$(printf '$%.4f' "$cost")
  fi
fi

# --- Todo / pending task count ---
session_id=$(echo "$input" | jq -r '.session_id // empty')
todo_file="$HOME/.claude/todos/${session_id}.json"
if [ -n "$session_id" ] && [ -f "$todo_file" ]; then
  pending=$(jq '[.[] | select(.status == "pending")] | length' "$todo_file" 2>/dev/null)
  [ -n "$pending" ] && [ "$pending" -gt 0 ] && todo_label="tasks:${pending}"
fi

# --- Assemble output ---
out=""

[ -n "$dir_label" ] && out="${dir_label}"
[ -n "$git_branch" ] && out="${out}:${git_branch}"

[ -n "$model" ] && out="${out:+$out | }${model}"
[ -n "$used" ] && out="${out} | ctx:$(printf '%.0f' "$used")%"
[ -n "$cost_label" ] && out="${out} | ${cost_label}"
[ -n "$todo_label" ] && out="${out} | ${todo_label}"
[ -n "$five" ] && out="${out} | 5h:$(printf '%.0f' "$five")%"
[ -n "$week" ] && out="${out} | 7d:$(printf '%.0f' "$week")%"

echo "$out"
