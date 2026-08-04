#!/usr/bin/env bash
# Advisory checks for the two AGENTS.md report-completion rules that
# CANNOT be verified reliably by keyword matching, only nudged at:
#   1. Sample-size caveat (checklist item 4): every Findings bullet for
#      a FAIL task should say something like "single draw" / "n=1" /
#      "sample-size caveat" when this is the only draw of that task.
#   2. Task+lever specificity ("Suggested next steps" rule): every
#      suggestion should name a specific task, not "steer more" / "try
#      again".
#
# Unlike bench/report-check.sh's placeholder check, these are NOT hard
# gates - a report can genuinely satisfy both rules using phrasing this
# script doesn't recognize, and can just as easily contain the magic
# words without genuinely satisfying the rule (e.g. a stray "single
# draw" copy-pasted from another bullet). Presence/absence of these
# words is weak evidence, not proof - so this always exits 0 and prints
# WARNING lines for a human/agent to judge, never a pass/fail verdict.
# This is the intentional Tier-4 remainder AGENTS.md's checklist still
# needs real judgment for; see bench/report-check.sh for the one part
# of report-completion that #is# a reliable mechanical gate.
#
# Usage: bash bench/report-heuristics.sh [--verbose] <report-file>
# Exit code: 0 always (advisory only), 2 if the file doesn't exist.
# --verbose enables bash's own command trace (`set -x`) into the log;
# every run always writes a full transcript to
# bench/logs/report-heuristics.sh-<timestamp>.log regardless.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
ORCH_DIR="$(cd "$SELF_DIR/.." && pwd)"

VERBOSE=0
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--verbose" ]; then
    VERBOSE=1
  else
    ARGS+=("$arg")
  fi
done
set -- "${ARGS[@]}"

LOG_DIR="$ORCH_DIR/bench/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/report-heuristics.sh-$(date -u +%Y%m%d-%H%M%S)-$$.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[report-heuristics.sh] full trace: $LOG_FILE"
if [ "$VERBOSE" -eq 1 ]; then
  export PS4='+ $(date -u +%H:%M:%S) ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
  set -x
fi

REPORT_FILE="${1:?usage: report-heuristics.sh [--verbose] <report-file>}"
[ -f "$REPORT_FILE" ] || { echo "ERROR: $REPORT_FILE not found" >&2; exit 2; }

section() {
  awk -v h="$1" '
    $0 == h { found=1; next }
    found && /^## / { exit }
    found { print }
  ' "$REPORT_FILE"
}

FINDINGS="$(section "## Findings")"
NEXT_STEPS="$(section "## Suggested next steps")"

WARNINGS=0

HAS_FAIL="$(python3 - "$SELF_DIR/lib" "$REPORT_FILE" <<'PY'
import sys
lib_dir, report_file = sys.argv[1:]
sys.path.insert(0, lib_dir)
from report_parse import parse_verdicts
verdicts = parse_verdicts(report_file)
print("yes" if "FAIL" in verdicts.values() else "no")
PY
)"

if [ "$HAS_FAIL" = "yes" ]; then
  if ! echo "$FINDINGS" | grep -qiE 'single draw|n=1|n=3|sample.?size|reliabilit|more draws'; then
    echo "WARNING: Results has a FAIL task but Findings doesn't mention a sample-size/single-draw caveat (checklist item 4) — verify by reading, this may just be phrased differently."
    WARNINGS=$((WARNINGS + 1))
  fi
fi

if echo "$NEXT_STEPS" | grep -qiE '\b(steer more|try again)\b'; then
  echo "WARNING: Suggested next steps contains a banned vague phrase ('steer more' / 'try again') — AGENTS.md requires a specific task + lever instead."
  WARNINGS=$((WARNINGS + 1))
fi

if [ -n "$NEXT_STEPS" ] && ! echo "$NEXT_STEPS" | grep -qE '`[^`]+`'; then
  echo "WARNING: Suggested next steps has no backtick-quoted task name anywhere — check it actually names specific tasks, not general advice."
  WARNINGS=$((WARNINGS + 1))
fi

if [ "$WARNINGS" -eq 0 ]; then
  echo "VERDICT: no heuristic issues found (advisory only — does not replace reading the report)."
else
  echo "VERDICT: $WARNINGS advisory warning(s) above — judge each by reading the actual text, not just this script's output."
fi
exit 0
