#!/usr/bin/env bash
# Tool-use check (archetype: missing-parameter clarification). The right
# tool (list_contacts) is obvious, but its required companyId is never
# stated. The model must recognize the call cannot be made and ask for the
# missing value (tool: null) instead of inventing a companyId.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## tool-use: tool-clarify"

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
tool = obj.get("tool")
if tool is not None:
    fails.append(f"called a tool ({tool!r}) instead of asking for the missing companyId")
    args = obj.get("arguments")
    if isinstance(args, dict) and "companyId" in args:
        fails.append(f"invented a companyId value not present in the request: {args['companyId']!r}")
else:
    reason = (obj.get("reason") or "").lower()
    if not reason:
        fails.append("tool is null but no reason given")
    elif "companyid" not in reason and "company id" not in reason and "company" not in reason:
        fails.append(f"reason doesn't name the missing companyId/company: {reason!r}")

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
