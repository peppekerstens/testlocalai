#!/usr/bin/env bash
# Reasoning check (archetype: exhaustive edge-case coverage). Hardest/longest
# task in the suite — requires naming specific fields across 4 distinct
# categories (missing-optional, obfuscation-correctness, lookup-value,
# excluded-field) plus the empty-result case, as a numbered list of >= 5
# items. Generic "test all fields" filler fails every category check.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## reasoning: reason-coverage"

FAIL=0

# category 1: obfuscation-correctness — at least one obfuscated field named
if grep -qiE "company\.name|contact\.name|owner\.name" "$OUT"; then
  echo "- category 1 (obfuscated field named): PASS"
else
  echo "- missing category 1: no obfuscated field (company.name/contact.name/owner.name) named"
  FAIL=1
fi

# category 2: lookup-value field named
if grep -qiE "\bstatus\b|\bpriority\b|\btype\b|\bboard\b" "$OUT"; then
  echo "- category 2 (lookup-value field named): PASS"
else
  echo "- missing category 2: no lookup-value field (status/priority/type/board) named"
  FAIL=1
fi

# category 3: excluded field named (must NOT appear in output)
if grep -qiE "dateResolved|severity|slaStatus|estimatedTimeCost|isInSla|impact\b" "$OUT"; then
  echo "- category 3 (excluded field named): PASS"
else
  echo "- missing category 3: no excluded field (dateResolved/severity/slaStatus/...) named"
  FAIL=1
fi

# category 4: empty-result case
if grep -qiE "empty|zero tickets|no tickets" "$OUT"; then
  echo "- category 4 (empty-result case) present: PASS"
else
  echo "- missing category 4: no empty-result / zero-tickets case"
  FAIL=1
fi

# category 5: missing-optional-object case
if grep -qiE "absent|missing|not present|no company|no contact|no owner" "$OUT"; then
  echo "- category 5 (missing-optional-object case) present: PASS"
else
  echo "- missing category 5: no absent/missing-optional-field case"
  FAIL=1
fi

# structural: at least 5 numbered items
ITEMS="$(grep -cE '^[[:space:]]*[0-9]+\.' "$OUT" || true)"
echo "- numbered items found: $ITEMS"
if [ "$ITEMS" -lt 5 ]; then
  echo "- need at least 5 numbered items"
  FAIL=1
else
  echo "- item count: PASS"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
