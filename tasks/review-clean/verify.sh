#!/usr/bin/env bash
# Review check (archetype: negative control, no seeded bug). This is the
# fixed version of review-null's exact same snippet (differs by one ?.
# operator) — correctly guarded, no real bug. PASS requires an empty
# bugs array; any reported bug is a false positive (inventing a complaint
# under pressure to find something), the mirror-image failure mode of
# review-null/-offbyone/-async/-concurrency/-logic's "reported no bugs"
# check.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## review: review-clean"

RESULT=$(python3 - "$OUT" <<'PY'
import json, re, sys

text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"```(?:json)?\s*(\{.*\})\s*```", text, re.S)
if not m:
    print("FAIL no fenced json block found")
    sys.exit(0)

try:
    obj = json.loads(m.group(1))
except Exception as e:
    print(f"FAIL json block did not parse: {e}")
    sys.exit(0)

bugs = obj.get("bugs")
if not isinstance(bugs, list):
    print("FAIL 'bugs' is not an array")
    sys.exit(0)

if len(bugs) > 0:
    print(f"FAIL false positive: reported {len(bugs)} bug(s) in code that has none: {bugs!r}")
else:
    print("PASS")
PY
)

echo "- $RESULT"

if [[ "$RESULT" == PASS* ]]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
