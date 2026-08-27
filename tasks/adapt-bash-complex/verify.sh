#!/usr/bin/env bash
# Adapt check (archetype: multi-point substitution + a removal, plus a
# deliberate trap grounded in a REAL idiom observed 2026-08-28 during a
# live opencode/local-first delegation session: a literal find-replace on
# a number can leave a comment asserting something now-false ("matching
# the live worker VM 600" - this VM has never been live). Fact #5 in the
# SPEC gives the model what it needs to catch this, without explicitly
# instructing the fix - same shape as the real spec gap that produced the
# original idiom. PASS/FAIL is the 4 literal substitutions + syntax only
# (crisply gradable); whether the stale-claim implication got caught is
# reported separately as an idiom signal, not a hard requirement - a
# strict OUTPUT FORMAT that only allows the code block gives the model no
# clean channel to flag the issue in prose instead of just fixing it.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## adapt: adapt-bash-complex"

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

check "VMID default 600"           'VMID:-600' present
check "no leftover VMID default 500" 'VMID:-500' absent
check "WORKER_NAME billing"        'WORKER_NAME:-billing' present
check "no leftover reports"        'WORKER_NAME:-reports' absent
check "IP updated to .90"          '10.20.0.90/24' present
check "no leftover .50 IP"         '10.20.0.50/24' absent
check "gw unchanged at .1"         'gw=10.20.0.1' present
check "legacy fallback line removed" 'ip=dhcp' absent

if bash -n "$TMP" 2>/dev/null; then
  echo "- bash -n syntax: PASS"
else
  echo "- bash -n syntax: FAIL"
  PASS=0
fi

# Idiom signal only - does NOT affect VERDICT. Reports whether the model
# caught that "matching the live worker VM" is now a false claim (fact #5
# said this VM has never been live) rather than leaving it after a literal
# 500->600 substitution.
if grep -qF -- 'matching the live worker VM' "$TMP"; then
  echo "- [idiom, non-blocking] stale 'matching the live worker VM' claim NOT caught (left in after literal substitution, now reads 'VM 600' - still false, this VM was never live)"
else
  echo "- [idiom, non-blocking] stale 'matching the live worker VM' claim was removed/reworded - caught the implication"
fi

rm -f "$TMP"

if [ "$PASS" = "1" ]; then
  echo "VERDICT: PASS"
else
  echo "VERDICT: FAIL"
fi
