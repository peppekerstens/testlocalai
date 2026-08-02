#!/usr/bin/env bash
# Doc-fidelity check (archetype: executable manual-test adaptation TS->C#).
# Output must be a valid bash script, with no stale Node tooling and the
# C#/.NET commands present.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## doc-fidelity: doc-script"

# 1) must be valid bash (also punishes fence-wrapping, R1's habit)
SYNTAX=0
if bash -n "$OUT" 2>/tmp/opencode/doc-script-bashn.err; then
  SYNTAX=1
  echo "- bash -n: PASS"
else
  echo "- bash -n: FAIL"
  cat /tmp/opencode/doc-script-bashn.err
  rm -f /tmp/opencode/doc-script-bashn.err
fi

# 2) no stale Node/TS tooling
FORBIDDEN=("npm" "node " "tsc" "dist/index.js")
FORBIDDEN_FAIL=0
for t in "${FORBIDDEN[@]}"; do
  if grep -qF "$t" "$OUT"; then
    echo "- forbidden token still present: '$t'"
    FORBIDDEN_FAIL=1
  fi
done
[ "$FORBIDDEN_FAIL" -eq 0 ] && echo "- forbidden Node/TS tokens absent: PASS"

# 3) required C#/.NET + smoke-assertion tokens present
REQUIRED=("dotnet build" "dotnet run" "curl" "mcp-session-id" "set -euo pipefail")
REQ_FAIL=0
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    REQ_FAIL=1
  fi
done
[ "$REQ_FAIL" -eq 0 ] && echo "- required C#/.NET tokens present: PASS"

if [ "$SYNTAX" -eq 1 ] && [ "$FORBIDDEN_FAIL" -eq 0 ] && [ "$REQ_FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
