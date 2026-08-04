#!/usr/bin/env bash
# Tier 2 gate: mechanically implements AGENTS.md's "Tier 2 gate - decide
# automatically, do not ask" rule. Given a Tier-1-settled report, compute
# the specialist pass rate and apply the fixed 60% threshold - a rule
# machine, not a judgment call, so it belongs in a script, not prose an
# agent re-derives (and could mis-remember the threshold for) every cycle.
#
# Usage: bash bench/tier2-gate.sh <report-file>
#   report-file: a bench/report.sh output, e.g.
#                models/qwen3.5-9b/reports/report-reason-20260804-160858.md
#
# Exit code: 0 if the gate says GO (>=60%, run Tier 2), 1 if SKIP (<60%).
# Prints the computed rate and decision either way - script the check,
# not the "what does this mean" framing, which stays human/agent-readable
# output rather than another thing to parse.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

REPORT_FILE="${1:?usage: tier2-gate.sh <report-file>}"
[ -f "$REPORT_FILE" ] || { echo "ERROR: $REPORT_FILE not found" >&2; exit 2; }

RESULT="$(python3 - "$SELF_DIR/lib" "$REPORT_FILE" <<'PY'
import sys
lib_dir, report_file = sys.argv[1:]
sys.path.insert(0, lib_dir)
from report_parse import parse_verdicts, pass_rate

verdicts = parse_verdicts(report_file)
passed, total, rate = pass_rate(verdicts)
decision = "GO" if rate >= 0.60 else "SKIP"
print(f"{passed}|{total}|{rate:.4f}|{decision}")
PY
)"

IFS='|' read -r PASSED TOTAL RATE DECISION <<< "$RESULT"
PCT="$(python3 -c "print(f'{float('"$RATE"')*100:.0f}')")"

echo "Tier 2 gate: $PASSED/$TOTAL specialist tasks PASS (${PCT}%)"
if [ "$DECISION" = "GO" ]; then
  echo "VERDICT: GO — >=60% specialist hit rate, run Tier 2 generalist search."
  exit 0
else
  echo "VERDICT: SKIP — <60% specialist hit rate, go straight to Confirm on the Tier 1 result. No exception, no question asked (AGENTS.md)."
  exit 1
fi
