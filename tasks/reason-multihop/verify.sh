#!/usr/bin/env bash
# Reasoning check (archetype: multi-hop root cause). Requires naming BOTH
# the proximate mechanism (config-driven redaction) AND the specific root
# cause (the missing config entry) — a single-hop "redaction is broken"
# answer must fail even though it's superficially plausible. No exact-match.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## reasoning: reason-multihop"

FAIL=0

# Hop 1: proximate mechanism (config-driven, not automatic)
if grep -qiF "config" "$OUT" || grep -qiF "obfuscation-rules" "$OUT"; then
  echo "- hop 1 (config-driven mechanism) present: PASS"
else
  echo "- missing hop 1: no mention of the config-driven mechanism"
  FAIL=1
fi

# Hop 2: the specific missing field/root cause
if grep -qF "addressLine2" "$OUT"; then
  echo "- hop 2 (names addressLine2 specifically) present: PASS"
else
  echo "- missing hop 2: doesn't name addressLine2 as the specific gap"
  FAIL=1
fi
if grep -qiF "fields" "$OUT" || grep -qiF "entities.company" "$OUT"; then
  echo "- hop 2 (names the fields section) present: PASS"
else
  echo "- missing hop 2 detail: doesn't name the fields/entities section"
  FAIL=1
fi

# Forbidden: stopping at the ruled-out single-hop answer
FORBIDDEN=("bug in redactDeep" "redactDeep is broken" "redactDeep has a bug" "bug in the redaction logic")
for t in "${FORBIDDEN[@]}"; do
  if grep -qiF "$t" "$OUT"; then
    echo "- forbidden single-hop (ruled-out) answer present: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- no ruled-out single-hop answer: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
