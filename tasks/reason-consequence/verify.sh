#!/usr/bin/env bash
# Reasoning check (role: reasoner). The consequence must recognize that a
# key absent from nestedEntities passes through untouched — including the
# member name that used to be obfuscated. It must NOT claim redaction still
# happens by shape, or that only owner.name (but not owner.id) is affected.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## reasoning: reason-consequence"

FAIL=0

# required: the removed key, the pass-through mechanism, and the leaking field
REQUIRED=("owner" "nestedEntities" "passes through" "name")
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- required tokens present: PASS"

# forbidden: claiming the redaction still applies by shape, or that owner.name
# is STILL obfuscated after the config change
FORBIDDEN=("still obfuscated" "still redacted" "remains obfuscated" "remains redacted" "continues to be obfuscated")
for t in "${FORBIDDEN[@]}"; do
  if grep -qF "$t" "$OUT"; then
    echo "- wrong-consequence token present: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- no wrong-consequence attribution: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
