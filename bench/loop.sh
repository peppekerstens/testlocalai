#!/usr/bin/env bash
# The quality-loop orchestrator (AGENTS.md's "The quality loop"),
# scripted end to end. This is the piece that used to be "a capable
# model reads AGENTS.md prose and decides what to run next" - almost
# all of that was actually orchestration glue (run a script, branch on
# its exit code), not judgment. This script IS that glue. Only two
# narrow call-outs remain, both to `claude -p` for now:
#
#   bucket 2 (narrow classifier - CONTINUE/GATE_OUT on Tier 1's
#     gate-on-run-2 rule): structured JSON, one enum field. Cheap,
#     bounded, mechanically validatable - the first candidate to hand
#     to a small local model once that's tested (see
#     docs/QUALITY-LOOP-WORKFLOW.md).
#   bucket 3 (generative - Findings/Suggested-next-steps text, steering
#     override authoring): structured JSON with a content field. Higher
#     quality risk (a bad override burns a real budget slot), stays on
#     a capable model for longer.
#
# Every call to `claude` runs with `--tools ""` (no file/bash access -
# this script does ALL file I/O itself and pastes exactly what's needed
# into the prompt) and `--json-schema` (a guaranteed field to extract,
# not fragile text-boundary parsing) - same reasoning as report_parse.py
# scoping its regex to one section: don't trust free-text parsing when
# a structural guarantee is available instead.
#
# NOT automated by this script (deliberately, for now): Phase 0
# (pre-flight infra research), the Research phase's cross-model idiom
# check and external research (both need real tool use - web search,
# reading other models' history.md - which `--tools ""` deliberately
# rules out; only a same-model history.md check is folded into
# author_override's prompt, not the full mandated Research step),
# Tier 2's generalist search, the Performance run, and the Final
# report's qualitative frontier-LLM comparison - these stay
# manual/Claude-Code-driven. This script stops cleanly and says so once
# Tier 1 -> gate -> Confirm settles; it never silently claims to have
# done a phase it skipped.
#
# Usage: bash bench/loop.sh [--verbose] <model> <role> [max_rounds] [backend] [port]
#   --verbose: also enables bash's own command trace (`set -x`) into the
#              log file (and terminal) - shows every command actually
#              run, including full claude invocations. Can appear
#              anywhere in the argument list.
#
# Every run always writes a full transcript to
# bench/logs/loop.sh-<UTC start timestamp>.log regardless of --verbose
# (stdout+stderr of this script AND everything it calls, via `exec >
# >(tee ...)` - the standard bash idiom for "capture everything, still
# show it live"). --verbose only controls how much low-level command
# detail is ALSO included, via bash's native `set -x` tracer rather
# than a hand-rolled print-more function.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCH_DIR="$(cd "$SELF_DIR/.." && pwd)"
cd "$ORCH_DIR"

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
START_TS="$(date -u +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/loop.sh-$START_TS-$$.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[loop.sh] full trace: $LOG_FILE"

if [ "$VERBOSE" -eq 1 ]; then
  export PS4='+ $(date -u +%H:%M:%S) ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
  set -x
fi

MODEL="${1:?usage: loop.sh [--verbose] <model> <role> [max_rounds] [backend] [port]}"
ROLE="${2:?usage: loop.sh [--verbose] <model> <role> [max_rounds] [backend] [port]}"
MAX_ROUNDS="${3:-4}"
BACKEND="${4:-llamacpp}"
PORT="${5:-8080}"

MODEL_DIR_NAME="$(echo "$MODEL" | tr ':' '-')"
MODEL_DIR="$ORCH_DIR/models/$MODEL_DIR_NAME"
REPORTS_DIR="$MODEL_DIR/reports"
OVERRIDES_DIR="$MODEL_DIR/task-overrides"
GATED_FILE="$OVERRIDES_DIR/.gated-$ROLE"
TMP_DIR="$ORCH_DIR/bench/tmp"
CLAUDE_TMP="$TMP_DIR/loop-claude"
mkdir -p "$REPORTS_DIR" "$OVERRIDES_DIR" "$CLAUDE_TMP"

log() { echo "[loop.sh] $*"; }

