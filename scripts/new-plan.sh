#!/usr/bin/env bash
# Create a new plan file from template.
# Usage: ./scripts/new-plan.sh <feature-name>
set -euo pipefail

FEATURE="${1:-unnamed-feature}"
DATE="$(date -u '+%Y-%m-%d')"
PLAN_FILE="docs/plans/active/${DATE}-${FEATURE}.md"

mkdir -p docs/plans/active

cat > "$PLAN_FILE" << EOF
# Plan: ${FEATURE}
**Date:** ${DATE}
**Spec:** docs/specs/${DATE}-${FEATURE}.md
**Flow:** standard
**Status:** active

## Task Breakdown
- [ ] Task 1
- [ ] Task 2

## Definition of Done
- All acceptance criteria from spec pass
- /verify artifact exists in docs/reports/
- /test artifact exists in docs/reports/
- No open critical/major findings from /self-review

## Risks
-
EOF

echo "Created: $PLAN_FILE"
