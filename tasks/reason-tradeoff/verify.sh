#!/usr/bin/env bash
# Reasoning check (archetype: open-ended tradeoff). Genuinely no single
# correct pick — scored on the PROCESS (both sides weighed, explicit
# recommendation given, no invented facts), not on which option was chosen.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## reasoning: reason-tradeoff"

FAIL=0

# topic grounding
for t in "phone" "note"; do
  if ! grep -qiF "$t" "$OUT"; then
    echo "- missing topic grounding: '$t'"
    FAIL=1
  fi
done

# privacy side of the tradeoff
if grep -qiF "privacy" "$OUT"; then
  echo "- privacy side present: PASS"
else
  echo "- missing privacy side of the tradeoff"
  FAIL=1
fi

# utility side of the tradeoff (any one of these phrasings counts)
if grep -qiE "usefulness|useful|technical detail|troubleshoot|contact (them|someone|the)|operationally" "$OUT"; then
  echo "- utility/usefulness side present: PASS"
else
  echo "- missing utility side of the tradeoff (what's lost by obfuscating)"
  FAIL=1
fi

# explicit recommendation — either pick is acceptable, "it depends" alone is not
if grep -qE "Option A|Option B" "$OUT"; then
  echo "- explicit recommendation given: PASS"
else
  echo "- no explicit 'Option A'/'Option B' recommendation found"
  FAIL=1
fi

# forbidden: factually wrong claim that these are already obfuscated
FORBIDDEN=("phone numbers are obfuscated" "phone numbers are already obfuscated" "notes are obfuscated" "already obfuscated")
for t in "${FORBIDDEN[@]}"; do
  if grep -qiF "$t" "$OUT"; then
    echo "- forbidden/factually wrong claim: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- no factually wrong claims: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
