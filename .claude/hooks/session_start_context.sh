#!/usr/bin/env bash
# Fires on SessionStart — orients the agent with repo state and active work.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
cd "$REPO_ROOT"

echo "=== gymOS Session Start ==="
echo "Date: $(date -u '+%Y-%m-%d %H:%M UTC')"
echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
echo "Last commit: $(git log --oneline -1 2>/dev/null || echo 'no commits yet')"
echo ""

# Show active plans
ACTIVE=$(find docs/plans/active -name "*.md" 2>/dev/null | head -5)
if [ -n "$ACTIVE" ]; then
  echo "=== Active Plans ==="
  echo "$ACTIVE"
  echo ""
fi

# Show recent reports
RECENT=$(find docs/reports -name "*.md" 2>/dev/null | sort -r | head -3)
if [ -n "$RECENT" ]; then
  echo "=== Recent Reports ==="
  echo "$RECENT"
  echo ""
fi

# Warn on dirty state
if ! git diff --quiet 2>/dev/null; then
  echo "⚠ WARNING: Uncommitted changes present."
  git status --short 2>/dev/null | head -10
fi

echo "=== Rules Active ==="
find .claude/rules -name "*.md" 2>/dev/null | sort

echo ""
echo "Ready. Source of truth: repo files > memory > chat history."
