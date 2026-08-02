#!/usr/bin/env bash
# Review check (archetype: async blocking pitfall). .Result blocks
# synchronously on a Task — a real deadlock/thread-starvation risk, not a
# style nit. Requires naming .Result and the deadlock/blocking mechanism,
# not just a vague "should be async" without the actual risk.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## review: review-async"

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
has_result = ".result" in blob
has_risk = any(kw in blob for kw in ("deadlock", "block", "thread"))

fails = []
if not has_result:
    fails.append("doesn't name .Result specifically")
if not has_risk:
    fails.append("doesn't explain the actual risk (deadlock/blocking/thread-starvation)")

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
