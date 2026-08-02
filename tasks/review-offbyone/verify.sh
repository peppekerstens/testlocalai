#!/usr/bin/env bash
# Review check (archetype: boundary/off-by-one bug). The outer loop's
# `<=` instead of `<` produces one extra empty trailing page whenever
# items.Count is an exact multiple of pageSize. Requires naming the
# specific mechanism (extra/empty page, or the <= condition itself), not
# just a vague "loop looks off" comment.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## review: review-offbyone"

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
has_condition = "<=" in blob
has_symptom = any(kw in blob for kw in ("empty page", "extra page", "trailing page", "extra empty"))

fails = []
if not (has_condition or has_symptom):
    fails.append("doesn't name the <= condition or the resulting extra/empty trailing page symptom")

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
