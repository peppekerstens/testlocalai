#!/usr/bin/env bash
# Reasoning check (role: reasoner). The trace must follow a restart through
# the session map, token regeneration, and the 400 the client gets — naming
# the in-memory transports map. No exact-match — phrasing varies.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## reasoning: reason-trace"

FAIL=0

# required: restart, session mechanism (in-memory map), the 400, token change.
# These alone discriminate: a wrong-mechanism answer (persistence/resumption)
# misses "in-memory", "400", "No valid session ID", and "Map". No forbidden
# list — the source doc legitimately contains the round-robin/load-balancer
# paragraph, so penalizing those tokens would false-negative a correct answer
# that cites the document's own content.
REQUIRED=("restart" "in-memory" "400" "No valid session ID" "re-initialize" "Map")
for t in "${REQUIRED[@]}"; do
  if ! grep -qF "$t" "$OUT"; then
    echo "- missing required token: '$t'"
    FAIL=1
  fi
done
[ "$FAIL" -eq 0 ] && echo "- required tokens present: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