# ---------------------------------------------------------------------
# ask_claude PROMPT_FILE SCHEMA_JSON OUT_JSON_FILE
# Stateless, tool-free, structured-output call. Writes the full JSON
# response (including the schema-validated "structured_output" object)
# to OUT_JSON_FILE. Caller extracts fields with python3 -c.
# ---------------------------------------------------------------------
ask_claude() {
  local prompt_file="$1" schema="$2" out_file="$3"
  local rc=0
  claude -p "$(cat "$prompt_file")" --tools "" --output-format json \
    --json-schema "$schema" > "$out_file" 2>"$out_file.stderr" || rc=$?
  if [ "$rc" -ne 0 ]; then
    log "ERROR: claude call exited $rc (see $out_file.stderr)"
    return 1
  fi
  if [ ! -s "$out_file" ]; then
    log "ERROR: claude call produced no output (see $out_file.stderr)"
    return 1
  fi
  if ! python3 -c "
import json, sys
d = json.load(open(sys.argv[1], encoding='utf-8'))
so = d.get('structured_output')
sys.exit(1 if (d.get('is_error') or not isinstance(so, dict) or not so) else 0)
" "$out_file"; then
    log "ERROR: claude call returned is_error or no usable structured_output (see $out_file)"
    return 1
  fi
}

extract_field() {
  local json_file="$1" field="$2"
  python3 -c "
import json, sys
d = json.load(open(sys.argv[1], encoding='utf-8'))
so = d.get('structured_output', {})
print(so.get(sys.argv[2], ''))
" "$json_file" "$field"
}

commit_if_changed() {
  local message="$1"
  git add -- "models/$MODEL_DIR_NAME/" >/dev/null 2>&1
  if ! git diff --cached --quiet; then
    git commit -q -m "$message"
    log "committed: $message"
  fi
}

# ---------------------------------------------------------------------
# complete_report_findings REPORT_FILE
# Bucket 3a. Fills Findings/Suggested-next-steps if report-check.sh
# says they're still templated. No-op (mechanical check only) otherwise.
# ---------------------------------------------------------------------
complete_report_findings() {
  local report_file="$1"
  if bash "$SELF_DIR/report-check.sh" "$report_file" >/dev/null 2>&1; then
    log "report already complete: $(basename "$report_file")"
    return 0
  fi

  log "filling Findings/Suggested-next-steps: $(basename "$report_file")"

  local prompt_file="$CLAUDE_TMP/findings-prompt.txt"
  {
    echo "You are completing a report per this project's exact rules. Follow them precisely, do not add extra sections."
    echo
    echo "=== AGENTS.md rules (verbatim) ==="
    sed -n '/^## Completing a report/,/^## Per-model doc-task steering/p' "$ORCH_DIR/AGENTS.md" | sed '$d'
    echo
    echo "=== Report so far (results + comparison tables) ==="
    sed '/^## Findings/,$d' "$report_file"
    echo
    echo "=== Raw output for FAIL/changed tasks ==="
    for f in "$TMP_DIR"/out-*.txt; do
      [ -f "$f" ] || continue
      echo "--- $(basename "$f") ---"
      cat "$f"
      echo
    done
    echo "=== Model's existing history.md (for idiom classification) ==="
    [ -f "$MODEL_DIR/history.md" ] && cat "$MODEL_DIR/history.md"
    echo
    echo "Return the Findings bullets (as they'd appear under '## Findings', markdown, no heading) and the Suggested next steps bullets (as they'd appear under '## Suggested next steps', markdown, no heading) as two separate fields."
  } > "$prompt_file"

  local schema='{"type":"object","properties":{"findings":{"type":"string"},"suggested_next_steps":{"type":"string"}},"required":["findings","suggested_next_steps"]}'
  local out_file="$CLAUDE_TMP/findings-result.json"
  if ! ask_claude "$prompt_file" "$schema" "$out_file"; then
    log "WARNING: could not fill Findings for $(basename "$report_file") — left templated"
    return 1
  fi

  local findings suggested
  findings="$(extract_field "$out_file" findings)"
  suggested="$(extract_field "$out_file" suggested_next_steps)"

  if [ -z "${findings// /}" ] || [ -z "${suggested// /}" ]; then
    log "WARNING: claude returned an empty findings/suggested_next_steps field — leaving report templated, not writing blank content"
    return 1
  fi

  python3 -c "
import re, sys
path, findings, suggested = sys.argv[1:4]
text = open(path, encoding='utf-8').read()
text = re.sub(
    r'(## Findings\n\n)<!--.*?-->',
    lambda m: m.group(1) + findings.strip() + '\n',
    text, count=1, flags=re.S)
text = re.sub(
    r'(## Suggested next steps\n\n)<!--.*?-->',
    lambda m: m.group(1) + suggested.strip() + '\n',
    text, count=1, flags=re.S)
open(path, 'w', encoding='utf-8').write(text)
" "$report_file" "$findings" "$suggested"

  if bash "$SELF_DIR/report-check.sh" "$report_file" >/dev/null 2>&1; then
    log "Findings/Suggested-next-steps filled and verified: $(basename "$report_file")"
  else
    log "WARNING: filled Findings but report-check.sh still flags it — needs manual review"
  fi
  bash "$SELF_DIR/report-heuristics.sh" "$report_file" | sed 's/^/[loop.sh][heuristics] /'
}

