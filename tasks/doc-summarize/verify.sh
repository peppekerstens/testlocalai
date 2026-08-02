#!/usr/bin/env bash
# Doc-fidelity check (archetype: summarize/compress). New scoring dimension
# vs the original doc tasks: a LENGTH bound, to check the model actually
# compressed rather than reproducing/paraphrasing the source at full length.
# No exact-match — summary wording is the model's own.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## doc-fidelity: doc-summarize"

FAIL=0

# 1) required facts
REQUIRED=("TypeScript" "Python" "OAuth" "ConnectWise MCP server")
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    FAIL=1
  fi
done
# SPEC explicitly allows either phrasing here — "reference implementation"
# or "official SDK"/the SDK package name — so the check must accept both,
# not just the first one literally.
if grep -qiE "reference implementation|official.*sdk|@modelcontextprotocol/sdk" "$OUT"; then
  :
else
  echo "- missing required fact: SDK is the reference implementation / official SDK"
  FAIL=1
fi
[ "$FAIL" -eq 0 ] && echo "- required facts present: PASS"

# 2) forbidden invented content
FORBIDDEN=("Django" "Flask" "gRPC" "psycopg" "performance" "faster")
for t in "${FORBIDDEN[@]}"; do
  if grep -qiF "$t" "$OUT"; then
    echo "- forbidden/invented token present: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- no invented content: PASS"

# 3) length bound: genuine compression, not a reproduction
WORDS="$(wc -w < "$OUT" | tr -d ' ')"
echo "- word count: $WORDS"
if [ "$WORDS" -gt 90 ]; then
  echo "- over the 90-word limit"
  FAIL=1
elif [ "$WORDS" -lt 20 ]; then
  echo "- under 20 words — too short to cover the required facts honestly"
  FAIL=1
else
  echo "- length within [20, 90] words: PASS"
fi

# 4) sentence count (rough: count sentence-ending punctuation)
SENTENCES="$(grep -o '[.!?]' "$OUT" | wc -l | tr -d ' ')"
echo "- sentence-ending punctuation count: $SENTENCES"
if [ "$SENTENCES" -gt 4 ]; then
  echo "- more than 4 sentences"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
