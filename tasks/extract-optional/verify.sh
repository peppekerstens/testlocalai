#!/usr/bin/env bash
# Extraction check (archetype: optional-field omission discipline). The
# text explicitly says priority/board are unset — a model that writes
# "priority": null or "priority": "unset" is emitting a value that isn't
# actually there, violating this project's own real "omit, don't null"
# convention. status isn't mentioned at all (an even easier omit case).
# Only id/summary should be present.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## extract: extract-optional"

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

want = {"id": 7788, "summary": "Printer offline in accounting department"}
optional_keys = {"status", "priority", "board"}

fails = []
for k, v in want.items():
    if k not in obj:
        fails.append(f"missing required field '{k}'")
    elif obj[k] != v:
        fails.append(f"field '{k}' wrong: {obj[k]!r} (expected {v!r})")

present_optional = optional_keys & set(obj.keys())
if present_optional:
    fails.append(
        f"emitted optional field(s) not actually given a value in the text "
        f"(should be omitted, not set to null/guessed): {sorted(present_optional)} "
        f"= {[obj[k] for k in sorted(present_optional)]!r}"
    )

extra = set(obj.keys()) - set(want.keys()) - optional_keys
if extra:
    fails.append(f"unexpected extra fields not in schema: {sorted(extra)}")

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
