#!/usr/bin/env bash
# Doc-fidelity check (archetype: TS/Node -> C#/.NET adaptation). Output must
# match expected.md up to whitespace (wrapping/blank-line differences are
# ignored; a model may legitimately re-wrap an inserted phrase), with no
# stale Node tooling and C# tokens present.
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

echo "## doc-fidelity: doc-adapt"

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

# 2) no stale Node/TS tooling
FORBIDDEN=("npm" "node dist" "tsc" "Express")
FORBIDDEN_FAIL=0
for t in "${FORBIDDEN[@]}"; do
  if grep -qF "$t" "$OUT"; then
    echo "- forbidden token still present: '$t'"
    FORBIDDEN_FAIL=1
  fi
done
[ "$FORBIDDEN_FAIL" -eq 0 ] && echo "- forbidden Node/TS tokens absent: PASS"

# 3) required C# adaptation tokens present
REQUIRED=("dotnet run" "Program.cs" "ObfuscationConfigLoader" "WebApplication")
REQ_FAIL=0
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    REQ_FAIL=1
  fi
done
[ "$REQ_FAIL" -eq 0 ] && echo "- required C# tokens present: PASS"

if [ "$EXACT" -eq 1 ] && [ "$FORBIDDEN_FAIL" -eq 0 ] && [ "$REQ_FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
