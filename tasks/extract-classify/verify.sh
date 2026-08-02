#!/usr/bin/env bash
# Extraction check (archetype: closed-set classification with a surface/
# rule mismatch trap). The note is worded urgently ("URGENT!!") but only
# affects one department (not ALL users, ruling out Critical) and a
# workaround exists (personal Gmail) — the correct answer per the given
# rules is High, not Critical. A model reacting to alarming wording
# instead of applying the definitions will pick Critical and fail.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## extract: extract-classify"

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

VALID = {"Critical", "High", "Medium", "Low"}
cat = obj.get("category")

fails = []
if cat not in VALID:
    fails.append(f"category {cat!r} is not one of the 4 valid labels {sorted(VALID)}")
elif cat != "High":
    fails.append(f"wrong category: {cat!r} (expected 'High' — affects multiple users but not ALL, and a workaround exists)")

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
