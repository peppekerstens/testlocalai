#!/usr/bin/env bash
# Tool-use check (archetype: basic single-tool selection). The output must
# be a parseable JSON object naming the one correct tool and the exact
# argument shape (name + type) from TOOL_CONTRACTS.md — not just mentioning
# the tool name in prose.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## tool-use: tool-select"

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
    elif args["ticketId"] != 4521:
        fails.append(f"ticketId wrong: {args['ticketId']!r} (expected 4521 as a number)")
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
