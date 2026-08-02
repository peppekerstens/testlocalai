#!/usr/bin/env bash
# Review check (archetype: thread-safety bug). Plain Dictionary is not
# thread-safe under concurrent tool calls — requires naming the
# Dictionary/thread-safety mechanism (or ConcurrentDictionary as the fix),
# not just a vague "looks unsafe" comment.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## review: review-concurrency"

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
has_thread_safety = any(kw in blob for kw in ("thread-safe", "thread safe", "not thread", "race", "concurrent"))
has_mechanism = "dictionary" in blob

fails = []
if not has_thread_safety:
    fails.append("doesn't identify this as a thread-safety/concurrency bug")
if not has_mechanism:
    fails.append("doesn't name Dictionary as the specific unsafe type")

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
