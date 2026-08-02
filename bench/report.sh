#!/usr/bin/env bash
# Report generator: runs one role's task track against a model via
# pure-run.sh, then writes an enriched, versioned report to
# models/<model>/reports/report-<role>-<YYYYMMDD-HHMMSS>.md — results
# table, token usage, and a diff against that model+role's most recent
# prior report (if one exists).
#
# What this script CAN automate: verdicts, token counts, finish_reason
# (truncation detection), and mechanical deltas vs the previous report.
# What it CANNOT automate: WHY a task failed, or what to try next — that
# needs someone to actually read the raw failing output. The report ends
# with "Findings" / "Suggested next steps" sections left as an explicit
# TODO placeholder rather than faking analysis the script didn't do.
#
# Usage: bash bench/report.sh <model> <role> [backend] [port]
#   model   : qwen2.5-coder:1.5b | deepseek-r1:1.5b | ... (required)
#   role    : docs | reason | tool | extract | review (required — see
#             pure-run.sh's --test for what each covers). Does NOT cover
#             code-* tasks (different harness, see bench.sh instead).
#   backend : llamacpp (default) | ollama
#   port    : LLAMACPP_PORT override (default 8080)
set -euo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
ORCH_DIR="$(cd "$SELF_DIR/.." && pwd)"

MODEL="${1:?usage: report.sh <model> <role> [backend] [port]}"
ROLE="${2:?usage: report.sh <model> <role> [backend] [port]}"
BACKEND="${3:-llamacpp}"
PORT="${4:-8080}"

case "$ROLE" in
  docs|reason|tool|extract|review) ;;
  *) echo "ERROR: unknown role '$ROLE' (expected: docs, reason, tool, extract, review)" >&2; exit 2 ;;
esac

MODEL_DIR_NAME="$(echo "$MODEL" | tr ':' '-')"
MODEL_DIR="$ORCH_DIR/models/$MODEL_DIR_NAME"
REPORTS_DIR="$MODEL_DIR/reports"
mkdir -p "$REPORTS_DIR"

TIMESTAMP="$(date -u +%Y%m%d-%H%M%S)"
REPORT_FILE="$REPORTS_DIR/report-$ROLE-$TIMESTAMP.md"

echo "==> running pure-run.sh: model=$MODEL role=$ROLE backend=$BACKEND port=$PORT" >&2
RESULTS="$(DISPATCH_BACKEND="$BACKEND" LLAMACPP_PORT="$PORT" bash "$SELF_DIR/pure-run.sh" "$MODEL" --test "$ROLE" 2>&1 | grep '^RESULT ')"

if [ -z "$RESULTS" ]; then
  echo "ERROR: pure-run.sh produced no RESULT lines — check it ran correctly" >&2
  exit 1
fi

# Most recent prior report for this exact model+role, if any (filenames
# sort chronologically since the timestamp is YYYYMMDD-HHMMSS).
PREV_REPORT="$(ls -1 "$REPORTS_DIR"/report-"$ROLE"-*.md 2>/dev/null | sort | tail -1 || true)"

RESULTS_FILE="$SELF_DIR/tmp/.report-results-$TIMESTAMP.txt"
mkdir -p "$SELF_DIR/tmp"
printf '%s\n' "$RESULTS" > "$RESULTS_FILE"

python3 - "$REPORT_FILE" "$MODEL" "$ROLE" "$BACKEND" "$PORT" "$TIMESTAMP" "${PREV_REPORT:-}" "$RESULTS_FILE" <<'PY'
import re, sys, datetime

report_file, model, role, backend, port, timestamp, prev_report, results_file = sys.argv[1:9]
with open(results_file, encoding="utf-8") as f:
    results_text = f.read()

rows = []
for line in results_text.splitlines():
    line = line.strip()
    if not line.startswith("RESULT "):
        continue
    fields = dict(re.findall(r"(\w+)=(\S+)", line))
    task = fields.get("task", "?")
    run = fields.get("model_run", "?")
    pt = fields.get("prompt_tok", "?")
    ct = fields.get("comp_tok", "?")
    truncated = "TRUNCATED-BY-CONTEXT-LIMIT" in line
    finish = "length (TRUNCATED)" if truncated else "stop"
    rows.append({"task": task, "verdict": run, "prompt_tok": pt, "comp_tok": ct, "finish": finish})

