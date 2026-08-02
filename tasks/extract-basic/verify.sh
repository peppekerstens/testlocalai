#!/usr/bin/env bash
# Extraction check (archetype: basic flat extraction). Parses the output
# as JSON and checks each field by value, not by grepping for substrings
# (a substring match would pass a wrong summary that merely contains one
# right word).
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## extract: extract-basic"

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

want = {
    "id": 4521,
    "summary": "Email sync failing for all users on Exchange integration",
    "status": "Open",
    "priority": "High",
}

fails = []
for k, v in want.items():
    if k not in obj:
        fails.append(f"missing field '{k}'")
    elif obj[k] != v:
        fails.append(f"field '{k}' wrong: {obj[k]!r} (expected {v!r})")
extra = set(obj.keys()) - set(want.keys())
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
