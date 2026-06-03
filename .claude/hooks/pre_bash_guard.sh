#!/usr/bin/env bash
# Fires on PreToolUse — guards dangerous bash commands before execution.
set -euo pipefail

INPUT="$(cat)"
TOOL="$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")"

if [ "$TOOL" != "Bash" ]; then
  echo "$INPUT"
  exit 0
fi

CMD="$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")"

# Block outright destructive patterns
BLOCKED=(
  "git push --force origin main"
  "git push --force origin master"
  "git reset --hard HEAD~"
  "DROP TABLE"
  "TRUNCATE TABLE"
)

for blocked in "${BLOCKED[@]}"; do
  if echo "$CMD" | grep -qi "$blocked"; then
    echo "BLOCK: Command matches blocked pattern: '$blocked'" >&2
    exit 1
  fi
done

# Warn on patterns that need care
WARN_PATTERNS=(
  "rm -rf"
  "git reset --hard"
  "git push --force"
)

for pattern in "${WARN_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qi "$pattern"; then
    echo "⚠ PRE-BASH GUARD: High-risk command detected: '$pattern'" >&2
    echo "   Ensure this is intentional." >&2
    break
  fi
done

echo "$INPUT"
