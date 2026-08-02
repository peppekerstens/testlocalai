#!/usr/bin/env bash
# Reasoning check (role: reasoner). The comparison must pick candidate A
# (eager boot-time validation) as the fix, justify against the "process
# running ⇒ config valid" property, and not endorse B (lazy) or C (auto-
# restart) as the fix.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## reasoning: reason-compare"

FAIL=0

# required: picks A, ties it to boot-time/startup, keeps the try/catch. "listen"
# covers both "app.listen" and "before the server starts listening".
REQUIRED=("A" "boot" "try/catch" "listen" "config was valid")
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- required tokens present: PASS"

# forbidden: endorsing B or C as the fix, or dropping the try/catch entirely
FORBIDDEN=("B is correct" "C is correct" "B is the correct" "C is the correct" "B alone" "C alone" "B only" "C only")
for t in "${FORBIDDEN[@]}"; do
  if grep -qF "$t" "$OUT"; then
    echo "- wrong-candidate token present: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- no wrong-candidate endorsement: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
