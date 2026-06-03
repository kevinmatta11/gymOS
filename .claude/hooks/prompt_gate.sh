#!/usr/bin/env bash
# Fires on UserPromptSubmit — reads stdin (the prompt JSON), flags risky patterns.
set -euo pipefail

INPUT="$(cat)"
PROMPT="$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "$INPUT")"

# Flag prompts requesting irreversible operations without explicit confirmation
RISKY_PATTERNS=(
  "drop table"
  "delete all"
  "truncate"
  "rm -rf"
  "force push"
  "reset --hard"
  "skip.*test"
  "no.*verify"
  "bypass"
)

for pattern in "${RISKY_PATTERNS[@]}"; do
  if echo "$PROMPT" | grep -qi "$pattern"; then
    echo "⚠ PROMPT GATE: Detected potentially risky pattern: '$pattern'"
    echo "   Confirm this is intentional before proceeding."
    break
  fi
done

# Pass through — gate is advisory only
echo "$INPUT"
