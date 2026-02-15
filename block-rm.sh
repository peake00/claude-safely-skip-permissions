#!/bin/bash
# claude-safely-skip-permissions: PreToolUse hook

[ "$CLAUDE_SAFE_MODE" != "1" ] && exit 0

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

deny() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# rm with -r, -f, -rf, -fr, or long flags
echo "$COMMAND" | grep -qEi '\brm\s+(-[a-zA-Z]*[rf]|--recursive|--force)\b|\brm\s+-[a-zA-Z]*r[a-zA-Z]*f|\brm\s+-[a-zA-Z]*f[a-zA-Z]*r' \
  && deny "BLOCKED: Destructive rm command. Use a safer alternative."

# find -delete
echo "$COMMAND" | grep -qEi '\bfind\b.*-delete\b' \
  && deny "BLOCKED: find -delete is not allowed."

# xargs rm
echo "$COMMAND" | grep -qEi '\bxargs\s+rm\b' \
  && deny "BLOCKED: xargs rm is not allowed."

# shred / wipe
echo "$COMMAND" | grep -qEi '\bshred\b|\bwipe\b' \
  && deny "BLOCKED: shred/wipe is not allowed."

exit 0
