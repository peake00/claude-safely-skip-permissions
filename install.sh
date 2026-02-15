#!/bin/bash
set -e

HOOK_DIR="$HOME/.claude/hooks"
HOOK_FILE="$HOOK_DIR/block-rm.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"
REPO_URL="https://raw.githubusercontent.com/jepeake/claude-safely-skip-permissions/main"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { echo -e "${BOLD}$1${RESET}"; }
ok()    { echo -e "${GREEN}$1${RESET}"; }
err()   { echo -e "${RED}$1${RESET}" >&2; }

# --- Check dependencies ---
if ! command -v jq &>/dev/null; then
  err "Error: jq is required but not installed."
  echo "  brew install jq  (macOS)"
  echo "  sudo apt install jq  (Linux)"
  exit 1
fi

# --- Install hook script ---
mkdir -p "$HOOK_DIR"

# If running from local repo, copy from there; otherwise download
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/block-rm.sh" ]; then
  cp "$SCRIPT_DIR/block-rm.sh" "$HOOK_FILE"
else
  curl -fsSL "$REPO_URL/block-rm.sh" -o "$HOOK_FILE"
fi
chmod +x "$HOOK_FILE"

# --- Update settings.json ---
HOOK_ENTRY='{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/hooks/block-rm.sh"
    }
  ]
}'

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "{}" > "$SETTINGS_FILE"
fi

SETTINGS=$(cat "$SETTINGS_FILE")

# Merge hook into existing settings
SETTINGS=$(echo "$SETTINGS" | jq --argjson hook "$HOOK_ENTRY" '
  .hooks.PreToolUse = (.hooks.PreToolUse // []) + [$hook]
')
echo "$SETTINGS" | jq '.' > "$SETTINGS_FILE"

# --- Add shell function ---

SHELL_FUNC='
# claude-safely-skip-permissions
claude() {
  local args=()
  local safe_mode=false
  for arg in "$@"; do
    if [[ "$arg" == "--safely-skip-permissions" ]]; then
      safe_mode=true
      args+=("--dangerously-skip-permissions")
    else
      args+=("$arg")
    fi
  done
  if $safe_mode; then
    CLAUDE_SAFE_MODE=1 command claude "${args[@]}"
  else
    command claude "${args[@]}"
  fi
}'

# Detect shell config file
if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "$(which zsh 2>/dev/null)" ] || [ "$SHELL" = "/bin/zsh" ]; then
  RC_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "$(which bash 2>/dev/null)" ] || [ "$SHELL" = "/bin/bash" ]; then
  RC_FILE="$HOME/.bashrc"
else
  RC_FILE="$HOME/.profile"
fi

# Follow symlinks to edit the real file
if [ -L "$RC_FILE" ]; then
  RC_FILE="$(readlink -f "$RC_FILE" 2>/dev/null || readlink "$RC_FILE")"
fi

  echo "$SHELL_FUNC" >> "$RC_FILE"

# --- Done ---
echo ""
ok "Installed."
echo ""
info "Usage:"
echo "  claude --safely-skip-permissions         # skip prompts, block destructive commands"
echo "  claude --dangerously-skip-permissions    # fully unrestricted (unchanged)"
echo ""
