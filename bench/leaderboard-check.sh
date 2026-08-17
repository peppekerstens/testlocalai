#!/usr/bin/env bash
# Mechanically implements the data/leaderboard.json half of AGENTS.md's
# "After a test run, persist it" rule: every role in a model's README
# Overview table must have a matching entry in data/leaderboard.json,
# or the leaderboard silently misses it even though the README itself
# is correct - the same "prose rule with no gate" failure mode that let
# all 4 qwen3.5-* READMEs ship without a required section (see
# check-readme-shape.sh's header comment for that incident).
#
# Existence-only check (does a row exist for this model+role) - never
# compares values against the README's numbers. The whole point of
# data/leaderboard.json is to avoid parsing README prose for real
# figures (see bench/leaderboard.py's docstring); this script doesn't
# either, it only confirms a row was added at all.
#
# Not applicable to models/claude-sonnet-5 (reference baseline, its own
# JSON section) or models/lfm2.5-vl-450m (scaffold, no Overview table
# yet) - don't run this against either.
#
# Usage: bash bench/leaderboard-check.sh [--verbose] <model>
# Exit code: 0 if every Overview-table role has a matching
# data/leaderboard.json entry, 1 if any are missing (prints which).
# --verbose enables bash's own command trace (`set -x`) into the log;
# every run always writes a full transcript to
# bench/logs/leaderboard-check.sh-<timestamp>-<pid>.log regardless.
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
LOG_FILE="$LOG_DIR/leaderboard-check.sh-$(date -u +%Y%m%d-%H%M%S)-$$.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[leaderboard-check.sh] full trace: $LOG_FILE"
if [ "$VERBOSE" -eq 1 ]; then
  export PS4='+ $(date -u +%H:%M:%S) ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
  set -x
fi

MODEL="${1:?usage: leaderboard-check.sh [--verbose] <model>}"
MODEL_DIR_NAME="$(echo "$MODEL" | tr ':' '-')"
README="$ORCH_DIR/models/$MODEL_DIR_NAME/README.md"
DATA="$ORCH_DIR/data/leaderboard.json"

[ -f "$README" ] || { echo "ERROR: $README not found" >&2; exit 2; }
[ -f "$DATA" ] || { echo "ERROR: $DATA not found" >&2; exit 2; }

# Overview table's Role column, data rows only (header + separator
# dropped via tail -n +3).
ROLE_CELLS="$(awk '
  /^## Overview/ { intable=1; next }
  intable && /^## / { exit }
  intable && /^\|/ { print }
' "$README" | tail -n +3 | awk -F'|' '{gsub(/^ +| +$/, "", $2); print $2}')"

if [ -z "$ROLE_CELLS" ]; then
  echo "ERROR: no Overview table found (or it's empty) in $README - is this claude-sonnet-5 or lfm2.5-vl-450m? This script doesn't apply to either, see header comment." >&2
  exit 2
fi

MISSING=0
while IFS= read -r role_cell; do
  [ -z "$role_cell" ] && continue
  RESULT="$(python3 - "$DATA" "$MODEL_DIR_NAME" "$role_cell" <<'PYEOF'
import json, sys
data_path, model_slug, role_cell = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(data_path))
role_cell_l = role_cell.lower()
matched_role_id = None
for role in data["roles"]:
    if role_cell_l.startswith(role["name"].lower()):
        matched_role_id = role["id"]
        break
if matched_role_id is None:
    print("NO_ROLE_MATCH")
    sys.exit(0)
for r in data["results"]:
    if r["modelSlug"] == model_slug and r["role"] == matched_role_id:
        print("OK")
        sys.exit(0)
for s in data.get("scaffold", []):
    if s.get("modelSlug", s.get("model")) == model_slug and s["role"] == matched_role_id:
        print("OK")
        sys.exit(0)
print(f"MISSING:{matched_role_id}")
PYEOF
)"
  case "$RESULT" in
    OK) : ;;
    NO_ROLE_MATCH)
      echo "WARN: Overview row '$role_cell' didn't match any known role name in data/leaderboard.json's roles[] - skipped, check by hand"
      ;;
    MISSING:*)
      echo "MISSING: data/leaderboard.json has no entry for $MODEL_DIR_NAME / ${RESULT#MISSING:}"
      MISSING=1
      ;;
  esac
done <<< "$ROLE_CELLS"

if [ "$MISSING" -eq 0 ]; then
  echo "VERDICT: OK - every Overview-table role has a data/leaderboard.json entry for $MODEL_DIR_NAME"
  exit 0
else
  echo "VERDICT: INCOMPLETE - see MISSING lines above. Add the row to data/leaderboard.json (bench/leaderboard.py's docstring has the schema), then re-run python3 bench/leaderboard.py."
  exit 1
fi