# ---------------------------------------------------------------------
# author_override TASK
# Bucket 3b. Writes models/<model-dir>/task-overrides/<task>.md.
# ---------------------------------------------------------------------
author_override() {
  local task="$1"
  log "authoring steering override: $task"

  local prompt_file="$CLAUDE_TMP/override-prompt-$task.txt"
  {
    echo "You are writing a Tier 1 per-task steering override for a small local LLM, per this project's exact convention. This file will be dispatched INSTEAD of the bare task SPEC — write it as a complete, self-contained prompt/instructions for the model under test, not a diff or a note about the change."
    echo
    echo "=== Task SPEC (bare, currently failing) ==="
    cat "$ORCH_DIR/tasks/$task/SPEC.md" 2>/dev/null
    echo
    echo "=== Raw failure output this task produced ==="
    cat "$TMP_DIR/out-$task.txt" 2>/dev/null
    echo
    echo "=== Model's history.md (check for an already-diagnosed idiom/fix pattern before inventing a new one) ==="
    [ -f "$MODEL_DIR/history.md" ] && cat "$MODEL_DIR/history.md"
    echo
    local example
    example="$(find "$OVERRIDES_DIR" -maxdepth 1 -name '*.md' ! -name '.gated-*' 2>/dev/null | head -1)"
    if [ -n "$example" ]; then
      echo "=== Example of an existing override in this model's task-overrides/ (format reference only, different task) ==="
      cat "$example"
    fi
    echo
    echo "Return the complete override file content (what the model under test will actually be dispatched), and separately your rationale (which idiom this targets, why this lever)."
  } > "$prompt_file"

  local schema='{"type":"object","properties":{"override_content":{"type":"string"},"rationale":{"type":"string"}},"required":["override_content","rationale"]}'
  local out_file="$CLAUDE_TMP/override-result-$task.json"
  if ! ask_claude "$prompt_file" "$schema" "$out_file"; then
    log "WARNING: could not author override for $task — leaving bare"
    return 1
  fi

  local content rationale
  content="$(extract_field "$out_file" override_content)"
  rationale="$(extract_field "$out_file" rationale)"
  if [ -z "${content// /}" ]; then
    log "WARNING: claude returned an empty override_content for $task — leaving bare, not writing a blank override"
    return 1
  fi
  printf '%s\n' "$content" > "$OVERRIDES_DIR/$task.md"
  log "override written for $task — rationale: $rationale"
}

# ---------------------------------------------------------------------
# gate_decision TASK BEFORE_REPORT AFTER_REPORT
# Bucket 2. Prints CONTINUE or GATE_OUT to stdout.
# ---------------------------------------------------------------------
gate_decision() {
  local task="$1" before="$2" after="$3"
  local prompt_file="$CLAUDE_TMP/gate-prompt-$task.txt"
  {
    echo "AGENTS.md's Tier 1 'gate on run 2' rule: after the first real steering attempt, only keep investing (up to the 4-run cap) in a task showing SOME real partial improvement (even short of a full PASS). A task flat or regressed after run 1 gets gated out - stop, revert to bare, move on."
    echo
    echo "Task: $task"
    echo "=== Raw output BEFORE this round's steering attempt ==="
    grep -A 3 "\`$task\`" "$before" 2>/dev/null || echo "(no prior data)"
    echo
    echo "=== Raw output AFTER this round's steering attempt ==="
    cat "$TMP_DIR/out-$task.txt" 2>/dev/null
    echo
    echo "Did this task show real partial improvement (even short of a full PASS), or is it flat/regressed? Answer CONTINUE (keep investing, up to the 4-run cap) or GATE_OUT (revert to bare, stop spending budget on it)."
  } > "$prompt_file"

  local schema='{"type":"object","properties":{"decision":{"type":"string","enum":["CONTINUE","GATE_OUT"]},"reason":{"type":"string"}},"required":["decision","reason"]}'
  local out_file="$CLAUDE_TMP/gate-result-$task.json"
  if ! ask_claude "$prompt_file" "$schema" "$out_file"; then
    log "WARNING: gate decision call failed for $task — defaulting to CONTINUE (fail open, budget cap still applies)"
    echo "CONTINUE"
    return
  fi
  local decision reason
  decision="$(extract_field "$out_file" decision)"
  reason="$(extract_field "$out_file" reason)"
  log "gate decision for $task: $decision — $reason"
  echo "$decision"
}

