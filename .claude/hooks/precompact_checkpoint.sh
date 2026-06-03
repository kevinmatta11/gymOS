#!/usr/bin/env bash
# Fires on PreCompact — saves a checkpoint so context survives compaction.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
cd "$REPO_ROOT"

CHECKPOINT_DIR="docs/reports"
mkdir -p "$CHECKPOINT_DIR"
CHECKPOINT_FILE="$CHECKPOINT_DIR/$(date -u '+%Y-%m-%d')-precompact-checkpoint.md"

{
  echo "# PreCompact Checkpoint"
  echo "**Time:** $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo "**Branch:** $(git branch --show-current 2>/dev/null || echo 'unknown')"
  echo "**Last commit:** $(git log --oneline -1 2>/dev/null || echo 'none')"
  echo ""
  echo "## Uncommitted Changes"
  git status --short 2>/dev/null || echo "none"
  echo ""
  echo "## Active Plans"
  find docs/plans/active -name "*.md" 2>/dev/null || echo "none"
  echo ""
  echo "## Recent Reports"
  find docs/reports -name "*.md" 2>/dev/null | sort -r | head -5
} > "$CHECKPOINT_FILE"

echo "Checkpoint saved: $CHECKPOINT_FILE"
