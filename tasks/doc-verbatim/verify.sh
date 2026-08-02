#!/usr/bin/env bash
# Doc-fidelity check (archetype: verbatim copy + one appended note).
# Output must be byte-identical to expected.md.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$1"
DIFF_TMP="$(mktemp)"

# Model output may omit the final newline; normalize before exact-compare.
norm() { printf '%s\n' "$(cat "$1")"; }

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## doc-fidelity: doc-verbatim"
if diff -u <(norm "$HERE/expected.md") <(norm "$OUT") > "$DIFF_TMP" 2>&1; then
  echo "- byte-identical to expected.md: PASS"
  echo "VERDICT: PASS"
  exit 0
else
  echo "- byte-identical to expected.md: FAIL"
  head -40 "$DIFF_TMP"
  echo "VERDICT: FAIL"
  exit 1
fi
