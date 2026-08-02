#!/usr/bin/env bash
# Doc-fidelity check (archetype: structural restructure). List -> table,
# every fact preserved, nothing invented. New scoring dimension vs the
# original doc tasks: checks the STRUCTURE genuinely changed (old bullet
# format gone, real table markup present), not just that facts survived.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## doc-fidelity: doc-restructure"

FAIL=0

# 1) all 4 capabilities present
REQUIRED_NAMES=("Companies" "Contacts" "Tickets" "Ticket detail")
for t in "${REQUIRED_NAMES[@]}"; do
  if ! grep -qiF "$t" "$OUT"; then
    echo "- missing capability: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- all 4 capabilities present: PASS"

# 2) detail preserved per row (not compressed away to generic phrasing)
DETAIL_REQUIRED=("priority" "board" "notes" "time entries")
for t in "${DETAIL_REQUIRED[@]}"; do
  if ! grep -qiF "$t" "$OUT"; then
    echo "- missing preserved detail: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- row-level detail preserved: PASS"

# 3) structure: real markdown table (header + separator + ~4 data rows)
PIPE_LINES="$(grep -c '|' "$OUT" || true)"
echo "- lines containing '|': $PIPE_LINES"
if [ "$PIPE_LINES" -lt 5 ]; then
  echo "- too few table lines to be a real table (need header+separator+4 rows)"
  FAIL=1
elif [ "$PIPE_LINES" -gt 8 ]; then
  echo "- more table lines than expected — possible invented extra row"
  FAIL=1
else
  echo "- table row count plausible: PASS"
fi
if ! grep -qE '^\|?\s*-{2,}\s*\|' "$OUT" && ! grep -qE '\|\s*-{2,}\s*\|' "$OUT"; then
  echo "- no markdown table separator row (|---|---|) found"
  FAIL=1
fi

# 4) forbidden: the old bullet-list format must be gone
if grep -qE '^- \*\*' "$OUT"; then
  echo "- old bullet-list format ('- **Name**') still present — not actually restructured"
  FAIL=1
else
  echo "- old bullet format gone: PASS"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
