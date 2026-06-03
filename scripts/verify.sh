#!/usr/bin/env bash
# Generic verify script — runs whatever static analysis applies to the stack.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

PASS=0
FAIL=0

run_check() {
  local name="$1"; shift
  echo -n "  $name... "
  if "$@" > /tmp/gymos_check_out 2>&1; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    cat /tmp/gymos_check_out
    FAIL=$((FAIL + 1))
  fi
}

echo "=== gymOS Verify ==="

# TypeScript / Node
if [ -f "package.json" ]; then
  if jq -e '.scripts.lint' package.json > /dev/null 2>&1; then
    run_check "ESLint" npm run lint --silent
  fi
  if jq -e '.scripts["type-check"]' package.json > /dev/null 2>&1; then
    run_check "TypeScript" npm run type-check --silent
  elif [ -f "tsconfig.json" ]; then
    run_check "TypeScript" npx tsc --noEmit
  fi
fi

# Python
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  if command -v ruff &>/dev/null; then
    run_check "Ruff" ruff check .
  fi
  if command -v mypy &>/dev/null; then
    run_check "Mypy" mypy .
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
