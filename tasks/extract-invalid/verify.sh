#!/usr/bin/env bash
# Extraction check (archetype: out-of-schema enum value, hardest extract
# task). "Duplicate" is not one of the schema's 3 allowed status values —
# the model must map it to the defined "Unknown" sentinel, not force-fit
# it to the nearest guess (e.g. "Closed"). Mirrors extract-ambiguous's
# "resist inventing a plausible value" skill for an out-of-domain value.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## extract: extract-invalid"

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

if obj.get("id") != 8823:
    fails.append(f"id wrong: {obj.get('id')!r} (expected 8823)")
if obj.get("summary") != "VPN client crashes on launch, Windows 11 only":
    fails.append(f"summary wrong: {obj.get('summary')!r}")

status = obj.get("status")
if status in ("Closed", "Open", "Pending"):
    fails.append(f"force-fit the out-of-schema value into an allowed one: {status!r}")
elif status != "Unknown":
    fails.append(f"status wrong: {status!r} (expected 'Unknown')")

extra = set(obj.keys()) - {"id", "summary", "status"}
if extra:
    fails.append(f"unexpected extra fields: {sorted(extra)}")

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
