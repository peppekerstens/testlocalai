#!/usr/bin/env bash
# Confirm: mechanically implements AGENTS.md's "Confirm — check the
# optimization is real, not one lucky draw" step. Runs bench/report.sh
# 3 times back-to-back against the current state, unchanged, then
# compares per-task verdicts across all 3 runs.
#
# This exists because the 3-draw-and-tally procedure was previously
# prose in AGENTS.md that an agent had to re-implement via ad-hoc bash
# every cycle — real cost (re-reading + re-deriving the procedure every
# run) and real risk (interpretation drift; see the -ngl-20
# misapplication incident this exact script's existence is meant to
# help prevent more of). What's still NOT automated, deliberately: WHY
# a task is flaky, and what to do about it (revert vs. investigate) -
# that's a judgment call for whoever reads this report, same as
# report.sh's own Findings/Suggested-next-steps split.
#
# Usage: bash bench/confirm.sh <model> <role> [backend] [port]
#   Same arguments as bench/report.sh - see that script's own usage
#   comment for what each one means.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
ORCH_DIR="$(cd "$SELF_DIR/.." && pwd)"

MODEL="${1:?usage: confirm.sh <model> <role> [backend] [port]}"
ROLE="${2:?usage: confirm.sh <model> <role> [backend] [port]}"
BACKEND="${3:-llamacpp}"
PORT="${4:-8080}"

MODEL_DIR_NAME="$(echo "$MODEL" | tr ':' '-')"
MODEL_DIR="$ORCH_DIR/models/$MODEL_DIR_NAME"
REPORTS_DIR="$MODEL_DIR/reports"

echo "==> Confirm: running $MODEL / $ROLE 3x back-to-back (unchanged state)"

REPORT_FILES=()
for i in 1 2 3; do
  echo "--- Confirm draw $i/3 ---"
  BEFORE="$(ls -1 "$REPORTS_DIR"/report-"$ROLE"-*.md 2>/dev/null || true)"
  bash "$SELF_DIR/report.sh" "$MODEL" "$ROLE" "$BACKEND" "$PORT"
  AFTER="$(ls -1 "$REPORTS_DIR"/report-"$ROLE"-*.md 2>/dev/null || true)"
  NEW_FILE="$(comm -13 <(echo "$BEFORE" | sort) <(echo "$AFTER" | sort))"
  REPORT_FILES+=("$NEW_FILE")
done

CONFIRM_FILE="$REPORTS_DIR/confirm-$ROLE-$(date -u +%Y%m%d-%H%M%S).md"

python3 - "$SELF_DIR/lib" "$CONFIRM_FILE" "$MODEL" "$ROLE" "${REPORT_FILES[@]}" <<'PY'
import sys, datetime

lib_dir, confirm_file, model, role, *report_files = sys.argv[1:]
sys.path.insert(0, lib_dir)
from report_parse import parse_verdicts

runs = [parse_verdicts(f) for f in report_files]
tasks = sorted(runs[0].keys())

stable = True
rows = []
for t in tasks:
    vs = [r.get(t, "?") for r in runs]
    consistent = len(set(vs)) == 1
    if not consistent:
        stable = False
    rows.append((t, vs, consistent))

pass_counts = [sum(1 for v in r.values() if v == "PASS") for r in runs]

with open(confirm_file, "w", encoding="utf-8") as f:
    f.write(f"# Confirm: {role} — `{model}` — {datetime.datetime.now(datetime.UTC).strftime('%Y%m%d-%H%M%S')}\n\n")
    f.write(f"- Model: `{model}`\n- Role: {role}\n")
    f.write(f"- Source reports: {', '.join('`' + r.split('/')[-1] + '`' for r in report_files)}\n")
    f.write(f"- Pass counts across 3 draws: {pass_counts}\n")
    f.write(f"- **VERDICT: {'CONFIRMED — stable across all 3 draws' if stable else 'FLAKY — see unstable tasks below, revert to previous checkpoint per AGENTS.md'}**\n\n")
    f.write("## Per-task consistency\n\n")
    f.write("| Task | Draw 1 | Draw 2 | Draw 3 | Consistent? |\n|---|---|---|---|---|\n")
    for t, vs, consistent in rows:
        mark = "✅" if consistent else "⚠️ FLAKY"
        f.write(f"| `{t}` | {vs[0]} | {vs[1]} | {vs[2]} | {mark} |\n")
    f.write("\n## Findings\n\nTODO — if FLAKY above, identify why the unstable task(s) vary (read the raw output per AGENTS.md's report-completion rule, don't paraphrase) before deciding whether to revert or investigate further.\n")

print(f"Confirm report written: {confirm_file}")
print(f"VERDICT: {'CONFIRMED' if stable else 'FLAKY'}")
PY

echo "==> confirm report: $CONFIRM_FILE"
