#!/usr/bin/env bash
# Tool-use check (archetype: policy-aware tool selection + fact recall).
# Combines picking the right introspection tool (describe_obfuscation_policy,
# not list_contacts itself) with correctly stating a specific, given fact
# (phone numbers are passthrough, NOT obfuscated) — a model that fixates on
# tool selection alone and gets the actual fact backwards must still fail.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## tool-use: tool-policy"

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
if obj.get("tool") != "describe_obfuscation_policy":
    fails.append(f"wrong tool: {obj.get('tool')!r} (expected describe_obfuscation_policy)")

answer = (obj.get("answer") or "").lower()
if not answer:
    fails.append("missing 'answer' field")
else:
    has_passthrough_claim = any(kw in answer for kw in (
        "not hidden", "not obfuscated", "passthrough", "pass through",
        "will show up", "show up", "real phone", "not redacted",
    ))
    wrong_claim = any(kw in answer for kw in (
        "are hidden", "are obfuscated", "will be hidden", "will be obfuscated",
        "phone numbers are redacted",
    ))
    if wrong_claim and not has_passthrough_claim:
        fails.append(f"answer wrongly claims phone numbers ARE hidden/obfuscated: {answer!r}")
    elif not has_passthrough_claim:
        fails.append(f"answer doesn't clearly state phone numbers are passthrough/unobfuscated: {answer!r}")

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
