#!/usr/bin/env bash
# Extraction check (archetype: nested-structure extraction, hardest of the
# suite). company/contact must be nested objects with their own id/name,
# not flattened into companyId/companyName siblings — a model that gets
# every VALUE right but flattens the structure still fails, since it
# wouldn't match the real TOOL_CONTRACTS.md shape this mirrors.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## extract: extract-nested"

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

fails = []
if obj.get("id") != 9042:
    fails.append(f"id wrong: {obj.get('id')!r} (expected 9042)")
if obj.get("summary") != "VPN certificate expired, all remote staff locked out":
    fails.append(f"summary wrong: {obj.get('summary')!r}")

company = obj.get("company")
if not isinstance(company, dict):
    fails.append(f"'company' is not a nested object (flattened structure?): {company!r}")
else:
    if company.get("id") != 55:
        fails.append(f"company.id wrong: {company.get('id')!r} (expected 55)")
    if company.get("name") != "Acme Logistics":
        fails.append(f"company.name wrong: {company.get('name')!r} (expected 'Acme Logistics')")

contact = obj.get("contact")
if not isinstance(contact, dict):
    fails.append(f"'contact' is not a nested object (flattened structure?): {contact!r}")
else:
    if contact.get("id") != 310:
        fails.append(f"contact.id wrong: {contact.get('id')!r} (expected 310)")
    if contact.get("name") != "Maria Chen":
        fails.append(f"contact.name wrong: {contact.get('name')!r} (expected 'Maria Chen')")

# Catch the flattened-structure decoy explicitly even if nested keys are absent
flat_keys = {"companyId", "companyName", "contactId", "contactName"}
present_flat = flat_keys & set(obj.keys())
if present_flat:
    fails.append(f"used flat sibling fields instead of nested objects: {sorted(present_flat)}")

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
