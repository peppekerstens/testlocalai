#!/usr/bin/env bash
# Tool-use check (archetype: multi-tool sequencing). The request bundles
# two genuinely separate needs (open tickets, contact-on-file) that no
# single tool covers — the model must recognize BOTH calls are needed,
# not settle for the first plausible single tool. Order-independent.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## tool-use: tool-multi"

RESULT=$(python3 - "$OUT" <<'PY'
import json, re, sys

text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"```(?:json)?\s*(\[.*?\])\s*```", text, re.S)
if not m:
    print("FAIL no fenced json array block found")
    sys.exit(0)

try:
    calls = json.loads(m.group(1))
except Exception as e:
    print(f"FAIL json block did not parse: {e}")
    sys.exit(0)

if not isinstance(calls, list):
    print("FAIL top-level json is not an array")
    sys.exit(0)

want = [
    ("search_tickets", {"companyId": 205}),
    ("list_contacts", {"companyId": 205}),
]

fails = []
found_tools = [c.get("tool") if isinstance(c, dict) else None for c in calls]
for name, args in want:
    matches = [c for c in calls if isinstance(c, dict) and c.get("tool") == name]
    if not matches:
        fails.append(f"missing call to {name}")
        continue
    call_args = matches[0].get("arguments")
    if call_args != args:
        fails.append(f"{name} arguments wrong: {call_args!r} (expected {args!r})")

if len(calls) != 2:
    fails.append(f"expected exactly 2 calls, got {len(calls)} (tools: {found_tools})")

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
