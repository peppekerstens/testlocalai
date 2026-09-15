#!/usr/bin/env bash
# Extraction check (archetype: numeric/currency normalization). The text
# states daysOpen and cost in prose/currency form ("twenty-three days",
# "$1,250.50") — the model must normalize both to plain JSON numbers, not
# pass through the words, the "$", or the thousands separator.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## extract: extract-numeric"

RESULT=$(python3 - "$OUT" <<'PY'
import json, re, sys

text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.S)
if not m:
    print("FAIL no fenced json block found")
    sys.exit(0)

try:
    obj = json.loads(m.group(1))
except Exception as e:
    print(f"FAIL json block did not parse: {e}")
    sys.exit(0)

fails = []

if obj.get("id") != 6210:
    fails.append(f"id wrong: {obj.get('id')!r} (expected 6210)")
if obj.get("summary") != "Server migration overran the estimate":
    fails.append(f"summary wrong: {obj.get('summary')!r}")

days = obj.get("daysOpen")
if isinstance(days, bool) or not isinstance(days, (int, float)):
    fails.append(f"daysOpen is not a number: {days!r}")
elif days != 23:
    fails.append(f"daysOpen wrong: {days!r} (expected 23)")

cost = obj.get("cost")
if isinstance(cost, bool) or not isinstance(cost, (int, float)):
    fails.append(f"cost is not a number: {cost!r}")
elif abs(float(cost) - 1250.50) > 0.001:
    fails.append(f"cost wrong: {cost!r} (expected 1250.50)")

extra = set(obj.keys()) - {"id", "summary", "daysOpen", "cost"}
if extra:
    fails.append(f"unexpected extra fields: {sorted(extra)}")

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
