#!/usr/bin/env bash
# Reasoning check (role: reasoning). The answer must identify the exact
# invalid reference (`owner`) and the violating field (`nestedEntities`),
# and must not invent a different culprit. No exact-match — phrasing varies.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## reasoning: reason-config-validity"

FAIL=0

# required: the diagnosis must name the bad value and the field + rule
REQUIRED=("owner" "nestedEntities" "entities")
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- required tokens present: PASS"

# forbidden: blaming the valid parts (mode/customFields) or a wrong field
FORBIDDEN=("idField" "tokenTemplate" "CW_")
for t in "${FORBIDDEN[@]}"; do
  if grep -qF "$t" "$OUT"; then
    echo "- unrelated token present: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- no unrelated culprit named: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
