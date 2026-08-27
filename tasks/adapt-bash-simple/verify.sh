#!/usr/bin/env bash
# Adapt check (archetype: pure string-substitution template adaptation, no
# removal/rewrite needed). All 3 substitutions must apply everywhere they
# occur, including the comment header - a model that adapts the variables
# but misses the header comment ("Widget service") is a known idiom worth
# tracking separately from a model that misses a variable entirely.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## adapt: adapt-bash-simple"

CODE=$(python3 - "$OUT" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"```(?:bash|sh)?\s*\n(.*?)```", text, re.S)
print(m.group(1) if m else "")
PY
)

if [ -z "$CODE" ]; then
  echo "- no fenced bash block found"
  echo "VERDICT: FAIL"
  exit 0
fi

TMP="$(mktemp)"
printf '%s' "$CODE" > "$TMP"

PASS=1

check() {
  local desc="$1" pattern="$2" expect="$3"  # expect: present|absent
  if grep -qF -- "$pattern" "$TMP"; then
    found="present"
  else
    found="absent"
  fi
  if [ "$found" = "$expect" ]; then
    echo "- ${desc}: PASS"
  else
    echo "- ${desc}: FAIL (expected ${expect}, got ${found})"
    PASS=0
  fi
}

check "gadget replaces widget (var value)" 'SERVICE_NAME="gadget"' present
check "no leftover widget var value"       'SERVICE_NAME="widget"' absent
check "port 4100 applied"                  'SERVICE_PORT="4100"' present
check "no leftover port 4000"              'SERVICE_PORT="4000"' absent
check "scratch file renamed"               '/tmp/gadget-check.tmp' present
check "no leftover widget scratch path"    '/tmp/widget-check.tmp' absent
check "header comment renamed (Gadget)"    'Gadget service' present
check "no leftover header comment (Widget)" 'Widget service' absent

if bash -n "$TMP" 2>/dev/null; then
  echo "- bash -n syntax: PASS"
else
  echo "- bash -n syntax: FAIL"
  PASS=0
fi

rm -f "$TMP"

if [ "$PASS" = "1" ]; then
  echo "VERDICT: PASS"
else
  echo "VERDICT: FAIL"
fi
