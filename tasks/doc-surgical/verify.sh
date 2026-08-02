#!/usr/bin/env bash
# Doc-fidelity check (archetype: surgical edits). Output must match
# expected.md up to whitespace (wrapping/blank-line differences are ignored;
# a model may legitimately re-wrap an inserted phrase), with the replaced TS
# wording gone and the C# tokens present.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$1"
DIFF_TMP="$(mktemp)"

# Model output may omit the final newline; normalize before exact-compare.
norm() { printf '%s\n' "$(cat "$1")"; }
# Collapse every run of whitespace to one space (wrapping/blank-line agnostic).
normws() { python3 -c 'import sys; print(" ".join(open(sys.argv[1]).read().split()))' "$1"; }

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## doc-fidelity: doc-surgical"

# 1) match against the reference adapted document, whitespace-normalized
EXACT=0
if diff -u <(normws "$HERE/expected.md") <(normws "$OUT") > "$DIFF_TMP" 2>&1; then
  EXACT=1
  echo "- content match (whitespace-normalized): PASS"
else
  echo "- content match (whitespace-normalized): FAIL"
  head -30 "$DIFF_TMP"
fi

# 1b) informational only: byte-exact diff (whitespace differences do not fail)
if diff -u <(norm "$HERE/expected.md") <(norm "$OUT") > "$DIFF_TMP" 2>&1; then
  echo "- byte-exact (diagnostic only): PASS"
else
  echo "- byte-exact (diagnostic only): differs — whitespace/wrapping only"
  head -10 "$DIFF_TMP"
fi

# 2) no stale TS/SDK wording left behind
FORBIDDEN=("@modelcontextprotocol/sdk" "node_modules" "zod" "fetch failed")
FORBIDDEN_FAIL=0
for t in "${FORBIDDEN[@]}"; do
  if grep -qF "$t" "$OUT"; then
    echo "- forbidden token still present: '$t'"
    FORBIDDEN_FAIL=1
  fi
done
[ "$FORBIDDEN_FAIL" -eq 0 ] && echo "- forbidden tokens absent: PASS"

# 3) required C# tokens present
REQUIRED=("ModelContextProtocol" "HttpRequestException")
REQ_FAIL=0
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    REQ_FAIL=1
  fi
done
[ "$REQ_FAIL" -eq 0 ] && echo "- required tokens present: PASS"

if [ "$EXACT" -eq 1 ] && [ "$FORBIDDEN_FAIL" -eq 0 ] && [ "$REQ_FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
