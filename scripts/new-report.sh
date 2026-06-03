#!/usr/bin/env bash
# Create a new report artifact from template.
# Usage: ./scripts/new-report.sh <feature-name> <stage>
# Stage: self-review | verify | test | session-summary
set -euo pipefail

FEATURE="${1:-unknown}"
STAGE="${2:-report}"
DATE="$(date -u '+%Y-%m-%d')"
REPORT_FILE="docs/reports/${DATE}-${FEATURE}-${STAGE}.md"

mkdir -p docs/reports

cat > "$REPORT_FILE" << EOF
# ${STAGE^}: ${FEATURE}
**Date:** ${DATE}
**Branch:** $(git branch --show-current 2>/dev/null || echo 'unknown')
**Result:** PASS | FAIL

## Notes

EOF

echo "Created: $REPORT_FILE"
