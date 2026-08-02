#!/usr/bin/env bash
# Doc-fidelity check (archetype: cross-document synthesis). The output must
# combine a specific fact from EACH of two unrelated source excerpts —
# scored by requiring tokens unique to each source, so a model that only
# read one of them fails. No exact-match — the FAQ answer is the model's
# own words.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## doc-fidelity: doc-crossref"

FAIL=0

# Source A fact (verification tool)
if grep -qF "describe_obfuscation_policy" "$OUT"; then
  echo "- Source A fact (describe_obfuscation_policy) present: PASS"
else
  echo "- missing Source A fact: 'describe_obfuscation_policy'"
  FAIL=1
fi

# Source B fact (exact transformation)
if grep -qF "obfuscated.invalid" "$OUT"; then
  echo "- Source B fact (obfuscated.invalid placeholder) present: PASS"
else
  echo "- missing Source B fact: 'obfuscated.invalid'"
  FAIL=1
fi

if grep -qiF "email" "$OUT"; then
  echo "- on-topic (mentions email): PASS"
else
  echo "- does not mention email at all"
  FAIL=1
fi

# forbidden: invented placeholder formats or a wrong "not obfuscated" claim
FORBIDDEN=("[REDACTED]" "***" "is not obfuscated" "isn't obfuscated" "visible to the assistant")
for t in "${FORBIDDEN[@]}"; do
  if grep -qiF "$t" "$OUT"; then
    echo "- forbidden/wrong token present: '$t'"
    FAIL=1
  fi
done

# forbidden: conflating describe_obfuscation_policy (a verification/reporting
# tool per Source A) with the mechanism that actually performs obfuscation.
# Both required tokens can be individually present while the answer still
# gets this relationship backwards — token presence alone doesn't catch it.
if grep -qiE "obfuscated (using|via|by|with).{0,35}describe_obfuscation_policy|describe_obfuscation_policy.{0,35}(is used to|used to|to) obfuscate|describe_obfuscation_policy.{0,10}(obfuscates|hides|replaces|redacts)" "$OUT"; then
  echo "- describes describe_obfuscation_policy as the obfuscation mechanism itself (backwards — it only REPORTS what's hidden)"
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "- no invented/wrong claims: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
