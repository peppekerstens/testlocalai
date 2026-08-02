#!/usr/bin/env bash
# Review check (archetype: obvious null-reference bug). The comment
# directly states DefaultContact is optional, and the code accesses
# .Name on it without a null check — a NullReferenceException whenever
# the company has no default contact. Checks the model both flags SOME
# bug (non-empty bugs array) and specifically names the null/optional
# mechanism, not a vague "there might be an issue" without substance.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## review: review-null"

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
    print("FAIL reported no bugs (there is a real one — missed it, or a false negative)")
    sys.exit(0)

blob = json.dumps(bugs).lower()
has_target_line = "defaultcontact.name" in blob.replace(" ", "")
has_null_language = any(kw in blob for kw in ("null", "nullreference", "optional"))

fails = []
if not has_target_line:
    fails.append("no bug references the DefaultContact.Name access specifically")
if not has_null_language:
    fails.append("no bug mentions null/nullreference/optional — doesn't identify the actual mechanism")

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
