#!/usr/bin/env bash
# Doc-fidelity check (archetype: synthesize). The output must be a NEW C#
# error-behavior section: the required C# error-shape + exception tokens must
# be present, the stale TypeScript/SDK tokens must be absent, and the section
# must be structured as heading + fenced JSON + two bullets. No exact-match —
# this is a synthesis task, prose is the model's own.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## doc-fidelity: doc-synthesize"

FAIL=0

# 1) structure: heading, a fenced JSON block, two bullets
grep -q '^# Error behavior (C# port)\|^## Error behavior (C# port)' "$OUT" \
  || { echo "- missing section heading"; FAIL=1; }
if grep -q '^```json' "$OUT" && grep -q '^```' "$OUT"; then
  echo "- fenced JSON block present: PASS"
else
  echo "- missing fenced JSON block"
  FAIL=1
fi
BULLETS="$(grep -cE '^[-*] \*\*' "$OUT" || true)"
if [ "$BULLETS" -ge 2 ]; then
  echo "- bullet count ($BULLETS) ok: PASS"
else
  echo "- need at least 2 bullets; found $BULLETS"
  FAIL=1
fi

# 2) required C# tokens
REQUIRED=("isError" "ConnectWise API error" "HttpRequestException")
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] || true
grep -qF "isError" "$OUT" && grep -qF "ConnectWise API error" "$OUT" && \
  grep -qF "HttpRequestException" "$OUT" && echo "- required tokens present: PASS"

# 3) forbidden stale TS/SDK tokens
FORBIDDEN=("zod" "fetch failed" "@modelcontextprotocol/sdk" "node_modules")
for t in "${FORBIDDEN[@]}"; do
  if grep -qF "$t" "$OUT"; then
    echo "- forbidden token present: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- no stale TS/SDK tokens: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
