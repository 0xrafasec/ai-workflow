#!/usr/bin/env bash
set -euo pipefail

# AI Workflow Installer
# Symlinks this repo's config files into ~/.claude/ so changes stay in sync.
#
# Usage:
#   ./install.sh                    Install everything
#   ./install.sh settings.json      Install only matching target(s)
#   ./install.sh settings.json CLAUDE.md skills/feature/SKILL.md
#
# A filter matches a target if it equals the source path, the destination
# path, or the basename of either. This lets you refresh one file without
# re-linking every skill and agent.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

FILTERS=("$@")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
skip()  { echo -e "${YELLOW}[-]${NC} skip $1"; }

# Returns 0 (install) if no filters given, or if any filter matches the entry.
# Matches on: exact src path, exact dst path, basename of src, basename of dst.
should_install() {
    local src="$1"
    local dst="$2"

    if [ ${#FILTERS[@]} -eq 0 ]; then
        return 0
    fi

    local src_base="${src##*/}"
    local dst_base="${dst##*/}"
    local f
    for f in "${FILTERS[@]}"; do
        if [ "$f" = "$src" ] || [ "$f" = "$dst" ] \
           || [ "$f" = "$src_base" ] || [ "$f" = "$dst_base" ]; then
            return 0
        fi
    done
    return 1
}

backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.bak.$(date +%s)"
        warn "Backing up existing $target -> $backup"
        mv "$target" "$backup"
    elif [ -L "$target" ]; then
        rm "$target"
    fi
}

link() {
    local src_rel="$1"
    local dst_rel="$2"
    local src="$SCRIPT_DIR/$src_rel"
    local dst="$CLAUDE_DIR/$dst_rel"

    if ! should_install "$src_rel" "$dst_rel"; then
        return 0
    fi

    MATCHED=$((MATCHED + 1))

    if [ ! -e "$src" ]; then
        error "Source not found: $src"
        return 1
    fi

    mkdir -p "$(dirname "$dst")"
    backup_if_exists "$dst"
    ln -sf "$src" "$dst"
    info "Linked $dst -> $src"
}

echo ""
echo "=== AI Workflow Installer ==="
echo ""
if [ ${#FILTERS[@]} -eq 0 ]; then
    echo "This will symlink ALL config files from:"
else
    echo "This will symlink filtered targets (${FILTERS[*]}) from:"
fi
echo "  $SCRIPT_DIR"
echo "into:"
echo "  $CLAUDE_DIR"
echo ""

MATCHED=0

# Ensure ~/.claude exists
mkdir -p "$CLAUDE_DIR"/{agents,commands,skills}

# Global config
link "CLAUDE.md"                "CLAUDE.md"
link "settings.json"            "settings.json"
link "statusline-command.sh"    "statusline-command.sh"

# Agents
link "agents/security-reviewer.md"      "agents/security-reviewer.md"
link "agents/architecture-reviewer.md"   "agents/architecture-reviewer.md"

# Commands
link "commands/sec-review.md"   "commands/sec-review.md"

# Skills
for skill in feature fix spec review new-project prd autopilot code-review roadmap architecture tdd security adr rfc commit pr design; do
    mkdir -p "$CLAUDE_DIR/skills/$skill"
    link "skills/$skill/SKILL.md" "skills/$skill/SKILL.md"
done

# Language-specific review guides
mkdir -p "$CLAUDE_DIR/reviews"
for guide in go rust typescript python; do
    link "reviews/$guide.md" "reviews/$guide.md"
done

echo ""
if [ ${#FILTERS[@]} -gt 0 ] && [ "$MATCHED" -eq 0 ]; then
    error "No targets matched filter(s): ${FILTERS[*]}"
    exit 1
fi
info "Done! $MATCHED target(s) linked."
info "Edit files in $SCRIPT_DIR and changes apply to ~/.claude/ automatically."
echo ""
