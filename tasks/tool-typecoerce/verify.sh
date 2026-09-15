#!/usr/bin/env bash
# Tool-use check (archetype: argument type coercion). The request states
# the ID as "#4,521" — a `#` prefix and a thousands separator, neither of
# which belongs in the argument. The model must produce the JSON number
# 4521, not the string "4521", "#4521", or "4,521".
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## tool-use: tool-typecoerce"

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
if obj.get("tool") != "get_ticket_details":
    fails.append(f"wrong tool: {obj.get('tool')!r} (expected get_ticket_details)")
args = obj.get("arguments")
if not isinstance(args, dict):
    fails.append("arguments is not an object")
else:
    if "ticketId" not in args:
        fails.append("arguments missing 'ticketId' key")
    else:
        tid = args["ticketId"]
        if isinstance(tid, bool) or not isinstance(tid, int):
            fails.append(f"ticketId is not a JSON number/int: {tid!r} ({type(tid).__name__})")
        elif tid != 4521:
            fails.append(f"ticketId wrong value: {tid!r} (expected 4521)")
    extra = set(args.keys()) - {"ticketId"}
    if extra:
        fails.append(f"unexpected extra argument keys: {sorted(extra)}")

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
