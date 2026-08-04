#!/usr/bin/env bash
# Mechanically implements AGENTS.md's "Completing a report: exactly what
# MUST be filled in after report.sh runs" check. report.sh always seeds
# ## Findings and ## Suggested next steps with a "<!-- NOT DONE YET"
# placeholder comment (see bench/report.sh) so a report that was never
# followed up reads as templated, not as "no findings" - this script
# just confirms the placeholder was actually replaced, since that's a
# structural grep, not a judgment call.
#
# Usage: bash bench/report-check.sh [--verbose] <report-file>
# Exit code: 0 if both sections were filled in, 1 if either still has
# the "NOT DONE YET" placeholder. --verbose enables bash's own command
# trace (`set -x`) into the log; every run always writes a full
# transcript to bench/logs/report-check.sh-<timestamp>.log regardless.
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
LOG_FILE="$LOG_DIR/report-check.sh-$(date -u +%Y%m%d-%H%M%S)-$$.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[report-check.sh] full trace: $LOG_FILE"
if [ "$VERBOSE" -eq 1 ]; then
  export PS4='+ $(date -u +%H:%M:%S) ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
  set -x
fi

REPORT_FILE="${1:?usage: report-check.sh [--verbose] <report-file>}"
[ -f "$REPORT_FILE" ] || { echo "ERROR: $REPORT_FILE not found" >&2; exit 2; }

INCOMPLETE=0

check_section() {
  local heading="$1"
  local section
  section="$(awk -v h="$heading" '
    $0 == h { found=1; next }
    found && /^## / { exit }
    found { print }
  ' "$REPORT_FILE")"
  if echo "$section" | grep -q "NOT DONE YET"; then
    echo "INCOMPLETE: $heading still has the report.sh placeholder"
    INCOMPLETE=1
  fi
}

check_section "## Findings"
check_section "## Suggested next steps"

if [ "$INCOMPLETE" -eq 0 ]; then
  echo "VERDICT: OK - Findings and Suggested next steps are both filled in"
  exit 0
else
  echo "VERDICT: INCOMPLETE - see lines above. Fill in per AGENTS.md's report-completion rule before treating this report as done."
  exit 1
fi
