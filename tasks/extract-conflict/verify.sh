#!/usr/bin/env bash
# Extraction check (archetype: temporal correction). The text states an
# initial value (Medium) and then a corrected value (High) for the same
# field — the model must extract the corrected/final value, not the
# first mention. Picking "Medium" is the exact trap this task tests.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## extract: extract-conflict"

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

if obj.get("id") != 3391:
    fails.append(f"id wrong: {obj.get('id')!r} (expected 3391)")
if obj.get("summary") != "Payroll export failing for EU region":
    fails.append(f"summary wrong: {obj.get('summary')!r}")

priority = obj.get("priority")
if priority == "Medium":
    fails.append("picked the stale, first-mentioned value 'Medium' instead of the correction")
elif priority != "High":
    fails.append(f"priority wrong: {priority!r} (expected 'High')")

extra = set(obj.keys()) - {"id", "summary", "priority"}
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
