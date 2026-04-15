#!/usr/bin/env bash
set -euo pipefail

# AI Workflow bootstrap — clones the repo and installs the toolkit.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/0xrafasec/ai-workflow/main/bootstrap.sh | bash
#
# Pin to a specific release:
#   curl -fsSL https://raw.githubusercontent.com/0xrafasec/ai-workflow/main/bootstrap.sh \
#     | AIWF_REF=v0.1.0 bash
#
# Environment:
#   AIWF_REPO_URL    Override repo URL (default: public GitHub HTTPS).
#   AIWF_INSTALL_DIR Override install dir (default: ~/.local/share/ai-workflow).
#   AIWF_BIN_DIR     Override bin dir     (default: ~/.local/bin).
#   AIWF_REF         Branch or tag to check out (default: main).

REPO_URL="${AIWF_REPO_URL:-https://github.com/0xrafasec/ai-workflow.git}"
INSTALL_DIR="${AIWF_INSTALL_DIR:-$HOME/.local/share/ai-workflow}"
BIN_DIR="${AIWF_BIN_DIR:-$HOME/.local/bin}"
REF="${AIWF_REF:-main}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1" >&2; }

command -v git  >/dev/null 2>&1 || { error "git is required";  exit 1; }
command -v bash >/dev/null 2>&1 || { error "bash is required"; exit 1; }

echo ""
echo "=== AI Workflow Bootstrap ==="
echo ""
info "Repo:        $REPO_URL"
info "Install dir: $INSTALL_DIR"
info "Bin dir:     $BIN_DIR"
info "Ref:         $REF"
echo ""

if [ -d "$INSTALL_DIR/.git" ]; then
    info "Existing clone found — fetching and checking out $REF"
    git -C "$INSTALL_DIR" fetch --quiet origin --tags
    git -C "$INSTALL_DIR" checkout --quiet "$REF"
    # Only fast-forward if we're on a branch (tags are detached HEAD).
    if git -C "$INSTALL_DIR" symbolic-ref -q HEAD >/dev/null; then
        git -C "$INSTALL_DIR" pull --ff-only --quiet \
            || warn "Could not fast-forward — leaving working tree as-is"
    fi
else
    info "Cloning into $INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
    git -C "$INSTALL_DIR" fetch --quiet --tags
    git -C "$INSTALL_DIR" checkout --quiet "$REF"
fi

chmod +x \
    "$INSTALL_DIR/aiwf" \
    "$INSTALL_DIR/install.sh" \
    "$INSTALL_DIR/uninstall.sh" \
    "$INSTALL_DIR/adapters/cursor/install.sh" \
    "$INSTALL_DIR/adapters/cursor/uninstall.sh" \
    "$INSTALL_DIR/adapters/codex/install.sh" \
    "$INSTALL_DIR/adapters/codex/uninstall.sh"

info "Linking aiwf into $BIN_DIR"
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/aiwf" "$BIN_DIR/aiwf"

# --- Claude Code (always) ----------------------------------------------------
info "Running 'aiwf install' (Claude Code)"
AIWF_INSTALL_DIR="$INSTALL_DIR" "$INSTALL_DIR/aiwf" install

# --- Cursor (if detected) ----------------------------------------------------
if command -v cursor >/dev/null 2>&1 || [ -d "$HOME/.cursor" ]; then
    info "Cursor detected — running 'aiwf install-cursor'"
    AIWF_INSTALL_DIR="$INSTALL_DIR" "$INSTALL_DIR/aiwf" install-cursor
else
    warn "Cursor not detected — skipping (run 'aiwf install-cursor' manually if needed)"
fi

# --- Codex CLI (if detected) -------------------------------------------------
if command -v codex >/dev/null 2>&1 || [ -d "$HOME/.codex" ]; then
    info "Codex CLI detected — running 'aiwf install-codex'"
    AIWF_INSTALL_DIR="$INSTALL_DIR" "$INSTALL_DIR/aiwf" install-codex
else
    warn "Codex CLI not detected — skipping (run 'aiwf install-codex' manually if needed)"
fi

echo ""
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR is not in your PATH. Add this to your shell profile:"
       echo "    export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

echo ""
info "Done. Try:"
echo "  aiwf status           # verify install across all platforms"
echo "  aiwf update           # pull latest (then re-run install-all to refresh)"
echo "  aiwf install-all      # install/refresh for Claude + Cursor + Codex"
echo "  aiwf help             # see all commands"
echo ""
