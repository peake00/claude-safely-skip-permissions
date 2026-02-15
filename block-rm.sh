#!/bin/bash
# claude-safely-skip-permissions: PreToolUse hook

[ "$CLAUDE_SAFE_MODE" != "1" ] && exit 0

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

ask() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# rm with -r, -f, -rf, -fr, or long flags
echo "$COMMAND" | grep -qEi '\brm\s+(-[a-zA-Z]*[rf]|--recursive|--force)\b|\brm\s+-[a-zA-Z]*r[a-zA-Z]*f|\brm\s+-[a-zA-Z]*f[a-zA-Z]*r' \
  && ask "BLOCKED: rm is not allowed autonomously."

# find -delete
echo "$COMMAND" | grep -qEi '\bfind\b.*-delete\b' \
  && ask "BLOCKED: find -delete is not allowed autonomously."

# xargs rm
echo "$COMMAND" | grep -qEi '\bxargs\s+rm\b' \
  && ask "BLOCKED: xargs rm is not allowed autonomously."

# shred / wipe
echo "$COMMAND" | grep -qEi '\bshred\b|\bwipe\b' \
  && ask "BLOCKED: shred/wipe is not allowed autonomously."

# trash / rmtrash - file deletion via trash utilities
echo "$COMMAND" | grep -qEi '\btrash\b|\brmtrash\b' \
  && ask "BLOCKED: trash/rmtrash is not allowed autonomously."

# rmdir / unlink - other file/directory removal commands
echo "$COMMAND" | grep -qEi '\brmdir\b|\bunlink\b' \
  && ask "BLOCKED: rmdir/unlink is not allowed autonomously."

# Destructive git commands: clean, reset --hard, push --force, branch -D, checkout -- ., restore .
echo "$COMMAND" | grep -qEi '\bgit\s+clean\b' \
  && ask "BLOCKED: git clean is not allowed autonomously."
echo "$COMMAND" | grep -qEi '\bgit\s+reset\s+--hard\b' \
  && ask "BLOCKED: git reset --hard is not allowed autonomously."
echo "$COMMAND" | grep -qEi '\bgit\s+push\s+(-[a-zA-Z]*f|--force)\b' \
  && ask "BLOCKED: git push --force is not allowed autonomously."
echo "$COMMAND" | grep -qEi '\bgit\s+branch\s+(-[a-zA-Z]*D)\b' \
  && ask "BLOCKED: git branch -D is not allowed autonomously."
echo "$COMMAND" | grep -qEi '\bgit\s+(checkout|restore)\s+--?\s*\.' \
  && ask "BLOCKED: git checkout/restore is not allowed autonomously."

# dd - raw disk/file operations
echo "$COMMAND" | grep -qEi '\bdd\s+' \
  && ask "BLOCKED: dd is not allowed autonomously."

# mkfs / format filesystem
echo "$COMMAND" | grep -qEi '\bmkfs\b' \
  && ask "BLOCKED: mkfs is not allowed autonomously."

# truncate
echo "$COMMAND" | grep -qEi '\btruncate\b' \
  && ask "BLOCKED: truncate is not allowed autonomously."

# Scripting language one-liners that delete files (shutil.rmtree, os.remove, unlink, etc.)
echo "$COMMAND" | grep -qEi 'shutil\.rmtree|os\.remove|os\.unlink|os\.rmdir|File\.delete|FileUtils\.rm|unlink\(' \
  && ask "BLOCKED: Scripting file deletion is not allowed autonomously."

exit 0
