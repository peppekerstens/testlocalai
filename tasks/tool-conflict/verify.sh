#!/usr/bin/env bash
# Tool-use check (archetype: compound failure diagnosis, hardest tool
# task). Combines tool-none's hallucination-resistance skill with
# tool-clarify's missing-argument skill in one answer — each of the 2
# request parts fails for a DIFFERENT reason, and the model must tell
# them apart, not give one generic "can't do it" answer twice.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## tool-use: tool-conflict"

RESULT=$(python3 - "$OUT" <<'PY'
import json, re, sys

text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"```(?:json)?\s*(\[.*?\])\s*```", text, re.S)
if not m:
    print("FAIL no fenced json array block found")
    sys.exit(0)

try:
    items = json.loads(m.group(1))
except Exception as e:
    print(f"FAIL json block did not parse: {e}")
    sys.exit(0)

REAL_TOOLS = {"list_companies", "list_contacts", "search_tickets",
              "get_ticket_details", "describe_obfuscation_policy"}

if not isinstance(items, list) or len(items) != 2:
    print(f"FAIL expected a 2-item array, got: {items!r}")
    sys.exit(0)

fails = []

# Item 1: delete request -- no tool can do this (hallucination-resistance skill)
i1 = items[0]
t1 = i1.get("tool")
if t1 is not None:
    fails.append(f"item 1 (delete): picked/invented a tool ({t1!r}) instead of tool: null")
else:
    r1 = (i1.get("reason") or "").lower()
    if not any(kw in r1 for kw in ("read-only", "read only", "no delete", "no write",
                                     "can't delete", "cannot delete", "does not exist",
                                     "doesn't exist", "no tool")):
        fails.append(f"item 1 reason doesn't explain the read-only/no-delete gap: {r1!r}")

# Item 2: contacts request -- missing companyId (clarification skill)
i2 = items[1]
t2 = i2.get("tool")
if t2 is not None:
    fails.append(f"item 2 (contacts): called a tool ({t2!r}) instead of asking for the missing companyId")
    args2 = i2.get("arguments")
    if isinstance(args2, dict) and "companyId" in args2:
        fails.append(f"item 2 invented a companyId not present in the request: {args2['companyId']!r}")
else:
    r2 = (i2.get("reason") or "").lower()
    if "companyid" not in r2 and "company id" not in r2 and "company" not in r2:
        fails.append(f"item 2 reason doesn't name the missing companyId/company: {r2!r}")

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
