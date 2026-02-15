#!/bin/bash
set -e

HOOK_FILE="$HOME/.claude/hooks/block-rm.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"

GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { echo -e "${BOLD}$1${RESET}"; }
ok()    { echo -e "${GREEN}$1${RESET}"; }

# --- Remove hook script ---
if [ -f "$HOOK_FILE" ]; then
  rm "$HOOK_FILE"
fi

# --- Remove hook from settings.json ---
if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
  if grep -q 'block-rm.sh' "$SETTINGS_FILE"; then
    SETTINGS=$(cat "$SETTINGS_FILE" | jq '
      .hooks.PreToolUse = [.hooks.PreToolUse[]? | select(.hooks[0].command != "~/.claude/hooks/block-rm.sh")]
      | if .hooks.PreToolUse == [] then del(.hooks.PreToolUse) else . end
      | if .hooks == {} then del(.hooks) else . end
    ')
    echo "$SETTINGS" | jq '.' > "$SETTINGS_FILE"
  fi
fi

# --- Remove shell function ---
for RC_FILE in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
  REAL_FILE="$RC_FILE"
  [ -L "$RC_FILE" ] && REAL_FILE="$(readlink -f "$RC_FILE" 2>/dev/null || readlink "$RC_FILE")"
  if [ -f "$REAL_FILE" ] && grep -q 'claude-safely-skip-permissions' "$REAL_FILE"; then
    # Remove the function block
    sed -i.bak '/# claude-safely-skip-permissions/,/^}/d' "$REAL_FILE"
    rm -f "${REAL_FILE}.bak"
  fi
done

echo ""
ok "Uninstalled."
