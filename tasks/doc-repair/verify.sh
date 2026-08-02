#!/usr/bin/env bash
# Doc-fidelity check (archetype: repair). The output must match expected.md
# up to whitespace (wrapping/blank-line differences are ignored), which
# requires both repairs applied while everything else stays intact. The
# broken fragments (unclosed YAML fence; missing separator row) must be gone.
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

echo "## doc-fidelity: doc-repair"

# 1) match against the reference repaired document, whitespace-normalized
EXACT=0
if diff -u <(normws "$HERE/expected.md") <(normws "$OUT") > "$DIFF_TMP" 2>&1; then
  EXACT=1
  echo "- content match (whitespace-normalized): PASS"
else
  echo "- content match (whitespace-normalized): FAIL"
  head -30 "$DIFF_TMP"
fi

# 1b) informational only: byte-exact diff
if diff -u <(norm "$HERE/expected.md") <(norm "$OUT") > "$DIFF_TMP" 2>&1; then
  echo "- byte-exact (diagnostic only): PASS"
else
  echo "- byte-exact (diagnostic only): differs — whitespace/wrapping only"
  head -10 "$DIFF_TMP"
fi

# 2) forbidden: the repaired fragments must be gone. A repaired YAML fence
# means the `nestedEntities` line is no longer the last line before a table
# row that starts with `|`. Check the separator row is present and the yaml
# closing fence exists.
REPAIR_FAIL=0
if ! grep -q '^```$' "$OUT"; then
  echo "- missing YAML closing fence"
  REPAIR_FAIL=1
fi
if ! grep -q '^|---|---|---|---|$' "$OUT"; then
  echo "- missing table separator row"
  REPAIR_FAIL=1
fi
[ "$REPAIR_FAIL" -eq 0 ] && echo "- both repairs present: PASS"

if [ "$EXACT" -eq 1 ] && [ "$REPAIR_FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
