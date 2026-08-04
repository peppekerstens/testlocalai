#!/usr/bin/env bash
# Reasoning check (role: reasoning). The diagnosis must name the exact
# missing variable and the fail-fast mechanism, and must not blame a
# different subsystem. No exact-match — phrasing varies.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## reasoning: reason-diagnose"

FAIL=0

# required: the culprit variable + the exact log-line (both are in the
# prompt material — fair to require).
REQUIRED=("CW_PRIVATE_KEY" "Missing required environment variable")
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- required tokens present: PASS"

# required: a description of the startup fail-fast mechanism (what
# validates the var and aborts), so a bare echo of the log line (zero
# diagnosis) still fails. NOT a literal "requireEnv" check — that
# internal function name is never shown anywhere in SPEC.md/input.md
# (only in expected.md, the answer key), so requiring the literal name
# was an undisclosed-token bug, not a fair reasoning check (found
# 2026-08-04, matches the doc-repair/doc-crossref shared-task-bug
# pattern — see models/qwen3.5-9b/history.md). Any one of these
# phrasings is an acceptable description of the same mechanism.
MECHANISM_PHRASES=("requireEnv" "validat" "fail-fast" "fail fast" "abort")
MECH_OK=0
for t in "${MECHANISM_PHRASES[@]}"; do
  if grep -qF "$t" "$OUT"; then
    MECH_OK=1
    break
  fi
done
if [ "$MECH_OK" -eq 0 ]; then
  echo "- missing mechanism description (one of: ${MECHANISM_PHRASES[*]})"
  FAIL=1
else
  echo "- mechanism description present: PASS"
fi

# forbidden: wrong-cause markers (config file / network / auth)
FORBIDDEN=("configuration file" "regex" "YAML" "ConnectWise API error" "fetch failed")
for t in "${FORBIDDEN[@]}"; do
  if grep -qF "$t" "$OUT"; then
    echo "- wrong-cause token present: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- no wrong-cause attribution: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
