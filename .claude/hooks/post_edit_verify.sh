#!/usr/bin/env bash
# Fires on PostToolUse — checks edits for encoding issues and flags fitness math files.
set -euo pipefail

INPUT="$(cat)"
TOOL="$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")"

if [[ "$TOOL" != "Edit" && "$TOOL" != "Write" ]]; then
  echo "$INPUT"
  exit 0
fi

FILE="$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "$INPUT"
  exit 0
fi

# Check for mojibake (garbled encoding)
if file "$FILE" | grep -q "Non-ISO\|binary"; then
  echo "⚠ POST-EDIT: Encoding issue detected in $FILE" >&2
fi

# Flag fitness calculation files for extra scrutiny
MATH_PATTERNS=("calories" "1rm" "one.rep.max" "progression" "overload" "macros" "bmr" "tdee")
BASENAME="$(basename "$FILE" | tr '[:upper:]' '[:lower:]')"
for pattern in "${MATH_PATTERNS[@]}"; do
  if echo "$BASENAME" | grep -qi "$pattern"; then
    echo "ℹ POST-EDIT: Fitness math file edited: $FILE — run /verify before shipping." >&2
    break
  fi
done

echo "$INPUT"
