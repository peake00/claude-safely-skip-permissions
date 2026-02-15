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
  && ask "BLOCKED: rm is not allowed."

# find -delete
echo "$COMMAND" | grep -qEi '\bfind\b.*-delete\b' \
  && ask "BLOCKED: find -delete is not allowed."

# xargs rm
echo "$COMMAND" | grep -qEi '\bxargs\s+rm\b' \
  && ask "BLOCKED: xargs rm is not allowed."

# shred / wipe
echo "$COMMAND" | grep -qEi '\bshred\b|\bwipe\b' \
  && ask "BLOCKED: shred/wipe is not allowed."

# trash / rmtrash - file deletion via trash utilities
echo "$COMMAND" | grep -qEi '\btrash\b|\brmtrash\b' \
  && ask "BLOCKED: trash/rmtrash is not allowed."

# rmdir / unlink - other file/directory removal commands
echo "$COMMAND" | grep -qEi '\brmdir\b|\bunlink\b' \
  && ask "BLOCKED: rmdir/unlink is not allowed."

# Destructive git commands: clean, reset --hard, push --force, branch -D, checkout -- ., restore .
echo "$COMMAND" | grep -qEi '\bgit\s+clean\b' \
  && ask "BLOCKED: git clean is not allowed."
echo "$COMMAND" | grep -qEi '\bgit\s+reset\s+--hard\b' \
  && ask "BLOCKED: git reset --hard is not allowed."
echo "$COMMAND" | grep -qEi '\bgit\s+push\s+(-[a-zA-Z]*f|--force)\b' \
  && ask "BLOCKED: git push --force is not allowed."
echo "$COMMAND" | grep -qEi '\bgit\s+branch\s+(-[a-zA-Z]*D)\b' \
  && ask "BLOCKED: git branch -D is not allowed."
echo "$COMMAND" | grep -qEi '\bgit\s+(checkout|restore)\s+--?\s*\.' \
  && ask "BLOCKED: Destructive git checkout/restore is not allowed."

# dd - raw disk/file operations
echo "$COMMAND" | grep -qEi '\bdd\s+' \
  && ask "BLOCKED: dd is not allowed."

# mkfs / format filesystem
echo "$COMMAND" | grep -qEi '\bmkfs\b' \
  && ask "BLOCKED: mkfs is not allowed."

# truncate
echo "$COMMAND" | grep -qEi '\btruncate\b' \
  && ask "BLOCKED: truncate is not allowed."

# Scripting language one-liners that delete files (shutil.rmtree, os.remove, unlink, etc.)
echo "$COMMAND" | grep -qEi 'shutil\.rmtree|os\.remove|os\.unlink|os\.rmdir|File\.delete|FileUtils\.rm|unlink\(' \
  && ask "BLOCKED: Scripting file deletion is not allowed."

exit 0
