#!/usr/bin/env bash
# Tool-use check (archetype: exact argument schema fidelity). The request
# text says "company ID 88" in prose — the model must map that to the
# tool's REAL argument key (`companyId`, camelCase, not `company_id` or
# `id`) and a JSON number (not the string "88"). Also checks it picked
# list_contacts, not search_tickets (both take a lone companyId argument,
# so tool identity itself must come from what's actually being asked for).
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## tool-use: tool-args"

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
if obj.get("tool") != "list_contacts":
    fails.append(f"wrong tool: {obj.get('tool')!r} (expected list_contacts)")
args = obj.get("arguments")
if not isinstance(args, dict):
    fails.append("arguments is not an object")
else:
    if "companyId" not in args:
        wrong_keys = [k for k in args if k.lower().replace("_", "") == "companyid"]
        if wrong_keys:
            fails.append(f"wrong argument key name: {wrong_keys[0]!r} (expected exactly 'companyId')")
        else:
            fails.append("arguments missing 'companyId' key")
    else:
        val = args["companyId"]
        if isinstance(val, str):
            fails.append(f"companyId is a string {val!r}, expected a JSON number")
        elif val != 88:
            fails.append(f"companyId wrong: {val!r} (expected 88)")
    extra = set(args.keys()) - {"companyId"}
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
