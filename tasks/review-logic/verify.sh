#!/usr/bin/env bash
# Review check (archetype: subtle logic bug, no crash). || instead of &&
# silently redacts fields that shouldn't be redacted (no rule configured,
# or explicitly disabled). Requires naming the operator AND at least one
# concrete wrong-case consequence, not just "the logic seems off."
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## review: review-logic"

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
if len(bugs) == 0:
    print("FAIL reported no bugs (there is a real one — missed it)")
    sys.exit(0)

blob = json.dumps(bugs).lower()
has_operator = "||" in blob or ("or" in blob and "and" in blob)
has_case1 = "no rule" in blob or ("null" in blob and "redact" in blob)
has_case2 = "disabled" in blob and "redact" in blob

fails = []
if not has_operator:
    fails.append("doesn't identify the || vs && operator mixup")
if not (has_case1 or has_case2):
    fails.append("doesn't trace through a concrete wrong-result case (no-rule-gets-redacted or disabled-still-redacts)")

if fails:
    print("FAIL " + "; ".join(fails))
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
