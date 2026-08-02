#!/usr/bin/env bash
# Reasoning check (role: verification-checklist authoring). The checklist
# must be .NET-native, cover fail-fast and the MCP initialize round-trip,
# and be structured as numbered steps. No exact-match.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## reasoning: reason-checklist"

FAIL=0

# required content tokens
REQUIRED=("dotnet run" "/mcp" "initialize" "curl" "mcp-session-id")
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    FAIL=1
  fi
done

# structural: at least 3 numbered steps, and no runaway output
STEPS="$(grep -cE '^[[:space:]]*[0-9]+\.' "$OUT" || true)"
echo "- numbered steps found: $STEPS"
if [ "$STEPS" -lt 3 ]; then
  echo "- need at least 3 numbered steps"
  FAIL=1
elif [ "$STEPS" -gt 12 ]; then
  echo "- over-produced: more than 12 numbered steps"
  FAIL=1
fi

# forbidden: stale Node tooling
FORBIDDEN=("npm" "node " "tsc")
for t in "${FORBIDDEN[@]}"; do
  if grep -qF "$t" "$OUT"; then
    echo "- forbidden token present: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- structure + required tokens: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
