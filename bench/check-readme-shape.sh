#!/usr/bin/env bash
# Mechanically implements AGENTS.md's Final-report checkpoint: "diff it
# against templates/new-model/MODEL-README-SCAFFOLD.md... run grep
# '^## ' on both and compare the two lists side by side." Purely
# structural (heading presence), zero judgment involved - the exact
# failure this exists for (all 4 qwen3.5-* READMEs shipped missing
# "How to optimize" entirely, invisible on a read-through, only caught
# when someone manually ran this exact diff) is a structural gap a
# script can check every time, not just when someone remembers to ask.
#
# Usage: bash bench/check-readme-shape.sh [--verbose] <model>
# Exit code: 0 if every required scaffold heading is present, 1 if any
# are missing (prints which ones). --verbose enables bash's own command
# trace (`set -x`) into the log; every run always writes a full
# transcript to bench/logs/check-readme-shape.sh-<timestamp>.log
# regardless.
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
LOG_FILE="$LOG_DIR/check-readme-shape.sh-$(date -u +%Y%m%d-%H%M%S)-$$.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[check-readme-shape.sh] full trace: $LOG_FILE"
if [ "$VERBOSE" -eq 1 ]; then
  export PS4='+ $(date -u +%H:%M:%S) ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
  set -x
fi

MODEL="${1:?usage: check-readme-shape.sh [--verbose] <model>}"
MODEL_DIR_NAME="$(echo "$MODEL" | tr ':' '-')"
README="$ORCH_DIR/models/$MODEL_DIR_NAME/README.md"
SCAFFOLD="$ORCH_DIR/templates/new-model/MODEL-README-SCAFFOLD.md"

[ -f "$README" ] || { echo "ERROR: $README not found" >&2; exit 2; }
[ -f "$SCAFFOLD" ] || { echo "ERROR: $SCAFFOLD not found" >&2; exit 2; }

MISSING=0
while IFS= read -r heading; do
  if [[ "$heading" == "## <Role> role:"* ]]; then
    # templated heading - require at least one "## X role: ..." in the
    # real README, not this literal placeholder text
    if ! grep -qE '^## [A-Za-z].* role:' "$README"; then
      echo "MISSING (pattern): a '## <Role> role: ...' section (e.g. 'Documenter role: final report')"
      MISSING=1
    fi
  else
    if ! grep -qF "$heading" "$README"; then
      echo "MISSING: $heading"
      MISSING=1
    fi
  fi
done < <(grep "^## " "$SCAFFOLD")

if [ "$MISSING" -eq 0 ]; then
  echo "VERDICT: OK - every scaffold heading present in $MODEL_DIR_NAME/README.md"
  exit 0
else
  echo "VERDICT: INCOMPLETE - see MISSING lines above"
  exit 1
fi