fail_tasks() {
  local report_file="$1"
  python3 -c "
import sys
sys.path.insert(0, '$SELF_DIR/lib')
from report_parse import parse_verdicts
v = parse_verdicts(sys.argv[1])
print('\n'.join(t for t, r in v.items() if r == 'FAIL'))
" "$report_file"
}

is_gated() {
  local task="$1"
  [ -f "$GATED_FILE" ] && grep -qxF "$task" "$GATED_FILE"
}

run_report() {
  if ! bash "$SELF_DIR/report.sh" "$MODEL" "$ROLE" "$BACKEND" "$PORT" >&2; then
    log "FATAL: report.sh failed (infra-level - service didn't come back healthy, or produced no results). Stopping, not continuing on a stale report."
    exit 1
  fi
  ls -1t "$REPORTS_DIR"/report-"$ROLE"-*.md | head -1
}

# =======================================================================
# Main — guarded so this file can be `source`d for testing individual
# functions (e.g. complete_report_findings) without triggering a real
# dispatch/report.sh/Confirm run.
# =======================================================================
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  return 0 2>/dev/null || true
fi

log "starting: model=$MODEL role=$ROLE max_rounds=$MAX_ROUNDS"

LATEST="$(ls -1t "$REPORTS_DIR"/report-"$ROLE"-*.md 2>/dev/null | head -1)"
if [ -z "$LATEST" ]; then
  log "no prior report — Phase 1 reference run"
  LATEST="$(run_report)"
else
  log "prior work found — resuming from $(basename "$LATEST")"
fi
complete_report_findings "$LATEST"
commit_if_changed "$MODEL role=$ROLE: loop.sh Phase 1/resume report"

FAILS="$(fail_tasks "$LATEST")"
if [ -z "$FAILS" ]; then
  log "no FAIL tasks — role already passing, skipping Tier 1"
else
  log "FAIL tasks: $(echo "$FAILS" | tr '\n' ' ')"

  for round in $(seq 1 "$MAX_ROUNDS"); do
    ACTIVE="$(fail_tasks "$LATEST" | while read -r t; do is_gated "$t" || echo "$t"; done)"
    if [ -z "$ACTIVE" ]; then
      log "round $round: no active FAIL tasks left (all passing or gated) — stopping Tier 1"
      break
    fi
    log "=== round $round/$MAX_ROUNDS — active: $(echo "$ACTIVE" | tr '\n' ' ') ==="

    while read -r t; do
      [ -z "$t" ] && continue
      [ -f "$OVERRIDES_DIR/$t.md" ] || author_override "$t"
    done <<< "$ACTIVE"

    PREV="$LATEST"
    LATEST="$(run_report)"
    complete_report_findings "$LATEST"
    commit_if_changed "$MODEL role=$ROLE: loop.sh Tier 1 round $round"

    if [ "$round" -eq 2 ]; then
      # One-time checkpoint (AGENTS.md: "gate on run 2"), not a
      # per-round re-evaluation - tasks that pass this once continue
      # automatically through their remaining budget.
      STILL_FAILING="$(fail_tasks "$LATEST")"
      while read -r t; do
        [ -z "$t" ] && continue
        echo "$ACTIVE" | grep -qxF "$t" || continue
        echo "$STILL_FAILING" | grep -qxF "$t" || continue
        DECISION="$(gate_decision "$t" "$PREV" "$LATEST" | tail -1)"
        if [ "$DECISION" = "GATE_OUT" ]; then
          rm -f "$OVERRIDES_DIR/$t.md"
          echo "$t" >> "$GATED_FILE"
          log "$t gated out — reverted to bare"
        fi
      done <<< "$STILL_FAILING"
      commit_if_changed "$MODEL role=$ROLE: loop.sh round $round gate decisions"
    fi
  done
fi

log "=== Tier 2 gate ==="
bash "$SELF_DIR/tier2-gate.sh" "$LATEST"
GATE_EXIT=$?
if [ "$GATE_EXIT" -eq 0 ]; then
  log "GATE: GO — Tier 2 generalist search is NOT automated by this script. Run it manually/via Claude Code before Confirm, per AGENTS.md."
else
  log "GATE: SKIP — proceeding to Confirm on the Tier 1 result."
fi

log "=== Confirm ==="
bash "$SELF_DIR/confirm.sh" "$MODEL" "$ROLE" "$BACKEND" "$PORT"

log "=== loop.sh done ==="
log "Automated: Phase 1/resume, Tier 1 steering rounds (up to $MAX_ROUNDS), gate-on-run-2 decisions, Tier 2 gate, Confirm."
log "NOT automated — do these manually next: Tier 2 generalist search (if GATE said GO), Performance run, Final report."
