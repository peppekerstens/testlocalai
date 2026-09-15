#!/usr/bin/env bash
# Review check (archetype: exception swallowing). catch (Exception)
# discards the real error and returns an empty config -- the process
# doesn't crash, it silently obfuscates nothing while looking healthy.
# Requires naming the catch/swallow and the actual consequence (no
# obfuscation / hidden startup error), not a vague "should log this."
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## review: review-swallow"

RESULT=$(python3 - "$OUT" <<'PY'
import json, re, sys

text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"```(?:json)?\s*(\{.*\})\s*```", text, re.S)
if not m:
    print("FAIL no fenced json block found")
    sys.exit(0)

try:
    obj = json.loads(m.group(1))
except Exception as e:
    print(f"FAIL json block did not parse: {e}")
    sys.exit(0)

bugs = obj.get("bugs")
if not isinstance(bugs, list):
    print("FAIL 'bugs' is not an array")
    sys.exit(0)
if len(bugs) == 0:
    print("FAIL reported no bugs (there is a real one — missed it)")
    sys.exit(0)

blob = json.dumps(bugs).lower()
has_swallow = any(kw in blob for kw in ("catch", "swallow", "swallowed"))
has_consequence = any(kw in blob for kw in ("empty config", "no obfuscation", "nothing is obfuscated",
                                              "obfuscates nothing", "not obfuscated", "silently",
                                              "hides the", "hidden", "real error"))

fails = []
if not has_swallow:
    fails.append("doesn't name the catch block that swallows the error")
if not has_consequence:
    fails.append("doesn't explain the actual consequence (silent empty config / no obfuscation)")

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
