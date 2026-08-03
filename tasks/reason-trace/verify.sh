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

# The required tokens above are individually insufficient — input.md's own
# three bullets already contain every one of them (restart, in-memory Map,
# 400, re-initialize), so echoing input.md verbatim previously passed with
# zero actual tracing. Two more checks close that: (1) input.md's own
# bullet-list structure must not survive into the answer — a real trace is
# prose connecting the dots, not the source's list; (2) "restart" and "400"
# must appear close together, proving the answer actually connects the
# restart scenario to the session-loss consequence, not just separately
# mentioning both (input.md discusses the 400 only in its third bullet,
# about round-robin load-balancing — a different scenario from the restart
# this task asks about).
BULLET_LINES="$(grep -cE '^- ' "$OUT" || true)"
if [ "$BULLET_LINES" -ge 2 ]; then
  echo "- source's bullet-list structure copied ($BULLET_LINES bullet lines) — not a synthesized trace"
  FAIL=1
fi
if ! python3 -c "
import re, sys
text = open('$OUT', encoding='utf-8').read()
restarts = [m.start() for m in re.finditer(r'restart', text, re.I)]
fours = [m.start() for m in re.finditer(r'\b400\b', text)]
sys.exit(0 if any(abs(r - f) < 300 for r in restarts for f in fours) else 1)
"; then
  echo "- 'restart' and '400' are not discussed near each other — doesn't connect the restart to the session-loss consequence"
  FAIL=1
fi
[ "$FAIL" -eq 0 ] && echo "- genuinely connects restart to the 400 consequence, not a source copy: PASS"

if [ "$FAIL" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