passed = sum(1 for r in rows if r["verdict"] == "PASS")
total = len(rows)

def parse_prev_table(path):
    """Extract {task: verdict} from a previous report's Results table."""
    prev = {}
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except Exception:
        return prev
    in_table = False
    for line in text.splitlines():
        if line.strip().startswith("| Task | Verdict"):
            in_table = True
            continue
        if in_table:
            if not line.strip().startswith("|"):
                break
            if line.strip().startswith("|---") or line.strip().startswith("| ---"):
                continue
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) >= 2:
                prev[cells[0].strip("`")] = cells[1]
    return prev

prev_verdicts = parse_prev_table(prev_report) if prev_report else {}

lines = []
lines.append(f"# Report: {role} — `{model}` — {timestamp}")
lines.append("")
lines.append(f"- Model: `{model}`")
lines.append(f"- Role: {role}")
lines.append(f"- Backend: {backend} (port {port})")
lines.append(f"- Generated: {timestamp} UTC")
lines.append(f"- **Result: {passed}/{total} PASS**")
lines.append("")
lines.append("## Results")
lines.append("")
lines.append("| Task | Verdict | Prompt tok | Completion tok | Finish reason |")
lines.append("|---|---|---|---|---|")
for r in rows:
    lines.append(f"| `{r['task']}` | {r['verdict']} | {r['prompt_tok']} | {r['comp_tok']} | {r['finish']} |")
lines.append("")

lines.append("## Comparison vs previous report")
lines.append("")
if not prev_report:
    lines.append(f"No previous `report-{role}-*.md` found for this model — this is the first report for this model+role combination, nothing to compare against.")
else:
    import os
    lines.append(f"Previous: `{os.path.basename(prev_report)}`")
    lines.append("")
    lines.append("| Task | Previous | Current | Change |")
    lines.append("|---|---|---|---|")
    flips_to_pass, flips_to_fail, unchanged, new_tasks = 0, 0, 0, 0
    for r in rows:
        task = r["task"]
        cur = r["verdict"]
        prev = prev_verdicts.get(task)
        if prev is None:
            change = "new task (no prior data)"
            new_tasks += 1
        elif prev == cur:
            change = "unchanged"
            unchanged += 1
        elif prev != "PASS" and cur == "PASS":
            change = "✅ improved"
            flips_to_pass += 1
        elif prev == "PASS" and cur != "PASS":
            change = "❌ regressed"
            flips_to_fail += 1
        else:
            change = f"changed ({prev} → {cur})"
        lines.append(f"| `{task}` | {prev or 'n/a'} | {cur} | {change} |")
    lines.append("")
    lines.append(
        f"**Summary:** {flips_to_pass} improved, {flips_to_fail} regressed, "
        f"{unchanged} unchanged, {new_tasks} new task(s) with no prior data."
    )
lines.append("")

lines.append("## Findings")
lines.append("")
lines.append(
    "<!-- NOT DONE YET. Required before this report is complete — see\n"
    "     AGENTS.md's \"Completing a report: exactly what MUST be filled\n"
    "     in after report.sh runs\". Per FAIL/changed task: (1) the exact\n"
    "     quoted verify.sh failure line, (2) idiom classification against\n"
    "     history.md, (3) truncation judgment if finish_reason shows one,\n"
    "     (4) the single-draw/sample-size caveat. Raw output for this run:\n"
    "     bench/tmp/out-<task>.txt (pure-run.sh/report.sh) or\n"
    "     tasks/<task>/rounds/out-<round>.txt (bench.sh). -->"
)
lines.append("")
lines.append("## Suggested next steps")
lines.append("")
lines.append(
    "<!-- NOT DONE YET — see the same AGENTS.md section. Each suggestion\n"
    "     needs a specific task + lever (not \"steer more\"), a stated\n"
    "     answer to \"do we need more draws first\", and a stated answer\n"
    "     to \"does models/<model>/README.md need updating\". -->"
)
lines.append("")

with open(report_file, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print(f"Report written: {report_file}")
print(f"Result: {passed}/{total} PASS")
PY

rm -f "$RESULTS_FILE"
