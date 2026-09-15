#!/usr/bin/env bash
# Review check (archetype: multiple distinct bugs, must find ALL). Two
# real, independent bugs share one snippet: an inverted hasMore condition
# and a missing null check on an optional field. Requires >=2 reported
# bugs and requires both specific mechanisms named — reporting only one
# (even correctly) fails, since the task tests exhaustiveness.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## review: review-multi"

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
if len(bugs) < 2:
    print(f"FAIL found only {len(bugs)} bug(s) — there are 2 distinct real bugs, must find both")
    sys.exit(0)

blob = json.dumps(bugs).lower()
has_hasmore = "hasmore" in blob and any(kw in blob for kw in
    ("backwards", "inverted", "wrong direction", "should be >", "flipped", "opposite"))
has_null = "defaultcontact" in blob and any(kw in blob for kw in
    ("null", "nullreferenceexception", "optional"))

fails = []
if not has_hasmore:
    fails.append("doesn't correctly name the inverted hasMore condition")
if not has_null:
    fails.append("doesn't correctly name the missing null check on DefaultContact")

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
