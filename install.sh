#!/usr/bin/env bash
set -euo pipefail

# AI Workflow Installer
# Symlinks this repo's config files into ~/.claude/ so changes stay in sync.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

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
    local src="$SCRIPT_DIR/$1"
    local dst="$CLAUDE_DIR/$2"

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
echo "This will symlink config files from:"
echo "  $SCRIPT_DIR"
echo "into:"
echo "  $CLAUDE_DIR"
echo ""

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
for skill in feature spec review new-project prd autopilot code-review; do
    mkdir -p "$CLAUDE_DIR/skills/$skill"
    link "skills/$skill/SKILL.md" "skills/$skill/SKILL.md"
done

# Language-specific review guides
mkdir -p "$CLAUDE_DIR/reviews"
for guide in go rust typescript python; do
    link "reviews/$guide.md" "reviews/$guide.md"
done

echo ""
info "Done! All config files are now symlinked."
info "Edit files in $SCRIPT_DIR and changes apply to ~/.claude/ automatically."
echo ""
