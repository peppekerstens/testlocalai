#!/usr/bin/env bash
# Review check (archetype: IDisposable resource leak). writer (a
# StreamWriter) is opened without a using block or try/finally and is
# never disposed — a real, common .NET resource-leak category. Requires
# naming the missing dispose/using and the concrete consequence (leak or
# unflushed buffered data), not a vague style complaint.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## review: review-dispose"

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
has_dispose = any(kw in blob for kw in ("dispose", "using", "using block", "using statement"))
has_consequence = any(kw in blob for kw in ("leak", "not flushed", "never flushed",
                                              "not written", "never reach", "never written",
                                              "buffered", "file handle"))

fails = []
if not has_dispose:
    fails.append("doesn't name the missing Dispose/using")
if not has_consequence:
    fails.append("doesn't explain the concrete consequence (leak or unflushed buffer)")

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
