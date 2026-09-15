#!/usr/bin/env bash
# Tool-use check (archetype: sequentially dependent multi-step call).
# Step 2's companyId is only knowable after step 1 runs — the model must
# not fabricate a concrete number for it, and must reference step 1's
# result instead. Distinct from tool-multi's two INDEPENDENT calls.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## tool-use: tool-chain"

RESULT=$(python3 - "$OUT" <<'PY'
import json, re, sys

text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"```(?:json)?\s*(\[.*?\])\s*```", text, re.S)
if not m:
    print("FAIL no fenced json array block found")
    sys.exit(0)

try:
    steps = json.loads(m.group(1))
except Exception as e:
    print(f"FAIL json block did not parse: {e}")
    sys.exit(0)

fails = []
if not isinstance(steps, list) or len(steps) != 2:
    print(f"FAIL expected a 2-step array, got: {steps!r}")
    sys.exit(0)

s1, s2 = steps[0], steps[1]

if s1.get("tool") != "list_companies":
    fails.append(f"step 1 wrong tool: {s1.get('tool')!r} (expected list_companies)")
if s1.get("arguments") not in ({}, None):
    fails.append(f"step 1 should take no arguments, got: {s1.get('arguments')!r}")

if s2.get("tool") != "search_tickets":
    fails.append(f"step 2 wrong tool: {s2.get('tool')!r} (expected search_tickets)")
args2 = s2.get("arguments")
if not isinstance(args2, dict) or "companyId" not in args2:
    fails.append("step 2 missing a companyId argument")
else:
    cid = args2["companyId"]
    if isinstance(cid, (int, float)):
        fails.append(f"step 2 fabricated a concrete companyId number: {cid!r} (not knowable before step 1 runs)")
    elif isinstance(cid, str):
        low = cid.lower()
        if not any(kw in low for kw in ("step 1", "previous", "result", "returned", "from list_companies")):
            fails.append(f"step 2 companyId placeholder doesn't reference step 1's result: {cid!r}")
    else:
        fails.append(f"step 2 companyId has an unexpected type: {cid!r}")

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
