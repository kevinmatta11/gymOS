#!/usr/bin/env bash
# Fires on SessionEnd — writes a summary artifact of what happened this session.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
cd "$REPO_ROOT"

REPORT_DIR="docs/reports"
mkdir -p "$REPORT_DIR"
SUMMARY_FILE="$REPORT_DIR/$(date -u '+%Y-%m-%d-%H%M')-session-summary.md"

{
  echo "# Session Summary"
  echo "**Ended:** $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo "**Branch:** $(git branch --show-current 2>/dev/null || echo 'unknown')"
  echo ""
  echo "## Commits This Session"
  git log --oneline --since="8 hours ago" 2>/dev/null || echo "none"
  echo ""
  echo "## Files Changed"
  git diff --name-only HEAD 2>/dev/null | head -20 || echo "none"
  echo ""
  echo "## Active Plans Remaining"
  find docs/plans/active -name "*.md" 2>/dev/null || echo "none"
} > "$SUMMARY_FILE"

echo "Session summary: $SUMMARY_FILE"
