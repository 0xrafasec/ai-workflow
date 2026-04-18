#!/usr/bin/env bash
set -euo pipefail

# AI Workflow Uninstaller
# Removes symlinks created by install.sh and restores backups if they exist.

CLAUDE_DIR="$HOME/.claude"
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

FILES=(
    "CLAUDE.md"
    "settings.json"
    "statusline-command.sh"
    "agents/security-reviewer.md"
    "agents/architecture-reviewer.md"
    "commands/sec-review.md"
    "skills/feature/SKILL.md"
    "skills/fix/SKILL.md"
    "skills/spec/SKILL.md"
    "skills/review/SKILL.md"
    "skills/new-project/SKILL.md"
    "skills/prd/SKILL.md"
    "skills/autopilot/SKILL.md"
    "skills/roadmap/SKILL.md"
    "skills/architecture/SKILL.md"
    "skills/tdd/SKILL.md"
    "skills/security/SKILL.md"
    "skills/adr/SKILL.md"
    "skills/rfc/SKILL.md"
    "skills/commit/SKILL.md"
    "skills/pr/SKILL.md"
    "skills/design/SKILL.md"
    "skills/verify-design/SKILL.md"
    "skills/factory/SKILL.md"
    "skills/issues/SKILL.md"
    "reviews/go.md"
    "reviews/rust.md"
    "reviews/typescript.md"
    "reviews/python.md"
)

for f in "${FILES[@]}"; do
    unlink_if_symlink "$CLAUDE_DIR/$f"
done

# Extras (opt-in in install.sh via --extra). Always cleaned up on uninstall
# regardless of whether they were installed, so this is safe to run.
EXTRA_SKILLS=(
    "skills/rlabs-design"
)
for f in "${EXTRA_SKILLS[@]}"; do
    unlink_if_symlink "$CLAUDE_DIR/$f"
done

unlink_if_symlink "$BIN_DIR/aiwf"

echo ""
info "Done! Symlinks removed. Original backups restored where available."
echo ""
