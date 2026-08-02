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

# required: the culprit variable + the exact log-line mechanism (both are in
# the prompt material — fair to require)
REQUIRED=("CW_PRIVATE_KEY" "Missing required environment variable")
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- required tokens present: PASS"

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
