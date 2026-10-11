#!/usr/bin/env bash
set -euo pipefail

# AI Workflow Uninstaller
# Removes symlinks created by install.sh and restores backups if they exist.
# The plugin itself is removed with `claude plugin uninstall wf@ai-workflow`.
#
# CLAUDE_DIR selects which Claude config dir to clean (default ~/.claude), and
# must match the one install.sh was run against. Only symlinks are removed, so
# a profile that kept its own settings.json (install.sh --no-settings) is left
# untouched.

# Resolve a directory to its canonical form so that ~/.claude, ~/.claude/,
# ~/./.claude and a symlinked ~/.claude all compare equal. The primary-dir
# comparison below decides whether settings.json is shared, so a spelling
# difference must never flip it.
canonical_dir() {
    local d="${1%/}"
    [ -z "$d" ] && d="/"
    if [ -d "$d" ]; then (cd -P "$d" && pwd); else printf '%s\n' "$d"; fi
}

PRIMARY_CLAUDE_DIR="$(canonical_dir "$HOME/.claude")"
CLAUDE_DIR="$(canonical_dir "${CLAUDE_DIR:-$HOME/.claude}")"
BIN_DIR="${AIWF_BIN_DIR:-$HOME/.local/bin}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

unlink_if_symlink() {
    local target="$1"
    if [ -L "$target" ]; then
        rm "$target"
        info "Removed symlink: $target"

        # Restore most recent backup if one exists
        local latest_backup
        latest_backup=$(ls -t "${target}.bak."* 2>/dev/null | head -1 || true)
        if [ -n "$latest_backup" ]; then
            mv "$latest_backup" "$target"
            warn "Restored backup: $latest_backup -> $target"
        fi
    fi
}

echo ""
echo "=== AI Workflow Uninstaller ==="
echo ""

for f in CLAUDE.md settings.json statusline-command.sh skills/rlabs-design; do
    unlink_if_symlink "$CLAUDE_DIR/$f"
done

# Before the toolkit became a plugin, install.sh symlinked every skill, agent,
# command and review guide into the config dir. Sweep any of those that still
# point into this clone, so upgrading does not leave them shadowing the plugin.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for dir in skills agents commands reviews; do
    [ -d "$CLAUDE_DIR/$dir" ] || continue
    while IFS= read -r -d '' link; do
        case "$(readlink "$link")" in
            "$SCRIPT_DIR"/*) rm "$link"; info "Removed legacy symlink: $link" ;;
        esac
    done < <(find "$CLAUDE_DIR/$dir" -type l -print0)
    find "$CLAUDE_DIR/$dir" -depth -type d -empty -delete
done

# The aiwf launcher no longer exists; remove the link an older install left.
if [ "$CLAUDE_DIR" = "$PRIMARY_CLAUDE_DIR" ]; then
    unlink_if_symlink "$BIN_DIR/aiwf"
fi

echo ""
info "Done! Symlinks removed. Original backups restored where available."
