#!/usr/bin/env bash
# Tool-use check (archetype: hallucination resistance). The request implies
# a "create ticket" action that would be convenient if it existed — no
# such tool is in the real list. The model must say so (tool: null) rather
# than inventing a plausible-sounding tool name (e.g. create_ticket,
# open_ticket, add_ticket) that isn't one of the 5 real tools.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## tool-use: tool-none"

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

REAL_TOOLS = {"list_companies", "list_contacts", "search_tickets",
              "get_ticket_details", "describe_obfuscation_policy"}

fails = []
tool = obj.get("tool")
if tool is not None:
    if tool in REAL_TOOLS:
        fails.append(f"picked a real tool ({tool!r}) that cannot actually create a ticket")
    else:
        fails.append(f"hallucinated a tool that doesn't exist: {tool!r}")
else:
    reason = (obj.get("reason") or "").lower()
    if not reason:
        fails.append("tool is null but no reason given")
    elif not any(kw in reason for kw in ("read-only", "read only", "no create", "no write", "does not exist", "doesn't exist", "no tool")):
        fails.append(f"reason present but doesn't explain why (no read-only/no-create-tool language): {reason!r}")

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
