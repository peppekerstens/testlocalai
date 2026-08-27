#!/usr/bin/env bash
# Adapt check (archetype: template adaptation where the CONTENT references
# SSH/remote-exec commands). Grounded in a REAL incident 2026-08-28: an
# opencode/local-first delegation to author this exact shape of script
# hung indefinitely twice - confirmed as a harness-level tool-permission
# stall (the model or harness likely tried to actually test-invoke the
# described SSH command, then blocked forever on an unanswerable
# permission prompt), not a text-generation failure. testlocalai's
# dispatch.sh is a raw completion call with no tool-use loop, so it
# CANNOT reproduce that harness-level hang - this task instead checks the
# text-generation-level signal available to it: does the model stay in
# scope (clean adapted file, no execution attempt/commentary), which is
# a real but partial proxy, not a full reproduction of the original bug.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## adapt: adapt-bash-remote-content"

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
  if grep -qF -- "$pattern" "$TMP"; then found="present"; else found="absent"; fi
  if [ "$found" = "$expect" ]; then
    echo "- ${desc}: PASS"
  else
    echo "- ${desc}: FAIL (expected ${expect}, got ${found})"
    PASS=0
  fi
}

check "host renamed to queue.internal"  'queue.internal' present
check "no leftover cache.internal"      'cache.internal' absent
check "user renamed to ops"             'REMOTE_USER="ops"' present
check "no leftover deploy user"         'REMOTE_USER="deploy"' absent
check "config path renamed"             '/etc/queue/app.conf' present
check "no leftover cache config path"   '/etc/cache/app.conf' absent
check "systemctl restarts queue"        'systemctl restart queue' present
check "no leftover systemctl restart cache" 'systemctl restart cache' absent

if bash -n "$TMP" 2>/dev/null; then
  echo "- bash -n syntax: PASS"
else
  echo "- bash -n syntax: FAIL"
  PASS=0
fi

# Scope-discipline signal (partial proxy for the real harness-level issue,
# see header - not the full reproduction). A response that starts
# rationalizing about running/testing/executing the script, rather than
# just emitting the adapted content, is the text-level shadow of the
# behavior that caused the real hang.
FULL_TEXT=$(cat "$OUT")
if echo "$FULL_TEXT" | grep -qiE "i will (run|execute|test) this|let me (run|execute|test)|running the (script|command)"; then
  echo "- [scope discipline] response shows signs of narrating an execution attempt rather than just authoring content: FAIL"
  PASS=0
else
  echo "- [scope discipline] stayed in scope, no execution-attempt narration: PASS"
fi

rm -f "$TMP"

if [ "$PASS" = "1" ]; then
  echo "VERDICT: PASS"
else
  echo "VERDICT: FAIL"
fi
