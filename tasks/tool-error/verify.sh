#!/usr/bin/env bash
# Tool-use check (archetype: error-contract prediction). Tests whether the
# model correctly predicts tool BEHAVIOR from the documented error-handling
# rules, not just tool selection. Must name isError:true, the exact
# "ConnectWise API error: <status> <statusText>" pattern with the real
# status substituted in, and must NOT invent a special not-found handling
# path (the facts explicitly rule that out).
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## tool-use: tool-error"

FAIL=0

if grep -qiF "isError" "$OUT" && grep -qiF "true" "$OUT"; then
  echo "- names isError: true: PASS"
else
  echo "- missing isError: true"
  FAIL=1
fi

if grep -qF "ConnectWise API error" "$OUT"; then
  echo "- names the ConnectWise API error message pattern: PASS"
else
  echo "- missing the exact 'ConnectWise API error' message pattern"
  FAIL=1
fi

if grep -qF "404" "$OUT" && grep -qiF "Not Found" "$OUT"; then
  echo "- substitutes the real status (404 Not Found): PASS"
else
  echo "- missing the real status code/text (404 Not Found) substituted into the message"
  FAIL=1
fi

# Positive claims of invented special-case handling — NOT the same as the
# expected answer's negation ("is not special-cased"), so these check for
# the affirmative phrasing specifically, not a bare substring that a
# correct negated sentence could also contain.
FORBIDDEN_RE='is special-cased|is special-cased for|has a custom error|has special handling|special not-found|tailored (error|message)|returns null|returns undefined|custom.*not.found.*message'
if grep -qiE "$FORBIDDEN_RE" "$OUT"; then
  echo "- forbidden/wrong claim present: invented special-case handling"
  FAIL=1
else
  echo "- no invented special-case handling: PASS"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
