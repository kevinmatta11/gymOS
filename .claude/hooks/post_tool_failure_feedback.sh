#!/usr/bin/env bash
# Fires on PostToolUseFailure — surfaces structured failure context.
set -euo pipefail

INPUT="$(cat)"
TOOL="$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")"
ERROR="$(echo "$INPUT" | jq -r '.error // ""' 2>/dev/null || echo "")"

echo "=== Tool Failure: $TOOL ==="
echo "Time: $(date -u '+%Y-%m-%d %H:%M UTC')"
if [ -n "$ERROR" ]; then
  echo "Error: $ERROR"
fi
echo ""
echo "Guidance:"
case "$TOOL" in
  Bash)
    echo "  - Check the command syntax and working directory"
    echo "  - Verify required tools are installed"
    echo "  - Check scripts/ for reusable alternatives"
    ;;
  Edit|Write)
    echo "  - Verify the file path exists"
    echo "  - Check for permission issues"
    echo "  - Re-read the file before attempting another edit"
    ;;
  *)
    echo "  - Review the tool input for correctness"
    echo "  - Consult .claude/rules/ for domain constraints"
    ;;
esac

echo "$INPUT"
