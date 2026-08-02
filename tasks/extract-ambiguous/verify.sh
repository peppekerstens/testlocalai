#!/usr/bin/env bash
# Extraction check (archetype: hallucination resistance for a REQUIRED
# field). The text never states a ticket number — the only correct value
# for the required `id` field is `null`. Any actual number is a
# hallucination, even a plausible-looking one. summary/status are checked
# loosely (keyword-based, prose has no canonical phrasing) since the
# hallucination-resistance point is specifically about `id`.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## extract: extract-ambiguous"

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
if "id" not in obj:
    fails.append("missing 'id' field entirely (schema requires it, even if null)")
elif obj["id"] is not None:
    fails.append(f"hallucinated a ticket id that was never in the text: {obj['id']!r} (expected null)")

status = str(obj.get("status", "")).lower()
if status != "open":
    fails.append(f"status wrong: {obj.get('status')!r} (expected 'Open')")

summary = str(obj.get("summary", "")).lower()
if not ("mail" in summary and ("server" in summary or "escalat" in summary)):
    fails.append(f"summary doesn't reflect the mail server / escalation content: {obj.get('summary')!r}")

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
