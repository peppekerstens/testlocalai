#!/usr/bin/env bash
# Extraction check (archetype: multi-entity enumeration). Three tickets are
# mentioned in one paragraph, in prose (not a list) — the model must find
# all three, not stop after the first or merge them. Matched by id, not by
# array position, so order doesn't matter.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## extract: extract-multi"

RESULT=$(python3 - "$OUT" <<'PY'
import json, re, sys

text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"```(?:json)?\s*(\[.*?\])\s*```", text, re.S)
if not m:
    print("FAIL no fenced json array block found")
    sys.exit(0)

try:
    arr = json.loads(m.group(1))
except Exception as e:
    print(f"FAIL json block did not parse: {e}")
    sys.exit(0)

if not isinstance(arr, list):
    print("FAIL top-level json is not an array")
    sys.exit(0)

want = {
    101: {"summary": "VPN client won't connect on Windows", "status": "Open"},
    102: {"summary": "Password reset email not arriving", "status": "Closed"},
    103: {"summary": "Printer driver crash on login", "status": "In Progress"},
}

fails = []
by_id = {}
for el in arr:
    if isinstance(el, dict) and "id" in el:
        by_id[el["id"]] = el

for tid, fields in want.items():
    if tid not in by_id:
        fails.append(f"missing ticket {tid}")
        continue
    el = by_id[tid]
    for k, v in fields.items():
        if el.get(k) != v:
            fails.append(f"ticket {tid} field '{k}' wrong: {el.get(k)!r} (expected {v!r})")

if len(arr) != 3:
    fails.append(f"expected exactly 3 tickets, got {len(arr)}")

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
