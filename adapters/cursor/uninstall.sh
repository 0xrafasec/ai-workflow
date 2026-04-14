#!/usr/bin/env bash
set -euo pipefail

# AI Workflow — Cursor Adapter Uninstaller
# Removes all aiwf-*.mdc rule files from ~/.cursor/rules/

CURSOR_RULES_DIR="${CURSOR_RULES_DIR:-$HOME/.cursor/rules}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

echo ""
echo "=== AI Workflow — Cursor Uninstaller ==="
echo ""

if [ ! -d "$CURSOR_RULES_DIR" ]; then
    warn "Rules dir not found: $CURSOR_RULES_DIR — nothing to remove"
    exit 0
fi

count=0
for f in "$CURSOR_RULES_DIR"/aiwf-*.mdc; do
    [ -f "$f" ] || continue
    rm "$f"
    info "Removed $f"
    count=$((count + 1))
done

echo ""
if [ "$count" -eq 0 ]; then
    warn "No aiwf-*.mdc files found — nothing removed"
else
    info "Removed $count file(s)."
fi
echo ""
